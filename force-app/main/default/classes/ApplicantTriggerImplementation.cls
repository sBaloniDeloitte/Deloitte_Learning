/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-05-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class ApplicantTriggerImplementation {
    public static void updateScoreSegmentOnOpp(List<Application_Applicant__c> keyApplicantList){
        Map<Id, String> oppScoreMap = new Map<Id, String>();
        for(Application_Applicant__c app : keyApplicantList){
            oppScoreMap.put(app.Loan_Application__c, app.Scorecard_Category__c);
        }
        if(oppScoreMap.isEmpty()){ 
            return; 
        }

        List<Opportunity> oppToUpdate = new List<Opportunity>();
        for(Opportunity opp : [SELECT Id, Score_Segment__c 
                               FROM Opportunity 
                               WHERE Id IN :oppScoreMap.keySet() 
                               AND HL_AHL_Vertical__c = 'AHL']){
            if(opp.Score_Segment__c != oppScoreMap.get(opp.Id)){
                opp.Score_Segment__c = oppScoreMap.get(opp.Id);
                oppToUpdate.add(opp);
            }
        }
        if(!oppToUpdate.isEmpty()){
            update oppToUpdate;
        }
    }

    public static void concatenateName(List<Application_Applicant__c> newRecords){

        for(Application_Applicant__c itr : newRecords) {

            string name = itr.Company__c;
            String existingName = itr?.Name;//sanwar(15/12/2025)
            String firstName = itr?.First_Name__c;//sanwar(15/12/2025)
            String middleName = itr?.Middle_Name__c;//sanwar(15/12/2025)
            String lastName = itr?.Last_Name__c;//sanwar(15/12/2025)
			System.debug('name>'+name);
            System.debug('existingName>'+existingName);
            System.debug('first name>'+itr.First_Name__c);
            System.debug('last Name>'+itr.Last_Name__c);
            if(itr.Customer_Type__c == Constants.CUSTOMER_TYPE_INDIVIDUAL || itr.Applicant_Type__c == 'Builder' || itr.Applicant_Type__c == 'Seller'){
                if(String.isNotBlank(firstName) || String.isNotBlank(middleName) || String.isNotBlank(lastName)){//sanwar(15/12/2025)
                    name = (string.isNotBlank(firstName) ? firstName : '') + (string.isNotBlank(middleName) ? ' '+ middleName : '') + (string.isNotBlank(lastName) ? ' '+ lastName : '');
                }else {//sanwar(15/12/2025)
                    name = existingName;
                }
                itr.Company__c = null;
            }
            else{
                name = itr.Name_of_Organization__c;
                System.debug('name 1>'+name);
            }
           /* else{
                itr.First_Name__c = null;
                itr.Middle_Name__c = null;
                itr.Last_Name__c = null;
            }*/

            itr.Name = name;
            System.debug('Name >'+itr.Name);
        }
    }
    @future
    public static void createDocumentChecklistNonIndividual(Set<Id> appIds){
        List<Document_Master__c> docMasterList = [SELECT Id, Name, Is_Required__c FROM Document_Master__c WHERE Is_Active__c = true And Requirement_At__c = 'Loan Application' And Document_Category__c = 'Non-Individual Draft Documents'];
        if(!docMasterList.isEmpty()){
            List<Document_Details__c> documentListToInsert = new List<Document_Details__c>();
            Map<string, List<string>> leadToExistingDocMap = new Map<string, List<string>>();
            for(Document_Details__c itr : [Select Id, Document_Master__c, Applicant__c From Document_Details__c Where Applicant__c In : appIds Order By Lead__c]){
                if(!leadToExistingDocMap.containsKey(itr.Applicant__c)){
                    leadToExistingDocMap.put(itr.Applicant__c, new List<string>{itr.Document_Master__c});
                }
                else{
                    leadToExistingDocMap.get(itr.Applicant__c).add(itr.Document_Master__c);
                }
            }
            //system.debug('leadToExistingDocMap: '+leadToExistingDocMap);
            
            for(Application_Applicant__c itr : [Select Id,Loan_Application__c from Application_Applicant__c where Id IN : appIds]){
                List<string> existingDocIdList = new list<string>();
                //system.debug('itr.Id: '+itr.Id);
                if(leadToExistingDocMap.containsKey(itr.Id)){
                    existingDocIdList = leadToExistingDocMap.get(itr.Id);
                }
                //system.debug('existingDocIdList: '+existingDocIdList);
                for(Document_Master__c itrDM : docMasterList){
                    if(!existingDocIdList.contains(itrDM.Id)){
                        Document_Details__c documentObj = new Document_Details__c();
                        documentObj.Name = itrDM.Name;
                        documentObj.Applicant__c = itr.Id;
                        documentObj.Document_Master__c = itrDM.Id;
                        documentObj.Status__c = Constants.STATUS_PENDING;
                        documentObj.Is_Required__c = itrDM.Is_Required__c;
                        documentObj.Loan_Application__c = itr.Loan_Application__c;
                        documentListToInsert.add(documentObj);
                    }
                }
            }
            if(!documentListToInsert.isEmpty())
                insert documentListToInsert;
        }
	}
    public static void populateAdditionalDocs(List<Application_Applicant__c> lstLoanApplication) {
        Integer itemToProcess = lstLoanApplication.size();
        System.debug('itemToProcess '+itemToProcess);
        

            for(Application_Applicant__c la : lstLoanApplication){
                createDocumentCheckList('fromLoan',la.Loan_Application__c,la.Id,la.Applicant_Type__c);
            }
        // }
    }

    public static void createDocumentCheckList(String fromLoan, String loanId, String applicantId, String applicantType){
        COMM_DocumentDetailsScreenController.executeMapping(fromLoan,loanId,applicantId,applicantType);
    }
    public static void verifyKycDoc(Set<Id> applicantIds, String docType) {
            // Query Document_Master__c records to get the names
            System.debug('89 '+applicantIds);
         String pattern = '%' + docType + '%';
            List<Document_Master__c> docMasters = [SELECT Name FROM Document_Master__c WHERE Name LIKE :pattern];
                if (docMasters.isEmpty()) {
        System.debug('No matching Document_Master__c records found. Exiting method.');
        return;
    }
        // Build the dynamic query string
            String query = 'SELECT Id, Verification_Status__c FROM Document_Details__c WHERE Applicant__c IN :applicantIds AND (';
            Boolean first = true;
            for (Document_Master__c master : docMasters) {
                if (!first) {
                    query += ' OR ';
                }
                query += 'Name LIKE \'%' + master.Name + '%\'';
                first = false;
            }
            query += ')';
    
            // Execute the dynamic query
            List<Document_Details__c> docDetails = Database.query(query);
    
            // Update the Verification_Status__c field to 'Verified'
            for (Document_Details__c doc : docDetails) {
                doc.Verification_Status__c = 'Verified';
                doc.Doc_Verified_By__c = UserInfo.getUserId();
            }
            // Perform the update
            if (!docDetails.isEmpty()) {
                update docDetails;
            }
        }

    public static void shareHoldingMaxValueValidation(Set<Id> applicantIds, Decimal shareHondlingPercent) {
        List<Application_Applicant__c> appList = [SELECT Id, Loan_Application__c FROM Application_Applicant__c WHERE Id IN :applicantIds LIMIT 1];
        if (appList.isEmpty()) return;
        Id loanId = appList[0].Loan_Application__c;
        if (loanId != null) {
            List<Application_Applicant__c> applicantList = [SELECT Id, Share_Holding_Percentage__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId];
            Decimal totalShareHoldingPercentage = 0;
            for (Application_Applicant__c applicant : applicantList) {
                if(applicant.Share_Holding_Percentage__c != null && applicant.Id != appList[0].Id) {
                    totalShareHoldingPercentage += applicant.Share_Holding_Percentage__c;
                }
            }
            totalShareHoldingPercentage += shareHondlingPercent;
            List<Application_Applicant__c> newRecords = (List<Application_Applicant__c>) Trigger.new;
            if (totalShareHoldingPercentage > 100) {
                String errorMsg = 'Validation Error: Total Share Holding Percentage across all applicants exceeds 100%. Current total: ' 
                                + totalShareHoldingPercentage + '%. Please adjust percentages before saving.';
                for (Application_Applicant__c updatedApp : newRecords) {
                    if (applicantIds.contains(updatedApp.Id)) {
                        updatedApp.Share_Holding_Percentage__c.addError(errorMsg);
                    }
                }
            }
        }
    }

    public static void syncCustomer(Set<Id> applicantIds) {
        System.debug('applicantIds : '+applicantIds);
        String accRecTypeId = Utility.getRecordTypeIdByDeveloperName('Account','Customer');
        Map<Id, Application_Applicant__c> applicantMapByCustomerId = new Map<Id, Application_Applicant__c>();
        List<Application_Applicant__c> appList = [SELECT Id, Name, First_Name__c, Middle_Name__c, Last_Name__c, Customer__c FROM Application_Applicant__c WHERE Id IN :applicantIds AND Customer__c != null];
        if (!appList.isEmpty()) {
            for (Application_Applicant__c app : appList) {
                applicantMapByCustomerId.put(app.Customer__c, app);
            }
        }
        if (!applicantMapByCustomerId.isEmpty()) {
            List<Account> accListToUpdate = [SELECT Id, Name, First_Name__c, Middle_Name__c, Last_Name__c FROM Account WHERE Id IN :applicantMapByCustomerId.keySet() AND RecordTypeId =: accRecTypeId];
            for (Account acc : accListToUpdate) {
                Application_Applicant__c app = applicantMapByCustomerId.get(acc.Id);
                acc.First_Name__c = app.First_Name__c;
                acc.Middle_Name__c = app.Middle_Name__c;
                acc.Last_Name__c = app.Last_Name__c;
                acc.Name = app.Name;
            }
        
            if (!accListToUpdate.isEmpty()) {
                update accListToUpdate;
            }
        }
    }
    public static void updatePrimaryAppNameOnOpp(List<Application_Applicant__c> applicantList){
        try{

        List<Opportunity> oppList = new List<Opportunity>();
        for(Application_Applicant__c app : applicantList){
            Opportunity opp  = new Opportunity();
            opp.Id = app.Loan_Application__c;
            opp.Applicant_Name__c = app.Applicant_Name__c;
            oppList.add(opp);
        }
        if(oppList.size()>0){
            update oppList;
        }
        }catch(exception e){
            system.debug('Error message: '+e.getMessage()+' line no: '+e.getLineNumber());
        }
    }

    public static void updateConsent(List<Application_Applicant__c> applicantList){
        try{
        List<Application_Applicant__c> appList = new List<Application_Applicant__c>();
        for(Application_Applicant__c app : applicantList){
            Application_Applicant__c objApp = new Application_Applicant__c();
            objApp.Id = app.Id;
            objApp.Consent_Status__c = '';
            objApp.Is_Consent_Received__c = false;
            appList.add(objApp);
        }
        if(!appList.isEmpty()){
          update appList;
        }
        }catch(Exception ex){
        System.debug('Error Message: '+ex.getMessage()+' Line No: '+ex.getLineNumber());
    }
    }

    public static void populateEmploymentType(List<Application_Applicant__c> applicantList){
        // Set<Id> loanIds = new Set<Id>();
        // for(Application_Applicant__c app : applicantList){
        //     loanIds.add(app.Loan_Application__c);
        // }
        // List<Application_Applicant__c> mainAppList = [Select Id, Loan_Application__c, Sub_Employment_Type_Non_Individual__c, Sector__c from Application_Applicant__c where Loan_Application__c in: loanIds and Applicant_Type__c = 'Primary Applicant'];
        // Map<String,Application_Applicant__c> loanToMainAppMap = new Map<String,Application_Applicant__c>();
        // for(Application_Applicant__c app : mainAppList){
        //     loanToMainAppMap.put(app.Loan_Application__c, app);
        // }
        // List<Application_Applicant__c> applicantToUpdateList = new List<Application_Applicant__c>();
        for(Application_Applicant__c app : applicantList){
            // if(loanToMainAppMap.containsKey(app.Loan_Application__c)){
            //     Application_Applicant__c mainApp = loanToMainAppMap.get(app.Loan_Application__c);
            //     if(mainApp != null){
                    app.Sector__c = 'Others';
                    app.Sub_Employment_Type_Non_Individual__c = 'Others';
                    app.Industry__c= 'OTHERS';
            //     }
            // }
        }
        /*if(!applicantToUpdateList.isEmpty()){
            Update applicantToUpdateList;
        }*/
    }

    public static void populateEmploymentInCoAppType(Map<String, Application_Applicant__c> applicantMap){
        List<Application_Applicant__c> applicantToUpdate= new List<Application_Applicant__c>();
        List<Application_Applicant__c> applicants = [SELECT Id, Customer_Profile__c, Loan_Application__c FROM Application_Applicant__c WHERE Loan_Application__c IN : applicantMap.keySet() AND Applicant_Type__c = 'Co Applicant' AND Customer_Profile__c = 'Non Working'];
        for(Application_Applicant__c app:applicants){
            if(app.Customer_Profile__c!= null){
                if(applicantMap.containsKey(app.Loan_Application__c)){
                    Application_Applicant__c mainApp = applicantMap.get(app.Loan_Application__c);
                    if(mainApp != null ){
                        if(mainApp.Sector__c!= null){
                            app.Sector__c = mainApp.Sector__c;
                        }
                        if(mainApp.Sub_Employment_Type_Non_Individual__c!= null){
                            app.Sub_Employment_Type_Non_Individual__c = mainApp.Sub_Employment_Type_Non_Individual__c;
                        }
                        applicantToUpdate.add(app);
                    }
                }
            }            
        }
        if(applicantToUpdate.size()>0){
            update applicantToUpdate;
        }
    }
    //Added by Satyam
    public static void updateAarohiFlag(List<Application_Applicant__c> appList,Set<Id> oppIdSet){
        if(appList.size()>0){
            List<Opportunity> oppListToUpdate = new List<Opportunity>();
            for(Application_Applicant__c app :appList){
                if(app.Gender__c=='Female'){
                   Opportunity oppDet = new Opportunity();
                   oppDet.id=app.Loan_Application__c;
                   oppDet.Women_Entrepreneurship__c = 'YES' ;
                   oppListToUpdate.add(oppDet);
                }
                else{
                    Opportunity oppDet = new Opportunity();
                    oppDet.id=app.Loan_Application__c;
                    oppDet.Women_Entrepreneurship__c = 'No' ;
                    oppListToUpdate.add(oppDet);
                }
            }
          
            if(oppListToUpdate.size()>0){
                update oppListToUpdate ;
            }
        }
    }
}