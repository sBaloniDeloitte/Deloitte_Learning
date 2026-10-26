/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-17-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

public class DocGenPreviewJSONCreator {
    public  digiUploadDocuments[] digiUploadDocumentsDto;
	//public  fieldData[] fieldData;
	public string lan;
	public String loanId;
	public String docType;
	
	public class  digiUploadDocuments {
		public fieldData[] fieldData;
		public String fileId;	//a09456789
		public String fileName;	//BLAB.pdf
		public String sequence;
	}
	public class  fieldData {
		public String sfieldKeyword;	//BLFL2
		public String sfieldType;	//String
		public String sfieldValue;	//1
	}
}