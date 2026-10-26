public class LoanExposureResponseService {
    
 @AuraEnabled
    public static LoanExposureResponseServiceWrapper getDeserailizedResponse(String response) {
        System.debug('response>>'+response);
        try {
            LoanExposureResponseServiceWrapper responseJSON = (LoanExposureResponseServiceWrapper)JSON.deserialize(response, LoanExposureResponseServiceWrapper.class);
            return responseJSON;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class LoanExposureResponseServiceWrapper{
    public ReturnStatus returnStatus;
    public BankingDetails bankingDetails;
    public SummaryExposure summaryExposure;
    public List<ExistingLoan> existingLoans;
    public LinklanDetails linklanDetails;
    }
    
    public class ReturnStatus {
        public String returnCode;
        public String returnText;
        public Boolean valid;
    }

    public class BankingDetails {
        public Decimal totalExposure;
        public Decimal totalExposureGHF_HFC;
        public Decimal totalExposureGFL_NBFC;
        public Decimal totalExposureGC;
    }

    public class SummaryExposure {
        public ExposureGHF exposureGHF;
        public String exposureGFL;
    }

    public class ExposureGHF {
        public String wipLoan;
        public String disburstLoan;
    }

    public class ExistingLoan {
        public String ucic;
        public String lan_no;
        public String full_name;
        public String cif;
        public Decimal original_amount;
        public Decimal installment_amount;
        public Decimal outstanding_amount;
        public String loan_date;
        public String loan_status;
        public String entity;
        public String dpd_string;
        public String dob;
        public String employment_type;
        public String employer_name;
        public String loan_type;
        public String no_of_bounce;
        public String booking_date;
        public Decimal undisbursed_amount;
        public String applicant;
    }

    public class LinklanDetails {
        public Map<String, List<LinkedLoan>> linkedLoans;
    }

    public class LinkedLoan {
        public String groupcode;
        public String groupdesc;
        public String lan;
    }
    
}