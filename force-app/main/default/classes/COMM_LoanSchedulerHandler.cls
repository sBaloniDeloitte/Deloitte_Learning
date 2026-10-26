public with sharing class COMM_LoanSchedulerHandler implements IntegrationInterface {
    static String conLabels = 'Error_Loan_Application_not_found,Error_Missing_Loan_Amount,Error_Missing_SanctionTerms,Error_No_Loan_Transaction_records_found,Error_Missing_Scheduling_Method,Error_TDS_Applicable_is_not_selected,Error_Missing_Rate_Type,Error_Missing_Number_of_Grace_Terms,Error_Missing_Default_BPI_Treatment,Error_Missing_Max_Planned_EMI_Holidays,Error_Missing_Max_Holidays,Error_Missing_EMI_Holiday_Lock_Period,Error_Missing_Planned_EMI_Capitalize,Charges_API_Invocation,Term_Loan,Flexi_Funds,Over_Draft,Variant,Sub_Variant,Product,Sub_Product,Interest_Only,Hybrid_Tenure,Hybrid_Only';

    public static Map <String,String> constants = Utility.getConstants(conLabels);

    //getting the value of constants
    public static Map <String,String> getConstants() {
        return constants;
    }

    // **Validation Method**
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
       
        List<String> errorMessages = new List<String>();
        String loanApplicationId = wrapper.loanApplicationId;
        String invocationType = wrapper.loanSchedulerInvocationType;
    
        // Fetch Loan Application (Opportunity)
        Opportunity loanApplication = [ 
            SELECT Id, Product__c,StageName,Final_Amount__c, Sanction_Tenure__c, Variant__c,Final_Tenure__c, Loan_Purpose__c
            FROM Opportunity 
            WHERE Id = :loanApplicationId 
            LIMIT 1
        ];
    
        // Fetch Loan Transactions
        List<Loan_Transaction__c> loanTransactions = [
            SELECT Id, Disbursement_Amount__c, Allow_Payment_in_Grace_Period__c, Schedule_Method__c, 
                   BPI_Treatment__c, Allow_Grace__c, TDS_Applicable__c, Step_Loan__c, 
                   Grace_Period_Frequency__c, Interest_Frequency__c, Allow_BPI__c, 
                   Allow_Planned_EMI_Holiday__c, Allow_Planned_Principal_Holiday__c,Allow_Planned_EMI_holiday_in_Grace__c, 
                   Planned_EMI_Holiday_Method__c, Max_per_Year__c, Max__c, 
                   Lock_Period_Months__c, Capitalize__c, Rate_Type__c,First_Disbursement_Amount__c,Elastic_Credit_Line_Type__c,
                   Half_Yearly_Selection__c,Yearly_Selection__c,Quarterly_Selection__c,Pure_Tenure__c,Dropline_Tenure__c,Interest_Due_date__c,
                   Dropline_Calculated_On__c,Payment_Method__c,Loan_Start_Date__c,Planned_EMI_Holiday_Month__c,Planned_Principal_Holiday_Method__c,
                   Planned_Principal_Holiday_Month__c,Max_per_Year_Principal_Holiday_Parameter__c,Max_Principal_Holiday_Parameter__c,Lock_Period_Principal_Holiday_Paramters__c
            FROM Loan_Transaction__c 
            WHERE Loan_Application__c = :loanApplicationId
            AND RecordType.DeveloperName = 'Transaction_Details'
        ];
        
        Loan_Transaction__c loanTransaction = loanTransactions.isEmpty() ? null : loanTransactions[0];
        // Product2 mainProduct =[SELECT Id from Product2 WHERE RecordType.Name = :constants.get('Product') AND Name = :loanApplication.Product__c AND Loan_Application__c = :wrapper.loanApplicationId LIMIT 1];
        // Product2 subProduct = [SELECT Id from Product2 WHERE RecordType.Name = :constants.get('Sub_Product') AND Product__c =:mainProduct.Id AND Loan_Application__c = :wrapper.loanApplicationId LIMIT 1];
        
        // List<string> prodVariantAndSubVariant = new List<string>();
        // prodVariantAndSubVariant.add(constants.get('Variant'));
        // prodVariantAndSubVariant.add(constants.get('Sub_Variant'));

        // List<Product2> productRecords = [
        //     SELECT Id, Name, RecordType.Name, PLR_Code__c, 
        //     PLR_Value__c, BPI_Interest_Days_Basis__c, Interest_Days_Basis__c 
        //     FROM Product2 
        //     WHERE Loan_Application__c = :wrapper.loanApplicationId 
        //     AND RecordType.Name In : prodVariantAndSubVariant AND Product__c = :subProduct.Id
        // ];
        Decimal graceTermCount = 0.00;
        List<Loan_Transaction__c> stepLoanRecords = new List<Loan_Transaction__c>();
        if (loanTransaction != null && loanTransaction.Step_Loan__c == true) {
            stepLoanRecords = [
                SELECT Number_of_Steps__c, Step_Amount__c, Margin__c,Loan_Tenor__c,
                Step_Number__c, Step_Specifier__c,Tenor_Split__c,Loan_Application__r.Final_Rate_Of_Interest__c
                FROM Loan_Transaction__c
                WHERE RecordType.DeveloperName = 'Step_Loan_Details'
                AND Loan_Application__c = :loanApplicationId AND Related_Transaction__c!=null/* AND IsActive__c=true Commenting this as no such filter*/
            ]; 
            for(Loan_Transaction__c step : stepLoanRecords){
                if(step.Step_Specifier__c == 'Grace'){
                    graceTermCount+= step.Loan_Tenor__c;
                }
            }
        }

        // **Validate Mandatory (M) Fields**
        String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1].Name;
        if(loanApplication.StageName != 'Sales login' && profileName!= 'System Administrator'){
        if (loanApplication == null) {
            errorMessages.add(constants.get('Error_Loan_Application_not_found') + loanApplicationId);
        } else {
            if (loanApplication.Final_Amount__c == null) {
                errorMessages.add(constants.get('Error_Missing_Loan_Amount'));
            }
            if (  loanApplication.Sanction_Tenure__c == null ) {
                errorMessages.add(constants.get('Error_Missing_SanctionTerms'));
            }
        }
    
        if (loanTransaction == null) {
            errorMessages.add(constants.get('Error_No_Loan_Transaction_records_found') + loanApplicationId);
        } 
        else if(loanTransaction != null && invocationType == 'RepaymentLWC'){
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
            if(loanTransaction.First_Disbursement_Amount__c == null){
                errorMessages.add('First Disbursement Amount is not populated.');
            }
            if(loanTransaction.Interest_Frequency__c == null){
                errorMessages.add('Missing Interest Frequency');
            }
            if(loanTransaction.Interest_Frequency__c != null){
                if(loanTransaction.Interest_Due_date__c == null){
                    errorMessages.add('Missing Due Date');
                }
                if(loanTransaction.Interest_Frequency__c == 'H' && loanTransaction.Half_Yearly_Selection__c == null){
                    errorMessages.add('Missing Half Yearly Month Selection');
                }
                if(loanTransaction.Interest_Frequency__c == 'Q' && loanTransaction.Quarterly_Selection__c == null){
                    errorMessages.add('Missing Quarterly Month Selection');
                }
                if(loanTransaction.Interest_Frequency__c == 'Y' && loanTransaction.Yearly_Selection__c == null){
                    errorMessages.add('Missing Yearly Month Selection');
                }
            }
            if(loanTransaction.Payment_Method__c == null){
                errorMessages.add('Payment Method is missing!');
            }
            if(loanTransaction.Loan_Start_Date__c == null){
                errorMessages.add('Loan Start Date is missing!');
            }
        }
    
        // **Validate Conditional Mandatory (CM) Fields**
        if (loanTransaction != null && invocationType == 'RepaymentLWC') {
            if (loanTransaction.Allow_Grace__c == true) {
                if (loanTransaction.Grace_Period_Frequency__c == null) {
                    errorMessages.add(constants.get('Error_Missing_Number_of_Grace_Terms'));
                }
                if(loanTransaction.Grace_Period_Frequency__c!=null && loanTransaction.Step_Loan__c == true && loanTransaction.Grace_Period_Frequency__c != graceTermCount){
                    errorMessages.add('Grace Period Terms in Transactional Details and the Step Tenure sum in Grace Steps is not matching');
                }
            }
            
    
            if (loanTransaction.Allow_BPI__c == true) {
                if (loanTransaction.BPI_Treatment__c == null) {
                    errorMessages.add(constants.get('Error_Missing_Default_BPI_Treatment'));
                }
            }
    
            if (loanTransaction.Allow_Planned_EMI_Holiday__c == true) {
                if (loanTransaction.Max_per_Year__c == null) {
                    errorMessages.add(constants.get('Error_Missing_Max_Planned_EMI_Holidays'));
                }
                if (loanTransaction.Max__c == null) {
                    errorMessages.add(constants.get('Error_Missing_Max_Holidays'));
                }
                if (loanTransaction.Lock_Period_Months__c == null) {
                    errorMessages.add(constants.get('Error_Missing_EMI_Holiday_Lock_Period'));
                }
                if (loanTransaction.Planned_EMI_Holiday_Method__c == null) {
                    errorMessages.add('Missing Planned EMI Holiday Method');
                }
                if (loanTransaction.Planned_EMI_Holiday_Method__c == 'F' && loanTransaction.Planned_EMI_Holiday_Month__c == null) {
                    errorMessages.add('Missing Planned EMI Holiday Months');
                }
            }
            if (loanTransaction.Allow_Planned_Principal_Holiday__c == true) {
                if (loanTransaction.Max_per_Year_Principal_Holiday_Parameter__c == null) {
                    errorMessages.add('Missing Max Planned Principal Holidays');
                }
                if (loanTransaction.Max_Principal_Holiday_Parameter__c == null) {
                    errorMessages.add(constants.get('Error_Missing_Max_Holidays'));
                }
                if (loanTransaction.Lock_Period_Principal_Holiday_Paramters__c == null) {
                    errorMessages.add('Missing Principal Holiday Lock Period');
                }
                if (loanTransaction.Planned_Principal_Holiday_Method__c == null) {
                    errorMessages.add('Missing Planned Principal Holiday Method');
                }
                if (loanTransaction.Planned_Principal_Holiday_Method__c == 'Frequency' && loanTransaction.Planned_Principal_Holiday_Month__c == null) {
                    errorMessages.add('Missing Planned Principal Holiday Months');
                }
            }
        }
        }
    
        return errorMessages;
    }
    

    // **Construct Payload Method**
    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
            system.debug('wrapper:: '+wrapper);
             Loan_Transaction__c loanTransaction;
            String frequencyCode;
            String dueDateCode ;
            String mmCode ;
           Integer sanctionTenure = 0;
           Product2 mainProduct;
            //Added By Prachi for HL
           Map<String,String> inputMapUtility = new  Map<String,String>();
            inputMapUtility.put('oppId',wrapper.loanApplicationId );
            Utility_V1.ProductWrapper wrp = Utility_V1.getProductDetails(inputMapUtility);
            Boolean isHLRelated = wrp.isHLRelated;
            system.debug('206---'+wrp.isHLRelated);
            Map<String, Default_Values_LoanSchedule_API__mdt> defaultValuesMap = Default_Values_LoanSchedule_API__mdt.getAll();
            Map<String, Map<String, String>> mapMasterCode =  COMM_UpsertCustomerHandler.getMasterCode(); //Arman : 19-11-2025 : adding to handle PLF master mapping

            system.debug('wrapper:: '+defaultValuesMap);
            // Create a map for easy access where Attribute__c is the key and Value__c is the value
            Map<String, String> defaultValues = new Map<String, String>();

            for (Default_Values_LoanSchedule_API__mdt metadataRecord : defaultValuesMap.values()) {
                String value = metadataRecord.Value__c != null ? metadataRecord.Value__c : '';
                defaultValues.put(metadataRecord.Attribute__c, value);
            }

            String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1].Name;

            // Fetch Loan Application (Opportunity)
            Opportunity loanApplication = [ 
                SELECT Id, Product__c,Requested_Amount__c,Loan_Hierarchy__c,Split_Parent_Loan_Application__c, StageName,Final_Amount__c, Sanction_Tenure__c, Branch_Master__c, Branch_Master__r.Branch_Code__c,Variant__c,Final_Tenure__c,Loan_Purpose__c 
                FROM Opportunity 
                WHERE Id = :wrapper.loanApplicationId 
                LIMIT 1
            ];
            system.debug('wrapper:: '+loanApplication);
            String requiredLoanId = wrapper.loanApplicationId;
            Boolean isParentLoan = false;
            String productType = 'Parent';
            if(loanApplication.Loan_Hierarchy__c == 'Child' && loanApplication.Split_Parent_Loan_Application__c != null){
                requiredLoanId = loanApplication.Split_Parent_Loan_Application__c;
                productType = 'Child';
            }
            else if(loanApplication.Loan_Hierarchy__c == 'Parent'){
                isParentLoan = true;
            } 
            List<Product2> subProductForParent = [SELECT Id,Name,Final_ROI__c,Final_Tenure__c,Sanctioned_Tenor__c, Final_Loan_Amount__c from Product2 WHERE 
            RecordType.Name = 'Sub Product' AND Product__r.Name = :loanApplication.Product__c  AND Product__r.Product_Type__c = 'Parent' AND Loan_Application__c = :wrapper.loanApplicationId  LIMIT 1];

            // Query Opportunity Team Members to find the first Sales Manager
            List<OpportunityTeamMember> teamMembers = [
                SELECT Name, TeamMemberRole 
                FROM OpportunityTeamMember 
                WHERE OpportunityId = :wrapper.loanApplicationId 
                AND TeamMemberRole = 'Sales Manager'
                LIMIT 1
            ];
			
            // Fetch Product2 record based on the Loan Application's Product & Sub Product
            if(wrapper.loanSchedulerInvocationType == constants.get('Charges_API_Invocation')){
                mainProduct =[SELECT Id,Product_Master__r.PLF_Loan_Type__c from Product2 WHERE RecordType.Name = 'Product' AND Id = :wrapper.productName  AND Loan_Application__c = :loanApplication.Id LIMIT 1];
            }
            else{
                if(isParentLoan){
                    mainProduct =[SELECT Id,Product_Master__r.PLF_Loan_Type__c from Product2 WHERE RecordType.Name = :constants.get('Product') AND Name = :loanApplication.Product__c AND Loan_Application__c = :wrapper.loanApplicationId AND Product_Type__c  = 'Parent' LIMIT 1];
                }
                else{
                    mainProduct =[SELECT Id,Product_Master__r.PLF_Loan_Type__c from Product2 WHERE RecordType.Name = :constants.get('Product') AND Name = :loanApplication.Product__c AND Loan_Application__c = :wrapper.loanApplicationId LIMIT 1];
                }
            }
            Product2 subProduct = [SELECT Id,Product_Master__r.PLF_Loan_Type__c, Product__r.Product_Type__c from Product2 WHERE RecordType.Name = 'Sub Product' AND Product__c =:mainProduct.Id AND Loan_Application__c = :loanApplication.Id LIMIT 1];
            system.debug('subProduct247--'+subProduct.Product_Master__r.PLF_Loan_Type__c);
            List<string> prodVariantAndSubVariant = new List<string>();
            prodVariantAndSubVariant.add(constants.get('Variant'));
            prodVariantAndSubVariant.add(constants.get('Sub_Variant'));

            String loanPurposeProd = '';
            String transactionTypeProd = '';
            for(Product2 itrProd : [SELECT Id,Name,RecordType.Name FROM Product2 WHERE RecordType.Name IN ('Transaction Type','Loan Purpose') AND Product__c =:subProduct.Id]){
                if(itrProd.RecordType.Name == 'Transaction Type'){
                    transactionTypeProd = itrProd.Name;
                }
                else if(itrProd.RecordType.Name == 'Loan Purpose'){
                    loanPurposeProd = itrProd.Name;
                }
            }
            List<PLF_Master__c> plfMasterRecs = [SElECT FICO_Code__c FROM PLF_Master__c WHERE Description__c = :loanPurposeProd AND Transaction_Type__c = :transactionTypeProd LIMIT 1];
            List<Product2> productRecords = [
                SELECT Id, Name, RecordType.Name, PLR_Code__c, 
                PLR_Value__c, BPI_Interest_Days_Basis__c, Interest_Days_Basis__c 
                FROM Product2 
                WHERE Loan_Application__c = :wrapper.loanApplicationId 
                AND RecordType.Name In : prodVariantAndSubVariant AND Product__c = :subProduct.Id
            ];
            System.debug('subProduct'+subProduct);
            System.debug('subProduct.Product_Master__r'+subProduct.Product_Master__c);
            System.debug('subProduct.Product_Master__r.PLF_Loan_Type__c'+subProduct.Product_Master__r.PLF_Loan_Type__c);
            String finType = isHlRelated ==true ? (String.isNotBlank(Utility_V1.returnFintypeFromTransactionTypeProduct(subProduct.Id)) ? Utility_V1.returnFintypeFromTransactionTypeProduct(subProduct.Id) : '') /*subProduct.Product_Master__r.PLF_Loan_Type__c*/ : mainProduct.Product_Master__r.PLF_Loan_Type__c;
            system.debug('261-FinType--'+finType);
            String profitDaysBasis = '';
            String bpiProfitDaysBasis = '';
            String plrCode = '';
            Decimal plrValue = 0;
            string subVariantPrd = '';
            List<Product2> hybridTenure;

            for (Product2 prod : productRecords) {
                if(prod.RecordType.Name == constants.get('Variant')){
                        profitDaysBasis = prod.Interest_Days_Basis__c != null ? prod.Interest_Days_Basis__c : '30E/360I';
                        bpiProfitDaysBasis = prod.BPI_Interest_Days_Basis__c != null ? prod.BPI_Interest_Days_Basis__c : '30E/360I';
                        plrCode = prod.PLR_Code__c != null ? prod.PLR_Code__c : 'GHFPLR';
                        plrValue = prod.PLR_Value__c != null ? prod.PLR_Value__c : 17.25;
                }
                else if(prod.RecordType.Name == constants.get('Sub_Variant')){
                        subVariantPrd = prod.Name;
                        hybridTenure = [Select Id, Name from Product2 Where Loan_Application__c = :wrapper.loanApplicationId 
                                        And Sub_Variant__c =: prod.Id And RecordType.Name =: constants.get('Hybrid_Tenure')];
                }
            }

            if(loanApplication.StageName != 'Sales login' && profileName!= 'System Administrator'){
            // Fetch Loan Transaction records for given Loan Application
            List<Loan_Transaction__c> loanTransactions = [
                SELECT Id, Disbursement_Amount__c, Allow_Payment_in_Grace_Period__c, Schedule_Method__c, 
                       BPI_Treatment__c, Allow_Grace__c, TDS_Applicable__c, Step_Loan__c, 
                       Grace_Period_Frequency__c, Interest_Frequency__c, Allow_BPI__c, 
                       Allow_Planned_EMI_Holiday__c, Allow_Planned_EMI_holiday_in_Grace__c,Interest_Due_date__c, 
                       Planned_EMI_Holiday_Method__c, Max_per_Year__c, Max__c, Lock_Period_Months__c, 
                       Capitalize__c,Rate_Type__c,Margin__c, Grace_Base_Rate_Code__c, Next_First_Payment_Date__c,
                       First_Disbursement_Amount__c,Payment_Method_Grace_Parameter__c,
                       Elastic_Credit_Line_Type__c,Dropline_Calculated_On__c,Pure_Tenure__c,Loan_Start_Date__c,
                       Dropline_Tenure__c,Yearly_Selection__c,Half_Yearly_Selection__c,Quarterly_Selection__c,
                       Planned_Principal_Holiday_Month__c,Planned_EMI_Holiday_Month__c,Allow_Planned_Principal_Holiday__c,
                       Planned_Principal_Holiday_Method__c,Max_Principal_Holiday_Parameter__c,Max_per_Year_Principal_Holiday_Parameter__c,
                       Lock_Period_Principal_Holiday_Paramters__c,PLR_Code__c,PLR_Value__c
                    //    Planned_EMI_Holiday_Year__c,Planned_Principal_Holiday_Year__c,
                FROM Loan_Transaction__c 
                WHERE Loan_Application__c = :wrapper.loanApplicationId
                AND RecordType.DeveloperName = 'Transaction_Details'
            ];

            // Use first Loan Transaction record (assuming there will always be at least one)
            loanTransaction = loanTransactions.isEmpty() ? null : loanTransactions[0];            
             frequencyCode = (loanTransaction.Interest_Frequency__c  != null ) ? loanTransaction.Interest_Frequency__c : 'M';
             dueDateCode = (loanTransaction.Interest_Due_date__c  != null ) ? loanTransaction.Interest_Due_date__c : '03';
             mmCode = '00'; // Default MM for Monthl
            }
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

            Integer noOfSteps = 0;
            Integer noOfGrcSteps = 0;
            List<Loan_Transaction__c> stepLoanRecords = new List<Loan_Transaction__c>();
            if (loanTransaction != null && loanTransaction.Step_Loan__c == true) {
                stepLoanRecords = [SELECT Number_of_Steps__c, Step_Amount__c,Auto_Cal__c, Margin__c , Step_Number__c, Step_Specifier__c, Tenor_Split__c,Loan_Application__r.Final_Rate_Of_Interest__c,Loan_Tenor__c
                FROM Loan_Transaction__c WHERE RecordType.DeveloperName = 'Step_Loan_Details' AND Loan_Application__c = :wrapper.loanApplicationId  AND Related_Transaction__c!=null ORDER BY Step_Number__c ASC];
                for (Loan_Transaction__c step : stepLoanRecords) {
                    if (step.Step_Specifier__c != null && step.Step_Specifier__c == 'Grace') {
                        noOfGrcSteps++;
                    }
                    if (step.Step_Specifier__c != null && step.Step_Specifier__c !='Grace') { //as per create finance
                        noOfSteps++;
                    }
                }
            }
            
            
            Boolean allowGrace = false;
            Boolean allowPlannedEMI = false;
            Boolean allowPlannedPrincipal = false;
            if(loanTransaction != null && loanTransaction.Allow_Grace__c == true){
                allowGrace = true;
            }
            if(loanTransaction != null && loanTransaction.Allow_Planned_EMI_Holiday__c == true){
                allowPlannedEMI = true;
            }
            if(loanTransaction != null && loanTransaction.Allow_Planned_Principal_Holiday__c == true){
                allowPlannedPrincipal = true;
            }
            

            // Instantiate Wrapper Object
            LoanRequestWrapper loanRequest = new LoanRequestWrapper();
            loanRequest.finReference = null;
            loanRequest.financeDetail = new FinanceDetail();
            loanRequest.financeDetail.advEMITerms = defaultValues.containsKey('advEMITerms') && String.isNotBlank(defaultValues.get('advEMITerms')) ? Integer.valueof(defaultValues.get('advEMITerms')) : 0;
            //loanRequest.financeDetail.allowGrcPeriod = loanTransaction != null ? loanTransaction.Allow_Grace__c : false;

            if(wrapper.loanSchedulerInvocationType == constants.get('Charges_API_Invocation')){
                if(subVariantPrd == constants.get('Interest_Only')){
                    loanRequest.financeDetail.allowGrcPeriod = true;
                }
                else {
                    loanRequest.financeDetail.allowGrcRepay = false;
                }
            }
            else{
                if(subVariantPrd == constants.get('Interest_Only')){
                    loanRequest.financeDetail.allowGrcPeriod = true;
                }
                else {
                    loanRequest.financeDetail.allowGrcPeriod = loanTransaction != null ? loanTransaction.Allow_Grace__c : false;    
                }
                
                //loanRequest.financeDetail.allowGrcPeriod = finType == 'BD' ? true : (loanTransaction != null ? loanTransaction.Allow_Grace__c : false);
                loanRequest.financeDetail.allowGrcRepay = (loanTransaction != null && allowGrace == true) ? loanTransaction.Allow_Payment_in_Grace_Period__c : false;
                loanRequest.financeDetail.finStartDate = (loanTransaction != null && loanTransaction.Loan_Start_Date__c!= null) ? formatDateString(loanTransaction.Loan_Start_Date__c): '';
            }

            loanRequest.financeDetail.alwBpiTreatment = (loanTransaction != null) ? loanTransaction.Allow_BPI__c : false;
            loanRequest.financeDetail.alwGrcAdj = defaultValues.containsKey('alwGrcAdj') && String.isNotBlank(defaultValues.get('alwGrcAdj')) ? Boolean.valueOf(defaultValues.get('alwGrcAdj')) : false;
            if(wrapper.loanSchedulerInvocationType == constants.get('Charges_API_Invocation')){
                loanRequest.financeDetail.alwManualSteps =  false;
            }else{
                loanRequest.financeDetail.alwManualSteps = (loanTransaction != null && loanTransaction.Step_Loan__c) ? true:false;
            }
            loanRequest.financeDetail.bpiPftDaysBasis = bpiProfitDaysBasis;
            loanRequest.financeDetail.cif = ''; // Fetch dynamically if available
            loanRequest.financeDetail.depreciationFrq = defaultValues.containsKey('depreciationFrq') ? defaultValues.get('depreciationFrq') : '';
            loanRequest.financeDetail.dftBpiTreatment = loanTransaction != null && loanTransaction.Allow_BPI__c == true && String.isNotEmpty(loanTransaction.BPI_Treatment__c)?loanTransaction.BPI_Treatment__c:'N';
            loanRequest.financeDetail.eligibilityMethod = defaultValues.containsKey('eligibilityMethod') && String.isNotBlank(defaultValues.get('eligibilityMethod')) ? Integer.valueof(defaultValues.get('eligibilityMethod')) : 0;
            loanRequest.financeDetail.employeeName = !teamMembers.isEmpty() ? teamMembers[0].Name : '';
            if(wrapper.loanSchedulerInvocationType == constants.get('Charges_API_Invocation')){
                if(loanApplication.StageName == 'Sales login' || profileName== 'System Administrator'){
                     loanRequest.financeDetail.finAssetValue = (loanApplication.Requested_Amount__c != null) ? Utility.addTwoZeros(loanApplication.Requested_Amount__c) : 0;
                     loanRequest.financeDetail.finAmount = (loanApplication.Requested_Amount__c != null) ? Utility.addTwoZeros(loanApplication.Requested_Amount__c) : 0;
                }
                else if((loanApplication.StageName == 'PSV' || loanApplication.StageName == 'Disbursement')){
                     loanRequest.financeDetail.finAssetValue = (loanTransaction != null) ? Utility.addTwoZeros(wrapper.sanctionLoanAmount) : 0;
                     loanRequest.financeDetail.finAmount = (loanTransaction != null) ? Utility.addTwoZeros(wrapper.sanctionLoanAmount) : 0;
                }
            }else{
                loanRequest.financeDetail.finAssetValue = (loanTransaction != null) ? Utility.addTwoZeros(loanApplication.Final_Amount__c) : 0; 
                loanRequest.financeDetail.finAmount = (loanTransaction != null) ? Utility.addTwoZeros(loanTransaction.First_Disbursement_Amount__c) : 0; 
            }

            loanRequest.financeDetail.finBranch = /*loanApplication.Branch_Master__r.Branch_Code__c*/ '';
            loanRequest.financeDetail.finCcy = defaultValues.containsKey('finCcy') ? defaultValues.get('finCcy') : 'INR';
            loanRequest.financeDetail.finCommitmentRef = defaultValues.containsKey('finCommitmentRef') ? defaultValues.get('finCommitmentRef') : '';
            loanRequest.financeDetail.finLimitRef = defaultValues.containsKey('finLimitRef') ? defaultValues.get('finLimitRef') : '';
            loanRequest.financeDetail.finPurpose = plfMasterRecs.size()>0 ? plfMasterRecs[0].FICO_Code__c : ''; //loanApplication.Loan_Purpose__c != null ? mapMasterCode.get('Loan Purpose'.toLowerCase()).get(loanApplication.Loan_Purpose__c.toLowerCase()) : '' ;    
            loanRequest.financeDetail.finType = finType;
            loanRequest.financeDetail.fixedRateTenor = defaultValues.containsKey('fixedRateTenor') && String.isNotBlank(defaultValues.get('fixedRateTenor')) ? Integer.valueof(defaultValues.get('fixedRateTenor')) : 0; //was diff in SL >>
            loanRequest.financeDetail.fixedTenorRate = defaultValues.containsKey('fixedTenorRate') && String.isNotBlank(defaultValues.get('fixedTenorRate')) ? Integer.valueof(defaultValues.get('fixedTenorRate')) : 0;
            loanRequest.financeDetail.increasedCost = defaultValues.containsKey('increasedCost') && String.isNotBlank(defaultValues.get('increasedCost')) ? Integer.valueOf(defaultValues.get('increasedCost')) : 0;
            loanRequest.financeDetail.legalRequired = defaultValues.containsKey('legalRequired') && String.isNotBlank(defaultValues.get('legalRequired')) ? Boolean.valueOf(defaultValues.get('legalRequired')) : false;
            loanRequest.financeDetail.manualSchedule = defaultValues.containsKey('manualSchedule') && String.isNotBlank(defaultValues.get('manualSchedule')) ? Boolean.valueOf(defaultValues.get('manualSchedule')) : false;
            loanRequest.financeDetail.maxReAgeHolidays = defaultValues.containsKey('maxReAgeHolidays') && String.isNotBlank(defaultValues.get('maxReAgeHolidays')) ? Integer.valueof(defaultValues.get('maxReAgeHolidays')) : 0;
            loanRequest.financeDetail.maxUnplannedEmi = defaultValues.containsKey('maxUnplannedEmi') && String.isNotBlank(defaultValues.get('maxUnplannedEmi')) ? Integer.valueof(defaultValues.get('maxUnplannedEmi')) : 0;
            loanRequest.financeDetail.nextRepayDate = /*loanTransaction.Next_First_Payment_Date__c;*/'';
            loanRequest.financeDetail.nextRepayPftDate = /*loanTransaction.Next_First_Payment_Date__c;*/'';
            Integer graceFreq;
            if(loanApplication.StageName != 'Sales login' && profileName!= 'System Administrator'){
                graceFreq = loanTransaction.Grace_Period_Frequency__c != null ? Integer.valueOf(loanTransaction.Grace_Period_Frequency__c) : 0;
                if(productType == 'Child'){
                    sanctionTenure = loanApplication.Final_Tenure__c != null ? Integer.valueOf(loanApplication.Final_Tenure__c) : Integer.valueOf(loanApplication.Sanction_Tenure__c);
                    if (loanTransaction.Allow_Grace__c == true) {
                        loanRequest.financeDetail.numberOfTerms = sanctionTenure - graceFreq;
                    } else {
                        loanRequest.financeDetail.numberOfTerms = sanctionTenure;
                    }
                }
                else{
                    if(subProductForParent.size() > 0){
                        sanctionTenure = subProductForParent[0].Final_Tenure__c != null ? Integer.valueOf(subProductForParent[0].Final_Tenure__c) : Integer.valueOf(subProductForParent[0].Sanctioned_Tenor__c);
                        if (loanTransaction.Allow_Grace__c == true) {
                            loanRequest.financeDetail.numberOfTerms = sanctionTenure - graceFreq;
                        } else {
                            loanRequest.financeDetail.numberOfTerms = sanctionTenure;
                        }
                    }
                }
                
                system.debug('loanRequest.financeDetail.numberOfTerms: '+loanRequest.financeDetail.numberOfTerms);
            }
            loanRequest.financeDetail.productCategory = defaultValues.containsKey('productCategory') ? defaultValues.get('productCategory') : 'CONV';
            loanRequest.financeDetail.profitDaysBasis = profitDaysBasis;
            loanRequest.financeDetail.quickDisb = defaultValues.containsKey('quickDisb')  && String.isNotBlank(defaultValues.get('quickDisb')) ? Boolean.valueOf(defaultValues.get('quickDisb')) : false;
            loanRequest.financeDetail.reAgeCpz = defaultValues.containsKey('reAgeCpz')  && String.isNotBlank(defaultValues.get('reAgeCpz')) ? Boolean.valueOf(defaultValues.get('reAgeCpz')) :false;
            loanRequest.financeDetail.referralId = defaultValues.containsKey('referralId') ? defaultValues.get('referralId') : '';
            loanRequest.financeDetail.repayAccountId = defaultValues.containsKey('repayAccountId') ? defaultValues.get('repayAccountId') : '';
            loanRequest.financeDetail.repayAdvMargin = defaultValues.containsKey('repayAdvMargin') && String.isNotBlank(defaultValues.get('repayAdvMargin')) ? Integer.valueOf(defaultValues.get('repayAdvMargin')) : 0;
            loanRequest.financeDetail.repayAdvPftRate = defaultValues.containsKey('repayAdvPftRate') && String.isNotBlank(defaultValues.get('repayAdvPftRate')) ? Integer.valueOf(defaultValues.get('repayAdvPftRate')) : 0;
            if(loanApplication.StageName != 'Sales login' &&  profileName!= 'System Administrator'){
                if(wrapper.loanSchedulerInvocationType == constants.get('Charges_API_Invocation')){
                    loanRequest.financeDetail.repayFrq = finalFrequencyCode;
                    loanRequest.financeDetail.repayPftFrq = finalFrequencyCode;
                }else{
                    loanRequest.financeDetail.repayFrq = (loanTransaction != null/* && loanTransaction.Step_Loan__c == false*/) ? finalFrequencyCode: '';
                    loanRequest.financeDetail.repayPftFrq = (loanTransaction != null /*&& loanTransaction.Step_Loan__c == false*/) ? finalFrequencyCode: '';
                }
            }
            loanRequest.financeDetail.rolloverFrq = defaultValues.containsKey('rolloverFrq') ? defaultValues.get('rolloverFrq') : '';
            loanRequest.financeDetail.salesDepartment = defaultValues.containsKey('salesDepartment') ? defaultValues.get('salesDepartment') : '';
            loanRequest.financeDetail.scheduleMethod = loanTransaction != null && loanTransaction.Step_Loan__c == true ? loanTransaction.Schedule_Method__c : 'EQUAL';
            loanRequest.financeDetail.stage = defaultValues.containsKey('stage') ? defaultValues.get('stage') : '';
            
            if(wrapper.loanSchedulerInvocationType == constants.get('Charges_API_Invocation')){
                loanRequest.financeDetail.stepFinance = false;
            }else{
                loanRequest.financeDetail.stepFinance = (loanTransaction != null) ? loanTransaction.Step_Loan__c : false;
            }
            
            loanRequest.financeDetail.tdsApplicable = false ; //(loanTransaction != null && loanTransaction.TDS_Applicable__c) ? true:false;
            loanRequest.financeDetail.planDeferCount = defaultValues.containsKey('planDeferCount') && String.isNotBlank(defaultValues.get('planDeferCount')) ? Integer.valueOf(defaultValues.get('planDeferCount')) : 0;
            
            if(wrapper.loanSchedulerInvocationType == constants.get('Charges_API_Invocation')){
                if(subVariantPrd == constants.get('Interest_Only')){
                    loanRequest.financeDetail.grcTerms = hybridTenure != null ? Integer.valueOf(hybridTenure[0].name) : 0;
                }
                else {
                    loanRequest.financeDetail.grcTerms = (loanTransaction != null && allowGrace == true) ? Integer.valueOf(loanTransaction.Grace_Period_Frequency__c) : 0;
                }
            }
            else{
                if(allowGrace == true){
                    // if(subVariantPrd == constants.get('Interest_Only')){
                    //     // loanRequest.financeDetail.grcTerms = hybridTenure != null ? Integer.valueOf(hybridTenure[0].name) : 0;
                    //     loanRequest.financeDetail.grcTerms = graceFreq;
                    // }
                    // else {
                        loanRequest.financeDetail.grcTerms = graceFreq;
                    // }
                }
                else{
                    loanRequest.financeDetail.grcTerms = 0;
                }
            }

            loanRequest.financeDetail.grcRateBasis = (loanTransaction != null && allowGrace == true && loanTransaction.Step_Loan__c == true) ? loanTransaction.Rate_Type__c :'R';
            loanRequest.financeDetail.grcMargin = (loanTransaction != null && allowGrace == true) ? loanTransaction.Margin__c - plrValue : 0;
            loanRequest.financeDetail.grcSchdMthd = (loanTransaction != null && allowGrace == true) ? loanTransaction.Payment_Method_Grace_Parameter__c : '';
            if(wrapper.loanSchedulerInvocationType == constants.get('Charges_API_Invocation')){
                loanRequest.financeDetail.grcPftFrq = (loanTransaction != null && allowGrace == true) ? finalFrequencyCode /*'Q0326'*/ /*loanTransaction.Payment_Method_Grace_Parameter__c*/: '';
            }else{
                loanRequest.financeDetail.grcPftFrq = (loanTransaction != null && allowGrace == true) ? finalFrequencyCode : '';
            }
            if(wrapper.loanSchedulerInvocationType == constants.get('Charges_API_Invocation')){
                loanRequest.financeDetail.grcPftRvwFrq = (loanTransaction != null && allowGrace == true) ? finalFrequencyCode : '';
            }else{
                loanRequest.financeDetail.grcPftRvwFrq = (loanTransaction != null && allowGrace == true) ? finalFrequencyCode : '';
            }
            if(wrapper.loanSchedulerInvocationType == constants.get('Charges_API_Invocation')){
                loanRequest.financeDetail.grcCpzFrq = (loanTransaction != null && allowGrace == true && loanTransaction.Capitalize__c == true) ? finalFrequencyCode /*'Q0326'*/ : '';
            }else{
                loanRequest.financeDetail.grcCpzFrq = (loanTransaction != null && allowGrace == true && loanTransaction.Capitalize__c == true && loanTransaction.Step_Loan__c == false) ? finalFrequencyCode /*'Q0326'*/ : '';//jayoti
            }
            system.debug('allowGrace: '+allowGrace);
            system.debug('loanRequest.financeDetail.grcMargin; '+loanRequest.financeDetail.grcMargin);
            loanRequest.financeDetail.grcMinRate = (defaultValues.containsKey('grcMinRate') && String.isNotBlank(defaultValues.get('grcMinRate')) && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcMinRate')): 0;
            loanRequest.financeDetail.grcMaxRate = (defaultValues.containsKey('grcMaxRate') && String.isNotBlank(defaultValues.get('grcMaxRate')) && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcMaxRate')) :0;
            loanRequest.financeDetail.grcMaxAmount = (defaultValues.containsKey('grcMaxAmount') && String.isNotBlank(defaultValues.get('grcMaxAmount')) && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcMaxAmount')) : 0;
            loanRequest.financeDetail.grcAdvPftRate = (defaultValues.containsKey('grcAdvPftRate') && String.isNotBlank(defaultValues.get('grcAdvPftRate')) && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcAdvPftRate')): 0;
            loanRequest.financeDetail.grcAdvMargin = (defaultValues.containsKey('grcAdvMargin') && String.isNotBlank(defaultValues.get('grcAdvMargin')) && allowGrace == true) ? Integer.valueOf(defaultValues.get('grcAdvMargin')): 0;
            loanRequest.financeDetail.reqRepayAmount = defaultValues.containsKey('reqRepayAmount') && String.isNotBlank(defaultValues.get('reqRepayAmount')) ? Integer.valueOf(defaultValues.get('reqRepayAmount')) : 0;
            loanRequest.financeDetail.repayRateBasis = defaultValues.containsKey('repayRateBasis') && String.isNotBlank(defaultValues.get('repayRateBasis')) ? String.valueOf(defaultValues.get('repayRateBasis')) : '';//loanTransaction != null ? loanTransaction.Rate_Type__c:'';
            loanRequest.financeDetail.repayMargin = (loanTransaction != null && plrValue != null) ? loanTransaction.Margin__c - plrValue : 0;
            loanRequest.financeDetail.repayCpzFrq = (loanTransaction != null && loanTransaction.Capitalize__c == true) ? finalFrequencyCode : '';
            loanRequest.financeDetail.repayMinRate = 0;
            loanRequest.financeDetail.repayMaxRate = 0;
            loanRequest.financeDetail.supplementRent = defaultValues.containsKey('supplementRent') && String.isNotBlank(defaultValues.get('supplementRent')) ? Integer.valueOf(defaultValues.get('supplementRent')) : 0;
            loanRequest.financeDetail.dsaCode = defaultValues.containsKey('dsaCode') ? defaultValues.get('dsaCode') : '';
            loanRequest.financeDetail.unPlanEMIHLockPeriod = defaultValues.containsKey('unPlanEMIHLockPeriod') && String.isNotBlank(defaultValues.get('unPlanEMIHLockPeriod')) ? Integer.valueof(defaultValues.get('unPlanEMIHLockPeriod')) : 0;
            loanRequest.financeDetail.unPlanEMICpz = defaultValues.containsKey('unPlanEMICpz')  && String.isNotBlank(defaultValues.get('unPlanEMICpz')) ? Boolean.valueOf(defaultValues.get('unPlanEMICpz')) : false;
            loanRequest.financeDetail.appliedLoanAmt = 500000000;//Utility.addTwoZeros(loanApplication.Final_Amount__c):null; Hardcoding it now as per SFHL-858 as discussed with Snigdha and Yash Transdigital.
            // loanRequest.financeDetail.elasticCrLine = (loanTransaction != null && finType == 'BD') ? true:false;
            // loanRequest.financeDetail.elasticCrLineType = (loanTransaction != null && finType == 'BD' && loanTransaction.Elastic_Credit_Line_Type__c != null) ? loanTransaction.Elastic_Credit_Line_Type__c:'';
            // loanRequest.financeDetail.elasticCrLineDropCalOn =  (loanTransaction != null && finType == 'BD' && loanTransaction.Dropline_Calculated_On__c != null) ? loanTransaction.Dropline_Calculated_On__c:'';
            
            system.debug('loanRequest.financeDetail.repayMargin: '+loanRequest.financeDetail.repayMargin);
            
            if(wrapper.loanSchedulerInvocationType == constants.get('Charges_API_Invocation')){
                loanRequest.financeDetail.grcBaseRate =  plrCode;
                loanRequest.financeDetail.repayBaseRate = plrCode;
            }else{
                loanRequest.financeDetail.grcBaseRate = plrCode;
                loanRequest.financeDetail.repayBaseRate = plrCode;
            }           
            if (loanTransaction != null && loanTransaction.Step_Loan__c == true && wrapper.loanSchedulerInvocationType != constants.get('Charges_API_Invocation') && stepLoanRecords != null) {
                loanRequest.financeDetail.noOfSteps = noOfSteps;
                loanRequest.financeDetail.noOfGrcSteps = noOfGrcSteps;   
                Integer graceCounter = 1;
                Integer regularCounter = 1; 
                Integer stepNumberAutoCal = 0;
                Decimal tenorSplitSum = 0.00;
                Decimal margin = 0.00;
                for (Loan_Transaction__c step : stepLoanRecords) {
                    step stepDetail = new step();
                    // Determine if step is Grace or Regular
                    Boolean isGrace = (step.Step_Specifier__c != null && step.Step_Specifier__c == 'Grace');
                    stepDetail.stepNumber = isGrace ? graceCounter++ : regularCounter++;
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
                    loanRequest.step.add(stepDetail);

                }

                Decimal totalStepInstallments = 0;

                for (step s : loanRequest.step) {
                    if (s.installments != null) {
                        totalStepInstallments += s.installments;
                    }
                }

                System.debug('Total step Installments: ' + totalStepInstallments);


                if (totalStepInstallments < sanctionTenure) { //loanRequest.financeDetail.numberOfTerms) { //this is coming from application right now >> Armani
                    step stepDetail = new step();
                    stepDetail.stepNumber = regularCounter++;
                    stepDetail.tenorSplitPerc = 100.00 - tenorSplitSum;
                    stepDetail.rateMargin = margin;
                    stepDetail.emiSplitPerc = 0;
                    stepDetail.steppedEMI = Utility.addTwoZeros(0);
                    stepDetail.stepSpecifier = 'R'; 
                    stepDetail.autoCal = 0;
                    stepDetail.installments = sanctionTenure - totalStepInstallments; //removing grace frequenccy for the last installment loanRequest.financeDetail.numberOfTerms
                    loanRequest.step.add(stepDetail);
                    loanRequest.financeDetail.noOfSteps = noOfSteps + 1;
                }
            }

            Map<String, String> monthMap = getMonthNameToDigitMap();

            
            List<String> plannedEMIHMList = new List<String>();
            if (loanTransaction?.Planned_EMI_Holiday_Month__c != null) {
                plannedEMIHMList = loanTransaction.Planned_EMI_Holiday_Month__c.split(';');
            }

            List<String> plannedPrinHMList = new List<String>();
            if (loanTransaction?.Planned_Principal_Holiday_Month__c != null) {
                plannedPrinHMList = loanTransaction.Planned_Principal_Holiday_Month__c.split(';');
            }

            // String plannedPrinHM;
            // if (loanTransaction != null && loanTransaction.Planned_Principal_Holiday_Month__c != null) {
            //     plannedPrinHM = loanTransaction.Planned_Principal_Holiday_Month__c;
            // }

            // String plannedEMIHM;
            // if (loanTransaction != null && loanTransaction.Planned_EMI_Holiday_Month__c != null) {
            //     plannedEMIHM = loanTransaction.Planned_EMI_Holiday_Month__c;
            // }

            if (loanTransaction != null && wrapper.loanSchedulerInvocationType != constants.get('Charges_API_Invocation')) {
                    if(allowPlannedEMI == true){ // as of now only Frequency method is allowed for PlannedEMI
                        loanRequest.financeDetail.planEMIHAlw = loanTransaction.Allow_Planned_EMI_Holiday__c ? true:false;
                        loanRequest.financeDetail.planEMIHAlwInGrace = loanTransaction.Allow_Grace__c ? true : false;
                        loanRequest.financeDetail.planEMIHMethod = loanTransaction.Planned_EMI_Holiday_Method__c != null ? loanTransaction.Planned_EMI_Holiday_Method__c : '';
                        loanRequest.financeDetail.planEMIHMax = loanTransaction.Max__c != null ? Integer.valueOf(loanTransaction.Max__c) : 0;
                        loanRequest.financeDetail.planEMIHLockPeriod = loanTransaction.Lock_Period_Months__c != null ? Integer.valueOf(loanTransaction.Lock_Period_Months__c) : 0;
                        loanRequest.financeDetail.planEMIHMaxPerYear = loanTransaction.Max_per_Year__c != null ? Integer.valueOf(loanTransaction.Max_per_Year__c) : 0;
                        loanRequest.financeDetail.planEMICpz = loanTransaction.Capitalize__c ? true : false;

                        for (String month : plannedEMIHMList) {
                            planEMIHmonths holidayMonthWrapper = new planEMIHmonths();
                            holidayMonthWrapper.holidayMonth = monthMap.get(month);
                            loanRequest.planEMIHmonths.add(holidayMonthWrapper);
                        }

                        // loanRequest.planEMIHmonths = plannedEMIHM.split(';');

                        // loanRequest.planEMIHmonths = (plannedEMIHM != null) ? plannedEMIHM.split(';') : new List<String>();

                    }
                    if(allowPlannedPrincipal == true){ // as of now only Frequency method is allowed for PlannedPrincipal
                        loanRequest.financeDetail.planPRIHAlw = loanTransaction.Allow_Planned_Principal_Holiday__c ? true:false;
                        loanRequest.financeDetail.planPRIHMethod = loanTransaction.Planned_Principal_Holiday_Method__c != null ? loanTransaction.Planned_Principal_Holiday_Method__c : '';
                        loanRequest.financeDetail.planPRIHMax = loanTransaction.Max_Principal_Holiday_Parameter__c != null ? Integer.valueOf(loanTransaction.Max_Principal_Holiday_Parameter__c) : 0;
                        loanRequest.financeDetail.planPRIHLockPeriod = loanTransaction.Lock_Period_Principal_Holiday_Paramters__c != null ? Integer.valueOf(loanTransaction.Lock_Period_Principal_Holiday_Paramters__c) : 0;
                        loanRequest.financeDetail.planPRIHMaxPerYear = loanTransaction.Max_per_Year_Principal_Holiday_Parameter__c != null ? Integer.valueOf(loanTransaction.Max_per_Year_Principal_Holiday_Parameter__c) : 0;

                        for (String month : plannedPrinHMList) {
                            planPRIHMonths holidayMonthWrapper = new planPRIHMonths();
                            holidayMonthWrapper.priHolidayMonth = month;
                            loanRequest.planPRIHmonths.add(holidayMonthWrapper);
                        }

                        
                        // loanRequest.planPRIHMonths = plannedPrinHM.split(';');

                        // loanRequest.planPRIHMonths = (plannedPrinHM != null) ? plannedPrinHM.split(';') : new List<String>();

                    }

                // if (loanTransaction.Planned_EMI_Holiday_Method__c == 'A'){
                //     //loanRequest.financeDetail.scheduleMethod = loanTransaction.Schedule_Method__c != null ? loanTransaction.Schedule_Method__c : '';// not needed as already we are sending above
                //     loanRequest.financeDetail.planPRIHAlw = loanTransaction.Allow_Planned_Principal_Holiday__c ? true:false;
                //     loanRequest.financeDetail.planPRIHMethod = loanTransaction.Planned_Principal_Holiday_Method__c != null ? loanTransaction.Planned_Principal_Holiday_Method__c : '';
                //     loanRequest.financeDetail.planPRIHMax = loanTransaction.Max_Principal_Holiday_Parameter__c != null ? Integer.valueOf(loanTransaction.Max_Principal_Holiday_Parameter__c) : 0;
                //     loanRequest.financeDetail.planPRIHLockPeriod = loanTransaction.Lock_Period_Principal_Holiday_Paramters__c != null ? Integer.valueOf(loanTransaction.Lock_Period_Principal_Holiday_Paramters__c) : 0;
                //     loanRequest.financeDetail.planPRIHMaxPerYear = loanTransaction.Max_per_Year_Principal_Holiday_Parameter__c != null ? Integer.valueOf(loanTransaction.Max_per_Year_Principal_Holiday_Parameter__c) : 0;
                //     // Add planEMIHDates
                //     // Add planPRIHDates
                // }
            }
            
            // Convert to JSON
            String requestJSON = JSON.serialize(loanRequest);
            System.debug('Request JSON: ' + requestJSON);
            return requestJSON;
        
        } catch (Exception e) {
            //throw new AuraHandledException('An error occurred: ' + e.getMessage());
            System.debug('exception>'+e.getMessage()+' at line number>'+e.getLineNumber());
            throw new AuraHandledException('There is a Salesforce Exception, please contact your Salesforce Administrator.');
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

    public static Map<String, String> getMonthNameToDigitMap() {
        return new Map<String, String>{
            '1'         => '1',
            'January'   => '1',
            'February'  => '2',
            'March'     => '3',
            'April'     => '4',
            'May'       => '5',
            'June'      => '6',
            'July'      => '7',
            'August'    => '8',
            'September' => '9',
            'October'   => '10',
            'November'  => '11',
            'December'  => '12'
        };
    }

    // **Request Wrapper Class**
    public class LoanRequestWrapper {
        public String finReference;
        public FinanceDetail financeDetail;
        public List<Step> step = new List<Step>();
        public List<planEMIHmonths> planEMIHmonths = new List<planEMIHmonths>();
        public List<planEMIHDates> planEMIHDates = new List<planEMIHDates>();
        public List<planPRIHMonths> planPRIHmonths = new List<planPRIHMonths>();
        public List<planPRIHDates> planPRIHDates = new List<planPRIHDates>();
    }

    public class FinanceDetail {
        public String cif;
        public String finType;
        public Decimal finAmount;
        public Decimal finAssetValue;
        public Boolean allowGrcRepay;
        public String scheduleMethod;
        public String dftBpiTreatment;
        public String finCcy;
        public String finBranch;
        public String profitDaysBasis;
        public Boolean allowGrcPeriod;
        public Boolean tdsApplicable;
        public Boolean manualSchedule;
        public Integer planDeferCount;
        public Boolean stepFinance;
        public Integer grcTerms;
        public String grcRateBasis;
        public Decimal grcMargin;
        public String grcPftFrq;
        public String grcPftRvwFrq;
        public String grcCpzFrq;
        public Integer grcMinRate;
        public Decimal grcMaxRate;
        public Decimal grcMaxAmount;
        public Decimal grcAdvPftRate;
        public Decimal grcAdvMargin;
        public Integer numberOfTerms;
        public Decimal reqRepayAmount;
        public String repayRateBasis;
        public Decimal repayMargin;
        public String repayFrq;
        public String nextRepayDate;
        public String repayPftFrq;
        public String nextRepayPftDate;
        public String repayCpzFrq;
        public Decimal repayMinRate;
        public Decimal repayMaxRate;
        public Decimal repayAdvPftRate;
        public Decimal repayAdvMargin;
        public Decimal supplementRent;
        public Decimal increasedCost;
        public String rolloverFrq;
        public String finPurpose;
        public String finLimitRef;
        public String finCommitmentRef;
        public String repayAccountId;
        public String depreciationFrq;
        public String dsaCode;
        public String salesDepartment;
        public String referralId;
        public String employeeName;
        public Boolean quickDisb;
        public Integer unPlanEMIHLockPeriod;
        public Boolean unPlanEMICpz;
        public Boolean reAgeCpz;
        public Integer maxUnplannedEmi;
        public Integer maxReAgeHolidays;
        public Boolean alwBpiTreatment;
        public String bpiPftDaysBasis;
        public Boolean planEMIHAlw;//EMI holiday
        public Boolean planEMIHAlwInGrace;//EMI holiday
        public String planEMIHMethod;//EMI holiday
        public Integer planEMIHMaxPerYear;//EMI holiday
        public Integer planEMIHMax;//EMI holiday
        public Integer planEMIHLockPeriod;//EMI holiday
        public Boolean planEMICpz;//EMI holiday
        public Boolean planPRIHAlw;//principal holiday
        public String planPRIHMethod;//principal holiday
        public Integer planPRIHMax;//principal holiday
        public Integer planPRIHLockPeriod;//principal holiday
        public Integer planPRIHMaxPerYear;//principal holiday
        public String stage;
        public Integer advEMITerms;
        public Integer fixedRateTenor;
        public Decimal fixedTenorRate;
        public Integer eligibilityMethod;
        public Boolean legalRequired;
        public String productCategory;
        public Decimal appliedLoanAmt;
        public Boolean alwGrcAdj;
        public String grcBaseRate;
        public String repayBaseRate;
        public boolean alwManualSteps;
        public Integer noOfGrcSteps;
        public Integer noOfSteps;
        // public boolean elasticCrLine;
        // public String elasticCrLineType;
        // public String elasticCrLineDropCalOn; 
        public String grcSchdMthd;
        public string finStartDate;
        //public List<step> step = new List<step>();
    }

    public class step {
        public Integer stepNumber;       
        public Decimal tenorSplitPerc;    
        public Decimal rateMargin;        
        public Decimal emiSplitPerc; 
        public Decimal steppedEMI;  
        public String stepSpecifier;   
        public Decimal autoCal;
        public Decimal installments;
    }

    public class planEMIHmonths {
        public String holidayMonth;       
    }

    public class planPRIHMonths {
        public String priHolidayMonth;       
    }

    public class planEMIHDates{
        public String holidayDate;
    }

    public class planPRIHDates{
        public String priHolidayDate;
    }
}