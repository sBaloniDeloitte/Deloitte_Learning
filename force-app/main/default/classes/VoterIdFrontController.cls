public with sharing class VoterIdFrontController {
    
    @AuraEnabled
    public static VoterIdFrontResponseWrapper getDeserailizedResponse(String response) {
        System.debug('response>>'+response);
        try {
            VoterIdFrontResponseWrapper responseJSON = (VoterIdFrontResponseWrapper)JSON.deserialize(response, VoterIdFrontResponseWrapper.class);
            return responseJSON;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class  VoterIdFrontResponseWrapper {
        public String requestId;	//9060072d-947b-4df7-9a85-5f5bbcd499b3
        public cls_result result;
        public Integer statusCode;	//101
        public cls_clientData clientData;
     }
     public class cls_result {
            public cls_documents[] documents;
        }
    public class cls_documents {
        public String documentType;	//VOTER
        public String subType;	//FRONT_NEW
        public Integer pageNo;	//1
        public cls_ocrData ocrData;
        public cls_additionalDetails additionalDetails;
        public cls_qualityChecks[] qualityChecks;
        public cls_tamperCheck tamperCheck;
        public cls_documentLink documentLink;
    }
    public class cls_ocrData {
        public cls_voterId voterId;
        public cls_name name;
        public cls_relationName relationName;
    }
    public class cls_voterId {
        public String value;	//
        public Double confidence;	//0.1
    }
    public class cls_name {
        public String value;	//
        public Double confidence;	//0.87
    }
    public class cls_relationName {
        public String value;	//
        public Double confidence;	//0.78
    }
    public class cls_additionalDetails {
    }
    public class cls_qualityChecks {
        public Double score;	//0.66
        public boolean flag;
        public String type;	//BRIGHTNESS
    }
    public class cls_tamperCheck {
        public Double score;	//0.9
        public String tamperRisk;	//HIGH
        public String status;	//SUCCESS
    }
    public class cls_documentLink {
    }
    public class cls_clientData {
        public String caseId;	//123456
    }
}