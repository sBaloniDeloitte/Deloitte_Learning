/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-28-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class FSSAITableData {
    @AuraEnabled
    // (cacheable=true)
    public static List<FSSAIAPIController.cls_result> parseMultipleResponses(String loanId, String Name) {
        List<FSSAIAPIController.cls_result> responseList = new List<FSSAIAPIController.cls_result>();
        
        // Query all records that match Loan ID & Name
        List<Integration_Details__c> idcRecords = [
            SELECT Id, Response_JSON__c FROM Integration_Details__c 
            WHERE Loan_Application__c = :loanId AND Name = :Name AND Status__c = '200'
        ];

        // Loop through records & parse JSON
        for (Integration_Details__c record : idcRecords) {
            if (String.isNotBlank(record.Response_JSON__c)) {
                try {
                    FSSAIAPIController.FSSAIResponseWrap parsedResponse = 
                    (FSSAIAPIController.FSSAIResponseWrap) System.JSON.deserialize(record.Response_JSON__c, FSSAIAPIController.FSSAIResponseWrap.class);

                    Integer statusCode= parsedResponse.status_code;
                    if(statusCode == 101){
                        responseList.add(parsedResponse.result);
                    }
                    
                    System.debug('responseList '+responseList);
                } catch (Exception e) { 
                    System.debug('Error parsing JSON: ' + e.getMessage());
                }
            }
        }

        return responseList;
    }
    @AuraEnabled
    public static Boolean checkIfAlreadyFetch(String loanId, String fssaiNumber) {
        Boolean isCalled = false;
        List<Integration_Details__c> idcRecords = [
            SELECT Id, Response_JSON__c FROM Integration_Details__c 
            WHERE Loan_Application__c = :loanId AND Name = 'FSSAI' AND Status__c = '200'
        ];
        for (Integration_Details__c record : idcRecords) {
            if (String.isNotBlank(record.Response_JSON__c)) {
                try {
                    FSSAIAPIController.FSSAIResponseWrap parsedResponse = (FSSAIAPIController.FSSAIResponseWrap) System.JSON.deserialize(record.Response_JSON__c, FSSAIAPIController.FSSAIResponseWrap.class);
                    
                    if(parsedResponse.result.LicNO == fssaiNumber) {
                        isCalled = true;
                        break;
                    }
                } catch (Exception e) { 
                    System.debug('Error parsing JSON: ' + e.getMessage());
                }
            }
        }
        return isCalled;

    }
}