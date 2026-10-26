public with sharing class PassportFrontController {
    @AuraEnabled
    public static PassportFrontResponseWrapper getDeserailizedResponse(String response) {
        System.debug('response>>'+response);
        try {
            PassportFrontResponseWrapper responseJSON = (PassportFrontResponseWrapper)JSON.deserialize(response, PassportFrontResponseWrapper.class);
            return responseJSON;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class PassportFrontResponseWrapper {
        public String requestId;	//4f51e788-9cf6-467d-9280-e63832b99e4d
        public cls_result result;
        public Integer statusCode;	//101
        public cls_clientData clientData;
    }
    public class cls_result {
            public cls_documents[] documents;
        }
    public class cls_documents {
        public String documentType;	//PASSPORT
        public String subType;	//FRONT
        public Integer pageNo;	//1
        public cls_ocrData ocrData;
        public cls_additionalDetails additionalDetails;
        public cls_qualityChecks[] qualityChecks;
        public cls_documentLink documentLink;
    }
    public class cls_ocrData {
        public cls_countryCode countryCode;
        public cls_dob dob;
        public cls_doe doe;
        public cls_doi doi;
        public cls_gender gender;
        public cls_givenName givenName;
        public cls_nationality nationality;
        public cls_passportNumber passportNumber;
        public cls_placeOfBirth placeOfBirth;
        public cls_placeOfIssue placeOfIssue;
        public cls_surname surname;
        public cls_type type;
        public cls_mrzLine1 mrzLine1;
        public cls_mrzLine2 mrzLine2;
    }
    public class cls_countryCode {
        public String value;	//IND
        public Double confidence;	//0.98
    }
    public class cls_dob {
        public String value;	//
        public Double confidence;	//0.9
    }
    public class cls_doe {
        public String value;	//
        public Double confidence;	//0.9
    }
    public class cls_doi {
        public String value;	//
        public Double confidence;	//0.9
    }
    public class cls_gender {
        public String value;	//
        public Double confidence;	//0.92
    }
    public class cls_givenName {
        public String value;	//
        public Double confidence;	//0.98
    }
    public class cls_nationality {
        public String value;	//INDIAN
        public Double confidence;	//0.8
    }
    public class cls_passportNumber {
        public String value;	//
        public Double confidence;	//0.99
    }
    public class cls_placeOfBirth {
        public String value;	//
        public Double confidence;	//0.96
    }
    public class cls_placeOfIssue {
        public String value;	//
        public Double confidence;	//0.61
    }
    public class cls_surname {
        public String value;	//
        public Double confidence;	//0.98
    }
    public class cls_type {
        public String value;	//P
        public Double confidence;	//0.98
    }
    public class cls_mrzLine1 {
        public String value;	//
        public Double confidence;	//0.92
    }
    public class cls_mrzLine2 {
        public String value;	//
        public Double confidence;	//0.92
    }
    public class cls_additionalDetails {
    }
    public class cls_qualityChecks {
        public Double score;	//0.71
        public boolean flag;
        public String type;	//BRIGHTNESS
    }
    public class cls_documentLink {
    }
    public class cls_clientData {
        public String caseId;	//123456
    }
    
}