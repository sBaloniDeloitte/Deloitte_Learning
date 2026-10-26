public class RepaymentScheduleWrapper {
    public String finReference { get; set; }
    public List<Fee> fees { get; set; }
    public List<Object> feeDues { get; set; }
    public List<Object> insurance { get; set; }
    public List<Step> step { get; set; }
    public List<Schedule> schedules { get; set; }
    public List<Object> planEMIHmonths { get; set; }
    public List<Object> planEMIHDates { get; set; }
    public List<Object> planPRIHDates { get; set; }
    public List<Object> planPRIHMonths { get; set; }
    public List<Object> overdueCharges { get; set; }
    public Summary summary { get; set; }
    public List<Object> vas { get; set; }
    public Decimal outstandingPri { get; set; }
    public ReturnStatus returnStatus { get; set; }
    public Boolean isUpfrontAuto { get; set; }
    public Decimal excessAmount { get; set; }
    public List<Object> intervalFee { get; set; }
    public List<Object> disbursements { get; set; }
    public Integer version { get; set; }

    public class Fee {
        public String feeCategory { get; set; }
        public String feeCode { get; set; }
        public Decimal feeAmount { get; set; }
        public Decimal waiverAmount { get; set; }
        public Decimal paidAmount { get; set; }
        public String feeMethod { get; set; }
        public Integer scheduleTerms { get; set; }
        public Decimal feeBalance { get; set; }
        public Integer version { get; set; }
        public List<Object> finFeeReceipts { get; set; }
    }

    public class Schedule {
        @AuraEnabled public String schDate { get; set; }
        @AuraEnabled public Decimal pftAmount { get; set; }
        @AuraEnabled public Decimal schdPft { get; set; }
        @AuraEnabled public Decimal profitBalance { get; set; }
        @AuraEnabled public Decimal schdPftPaid { get; set; }
        @AuraEnabled public Decimal schdPri { get; set; }
        @AuraEnabled public Decimal schdPriPaid { get; set; }
        @AuraEnabled public Decimal feeSchd { get; set; }
        @AuraEnabled public Decimal tDSAmount { get; set; }
        @AuraEnabled public Decimal totalAmount { get; set; }
        @AuraEnabled public Decimal endBal { get; set; }
        @AuraEnabled public Decimal limitDrop { get; set; }
        @AuraEnabled public Decimal dropLineLimit { get; set; }
        @AuraEnabled public Decimal availableLimit { get; set; }
        @AuraEnabled public String dueDate { get; set; }
        @AuraEnabled public Integer version { get; set; }
        @AuraEnabled public Integer instNumber { get; set; }
        @AuraEnabled public Decimal bpiAmount { get; set; }
        @AuraEnabled public String specifier {get;set;}
    }

    public class Summary {
        @AuraEnabled public Decimal effectiveRateOfReturn { get; set; }
        @AuraEnabled public Decimal totalGracePft { get; set; }
        @AuraEnabled public Decimal totalGraceCpz { get; set; }
        @AuraEnabled public Decimal totalGrossGrcPft { get; set; }
        @AuraEnabled public Decimal totalCpz { get; set; }
        @AuraEnabled public Decimal totalProfit { get; set; }
        @AuraEnabled public Decimal totalRepayAmt { get; set; }
        @AuraEnabled public Decimal feeChargeAmount { get; set; }
        @AuraEnabled public Integer numberOfTerms { get; set; }
        @AuraEnabled public Integer loanTenor { get; set; }
        @AuraEnabled public String maturityDate { get; set; }
        @AuraEnabled public Decimal firstEmiAmount { get; set; }
        @AuraEnabled public String nextSchDate { get; set; }
        @AuraEnabled public Decimal nextRepayAmount { get; set; }
        @AuraEnabled public Integer futureInst { get; set; }
        @AuraEnabled public Integer futureTenor { get; set; }
        @AuraEnabled public String firstInstDate { get; set; }
        @AuraEnabled public Decimal paidTotal { get; set; }
        @AuraEnabled public Decimal paidPri { get; set; }
        @AuraEnabled public Decimal paidPft { get; set; }
        @AuraEnabled public String lastRepayDate { get; set; }
        @AuraEnabled public Decimal outstandingTotal { get; set; }
        @AuraEnabled public Decimal outstandingPri { get; set; }
        @AuraEnabled public Decimal outstandingPft { get; set; }
        @AuraEnabled public Decimal overdueTotal { get; set; }
        @AuraEnabled public Decimal overduePri { get; set; }
        @AuraEnabled public Decimal overduePft { get; set; }
        @AuraEnabled public Integer overdueInst { get; set; }
        @AuraEnabled public Decimal overDueCharges1 { get; set; }
        @AuraEnabled public Decimal overdueTotalIncludeCharges { get; set; }
        @AuraEnabled public List<Object> overdueCharges { get; set; }
        @AuraEnabled public Decimal advPaymentAmount { get; set; }
        @AuraEnabled public String finActiveStatus { get; set; }
        @AuraEnabled public Boolean fullyDisb { get; set; }
        @AuraEnabled public Decimal limitBalance { get; set; }
        @AuraEnabled public Decimal billedAmount { get; set; }
        @AuraEnabled public Decimal unbilledAmount { get; set; }
        @AuraEnabled public Integer DPDDays { get; set; }
        @AuraEnabled public String dueDate { get; set; }
        @AuraEnabled public Decimal dueAmount { get; set; }
        @AuraEnabled public Decimal limitDrop { get; set; }
        @AuraEnabled public Decimal currentDroplineLimit { get; set; }
        @AuraEnabled public Decimal utilisation { get; set; }
        @AuraEnabled public Decimal availableLimit { get; set; }
        @AuraEnabled public Integer graceInst { get; set; }
        @AuraEnabled public Integer graceTenor { get; set; }
        @AuraEnabled public Integer futureGraceInst { get; set; }
        @AuraEnabled public Integer futureGraceTenor { get; set; }
        @AuraEnabled public Integer totalRevisedTenure { get; set; }
        @AuraEnabled public Integer revisedLastStepTerms { get; set; }
    }

    public class ReturnStatus {
        public String returnCode { get; set; }
        public String returnText { get; set; }
    }

    public class Step {
        public Integer stepNumber { get; set; }
        public Decimal tenorSplitPerc { get; set; }
        public Decimal emiSplitPerc { get; set; }
        public Integer installments { get; set; }
        public Decimal steppedEMI { get; set; }
        public String stepSpecifier { get; set; }
        public Boolean autoCal { get; set; }
        public Integer version { get; set; }
    }
}