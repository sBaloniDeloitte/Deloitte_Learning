public class upfrontFeeHandler implements IntegrationInterface {
    static String conLabels = 'Fin_Type_AHL,Payment_Mode,sub_Receipt_Mode,Process_Stage,Loan_Currency';
    
    public static Map <String,String> constants = Utility.getConstants(conLabels);
    public static string requestType = 'Post';

    //getting the value of constants
    public static Map <String,String> getConstants() {
        return constants;
    }
    
    
    // **Validation Method**
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        if (wrapper == null || wrapper.loanApplicationId == null) {
            errorMessages.add('Wrapper or Loan Application Id is missing.');
            return errorMessages;
   		 }
        String loanApplicationId = wrapper.loanApplicationId;
        Application_Applicant__c applicant = [SELECT Id,Loan_Application__r.name,Customer__r.name,Applicant_Type__c,GSTIN__c
                                              from Application_Applicant__c where Loan_Application__c =:wrapper.loanApplicationId AND
                                              Applicant_Type__c = 'Primary Applicant' LIMIT 1];
        List<Applicant_Address__c> applicantAddress = [SELECT Id,State__c,Address_Line_1__c,Address_Line_2__c,Address_Line_3__c
                                                 from Applicant_Address__c WHERE Applicant__c =: applicant.Id limit 1 ];
        
        if (applicantAddress.isEmpty()) {
            errorMessages.add('Primary Applicant Address is missing.');
        }
        //added by Armannn to make sure API doesnt push to PLF twice. 08-12-2025
       /* List<Integration_Details__c> existingLoginFeeRecordList = [SELECT Id,Name,Loan_Application__c,Is_Success_Response__c,CreatedDate from Integration_Details__c WHERE Name = 'Upfront fee' AND Loan_Application__c =:loanApplicationId AND Is_Success_Response__c = true ORDER BY CreatedDate DESC LIMIT 1];
        if(existingLoginFeeRecordList.size()>0){
            errorMessages.add('Login Fee has already been processed. ');
        }*/

        return errorMessages;
    }
    
    // **Construct Payload Method**
    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        Charges_Insurance__c upfrontFeeObj = wrapper.upfrontFeeObj; //added by Arman for upfron fee 19th dec
        List<string> chargeFeeTypes = new List<String>{'PROCFEE','STFRCHG'};
         //Added By Prachi for HL
            Map<String,String> inputMapUtility = new  Map<String,String>{'oppId' => wrapper.loanApplicationId};
            Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.getProductDetails(inputMapUtility);
            Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
        // Fetch Loan Application (Opportunity)
        Opportunity loanApplication = [ 
            SELECT Id,Name, Product__c,Requested_Amount__c,Loan_Application_Number__c,StageName,Final_Amount__c,
            Sanction_Tenure__c, Branch_Master__c, Branch_Master__r.Branch_Code__c,Variant__c,Final_Tenure__c
           
            FROM Opportunity 
            WHERE Id = :wrapper.loanApplicationId 
            LIMIT 1
        ];
        
        Application_Applicant__c applicant = [SELECT Id,Loan_Application__r.name,Customer__r.name,Applicant_Type__c,GSTIN__c
                                              from Application_Applicant__c where Loan_Application__c =:wrapper.loanApplicationId AND
                                              Applicant_Type__c = 'Primary Applicant' LIMIT 1];
        Applicant_Address__c applicantAddress = [SELECT Id,State__c,Address_Line_1__c,Address_Line_2__c,Address_Line_3__c
                                                 from Applicant_Address__c WHERE Applicant__c =: applicant.Id limit 1 ];
        Charges_Insurance__c LoginFeeRecord;
        if(upfrontFeeObj ==null){
            LoginFeeRecord = [SELECT Id,Login_Fees__c,Sub_Receipt_Mode__c,Transaction_Reference__c,Default_Amount_INR__c,Receipt_No__c,Payment_Received_Date__c,Requested_Amount_INR__c,Remarks__c,CreatedDate
                                from Charges_Insurance__c where 
                                Loan_Application__c =: wrapper.loanApplicationId AND Charges_Fee_Type__c = 'Login Fee' lIMIT 1];
        }
        
        List<Charges_Insurance__c> chargeInsuranceList = [SELECT Id,Login_Fees__c,Product__c,Tax__c, Product__r.Product_Master__r.PLF_Loan_Type__c,Final_Amount_INR__c,Allocated_Amount__c,Adjusted_Login_Fee__c,Charges_Fee_Type__c,Transaction_Reference__c,Receipt_No__c,Payment_Received_Date__c 
                                                from Charges_Insurance__c where 
                                                Loan_Application__c =: wrapper.loanApplicationId AND Charges_Fee_Type__c in:chargeFeeTypes AND Product__r.Product_Type__c = 'Parent' lIMIT 2]; // this should sort the product issue >> only the parent one will go in the API..
        Integration_Details__c intDetail = [SELECT Id, Business_Date__c FROM Integration_Details__c WHERE Business_Date__c !=null AND Name = 'Fetch Application Date' ORDER BY CreatedDate DESC LIMIT 1];
        Product2 subProduct = [SELECT Id,Name,Product_Master__r.PLF_Loan_Type__c from Product2 WHERE RecordType.Name = 'Sub Product' AND Product__c =:chargeInsuranceList[0].Product__c AND Loan_Application__c = :wrapper.loanApplicationId LIMIT 1];
        City_Master__c StateCode = [Select State__c,State_Name__c from City_Master__c where State_Name__c =: applicantAddress.State__c limit 1];
        System.debug('linw 47-->>> '+ StateCode.State__c);
        
        UpfrontFeeRequestWrapper req = new UpfrontFeeRequestWrapper();
        String oppNameNoHyphen = loanApplication.Name.replaceAll('-', '');
        
        req.finReference = '';
        //req.externalReference = loanApplication.Loan_Application_Number__c.replaceAll('-', '');
        req.externalReference = oppNameNoHyphen;
       
        req.amount = upfrontFeeObj== null ? Utility.addTwoZeros(LoginFeeRecord.Requested_Amount_INR__c) : Utility.addTwoZeros(upfrontFeeObj.Final_Amount_INR__c); // final amount that will be paid in upfront >> should be summation of procfee inc tax + stfr fee incl tax
        //req.finType = constants.get('Fin_Type_AHL');
        req.finType =  isHlRelated ? (String.isNotBlank(Utility_V1.returnFintypeFromTransactionTypeProduct(subProduct.Id)) ? Utility_V1.returnFintypeFromTransactionTypeProduct(subProduct.Id) : '')/*subProduct.Product_Master__r.PLF_Loan_Type__c */: chargeInsuranceList[0].Product__r.Product_Master__r.PLF_Loan_Type__c;//Changed By Prachi
        //req.finType = 'AH';
        req.paymentMode = constants.get('Payment_Mode');
        req.subReceiptMode =upfrontFeeObj ==null ? LoginFeeRecord.Sub_Receipt_Mode__c : upfrontFeeObj.Sub_Receipt_Mode__c;//constants.get('sub_Receipt_Mode');//Payment gateway - should be less than 10 characters error in response
        req.reqType = requestType;
        req.fromBranch = loanApplication.Branch_Master__r.Branch_Code__c;
        //req.toBranch = '1001';
        req.customerName = applicant.Customer__r.name;
        req.customerAddress1 = applicantAddress.Address_Line_1__c;
        req.customerAddress2 = applicantAddress.Address_Line_2__c;
        req.customerAddress3 = applicantAddress.Address_Line_3__c;
        req.customerToState = StateCode.State__c; 
        req.finBranch = loanApplication.Branch_Master__r.Branch_Code__c;
        req.stpProcess = true;
        req.processStage = constants.get('Process_Stage');
        req.realizationDate = intDetail.Business_Date__c;
        req.loanCurrency = constants.get('Loan_Currency'); 
        req.gstNumber = (applicant.GSTIN__c != null) ? applicant.GSTIN__c : '';
        
        UpfrontFeeRequestWrapper.receiptDetail detail = new UpfrontFeeRequestWrapper.receiptDetail();
        detail.transactionRef = (upfrontFeeObj == null) ? (String.isNotBlank(LoginFeeRecord.Transaction_Reference__c) ? LoginFeeRecord.Transaction_Reference__c : '')
        : (String.isNotBlank(upfrontFeeObj.Transaction_Reference__c) ? upfrontFeeObj.Transaction_Reference__c : '');
        detail.receivedDate = intDetail.Business_Date__c;

        detail.paymentRef =  (upfrontFeeObj == null) ? (String.isNotBlank(LoginFeeRecord.Receipt_No__c) ? LoginFeeRecord.Receipt_No__c : '')
        : (String.isNotBlank(upfrontFeeObj.Receipt_No__c) ? upfrontFeeObj.Receipt_No__c : '');

        detail.remarks =  (upfrontFeeObj == null) ? (String.isNotBlank(LoginFeeRecord.Remarks__c) ? LoginFeeRecord.Remarks__c : '')
        : (String.isNotBlank(upfrontFeeObj.Remarks__c) ? upfrontFeeObj.Remarks__c : '');
        detail.favourName = 'Agreds';//Mandatory
        //detail.favourNumber = '123456';
        detail.depositDate =  (upfrontFeeObj == null) ? LoginFeeRecord.CreatedDate : System.now();
        //detail.bankCode =  '004';
        detail.fundingAccount = Decimal.valueOf(Label.UpfrontFeeBankCode); 
        req.receiptDetail = detail;
        
        req.fees = new List<UpfrontFeeRequestWrapper.FeeDetail>();
        
        UpfrontFeeRequestWrapper.FeeDetail fee1 = new UpfrontFeeRequestWrapper.FeeDetail();
        UpfrontFeeRequestWrapper.FeeDetail fee2 = new UpfrontFeeRequestWrapper.FeeDetail();
        
        for (Charges_Insurance__c record : chargeInsuranceList) {
            Decimal finalAmt = record.Final_Amount_INR__c != null ? record.Final_Amount_INR__c : 0;
            Decimal adjLoginFee = record.Adjusted_Login_Fee__c != null ? record.Adjusted_Login_Fee__c : 0;
            
            Decimal allocated = record.Allocated_Amount__c;
            Decimal taxPercent = 18; //COmmenting for now : Gaurav will fill the tax percent in Tax__c field and thenwill remove comment >>> record.Tax__c; // this is being done as the upfront api doesnt calculate how much is the feebalance left hereee 
            Decimal totalWithTax = allocated + (allocated * (taxPercent / 100));


            if (record.Charges_Fee_Type__c == 'PROCFEE') {
                fee1.feeCode = record.Charges_Fee_Type__c;
                fee1.waivedAmount = 0;
                fee1.feeAmount = upfrontFeeObj == null ? Utility.addTwoZeros(totalWithTax) : Utility.addTwoZeros(totalWithTax);
                fee1.totPaid = '';
                fee1.paidAmount = upfrontFeeObj == null ? Utility.addTwoZeros(adjLoginFee) : Utility.addTwoZeros(upfrontFeeObj.Processing_Fee_Inc_Tax_Upfront__c); // NEW FIELD >> this will remain as is and we'll update that in the controller when the API hits with success
                
            } else if (record.Charges_Fee_Type__c == 'STFRCHG') {
                fee2.feeCode = record.Charges_Fee_Type__c;
                fee2.waivedAmount = 0; //wont come in fee amount but in fee Amount
                fee2.feeAmount = upfrontFeeObj == null ? Utility.addTwoZeros(allocated) : Utility.addTwoZeros(allocated);
                fee2.totPaid = '';
                fee2.paidAmount = upfrontFeeObj == null ? Utility.addTwoZeros(adjLoginFee) : Utility.addTwoZeros(upfrontFeeObj.Stamp_Fee_Inc_Tax_Upfront__c); // NEW FIELD >> this we'll reduce in the amount in the controller .
            }
        }
        
        
        
        
        // Add fee details to the fees list
        req.fees.add(fee1);
        req.fees.add(fee2);
        
        
        
        
        
        String requestJSON = JSON.serialize(req);
        requestJSON = requestJSON.replace('"loanCurrency"', '"currency"');
        system.debug('line 34--->>'+requestJSON);
        
        return requestJSON;
    }
    
}