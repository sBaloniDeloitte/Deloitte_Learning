public class IncomeEligibilityCalculatorController {
	public class ResponseWrapper{
		@AuraEnabled public String fieldLabel;
		@AuraEnabled public String fieldValue;
		@AuraEnabled public Boolean isHeader;
	}
	@AuraEnabled
	public static List<ResponseWrapper> getIncomeTableData(String loanId, String tableName){
		List<ResponseWrapper> respList = new List<ResponseWrapper>();
		ResponseWrapper resp = new ResponseWrapper();
		resp.fieldLabel = 'Final Program Chosen - HL/BT';
		resp.fieldValue = tableName;
		resp.isHeader = true;
		respList.add(resp);
		Map<String,String> labelToFieldMap = new Map<String,String>();
		labelToFieldMap.put('Final Monthly Eligible Income','Final_Monthly_Eligible_Income__c');
		labelToFieldMap.put('Final Monthly Obligation Considered','Final_Monthly_Obligation_Considered__c');
		labelToFieldMap.put('Max Outflow Allowed','Max_Outflow_Allowed__c');
		labelToFieldMap.put('Available for Proposed Loan','Available_for_Proposed_Loan__c');
		labelToFieldMap.put('Final Loan basis FOIR','Final_Loan_basis_FOIR__c');
		labelToFieldMap.put('Final Loan capped by Ind Type','Final_Loan_capped_by_Ind_Type__c');
		labelToFieldMap.put('Final Eligible Loan','Final_Eligible_Loan__c');
		List<Income_Assessment__c> incmList = [Select Id, Final_Monthly_Eligible_Income__c, Final_Monthly_Obligation_Considered__c, Max_Outflow_Allowed__c, 
												Available_for_Proposed_Loan__c, Final_Loan_basis_FOIR__c, Final_Loan_capped_by_Ind_Type__c, Final_Eligible_Loan__c
												from Income_Assessment__c where Loan_Application__c =: loanId and RecordType.Name =: tableName limit 1];
		if(!incmList.isEmpty()){
			for(String str: labelToFieldMap.keySet()){
				ResponseWrapper iterResp = new ResponseWrapper();
				iterResp.fieldLabel = str;
				iterResp.isHeader = false;
				if(incmList[0].get(labelToFieldMap.get(str)) != null){
					iterResp.fieldValue = String.valueOf(incmList[0].get(labelToFieldMap.get(str)));
				}
				else{
					iterResp.fieldValue = '-';
				}
				respList.add(iterResp);
			}
		}
		return respList;
	}
	
}