/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-19-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

public class CustomerDedupeWrapper {
    
    public cls_Data Data;
	public Integer StatusCode;
	public class cls_Data {
		public cls_SessionContext SessionContext;
        public cls_TransactionStatus[] TransactionStatus;
		// public cls_PostingDate[] PostingDate;
		public cls_CustomerDetails[] CustomerDetails;
		public String FlgIndividual;			//Y
		public String customerId;
        public String aadharNumber;				//9128506
        public String VoterId;				//BB/2425/2312
        public String PassportNumber;			//ANKIT
        public String DrivingLicenseNumber;
        public String jobCardNREGA;				//SRIVASTAVA
        public String letterNationalPopulationRegister;
        public String PANNumber;
        public String MobileNumber;				//9128506
        public String emailID;					//BB/2425/2312
        public String dob;						//ANKIT
        public String firstName;
        public String middleName;				//SRIVASTAVA
        public String lastName;
        public String customerName;
        public String addressDetails;
	}
	public class cls_SessionContext {
		public String BankCode;	//750
		public String TransactionBranch;	//1000
		public String ExternalReferenceNo;	//46t7uxh1b1346x
		public String UserId;	//TU1BAPIUSR
		public String ServiceCode;	//B277
		public String UserNo;	//120342
	}
    public class cls_TransactionStatus {
		public String IsOverriden;	//false
		public String ReplyCode;	//0
		public String SpReturnValue;	//0
		public String ExternalReferenceNo;	//46t7uxhb926x
		public String IsServiceChargeApplied;	//false
		public String ErrorCode;	//0
		public cls_ExtendedReply ExtendedReply;
		public boolean FCYHangeHandlingApplied;
	}
    public class cls_ExtendedReply {
	}
    public class cls_PostingDate {
        public String postDate;
    }
    public class cls_CustomerDetails {
		public Integer CustomerNumber;	//320809486
		public String AadhaarNumber;	//0523
		public Long MobileNumber;	//8972787552
		public String FullName;	//UMUMA ARARMAKAR
		public String BirthDate;	//19930202
		public String MotherName;	//MITHU
		public String Address1;	//KBIDEV KENDULI JOYDEV KENDULI LAND MARK
		public String Address2;	//LBLI MANDIR DIST-BIRBHUM
		public String Address3;	//!
		public String City;	//ILLAMBAZAR
		public String State;	//West Bengal
		public String Pincode;	//731124
		public String Country;	//INDIA
		public String BlockStatus;	//N
		public String EmailId;	
		public String FirstName;	//UMUMA
		public String LastName;	//ARARMAKAR
		public String CKYCID;	//40039478582000
		public String IcType;	//Individual
		public String CustIc;	//320809486
		public String PANNumber;
	}
}