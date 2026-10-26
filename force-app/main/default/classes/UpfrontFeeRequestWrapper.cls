public class UpfrontFeeRequestWrapper {
    public String finReference;
    public String externalReference;
    public Decimal amount;
    public String finType;
    public String paymentMode;
    public String subReceiptMode;
    public String reqType;
    public String toBranch;
    public String fromBranch;
    public String customerName;
    public String customerAddress1;
    public String customerAddress2;
    public String customerAddress3;
    public String customerToState;
    public String finBranch;
    public Boolean stpProcess;
    public String processStage;
    public Datetime realizationDate;
    public String loanCurrency;
    public String gstNumber;
    public ReceiptDetail receiptDetail;
    public List<FeeDetail> fees;
    
    
    public class ReceiptDetail {
        public Decimal fundingAccount;
        public String transactionRef;
        public datetime receivedDate;
        public String paymentRef;
        public String remarks;
        public String favourName;
        public String favourNumber;
        public String bankCode;
        public datetime depositDate;
    }
    
    
    
    public class FeeDetail {
        public String feeCode;
        public Decimal waivedAmount;
        public Decimal feeAmount;
        public String totPaid;
        public Decimal paidAmount;
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}