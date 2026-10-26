public with sharing class CIBILResponseWrapper {

    @AuraEnabled
    public static CIBILResponse getDeserializedResponse(String response) {
        System.debug('CIBIL response: ' + response);
        try {
            CIBILResponse responseJSON = (CIBILResponse) JSON.deserialize(response, CIBILResponse.class);
            return responseJSON;
        } catch (Exception e) {
            throw new AuraHandledException('Error deserializing response: ' + e.getMessage());
        }
    }

    public class CIBILResponse {
        public Integer leadcibilid;
        public Integer applicationkey;
        public Integer leadid;
        public Integer coapplicantid;
        public Integer hlorlaploanamount;
        public Integer creditcardoutstanding;
        public Integer autoloanamount;
        public Integer twowheelerloanamount;
        public Integer blloanamount;
        public Integer plloanamount;
        public Integer ccoverdueAmount;
        public Integer secccoverdueAmount;
        public Integer eduloanamount;
        public Integer consumerloanamount;
        public Integer commvehicleloaamount;
        public Integer usedcarloanamount;
        public Integer seccreditcardoutstanding;
        public Integer loanoncreditcard;
        public Integer creditcardoutstandingemi;
        public Integer hlorlaploanamountemi;
        public Integer autoloanamountemi;
        public Integer twowheelerloanamountemi;
        public Integer blloanamountemi;
        public Integer plloanamountemi;
        public Integer eduloanamountemi;
        public Integer consumerloanamountemi;
        public Integer commvehicleloaamountemi;
        public Integer usedcarloanamountemi;
        public Integer seccreditcardoutstandingemi;
        public Integer loanoncreditcardemi;
        public String cibilapplicationid;
        public String cibildocumentid;
        public String cibildocumentbase64;
        public String cibilpdfdocumentbase64;
        public Integer noofaccountsin30dpdinl12m;
        public Integer noofaccountsin60dpdinl12m;
        public Integer cibilscore;
        public CIBILHeader cibilresponse;
    }

    public class CIBILHeader {
        public String EnquiryControlNumber;
        public String ApplicationReferenceNumber;
        public String Version;
        public String TimeProcessed;
        public String DateProcessed;
        public String SegmentTag;
        public String SubjectReturnCode;
        public String EnquiryMemberUserID;
    }

    public class PrimaryApplicant {
        public String ConsumerNameField1;
        public String ScoreDate;
        public String DateofBirth;
        public String Score;
        public String OccupationCode;
        public List<IDDetails> ID;
        public List<AddressSegment> AddressSegment;
    }

    public class IDDetails {
        public String IDType;
        public String IDNo;
        public String IDNumber;
    }

    public class AddressSegment {
        public String AddressLine1;
        public String AddressLine2;
        public String AddressLine3;
        public String PinCode;
        public String DateReported;
        public String StateCode;
    }

    public class AccountSegment {
        public String AccountType;
        public String AccountStatus;
        public String HighCreditORSanctionedAmount;
        public String CurrentBalance;
        public String CreditAmuntOverdue;
        public String DateOpenedORDisbursed;
        public String PaymentHistory1;
    }
}