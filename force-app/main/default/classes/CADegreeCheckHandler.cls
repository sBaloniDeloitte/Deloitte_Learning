public with sharing class CADegreeCheckHandler implements IntegrationInterface{
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        
        if(wrapper.registrationNo== null){
            errorMessages.add('Membership number is not added'); 
        }

        return errorMessages;
    }

    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings){
        String request;
        CADegreeCheckRequestWrapper requestWrap = new CADegreeCheckRequestWrapper();

        try {
            Map<String, List<Integration_Mapping__mdt>> groupByMap = new Map<String, List<Integration_Mapping__mdt>>();
            
            List<Integration_Mapping__mdt> integrationMappings = [SELECT id, API_Name__c, GroupBy__c, Source_Value__c, Target_Value__c 
                                                                FROM Integration_Mapping__mdt];
        
            for (Integration_Mapping__mdt mapping : integrationMappings) {
                if (!groupByMap.containsKey(mapping.GroupBy__c)) {
                    groupByMap.put(mapping.GroupBy__c, new List<Integration_Mapping__mdt>());
                }
                groupByMap.get(mapping.GroupBy__c).add(mapping);
            }

            String caseId = '';
            String consent ='';
            if (groupByMap.containsKey('caseId')) {
                for (Integration_Mapping__mdt mapping : groupByMap.get('caseId')) {
                    if (mapping.Source_Value__c == '0001') {
                        caseId = mapping.Target_Value__c;
                        break; 
                    }
                }
            }
            if (groupByMap.containsKey('consent')) {
                for (Integration_Mapping__mdt mapping : groupByMap.get('consent')) {
                    if (mapping.Source_Value__c == 'Y') {
                        consent = mapping.Target_Value__c;
                        break; 
                    }
                }
            }

            requestWrap.contactDetails= false;
            requestWrap.membership_no= wrapper.registrationNo;
            requestWrap.consent= consent;

            ClientRequestDataWrapper clientDataRequest = new ClientRequestDataWrapper();
            clientDataRequest.caseId = caseId;

            requestWrap.clientData = clientDataRequest;
            String requestJSON = JSON.serialize(requestWrap);
            return requestJSON;
        } catch (Exception ex) {
            
        }
        return request;
    }

    public class CADegreeCheckRequestWrapper{
        public String membership_no { get; set; }
        public Boolean contactDetails { get; set; }
        public String consent { get; set; }
        public ClientRequestDataWrapper clientData { get; set; }        
    }

    public class ClientRequestDataWrapper {
        public String caseId { get; set; }
    }
}