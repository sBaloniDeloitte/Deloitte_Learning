public with sharing class ContentDocumentTriggerHelper implements ITriggerHandler{
	Boolean isTriggerDisabled = false;
    public static void beforeInsert(List<SObject> newList){
        /*
        List<ContentDocumentLink> newRecords = (List<ContentDocumentLink>)newList;
        List<Id> insertedIds = new List<Id>();
        for(ContentDocumentLink cdl : newRecords){
            insertedIds.add(cdl.ContentDocumentId);
        }
        if(insertedIds.size() > 0) {
            List<ContentDocumentLink> cdlInserted = [Select Id, LinkedEntity.Name, ContentDocumentId, ContentDocument.FileType from ContentDocumentLink where ContentDocumentId in: insertedIds];
        for(ContentDocumentLink cdl : cdlInserted){
            for(ContentDocumentLink newCdl : newRecords){
                if(newCdl.Id == cdl.Id){
                    if(cdl.LinkedEntity.Name == '12 months bank statement' && cdl.ContentDocument.FileType != 'PDF'){
                        //newCdl.addError('12 months Bank Statement should only be of type PDF');
                    }
                }
            }
        }
        }*/
        
    }
    public static void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
        List<ContentDocumentLink> newRecords = (List<ContentDocumentLink>)newList;
        Map<Id,ContentDocumentLink> oldRecords = (Map<Id,ContentDocumentLink>)oldItems;
        List<Id> updatedIds = new List<Id>();
        for(ContentDocumentLink cdl : newRecords){
            updatedIds.add(cdl.ContentDocumentId);
        }
        if(updatedIds.size() > 0) {
            List<ContentDocumentLink> cdlUpdateded = [Select Id, LinkedEntity.Name, ContentDocumentId, ContentDocument.FileType from ContentDocumentLink where ContentDocumentId in: updatedIds];
        for(ContentDocumentLink cdl : cdlUpdateded){
            for(ContentDocumentLink newCdl : newRecords){
                if(newCdl.Id == cdl.Id){
                    if(cdl.LinkedEntity.Name == '12 months bank statement' && cdl.ContentDocument.FileType != 'PDF'){
                        newCdl.addError('12 months Bank Statement should only be of type PDF');
                    }
                }
            }
        }
        }
        
    }
    public static void afterInsert(List<SObject> newList, Map<Id, SObject> newMap){
        List<ContentDocumentLink> newRecords = (List<ContentDocumentLink>)newList;
        List<Id> insertedIds = new List<Id>();
        for(ContentDocumentLink cdl : newRecords){
            insertedIds.add(cdl.ContentDocumentId);
        }
        if(insertedIds.size() > 0) {
            List<ContentDocumentLink> cdlInserted = [Select Id, LinkedEntity.Name, ContentDocumentId, ContentDocument.FileType from ContentDocumentLink where ContentDocumentId in: insertedIds];
        for(ContentDocumentLink cdl : cdlInserted){
            for(ContentDocumentLink newCdl : newRecords){
                if(newCdl.Id == cdl.Id){
                    if(cdl.LinkedEntity.Name == '12 months bank statement' && cdl.ContentDocument.FileType != 'PDF'){
                        newCdl.addError('12 months Bank Statement should only be of type PDF');
                    }
                }
            }
        }
        }
        
    }
    public static void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){        
        List<ContentDocumentLink> newRecords = (List<ContentDocumentLink>)newList;
        Map<Id, ContentDocumentLink> oldMap = (Map<Id, ContentDocumentLink>)oldItems;
    }
    public static void afterDelete( List<SObject> oldList, Map<Id, SObject> oldItems){}
 
    public static void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap){}
    public static void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems){
    }
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
}