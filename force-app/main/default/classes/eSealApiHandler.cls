/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-10-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class  eSealApiHandler implements IntegrationInterface {
public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) {
    String loanApplicationId = wrapper.loanApplicationId;
    List<String> errorMessages = new List<String>();
    
    if (String.isBlank(loanApplicationId)) {
        errorMessages.add('Error: loanApplicationId is missing');
        return errorMessages;
    }
    List<Opportunity> loanApplications = [
        SELECT Id, E_seal_Colour__c, E_seal_Inner_Name__c, E_Seal_Outer_Name__c, E_seal_Shape__c 
        FROM Opportunity 
        WHERE Id = :loanApplicationId
    ];
    if (loanApplications.isEmpty()) {
        errorMessages.add('Error: No Loan_Application__c found with the provided ID.');
        return errorMessages;
    }
    Opportunity loanApp = loanApplications[0];
    // Check if each field is blank or null, use String.isBlank for text fields
    if (String.isBlank(loanApp.E_seal_Colour__c)) {
        errorMessages.add('Error: No E_seal_Colour__c found for Loan');
    }
    if (String.isBlank(loanApp.E_seal_Inner_Name__c)) {
        errorMessages.add('Error: No E_seal_Inner_Name__c found for Loan');
    }
    if (String.isBlank(loanApp.E_Seal_Outer_Name__c)) {
        errorMessages.add('Error: No E_Seal_Outer_Name__c found for Loan');
    }
    if (String.isBlank(loanApp.E_seal_Shape__c)) {
        errorMessages.add('Error: No E_seal_Shape__c found for Loan');
    }
    return errorMessages;
}
public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
    try {
        String loanApplicationId = wrapper.loanApplicationId;

        // Query Loan_Application__c, not Opportunity
        Opportunity loanApplication = [
            SELECT Id, E_seal_Colour__c, E_seal_Inner_Name__c, E_Seal_Outer_Name__c, E_seal_Shape__c 
            FROM Opportunity 
            WHERE Id = :loanApplicationId
            LIMIT 1
        ];
        // Create a Map to build JSON payload dynamically
        Map<String, Object> payloadMap = new Map<String, Object>();
        payloadMap.put('outerName', loanApplication.E_Seal_Outer_Name__c);
        payloadMap.put('innerName', loanApplication.E_seal_Inner_Name__c);
        payloadMap.put('color', loanApplication.E_seal_Colour__c);
        payloadMap.put('shape', loanApplication.E_seal_Shape__c);
        // Serialize the map to JSON string
        String requestJSON = JSON.serialize(payloadMap);
        return requestJSON;
    } catch (Exception exp) {
        System.debug('Exception: ' + exp.getMessage());
        throw new AuraHandledException('An error occurred: ' + exp.getMessage());
    }
}



}