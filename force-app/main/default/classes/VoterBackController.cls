/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-18-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class VoterBackController {
    @AuraEnabled
    public static VoterBackResponseWrapper getDeserailizedResponse(String response) {
        System.debug('response>>'+response);
        try {
            VoterBackResponseWrapper responseJSON = (VoterBackResponseWrapper)JSON.deserialize(response, VoterBackResponseWrapper.class);
            return responseJSON;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class VoterBackResponseWrapper{
    public String requestId;	//8c49e926-1f4d-4465-93e3-df0af9137337
	public cls_result result;
	public Integer statusCode;	//101
	public cls_clientData clientData;
    }
	public class cls_result {
		public cls_documents[] documents;
	}
	public class cls_documents {
		public String documentType;	//VOTER
		public String subType;	//BACK_NEW
		public Integer pageNo;	//1
		public cls_ocrData ocrData;
		public cls_additionalDetails additionalDetails;
		public cls_qualityChecks[] qualityChecks;
		public cls_tamperCheck tamperCheck;
		// public cls_documentLink documentLink;
	}
	public class cls_ocrData {
		public cls_voterId voterId;
		public cls_gender gender;
		public cls_lastUpdatedDate lastUpdatedDate;
		public cls_dob dob;
		public cls_age age;
		public cls_address address;
	}
	public class cls_voterId {
		public String value;	//
		public Double confidence;	//0
	}
	public class cls_gender {
		public String value;	//
		public Double confidence;	//0.59
	}
	public class cls_lastUpdatedDate {
		public String value;	//
		public Double confidence;	//0
	}
	public class cls_dob {
		public String value;	//
		public Double confidence;	//0
	}
	public class cls_age {
		public String value;	//33
		public Double confidence;	//1
	}
	public class cls_address {
		public String value;	//
		public Double confidence;	//0.71
	}
	public class cls_additionalDetails {
		public cls_addressSplit addressSplit;
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
	public class cls_qualityChecks {
		public Double score;	//0.71
		public boolean flag;
		public String type;	//BRIGHTNESS
	}
	public class cls_tamperCheck {
		public Double score;	//0.9
		public String tamperRisk;	//HIGH
		public String status;	//SUCCESS
	}
	class cls_documentLink {
	}
	public class cls_clientData {
		public String caseId;	//123456
	}
}