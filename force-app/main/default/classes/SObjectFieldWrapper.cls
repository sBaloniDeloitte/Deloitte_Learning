public without sharing class SObjectFieldWrapper {
    @AuraEnabled public String Label;
    @AuraEnabled public String Name;
    @AuraEnabled public String Type;
    @AuraEnabled public Boolean isPickList;
    @AuraEnabled public Boolean isTextArea;
    @AuraEnabled public Object Value;
    @AuraEnabled public PickListWrapper[] Option;

    public SObjectFieldWrapper(Schema.SObjectField fieldData,Object value){
        this.Label = fieldData.getDescribe().getLabel();
        this.Name = fieldData.getDescribe().getName();
        this.Type = fieldData.getDescribe().getType().name();
        this.Value = value;
        this.setTypeParameter(fieldData);
    }

    public void setTypeParameter(Schema.SObjectField fieldData){
        switch on this.Type {
            when 'PICKLIST' {
                this.isPickList = true;
                this.setPickListValues(fieldData.getDescribe().getPicklistValues());
            }
            when 'TESTAREA' {
                this.isTextArea = true;
            }
            when else {
                
            }
        }
    }

    public void setPickListValues(List<Schema.PicklistEntry> pickValues){
        this.Option = new List<PickListWrapper>();
        for(Schema.PicklistEntry pickValue : pickValues){
            if(pickValue.isActive()){
                this.Option.add(new PickListWrapper(pickValue.getLabel(),pickValue.getValue()));
            }
        }
    }

    public class PickListWrapper{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public PickListWrapper(String label,String value){
            this.label = label;
            this.value = value;
        }

    }
}