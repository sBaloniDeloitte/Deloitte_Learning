/*
* Created By : Romesh Somani
* Created Date : 06/11/2024
* Purpose : Interface that serves as template for every trigger events.
*/

public interface ITriggerHandler {

	void beforeInsert(List<SObject> newList); 
 
    void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems);
 
    void beforeDelete(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems); 
 
    void afterInsert(List<SObject> newList, Map<Id, SObject> newMap);
 
    void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldItems);
 
    void afterDelete( List<SObject> oldList, Map<Id, SObject> oldItems);
 
    void afterUndelete(List<SObject> newList, Map<Id, SObject> newMap);
 
    Boolean isDisabled();
}