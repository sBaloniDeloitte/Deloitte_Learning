public with sharing class UdhyamRegistartionCheckHandler implements IntegrationInterface{
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        
        if(wrapper.registrationNo== null){
            errorMessages.add('Udhyam regisration number is not added');
        }

        //no validations
        return errorMessages;
    }

    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings){
        String request;
        UdhyamRegistartionCheckRequestWrapper requestWrap = new UdhyamRegistartionCheckRequestWrapper();
        
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

            requestWrap.isPDFRequired= consent;
            requestWrap.getEnterpriseDetails= consent;
            requestWrap.udyamRegistrationNo= wrapper.registrationNo;
            requestWrap.consent= consent;

            Cls_ClientDataWrapper clientDataRequest = new Cls_ClientDataWrapper();
            clientDataRequest.caseId = caseId;

            requestWrap.clientData = clientDataRequest;
            String requestJSON = JSON.serialize(requestWrap);
            return requestJSON;
        } catch (Exception exp) {
            
        }
        return request;
    }

    public class UdhyamRegistartionCheckRequestWrapper{
        public String consent { get; set; }
        public String udyamRegistrationNo { get; set; }
        public String isPDFRequired { get; set; }
        public String getEnterpriseDetails { get; set; }
        public Cls_ClientDataWrapper clientData { get; set; }
    }

    public class Cls_ClientDataWrapper {
        public String caseId { get; set; }
    }
}