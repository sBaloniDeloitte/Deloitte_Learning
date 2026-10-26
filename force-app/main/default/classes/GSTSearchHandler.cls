public class GSTSearchHandler implements IntegrationInterface {
public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String panNumber = wrapper.panNumber;
        if (String.isEmpty(panNumber)) {
                errorMessages.add('Error: Missing PAN number.');
        }        
        return errorMessages;
    }
    
    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();
        
        try {
            system.debug('are we inside construct??');
            String panNumber = wrapper.panNumber;
            String body = JSON.serialize(new Map<String, String>{
                'pan' => panNumber,
                    'consent' => 'Y',
                    'needkarza' => 'N'
                    });
            
            
            return body;
            
        } catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'GSTSearchHandler', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
        
    }
}