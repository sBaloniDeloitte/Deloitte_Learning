public with sharing class COMM_PANOCRController {
    @AuraEnabled
    public static PanResponseWrapper getDeserailizedResponse(String response) {
        System.debug('response>>'+response);
        try {
            PanResponseWrapper responseJSON = (PanResponseWrapper)JSON.deserialize(response, PanResponseWrapper.class);
            return responseJSON;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    public class PanResponseWrapper {
        @AuraEnabled public String requestId; // 67989ed2-8a6a-42a6-922a-7fec3e644990
        @AuraEnabled public cls_result result;
        @AuraEnabled public Integer statusCode; // 101
        @AuraEnabled public cls_clientData clientData;
    }
    
        public class cls_result {
            @AuraEnabled public List<cls_documents> documents;
        }
    
        public class cls_documents {
            @AuraEnabled public String documentType; // PAN
            @AuraEnabled public String subType;
            @AuraEnabled public Integer pageNo; // 1
            @AuraEnabled public cls_ocrData ocrData;
            @AuraEnabled public cls_additionalDetails additionalDetails;
            @AuraEnabled public List<cls_qualityChecks> qualityChecks;
            @AuraEnabled public cls_tamperCheck tamperCheck;
            @AuraEnabled public cls_documentLink documentLink;
        }
    
        public class cls_ocrData {
            @AuraEnabled public cls_dob dob;
            @AuraEnabled public cls_doi doi;
            @AuraEnabled public cls_father father;
            @AuraEnabled public cls_name name;
            @AuraEnabled public cls_pan pan;
        }
    
        public class cls_dob {
            @AuraEnabled public String value; // 29/10/1982
            @AuraEnabled public Decimal confidence; // 1
        }
    
        public class cls_doi {
            @AuraEnabled public String value;
            @AuraEnabled public Decimal confidence; // 0
        }
    
        public class cls_father {
            @AuraEnabled public String value;
            @AuraEnabled public Decimal confidence; // 0.84
        }
    
        public class cls_name {
            @AuraEnabled public String value;
            @AuraEnabled public Decimal confidence; // 1
        }
    
        public class cls_pan {
            @AuraEnabled public String value;
            @AuraEnabled public Decimal confidence; // 1
        }
    
        public class cls_additionalDetails {
        }
    
        public class cls_qualityChecks {
            @AuraEnabled public Double score; // 0.59
            @AuraEnabled public Boolean flag;
            @AuraEnabled public String type; // BRIGHTNESS
        }
    
        public class cls_tamperCheck {
            @AuraEnabled public Double score; // 0.9
            @AuraEnabled public String tamperRisk; // HIGH
            @AuraEnabled public String status; // SUCCESS
        }
    
        public class cls_documentLink {
        }
    
        public class cls_clientData {
            @AuraEnabled public String caseId; // 123456
        }
    
    


    // public class PanResponseWrapper{
	// 		@AuraEnabled public cls_result result;
	// 		@AuraEnabled public String request_id;  // deff5ed8-0460-11e9-a082-4742912ca12a
	// 		@AuraEnabled public String status_code;  // 101
	// 		@AuraEnabled public cls_clientData clientData;
	//    }
		
	// 		public class cls_result {
	// 			@AuraEnabled public String status;  // Active
	// 			@AuraEnabled public cls_duplicate duplicate;
	// 			@AuraEnabled public Boolean nameMatch;
	// 			@AuraEnabled public Boolean dobMatch;
	// 		}
		
	// 		public class cls_duplicate {
	// 			// You can add properties inside this class if needed
	// 		}
		
	// 		public class cls_clientData {
	// 			@AuraEnabled public String caseId;  // 123456
	// 		}
		
}