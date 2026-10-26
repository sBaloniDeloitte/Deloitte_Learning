public with sharing class COMM_GetFinanceDetailsByUCICController {

    @AuraEnabled
    public static List<Finance> getCustomerFinances(String customerId, String processName) {
        try {
            // Fetch integration settings
            List<Integration_Settings__c> intSettingList = [
                SELECT Client_Id__c, Message_Id__c, Entity_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                FROM Integration_Settings__c
                WHERE Name = :processName
                LIMIT 1
            ];
            Integration_Settings__c intSetting = intSettingList[0];
			Map<String, String> requestBodyMap = new Map<String, String>();
				requestBodyMap.put('coreBankID', '');
				requestBodyMap.put('cif', customerId);
			String requestBodyJSON = JSON.serialize(requestBodyMap);
            // Prepare API request map
            Map<String, String> integrationRequestMap = new Map<String, String>();
			String bearer = Utility.getAccessToken();
            integrationRequestMap.put('bearer', bearer);
            integrationRequestMap.put('intSettingName', processName);
            integrationRequestMap.put('endPoint', intSetting.Endpoint__c);
            integrationRequestMap.put('serviceName', 'getFinanceDetailsByUCICorCIF');
            integrationRequestMap.put('MESSAGEID', intSetting.Message_Id__c);
            integrationRequestMap.put('ENTITYID', intSetting.Entity_Id__c);
            integrationRequestMap.put('ServiceVersion', '1');
            integrationRequestMap.put('RequestTime', String.valueOf(DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss')));
            integrationRequestMap.put('Language', 'EN');
			integrationRequestMap.put('requestJSON',requestBodyJSON);

            // Call API
            HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
            System.debug('responseJSON -->' + resp.getBody());

            // Check status code and body
            if(resp.getStatusCode() == 200 && !String.isBlank(resp.getBody())) {
				FinancialResponse fullResponse = (FinancialResponse) JSON.deserialize(resp.getBody(), FinancialResponse.class);
				System.debug('Full Response: ' + fullResponse);

				if(fullResponse.finances != null) {
					System.debug('Full financeList: ' + fullResponse.finances);
					return fullResponse.finances;
				} else {
					return new List<Finance>();
				}
			}
			else {
                System.debug('API returned non-200 or empty body. StatusCode: ' + resp.getStatusCode());
                return new List<Finance>();
            }

        } catch (Exception e) {
            System.debug('Error in getCustomerFinances: ' + e.getMessage());
            return new List<Finance>();
        }
    }

    // Wrapper classes
	public class FinancialResponse {
		@AuraEnabled public List<Finance> finances;
		//@AuraEnabled public List<Finance> CoApplicant;
		//@AuraEnabled public List<Finance> Gurantor;
		@AuraEnabled public ReturnStatus returnStatus;
	}

	public class Finance {
		@AuraEnabled public String finReference;
		@AuraEnabled public String coreBankID;
		@AuraEnabled public String cif;
		@AuraEnabled public Decimal finAmount;
		@AuraEnabled public Decimal emiAmount;
		@AuraEnabled public Decimal outstandingBal;
		@AuraEnabled public Decimal outstandingPri;
		@AuraEnabled public String status;
		@AuraEnabled public String finStatus;
		@AuraEnabled public String entityType;
		@AuraEnabled public String custShrtName;
		@AuraEnabled public String custDOB;
		@AuraEnabled public String custCtgCode;
		@AuraEnabled public String finType;
		@AuraEnabled public String finStartDate;
		@AuraEnabled public Integer noOfOdDays;
		@AuraEnabled public Integer noOfBounces;
		@AuraEnabled public String source;
	}

	public class ReturnStatus {
		@AuraEnabled public String returnCode;
		@AuraEnabled public String returnText;
	}

}