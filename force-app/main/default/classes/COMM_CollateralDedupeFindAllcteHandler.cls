public with sharing class COMM_CollateralDedupeFindAllcteHandler implements IntegrationInterface {

	static String conLabels = 'COLLATERAL_DEDUPE_F&A';
    public static Map<String, String> constants = Utility.getConstants(conLabels);

    @AuraEnabled
    public static Map<String, String> getConstants() {
        return constants;
    }

    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
		String loanApplicationId = wrapper.loanApplicationId;
        List<String> errorMessages = new List<String>();

        if (String.isBlank(loanApplicationId)) {
            errorMessages.add('Error: Loan Id is missing');
            return errorMessages;
        }

        List<Opportunity> loan = [
            SELECT Id FROM Opportunity WHERE Id = :loanApplicationId LIMIT 1];

        if (loan.isEmpty()) {
            errorMessages.add('Error: No applicant found with the provided ID.');
        } 
        return errorMessages;
	}

	public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
		try {
			System.debug('wrapper---'+wrapper.collateralJson);
			COMM_SalesCollateralDetailsController.CollateralWrapper collateral = 
				(COMM_SalesCollateralDetailsController.CollateralWrapper) 
				JSON.deserialize(wrapper.collateralJson, COMM_SalesCollateralDetailsController.CollateralWrapper.class);

			String loanApplicationId = wrapper.loanApplicationId;
			String tenDigit = String.valueOf(Datetime.now().getTime()).right(10);
			Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Id = :loanApplicationId LIMIT 1];

			String timestamp = String.valueOf(Datetime.now().getTime()); 
			String oppNameNoHyphen = opp.Name.replaceAll('-', '');

			// ✅ Initialize all fields with blank string
			FindPropertyRequestWrapper req = new FindPropertyRequestWrapper();
			req.UNIQUEREQUEST_ID        = oppNameNoHyphen + timestamp;
			req.PROFILE_ID              = collateral.apfValue.toLowerCase() == 'yes' ? '1' : '2';
			req.EXTERNAL_ID             = 'CL' + tenDigit;
			req.LANREFERENCE_NO         = oppNameNoHyphen;
			req.ADDRESS                 = '';
			req.ADDRESS_1               = collateral.address1;
			req.ADDRESS_2               = collateral.address2;
			req.ADDRESS_3               = collateral.address3;
			req.ADDRESS_TYPE            = '';
			req.AFFORDABLE              = '';
			req.APF_NONAPF              = '';
			req.APF_NUMBER              = collateral.apfValue.toLowerCase() == 'yes' ? collateral.apfNumber : '';
			req.UNIT_NUMBER = collateral.apfValue.toLowerCase() == 'yes' ? String.valueOf(collateral.unitNumber) : '';
			req.ASSIGNMENT_PERCENTAGE   = '';
			req.BUILDER_ID              = '';
			req.BUILDER_NAME            = collateral.apfValue.toLowerCase() == 'yes' ? collateral.devName : '';
			req.COLLATERAL_TYPE         = collateral.collateralType;
			req.CONSTRUCTION_TYPE       = '';
			req.CERSAINUMBER            = '';
			req.CIF_NUMBER              = '';
			req.DISTRICT_CITY           = collateral.city;
			req.DOCUMENTEDVALUE         = '';
			req.ENTITY_NAME             = 'GHF';
			req.EXTENT_OF_BUILTUP_AREA  = '';
			req.EXTENT_OF_LAND          = '';
			req.FLOOR_NUMBER            = collateral.apfValue.toLowerCase() == 'yes' ? collateral.floor : '';
			req.FLAG1                   = '';
			req.FLAG2                   = '';
			req.FLAG3                   = '';
			req.FLAT_PLOT_NUMBER        = '';
			req.HOUSE_NUMBER            = collateral.housePlotNo;
			req.LOCALITY                = '';
			req.LOANAPPLICATION_ID      = '';
			req.LOAN_TYPE               = '';
			req.MARKETVALUE             = collateral.marketValue!=null ? String.valueOf(collateral.marketValue) : '';
			req.PROJECT_ID              = '';//collateral.apfValue.toLowerCase() == 'yes' ? collateral.projId : '';
			req.PROJECT_NAME            = collateral.apfValue.toLowerCase() == 'yes' ? collateral.projName : '';
			req.PROPERTY_ID             = '';
			req.PROPERTY_NATURE         = '';
			req.PROPERTY_STATUS         = '';
			req.PROPERTY_TYPE           = collateral.unitType;
			req.REGION_THESIL           = collateral.block;
			req.SOURCE_SYSTEM           = 'SALESFORCE';
			req.STATE                   = collateral.state;
			req.SURVEY_NUMBER           = String.isNotBlank(collateral.surveyNumber) ? collateral.surveyNumber : '';
			req.TOWER_NAME              = collateral.apfValue.toLowerCase() == 'yes' ? collateral.towerName : '';
			req.UTILITY_TYPE            = '';
			req.PINCODE                 = collateral.pincode;

			/*if (collateral.apfValue == 'No') {
				req.PROFILE_ID  = '2';
			} else {
				req.PROFILE_ID    = '1';
			}*/

			String requestJSON = JSON.serialize(req);
			System.debug('Request Json---' + requestJSON);
			return requestJSON;

		} catch (Exception ex) {
			System.debug('Error in constructPayload: ' + ex.getMessage());
			throw new AuraHandledException('Failed to construct payload: ' + ex.getMessage());
		}
	}

	public class FindPropertyRequestWrapper {
		public String UNIQUEREQUEST_ID;
		public String PROFILE_ID;
		public String EXTERNAL_ID;
		public String LANREFERENCE_NO;
		public String ADDRESS;
		public String ADDRESS_1;
		public String ADDRESS_2;
		public String ADDRESS_3;
		public String ADDRESS_TYPE;
		public String AFFORDABLE;
		public String APF_NONAPF;
		public String APF_NUMBER;
		public String ASSIGNMENT_PERCENTAGE;
		public String BUILDER_ID;
		public String BUILDER_NAME;
		public String COLLATERAL_TYPE;
		public String CONSTRUCTION_TYPE;
		public String CERSAINUMBER;
		public String CIF_NUMBER;
		public String DISTRICT_CITY;
		public String DOCUMENTEDVALUE;
		public String ENTITY_NAME;
		public String EXTENT_OF_BUILTUP_AREA;
		public String EXTENT_OF_LAND;
		public String FLOOR_NUMBER;
		public String FLAG1 ;
		public String FLAG2 ;
		public String FLAG3;
		public String FLAT_PLOT_NUMBER;
		public String HOUSE_NUMBER;
		public String LOCALITY;
		public String LOANAPPLICATION_ID;
		public String LOAN_TYPE;
		public String MARKETVALUE;
		public String PROJECT_ID;
		public String PROJECT_NAME;
		public String PROPERTY_ID;
		public String PROPERTY_NATURE;
		public String PROPERTY_STATUS;
		public String PROPERTY_TYPE;
		public String REGION_THESIL;
		public String SOURCE_SYSTEM;
		public String STATE;
		public String SURVEY_NUMBER;
		public String TOWER_NAME;
		public String UTILITY_TYPE;
		public String PINCODE;
		public String UNIT_NUMBER;
	}
	
}