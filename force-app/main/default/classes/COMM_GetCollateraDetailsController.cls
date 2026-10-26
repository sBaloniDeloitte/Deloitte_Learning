/**
* @File Name : COMM_GetCollateraDetailsController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 21, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 21, 2025 |   | Initial Version
**/

public with sharing class COMM_GetCollateraDetailsController {

    public static CollateralResponseWrapper getCollateralDetails(String customerId,String processName) {
        try {
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Message_Id__c, Entity_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c FROM Integration_Settings__c WHERE Name = :processName LIMIT 1];

            Integration_Settings__c intSetting = intSettingList[0];
            Map<String,String> integrationRequestMap = new Map<String,String>();
            String endpoint  = intSetting.Endpoint__c+'/'+customerId;
            integrationRequestMap.put('intSettingName',processName);
            integrationRequestMap.put('endPoint',endpoint);
            integrationRequestMap.put('serviceName','getCollaterals');
           	integrationRequestMap.put('MESSAGEID', intSetting.Message_Id__c);
            integrationRequestMap.put('ENTITYID', intSetting.Entity_Id__c);
            integrationRequestMap.put('ServiceVersion','1');
            integrationRequestMap.put('RequestTime', String.valueof(DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss')));
            integrationRequestMap.put('Language','ENG');
             String bearer = Utility.getAccessToken();
            System.debug('bearer----'+bearer);
            integrationRequestMap.put('bearer',bearer);
            HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
            system.debug('response-33---'+resp.getBody());

            CollateralResponseWrapper wrapper = (CollateralResponseWrapper) JSON.deserialize(resp.getBody(), CollateralResponseWrapper.class);


                   /* integrationDetail.Calling_Source__c = 'Get Collateral Details';
                    integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
                    integrationDetail.Method_Type__c = intSetting.Request_Method__c;
                    integrationDetail.EndPoint__c = intSetting.Endpoint__c;
                    integrationDetail.Name = 'Get Collateral Details';
                    integrationDetail.Related_Record_Id__c = checklist.Id;
                    // integrationDetail.Loan_Application__c = loanId;
                    integrationDetail.Customer_Id__c= customerId;
                    insert integrationDetail;*/

            return wrapper;

        }
        catch (Exception e) {
            System.debug('Error in getCollateralDetails: ' + e.getMessage());
            return null;
        }
    }


    public class CollateralResponseWrapper {
        public String cif;
        public ReturnStatus returnStatus;
        public List<Collateral> collateral;
    }

    public class ReturnStatus {
        public String returnCode;
        public String returnText;
    }

    public class Collateral {
        public String collateralRef;
        public String cif;
        public String collateralType;
        public Integer version;
        public Decimal splLtv;
        public String collateralCcy;
        public Decimal maxCollateralValue;
        public String remarks;
        public String collateralLoc;
        public String valuator;
        public String rvwFrq;
        public Boolean alwThirdPartyAssign;
        public Boolean alwMultiLoanAssign;
        public List<CoOwnerDetail> coOwnerDetails;
        public List<ThirdParty> thirdParties;
        public List<Document> documents;
        public List<ExtendedDetail> extendedDetails;
    }

    public class CoOwnerDetail {}
    public class ThirdParty {}
    public class Document {}

    public class ExtendedDetail {
        //public List<ExtendedField> extendedFields;
    }

   // public class ExtendedField {
       // public String fieldName;
       // public Object fieldValue; 
   // }

}