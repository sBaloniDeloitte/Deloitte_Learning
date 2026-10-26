public class COMM_IncomeSanctionLetterController {
    static String conLabels = 'Error_Loan_Application_not_found,Error_Missing_Loan_Amount,Error_Missing_SanctionTerms,Error_No_Loan_Transaction_records_found,Error_Missing_Scheduling_Method,Error_TDS_Applicable_is_not_selected,Error_Missing_Rate_Type,Error_Missing_Number_of_Grace_Terms,Error_Missing_Default_BPI_Treatment,Error_Missing_Max_Planned_EMI_Holidays,Error_Missing_Max_Holidays,Error_Missing_EMI_Holiday_Lock_Period,Error_Missing_Planned_EMI_Capitalize,Charges_API_Invocation,Term_Loan,Flexi_Funds,Over_Draft,Variant,Product,Sub_Product,Sub_Variant,Interest_Only,Hybrid_Tenure,Hybrid_Only';
    
    public static Map <String,String> constants = Utility.getConstants(conLabels);
    
    //getting the value of constants
    public static Map <String,String> getConstants() {
        return constants;
    }
    
    public static string formatDateString(date myDate){
        try{
            String formattedDate;
            
            if(myDate != null){
                DateTime myDateTime = DateTime.newInstance(myDate.year(), myDate.month(), myDate.day());
                formattedDate = myDateTime.format('yyyy-MM-dd');
                
                if(formattedDate != ''){
                    formattedDate = formattedDate + 'T00:00:00';
                }
            }
            System.debug('Convert Date String Format : ' + formattedDate);
            
            return formattedDate;
            
        } catch(Exception e){
            System.debug('FinanceApiHandler->formatDateString ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string sendIncomeSanctionEvent(String loanId,String productId) {
        try {
            String loanApplicationId = loanId;  
            Utility_V1.ProductWrapper prodWrapperRec = Utility_V1.checkIfLoggedInUserIsHLRelated(new Map<String, String>{});
            Boolean isHLUser = (prodWrapperRec != null && prodWrapperRec.isHLRelated == true);
            
            // Fetch all metadata records at once
            Map<String, Default_Values_LoanSchedule_API__mdt> defaultValuesMap = Default_Values_LoanSchedule_API__mdt.getAll();
            system.debug('wrapper:: '+defaultValuesMap);
            // Create a map for easy access where Attribute__c is the key and Value__c is the value
            Map<String, String> defaultValues = new Map<String, String>();
            
            for (Default_Values_LoanSchedule_API__mdt metadataRecord : defaultValuesMap.values()) {
                String value = metadataRecord.Value__c != null ? metadataRecord.Value__c : '';
                defaultValues.put(metadataRecord.Attribute__c, value);
            }
            
            // **Bulk Query: Fetch Loan Application (Opportunity)**
            List<Opportunity> loanApplications = [
                SELECT Id, Product__c,Name, Sanction_Loan_Amount__c, Sanction_Tenure__c, Branch_Master__c, Branch_Master__r.Branch_Code__c,Dsa_Area_Manager__r.Name, Dsa_Area_Manager__r.Employee_Id__c, Dsa_Area_Manager__r.Manager.Email, Dsa_Area_Manager__r.Email,
                Variant__c,Final_Rate_Of_Interest__c, Loan_Purpose__c,Tenor_Months__c,Final_Tenure__c,APR__c,Lead__c,Lead__r.Dsa_Area_Manager__r.email,Loan_Hierarchy__c,Split_Parent_Loan_Application__c, Dsa_Area_Manager__r.Manager.Name, Dsa_Area_Manager__r.Manager.Employee_Id__c
                FROM Opportunity 
                WHERE Id = :loanApplicationId
            ];
            Opportunity loanApplication = loanApplications.isEmpty() ? null : loanApplications[0];

            List<Loan_Transaction__c> loanTransactions = [
                SELECT Id, Disbursement_Amount__c, Allow_Payment_in_Grace_Period__c, Schedule_Method__c, 
                BPI_Treatment__c, Allow_Grace__c, TDS_Applicable__c, Step_Loan__c,PLR_Code__c,PLR_Value__c, 
                Grace_Period_Frequency__c, Interest_Frequency__c, Allow_BPI__c, Loan_Start_Date__c,
                Allow_Planned_EMI_Holiday__c, Allow_Planned_EMI_holiday_in_Grace__c,Interest_Due_date__c, 
                Planned_EMI_Holiday_Method__c, Max_per_Year__c, Max__c, Lock_Period_Months__c, 
                Capitalize__c,Rate_Type__c,Margin__c, Grace_Base_Rate_Code__c, Next_First_Payment_Date__c,
                First_Disbursement_Amount__c,Payment_Method_Grace_Parameter__c,Payment_Method__c,
                Elastic_Credit_Line_Type__c,Dropline_Calculated_On__c,Yearly_Selection__c,
                Half_Yearly_Selection__c,Quarterly_Selection__c,Dropline_Tenure__c,Pure_Tenure__c,Number_of_Terms__c
                FROM Loan_Transaction__c
                WHERE Loan_Application__c = :loanApplicationId
                AND RecordType.DeveloperName = 'Transaction_Details'
            ];
            Loan_Transaction__c loanTransaction = loanTransactions.isEmpty() ? null : loanTransactions[0];
            
            String requiredLoanId = loanApplicationId;
            if(loanApplication.Loan_Hierarchy__c == 'Child' && loanApplication.Split_Parent_Loan_Application__c != null){
                requiredLoanId = loanApplication.Split_Parent_Loan_Application__c;
            }
            
            
            
            // **Fetch Primary Application Applicant**
            List<Application_Applicant__c> applicants = [
                SELECT Id, Name, First_Name__c, Last_Name__c,Customer__r.SF_Customer_ID__c, Applicant_Name__c,Mobile_Number__c, Email__c, Salutation__c, Customer__r.Customer_LMS_Id__c, Nationality__c,
                Customer_Type__c, Gender__c, Residency_Status__c,Employment_Type__c, Mother_s_First_Name__c, Father_s_First_Name__c, DOB__c, Marital_Status__c, PAN_Number__c
                FROM Application_Applicant__c
                WHERE Loan_Application__c = :requiredLoanId
                AND Applicant_Type__c = 'Primary Applicant'
            ];
            
            Application_Applicant__c primaryApplicant = applicants.isEmpty() ? null : applicants[0];
            String primarycustomerId = primaryApplicant.Customer__r.SF_Customer_ID__c;
            if (primarycustomerId.startsWith('C-') && !System.Test.isRunningTest()) {
                primarycustomerId = primarycustomerId.substring(2); // Remove the first 2 characters (C-)
            }
            // **Fetch Co Application Applicant**
            List<Application_Applicant__c> coapplicants = [
                SELECT Id, Name, First_Name__c, Customer__r.SF_Customer_ID__c,Last_Name__c,Applicant_Name__c,Mobile_Number__c, Email__c, Salutation__c, Customer__r.Customer_LMS_Id__c, 
                Customer_Type__c, Gender__c, Residency_Status__c,Employment_Type__c, Mother_s_First_Name__c, Father_s_First_Name__c, DOB__c, Marital_Status__c, PAN_Number__c,
                Nationality__c
                FROM Application_Applicant__c
                WHERE Loan_Application__c = :requiredLoanId
                AND Applicant_Type__c = 'Co Applicant'
            ];
            Application_Applicant__c coApplicant = coapplicants.isEmpty() ? null : coapplicants[0];
            
            Set<Id> applicantIds = new Set<Id>();
            if (primaryApplicant != null) applicantIds.add(primaryApplicant.Id);
            if (coApplicant != null) applicantIds.add(coApplicant.Id);
            
            //List<Applicant_Address__c> applicantAddress = new List<Applicant_Address__c>();
            List<Applicant_Address__c> allAddresses = [
                SELECT Id, Full_Address1__c
                FROM Applicant_Address__c
                WHERE Applicant__r.Loan_Application__c =: requiredLoanId And Applicant__c =: primaryApplicant.Id And Address_Line_1__c != '' And Address_Priority__c = '5' Limit 1
            ];
            
            List<Applicant_Address__c> allAddressesCoApp = new List<Applicant_Address__c>();
            if (coApplicant != null) {
                allAddressesCoApp = [
                    SELECT Id, Full_Address1__c
                    FROM Applicant_Address__c
                    WHERE Applicant__r.Loan_Application__c =: requiredLoanId And Applicant__c =: coApplicant.Id And Address_Line_1__c != '' And Address_Priority__c = '5' Limit 1
                ];
            }
            
            List<Sanction_Condition__c> sanctionConditions = [SELECT Id, Name, Condition_Name__c, Condition_Approval__c, Loan_Application__c FROM Sanction_Condition__c 
                                                              WHERE Loan_Application__c = :requiredLoanId And Condition_Approval__c = 'Pending'];
            
            List<Application_Collateral__c> appCollateral = [select Id,Collateral__r.Unit_Number__c,Collateral__r.Floor_Number__c,Collateral__r.Tower_Building_Name__c,
                                                             Collateral__r.Project__c,Collateral__r.Project__r.Name,Collateral__r.Address_Line_1__c,Collateral__r.Address_Line_2__c,Collateral__r.Address_Line_3__c,
                                                             Collateral__r.Landmark__c,Collateral__r.City__c,Collateral__r.State__c,Collateral__r.Pincode__r.Name,Collateral__r.Unit_Property_Type__c,
                                                             Collateral__r.Name from Application_Collateral__c where HL_Loan_Application__c = :requiredLoanId];
            
            
            
            
            List<Bank_Details__c> repaymentAccounts = [SELECT Id, Account_Holder_Name__c, Name, Account_Number__c, Account_Type__c, 
                                                       OD_CC_Limit__c, ABB__c, Source__c, Application_Applicant__c, Application_Applicant__r.Applicant_Type__c, 
                                                       Bank_Master__r.Name,  Bank_Master__r.MICR__c,Bank_Master__r.Branch_Name__c, 
                                                       Bank_Master__r.Branch_Location__c
                                                       FROM Bank_Details__c
                                                       WHERE Application_Applicant__c IN :applicantIds 
                                                       AND Is_Repayment_Account__c = true
                                                       ORDER BY Application_Applicant__r.Applicant_Type__c ASC];
            
            Bank_Details__c selectedAccount = new Bank_Details__c();
            
            // **Fetch Sales Manager's Email from Opportunity Team Members**
            List<OpportunityTeamMember> oppTeamMembers = [
                SELECT User.Email,User.Name,User.Employee_Id__c, User.Manager.Email,User.Manager.Name,User.Manager.Employee_Id__c,TeamMemberRole , Associated_With_Loan_Application__c
                FROM OpportunityTeamMember 
                WHERE OpportunityId = :loanApplicationId
            ];
            
            Map<String, Communication_Event_Product_Mapping__mdt> productMetaMapping = Communication_Event_Product_Mapping__mdt.getAll();
            Map<String, Communication_Event_Product_Mapping__mdt> productMapping= new Map<String, Communication_Event_Product_Mapping__mdt>();
            for (Communication_Event_Product_Mapping__mdt metadata : productMetaMapping.values()){
                productMapping.put(metadata.Product_Name__c, metadata);
            }
            if (isHLUser) {
                Map<Id, List<Applicant_Address__c>> collateralToAddressMap = new Map<Id, List<Applicant_Address__c>>();
                Set<Id> appCollateralIds = new Set<Id>();
                List<Product2> allProducts = new List<Product2>();
                
                for (Application_Collateral__c ac : appCollateral) {
                    appCollateralIds.add(ac.Id);
                }
                List<Applicant_Address__c> applicantAddressCoolateral = [SELECT Id,Name,Pincode__r.Name,Pincode__c,Application_Collateral__c,Address_Line_1__c,Address_Line_2__c,Address_Line_3__c From Applicant_Address__c Where Loan_Application__c =:loanApplicationId AND Application_Collateral__c IN :appCollateralIds];
                for (Applicant_Address__c addr : applicantAddressCoolateral) {
                    if (!collateralToAddressMap.containsKey(addr.Application_Collateral__c)) {
                        collateralToAddressMap.put(addr.Application_Collateral__c, new List<Applicant_Address__c>());
                    }
                    collateralToAddressMap.get(addr.Application_Collateral__c).add(addr);
                }
                system.debug('productId 155--'+productId);
                
                allProducts = [SELECT Id, Name,Sanctioned_Tenor__c,Sanctioned_Loan_Amount__c,Final_ROI__c ,Final_Tenure__c,Sanctioned_ROI__c, RecordType.Name, Loan_Application__c, Product__c,Product__r.Name, Product_Master__r.PLF_Loan_Type__c, PLR_Code__c, PLR_Value__c,BPI_Interest_Days_Basis__c, Interest_Days_Basis__c FROM Product2 WHERE Loan_Application__c = :loanApplicationId];  
                Map<Id, Product2> productMap = new Map<Id, Product2>();
                Map<Id, Product2> subProductMap = new Map<Id, Product2>();
                Map<Id, List<Product2>> subProdToVariantsMap = new Map<Id, List<Product2>>();
                
                // Separate based on record type
                for (Product2 p : allProducts) {
                    String rt = p.RecordType.Name;
                    
                    // --- If productId is provided ---
                    if (!String.isBlank(productId)) {
                        // Case 1: Product record (only add the one passed in)
                        if (rt == constants.get('Product') && p.Id == productId) {
                            productMap.put(p.Id, p);
                        } 
                        // Case 2: Sub-product
                        else if (rt == constants.get('Sub_Product')) {
                            subProductMap.put(p.Id, p);
                        } 
                        // Case 3: Variants/Sub-variants under sub-product
                        else if (rt == constants.get('Variant') || rt == constants.get('Sub_Variant')) {
                            if (p.Product__c != null) {
                                if (!subProdToVariantsMap.containsKey(p.Product__c)) {
                                    subProdToVariantsMap.put(p.Product__c, new List<Product2>());
                                }
                                subProdToVariantsMap.get(p.Product__c).add(p);
                            }
                        }
                    }
                    // --- If no productId passed, keep full logic (all Product records) ---
                    else {
                        if (rt == constants.get('Product')) {
                            productMap.put(p.Id, p);
                        } 
                        else if (rt == constants.get('Sub_Product')) {
                            subProductMap.put(p.Id, p);
                        } 
                        else if (rt == constants.get('Variant') || rt == constants.get('Sub_Variant')) {
                            if (p.Product__c != null) {
                                if (!subProdToVariantsMap.containsKey(p.Product__c)) {
                                    subProdToVariantsMap.put(p.Product__c, new List<Product2>());
                                }
                                subProdToVariantsMap.get(p.Product__c).add(p);
                            }
                        }
                    }
                }
                
                // --- Query Charges only for main products using productMap.keySet() ---
                Map<Id, List<Charges_Insurance__c>> productIdToChargesMap = new Map<Id, List<Charges_Insurance__c>>();
                if (!productMap.isEmpty()) {
                    for (Charges_Insurance__c ch : [SELECT Id, RecordType.Name, Name,Final_Amount_INR__c, Charges_Fee_Type__c,Requested_Amount_INR__c, Category__c, Requested_Percentage__c,Product__c, Loan_Application__c FROM Charges_Insurance__c WHERE Loan_Application__c = :requiredLoanId AND RecordType.Name = 'Charges']) {
                        if (!productIdToChargesMap.containsKey(ch.Product__c)) {
                            productIdToChargesMap.put(ch.Product__c, new List<Charges_Insurance__c>());
                        }
                        productIdToChargesMap.get(ch.Product__c).add(ch);
                    }
                }
                system.debug('productIdToChargesMap---215'+productIdToChargesMap);
                
                for (Product2 product : productMap.values()) {         
                    Product2 subProduct;
                    for (Product2 sp : subProductMap.values()) {
                        if (sp.Product__c == product.Id) {
                            subProduct = sp;
                            break;
                        }
                    }
                    
                    if (subProduct == null) continue;
                    
                    // Related variants/subvariants
                    List<Product2> productRecords = subProdToVariantsMap.get(subProduct.Id);
                    
                    String finType = subProduct.Product_Master__r.PLF_Loan_Type__c;  // 'AH'
                    String productName = '';
                    String profitDaysBasis = '';
                    String bpiProfitDaysBasis = '';
                    String plrCode = '';
                    Decimal plrValue = 0;
                    string subVariantPrd = '';
                    List<Product2> hybridTenure;
                    
                    
                    if(product.name == 'Affordable Home Loan') {
                        productName = 'AH';
                    }else if(product.name == 'Affordable Non-Home Loan') {
                        productName = 'AL';
                    }else if(product.name == 'Flexi Loan') {
                        productName = 'FL';
                    }
                    else {
                        productName= productMapping.get(subProduct.name).Product_Name_in_Wrapper__c;
                    }
                    
                    for (Product2 prod : productRecords) {
                        if(prod.RecordType.Name == constants.get('Variant')){
                            profitDaysBasis = prod.Interest_Days_Basis__c != null ? prod.Interest_Days_Basis__c : '30E/360I';
                            bpiProfitDaysBasis = prod.BPI_Interest_Days_Basis__c != null ? prod.BPI_Interest_Days_Basis__c : '30E/360I';
                            plrCode = prod.PLR_Code__c != null ? prod.PLR_Code__c : 'GHFPLR';
                            plrValue = prod.PLR_Value__c != null ? prod.PLR_Value__c : 18.31;
                            // productName = loanApplication.Product__c;
                        }
                        else if(prod.RecordType.Name == constants.get('Sub_Variant')){
                            subVariantPrd = prod.Name;
                            hybridTenure = [Select Id, Name from Product2 Where Loan_Application__c = :loanId 
                                            And Sub_Variant__c =: prod.Id And RecordType.Name =: constants.get('Hybrid_Tenure')];
                        }
                    }       
                    
                    if(repaymentAccounts != null && !repaymentAccounts.isEmpty()){
                        selectedAccount = repaymentAccounts[0];   
                    }else{
                        selectedAccount = null;
                    }
                    
                    List<Charges_Insurance__c> charges = productIdToChargesMap.get(product.Id);
                    system.debug('charges--261'+charges);
                    
                    String rmEmail = '';
                    String amEmail = '';
                    String rmname = '';
                    String rmid = '';
                    String amname = '';
                    String amid = '';
                    String timestamp = Datetime.now().format('yyyy-MM-dd HH:mm:ss.SSS');
                    String stepFlag = '0';
                    String frequencyCode =  'M';
                    String instalmentFrequency = 'Monthly';
                    if (frequencyCode.startsWith('M')) {
                        instalmentFrequency = 'Monthly';
                    } else if (frequencyCode.startsWith('Y')) {
                        instalmentFrequency = 'Yearly';
                    } else if (frequencyCode.startsWith('Q')) {
                        instalmentFrequency = 'Quarterly';
                    } else if (frequencyCode.startsWith('H')) {
                        instalmentFrequency = 'Half Yearly';
                    }
                    String dueDateCode =  '03';
                    
                    String mmCode = '00'; // Default MM for Monthly
                    
                    if (frequencyCode == 'Y') {
                        mmCode = '01';
                    } else if (frequencyCode == 'H') {
                        mmCode = '01';
                    } else if (frequencyCode == 'Q') {
                        mmCode =  '01';
                    }
                    // M already defaulted to '00'
                    
                    String finalFrequencyCode = frequencyCode + mmCode + dueDateCode;
                    System.debug('Final Frequency Code: ' + finalFrequencyCode);
                    
                    Integer sanctionTenure = subProduct.Final_Tenure__c != null ? Integer.valueOf(subProduct.Final_Tenure__c) : Integer.valueOf(loanApplication.Sanction_Tenure__c);
                    // Integer graceFreq = hybridTenure != null ? Integer.valueOf(hybridTenure[0].name) : 0;
                    Integer graceFreq = 0;
                    
                    
                    Integer noOfSteps = 0;
                    Integer noOfGrcSteps = 0;
                    
                    
                    
                    
                    if(isHLUser){
                        for (OpportunityTeamMember teamMember : oppTeamMembers) {
                            system.debug('teamMember.TeamMemberRole'+ teamMember.TeamMemberRole);
                            system.debug('teamMember.Associated_With_Loan_Application__c'+ teamMember.Associated_With_Loan_Application__c);
                            system.debug('teamMember.Email'+ teamMember.User.Email);
                            if(teamMember.TeamMemberRole == 'Sales' && teamMember.Associated_With_Loan_Application__c == true && String.isNotBlank(teamMember.User.Email)){
                                rmEmail = teamMember.User.Email;
                                rmname = String.isNotBlank(teamMember.User.Name) ? teamMember.User.Name : '';
                                rmid = String.isNotBlank(teamMember.User.Employee_Id__c) ? teamMember.User.Employee_Id__c : '';
                                amEmail = teamMember.User.Manager != null ? teamMember.User.Manager.Email : rmEmail;
                                amname = teamMember.User.Manager != null ? teamMember.User.Manager.Name : rmname;
                                amid = teamMember.User.Manager != null ? teamMember.User.Manager.Employee_Id__c : rmid;
                                break; 
                            }
                        }
                    }
                    
                    Boolean allowGrace = false;
                    Boolean allowPlannedEMI = false;
                    
                    
                    Date plfDate = [SELECT Business_Date__c FROM Integration_Details__c WHERE Business_Date__c != null ORder by CreatedDate DESC Limit 1].Business_Date__c;
                    
                    // **Initialize Request Wrapper**
                    SanctionLetterRequestWrapper request = new SanctionLetterRequestWrapper();
                    request.eventID = defaultValues.containsKey('eventID') ? String.valueOf(defaultValues.get('eventID')):'005Ci000003sh1RIAJ';
                    request.lettertype = defaultValues.containsKey('lettertype') ? String.valueOf(defaultValues.get('lettertype')):'SLSF';
                    request.mobile_number = primaryApplicant != null ? primaryApplicant.Mobile_Number__c : '';
                    request.whatsaap_number = primaryApplicant != null ? primaryApplicant.Mobile_Number__c : '';
                    if(primaryApplicant != null && primaryApplicant.Customer_Type__c == 'Individual'){
                        request.custctgcode = 'RETAIL';
                    }else if(primaryApplicant != null && primaryApplicant.Customer_Type__c == 'Non Individual'){
                        request.custctgcode = 'CORP';
                    }else{
                        request.custctgcode =  '';
                    }
                    request.email_id = primaryApplicant != null && primaryApplicant.Email__c != null ? primaryApplicant.Email__c : '';
                    request.reference = loanApplication.Name;
                    if(primaryApplicant != null && primaryApplicant.Customer_Type__c == 'Individual'){
                        request.salutation = primaryApplicant.Salutation__c != null ? primaryApplicant.Salutation__c : '';
                    }else if(primaryApplicant != null && primaryApplicant.Customer_Type__c == 'Non Individual'){
                        request.salutation = 'M/S';
                    }else{
                        request.salutation =  '';
                    }
                    request.time_stamp = timestamp;
                    request.typeOfLoan = product.Name;
                    request.step_finance = stepFlag;
                    request.cif = primaryApplicant != null && primaryApplicant.Customer__r.Customer_LMS_Id__c != null? primaryApplicant.Customer__r.Customer_LMS_Id__c : primarycustomerId;
                    // request.isLRD = ''; 
                    request.name = primaryApplicant != null ? primaryApplicant.Applicant_Name__c : '';
                    request.custfirstname = primaryApplicant != null ? primaryApplicant.First_Name__c : '';
                    request.custlastname = primaryApplicant != null ? primaryApplicant.Last_Name__c : '';
                    
                    request.custaddr1 = !allAddresses.isEmpty() ? allAddresses[0].Full_Address1__c : '';
                    request.custaddr2 = '';
                    request.custaddr3 = '';
                    
                    request.finStartDate = formatDateString(plfDate);
                    
                    //request.date_of_disbursal = plfDate != null ? DateTime.newInstance(plfDate, Time.newInstance(0, 0, 0, 0)).formatGmt('yyyy-MM-dd HH:mm:ss') : '';
                    request.date_of_disbursal = plfDate != null ? plfDate.toString() : '';
                    //request.loan_amount = loanApplication != null && loanTransaction.First_Disbursement_Amount__c!= null ? Integer.valueOf(Utility.addTwoZeros(loanTransaction.First_Disbursement_Amount__c)) : 0;
                    request.loan_amount = subProduct.Sanctioned_Loan_Amount__c != null ? Utility.addTwoZeros(subProduct.Sanctioned_Loan_Amount__c).longValue() : 0;
                    request.rate_of_interest = subProduct != null ? subProduct.Sanctioned_ROI__c : 0;
                    request.type_of_interest = 'Fixed Rate';
                    request.ghplr = String.valueOf(plrValue);
                    // request.margin = 0;
                    request.margin = (loanTransaction != null && plrValue != null) ? loanTransaction.Margin__c - plrValue :0;
                    request.stepup_pre_emi_tenor = 0;
                    request.bank_name = selectedAccount!= null && selectedAccount.Name != null ? selectedAccount.Name : ''; 
                    request.acc_number = selectedAccount!= null && selectedAccount.Account_Number__c != null ? selectedAccount.Account_Number__c:'';
                    request.finassetvalue = subProduct.Sanctioned_Loan_Amount__c!= null ? Utility.addTwoZeros(subProduct.Sanctioned_Loan_Amount__c).longValue() : 0;
                    //request.total_tenor = loanApplication != null ? Integer.valueOf(loanApplication.Final_Tenure__c) : 0;
                    
                    // **Insurance Charges - Fetch Total VAS Amount**
                    Decimal insuranceCharges = 0;
                    Decimal amcCharges = 0;
                    Decimal processingFee = 0;
                    Decimal finalProcessingFee = 0;
                    Decimal stampingFranking = 0;
                    
                    for (Charges_Insurance__c charge : charges) {
                        if (charge.Category__c == 'Insurance') {
                            insuranceCharges += charge.Final_Amount_INR__c;
                        }
                        else if(charge.Category__c == 'LMS') {
                            if(charge.Name == 'LOSAMC'){
                                amcCharges += charge.Requested_Percentage__c;
                            }
                        }
                        else if(charge.Category__c == 'LOS') {
                            if (charge.Name == 'PROCFEE') {
                                processingFee += charge.Requested_Amount_INR__c;
                                // finalProcessingFee += charge.Final_Amount_INR__c;
                            }
                            else if (charge.Name == 'STFRCHG') {
                                stampingFranking += charge.Final_Amount_INR__c;
                            }
                        }
                    }
                    if(processingFee > 0){
                        finalProcessingFee = (processingFee + ((processingFee * 18)/100)).setScale(0, RoundingMode.HALF_UP);
                    }
                    
                    
                    request.total_tenor = subProduct.Sanctioned_Tenor__c != null ? Integer.valueOf(subProduct.Sanctioned_Tenor__c) : 0;
                    request.full_emi_tenor = subProduct.Sanctioned_Tenor__c != null ? Integer.valueOf(subProduct.Sanctioned_Tenor__c) : 0;
                    
                    
                    system.debug('request.full_emi_tenor: '+request.full_emi_tenor);
                    
                    request.moratorium_tenor = 0;
                    // request.pemii_tenor = 0;
                    if (finType == 'HL' || finType == 'NHL') {
                        request.pemii_tenor = 0;
                    }
                    //request.full_emi_tenor = loanApplication != null ? Integer.valueOf(loanApplication.Final_Tenure__c) : 0/*240*/; 
                    // request.holiday_tenor = 0;
                    if (finType == 'HL' || finType == 'NHL') {
                        request.holiday_tenor = 0;
                    }
                    request.repayment_mode = '';
                    //request.additional_product = ''; // Default
                    request.end_use_of_loan = loanApplication.Loan_Purpose__c != null ? loanApplication.Loan_Purpose__c:'Business Expansion';
                    request.stepfinance ='FALSE';
                    request.finisactive = 1;
                    request.repaybaserate = /*'GFLPLRBL';*/plrCode;//productmaster
                    request.grcpftfrq = '';
                    request.grcpftrvwfrq = '';
                    request.grccpzfrq =  '';
                    request.allow_bpi =  false;
                    request.bpitreatment = 'N';
                    request.allowgrcrepay =  false;
                    request.grcratebasis = 'R';
                    if(allowGrace == true){
                        // if(subVariantPrd == constants.get('Interest_Only')){
                        //     request.graceterms = hybridTenure != null ? Integer.valueOf(hybridTenure[0].name) : 0;
                        // }
                        // else {
                        request.graceterms = graceFreq;
                        // }
                    }else{
                        request.graceterms = 0;
                    }
                    //request.graceterms = (loanTransaction != null && allowGrace == true) ? Integer.valueOf(loanTransaction.Grace_Period_Frequency__c) : 0;
                    //request.grcratebasis = (loanTransaction != null && allowGrace == true) ? loanTransaction.Rate_Type__c:'';
                    request.grcmargin =  0;
                    request.grcminrate = (defaultValues.containsKey('grcMinRate') && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcMinRate')) : 0;
                    request.grcmaxrate = (defaultValues.containsKey('grcMaxRate') && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcMaxRate')) : 0;
                    request.grcmaxamount = (defaultValues.containsKey('grcMaxAmount') && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcMaxAmount')) : 0;
                    request.grcadvpftrate = (defaultValues.containsKey('grcAdvPftRate') && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcAdvPftRate')) : 0;
                    request.grcadvmargin = (defaultValues.containsKey('grcAdvMargin') && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcAdvMargin')) : 0;
                    request.alwgrcadj = false;
                    request.gracebaserate =  'GHFPLR'; 
                    request.schedulemethod =  'EQUAL';
                    request.profitdaysbasis = profitDaysBasis;
                    request.bpipftdaysbasis = bpiProfitDaysBasis;
                    request.finrepaypftonfrq = false; //new field on loan transaction
                    request.frequency = '';
                    request.instalment_frequency = instalmentFrequency;
                    
                    
                    request.numberofterms = subProduct.Sanctioned_Tenor__c != null ? Integer.valueOf(subProduct.Sanctioned_Tenor__c) : 0;
                    
                    system.debug('request.numberofterms: '+request.numberofterms);
                    
                    request.insurance_charges = Integer.valueOf(Utility.addTwoZeros(insuranceCharges));
                    request.other_charges = 0;
                    request.apr = loanApplication.APR__c != null ? loanApplication.APR__c : (defaultValues.containsKey('apr') ? Decimal.valueOf(defaultValues.get('apr')) : 16.622373624);
                        
                        request.processing_fee = Integer.valueOf(Utility.addTwoZeros(processingFee));
                    request.fintype = finType;
                    request.interestperiod = 0;
                    request.sanction_withdrawal_amt = '';/*null (if API throws error then pass final amount)"sanction_withdrawal_amt":"1000000000" check with null again*/
                    request.product_variant = '';
                    request.feetypeid = 1;
                    request.processingfee = Integer.valueOf(Utility.addTwoZeros(finalProcessingFee)); // Final Processing Fee Amount
                    request.custresidentialsts = /*primaryApplicant != null ? primaryApplicant.Residency_Status__c : ''*/'';
                    request.finpurpose = 'BR';//mapping codes need to happen
                    request.allowgrcperiod =  0;
                    request.allow_grcperiod =  false;
                    
                    request.grcschdmthd =  'EQUAL';
                    request.branch_code = loanApplication.Branch_Master__r.Branch_Code__c!=null ?loanApplication.Branch_Master__r.Branch_Code__c:'3002';
                    request.gender = primaryApplicant != null && primaryApplicant.Gender__c != null ? primaryApplicant.Gender__c : '';
                    request.resident_status = primaryApplicant != null && primaryApplicant.Residency_Status__c!= null ? primaryApplicant.Residency_Status__c : '';
                    request.rm_email_id = rmEmail;
                    request.am_email_id = amEmail != null ? amEmail : rmEmail;
                    
                    // request.elasticcrlinetype = '#'; // default to # for BL, BD will have value
                    //request.elasticcrLine = (loanTransaction != null && finType == 'BD') ? true:false;
                    
                    request.stamping_franking = String.valueOf(Integer.valueOf(Utility.addTwoZeros(stampingFranking))); // Stamping & Franking Charges
                    
                    // **Handle Co-Applicants**
                    request.coApplicant = new List<SanctionLetterRequestWrapper.cls_coApplicant>();
                    for (Application_Applicant__c coApp : coApplicants) {
                        SanctionLetterRequestWrapper.cls_coApplicant coAppWrap = new SanctionLetterRequestWrapper.cls_coApplicant();
                        
                        String coAppcustomerId = coApp.Customer__r.SF_Customer_ID__c;
                        if(System.Test.isRunningTest()) {
                            coAppcustomerId = 'C-00000001';
                        }
                        
                        if (coAppcustomerId.startsWith('C-')) {
                            coAppcustomerId = coAppcustomerId.substring(2); // Remove the first 2 characters (C-)
                        }
                        // **Set Salutation Based on Customer Type**
                        if (coApp.Customer_Type__c == 'Individual') {
                            coAppWrap.salutation = coApp.Salutation__c != null ? coApp.Salutation__c : '';
                        } else if (coApp.Customer_Type__c == 'Non-Individual') {
                            coAppWrap.salutation = 'M/s';
                        } else {
                            coAppWrap.salutation = '';
                        }
                        
                        coAppWrap.name = coApp.Applicant_Name__c != null ? coApp.Applicant_Name__c : '';
                        coAppWrap.cif = coApp.Customer__r.Customer_LMS_Id__c != null ? coApp.Customer__r.Customer_LMS_Id__c : coAppcustomerId;
                        coAppWrap.email_address = coApp.Email__c != null ? coApp.Email__c : '';
                        coAppWrap.whatsaap_number = coApp.Mobile_Number__c != null ? coApp.Mobile_Number__c : '';
                        coAppWrap.sms_number = coApp.Mobile_Number__c != null ? coApp.Mobile_Number__c : '';
                        
                        request.coApplicant.add(coAppWrap);
                    }
                    
                    
                    // **Handle Sanction Conditions**
                    request.sanctionConditions = new List<SanctionLetterRequestWrapper.cls_sanctionConditions>();
                    Integer seqCounter = 1;
                    for (Sanction_Condition__c condition : sanctionConditions) {
                        SanctionLetterRequestWrapper.cls_sanctionConditions sanctionWrap = new SanctionLetterRequestWrapper.cls_sanctionConditions();  
                        sanctionWrap.seqno = seqCounter;
                        sanctionWrap.sanctioncondition = condition.Condition_Name__c;
                        request.sanctionConditions.add(sanctionWrap);
                        seqCounter++;
                    }
                    
                    request.repaymentPlanData = new List<SanctionLetterRequestWrapper.repaymentPlanData>();
                    
                    request.hlsData = new List<Object>();
                    request.linkedLans = new List<SanctionLetterRequestWrapper.cls_linkedLans>();
                    for (Integer i = 0; i < 1; i++) {//dummy
                        SanctionLetterRequestWrapper.cls_linkedLans linkedLoan = new SanctionLetterRequestWrapper.cls_linkedLans();
                        linkedLoan.reference = '';
                        request.linkedLans.add(linkedLoan);
                    }
                    
                    request.collateralPropertyDetails = new List<SanctionLetterRequestWrapper.cls_collateralPropertDetails>();
                    for (Application_Collateral__c col : appCollateral) {
                        List<Applicant_Address__c> relatedAddresses = collateralToAddressMap.get(col.Id);
                        Applicant_Address__c addr = relatedAddresses[0];
                        SanctionLetterRequestWrapper.cls_collateralPropertDetails collateralWrap = new SanctionLetterRequestWrapper.cls_collateralPropertDetails();  
                        collateralWrap.unit = col.Collateral__r.Unit_Number__c != null ? col.Collateral__r.Unit_Number__c.toString() : '';
                        collateralWrap.floornumber = col.Collateral__r.Floor_Number__c != null ? col.Collateral__r.Floor_Number__c : '';
                        collateralWrap.tower = col.Collateral__r.Tower_Building_Name__c != null ? col.Collateral__r.Tower_Building_Name__c : '';
                        collateralWrap.project_name = col.Collateral__r.Project__c != null ? col.Collateral__r.Project__r.Name.toString() : '';     
                        
                        collateralWrap.propertyaddress1 = addr.Address_Line_1__c != null ? addr.Address_Line_1__c : '';
                        collateralWrap.propertyaddress2 = addr.Address_Line_2__c != null ? addr.Address_Line_2__c : '';
                        collateralWrap.propertyaddress3 = addr.Address_Line_3__c != null ? addr.Address_Line_3__c : '';
                        collateralWrap.landmark = col.Collateral__r.Landmark__c != null ? col.Collateral__r.Landmark__c : '';
                        collateralWrap.city = col.Collateral__r.City__c != null ? col.Collateral__r.City__c : '';
                        collateralWrap.state = col.Collateral__r.State__c != null ? col.Collateral__r.State__c : '';
                        collateralWrap.pincode = addr.Pincode__r.Name != null ? addr.Pincode__r.Name : '';
                        collateralWrap.collateral_id = col.Collateral__r.Name != null ? col.Collateral__r.Name : '';
                        collateralWrap.unittype = col.Collateral__r.Unit_Property_Type__c != null ? col.Collateral__r.Unit_Property_Type__c : '';
                        request.collateralPropertyDetails.add(collateralWrap);
                    }
                    
                    request.repaymentSchedule = new List<Object>();
                    request.subcategory = primaryApplicant != null ? primaryApplicant.Employment_Type__c : '';
                    request.subproduct =  subProduct != null ? subProduct.Name : '';
                    request.rmname = rmname != null ? rmname : '';
                    request.rmid = rmid != null ? rmid : '';
                    request.amname = amname != null ? amname : (rmname != null ? rmname : '');
                        request.amid = amid != null ? amid : (rmid != null ? rmid : '');
                            request.offemailverified = false;//need clarification 
                    // request.loan_towards_selfcon = 0;//need clarification
                    if (finType == 'HL' || finType == 'NHL') {
                        request.loan_towards_selfcon = 0;
                        request.loan_towards_plot = 0;
                        request.elasticcrlinetype = '#';
                        request.isLRD = ''; 
                    }
                    
                    request.appFormDetails = new List<SanctionLetterRequestWrapper.cls_appFormDetails>();
                    request.appFormCoappDetails = new List<SanctionLetterRequestWrapper.cls_appFormCoappDetails>();
                    SanctionLetterRequestWrapper.cls_appFormDetails primaryAppWrap = new SanctionLetterRequestWrapper.cls_appFormDetails(); 
                    SanctionLetterRequestWrapper.cls_appFormCoappDetails coAppWrap = new SanctionLetterRequestWrapper.cls_appFormCoappDetails();  
                    if(finType == 'FL'){
                        primaryAppWrap.custshrtname = primaryApplicant.Applicant_Name__c != null ? primaryApplicant.Applicant_Name__c : '';
                        primaryAppWrap.mothername = primaryApplicant.Mother_s_First_Name__c != null ? primaryApplicant.Mother_s_First_Name__c : '';
                        primaryAppWrap.fathername = primaryApplicant.Father_s_First_Name__c != null ? primaryApplicant.Father_s_First_Name__c : '';
                        primaryAppWrap.custcif = primaryApplicant.Customer__r.Customer_LMS_Id__c != null ? primaryApplicant.Customer__r.Customer_LMS_Id__c : '';
                        primaryAppWrap.dateofbirth = primaryApplicant.DOB__c != null ? formatDateString(primaryApplicant.DOB__c) : ''; //Need to check the field
                        // primaryAppWrap.dateofbirth = '';
                        primaryAppWrap.maritalstatus = primaryApplicant.Marital_Status__c != null ? primaryApplicant.Marital_Status__c : '';
                        // primaryAppWrap.countryofbirth = primaryApplicant.Country_of_Birth__c != null ? primaryApplicant.Country_of_Birth__c : ''; //Need to check the field
                        primaryAppWrap.countryofbirth = '';
                        primaryAppWrap.occupationcategory = primaryApplicant.Employment_Type__c != null ? primaryApplicant.Employment_Type__c : '';
                        primaryAppWrap.nationality = primaryApplicant.Nationality__c != null ? primaryApplicant.Nationality__c : '';
                        primaryAppWrap.gender = primaryApplicant.Gender__c != null ? primaryApplicant.Gender__c : '';
                        primaryAppWrap.pan = primaryApplicant.PAN_Number__c != null ? primaryApplicant.PAN_Number__c : '';
                        primaryAppWrap.mobile = primaryApplicant.Mobile_Number__c != null ? primaryApplicant.Mobile_Number__c : '';
                        primaryAppWrap.phonenumber = primaryApplicant.Mobile_Number__c != null ? primaryApplicant.Mobile_Number__c : '';
                        primaryAppWrap.emailid = primaryApplicant.Email__c != null ? primaryApplicant.Email__c : '';
                        primaryAppWrap.residentialstatus = primaryApplicant.Residency_Status__c != null ? primaryApplicant.Residency_Status__c : '';
                        primaryAppWrap.address = !allAddresses.isEmpty() ? allAddresses[0].Full_Address1__c : ''; //Need to check the field
                        request.appFormDetails.add(primaryAppWrap);
                        
                        if (coApplicant != null) {
                            coAppWrap.custshrtname = coApplicant.Applicant_Name__c != null ? coApplicant.Applicant_Name__c : '';
                            coAppWrap.mothername = coApplicant.Mother_s_First_Name__c != null ? coApplicant.Mother_s_First_Name__c : '';
                            coAppWrap.fathername = coApplicant.Father_s_First_Name__c != null ? coApplicant.Father_s_First_Name__c : '';
                            coAppWrap.custcif = coApplicant.Customer__r.Customer_LMS_Id__c != null ? coApplicant.Customer__r.Customer_LMS_Id__c : '';
                            coAppWrap.dateofbirth = coApplicant.DOB__c != null ? formatDateString(coApplicant.DOB__c) : ''; //Need to check the field
                            // coAppWrap.dateofbirth = '';
                            coAppWrap.maritalstatus = coApplicant.Marital_Status__c != null ? coApplicant.Marital_Status__c : '';
                            // coAppWrap.countryofbirth = coApplicant.Country_of_Birth__c != null ? coApplicant.Country_of_Birth__c : ''; //Need to check the field
                            coAppWrap.countryofbirth = '';
                            coAppWrap.occupationcategory = coApplicant.Employment_Type__c != null ? coApplicant.Employment_Type__c : '';
                            coAppWrap.nationality = coApplicant.Nationality__c != null ? coApplicant.Nationality__c : '';
                            coAppWrap.gender = coApplicant.Gender__c != null ? coApplicant.Gender__c : '';
                            coAppWrap.pan = coApplicant.PAN_Number__c != null ? coApplicant.PAN_Number__c : '';
                            coAppWrap.mobile = coApplicant.Mobile_Number__c != null ? coApplicant.Mobile_Number__c : '';
                            coAppWrap.phonenumber = coApplicant.Mobile_Number__c != null ? coApplicant.Mobile_Number__c : '';
                            coAppWrap.emailid = coApplicant.Email__c != null ? coApplicant.Email__c : '';
                            coAppWrap.residentialstatus = coApplicant.Residency_Status__c != null ? coApplicant.Residency_Status__c : '';
                            coAppWrap.address = !allAddressesCoApp.isEmpty() ? allAddressesCoApp[0].Full_Address1__c : ''; //Need to check the field
                            // coAppWrap.address = '';
                            coAppWrap.catofcoapplicant = ''; //Need to check the field
                            request.appFormCoappDetails.add(coAppWrap);
                        }
                        
                    }
                    // request.loan_towards_plot = 0;//need clarification
                    request.fixedratetenor = 0;//need clarification //Mandatory Field if interest Type is Hybrid.For other interest Types not applicable
                    // request.calterms = (loanTransaction != null && String.isNotBlank(loanTransaction.Number_of_Terms__c)) ? Integer.valueOf(loanTransaction.Number_of_Terms__c) : 0;
                    request.calterms = request.numberofterms ; //(loanApplication != null && loanApplication.Sanction_Tenure__c != null) ? Integer.valueOf(loanApplication.Sanction_Tenure__c) : 0;
                    request.finocrrequired = 0;//need clarification
                    
                    // **Convert to JSON**
                    String requestJSON = JSON.serialize(request);
                    System.debug('Request JSON: ' + requestJSON);
                    generateSanctionLetterEvent(loanId,requestJSON,subProduct);
                }
                return 'success';
            }else{
                Product2 mainProduct =[SELECT Id,Name,Product_Master__r.PLF_Loan_Type__c from Product2 WHERE RecordType.Name = :constants.get('Product') AND Name = :loanApplication.Product__c AND Loan_Application__c = :loanApplicationId AND Product_Type__c = 'Parent' LIMIT 1];
                Product2 subProduct = [SELECT Id,Name, Product__r.Name, Sanctioned_ROI__c from Product2 WHERE RecordType.Name = :constants.get('Sub_Product') AND Product__c =:mainProduct.Id AND Loan_Application__c = :loanApplicationId LIMIT 1];
                
                List<string> prodVariantAndSubVariant = new List<string>();
                prodVariantAndSubVariant.add(constants.get('Variant'));
                prodVariantAndSubVariant.add(constants.get('Sub_Variant'));
                
                List<Product2> productRecords = [
                    SELECT Id, Name, RecordType.Name, PLR_Code__c, 
                    PLR_Value__c, BPI_Interest_Days_Basis__c, Interest_Days_Basis__c 
                    FROM Product2 
                    WHERE Loan_Application__c = :loanId
                    AND RecordType.Name In : prodVariantAndSubVariant AND Product__c = :subProduct.Id
                ];
                
                String finType = mainProduct.Product_Master__r.PLF_Loan_Type__c;  // 'AH'
                String productName = '';
                String profitDaysBasis = '';
                String bpiProfitDaysBasis = '';
                String plrCode = '';
                Decimal plrValue = 0;
                string subVariantPrd = '';
                List<Product2> hybridTenure;
                
                if(mainProduct.name == 'Affordable Home Loan') {
                    productName = 'AH';
                }else if(mainProduct.name == 'Affordable Non-Home Loan') {
                    productName = 'AL';
                }else if(mainProduct.name == 'Flexi Loan') {
                    productName = 'FL';
                }
                else {
                    productName= productMapping.get(subProduct.name).Product_Name_in_Wrapper__c;
                }
                
                for (Product2 prod : productRecords) {
                    if(prod.RecordType.Name == constants.get('Variant')){
                        profitDaysBasis = prod.Interest_Days_Basis__c != null ? prod.Interest_Days_Basis__c : '30E/360I';
                        bpiProfitDaysBasis = prod.BPI_Interest_Days_Basis__c != null ? prod.BPI_Interest_Days_Basis__c : '30E/360I';
                        plrCode = prod.PLR_Code__c != null ? prod.PLR_Code__c : 'GHFPLR';
                        plrValue = prod.PLR_Value__c != null ? prod.PLR_Value__c : 18.31;
                        // productName = loanApplication.Product__c;
                    }
                    else if(prod.RecordType.Name == constants.get('Sub_Variant')){
                        subVariantPrd = prod.Name;
                        hybridTenure = [Select Id, Name from Product2 Where Loan_Application__c = :loanId 
                                        And Sub_Variant__c =: prod.Id And RecordType.Name =: constants.get('Hybrid_Tenure')];
                    }
                }
                
                if(repaymentAccounts != null && !repaymentAccounts.isEmpty()){
                    selectedAccount = repaymentAccounts[0];   
                }else{
                    selectedAccount = null;
                }
                
                List<Charges_Insurance__c> charges = [SELECT Id, recordtype.name, Name,     
                                                      Final_Amount_INR__c,Charges_Fee_Type__c,Requested_Amount_INR__c,Category__c,Requested_Percentage__c FROM Charges_Insurance__c WHERE Loan_Application__c = :requiredLoanId AND recordtype.name = 'Charges' AND Product_Name__c = :loanApplication.Product__c] ;       
                
                String rmEmail = '';
                String amEmail = '';
                String rmname = '';
                String rmid = '';
                String amname = '';
                String amid = '';
                String timestamp = Datetime.now().format('yyyy-MM-dd HH:mm:ss.SSS');
                String stepFlag = '0';
                String frequencyCode =  'M';
                String instalmentFrequency = 'Monthly';
                if (frequencyCode.startsWith('M')) {
                    instalmentFrequency = 'Monthly';
                } else if (frequencyCode.startsWith('Y')) {
                    instalmentFrequency = 'Yearly';
                } else if (frequencyCode.startsWith('Q')) {
                    instalmentFrequency = 'Quarterly';
                } else if (frequencyCode.startsWith('H')) {
                    instalmentFrequency = 'Half Yearly';
                }
                String dueDateCode =  '03';
                
                String mmCode = '00'; // Default MM for Monthly
                
                if (frequencyCode == 'Y') {
                    mmCode = '01';
                } else if (frequencyCode == 'H') {
                    mmCode = '01';
                } else if (frequencyCode == 'Q') {
                    mmCode =  '01';
                }
                // M already defaulted to '00'
                
                String finalFrequencyCode = frequencyCode + mmCode + dueDateCode;
                System.debug('Final Frequency Code: ' + finalFrequencyCode);
                
                Integer sanctionTenure = loanApplication.Final_Tenure__c != null ? Integer.valueOf(loanApplication.Final_Tenure__c) : Integer.valueOf(loanApplication.Sanction_Tenure__c);
                // Integer graceFreq = hybridTenure != null ? Integer.valueOf(hybridTenure[0].name) : 0;
                Integer graceFreq = 0;
                
                
                Integer noOfSteps = 0;
                Integer noOfGrcSteps = 0;
                
                rmEmail = String.isNotBlank(loanApplication.Dsa_Area_Manager__r.Email) ? loanApplication.Dsa_Area_Manager__r.Email : '';
                rmname = String.isNotBlank(loanApplication.Dsa_Area_Manager__r.Name) ? loanApplication.Dsa_Area_Manager__r.Name : '';
                rmid = String.isNotBlank(loanApplication.Dsa_Area_Manager__r.Employee_Id__c) ? loanApplication.Dsa_Area_Manager__r.Employee_Id__c : '';
                amEmail = loanApplication.Dsa_Area_Manager__r.Manager != null ? loanApplication.Dsa_Area_Manager__r.Manager.Email :rmEmail;
                amname = loanApplication.Dsa_Area_Manager__r.Manager != null ? loanApplication.Dsa_Area_Manager__r.Manager.Name : rmname;
                amid = loanApplication.Dsa_Area_Manager__r.Manager != null ? loanApplication.Dsa_Area_Manager__r.Manager.Employee_Id__c : '';
                
                
                Boolean allowGrace = false;
                Boolean allowPlannedEMI = false;
                
                
                Date plfDate = [SELECT Business_Date__c FROM Integration_Details__c WHERE Business_Date__c != null ORder by CreatedDate DESC Limit 1].Business_Date__c;
                
                // **Initialize Request Wrapper**
                SanctionLetterRequestWrapper request = new SanctionLetterRequestWrapper();
                request.eventID = defaultValues.containsKey('eventID') ? String.valueOf(defaultValues.get('eventID')):'005Ci000003sh1RIAJ';
                request.lettertype = defaultValues.containsKey('lettertype') ? String.valueOf(defaultValues.get('lettertype')):'SLSF';
                request.mobile_number = primaryApplicant != null ? primaryApplicant.Mobile_Number__c : '';
                request.whatsaap_number = primaryApplicant != null ? primaryApplicant.Mobile_Number__c : '';
                if(primaryApplicant != null && primaryApplicant.Customer_Type__c == 'Individual'){
                    request.custctgcode = 'RETAIL';
                }else if(primaryApplicant != null && primaryApplicant.Customer_Type__c == 'Non Individual'){
                    request.custctgcode = 'CORP';
                }else{
                    request.custctgcode =  '';
                }
                request.email_id = primaryApplicant != null && primaryApplicant.Email__c != null ? primaryApplicant.Email__c : '';
                request.reference = loanApplication.Name;
                if(primaryApplicant != null && primaryApplicant.Customer_Type__c == 'Individual'){
                    request.salutation = primaryApplicant.Salutation__c != null ? primaryApplicant.Salutation__c : '';
                }else if(primaryApplicant != null && primaryApplicant.Customer_Type__c == 'Non Individual'){
                    request.salutation = 'M/S';
                }else{
                    request.salutation =  '';
                }
                request.time_stamp = timestamp;
                request.typeOfLoan = (productName == 'AH' || productName == 'AL') ? 'Affordable Housing Loan' : loanApplication.Product__c;/*'Term -> Business Loan' Flexi -> Business Loan Flexi Funds;*/
                request.step_finance = stepFlag;
                request.cif = primaryApplicant != null && primaryApplicant.Customer__r.Customer_LMS_Id__c != null? primaryApplicant.Customer__r.Customer_LMS_Id__c : primarycustomerId;
                // request.isLRD = ''; 
                request.name = primaryApplicant != null ? primaryApplicant.Applicant_Name__c : '';
                request.custfirstname = primaryApplicant != null ? primaryApplicant.First_Name__c : '';
                request.custlastname = primaryApplicant != null ? primaryApplicant.Last_Name__c : '';
                
                request.custaddr1 = !allAddresses.isEmpty() ? allAddresses[0].Full_Address1__c : '';
                request.custaddr2 = '';
                request.custaddr3 = '';
                
                // request.finStartDate = null;
                request.finStartDate = formatDateString(plfDate);
                
                //request.date_of_disbursal = plfDate != null ? DateTime.newInstance(plfDate, Time.newInstance(0, 0, 0, 0)).formatGmt('yyyy-MM-dd HH:mm:ss') : '';
                request.date_of_disbursal = plfDate != null ? plfDate.toString() : '';
                //request.loan_amount = loanApplication != null && loanTransaction.First_Disbursement_Amount__c!= null ? Integer.valueOf(Utility.addTwoZeros(loanTransaction.First_Disbursement_Amount__c)) : 0;
                request.loan_amount = loanApplication.Sanction_Loan_Amount__c != null ? Utility.addTwoZeros(loanApplication.Sanction_Loan_Amount__c).longValue() : 0;
                request.rate_of_interest = subProduct.Sanctioned_ROI__c   != null ? subProduct.Sanctioned_ROI__c   : 0;
                request.type_of_interest = 'Fixed Rate';
                request.ghplr = String.valueOf(plrValue);
                // request.margin = 0;
                request.margin = (loanTransaction != null && plrValue != null) ? loanTransaction.Margin__c - plrValue :0;
                request.stepup_pre_emi_tenor = 0;
                request.bank_name = selectedAccount!= null && selectedAccount.Name != null ? selectedAccount.Name : ''; 
                request.acc_number = selectedAccount!= null && selectedAccount.Account_Number__c != null ? selectedAccount.Account_Number__c:'';
                request.finassetvalue = loanApplication.Sanction_Loan_Amount__c!= null ? Utility.addTwoZeros(loanApplication.Sanction_Loan_Amount__c).longValue() : 0;
                //request.total_tenor = loanApplication != null ? Integer.valueOf(loanApplication.Final_Tenure__c) : 0;
                
                // **Insurance Charges - Fetch Total VAS Amount**
                Decimal insuranceCharges = 0;
                Decimal amcCharges = 0;
                Decimal processingFee = 0;
                Decimal finalProcessingFee = 0;
                Decimal stampingFranking = 0;
                
                for (Charges_Insurance__c charge : charges) {
                    if (charge.Category__c == 'Insurance') {
                        insuranceCharges += charge.Final_Amount_INR__c;
                    }
                    else if(charge.Category__c == 'LMS') {
                        if(charge.Name == 'LOSAMC'){
                            amcCharges += charge.Requested_Percentage__c;
                        }
                    }
                    else if(charge.Category__c == 'LOS') {
                        if (charge.Name == 'PROCFEE') {
                            processingFee += charge.Requested_Amount_INR__c;
                            // finalProcessingFee += charge.Final_Amount_INR__c;
                        }
                        else if (charge.Name == 'STFRCHG') {
                            stampingFranking += charge.Final_Amount_INR__c;
                        }
                    }
                }
                if(processingFee > 0){
                    finalProcessingFee = (processingFee + ((processingFee * 18)/100)).setScale(0, RoundingMode.HALF_UP);
                }
                
                
                request.total_tenor = loanApplication.Sanction_Tenure__c != null ? Integer.valueOf(loanApplication.Sanction_Tenure__c) : 0;
                request.full_emi_tenor = loanApplication.Sanction_Tenure__c != null ? Integer.valueOf(loanApplication.Sanction_Tenure__c) : 0;
                
                
                system.debug('request.full_emi_tenor: '+request.full_emi_tenor);
                
                request.moratorium_tenor = 0;
                // request.pemii_tenor = 0;
                if (finType == 'AH') {
                    request.pemii_tenor = 0;
                }
                //request.full_emi_tenor = loanApplication != null ? Integer.valueOf(loanApplication.Final_Tenure__c) : 0/*240*/; 
                // request.holiday_tenor = 0;
                if (finType == 'AH') {
                    request.holiday_tenor = 0;
                }
                request.repayment_mode = '';
                //request.additional_product = ''; // Default
                request.end_use_of_loan = loanApplication.Loan_Purpose__c != null ? loanApplication.Loan_Purpose__c:'Business Expansion';
                request.stepfinance ='FALSE';
                request.finisactive = 1;
                request.repaybaserate = /*'GFLPLRBL';*/plrCode;//productmaster
                request.grcpftfrq = '';
                request.grcpftrvwfrq = '';
                request.grccpzfrq =  '';
                request.allow_bpi =  false;
                request.bpitreatment = 'N';
                request.allowgrcrepay =  false;
                request.grcratebasis = 'R';
                if(allowGrace == true){
                    // if(subVariantPrd == constants.get('Interest_Only')){
                    //     request.graceterms = hybridTenure != null ? Integer.valueOf(hybridTenure[0].name) : 0;
                    // }
                    // else {
                    request.graceterms = graceFreq;
                    // }
                }else{
                    request.graceterms = 0;
                }
                //request.graceterms = (loanTransaction != null && allowGrace == true) ? Integer.valueOf(loanTransaction.Grace_Period_Frequency__c) : 0;
                //request.grcratebasis = (loanTransaction != null && allowGrace == true) ? loanTransaction.Rate_Type__c:'';
                request.grcmargin =  0;
                request.grcminrate = (defaultValues.containsKey('grcMinRate') && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcMinRate')) : 0;
                request.grcmaxrate = (defaultValues.containsKey('grcMaxRate') && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcMaxRate')) : 0;
                request.grcmaxamount = (defaultValues.containsKey('grcMaxAmount') && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcMaxAmount')) : 0;
                request.grcadvpftrate = (defaultValues.containsKey('grcAdvPftRate') && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcAdvPftRate')) : 0;
                request.grcadvmargin = (defaultValues.containsKey('grcAdvMargin') && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcAdvMargin')) : 0;
                request.alwgrcadj = false;
                request.gracebaserate =  'GHFPLR'; 
                request.schedulemethod =  'EQUAL';
                request.profitdaysbasis = profitDaysBasis;
                request.bpipftdaysbasis = bpiProfitDaysBasis;
                request.finrepaypftonfrq = false; //new field on loan transaction
                request.frequency = '';
                request.instalment_frequency = instalmentFrequency;
                
                
                request.numberofterms = loanApplication.Sanction_Tenure__c != null ? Integer.valueOf(loanApplication.Sanction_Tenure__c) : 0;
                
                system.debug('request.numberofterms: '+request.numberofterms);
                
                request.insurance_charges = Integer.valueOf(Utility.addTwoZeros(insuranceCharges));
                request.other_charges = 0;
                request.apr = loanApplication.APR__c != null ? loanApplication.APR__c : (defaultValues.containsKey('apr') ? Decimal.valueOf(defaultValues.get('apr')) : 16.622373624);
                    
                    request.processing_fee = Integer.valueOf(Utility.addTwoZeros(processingFee));
                request.fintype = finType;
                request.interestperiod = 0;
                request.sanction_withdrawal_amt = '';/*null (if API throws error then pass final amount)"sanction_withdrawal_amt":"1000000000" check with null again*/
                request.product_variant = '';
                request.feetypeid = 1;
                request.processingfee = Integer.valueOf(Utility.addTwoZeros(finalProcessingFee)); // Final Processing Fee Amount
                request.custresidentialsts = /*primaryApplicant != null ? primaryApplicant.Residency_Status__c : ''*/'';
                request.finpurpose = 'BR';//mapping codes need to happen
                request.allowgrcperiod =  0;
                request.allow_grcperiod =  false;
                
                request.grcschdmthd =  'EQUAL';
                request.branch_code = loanApplication.Branch_Master__r.Branch_Code__c!=null ?loanApplication.Branch_Master__r.Branch_Code__c:'3002';
                request.gender = primaryApplicant != null && primaryApplicant.Gender__c != null ? primaryApplicant.Gender__c : '';
                request.resident_status = primaryApplicant != null && primaryApplicant.Residency_Status__c!= null ? primaryApplicant.Residency_Status__c : '';
                request.rm_email_id = rmEmail;
                request.am_email_id = amEmail != null ? amEmail : rmEmail;
                
                // request.elasticcrlinetype = '#'; // default to # for BL, BD will have value
                //request.elasticcrLine = (loanTransaction != null && finType == 'BD') ? true:false;
                
                request.stamping_franking = String.valueOf(Integer.valueOf(Utility.addTwoZeros(stampingFranking))); // Stamping & Franking Charges
                
                // **Handle Co-Applicants**
                request.coApplicant = new List<SanctionLetterRequestWrapper.cls_coApplicant>();
                for (Application_Applicant__c coApp : coApplicants) {
                    SanctionLetterRequestWrapper.cls_coApplicant coAppWrap = new SanctionLetterRequestWrapper.cls_coApplicant();
                    
                    String coAppcustomerId = coApp.Customer__r.SF_Customer_ID__c;
                    if(System.Test.isRunningTest()) {
                        coAppcustomerId = 'C-00000001';
                    }
                    
                    if (coAppcustomerId.startsWith('C-')) {
                        coAppcustomerId = coAppcustomerId.substring(2); // Remove the first 2 characters (C-)
                    }
                    // **Set Salutation Based on Customer Type**
                    if (coApp.Customer_Type__c == 'Individual') {
                        coAppWrap.salutation = coApp.Salutation__c != null ? coApp.Salutation__c : '';
                    } else if (coApp.Customer_Type__c == 'Non-Individual') {
                        coAppWrap.salutation = 'M/s';
                    } else {
                        coAppWrap.salutation = '';
                    }
                    
                    coAppWrap.name = coApp.Applicant_Name__c != null ? coApp.Applicant_Name__c : '';
                    coAppWrap.cif = coApp.Customer__r.Customer_LMS_Id__c != null ? coApp.Customer__r.Customer_LMS_Id__c : coAppcustomerId;
                    coAppWrap.email_address = coApp.Email__c != null ? coApp.Email__c : '';
                    coAppWrap.whatsaap_number = coApp.Mobile_Number__c != null ? coApp.Mobile_Number__c : '';
                    coAppWrap.sms_number = coApp.Mobile_Number__c != null ? coApp.Mobile_Number__c : '';
                    
                    request.coApplicant.add(coAppWrap);
                }
                
                
                // **Handle Sanction Conditions**
                request.sanctionConditions = new List<SanctionLetterRequestWrapper.cls_sanctionConditions>();
                Integer seqCounter = 1;
                for (Sanction_Condition__c condition : sanctionConditions) {
                    SanctionLetterRequestWrapper.cls_sanctionConditions sanctionWrap = new SanctionLetterRequestWrapper.cls_sanctionConditions();  
                    sanctionWrap.seqno = seqCounter;
                    sanctionWrap.sanctioncondition = condition.Condition_Name__c;
                    request.sanctionConditions.add(sanctionWrap);
                    seqCounter++;
                }
                
                request.repaymentPlanData = new List<SanctionLetterRequestWrapper.repaymentPlanData>();
                /*
if (loanTransaction != null && loanTransaction.Step_Loan__c == true){
Integer graceCounter = 1;
Integer regularCounter = 1; 
for(Loan_Transaction__c step : stepLoanRecords){
SanctionLetterRequestWrapper.RepaymentPlanData stepDetail = new SanctionLetterRequestWrapper.RepaymentPlanData();  
Boolean isGrace = (step.Step_Specifier__c != null && step.Step_Specifier__c == 'Grace');
stepDetail.installments = (Integer)step.Loan_Tenor__c;
stepDetail.step_no = isGrace ? graceCounter++ : regularCounter++;
stepDetail.stepped_emi = (Integer)step.Step_Amount__c;
stepDetail.step_specifier = (step.Step_Specifier__c != null && step.Step_Specifier__c == 'Grace') ? 'G' : 'R';
request.repaymentPlanData.add(stepDetail);
}
}*/
                /*
SanctionLetterRequestWrapper.RepaymentPlanData stepDetail = new SanctionLetterRequestWrapper.RepaymentPlanData();  
stepDetail.installments = null;
stepDetail.step_no = null;
stepDetail.stepped_emi = null;
stepDetail.step_specifier = 'R';
request.repaymentPlanData.add(stepDetail);
*/
                //request.amcDetails = new List<Object>();
                request.hlsData = new List<Object>();
                request.linkedLans = new List<SanctionLetterRequestWrapper.cls_linkedLans>();
                for (Integer i = 0; i < 1; i++) {//dummy
                    SanctionLetterRequestWrapper.cls_linkedLans linkedLoan = new SanctionLetterRequestWrapper.cls_linkedLans();
                    linkedLoan.reference = '';
                    request.linkedLans.add(linkedLoan);
                }
                
                request.collateralPropertyDetails = new List<SanctionLetterRequestWrapper.cls_collateralPropertDetails>();
                for (Application_Collateral__c col : appCollateral) {
                    SanctionLetterRequestWrapper.cls_collateralPropertDetails collateralWrap = new SanctionLetterRequestWrapper.cls_collateralPropertDetails();  
                    collateralWrap.unit = col.Collateral__r.Unit_Number__c != null ? col.Collateral__r.Unit_Number__c.toString() : '';
                    collateralWrap.floornumber = col.Collateral__r.Floor_Number__c != null ? col.Collateral__r.Floor_Number__c : '';
                    collateralWrap.tower = col.Collateral__r.Tower_Building_Name__c != null ? col.Collateral__r.Tower_Building_Name__c : '';
                    collateralWrap.project_name = col.Collateral__r.Project__c != null ? col.Collateral__r.Project__r.Name.toString() : '';     
                    
                    collateralWrap.propertyaddress1 = col.Collateral__r.Address_Line_1__c != null ? col.Collateral__r.Address_Line_1__c : '';
                    collateralWrap.propertyaddress2 = col.Collateral__r.Address_Line_2__c != null ? col.Collateral__r.Address_Line_2__c : '';
                    collateralWrap.propertyaddress3 = col.Collateral__r.Address_Line_3__c != null ? col.Collateral__r.Address_Line_3__c : '';
                    collateralWrap.landmark = col.Collateral__r.Landmark__c != null ? col.Collateral__r.Landmark__c : '';
                    collateralWrap.city = col.Collateral__r.City__c != null ? col.Collateral__r.City__c : '';
                    collateralWrap.state = col.Collateral__r.State__c != null ? col.Collateral__r.State__c : '';
                    collateralWrap.pincode = col.Collateral__r.Pincode__r.Name != null ? col.Collateral__r.Pincode__r.Name : '';
                    collateralWrap.collateral_id = col.Collateral__r.Name != null ? col.Collateral__r.Name : '';
                    collateralWrap.unittype = col.Collateral__r.Unit_Property_Type__c != null ? col.Collateral__r.Unit_Property_Type__c : '';
                    request.collateralPropertyDetails.add(collateralWrap);
                }
                
                request.repaymentSchedule = new List<Object>();
                request.subcategory = primaryApplicant != null ? primaryApplicant.Employment_Type__c : '';
                request.subproduct =  subProduct != null ? subProduct.Name : '';
                request.rmname = rmname != null ? rmname : '';
                request.rmid = rmid != null ? rmid : '';
                request.amname = amname != null ? amname : (rmname != null ? rmname : '');
                    request.amid = amid != null ? amid : (rmid != null ? rmid : '');
                        request.offemailverified = false;//need clarification 
                // request.loan_towards_selfcon = 0;//need clarification
                if (finType == 'HL' || finType == 'NHL'||finType == 'AH') {
                    request.loan_towards_selfcon = 0;
                    request.loan_towards_plot = 0;
                    request.elasticcrlinetype = '#';
                    request.isLRD = ''; 
                }
                
                request.appFormDetails = new List<SanctionLetterRequestWrapper.cls_appFormDetails>();
                request.appFormCoappDetails = new List<SanctionLetterRequestWrapper.cls_appFormCoappDetails>();
                SanctionLetterRequestWrapper.cls_appFormDetails primaryAppWrap = new SanctionLetterRequestWrapper.cls_appFormDetails(); 
                SanctionLetterRequestWrapper.cls_appFormCoappDetails coAppWrap = new SanctionLetterRequestWrapper.cls_appFormCoappDetails();  
                if(finType == 'FL'){
                    primaryAppWrap.custshrtname = primaryApplicant.Applicant_Name__c != null ? primaryApplicant.Applicant_Name__c : '';
                    primaryAppWrap.mothername = primaryApplicant.Mother_s_First_Name__c != null ? primaryApplicant.Mother_s_First_Name__c : '';
                    primaryAppWrap.fathername = primaryApplicant.Father_s_First_Name__c != null ? primaryApplicant.Father_s_First_Name__c : '';
                    primaryAppWrap.custcif = primaryApplicant.Customer__r.Customer_LMS_Id__c != null ? primaryApplicant.Customer__r.Customer_LMS_Id__c : '';
                    primaryAppWrap.dateofbirth = primaryApplicant.DOB__c != null ? formatDateString(primaryApplicant.DOB__c) : ''; //Need to check the field
                    // primaryAppWrap.dateofbirth = '';
                    primaryAppWrap.maritalstatus = primaryApplicant.Marital_Status__c != null ? primaryApplicant.Marital_Status__c : '';
                    // primaryAppWrap.countryofbirth = primaryApplicant.Country_of_Birth__c != null ? primaryApplicant.Country_of_Birth__c : ''; //Need to check the field
                    primaryAppWrap.countryofbirth = '';
                    primaryAppWrap.occupationcategory = primaryApplicant.Employment_Type__c != null ? primaryApplicant.Employment_Type__c : '';
                    primaryAppWrap.nationality = primaryApplicant.Nationality__c != null ? primaryApplicant.Nationality__c : '';
                    primaryAppWrap.gender = primaryApplicant.Gender__c != null ? primaryApplicant.Gender__c : '';
                    primaryAppWrap.pan = primaryApplicant.PAN_Number__c != null ? primaryApplicant.PAN_Number__c : '';
                    primaryAppWrap.mobile = primaryApplicant.Mobile_Number__c != null ? primaryApplicant.Mobile_Number__c : '';
                    primaryAppWrap.phonenumber = primaryApplicant.Mobile_Number__c != null ? primaryApplicant.Mobile_Number__c : '';
                    primaryAppWrap.emailid = primaryApplicant.Email__c != null ? primaryApplicant.Email__c : '';
                    primaryAppWrap.residentialstatus = primaryApplicant.Residency_Status__c != null ? primaryApplicant.Residency_Status__c : '';
                    primaryAppWrap.address = !allAddresses.isEmpty() ? allAddresses[0].Full_Address1__c : ''; //Need to check the field
                    request.appFormDetails.add(primaryAppWrap);
                    
                    if (coApplicant != null) {
                        coAppWrap.custshrtname = coApplicant.Applicant_Name__c != null ? coApplicant.Applicant_Name__c : '';
                        coAppWrap.mothername = coApplicant.Mother_s_First_Name__c != null ? coApplicant.Mother_s_First_Name__c : '';
                        coAppWrap.fathername = coApplicant.Father_s_First_Name__c != null ? coApplicant.Father_s_First_Name__c : '';
                        coAppWrap.custcif = coApplicant.Customer__r.Customer_LMS_Id__c != null ? coApplicant.Customer__r.Customer_LMS_Id__c : '';
                        coAppWrap.dateofbirth = coApplicant.DOB__c != null ? formatDateString(coApplicant.DOB__c) : ''; //Need to check the field
                        // coAppWrap.dateofbirth = '';
                        coAppWrap.maritalstatus = coApplicant.Marital_Status__c != null ? coApplicant.Marital_Status__c : '';
                        // coAppWrap.countryofbirth = coApplicant.Country_of_Birth__c != null ? coApplicant.Country_of_Birth__c : ''; //Need to check the field
                        coAppWrap.countryofbirth = '';
                        coAppWrap.occupationcategory = coApplicant.Employment_Type__c != null ? coApplicant.Employment_Type__c : '';
                        coAppWrap.nationality = coApplicant.Nationality__c != null ? coApplicant.Nationality__c : '';
                        coAppWrap.gender = coApplicant.Gender__c != null ? coApplicant.Gender__c : '';
                        coAppWrap.pan = coApplicant.PAN_Number__c != null ? coApplicant.PAN_Number__c : '';
                        coAppWrap.mobile = coApplicant.Mobile_Number__c != null ? coApplicant.Mobile_Number__c : '';
                        coAppWrap.phonenumber = coApplicant.Mobile_Number__c != null ? coApplicant.Mobile_Number__c : '';
                        coAppWrap.emailid = coApplicant.Email__c != null ? coApplicant.Email__c : '';
                        coAppWrap.residentialstatus = coApplicant.Residency_Status__c != null ? coApplicant.Residency_Status__c : '';
                        coAppWrap.address = !allAddressesCoApp.isEmpty() ? allAddressesCoApp[0].Full_Address1__c : ''; //Need to check the field
                        // coAppWrap.address = '';
                        coAppWrap.catofcoapplicant = ''; //Need to check the field
                        request.appFormCoappDetails.add(coAppWrap);
                    }
                    
                }
                // request.loan_towards_plot = 0;//need clarification
                request.fixedratetenor = 0;//need clarification //Mandatory Field if interest Type is Hybrid.For other interest Types not applicable
                // request.calterms = (loanTransaction != null && String.isNotBlank(loanTransaction.Number_of_Terms__c)) ? Integer.valueOf(loanTransaction.Number_of_Terms__c) : 0;
                request.calterms = request.numberofterms ; //(loanApplication != null && loanApplication.Sanction_Tenure__c != null) ? Integer.valueOf(loanApplication.Sanction_Tenure__c) : 0;
                request.finocrrequired = 0;//need clarification
                
                // **Convert to JSON**
                String requestJSON = JSON.serialize(request);
                System.debug('Request JSON: ' + requestJSON);
                generateSanctionLetterEvent(loanId,requestJSON,subProduct);
                return 'success';    
            }
            
        } catch (Exception e) {
            
            System.debug('Error in Construct Payload: ' + e.getMessage() +'at line number' + e.getLineNumber());
            return 'fail';
        }
    }
    
    public static void generateSanctionLetterEvent( String loanId, String payload,Product2 product){
        
        String messageWrapper = payload;
        system.debug('messageWrapper'+messageWrapper);
        String commProduct;
        Map<String, Communication_Event_Product_Mapping__mdt> productMetaMapping = Communication_Event_Product_Mapping__mdt.getAll();
        Map<String, Communication_Event_Product_Mapping__mdt> productMapping= new Map<String, Communication_Event_Product_Mapping__mdt>();
        for (Communication_Event_Product_Mapping__mdt metadata : productMetaMapping.values()){
            productMapping.put(metadata.Product_Name__c, metadata);
        }
        
        if(product.Product__r.name == 'Affordable Home Loan') {
            commProduct = 'Affordable Housing loan';
        }else if(product.Product__r.name == 'Affordable Non-Home Loan') {
            commProduct = 'Affordable LAP';
        }else if(product.Product__r.name == 'Flexi Loan') {
            commProduct = 'Flexible Loan';
        }
        else {
            commProduct= productMapping.get(product.name).Product_Field__c;
        }
        if(messageWrapper != null && messageWrapper!= ''){
            
            Integration_Details__c integration2 = new Integration_Details__c();
            integration2.name = 'Communication Event';
            integration2.Loan_Application__c = loanId;
            integration2.Endpoint__c = 'SLSF_ISL'; 
            integration2.Communication_Status__c = 'Published';
            integration2.Request_JSON__c = messageWrapper;
            integration2.Product__c = product.Id;
            insert integration2;
            
            system.debug('messageWrapper'+integration2);
            
            Communication__e event2 = new Communication__e(
                Message__c = messageWrapper,
                Record_Id__c = integration2.Id,
                Type__c = 'SLSF_ISL',
                product__c = commProduct
            );
            
            Database.SaveResult result2 = EventBus.publish(event2);
            if (result2.isSuccess()) {
                System.debug('Platform Event published successfully.'+result2);
            } else {
                // Log errors if publishing failed
                for (Database.Error error : result2.getErrors()) {
                    System.debug('Error publishing event: ' + error.getMessage());
                }
            }
        }
    }
    
    @AuraEnabled
    public static List<Integration_Details__c> getExistingSanctionLetter(String loanId) {
        List<Integration_Details__c> latestRecords = new List<Integration_Details__c>();
        
        try {
            if (String.isBlank(loanId)) {
                System.debug('⚠️ Missing LoanId');
                return latestRecords;
            }
            
            // 🔹 Step 1: Fetch all Communication Event records for this loan, ordered by CreatedDate DESC
            List<Integration_Details__c> allIntegrations = [SELECT Id, Name, Product__c, Communication_Status__c, CreatedDate FROM Integration_Details__c WHERE Name = 'Communication Event' AND Loan_Application__c = :loanId ORDER BY CreatedDate DESC];
            
            // 🔹 Step 2: Keep only the latest record per Product
            Map<Id, Integration_Details__c> productToLatestMap = new Map<Id, Integration_Details__c>();
            for (Integration_Details__c rec : allIntegrations) {
                if (!productToLatestMap.containsKey(rec.Product__c)) {
                    productToLatestMap.put(rec.Product__c, rec);
                }
            }
            
            latestRecords.addAll(productToLatestMap.values());
            System.debug('✅ Latest Integration Records: ' + latestRecords);
        } catch (Exception e) {
            System.debug('❌ Exception in getExistingSanctionLetter: ' + e.getMessage());
        }
        
        return latestRecords;
    }
    
}