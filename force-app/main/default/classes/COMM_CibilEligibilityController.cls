public with sharing class COMM_CibilEligibilityController {
    public class ResponseWrapper{
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String fieldValue;
        @AuraEnabled public Boolean isSectionSeperator;
        @AuraEnabled public String sectionSeperatorName;
        @AuraEnabled public String colourName;
        @AuraEnabled public boolean isGreen;
        @AuraEnabled public boolean isRed;
        @AuraEnabled public boolean isBlank ;

    }
    @AuraEnabled
    public static List<ResponseWrapper> getScreenFieldData(String screenName, Id applicantId) {
        List<ResponseWrapper> respList = new List<ResponseWrapper>();
        List<Screen_Field__c> screenFields = [
            SELECT Field_Label__c, Read_Field_Name__c, Condition__c,Section_Seperator__c,Section_Name__c
            FROM Screen_Field__c
            WHERE Screen_Name__c = :screenName and Is_Active__c = true
            ORDER BY Field_Sequence__c ASC
        ];
        Map<String,Screen_Field__c> readFieldToLabelMap = new Map<String,Screen_Field__c>();
        for(Screen_Field__c sc : screenFields){
            readFieldToLabelMap.put(sc.Read_Field_Name__c,sc);
        }
        List<Integration_Details__c> intDetails  = [SELECT id,Response_JSON__c,Related_Record_Id__c,Name from Integration_Details__c where Name ='FICO cibil' AND Related_Record_Id__c=:applicantId order by createdDate Desc LIMIT 1];
        
        //when api is ready pass query from integration information with the help of applicantId and fetch the resposne and deserialize it
        FICOResponse ficoResponse = (FICOResponse) JSON.deserialize(intDetails[0].Response_JSON__c,  FICOResponse.class);
        System.debug('ficoResponse: '+ficoResponse.response.finalApprovalLevel);

        Set<String> fieldApiNames = new Set<String>();
        for (Screen_Field__c field : screenFields) {
            fieldApiNames.add(field.Read_Field_Name__c);
        }
        for(String str : fieldApiNames){
            for(FICOResponse.cls_calculatedVariables iter : ficoResponse.response.calculatedVariables){
                if(iter.fieldName == str){
                    ResponseWrapper rw = new ResponseWrapper();
                    rw.isBlank= true;
                    rw.isRed=false;
                    rw.isGreen=false;
                    rw.fieldLabel = readFieldToLabelMap.get(str).Field_Label__c;
                 
                    rw.fieldValue = iter.fieldValue.split(',')[0];
                    if(iter.fieldValue.contains(',')){
                         list<String> SplittedValues= iter.fieldValue.split(',');
                            if(SplittedValues[1].containsIgnoreCase('red')){
                                rw.colourName='red';
                                rw.isRed=true;
                                rw.isBlank= false;
                            }
                            else if(SplittedValues[1].containsIgnoreCase('green')){
                                rw.colourName='green';
                                rw.isGreen=true;
                                rw.isBlank= false;
                            }
                         }

                    
                    rw.isSectionSeperator=readFieldToLabelMap.get(str).Section_Seperator__c;
                    rw.sectionSeperatorName=readFieldToLabelMap.get(str).Section_Name__c;
                    respList.add(rw);
                    break;
                }
            }
        }
        return respList;
    }
}