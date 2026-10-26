public class SanctionLetterRequestWrapper {
    public String eventID;
    public String lettertype;
    public String mobile_number;
    public String whatsaap_number;
    public String custctgcode;
    public String email_id;
    public String reference;
    public String salutation;
    public String time_stamp;
    public String typeOfLoan;
    public String step_finance;
    public String cif;
    public String isLRD;
    public String name;
    public String custfirstname;
    public String custlastname;
    public String custaddr1;
    public String custaddr2;
    public String custaddr3;
    public String date_of_disbursal;
    public Long loan_amount;
    public Decimal rate_of_interest;
    public String type_of_interest;
    public String ghplr;
    public Decimal margin;
    public Integer stepup_pre_emi_tenor;
    public String languagePreferred;
    public String bank_name;
    public String acc_number;
    public Long finassetvalue;
    public Integer total_tenor;
    public Integer moratorium_tenor;
    public Integer pemii_tenor;
    public Integer full_emi_tenor;
    public Integer holiday_tenor;
    public String repayment_mode;
    //public String additional_product;
    public String end_use_of_loan;
    public String stepfinance;
    public Integer finisactive;
    public String repaybaserate;
    public String grcpftfrq;
    public String grcpftrvwfrq;
    public String grccpzfrq;
    public Boolean allow_bpi;
    public Boolean alwBpiTreatment;
    public String bpitreatment;
    public Boolean allowgrcrepay;
    public Boolean allow_grcperiod;
    public Integer graceterms;
    public String grcratebasis;
    public Decimal grcmargin;
    public Integer grcminrate;
    public Integer grcmaxrate;
    public Integer grcmaxamount;
    public Integer grcadvpftrate;
    public Integer grcadvmargin;
    public Boolean alwgrcadj;
    public String gracebaserate;
    public String schedulemethod;
    public String profitdaysbasis;
    public String bpipftdaysbasis;
    public Boolean finrepaypftonfrq;
    public String frequency;
    public String instalment_frequency;
    public Integer insurance_charges;
    public Integer other_charges;
    public Decimal apr;
    public Integer processing_fee;
    public String fintype;
    public Integer interestperiod;
    public String sanction_withdrawal_amt;
    public String product_variant;
    public Integer noOfGrcSteps; //added by Arman on 09-01-2026 cause of SFHL-858 jira
    public Integer noOfSteps; //added by Arman on 09-01-2026 cause of SFHL-858 jira
    public Boolean alwManualSteps; //added by Arman on 09-01-2026 cause of SFHL-858 jira
    public Integer feetypeid;
    public Integer processingfee;
    public String custresidentialsts;
    public String finpurpose;
    public Integer allowgrcperiod;
    public String grcschdmthd;
    public String branch_code;
    public String gender;
    public String resident_status;
    public String rm_email_id;
    public String am_email_id;
    public String elasticcrlinetype;
    public String stamping_franking;
    //public String elasticcrlinedropcalon;
    //public boolean elasticcrLine;
    public Integer numberofterms;
    //public Decimal amc_perc;
    public string finStartDate;
    public string subproduct;
    public Integer fixedratetenor;
    public Integer calterms;
    public Integer loan_towards_plot;
    public Integer loan_towards_selfcon;
    public Integer finocrrequired;
    public String subcategory;
    public Boolean offemailverified;
    public String rmname;
    public String amname;
    public String rmid;
    public String amid;
    public List<Step> step; 
    public List<RepaymentPlanData> repaymentPlanData;
    public List<cls_linkedLans> linkedLans;
    public List<cls_coApplicant> coApplicant;
    public List<Object> hlsData;
    public List<cls_sanctionConditions> sanctionConditions;
    public List<Object> repaymentSchedule;
    //public List<Object> amcDetails;
    public List<cls_collateralPropertDetails> collateralPropertyDetails;
    public List<cls_appFormDetails> appFormDetails;
    public List<cls_appFormCoappDetails> appFormCoappDetails;

    // Inner Classes
    public class RepaymentPlanData {
        public Integer step_no;
        public String step_specifier;
        public Integer installments;
        public Decimal stepped_emi;
    }

    public class Step {
        public Integer stepNumber;       
        public Decimal tenorSplitPerc;    
        public Decimal rateMargin;        
        public Decimal emiSplitPerc; 
        public Decimal steppedEMI;  
        public String stepSpecifier;   
        public Decimal autoCal;
        public Decimal installments;
    }

    public class cls_linkedLans {
        public String reference;
    }

    public class cls_coApplicant {
        public String salutation;
        public String name;
        public String cif;
        public String email_address;
        public String whatsaap_number;
        public String sms_number;
    }

    /*public class cls_hlsData {
        public String year;
        public String interest_only_months;
    }*/

    public class cls_sanctionConditions {
        public Integer seqno;
        public String sanctioncondition;
    }

    public class cls_collateralPropertDetails {
        public String unit;
        public String floornumber;
        public String tower;
        public String project_name;
        public String propertyaddress1;
        public String propertyaddress2;
        public String propertyaddress3;
        public String landmark;
        public String city;
        public String state;
        public String pincode;
        public String collateral_id;
        public String unittype;
    }

    public class cls_appFormDetails{
        public String custshrtname;
        public String mothername;
        public String fathername;
        public String custcif;
        public String dateofbirth;
        public String maritalstatus;
        public String countryofbirth;
        public String occupationcategory;
        public String nationality;
        public String gender;
        public String pan;
        public String mobile;
        public String phonenumber;
        public String emailid;
        public String residentialstatus;
        public String address;
        public String catofcoapplicant;
    }

    public class cls_appFormCoappDetails{
        public String custshrtname;
        public String mothername;
        public String fathername;
        public String custcif;
        public String dateofbirth;
        public String maritalstatus;
        public String countryofbirth;
        public String occupationcategory;
        public String nationality;
        public String gender;
        public String pan;
        public String mobile;
        public String phonenumber;
        public String emailid;
        public String residentialstatus;
        public String address;
        public String catofcoapplicant;
    }

    // Deserialize method
    public static SanctionLetterRequestWrapper parse(String json) {
        return (SanctionLetterRequestWrapper) System.JSON.deserialize(json, SanctionLetterRequestWrapper.class);
    }
}