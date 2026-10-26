/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-12-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class FinalEligibilityFieldsController {
	public static Map<String,List<String>> labelToFieldMapping = new Map<String,List<String>>();

	static {
		labelToFieldMapping.put('Base Rate / Margin (PLR)', new List<String>{'PLR_Code__c','PLR_Value__c'});
		labelToFieldMapping.put('Effective Margin', new List<String>{'Margin__c',''});
		labelToFieldMapping.put('Final Loan Amount', new List<String>{'Final_Loan_Amount__c','Sanctioned_Loan_Amount__c'});
		labelToFieldMapping.put('Rate of Interest', new List<String>{'HL_Rate_of_Interest__c','Sanctioned_ROI__c'});
		labelToFieldMapping.put('Full EMI Tenure', new List<String>{'HL_Tenor_in_months__c','Sanctioned_Tenor__c'});
		labelToFieldMapping.put('Final EMI', new List<String>{'HL_Final_EMI__c','EMI_Amount__c'});
		labelToFieldMapping.put('Final FOIR', new List<String>{'HL_Final_FOIR__c','HL_Final_FOIRSanctioned_Terms__c'});
		labelToFieldMapping.put('Additional FOIR', new List<String>{'','Additional_Foir__c'});
		labelToFieldMapping.put('Final LTV', new List<String>{'HL_Final_LTV__c','HL_Final_LTVSanctioned_Terms__c'});
		labelToFieldMapping.put('Maximum LTV as per Policy', new List<String>{'HL_Maximum_LTV__c',''});
		labelToFieldMapping.put('Maximum Loan Eligibility basis LTV', new List<String>{'HL_Maximum_Loan_Eligibility_basis_LTV__c','HL_Maximum_LoanEligibility_LTV_st__c'});
		labelToFieldMapping.put('Maximum Loan Eligibility basis Income', new List<String>{'HL_Maximum_Loan_Eligibility_basis_Income__c','HL_Maximum_Loan_EligibilityIncomeSt__c'});
	}
	public static Map<String,List<String>> labelToFieldMappingIncomeCalculator = new Map<String,List<String>>();

	static {
		labelToFieldMappingIncomeCalculator.put('Base Rate / Margin (PLR)', new List<String>{'PLR_Code__c','PLR_Value__c'});
		labelToFieldMappingIncomeCalculator.put('Effective Margin', new List<String>{'Margin__c',''});
		labelToFieldMappingIncomeCalculator.put('Final Loan Amount', new List<String>{'Final_Loan_Amount_Income_Calculator__c','Sanctioned_Loan_Amount_Income_Calculator__c'});
		labelToFieldMappingIncomeCalculator.put('Rate of Interest', new List<String>{'HL_Rate_of_Interest_Income_Calculator__c','Sanctioned_ROI_Income_Calculator__c'});
		labelToFieldMappingIncomeCalculator.put('Full EMI Tenure', new List<String>{'HL_Tenor_in_months_Calculator__c','Sanctioned_Tenor_Income_Calculator__c'});
		labelToFieldMappingIncomeCalculator.put('Final EMI', new List<String>{'HL_FINAL_EMI_INCOME_CALCULATOR__c','EMI_Amount_Income_Calculator__c'});
		labelToFieldMappingIncomeCalculator.put('Final FOIR', new List<String>{'HL_Final_Foir_Income_Calculator__c','HL_Final_FOIRSanctioned_Terms_Income_Cal__c'});
		labelToFieldMappingIncomeCalculator.put('Additional FOIR', new List<String>{'','Additional_Foir__c'});
		labelToFieldMappingIncomeCalculator.put('Final LTV', new List<String>{'HL_Final_LTV_Income_Calculator__c','HL_Final_LTVSanctioned_Terms_Income_Calc__c'});
		labelToFieldMappingIncomeCalculator.put('Maximum LTV as per Policy', new List<String>{'HL_Maximum_LTV_Income_Calculator__c',''});
		labelToFieldMappingIncomeCalculator.put('Maximum Loan Eligibility basis LTV', new List<String>{'HL_Maximum_Loan_Eligibility_LTV_Calc__c','HL_Maximum_LoanEligibility_LTV_Income_C__c'});
		labelToFieldMappingIncomeCalculator.put('Maximum Loan Eligibility basis Income', new List<String>{'HL_Maximum_Loan_Eligibility_Income_Calc__c','HL_Maximum_Loan_EligibilityIncomeStCalc__c'});
		labelToFieldMappingIncomeCalculator.put('Max ABB EMI Ratio Allowed', new List<String>{'Max_ABB_EMI_Ratio_Allowed__c',''});
	}

	public static List<String> editableLabels = new List<String>{'Sanctioned_Loan_Amount__c','Sanctioned_ROI__c','Sanctioned_Tenor__c'};
	public static List<String> editableLabelsIncome = new List<String>{'Sanctioned_Loan_Amount_Income_Calculator__c','Sanctioned_ROI_Income_Calculator__c','Sanctioned_Tenor_Income_Calculator__c'};

	@AuraEnabled
	public static List<MainWrapper> fetchProductDetails(String productId,Boolean Calculator){
		List<MainWrapper> mwList = new List<MainWrapper>();

		String prodQuery = 'Select Id, Is_Final_Eligibility__c, Product__r.HL_Maximum_LTV_as_per_Policy_1__c, Product__r.HL_Maximum_LTV_as_per_Policy_2__c, Product__r.HL_Maximum_LTV_as_per_Policy_3__c ';
		
		for(String str : labelToFieldMapping.keySet()){
			List<String> fieldList;
			if(Calculator){
				fieldList = labelToFieldMappingIncomeCalculator.get(str);
			}
			else{
				fieldList = labelToFieldMapping.get(str);
			}

			for(String field : fieldList){
				System.debug('field: '+field);
				if(String.isNotBlank(field)){
					prodQuery = prodQuery +','+ field;
				}
			}
		}

		prodQuery = prodQuery+ ' From Product2 Where Product__c =: productId And RecordType.Name = \'Sub Product\' Limit 1';
		System.debug('prodQuery=: '+prodQuery);

		List<Product2> prodList = Database.query(prodQuery);
		decimal loanAmount;
        if(Calculator){
			loanAmount = prodList[0].get('Final_Loan_Amount_Income_Calculator__c') != null ? decimal.valueOf(String.valueOf(prodList[0].get('Final_Loan_Amount_Income_Calculator__c'))) : 0;
		}
		else{
			loanAmount = prodList[0].get('Final_Loan_Amount__c') != null ? decimal.valueOf(String.valueOf(prodList[0].get('Final_Loan_Amount__c'))) : 0;
		}

		decimal policyLTV;
		if(loanAmount < 3000000){
			policyLTV = prodList[0].getSObject('Product__r')?.get('HL_Maximum_LTV_as_per_Policy_1__c') != null ? Decimal.valueOf(String.valueOf(prodList[0].getSObject('Product__r')?.get('HL_Maximum_LTV_as_per_Policy_1__c'))) : 0;
		}
		else if(loanAmount >= 3000000 && loanAmount < 7500000){
			policyLTV = prodList[0].getSObject('Product__r')?.get('HL_Maximum_LTV_as_per_Policy_2__c') != null ? Decimal.valueOf(String.valueOf(prodList[0].getSObject('Product__r')?.get('HL_Maximum_LTV_as_per_Policy_2__c'))) : 0;
		}
		else if(loanAmount >= 7500000){
			policyLTV = prodList[0].getSObject('Product__r')?.get('HL_Maximum_LTV_as_per_Policy_3__c') != null ? Decimal.valueOf(String.valueOf(prodList[0].getSObject('Product__r')?.get('HL_Maximum_LTV_as_per_Policy_3__c'))) : 0;
		}

		Boolean isFinalEligibility = Boolean.valueOf(String.valueOf(prodList[0].get('Is_Final_Eligibility__c')));

		if(!Calculator){
			for(String str : labelToFieldMapping.keySet()){
				List<String> fieldList = labelToFieldMapping.get(str);
				MainWrapper mw = new MainWrapper();
				mw.fieldLabel = str;
				mw.userInput = new FieldWrapper();
				mw.breOutput = new FieldWrapper();
				mw.sanctionTermOutput = new FieldWrapper();
				mw.breOutput.fieldApiVal = '';
				mw.breOutput.isEditable = false;
				mw.sanctionTermOutput.fieldApiVal = '';
				mw.sanctionTermOutput.isEditable = false;
				mw.isSectionSeperator = false;
				mw.isFinalEligibility = isFinalEligibility;

				if(str == 'Base Rate / Margin (PLR)' || str == 'Maximum LTV as per Policy'){
					mw.isSectionSeperator = true;
					if(str == 'Base Rate / Margin (PLR)'){
						mw.sectionName = 'Final Amount';
					}
					else{
						mw.sectionName = 'Final Sanction';
					}
				}

				for(Integer i=0; i< fieldList.size(); i++){
					string value;
					mw.allowFractional = true;

					if(String.isNotBlank(fieldList[i])){
						value = String.valueOf(prodList[0].get(fieldList[i]));
					}

					if(value != null){
						value = Utility.isNumeric(value) ? String.valueOf(Decimal.valueOf(value).setScale(2)) : value;

						if(str == 'Full EMI Tenure' || str == 'Final Loan Amount'){
							mw.allowFractional = false;
							value = String.valueOf(Decimal.valueOf(value).setScale(0));
						}
					}

					if(i == 0){
						mw.breOutput.fieldApiName = fieldList[i];
						mw.breOutput.fieldApiVal = value;
					}
					else{
						mw.sanctionTermOutput.fieldApiName = fieldList[i];
						mw.sanctionTermOutput.fieldApiVal = value;
						
						if(editableLabels.contains(fieldList[i])){
							mw.sanctionTermOutput.isEditable = true;
						}

						mw.userInput.fieldApiName = mw.sanctionTermOutput.fieldApiName;
						mw.userInput.fieldApiVal = mw.sanctionTermOutput.fieldApiVal;
						mw.userInput.isEditable = mw.sanctionTermOutput.isEditable;

						if(str == 'Rate of Interest'){
							mw.sanctionTermOutput.isEditable = false;
						}
						else if(str == 'Full EMI Tenure'){
							mw.sanctionTermOutput.isEditable = false;
						}
					}

					if(str == 'Additional FOIR'){
						mw.userInput.isEditable = true;
					}
					else if(str == 'Effective Margin'){
						mw.sanctionTermOutput.fieldApiVal = '';
						mw.breOutput.fieldApiVal = '';
					}
					else if(str == 'Base Rate / Margin (PLR)'){
						mw.userInput.isEditable = true;
						mw.userInput.isPickListField = true;
						mw.sanctionTermOutput.fieldApiVal = '';
						mw.breOutput.fieldApiVal = '';
					}
					else if(str == 'Maximum LTV as per Policy'){
						mw.sanctionTermOutput.fieldApiVal = policyLTV.toString();
						mw.breOutput.fieldApiVal = '_';
						mw.userInput.fieldApiVal = policyLTV.toString();
					}
				}
				mwList.add(mw);
			}
		}
		else{
			for(String str : labelToFieldMappingIncomeCalculator.keySet()){
				List<String> fieldList = labelToFieldMappingIncomeCalculator.get(str);
				MainWrapper mw = new MainWrapper();
				mw.fieldLabel = str;
				mw.userInput = new FieldWrapper();
				mw.breOutput = new FieldWrapper();
				mw.sanctionTermOutput = new FieldWrapper();
				mw.breOutput.fieldApiVal = '';
				mw.breOutput.isEditable = false;
				mw.sanctionTermOutput.fieldApiVal = '';
				mw.sanctionTermOutput.isEditable = false;
				mw.isSectionSeperator = false;
				mw.isFinalEligibility = isFinalEligibility;

				if(str == 'Base Rate / Margin (PLR)' || str == 'Maximum LTV as per Policy'){
					mw.isSectionSeperator = true;
					if(str == 'Base Rate / Margin (PLR)'){
						mw.sectionName = 'Final Amount';
					}
					else{
						mw.sectionName = 'Final Sanction';
					}
				}

				for(Integer i=0; i< fieldList.size(); i++){
					string value;
					mw.allowFractional = true;

					if(String.isNotBlank(fieldList[i])){
						value = String.valueOf(prodList[0].get(fieldList[i]));
					}

					if(value != null){
						value = Utility.isNumeric(value) ? String.valueOf(Decimal.valueOf(value).setScale(2)) : value;

						if(str == 'Full EMI Tenure' || str == 'Final Loan Amount'){
							mw.allowFractional = false;
							value = String.valueOf(Decimal.valueOf(value).setScale(0));
						}
					}

					if(i == 0){
						mw.breOutput.fieldApiName = fieldList[i];
						mw.breOutput.fieldApiVal = value;
					}
					else{
						mw.sanctionTermOutput.fieldApiName = fieldList[i];
						mw.sanctionTermOutput.fieldApiVal = value;
						
						if(editableLabelsIncome.contains(fieldList[i])){
							mw.sanctionTermOutput.isEditable = true;
						}

						mw.userInput.fieldApiName = mw.sanctionTermOutput.fieldApiName;
						mw.userInput.fieldApiVal = mw.sanctionTermOutput.fieldApiVal;
						mw.userInput.isEditable = mw.sanctionTermOutput.isEditable;

						if(str == 'Rate of Interest'){
							mw.sanctionTermOutput.isEditable = false;
						}
						else if(str == 'Full EMI Tenure'){
							mw.sanctionTermOutput.isEditable = false;
						}
					}

					if(str == 'Additional FOIR'){
						mw.userInput.isEditable = true;
					}
					else if(str == 'Effective Margin'){
						mw.sanctionTermOutput.fieldApiVal = '';
						mw.breOutput.fieldApiVal = '';
					}
					else if(str == 'Base Rate / Margin (PLR)'){
						mw.userInput.isEditable = true;
						mw.userInput.isPickListField = true;
						mw.sanctionTermOutput.fieldApiVal = '';
						mw.breOutput.fieldApiVal = '';
					}
					else if(str == 'Maximum LTV as per Policy'){
						mw.sanctionTermOutput.fieldApiVal = policyLTV.toString();
						mw.breOutput.fieldApiVal = '_';
						mw.userInput.fieldApiVal = policyLTV.toString();
					}
				}
				mwList.add(mw);
			}
		}
		return mwList;
	}

	public class MainWrapper{
		@AuraEnabled public String fieldLabel;
		@AuraEnabled public FieldWrapper userInput;
		@AuraEnabled public FieldWrapper breOutput;
		@AuraEnabled public FieldWrapper sanctionTermOutput;
		@AuraEnabled public Boolean isSectionSeperator;
		@AuraEnabled public Boolean allowFractional;
		@AuraEnabled public String sectionName;
		@AuraEnabled public Boolean isFinalEligibility;
	}

	public class FieldWrapper{
		@AuraEnabled public String fieldApiName;
		@AuraEnabled public String fieldApiVal;
		@AuraEnabled public Boolean isEditable;
		@AuraEnabled public Boolean isPickListField;
	}
}