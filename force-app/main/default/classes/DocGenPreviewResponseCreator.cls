public with sharing class DocGenPreviewResponseCreator {
    // public cls_data data;
	// public String message;	//Output document
	// public Boolean status; //Integer status, incase of 500 response from API
	// public Integer statusCode;	//200
	// public string traceId;
	// public class cls_data {
	// 	public cls_documentAndPageNumbers[] documentAndPageNumbers;
	// 	public String id;	//068Bi000003OUHmIAO
	// }
	// public class cls_documentAndPageNumbers {
	// 	public String documentName;	//BLAB.pdf
	// 	public String pageNumbers;	//43
	// }

	public class syncResponse{
		public cls_data data;
		public String message;	//Output document
		public Boolean status; //Integer status, incase of 500 response from API
		public Integer statusCode;	//200
		public string traceId;
	}

	public class cls_data {
		public cls_documentAndPageNumbers[] documentAndPageNumbers;
		public String id;	//068Bi000003OUHmIAO
	}

	public class cls_documentAndPageNumbers {
		public String documentName;	//BLAB.pdf
		public String pageNumbers;	//43
	}

	public class asyncResponse {
		public String data;           
        public String message;
        public Boolean status;
        public Integer statusCode;
        public String traceId;
	}
}