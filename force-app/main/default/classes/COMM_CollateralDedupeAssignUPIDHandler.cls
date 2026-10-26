/**
* @File Name : CollateralDedupeAssignUPIDHandler.cls
* @Description : Handles UPID assignment for Collateral Dedupe
* @Author :
* @Last Modified By :
* @Last Modified On : July 24, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 24, 2025 |   | Initial Version
**/

public with sharing class COMM_CollateralDedupeAssignUPIDHandler implements IntegrationInterface {

    static String conLabels = 'COLLATERAL_DEDUPE_ASSIGN_UPID';
    public static Map<String, String> constants = Utility.getConstants(conLabels);

    @AuraEnabled
    public static Map<String, String> getConstants() {
        return constants;
    }

    public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) { 
        String loanApplicationId = wrapper.loanApplicationId;
        List<String> errorMessages = new List<String>();

        if (String.isBlank(loanApplicationId)) {
            errorMessages.add('Error: Loan Id is missing');
            return errorMessages;
        }

        List<Opportunity> loan = [
            SELECT Id FROM Opportunity WHERE Id = :loanApplicationId LIMIT 1
        ];

        if (loan.isEmpty()) {
            errorMessages.add('Error: No applicant found with the provided ID.');
        }
        return errorMessages;
    }

    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
            COMM_SalesCollateralDetailsController.CollateralWrapper collateral = 
                (COMM_SalesCollateralDetailsController.CollateralWrapper) JSON.deserialize(wrapper.collateralJson, COMM_SalesCollateralDetailsController.CollateralWrapper.class);
            String loanApplicationId = wrapper.loanApplicationId;
            
            Opportunity opp = [SELECT Id, Name,HL_AHL_Vertical__c FROM Opportunity WHERE Id =: loanApplicationId LIMIT 1];
            String vertical = opp.HL_AHL_Vertical__c;
            String uniqueRequestId =  Utility.generateRequestId(vertical);                    //wrapper.uniqueReqId;
            String externalId = wrapper.externalId;
            system.debug('uniqueRequestId--'+uniqueRequestId);
            system.debug('externalId--'+externalId);

			String timestamp = String.valueOf(Datetime.now().getTime());
            String oppNameNoHyphen = opp.Name.replaceAll('-', '');

            AssignUPIDRequestWrapper metadata = new AssignUPIDRequestWrapper();
            metadata.UNIQUEREQUEST_ID = uniqueRequestId;
            metadata.EXTERNAL_ID = externalId;
            metadata.LANREFERENCE_NO = oppNameNoHyphen;
            metadata.SOURCE_SYSTEM = 'SALESFORCE';
            metadata.UPID = String.isBlank(collateral.upid) ? '' : collateral.upid;
            metadata.UPID_TYPE = String.isBlank(collateral.upid) ? 'N' : 'E';

            // Wrap it inside a metadata object
            MetadataWrapper finalRequest = new MetadataWrapper();
            finalRequest.Metadata = metadata;

            String requestJSON = JSON.serialize(finalRequest);
            System.debug('Constructed Request JSON: ' + requestJSON);
            return requestJSON;

        } catch (Exception ex) {
            System.debug('Error in constructPayload: ' + ex.getMessage());
            throw new AuraHandledException('Failed to construct payload: ' + ex.getMessage());
        }
    }

    public class MetadataWrapper {
        public AssignUPIDRequestWrapper Metadata;
    }

    public class AssignUPIDRequestWrapper {
        public String UNIQUEREQUEST_ID;
        public String EXTERNAL_ID;
        public String LANREFERENCE_NO;
        public String SOURCE_SYSTEM;
        public String UPID;
        public String UPID_TYPE;
    }
}