/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-06-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class PassportBackController {
    @AuraEnabled
    public static PassportBackResponseWrapper getDeserializedResponse(String response) {
        System.debug('response>>' + response);
        try {
            PassportBackResponseWrapper responseJSON = (PassportBackResponseWrapper) JSON.deserialize(response, PassportBackResponseWrapper.class);
            return responseJSON;
        } catch (Exception e) {
            System.debug('Deserialization Error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class PassportBackResponseWrapper {
        public String requestId;
        public cls_result result;
        public Integer statusCode;
    }

    public class cls_result {
        public cls_documents[] documents;
    }

    public class cls_documents {
        public String documentType;
        public String subType;
        public Integer pageNo;
        public cls_ocrData ocrData;
        public cls_additionalDetails additionalDetails;
    }

    public class cls_ocrData {
        public cls_father father;
        public cls_fileNumber fileNumber;
        public cls_mother mother;
        public cls_oldDoi oldDoi;
        public cls_oldPassportNumber oldPassportNumber;
        public cls_oldPlaceOfIssue oldPlaceOfIssue;
        public cls_passportNumber passportNumber;
        public cls_pin pin;
        public cls_spouse spouse;
        public cls_address address;
    }

    public class cls_father {
        public String value;
        public Double confidence;
    }

    public class cls_fileNumber {
        public String value;
        public Double confidence;
    }

    public class cls_mother {
        public String value;
        public Double confidence;
    }

    public class cls_oldDoi {
        public String value;
        public Double confidence;
    }

    public class cls_oldPassportNumber {
        public String value;
        public Double confidence;
    }

    public class cls_oldPlaceOfIssue {
        public String value;
        public Double confidence;
    }

    public class cls_passportNumber {
        public String value;
        public Double confidence;
    }

    public class cls_pin {
        public String value;
        public Double confidence;
    }

    public class cls_spouse {
        public String value;
        public Double confidence;
    }

    public class cls_address {
        public String value;
        public Double confidence;
    }

    public class cls_additionalDetails {
        public cls_addressSplit addressSplit;
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

    public class cls_clientData {
        public String caseId;
    }
}