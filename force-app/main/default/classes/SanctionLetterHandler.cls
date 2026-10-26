public class SanctionLetterHandler implements IntegrationInterface{

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
            SELECT Id, Product__c,Final_Amount__c, Sanction_Tenure__c, Variant__c,Lead__r.Dsa_Area_Manager__r.email,Final_Tenure__c
            FROM Opportunity 
            WHERE Id = :loanApplicationId 
            LIMIT 1
        ];
    
        // Fetch Loan Transactions
        List<Loan_Transaction__c> loanTransactions = [
            SELECT Id, Disbursement_Amount__c, Allow_Payment_in_Grace_Period__c, Schedule_Method__c, 
                   BPI_Treatment__c, Allow_Grace__c, TDS_Applicable__c, Step_Loan__c, 
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

        if (loanApplication == null) {
            errorMessages.add(constants.get('Error_Loan_Application_not_found') + loanApplicationId);
        } else {
            if (loanApplication.Final_Amount__c == null) {
                errorMessages.add(constants.get('Error_Missing_Loan_Amount'));
            }
            if (loanApplication.Sanction_Tenure__c == null) {
                errorMessages.add(constants.get('Error_Missing_SanctionTerms'));
            }
        }
    
        if (loanTransaction == null) {
            errorMessages.add(constants.get('Error_No_Loan_Transaction_records_found') + loanApplicationId);
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
                Variant__c,Final_Rate_Of_Interest__c, Loan_Purpose__c,Tenor_Months__c,Final_Tenure__c,APR__c,Lead__c,Lead__r.Dsa_Area_Manager__r.email
                FROM Opportunity 
                WHERE Id = :loanApplicationId
            ];
            Opportunity loanApplication = loanApplications.isEmpty() ? null : loanApplications[0];
    
            // **Bulk Query: Fetch Loan Transactions**
            List<Loan_Transaction__c> loanTransactions = [
                SELECT Id, Disbursement_Amount__c, Allow_Payment_in_Grace_Period__c, Schedule_Method__c, 
                BPI_Treatment__c, Allow_Grace__c, TDS_Applicable__c, Step_Loan__c, 
                Grace_Period_Frequency__c, Interest_Frequency__c, Allow_BPI__c, Loan_Start_Date__c,
                Allow_Planned_EMI_Holiday__c, Allow_Planned_EMI_holiday_in_Grace__c,Interest_Due_date__c, 
                Planned_EMI_Holiday_Method__c, Max_per_Year__c, Max__c, Lock_Period_Months__c, 
                Capitalize__c,Rate_Type__c,Margin__c, Grace_Base_Rate_Code__c, Next_First_Payment_Date__c,
                First_Disbursement_Amount__c,Payment_Method_Grace_Parameter__c,Payment_Method__c,
                Elastic_Credit_Line_Type__c,Dropline_Calculated_On__c,Yearly_Selection__c,
                Half_Yearly_Selection__c,Quarterly_Selection__c,Dropline_Tenure__c,Pure_Tenure__c
                FROM Loan_Transaction__c
                WHERE Loan_Application__c = :loanApplicationId
                AND RecordType.DeveloperName = 'Transaction_Details'
            ];
            System.debug('loanTransactions.size()>>'+loanTransactions.size());
            Loan_Transaction__c loanTransaction = loanTransactions.isEmpty() ? null : loanTransactions[0];
    
            // **Fetch Primary Application Applicant**
            List<Application_Applicant__c> applicants = [
                SELECT Id, Name, First_Name__c, Last_Name__c,Customer__r.SF_Customer_ID__c, Applicant_Name__c,Mobile_Number__c, Email__c, Salutation__c, Customer__r.Customer_LMS_Id__c, 
                Customer_Type__c, Gender__c, Residency_Status__c,Employment_Type__c
                FROM Application_Applicant__c
                WHERE Loan_Application__c = :loanApplicationId
                AND Applicant_Type__c = 'Primary Applicant'
            ];
            
            Application_Applicant__c primaryApplicant = applicants.isEmpty() ? null : applicants[0];
            String primarycustomerId = primaryApplicant.Customer__r.SF_Customer_ID__c;
            system.debug('primarycustomerId>>'+primarycustomerId);
                if (primarycustomerId.startsWith('C-')) {
                    primarycustomerId = primarycustomerId.substring(2); // Remove the first 2 characters (C-)
                }
            // **Fetch Co Application Applicant**
            List<Application_Applicant__c> coapplicants = [
                SELECT Id, Name, First_Name__c, Customer__r.SF_Customer_ID__c,Last_Name__c,Applicant_Name__c,Mobile_Number__c, Email__c, Salutation__c, Customer__r.Customer_LMS_Id__c, 
                Customer_Type__c, Gender__c, Residency_Status__c
                FROM Application_Applicant__c
                WHERE Loan_Application__c = :loanApplicationId
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
                WHERE Applicant__r.Loan_Application__c =: loanApplicationId And Applicant__c =: primaryApplicant.Id And Address_Line_1__c != '' And Address_Priority__c = '5' Limit 1
            ];

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

            Product2 mainProduct =[SELECT Id from Product2 WHERE RecordType.Name = :constants.get('Product') AND Name = :loanApplication.Product__c AND Loan_Application__c = :loanApplicationId LIMIT 1];
            System.debug('mainProduct>>>'+mainProduct);
            Product2 subProduct = [SELECT Id,Name from Product2 WHERE RecordType.Name = :constants.get('Sub_Product') AND Product__c =:mainProduct.Id AND Loan_Application__c = :loanApplicationId LIMIT 1];
            System.debug('subProduct>>>'+subProduct);
            
            List<string> prodVariantAndSubVariant = new List<string>();
            prodVariantAndSubVariant.add(constants.get('Variant'));
            prodVariantAndSubVariant.add(constants.get('Sub_Variant'));
            
           
            System.debug('228>>'+[
                SELECT Id, Name,Product__c
                FROM Product2 
               ]);
            System.debug('234>>'+[SELECT Id, Name,Product__c
                FROM Product2 
                WHERE Loan_Application__c = :wrapper.loanApplicationId 
                AND Product__c = :subProduct.Id]);

            List<Product2> productRecords = [
                SELECT Id, Name, RecordType.Name, PLR_Code__c, 
                PLR_Value__c, BPI_Interest_Days_Basis__c, Interest_Days_Basis__c 
                FROM Product2 
                WHERE Loan_Application__c = :wrapper.loanApplicationId 
                AND RecordType.Name In : prodVariantAndSubVariant AND Product__c = :subProduct.Id
            ];
            System.debug('productRecords>>>'+productRecords);

            String finType = 'HL';  // Default
            String productName = '';
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
                        plrValue = prod.PLR_Value__c != null ? prod.PLR_Value__c : 18.31;
                        productName = loanApplication.Product__c;
                }
                else if(prod.RecordType.Name == constants.get('Sub_Variant')){
                        subVariantPrd = prod.Name;
                        hybridTenure = [Select Id, Name from Product2 Where Loan_Application__c = :wrapper.loanApplicationId 
                                        And Sub_Variant__c =: prod.Id And RecordType.Name =: constants.get('Hybrid_Tenure')];
                }
            }

            List<Sanction_Condition__c> sanctionConditions = [SELECT Id, Name, Condition_Name__c, Condition_Approval__c, Loan_Application__c FROM Sanction_Condition__c 
                                                                WHERE Loan_Application__c = :loanApplicationId And Condition_Approval__c = 'Pending'];

            List<Application_Collateral__c> appCollateral = [select Id,Collateral__r.Unit_Number__c,Collateral__r.Floor_Number__c,Collateral__r.Tower_Building_Name__c,
                                                             Collateral__r.Project__c,Collateral__r.Project__r.Name,Collateral__r.Address_Line_1__c,Collateral__r.Address_Line_2__c,Collateral__r.Address_Line_3__c,
                                                             Collateral__r.Landmark__c,Collateral__r.City__c,Collateral__r.State__c,Collateral__r.Pincode__r.Name,Collateral__r.Unit_Property_Type__c,
                                                             Collateral__r.Name from Application_Collateral__c where HL_Loan_Application__c = :loanApplicationId];
                                                                

                                                                

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
                            Final_Amount_INR__c,Charges_Fee_Type__c,Requested_Amount_INR__c,Category__c,Requested_Percentage__c FROM Charges_Insurance__c WHERE Loan_Application__c = :loanApplicationId AND recordtype.name = 'Charges'] ;       

            // **Fetch Sales Manager's Email from Opportunity Team Members**
            List<OpportunityTeamMember> oppTeamMembers = [
                SELECT User.Email,User.Name,User.Employee_Id__c, User.Manager.Email,User.Manager.Name,User.Manager.Employee_Id__c,TeamMemberRole 
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

            Integer sanctionTenure = loanApplication.Final_Tenure__c != null ? Integer.valueOf(loanApplication.Final_Tenure__c) : Integer.valueOf(loanApplication.Sanction_Tenure__c);
            Integer graceFreq = hybridTenure != null ? Integer.valueOf(hybridTenure[0].name) : 0;

            List<Loan_Transaction__c> stepLoanRecords = new List<Loan_Transaction__c>();
            Integer noOfSteps = 0;
            Integer noOfGrcSteps = 0;
            if (loanTransaction != null && loanTransaction.Step_Loan__c == true) {
                stepLoanRecords = [
                    SELECT Number_of_Steps__c, Step_Amount__c, 
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
                    else if(step.Step_Specifier__c != null && step.Step_Specifier__c == 'Repayment'){
                        noOfSteps++;
                    }
                }
            }     

            for (OpportunityTeamMember teamMember : oppTeamMembers) {
                if ((teamMember.TeamMemberRole == 'Sales Manager' || teamMember.TeamMemberRole == 'Relationship Manager') && String.isNotBlank(teamMember.User.Email)) {
                    rmEmail = teamMember.User.Email;
                    rmname = String.isNotBlank(teamMember.User.Name) ? teamMember.User.Name : '';
                    rmid = String.isNotBlank(teamMember.User.Employee_Id__c) ? teamMember.User.Employee_Id__c : '';
                    amEmail = teamMember.User.Manager != null ? teamMember.User.Manager.Email : '';
                    amname = teamMember.User.Manager != null ? teamMember.User.Manager.Name : '';
                    amid = teamMember.User.Manager != null ? teamMember.User.Manager.Employee_Id__c : '';
                    break; 
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
            request.typeOfLoan = productName;/*'Term -> Business Loan' Flexi -> Business Loan Flexi Funds;*/
            request.step_finance = stepFlag;
            request.cif = primaryApplicant != null && primaryApplicant.Customer__r.Customer_LMS_Id__c != null? primaryApplicant.Customer__r.Customer_LMS_Id__c : primarycustomerId;
            request.isLRD = ''; 
            request.name = primaryApplicant != null ? primaryApplicant.Applicant_Name__c : '';
            request.custfirstname = primaryApplicant != null ? primaryApplicant.First_Name__c : '';
            request.custlastname = primaryApplicant != null ? primaryApplicant.Last_Name__c : '';

            request.custaddr1 = !allAddresses.isEmpty() ? allAddresses[0].Full_Address1__c : '';
            request.custaddr2 = '';
            request.custaddr3 = '';

            request.finStartDate = formatDateString(loanTransaction.Loan_Start_Date__c);
            
            //request.date_of_disbursal = plfDate != null ? DateTime.newInstance(plfDate, Time.newInstance(0, 0, 0, 0)).formatGmt('yyyy-MM-dd HH:mm:ss') : '';
            request.date_of_disbursal = plfDate != null ? plfDate.toString() : '';
            request.loan_amount = loanApplication != null && loanTransaction.First_Disbursement_Amount__c!= null ? Integer.valueOf(Utility.addTwoZeros(loanTransaction.First_Disbursement_Amount__c)) : 0;
            request.rate_of_interest = loanApplication != null ? loanApplication.Final_Rate_Of_Interest__c : 0;
            request.type_of_interest = 'Fixed Rate';
            request.ghplr = String.valueOf(plrValue);
            system.debug('loanTransaction.Margin__c:: '+loanTransaction.Margin__c + ' plrValue:: '+plrValue+ ' subtraction:: '+Integer.valueOf(loanTransaction.Margin__c - plrValue));
            request.margin = (loanTransaction != null && plrValue != null) ? loanTransaction.Margin__c - plrValue :0;
            request.stepup_pre_emi_tenor = 0;
            request.bank_name = selectedAccount!= null && selectedAccount.Name != null ? selectedAccount.Name : ''; 
            request.acc_number = selectedAccount!= null && selectedAccount.Account_Number__c != null ? selectedAccount.Account_Number__c:'';
            request.finassetvalue = loanTransaction != null && loanApplication.Final_Amount__c!= null ? Integer.valueOf(Utility.addTwoZeros(loanApplication.Final_Amount__c)) : 0;
            //request.total_tenor = loanApplication != null ? Integer.valueOf(loanApplication.Final_Tenure__c) : 0;
           
            // **Insurance Charges - Fetch Total VAS Amount**
            Decimal insuranceCharges = 0;
            Decimal amcCharges = 0;
            Decimal processingFee = 0;
            Decimal finalProcessingFee = 0;
            Decimal stampingFranking = 0;
System.debug('charges>>>>'+charges);
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
                        finalProcessingFee += charge.Final_Amount_INR__c;
                    }
                    else if (charge.Name == 'STFRCHG') {
                        stampingFranking += charge.Final_Amount_INR__c;
                    }
                }
            }

            if (loanTransaction.Allow_Grace__c == true) {
                request.total_tenor = sanctionTenure;
                request.full_emi_tenor = sanctionTenure - graceFreq;
            }
            else {
                request.total_tenor = loanApplication.Final_Tenure__c != null ? Integer.valueOf(loanApplication.Final_Tenure__c) : Integer.valueOf(loanApplication.Sanction_Tenure__c);
                request.full_emi_tenor = loanApplication.Final_Tenure__c != null ? Integer.valueOf(loanApplication.Final_Tenure__c) : Integer.valueOf(loanApplication.Sanction_Tenure__c);
            }

            system.debug('request.full_emi_tenor: '+request.full_emi_tenor);

            request.moratorium_tenor = 0;
            request.pemii_tenor = 0;
            //request.full_emi_tenor = loanApplication != null ? Integer.valueOf(loanApplication.Final_Tenure__c) : 0/*240*/; 
            request.holiday_tenor = 0;
            request.repayment_mode = loanTransaction != null ? loanTransaction.Payment_Method__c : '';
            //request.additional_product = ''; // Default
            request.end_use_of_loan = loanApplication.Loan_Purpose__c != null ? loanApplication.Loan_Purpose__c:'Business Expansion';
            request.stepfinance = loanTransaction != null && loanTransaction.Step_Loan__c ? 'TRUE': 'FALSE';
            request.finisactive = 1;
            request.repaybaserate = /*'GFLPLRBL';*/plrCode;//productmaster
            request.grcpftfrq = (loanTransaction != null && allowGrace == true) ? finalFrequencyCode:'';
            request.grcpftrvwfrq = (loanTransaction != null && allowGrace == true) ? finalFrequencyCode : '';
            request.grccpzfrq = (loanTransaction != null && allowGrace == true && loanTransaction.Capitalize__c == true && loanTransaction.Step_Loan__c == false) ? /*frequencyCode + dueDateCode*/finalFrequencyCode : '';
            request.allow_bpi = (loanTransaction != null) ? Boolean.valueOf(loanTransaction.Allow_BPI__c) : false;
            request.bpitreatment = loanTransaction != null && loanTransaction.Allow_BPI__c == true && String.isNotEmpty(loanTransaction.BPI_Treatment__c)?loanTransaction.BPI_Treatment__c:'N';
            request.allowgrcrepay = (loanTransaction != null && allowGrace == true) ? loanTransaction.Allow_Payment_in_Grace_Period__c : false;
            request.grcratebasis = (loanTransaction != null && allowGrace == true) ? loanTransaction.Rate_Type__c:'R';
            if(allowGrace == true){
                if(subVariantPrd == constants.get('Interest_Only')){
                    request.graceterms = hybridTenure != null ? Integer.valueOf(hybridTenure[0].name) : 0;
                }
                else {
                    request.graceterms = Integer.valueOf(loanTransaction.Grace_Period_Frequency__c);
                }
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
            request.schedulemethod = (loanTransaction != null) ? loanTransaction.Schedule_Method__c : 'EQUAL';
            request.profitdaysbasis = profitDaysBasis;
            request.bpipftdaysbasis = bpiProfitDaysBasis;
            request.finrepaypftonfrq = false; //new field on loan transaction
            request.frequency = (loanTransaction != null ) ? finalFrequencyCode:'';
            request.instalment_frequency = instalmentFrequency;
            
            if (loanTransaction.Allow_Grace__c == true) {
                request.numberofterms = sanctionTenure - graceFreq;
            } else {
                request.numberofterms = loanApplication.Final_Tenure__c != null ? Integer.valueOf(loanApplication.Final_Tenure__c) : Integer.valueOf(loanApplication.Sanction_Tenure__c);
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
            request.feetypeid = 1;
            request.processingfee = Integer.valueOf(Utility.addTwoZeros(finalProcessingFee)); // Final Processing Fee Amount
            request.custresidentialsts = /*primaryApplicant != null ? primaryApplicant.Residency_Status__c : ''*/'';
            request.finpurpose = 'BR';//mapping codes need to happen
            request.allowgrcperiod = (loanTransaction != null && loanTransaction.Allow_Grace__c) ? 1 : 0;
            request.allow_grcperiod = (loanTransaction != null && loanTransaction.Allow_Grace__c != null) ? loanTransaction.Allow_Grace__c : false;
            
            request.grcschdmthd = (loanTransaction != null) ? loanTransaction.Schedule_Method__c : 'EQUAL';
            request.branch_code = loanApplication.Branch_Master__r.Branch_Code__c!=null ?loanApplication.Branch_Master__r.Branch_Code__c:'3002';
            request.gender = primaryApplicant != null && primaryApplicant.Gender__c != null ? primaryApplicant.Gender__c : '';
            request.resident_status = primaryApplicant != null && primaryApplicant.Residency_Status__c!= null ? primaryApplicant.Residency_Status__c : '';
            request.rm_email_id = /*rmEmail*/'';
            request.am_email_id = loanApplication.Lead__r.Dsa_Area_Manager__r.email != null ? loanApplication.Lead__r.Dsa_Area_Manager__r.email : '';

            request.elasticcrlinetype = '#'; // default to # for BL, BD will have value
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
            }

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
            request.amname = amname != null ? amname : '';
            request.amid = amid != null ? amid : '';
            request.offemailverified = false;//need clarification 
            request.loan_towards_selfcon = 0;//need clarification
            request.loan_towards_plot = 0;//need clarification
            request.fixedratetenor = 0;//need clarification //Mandatory Field if interest Type is Hybrid.For other interest Types not applicable
            request.calterms = 0;//need clarification
            request.finocrrequired = 0;//need clarification

            // **Convert to JSON**
            String requestJSON = JSON.serialize(request);
            System.debug('Request JSON: ' + requestJSON);
            return requestJSON;
    
        } catch (Exception e) {
            //throw new AuraHandledException('Error in Construct Payload: ' + e.getMessage());
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
}