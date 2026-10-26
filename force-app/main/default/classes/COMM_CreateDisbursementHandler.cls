public with sharing class COMM_CreateDisbursementHandler implements IntegrationInterface{

    // **Validation Method**
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
       List<String> errorMessages = new List<String>();

       return errorMessages;
    }

    // **Construct Payload Method**
    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
            system.debug('wrapper:: '+wrapper);
            String loanApplicationId = wrapper.loanApplicationId;
            List<String> vasCodes = new List<String>();
            Map<String, Map<String, String>> mapMasterCode =  COMM_UpsertCustomerHandler.getMasterCode();

            // **Bulk Query: Fetch Loan Application (Opportunity)**
            List<Opportunity> loanApplications = [SELECT Id,LMS_Loan_Reference__c FROM Opportunity WHERE Id = :loanApplicationId];
            Opportunity loanApplication = loanApplications.isEmpty() ? null : loanApplications[0];

            List<Charges_Insurance__c> InsuranceList = getChargeInsuranceList('Insurance', loanApplicationId); 
            for(Charges_Insurance__c ins : InsuranceList){
                vasCodes.add(ins.VAS_Code__c);
            }

            List<Loan_Transaction__c> disbursementRecs = [SELECT Id, Name, Net_Amount__c,Scheduled_Disbursement_Date__c,Disbursement_Party__c, Disbursement_Type__c, Loan_Application__c,Disbursement_Date__c,
                                                          Disbursement_Amount__c,Partner_bank__c,Cheque_DD_Number__c,Remark__c,Bank_Details__r.Bank_Master__r.Bank_Code__c, Bank_Details__r.Bank_Master__r.Branch_Code__c, 
                                                          Bank_Details__r.Bank_Master__r.IFSC__c,Bank_Details__r.Bank_Master__r.MICR__c,Bank_Details__r.Account_Holder_Name__c, Bank_Details__r.Account_Number__c, 
                                                          Bank_Details__r.Account_Type__c, Bank_Details__r.Bank_Master__r.Bank_Name__c,Third_Party_Phone_Number__c,Mobile_Number__c,Favoring_Name__c,Payable_Location__c,
                                                          Value_Date__c,Printing_Location__c,Issuing_Bank_Location__c
                                                          FROM Loan_Transaction__c 
                                                          WHERE Loan_Application__c = :loanApplicationId And RecordType.DeveloperName = 'Payment' AND QDP_Status__c = 'New'];

            List<Charges_Insurance_Master__c>  vasBankDetailList = getVasBankDetails(vasCodes);
            Charges_Insurance_Master__c vasBankDetails = (!vasBankDetailList.isEmpty()) ? vasBankDetailList[0] : null;
            Set<String> setOfIssuingBankLocation = new Set<String>();
            Set<String> setOfPrintingLocation = new Set<String>();
            for(Loan_Transaction__c pay: disbursementRecs){
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
                    mapOfLocationVsBankCode.put(bankBranch.Branch_Name__c, bankBranch.Bank_Code__c);
                }
            }

            // **Initialize Request Wrapper**
            CreateDisbursementRequestWrapper request = new CreateDisbursementRequestWrapper();
            request.finReference = loanApplication.LMS_Loan_Reference__c != null ? loanApplication.LMS_Loan_Reference__c : '';
            request.disbursements = new List<DisbursementsReq>();
            for (Loan_Transaction__c disbRec : disbursementRecs) {
                DisbursementsReq disbWrap = new DisbursementsReq();  
                disbWrap.disbParty = (disbRec.Disbursement_Party__c != null) ? mapMasterCode.get('Disbursement Party'.toLowerCase()).get(disbRec.Disbursement_Party__c.toLowerCase()) : '' ;  
                disbWrap.disbDate = formatDateString(disbRec.Scheduled_Disbursement_Date__c);// for Dev/UAT this should be greater than GC system date i.e 2038/08/15
                if(disbRec.Net_Amount__c != null){
                    disbWrap.disbAmount = disbRec.Net_Amount__c!=null ? addTwoZeros((Integer)Math.round(disbRec.Net_Amount__c)) : 0;
                } else {
                    disbWrap.disbAmount = 0; 
                }

                if(disbRec.Disbursement_Party__c != null){
                    if(disbRec.Disbursement_Party__c == 'VAS') {
                        disbWrap.disbType = 'NEFT'; 
                        if(vasBankDetails != null){
                            disbWrap.issueBank = vasBankDetails.Bank_Branch_Master__r.Bank_Code__c ?? '';
                            disbWrap.bankCode = vasBankDetails.Bank_Branch_Master__r.Bank_Code__c ?? '';
                            disbWrap.branchCode = vasBankDetails.Bank_Branch_Master__r.Branch_Code__c ?? '';  
                            disbWrap.ifsc = vasBankDetails.Bank_Branch_Master__r.IFSC__c ?? '';  
                            disbWrap.accountNo = vasBankDetails.Account_Number__c ??  '';
                            disbWrap.acHolderName = vasBankDetails.Dealer_Name__c ??  '';                          
                        }                   
                    }  else {  // Customer , Third Party
                        disbWrap.disbType = (String.isNotBlank(disbRec.Disbursement_Type__c)) ? disbRec.Disbursement_Type__c : 'NEFT';   
                        disbWrap.bankCode = (disbRec.Bank_Details__r.Bank_Master__r.Bank_Code__c != null) ? disbRec.Bank_Details__r.Bank_Master__r.Bank_Code__c : '';                      
                        disbWrap.branchCode = (disbRec.Bank_Details__r.Bank_Master__r.Branch_Code__c != null) ? disbRec.Bank_Details__r.Bank_Master__r.Branch_Code__c : '';  
                        disbWrap.ifsc = (disbRec.Bank_Details__r.Bank_Master__r.IFSC__c != null) ?  disbRec.Bank_Details__r.Bank_Master__r.IFSC__c : ''; 
                        /*disbWrap.accountNo = (disbRec.Bank_Details__r.Account_Number__c  != null) ? disbRec.Bank_Details__r.Account_Number__c : '';   commenting this as will move out opf the array arey
                        disbWrap.issueBank = (disbRec.Bank_Details__r.Bank_Master__r.Bank_Code__c != null) ? disbRec.Bank_Details__r.Bank_Master__r.Bank_Code__c : '';  
                        disbWrap.acHolderName = (disbRec.Bank_Details__r.Account_Holder_Name__c != null) ? disbRec.Bank_Details__r.Account_Holder_Name__c : '';  */

                        if(disbWrap.disbType == 'CHEQUE'){
                        if(disbRec.Issuing_Bank_Location__c != null && disbRec.Printing_Location__c != null){
                            disbWrap.issueBank = (!mapOfLocationVsBankCode.isEmpty() && mapOfLocationVsBankCode.containsKey(disbRec.Printing_Location__c)) ? mapOfLocationVsBankCode.get(disbRec.Printing_Location__c) : '';
                        }
                        else{
                            disbWrap.issueBank = '';
                        }
                        disbWrap.favourName = String.isNotBlank(disbRec.Favoring_Name__c) ?  disbRec.Favoring_Name__c : '';
                        disbWrap.payableLoc = disbRec.Payable_Location__c!=null ? disbRec.Payable_Location__c : '';
                        disbWrap.chequeNo = disbRec.Cheque_DD_Number__c != null ? disbRec.Cheque_DD_Number__c : '';
                        disbWrap.printingLoc = disbRec.Printing_Location__c!=null ? disbRec.Printing_Location__c : '';
                        disbWrap.accountNo  = '';
                        disbWrap.acHolderName = '';
                        }
                        else{
                            disbWrap.favourName =  '';
                            disbWrap.payableLoc =  '';
                            disbWrap.chequeNo = '';
                            disbWrap.printingLoc = '';
                            disbWrap.accountNo = (disbRec.Bank_Details__r.Account_Number__c  != null) ? disbRec.Bank_Details__r.Account_Number__c : '';
                            disbWrap.acHolderName = (disbRec.Bank_Details__r.Account_Holder_Name__c != null) ? disbRec.Bank_Details__r.Account_Holder_Name__c : ''; 
                        }
                    }                 
                }

                disbWrap.partnerBankId = disbRec.Partner_bank__c!=null ? String.valueOf(Integer.valueOf(disbRec.Partner_bank__c)) :'' ;  // '154'
                disbWrap.phoneNumber = disbRec.Disbursement_Party__c != null && disbRec.Disbursement_Party__c == 'Third party' ? disbRec.Third_Party_Phone_Number__c : disbRec.Mobile_Number__c ?? '';
                disbWrap.remarks = String.isNotBlank(disbRec.Id) ? disbRec.Id : '';
                disbWrap.valueDate = disbRec.Value_Date__c!=null ? formatDateString(disbRec.Value_Date__c) : '';
                // pending fields to be mapped
                disbWrap.phoneCountryCode= '';
                disbWrap.phoneAreaCode = '';
                
                request.disbursements.add(disbWrap);
            }

            // **Convert to JSON**
            String requestJSON = JSON.serialize(request);
            System.debug('Request JSON: ' + requestJSON);
            return requestJSON;
        } catch (Exception e) {
            throw new AuraHandledException('There is a Salesforce Exception, please contact your Salesforce Administrator.');
        }
    }

    public static Integer addTwoZeros(Decimal inputNumber) { //returning Integer now.. it seems the server side requests two zeros --00-- instead of decimal.00
        // Multiply the number by 100 to add two zeros
        return Integer.valueOf(inputNumber * 100);
    }
    
    public static List<Charges_Insurance_Master__c> getVasBankDetails(List<String> vasCodes){
        try {
            List<Charges_Insurance_Master__c> chargesMaster = new List<Charges_Insurance_Master__c>();
            
            if(vasCodes.isEmpty()){
                return chargesMaster;
            }
            
            List<Charges_Insurance_Master__c> chargesInsuranceMaster = [
                SELECT Id, VAS_Provider__c FROM Charges_Insurance_Master__c WHERE VAS_Code__c IN :vasCodes
            ];
            Charges_Insurance_Master__c  vasDetails = chargesInsuranceMaster != null ? chargesInsuranceMaster[0] : null;
            
            if(vasDetails != null){
                chargesMaster = [
                    SELECT Id,Dealer_Name__c, Account_Number__c,Bank_Branch_Master__r.IFSC__c,
                    Bank_Branch_Master__r.Bank_Code__c,Bank_Branch_Master__r.Branch_Code__c,
                    Bank_Branch_Master__r.Bank_Name__c  
                    FROM Charges_Insurance_Master__c 
                    WHERE Id =: vasDetails.VAS_Provider__c 
                ];
            }         

            return chargesMaster;
        } catch (Exception e) {
            System.debug('FinanceApiHandler->getVasBankDetails ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    } 

    public static List<Charges_Insurance__c> getChargeInsuranceList(String recType, String loanId){
        try {
            List<Charges_Insurance__c> chargesInsuranceList = new List<Charges_Insurance__c>();
            if(recType == 'Charges'){
                    chargesInsuranceList = [SELECT id, Fee_Method__c,VAS_Code__c,Total_VAS_Amount__c,Category__c,
                Self_Funded_Amount__c,Value_Date__c,Nom_Relationship__c,Loan_Amount__c, Loan_tenure__c,Gender_Bank_Insurance_Details__c,
                Insurance_Premium__c,Sum_Insured_Customer_Details__c,Applicant_Type__c,Date_of_Birth__c,Gender__c,Charges_Fee_Type__c,
                Requested_Amount_INR__c,  Policy_Tenure__c ,Application_Applicant__r.Customer_Profile__c, Nominee_Name__c,Nominee_DOB__c        
                FROM Charges_Insurance__c 
                WHERE RecordType.DeveloperName =: recType AND  Loan_Application__c =: loanId 
                AND (Category__c IN ('LOS','Insurance'))
                ];
            } else {
                    chargesInsuranceList = [SELECT id, Fee_Method__c,VAS_Code__c,Total_VAS_Amount__c,Category__c,
                Self_Funded_Amount__c,Value_Date__c,Nom_Relationship__c,Loan_Amount__c, Loan_tenure__c,Gender_Bank_Insurance_Details__c,
                Insurance_Premium__c,Sum_Insured_Customer_Details__c,Applicant_Type__c,Date_of_Birth__c,Gender__c,Charges_Fee_Type__c,
                Requested_Amount_INR__c,  Policy_Tenure__c ,Application_Applicant__r.Customer_Profile__c, Nominee_Name__c,Nominee_DOB__c        
                FROM Charges_Insurance__c 
                WHERE RecordType.DeveloperName =: recType AND Loan_Application__c =: loanId];             
            }            

            return chargesInsuranceList;

        } catch (Exception e) {
            System.debug('FinanceApiHandler->getChargeInsuranceList ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
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

    public class CreateDisbursementRequestWrapper {
       public String finReference;	//GHF1001HL0005309
       public DisbursementsReq[] disbursements;
    }

    public class DisbursementsReq {
        public String disbParty;
        public String disbType;
        public String disbDate;
        public Integer disbAmount;
        public String partnerBankId;
        public String chequeNo;
        public String remarks;
        public String issueBank;
        public String payableLoc;
        public String printingLoc;
        public String valueDate;
        public String bankCode;
        public String branchCode;
        public String ifsc;
        public String favourName;
        public String accountNo;
        public String acHolderName;
        public String phoneCountryCode;
        public String phoneAreaCode;
        public String phoneNumber;
	}
}