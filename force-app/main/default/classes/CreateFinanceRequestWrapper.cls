public class CreateFinanceRequestWrapper{
	public boolean stp;
	public String finReference;	//
	public String processStage;	//
	public FinanceSchedule financeSchedule;
	public CoApplicants[] coApplicants;
	public Collaterals[] collaterals;
	public CovenantDetails[] covenantDetails;
	public Disbursement[] disbursement;
	public MandateDetail mandateDetail;
	public ChequeHeaders[] chequeHeaders;
	public FinOCRHeader finOCRHeader;
	public boolean createPLMGroup;
	public boolean existingGroup;
	public String groupCode;	//
	public PlmHeaderList[] plmHeaderList;
	public class FinanceSchedule {
		public FinanceDetail financeDetail;
		public Step[] step;
		public Vas[] vas;
		public Fees[] fees;
		public String externalReference;
	}
	public ExtendedDetails[] extendedDetails;
	public class FinanceDetail {
		public String finType;	//HL
		public String cif;	//105374
		public Integer finBranch;	//1001
		public Integer sourcingBranch;	//1001
		public Long finAmount;	//27168000  //it was decimal in BL with add two zeros logic
		public String finStartDate;	//2037-07-10T00:00:00
		public String repayFrq;	//M0003
		public boolean allowOCR;
		public Decimal repayMargin;
		public String parentLoanReference;	//
		public boolean stepFinance;
		public boolean alwManualSteps;
		public boolean allowGrcPeriod;
		public Integer noOfSteps;	//2
		public Integer noOfGrcSteps;	//2
		public String grcPftFrq;	//M0003
		public String grcCpzFrq;	//M0003
		public boolean allowGrcRepay;
		public String grcSchdMthd;	//PFT
		public String nextGrcPftDate;	//
		public String nextRepayDate;	//
		public String repayPftFrq;	//M0003
		public String nextRepayPftDate;	//
		public String repayRvwFrq;	//M0003
		public String nextRepayRvwDate;	//
		public String finRepayMethod;	//NACH
		public String applicationNo;
		public String offerId;	//6990
		public String numberOfTerms;	//48
		public Integer grcTerms;	//12
		public String grcRateBasis;	//R
		public Integer grcPftRate;	//0
		public String grcBaseRate;	//GHFPLR
		public Decimal grcMargin;	//0
		public String repayBaseRate;	//GHFPLR
		public Integer fixedRateTenor;	//5
		public String interestType;	//
		public Long finAssetValue;	//60000000
		public String dftBpiTreatment; // E
		public String bpiPftDaysBasis; //
		public boolean alwBpiTreatment; // new tag for bpi
		public String finPurpose;	//BR
		public Integer finCurrAssetValue;	//0
		public String sourChannelCategory;	//DSA
		public String dsaCode;	//
		public String dmaCode;	//
		public boolean quickDisb;
		
		public Long reqLoanAmt;	//600000000
		public String reqloanTenor;	//
		public String reqTerms;	//
		public String maturityDate;	//
		public String scheduleMethod;	//EQUAL
	}
	public class Step {
		public Integer stepNumber;	//1
		public Decimal tenorSplitPerc;	//50.00
		public Integer rateMargin;	//0
		public Integer emiSplitPerc;	//0
		public Integer steppedEMI;	//0
		public String stepSpecifier;	//G
		public Integer autoCal;	//0
		public Integer installments;	//6
	}
	public class Vas {
		public String product;	//TAIGGMC
		public String postingAgainst;	//Loan
		public String totalVASAmount;	//1000000
		public String selfFundedAmount;	//800000
		public String waivedAmt;	//
		public String feePaymentMode;	//Cash
		public String valueDate;	//2037-07-10T00:00:00
		public String renewalFee;	//200000
		public String entitycode;	//GHF
		public String terminsurancelien;	//false
		public String medicalstatus;	//
		public String medicalapplicable;	//false
		public String status;	//
		public String count;	//
		public String fee;
		public ExtendedDetails[] extendedDetails;
	}
	public class ExtendedDetails {
		public ExtendedFields[] extendedFields;
	}
	public class ExtendedFields {
		public String fieldName;	//NOMINEERELATIONSH
		public String fieldValue;	//SIS
	}
	public class Fees {
		public String feeCategory;	//FC
		public String feeCode;	//TAIGGMC
		public String feeAmount;	//200000
		public String waiverAmount;	//0
		public String paidAmount;	//0
		public String feeMethod;	//DISB
		public Integer scheduleTerms;	//0
		public Integer feeBalance;	//0
		public Integer version;	//1
		public FinFeeReceipts[] finFeeReceipts;
	}
	public class FinFeeReceipts {
	}
	public class CoApplicants {
		public String cif;	//105407
		public String catOfcoApplicant;	//BRTINLAW
		public String includeRepay;	//false
	}
	public class Collaterals {
		public String collateralRef;	//CT3724400002
		public Integer assignPerc;	//30
		public Integer version;	//1
		public Integer seq;	//0
	}
	public class CovenantDetails {
		public String category;	//SKR
		public String covenantTypeId;	//19
		public String description;	//SKR
		public String otc;	//N
		public String pdd;	//Y
		public String receivableDate;	//2038-01-16T00:00:00
		public String frequency;	//
		public String alertsRequired;	//N
		public String alertType;	//
		public String graceDays;	//
		public String alertDays;	//
		public String nextFrequencyDate;	//
		public String notifyTo;	//
		public String graceDueDate;	//
		public String internalUse;	//true
		public String standardValue;	//6
		public String actualValue;	//5
		public String allowWaiver;	//false
		public String mandatoryRole;	//
		public String natureOfDoc;	//
		public String printOnLod;	//
		public String remarks;
		public String additionalRemarks;
		public CovenantDocuments[] covenantDocuments;
	}
	public class CovenantDocuments {
	}
	public class Disbursement {
		public String disbParty;	//CS
		public String disbType;	//NEFT
		public String disbDate;	//2037-07-10T00:00:00
		public Long disbAmount;	//25752000
		public String partnerBankId;	//153
		public String remarks;	//
		public String issueBank;	//002
		public String favourName;	//
		public String payableLoc;	//xdx
		public String printingLoc;	//xdfv
		public String valueDate;	//2037-07-10T00:00:00
		public String bankCode;	//002
		public String branchCode;	//067501
		public String ifsc;	//SBIN0006042
		public String accountNo;	//101
		public String acHolderName;	//Akshaya
		public String phoneCountryCode;	//162
		public String phoneAreaCode;	//123
		public String phoneNumber;	//2563986996
		public String chequeNo;	//2563986996
		public string vasProductCode;
	}
	public class MandateDetail {
		public boolean useExisting;
		public String mandateType;	//NACH
		public String mandateID;	//4284
		public String entityCode;	//SF
		public String bankCode;	//016
		public String branchCode;	//017213
		public String ifsc;	//CBIN0282064
		public String micr;	//400016053
		public String accType;	//11
		public String partnerBankId;	//207
		public String accNumber;	//1234567890
		public String accHolderName;	//ramya
		public String jointAccHolderName;	//raj
		public String openMandate;	//false
		public String docRefId;	//2
		public String documentName;	//mandate.jpg
		public String startDate;	//2037-07-16T00:00:00
		public String expiryDate;	//2050-12-025T00:00:00
		public Integer maxLimit;	//10000000
		public String periodicity;	//M0003
		public String phoneNumber;	//1234589670 >> converted into String since being integer the max value it can take is 2,147,483,647 beacuse of 32-bit ?>> reverted back
	}
	public class ChequeHeaders {
		public String noOfCheques;	//3
		public String ifsc;	//
		public String micr;	//
		public String bankCode;	//002
		public String branchCode;	//109010
		public String accHolderName;	//Akula
		public String accountNo;	//123456789098765
		public String chequeSerialNo;	//23460
		public ChequeDetails[] chequeDetails;
	}
	public class ChequeDetails {
		public String chequeType;	//PDC
		public String accountType;	//SA
		public String chequeDate;	//2046-04-03T00:00:00
		public String amount;	//15846000
		public String docFormat;	//
		public String docName;	//
		public String docContent;	//
	}
	public class FinOCRHeader {
		public String ocrID;	//2080
		public String totalDemand;	//10000000
		public OCRDetails[] OCRDetails;
		public OCRCaptureDetails[] OCRCaptureDetails;
	}
	public class OCRDetails {
		public Integer version;	//1
		public Integer stepSequence;	//1
		public Decimal customerContribution;	//5
		public Decimal financerContribution;	//0
		public String contributor;	//Customer
	}
	public class OCRCaptureDetails {
		public Integer receiptNumber;	//1
		public Long demandAmount;	//29882000
		public String paidAmount;	//2500000
		public String receiptDate;	//2037-07-10T00:00:00
		public String remarks;	//
	}
	public class PlmHeaderList {
		public String groupDesc;	//TESTING111
		public String finreference;	//GHF1001AH0005212, GHF1001AH0005123
	}
	public static CreateFinanceRequestWrapper parse(String json){
		return (CreateFinanceRequestWrapper) System.JSON.deserialize(json, CreateFinanceRequestWrapper.class);
	}
}