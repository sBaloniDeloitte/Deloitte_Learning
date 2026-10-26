/**
* @File Name : OpportunityUtility.cls
* @Description : This is a utility class for Opportunity trigger
* @Author : 
* @Last Modified By :
* @Last Modified On : March 27, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | March 27, 2025 |   | Initial Version
**/

public with sharing class OpportunityUtility {

	PRIVATE STATIC FINAL STRING loan_transaction_Object_Api_Name = Constants__mdt.getInstance('Loan_Transaction').value__c;
	PRIVATE STATIC FINAL STRING Loan_Details_Form_Name = Constants__mdt.getInstance('Loan_Details_Form_Name').value__c;
	PRIVATE STATIC STRING Fetch_Application_Date = Constants__mdt.getInstance('Fetch_Application_Date').Value__c;

	public static void createLoanTransaction(List<Opportunity> newOppList){
		try{
			List<Loan_Transaction__c> exitingLoanTransactionRecs = [SELECT Id FROM Loan_Transaction__c WHERE Loan_Application__c IN :newOppList AND Disbursement_Party__c !='VAS'];

			if(!exitingLoanTransactionRecs.isEmpty()){
				DELETE exitingLoanTransactionRecs;
			}

			List<Loan_Transaction__c> loanTransactionList = new List<Loan_Transaction__c>();
			Map<String,List<Screen_Field__c>> screenFieldMap = new Map<String, List<Screen_Field__c>>();
			for(Screen_Field__c scrnField : [SELECT Id, Form_Name__c ,Loan_Type__c, Parent_Screen__r.Form_Name__c, Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c, Filtered_Picklist_Values__c,
																Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,Section_Seperator__c,Section_Name__c,
																Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c, Read_Field_Name__c,Applicable_For__c,Picklist_Dependent_On_RecordType__c,
																Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c,Default_Value__c 
																FROM Screen_Field__c WHERE Is_Active__c = TRUE AND Parent_Screen__r.Is_Screen_Active__c = TRUE AND Form_Name__c = :Loan_Details_Form_Name AND Loan_Type__c != NULL AND Storage_Object__c = :loan_transaction_Object_Api_Name AND (Default_Value__c != NULL OR Storage_Field__c = 'Loan_Start_Date__c') order by Field_Sequence__c ASC]){
				if(screenFieldMap.containsKey(scrnField.Loan_Type__c)){
					screenFieldMap.get(scrnField.Loan_Type__c).add(scrnField);
				}else{
					screenFieldMap.put(scrnField.Loan_Type__c,new List<Screen_Field__c>{scrnField});
				}												
			}
			Map<Id,List<Product2>> loanAppProductMap = new Map<Id,List<Product2>>();
			Utility_V1.ProductWrapper prodWrapperRec = Utility_V1.getProductDetails(new Map<String,String>{'oppId' => newOppList[0].Id});
			if(prodWrapperRec != null && prodWrapperRec.isHLRelated ==true){
				List<Product2> mainProductList =[SELECT Id,Product_Type__c,RecordType.Name from Product2 WHERE RecordType.Name = 'Product' AND Loan_Application__c IN :newOppList AND Product_Type__c = 'Parent'];
				system.debug('mainProductList:: '+mainProductList + ' newOppList[0].Product__c ');
				List<Product2> subProductList = [SELECT Id from Product2 WHERE RecordType.Name = 'Sub Product' AND Product__c IN :mainProductList];
				List<Product2> productRecords = [SELECT Id,Product__r.PLR_Code__c, Product__r.PLR_Value__c,Product__r.Product__c,Product__r.Product__r.Name,Name,Loan_Application__c,Loan_Application__r.Sanction_Loan_Amount__c FROM Product2 WHERE Loan_Application__c IN :newOppList AND RecordType.DeveloperName = 'Sub_Variant' AND Product__c IN :subProductList];
				system.debug('subProduct:: '+subProductList + ' productRecords '+productRecords);
				for(Product2 product : productRecords){
					if(loanAppProductMap.containsKey(product.Loan_Application__c)){
						loanAppProductMap.get(product.Loan_Application__c).add(product);
					}
					else{
						loanAppProductMap.put(product.Loan_Application__c, new List<Product2>{product});
					}
				}
			}
			else{
				Product2 mainProduct =[SELECT Id from Product2 WHERE RecordType.Name = 'Product' AND Name = :newOppList[0].Product__c AND Loan_Application__c IN :newOppList LIMIT 1];
				system.debug('mainProduct:: '+mainProduct + ' newOppList[0].Product__c '+newOppList[0].Product__c);
				Product2 subProduct = [SELECT Id from Product2 WHERE RecordType.Name = 'Sub Product' AND Product__c =:mainProduct.Id LIMIT 1];
				List<Product2> productRecords = [SELECT Id,Product__r.PLR_Code__c, Product__r.PLR_Value__c,Product__r.Product__c,Product__r.Product__r.Name,Name,Loan_Application__c,Loan_Application__r.Sanction_Loan_Amount__c FROM Product2 WHERE Loan_Application__c IN :newOppList AND RecordType.DeveloperName = 'Variant' AND Product__c =:subProduct.Id  AND Loan_Application__c IN :newOppList LIMIT 1];
				system.debug('subProduct:: '+subProduct + ' productRecords '+productRecords);
				for(Product2 product : productRecords){
					loanAppProductMap.put(product.Loan_Application__c, new List<Product2>{product});
				}
			}

			Integration_Details__c integrationRecord = [SELECT Id,Business_Date__c FROM Integration_Details__c WHERE Name = :Fetch_Application_Date ORDER BY Createddate desc LIMIT 1];

			for(Opportunity opp : newOppList){
				for(Product2 itrProduct : loanAppProductMap.get(opp.Id)){
					Loan_Transaction__c loanTransaction = new Loan_Transaction__c();
					loanTransaction.Loan_Application__c = opp.Id;
					if(prodWrapperRec.isHLRelated ==true){
						loanTransaction.Product_Subvariant__c = itrProduct.Id;
						loanTransaction.Product__c = itrProduct.Product__r?.Product__c;
						loanTransaction.PLR_Code__c = itrProduct.Product__r?.PLR_Code__c; //adding PLR code mapping heree 25th Feb 2026 : to map PLR code from sub prod to transaction record ehen it creates for HL
						System.debug('ProdName'+itrProduct.Name);

						loanTransaction.Allow_Grace__c = (itrProduct.Name.trim().toUpperCase() == 'PEMI' || itrProduct.Name.trim().toUpperCase() =='MORAT') ? true : false;
						loanTransaction.Allow_Payment_in_Grace_Period__c =  itrProduct.Name.trim().toUpperCase() == 'PEMI' ? true : false;
						System.debug('loanTransaction.Allow_Grace__c'+loanTransaction.Allow_Grace__c);
						System.debug('loanTransaction.Allow_Payment_in_Grace_Period__c'+loanTransaction.Allow_Payment_in_Grace_Period__c);
					}
					loanTransaction.RecordTypeId = SObjectType.Loan_Transaction__c.getRecordTypeInfosByDeveloperName().get(Constants__mdt.getInstance('Transaction_Detail_Record_type').Value__c).getRecordTypeId();
					Schema.SObjectType objType = Schema.getGlobalDescribe().get(loan_transaction_Object_Api_Name);
					//for(Screen_Field__c scrnField : screenFieldMap.get(loanAppProductMap.get(opp.Id)?.Product__r?.Product__r?.Name)){
					for(Screen_Field__c scrnField : screenFieldMap.get('Affordable Home Loan')){
						Schema.DescribeFieldResult fieldDesc = objType.getDescribe().fields.getMap().get(scrnField.Storage_Field__c).getDescribe();
						System.debug(fieldDesc.getLocalName());
						if(fieldDesc.getLocalName() == 'Loan_Start_Date__c'){
							loanTransaction.put(scrnField.Storage_Field__c, integrationRecord?.Business_Date__c);
						}else if(fieldDesc.getType().name().toLowerCase() == 'integer'){
							loanTransaction.put(scrnField.Storage_Field__c,Integer.valueOf(scrnField.Default_Value__c));
						}else if(fieldDesc.getType().name().toLowerCase() == 'double'){
							loanTransaction.put(scrnField.Storage_Field__c,Double.valueOf(scrnField.Default_Value__c));
						}else if(fieldDesc.getType().name().toLowerCase() == 'boolean'){
							loanTransaction.put(scrnField.Storage_Field__c, Boolean.ValueOf(scrnField.Default_Value__c));
						}else if(fieldDesc.getType().name().toLowerCase() == 'time'){
							String timeString = String.valueof(scrnField.Default_Value__c);
							List<String> timeParts = timeString.split(':');
							Integer hours = Integer.valueOf(timeParts[0]);
							Integer minutes = Integer.valueOf(timeParts[1]);
							Integer seconds = Integer.valueOf(timeParts[2].split('\\.')[0]);
							Integer milliseconds = Integer.valueOf(timeParts[2].split('\\.')[1]);
							loanTransaction.put(scrnField.Storage_Field__c, Time.newInstance(hours, minutes, seconds, milliseconds));
						}else if(fieldDesc.getType().name().toLowerCase() == 'date'){
							loanTransaction.put(scrnField.Storage_Field__c, Date.ValueOf(scrnField.Default_Value__c));
						}else if(fieldDesc.getType().name().toLowerCase() == 'datetime'){
							//default value should be in the following form 2025-04-01 18:30:00 to be able to convert from string to date time
							loanTransaction.put(scrnField.Storage_Field__c, DateTime.ValueOf(scrnField.Default_Value__c)); 
						}else{
							loanTransaction.put(scrnField.Storage_Field__c,scrnField.Default_Value__c);
						}
					}
					
					loanTransaction.put('First_Disbursement_Amount__c', loanAppProductMap.get(opp.Id)[0]?.Loan_Application__r?.Sanction_Loan_Amount__c);
					loanTransaction.put('Total_Disbursed_Amount__c', loanAppProductMap.get(opp.Id)[0]?.Loan_Application__r?.Sanction_Loan_Amount__c);
					
				
					loanTransactionList.add(loanTransaction);
				}
			}

			if(!loanTransactionList.isEmpty()){
				Database.insert(loanTransactionList);
			}

		}catch(Exception ex){
            System.debug('OpportunityUtility->createLoanTransaction ::' + ex.getMessage() +' AT '+ ex.getLineNumber() + ' STACKTRACE '+ex.getStackTraceString());
			Utility.generateException(ex,Constants__mdt.getInstance('Opportunity').value__c, Constants__mdt.getInstance('OpportunityUtility').value__c);
		}
	}

	public static void updateProduct2FieldsOnStageChange(List<Opportunity> newOppList) {
        Set<Id> oppIds = new Set<Id>();
	
		for (Opportunity opp : newOppList) {
			oppIds.add(opp.Id);
		}
		List<Product2> subProducts = [
			SELECT Id,Sanctioned_Loan_Amount__c,Sanctioned_ROI__c,Sanctioned_Tenor__c,Negotiated_Loan_Amount__c,Negotiated_ROI__c,Negotiated_Tenure__c,Final_Loan_Amount__c,Final_ROI__c,Final_Tenure__c FROM Product2 WHERE RecordType.Name = 'Sub Product' AND Loan_Application__c IN :oppIds
		];

        for(Product2 subProd : subProducts){
           subProd.Negotiated_Loan_Amount__c = subProd.Sanctioned_Loan_Amount__c;
		   subProd.Negotiated_ROI__c = subProd.Sanctioned_ROI__c;
		   subProd.Negotiated_Tenure__c = subProd.Sanctioned_Tenor__c;
		   subProd.Final_Loan_Amount__c = subProd.Sanctioned_Loan_Amount__c;
		   subProd.Final_ROI__c = subProd.Sanctioned_ROI__c;
		   subProd.Final_Tenure__c = subProd.Sanctioned_Tenor__c;
		}

		if (!subProducts.isEmpty()) {
			update subProducts;
		}
	}

	public static void updateProduct2FieldsAfterApproval(List<Opportunity> newOppList) {
        Set<Id> oppIds = new Set<Id>();
	
		for (Opportunity opp : newOppList) {
			oppIds.add(opp.Id);
		}
		List<Product2> subProducts = [
			SELECT Id,Sanctioned_Loan_Amount__c,Sanctioned_ROI__c,Sanctioned_Tenor__c,Negotiated_Loan_Amount__c,Negotiated_ROI__c,Negotiated_Tenure__c,Final_Loan_Amount__c,Final_ROI__c,Final_Tenure__c FROM Product2 WHERE RecordType.Name = 'Sub Product' AND Loan_Application__c IN :oppIds
		];

        for(Product2 subProd : subProducts){
			if (subProd.Negotiated_ROI__c != null) {
                subProd.Final_ROI__c = subProd.Negotiated_ROI__c;
            }
		}

		if (!subProducts.isEmpty()) {
			update subProducts;
		}
	}
	//take plr code and plr value from product2 subprod and map it on loanT 
	/*public static void updatePlrCodeValueInTranFromProduct2(String loanApplicationId) {
        List<Product2> subProducts = [SELECT Id,Name,Product__c,Loan_Application__c,RecordType.DeveloperName,PLR_Code__c,PLR_Value__c FROM Product2
            WHERE Loan_Application__c =:loanApplicationId AND RecordType.DeveloperName = 'Sub_Product' AND Product__c != NULL];

        Map<Id, Product2> parentProductIdToSubProduct = new Map<Id, Product2>();
        Set<Id> parentProductIds = new Set<Id>();
        for (Product2 sp : subProducts) {
            parentProductIdToSubProduct.put(sp.Product__c, sp);
            parentProductIds.add(sp.Product__c);
        }

        List<Loan_Transaction__c> transactions = [SELECT Id,Name,Product__c,PLR_Code__c,PLR_Value__c,RecordType.DeveloperName FROM Loan_Transaction__c 
		WHERE Product__c IN :parentProductIds AND RecordType.DeveloperName = 'Transactional_Details'];

        List<Loan_Transaction__c> toUpdate = new List<Loan_Transaction__c>();
        for (Loan_Transaction__c txn : transactions) {
            Product2 sp = parentProductIdToSubProduct.get(txn.Product__c);
            if (sp == null) continue;

            Boolean changed = false;
            if (txn.PLR_Code__c != sp.PLR_Code__c) {
                txn.PLR_Code__c = sp.PLR_Code__c;
                changed = true;
            }
            // if (txn.PLR_Value__c != sp.PLR_Value__c) { formula fielddd
            //     txn.PLR_Value__c = sp.PLR_Value__c;
            //     changed = true;
            // }
            if (changed) toUpdate.add(txn);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }*/

	public static void updateSanctionedTenureWithTotalTenure(String loanApplicationId){
		List<Product2> allProducts = [SELECT Id,Name,CreatedDate,Product__c,Loan_Application__r.StageName, Loan_Application__r.Name,Sanctioned_Tenor__c,RecordType.DeveloperName, RecordType.Name,Product_Master__c,Product_Master__r.RecordType.Name,
		Product__r.Name,Product_Master__r.Name FROM Product2 WHERE Loan_Application__c = :loanApplicationId];
		Map<Id, Decimal> subproductToTotalTenureMap = new Map<Id, Decimal>();
		List<Product2> subProducts = new List<Product2>();
		for (Product2 p : allProducts) {
			if (p.RecordType.DeveloperName == 'Sub_Product') {
				subProducts.add(p);
			} else if (p.RecordType.DeveloperName == 'Total_Tenure' && p.Product__c != null) {
				subproductToTotalTenureMap.put(p.Product__c, Decimal.valueOf(p.Name));
			}
		}
		// Updatingg Sub Products with their corresponding Total Tenure
		List<Product2> toUpdate = new List<Product2>();
		for (Product2 sp : subProducts) {
			if (subproductToTotalTenureMap.containsKey(sp.Id)) {
				Decimal newTenure = subproductToTotalTenureMap.get(sp.Id);
				if (sp.Sanctioned_Tenor__c != newTenure) {
					sp.Sanctioned_Tenor__c = newTenure;
					toUpdate.add(sp);
				}
			}
		}
		if (!toUpdate.isEmpty()) {
			update toUpdate;
		}
	}

	public static void updateLMSChargesBasedOnProductChange(List<Opportunity> oppListForAPI) {
		Set<Id> oppIds = new Set<Id>();
		String productName = null;
	
		for (Opportunity opp : oppListForAPI) {
			oppIds.add(opp.Id);
			productName = opp.Product__c;
		}
	
		// Step 1: Delete existing LMS charges
		List<Charges_Insurance__c> existingCharges = [
			SELECT Id FROM Charges_Insurance__c
			WHERE Loan_Application__c IN :oppIds AND Category__c = 'LMS'
		];
		if (!existingCharges.isEmpty()) {
			delete existingCharges;
		}
	
		// Step 2: Fetch related Product2 records (Product, Sub Product, Variant, Sub Variant)
		Product2 mainProduct = [
			SELECT Id FROM Product2 WHERE RecordType.Name = 'Product' AND Name = :productName AND Loan_Application__c IN :oppIds LIMIT 1
		];
		Product2 subProduct = [
			SELECT Id FROM Product2 WHERE RecordType.Name = 'Sub Product' AND Product__c = :mainProduct.Id AND Loan_Application__c IN :oppIds LIMIT 1
		];
		List<Product2> variantProducts = [
			SELECT Id, Name, RecordType.Name, Loan_Application__c FROM Product2
			WHERE Loan_Application__c IN :oppIds AND RecordType.Name = 'Variant' AND Product__c = :subProduct.Id
		];
		List<Product2> subVariantProducts = [
			SELECT Id, Name, RecordType.Name, Loan_Application__c FROM Product2
			WHERE RecordType.Name = 'Sub Variant' AND Variant__c = :variantProducts[0].Id AND Loan_Application__c IN :oppIds LIMIT 1
		];
	
		Map<Id, Map<String, String>> oppIdVsProductRecords = new Map<Id, Map<String, String>>();
		for (Product2 prod : variantProducts) {
			if (!oppIdVsProductRecords.containsKey(prod.Loan_Application__c)) {
				oppIdVsProductRecords.put(prod.Loan_Application__c, new Map<String, String>());
			}
			oppIdVsProductRecords.get(prod.Loan_Application__c).put(prod.RecordType.Name, prod.Name);
		}
		if (!subVariantProducts.isEmpty()) {
			for (Product2 subVar : subVariantProducts) {
				if (!oppIdVsProductRecords.containsKey(subVar.Loan_Application__c)) {
					oppIdVsProductRecords.put(subVar.Loan_Application__c, new Map<String, String>());
				}
				oppIdVsProductRecords.get(subVar.Loan_Application__c).put(subVar.RecordType.Name, subVar.Name);
			}
		}
	
		// Step 3: Fetch LMS Charge Master
		List<Charges_Insurance_Master__c> chargeMasters = [
			SELECT Id, Charges_Fee_Type__c, Default_Value__c, Category__c, 
				   Sub_Product__r.Name, Sub_Variant__r.Name,
				   Max_Percent__c, Min_Percent__c
			FROM Charges_Insurance_Master__c
			WHERE Category__c = 'LMS'
		];
	
		// Get Charges record type
		Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.getGlobalDescribe()
			.get('Charges_Insurance__c')
			.getDescribe()
			.getRecordTypeInfosByName();
		Id chargesRecordTypeId = recordTypeMap.get('Charges').getRecordTypeId();
	
		// Step 4: Recreate Charges
		List<Charges_Insurance__c> chargeList = new List<Charges_Insurance__c>();
		for (Opportunity opp : oppListForAPI) {
			Map<String, String> productData = oppIdVsProductRecords.get(opp.Id);
			if (productData == null) continue;
	
			String actualVariant = productData.get('Variant');
			String actualSubVariant = productData.containsKey('Sub Variant') ? productData.get('Sub Variant') : '';
	
			for (Charges_Insurance_Master__c master : chargeMasters) {
				String requiredVariant = master.Sub_Product__r.Name;
				String requiredSubVariant = master.Sub_Variant__r != null ? master.Sub_Variant__r.Name : '';
	
				Boolean isVariantMatch = actualVariant == requiredVariant && String.isBlank(requiredSubVariant);
				Boolean isVariantAndSubVariantMatch = actualVariant == requiredVariant && actualSubVariant == requiredSubVariant;
	
				if (isVariantMatch || isVariantAndSubVariantMatch) {
					Charges_Insurance__c newCharge = new Charges_Insurance__c();
					newCharge.Name = master.Charges_Fee_Type__c;
					newCharge.Charges_Fee_Type__c = master.Charges_Fee_Type__c;
					newCharge.Default_Percentage__c = master.Default_Value__c;
					newCharge.Requested_Percentage__c = master.Default_Value__c;
					newCharge.Loan_Application__c = opp.Id;
					newCharge.Category__c = 'LMS';
					newCharge.Max_Percent__c = master.Max_Percent__c;
					newCharge.Min_Percent__c = master.Min_Percent__c;
					newCharge.RecordTypeId = chargesRecordTypeId;
					chargeList.add(newCharge);
				}
			}
		}
	
		if (!chargeList.isEmpty()) {
			insert chargeList;
		}
	}
	
	public static void createSantionLetterEventRecord(Set<Id> loanApplicationIds, Boolean isApproved) {
		Map<Id, Document_Details__c> latestDocMap = new Map<Id, Document_Details__c>();
		for (AggregateResult ar : [SELECT Loan_Application__c appId, MAX(CreatedDate) maxDate 
			FROM Document_Details__c WHERE Loan_Application__c IN :loanApplicationIds 
			AND Name = 'Sanction Letter' AND Active__c = true GROUP BY Loan_Application__c]) {
			latestDocMap.put((Id)ar.get('appId'), null);
		}
		if (!latestDocMap.isEmpty()) {
			List<Document_Details__c> latestDocs = [SELECT Id, CreatedDate, Loan_Application__c FROM Document_Details__c
			WHERE Loan_Application__c IN :latestDocMap.keySet() AND Name = 'Sanction Letter' AND Active__c = true 
			ORDER BY CreatedDate DESC];
			for (Document_Details__c doc : latestDocs) {
				if (!latestDocMap.containsKey(doc.Loan_Application__c) || latestDocMap.get(doc.Loan_Application__c) == null) {
					latestDocMap.put(doc.Loan_Application__c, doc);
				}
			}
		}
		Map<Id, Loan_Transaction__c> txnMap = new Map<Id, Loan_Transaction__c>();
		List<Loan_Transaction__c> allTransactions = [
			SELECT Id, CreatedDate, Sanction_Letter_Generated_Time__c, Loan_Application__c, Quick_Disbursement__c, CSD_flag__c 
			FROM Loan_Transaction__c WHERE Loan_Application__c IN :loanApplicationIds 
			AND RecordType.Name = 'Transaction Details' ORDER BY CreatedDate ASC];
		for (Loan_Transaction__c txn : allTransactions) {
			if (!txnMap.containsKey(txn.Loan_Application__c)) {
				txnMap.put(txn.Loan_Application__c, txn);
			}
		}
		List<Loan_Transaction__c> transactionsToUpdate = new List<Loan_Transaction__c>();
		// Integration_Master__mdt metadata = new Integration_Master__mdt();
		// if(isApproved){
		// metadata = [
        //         SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, Client_Id__c, 
        //             Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, Refresh_Allowed__c, Activity_Name__c
        //         FROM Integration_Master__mdt 
        //         WHERE Activity_Name__c = 'Create Finance AHL' 
        //         LIMIT 1
        //     ];
		// }
		List<Integration_Details__c> integrationList= [SELECT Id, name, Request_JSON__c, Loan_Application__c, Endpoint__c FROM Integration_Details__c WHERE Loan_Application__c IN :loanApplicationIds AND (Name = 'Sanction Letter Generation' OR Endpoint__c = 'CSD') ORDER BY CreatedDate DESC];
		Map<String, String> integrationMap = new Map<String, String>();
		Map<String, Boolean> csdpresent = new Map<String, Boolean>();
		for(Integration_Details__c intDetails : integrationList){
			if(!csdpresent.containsKey(intDetails.Loan_Application__c)){
				csdpresent.put(intDetails.Loan_Application__c, false);
			}
			if(intDetails.Name == 'Sanction Letter Generation'){
				if(!integrationMap.containsKey(intDetails.Loan_Application__c)){
					integrationMap.put(intDetails.Loan_Application__c, intDetails.Request_JSON__c);
				}
			}
			if(intDetails.Endpoint__c == 'CSD'){
				csdpresent.put(intDetails.Loan_Application__c, true);
			}
		}
		for (Id loanAppId : loanApplicationIds) {
			Loan_Transaction__c txn = txnMap.get(loanAppId);
			if (txn == null) continue;
			Boolean shouldPublishEvent = false;
			if (txn.Sanction_Letter_Generated_Time__c == null) {
				txn.Sanction_Letter_Generated_Time__c = System.now();
				transactionsToUpdate.add(txn);
				shouldPublishEvent = true;
			} else {
				Document_Details__c latestDoc = latestDocMap.get(loanAppId);
				if (latestDoc != null && latestDoc.CreatedDate > txn.Sanction_Letter_Generated_Time__c) {
					shouldPublishEvent = true;
				}
			}
			if (shouldPublishEvent) {
				// intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
				// wrapper.recordId = '';
				// wrapper.loanApplicationId = loanAppId;
				// wrapper.type = 'Sanction Letter Generation';
				// IntHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
				if(integrationMap.containsKey(loanAppId)){
					Utility.publishCommunicationEvent(integrationMap.get(loanAppId), loanAppId, 'SLSF');
					Utility.publishCommunicationEvent(integrationMap.get(loanAppId), loanAppId, 'SLSF_SALES');
				}
			}
			System.debug('isApproved'+ isApproved);
			if(isApproved && ( !csdpresent.containsKey(loanAppId) || (csdpresent.containsKey(loanAppId) && !csdpresent.get(loanAppId)))){
				Boolean csdFlag = txn.CSD_flag__c== 'Yes' ? true: false;
				Boolean qdFlag = txn.Quick_Disbursement__c;
				// intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
				// wrapper.recordId = loanAppId;
				// wrapper.loanApplicationId = loanAppId;  
				// wrapper.type = 'Create Finance AHL';
				// wrapper.endpoint = metadata.Endpoint__c;
				// wrapper.requestMethod = metadata.Request_Method__c;
				// wrapper.clientId = metadata.Client_Id__c;
				// wrapper.clientSecret = metadata.Client_Secret__c;
				// wrapper.allowedRetry = metadata.Allowed_Retry__c;
				// wrapper.gestationPeriod = metadata.Gestation_Period__c;
				// wrapper.activityname = metadata.Activity_Name__c;
				// wrapper.refreshallowed = metadata.Refresh_Allowed__c;
				// wrapper.handlername = metadata.Handler_Class__c;
            	// intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
				if(qdFlag || csdFlag){
					String csdPayload = prepareCDSWrapper(loanAppId, txn.Quick_Disbursement__c);
					Utility.publishCommunicationEvent(csdPayload, loanAppId, 'CSD');
				}
			}
		}
		if (!transactionsToUpdate.isEmpty()) {
			update transactionsToUpdate;
		}
	}

	public static String prepareCDSWrapper (String loanAppId, Boolean Quickdisb){
		String requiredLoanId = loanAppId;
		Opportunity opp = [select Id,Loan_Hierarchy__c,Split_Parent_Loan_Application__c,Product__c from Opportunity where Id = :loanAppId LIMIT 1];
		String productName = opp != null ? opp.Product__c : '';
		if(opp.Loan_Hierarchy__c == 'Child' && opp.Split_Parent_Loan_Application__c != null){
			requiredLoanId = opp.Split_Parent_Loan_Application__c;
		}

		List<Application_Applicant__c> allApplicants = [ SELECT Id, Mobile_Number__c,
                Customer_Type__c, Applicant_Type__c, Salutation__c, First_Name__c, Last_Name__c,
                 Customer__r.Customer_LMS_Id__c, Loan_Application__r.Name, Email__c, Company__c, Name_of_Organization__c FROM Application_Applicant__c WHERE Loan_Application__c = :requiredLoanId AND Applicant_Type__c = 'Primary Applicant'];
		List<Product2> mainProduct = [SELECT Id, Name, Description from Product2 WHERE RecordType.Name = 'Product' AND Loan_Application__c = :loanAppId LIMIT 1];
		List<product2> productList= [SELECT Id, name,Product__r.name, Description FROM product2 WHERE  Loan_Application__c = :loanAppId AND RecordType.name = 'Variant'];
		String loanProduct;
		Map<String, Communication_Event_Product_Mapping__mdt> productMetaMapping = Communication_Event_Product_Mapping__mdt.getAll();
		Map<String, Communication_Event_Product_Mapping__mdt> productMapping= new Map<String, Communication_Event_Product_Mapping__mdt>();
		for (Communication_Event_Product_Mapping__mdt metadata : productMetaMapping.values()){
			productMapping.put(metadata.Product_Name__c, metadata);
		}
		if(mainProduct.size() > 0) {
			if(mainProduct[0].name == 'Affordable Home Loan') {
				loanProduct = 'AH';
			}else if(mainProduct[0].name == 'Affordable Non-Home Loan') {
				loanProduct = 'AL';
			}else if(mainProduct[0].name == 'Flexi Loan') {
				loanProduct = 'FL';
			}
			else {
				loanProduct= productMapping.get(productList[0].Product__r.name).Product_Name_in_Wrapper__c;
			}
		}
		CSDWrapper csdObj = new CSDWrapper();
		csdObj.Salutation = allApplicants[0].Salutation__c;
		csdObj.FirstName = allApplicants[0].First_Name__c;
		csdObj.LastName = allApplicants[0].Last_Name__c;
		csdObj.ProductName = String.isNotBlank(loanProduct) ? loanProduct: '';
		// mainProduct[0].Name;
		csdObj.ProductDescription = mainProduct[0].Description;
		csdObj.LANNumber = allApplicants[0].Loan_Application__r.Name;
		csdObj.Quickdisb = Quickdisb;
		csdObj.csd_tagging = ''; // Need to confirm
		if(allApplicants[0].Customer_Type__c == 'Individual'){
			csdObj.CustomerCategory = 'RETAIL';
		}else if(allApplicants[0].Customer_Type__c == 'Non Individual'){
			csdObj.CustomerCategory = 'CORP';
		}else{
			csdObj.CustomerCategory =  '';
		}
		csdObj.mobile_number = allApplicants[0].Mobile_Number__c;
		csdObj.applicantType = allApplicants[0].Applicant_Type__c;
		csdObj.whatsaap_number = allApplicants[0].Mobile_Number__c;
		csdObj.emailId = allApplicants[0].Email__c;
		csdObj.cif =  allApplicants[0].Customer__r.Customer_LMS_Id__c != null ? allApplicants[0].Customer__r.Customer_LMS_Id__c : '';
		csdObj.CompanyName =  allApplicants[0].Customer_Type__c == 'Individual' ? (String.isNotBlank(allApplicants[0].Company__c) ?  allApplicants[0].Company__c: '') :  (String.isNotBlank(allApplicants[0].Name_of_Organization__c) ?  allApplicants[0].Name_of_Organization__c: '');
		List<CSDWrapper> csdList = new List<CSDWrapper>();
		csdList.add(csdObj);
		return JSON.serialize(csdList);
	}

    public class CSDWrapper {
        public String Salutation;
        public String FirstName;
        public String LastName;
        public String ProductName;
        public String ProductDescription;
        public String LANNumber;
        public Boolean Quickdisb;
        public String csd_tagging;
        public String CustomerCategory;
        public String mobile_number;
        public String whatsaap_number;
        public String emailId;
        public String cif;
		public String CompanyName;
		public String applicantType;
    }
}