public with sharing class SalesLoanEntireViewController {
    @AuraEnabled
    public static List<String> getLoanDetailsFromCustId(String custId) {
        try {
           
            List<String> loanNumbers = new List<String>();
            if (custId != null) {
                COMM_GetCustomerController.Response custResponse = (COMM_GetCustomerController.Response)JSON.deserialize(COMM_GetCustomerController.getCustomerDetails(custId, 'Get Customer').respBody,COMM_GetCustomerController.Response.class);
                    if (custResponse != null && custResponse.customerFinanceDetailList != null) {
                    system.debug('Response--> '+custResponse.customerFinanceDetailList);
                    for (COMM_GetCustomerController.cls_customerFinanceDetailList financeDetail : custResponse.customerFinanceDetailList) {
                        if (financeDetail != null && String.isNotBlank(financeDetail.finReference)) {
                            loanNumbers.add(financeDetail.finReference);
                        }
                    }
                  
                    // for (String loanNumber : loanNumbers) {
                    //      GetExistingLoanDetailsController.getExistingLoanDetails(loanNumber);
                       
                    // }
                }
                
            }
            return loanNumbers;
        } catch (Exception e) {
            throw new AuraHandledException('Error in getLoanDetailsFromCustId: ' + e.getMessage());
        }
    }



    
    @AuraEnabled
    public static List< GetExistingLoanDetailsController.GetExistingLoanDetailsWrapper> getLoanDetailsFromCIF(String cifId) {
        List<GetExistingLoanDetailsController.GetExistingLoanDetailsWrapper> loanDetailsList = new List<GetExistingLoanDetailsController.GetExistingLoanDetailsWrapper>();

        try {
            Account acc = [SELECT Id FROM Account WHERE Customer_LMS_Id__c = :cifId LIMIT 1];
            if (acc != null) {
                    List<Integration_Details__c> allIntegrationRecords = [
                    SELECT Id, GC_Loan_Number__c, Related_Record_Id__c, CreatedDate
                    FROM Integration_Details__c
                    WHERE Name = 'Get Loan Details'
                    AND GC_Loan_Number__c != null
                    AND Object_Name__c = 'Document_Details__c'
                    AND Related_Record_Id__c != null
                    
                    AND Customer_Id__c =: cifId
                    ORDER BY CreatedDate DESC
                ];
                Map<String, String> latestPerLoanMap = new Map<String, String>();
                for (Integration_Details__c record : allIntegrationRecords) {
                    if (!latestPerLoanMap.containsKey(record.GC_Loan_Number__c)) {
                        latestPerLoanMap.put(record.GC_Loan_Number__c, record.Related_Record_Id__c);
                    }
                }
                    List<Document_Details__c> docList = [
                    SELECT Id, Content_Document_Id__c, Account__c
                    FROM Document_Details__c
                    WHERE Id IN :latestPerLoanMap.values() AND Account__c = :acc.Id
                ];
    
                Set<Id> contentDocIds = new Set<Id>();
                for (Document_Details__c doc : docList) {
                    if (doc.Content_Document_Id__c != null) {
                        contentDocIds.add(doc.Content_Document_Id__c);
                    }
                }
                List<ContentVersion> versionList = [
                    SELECT Id, VersionData
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :contentDocIds
                    ORDER BY CreatedDate DESC
                ];
    
                for (ContentVersion version : versionList) {
                    String txtContent = version.VersionData.toString();
                        if (String.isNotBlank(txtContent)) 
                        {
                            GetExistingLoanDetailsController.GetExistingLoanDetailsWrapper detail = (GetExistingLoanDetailsController.GetExistingLoanDetailsWrapper) JSON.deserialize(txtContent,GetExistingLoanDetailsController.GetExistingLoanDetailsWrapper.class);
                            loanDetailsList.add(detail);
                            
                        }
                } 
            }
    }catch (Exception e) {
            throw new AuraHandledException('Error in getLoanDetailsFromCIF: ' + e.getMessage());
        }

        return loanDetailsList;
    }
    
    @AuraEnabled
    public static List<LoanDetailsWrapper> getFinanceDetails(String cifId) {
        try {
            List<GetExistingLoanDetailsController.GetExistingLoanDetailsWrapper> loanDetailsList = getLoanDetailsFromCIF(cifId);
            List<LoanDetailsWrapper> loanDetails = new List<LoanDetailsWrapper>();

            for (GetExistingLoanDetailsController.GetExistingLoanDetailsWrapper lwList : loanDetailsList) {
                LoanDetailsWrapper lo = new LoanDetailsWrapper();
                lo.loanNumber = lwList.finReference;

                cls_financeDetail financeSchedule = new cls_financeDetail();
                if(lwList.financeSchedule != null && lwList.financeSchedule.financeDetail !=null){
                    financeSchedule.applicationNo = lwList.financeSchedule.financeDetail.applicationNo;
                    financeSchedule.finType = lwList.financeSchedule.financeDetail.finType;
                    financeSchedule.finCcy = lwList.financeSchedule.financeDetail.finCcy;
                    financeSchedule.finBranch = lwList.financeSchedule.financeDetail.finBranch;
                    financeSchedule.finAmount = lwList.financeSchedule.financeDetail.finAmount;
                    financeSchedule.finAssetValue = lwList.financeSchedule.financeDetail.finAssetValue;
                    financeSchedule.finRepayMethod = lwList.financeSchedule.financeDetail.finRepayMethod;
                    financeSchedule.finStartDate = lwList.financeSchedule.financeDetail.finStartDate;
                    financeSchedule.numberOfTerms = lwList.financeSchedule.financeDetail.numberOfTerms;
                    financeSchedule.stage = lwList.financeSchedule.financeDetail.stage;
                    financeSchedule.status = lwList.financeSchedule.financeDetail.status;
                }
                
                lo.financeSchedule = financeSchedule;
                lo.repayList = new List<cls_repayInstruction>();
                if(lwList.financeSchedule != null && lwList.financeSchedule.repayInstruction !=null){
                    for(GetExistingLoanDetailsController.cls_repayInstruction iterRepay : lwList.financeSchedule.repayInstruction){
                        cls_repayInstruction childRepay = new cls_repayInstruction();
                        childRepay.repayDate = iterRepay.repayDate;
                        childRepay.repayAmount = iterRepay.repayAmount;
                        childRepay.repaySchdMethod = iterRepay.repaySchdMethod;
                        childRepay.version = iterRepay.version;
                        lo.repayList.add(childRepay);
                    }
                }
                lo.scheduleList = new List<cls_schedules>();
                if(lwList.financeSchedule != null && lwList.financeSchedule.schedules !=null){
                    for(GetExistingLoanDetailsController.cls_schedules iter : lwList.financeSchedule.schedules){
                        cls_schedules childSchedule = new cls_schedules();
                        childSchedule.schDate = iter.schDate;
                        childSchedule.pftAmount = iter.pftAmount;
                        childSchedule.schdPft = iter.schdPft;
                        childSchedule.schdPftPaid = iter.schdPftPaid;
                        childSchedule.schdPri = iter.schdPri;
                        childSchedule.schdPriPaid = iter.schdPriPaid;
                        childSchedule.feeSchd = iter.feeSchd;
                        childSchedule.tDSAmount = iter.tDSAmount;
                        childSchedule.totalAmount = iter.totalAmount;
                        childSchedule.endBal = iter.endBal;
                        childSchedule.limitDrop = iter.limitDrop;
                        childSchedule.dropLineLimit = iter.dropLineLimit;
                        childSchedule.availableLimit = iter.availableLimit;
                        childSchedule.dueDate = iter.dueDate;
                        childSchedule.version = iter.version;
                        lo.scheduleList.add(childSchedule);
                    }
                }
                lo.overdueDetails = new cls_overdue();
                if(lwList.financeSchedule != null && lwList.financeSchedule.overdue != null){
                    lo.overdueDetails.applyODPenalty = lwList.financeSchedule.overdue.applyODPenalty;
                    lo.overdueDetails.odIncGrcDays = lwList.financeSchedule.overdue.odIncGrcDays;
                    lo.overdueDetails.odGraceDays = lwList.financeSchedule.overdue.odGraceDays;
                    lo.overdueDetails.odChargeType = lwList.financeSchedule.overdue.odChargeType;
                    lo.overdueDetails.odChargeCalOn = lwList.financeSchedule.overdue.odChargeCalOn;
                    lo.overdueDetails.odChargeAmtOrPerc = lwList.financeSchedule.overdue.odChargeAmtOrPerc;
                    lo.overdueDetails.odAllowWaiver = lwList.financeSchedule.overdue.odAllowWaiver;
                    lo.overdueDetails.odMaxWaiverPerc = lwList.financeSchedule.overdue.odMaxWaiverPerc;
                }
                lo.summaryDetails = new cls_summary();
                if(lwList.financeSchedule != null && lwList.financeSchedule.summary !=null){
                    lo.summaryDetails.effectiveRateOfReturn = lwList.financeSchedule.summary.effectiveRateOfReturn;
                    lo.summaryDetails.totalGracePft = lwList.financeSchedule.summary.totalGracePft;
                    lo.summaryDetails.totalGraceCpz = lwList.financeSchedule.summary.totalGraceCpz;
                    lo.summaryDetails.totalGrossGrcPft = lwList.financeSchedule.summary.totalGrossGrcPft;
                    lo.summaryDetails.totalCpz = lwList.financeSchedule.summary.totalCpz;
                    lo.summaryDetails.totalProfit = lwList.financeSchedule.summary.totalProfit;
                    lo.summaryDetails.totalRepayAmt = lwList.financeSchedule.summary.totalRepayAmt;
                    lo.summaryDetails.feeChargeAmount = lwList.financeSchedule.summary.feeChargeAmount;
                    lo.summaryDetails.numberOfTerms = lwList.financeSchedule.summary.numberOfTerms;
                    lo.summaryDetails.loanTenor = lwList.financeSchedule.summary.loanTenor;
                    lo.summaryDetails.maturityDate = lwList.financeSchedule.summary.maturityDate;
                    lo.summaryDetails.firstDisbDate = lwList.financeSchedule.summary.firstDisbDate;
                    lo.summaryDetails.lastDisbDate = lwList.financeSchedule.summary.lastDisbDate;
                    lo.summaryDetails.firstEmiAmount = lwList.financeSchedule.summary.firstEmiAmount;
                    lo.summaryDetails.nextSchDate = lwList.financeSchedule.summary.nextSchDate;
                    lo.summaryDetails.nextRepayAmount = lwList.financeSchedule.summary.nextRepayAmount;
                    lo.summaryDetails.futureInst = lwList.financeSchedule.summary.futureInst;
                    lo.summaryDetails.futureTenor = lwList.financeSchedule.summary.futureTenor;
                    lo.summaryDetails.firstInstDate = lwList.financeSchedule.summary.firstInstDate;
                    lo.summaryDetails.paidTotal = lwList.financeSchedule.summary.paidTotal;
                    lo.summaryDetails.paidPri = lwList.financeSchedule.summary.paidPri;
                    lo.summaryDetails.paidPft = lwList.financeSchedule.summary.paidPft;
                    lo.summaryDetails.lastRepayDate = lwList.financeSchedule.summary.lastRepayDate;
                    lo.summaryDetails.outstandingTotal = lwList.financeSchedule.summary.outstandingTotal;
                    lo.summaryDetails.outstandingPri = lwList.financeSchedule.summary.outstandingPri;
                    lo.summaryDetails.outstandingPft = lwList.financeSchedule.summary.outstandingPft;
                    lo.summaryDetails.overdueTotal = lwList.financeSchedule.summary.overdueTotal;
                    lo.summaryDetails.overduePri = lwList.financeSchedule.summary.overduePri;
                    lo.summaryDetails.overduePft = lwList.financeSchedule.summary.overduePft;
                    lo.summaryDetails.overdueInst = lwList.financeSchedule.summary.overdueInst;
                    lo.summaryDetails.overDueChargesVal = lwList.financeSchedule.summary.overDueChargesVal;
                    lo.summaryDetails.overdueTotalIncludeCharges = lwList.financeSchedule.summary.overdueTotalIncludeCharges;
                    lo.summaryDetails.advPaymentAmount = lwList.financeSchedule.summary.advPaymentAmount;
                    lo.summaryDetails.finActiveStatus = lwList.financeSchedule.summary.finActiveStatus;
                    lo.summaryDetails.fullyDisb = lwList.financeSchedule.summary.fullyDisb;
                    lo.summaryDetails.limitBalance = lwList.financeSchedule.summary.limitBalance;
                    lo.summaryDetails.billedAmount = lwList.financeSchedule.summary.billedAmount;
                    lo.summaryDetails.unbilledAmount = lwList.financeSchedule.summary.unbilledAmount;
                    lo.summaryDetails.DPDDays = lwList.financeSchedule.summary.DPDDays;
                    lo.summaryDetails.dueDate = lwList.financeSchedule.summary.dueDate;
                    lo.summaryDetails.dueAmount = lwList.financeSchedule.summary.dueAmount;
                    lo.summaryDetails.limitDrop = lwList.financeSchedule.summary.limitDrop;
                    lo.summaryDetails.currentDroplineLimit = lwList.financeSchedule.summary.currentDroplineLimit;
                    lo.summaryDetails.utilisation = lwList.financeSchedule.summary.utilisation;
                    lo.summaryDetails.availableLimit = lwList.financeSchedule.summary.availableLimit;
                    lo.summaryDetails.graceInst = lwList.financeSchedule.summary.graceInst;
                    lo.summaryDetails.graceTenor = lwList.financeSchedule.summary.graceTenor;
                    lo.summaryDetails.futureGraceInst = lwList.financeSchedule.summary.futureGraceInst;
                    lo.summaryDetails.futureGraceTenor = lwList.financeSchedule.summary.futureGraceTenor;
                    lo.summaryDetails.totalRevisedTenure = lwList.financeSchedule.summary.totalRevisedTenure;
                    lo.summaryDetails.revisedLastStepTerms = lwList.financeSchedule.summary.revisedLastStepTerms;
                }
                lo.disbursementList = new List<cls_Disbursements>();
                if(lwList != null && lwList.financeSchedule != null && lwList.financeSchedule.disbursements != null){
                    for(GetExistingLoanDetailsController.cls_Disbursements iter : lwList.financeSchedule.disbursements){
                        cls_Disbursements childDisb = new cls_Disbursements();
                        childDisb.disbParty = iter.disbParty;
                        childDisb.disbType = iter.disbType;
                        childDisb.disbDate = iter.disbDate;
                        childDisb.disbAmount = iter.disbAmount;
                        childDisb.bankCode = iter.bankCode;
                        childDisb.branchBankName = iter.branchBankName;
                        childDisb.branchCode = iter.branchCode;
                        childDisb.ifsc = iter.ifsc;
                        childDisb.accountNo = iter.accountNo;
                        childDisb.acHolderName = iter.acHolderName;
                        childDisb.partnerBankId = iter.partnerBankId;
                        childDisb.partnerbankCode = iter.partnerbankCode;
                        childDisb.phoneNumber = iter.phoneNumber;
                        childDisb.remarks = iter.remarks;
                        childDisb.favourName = iter.favourName;
                        childDisb.payableLoc = iter.payableLoc;
                        childDisb.printingLoc = iter.printingLoc;
                        childDisb.chequeNo = iter.chequeNo;
                        childDisb.version = iter.version;
                        childDisb.vasReference = iter.vasReference;
                        
                        lo.disbursementList.add(childDisb);
                    }
                }
                lo.mandateDetails = new cls_mandateDetail();
                if(lwList.mandateDetail != null){
                    lo.mandateDetails.cif = lwList.mandateDetail.cif;
                    lo.mandateDetails.finReference = lwList.mandateDetail.finReference;
                    lo.mandateDetails.mandateID = lwList.mandateDetail.mandateID;
                    lo.mandateDetails.mandateRef = lwList.mandateDetail.mandateRef;
                    lo.mandateDetails.mandateType = lwList.mandateDetail.mandateType;
                }
                lo.coappList = new List<cls_coApplicants>();
                if(lwList.coApplicants != null){
                    for(GetExistingLoanDetailsController.cls_coApplicants iter : lwList.coApplicants){
                        cls_coApplicants classCoApp = new cls_coApplicants();
                        classCoApp.cif = iter.cif;
                        classCoApp.shortName = iter.shortName;
                        classCoApp.includeRepay = iter.includeRepay;
                        classCoApp.authoritySignatory = iter.authoritySignatory;
                        classCoApp.sequence = iter.sequence;
                        classCoApp.version = iter.version;
                        classCoApp.catOfcoApplicant = iter.catOfcoApplicant;
                        classCoApp.includeIncome = iter.includeIncome;
                        
                        lo.coappList.add(classCoApp);
                    }
                }
                //Iterate on coapplicants coming from wrapper
                //declare a variable of type cls_coApplicants inside for loop
                //assign the values from the iter wrapper
                //add the value to the lo.coappList
                //show in the same format as we are showing scheduleList but without tab(copy code from inside the tab)
                loanDetails.add(lo);
            }

            return loanDetails;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class LoanDetailsWrapper {
        @AuraEnabled public String loanNumber;
        @AuraEnabled public cls_financeDetail financeSchedule;
        @AuraEnabled public List<cls_repayInstruction> repayList;
        @AuraEnabled public List<cls_schedules> scheduleList;
        @AuraEnabled public cls_overdue overdueDetails;
        @AuraEnabled public cls_summary summaryDetails;
        @AuraEnabled public List<cls_Disbursements> disbursementList;
        @AuraEnabled public List<cls_coApplicants> coappList;
        @AuraEnabled public cls_mandateDetail mandateDetails;
    }

    public class cls_financeDetail {
        @AuraEnabled public String applicationNo;
        @AuraEnabled public String finType;
        @AuraEnabled public String finCcy;
        @AuraEnabled public String finBranch;
        @AuraEnabled public Decimal finAmount;
        @AuraEnabled public Decimal finAssetValue;
        @AuraEnabled public String finRepayMethod;
        @AuraEnabled public String finStartDate;
        @AuraEnabled public Decimal numberOfTerms;
        @AuraEnabled public String stage;
        @AuraEnabled public String status;
    }
    public class cls_repayInstruction {
        @AuraEnabled public String repayDate;    //2044-04-26T00:00:00
        @AuraEnabled public Decimal repayAmount; //0
        @AuraEnabled public String repaySchdMethod;  //PFT
        @AuraEnabled public Decimal version; //0
    }
    
    public class cls_schedules {
        @AuraEnabled public String schDate;  //2044-03-15T00:00:00
        @AuraEnabled public Decimal pftAmount;   //0
        @AuraEnabled public Decimal schdPft; //0
        @AuraEnabled public Decimal schdPftPaid; //0
        @AuraEnabled public Decimal schdPri; //0
        @AuraEnabled public Decimal schdPriPaid; //0
        @AuraEnabled public Decimal feeSchd; //0
        @AuraEnabled public Decimal tDSAmount;   //0
        @AuraEnabled public Decimal totalAmount; //0
        @AuraEnabled public Decimal endBal;  //30000000
        @AuraEnabled public Decimal limitDrop;   //0
        @AuraEnabled public Decimal dropLineLimit;   //1000000000
        @AuraEnabled public Decimal availableLimit;  //970000000
        @AuraEnabled public String dueDate;  //2044-04-06T00:00:00
        @AuraEnabled public Decimal version; //0
    }
    
    public class cls_overdue {
        @AuraEnabled public boolean applyODPenalty;
        @AuraEnabled public boolean odIncGrcDays;
        @AuraEnabled public Decimal odGraceDays; //7
        @AuraEnabled public String odChargeType; //D
        @AuraEnabled public String odChargeCalOn;    //STOT
        @AuraEnabled public Decimal odChargeAmtOrPerc;   //24
        @AuraEnabled public boolean odAllowWaiver;
        @AuraEnabled public Decimal odMaxWaiverPerc; //100
    }
    
    public class cls_summary {
        @AuraEnabled public Double effectiveRateOfReturn;    //18.369918468
        @AuraEnabled public Decimal totalGracePft;   //0
        @AuraEnabled public Decimal totalGraceCpz;   //0
        @AuraEnabled public Decimal totalGrossGrcPft;    //0
        @AuraEnabled public Decimal totalCpz;    //0
        @AuraEnabled public Decimal totalProfit; //10318500
        @AuraEnabled public Decimal totalRepayAmt;   //40318500
        @AuraEnabled public Decimal feeChargeAmount; //2399800
        @AuraEnabled public Decimal numberOfTerms;   //24
        @AuraEnabled public Decimal loanTenor;   //24
        @AuraEnabled public String maturityDate; //2046-03-26T00:00:00
        @AuraEnabled public String firstDisbDate;    //2044-03-15T00:00:00
        @AuraEnabled public String lastDisbDate; //2044-03-15T00:00:00
        @AuraEnabled public Decimal firstEmiAmount;  //430900
        @AuraEnabled public String nextSchDate;  //2044-06-26T00:00:00
        @AuraEnabled public Decimal nextRepayAmount; //430900
        @AuraEnabled public Decimal futureInst;  //22
        @AuraEnabled public Decimal futureTenor; //21
        @AuraEnabled public String firstInstDate;    //2044-04-26T00:00:00
        @AuraEnabled public Decimal paidTotal;   //0
        @AuraEnabled public Decimal paidPri; //0
        @AuraEnabled public Decimal paidPft; //0
        @AuraEnabled public String lastRepayDate;    //2044-05-26T00:00:00
        @AuraEnabled public Decimal outstandingTotal;    //40318500
        @AuraEnabled public Decimal outstandingPri;  //30000000
        @AuraEnabled public Decimal outstandingPft;  //10318500
        @AuraEnabled public Decimal overdueTotal;    //1001000
        @AuraEnabled public Decimal overduePri;  //0
        @AuraEnabled public Decimal overduePft;  //1001000
        @AuraEnabled public Decimal overdueInst; //3
        @AuraEnabled public Decimal overDueChargesVal;   //20300
        @AuraEnabled public Decimal overdueTotalIncludeCharges;  //1021300
        @AuraEnabled public Decimal advPaymentAmount;    //0
        @AuraEnabled public String finActiveStatus;  //A
        @AuraEnabled public boolean fullyDisb;
        @AuraEnabled public Decimal limitBalance;    //0
        @AuraEnabled public Decimal billedAmount;    //0
        @AuraEnabled public Decimal unbilledAmount;  //0
        @AuraEnabled public Decimal DPDDays; //69
        @AuraEnabled public String dueDate;  //
        @AuraEnabled public Decimal dueAmount;   //0
        @AuraEnabled public Decimal limitDrop;   //0
        @AuraEnabled public Decimal currentDroplineLimit;    //1000000000
        @AuraEnabled public Decimal utilisation; //30000000
        @AuraEnabled public Decimal availableLimit;  //970000000
        @AuraEnabled public Decimal graceInst;   //0
        @AuraEnabled public Decimal graceTenor;  //0
        @AuraEnabled public Decimal futureGraceInst; //0
        @AuraEnabled public Decimal futureGraceTenor;    //2
        @AuraEnabled public Decimal totalRevisedTenure;  //0
        @AuraEnabled public Decimal revisedLastStepTerms;    //0
    }
    
    public class cls_disbursements {
        @AuraEnabled public String disbParty;    //CS
        @AuraEnabled public String disbType; //NEFT
        @AuraEnabled public String disbDate; //2044-03-15T00:00:00
        @AuraEnabled public Decimal disbAmount;  //28800100
        @AuraEnabled public String bankCode; //176
        @AuraEnabled public String branchBankName;   //RATNAKAR BANK LTD
        @AuraEnabled public String branchCode;   //0000114
        @AuraEnabled public String ifsc; //RATN0000114
        @AuraEnabled public String accountNo;    //7865432456
        @AuraEnabled public String acHolderName; //gfdsa
        @AuraEnabled public Decimal partnerBankId;   //154
        @AuraEnabled public String partnerbankCode;  //106
        @AuraEnabled public String phoneNumber;  //
        @AuraEnabled public String remarks;  //
        @AuraEnabled public String favourName;   //
        @AuraEnabled public String payableLoc;   //
        @AuraEnabled public String printingLoc;  //
        @AuraEnabled public String chequeNo; //
        @AuraEnabled public Decimal version; //1
        @AuraEnabled public String vasReference; //#
    }
    
    public class cls_mandateDetail {
        @AuraEnabled public String cif;	//119808
        @AuraEnabled public String finReference;	//GFL3001BD0014530
        @AuraEnabled public boolean useExisting;
        @AuraEnabled public Decimal mandateID;	//3151
        @AuraEnabled public String mandateRef;	//
        @AuraEnabled public String mandateType;	//NACH
        @AuraEnabled public String bankCode;	//485
        @AuraEnabled public String branchCode;	//0000207
        @AuraEnabled public String ifsc;	//KKBK0000207
        @AuraEnabled public String micr;	//
        @AuraEnabled public String accType;	//12
        @AuraEnabled public String accNumber;	//4545465656545656
        @AuraEnabled public String accHolderName;	//yhtgrfdes
        @AuraEnabled public String jointAccHolderName;	//
        @AuraEnabled public boolean openMandate;
        @AuraEnabled public String startDate;	//2044-04-16T00:00:00
        @AuraEnabled public String expiryDate;	//2060-12-18T00:00:00
        @AuraEnabled public Decimal maxLimit;	//3000000000
        @AuraEnabled public String periodicity;	//M0001
        @AuraEnabled public String phoneNumber;	//
        @AuraEnabled public String status;	//NEW
        @AuraEnabled public boolean active;
        @AuraEnabled public Decimal totEMIAmount;	//430900
        @AuraEnabled public String barCodeNumber;	//
        @AuraEnabled public String entityCode;	//GFL
        @AuraEnabled public boolean swap;
        @AuraEnabled public Decimal partnerBankId;	//0
        @AuraEnabled public Decimal version;	//1
        @AuraEnabled public String reason;	//
        @AuraEnabled public boolean defaultMandate;
        @AuraEnabled public String documentName;	//
    }

    public class cls_coApplicants {
        @AuraEnabled  public String cif;	//120836
        @AuraEnabled  public String shortName;	//jinkya Daduuu More
        @AuraEnabled  public boolean includeRepay;
        @AuraEnabled  public boolean authoritySignatory;
        @AuraEnabled  public Integer sequence;	//0
        @AuraEnabled  public Integer version;	//1
        @AuraEnabled  public String catOfcoApplicant;	//MOTHER
        @AuraEnabled  public boolean includeIncome;
	}
    
    // public class cls_coApplicants {
    //     @AuraEnabled public String firstName;
    //     @AuraEnabled public String lastName;
    // }
}