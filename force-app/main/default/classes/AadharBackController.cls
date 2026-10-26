/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-15-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class AadharBackController {
    public class AadharBackControllerResponseWrapper {
        public String requestId;
        public Integer statusCode;
        public cls_clientData clientData;
        public cls_result result;
    }

    public class cls_clientData {
        public String caseId;
    }

    public class cls_result {
        public cls_documents[] documents;
        public String fileBase64;
    }

    public class cls_documents {
        public String documentType;
        public String subType;
        public Integer pageNo;
        public cls_ocrData ocrData;
        public cls_additionalDetails additionalDetails;
        public cls_qualityChecks[] qualityChecks;
        public cls_tamperCheck tamperCheck;
        public String documentBase64;
    }

    public class cls_ocrData {
        public cls_aadhaar aadhaar;
        public cls_aadhaar address;
        public cls_aadhaar pin;
        public cls_aadhaar vid;
    }

    public class cls_aadhaar {
        public String value;
        public Decimal confidence;
    }

    public class cls_additionalDetails {
        public cls_inputMaskStatus inputMaskStatus;
        public Boolean outputMaskStatus;
        public Boolean verhoeffCheck;
        public String qr;
        public String barcode;
        public cls_parsedQrData parsedQrData;
        public cls_addressSplit addressSplit;
        public cls_careOfDetails careOfDetails;
    }

    public class cls_inputMaskStatus {
        public Boolean isMasked;
        public String maskedBy;
        public Decimal confidence;
    }

    public class cls_parsedQrData {
        public String aadhaar;
        public String name;
        public String dob;
        public String yob;
        public String gender;
        public String emailHash;
        public String mobileHash;
        public String image;
        public String address;
        public String version;
        public String mobile;
        public cls_additionalQrDetails additionalDetails;
    }

    public class cls_additionalQrDetails {
        public cls_addressSplit addressSplit;
        public Boolean isSigned;
        public Boolean signatureVerified;
        public Boolean verhoeffCheck;
    }

    public class cls_addressSplit {
        public String building;
        public String city;
        public String district;
        public String pin;
        public String floor;
        public String house;
        public String locality;
        public String state;
        public String street;
        public String complex;
        public String landmark;
        public String untagged;
    }

    public class cls_careOfDetails {
        public String relation;
        public String name;
    }

    public class cls_qualityChecks {
        public Decimal score;
        public Boolean flag;
        public String type;
    }

    public class cls_tamperCheck {
        public Decimal score;
        public String tamperRisk;
        public String status;
    }
    
}