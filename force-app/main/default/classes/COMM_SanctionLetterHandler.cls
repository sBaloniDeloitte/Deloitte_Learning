/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-24-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class COMM_SanctionLetterHandler implements IntegrationInterface{
    
    static String conLabels = 'Error_Loan_Application_not_found,Error_Missing_Loan_Amount,Error_Missing_SanctionTerms,Error_No_Loan_Transaction_records_found,Error_Missing_Scheduling_Method,Error_TDS_Applicable_is_not_selected,Error_Missing_Rate_Type,Error_Missing_Number_of_Grace_Terms,Error_Missing_Default_BPI_Treatment,Error_Missing_Max_Planned_EMI_Holidays,Error_Missing_Max_Holidays,Error_Missing_EMI_Holiday_Lock_Period,Error_Missing_Planned_EMI_Capitalize,Charges_API_Invocation,Term_Loan,Flexi_Funds,Over_Draft,Variant,Product,Sub_Product,Sub_Variant,Interest_Only,Hybrid_Tenure,Hybrid_Only';

    public static Map <String,String> constants = Utility.getConstants(conLabels);

    //getting the value of constants
    public static Map <String,String> getConstants() {
        return constants;
    }
    
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String loanApplicationId = wrapper.loanApplicationId;

        // Fetch Loan Application (Opportunity)
        Opportunity loanApplication = [ 
            SELECT Id,Name, Product__c,Final_Amount__c, Sanction_Tenure__c, Variant__c,Lead__r.Dsa_Area_Manager__r.email,Final_Tenure__c,Is_Pricing_Approval_Required__c
            FROM Opportunity 
            WHERE Id = :loanApplicationId 
            LIMIT 1
        ];

        if (loanApplication != null && loanApplication.Is_Pricing_Approval_Required__c == true) {
            errorMessages.add('Please complete the pricing approval process before generating sanction letter');
            return errorMessages;
        }

        // Fetch Loan Transactions
        List<Loan_Transaction__c> loanTransactions = [
            SELECT Id, Disbursement_Amount__c,Loan_Application__c,Repayment_Schedule_DateTime__c,Latest_Sanction_Generated_DateTime__c, Allow_Payment_in_Grace_Period__c,
             Schedule_Method__c, BPI_Treatment__c, Allow_Grace__c, TDS_Applicable__c, Step_Loan__c,PLR_Value__c,PLR_Code__c, 
                   Grace_Period_Frequency__c, Interest_Frequency__c, Allow_BPI__c, 
                   Allow_Planned_EMI_Holiday__c, Allow_Planned_EMI_holiday_in_Grace__c, 
                   Planned_EMI_Holiday_Method__c, 
                   Max_per_Year__c, Max__c, Lock_Period_Months__c, Capitalize__c, Rate_Type__c,Loan_Start_Date__c
            FROM Loan_Transaction__c 
            WHERE Loan_Application__c = :loanApplicationId
            AND RecordType.DeveloperName = 'Transaction_Details'
        ];

        Loan_Transaction__c loanTransaction = loanTransactions.isEmpty() ? null : loanTransactions[0];
        List<Loan_Transaction__c> stepLoanRecords = new List<Loan_Transaction__c>();
        if (loanTransaction != null && loanTransaction.Step_Loan__c == true) {
            stepLoanRecords = [
                SELECT Number_of_Steps__c, Step_Amount__c, 
                Step_Number__c, Step_Specifier__c,Tenor_Split__c,Loan_Application__r.Final_Rate_Of_Interest__c
                FROM Loan_Transaction__c
                WHERE RecordType.DeveloperName = 'Step_Loan_Details'
                AND Loan_Application__c = :loanApplicationId
            ]; 
        }
        if(!System.test.isRunningTest()){
            Datetime rpsDate = loanTransaction.Repayment_Schedule_DateTime__c!=null ? loanTransaction.Repayment_Schedule_DateTime__c : null;
            Datetime sanctionDate = loanTransaction.Latest_Sanction_Generated_DateTime__c!=null ? loanTransaction.Latest_Sanction_Generated_DateTime__c : null;
            if(rpsDate == null) {
            errorMessages.add('Please generate Repayment Schedule before proceeding with Sanction Letter');
            }
        }
        
        

        if (loanApplication == null) {
            errorMessages.add(constants.get('Error_Loan_Application_not_found ') + loanApplication.Name);
        } else {
            if (loanApplication.Final_Amount__c == null) {
                errorMessages.add(constants.get('Error_Missing_Loan_Amount'));
            }
            if (loanApplication.Sanction_Tenure__c == null) {
                errorMessages.add(constants.get('Error_Missing_SanctionTerms'));
            }
        }
    
        if (loanTransaction == null) {
            errorMessages.add(constants.get('Error_No_Loan_Transaction_records_found ') + loanApplication.Name);
        } else if(loanTransaction != null){
            if (loanTransaction.Schedule_Method__c == null) {
                errorMessages.add(constants.get('Error_Missing_Scheduling_Method'));
            }
            if (loanTransaction.TDS_Applicable__c == null) {
                errorMessages.add(constants.get('Error_TDS_Applicable_is_not_selected'));
            }
            if (loanTransaction.Rate_Type__c == null) {
                errorMessages.add(constants.get('Error_Missing_Rate_Type'));
            }
            if(loanTransaction.Step_Loan__c == true && stepLoanRecords.isEmpty()){
                errorMessages.add('Applicable Step Loan Details are missing');
            }
            if(loanTransaction.Loan_Start_Date__c == null){
                errorMessages.add('Loan Start Date is not populated.');
            }
        }
    
        // **Validate Conditional Mandatory (CM) Fields**
        if (loanTransaction != null) {
            if (loanTransaction.Allow_Grace__c == true) {
                if (loanTransaction.Grace_Period_Frequency__c == null) {
                    errorMessages.add(constants.get('Error_Missing_Number_of_Grace_Terms'));
                }
            }
    
            if (loanTransaction.Allow_BPI__c == true) {
                if (loanTransaction.BPI_Treatment__c == null) {
                    errorMessages.add(constants.get('Error_Missing_Default_BPI_Treatment'));
                }
            }
    
            // if (loanTransaction.Allow_Planned_EMI_Holiday__c == true) {
            //     if (loanTransaction.Max_per_Year__c == null) {
            //         errorMessages.add(constants.get('Error_Missing_Max_Planned_EMI_Holidays'));
            //     }
            //     if (loanTransaction.Max__c == null) {
            //         errorMessages.add(constants.get('Error_Missing_Max_Holidays'));
            //     }
            //     if (loanTransaction.Lock_Period_Months__c == null) {
            //         errorMessages.add(constants.get('Error_Missing_EMI_Holiday_Lock_Period'));
            //     }
            //     if (loanTransaction.Capitalize__c == false) {
            //         errorMessages.add(constants.get('Error_Missing_Planned_EMI_Capitalize'));
            //     }
            // }
        }
    
        return errorMessages;
        //validate the payload here
    }
    
    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
            String loanApplicationId = wrapper.loanApplicationId;        
            // Fetch all metadata records at once
            Map<String, Default_Values_LoanSchedule_API__mdt> defaultValuesMap = Default_Values_LoanSchedule_API__mdt.getAll();
            //Added By Prachi for HL
             Map<String,String> inputMapUtility = new  Map<String,String>{'oppId' =>loanApplicationId };
            Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.getProductDetails(inputMapUtility);
            Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
            system.debug('wrapper:: '+defaultValuesMap);
            // Create a map for easy access where Attribute__c is the key and Value__c is the value
            Map<String, String> defaultValues = new Map<String, String>();

            for (Default_Values_LoanSchedule_API__mdt metadataRecord : defaultValuesMap.values()) {
                String value = metadataRecord.Value__c != null ? metadataRecord.Value__c : '';
                defaultValues.put(metadataRecord.Attribute__c, value);
            }
            
            // **Bulk Query: Fetch Loan Application (Opportunity)**
            List<Opportunity> loanApplications = [
                SELECT Id, Product__c,Name, Final_Amount__c, Sanction_Tenure__c, Branch_Master__c, Branch_Master__r.Branch_Code__c,
                Variant__c,Final_Rate_Of_Interest__c, Loan_Purpose__c,Tenor_Months__c,Final_Tenure__c,APR__c,Lead__c,Lead__r.Dsa_Area_Manager__r.email,Loan_Hierarchy__c,Split_Parent_Loan_Application__c,
                Dsa_Area_Manager__c,Dsa_Area_Manager__r.Employee_Id__c,Dsa_Area_Manager__r.Name, Dsa_Area_Manager__r.Email
                FROM Opportunity 
                WHERE Id = :loanApplicationId
            ];
            Opportunity loanApplication = loanApplications.isEmpty() ? null : loanApplications[0];

            String requiredLoanId = loanApplicationId;
            Boolean isParentLoan = false;
            String productType = 'Parent';
            if(loanApplication.Loan_Hierarchy__c == 'Child' && loanApplication.Split_Parent_Loan_Application__c != null){
                requiredLoanId = loanApplication.Split_Parent_Loan_Application__c;
                productType = 'Child';
            }
            else if(loanApplication.Loan_Hierarchy__c == 'Parent'){
                isParentLoan = true;
            } 

    
            // **Bulk Query: Fetch Loan Transactions**
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
    
            // **Fetch Primary Application Applicant**
            List<Application_Applicant__c> applicants = [
                SELECT Id, Name, First_Name__c, Last_Name__c,Customer_Profile__c,Customer__r.SF_Customer_ID__c, Applicant_Name__c,Mobile_Number__c, Email__c, Salutation__c, Customer__r.Customer_LMS_Id__c, Nationality__c,
                Customer_Type__c, Gender__c, Residency_Status__c,Employment_Type__c, Mother_s_First_Name__c, Father_s_First_Name__c, DOB__c, Marital_Status__c, PAN_Number__c,Preferred_Language__c
                FROM Application_Applicant__c
                WHERE Loan_Application__c = :requiredLoanId
                AND Applicant_Type__c = 'Primary Applicant'
            ];
            
            Application_Applicant__c primaryApplicant = applicants.isEmpty() ? null : applicants[0];
            String primarycustomerId = '';
            if (primaryApplicant != null && primaryApplicant.Customer__r != null && primaryApplicant.Customer__r.SF_Customer_ID__c != null) {
                primarycustomerId = primaryApplicant.Customer__r.SF_Customer_ID__c;
                if (String.isNotBlank(primarycustomerId) && primarycustomerId.startsWith('C-')) {
                    primarycustomerId = primarycustomerId.substring(2); // Remove the first 2 characters (C-)
                }
            }
            // **Fetch Co Application Applicant**
            List<Application_Applicant__c> coapplicants = [
                SELECT Id, Name, First_Name__c, Customer__r.SF_Customer_ID__c,Customer_Profile__c,Last_Name__c,Applicant_Name__c,Mobile_Number__c, Email__c, Salutation__c, Customer__r.Customer_LMS_Id__c, 
                Customer_Type__c, Gender__c,Nationality__c, Preferred_Language__c,Residency_Status__c,Employment_Type__c, Mother_s_First_Name__c, Father_s_First_Name__c, DOB__c, Marital_Status__c, PAN_Number__c
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
                SELECT Id, Full_Address1__c, Address_Priority__c 
                FROM Applicant_Address__c
                WHERE Applicant__r.Loan_Application__c =: requiredLoanId And Applicant__c =: primaryApplicant.Id And Address_Line_1__c != '' And (Address_Priority__c = '5' OR Address_Priority__c= '4')
            ];

            List<Applicant_Address__c> allAddressesCoApp = new List<Applicant_Address__c>();
            if (coApplicant != null) {
                allAddressesCoApp = [
                SELECT Id, Full_Address1__c, Address_Priority__c 
                FROM Applicant_Address__c
                WHERE Applicant__r.Loan_Application__c =: requiredLoanId And Applicant__c =: coApplicant.Id And Address_Line_1__c != '' And (Address_Priority__c = '5' OR Address_Priority__c= '4')
            ];
            }
            

            // Map<String, Applicant_Address__c> addressMap = new Map<String, Applicant_Address__c>();
            // for (Applicant_Address__c addr : allAddresses) {
            //     if (!addressMap.containsKey(addr.Address_Type__c)) {
            //         addressMap.put(addr.Address_Type__c, addr);
            //     }
            // }

            // if (addressMap.containsKey('Permanent')) {
            //     applicantAddress.add(addressMap.get('Permanent'));
            // } else if (addressMap.containsKey('Current')) {
            //     applicantAddress.add(addressMap.get('Current'));
            // } else if (addressMap.containsKey('Office')) {
            //     applicantAddress.add(addressMap.get('Office'));
            // }

            // List<String> addressStrings = new List<String>();
            // for (Applicant_Address__c addr : applicantAddress) {
            //     if (String.isNotBlank(addr.Full_Address__c)) {
            //         addressStrings.add(addr.Full_Address__c);
            //     }
            // }
            // String fullAddress = String.join(addressStrings, ', ');

             // Fetch Product2 record based on the Loan Application's Product & Sub Product
            String loanPurposeProd = '';
            String transactionTypeProd = '';
            Product2 mainProduct;
            if(isParentLoan){
                mainProduct =[SELECT Id,Product_Master__r.PLF_Loan_Type__c from Product2 WHERE RecordType.Name = :constants.get('Product') AND Name = :loanApplication.Product__c AND Loan_Application__c = :loanApplicationId AND Product_Type__c  = 'Parent' LIMIT 1];
            }
            else{
                mainProduct =[SELECT Id,Product_Master__r.PLF_Loan_Type__c from Product2 WHERE RecordType.Name = :constants.get('Product') AND Name = :loanApplication.Product__c AND Loan_Application__c = :loanApplicationId LIMIT 1];
            }
            Product2 subProduct = [SELECT Id,Name,Product_Master__r.PLF_Loan_Type__c from Product2 WHERE RecordType.Name = :constants.get('Sub_Product') AND Product__c =:mainProduct.Id AND Loan_Application__c = :loanApplicationId LIMIT 1];
                for(Product2 itrProd : [SELECT Id,Name,RecordType.Name FROM Product2 WHERE RecordType.Name IN ('Transaction Type','Loan Purpose') AND Product__c =:subProduct.Id]){
                    if(itrProd.RecordType.Name == 'Transaction Type'){
                        transactionTypeProd = itrProd.Name;
                    }
                    else if(itrProd.RecordType.Name == 'Loan Purpose'){
                        loanPurposeProd = itrProd.Name;
                    }
                }
            List<PLF_Master__c> plfMasterRecs = [SElECT FICO_Code__c FROM PLF_Master__c WHERE Description__c = :loanPurposeProd AND Transaction_Type__c = :transactionTypeProd LIMIT 1];
            
            List<string> prodVariantAndSubVariant = new List<string>();
            prodVariantAndSubVariant.add(constants.get('Variant'));
            prodVariantAndSubVariant.add(constants.get('Sub_Variant'));

            List<Product2> productRecords = [
                SELECT Id, Name, RecordType.Name, PLR_Code__c, 
                PLR_Value__c, BPI_Interest_Days_Basis__c, Interest_Days_Basis__c 
                FROM Product2 
                WHERE Loan_Application__c = :wrapper.loanApplicationId 
                AND RecordType.Name In : prodVariantAndSubVariant AND Product__c = :subProduct.Id
            ];

            Map<String, Communication_Event_Product_Mapping__mdt> productMetaMapping = Communication_Event_Product_Mapping__mdt.getAll();
            Map<String, Communication_Event_Product_Mapping__mdt> productMapping= new Map<String, Communication_Event_Product_Mapping__mdt>();
            for (Communication_Event_Product_Mapping__mdt metadata : productMetaMapping.values()){
                productMapping.put(metadata.Product_Name__c, metadata);
            }
            String finType = isHlRelated ? (String.isNotBlank(Utility_V1.returnFintypeFromTransactionTypeProduct(subProduct.Id)) ? Utility_V1.returnFintypeFromTransactionTypeProduct(subProduct.Id) : '')/*subProduct.Product_Master__r.PLF_Loan_Type__c*/ : mainProduct.Product_Master__r.PLF_Loan_Type__c;
            String productName = '';
            String profitDaysBasis = '';
            String bpiProfitDaysBasis = '';
            String plrCode = '';
            Decimal plrValue = 0;
            string subVariantPrd = '';
            List<Product2> hybridTenure;

            if(isHlRelated){
                productName =productMapping.get(subProduct.name).Product_Field__c;
            }else if(!isHlRelated){
                productName = loanApplication.Product__c;
            }
            for (Product2 prod : productRecords) {
                if(prod.RecordType.Name == constants.get('Variant')){
                        profitDaysBasis = prod.Interest_Days_Basis__c != null ? prod.Interest_Days_Basis__c : '30E/360I';
                        bpiProfitDaysBasis = prod.BPI_Interest_Days_Basis__c != null ? prod.BPI_Interest_Days_Basis__c : '30E/360I';
                        plrCode = prod.PLR_Code__c != null ? prod.PLR_Code__c : 'GHFPLR';
                        plrValue = prod.PLR_Value__c != null ? prod.PLR_Value__c : 18.31;
                        
                        
                }
                else if(prod.RecordType.Name == constants.get('Sub_Variant')){
                        subVariantPrd = prod.Name;
                        hybridTenure = [Select Id, Name from Product2 Where Loan_Application__c = :wrapper.loanApplicationId 
                                        And Sub_Variant__c =: prod.Id And RecordType.Name =: constants.get('Hybrid_Tenure')];
                }
            }
            if(!isHlRelated){
                plrCode = loanTransaction.PLR_Code__c !=null ? loanTransaction.PLR_Code__c : String.valueOf(Label.Plr_Code);
                plrValue = loanTransaction.PLR_Value__c !=null ? loanTransaction.PLR_Value__c : Decimal.valueOf(Label.Plr_Value);
            }
            List<Product2> subProductForTenureRoiAmountFromProduct = new List<Product2>();
            if(productType =='Child'){
                subProductForTenureRoiAmountFromProduct = [SELECT Id,Name,Final_ROI__c,Final_Tenure__c,Sanctioned_Tenor__c, Final_Loan_Amount__c from Product2 WHERE RecordType.Name = :constants.get('Sub_Product') AND Product__r.Name = :loanApplication.Product__c  AND Product__r.Product_Type__c = 'Child' AND Loan_Application__c = :loanApplicationId LIMIT 1];
            }
            else{
                subProductForTenureRoiAmountFromProduct = [SELECT Id,Name,Final_ROI__c,Final_Tenure__c,Sanctioned_Tenor__c, Final_Loan_Amount__c from Product2 WHERE RecordType.Name = :constants.get('Sub_Product') AND Product__r.Name = :loanApplication.Product__c  AND Product__r.Product_Type__c = 'Parent' AND Loan_Application__c = :loanApplicationId LIMIT 1];
            }
            List<Product2> subProductDetails = [SELECT Id,Name,Loan_Purpose__c from Product2 WHERE RecordType.Name = :constants.get('Sub_Product') AND Product__r.Name = :loanApplication.Product__c  AND Product__r.Product_Type__c =: productType AND Loan_Application__c = :requiredLoanId LIMIT 1];

            List<Sanction_Condition__c> sanctionConditions= new List<Sanction_Condition__c>();
            if(isHlRelated){
                sanctionConditions = [SELECT Id, Name, Condition_Name__c, Condition_Approval__c, Loan_Application__c FROM Sanction_Condition__c 
                                                                WHERE Loan_Application__c = :loanApplicationId //changing with the multiprod change 24-06 > in consent with Alika and Aditya
                                                                // AND Condition_Approval__c IN ('Pending', 'OTC' , 'PDD' ) 
                                                                AND HL_Related_Product__r.Name = :loanApplication.Product__c]; //Condition_Approval__c = 'Pending'
            }else{
                sanctionConditions = [SELECT Id, Name, Condition_Name__c, Condition_Approval__c, Loan_Application__c FROM Sanction_Condition__c 
                                                                WHERE Loan_Application__c = :requiredLoanId AND Condition_Approval__c IN ('Pending', 'OTC' , 'PDD' )]; //Condition_Approval__c = 'Pending'
            }
            

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
            if(repaymentAccounts != null && !repaymentAccounts.isEmpty()){
                selectedAccount = repaymentAccounts[0];   
            }else{
                selectedAccount = null;
            }
            
            List<Charges_Insurance__c> charges = [SELECT Id, recordtype.name, Name,
            Final_Amount_INR__c,Charges_Fee_Type__c,Requested_Amount_INR__c,Category__c,
             Allocated_Amount__c, Requested_Percentage__c, Balance_Fees__c,Paid_Orginal__c,Paid_Amount_Gst__c 
             FROM Charges_Insurance__c WHERE Loan_Application__c = :requiredLoanId AND recordtype.name = 'Charges' AND Product_Name__c = :loanApplication.Product__c AND Product__r.Product_Type__c =: productType] ; 
            // **Fetch Sales Manager's Email from Opportunity Team Members**
            List<OpportunityTeamMember> oppTeamMembers = [
                SELECT User.Email,User.Name,User.Employee_Id__c, User.Manager.Email,User.Manager.Name,User.Manager.Employee_Id__c,TeamMemberRole, Associated_With_Loan_Application__c
                FROM OpportunityTeamMember 
                WHERE OpportunityId = :loanApplicationId
            ];
            String rmEmail = '';
            String amEmail = '';
            String rmname = '';
            String rmid = '';
            String amname = '';
            String amid = '';
            String timestamp = Datetime.now().format('yyyy-MM-dd HH:mm:ss.SSS');
            String stepFlag = loanTransaction != null && loanTransaction.Step_Loan__c ? '1' : '0';
            String frequencyCode =  (loanTransaction.Interest_Frequency__c  != null )? loanTransaction.Interest_Frequency__c:'M';
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
            String dueDateCode =  (loanTransaction.Interest_Due_date__c  != null )? loanTransaction.Interest_Due_date__c:'03';
            
            String mmCode = '00'; // Default MM for Monthly

            if (frequencyCode == 'Y') {
                mmCode = (loanTransaction.Yearly_Selection__c != null) ? loanTransaction.Yearly_Selection__c : '01';
            } else if (frequencyCode == 'H') {
                mmCode = (loanTransaction.Half_Yearly_Selection__c != null) ? loanTransaction.Half_Yearly_Selection__c : '01';
            } else if (frequencyCode == 'Q') {
                mmCode = (loanTransaction.Quarterly_Selection__c != null) ? loanTransaction.Quarterly_Selection__c : '01';
            }
            // M already defaulted to '00'

            String finalFrequencyCode = frequencyCode + mmCode + dueDateCode;
            System.debug('Final Frequency Code: ' + finalFrequencyCode);

            // NOT BEING USED >> Integer sanctionTenure = loanApplication.Final_Tenure__c != null ? Integer.valueOf(loanApplication.Final_Tenure__c) : Integer.valueOf(loanApplication.Sanction_Tenure__c);
            // Integer graceFreq = hybridTenure != null ? Integer.valueOf(hybridTenure[0].name) : 0;
            Integer graceFreq = loanTransaction.Grace_Period_Frequency__c != null ? Integer.valueOf(loanTransaction.Grace_Period_Frequency__c) : 0;

            List<Loan_Transaction__c> stepLoanRecords = new List<Loan_Transaction__c>();
            Integer noOfSteps = 0;
            Integer noOfGrcSteps = 0;
            if (loanTransaction != null && loanTransaction.Step_Loan__c == true) {
                stepLoanRecords = [
                    SELECT Number_of_Steps__c, Step_Amount__c,Margin__c,Auto_Cal__c,
                    Step_Number__c, Step_Specifier__c,
                    Tenor_Split__c,Loan_Application__r.Final_Rate_Of_Interest__c,Loan_Tenor__c
                    FROM Loan_Transaction__c
                    WHERE RecordType.DeveloperName = 'Step_Loan_Details' 
                    AND Loan_Application__c = :wrapper.loanApplicationId Order by Step_Number__c ASC
                ]; 
                for (Loan_Transaction__c step : stepLoanRecords) {
                    
                    if (step.Step_Specifier__c != null && step.Step_Specifier__c == 'Grace') {
                        noOfGrcSteps++;
                    }
                    else if(step.Step_Specifier__c != null && step.Step_Specifier__c !='Grace') { //as per create finance
                        noOfSteps++;
                    }
                }
            }    

            if(!isHlRelated){
            rmEmail = loanApplication.Dsa_Area_Manager__c != null ? loanApplication.Dsa_Area_Manager__r.Email : (String.isNotBlank(loanApplication.Dsa_Area_Manager__r.Email) ? loanApplication.Dsa_Area_Manager__r.Email : '');
            rmname  = loanApplication.Dsa_Area_Manager__c != null ? loanApplication.Dsa_Area_Manager__r.Name : (String.isNotBlank(loanApplication.Dsa_Area_Manager__r.Name) ? loanApplication.Dsa_Area_Manager__r.Name : '');
            rmid    = loanApplication.Dsa_Area_Manager__c != null ? loanApplication.Dsa_Area_Manager__r.Employee_Id__c : (String.isNotBlank(loanApplication.Dsa_Area_Manager__r.Employee_Id__c) ? loanApplication.Dsa_Area_Manager__r.Employee_Id__c : '');
            amEmail = loanApplication.Dsa_Area_Manager__c != null ? loanApplication.Dsa_Area_Manager__r.Email : (String.isNotBlank(loanApplication.Dsa_Area_Manager__r.Email) ? loanApplication.Dsa_Area_Manager__r.Email : '');
            amname  = loanApplication.Dsa_Area_Manager__c != null ? loanApplication.Dsa_Area_Manager__r.Name : (String.isNotBlank(loanApplication.Dsa_Area_Manager__r.Name) ? loanApplication.Dsa_Area_Manager__r.Name : '');
            amid    = loanApplication.Dsa_Area_Manager__c != null ? loanApplication.Dsa_Area_Manager__r.Employee_Id__c : (String.isNotBlank(loanApplication.Dsa_Area_Manager__r.Employee_Id__c) ? loanApplication.Dsa_Area_Manager__r.Employee_Id__c : '');
            }else if(isHlRelated){
                for (OpportunityTeamMember teamMember : oppTeamMembers) {
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
            if(loanTransaction != null && loanTransaction.Allow_Grace__c == true){
                allowGrace = true;
            }
            if(loanTransaction != null && loanTransaction.Allow_Planned_EMI_Holiday__c == true){
                allowPlannedEMI = true;
            }

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
            request.typeOfLoan = (productName == 'Affordable Home Loan') ? 'Affordable Housing Loan' : productName;/*'Term -> Business Loan' Flexi -> Business Loan Flexi Funds;*/
            request.step_finance = stepFlag;
            request.cif = primaryApplicant != null && primaryApplicant.Customer__r.Customer_LMS_Id__c != null? primaryApplicant.Customer__r.Customer_LMS_Id__c : primarycustomerId;
            // request.isLRD = ''; 
            request.name = primaryApplicant != null ? primaryApplicant.Applicant_Name__c : '';
            request.custfirstname = primaryApplicant != null ? primaryApplicant.First_Name__c : '';
            request.custlastname = primaryApplicant != null ? primaryApplicant.Last_Name__c : '';

            if(isHlRelated){
                if(primaryApplicant != null && primaryApplicant.Customer_Profile__c!= 'Salaried NRI'){
                    for(Applicant_Address__c address: allAddresses){
                        if(address.Address_Priority__c== '5'){
                            request.custaddr1 = address.Full_Address1__c;
            request.custaddr2 = '';
            request.custaddr3 = '';
                            break;
                        }
                    }
                }else if(primaryApplicant != null && primaryApplicant.Customer_Profile__c== 'Salaried NRI'){
                    for(Applicant_Address__c address: allAddresses){
                        if(address.Address_Priority__c== '4'){
                            request.custaddr1 = address.Full_Address1__c;
                            request.custaddr2 = '';
                            request.custaddr3 = '';
                            break;
                        }
                    }
                }
            }else{
                for(Applicant_Address__c address: allAddresses){
                    if(address.Address_Priority__c== '5'){
                        request.custaddr1 = address.Full_Address1__c;
                        request.custaddr2 = '';
                        request.custaddr3 = '';
                        break;
                    }
                }
            }
            
            

            request.finStartDate = formatDateString(loanTransaction.Loan_Start_Date__c);
            
            //request.date_of_disbursal = plfDate != null ? DateTime.newInstance(plfDate, Time.newInstance(0, 0, 0, 0)).formatGmt('yyyy-MM-dd HH:mm:ss') : '';
            request.date_of_disbursal = plfDate != null ? plfDate.toString() : '';
            //request.loan_amount = loanApplication != null && loanTransaction.First_Disbursement_Amount__c!= null ? Integer.valueOf(Utility.addTwoZeros(loanTransaction.First_Disbursement_Amount__c)) : 0;
            Integer sanctionTenure = 0;
            if(loanApplication.Loan_Hierarchy__c == 'Child' && loanApplication.Split_Parent_Loan_Application__c != null){
                if(isHlRelated){
                    if(subProductForTenureRoiAmountFromProduct.size() > 0){
                        request.rate_of_interest = subProductForTenureRoiAmountFromProduct[0].Final_ROI__c;
                        request.loan_amount = loanTransaction != null ? Utility.addTwoZeros(loanTransaction.First_Disbursement_Amount__c).longValue() : 0;
                        request.finassetvalue = subProductForTenureRoiAmountFromProduct[0].Final_Loan_Amount__c != null ? Utility.addTwoZeros(subProductForTenureRoiAmountFromProduct[0].Final_Loan_Amount__c).longValue() : 0;
                        sanctionTenure = subProductForTenureRoiAmountFromProduct[0].Final_Tenure__c != null ? Integer.valueOf(subProductForTenureRoiAmountFromProduct[0].Final_Tenure__c) : Integer.valueOf(subProductForTenureRoiAmountFromProduct[0].Sanctioned_Tenor__c);
                    }
                }else{
                 request.rate_of_interest = loanApplication != null ? loanApplication.Final_Rate_Of_Interest__c : 0;
                 request.loan_amount = loanTransaction != null && loanTransaction.First_Disbursement_Amount__c!= null ? Utility.addTwoZeros(loanTransaction.First_Disbursement_Amount__c).longValue() : 0;
                 request.finassetvalue = loanTransaction != null && loanApplication.Final_Amount__c!= null ? Utility.addTwoZeros(loanApplication.Final_Amount__c).longValue(): 0;
                 sanctionTenure = loanApplication.Final_Tenure__c != null ? Integer.valueOf(loanApplication.Final_Tenure__c) : Integer.valueOf(loanApplication.Sanction_Tenure__c);
                }
            }
            else{ 
                if(subProductForTenureRoiAmountFromProduct.size() > 0){
                    request.rate_of_interest = subProductForTenureRoiAmountFromProduct[0].Final_ROI__c;
                    request.loan_amount = loanTransaction != null ? Utility.addTwoZeros(loanTransaction.First_Disbursement_Amount__c).longValue() : 0;
                    request.finassetvalue = subProductForTenureRoiAmountFromProduct[0].Final_Loan_Amount__c != null ? Utility.addTwoZeros(subProductForTenureRoiAmountFromProduct[0].Final_Loan_Amount__c).longValue() : 0;
                    sanctionTenure = subProductForTenureRoiAmountFromProduct[0].Final_Tenure__c != null ? Integer.valueOf(subProductForTenureRoiAmountFromProduct[0].Final_Tenure__c) : Integer.valueOf(subProductForTenureRoiAmountFromProduct[0].Sanctioned_Tenor__c);
                }
                else{
                  request.rate_of_interest = 0;
                  request.loan_amount = 0;
                  request.finassetvalue = 0;
                }
            }
            request.type_of_interest = 'Fixed Rate';
            request.ghplr = String.valueOf(plrValue);
            system.debug('loanTransaction.Margin__c:: '+loanTransaction.Margin__c + ' plrValue:: '+plrValue+ ' subtraction:: '+Integer.valueOf(loanTransaction.Margin__c - plrValue));
            request.margin = (loanTransaction != null && plrValue != null) ? loanTransaction.Margin__c - plrValue :0;
            request.languagePreferred = primaryApplicant != null ? primaryApplicant.Preferred_Language__c : '';
            request.stepup_pre_emi_tenor = 0;
            request.bank_name = selectedAccount!= null && selectedAccount.Name != null ? selectedAccount.Name : ''; 
            request.acc_number = selectedAccount!= null && selectedAccount.Account_Number__c != null ? selectedAccount.Account_Number__c:'';
            //request.total_tenor = loanApplication != null ? Integer.valueOf(loanApplication.Final_Tenure__c) : 0;
           
            // **Insurance Charges - Fetch Total VAS Amount**
            Decimal insuranceCharges = 0;
            Decimal amcCharges = 0;
            Decimal processingFee = 0;
            Decimal finalProcessingFee = 0;
            Decimal stampingFranking = 0;

            for (Charges_Insurance__c charge : charges) {
                if (charge.Category__c == 'Insurance' && charge.Final_Amount_INR__c != null) {
                    insuranceCharges += charge.Final_Amount_INR__c;
                }
                else if(charge.Category__c == 'LMS') {
                    if(charge.Name == 'LOSAMC' && charge.Requested_Percentage__c != null){
                        amcCharges += charge.Requested_Percentage__c;
                    }
                }
                else if(charge.Category__c == 'LOS') {
                    if (charge.Name == 'PROCFEE'){
                        if (charge.Name == 'PROCFEE' && charge.Allocated_Amount__c != null) {
                            processingFee += charge.Allocated_Amount__c;
                        }
                        
                        if(isHlRelated){
                            if (charge.Name == 'PROCFEE' && charge.Final_Amount_INR__c != null) {
                                finalProcessingFee = charge.Final_Amount_INR__c;
                            }
                        }
                    }
                    else if (charge.Name == 'STFRCHG' && charge.Allocated_Amount__c != null) {
                        stampingFranking += charge.Allocated_Amount__c;//Sanwar - 27-11-2025
                    }
                }
            }
            if(!isHlRelated){
                if(processingFee > 0){//Sanwar - 27-11-2025 -Start
                    finalProcessingFee = (processingFee + ((processingFee * 18)/100)).setScale(0, RoundingMode.HALF_UP);
                }//Sanwar - 27-11-2025 -End
            }

            if (loanTransaction.Allow_Grace__c == true) {
                request.total_tenor = sanctionTenure;
                request.full_emi_tenor = sanctionTenure - graceFreq;
            }
            else {
                request.total_tenor = sanctionTenure;
                request.full_emi_tenor = sanctionTenure;
            }

            system.debug('request.full_emi_tenor: '+request.full_emi_tenor);

            request.moratorium_tenor = 0;
            // request.pemii_tenor = 0;
            if (finType == 'AH' || finType =='HL') {
                request.pemii_tenor = 0;
            }
            //request.full_emi_tenor = loanApplication != null ? Integer.valueOf(loanApplication.Final_Tenure__c) : 0/*240*/; 
            // request.holiday_tenor = 0;
            if (finType == 'AH' || finType =='HL') {
                request.holiday_tenor = 0;
            }
            request.repayment_mode = loanTransaction != null ? loanTransaction.Payment_Method__c : '';
            //request.additional_product = ''; // Default
            if(isHlRelated){
                request.end_use_of_loan = String.isNotBlank(loanPurposeProd) ? loanPurposeProd : '';
            } else{
                request.end_use_of_loan = subProductDetails[0].Loan_Purpose__c != null ? subProductDetails[0].Loan_Purpose__c:'Business Expansion';
            }
            // request.end_use_of_loan = String.isNotBlank(loanPurposeProd) ? loanPurposeProd : '';//Mapping changed >> subProductDetails[0].Loan_Purpose__c != null ? subProductDetails[0].Loan_Purpose__c:'Business Expansion';
            request.stepfinance = loanTransaction != null && loanTransaction.Step_Loan__c ? 'TRUE': 'FALSE';
            request.finisactive = 1;
            request.repaybaserate = /*'GFLPLRBL';*/plrCode;//productmaster
            request.grcpftfrq = (loanTransaction != null && allowGrace == true) ? finalFrequencyCode:'';
            request.grcpftrvwfrq = (loanTransaction != null && allowGrace == true) ? finalFrequencyCode : '';
            request.grccpzfrq = (loanTransaction != null && allowGrace == true && loanTransaction.Capitalize__c == true && loanTransaction.Step_Loan__c == false) ? /*frequencyCode + dueDateCode*/finalFrequencyCode : '';
            request.allow_bpi = (loanTransaction != null) ? Boolean.valueOf(loanTransaction.Allow_BPI__c) : false;
            request.alwBpiTreatment = (loanTransaction != null) ? Boolean.valueOf(loanTransaction.Allow_BPI__c) : false;
            request.bpitreatment = loanTransaction != null && loanTransaction.Allow_BPI__c == true && String.isNotEmpty(loanTransaction.BPI_Treatment__c)?loanTransaction.BPI_Treatment__c:'N';
            request.allowgrcrepay = (loanTransaction != null && allowGrace == true) ? loanTransaction.Allow_Payment_in_Grace_Period__c : false;
            request.grcratebasis = (loanTransaction != null && allowGrace == true) ? loanTransaction.Rate_Type__c:'R';
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
            request.grcmargin = (loanTransaction != null && allowGrace == true) ? loanTransaction.Margin__c - plrValue : 0;
            request.grcminrate = (defaultValues.containsKey('grcMinRate') && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcMinRate')) : 0;
            request.grcmaxrate = (defaultValues.containsKey('grcMaxRate') && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcMaxRate')) : 0;
            request.grcmaxamount = (defaultValues.containsKey('grcMaxAmount') && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcMaxAmount')) : 0;
            request.grcadvpftrate = (defaultValues.containsKey('grcAdvPftRate') && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcAdvPftRate')) : 0;
            request.grcadvmargin = (defaultValues.containsKey('grcAdvMargin') && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcAdvMargin')) : 0;
            request.alwgrcadj = false;
            request.gracebaserate = ((loanTransaction != null) && allowGrace == true) ? plrCode: 'GHFPLR'; 
            request.schedulemethod = loanTransaction != null && loanTransaction.Step_Loan__c == true ? loanTransaction.Schedule_Method__c : 'EQUAL';
            request.profitdaysbasis = profitDaysBasis;
            request.bpipftdaysbasis = bpiProfitDaysBasis;
            request.finrepaypftonfrq = false; //new field on loan transaction
            request.frequency = (loanTransaction != null ) ? finalFrequencyCode:'';
            request.instalment_frequency = instalmentFrequency;
            
            if (loanTransaction.Allow_Grace__c == true) {
                request.numberofterms = sanctionTenure - graceFreq;
            } else {
                request.numberofterms = sanctionTenure;
            }
            system.debug('request.numberofterms: '+request.numberofterms);

            request.insurance_charges = Integer.valueOf(Utility.addTwoZeros(insuranceCharges));
            request.other_charges = 0;
            request.apr = loanApplication.APR__c != null ? loanApplication.APR__c : (defaultValues.containsKey('apr') ? Decimal.valueOf(defaultValues.get('apr')) : 16.622373624);
            
            request.processing_fee = Integer.valueOf(Utility.addTwoZeros(processingFee));
            request.fintype = finType;
            request.interestperiod = 0;
            request.sanction_withdrawal_amt = '';/*null (if API throws error then pass final amount)"sanction_withdrawal_amt":"1000000000" check with null again*/
            request.product_variant = '';
            request.noOfSteps = noOfSteps;//added by Arman on 9th Jan 2026 for SFHL-858
            request.noOfGrcSteps = noOfGrcSteps; //added by Arman on 9th Jan 2026 for SFHL-858
            request.alwManualSteps = (loanTransaction != null && loanTransaction.Step_Loan__c) ? true : false; // //added by Arman on 9th Jan 2026 for SFHL-858
            request.feetypeid = 1;
                 request.processingfee = Integer.valueOf(Utility.addTwoZeros(finalProcessingFee)); // Final Processing Fee Amount
            request.custresidentialsts = /*primaryApplicant != null ? primaryApplicant.Residency_Status__c : ''*/'';
            request.finPurpose = (plfMasterRecs.size()>0 && plfMasterRecs[0].FICO_Code__c != null) ? plfMasterRecs[0].FICO_Code__c : '';
            request.allowgrcperiod = (loanTransaction != null && loanTransaction.Allow_Grace__c) ? 1 : 0;
            request.allow_grcperiod = (loanTransaction != null && loanTransaction.Allow_Grace__c != null) ? loanTransaction.Allow_Grace__c : false;
            
            request.grcschdmthd = (loanTransaction != null && loanTransaction.Allow_Grace__c && loanTransaction.Payment_Method_Grace_Parameter__c != null) ? loanTransaction.Payment_Method_Grace_Parameter__c : '';
            request.branch_code = loanApplication.Branch_Master__r.Branch_Code__c!=null ?loanApplication.Branch_Master__r.Branch_Code__c:'3002';
            request.gender = primaryApplicant != null && primaryApplicant.Gender__c != null ? primaryApplicant.Gender__c : '';
            request.resident_status = primaryApplicant != null && primaryApplicant.Residency_Status__c!= null ? primaryApplicant.Residency_Status__c : '';
            request.rm_email_id = rmEmail;
            request.am_email_id = amEmail;
            /*if(isHlRelated){
                request.rm_email_id = rmEmail;
                request.am_email_id = amEmail;
            }else{
                request.rm_email_id = '';//rmEmail'';
                request.am_email_id = loanApplication.Lead__r.Dsa_Area_Manager__r.email != null ? loanApplication.Lead__r.Dsa_Area_Manager__r.email : '';
            }*/

            // request.elasticcrlinetype = '#'; // default to # for BL, BD will have value
            //request.elasticcrLine = (loanTransaction != null && finType == 'BD') ? true:false;
            
            request.stamping_franking = String.valueOf(Integer.valueOf(Utility.addTwoZeros(stampingFranking))); // Stamping & Franking Charges
            
            // **Handle Co-Applicants**
            request.coApplicant = new List<SanctionLetterRequestWrapper.cls_coApplicant>();
            for (Application_Applicant__c coApp : coApplicants) {
                SanctionLetterRequestWrapper.cls_coApplicant coAppWrap = new SanctionLetterRequestWrapper.cls_coApplicant();
            
                String coAppcustomerId = coApp.Customer__r.SF_Customer_ID__c;
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
            request.step = new List<SanctionLetterRequestWrapper.Step>();
            if (loanTransaction != null && loanTransaction.Step_Loan__c == true){
                Integer graceCounter = 1;
                Integer regularCounter = 1; 
                for(Loan_Transaction__c step : stepLoanRecords){
                    SanctionLetterRequestWrapper.RepaymentPlanData stepDetail = new SanctionLetterRequestWrapper.RepaymentPlanData();  
                    Boolean isGrace = (step.Step_Specifier__c != null && step.Step_Specifier__c == 'Grace');
                    stepDetail.step_no = isGrace ? graceCounter++ : regularCounter++;
                    stepDetail.installments = (Integer)step.Loan_Tenor__c;
                    stepDetail.stepped_emi = step.Step_Amount__c!=null ? Utility.addTwoZeros(step.Step_Amount__c) : 0 ;
                    stepDetail.step_specifier = (step.Step_Specifier__c != null && step.Step_Specifier__c == 'Grace') ? 'G' : 'R';
                    request.repaymentPlanData.add(stepDetail);
                }
                /////////step array
                Integer graceCounterStep = 1;
                Integer regularCounterStep = 1; 
                Integer stepNumberAutoCal = 0;
                Decimal tenorSplitSum = 0.00;
                Decimal margin = 0.00;
                for (Loan_Transaction__c step : stepLoanRecords) {
                    SanctionLetterRequestWrapper.Step stepDetail = new SanctionLetterRequestWrapper.Step();
                    // Determine if step is Grace or Regular
                    Boolean isGrace = (step.Step_Specifier__c != null && step.Step_Specifier__c == 'Grace');
                    stepDetail.stepNumber = isGrace ? graceCounterStep++ : regularCounterStep++;
                    stepDetail.tenorSplitPerc = step.Tenor_Split__c.setScale(2)  ?? 0.00;
                    stepDetail.rateMargin = step.Margin__c!=null ? step.Margin__c : 0;
                    stepDetail.emiSplitPerc = 0;
                    stepDetail.steppedEMI = step.Step_Amount__c!=null ? Utility.addTwoZeros(step.Step_Amount__c) : 0 ;
                    stepDetail.stepSpecifier = step.Step_Specifier__c == 'Grace' ? 'G': 'R';
                    stepDetail.autoCal = (step.Auto_Cal__c ? 1 :0);
                    stepDetail.installments = step.Loan_Tenor__c;
                    stepNumberAutoCal = (Integer)stepDetail.stepNumber; //Armani : to assign the last tenot split
                    tenorSplitSum += step.Tenor_Split__c.setScale(2);
                    margin = stepDetail.rateMargin; //the last valuw will get assigned>> putting this till logic for margin comes for the last step
                    request.step.add(stepDetail);
                }

                Decimal totalStepInstallments = 0;
                for (SanctionLetterRequestWrapper.step s : request.step) {
                    if (s.installments != null) {
                        totalStepInstallments += s.installments;
                    }
                }
                System.debug('Total step Installments: ' + totalStepInstallments);

                if (totalStepInstallments < sanctionTenure) { //loanRequest.financeDetail.numberOfTerms) { //this is coming from application right now >> Armani
                    SanctionLetterRequestWrapper.Step stepDetail = new SanctionLetterRequestWrapper.Step();
                    stepDetail.stepNumber = regularCounter++;
                    stepDetail.tenorSplitPerc = 100.00 - tenorSplitSum;
                    stepDetail.rateMargin = margin;
                    stepDetail.emiSplitPerc = 0;
                    stepDetail.steppedEMI = Utility.addTwoZeros(0);
                    stepDetail.stepSpecifier = 'R'; 
                    stepDetail.autoCal = 0;
                    stepDetail.installments = sanctionTenure - totalStepInstallments; //removing grace frequenccy for the last installment loanRequest.financeDetail.numberOfTerms
                    request.step.add(stepDetail);
                    request.noOfSteps = noOfSteps + 1;
                }
            }

            //request.amcDetails = new List<Object>();
            request.hlsData = new List<Object>();
            request.linkedLans = new List<SanctionLetterRequestWrapper.cls_linkedLans>();
           /* for (Integer i = 0; i < 1; i++) {//dummy removing till the point linkedLoans come
                SanctionLetterRequestWrapper.cls_linkedLans linkedLoan = new SanctionLetterRequestWrapper.cls_linkedLans();
                linkedLoan.reference = '';
                request.linkedLans.add(linkedLoan);
            }*/

            if(finType != 'FL'){
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
            }

            request.repaymentSchedule = new List<Object>();
            // request.subcategory = primaryApplicant != null ? primaryApplicant.Employment_Type__c : '';
            if(primaryApplicant != null && primaryApplicant.Customer_Type__c == 'Individual'){
                if(primaryApplicant.Customer_Profile__c == 'Salaried Indian​' || primaryApplicant.Customer_Profile__c == 'Salaried NRI'){
                    request.subCategory = 'SALARIED';
                }
                else{
                    request.subCategory = primaryApplicant.Customer_Profile__c.toUpperCase(); 
                }
            }else {
                request.subCategory = '';
            }
            
            request.subproduct =  subProduct != null ? subProduct.Name : '';
            request.rmname = rmname != null ? rmname : '';
            request.rmid = rmid != null ? rmid : '';
            request.amname = amname != null ? amname : '';
            request.amid = amid != null ? amid : '';
            request.offemailverified = false;//need clarification 
            // request.loan_towards_selfcon = 0;//need clarification
            if (finType == 'AH' || finType =='HL') {
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
                if(isHlRelated){
                    if(primaryApplicant != null && primaryApplicant.Customer_Profile__c!= 'Salaried NRI'){
                        for(Applicant_Address__c address: allAddresses){
                            if(address.Address_Priority__c== '5'){
                                primaryAppWrap.address = address.Full_Address1__c;
                                break;
                            }
                        }
                    }else if(primaryApplicant != null && primaryApplicant.Customer_Profile__c== 'Salaried NRI'){
                        for(Applicant_Address__c address: allAddresses){
                            if(address.Address_Priority__c== '4'){
                                primaryAppWrap.address = address.Full_Address1__c;
                                break;
                            }
                        }
                    }
                }else{
                    for(Applicant_Address__c address: allAddresses){
                        if(address.Address_Priority__c== '5'){
                            primaryAppWrap.address = address.Full_Address1__c;
                            break;
                        }
                    }
                }
                
                // primaryAppWrap.address = !allAddresses.isEmpty() ? allAddresses[0].Full_Address1__c : ''; //Need to check the field
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
                    if(isHlRelated){
                        if(coApplicant != null && coApplicant.Customer_Profile__c!= 'Salaried NRI'){
                            for(Applicant_Address__c address: allAddressesCoApp){
                                if(address.Address_Priority__c== '5'){
                                    coAppWrap.address = address.Full_Address1__c ;
                                    break;
                                }
                            }
                        }else if(coApplicant != null && coApplicant.Customer_Profile__c== 'Salaried NRI'){
                            for(Applicant_Address__c address: allAddressesCoApp){
                                if(address.Address_Priority__c== '4'){
                                    coAppWrap.address = address.Full_Address1__c ;
                                    break;
                                }
                            }
                        }
                    }else{
                        for(Applicant_Address__c address: allAddressesCoApp){
                            if(address.Address_Priority__c== '5'){
                                coAppWrap.address = address.Full_Address1__c ;
                                break;
                            }
                        }
                    }
                    
                    // coAppWrap.address = !allAddressesCoApp.isEmpty() ? allAddressesCoApp[0].Full_Address1__c : ''; //Need to check the field
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
            return requestJSON;
    
        } catch (Exception e) {
            System.debug('Sanctionletterhandler-> ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            return 'ERROR: '+e.getStackTraceString();
            //throw new AuraHandledException('Error: ' + e.getMessage() + ' at line ' + e.getLineNumber() + ' | ' + e.getStackTraceString());
        }
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
}