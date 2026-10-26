public without sharing class HL_fetchApplicantsController {
	@AuraEnabled
	public static List<ApplicationWrapper>  fetchApplicants(string recordId){
		List<ApplicationWrapper> appWrapList = new List<ApplicationWrapper>();
		Legal__c legal = [select Id,Loan_Application__c,Application_Collateral__c from Legal__c where Id =:recordId];
		string loanAppId = legal.Loan_Application__c;
		string appCollId = legal.Application_Collateral__c;
		List<Application_Applicant__c> lstApplicants = [SELECT Id,name,Applicant_Type__c 
		              from Application_Applicant__c where Loan_Application__c =: loanAppId];
		List<Collateral_Owner__c> colltOwner = [Select Id,Application_Applicant__c, Application_Applicant__r.name,Application_Collateral__c,Application_Applicant__r.Applicant_Type__c, HL_Active_Owner__c
		 										from Collateral_Owner__c where Application_Collateral__c =:appCollId];
		Map<String, Collateral_Owner__c> appToOwnerMap = new Map<String,Collateral_Owner__c>();
		for(Collateral_Owner__c coll : colltOwner){
			appToOwnerMap.put(coll.Application_Applicant__c, coll);
		}
		for(Application_Applicant__c app :lstApplicants ){
			ApplicationWrapper appWrap = new ApplicationWrapper();
			appWrap.applicantName = app.name;
			appWrap.applicantType = app.Applicant_Type__c;
			appWrap.applicantId = app.id;
			if(appToOwnerMap.containsKey(app.Id)){
				appWrap.isOwner = appToOwnerMap.get(app.Id).HL_Active_Owner__c;
			}
			appWrapList.add(appWrap);
		}
		return appWrapList;
	}
	@AuraEnabled
	public static List<ApplicationWrapper>  fetchCollateralOwners(string recordId){
		List<ApplicationWrapper> appWrapList = new List<ApplicationWrapper>();
		Legal__c legal = [select Id,Loan_Application__c,Application_Collateral__c from Legal__c where Id =:recordId];
		string loanAppId = legal.Loan_Application__c;
		string appCollId = legal.Application_Collateral__c;
		List<Collateral_Owner__c> colltOwner = [Select Id,Application_Applicant__c, Application_Applicant__r.name,Application_Collateral__c,Application_Applicant__r.Applicant_Type__c, HL_Active_Owner__c
		 										from Collateral_Owner__c where Application_Collateral__c =:appCollId];
		Map<String, Collateral_Owner__c> appToOwnerMap = new Map<String,Collateral_Owner__c>();
		for(Collateral_Owner__c coll : colltOwner){
			appToOwnerMap.put(coll.Application_Applicant__c, coll);
		}
		for(Collateral_Owner__c coll : colltOwner){
			ApplicationWrapper appWrap = new ApplicationWrapper();
			appWrap.applicantName = coll.Application_Applicant__r.name;
			appWrap.applicantType =coll.Application_Applicant__r.Applicant_Type__c;
			appWrap.applicantId = coll.Application_Applicant__c;
			if(appToOwnerMap.containsKey(coll.Application_Applicant__c)){
				appWrap.isOwner = appToOwnerMap.get(coll.Application_Applicant__c).HL_Active_Owner__c;
			}
			appWrapList.add(appWrap);
		}
		System.debug('appWrapList--'+appWrapList);
		 return appWrapList;
	}
	@AuraEnabled
	public static void deleteApplicants(String appId , string recordId){
		Legal__c legal = [select Id,Loan_Application__c,Application_Collateral__c from Legal__c where Id =:recordId limit 1];
		string applCollid = legal.Application_Collateral__c;
		list<Collateral_Owner__c> deleteColl= [SELECT Id,Name,Application_Applicant__r.name,Application_Applicant__r.Applicant_Type__c FROM Collateral_Owner__c where
												Application_Applicant__c =: appId AND Application_Collateral__c =: applCollid];
		if(deleteColl.size() > 0){
			//delete deleteColl;
			for(Collateral_Owner__c coll : deleteColl){
				coll.HL_Active_Owner__c = false;
				coll.HL_Status__c = 'Sent for Approval';
			}
			Update deleteColl;
		}	
	}
	@AuraEnabled
    public static void insertApplicants(String appId, String recordId) {
		if (appId == null) {
			return;
		}
		Legal__c legal = [
			SELECT Id, Application_Collateral__c 
			FROM Legal__c 
			WHERE Id = :recordId 
			LIMIT 1
		];
		List<Collateral_Owner__c> collOwnerList = new List<Collateral_Owner__c>();
		List<Collateral_Owner__c> existingOwner = [Select Id, Application_Applicant__c from Collateral_Owner__c where Application_Collateral__c =: legal.Application_Collateral__c and Application_Applicant__c =: appId];
		Collateral_Owner__c colOwnerVar = new Collateral_Owner__c();
		colOwnerVar.Application_Applicant__c = appId;//applicantId;
		colOwnerVar.Application_Collateral__c = legal.Application_Collateral__c;
		colOwnerVar.HL_Active_Owner__c = true;
		colOwnerVar.HL_Status__c = '';
		if (!existingOwner.isEmpty()) {
			colOwnerVar.Id = existingOwner[0].Id;
		}
		Upsert colOwnerVar;
	}
	@AuraEnabled
	public static Boolean isCreditManager(String recordId){
		Legal__c legal = [
			SELECT Id, Application_Collateral__c, Stage__c 
			FROM Legal__c 
			WHERE Id = :recordId 
			LIMIT 1
		];
		User u = [SELECT Id, Contact.AccountId FROM User where Id =: UserInfo.getUserId()];
		List<AccountTeamMember> accMembers = [Select id from AccountTeamMember where UserId =: UserInfo.getUserId() and TeamMemberRole = 'Legal Admin'];
		Profile pr = [Select Id, Name from Profile where id =: UserInfo.getProfileId()];
		if(accMembers.size()>0 && (legal.Stage__c == 'Assigned to Admin' || legal.Stage__c == 'Submitted by Executive')){
			return true;
		}
		else{
			return false;
		}
	}
	@AuraEnabled
	public static Boolean checkRecordStatus(String recordId){
		Boolean result = false;
		Profile pr = [Select Id, Name from Profile where id =: UserInfo.getProfileId()];
		List<Legal__c> legal = [
			SELECT Id, Application_Collateral__c, Stage__c 
			FROM Legal__c 
			WHERE Id = :recordId 
			LIMIT 1
		];
		if(!legal.isEmpty()){
			List<Collateral_Owner__c> collList = [SELECT Id,Name,Application_Applicant__r.name,Application_Applicant__r.Applicant_Type__c, HL_Status__c, HL_Active_Owner__c FROM Collateral_Owner__c where
													Application_Collateral__c =: legal[0].Application_Collateral__c and HL_Status__c = 'Sent for Approval'];
			if( pr.Name.equalsIgnoreCase('Credit Manager') && legal[0].Stage__c == 'Submitted by Admin' && !collList.isEmpty()){
				result = true;
			}
		}
		return result;
	}
	@AuraEnabled
	public static void permanentDeleteOwners(String recordId){
		List<Legal__c> legal = [
			SELECT Id, Application_Collateral__c, Stage__c 
			FROM Legal__c 
			WHERE Id = :recordId 
			LIMIT 1
		];
		List<Collateral_Owner__c> ownerList = [SELECT Id,Name,Application_Applicant__r.name,Application_Applicant__r.Applicant_Type__c, HL_Status__c, HL_Active_Owner__c FROM Collateral_Owner__c where
													Application_Collateral__c =: legal[0].Application_Collateral__c and HL_Status__c = 'Sent for Approval' and HL_Active_Owner__c = false];
		if(!ownerList.isEmpty()){
			Delete ownerList;
		}
	}
	@AuraEnabled
	public static void revertOwnerDeletionRequest(String recordId){
		List<Legal__c> legal = [
			SELECT Id, Application_Collateral__c, Stage__c 
			FROM Legal__c 
			WHERE Id = :recordId 
			LIMIT 1
		];
		List<Collateral_Owner__c> ownerList = [SELECT Id,Name,Application_Applicant__r.name,Application_Applicant__r.Applicant_Type__c, HL_Status__c, HL_Active_Owner__c FROM Collateral_Owner__c where
													Application_Collateral__c =: legal[0].Application_Collateral__c and HL_Status__c = 'Sent for Approval' and HL_Active_Owner__c = false];
		if(!ownerList.isEmpty()){
			for(Collateral_Owner__c coll : ownerList){
				coll.HL_Status__c = '';
				coll.HL_Active_Owner__c = true;
			}
			Update ownerList;
		}
	}
	public class ApplicationWrapper{
		@AuraEnabled public string applicantId;
		@AuraEnabled public string applicantType;
		@AuraEnabled public string applicantName;
		@AuraEnabled public Boolean isOwner;
	}
	public class CollWrapper{
		@AuraEnabled public String collateralId;
		@AuraEnabled public String applicantName;
		@AuraEnabled public String applicantType;
		@AuraEnabled public boolean isCollOnwer ;
	}
    //HL_Ayushi - 28/10
	@AuraEnabled(cacheable=true)
    public static String getRecordTypeName(Id recordId) {
        try {
            // This dynamically figures out the object type (e.g., Legal__c)
            String objectApiName = recordId.getSObjectType().getDescribe().getName();
            
            // Build and run a query to get the RecordType Name
            String query = 'SELECT RecordType.Name FROM ' + objectApiName + ' WHERE Id = :recordId LIMIT 1';
            SObject record = Database.query(query);
            
            // Return the name
            return (String)record.getSObject('RecordType').get('Name');
            
        } catch (Exception e) {
            System.debug('Error in getRecordTypeName: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
}