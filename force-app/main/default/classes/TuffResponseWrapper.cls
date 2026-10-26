public with sharing class TuffResponseWrapper {
    
    // public class CIBILResponseWrapper {
    //     public Integer leadCibilId;
    //     public Integer applicationKey;
    //     public Integer leadId;
    //     public Integer coApplicantId;
    //     public Decimal hlorLapLoanAmount;
    //     public Decimal creditCardOutstanding;
    //     public Decimal autoLoanAmount;
    //     public Decimal twoWheelerLoanAmount;
    //     public Decimal blLoanAmount;
    //     public Decimal plLoanAmount;
    //     public Decimal ccOverdueAmount;
    //     public Decimal secCcOverdueAmount;
    //     public Decimal eduLoanAmount;
    //     public Decimal consumerLoanAmount;
    //     public Decimal commVehicleLoanAmount;
    //     public Decimal usedCarLoanAmount;
    //     public Decimal secCreditCardOutstanding;
    //     public Decimal loanOnCreditCard;
    //     public Decimal creditCardOutstandingEmi;
    //     public Decimal hlorLapLoanAmountEmi;
    //     public Decimal autoLoanAmountEmi;
    //     public Decimal twoWheelerLoanAmountEmi;
    //     public Decimal blLoanAmountEmi;
    //     public Decimal plLoanAmountEmi;
    //     public Decimal eduLoanAmountEmi;
    //     public Decimal consumerLoanAmountEmi;
    //     public Decimal commVehicleLoanAmountEmi;
    //     public Decimal usedCarLoanAmountEmi;
    //     public Decimal secCreditCardOutstandingEmi;
    //     public Decimal loanOnCreditCardEmi;
    //     public Integer cibilScore;
    //     public String cibilApplicationId;
    //     public String cibilDocumentId;
    //     public String cibilDocumentBase64;
    //     public String cibilPdfDocumentBase64;
    //     public Integer noOfAccountsIn30DpdInL12M;
    //     public Integer noOfAccountsIn60DpdInL12M;
    //     //public String cibilResponse;
    //     public String lastMntOn;
    //     public String pan;
    //     public String mobile;
    //     public String tuffResponse;
    //     public String requestType;
    //     public String requestSource;
    //     public String entity;
    //     public String agency;
    //     public String createdOn;
    //     public Integer isActive;
    //     //public cls_cibilresponse cibilresponse;
    // }

    // public class cls_cibilresponse {
	// 	public cls_cibilHeader cibilHeader;
	// 	public cls_PrimaryApplicant PrimaryApplicant;
	// 	public cls_SecondaryApplicant[] SecondaryApplicant;
	// }
	// public class cls_cibilHeader {
	// 	public String EnquiryControlNumber;	//002160164199
	// 	public String ApplicationReferenceNumber;	//51576375
	// 	public String Version;	//12
	// 	public String TimeProcessed;	//16:47:42
	// 	public String DateProcessed;	//08/07/2024
	// 	public String SegmentTag;	//TUEF
	// 	public String SubjectReturnCode;	//1
	// 	public String EnquiryMemberUserID;	//HF64221001_UATC2CNPE1
	// }
	// public class cls_PrimaryApplicant {
	// 	public String ScoreCardName;	//08
	// 	public String LengthofTransmission;	//0000796
	// 	public String ScoreName;	//CIBILTUSC3
	// 	public cls_AddressSegment[] AddressSegment;
	// 	public String Gender;	//Female
	// 	public String ConsumerNameField1;	//GAYATRI VARMA
	// 	public String ScoreDate;	//08072024
	// 	public String Score;	//000-1
	// 	public cls_EnquirySegment[] EnquirySegment;
	// 	public Integer NoOfUnsecuredBLPLAcc;	//1
	// 	public String DateofBirth;	//19/09/2000
	// 	public cls_ID[] ID;
	// 	public String ScoreCardVersion;	//10
	// }
	// public class cls_AddressSegment {
	// 	public String AddressLine1;	//THANE,MAHARASHTRA,401107
	// 	public String Address;	//1
	// 	public String AddressCategory;	//Residence Address
	// 	public String DateReported;	//20/09/2023
	// 	public String AddressLine5;	//THANE
	// 	public String StateCode;	//27
	// 	public String AddressEnrichedThroughEnquiry;	//Y
	// 	public String ResidenceCode;	//Owned
	// 	public String PinCode;	//401107
	// }
	// class cls_EnquirySegment {
	// 	public String DateofEnquiry;	//02/07/2024
	// 	public String EnquiryPurpose;	//Property Loan
	// 	public String EnquiringMemberShortName;	//GODHOUSE
	// 	public String EnquiryAmount;	//144,000
	// 	public String EnqSno;	//1
	// }
	// class cls_ID {
	// 	public String EnrichedThroughEnquiry;	//Y
	// 	public String IDType;	//Income Tax ID Number (PAN)
	// 	public String IDNo;	//1
	// 	public String IDNumber;	//AAJPG3357P
	// }
	// class cls_SecondaryApplicant {
	// 	public String ScoreCardName;	//08
	// 	public String LengthofTransmission;	//0000796
	// }
    public class TuffResponse{
        public cls_CreditReport CreditReport;
    }
	// class cls_DCResponse {
	// 	public String Status;	//Success
	// 	public cls_Authentication Authentication;
	// 	public cls_ResponseInfo ResponseInfo;
	// 	public cls_ContextData ContextData;
	// }
	// class cls_Authentication {
	// 	public String Status;	//PasswordHasExpired
	// 	public String Token;	//fb804e8e-1ecf-496f-9c96-96618b5764bf
	// }
	// class cls_ResponseInfo {
	// 	public String ApplicationId;	//33456672
	// 	public String SolutionSetInstanceId;	//699a63fa-d5b8-4b2e-8981-6809c18b7d74
	// 	public String CurrentQueue;	//
	// }
	// class cls_ContextData {
	// 	public cls_Field[] Field;
	// }
	// class cls_Field {
	// 	public cls_Applicants Applicants;
	// 	public String NewKey;	//Applicants
	// }
	// class cls_Applicants {
	// 	public cls_Applicant Applicant;
	// }
	// class cls_Applicant {
	// 	public cls_Accounts Accounts;
	// 	public String MemberOtherId1Type;	//
	// 	public String MemberOtherId1;	//
	// 	public String MemberOtherId2Type;	//
	// 	public String MemberOtherId2;	//
	// 	public String MemberOtherId3Type;	//
	// 	public String MemberOtherId3;	//
	// 	public String KeyPersonName;	//
	// 	public String KeyPersonRelation;	//
	// 	public String MemberRelationName1;	//
	// 	public String MemberRelationType1;	//
	// 	public String MemberRelationName2;	//
	// 	public String MemberRelationType2;	//
	// 	public String MemberRelationName3;	//
	// 	public String MemberRelationType3;	//
	// 	public String MemberRelationName4;	//
	// 	public String MemberRelationType4;	//
	// 	public String NomineeName;	//
	// 	public String NomineeRelation;	//
	// 	public cls_Addresses Addresses;
	// 	public cls_Telephones Telephones;
	// 	public cls_Identifiers Identifiers;
	// 	public String CompanyName;	//
	// 	public String EmailAddress;	//
	// 	public String Gender;	//2
	// 	public String DateOfBirth;	//04121995
	// 	public String ApplicantLastName;	//
	// 	public String ApplicantMiddleName;	//
	// 	public String ApplicantFirstName;	//Harshal Patel
	// 	public String ApplicantType;	//Main
	// 	public String NodeIdentifier;	//0
	// 	public cls_DsCibilBureau DsCibilBureau;
	// 	public cls_DsTuVerification DsTuVerification;
	// 	public cls_HRAAttributes HRAAttributes;
	// 	public cls_HRARuleAttributes HRARuleAttributes;
	// 	public String DsAadharEkycOtp;	//
	// }
	// class cls_Accounts {
	// 	public cls_Account Account;
	// }
	// class cls_Account {
	// 	public String Length;	//04
	// 	public String SegmentTag;	//T001
	// 	public cls_Account_Summary_Segment_Fields Account_Summary_Segment_Fields;
	// 	public cls_Account_NonSummary_Segment_Fields Account_NonSummary_Segment_Fields;
	// }
	// class cls_Addresses {
	// 	public cls_Address Address;
	// }
	// class cls_Address {
	// 	public String AddressSegmentTag;	//PA
	// 	public String Length;	//03
	// 	public String SegmentTag;	//A01
	// 	public String AddressLine1FieldLength;	//05
	// 	public String AddressLine1;	//DELHI
	// 	public String AddressLine2FieldLength;	//
	// 	public String AddressLine2;	//
	// 	public String AddressLine3FieldLength;	//
	// 	public String AddressLine3;	//
	// 	public String AddressLine4FieldLength;	//
	// 	public String AddressLine4;	//
	// 	public String AddressLine5FieldLength;	//
	// 	public String AddressLine5;	//
	// 	public String StateCode;	//07
	// 	public String PinCodeFieldLength;	//06
	// 	public String PinCode;	//110020
	// 	public String AddressCategory;	//02
	// 	public String ResidenceCode;	//
	// 	public String DateReported;	//05062020
	// 	public String MemberShortNameFieldLength;	//
	// 	public String MemberShortName;	//
	// 	public String FID;	//
	// 	public String SNo;	//
	// 	public String EnrichedThroughEnquiry;	//Y
	// 	public String SuppressFlag;	//
	// 	public String DateOfSuppression;	//
	// }
	// class cls_Telephones {
	// 	public cls_Telephone[] Telephone;
	// }
	// class cls_Telephone {
	// 	public String TelephoneType;	//01
	// 	public String TelephoneNumber;	//
	// 	public String TelephoneExtension;	//
	// }
	// class cls_Identifiers {
	// 	public cls_Identifier[] Identifier;
	// }
	// class cls_Identifier {
	// 	public String IdType;	//01
	// 	public String IdNumber;	//AEXPH6620Q
	// }
	// public class cls_DsCibilBureau {
	// 	public cls_DsCibilBureauData DsCibilBureauData;
	// 	public cls_DsCibilBureauStatus DsCibilBureauStatus;
	// 	public cls_Response Response;
	// 	public cls_Document Document;
	// }
	// public class cls_DsCibilBureauData {
	// 	public cls_Request Request;
	// }
	// public class cls_Request {
	// 	public cls_Request Request;
	// 	public cls_ConsumerDetails ConsumerDetails;
	// }
	// class cls_ConsumerDetails {
	// 	public cls_CreditReportInquiry CreditReportInquiry;
	// }
	// public class cls_CreditReportInquiry {
	// 	public cls_Header Header;
	// 	public cls_Names Names;
	// 	public cls_Identifications Identifications;
	// 	public String Telephones;	//
	// 	public cls_Addresses Addresses;
	// }
	
	// public class cls_Names {
	// 	public cls_Name Name;
	// }
	// public class cls_Name {
	// 	public String ConsumerName1;	//Harshal Patel
	// 	public String ConsumerName2;	//
	// 	public String ConsumerName3;	//
	// 	public String ConsumerName4;	//
	// 	public String ConsumerName5;	//
	// 	public String DateOfBirth;	//04121995
	// 	public String Gender;	//2
	// }
	// public class cls_Identifications {
	// 	public cls_Identification Identification;
	// }
	// public class cls_Identification {
	// 	public String PanNo;	//AEXPH6620Q
	// 	public String PassportNumber;	//
	// 	public String DLNo;	//
	// 	public String VoterId;	//
	// 	public String UId;	//
	// 	public String RationCardNo;	//
	// 	public String AdditionalID1;	//
	// 	public String AdditionalID2;	//
	// }
	// public class cls_DsCibilBureauStatus {
	// 	public String Trail;	//
	// }
	// public class cls_Response {
	// 	public String IsSuccess;	//False
	// 	public String ErrorCode;	//
	// 	public String ErrorMessage;	//
	// 	public String VerificationResponseXml;	//
	// }
	// public class cls_CibilBureauResponse {
	// 	public String BureauResponseRaw;	
	// 	public cls_BureauResponseXml BureauResponseXml;
	// 	public String SecondaryReportXml;	//
	// 	public String IsSucess;	//True
	// }
	// public class cls_BureauResponseXml {
	// 	public cls_CreditReport CreditReport;
	// }
	public class cls_CreditReport {
		public cls_Header Header;
		// public cls_NameSegment NameSegment;
		// public cls_IDSegment[] IDSegment;
		// public cls_TelephoneSegment[] TelephoneSegment;
		// public cls_EmailContactSegment[] EmailContactSegment;
		// public cls_EmploymentSegment EmploymentSegment;
		public cls_ScoreSegment ScoreSegment;
		// public cls_Address[] Address;
		// public cls_Account[] Account;
		// public cls_Enquiry[] Enquiry;
		// public cls_End Changed;
	}
    public class cls_Header {
		public String SegmentTag;	//TUEF
		public String Version;	//12
		public String ReferenceNumber;	//895377593
		public String FutureUse1;	//
		public String FutureUse2;	//
		public String MemberCode;	//NB76848888_CIRC2CNPE
		public String SubjectReturnCode;	//1
		public String EnquiryControlNumber;	//005620030852
		public String DateProcessed;	//22112024
		public String TimeProcessed;	//131011
	}
	public class cls_NameSegment {
		public String Length;	//03
		public String SegmentTag;	//N01
		public String ConsumerName1FieldLength;	//12
		public String ConsumerName1;	//SHASHI KUMAR
		public String ConsumerName2FieldLength;	//
		public String ConsumerName2;	//
		public String ConsumerName3FieldLength;	//
		public String ConsumerName3;	//
		public String ConsumerName4FieldLength;	//
		public String ConsumerName4;	//
		public String ConsumerName5FieldLength;	//
		public String ConsumerName5;	//
		public String DateOfBirthFieldLength;	//08
		public String DateOfBirth;	//24051964
		public String GenderFieldLength;	//01
		public String Gender;	//2
		public String DateOfEntryForErrorCode;	//
		public String ErrorSegmentTag;	//
		public String ErrorCode;	//
		public String DateOfEntryForCIBILRemarksCode;	//
		public String CIBILRemarksCode;	//
		public String DateOfEntryForErrorDisputeRemarksCode;	//
		public String ErrorDisputeRemarksCode1;	//
		public String ErrorDisputeRemarksCode2;	//
		public String EnrichThroughEnquiryForName;	//
		public String FID;	//
		public String EnrichThroughEnquiryForDateOfBirth;	//
		public String EnrichThroughEnquiryForGender;	//
		public String DateOfSuppression;	//
	}
	public class cls_IDSegment {
		public String Length;	//03
		public String SegmentTag;	//I01
		public String IDType;	//01
		public String IDNumberFieldLength;	//10
		public String IDNumber;	//AEXPH6620Q
		public String IssueDate;	//
		public String ExpirationDate;	//
		public String EnrichedThroughEnquiry;	//
		public String FID;	//
		public String SNo;	//
		public String SuppressFlag;	//
		public String DateOfSuppression;	//
	}
	public class cls_TelephoneSegment {
		public String Length;	//03
		public String SegmentTag;	//T01
		public String TelephoneNumberFieldLength;	//08
		public String TelephoneNumber;	//98100645
		public String TelephoneExtensionFieldLength;	//
		public String TelephoneExtension;	//
		public String TelephoneType;	//00
		public String EnrichedThroughEnquiry;	//
		public String FID;	//
		public String SNo;	//
		public String SuppressFlag;	//
		public String DateOfSuppression;	//
	}
	public class cls_EmailContactSegment {
		public String Length;	//03
		public String SegmentTag;	//C01
		public String EmailIDFieldLength;	//23
		public String EmailID;	//JKOILMILLS2920@YAHOO.IN
		public String FID;	//
		public String SNo;	//
		public String SuppressFlag;	//
		public String DateOfSuppression;	//
	}
	public class cls_EmploymentSegment {
		public String Length;	//03
		public String SegmentTag;	//E01
		public String AccountType;	//51
		public String DateReportedCertified;	//31082017
		public String OccupationCode;	//04
		public String IncomeFieldLength;	//
		public String Income;	//
		public String NetGrossIndicator;	//
		public String MonthlyAnnualIndicator;	//
		public String DateOfEntryForErrorCode;	//
		public String ErrorCode;	//
		public String DateOfEntryForCIBILRemarksCode;	//
		public String CIBILRemarksCode;	//
		public String DateOfEntryForErrorDisputeRemarksCode;	//
		public String ErrorDisputeRemarksCode1;	//
		public String ErrorDisputeRemarksCode2;	//
		public String FID;	//
		public String SNo;	//
		public String SuppressFlag;	//
		public String DateOfSuppression;	//
	}
	public class cls_ScoreSegment {
		public String Length;	//10
		public String ScoreName;	//CIBILTUSC3
		public String ScoreCardName;	//08
		public String ScoreCardVersion;	//10
		public String ScoreDate;	//11052023
		public String Score;	//00775
		public String ExclusionCode1FieldLength;	//
		public String ExclusionCode1;	//
		public String ExclusionCode2FieldLength;	//
		public String ExclusionCode2;	//
		public String ExclusionCode3FieldLength;	//
		public String ExclusionCode3;	//
		public String ExclusionCode4FieldLength;	//
		public String ExclusionCode4;	//
		public String ExclusionCode5FieldLength;	//
		public String ExclusionCode5;	//
		public String ExclusionCode6FieldLength;	//
		public String ExclusionCode6;	//
		public String ExclusionCode7FieldLength;	//
		public String ExclusionCode7;	//
		public String ExclusionCode8FieldLength;	//
		public String ExclusionCode8;	//
		public String ExclusionCode9FieldLength;	//
		public String ExclusionCode9;	//
		public String ExclusionCode10FieldLength;	//
		public String ExclusionCode10;	//
		public String ReasonCode1FieldLength;	//02
		public String ReasonCode1;	//39
		public String ReasonCode2FieldLength;	//
		public String ReasonCode2;	//
		public String ReasonCode3FieldLength;	//
		public String ReasonCode3;	//
		public String ReasonCode4FieldLength;	//
		public String ReasonCode4;	//
		public String ReasonCode5FieldLength;	//
		public String ReasonCode5;	//
		public String ErrorCode;	//
		public String TRLScore;	//
		//public String BureauCharacterstics;	//
	}
	public class cls_Account_Summary_Segment_Fields {
		public String ReportingMemberShortNameFieldLength;	//13
	}
	public class cls_Account_NonSummary_Segment_Fields {
		public String ReportingMemberShortNameFieldLength;	//13
		public String ReportingMemberShortName;	//NOT DISCLOSED
		public String AccountType;	//51
		public String OwenershipIndicator;	//4
		public String DateOpenedOrDisbursed;	//29052023
		public String DateOfLastPayment;	//
		public String DateClosed;	//
		public String DateReportedAndCertified;	//31032024
		public String HighCreditOrSanctionedAmountFieldLength;	//07
		public String HighCreditOrSanctionedAmount;	//1200000
		public String CurrentBalanceFieldLength;	//04
		public String CurrentBalance;	//800000
		public String PaymentHistory1FieldLength;	//03
		public String PaymentHistory1;	//000000000000000000000000000000000
		public String PaymentHistory2FieldLength;	//
		public String PaymentHistory2;	//
		public String PaymentHistoryStartDate;	//01032024
		public String PaymentHistoryEndDate;	//01052023
	}
	public class cls_Enquiry {
		public String Length;	//04
		public String SegmentTag;	//I001
		public String DateOfEnquiryFields;	//11042024
		public String EnquiringMemberShortNameFieldLength;	//13
		public String EnquiringMemberShortName;	//NOT DISCLOSED
		public String EnquiryPurpose;	//61
		public String EnquiryAmountFieldLength;	//07
		public String EnquiryAmount;	//3500000
	}
	public class cls_End {
		public String SegmentTag;	//
		public String TotalLength;	//0
	}
	public class cls_Document {
		public String Id;	//13328815
		public String Name;	//33456672_Cons_CIR_Harshal Patel.html
	}
	// public class cls_DsTuVerification {
	// 	public cls_Response Response;
	// }
	public class cls_HRAAttributes {
		public cls_Attribute[] Attribute;
	}
	public class cls_Attribute {
		public String Id;	//RankSegment
		public String Value;	//LOW
	}
	public class cls_HRARuleAttributes {
		public cls_Attribute[] Attribute;
	}




}