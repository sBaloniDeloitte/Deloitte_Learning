/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-15-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class COMM_AadharFrontTopController {

    @AuraEnabled
    public static AadharFrontTopResponseWrapper getDeserailizedResponse(String response) {
        System.debug('response>>'+response);
        try {
            AadharFrontTopResponseWrapper responseJSON = (AadharFrontTopResponseWrapper)JSON.deserialize(response, AadharFrontTopResponseWrapper.class);
            return responseJSON;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    
    public class AadharFrontTopResponseWrapper {
    public String requestId;	//0926686d-04af-4495-bcb2-76f6cdf17c24
	public cls_result result;
	public Integer statusCode;	//101
	public cls_clientData clientData;
    }
	public class cls_result {
		public cls_documents[] documents;
		public String fileBase64;
	}
	public class cls_documents {
		public String documentType;	//AADHAAR
		public String subType;	//FRONT_TOP
		public Integer pageNo;	//1
		public cls_ocrData ocrData;
		public cls_additionalDetails additionalDetails;
		public cls_qualityChecks[] qualityChecks;
		// public cls_tamperCheck tamperCheck;
		public String documentBase64;	//
	}
	public class cls_ocrData {
		public cls_aadhaar aadhaar;
		public cls_address address;
		public cls_name name;
		public cls_phone phone;
		public cls_pin pin;
		public cls_vid vid;
	}
	public class cls_aadhaar {
		public String value;	//****
		public Double confidence;	//0.78
	}
	public class cls_address {
		public String value;	//
		public Double confidence;	//0.92
	}
	public class cls_name {
		public String value;	//
		public Double confidence;	//0.88
	}
	public class cls_phone {
		public String value;	//
		public Double confidence;	//0.97
	}
	public class cls_pin {
		public String value;	//491001
		public Double confidence;	//0.7
	}
	public class cls_vid {
		public String value;	//
		public Double confidence;	//0.8
	}
	public class cls_additionalDetails {
		public cls_addressSplit addressSplit;
		public boolean isSigned;
		public boolean signatureVerified;
		public boolean verhoeffCheck;
		public cls_inputMaskStatus inputMaskStatus;
		public cls_careOfDetails careOfDetails;
		public Boolean outputMaskStatus;
	}
	public class cls_inputMaskStatus {
		public Boolean isMasked;
		public String maskedBy;
		public Double confidence;
	}
	// class cls_isMasked {
	// }
	// class cls_maskedBy {
	// }
	// class cls_confidence {
	// }
	class cls_verhoeffCheck {
	}
	class cls_qr {
	}
	class cls_barcode {
	}
	public class cls_parsedQrData {
		public String aadhaar;	//********8855
		public String name;	//
		public String dob;	//1997-04-19
		public String yob;	//1997
		public String gender;	//F
		public cls_emailHash emailHash;
		public String mobileHash;	//b3987028141ed0d5613d3ac7dc4e1c39ff910004001080ff910004001180ffd9
		public String image;	//
		public String address;	//
		public String version;	//SECURE_V2
		public String mobile;	//******6853
		public cls_additionalDetails additionalDetails;
	}
	class cls_emailHash {
	}
	public class cls_addressSplit {
		public String building;	//
		public String city;	//
		public String district;	//
		public String pin;	//
		public String floor;	//
		public String house;	//
		public String locality;	//
		public String state;	//
		public String street;	//
		public String complex;	//
		public String landmark;	//
		public String untagged;	//
	}
	public class cls_careOfDetails {
		public String relation;	//
		public String name;	//
	}
	public class cls_qualityChecks {
		public Double score;	//0.89
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