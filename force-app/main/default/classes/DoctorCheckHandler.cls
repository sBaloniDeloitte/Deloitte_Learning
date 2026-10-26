public with sharing class DoctorCheckHandler implements IntegrationInterface{
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
    
        if(wrapper.councilName== null){
            errorMessages.add('Council name is not added');
        }
        if(wrapper.registrationNo== null){
            errorMessages.add('Registration number is not added');
        }
        if(wrapper.yearOfReg== null){
            errorMessages.add('Year of registration is not provided');
        }

        return errorMessages;
    }

    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings){
        String request;
        DoctorCheckRequestWrapper requestWrap = new DoctorCheckRequestWrapper();

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
                        //caseId = '123456';
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

            requestWrap.registrationNo= wrapper.registrationNo;
            requestWrap.yearOfReg= wrapper.yearOfReg;
            requestWrap.medicalCouncil= wrapper.councilName;
            requestWrap.consent= 'Y';

            ClientDataRequestWrapper clientDataRequest = new ClientDataRequestWrapper();
            clientDataRequest.caseId = caseId;

            requestWrap.clientData = clientDataRequest;
            String requestJSON = JSON.serialize(requestWrap);
            return requestJSON;
        } catch (Exception ex) {
            
        }

        return request;
    }

    public class DoctorCheckRequestWrapper{
        public String registrationNo { get; set; }
        public String yearOfReg { get; set; }
        public String medicalCouncil { get; set; }
        public String consent { get; set; }
        public ClientDataRequestWrapper clientData { get; set; }
    }

    public class ClientDataRequestWrapper {
        public String caseId { get; set; }
    }

    
}