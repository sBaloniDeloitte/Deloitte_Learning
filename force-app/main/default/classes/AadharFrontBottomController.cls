/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-15-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class AadharFrontBottomController {
    @AuraEnabled
    public static AadharFrontBottomResponseWrapper getDeserailizedResponse(String response) {
        System.debug('response>>'+response);
        try {
            AadharFrontBottomResponseWrapper responseJSON = (AadharFrontBottomResponseWrapper)JSON.deserialize(response, AadharFrontBottomResponseWrapper.class);
            return responseJSON;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class AadharFrontBottomResponseWrapper {
        public String requestId;	//378d4b46-5e30-4107-9a6d-368b120013ab
        public cls_result result;
        public Double statusCode;	//101
        public cls_clientData clientData;
        }
        public class cls_result {
            public cls_documents[] documents;
            public String fileBase64;
        }
        public class cls_documents {
            public String documentType;	//AADHAAR
            public String subType;	//FRONT_BOTTOM
            public Double pageNo;	//1
            public cls_ocrData ocrData;
            public cls_additionalDetails additionalDetails;
            public cls_qualityChecks[] qualityChecks;
            public cls_tamperCheck tamperCheck;
            public String documentBase64;	//
        }
        public class cls_ocrData {
            public cls_aadhaar aadhaar;
            public cls_dob dob;
            public cls_father father;
            public cls_gender gender;
            public cls_husband husband;
            public cls_mother mother;
            public cls_name name;
            public cls_vid vid;
            public cls_yob yob;
        }
        public class cls_aadhaar {
            public String value;	//********8855
            public Double confidence;	//1
        }
        public class cls_dob {
            public String value;	//
            public Double confidence;	//1
        }
        public class cls_father {
            public String value;	//
            public Double confidence;	//0
        }
        public class cls_gender {
            public String value;	//
            public Double confidence;	//1
        }
        public class cls_husband {
            public String value;	//
            public Double confidence;	//0
        }
        public class cls_mother {
            public String value;	//
            public Double confidence;	//0
        }
        public class cls_name {
            public String value;	//
            public Double confidence;	//1
        }
        public class cls_vid {
            public String value;	//
            public Double confidence;	//0.8
        }
        public class cls_yob {
            public String value;	//
            public Double confidence;	//0
        }
        public class cls_additionalDetails {
            public cls_inputMaskStatus inputMaskStatus;
            public boolean outputMaskStatus;
            public boolean verhoeffCheck;
            // public cls_qr qr;
            // public cls_barcode barcode;
        }
        public class cls_inputMaskStatus {
            public boolean isMasked;
            public String maskedBy;
            public Double confidence;
        }
        class cls_maskedBy {
        }
        class cls_confidence {
        }
        class cls_qr {
        }
        class cls_barcode {
        }
        public class cls_qualityChecks {
            public Double score;	//0.76
            public boolean flag;
            public String type;	//BRIGHTNESS
        }
        public class cls_tamperCheck {
            public Double score;	//0.9
            public String tamperRisk;	//HIGH
            public String status;	//SUCCESS
        }
        public class cls_clientData {
            public String caseId;	//123456
        }
    
}