public without sharing class ApplicantAddressTriggerHelper implements ITriggerHandler{
    Boolean isTriggerDisabled = false;

    public static void beforeInsert(List<SObject> newList){
        List<Applicant_Address__c> newRecords = (List<Applicant_Address__c>)newList;
        
        //validateDuplicates(newRecords, null);
        
        for(Applicant_Address__c itr : newRecords) {
            
            if(itr.Address_Type__c != null && itr.Address_Type__c == 'Permanent' && itr.Flag_PO_as_High__c == true) {
                itr.Address_Priority__c = '4';
            }
            if(itr.Address_Type__c != null && itr.Address_Type__c == 'Current' && itr.Flag_Current_Registred_as_Very_High__c == true) {
                itr.Address_Priority__c = '5';
            }
            if(itr.Address_Type__c != null && itr.Address_Type__c == 'Registered Office' && itr.Flag_Current_Registred_as_Very_High__c == true) {
                itr.Address_Priority__c = '5';
            }
            if(itr.Address_Type__c != null && itr.Address_Type__c == 'Business Operational' && itr.Flag_PO_as_High__c == true) {
                itr.Address_Priority__c = '2';
            }
            if(itr.Address_Type__c != null && (itr.Address_Type__c == 'Permanent'|| itr.Address_Type__c == 'Business Operational')){
                itr.Flag_Current_Registred_as_Very_High__c =false;
            }
            if(itr.Address_Type__c != null && (itr.Address_Type__c == 'Current'|| itr.Address_Type__c == 'Registered Office')){
                itr.Flag_PO_as_High__c=false;
            }
        }
    }
    
    public static void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
        List<Applicant_Address__c> newRecords = (List<Applicant_Address__c>)newList;
        
        //validateDuplicates(newRecords, oldItems);
        
        for(Applicant_Address__c itr : newRecords) {
            Applicant_Address__c oldObj = (Applicant_Address__c)oldItems.get(itr.Id);
            
            if(itr.Address_Type__c != null && itr.Address_Type__c == 'Permanent') {
                if(itr.Flag_PO_as_High__c == true){
                    itr.Address_Priority__c = '4';
                }else{
                    itr.Address_Priority__c = '';
                }
            }
            if(itr.Address_Type__c != null && itr.Address_Type__c == 'Current') {
                if(itr.Flag_Current_Registred_as_Very_High__c == true){
                    itr.Address_Priority__c = '5';
                }else{
                    itr.Address_Priority__c = '';
                }
            }
            if(itr.Address_Type__c != null && itr.Address_Type__c == 'Registered Office'  && itr.Address_Priority__c!= '3') {
                if(itr.Flag_Current_Registred_as_Very_High__c == true){
                    itr.Address_Priority__c = '5';
                }else{
                    itr.Address_Priority__c = '';
                }
            }
            if(itr.Address_Type__c != null && itr.Address_Type__c == 'Business Operational') {
                if(itr.Flag_PO_as_High__c == true){
                    itr.Address_Priority__c = '2';
                }else{
                    itr.Address_Priority__c = '';
                }
            }
            if(itr.Address_Type__c != null && (itr.Address_Type__c == 'Permanent'|| itr.Address_Type__c == 'Business Operational')){
                itr.Flag_Current_Registred_as_Very_High__c =false;
            }
            if(itr.Address_Type__c != null && (itr.Address_Type__c == 'Current'|| itr.Address_Type__c == 'Registered Office')){
                itr.Flag_PO_as_High__c=false;
            }

        }
        
    }

    /*private static void validateDuplicates(List<Applicant_Address__c> newRecords, Map<Id, SObject> oldItems) {
        Set<Id> applicantIds = new Set<Id>();
        
        for(Applicant_Address__c addr : newRecords) {
            if(addr.Applicant__c != null) {
                applicantIds.add(addr.Applicant__c);
            }
        }
        
        if(applicantIds.isEmpty()) {
            return;
        }
        
        List<Applicant_Address__c> existingAddresses = [
            SELECT Id, Applicant__c, Address_Type__c, Flag_PO_as_High__c, Flag_Current_Registred_as_Very_High__c
            FROM Applicant_Address__c
            WHERE Applicant__c IN :applicantIds
        ];
        
        Map<Id, Application_Applicant__c> applicantMap = new Map<Id, Application_Applicant__c>(
            [SELECT Id, Name FROM Application_Applicant__c WHERE Id IN :applicantIds]
        );
        
        Map<String, Set<Id>> poFlagMap = new Map<String, Set<Id>>();
        Map<String, Set<Id>> currentRegFlagMap = new Map<String, Set<Id>>();
        
        for(Applicant_Address__c existing : existingAddresses) {
            if(existing.Flag_PO_as_High__c == true && 
               (existing.Address_Type__c == 'Permanent' || existing.Address_Type__c == 'Business Operational')) {
                String flagKey = existing.Applicant__c + '-' + existing.Address_Type__c + '-PO';
                if(!poFlagMap.containsKey(flagKey)) {
                    poFlagMap.put(flagKey, new Set<Id>());
                }
                poFlagMap.get(flagKey).add(existing.Id);
            }
            
            if(existing.Flag_Current_Registred_as_Very_High__c == true &&
               (existing.Address_Type__c == 'Current' || existing.Address_Type__c == 'Registered Office')) {
                String flagKey = existing.Applicant__c + '-' + existing.Address_Type__c + '-CR';
                if(!currentRegFlagMap.containsKey(flagKey)) {
                    currentRegFlagMap.put(flagKey, new Set<Id>());
                }
                currentRegFlagMap.get(flagKey).add(existing.Id);
            }
        }
        
        for(Applicant_Address__c addr : newRecords) {
            if(addr.Applicant__c == null) {
                continue;
            }
            
            Applicant_Address__c oldAddr = oldItems != null ? (Applicant_Address__c)oldItems.get(addr.Id) : null;
            Application_Applicant__c applicant = applicantMap.get(addr.Applicant__c);
            String applicantName = applicant != null ? applicant.Name : 'Unknown';
            
            if(addr.Address_Type__c != null && addr.Flag_PO_as_High__c == true && 
               (addr.Address_Type__c == 'Permanent' || addr.Address_Type__c == 'Business Operational')) {
                
                Boolean isFlagChanging = (oldAddr == null || addr.Flag_PO_as_High__c != oldAddr.Flag_PO_as_High__c || 
                                         addr.Address_Type__c != oldAddr.Address_Type__c || addr.Applicant__c != oldAddr.Applicant__c);
                
                if(isFlagChanging) {
                    String flagKey = addr.Applicant__c + '-' + addr.Address_Type__c + '-PO';
                    if(poFlagMap.containsKey(flagKey)) {
                        Set<Id> existingIds = poFlagMap.get(flagKey);
                        Boolean isDuplicate = false;
                        for(Id existingId : existingIds) {
                            if(addr.Id != existingId) {
                                isDuplicate = true;
                                break;
                            }
                        }
                        if(isDuplicate) {
                            addr.addError('A high priority address of type "' + addr.Address_Type__c + '" already exists for applicant: ' + applicantName);
                        }
                    }
                }
            }
            
            if(addr.Address_Type__c != null && addr.Flag_Current_Registred_as_Very_High__c == true &&
               (addr.Address_Type__c == 'Current' || addr.Address_Type__c == 'Registered Office')) {
                
                Boolean isFlagChanging = (oldAddr == null || addr.Flag_Current_Registred_as_Very_High__c != oldAddr.Flag_Current_Registred_as_Very_High__c ||
                                         addr.Address_Type__c != oldAddr.Address_Type__c || addr.Applicant__c != oldAddr.Applicant__c);
                
                if(isFlagChanging) {
                    String flagKey = addr.Applicant__c + '-' + addr.Address_Type__c + '-CR';
                    if(currentRegFlagMap.containsKey(flagKey)) {
                        Set<Id> existingIds = currentRegFlagMap.get(flagKey);
                        Boolean isDuplicate = false;
                        for(Id existingId : existingIds) {
                            if(addr.Id != existingId) {
                                isDuplicate = true;
                                break;
                            }
                        }
                        if(isDuplicate) {
                            addr.addError('A very high priority address of type "' + addr.Address_Type__c + '" already exists for applicant: ' + applicantName);
                        }
                    }
                }
            }
        }
    }*/

    public static void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){

    } 

    public static void afterInsert(List<SObject> newList, Map<Id, SObject> newMap){
        List<Applicant_Address__c> newRecords = (List<Applicant_Address__c>)newList;
        Set<Id> applicantIds = new Set<Id>();
        for(Applicant_Address__c itr : newRecords){
            if(itr.Address_Type__c != null && itr.Address_Type__c == 'Registered Office' && itr.Applicant__c != null) {
                applicantIds.add(itr.Applicant__c);
            }
        }
        if(applicantIds.size()>0){
            Map<Id, Application_Applicant__c> applicantMap = new Map<Id, Application_Applicant__c>(
                [
                    SELECT Id, Customer_Profile__c
                    FROM Application_Applicant__c
                    WHERE Id IN :applicantIds
                ]
            );
            List<Applicant_Address__c> addressesToUpdate = new List<Applicant_Address__c>();
            for (Applicant_Address__c addr : newRecords) {
                Application_Applicant__c app = applicantMap.get(addr.Applicant__c);

                if (
                    addr.Address_Type__c == 'Registered Office' &&
                    app != null &&
                    app.Customer_Profile__c != null &&
                    app.Customer_Profile__c.toLowerCase().contains('salaried')
                ) {
                    addressesToUpdate.add(new Applicant_Address__c(
                        Id = addr.Id,
                        Address_Priority__c = '3'
                    ));
                }
            }

            if (!addressesToUpdate.isEmpty()) {
                update addressesToUpdate;
            }
        }
    }

    public static void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){        
        List<Applicant_Address__c> newRecords = (List<Applicant_Address__c>)newList;
        Set<Id> applicantIds = new Set<Id>();
        for(Applicant_Address__c itr : newRecords){
            if(itr.Address_Type__c != null && itr.Address_Type__c == 'Registered Office' && itr.Applicant__c != null) {
                applicantIds.add(itr.Applicant__c);
            }
        }
        if(applicantIds.size()>0){
            Map<Id, Application_Applicant__c> applicantMap = new Map<Id, Application_Applicant__c>(
                [
                    SELECT Id, Customer_Profile__c
                    FROM Application_Applicant__c
                    WHERE Id IN :applicantIds
                ]
            );
            List<Applicant_Address__c> addressesToUpdate = new List<Applicant_Address__c>();
            for (Applicant_Address__c addr : newRecords) {
                Application_Applicant__c app = applicantMap.get(addr.Applicant__c);

                if (
                    addr.Address_Type__c == 'Registered Office' &&
                    app != null &&
                    app.Customer_Profile__c != null &&
                    app.Customer_Profile__c.toLowerCase().contains('salaried')
                ) {
                    addressesToUpdate.add(new Applicant_Address__c(
                        Id = addr.Id,
                        Address_Priority__c = '3'
                    ));
                }
            }

            if (!addressesToUpdate.isEmpty()) {
                update addressesToUpdate;
            }
        }
    }
    public static void afterDelete( List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public static void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap){}
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}