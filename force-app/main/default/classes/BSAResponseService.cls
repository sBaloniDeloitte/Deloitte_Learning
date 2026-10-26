public with sharing class BSAResponseService {
    public boolean status;
	public cls_data data;
	public String message;	//callback sended
	public class cls_data {
		public cls_bsaReport bsaReport;
		public String lan;
		public String perfiosTransactionId;	//2H9H1736584084797
		public String status;	//COMPLETED
		public String bsaByteReport;	
		public cls_uploadedFile[] uploadedFile;
		public String clientTrasactionId;	//JH6fmwqzzxfNPHqyZwJC
		public String source;	//BsaPdf
		public String errorMessage;
	}
	public class cls_bsaReport {
		public cls_customerInfo customerInfo;
		public cls_accountAnalysis[] accountAnalysis;
		public cls_combinedAccountXns[] combinedAccountXns;
		public cls_combinedMonthlyDetails[] combinedMonthlyDetails;
		public cls_combinedBouncedOrPenalXns[] combinedBouncedOrPenalXns;
		public cls_combinedTransferFromToIGXns[] combinedTransferFromToIGXns;
		public cls_combinedLoanDisbursalXns[] combinedLoanDisbursalXns;
		public cls_combinedHighValueDebitXns[] combinedHighValueDebitXns;
		public cls_combinedRegularCreditXns[] combinedRegularCreditXns;
		public cls_combinedRegularDebitXns[] combinedRegularDebitXns;
		public cls_accountXns[] accountXns;
		public cls_customUserInfo customUserInfo;
		public cls_AdditionalSummaryDetails[] AdditionalSummaryDetails;
		public cls_AdditionalMonthlyDetails AdditionalMonthlyDetails;
	}
	public class cls_customerInfo {
		public String name;	//COOPER GASKETS P LTD
		public String address;	//#1018, SECTOR 21 B CHANDIGARH 160022
		public String landline;	//
		public String mobile;	//
		public String email;	//
		public String pan;	//
		public String perfiosTransactionId;	//2H9H1736584084797
		public String customerTransactionId;	//JH6fmwqzzxfNPHqyZwJC
		public String bank;	//Punjab National Bank, India
		public Decimal instId;	//30
	}
    public class cls_accountAnalysis {
		public String accountNo;	//2938008700003039
		public String accountType;	//
		public cls_loanTrackDetails[] loanTrackDetails;
		public cls_summaryInfo summaryInfo;
		public cls_monthlyDetails[] monthlyDetails;
		public cls_eODBalances[] eODBalances;
		public cls_top5FundsReceived[] top5FundsReceived;
		public cls_top10PaymentsReceivedMonthwise[] top10PaymentsReceivedMonthwise;
		public cls_samePartyXns[] samePartyXns;
		public cls_top5FundsTransferred[] top5FundsTransferred;
		public cls_top10PaymentsmadeMonthwise[] top10PaymentsmadeMonthwise;
	}
	public class cls_loanTrackDetails {
		public Decimal amount;	//22956
		public String category;	//Auto Loan
		public String dates;	//21-Dec-21 21-Jan-22 22-Feb-22 22-Mar-22 21-Apr-22 21-May-22 21-Jun-22 21-Jul-22 22-Aug-22 21-Sep-22 
	}
	public class cls_summaryInfo {
		public String instName;	//Punjab National Bank, India
		public String accNo;	//2938008700003039
		public String accType;	//
		public Decimal fullMonthCount;	//13
		public cls_total total;
		public cls_average average;
	}
	public class cls_total {
		public Double avgNegEOD;	//-655954558.29
		public Double bal15;	//-645679221.63
		public Double bal20;	//-656266794.4
		public Double bal25;	//-656185212.25
		public Double bal30;	//-659963856.05
		public Double bal5;	//-662883115.97
		public Double balAvg;	//-655954558.29
		public Double balMax;	//-629558016.28
		public Double balMin;	//-672151487.48
		public Decimal cashDeposits;	//11
		public Decimal cashWithdrawals;	//0
		public Decimal chqDeposits;	//24
		public Decimal chqIssues;	//71
		public Decimal credits;	//716
		public Decimal creditsSC;	//0
		public Decimal creditsSelf;	//0
		public Decimal debits;	//2612
		public Decimal debitsSC;	//0
		public Decimal debitsSelf;	//13
		public Decimal dpLimit;	//0
		public Decimal intPayDelay;	//32
		public Decimal invExpenses;	//32
		public Decimal invIncomes;	//0
		public Decimal inwBounces;	//2
		public Decimal inwChqBounces;	//0
		public Decimal inwECSBounces;	//0
		public Decimal loanDisbursals;	//37
		public Decimal outwBounces;	//0
		public Decimal outwChqBounces;	//0
		public Decimal overdrawnDays;	//0
		public Decimal overdrawnInstances;	//0
		public Decimal penalCharges;	//0
		public Decimal samePartyAmountCreditDebits;	//4
		public Decimal snLimit;	//0
		public Decimal totalCashDeposit;	//2490000
		public Decimal totalCashWithdrawal;	//0
		public Double totalChqDeposit;	//1327275.16
		public Decimal totalChqIssue;	//6259466
		public Double totalCredit;	//222039082.39
		public Decimal totalCreditSC;	//0
		public Decimal totalCreditSelf;	//0
		public Double totalDebit;	//220102774.46
		public Decimal totalDebitSC;	//0
		public Decimal totalDebitSelf;	//1183635
		public Double totalEmiEcsLoanIssue;	//3607374.38
		public Decimal totalInterestCharged;	//5970417
		public Double totalInvExpense;	//2350034.44
		public Decimal totalInvIncome;	//0
		public Decimal totalInwBounce;	//32550
		public Decimal totalInwChqBounce;	//0
		public Decimal totalInwECSBounce;	//0
		public Decimal totalInwEMIBounce;	//0
		public Double totalLoanDisbursal;	//79052051.93
		public Decimal totalOutwBounce;	//0
		public Decimal totalOutwChqBounce;	//0
		public Decimal totalSamePartyAmountCreditDebit;	//1208937
		public Double totalTransferFrom;	//134370492.87
		public Double totalTransferTo;	//180233120.56
		public Decimal xnsCount;	//3345
	}
	public class cls_average {
		public Double avgNegEOD;	//-50458042.95
		public Double bal15;	//-49667632.43
		public Double bal20;	//-50482061.11
		public Double bal25;	//-50475785.56
		public Double bal30;	//-50766450.47
		public Double bal5;	//-50991008.92
		public Double balAvg;	//-50458042.95
		public Double balMax;	//-48427539.71
		public Double balMin;	//-51703960.58
		public Decimal cashDeposits;	//1
		public Decimal cashWithdrawals;	//0
		public Decimal chqDeposits;	//2
		public Decimal chqIssues;	//5
		public Decimal credits;	//55
		public Decimal creditsSC;	//0
		public Decimal creditsSelf;	//0
		public Decimal debits;	//201
		public Decimal debitsSC;	//0
		public Decimal debitsSelf;	//1
		public Decimal dpLimit;	//0
		public Decimal intPayDelay;	//2
		public Decimal invExpenses;	//2
		public Decimal invIncomes;	//0
		public Decimal inwBounces;	//0
		public Decimal inwChqBounces;	//0
		public Decimal inwECSBounces;	//0
		public Decimal loanDisbursals;	//3
		public Decimal outwBounces;	//0
		public Decimal outwChqBounces;	//0
		public Decimal overdrawnDays;	//0
		public Decimal overdrawnInstances;	//0
		public Decimal penalCharges;	//0
		public Decimal samePartyAmountCreditDebits;	//0
		public Decimal snLimit;	//0
		public Double totalCashDeposit;	//191538.46
		public Decimal totalCashWithdrawal;	//0
		public Double totalChqDeposit;	//102098.09
		public Double totalChqIssue;	//481497.38
		public Double totalCredit;	//17079929.41
		public Decimal totalCreditSC;	//0
		public Decimal totalCreditSelf;	//0
		public Double totalDebit;	//16930982.65
		public Decimal totalDebitSC;	//0
		public Double totalDebitSelf;	//91048.85
		public Double totalEmiEcsLoanIssue;	//277490.34
		public Double totalInterestCharged;	//459262.85
		public Double totalInvExpense;	//180771.88
		public Decimal totalInvIncome;	//0
		public Double totalInwBounce;	//2503.85
		public Decimal totalInwChqBounce;	//0
		public Decimal totalInwECSBounce;	//0
		public Decimal totalInwEMIBounce;	//0
		public Double totalLoanDisbursal;	//6080927.07
		public Decimal totalOutwBounce;	//0
		public Decimal totalOutwChqBounce;	//0
		public Double totalSamePartyAmountCreditDebit;	//92995.15
		public Double totalTransferFrom;	//10336191.76
		public Double totalTransferTo;	//13864086.2
		public Decimal xnsCount;	//257
	}
	public class cls_monthlyDetails {
		public Double avgNegEOD;	//-51656188.68
		public Double bal15;	//-51716183.73
		public Double bal20;	//-51716183.73
		public Double bal25;	//-51758203.73
		public Double bal30;	//-51538980.79
		public Double bal5;	//-51716183.73
		public Double balAvg;	//-51656188.68
		public Double balMax;	//-50018733.63
		public Double balMin;	//-51758203.73
		public Decimal cashDeposits;	//0
		public Decimal cashWithdrawals;	//0
		public Decimal chqDeposits;	//0
		public Decimal chqIssues;	//0
		public Decimal credits;	//11
		public Decimal creditsSC;	//0
		public Decimal creditsSelf;	//0
		public Decimal debits;	//16
		public Decimal debitsSC;	//0
		public Decimal debitsSelf;	//0
		public Decimal dpLimit;	//0
		public Decimal intPayDelay;	//2
		public Decimal invExpenses;	//0
		public Decimal invIncomes;	//0
		public Decimal inwBounces;	//0
		public Decimal inwChqBounces;	//0
		public Decimal inwECSBounces;	//0
		public Decimal loanDisbursals;	//1
		public String monthName;	//Sep-21
		public Decimal outwBounces;	//0
		public Decimal outwChqBounces;	//0
		public Decimal overdrawnDays;	//0
		public Decimal overdrawnInstances;	//0
		public Decimal penalCharges;	//0
		public Decimal samePartyAmountCreditDebits;	//0
		public Decimal snLimit;	//0
		public String startDate;	//2021-09-01
		public Decimal totalCashDeposit;	//0
		public Decimal totalCashWithdrawal;	//0
		public Decimal totalChqDeposit;	//0
		public Decimal totalChqIssue;	//0
		public Double totalCredit;	//2060279.24
		public Decimal totalCreditSC;	//0
		public Decimal totalCreditSelf;	//0
		public Double totalDebit;	//1883076.3
		public Decimal totalDebitSC;	//0
		public Decimal totalDebitSelf;	//0
		public Decimal totalEmiEcsLoanIssue;	//0
		public Decimal totalInterestCharged;	//492981
		public Decimal totalInvExpense;	//0
		public Decimal totalInvIncome;	//0
		public Decimal totalInwBounce;	//0
		public Decimal totalInwChqBounce;	//0
		public Decimal totalInwECSBounce;	//0
		public Decimal totalInwEMIBounce;	//0
		public Double totalLoanDisbursal;	//1646.4
		public Decimal totalOutwBounce;	//0
		public Decimal totalOutwChqBounce;	//0
		public Decimal totalSamePartyAmountCreditDebit;	//0
		public Double totalTransferFrom;	//2058632.84
		public Double totalTransferTo;	//1390095.3
		public Decimal xnsCount;	//27
	}
	public class cls_eODBalances {
		public String dateValVal;	//2021-09-01
		public Double balance;	//-51716183.73
	}
	public class cls_top5FundsReceived {
		public String month;	//Sep-21
		public String category;	//Transfer from SAM EDEUTZFAHRINDIA PVT
		public Double amount;	//837188.35
	}
	public class cls_top10PaymentsReceivedMonthwise {
		public String month;	//Sep-21
		public String party;	//SAMEDEUTZFAHRINDIAPV
		public Double amount;	//837188.35
	}
	public class cls_samePartyXns {
		public String month;	//Dec-21
		public String category;	//COOPERAUTOMOTIVESLTD
		public Decimal amount;	//200000
		public String type;	//Cr
	}
	public class cls_top5FundsTransferred {
		public String month;	//Sep-21
		public String category;	//Transfer to FINE METALS
		public Double amount;	//638659.44
	}
	public class cls_top10PaymentsmadeMonthwise {
		public String month;	//Sep-21
		public String party;	//FINEMETALS
		public Double amount;	//638659.44
	}
	public class cls_combinedAccountXns {
		public Decimal slNo;	//1
		public String dateVal;	//2021-09-25
		public String chqNo;	//
		public String narration;	//NEFT_OUT:PUNBH21268776781/GULATI ENTERPRISE/HDFC 0001955/50200059282451
		public Decimal amount;	//-42020
		public String category;	//Transfer to GULATI ENTERPRISE
		public Double balance;	//-51758203.73
		public String bank;	//Punjab National Bank, India
		public String accNo;	//2938008700003039
	}
	public class cls_combinedMonthlyDetails {
		public String monthName;	//Sep-21
		public String startDate;	//2021-09-01
	}
	public class cls_combinedBouncedOrPenalXns {
		public Decimal slNo;	//1
		public String dateVal;	//2021-10-29
		public String chqNo;	//
		public String narration;	//NEFT_IN:Rej For: N302211692326880/0036/-RETURN-PUNBH21302319507 -SUMAN ELECTRICAL
		public Decimal amount;	//29450
		public String category;	//Bounced I/W Payment
		public Double balance;	//-49766003.36
		public String bank;	//Punjab National Bank, India
		public String accNo;	//2938008700003039
	}
	public class cls_combinedTransferFromToIGXns {
		public Decimal slNo;	//1
		public String dateVal;	//2021-11-02
		public String chqNo;	//
		public String narration;	//2938008700003039 to 293800IL00000100
		public Decimal amount;	//-63890
		public String category;	//Transfer to Self
		public Double balance;	//-49258286.57
		public String bank;	//Punjab National Bank, India
		public String accNo;	//2938008700003039
	}
	public class cls_combinedLoanDisbursalXns {
		public Decimal slNo;	//1
		public String dateVal;	//2021-09-27
		public String chqNo;	//
		public String narration;	//NEFT_IN:N270211650347059/0035/ MAHINDRA AND MAHINDRA FIN S L 3576
		public Double amount;	//1646.4
		public String category;	//Loan Disbursed
		public Double balance;	//-51731777.33
		public String bank;	//Punjab National Bank, India
		public String accNo;	//2938008700003039
	}
	public class cls_combinedHighValueDebitXns {
		public Decimal slNo;	//1
		public String dateVal;	//2021-09-30
		public String chqNo;	//
		public String narration;	//NEFT_OUT:PUNBH21273874272/FINE METALS /HDFC0000673/50200057156210
		public Double amount;	//138659.44
		public String category;	//Transfer to FINE METALS
		public Double balance;	//-50157393.07
		public String bank;	//Punjab National Bank, India
		public String accNo;	//2938008700003039
	}
	public class cls_combinedRegularCreditXns {
		public Decimal groupNo;	//1
		public Decimal slNo;	//1
		public String dateVal;	//2021-09-30
		public String chqNo;	//
		public String narration;	//NEFT_IN:N273211655018251/0033/ TAFE MOTORS AND TRAC
		public Double amount;	//149882.14
		public String category;	//Transfer from TAFE MOTORS AND TRAC
		public Double balance;	//-51031125.99
		public String bank;	//Punjab National Bank, India
		public String accNo;	//2938008700003039
	}
	public class cls_combinedRegularDebitXns {
		public Decimal groupNo;	//1
		public Decimal slNo;	//1
		public String dateVal;	//2022-02-08
		public String chqNo;	//
		public String narration;	//NEFT_OUT:PUNBH22039683734/Trice Enterprises/UBIN0539899/398901010007098
		public Decimal amount;	//-11448
		public String category;	//Transfer to Trice Enterprises
		public Double balance;	//-51781575.5
		public String bank;	//Punjab National Bank, India
		public String accNo;	//2938008700003039
	}
	public class cls_accountXns {
		public String accountNo;	//2938008700003039
		public String accountType;	//
		public cls_xns[] xns;
	}
    public class cls_xns {
		public String dateVal;	//2021-09-25
		public String chqNo;	//
		public String narration;	//NEFT_OUT:PUNBH21268776781/GULATI ENTERPRISE/HDFC 0001955/50200059282451
		public Decimal amount;	//-42020
		public String category;	//Transfer to GULATI ENTERPRISE
		public Double balance;	//-51758203.73
	}
	public class cls_customUserInfo {
		public String employmentType;	//SelfEmployed
		public String employerName;	//
	}
	public class cls_AdditionalSummaryDetails {
		public String accNo;	//2938008700003039
		public Decimal limitVal;	//0
		public String latestUtilizationOn;	//Sep-22
		public Double totalAmountBal5Bal15Bal20Bal25Bal30;	//-3280978200.3
		public Double averageAmountBal5Bal15Bal20Bal25Bal30;	//-50476587.7
		public Decimal totalNumberOfInwardAndOutwardBounces;	//2
		public Double averageNumberOfInwardAndOutwardBounces;	//0.15
		public Double averageAmountBal5Bal15Bal25Bal30;	//-50475219.34
		public Double emiTotalAmount;	//1150811.38
	}
	public class cls_AdditionalMonthlyDetails {
		public cls_MonthlyData1[] MonthlyData1;
		public cls_MonthlyData1[] MonthlyData2;
		public cls_MonthlyData1[] MonthlyData3;
		public cls_MonthlyData1[] MonthlyData4;
		public cls_MonthlyData1[] MonthlyData5;
	}
	public class cls_MonthlyData1 {
		public String monthName;	//Sep-21
		public Decimal credits;	//11
		public Double totalCredit;	//2060279.24
		public Decimal debits;	//16
		public Double totalDebit;	//1883076.3
		public Decimal numberOfSelfAndRelatedPartyCreditTxns;	//0
		public Decimal totalOfSelfAndRelatedPartyCreditTxns;	//0
		public Decimal numberOfBusinessCreditTxns;	//10
		public Double totalBusinessCreditTxns;	//2058632.84
		public Decimal numberOfSelfAndRelatedPartyDebitTxns;	//0
		public Decimal totalOfSelfAndRelatedPartyDebitTxns;	//0
		public Decimal numberOfBusinessDebitTxns;	//16
		public Double totalBusinessDebitTxns;	//1883076.3
		public Decimal cashDepositToTotalCreditPercent;	//0
		public Decimal cashWithdrawalToTotalDebitPercent;	//0
		public Decimal totalNumberOfInwardReturnsToTotalDebitPercent;	//0
		public Decimal totalAmountOfInwardReturnsToTotalDebitPercent;	//0
		public Decimal totalNumberOfOutwardReturnsToTotalCreditPercent;	//0
		public Decimal totalAmountOfOutwardReturnsToTotalCreditPercent;	//0
		public Decimal averageLimitUtilization;	//0
		public Decimal utilizationBalance;	//0
		public Double aBBBal5Bal15Bal25Bal30;	//-51682387.99
		public Double top10CreditorsToTotalCreditorsAmountPrcent;	//99.36
		public Decimal top10DebitorsToTotalDebitorsAmountPrcent;	//100
	}
	public class cls_lan {
	}
	public class cls_uploadedFile {
	}
}