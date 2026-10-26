public class DocGenESignJSONCreator {
    public cls_authSignatoryDetails authSignatoryDetails;
	public cls_coApplicantDetails coApplicantDetails;
	public String contentId;	//sdfghj12345
	public cls_customerDetails customerDetails;
	//public cls_digiUploadDocumentsDto[] digiUploadDocumentsDto;
	public cls_documentAndPageNumbers[] documentAndPageNumbers;
	public cls_estampDetails[] estampDetails;
	public String lan;	//GFL3001BL0015103
	public Boolean stamppaperRequired;
	public class cls_authSignatoryDetails {
		public String emailID;	//sachin.shah@godrejcapital.com
		public String mobileNumber;	//
		public String name;	//Sachin Shah
	}
	public class cls_coApplicantDetails {
		public cls_applicants[] applicants;
	}
	public class cls_applicants {
		public String emailID;	//
		public String id;	//
		public String mobileNumber;	//9657129890
		public String name;	//Amritha Nikhil
	}
	public class cls_customerDetails {
		public String emailID;
		public String mobileNumber;	//9137335330
		public String name;	//Dhiraj Traders
	}
	
	/*public class cls_digiUploadDocumentsDto {
		public String fileId;	//068Bi000003KWurIAG
		public String fileName;	//BLAB.pdf
	}*/
	public class cls_documentAndPageNumbers {
		public String documentName;	//BLAB
		public Integer pageNumbers;	//43
	}
	public class cls_estampDetails {
		public String tagName;	//GA-100-GA-100
		public Integer tagQuantity;	//2
	}
	public class DocGenEsigncompleteWrapper{
        public string docusignstring;
        public string signedCoordinates;
    }
}