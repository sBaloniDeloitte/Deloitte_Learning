/**
* @File Name : AHL_ChargesInsuranceCmpController.cls
* @Description : This is a controller class for ChargesInsuranceCmp LWC
* @Author : Vijaya Krishna Y
* @Last Modified By : Vijaya Krishna Y
* @Last Modified On : February 12, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | February 12, 2025 |   | Initial Version
**/

public without sharing class AHL_ChargesInsuranceCmpController {
	@AuraEnabled
    public static Integer getSanctionTenure(Id loanId) {
        Product2 prod = [
            SELECT Sanctioned_Tenor__c 
            FROM Product2 
            WHERE RecordType.Name = 'Sub Product' 
              AND Loan_Application__c = :loanId
            ORDER BY CreatedDate ASC 
            LIMIT 1
        ];
        
        return (prod.Sanctioned_Tenor__c != null) ? Integer.valueOf(prod.Sanctioned_Tenor__c) : 0;
    }

//added

	PRIVATE STATIC FINAL STRING VAS_Premium_Percentage = 'VAS_Premium_Percentage';
	PRIVATE STATIC FINAL STRING VAS_Allowed_File_Formats = 'VAS_Allowed_File_Formats';
	PRIVATE STATIC STRING FETCH_APPLICATION_DATE = Constants__mdt.getInstance('Fetch_Application_Date').Value__c;

	@AuraEnabled
	public static Boolean checkIfVASExists(id parentLoanAppId){
		return ![SELECT Id from Charges_Insurance__c where Loan_Application__c =:parentLoanAppId and Category__c='Insurance'].isEmpty();
	}

	@AuraEnabled(cacheable=true)
	public static Date getIntegrationDetails(){
		return [SELECT Id,Business_Date__c FROM Integration_Details__c WHERE Name = :FETCH_APPLICATION_DATE ORDER BY Createddate DESC LIMIT 1].Business_Date__c;
	}
    
    
    @AuraEnabled(cacheable=true)
	public static Boolean getVASOnlyOppDetails(id parentLoanAppId){
		Boolean isLoanVASOnly = false;
		list<Product2> getOppProductDetail = [Select Is_loan_VAS_only__c from Product2 where Loan_Application__c =:parentLoanAppId and RecordType.Name = 'Product'];
		if(!getOppProductDetail.isEmpty()){
			isLoanVASOnly = getOppProductDetail[0].Is_loan_VAS_only__c;
		}else{
			isLoanVASOnly = false;
		}
		return isLoanVASOnly;
	}
	
	
	@AuraEnabled
	public static List<vasMasterWrapper> getVASMasterRecords(Id selectedVASRecordId){
		try{
			List<vasMasterWrapper> vasMasterWrapper = new List<vasMasterWrapper>();
			Charges_Insurance_Master__c selectedVasRecord = [SELECT VAS_Code__c FROM Charges_Insurance_Master__c WHERE Id = :selectedVASRecordId];
			
			Schema.SObjectType objType = Schema.getGlobalDescribe().get('Charges_Insurance__c');
			for(Charges_Insurance_Master__c vasMaster : [SELECT Id,VAS_Code__c,Tab_Name__c,Section_Fields__c,Sequence__c,Section_Name__c,
			                                             VAS_Description__c, Fee_Method__c, Min_Value__c,Max_Value__c,Default_Text_Value__c
														FROM Charges_Insurance_Master__c 
														WHERE VAS_Code__c = :selectedVasRecord.VAS_Code__c 
														ORDER BY Sequence__c]){
				vasMasterWrapper vasWrapper = new vasMasterWrapper();
				vasWrapper.vasMasterRecord = vasMaster;
				List<String> picklistList = new List<String>();
				for(String fieldName : vasMaster?.Section_Fields__c.split(',')){
					if(objType?.getDescribe()?.fields?.getMap()?.get(fieldName)?.getDescribe()?.getType()?.name() == 'PICKLIST'){
						picklistList.add(fieldName);
					}
				}
				vasWrapper.picklistFieldList = picklistList;
				vasMasterWrapper.add(vasWrapper);
			}
			return vasMasterWrapper;
		}catch(Exception ex){
			throw new AuraHandledException(ex.getMessage());
		}
		
	}

	@AuraEnabled //Sanwar
    public static Charges_Insurance__c getVasData(String RecordId){
        try {
            Charges_Insurance__c vasData = [SELECT Id, Product_Name__c, Product__c, Fee_Method__c FROM Charges_Insurance__c Where Id =: RecordId limit 1];
            return vasData;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

	@AuraEnabled
	public static List<vasRecordWrapper> getChargeInsuranceRecords(Id loanId){
		try{
			Set<Id> contentIdSet = new Set<Id>();
			List<vasRecordWrapper> wrapperList = new List<vasRecordWrapper>();
			List<Charges_Insurance__c> existingRecords = [SELECT Id,Loan_Application__c, Loan_Application__r.Sanction_Loan_Amount__c,Policy_Tenure_Min_Value__c,Policy_Tenure_Max_Value__c,
														Loan_Application__r.Sanction_Tenure__c,Total_VAS_Amount__c,VAS_Id__c,Self_Funded__c,
														Description__c, Product_Name__c, Mode_of_Payment__c,Fee_Accural_Date__c,Value_Date__c,toLabel(Fee_Method__c),
														Nominee_DOB__c,VAS_Code__c,Application_Applicant__c,Application_Applicant__r.Name,Application_Applicant__r.Monthly_Gross_Salary__c,Charges_Insurance_Master__c,Insurance_Premium__c,Sum_Insured_Customer_Details__c,Product__c,  
														Charge_or_Insurance_Number__c, Custom_Auto_Number__c,VAS_Type__c, (Select Id,Content_Document_Id__c,Name from Document_Details__r) FROM Charges_Insurance__c WHERE Loan_Application__c = :loanId 
														AND RecordType.Name = :Constants__mdt.getInstance('CHARGES_INSURANCE_RECORD_TYPE').value__c ORDER BY CreatedDate];//sanwar (add monthly gross salary)
			// Application_Applicant__r.Applicant_Name__c
		    List<Document_Details__c>docDetailsList = new List<Document_Details__c>();

		for(Charges_Insurance__c insurance : existingRecords){
				docDetailsList.addAll(insurance.Document_Details__r);
			}

			for(Document_Details__c doc : docDetailsList){
				contentIdSet.add(doc.Content_Document_Id__c);
			}

		// for(Charges_Insurance__c insurance : existingRecords){
		// 		if(!insurance.Document_Details__r.isEmpty()){
		// 			contentIdSet.add(insurance.Document_Details__r[0].Content_Document_Id__c);
		// 		}
		// 	}	
		Map<Id,ContentDocument> contentDocMap = new Map<Id,ContentDocument>([SELECT Id,FileType 
		                                                                     FROM ContentDocument 
																			 WHERE Id IN :contentIdSet]);

		System.debug('contentDocMap>>'+contentDocMap);
																		

		for(Charges_Insurance__c insurance  : existingRecords){
			vasRecordWrapper recWrapper = new vasRecordWrapper();
			recWrapper.chargeInsurance = insurance;
			if(!insurance?.Document_Details__r.isEmpty()){
				for(Document_Details__c doc : insurance?.Document_Details__r){
					if(doc.Name == 'Insurance Related Document'){
						recWrapper.docDetailId = doc.Id;
				        recWrapper.contentId = doc.Content_Document_Id__c;
				        recWrapper.fileType = contentDocMap.get(doc.Content_Document_Id__c)?.FileType;
					}
					if(doc.Name == 'Excel Calculator'){
						recWrapper.docDetailIdExcel = doc.Id;
						recWrapper.contentIdExcel = doc.Content_Document_Id__c;
						recWrapper.fileTypeExcel = contentDocMap.get(doc.Content_Document_Id__c)?.FileType;
					}

				}
				// if(!insurance?.Document_Details__r.Document_Name__c == 'Insurance Related Document'){
				// recWrapper.docDetailId = insurance?.Document_Details__r[0].Id;
				// recWrapper.contentId = insurance?.Document_Details__r[0].Content_Document_Id__c;
				// recWrapper.fileType = contentDocMap.get(insurance?.Document_Details__r[0]?.Content_Document_Id__c)?.FileType;
				// }
				// if(!insurance?.Document_Details__r.Document_Name__c == 'Excel Calculator'){
				// recWrapper.docDetailIdExcel = insurance?.Document_Details__r[0].Id;
				// recWrapper.contentIdExcel = insurance?.Document_Details__r[0].Content_Document_Id__c;
				// recWrapper.fileTypeExcel = contentDocMap.get(insurance?.Document_Details__r[0]?.Content_Document_Id__c)?.FileType;

				//}
			}

			wrapperList.add(recWrapper);
		}

		
		
		return wrapperList;

		}catch(Exception ex){
			throw new AuraHandledException(ex.getMessage());
		}
		
	}

	@AuraEnabled
	public static void updateDocDetails(Id LoanId, Id customerId, Id docDetailId, String vasCode, String product){//sanwar(21/12/2025)
		
			Charges_Insurance__c insurance = [SELECT Id FROM Charges_Insurance__c WHERE VAS_Code__c = :vasCode AND Loan_Application__c = :LoanId AND Application_Applicant__c = :customerId And Product__c = :product LIMIT 1];//sanwar(21/12/2025)
			Document_Details__c doc = new Document_Details__c();
			doc.Id = docDetailId;
			doc.Charges_Insurance__c = insurance.Id;
			doc.Loan_Application__c = LoanId;
		try{
			update doc;
            
		}catch(Exception ex){
			throw new AuraHandledException(ex.getMessage());
		}
		
	}

	@AuraEnabled
	public static Id createDocumentDetail(String name){
		try{
			deleteDocumentDetail(name); //we are deleting the document detail as there is a chance that different users can work on doc detail record as doc details owd is private
			Document_Master__c docMaster = [SELECT Id,Document_Name__c FROM Document_Master__c WHERE Requirement_At__c = 'Insurance' AND Document_Name__c = :name LIMIT 1];

			Document_Details__c docDetail = new Document_Details__c();
			docDetail.Name = docMaster.Document_Name__c;
			docDetail.Document_Master__c = docMaster.Id;

		
			INSERT docDetail;

			return docDetail.Id;
		}catch(Exception ex){
			throw new AuraHandledException(ex.getMessage());
		}
	}

	@AuraEnabled
	public static void deleteDocumentDetail(String name){
		try{
			List<Document_Details__c> existingDocDetail = new List<Document_Details__c>();
			existingDocDetail = [SELECT Id 
			                     FROM Document_Details__c 
								 WHERE Name = :name
								 AND Charges_Insurance__c = NULL 
								 AND Is_Uploaded__c = false LIMIT 1];
			
			if(!existingDocDetail.isEmpty()){
				DELETE existingDocDetail;
			}
		}catch(Exception ex){
			throw new AuraHandledException(ex.getMessage());
		}
		
	}

	@AuraEnabled(cacheable=true)
	public static List<Application_Applicant__c> getApplicantDetails(Id loanId){
		return [SELECT Id, Name, Applicant_Type__c, Relationship_with_Primary_Applicant__c, Applicant_Name__c, DOB__c, Gender__c,Customer_Type__c, Monthly_Gross_Salary__c, Customer_Profile__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId AND Applicant_Type__c IN ('Primary Applicant','Co Applicant')];//sanwar(add monthly gross salary)
		
	}

	@AuraEnabled
	public static void deleteChargeInsurance(Id vasId)
	{	
		try{
			 List<Document_Details__c> docDetails = [SELECT Id, Content_Document_Id__c FROM Document_Details__c WHERE Charges_Insurance__c = : vasId];//Sanwar - Start 
			 Set<Id> contentDocumentIds = new Set<Id>();
			for(Document_Details__c doc : docDetails){
				if(doc != null && doc.Content_Document_Id__c != null){
					contentDocumentIds.add(doc.Content_Document_Id__c);
					doc.Content_Document_Id__c = null;
				}
			}
			if(!docDetails.isEmpty()) {
				update docDetails; // Persist nullification before delete
			}
			if(!contentDocumentIds.isEmpty()) {
				DELETE [SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIds];
			}
			DELETE docDetails;//Sanwar - End 
			DELETE [SELECT Id FROM Loan_Transaction__c WHERE Disbursement_Party__c = 'VAS' AND Charges_Insurance__c = :vasId ];
			DELETE [SELECT Id FROM Charges_Insurance__c WHERE Related_Insurance__c=: vasId OR Id = :vasId];
			
		}catch(Exception ex){
			throw new AurahandledException(ex.getMessage());
		}
        
	}

	@AuraEnabled(cacheable=true)
	public static List<String> fetchConstants(){
		
		List<String> constantsValueList = new List<String>();
		constantsValueList.add(Constants__mdt.getInstance(VAS_Premium_Percentage).value__c);
		constantsValueList.add(Constants__mdt.getInstance(VAS_Allowed_File_Formats).value__c);
		return constantsValueList;
	}

	@AuraEnabled(cacheable=true)
    public static String getOpportunityTeamRole(Id oppId) {
        Id currentUserId = UserInfo.getUserId();

        List<OpportunityTeamMember> teamMembers = [
            SELECT Id, UserId, TeamMemberRole 
            FROM OpportunityTeamMember 
            WHERE OpportunityId = :oppId AND UserId = :currentUserId
            LIMIT 1
        ];

        if (!teamMembers.isEmpty()) {
            return teamMembers[0].TeamMemberRole;
        }
        return null;
    }

	@AuraEnabled
	public static Boolean canUserEditVAS(String opportunityId) {
		List<Loan_Transaction__c> loanTxn =
		[SELECT Id, Quick_Disbursement__c, QDP_Status__c, STP__c, RecordType.DeveloperName, Loan_Application__c, Loan_Application__r.StageName, Loan_Application__r.Sub_stage__c, Loan_Application__r.DocGen_Status__c 
		FROM Loan_Transaction__c WHERE Loan_Application__c = :opportunityId AND RecordType.DeveloperName = 'Transaction_Details' LIMIT  1];

		List<OpportunityTeamMember> teamMemberdata = [Select Id,TeamMemberRole From OpportunityTeamMember Where OpportunityId =: opportunityId AND UserId =: UserInfo.getUserId() Limit 1];
		if(!teamMemberdata.isEmpty()){
			if(loanTxn.size()>0){
				if (((loanTxn[0].Loan_Application__r.StageName== 'PSV' || (loanTxn[0].Loan_Application__r.StageName== 'Disbursment' && loanTxn[0].Loan_Application__r.Sub_stage__c == 'Ops Maker')) && loanTxn[0].Loan_Application__r.DocGen_Status__c != 'Esign Initiated' ) && teamMemberdata[0].TeamMemberRole.contains('Sales')){
					return true;
				}else if (( (loanTxn[0].Loan_Application__r.StageName== 'Disbursment' && loanTxn[0].Loan_Application__r.Sub_stage__c == 'Ops Maker') && loanTxn[0].Loan_Application__r.DocGen_Status__c != 'Esign Initiated') && teamMemberdata[0].TeamMemberRole.contains('OPS Maker')){
					return true;
				}
			}
		}
		Id sysAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
		if (UserInfo.getProfileId() == sysAdminProfileId) {
			return true;
		}

		return false;
	}

	@AuraEnabled//sanwar
	public static List<Product2> getProductDataForSelectedRecordId(String selectedRecordId, String recordId){
		try {
			List<Product2> proList = [SELECT Id,Sanctioned_Tenor__c, Sanctioned_Loan_Amount__c 
										FROM Product2 
										WHERE Loan_Application__c =:recordId 
										AND RecordType.Name = 'Sub Product' 
										AND Product__r.RecordType.Name = 'Product' 
										AND Product__c = :selectedRecordId 
										ORDER BY CreatedDate ASC];
			return proList;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	public class vasMasterWrapper{
		@AuraEnabled public List<String> picklistFieldList;
		@AuraEnabled public Charges_Insurance_Master__c vasMasterRecord;
	}

	public class vasRecordWrapper{
		@AuraEnabled public Charges_Insurance__c chargeInsurance;
		@AuraEnabled public Id docDetailId;
		@AuraEnabled public String contentId;
		@AuraEnabled public String fileType;
		@AuraEnabled public Id docDetailIdExcel;
		@AuraEnabled public String contentIdExcel;
		@AuraEnabled public String fileTypeExcel;

	}
	@AuraEnabled
	public static NomineeWrapper getNomineeDetails(Map<String,String> inputMap){
		try {
			NomineeWrapper nw = new NomineeWrapper();
			String loanId = inputMap.get('loanId');
			String selectedNomineeType = inputMap.get('selectedNomineeType');
			List<Application_Applicant__c> appList =[Select id, Applicant_Name__c, Relationship_with_Primary_Applicant__c, DOB__c,DOI__c,Applicant_Type__c from Application_Applicant__c where Loan_Application__c=:loanId and id=:selectedNomineeType];
			if(appList.size()>0){
				nw.nomineeName = appList[0].Applicant_Name__c;
				nw.nomineeDOB = appList[0].DOB__c!=null? appList[0].DOB__c:appList[0].DOI__c;
				nw.relationship = appList[0].Applicant_Type__c=='Primary Applicant'?'Self':appList[0].Relationship_with_Primary_Applicant__c;

			}
			return nw;
			
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	public class NomineeWrapper{
		@AuraEnabled public String nomineeName;
		@AuraEnabled public Date nomineeDOB;
		@AuraEnabled public String relationship;
	}

	
	@AuraEnabled
	public static List<Map<String, String>> fetchServiceProvider() {
		try {
			List<Charges_Insurance_Master__c> records = [
				SELECT Id, Dealer_Name__c
				FROM Charges_Insurance_Master__c
				WHERE RecordType.Name = 'Vas Provider'
			];

			List<Map<String, String>> resultList = new List<Map<String, String>>();

			for (Charges_Insurance_Master__c rec : records) {
				if (rec.Dealer_Name__c != null) {
					resultList.add(new Map<String, String>{
						'id' => rec.Id,
						'name' => rec.Dealer_Name__c
					});
				}
			}

			return resultList;

		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static List<Map<String, String>> fetchServices(String providerId) {
    try {
		List<Charges_Insurance_Master__c> records = new List<Charges_Insurance_Master__c>() ;
		String baseQuery = 'SELECT Id,Fintype_CSV__c, VAS_Description__c,VAS_Code__c' + ' FROM Charges_Insurance_Master__c' +' WHERE  RecordType.Name = \'Insurance\'' + ' AND VAS_Provider__c = :providerId' + ' AND Section_Name__c ='+label.HL_VAS_Service_Provider  ;
		System.debug('395 Base Query-->'+baseQuery) ;
		records = Database.query(baseQuery); 
		System.debug('396 records query-->'+records) ;
        List<Map<String, String>> options = new List<Map<String, String>>();
        for (Charges_Insurance_Master__c rec : records) {
            String label = rec.VAS_Code__c + ' - ' + rec.VAS_Description__c;
            options.add(new Map<String, String>{
                'id' => rec.Id,
                'label' => label,
				'finTypes' => rec.Fintype_CSV__c
            });
        }
        return options;
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}

	@AuraEnabled
	public static String getLoanStartDate(Id loanId){
		List<Loan_Transaction__c> transactionList = [SELECT Id, Name, RecordType.Name, Loan_Start_Date__c FROM Loan_Transaction__c WHERE Loan_Application__c =: loanId AND RecordType.Name = 'Transaction Details' LIMIT 1]; 
		if(!transactionList.isEmpty() && transactionList[0].Loan_Start_Date__c != null){
			return String.valueOf(transactionList[0].Loan_Start_Date__c);
		}
		return null;

	}

}