public with sharing class FetchMCAHandler implements IntegrationInterface {

    // ✅ Only CIN validation
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        if (String.isBlank(wrapper.cin)) {
            errorMessages.add('CIN is not provided');
        }
        return errorMessages;
    }

    // ✅ Build minimal payload
    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
            FetchMCAWrapper requestWrap = new FetchMCAWrapper();
            system.debug('wrapper.applicantId--16--'+wrapper.applicantId);
            // Hardcoded values (can be dynamic if needed later)
            requestWrap.consent = 'Y';
            requestWrap.cin = wrapper.cin;

            ClientDataRequestWrapper clientData = new ClientDataRequestWrapper();
            clientData.caseId = wrapper.applicantId; 
            requestWrap.clientData = clientData;

            // Return JSON
            return JSON.serialize(requestWrap);
        } catch (Exception ex) {
            System.debug('❌ Error constructing FetchMCA payload: ' + ex.getMessage());
            return null;
        }
    }

    // ✅ Final Payload Classes
    public class FetchMCAWrapper {
        public String consent { get; set; }
        public String cin { get; set; }
        public ClientDataRequestWrapper clientData { get; set; }
    }

    public class ClientDataRequestWrapper {
        public String caseId { get; set; }
    }
}