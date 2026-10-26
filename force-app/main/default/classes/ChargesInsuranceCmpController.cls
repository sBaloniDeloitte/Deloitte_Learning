/**
* @File Name : ChargesInsuranceCmpController.cls
* @Description : This is a controller class for ChargesInsuranceCmp LWC
* @Author : Vijaya Krishna Y
* @Last Modified By : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On : 06-20-2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | February 12, 2025 |   | Initial Version
**/

public without sharing class ChargesInsuranceCmpController {

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
public static List<vasMasterWrapper> getVASMasterRecords(Id selectedVASRecordId) {
    try {
        List<vasMasterWrapper> wrapperList = new List<vasMasterWrapper>();
        Charges_Insurance_Master__c selectedVasRecord = [
            SELECT VAS_Code__c 
            FROM Charges_Insurance_Master__c 
            WHERE Id = :selectedVASRecordId
        ];
        Schema.SObjectType objType = Schema.getGlobalDescribe().get('Charges_Insurance__c');
        for (Charges_Insurance_Master__c vasMaster : [
            SELECT Id, VAS_Code__c, Tab_Name__c, Section_Fields__c, Sequence__c, 
                   Section_Name__c, Required_Fields__c, VAS_Description__c, 
                   Min_Value__c, Max_Value__c, Default_Text_Value__c
            FROM Charges_Insurance_Master__c 
            WHERE VAS_Code__c = :selectedVasRecord.VAS_Code__c 
            ORDER BY Sequence__c
        ]) {
            vasMasterWrapper vasWrapper = new vasMasterWrapper();
            vasWrapper.vasMasterRecord = vasMaster;
            // Identify picklist fields
            List<String> picklistList = new List<String>();
            for (String fieldName : vasMaster?.Section_Fields__c.split(',')) {
                if (objType?.getDescribe()?.fields?.getMap()?.get(fieldName)?.getDescribe()?.getType()?.name() == 'PICKLIST') {
                    picklistList.add(fieldName);
                }
            }
            // Split section fields
            List<String> sectionFields = new List<String>();
            if (String.isNotBlank(vasMaster.Section_Fields__c)) {
                for (String f : vasMaster.Section_Fields__c.split(',')) {
                    sectionFields.add(f.trim());
                }
            }
            // Split required fields
            Set<String> requiredFields = new Set<String>();
            if (String.isNotBlank(vasMaster.Required_Fields__c)) {
                for (String f : vasMaster.Required_Fields__c.split(',')) {
                    requiredFields.add(f.trim());
                }
            }
            // Nested map creation
            vasWrapper.nestedMap = new Map<String, Map<String, Boolean>>();
            String tabName = vasMaster.Section_Name__c;
            Map<String, Boolean> fieldMap = new Map<String, Boolean>();
            for (String fieldName : sectionFields) {
                Boolean isRequired = requiredFields.contains(fieldName);
                fieldMap.put(fieldName, isRequired);
            }
            vasWrapper.nestedMap.put(tabName, fieldMap);
            vasWrapper.picklistFieldList = picklistList;
            wrapperList.add(vasWrapper);
        }
        return wrapperList;

    } catch (Exception ex) {
        throw new AuraHandledException(ex.getMessage());
    }
}

	@AuraEnabled(cacheable=true)
	public static List<vasRecordWrapper> getChargeInsuranceRecords(Id loanId){
		try{
			Set<Id> contentIdSet = new Set<Id>();
			List<vasRecordWrapper> wrapperList = new List<vasRecordWrapper>();
			List<Charges_Insurance__c> existingRecords = [SELECT Id,Loan_Application__c, Loan_Application__r.Sanction_Loan_Amount__c,Policy_Tenure_Min_Value__c,Policy_Tenure_Max_Value__c,
														Loan_Application__r.Sanction_Tenure__c,Total_VAS_Amount__c,VAS_Id__c,Self_Funded__c,
														Description__c,Mode_of_Payment__c,Fee_Accural_Date__c,Value_Date__c,toLabel(Fee_Method__c),
														Nominee_DOB__c,VAS_Code__c,Application_Applicant__c,Application_Applicant__r.Applicant_Name__c,Charges_Insurance_Master__c,Insurance_Premium__c,Sum_Insured_Customer_Details__c,  
														Charge_or_Insurance_Number__c, Custom_Auto_Number__c,VAS_Type__c, (Select Id,Content_Document_Id__c,Name from Document_Details__r where Active__c = true) FROM Charges_Insurance__c WHERE Loan_Application__c = :loanId 
														AND RecordType.Name = :Constants__mdt.getInstance('CHARGES_INSURANCE_RECORD_TYPE').value__c ORDER BY CreatedDate];

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
	public static void updateDocDetails(Id LoanId, Id customerId, Id docDetailId, String vasCode){
		
			Charges_Insurance__c insurance = [SELECT Id FROM Charges_Insurance__c WHERE VAS_Code__c = :vasCode AND Loan_Application__c = :LoanId AND Application_Applicant__c = :customerId LIMIT 1];
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
    public static Map<String, Id> createDocumentDetail(List<String> names) {
    try {
        Map<String, Id> nameToDocDetailIdMap = new Map<String, Id>();

        // Fetch matching Document_Master__c records
        List<Document_Master__c> docMasters = [
            SELECT Id, Document_Name__c
            FROM Document_Master__c
            WHERE Requirement_At__c = 'Insurance'
            AND Document_Name__c IN :names
        ];

        List<Document_Details__c> docDetailsToInsert = new List<Document_Details__c>();

        // Create a map for Document_Master by name
        Map<String, Document_Master__c> docMasterMap = new Map<String, Document_Master__c>();
        for (Document_Master__c dm : docMasters) {
            docMasterMap.put(dm.Document_Name__c, dm);
        }

        for (String docName : names) {
            if (docMasterMap.containsKey(docName)) {
			Document_Details__c docDetail = new Document_Details__c();
                docDetail.Name = docName;
                docDetail.Document_Master__c = docMasterMap.get(docName).Id;
                docDetailsToInsert.add(docDetail);
            }
        }

        // Insert Document_Details__c records
        insert docDetailsToInsert;

        // Map inserted Document_Details__c Ids to their names
        for (Document_Details__c insertedDetail : docDetailsToInsert) {
            nameToDocDetailIdMap.put(insertedDetail.Name, insertedDetail.Id);
        }

        return nameToDocDetailIdMap;
    } catch (Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/*@AuraEnabled
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
}*/



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
		return [SELECT Id, Name, Applicant_Type__c, DOB__c, Gender__c,Customer_Type__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId AND Applicant_Type__c IN ('Primary Applicant','Co Applicant')];
		
	}

@AuraEnabled
public static void deleteChargeInsurance(Id vasId) {    
    try {
        List<Document_Details__c> docDetails = [SELECT Id, Content_Document_Id__c FROM Document_Details__c WHERE Charges_Insurance__c = :vasId];
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
        DELETE docDetails;
        DELETE [SELECT Id FROM Loan_Transaction__c WHERE Disbursement_Party__c = 'VAS' AND Charges_Insurance__c = :vasId];
        DELETE [SELECT Id FROM Charges_Insurance__c WHERE Related_Insurance__c = :vasId OR Id = :vasId];

    } catch(Exception ex) {
        throw new AuraHandledException(ex.getMessage());
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
	public static void updateEligibleForResanction(Id opportunityId) {
		try {
			Opportunity opp = new Opportunity(Id = opportunityId, Eligible_for_Resanction__c = true);
			update opp;
		} catch (Exception e) {
			throw new AuraHandledException('Unable to update resanction flag: ' + e.getMessage());
		}
	}

	@AuraEnabled
	public static Boolean canUserEditVAS(String opportunityId) {
		// Step 1: Fetch opportunity with sub-stage and stage
		Opportunity opp = [
			SELECT Id, StageName, Sub_stage__c
			FROM Opportunity
			WHERE Id = :opportunityId
			LIMIT 1
		];

		if(opp.Sub_stage__c == 'Disbursed'){
            return false;
        }

		// If not Disbursement stage or not Ops Maker sub-stage, return true (allow editing)
		if (opp.StageName != 'Disbursement' || (opp.Sub_stage__c != 'Ops Maker' && opp.Sub_stage__c != 'Ops Author')) {
			return true;
		}

		// Step 2: Fetch current user’s Opportunity Team Member record
		List<OpportunityTeamMember> teamMembers = [
			SELECT Id, UserId, TeamMemberRole
			FROM OpportunityTeamMember
			WHERE OpportunityId = :opp.Id AND UserId = :UserInfo.getUserId()
			LIMIT 1
		];

		// Step 3: Check if role is Ops Maker
		if (!teamMembers.isEmpty() && opp.Sub_stage__c == 'OPS Maker' && teamMembers[0].TeamMemberRole == 'OPS Maker') {
			return true; // User can edit
		}

		return false; // Others can only preview
	}


	public class vasMasterWrapper{
		@AuraEnabled public List<String> picklistFieldList;
		@AuraEnabled public Charges_Insurance_Master__c vasMasterRecord;
        @AuraEnabled public Map<String, Map<String, Boolean>> nestedMap;
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
}