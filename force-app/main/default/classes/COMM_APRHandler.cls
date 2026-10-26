public with sharing class COMM_APRHandler implements IntegrationInterface {
    static String conLabels = 'Error_Loan_Application_not_found,Error_Missing_Loan_Amount,Error_Missing_SanctionTerms,Error_Missing_Final_ROI,Error_Missing_Final_Tenure,Error_No_Loan_Transaction_records_found,Error_Missing_Scheduling_Method,Error_TDS_Applicable_is_not_selected,Error_Missing_Rate_Type,Error_Missing_Number_of_Grace_Terms,Error_Missing_Default_BPI_Treatment,Error_Missing_Max_Planned_EMI_Holidays,Error_Missing_Max_Holidays,Error_Missing_EMI_Holiday_Lock_Period,Error_Missing_Planned_EMI_Capitalize,Charges_API_Invocation,Term_Loan,Flexi_Funds,Over_Draft,Variant,Product,Sub_Product,Sub_Variant,Hybrid_Tenure,Interest_Only';

    public static Map <String,String> constants = Utility.getConstants(conLabels);

    //getting the value of constants
    public static Map <String,String> getConstants() {
        return constants;
    }

    // **Validation Method**
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 

        List<String> errorMessages = new List<String>();
    
        // Fetch Loan Application (Opportunity)
        Opportunity loanApplication = [ 
            SELECT Id, Product__c, Final_Amount__c, Sanction_Tenure__c, Branch_Master__c, Variant__c, Final_Tenure__c, Final_Rate_Of_Interest__c,Loan_Hierarchy__c,Split_Parent_Loan_Application__c
            FROM Opportunity 
            WHERE Id = :wrapper.loanApplicationId 
            LIMIT 1
        ];

        String requiredLoanId = wrapper.loanApplicationId;
        if(loanApplication.Loan_Hierarchy__c == 'Child' && loanApplication.Split_Parent_Loan_Application__c != null){
            requiredLoanId = loanApplication.Split_Parent_Loan_Application__c;
        }
    
        // Fetch Loan Transactions
        List<Loan_Transaction__c> loanTransactions = [
            SELECT Id, Disbursement_Amount__c, Allow_Payment_in_Grace_Period__c, Schedule_Method__c, 
                   BPI_Treatment__c, Allow_Grace__c, TDS_Applicable__c, Step_Loan__c, 
                   Grace_Period_Frequency__c, Interest_Frequency__c, Allow_BPI__c, 
                   Allow_Planned_EMI_Holiday__c, Allow_Planned_EMI_holiday_in_Grace__c, 
                   Planned_EMI_Holiday_Method__c, Max_per_Year__c, Max__c, Loan_Start_Date__c, 
                   Lock_Period_Months__c, Capitalize__c, Rate_Type__c,First_Disbursement_Amount__c
            FROM Loan_Transaction__c 
            WHERE Loan_Application__c = :wrapper.loanApplicationId
            AND RecordType.DeveloperName = 'Transaction_Details'
        ];
        
        Loan_Transaction__c loanTransaction = loanTransactions.isEmpty() ? null : loanTransactions[0];

        List<Charges_Insurance__c> chargesList = [Select Id, Category__c, Charges_Fee_Type__c, Final_Amount_INR__c, Default_Amount_INR__c, Requested_Amount_INR__c,
                                                    Default_Percentage__c, Requested_Percentage__c, Total_VAS_Amount__c
                                                    From Charges_Insurance__c Where Loan_Application__c =:requiredLoanId 
                                                    And RecordType.Name = 'Charges' And Charges_Fee_Type__c != '' AND Product_Name__c = :loanApplication.Product__c];

        // **Validate Mandatory (M) Fields**
        if (loanApplication == null) {
            errorMessages.add(constants.get('Error_Loan_Application_not_found') + wrapper.loanApplicationId);
        } else {
            if (loanApplication.Final_Tenure__c == null) {
                errorMessages.add(constants.get('Error_Missing_Final_Tenure'));
            }
            if (loanApplication.Final_Rate_Of_Interest__c == null) {
                errorMessages.add(constants.get('Error_Missing_Final_ROI'));
            }
        }
    
        if (loanTransaction == null) {
            errorMessages.add(constants.get('Error_No_Loan_Transaction_records_found') + wrapper.loanApplicationId);
        }
        else{      
            if(loanTransaction.First_Disbursement_Amount__c == null){
                errorMessages.add('First Disbursement Amount is not populated.');
            }
        }

        for(Charges_Insurance__c rec : chargesList){
            if(rec.Category__c == 'LMS'){
                if(rec.Default_Percentage__c == null){
                    errorMessages.add('Error: Missing Default Percentage for '+ rec.Charges_Fee_Type__c +' in Charges');
                }
                if(rec.Requested_Percentage__c == null){
                    errorMessages.add('Error: Missing Requested Percentage '+ rec.Charges_Fee_Type__c +' in Charges');
                }
            }
            else if(rec.Category__c == 'LOS'){
                if(rec.Charges_Fee_Type__c == 'PROCFEE' && rec.Final_Amount_INR__c == null){
                    errorMessages.add('Error: Missing Final Amount '+ rec.Charges_Fee_Type__c +' in Charges');
                }
                // if(rec.Default_Amount_INR__c == null){
                //     errorMessages.add('Error: Missing Default Amount '+ rec.Charges_Fee_Type__c +' in Charges');
                // }
                // if(rec.Requested_Amount_INR__c == null){
                //     errorMessages.add('Error: Missing Requested Amount '+ rec.Charges_Fee_Type__c +' in Charges');
                // }
            }
            else if(rec.Category__c == 'Insurance'){
                if(rec.Total_VAS_Amount__c == null){
                    errorMessages.add('Error: Missing VAS Amount '+ rec.Charges_Fee_Type__c +' in Charges');
                }
            }
        }
    
        return errorMessages;
    }

    // **Construct Payload Method**
    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {

       try {
            system.debug('wrapper:: '+wrapper);
            // Create a map for easy access where Attribute__c is the key and Value__c is the value
            Map<String, String> defaultValues = new Map<String, String>();
            //Added By Prachi for HL
             Map<String,String> inputMapUtility = new  Map<String,String>();
            Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
            Boolean isHlRelated =isHLRelatedFinal.isHLRelated;

            for(Default_Values_APR_API__mdt metadataRecord : [Select Attribute__c, Value__c From Default_Values_APR_API__mdt]) {
                String value = metadataRecord.Value__c != null ? metadataRecord.Value__c : '';
                defaultValues.put(metadataRecord.Attribute__c, value);
            }

            // Fetch Loan Application (Opportunity)
            Opportunity loanApplication = [ 
                SELECT Id, Product__c, Final_Amount__c, Sanction_Tenure__c, Branch_Master__r.Branch_Code__c, Variant__c, Final_Tenure__c, Final_Rate_Of_Interest__c,Loan_Hierarchy__c,Split_Parent_Loan_Application__c
                FROM Opportunity 
                WHERE Id = :wrapper.loanApplicationId 
                LIMIT 1
            ];
            system.debug('loanApplication:: '+loanApplication);

            String requiredLoanId = wrapper.loanApplicationId;
            if(loanApplication.Loan_Hierarchy__c == 'Child' && loanApplication.Split_Parent_Loan_Application__c != null){
                requiredLoanId = loanApplication.Split_Parent_Loan_Application__c;
            }

            // Query Opportunity Team Members to find the first Sales Manager
            List<OpportunityTeamMember> teamMembers = [
                SELECT Name 
                FROM OpportunityTeamMember 
                WHERE OpportunityId = :wrapper.loanApplicationId 
                AND TeamMemberRole = 'Sales Manager'
                LIMIT 1
            ];

            // Fetch Product2 record based on the Loan Application's Product & Sub Product
            Product2 mainProduct =[SELECT Id,Product_Master__r.PLF_Loan_Type__c from Product2 WHERE RecordType.Name = :constants.get('Product') AND Name = :loanApplication.Product__c AND Loan_Application__c = :wrapper.loanApplicationId LIMIT 1];
            Product2 subProduct = [SELECT Id,Product_Master__r.PLF_Loan_Type__c from Product2 WHERE RecordType.Name = :constants.get('Sub_Product') AND Product__c =:mainProduct.Id AND Loan_Application__c = :wrapper.loanApplicationId LIMIT 1];
            
            List<string> prodVariantAndSubVariant = new List<string>();
            prodVariantAndSubVariant.add(constants.get('Variant'));
            prodVariantAndSubVariant.add(constants.get('Sub_Variant'));

            List<Product2> productRecords = [
                SELECT Id, Name, PLR_Code__c, RecordType.Name,
                PLR_Value__c, BPI_Interest_Days_Basis__c, Interest_Days_Basis__c 
                FROM Product2 
                WHERE Loan_Application__c = :wrapper.loanApplicationId 
                AND RecordType.Name In : prodVariantAndSubVariant AND Product__c = :subProduct.Id
            ];

            String finType = isHlRelated ? subProduct.Product_Master__r.PLF_Loan_Type__c : mainProduct.Product_Master__r.PLF_Loan_Type__c;//Changed By Prachi
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
                }
                else if(prod.RecordType.Name == constants.get('Sub_Variant')){
                        subVariantPrd = prod.Name;
                        hybridTenure = [Select Id, Name from Product2 Where Loan_Application__c = :wrapper.loanApplicationId 
                                        And Sub_Variant__c =: prod.Id And RecordType.Name =: constants.get('Hybrid_Tenure')];
                }
            }

            // Fetch Loan Transaction records for given Loan Application
            List<Loan_Transaction__c> loanTransactions = [
                SELECT Id, Disbursement_Amount__c, Allow_Payment_in_Grace_Period__c, Schedule_Method__c, 
                       BPI_Treatment__c, Allow_Grace__c, TDS_Applicable__c, Step_Loan__c, 
                       Grace_Period_Frequency__c, Interest_Frequency__c, Allow_BPI__c, 
                       Allow_Planned_EMI_Holiday__c, Allow_Planned_EMI_holiday_in_Grace__c,Interest_Due_date__c, 
                       Planned_EMI_Holiday_Method__c, Max_per_Year__c, Max__c, Lock_Period_Months__c, 
                       Capitalize__c,Rate_Type__c,Margin__c, Next_First_Payment_Date__c,
                       First_Disbursement_Amount__c,Payment_Method_Grace_Parameter__c,
                       Elastic_Credit_Line_Type__c,Dropline_Calculated_On__c,Pure_Tenure__c, Loan_Start_Date__c, 
                       Dropline_Tenure__c,Yearly_Selection__c,Half_Yearly_Selection__c,Quarterly_Selection__c
                FROM Loan_Transaction__c 
                WHERE Loan_Application__c = :wrapper.loanApplicationId
                AND RecordType.DeveloperName = 'Transaction_Details'
            ];

            List<Charges_Insurance__c> chargesList = [Select Id, Category__c, Charges_Fee_Type__c, Final_Amount_INR__c, Default_Amount_INR__c, Requested_Amount_INR__c,
                                                        Default_Percentage__c, Requested_Percentage__c, Total_VAS_Amount__c
                                                        From Charges_Insurance__c Where Loan_Application__c =:requiredLoanId 
                                                        And RecordType.Name = 'Charges' And Charges_Fee_Type__c != '' AND Product_Name__c = :loanApplication.Product__c];

            // Use first Loan Transaction record (assuming there will always be at least one)
            Loan_Transaction__c loanTransaction = loanTransactions.isEmpty() ? null : loanTransactions[0];
            String frequencyCode = (loanTransaction.Interest_Frequency__c != null ) ? loanTransaction.Interest_Frequency__c : 'M';
            String dueDateCode = (loanTransaction.Interest_Due_date__c != null ) ? loanTransaction.Interest_Due_date__c : '03';

            String mmCode = '00'; // Default MM for Monthl

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

            Boolean allowGrace = false;
            Boolean allowPlannedEMI = false;
            if(loanTransaction != null && loanTransaction.Allow_Grace__c == true){
                allowGrace = true;
            }
            if(loanTransaction != null && loanTransaction.Allow_Planned_EMI_Holiday__c == true){
                allowPlannedEMI = true;
            }

            decimal otherCharges = 0;
            decimal insCharges = 0;
            decimal amcRevPer = 0;
            decimal amcWaiver = 0;
            decimal processChargesGST = 0;
            decimal processCharges = 0;

            for(Charges_Insurance__c rec : chargesList){
                if(rec.Category__c == 'Insurance'){
                    insCharges += rec.Total_VAS_Amount__c!=null ? rec.Total_VAS_Amount__c : 0;
                }
                else if(rec.Category__c == 'LOS'){
                    if(rec.Charges_Fee_Type__c == 'PROCFEE'){
                        processChargesGST += rec.Final_Amount_INR__c!=null ? rec.Final_Amount_INR__c : 0;
                        processCharges += rec.Default_Amount_INR__c!=null ? rec.Default_Amount_INR__c : 0;
                    }
                }
                else if(rec.Category__c == 'LMS'){
                    if(rec.Charges_Fee_Type__c == 'LOSAMC'){
                        amcRevPer += rec.Requested_Percentage__c;
                        amcWaiver += (rec.Default_Percentage__c!=null ? rec.Default_Percentage__c : 0) - (rec.Requested_Percentage__c!=null ? rec.Requested_Percentage__c : 0);
                    }
                }
                else {
                    otherCharges += rec.Default_Amount_INR__c!=null ? rec.Default_Amount_INR__c : 0;
                }
            }

            // Instantiate Wrapper Object -------------------------------------------------
            APRRequestWrapper req = new APRRequestWrapper();

            req.finAmount = loanTransaction != null ? loanTransaction.First_Disbursement_Amount__c : null;
            req.finAmount = req.finAmount == null ? Decimal.valueOf(defaultValues.get('finAmount')) : Utility.addTwoZeros(req.finAmount);

            req.tenure_in_months = loanApplication.Final_Tenure__c != null ? Integer.valueOf(loanApplication.Final_Tenure__c) : 0;
            req.roi = loanApplication.Final_Rate_Of_Interest__c;
            req.processing_fees_incl_gst = Utility.addTwoZeros(processChargesGST);
            req.insurance_charges = Utility.addTwoZeros(insCharges);
            req.others_charges = Utility.addTwoZeros(otherCharges);
            
            // Convert to JSON
            String requestJSON = JSON.serialize(req);
            System.debug('APR Request JSON: ' + requestJSON);
            return requestJSON;
        
        } catch (Exception e) {
            //throw new AuraHandledException('An error occurred: ' + e.getMessage());
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

    public class APRRequestWrapper {
        //public Boolean ecl_flag;
        public Integer tenure_in_months;
        public Decimal roi;
        public Decimal processing_fees_incl_gst;
        public Decimal insurance_charges;
        public Decimal others_charges;
        public Decimal finAmount;
    }
}