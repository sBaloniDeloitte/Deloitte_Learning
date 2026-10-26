public with sharing class DisbursmentMemoHandler {
    private Id recordId;
    public String loanNumber{get;set;}
    public String branch{get;set;}
    public String product{get;set;}
    public date businessdate{get;set;}
    public String customername{get;set;}
    public Decimal loanAmount{get;set;}
    public List<Loan_Transaction__c> loanpayment{get;set;}
    public List<Charges_Insurance__c> Insurence{get;set;}
    public List<Application_Applicant__c> coapps{get;set;}
    public String coappname{get;set;}
    public String address{get;set;}
    public date applicationdate{get;set;}
    public String city{get;set;}
    public string zip{get;set;}
    public decimal fixrate{get;set;}
    public String state{get;set;}
    public String country{get;set;}
    public decimal floatrate{get;set;}
    public string email{get;set;}
    public date floatratedate{get;set;}
    public date interestdate{get;set;}
    public decimal loanterms{get;set;}
    public Boolean moratorium{get;set;}
    public decimal installmentamount{get;set;}
    public decimal installmentamountschedule{get;set;}
    public string paymentfrequency{get;set;}
    public decimal moratoriumterms{get;set;}
    public date firstduedate{get;set;}
    public decimal totalterms{get;set;}
    public decimal firstdisbursementamount{get;set;}
    public string inttype {get;set;}
    public decimal bpi {get;set;}
    public string lan1{get;set;}
    public string lan2{get;set;}
    public decimal finalamount{get;set;}
    public List<RepaymentScheduleWrapper.schedule> repaymentSchedules { get; set; }



    public DisbursmentMemoHandler() {
        try {
            this.recordId = ApexPages.currentPage().getParameters().get('Id');
            System.debug('this.recordId -->'+this.recordId);
            opportunity loan = [SELECT Id, Loan_Application_Number__c,Branch_Master__r.Branch_Code__c,Sub_Product__c,Product__c,Final_Rate_Of_Interest__c,CreatedDate,Final_Amount__c,Final_Tenure__c,Sanction_Tenure__c,Sanction_EMI__c,EMI_Amount_Repayment_Schedule__c  FROM Opportunity where id =: recordId ];
            Loan_Transaction__c loanTransactions = [
            SELECT Id, Disbursement_Amount__c, Allow_Payment_in_Grace_Period__c, Schedule_Method__c, 
                   BPI_Treatment__c, Allow_Grace__c, TDS_Applicable__c, Step_Loan__c, 
                   Grace_Period_Frequency__c, Interest_Frequency__c, Allow_BPI__c, 
                   Allow_Planned_EMI_Holiday__c, Allow_Planned_EMI_holiday_in_Grace__c, 
                   Planned_EMI_Holiday_Method__c, 
                   Max_per_Year__c, Max__c, Lock_Period_Months__c, Capitalize__c, Rate_Type__c,Loan_Start_Date__c,Interest_Due_date__c, First_Disbursement_Amount__c
            FROM Loan_Transaction__c 
            WHERE Loan_Application__c = :recordId
            AND RecordType.DeveloperName = 'Transaction_Details'
            ];
            loanpayment = [SELECT Id, Payment_Sequence__c,Disbursement_Amount__c, Account_Holder_Name__c,Scheduled_Disbursement_Date__c,Bank__c,Account_Number__c,IFSC__c,Payment_Method__c,Cheque_DD_Number__c,Favoring_Name__c,Disbursement_Type__c,Net_Amount__c
            FROM Loan_Transaction__c 
            WHERE Loan_Application__c = :recordId
            AND RecordType.DeveloperName = 'Payment' ORDER BY Payment_Sequence__c ASC];
            Insurence = [select id , Name , VAS_Code__c, Insurance_Premium__c , Sum_Insured_Customer_Details__c from Charges_Insurance__c where RecordType.DeveloperName = 'Insurance' and Loan_Application__c =: recordId];
            List<Charges_Insurance__c> chargesList = [
                SELECT Id, Name, Final_Amount_INR__c 
                FROM Charges_Insurance__c 
                WHERE RecordType.DeveloperName = 'Charges' 
                AND Name = 'PROCFEE' 
                AND Loan_Application__c = :recordId 
                LIMIT 1
            ];

            if (!chargesList.isEmpty()) {
                this.finalamount = chargesList[0].Final_Amount_INR__c != null ? chargesList[0].Final_Amount_INR__c : 0;
            } else {
                this.finalamount = 0;
            }
            List<Application_Applicant__c> applicantList = [select id , name , Applicant_Type__c ,Customer_Type__c,Email__c  from Application_Applicant__c where Loan_Application__c =: recordId];
            Id primaryApplicantId;
            string applicantType;
            for (Application_Applicant__c app1 : applicantList) {
                if (app1.Applicant_Type__c == 'Primary Applicant') {
                    primaryApplicantId = app1.Id;
                    applicantType = app1.Customer_Type__c;
                    break;
                }
            }
            System.debug('primaryApplicantId '+primaryApplicantId);
            List<Applicant_Address__c> addrList = new List<Applicant_Address__c>();
            System.debug('At 89');
            if (primaryApplicantId != null) {
                System.debug('At 91');
                List<Applicant_Address__c> debugAddr = [
    SELECT Id, Applicant__c, Address_Priority__c, Address_Line_1__c
    FROM Applicant_Address__c
    WHERE Applicant__c = :primaryApplicantId
];
System.debug('All addresses for this applicant: ' + debugAddr);
                addrList = [
                    SELECT Id, Full_Address1__c, City__c, State__c, Pincode__r.Name, Pincode__r.Country__c
                    FROM Applicant_Address__c
                    WHERE Applicant__c = :primaryApplicantId
                    AND Address_Priority__c = '5'
                    AND Address_Line_1__c != null
                ];
                System.debug('At 98'+addrList);
            }
            if (!addrList.isEmpty()) {
                this.address = addrList[0].Full_Address1__c;
                this.city = addrList[0].City__c;
                this.state = addrList[0].State__c;
                this.country = addrList[0].Pincode__r.Country__c;
                this.zip = addrList[0].Pincode__r.name;
            }
            
            
            this.loanNumber=loan.Loan_Application_Number__c;
            this.branch=loan.Branch_Master__r.Branch_Code__c;
            String subProd = loan.Sub_Product__c != null ? loan.Sub_Product__c.trim().toLowerCase() : '';
            if (subProd == 'Over Draft' || subProd == 'Flexi Funds') {
                this.product = loan.Product__c + ' ' + loan.Sub_Product__c;
            } else {
                this.product = loan.Product__c;
            }
            this.businessdate = loanTransactions.Loan_Start_Date__c;
            this.loanAmount = loan.Final_Amount__c;
            this.applicationdate = Date.valueOf(loan.createdDate);
            this.fixrate = loan.Final_Rate_Of_Interest__c;
            this.floatratedate = loanTransactions.Loan_Start_Date__c;
            this.loanterms = loan.Final_Tenure__c!= null?loan.Final_Tenure__c:0 ;
            this.interestdate = loanTransactions.Loan_Start_Date__c;
            this.moratorium = loanTransactions.Allow_Grace__c;
            this.installmentamount = loan.Sanction_EMI__c;
            String instalmentFrequency = 'Monthly';
            if (loanTransactions.Interest_Frequency__c == 'M') {
                this.paymentfrequency = 'Monthly';
            } else if (loanTransactions.Interest_Frequency__c == 'Y') {
                this.paymentfrequency = 'Yearly';
            } else if (loanTransactions.Interest_Frequency__c == 'Q') {
                this.paymentfrequency = 'Quarterly';
            } else if (loanTransactions.Interest_Frequency__c == 'H') {
                this.paymentfrequency = 'Half Yearly';
            }
            this.moratoriumterms = loanTransactions.Grace_Period_Frequency__c;
            // this.firstduedate = loanTransactions.Interest_Due_date__c;
            this.firstdisbursementamount = loanTransactions.First_Disbursement_Amount__c;
            this.inttype = loanTransactions.Rate_Type__c;
            this.totalterms = loan.Final_Tenure__c!= null?loan.Final_Tenure__c:0 ;
            // this.coappname = '';
            for (Application_Applicant__c app : applicantList) {
                if (app.Applicant_Type__c == 'Primary Applicant') {
                    this.customername = app.name;
                    this.email = app.Email__c != null ? app.Email__c : 'NA';
                } else if (app.Applicant_Type__c == 'Co Applicant') {
                    if (this.coappname == null) {
                        this.coappname = app.name;
                    } else {
                        this.coappname += ', ' + app.name;
                    }
                }
            }
            // repaymentSchedules = RepaymentScheduleController.fetchSchedule(recordId);
            // if (repaymentSchedules != null && !repaymentSchedules.isEmpty()) {
            //     system.debug('Check the data'+repaymentSchedules);
            //     for(RepaymentScheduleWrapper.schedule schedule : repaymentSchedules)
            //     {
            //         if(schedule.instNumber == 1)
            //         this.firstduedate = Date.valueOf(schedule.dueDate);
            //         if(schedule.bpiAmount != 0)
            //         this.bpi = schedule.bpiAmount;
            //     }
            // }
            this.installmentamountschedule = loan.EMI_Amount_Repayment_Schedule__c;
        }
        catch(Exception exp){

        }
    }
}