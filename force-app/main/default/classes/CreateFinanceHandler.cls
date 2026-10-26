/*
Version History :
CH01 : 04-08-2025 : Arman :   ##NAInWrapperAHL >> AHL wrapper changes
CH02 : 04-08-2025 : Arman : #VariableTypeChange >> type changed since coming the same in requestJson given by ANIL from GC
CH03 : 04-08-2025 : Arman : TBD >> where mapping needs to be discussed with Team
CH04 : 04-08-2025 : Arman : newMapping >> for new mappings
CH04 : 04-08-2025 : Arman : //NEED TO DISCUSS
CH05 : 10-09-2025 : Arman : Shiva changes on CF >> array mapping change 
*/
public without sharing class CreateFinanceHandler implements IntegrationInterface {

    static String conLabels = 'Loan_Number_already_exists,Error_Loan_Application_not_found,Error_Missing_Loan_Amount,Error_Missing_SanctionTerms,Error_No_Loan_Transaction_records_found,Error_Missing_Scheduling_Method,Error_TDS_Applicable_is_not_selected,Error_Missing_Rate_Type,Error_Missing_Number_of_Grace_Terms,Error_Missing_Default_BPI_Treatment,Error_Missing_Max_Planned_EMI_Holidays,Error_Missing_Max_Holidays,Error_Missing_EMI_Holiday_Lock_Period,Error_Missing_Planned_EMI_Capitalize,Charges_API_Invocation,Term_Loan,Flexi_Funds,Over_Draft,Variant,Product,Sub_Product,Sub_Variant,Interest_Only,Hybrid_Tenure,Hybrid_Only';

    public static Map <String,String> constants = Utility.getConstants(conLabels);

    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String loanApplicationId = wrapper.loanApplicationId;
        Opportunity loanApplication = [SELECT Id, Final_Amount__c,Loan_Purpose__c,LMS_Loan_Reference__c,LMS_Effective_Rate_of_Return__c,Sub_stage__c,Loan_Hierarchy__c,Split_Parent_Loan_Application__c,Split_Parent_Loan_Application__r.LMS_Loan_Reference__c,product__c FROM Opportunity WHERE Id =: loanApplicationId];
        List<String> errorStatusCodeList = Label.BypassCreateFinanceStatusCodes.split(',');
        List<Integration_Details__c> sessionTimeOutIntDetRecord = [SELECT Id FROM Integration_Details__c WHERE Loan_Application__c =:loanApplicationId AND Name = 'Create Finance AHL' AND Status__c IN :errorStatusCodeList ];
        if(sessionTimeOutIntDetRecord.size()>0){
            errorMessages.add('Create Finance has already been hit. Kindly check the Logs.');
        }
        else{
            String disableFlag = Label.CreateFinanceDisableFlag;
            String disableMessage = Label.CreateFinanceDisableMessage;

            if(disableFlag == 'true'){
                errorMessages.add(disableMessage);
            }
            Map<String,String> mapLMS_Id = wrapper.inputMap;
            Boolean isQdp = wrapper.isQdp;
            Map<String,String> mapOfappColIdPlfId = wrapper.mapOfappColIdPlfId;
            // Map<String,List<string>> mapInputJSON = financeJSON(loanApplicationId, mapLMS_Id, isQdp, mapOfappColIdPlfId);
            // List<string> reqBodyList = mapInputJSON.get('errors');

            if(loanApplication.Loan_Hierarchy__c == 'Child' && loanApplication.Split_Parent_Loan_Application__c != null && String.isBlank(loanApplication.Split_Parent_Loan_Application__r.LMS_Loan_Reference__c)){
                errorMessages.add('Please push the Parent Loan Application to LMS first');
            }
            if(!String.isBlank(loanApplication.LMS_Loan_Reference__c)){
                errorMessages.add(constants.get('Loan_Number_already_exists') + loanApplicationId);
            }
            if(loanApplication.Final_Amount__c == null){
                errorMessages.add('Final Amount on Loan Application cannot be null');
            }
            if(loanApplication.Product__c != 'Flexi Loan'){
            List<String> approvalProdValidation = Hl_LoanApprovalController.productValidations(loanApplicationId);
            errorMessages.addAll(approvalProdValidation);
            }
            /*if(String.isNotBlank(loanApplication.Loan_Purpose__c)){
                errorMessages.add('Loan Purpose on Loan Application cannot be blank');
            }*/
            //errorMessages.addAll(reqBodyList);
            System.debug('ERROR MESSAGES IN VALIDATE PAYLOAD++' +errorMessages);
        }
        return errorMessages;
    }


    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
             System.debug('inside JSON: ');
            String loanId = wrapper.loanApplicationId;
            Map<String,String> mapLMS_Id = wrapper.inputMap;
            Boolean isQdp = wrapper.isQdp;
            Map<String,String> mapOfappColIdPlfId = wrapper.mapOfappColIdPlfId;
                Map<String,List<string>> mapInputJSON = financeJSON(loanId, mapLMS_Id, isQdp, mapOfappColIdPlfId);
             System.debug('mapInputJSON JSON: ' + mapInputJSON);
            List<string> reqBodyList = mapInputJSON.get('reqBody');
            String requestJSON = reqBodyList[0];

            System.debug('Request JSON: ' + requestJSON);
            return requestJSON;
        } 
        catch (Exception ex) {
            System.debug('Error: ' + ex.getMessage()+ex.getStackTraceString());
            System.debug('Line: ' + ex.getLineNumber());
            throw new AuraHandledException('Error in Create Finance');
        }
    }

    public static map<String, List<String>> financeJSON(String loanId, Map<String,String> mapLMS_Id, Boolean isQdp, Map<String,String> mapOfappColIdPlfId){
        try {   
            List<String> errorCode = new List<String>();
            //Map<String,String> mapLMS_Id = new Map<String,String>();
            Map<String, Map<String, String>> mapMasterCode =  COMM_UpsertCustomerHandler.getMasterCode();
            Map<String,List<String>> mapInput = new   Map<String,List<String>>(); 
            Map<String,String> inputMapUtility = new  Map<String,String>();
            inputMapUtility.put('oppId',loanId);
            Utility_V1.ProductWrapper wrp = Utility_V1.getProductDetails(inputMapUtility);
            Boolean isHLRelated = wrp.isHLRelated;
            Opportunity loanApp = getLoanApplication(loanId);
            //Split_Parent_Loan_Application__c >> Parent and loanId > child
            String requiredLoanId = loanApp.Split_Parent_Loan_Application__c!=null && loanApp.Loan_Hierarchy__c == 'Child' ? loanApp.Split_Parent_Loan_Application__c : loanId; //FOR MULTIIIIIII Loan >.>.>.>. Armani.
            Boolean isParentLoan = false;
            String productType = 'Parent';
            if(loanApp.Loan_Hierarchy__c == 'Child' && loanApp.Split_Parent_Loan_Application__c != null){
                productType = 'Child';
            }
            else if(loanApp.Loan_Hierarchy__c == 'Parent'){
                isParentLoan = true;
            } 
            List<Product2> subProductForParent = [SELECT Id,Name,Final_ROI__c,Final_Tenure__c,Sanctioned_Tenor__c,Product__r.Name, Final_Loan_Amount__c from Product2 WHERE 
            RecordType.Name = 'Sub Product' AND Product__r.Name = :loanApp.Product__c  AND Product__r.Product_Type__c = 'Parent' AND Loan_Application__c = :requiredLoanId  LIMIT 1];
            
            Map<String, List<Application_Applicant__c>> applicantTypeToApplicantListMap = getApplicantMap(requiredLoanId);
            List<Loan_Transaction__c> loanTransactions = getLoanTransactionByRecType(loanId, 'Transaction_Details');
            Loan_Transaction__c loanTransaction = loanTransactions.isEmpty() ? null : loanTransactions[0];
            List<Instrument_mandate__c> instrumentMandateList =  getInstrumentMandateList(loanId, 'Mandate', 'Repayment Mandate');
            Instrument_mandate__c instrumentMandateObj = instrumentMandateList.isEmpty() ? null : instrumentMandateList[0];
            List<Charges_Insurance__c> chargesInsuranceList = getChargeInsuranceList('Charges', loanId, loanApp.Product__c);
            List<Document_Details__c> covenantDocumentsList = new List<Document_Details__c>();
            if(isHLRelated){
                covenantDocumentsList = getCovenantDocumentList(loanId, Label.CovenantCreateFinance.split(','), true);
            }
            else{
                covenantDocumentsList = getCovenantDocumentList(loanId, new List<String>{'OTC' ,'PDD'}, false);
            }
            List<Application_Collateral__c> appCollateralList = new List<Application_Collateral__c>();
            if(loanApp.Product__c != 'Flexi Loan'){
               appCollateralList = [SELECT Id,Collateral__r.PLF_ID__c,Collateral__r.External_Id__c,Collateral__r.Assigned_Percentage__c,Collateral__r.Name, Collateral__c, HL_Loan_Application__c FROM Application_Collateral__c 
                                                                    WHERE HL_Loan_Application__c=:requiredLoanId ORDER BY CreatedDate DESC];
            }
            List<Instrument_mandate__c> parentInstrumentList = [SELECT Id, Starting_Instrument_Number__c, Bank_Details__r.Account_Holder_Name__c,Bank_Details__r.Account_Number__c,Bank_Details__r.Bank_Master__r.IFSC__c,
                Bank_Details__r.Bank_Master__r.MICR__c,Bank_Details__r.Bank_Master__r.Bank_Code__c,Bank_Details__r.Bank_Master__r.Branch_Code__c,
                (SELECT Id, Purpose__c, Instrument_Date__c, Instrument_Amount__c,Bank_Details__r.Account_Type__c FROM Instrument_Mandate__r WHERE Type_of_Instrument_Record__c = 'Child') FROM 
                Instrument_mandate__c WHERE Loan_Application__c = :loanId AND RecordType.DeveloperName = 'Instrument' AND Type_of_Instrument_Record__c = 'Parent'];
            // Fetch all metadata records at once
            Map<String, Default_Values_LoanSchedule_API__mdt> defaultValuesMap = Default_Values_LoanSchedule_API__mdt.getAll();
            system.debug('wrapper:: '+defaultValuesMap);

             // Create a map for easy access where Attribute__c is the key and Value__c is the value
            Map<String, String> defaultValues = new Map<String, String>();
 
            for (Default_Values_LoanSchedule_API__mdt metadataRecord : defaultValuesMap.values()) {
                String value = metadataRecord.Value__c != null ? metadataRecord.Value__c : '';
                defaultValues.put(metadataRecord.Attribute__c, value);
            }
            // new code logic added for product and sub-product
            Product2 mainProduct =[SELECT Id,Product_Master__r.PLF_Loan_Type__c,BPI_Interest_Days_Basis__c,Name from Product2 WHERE RecordType.Name = 'Product' AND Loan_Application__c =:loanId AND Name = :loanApp.Product__c LIMIT 1];
            Product2 subProduct = [SELECT Id,Product_Master__r.PLF_Loan_Type__c from Product2 WHERE RecordType.Name = 'Sub Product' AND Product__c =:mainProduct.Id LIMIT 1];
            List<Product2> productRecords = [
                SELECT Id, Name, RecordType.Name, PLR_Code__c, Product__r.Product__r.Name,
                PLR_Value__c, BPI_Interest_Days_Basis__c, Interest_Days_Basis__c
                FROM Product2
                WHERE Loan_Application__c =:loanId
                AND RecordType.Name =: constants.get('Variant') AND Product__c = :subProduct.Id
                LIMIT 1
            ];
            String finType = 'AH';  // 
            String profitDaysBasis = '';
            String bpiProfitDaysBasis = '';
            String plrCode = '';
            Decimal plrValue = 0;
            Integer sanctionTenure = 0; //new tag that will handle the sanction tenure that may come from subproduct

            for (Product2 prod : productRecords) {
                plrCode = prod.PLR_Code__c != null ? prod.PLR_Code__c : String.valueOf(Label.Plr_Code); //this will work for HL only as in case of AHL it gets bypassed later on. We re not touching the below loop as of now. Not sure of its implication.
                plrValue = prod.PLR_Value__c != null ? prod.PLR_Value__c : Decimal.valueOf(Label.Plr_Value);
                if (prod.Name == constants.get('Term_Loan')) {
                    profitDaysBasis = prod.Interest_Days_Basis__c != null ? prod.Interest_Days_Basis__c : '30E/360I';
                    bpiProfitDaysBasis = prod.BPI_Interest_Days_Basis__c != null ? prod.BPI_Interest_Days_Basis__c : '30E/360I';
                    break;
                } else if (prod.Name == constants.get('Over_Draft') || prod.Name == constants.get('Flexi_Funds')) {
                    profitDaysBasis = prod.Interest_Days_Basis__c != null ? prod.Interest_Days_Basis__c : 'A/A_365L';
                    bpiProfitDaysBasis = prod.BPI_Interest_Days_Basis__c != null ? prod.BPI_Interest_Days_Basis__c : 'A/A_365L';
                    break;
                }
                else if (prod.Name == 'Affordable Home Loan') {
                    profitDaysBasis = prod.Interest_Days_Basis__c != null ? prod.Interest_Days_Basis__c : 'A/A_365L';
                    bpiProfitDaysBasis = prod.BPI_Interest_Days_Basis__c != null ? prod.BPI_Interest_Days_Basis__c : 'A/A_365L';
                    
                    break;
                }
                else if(prod.Name =='Home Loan' || prod.Name == 'Flexi Loan'){
                    profitDaysBasis = prod.Interest_Days_Basis__c != null ? prod.Interest_Days_Basis__c : 'A/A_365L';
                    bpiProfitDaysBasis = prod.BPI_Interest_Days_Basis__c != null ? prod.BPI_Interest_Days_Basis__c : 'A/A_365L';
                    break;
                }
            }
            finType = isHlRelated ? (String.isNotBlank(Utility_V1.returnFintypeFromTransactionTypeProduct(subProduct.Id)) ? Utility_V1.returnFintypeFromTransactionTypeProduct(subProduct.Id) : '')/*subProduct.Product_Master__r.PLF_Loan_Type__c*/ : mainProduct.Product_Master__r.PLF_Loan_Type__c;
            //profitDaysBasis = prod.Interest_Days_Basis__c != null ? prod.Interest_Days_Basis__c : '30E/360I';
            bpiProfitDaysBasis = mainProduct.BPI_Interest_Days_Basis__c != null ? mainProduct.BPI_Interest_Days_Basis__c : '30E/360I';
            if(!isHLRelated){
                plrCode = loanTransaction.PLR_Code__c !=null ? loanTransaction.PLR_Code__c : String.valueOf(Label.Plr_Code);
                plrValue = loanTransaction.PLR_Value__c !=null ? loanTransaction.PLR_Value__c : Decimal.valueOf(Label.Plr_Value);
            }
            Boolean allowGrace = false;
            Boolean allowPlannedEMI = false;
            String numberOfTermsValue; //using this to add validation of numberOfTermsIn Step Installments

            if(loanTransaction != null && loanTransaction.Allow_Grace__c == true){
                allowGrace = true;
            }
            if(loanTransaction != null && loanTransaction.Allow_Planned_EMI_Holiday__c == true){
                allowPlannedEMI = true;
            }
            String frequencyCode =  (loanTransaction != null && loanTransaction.Interest_Frequency__c  != null )? loanTransaction.Interest_Frequency__c:'M';
            String dueDateCode =  (loanTransaction != null && loanTransaction.Interest_Due_date__c  != null )? loanTransaction.Interest_Due_date__c:'0003';
            
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

            //SELECT Id,Quick_Disbursement__c,STP__c,Process_Stage__c FROM Loan_Transaction__c WHERE RecordType.DeveloperName = 'transaction_details' and Loan_Application__c = '006Bg00000HcyhJIAR'
            // Finance Wrapper obj mapping starts here
            CreateFinanceRequestWrapper fWrap = new CreateFinanceRequestWrapper();
            //fWrap.stp = loanTransaction!=null &&  loanTransaction.Quick_Disbursement__c == true ? loanTransaction.STP__c : true; 
            fWrap.stp = (isQdp == true) ? false : true; 
            fWrap.groupCode = ''; //newMapping
            fWrap.createPLMGroup = false;//newMapping
            fWrap.existingGroup = false;//newMapping
            fWrap.finReference = ''; //NEED TO DISCUSS
            //fWrap.processStage = loanTransaction!=null &&  String.isNotBlank(loanTransaction.Process_Stage__c) ? loanTransaction.Process_Stage__c : '';  //NEED TO DISCUSS
            fWrap.processStage = (isQdp == true) ? 'OPS Maker2' : ''; 
            CreateFinanceRequestWrapper.FinanceDetail fDetail = new CreateFinanceRequestWrapper.FinanceDetail();
            fDetail.applicationNo = String.isNotBlank(loanApp.Name) ? loanApp.Name : ''; //it was null on their side but Anil said to pass LAN no.
            fDetail.finType = finType; 
            if (applicantTypeToApplicantListMap.get('primary') != null 
                && !applicantTypeToApplicantListMap.get('primary').isEmpty()
                && String.isNotBlank(applicantTypeToApplicantListMap.get('primary')[0].Customer_LMS_Id__c)) {
                fDetail.cif = applicantTypeToApplicantListMap.get('primary')[0].Customer_LMS_Id__c;
            } else if (applicantTypeToApplicantListMap.get('primary') != null 
                    && !applicantTypeToApplicantListMap.get('primary').isEmpty()  && mapLMS_Id != null
                    && !mapLMS_Id.isEmpty() 
                    && mapLMS_Id.containsKey(applicantTypeToApplicantListMap.get('primary')[0].Customer__c)) {
                fDetail.cif = mapLMS_Id.get(applicantTypeToApplicantListMap.get('primary')[0].Customer__c);
            } else {
                fDetail.cif = '';
            }
            fDetail.finBranch = Integer.valueOf(loanApp.Branch_Master__r.Branch_Code__c) ??  null ; 
            fDetail.finStartDate = loanTransaction!=null && loanTransaction.Loan_Start_Date__c!=null ? formatDateString(loanTransaction.Loan_Start_Date__c) : '';
            fDetail.finAmount = (loanTransaction != null) && loanTransaction.First_Disbursement_Amount__c!=null ? Utility.addTwoZeros(loanTransaction.First_Disbursement_Amount__c).setScale(0).longValue() : 0;  //since integer can hold max 1410065408 >> so a sum of 1 crore or 10 crore in this field will return this value in Json
            fDetail.finAssetValue = (loanTransaction != null) && loanApp.Final_Amount__c!=null  ?  Utility.addTwoZeros(loanApp.Final_Amount__c).longValue() : 0;  
            fDetail.finRepayMethod = (loanTransaction != null) ? loanTransaction.Payment_Method__c : ''; 
            fDetail.alwManualSteps = (loanTransaction != null && loanTransaction.Step_Loan__c) ? loanTransaction.Step_Loan__c : false;
            fDetail.stepFinance = (loanTransaction != null && loanTransaction.Step_Loan__c) ? loanTransaction.Step_Loan__c : false;                
            fDetail.allowGrcRepay = (loanTransaction != null && allowGrace == true) ? loanTransaction.Allow_Payment_in_Grace_Period__c : false;  
            Integer graceFreq = loanTransaction.Grace_Period_Frequency__c != null ? Integer.valueOf(loanTransaction.Grace_Period_Frequency__c) : 0;
           // if(finType == 'HL' || finType =='AH' || finType == 'FL' || finType == 'AL'){
                if(productType == 'Child'){
                    sanctionTenure = loanApp.Final_Tenure__c != null ? Integer.valueOf(loanApp.Final_Tenure__c) : Integer.valueOf(loanApp.Sanction_Tenure__c);
                    if (loanTransaction.Allow_Grace__c == true) {
                        fDetail.numberOfTerms = String.valueOf(sanctionTenure - graceFreq);
                    } else {
                        fDetail.numberOfTerms = String.valueOf(sanctionTenure);
                    }
                }
                else{
                    if(subProductForParent.size() > 0){
                        sanctionTenure = subProductForParent[0].Final_Tenure__c != null ? Integer.valueOf(subProductForParent[0].Final_Tenure__c) : Integer.valueOf(subProductForParent[0].Sanctioned_Tenor__c);
                        if (loanTransaction.Allow_Grace__c == true) {
                            fDetail.numberOfTerms = String.valueOf(sanctionTenure - graceFreq);
                        } else {
                            fDetail.numberOfTerms = String.valueOf(sanctionTenure);
                        }
                    }
                }////////////////
                /*if (loanTransaction.Allow_Grace__c == true) {
                    Integer sanctionTenure = loanApp.Sanction_Tenure__c != null ? Integer.valueOf(loanApp.Sanction_Tenure__c) : 0;
                    Integer graceFreq = loanTransaction.Grace_Period_Frequency__c != null ? Integer.valueOf(loanTransaction.Grace_Period_Frequency__c) : 0;
                    fDetail.numberOfTerms = String.valueOf(sanctionTenure - graceFreq);
                } else {
                    fDetail.numberOfTerms = loanApp.Sanction_Tenure__c != null ? String.valueOf(loanApp.Sanction_Tenure__c) : '0';
                }*/
            //} 
            //special cases below >> SINCE THIS WAS A BL SCENARIO SO WE'VE COMMENT IT
            /*else {
                if(loanTransaction.Elastic_Credit_Line_Type__c != null && loanTransaction.Elastic_Credit_Line_Type__c == 'D'){
                    fDetail.numberOfTerms = String.valueOf(loanTransaction.Dropline_Tenure__c);
                } else if(loanTransaction.Elastic_Credit_Line_Type__c != null && loanTransaction.Elastic_Credit_Line_Type__c == 'H'){
                    fDetail.numberOfTerms = String.valueOf(loanTransaction.Dropline_Tenure__c);
                }
            }*/
            numberOfTermsValue = fDetail.numberOfTerms;

            if(finType == 'BD'){
                if(loanTransaction.Elastic_Credit_Line_Type__c != null && (loanTransaction.Elastic_Credit_Line_Type__c == 'P' || loanTransaction.Elastic_Credit_Line_Type__c == 'D')){
                    fDetail.allowGrcPeriod = false;
                }else{
                    fDetail.allowGrcPeriod = true;
                }
            }else{
                fDetail.allowGrcPeriod = loanTransaction != null ? loanTransaction.Allow_Grace__c : false;
            }
            if(finType == 'BD' && loanTransaction.Elastic_Credit_Line_Type__c != null && (loanTransaction.Elastic_Credit_Line_Type__c == 'P' || loanTransaction.Elastic_Credit_Line_Type__c == 'H')){
                fDetail.grcTerms = Integer.valueOf(loanTransaction.Pure_Tenure__c);
                //fDetail.grcPftDueFrq = (loanTransaction != null && loanTransaction.Step_Loan__c == false) ? finalFrequencyCode: '';  ##NAInWrapperAHL
            }else if( allowGrace == true){
                fDetail.grcTerms = Integer.valueOf(loanTransaction.Grace_Period_Frequency__c) ?? 0 ;
                if (fDetail.grcTerms == 0) { errorCode.add(validationMessage('Grace Terms in Finance Detail')); //#VariableTypeChange
            }
            }/*else{
                fDetail.grcTerms = 0;
            }*/
            fDetail.scheduleMethod =loanTransaction != null /*&& loanTransaction.Step_Loan__c == true*/ ? loanTransaction.Schedule_Method__c : ''; 
            fDetail.repayPftFrq =  (loanTransaction != null /*&& loanTransaction.Step_Loan__c == false*/) ? finalFrequencyCode: ''; 
            fDetail.repayFrq =   (loanTransaction != null /*&& loanTransaction.Step_Loan__c == false*/) ? finalFrequencyCode: '';    
            fDetail.repayRvwFrq =  (loanTransaction != null/* && loanTransaction.Step_Loan__c == false*/) ? finalFrequencyCode: '';  
            fDetail.nextRepayDate = '';     //tobeblank      
            fDetail.nextRepayPftDate = ''; //tobeblank
            fDetail.nextRepayRvwDate = '';            
            if(!isHLRelated){
            fDetail.finPurpose = (loanApp.Loan_Purpose__c != null) ? mapMasterCode.get('Loan Purpose'.toLowerCase()).get(loanApp.Loan_Purpose__c.toLowerCase()) : '' ;   
            }
            else{
                List<Product2> loanProductList = new List<Product2>();
                if(loanApp.Loan_Hierarchy__c!= null){
                    loanProductList = [SELECT Id,Name,RecordType.Name,Product__r.Product__r.Name,Product__r.Name FROM Product2 WHERE Loan_Application__c  =:loanId AND Product__r.Product__r.Name=:loanApp.Product__c AND ((Loan_Application__r.Loan_Hierarchy__c ='Parent' AND Product__r.Product__r.Product_Type__c = 'Parent') OR (Loan_Application__r.Loan_Hierarchy__c = 'Child' AND Product__r.Product__r.Product_Type__c = 'Child' ))]; 
                }else{
                    loanProductList = [SELECT Id,Name,RecordType.Name,Product__r.Product__r.Name,Product__r.Name FROM Product2 WHERE Loan_Application__c  =:loanId AND Product__r.Product__r.Name=:loanApp.Product__c AND Product__r.Product__r.Product_Type__c='Parent']; 
                }
                Product2 loanTransactionProduct = new Product2();
                Product2 loanPurposeProduct = new Product2();
                for(Product2 iterProd : loanProductList){
                    if(iterProd.RecordType.Name == 'Transaction Type'){
                        loanTransactionProduct = iterProd;
                    }
                    else if(iterProd.RecordType.Name == 'Loan Purpose'){
                        loanPurposeProduct = iterProd;
                    }
                } 
                fDetail.finPurpose = '';       
                if(loanTransactionProduct != null && loanPurposeProduct != null){   
                    List<PLF_Master__c> plfList = [SELECT Id,Transaction_Type__c, Description__c, FICO_Code__c  FROM PLF_Master__c WHERE Master_Type__c = 'Loan Purpose' AND Transaction_Type__c != null and Transaction_Type__c =: loanTransactionProduct.Name and Description__c =: loanPurposeProduct.Name];
                    if(!plfList.isEmpty()){
                        fDetail.finPurpose = plfList[0].FICO_Code__c != null ? plfList[0].FICO_Code__c : '';
                    }
                }
            }    
            fDetail.fixedRateTenor = 0; //will be bydefault 0 as per mail on 28th August 2025 : defaultValues.containsKey('fixedRateTenor') && String.isNotBlank(defaultValues.get('fixedRateTenor')) ? Integer.valueof(defaultValues.get('fixedRateTenor')) : 0;
            fDetail.reqLoanAmt = (loanApp.Requested_Amount__c != null) ? Utility.addTwoZeros(loanApp.Requested_Amount__c).longValue() : 0;  
            fDetail.reqLoanTenor = String.valueOf((Integer)loanApp.Final_Tenure__c) ?? '';//#VariableTypeChange
            fDetail.sourChannelCategory = ''; //anil to confirm
            fDetail.offerId = ''; //anil to confirm
            fDetail.sourcingBranch = Integer.valueOf(loanApp.Branch_Master__r.Branch_Code__c) ?? null; //#VariableTypeChange
            fDetail.reqTerms=String.valueOf((Integer)loanApp.Final_Tenure__c); //newMapping
            fDetail.parentLoanReference = loanApp.Split_Parent_Loan_Application__c!=null && loanApp.Loan_Hierarchy__c == 'Child' ? String.isNotBlank(loanApp.Split_Parent_Loan_Application__r.LMS_Loan_Reference__c) ? loanApp.Split_Parent_Loan_Application__r.LMS_Loan_Reference__c : '' : '';
            fDetail.nextGrcPftDate=''; //will remain blank
            fDetail.maturityDate='';
            fDetail.interestType=''; //newMapping probably from Product_Master__c NNEDS TO BE DISCUSSED.
            fDetail.grcSchdMthd =(loanTransaction != null && allowGrace == true) ? loanTransaction.Payment_Method_Grace_Parameter__c : '';
            fDetail.grcRateBasis = (loanTransaction != null && allowGrace == true) ? loanTransaction.Step_Loan__c == true ? loanTransaction.Rate_Type__c : 'R' :'';
            fDetail.grcPftRate =0;
            fDetail.grcPftFrq = (loanTransaction != null && allowGrace == true) ? finalFrequencyCode : '';
            fDetail.grcMargin = (loanTransaction != null && allowGrace == true) ? loanTransaction.Margin__c - plrValue : 0;
            fDetail.grcCpzFrq = (loanTransaction != null && allowGrace == true && loanTransaction.Capitalize__c == true && loanTransaction.Step_Loan__c == false) ? finalFrequencyCode : ''; //from LoanSchedulerHandler
            fDetail.grcBaseRate=plrCode;
            fDetail.repayBaseRate = plrCode;
            fDetail.finCurrAssetValue =0;
            fDetail.dsaCode=defaultValues.containsKey('dsaCode') ? defaultValues.get('dsaCode') : ''; //NEED TO DISCUSS
            fDetail.dmaCode =''; //NEED TO DISCUSS
            fDetail.dftBpiTreatment =  (loanTransaction != null ) ? String.isNotBlank(loanTransaction.BPI_Treatment__c) && loanTransaction.Allow_BPI__c == true ?  loanTransaction.BPI_Treatment__c : 'N' : 'N';
            fDetail.alwBpiTreatment =  (loanTransaction != null ) ? loanTransaction.Allow_BPI__c : false;
            fDetail.bpiPftDaysBasis = bpiProfitDaysBasis;
            //fDetail.quickDisb = loanTransaction != null ? loanTransaction.Quick_Disbursement__c : false;
            fDetail.quickDisb = isQdp;
            fDetail.allowOCR = loanApp.Allow_OCR__c;
            fDetail.repayMargin = loanTransaction != null ? loanTransaction.Margin__c - plrValue : 0;

            // Add validation check 
            
            if (String.isNotBlank(fDetail.reqLoanTenor) && Integer.valueOf(fDetail.reqLoanTenor) == 0) { errorCode.add(validationMessage('Requested Tenure in Months')); //#VariableTypeChange
            }
                    
            // Add Steps conditinally, if alwManualSteps is true *****
            Integer noOfSteps = 0;
            Integer noOfGrcSteps = 0;
            Integer installmentSum =0;
            List<CreateFinanceRequestWrapper.Step> stepList = new List<CreateFinanceRequestWrapper.Step>();

            if(fDetail.stepFinance){
                List<Loan_Transaction__c> stepRecList = getLoanTransactionByRecType(loanId, 'Step_Loan_Details');

                for (Loan_Transaction__c step : stepRecList) {
                    if(step.Step_Specifier__c != null && step.Step_Specifier__c != 'Grace'){
                        noOfSteps++;
                    }
                    if (step.Step_Specifier__c != null && step.Step_Specifier__c == 'Grace') {
                        noOfGrcSteps++;
                    }
                }
                fDetail.noOfSteps = Integer.valueOf(noOfSteps);
                fDetail.noOfGrcSteps = Integer.valueOf(noOfGrcSteps); 
                
                Integer graceCounter = 1;
                Integer regularCounter = 1; 
                Integer stepNumberAutoCal = 0;
                Decimal tenorSplitSum = 0.00;
                Decimal margin = 0.00;
                for (Loan_Transaction__c step : stepRecList) {
                    CreateFinanceRequestWrapper.Step stepDetail = new CreateFinanceRequestWrapper.Step();
                    Boolean isGrace = (step.Step_Specifier__c != null && step.Step_Specifier__c == 'Grace');
                    stepDetail.stepNumber = isGrace ? graceCounter++ : regularCounter++;
                    stepDetail.tenorSplitPerc = step.Tenor_Split__c.setScale(2)  ?? 0.00;
                    stepDetail.rateMargin = step.Margin__c!=null ? Integer.valueOf(step.Margin__c) : 0;
                    stepDetail.emiSplitPerc = 0;
                    stepDetail.steppedEMI = step.Step_Amount__c!=null ? addTwoZeros(step.Step_Amount__c) : 0 ;
                    stepDetail.stepSpecifier = step.Step_Specifier__c == 'Grace' ? 'G': 'R';
                    stepDetail.autoCal = (step.Auto_Cal__c ? 1 :0);
                    stepDetail.installments =  step.Loan_Tenor__c!=null ? (Integer)step.Loan_Tenor__c : 0; //cannot be blank
                    stepNumberAutoCal = (Integer)stepDetail.stepNumber; //Armani : to assign the last tenot split
                    tenorSplitSum += step.Tenor_Split__c.setScale(2);
                    margin = stepDetail.rateMargin; //the last valuw will get assigned>> putting this till logic for margin comes for the last step
                    stepList.add(stepDetail);
                }
                Decimal totalStepInstallments = 0;
                for (CreateFinanceRequestWrapper.Step s : stepList) {
                    if (s.installments != null) {
                        totalStepInstallments += s.installments;
                    }
                }
                System.debug('Total step Installments: ' + totalStepInstallments);
                if (totalStepInstallments < sanctionTenure) { //loanRequest.financeDetail.numberOfTerms) { //this is coming from application right now >> Armani
                    CreateFinanceRequestWrapper.Step stepDetail = new CreateFinanceRequestWrapper.Step();
                    stepDetail.stepNumber = regularCounter++;
                    stepDetail.tenorSplitPerc = 100.00 - tenorSplitSum;
                    stepDetail.rateMargin = Integer.valueOf(margin);
                    stepDetail.emiSplitPerc = 0;
                    stepDetail.steppedEMI = addTwoZeros(0);
                    stepDetail.stepSpecifier = 'R'; 
                    stepDetail.autoCal = 0;
                    stepDetail.installments = Integer.valueOf(sanctionTenure - totalStepInstallments); //removing grace frequenccy for the last installment loanRequest.financeDetail.numberOfTerms
                    stepList.add(stepDetail);
                    fDetail.noOfSteps = noOfSteps + 1;
                }
                /////////////////     
                // Arman commenting this as making it same as RPS and SL. The Grace starts with 1 and Repayment starts with 1 in RPS> it was not here in CF.
               /* for(Loan_Transaction__c step: stepRecList){
                    CreateFinanceRequestWrapper.Step stepDetail = new CreateFinanceRequestWrapper.Step();
                    stepDetail.stepNumber = (Integer)step.Step_Number__c;
                    stepDetail.tenorSplitPerc = step.Tenor_Split__c.setScale(2)  ?? 0.00;
                    stepDetail.rateMargin = step.Margin__c!=null ? Integer.valueOf(step.Margin__c) : 0;
                    stepDetail.emiSplitPerc = 0;
                    stepDetail.steppedEMI = step.Step_Amount__c!=null ? addTwoZeros(step.Step_Amount__c) : 0 ;
                    stepDetail.stepSpecifier = (step.Step_Specifier__c != null && step.Step_Specifier__c == 'Grace') ? 'G' : 'R';
                    stepDetail.autoCal = 0;
                    stepDetail.installments = step.Loan_Tenor__c!=null ? (Integer)step.Loan_Tenor__c : 0; //cannot be blank
                    installmentSum = (step.Step_Specifier__c != null && step.Step_Specifier__c != 'Grace') ? installmentSum + stepDetail.installments :installmentSum+0;
                    if(stepDetail.installments==0){ errorCode.add(validationMessage('stepDetail.installments'));  }
                    stepList.add(stepDetail);
                } 
                     //TOBECHECK           
                if( numberOfTermsValue!= String.valueOf(installmentSum)){
                 errorCode.add('NumberOfTerms is not equal to the sum of Step Installments.'); 
                }*/
                /////////////////////////////////
            }  
            
            // Cheque Headers
            
            List<CreateFinanceRequestWrapper.ChequeHeaders> chequeHeaders = new List<CreateFinanceRequestWrapper.ChequeHeaders>();
            if(!parentInstrumentList.isEmpty()){
                // Loop through each parent
                for (Instrument_mandate__c parentInstrument : parentInstrumentList) {
                    if(parentInstrument.Instrument_Mandate__r.size()>0){
                        CreateFinanceRequestWrapper.ChequeHeaders chequeHeader = new CreateFinanceRequestWrapper.ChequeHeaders();
                        chequeHeader.noOfCheques = String.valueOf(parentInstrument.Instrument_Mandate__r.size());
                        chequeHeader.chequeSerialNo = String.valueOf(parentInstrument.Starting_Instrument_Number__c);
                        chequeHeader.accHolderName = parentInstrument.Bank_Details__c!=null ? String.isNotBlank(parentInstrument.Bank_Details__r.Account_Holder_Name__c) ? parentInstrument.Bank_Details__r?.Account_Holder_Name__c.trim().replaceAll('[^A-Za-z0-9 ]', '') : '' : '';
                        chequeHeader.accountNo = parentInstrument.Bank_Details__r?.Account_Number__c;
                        if(parentInstrument.Bank_Details__r?.Bank_Master__r?.Bank_Code__c!=null &&  parentInstrument.Bank_Details__r?.Bank_Master__r?.Branch_Code__c!=null){
                            chequeHeader.bankCode = parentInstrument.Bank_Details__r?.Bank_Master__r?.Bank_Code__c ?? '';
                            chequeHeader.branchCode = parentInstrument.Bank_Details__r?.Bank_Master__r?.Branch_Code__c ?? '';
                            chequeHeader.ifsc = '';
                            chequeHeader.micr = '';
                        }
                        else{
                            chequeHeader.ifsc = parentInstrument.Bank_Details__r?.Bank_Master__r?.IFSC__c ?? '';
                            chequeHeader.micr = parentInstrument.Bank_Details__r?.Bank_Master__r?.MICR__c ?? '';
                            chequeHeader.bankCode = '';
                            chequeHeader.branchCode = '';
                        }
                        chequeHeader.chequeDetails = new List<CreateFinanceRequestWrapper.ChequeDetails>();

                        // ChequeDetails
                        List<Instrument_mandate__c> childInstruments = parentInstrument.Instrument_Mandate__r;

                        if (childInstruments != null && !childInstruments.isEmpty()) {
                            for (Instrument_mandate__c child : childInstruments) {
                                if (child == null) 
                                {continue;}
                                CreateFinanceRequestWrapper.ChequeDetails detail= new CreateFinanceRequestWrapper.ChequeDetails();
                                if(child.Purpose__c == 'Security'){
                                    detail.chequeType = 'UDC';
                                }
                                else{
                                    detail.chequeType = 'PDC';
                                }
                                detail.chequeDate =  formatDateString(child.Instrument_Date__c) ?? '';
                                detail.amount = child.Instrument_Amount__c!=null ? String.valueOf(addTwoZeros(child.Instrument_Amount__c)) : '';
                                detail.accountType =  child.Bank_Details__r.Account_Type__c!=null ? mapMasterCode.get('Bank Account Type'.toLowerCase()).get(child.Bank_Details__r.Account_Type__c.toLowerCase()) : ''; //SA
                                detail.docFormat = '';
                                detail.docName   = '';
                                detail.docContent = '';
                                chequeHeader.chequeDetails.add(detail);
                            }
                        }
                        chequeHeaders.add(chequeHeader);
                    }
                }
            }
            fWrap.chequeHeaders = chequeHeaders;
            
            //OCR 
            if(loanApp.Allow_OCR__c == true){
                if((String.isNotBlank(loanApp.Loan_Hierarchy__c) && loanApp.Loan_Hierarchy__c!= 'Child') || String.isBlank(loanApp.Loan_Hierarchy__c)){
                    CreateFinanceRequestWrapper.FinOCRHeader ocrHeader = new CreateFinanceRequestWrapper.FinOCRHeader();
                    List<CreateFinanceRequestWrapper.OCRDetails> ocrDetailsList = new List<CreateFinanceRequestWrapper.OCRDetails>();
                    List<CreateFinanceRequestWrapper.OCRCaptureDetails> ocrCaptureList = new List<CreateFinanceRequestWrapper.OCRCaptureDetails>();
                    List<Loan_Transaction__c> ocrHeaderRecordList = getLoanTransactionByRecType(requiredLoanId, 'OCR'); //changin recordId because of {"returnCode":"92021","returnText":"No value should be provided for OCRDetails when parentloanref is provided in the request."}
                    if(ocrHeaderRecordList.size()>0){
                        ocrHeader.ocrID = ocrHeaderRecordList[0].OCR_ID__c;
                        ocrHeader.totalDemand = ocrHeaderRecordList[0].Total_Demand__c!=null ? String.valueOf(ocrHeaderRecordList[0].Total_Demand__c) : ''; //adding two zeross as per sample json

                        //OCR Details
                        List<Loan_Transaction__c> ocrDetailsTransactionList = getLoanTransactionByRecType(requiredLoanId, 'OCR_Steps');
                        for(Loan_Transaction__c itrOcrDet : ocrDetailsTransactionList){
                            CreateFinanceRequestWrapper.OCRDetails ocrDetail = new CreateFinanceRequestWrapper.OCRDetails();
                            ocrDetail.version = 1; //default 1
                            ocrDetail.stepSequence = Integer.valueOf(itrOcrDet.Step_Sequence__c);
                            ocrDetail.customerContribution = itrOcrDet.Customer_Contribution__c!=null ? itrOcrDet.Customer_Contribution__c : 0.00;
                            ocrDetail.financerContribution = itrOcrDet.Financer_Contribution__c!=null ? itrOcrDet.Financer_Contribution__c : 0.00;
                            ocrDetail.contributor = itrOcrDet.Contributor__c;
                            ocrDetailsList.add(ocrDetail);
                        }
                        //OCR Capture Details   
                        List<Loan_Transaction__c> ocrCaptureTransactionList = getLoanTransactionByRecType(requiredLoanId, 'OCR_Capture_Transaction');    
                        for(Loan_Transaction__c itrOcrCap : ocrCaptureTransactionList){
                            
                            if(itrOcrCap.isParent__c == false){ //done to remove the parent record of ocr capture since it is indulged in the same RC with isParent__c field as true
                                CreateFinanceRequestWrapper.OCRCaptureDetails ocrCapture = new CreateFinanceRequestWrapper.OCRCaptureDetails();
                                ocrCapture.receiptNumber = Integer.valueOf(itrOcrCap.Step_Sequence__c);
                                //ocrCapture.demandAmount = itrOcrCap.Builder_Demand__c!=null ? Integer.valueOf(addTwoZeros(itrOcrCap.Builder_Demand__c)): 0; //as discussed with Shiva on SFHL-225 on 14th Nov 2025: we have removed two zeroes for builder demand and paid amount
                                ocrCapture.demandAmount = itrOcrCap.Builder_Demand__c != null ? Utility.addTwoZeros(itrOcrCap.Builder_Demand__c).setScale(0).longValue(): 0;
                                ocrCapture.paidAmount = itrOcrCap.Paid_Amount__c!=null ? String.valueOf(addTwoZeros(itrOcrCap.Paid_Amount__c)) : '0'; 
                                ocrCapture.receiptDate = itrOcrCap.Receipt_Date__c != null ? formatDateString(itrOcrCap.Receipt_Date__c) : '';
                                //DateTime.newInstance(itrOcrCap.Receipt_Date__c.year(), itrOcrCap.Receipt_Date__c.month(), itrOcrCap.Receipt_Date__c.day(), 0, 0, 0).format('yyyy-MM-dd\'T\'HH:mm:ss') : '';
                                ocrCapture.remarks = itrOcrCap.Remark__c;
                                ocrCaptureList.add(ocrCapture);
                            }
                        }
                    }
                    ocrHeader.OCRDetails = ocrDetailsList;
                    ocrHeader.OCRCaptureDetails = ocrCaptureList;
                    fwrap.finOCRHeader = ocrHeader;
                }
            }

            // Fees
            List<CreateFinanceRequestWrapper.Fees> feesList = new List<CreateFinanceRequestWrapper.Fees>();
            List<CreateFinanceRequestWrapper.FinFeeReceipts> feeRecList = new List<CreateFinanceRequestWrapper.FinFeeReceipts>();
            for(Charges_Insurance__c ins : chargesInsuranceList){
                CreateFinanceRequestWrapper.FinFeeReceipts feeRecObj = new CreateFinanceRequestWrapper.FinFeeReceipts();
                CreateFinanceRequestWrapper.Fees feeObj = new CreateFinanceRequestWrapper.Fees();
                feeObj.feeCategory = 'FC';
                if(ins.Category__c == 'LOS'){
                    //Decimal waiverAmt = (ins.Allocated_Amount__c ?? 0) - ((ins.Adjusted_Login_Fee__c ?? 0) + (ins.Requested_Amount_INR__c ?? 0));
                    Decimal feeAmount = (ins.Allocated_Amount__c != null) ? ins.Allocated_Amount__c : 0;
                    feeObj.feeAmount = String.valueOf(addTwoZeros(feeAmount)) ?? ''; //#VariableTypeChange
                    feeObj.waiverAmount =  (ins.Waived_Charge_Amount__c!=null && ins.Waived_Charge_Amount__c != 0) ? String.valueOf(addTwoZeros(ins.Waived_Charge_Amount__c)) : '0'; //#VariableTypeChange
                    feeObj.feeCode = ins.Charges_Fee_Type__c ?? '';  // comment >> to be checked what to pass >> for LOS requirements
                } else {
                    Decimal feeAmount = (ins.Total_VAS_Amount__c != null) ? ins.Total_VAS_Amount__c : 0;
                    feeObj.feeAmount = String.valueOf(addTwoZeros(feeAmount)) ?? ''; //#VariableTypeChange
                    feeObj.feeCode = ins.VAS_Code__c ?? ''; 
                    feeObj.waiverAmount = '0';
                }
                //feeRecList.add(feeRecObj); > commenting this as feeRecObj has no fields
               
                feeObj.paidAmount = '0';//ins.Adjusted_Login_Fee__c!=null ? String.valueOf(addTwoZeros(ins.Adjusted_Login_Fee__c)) : '0';
                feeObj.feeMethod = ins.Fee_Method__c; //self funded cases should not go to CF? GC team will confirm.
                feeObj.scheduleTerms = 0; 
                feeObj.feeBalance = 0; //ins.Requested_Amount_INR__c!=null && ins.Adjusted_Login_Fee__c!=null ? addTwoZeros(ins.Requested_Amount_INR__c) : 0;
                feeObj.version = 1;           
                feeObj.finFeeReceipts = feeRecList;                    
               
                
                feesList.add(feeObj);
                //assigning it here as moved to fwrap //CH03

                if(feeObj.feeMethod == ''){ errorCode.add(validationMessage('feeMethod'));  }
            }
            //fWrap.fees = feesList; //CH05 >> 

            // Vas         
            List<String> vasCodes = new List<String>();
            List<CreateFinanceRequestWrapper.Vas> vasList = new List<CreateFinanceRequestWrapper.Vas>();  
            List<Charges_Insurance__c> InsuranceList = getChargeInsuranceList('Insurance', loanId, loanApp.Product__c);          
           
            for(Charges_Insurance__c insObj : InsuranceList){
                CreateFinanceRequestWrapper.Vas vasObj = new CreateFinanceRequestWrapper.Vas();
                vasCodes.add(insObj.VAS_Code__c);
                vasObj.product = insObj.VAS_Code__c;
                vasObj.postingAgainst = 'Loan';
                
                //if(constants.get('Finance_API_Version') == '0'){
                   // vasObj.totalVASAmount = null; //Arman: why has this been commented? Who did this?
                    vasObj.totalVASAmount = (insObj.Total_VAS_Amount__c != null) ?  String.valueOf(addTwoZeros(insObj.Total_VAS_Amount__c)) : '0'; //#VariableTypeChange Int to Str
                    vasObj.selfFundedAmount = (insObj.Fee_Method__c == 'Self funded' && String.isNotBlank(insObj.Self_Funded_Amount__c)) ? String.valueOf(addTwoZeros(Integer.valueOf(insObj.Self_Funded_Amount__c))) : '0';//#VariableTypeChange Int to String
                    vasObj.waivedAmt = '';
                /*} else {
                    vasObj.totalVASAmount = (insObj.Total_VAS_Amount__c != null) ?  String.valueOf(addTwoZeros(insObj.Total_VAS_Amount__c)) : '0'; //vas.fee changed to vas.totalVASAmount //#VariableTypeChange
                    vasObj.waivedAmt = (insObj.Self_Funded_Amount__c != null) ? String.valueOf(Integer.valueOf(insObj.Self_Funded_Amount__c)) : '0'; //#VariableTypeChange
                    vasObj.selfFundedAmount = '';
                }*/
                
                vasObj.feePaymentMode =  'Cash'; //insObj.Fee_Method__c;   
                vasObj.valueDate =  formatDateString(insObj.Value_Date__c); 

                
                Decimal totalVAS = insObj.Total_VAS_Amount__c != null ? insObj.Total_VAS_Amount__c : 0;
                Decimal selfFunded = 0;

                if (String.isNotBlank(insObj.Self_Funded_Amount__c)) {
                    try {
                        selfFunded = Decimal.valueOf(insObj.Self_Funded_Amount__c);
                    } catch (Exception e) {
                        System.debug('error in 472' +e.getStackTraceString());
                        selfFunded = 0;
                    }
                }

                Decimal renewalAmount = totalVAS - selfFunded;
                //vasObj.renewalFee = String.valueOf(addTwoZeros(renewalAmount));
                vasObj.renewalFee = '0';
                vasObj.fee = '';//(renewalAmount != null) ?  String.valueOf(addTwoZeros(renewalAmount)) : '0';


               // vasObj.renewalFee = insObj.Total_VAS_Amount__c!=null ? String.isNotBlank(insObj.Self_Funded_Amount__c) ? String.valueOf(addTwoZeros(insObj.Total_VAS_Amount__c - Integer.valueOf(insObj.Self_Funded_Amount__c))) : String.valueOf(addTwoZeros(insObj.Total_VAS_Amount__c)) :  '0'; //TO BE CHECKED '20000000'; 
                vasObj.entitycode = 'GHF';
                vasObj.terminsurancelien = 'false'; //false
                vasObj.medicalstatus = '';
                vasObj.medicalapplicable = 'false'; //false
                vasObj.status = '';
                vasObj.count = '';    
                
                //EXTENDED FIELDS FOR VAS
                List<CreateFinanceRequestWrapper.ExtendedFields> extFldList = new List<CreateFinanceRequestWrapper.ExtendedFields>();              
            
                if(!InsuranceList.isEmpty()){
                    //Charges_Insurance__c insObj =  InsuranceList[0];  
                    Map<String, Object> fieldsToValue = insObj.getPopulatedFieldsAsMap();            
    
                    for (String fieldName : fieldsToValue.keySet()){
                        CreateFinanceRequestWrapper.ExtendedFields extFld = new CreateFinanceRequestWrapper.ExtendedFields();
                        
                        if(fieldName == 'Nom_Relationship__c'){
                            extFld.fieldName = (insObj.VAS_Code__c != null) ? mapMasterCode.get('VAS Code'.toLowerCase()).get(insObj.VAS_Code__c.toLowerCase()) : '' ; 
                            extFld.fieldValue = insObj.Nom_Relationship__c != null ? mapMasterCode.get('Nom Relationship'.toLowerCase()).get(insObj.Nom_Relationship__c.toLowerCase()) : '' ; //(insObj.Nom_Relationship__c != null) ? insObj.Nom_Relationship__c : '';
                        if(String.isBlank(extFld.fieldValue)) { errorCode.add(validationMessage(extFld.fieldName)); }
                        } else if(fieldName == 'Nominee_Name__c'){
                            extFld.fieldName = 'NOMINEENAME';
                            extFld.fieldValue = String.valueOf(insObj.Nominee_Name__c);
                        if(String.isBlank(extFld.fieldValue)) { errorCode.add(validationMessage('NOMINEENAME')); }
                        } else if(fieldName == 'Nominee_DOB__c'){
                            extFld.fieldName = 'NOMINEEDOB';  
                            String nomDOBFld = formatDateString(insObj.Nominee_DOB__c); 
                            extFld.fieldValue = nomDOBFld; 
                            if(String.isBlank(extFld.fieldValue)) { errorCode.add(validationMessage('NOMINEEDOB')); }
                        } else if(fieldName == 'Date_of_Birth__c'){
                            extFld.fieldName = 'DATEOFBIRTH';
                            String dobFld = formatDateString(insObj.Date_of_Birth__c); 
                            extFld.fieldValue = dobFld;  
                            if(String.isBlank(extFld.fieldValue)) { errorCode.add(validationMessage('DATEOFBIRTH')); }             
                        } else if(fieldName == 'Loan_Amount__c'){
                            extFld.fieldName = 'LOANAMOUNT';
                            Integer loanAmount = roundOffNumber(Integer.valueOf(insObj.Loan_Amount__c));
                            extFld.fieldValue = String.valueOf(loanAmount);
                            if(String.isBlank(extFld.fieldValue)) { errorCode.add(validationMessage('LOANAMOUNT')); }     
                        } else if(fieldName == 'Sum_Insured_Customer_Details__c'){
                            extFld.fieldName = 'SUMINSURED';
                            Integer sumInsured = roundOffNumber(Integer.valueOf(insObj.Sum_Insured_Customer_Details__c));
                            extFld.fieldValue = String.valueOf(sumInsured);
                            if(String.isBlank(extFld.fieldValue)) { errorCode.add(validationMessage('SUMINSURED')); }    
                        } else if(fieldName == 'Loan_tenure__c'){
                            extFld.fieldName = 'LOANTENURE';
                            extFld.fieldValue = String.valueOf(insObj.Loan_tenure__c);        
                            if(String.isBlank(extFld.fieldValue)) { errorCode.add(validationMessage('LOANTENURE')); }            
                        } else if(fieldName == 'Policy_Tenure__c'){
                            extFld.fieldName = 'POLICYTENURE';
                            extFld.fieldValue = (insObj.Policy_Tenure__c == null) ? null : String.valueOf(insObj.Policy_Tenure__c);
                            if(String.isBlank(extFld.fieldValue)) { errorCode.add(validationMessage('POLICYTENURE')); }  
                        } else if(fieldName == 'Insurance_Premium__c'){
                            extFld.fieldName = 'INSURANCEPREMIUM';
                            Integer premium = roundOffNumber(Integer.valueOf(insObj.Insurance_Premium__c));
                            extFld.fieldValue = String.valueOf(premium);
                            if(String.isBlank(extFld.fieldValue)) { errorCode.add(validationMessage('INSURANCEPREMIUM')); }  
                        } else if(fieldName == 'Applicant_Type__c'){
                            extFld.fieldName = 'APPLICANTTYPE';
                            extFld.fieldValue = (insObj.Applicant_Type__c != null) ? mapMasterCode.get('Applicant Type'.toLowerCase()).get(insObj.Applicant_Type__c.toLowerCase()) : '' ;  //'APPLICANT'; 
                            if(String.isBlank(extFld.fieldValue)) { errorCode.add(validationMessage('APPLICANTTYPE')); }  
                        } else if(fieldName == 'Gender_Bank_Insurance_Details__c'){
                            extFld.fieldName = 'GENDER';
                            extFld.fieldValue = string.valueOf(insObj.Gender_Bank_Insurance_Details__c).toUpperCase(); 
                            if(String.isBlank(extFld.fieldValue)) { errorCode.add(validationMessage('GENDER')); }  
                        }              
        
                        if(extFld.fieldName != null){
                            extFldList.add(extFld);
                        }                    
                    } 
                    List<String> extFieldsList = new List<String>{'CUSTOMERTYPE'}; //this extended field logic was done separately cause it uses the lookup on VAS not exactly a VAS field .. other fields use getpopulatedFieldsasMap mehtod >>
                    List<CreateFinanceRequestWrapper.ExtendedFields> extFldListcst = new List<CreateFinanceRequestWrapper.ExtendedFields>();
                    for(String fieldName: extFieldsList){
                        CreateFinanceRequestWrapper.ExtendedFields extFldcst = new CreateFinanceRequestWrapper.ExtendedFields();
                        if(fieldName == 'CUSTOMERTYPE'){
                            extFldcst.fieldName = 'CUSTOMERTYPE';
                            extFldcst.fieldValue = (insObj.Application_Applicant__r.Customer_Profile__c != null) ? mapMasterCode.get('VAS Customer Type'.toLowerCase()).get(insObj.Application_Applicant__r.Customer_Profile__c.toLowerCase()) : '';   
                            if(extFldcst.fieldValue == null || extFldcst.fieldValue == '') { 
                                errorCode.add(validationMessage('CUSTOMERTYPE')); 
                            } 
                        } 
                        if(extFldcst.fieldName != null){
                            extFldListcst.add(extFldcst);
                        }
                    }
                    // Merge two extended fields list into all
                    extFldList.addAll(extFldListcst);
                    CreateFinanceRequestWrapper.ExtendedDetails extObj = new CreateFinanceRequestWrapper.ExtendedDetails();
                    extObj.extendedFields = extFldList;
                    List<CreateFinanceRequestWrapper.ExtendedDetails> extObjList = new List<CreateFinanceRequestWrapper.ExtendedDetails>();
                    extObjList.add(extObj);
                    vasObj.extendedDetails = extObjList;
                }
                vasList.add(vasObj);
                if(vasObj.feePaymentMode == '') { errorCode.add(validationMessage('Fee Method')); }
            }
            //fWrap.vas = vasList; //Assigning it as it is part of fwrap now CH03
            //fSch.vas = vasList; //CH05
 
                    
  
            CreateFinanceRequestWrapper.FinanceSchedule fSch = new CreateFinanceRequestWrapper.FinanceSchedule();
            fSch.financeDetail = fDetail;
            fSch.fees = feesList; //>> moved to fwrap
            fSch.vas = vasList; //>> moved to fwrap
            fSch.step = stepList; 

            Boolean toPassExtReference = false; //logic for ext ref changed for both HL and AHL. Instead of using the child ext field, now we'll check for the amount and pass the application name of child/parent application basis on the child/parent product
            for(Charges_Insurance__c chargeObj : [SELECT Id,Name,Stage__c,Allocated_Amount__c,Adjusted_Login_Fee__c,Product__r.Name,Product__c,Product__r.Product_Type__c,Requested_Amount_INR__c,Login_Fees__c, Charges_Fee_Type__c FROM Charges_Insurance__c WHERE Loan_Application__c = :requiredLoanId AND Product__r.Name =:mainProduct.Name and Product__r.Product_Type__c = :productType]){//Changing this to the Name field for month end purposes and will discuss thios with NEETI ////product is application's prodcut cause after split this works fine and we're in Ops maker/Author when this gets called >>)
                if(new List<String>{'PROCFEE','STFRCHG'}.contains(chargeObj.Name) && chargeObj.Adjusted_Login_Fee__c!=null && chargeObj.Adjusted_Login_Fee__c >0){ //loops one and passes it as trueee
                    toPassExtReference = true;
                }
            }
            fSch.externalReference = toPassExtReference == true ? String.isNotBlank(loanApp.Name) ? loanApp.Name.replaceAll('-', '') : '' : '';
            fWrap.financeSchedule =  fSch;
            //Sanwar - Start
            List<String> extFieldsList = new List<String>{'SAP_CPC','GHFRM','GHFAM','WEFLAG', 'LANGUAGE_PREFERRED','SAP_REFCODE4'};
            List<CreateFinanceRequestWrapper.ExtendedFields> additionalExtFldListcst = new List<CreateFinanceRequestWrapper.ExtendedFields>();

            for(String fieldName: extFieldsList){
                CreateFinanceRequestWrapper.ExtendedFields additionalExtFldcst = new CreateFinanceRequestWrapper.ExtendedFields();
                if(fieldName == 'SAP_CPC'){
                    additionalExtFldcst.fieldName = fieldName;
                    additionalExtFldcst.fieldValue = new List<String>{'Direct','Default'}.contains(loanApp.Channel_Type__c) ? loanApp.Channel_Type__c.toUpperCase() : loanApp.Channel_Code__c;
                }
                if(fieldName == 'LANGUAGE_PREFERRED'){
                    additionalExtFldcst.fieldName = 'LANGUAGE_PREFERRED';
                    additionalExtFldcst.fieldValue = (applicantTypeToApplicantListMap.get('primary')[0].Preferred_Language__c.toUpperCase() != null) 
                        ? applicantTypeToApplicantListMap.get('primary')[0].Preferred_Language__c.toUpperCase()
                        : '';
                }

                if(fieldName == 'GHFRM'){
                    additionalExtFldcst.fieldName = fieldName;
                    //additionalExtFldcst.fieldValue = isHLRelated ? loanApp.Sourcing_Manager__r?.Employee_Id__c : loanApp.Dsa_Area_Manager__r?.Employee_Id__c;//'G111425';
                    additionalExtFldcst.fieldValue = isHLRelated ? loanApp.HL_Relationship_Manager__r?.Employee_Id__c : loanApp.Dsa_Area_Manager__r?.Employee_Id__c;//'G111425';
                }
                if(fieldName == 'GHFAM'){
                    additionalExtFldcst.fieldName = fieldName;
                    //additionalExtFldcst.fieldValue = isHLRelated ? loanApp.Sourcing_Manager__r?.Employee_Id__c : loanApp.Dsa_Area_Manager__r?.Employee_Id__c;//'G103833';
                    additionalExtFldcst.fieldValue = isHLRelated ? loanApp.HL_Area_Manager__r?.Employee_Id__c : loanApp.Dsa_Area_Manager__r?.Employee_Id__c;//'G103833';
                }
                if(isHLRelated){
                     if(fieldName == 'SAP_REFCODE4'){
                        additionalExtFldcst.fieldName = fieldName;
                        additionalExtFldcst.fieldValue = isHLRelated ? loanApp.HL_DST__r?.Employee_Id__c : loanApp.HL_DST__r?.Employee_Id__c;
                    }
                }
                if(fieldName == 'WEFLAG'){
                    additionalExtFldcst.fieldName = fieldName;
                    additionalExtFldcst.fieldValue = loanApp.Women_Entrepreneurship__c != null ? loanApp.Women_Entrepreneurship__c : '';
                }
                if(additionalExtFldcst.fieldValue != null){
                    additionalExtFldListcst.add(additionalExtFldcst);
                }
            }
            CreateFinanceRequestWrapper.ExtendedDetails additionalExtfieldObj = new CreateFinanceRequestWrapper.ExtendedDetails();
            additionalExtfieldObj.extendedFields = additionalExtFldListcst;
            List<CreateFinanceRequestWrapper.ExtendedDetails> additionalExtdtlLst = new List<CreateFinanceRequestWrapper.ExtendedDetails>();
            additionalExtdtlLst.add(additionalExtfieldObj);
            fWrap.extendedDetails = additionalExtdtlLst;
            //Sanwar -End               
            // Disbursement         
            List<Loan_Transaction__c> paymentList = getLoanTransactionByRecType(loanId, 'Payment');
            List<CreateFinanceRequestWrapper.Disbursement> disbList = new List<CreateFinanceRequestWrapper.Disbursement>();
            // List<Charges_Insurance_Master__c>  vasBankDetailList = getVasBankDetails(vasCodes);
            // Charges_Insurance_Master__c vasBankDetails = (!vasBankDetailList.isEmpty()) ? vasBankDetailList[0] : null;
            Map<String, Charges_Insurance_Master__c> vasBankDetailsMap = getVasBankDetails(vasCodes);
            Charges_Insurance__c chargesInsuranceObj = new Charges_Insurance__c();
            List<Loan_Transaction__c> parentPaymentList = getLoanTransactionByRecType(requiredLoanId, 'Payment');


            List<Integration_Details__c> integrationDetailsList = [SELECT Id, Business_Date__c FROM Integration_Details__c WHERE Name = 'Fetch Application Date' AND Method_Type__c = 'GET' AND Business_Date__c != null ORDER BY CreatedDate DESC];

            Date fetchedOverrideDate = (!integrationDetailsList.isEmpty() && integrationDetailsList[0].Business_Date__c != null) ? integrationDetailsList[0].Business_Date__c : Date.today();

            if(InsuranceList.size() > 0){
                chargesInsuranceObj = InsuranceList[0];  
            }            
            Set<String> setOfIssuingBankLocation = new Set<String>();
            Set<String> setOfPrintingLocation = new Set<String>();
            for(Loan_Transaction__c pay: paymentList){
                if(pay.Issuing_Bank_Location__c != null && pay.Printing_Location__c != null) {
                    setOfIssuingBankLocation.add(pay.Issuing_Bank_Location__c);
                    setOfPrintingLocation.add(pay.Printing_Location__c);
                }
            }
            List<Bank_Branch_Master__c> bankBranchData = [
                                            SELECT Id,Bank_Name__c,Bank_Code__c,Branch_Name__c,Branch_Code__c,Bank__r.Name
                                            FROM Bank_Branch_Master__c 
                                            WHERE Bank__r.Name IN: setOfIssuingBankLocation 
                                            AND Branch_Name__c IN: setOfPrintingLocation 
                                        ];
            Map<String, String> mapOfLocationVsBankCode = new Map<String, String>();
            if(!bankBranchData.isEmpty()){
                for (Bank_Branch_Master__c bankBranch : bankBranchData) {
                    mapOfLocationVsBankCode.put(bankBranch.Branch_Name__c.toLowerCase(), bankBranch.Bank_Code__c);
                }
            }
            //sanwar start (19/12/2025)
            Set<Id> applicantIds = new Set<Id>();

            for(Loan_Transaction__c record : paymentList){
                if((record.Disbursement_Party__c == 'Seller' || record.Disbursement_Party__c == 'Builder') && (record.Bank_Details__c == null || record.Bank_Details__r.Bank_Master__c ==null) && record.Application_Applicant__c !=null){
                    applicantIds.add(record.Application_Applicant__c);
                }
            }

            Map<Id, Bank_Details__c> applicantBankMap = new Map<Id, Bank_Details__c>();
            if(!applicantIds.isEmpty()){
                for(Bank_Details__c bd : [
                    SELECT Id,Application_Applicant__c, Branch_Name__c, Bank_Master__r.Bank_Code__c, Bank_Master__r.Branch_Code__c, Bank_Master__r.IFSC__c, Bank_Master__r.MICR__c, Account_Holder_Name__c, Account_Number__c, Account_Type__c, Bank_Master__r.Bank_Name__c, Bank_Master__c  
                    FROM Bank_Details__c
                    WHERE Application_Applicant__c IN :applicantIds 
                ]){
                    if(!applicantBankMap.containsKey(bd.Application_Applicant__c)){
                        applicantBankMap.put(bd.Application_Applicant__c, bd);
                    }
                }
            } //sanwar end (19/12/2025)

            Date todayDate = Date.today();

            for(Loan_Transaction__c pay: paymentList){
                //if(String.isNotBlank(pay.Disbursement_Party__c ) && pay.Disbursement_Party__c !='VAS'){
                //Changed by AD 0n 2 Dec - dont deploy to PROD
                if(String.isNotBlank(pay.Disbursement_Party__c )
                    && ((String.isNOTBlank(loanApp.Loan_Hierarchy__c) && (pay.Disbursement_Party__c !='VAS')) 
                    || (String.isBlank(loanApp.Loan_Hierarchy__c) && (pay.Disbursement_Party__c !='VAS' || label.VASCheck == 'true')))){ 
                                           
                    CreateFinanceRequestWrapper.Disbursement disb = new CreateFinanceRequestWrapper.Disbursement();

                    //Sanwar Start (08/12/2025)
                    // disb.disbParty = (pay.Disbursement_Party__c != null) ? mapMasterCode.get('Disbursement Party'.toLowerCase()).get(pay.Disbursement_Party__c.toLowerCase()) : '' ;   
                    String dp = pay.Disbursement_Party__c;

                    if (String.isNotBlank(dp) && dp == 'Seller') {  //|| dp == 'Builder' removed this condition as only Seller needs to be sent as TP. COnfirmed by Shiva
                        disb.disbParty = mapMasterCode.get('Disbursement Party'.toLowerCase()).get('third party');
                    } else {
                        disb.disbParty = String.isNotBlank(dp) ? mapMasterCode.get('Disbursement Party'.toLowerCase()).get(dp.toLowerCase()) : '';
                    }//Sanwar End (08/12/2025)
                    // disb.disbDate =  formatDateString(pay.Scheduled_Disbursement_Date__c);  

                    if (pay.Scheduled_Disbursement_Date__c != null) {
                        if (pay.Scheduled_Disbursement_Date__c < todayDate && loanApp.Loan_Hierarchy__c == 'Child') {
                            // SFAH-1413, user will send back the case and update all the dates, regenerate the repayment schedule.
                            // disb.disbDate = formatDateString(fetchedOverrideDate); 
                            disb.disbDate = formatDateString(pay.Scheduled_Disbursement_Date__c);
                        } else {
                            disb.disbDate = formatDateString(pay.Scheduled_Disbursement_Date__c);
                        }
                    }

                    // Validate Value Date
                    if (pay.Value_Date__c != null) {
                        if (pay.Value_Date__c < todayDate && loanApp.Loan_Hierarchy__c == 'Child') {
                            // SFAH-1413, user will send back the case and update all the dates, regenerate the repayment schedule.
                            // disb.valueDate = formatDateString(fetchedOverrideDate);
                            disb.valueDate = formatDateString(pay.Value_Date__c);
                        } else {
                            disb.valueDate = formatDateString(pay.Value_Date__c);
                        }
                    } else {
                        disb.valueDate = '';
                    }
                    disb.disbAmount = pay.Net_Amount__c!=null ? Utility.addTwoZeros(pay.Net_Amount__c).setScale(0).longValue() : 0; //(isHLRelated ==true ? addTwoZeros(pay.Net_Amount__c) : addTwoZeros((Integer)Math.round(pay.Net_Amount__c)))
                        
                    if(pay.Disbursement_Party__c != null){
                        if(pay.Disbursement_Party__c == 'VAS' ) {
                            disb.vasProductCode = (pay.Charges_Insurance__c != null) ? pay.Charges_Insurance__r.VAS_Code__c : '' ;
                            String vasCode = pay.Charges_Insurance__r.VAS_Code__c;
                            Charges_Insurance_Master__c vasBankDetails = vasBankDetailsMap.get(vasCode);
                            // disb.vasProductCode = (chargesInsuranceObj != null) ? chargesInsuranceObj.VAS_Code__c : '' ;  ##NAInWrapperAHL
                            if(vasBankDetails != null){
                                disb.disbType = vasBankDetails.Payment_Mode__c!=null ? vasBankDetails.Payment_Mode__c : 'NEFT';
                                disb.partnerBankId = defaultValues.containsKey('partnerBankId') ? defaultValues.get('partnerBankId') : '';
                                disb.issueBank = vasBankDetails.Bank_Branch_Master__r.Bank_Code__c ?? '';
                                disb.bankCode = vasBankDetails.Bank_Branch_Master__r.Bank_Code__c ?? '';
                                //disb.branchBankName = vasBankDetails.Bank_Branch_Master__r.Bank_Name__c ?? null;  ##NAInWrapperAHL
                                disb.branchCode = vasBankDetails.Bank_Branch_Master__r.Branch_Code__c ?? '';  
                                disb.ifsc = vasBankDetails.Bank_Branch_Master__r.IFSC__c ?? '';  
                                disb.accountNo = vasBankDetails.Account_Number__c ??  '';
                                disb.acHolderName = vasBankDetails.Dealer_Name__c ??  '';                          
                            }                   
                        }  else {  // Customer , Third Party
                                if(!isHLRelated){ //for AHL from default values for HL configurable from Field
                                    disb.partnerBankId = defaultValues.containsKey('partnerBankId') ? defaultValues.get('partnerBankId') : '';
                                } 
                                else{
                                    disb.partnerBankId = pay.Partner_bank__c!=null ? String.valueOf(pay.Partner_bank__c) : '';
                                }
                                disb.disbType = (String.isNotBlank(pay.Disbursement_Type__c)) ? pay.Disbursement_Type__c : 'NEFT';  
                                // ----------------CHEQUE----------------
                                if(disb.disbType == 'CHEQUE'){
                                    if(pay.Issuing_Bank_Location__c != null && pay.Printing_Location__c != null){
                                        disb.issueBank = (!mapOfLocationVsBankCode.isEmpty() && mapOfLocationVsBankCode.containsKey(pay.Printing_Location__c.toLowerCase()))
                                            ? mapOfLocationVsBankCode.get(pay.Printing_Location__c.toLowerCase())
                                            : '';
                                    } 
                                    else{
                                        disb.issueBank = '';
                                    }
                                    disb.chequeNo = String.isNotBlank(pay.Cheque_DD_Number__c) ? pay.Cheque_DD_Number__c : '';
                                }
                                // ----------------NEFT/RTGS/IMPS/whatever----------------
                                else{
                                    disb.issueBank = (pay.Bank_Details__r.Bank_Master__r.Bank_Code__c != null) ? pay.Bank_Details__r.Bank_Master__r.Bank_Code__c
                                            : (pay.Application_Applicant__c != null && !isHLRelated && !applicantBankMap.isEmpty() && applicantBankMap.containsKey(pay.Application_Applicant__c) && applicantBankMap.get(pay.Application_Applicant__c).Bank_Master__r.Bank_Code__c != null)
                                            ? applicantBankMap.get(pay.Application_Applicant__c).Bank_Master__r.Bank_Code__c
                                            : '';
                                    disb.accountNo = (pay.Bank_Details__r.Account_Number__c  != null) ? pay.Bank_Details__r.Account_Number__c
                                            : (pay.Application_Applicant__c != null && !isHLRelated && !applicantBankMap.isEmpty() && applicantBankMap.containsKey(pay.Application_Applicant__c) && applicantBankMap.get(pay.Application_Applicant__c).Account_Number__c != null)
                                            ? applicantBankMap.get(pay.Application_Applicant__c).Account_Number__c
                                            : '';
                                }
                                // bankCode
                                disb.bankCode = (pay.Bank_Details__r.Bank_Master__r.Bank_Code__c != null)
                                        ? pay.Bank_Details__r.Bank_Master__r.Bank_Code__c
                                        : (pay.Application_Applicant__c != null && !isHLRelated && !applicantBankMap.isEmpty() && applicantBankMap.containsKey(pay.Application_Applicant__c) && applicantBankMap.get(pay.Application_Applicant__c).Bank_Master__r.Bank_Code__c != null)
                                        ? applicantBankMap.get(pay.Application_Applicant__c).Bank_Master__r.Bank_Code__c
                                        : '';
                                // branchCode
                                disb.branchCode = (pay.Bank_Details__r.Bank_Master__r.Branch_Code__c != null)
                                        ? pay.Bank_Details__r.Bank_Master__r.Branch_Code__c
                                        : (pay.Application_Applicant__c != null && !isHLRelated && !applicantBankMap.isEmpty() && applicantBankMap.containsKey(pay.Application_Applicant__c) && applicantBankMap.get(pay.Application_Applicant__c).Bank_Master__r.Branch_Code__c != null)
                                        ? applicantBankMap.get(pay.Application_Applicant__c).Bank_Master__r.Branch_Code__c
                                        : '';
                                // ifsc
                                disb.ifsc = (pay.Bank_Details__r.Bank_Master__r.IFSC__c != null)
                                        ? pay.Bank_Details__r.Bank_Master__r.IFSC__c
                                        : (pay.Application_Applicant__c != null && !isHLRelated && !applicantBankMap.isEmpty() && applicantBankMap.containsKey(pay.Application_Applicant__c) && applicantBankMap.get(pay.Application_Applicant__c).Bank_Master__r.IFSC__c != null)
                                        ? applicantBankMap.get(pay.Application_Applicant__c).Bank_Master__r.IFSC__c
                                        : '';
                                // acHolderName
                                if(disb.disbType != 'CHEQUE') {
                                    disb.acHolderName = (pay.Account_Holder_Name__c != null)
                                            ? pay.Account_Holder_Name__c.trim().replaceAll('[^A-Za-z0-9 ]', '')
                                            : (pay.Bank_Details__r.Account_Holder_Name__c != null )? pay.Bank_Details__r.Account_Holder_Name__c.trim().replaceAll('[^A-Za-z0-9 ]', '') : (pay.Application_Applicant__c != null && !isHLRelated && !applicantBankMap.isEmpty() && applicantBankMap.containsKey(pay.Application_Applicant__c) && applicantBankMap.get(pay.Application_Applicant__c).Account_Holder_Name__c != null)
                                            ? applicantBankMap.get(pay.Application_Applicant__c).Account_Holder_Name__c.trim().replaceAll('[^A-Za-z0-9 ]', '')
                                            : '';
                                }else{
                                    disb.acHolderName = '';
                                }
                            }
                
                    }
                    
                    //disb.partnerbankCode = 'HDFC';   ##NAInWrapperAHL
                    disb.phoneNumber = pay.Disbursement_Party__c != null && pay.Disbursement_Party__c == 'Third party' ? pay.Third_Party_Phone_Number__c : pay.Mobile_Number__c ?? '';
                    //newMapping
                    disb.remarks = String.isNotBlank(pay.Id) ? pay.Id : '';
                    disb.favourName = String.isNotBlank(pay.Favoring_Name__c) ?  pay.Favoring_Name__c : '';
                    if(disb.disbType == 'CHEQUE'){
                       disb.payableLoc = String.isNotBlank(pay.Payable_Location__c) ? (pay.Payable_Location__c).toUpperCase() : '';
                    }
                    else{
                        disb.payableLoc = pay.Bank_Details__c!=null && String.isNotBlank(pay.Bank_Details__r.Branch_Name__c) ? pay.Bank_Details__r.Branch_Name__c : '';
                    }
                    disb.printingLoc = pay.Printing_Location__c!=null ? (pay.Printing_Location__c).toUpperCase() : '';
                    // disb.valueDate = pay.Value_Date__c!=null ? formatDateString(pay.Value_Date__c) : '';
                    disb.phoneCountryCode= ''; //162
                    disb.phoneAreaCode = ''; //123

                    //disb.holdDisbursement = false;  ##NAInWrapperAHL
                    disbList.add(disb);

                    if(disb.disbParty == ''){ errorCode.add(validationMessage('Disbursement Party'));  }
                    if(disb.disbDate == ''){ errorCode.add(validationMessage('Disbursement Date'));  }
                }
            }

            if (String.isNotBlank(loanApp.Loan_Hierarchy__c) && label.VASCheck == 'true') {
                system.debug('InsuranceList  '+InsuranceList);
                for(Charges_Insurance__c insObj : InsuranceList){ //VAS for Child and Parent
                    if (loanApp.Loan_Hierarchy__c == insObj.Product__r.Product_Type__c) {
                        for(Loan_Transaction__c pay: parentPaymentList){
                            CreateFinanceRequestWrapper.Disbursement disb = new CreateFinanceRequestWrapper.Disbursement();
                            disb.vasProductCode = (insObj.VAS_Code__c != null) ? insObj.VAS_Code__c : '' ;
                            if(pay.Disbursement_Party__c != null && pay.Disbursement_Party__c == 'VAS'){
                                if (pay.Charges_Insurance__c != null && pay.Charges_Insurance__r.VAS_Code__c != null && insObj.VAS_Code__c != null && pay.Charges_Insurance__c == insObj.Id) {
                                    disb.disbParty = (pay.Disbursement_Party__c != null) ? mapMasterCode.get('Disbursement Party'.toLowerCase()).get(pay.Disbursement_Party__c.toLowerCase()) : '' ;  
                                    // disb.disbDate =  formatDateString(pay.Scheduled_Disbursement_Date__c);  
                                    // Validate Scheduled Disbursement Date
                                    if (pay.Scheduled_Disbursement_Date__c != null) {
                                        if (pay.Scheduled_Disbursement_Date__c < todayDate) {
                                            // SFAH-1413, user will send back the case and update all the dates, regenerate the repayment schedule.
                                            // disb.disbDate = formatDateString(fetchedOverrideDate); 
                                            disb.disbDate = formatDateString(pay.Scheduled_Disbursement_Date__c);
                                        } else {
                                            disb.disbDate = formatDateString(pay.Scheduled_Disbursement_Date__c);
                                        }
                                    }

                                    // Validate Value Date
                                    if (pay.Value_Date__c != null) {
                                        if (pay.Value_Date__c < todayDate) {
                                            // SFAH-1413, user will send back the case and update all the dates, regenerate the repayment schedule.
                                            // disb.valueDate = formatDateString(fetchedOverrideDate);
                                            disb.valueDate = formatDateString(pay.Value_Date__c);
                                        } else {
                                            disb.valueDate = formatDateString(pay.Value_Date__c);
                                        }
                                    } else {
                                        disb.valueDate = '';
                                    }
                                    disb.disbAmount = pay.Net_Amount__c!=null ? Utility.addTwoZeros(pay.Net_Amount__c).setScale(0).longValue() : 0; //(isHLRelated ==true ? addTwoZeros(pay.Net_Amount__c) : addTwoZeros((Integer)Math.round(pay.Net_Amount__c)))
                                    String vasCode = (insObj.VAS_Code__c != null) ? insObj.VAS_Code__c : '' ;
                                    Charges_Insurance_Master__c vasBankDetails = vasBankDetailsMap.get(vasCode);
                                    if(vasBankDetails != null){
                                        disb.disbType = vasBankDetails.Payment_Mode__c!=null ? vasBankDetails.Payment_Mode__c : 'NEFT';
                                        disb.partnerBankId = defaultValues.containsKey('partnerBankId') ? defaultValues.get('partnerBankId') : '';
                                        disb.issueBank = vasBankDetails.Bank_Branch_Master__r.Bank_Code__c ?? '';
                                        disb.bankCode = vasBankDetails.Bank_Branch_Master__r.Bank_Code__c ?? '';
                                        disb.branchCode = vasBankDetails.Bank_Branch_Master__r.Branch_Code__c ?? '';  
                                        disb.ifsc = vasBankDetails.Bank_Branch_Master__r.IFSC__c ?? '';  
                                        disb.accountNo = vasBankDetails.Account_Number__c ??  '';
                                        disb.acHolderName = vasBankDetails.Dealer_Name__c ??  '';                          
                                    }
                                    disb.phoneNumber = pay.Disbursement_Party__c != null && pay.Disbursement_Party__c == 'Third party' ? pay.Third_Party_Phone_Number__c : pay.Mobile_Number__c ?? '';
                                    disb.remarks = String.isNotBlank(pay.Id) ? pay.Id : '';
                                    disb.favourName = String.isNotBlank(pay.Favoring_Name__c) ?  pay.Favoring_Name__c : '';
                                    if(disb.disbType == 'CHEQUE'){
                                    disb.payableLoc = String.isNotBlank(pay.Payable_Location__c) ? pay.Payable_Location__c : '';
                                    }
                                    else{
                                        disb.payableLoc = pay.Bank_Details__c!=null && String.isNotBlank(pay.Bank_Details__r.Branch_Name__c) ? pay.Bank_Details__r.Branch_Name__c : '';
                                    }
                                    disb.printingLoc = pay.Printing_Location__c!=null ? pay.Printing_Location__c : '';
                                    // disb.valueDate = pay.Value_Date__c!=null ? formatDateString(pay.Value_Date__c) : '';
                                    disb.phoneCountryCode= ''; //162
                                    disb.phoneAreaCode = ''; //123
                                    disbList.add(disb);
                                }
                            }
                        }
                    }
                }
            }
           
            fWrap.disbursement = disbList;
         
            // Mandate Detail
            CreateFinanceRequestWrapper.MandateDetail mDet = new CreateFinanceRequestWrapper.MandateDetail();
            mDet.useExisting = false; 

            if(instrumentMandateObj != null && instrumentMandateObj.Mandate_Type__c == 'Repayment Mandate'){
                if(loanTransaction.Payment_Method__c == 'PDC' || loanTransaction.Payment_Method__c == 'MANUAL'){
                    mDet.mandateType = 'NACH';
                } else {
                    mDet.mandateType = loanTransaction.Payment_Method__c;
                }
            } else {
                mDet.mandateType = instrumentMandateObj != null ? instrumentMandateObj.Mandate_Type__c : '' ;
            }
            
            mDet.mandateID = ''; //4284 //TOBE CHANGED >> mandatory when useExisting = true;
            mDet.entityCode = 'GHF';// defaultValues.containsKey('partnerBankId') ? defaultValues.get('partnerBankId') : ''; //GHF for AHL and HL loans >> MAKE it configurable CH04
            mDet.bankCode = (instrumentMandateObj != null && instrumentMandateObj.Bank_Details__r.Bank_Master__r.Bank_Code__c != null ) ? instrumentMandateObj.Bank_Details__r.Bank_Master__r.Bank_Code__c : '';  
            mDet.branchCode = (instrumentMandateObj != null && instrumentMandateObj.Bank_Details__r.Bank_Master__r.Branch_Code__c != null ) ? instrumentMandateObj.Bank_Details__r.Bank_Master__r.Branch_Code__c : '';  
            mDet.ifsc = (instrumentMandateObj != null && instrumentMandateObj.Bank_Details__r.Bank_Master__r.IFSC__c != null) ? instrumentMandateObj.Bank_Details__r.Bank_Master__r.IFSC__c : '';  
            mDet.micr = (instrumentMandateObj != null && instrumentMandateObj.Bank_Details__r.Bank_Master__r.MICR__c != null) ? instrumentMandateObj.Bank_Details__r.Bank_Master__r.MICR__c : ''; 
            mDet.accType = (instrumentMandateObj != null &&  instrumentMandateObj.Bank_Details__r.Account_Type__c != null) ? mapMasterCode.get('Account Type CF'.toLowerCase()).get(instrumentMandateObj.Bank_Details__r.Account_Type__c.toLowerCase()) : '' ;  //'11'; we need the mapping for it in SF >> 10 saving 11 current >>
            mDet.partnerBankId = defaultValues.containsKey('partnerBankId') ? defaultValues.get('partnerBankId') : '';  //207 default
            mDet.accNumber = (instrumentMandateObj != null && instrumentMandateObj.Bank_Details__r.Account_Number__c != null) ? instrumentMandateObj.Bank_Details__r.Account_Number__c : '';  
            mDet.accHolderName = (instrumentMandateObj != null && instrumentMandateObj.Bank_Details__r.Account_Holder_Name__c != null) ? instrumentMandateObj.Bank_Details__r.Account_Holder_Name__c.trim().replaceAll('[^A-Za-z0-9 ]', '') : ''; //remove special chars
            mDet.jointAccHolderName = ''; 
            mDet.openMandate = 'false'; 
            mDet.docRefId = '2'; 
            mDet.documentName = 'mandate.jpg'; 
            
            if(!System.Test.isRunningTest()){      
                mDet.startDate = instrumentMandateObj != null ? formatDateString(instrumentMandateObj.Start_Date__c) : ''; 
                mDet.expiryDate = instrumentMandateObj != null ? formatDateString(instrumentMandateObj.End_Date__c) : '';     //  mDet.expiryDate  should be after the loan maturity date
            } else {
                Date today = Date.today();
                mDet.startDate =  String.valueOf(today); 
                mDet.expiryDate =  String.valueOf(today);           
            }
            
            mDet.maxLimit =  (instrumentMandateObj != null && instrumentMandateObj.Max_Limit__c != null) ?  addTwoZeros(instrumentMandateObj.Max_Limit__c) : 0;  // 500000.00;  //#VariableTypeChange // pay.Disbursement_Amount__c;  1000000; //instrumentMandateObj.Max_Limit__c ; 
            mDet.periodicity = finalFrequencyCode;
            mDet.phoneNumber = String.isNotBlank(applicantTypeToApplicantListMap.get('primary')[0].Mobile_Number__c) ? String.valueOf(applicantTypeToApplicantListMap.get('primary')[0].Mobile_Number__c) : '';   ////#VariableTypeChange get the type changed
            fWrap.mandateDetail = mDet;

            //
            if(mDet.mandateType == ''){ errorCode.add(validationMessage('Mandate Type')); }
                                    
            // Co-Applicants
            List<CreateFinanceRequestWrapper.CoApplicants> coAppList = new List<CreateFinanceRequestWrapper.CoApplicants>();
            for(Application_Applicant__c co: applicantTypeToApplicantListMap.get('nonPrimary')){
                CreateFinanceRequestWrapper.CoApplicants coAppObj = new CreateFinanceRequestWrapper.CoApplicants();
                if(String.isBlank(co.Customer_LMS_Id__c) && mapLMS_Id != null){
                    coAppObj.cif = mapLMS_Id.get(co.Customer__c);
                } else {
                    coAppObj.cif = co.Customer_LMS_Id__c;
                }
                coAppObj.catOfcoApplicant = (co.Relationship_with_Primary_Applicant__c != null) ? mapMasterCode.get('Relationship With Applicant'.toLowerCase()).get(co.Relationship_with_Primary_Applicant__c.toLowerCase()) : '' ; 
                coAppObj.includeRepay = 'false'; //#VariableTypeChange
                coAppList.add(coAppObj);
                if(coAppObj.cif == ''){ errorCode.add(validationMessage('Cif'));  }
            }
            fWrap.coApplicants = coAppList;

            // Collaterals
            List<CreateFinanceRequestWrapper.Collaterals> collateralsList = new List<CreateFinanceRequestWrapper.Collaterals>();
            
            for(Application_Collateral__c itrAppCol : appCollateralList){
                CreateFinanceRequestWrapper.Collaterals collateral = new CreateFinanceRequestWrapper.Collaterals();
                collateral.collateralRef = mapOfappColIdPlfId.containsKey(itrAppCol.Id) ? mapOfappColIdPlfId.get(itrAppCol.Id) : ''; // 'CT3910200009' ;//itrAppCol.Collateral__r.PLF_ID__c; 

                if(loanApp.Split_Parent_Loan_Application__c!=null && loanApp.Loan_Hierarchy__c == 'Child' && loanApp.Product__c != 'Flexi Loan'){
                    collateral.assignPerc  = Integer.valueOf(Label.ChildCollateralAllocation);
                }
                else{
                collateral.assignPerc = itrAppCol.Collateral__r.Assigned_Percentage__c!=null ? Integer.valueOf(itrAppCol.Collateral__r.Assigned_Percentage__c) : 0; //
                }
                collateral.seq = 0;
                collateral.version = 1;
                collateralsList.add(collateral);
            }
            fWrap.collaterals = colLateralsList;

            // covenantDetails
            List<CreateFinanceRequestWrapper.CovenantDetails> covenantDetailsList = new List<CreateFinanceRequestWrapper.CovenantDetails>();
            List<CreateFinanceRequestWrapper.CovenantDocuments> covenantDocumentList = new List<CreateFinanceRequestWrapper.CovenantDocuments>();
            if(covenantDocumentsList.size()>0){
                for(Document_Details__c itrCovenant : covenantDocumentsList){
                    CreateFinanceRequestWrapper.CovenantDetails covenantDetails = new CreateFinanceRequestWrapper.CovenantDetails();
                    covenantDetails.category =itrCovenant.Covenant_Master__r.category__c; //SKR 
                    covenantDetails.covenantTypeId = itrCovenant.Covenant_Id__c;
                    covenantDetails.description = (String.isNotBlank(itrCovenant.Remarks__c) && itrCovenant.Remarks__c.length() > 250) ? itrCovenant.Remarks__c.substring(0, 250) : itrCovenant.Remarks__c;
                    covenantDetails.remarks = String.isNotBlank(itrCovenant.Remarks__c) ? itrCovenant.Remarks__c : '';
                    covenantDetails.additionalRemarks = '';
                    covenantDetails.otc = (String.valueOf(itrCovenant.Document_Type__c).contains('PDD')  || String.valueOf(itrCovenant.Document_Type__c).contains('LOS')) ? 'N' : 'Y';
                    covenantDetails.pdd = String.valueOf(itrCovenant.Document_Type__c).contains('PDD') ? 'Y' : 'N';
                    covenantDetails.receivableDate = itrCovenant.Target_Date__c!=null ? formatDateString(itrCovenant.Target_Date__c) : '';
                    covenantDetails.frequency ='';
                    covenantDetails.alertsRequired ='N';
                    covenantDetails.alertType ='';
                    covenantDetails.graceDays = String.isNotBlank(itrCovenant.Covenant_Grace_Days__c) ? itrCovenant.Covenant_Grace_Days__c : '';
                    covenantDetails.alertDays = String.isNotBlank(itrCovenant.Alert_Days__c) ? itrCovenant.Alert_Days__c : '';
                    covenantDetails.nextFrequencyDate = itrCovenant.Covenant_Next_Frequency_Date__c!=null ? formatDateString(itrCovenant.Covenant_Next_Frequency_Date__c) : '';
                    covenantDetails.notifyTo ='';
                    covenantDetails.graceDueDate = itrCovenant.Covenant_Grace_Due_Date__c!=null ? formatDateString(itrCovenant.Covenant_Grace_Due_Date__c) : '';
                    covenantDetails.internalUse ='true';
                    covenantDetails.standardValue = String.isNotBlank(itrCovenant.Standard_Value__c) ? itrCovenant.Standard_Value__c : '';
                    covenantDetails.actualValue = String.isNotBlank(itrCovenant.Actual_Value__c) ? itrCovenant.Actual_Value__c : '';
                    covenantDetails.allowWaiver = String.valueOf(itrCovenant.Allow_Postponement__c);
                    covenantDetails.mandatoryRole = '';
                    covenantDetails.natureOfDoc = String.isNotBlank(itrCovenant.Nature_of_Document__c) ? itrCovenant.Nature_of_Document__c : '';
                    covenantDetails.printOnLod = '';//String.valueOf(itrCovenant.Print_On_LOD__c);
                    covenantDetails.covenantDocuments = covenantDocumentList;
                    covenantDetailsList.add(covenantDetails);
                }
            }
            fWrap.covenantDetails = covenantDetailsList;
           //plmHeaderList
            List<CreateFinanceRequestWrapper.PlmHeaderList> plmHeaders = new List<CreateFinanceRequestWrapper.PlmHeaderList>();
            fWrap.plmHeaderList = plmHeaders;
            String finalJson = JSON.serialize(fWrap); //Armanni : parsing and serializing to handle OCR as a blank obj in case it is null
            Object parsedObj = JSON.deserializeUntyped(finalJson);
            Map<String, Object> obj = (Map<String, Object>) parsedObj;
            Object finVal = obj.get('finOCRHeader');
            if (finVal == null) {
                obj.put('finOCRHeader', new Map<String, Object>());
            }
            String outputJson = JSON.serialize(obj);

            List<String> listReqBody = new List<String>();
            listReqBody.add(outputJson);
            mapInput.put('reqBody', listReqBody);
            mapInput.put('errors', errorCode);
            return mapInput;

        } catch (Exception e) {
            System.debug('FinanceApiHandler->financeJSON ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString() + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }        
    }
    
    public static Integer addTwoZeros(Decimal inputNumber) { //returning Integer now.. it seems the server side requests two zeros --00-- instead of decimal.00
        // Multiply the number by 100 to add two zeros
        return Integer.valueOf(inputNumber * 100);
    }

    public static string formatDateString(DateTime myDate){
        try{
            String formattedDate;

            if(myDate != null){
                /*Date onlyDate = myDate.date();
                formattedDate = onlyDate.format('yyyy-MM-dd');*/
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

    
    // public static List<Charges_Insurance_Master__c> getVasBankDetails(List<String> vasCodes){
    //     try {
    //         List<Charges_Insurance_Master__c> chargesMaster = new List<Charges_Insurance_Master__c>();
            
    //         if(vasCodes.isEmpty()){
    //             return chargesMaster;
    //         }
            
    //         List<Charges_Insurance_Master__c> chargesInsuranceMaster = [
    //             SELECT Id, VAS_Provider__c FROM Charges_Insurance_Master__c WHERE VAS_Code__c IN :vasCodes
    //         ];
    //         Charges_Insurance_Master__c  vasDetails = chargesInsuranceMaster != null ? chargesInsuranceMaster[0] : null;
            
    //         if(vasDetails != null){
    //             chargesMaster = [
    //                 SELECT Id,Dealer_Name__c, Account_Number__c,Bank_Branch_Master__r.IFSC__c,
    //                 Bank_Branch_Master__r.Bank_Code__c,Bank_Branch_Master__r.Branch_Code__c,
    //                 Bank_Branch_Master__r.Bank_Name__c, Payment_Mode__c , Bank_Branch_Master__r.BankBranchId__c
    //                 FROM Charges_Insurance_Master__c 
    //                 WHERE Id =: vasDetails.VAS_Provider__c 
    //             ];
    //         }         

    //         return chargesMaster;
    //     } catch (Exception e) {
    //         System.debug('FinanceApiHandler->getVasBankDetails ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // } 

    public static Map<String, Charges_Insurance_Master__c> getVasBankDetails(List<String> vasCodes) {
        try {
            Map<String, Charges_Insurance_Master__c> resultMap = new Map<String, Charges_Insurance_Master__c>();

            if (vasCodes == null || vasCodes.isEmpty()) {
                return resultMap;
            }

            // 1. Querying VAS master records matching the VAS Codes
            List<Charges_Insurance_Master__c> vasMasterList = [
                SELECT Id, VAS_Code__c, VAS_Provider__c
                FROM Charges_Insurance_Master__c
                WHERE VAS_Code__c IN :vasCodes
            ];

            if (vasMasterList.isEmpty()) {
                return resultMap;
            }

            // 2. Store respective vas provider Ids
            Set<Id> providerIds = new Set<Id>();
            for (Charges_Insurance_Master__c rec : vasMasterList) {
                if (rec.VAS_Provider__c != null) {
                    providerIds.add(rec.VAS_Provider__c);
                }
            }

            if (providerIds.isEmpty()) {
                return resultMap;
            }

            // 3. Query full provider details
            Map<Id, Charges_Insurance_Master__c> providerMap = new Map<Id, Charges_Insurance_Master__c>(
                [
                    SELECT Id, Dealer_Name__c, Account_Number__c, Bank_Branch_Master__r.IFSC__c, 
                        Bank_Branch_Master__r.Bank_Code__c, Bank_Branch_Master__r.Branch_Code__c,
                        Bank_Branch_Master__r.Bank_Name__c, Bank_Branch_Master__r.BankBranchId__c, Payment_Mode__c
                    FROM Charges_Insurance_Master__c
                    WHERE Id IN :providerIds
                ]
            );

            // 4. Build final map keyed by VAS_Code__c
            for (Charges_Insurance_Master__c rec : vasMasterList) {
                if (rec.VAS_Provider__c != null && providerMap.containsKey(rec.VAS_Provider__c)) {
                    resultMap.put(rec.VAS_Code__c, providerMap.get(rec.VAS_Provider__c));
                }
            }

            return resultMap;

        } catch (Exception e) {
            System.debug('FinanceApiHandler->getVasBankDetails ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }


    public static Integer roundOffNumber(Integer amt) {
        String appendZeroStr = '100';//constants.get('Append_Zero'); //this was not working constants.get()
        System.debug('appendzero>>'+appendZeroStr);
        if (String.isBlank(appendZeroStr)) {
            return 0;
        }
        Integer appendZero = Integer.valueOf(appendZeroStr);
        return amt * appendZero;
    }

    public static List<Charges_Insurance__c> getChargeInsuranceList(String recType, String loanId, String productName){
        try {
            Utility_V1.ProductWrapper wrp = Utility_V1.getProductDetails(new Map<String,String>{'oppId' => loanId});
            Boolean isHLRelated = wrp.isHLRelated;
            String productType = 'Parent';
            String requiredLoanId = loanId;
            Opportunity loanApp = getLoanApplication(loanId);
            if(loanApp.Loan_Hierarchy__c == 'Child' && loanApp.Split_Parent_Loan_Application__c != null){
                requiredLoanId = loanApp.Split_Parent_Loan_Application__c;
                productType = 'Child';
            }

            List<Charges_Insurance__c> chargesInsuranceList = new List<Charges_Insurance__c>();
            if(recType == 'Charges'){
                Boolean passParent = false;
                if(isHLRelated){
                    chargesInsuranceList = [SELECT id, Fee_Method__c,VAS_Code__c,Total_VAS_Amount__c,Category__c,
                Self_Funded_Amount__c,Value_Date__c,Nom_Relationship__c,Loan_Amount__c, Loan_tenure__c,Gender_Bank_Insurance_Details__c, Product__c, Product__r.Product_Type__c,
                Insurance_Premium__c,Sum_Insured_Customer_Details__c,Applicant_Type__c,Date_of_Birth__c,Gender__c,Charges_Fee_Type__c,Waiver_Amount__c,
                Requested_Amount_INR__c,  Policy_Tenure__c ,Application_Applicant__r.Customer_Profile__c, Nominee_Name__c,Nominee_DOB__c,Allocated_Amount__c,Adjusted_Login_Fee__c,Waived_Charge_Amount__c      
                FROM Charges_Insurance__c 
                WHERE RecordType.DeveloperName =: recType AND  Loan_Application__c =: requiredLoanId 
                AND (Category__c IN ('LOS','Insurance')) AND Charges_Fee_Type__c!= 'Login Fee' AND Product_Name__c =:productName AND Product__r.Product_Type__c =: productType
                ];
                    if(!chargesInsuranceList.isEmpty()){
                        for(Charges_Insurance__c ci : chargesInsuranceList){
                            if(ci.Category__c !='Insurance'){
                                passParent = true;
                            }
                        }
                        if(!passParent){
                            chargesInsuranceList = [SELECT id, Fee_Method__c,VAS_Code__c,Total_VAS_Amount__c,Category__c,
                                Self_Funded_Amount__c,Value_Date__c,Nom_Relationship__c,Loan_Amount__c, Loan_tenure__c,Gender_Bank_Insurance_Details__c, Product__c, Product__r.Product_Type__c,
                                Insurance_Premium__c,Sum_Insured_Customer_Details__c,Applicant_Type__c,Date_of_Birth__c,Gender__c,Charges_Fee_Type__c,Waiver_Amount__c,
                                Requested_Amount_INR__c,  Policy_Tenure__c ,Application_Applicant__r.Customer_Profile__c, Nominee_Name__c,Nominee_DOB__c,Allocated_Amount__c,Adjusted_Login_Fee__c,Waived_Charge_Amount__c      
                                FROM Charges_Insurance__c 
                                WHERE RecordType.DeveloperName =: recType AND  Loan_Application__c =: loanId 
                                AND (Category__c IN ('LOS','Insurance')) AND Charges_Fee_Type__c!= 'Login Fee' AND Product_Name__c =:productName AND Product__r.Product_Type__c =: productType
                            ];
                        }
                    }
                    else if(chargesInsuranceList.isEmpty()){
                        chargesInsuranceList = [SELECT id, Fee_Method__c,VAS_Code__c,Total_VAS_Amount__c,Category__c,
                        Self_Funded_Amount__c,Value_Date__c,Nom_Relationship__c,Loan_Amount__c, Loan_tenure__c,Gender_Bank_Insurance_Details__c, Product__c, Product__r.Product_Type__c,
                        Insurance_Premium__c,Sum_Insured_Customer_Details__c,Applicant_Type__c,Date_of_Birth__c,Gender__c,Charges_Fee_Type__c,Waiver_Amount__c,
                        Requested_Amount_INR__c,  Policy_Tenure__c ,Application_Applicant__r.Customer_Profile__c, Nominee_Name__c,Nominee_DOB__c,Allocated_Amount__c,Adjusted_Login_Fee__c,Waived_Charge_Amount__c      
                        FROM Charges_Insurance__c 
                        WHERE RecordType.DeveloperName =: recType AND  Loan_Application__c =: loanId 
                        AND (Category__c IN ('LOS','Insurance')) AND Charges_Fee_Type__c!= 'Login Fee' AND Product_Name__c =:productName AND Product__r.Product_Type__c =: productType];
                    }
                }
                else{
                    chargesInsuranceList = [SELECT id, Fee_Method__c,VAS_Code__c,Total_VAS_Amount__c,Category__c,
                    Self_Funded_Amount__c,Value_Date__c,Nom_Relationship__c,Loan_Amount__c, Loan_tenure__c,Gender_Bank_Insurance_Details__c, Product__c, Product__r.Product_Type__c,
                    Insurance_Premium__c,Sum_Insured_Customer_Details__c,Applicant_Type__c,Date_of_Birth__c,Gender__c,Charges_Fee_Type__c,Waiver_Amount__c,
                    Requested_Amount_INR__c,  Policy_Tenure__c ,Application_Applicant__r.Customer_Profile__c, Nominee_Name__c,Nominee_DOB__c,Allocated_Amount__c,Adjusted_Login_Fee__c,Waived_Charge_Amount__c      
                    FROM Charges_Insurance__c 
                    WHERE RecordType.DeveloperName =: recType AND  Loan_Application__c =: requiredLoanId 
                    AND (Category__c IN ('LOS','Insurance')) AND Charges_Fee_Type__c!= 'Login Fee' AND Product_Name__c =:productName AND Product__r.Product_Type__c =: productType
                    ];
                }
            } else {
                if(isHLRelated){
                    chargesInsuranceList = [SELECT id, Fee_Method__c,VAS_Code__c,Total_VAS_Amount__c,Category__c,
                    Self_Funded_Amount__c,Value_Date__c,Nom_Relationship__c,Loan_Amount__c, Loan_tenure__c,Gender_Bank_Insurance_Details__c,Waiver_Amount__c, Product__c, Product__r.Product_Type__c,
                    Insurance_Premium__c,Sum_Insured_Customer_Details__c,Applicant_Type__c,Date_of_Birth__c,Gender__c,Charges_Fee_Type__c,Allocated_Amount__c,Adjusted_Login_Fee__c,
                    Requested_Amount_INR__c,  Policy_Tenure__c ,Application_Applicant__r.Customer_Profile__c, Nominee_Name__c,Nominee_DOB__c        
                    FROM Charges_Insurance__c WHERE RecordType.DeveloperName =: recType AND Loan_Application__c =: requiredLoanId AND Fee_Method__c NOT IN ('Funded By GC', 'Self funded') AND 
                    Product_Name__c =:productName AND Product__r.Product_Type__c =: productType];
                    if(chargesInsuranceList.isEmpty()){ //doing this as a check to make sure it takes VAS from parent first and then consider parent for 1404 jira. in the future, we'll just keep the child one.
                        chargesInsuranceList = [SELECT id, Fee_Method__c,VAS_Code__c,Total_VAS_Amount__c,Category__c,
                        Self_Funded_Amount__c,Value_Date__c,Nom_Relationship__c,Loan_Amount__c, Loan_tenure__c,Gender_Bank_Insurance_Details__c,Waiver_Amount__c, Product__c, Product__r.Product_Type__c,
                        Insurance_Premium__c,Sum_Insured_Customer_Details__c,Applicant_Type__c,Date_of_Birth__c,Gender__c,Charges_Fee_Type__c,Allocated_Amount__c,Adjusted_Login_Fee__c,
                        Requested_Amount_INR__c,  Policy_Tenure__c ,Application_Applicant__r.Customer_Profile__c, Nominee_Name__c,Nominee_DOB__c        
                        FROM Charges_Insurance__c WHERE RecordType.DeveloperName =: recType AND Loan_Application__c =: loanId AND Fee_Method__c NOT IN ('Funded By GC', 'Self funded') AND 
                        Product_Name__c =:productName AND Product__r.Product_Type__c =: productType];
                    }
                }
                else{
                    chargesInsuranceList = [SELECT id, Fee_Method__c,VAS_Code__c,Total_VAS_Amount__c,Category__c,
                Self_Funded_Amount__c,Value_Date__c,Nom_Relationship__c,Loan_Amount__c, Loan_tenure__c,Gender_Bank_Insurance_Details__c,Waiver_Amount__c, Product__c, Product__r.Product_Type__c,
                Insurance_Premium__c,Sum_Insured_Customer_Details__c,Applicant_Type__c,Date_of_Birth__c,Gender__c,Charges_Fee_Type__c,Allocated_Amount__c,Adjusted_Login_Fee__c,
                Requested_Amount_INR__c,  Policy_Tenure__c ,Application_Applicant__r.Customer_Profile__c, Nominee_Name__c,Nominee_DOB__c        
                FROM Charges_Insurance__c 
                WHERE RecordType.DeveloperName =: recType AND Loan_Application__c =: requiredLoanId AND Fee_Method__c NOT IN ('Funded By GC', 'Self funded') AND Product_Name__c =:productName AND Product__r.Product_Type__c =: productType];             
            }            
            }
            return chargesInsuranceList;

        } catch (Exception e) {
            System.debug('FinanceApiHandler->getChargeInsuranceList ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<Document_Details__c> getCovenantDocumentList(String loanId, List<String> documentCategory, Boolean isHLRelated){
        try{
            List<Document_Details__c> covenantDocumentList = new List<Document_Details__c>();
            //hl block
            if(isHLRelated){
                covenantDocumentList = [
                SELECT Id, Content_Document_Id__c, Document_Master__c,Document_Type__c,Covenant_Master__c, Covenant_Master__r.category__c, Description__c,Covenant_Id__c, Type__c,Document_Master__r.Requirement_At__c, Status__c,Covenant_Grace_Days__c, Remarks__c, Target_Date__c, Document_Date_of_Receipt__c, 
                Nature_of_Document__c,Alert_Days__c, Covenant_Next_Frequency_Date__c, Covenant_Grace_Due_Date__c, Standard_Value__c, Actual_Value__c,Allow_Postponement__c,Print_On_LOD__c,
                Document_Master__r.Document_Name__c, Document_Master__r.Document_Type__c, Document_Master__r.Document_Category__c FROM Document_Details__c WHERE
                Loan_Application__c=:loanId AND /*Document_Type__c IN :documentCategory AND*/ RecordType.Name = 'Covenant Details' AND Covenant_Id__c!=null /*AND Covenant_Approval_Status__c = 'Approved'*/ //Document_Type__c, Covenant_Approval_Status__c check commented by Kunal Bisht, Aditya Awhad for SFHL-1877
                ];
            }
            else{
                covenantDocumentList = [
                SELECT Id, Content_Document_Id__c, Document_Master__c,Document_Type__c,Covenant_Master__c, Covenant_Master__r.category__c, Description__c,Covenant_Id__c, Type__c,Document_Master__r.Requirement_At__c, Status__c,Covenant_Grace_Days__c, Remarks__c, Target_Date__c, Document_Date_of_Receipt__c, 
                Nature_of_Document__c,Alert_Days__c, Covenant_Next_Frequency_Date__c, Covenant_Grace_Due_Date__c, Standard_Value__c, Actual_Value__c,Allow_Postponement__c,Print_On_LOD__c,
                Document_Master__r.Document_Name__c, Document_Master__r.Document_Type__c, Document_Master__r.Document_Category__c FROM Document_Details__c WHERE
                Loan_Application__c=:loanId AND Document_Type__c IN :documentCategory AND Covenant_Id__c!=null AND RecordType.Name = 'Covenant Details' and Active__c = true
                ];
            }
            return covenantDocumentList;
        }
        catch(Exception e){
            System.debug('FinanceApiHandler->financeJSON ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    public static String validationMessage(string fieldName){
        String msg = 'Please enter valid data for '+ fieldName;
        return msg;
    }

    private static List<Instrument_mandate__c> getInstrumentMandateList(string loanId, string recType, String mandateType){
        try {
            List<Instrument_mandate__c> instrumentMandateList = [
                SELECT id, Application_Applicant__c,Mandate_Type__c, Start_Date__c, End_Date__c, Max_Limit__c,Periodicity__c,Bank_Details__r.Bank_Master__r.Bank_Code__c, 
                Bank_Details__r.Bank_Master__r.Branch_Code__c, Bank_Details__r.Bank_Master__r.IFSC__c, Bank_Details__r.Bank_Master__r.MICR__c,Bank_Details__r.Account_Holder_Name__c, 
                Bank_Details__r.Account_Number__c, Bank_Details__r.Account_Type__c
                FROM Instrument_Mandate__c 
                WHERE Loan_Application__c =: loanId AND RecordType.DeveloperName =: recType AND Mandate_Type__c =: mandateType];

            return instrumentMandateList;

        } catch (Exception e) {
            System.debug('FinanceApiHandler->financeJSON ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static List<Bank_Details__c> getBankDetails(string loanId){
        try{
            List<Application_Applicant__c> applicants = [
                SELECT Id FROM Application_Applicant__c WHERE Loan_Application__c = :loanId
            ];
           
            Set<Id> applicantIds = new Set<Id>();
            for (Application_Applicant__c applicant : applicants) {
                applicantIds.add(applicant.Id);
            }
 
            List<Bank_Details__c> repaymentAccounts = new List<Bank_Details__c>();
            if (!applicantIds.isEmpty()) {
                repaymentAccounts = [
                    SELECT Id, Account_Holder_Name__c, Name, Account_Number__c, Account_Type__c,
                    OD_CC_Limit__c, ABB__c, Source__c, Application_Applicant__c, Application_Applicant__r.Applicant_Type__c, Bank_Master__r.Name,  Bank_Master__r.Branch_Name__c, Bank_Master__r.MICR__c,
                    Bank_Master__r.IFSC__c, Bank_Master__r.Branch_Location__c, Bank_Master__r.Branch_Code__c, Bank_Master__r.Bank_Code__c FROM Bank_Details__c
                    WHERE Application_Applicant__c IN :applicantIds AND Is_Repayment_Account__c = TRUE
                ];                         
            }

            return repaymentAccounts;
        } catch (Exception e) {
            System.debug('FinanceApiHandler->getBankDetails ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<Loan_Transaction__c> getLoanTransactionByRecType(String loanId, String recTypeName){
        try{
            List<Loan_Transaction__c> ltObj = [
                
                SELECT Id, Loan_Application__c, Application_Applicant__c,Auto_Cal__c, Cheque_DD_Number__c, Bank_Details__r.Branch_Name__c,Printing_Location__c,Process_Stage__c, STP__c, Yearly_Selection__c,First_Disbursement_Amount__c,Rate_Type__c, Payment_Method__c,Allow_Grace__c,Scheduled_Disbursement_Date__c,Payment_Method_Grace_Parameter__c,
                TDS_Applicable__c,Step_Loan__c,Tenor_Split__c, Allow_Payment_in_Grace_Period__c,Margin__c,Schedule_Method__c,Issuing_Bank_Location__c,Favoring_Name__c,Payable_Location__c,Value_Date__c,
                Interest_Due_date__c,Interest_Frequency__c,Loan_Start_Date__c,Quick_Disbursement__c, Unplanned_EMI_Holiday_Capitalization__c,Unplanned_EMI_Holiday_Lock_Period__c,Max_unplanned_EMI_Holidays__c,Charges_Insurance__r.VAS_Code__c,
                Allow_BPI__c,BPI_Treatment__c,Allow_Planned_EMI_Holiday__c,Allow_Planned_EMI_holiday_in_Grace__c, Planned_EMI_Holiday_Method__c,Max_per_Year__c,Max__c,Lock_Period_Months__c,Capitalize__c, Charges_Insurance__c,
                Allow_Unplanned_Principal_Holiday__c,Unplanned_Principal_Holiday_Lock_Period__c,Max_unplanned_Principal_Holidays__c, Allow_Planned_Principal_Holiday__c,Planned_Principal_Holiday_Method__c,
                Max_per_Year_Principal_Holiday_Parameter__c,Max_Principal_Holiday_Parameter__c,Lock_Period_Principal_Holiday_Paramters__c, Disbursement_Party__c,Disbursement_Type__c,Disbursement_Date__c,
                Disbursement_Amount__c,Net_Amount__c,IFSC__c,Account_Number__c,Account_Holder_Name__c,Partner_bank__c,Step_Number__c, Step_Amount__c, Step_Specifier__c, Loan_Tenor__c, Grace_Period_Frequency__c,
                Pay_on_Interest_Frequency__c, Third_Party_Phone_Number__c,Mobile_Number__c, Elastic_Credit_Line_Type__c, Dropline_Calculated_On__c,Pure_Tenure__c, Dropline_Tenure__c, 
                Bank_Details__r.Bank_Master__r.Bank_Code__c, Bank_Details__r.Bank_Master__r.Branch_Code__c, Bank_Details__r.Bank_Master__r.IFSC__c,PLR_Code__c,PLR_Value__c,
                Bank_Details__r.Bank_Master__r.MICR__c,Bank_Details__r.Account_Holder_Name__c, Bank_Details__r.Account_Number__c, Bank_Details__r.Account_Type__c, Bank_Details__r.Bank_Master__r.Bank_Name__c,
                Total_OCR_Paid__c,Contributor__c,Financer_Contribution__c, Customer_Contribution__c, Step_Sequence__c,  OCR_Definition__c, OCR_ID__c, RecordType.Name,Builder_Demand__c,
                Paid_Amount__c,Receipt_Date__c,Remark__c,OCR_Receivable__c,Total_Builder_Demand_Raised__c,Total_Demand__c,Total_OCR_Receivable__c,Total_Demand_Received__c,Total_OCR_Received__c,isParent__c, Bank_Details__c, Bank_Details__r.Bank_Master__c 
                FROM Loan_Transaction__c WHERE Loan_Application__c =: loanId  AND RecordType.DeveloperName =: recTypeName ORDER BY Step_Sequence__c ASC, Step_Specifier__c ASC, Step_Number__c ASC
            ];//sanwar(19/12/2025)(add Application_Applicant__c)
            return ltObj;
        } catch (Exception e) {
            System.debug('FinanceApiHandler->getLoanTransactionByRecType ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Opportunity getLoanApplication(String loanId){
        try{
            return  [SELECT Id,Allow_OCR__c,Name, HL_DST__c,HL_DST__r.Employee_Id__c, HL_Area_Manager__c, HL_Area_Manager__r.Employee_Id__c, HL_Relationship_Manager__r.Employee_Id__c,
            HL_Relationship_Manager__c, Sourcing_Manager__c,Sourcing_Manager__r.Employee_Id__c, Final_Tenure__c,Women_Entrepreneurship__c,Split_Parent_Loan_Application__c,Channel_Type__c, 
            LMS_Loan_Reference__c,Split_Parent_Loan_Application__r.LMS_Loan_Reference__c, Loan_Hierarchy__c,Product__c,Sub_Product__c, Final_Amount__c,Sanction_Tenure__c,Tenor_months__c, Loan_Purpose__c,
            Requested_Amount__c,Loan_Application_Number__c, Reference_Name_1__c,Reference_Last_Name_1__c,Reference_Address_1__c,Reference_Phone_1__c, Reference_Name_2__c,Reference_Last_Name_2__c,Reference_Address_2__c,Reference_Phone_2__c,
            Owner.Employee_Id__c,Lead__r.Dsa_Area_Manager__r.Employee_Id__c, Lead__r.Referred_By_DSA__r.Vendor_Code__c,Branch_Master__r.Branch_Code__c,ownerId,Channel_Code__c,
            Dsa_Area_Manager__r.Employee_Id__c,Dsa_Area_Manager__c,Area_Manager__c,Area_Manager__r.Employee_Id__c,Child_Ext_Reference__c FROM Opportunity WHERE Id =: loanId];
        } catch(Exception e){
            System.debug('FinanceApiHandler->getLoanApplication ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static Map<String, List<Application_Applicant__c>> getApplicantMap(String loanId) {
        Map<String, List<Application_Applicant__c>> applicantMap = new Map<String, List<Application_Applicant__c>>();
            try{
                List<Application_Applicant__c> allApplicants = [ SELECT Id, Customer_LMS_Id__c, Customer__c,Mobile_Number__c, PSL__c,Relationship_with_Primary_Applicant__c, Udhyam_Registration_No__c,
                Customer_Type__c, Applicant_Type__c, Industry__c,Salutation__c,First_Name__c, Existing_Customer__c, Last_Name__c,Middle_Name__c,Gender__c, Mother_s_First_Name__c, Father_s_First_Name__c,
                DOB__c,Marital_Status__c,Nationality__c,PAN_Number__c,Masked_Aadhar_Number__c,GSTIN__c, Sub_Employment_Type_Non_Individual__c,Qualification__c,Religion__c,Residency_Status__c,Email__c,
                Loan_Application__c,Sector__c, Customer__r.Customer_LMS_Id__c, Customer__r.Exisiting_Customer__c, DOI__c ,Customer_Profile__c,Applicant_Name__c,Cast_Category__c,
                Loan_Application__r.Branch_Master__r.Branch_Code__c, Preferred_Language__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId];
                applicantMap.put('all', allApplicants);
                applicantMap.put('primary', new List<Application_Applicant__c>());
                applicantMap.put('nonPrimary', new List<Application_Applicant__c>());

                for (Application_Applicant__c app : allApplicants) {
                    if (app.Applicant_Type__c == 'Primary Applicant') {
                        applicantMap.get('primary').add(app);
                    } else if(app.Applicant_Type__c == 'Co Applicant') {
                        applicantMap.get('nonPrimary').add(app);
                    }
                }
            }
            catch(Exception e){
                System.debug('FinanceApiHandler->getCoApplicant ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
                throw new AuraHandledException(e.getMessage());
            }
        return applicantMap;
    }
}