public class UpfrontFeeResponseWrapper {
    public String finReference;
    public Boolean stp;
    public String finType;
    public String customerName;
    public String customerToState;
    public String finBranch;
    public String postBranch;
    public ReturnStatus returnStatus;
    public Integer version;
    public Integer receiptId;
    public Boolean disbStp;
    public Integer maxPPAmount;
    public Integer maxPPPercentage;
    public Boolean createPLMGroup;
    public Boolean existingGroup;
    public List<FinReceiptHeader> finReceiptHeaders;

    public class ReturnStatus {
        public String returnCode;
        public String returnText;
    }

    public class FinReceiptHeader {
        public Integer receiptID;
        public String receiptMode;
        public String subReceiptMode;
        public Decimal receiptAmount;
        public String receiptModeStatus;
        public String remarks;
        public Integer version;
        public String reference;
        public String finType;
        public String extReference;
        public Decimal excessAmount;
        public Boolean stp;
        public List<FeeReceiptDetail> FeeReceiptDetails;
        public List<FeeDetail> feeDetails;
        public List<Object> documents; // Assuming documents is a list but empty here, you can define this class if structure is known
    }

    public class FeeReceiptDetail {
        public Integer version;
        public Integer receiptID;
        public Integer receiptSeqID;
        public String favourNumber;
        public String valueDate;
        public String favourName;
        public String depositDate;
        public String paymentRef;
        public String transactionRef;
        public String chequeAcNo;
        public String receivedDate;
        public Integer fundingAccount;
    }

    public class FeeDetail {
        public String feeCode;
        public Decimal netAmountOriginal;
        public Decimal netAmountGST;
        public Decimal netAmount;
        public Decimal paidAmountOriginal;
        public Decimal paidAmountGST;
        public Decimal paidAmount;
        public Decimal feeBalance;
        public Decimal netTDS;
        public Decimal paidTDS;
        public Decimal remTDS;
        public Decimal waiverAmount;
        public String feeMethod;
        public Integer scheduleTerms;
        public Integer version;
        public Decimal refundAmount;
        public Decimal feeAmount;
    }
}