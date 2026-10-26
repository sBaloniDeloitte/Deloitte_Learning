public class HL_CallApfBuilderHandler {
	public static void CallAPFBuilderInsertAPI(String BuilderID)
    {
        Map<String,String> inputMap = new Map<String,String>();
		List<Builder__c> lstBuilder = [select  name , Segmentation__c, Record_Status__c, Exposure_Limit_On_Amount__c,
                   		Exposure_Limit_On_No_Of_Units__c, Pincode_Master__r.City__c,Pincode_Master__r.City__r.City_Code__c ,
                      	Pincode_ID__c,Pincode_Master__r.City__r.State__c, Pincode_Master__r.Name from Builder__c where
                       	id=:BuilderID];

        inputMap.put('opr','insert');
        Hl_ApfBuilderHandler.initiateApfBuilderCallout(inputMap,lstBuilder);
        //System.debug('Output::'+s);
    }
    public static void CallAPFBuilderUpdateAPI(String BuilderID)
    {
        Map<String,String> inputMap = new Map<String,String>();
		List<Builder__c> lstBuilder = [select  name , Segmentation__c, Record_Status__c, Exposure_Limit_On_Amount__c,
                   		Exposure_Limit_On_No_Of_Units__c, Pincode_Master__r.City__c,Pincode_Master__r.City__r.City_Code__c ,
                      	Pincode_ID__c,Pincode_Master__r.City__r.State__c, Pincode_Master__r.Name from Builder__c where
                       	id=:BuilderID];

        inputMap.put('opr','update');
        Hl_ApfBuilderHandler.initiateApfBuilderCallout(inputMap,lstBuilder);
       // System.debug('Output::'+s);
    }
}