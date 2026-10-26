/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-30-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class DLController {
    @AuraEnabled
    public static DLResponseWrapper getDeserailizedResponse(String response) {
        System.debug('response>>'+response);
        try {
            DLResponseWrapper responseJSON = (DLResponseWrapper)JSON.deserialize(response, DLResponseWrapper.class);
            return responseJSON;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public  class DLResponseWrapper {
    public String requestId;	//014b9c92-2388-4c6b-88b9-b7895db039a4
	public cls_result result;
	public Integer statusCode;	//101
	// public cls_clientData clientData;
    }
	public class cls_result {
		public cls_documents[] documents;
	}
	public class cls_documents {
		public String documentType;	//DL
		public String subType;	//
		public cls_pageNo pageNo;
		public cls_ocrData ocrData;
		public cls_additionalDetails additionalDetails;
	}
	public class cls_pageNo {
	}
	public class cls_ocrData {
		public cls_dlNo dlNo;
		public cls_name name;
		public cls_dob dob;
		public cls_doi doi;
		public cls_doe doe;
		public cls_relationName relationName;
		public cls_address address;
		public cls_pin pin;
	}
	public class cls_dlNo {
		public String value;	//
		public Double confidence;	//0.79
	}
	public class cls_name {
		public String value;	//
		public Double confidence;	//0.91
	}
	public class cls_dob {
		public String value;	//05-01-1995
		public Double confidence;	//0.68
	}
	public class cls_doi {
		public String value;	//13-01-2015
		public Double confidence;	//0.66
	}
	public class cls_doe {
		public String value;	//12-01-2035
		public Double confidence;	//0.88
	}
	public class cls_relationName {
		public String value;	//
		public Double confidence;	//0.91
	}
	public class cls_address {
		public String value;	//
		public Double confidence;	//0.91
	}
	public class cls_pin {
		public String value;	//
		public Double confidence;	//0.77
	}
	public class cls_additionalDetails {
		public boolean faceDetected;
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
	public class cls_clientData {
		public String caseId;	//123456
	}
    
}