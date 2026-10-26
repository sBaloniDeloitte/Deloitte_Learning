/**
                                     * @File Name : HL_LoanApplicationActionController.cls
                                     * @Description :
                                     * @Author :
                                     * @Last Modified By :
                                     * @Last Modified On : October 8, 2025
                                     * @Modification Log :
                                     *==============================================================================
                                     * Ver | Date | Author | Modification
                                     *==============================================================================
                                     * 1.0 | October 8, 2025 |   | Initial Version
                                     **/
                                    
                                    public class HL_LoanApplicationActionController {
                                        static string conLabels = 'Days_to_process_loan';
                                        
                                        public static Map<string, string> constants = Utility.getConstants(conLabels);
                                        //getting the value of constants
                                        @AuraEnabled
                                        public static Map<string, string> getConstants(){
                                            return constants;
                                        }
                                        
                                        @AuraEnabled
                                        public static List<String> sanctionLetterGeneratedValidation(String recordId) {
                                            try {
                                                List<String> errorMessages = new List<String>();
                                                // List<Bank_Statement_Analysis__c> lstBA = [SELECT Id, Bank_Details__c 
            //                                             FROM Bank_Statement_Analysis__c 
            //                                             WHERE Bank_Details__r.Application_Applicant__r.Loan_Application__c = :recordId
            //                                             AND (Bank_Details__r.Is_Repayment_Account__c = true OR Bank_Details__r.Is_Disbursal_Account__c = true)
            //                                             AND (Bank_Details__r.IFSC__c = null OR Bank_Details__r.Account_Number__c = null)];
                                                // if(!lstBA.isEmpty()){
                                                    //     errorMessages.add('Ensure that all the disbursement and repayment bank accounts have IFSC code and account number updated.');
                                                // }
                                                // 1. Fetch active sanction letter
                                                List<Document_Details__c> sanctionLetters = [  SELECT Id, Content_Document_Id__c, CreatedDate, Active__c FROM Document_Details__c  WHERE Loan_Application__c = :recordId AND Name = 'Sanction Letter' AND Active__c = true ORDER BY CreatedDate DESC LIMIT 1];
                                                
                                                if (sanctionLetters.isEmpty()) {
                                                    errorMessages.add('Sanction Letter is not yet generated for the application to move to Disbursement.');
                                                    return errorMessages; // No point continuing if sanction letter doesn't exist
                                                }
                                                
                                                DateTime sanctionLetterCreatedDate = sanctionLetters[0].CreatedDate;
                                                
                                                // 2. Fetch latest Loan Transaction for the loan
                                                List<Loan_Transaction__c> loanTransactions = [ SELECT Id, LastModifiedDate FROM Loan_Transaction__c WHERE Loan_Application__c = :recordId ORDER BY LastModifiedDate DESC LIMIT 1 ];
                                                
                                                if (!loanTransactions.isEmpty()) {
                                                    DateTime txnLastModified = loanTransactions[0].LastModifiedDate;
                                                    
                                                    // Check if Loan Transaction was modified after Sanction Letter
                                                    if (txnLastModified > sanctionLetterCreatedDate) {
                                                        errorMessages.add('Loan Transaction was modified after the Sanction Letter was generated. Please regenerate the Sanction Letter.');
                                                    }
                                                }
                                                
                                                // 3. Fetch last repayment schedule generation info from Integration_Details
                                                List<Integration_Details__c> scheduleRecord = [ SELECT Id, CreatedDate FROM Integration_Details__c  WHERE Loan_Application__c = :recordId AND Calling_Source__c = 'Loan Scheduler Create Charges' AND Object_Name__c = 'Document_Details__c' ORDER BY CreatedDate DESC LIMIT 1];
                                                
                                                if (!scheduleRecord.isEmpty() && !loanTransactions.isEmpty()) {
                                                    DateTime scheduleCreated = scheduleRecord[0].CreatedDate;
                                                    DateTime txnLastModified = loanTransactions[0].LastModifiedDate;
                                                    
                                                    if (txnLastModified > scheduleCreated) {
                                                        errorMessages.add('Loan Transaction was modified after Repayment Schedule generation. Please regenerate the schedule before proceeding.');
                                                    }
                                                }
                                                
                                                return errorMessages;
                                                
                                            } catch (Exception e) {
                                                throw new AuraHandledException('Validation Error: ' + e.getMessage());
                                            }
                                        }
                                        
                                        @AuraEnabled
                                        public static String quickActionSave(String loanApplicationId,String quickActionName,String remarks,String userName, String selectedStage){
                                            try{
            utility.ahlOpportunityOwnerChangeByPass=true;
Utility.byPassOwnershipUpdate = true;
                                                System.debug('quickActionSave>>');
                                                List<Application_Applicant__Share> shareList = new List<Application_Applicant__Share>();
                                                System.debug('remarks--'+remarks);
                                                String returnMessage = '';
                                                String buttonName = 'Mark as complete';
                                                if(quickActionName == 'Send_Back'){
                                                    buttonName = 'Send Back';
                                                }
                                                List<Application_Applicant__c> updatedApplicationApplicant = new List<Application_Applicant__c>();
                                                Boolean checkAndUpdateDocDetails = false;
                                                List<Document_Details__c> updatedDocDetailsList = new List<Document_Details__c>();
                                                
                                                List<String> oppListId =  new  List<String> ();
                                                Opportunity currentLoanApplicationDetails = [SELECT Id,Name,StageName,Sub_stage__c,owner.Email,owner.Name, Send_Back_Remarks__c
                                                         FROM Opportunity 
                                                         WHERE Id = :loanApplicationId 
                                                         LIMIT 1];
                                                String currentUserProfile = [SELECT Name,Profile.Name 
                                         FROM User 
                                         WHERE Id = :UserInfo.getUserId() 
                                         LIMIT 1].Profile.Name;
                                                
                                                String newProfile = '';
                                                Boolean createSalesOppTeamMember = false;
                                                
                                                
                                                System.debug('currentUserProfile----'+ currentUserProfile);
                                                System.debug('currentLoanApplicationDetails.StageName---'+currentLoanApplicationDetails.StageName);
                                                System.debug('buttonName----'+buttonName);
                                                String stageName= currentLoanApplicationDetails.StageName;
                                                String query= 'SELECT Id,Button__c,Message__c,Profile__c,Stage_from__c,Stage_to__c,Sub_stage_from__c,Sub_stage_to__c,TAT_Code__c FROM StagechangeRules__mdt WHERE Stage_from__c = :stageName AND Profile__c = :currentUserProfile AND Button__c = :buttonName';
                                                
                                                if(currentLoanApplicationDetails.StageName== 'PSV' && buttonName == 'Send Back'){
                                                    query = query + ' AND Stage_to__c= :selectedStage';
                                                }
                                                System.debug('queryyy---'+query);
                                                List<StagechangeRules__mdt> stageChangeMetadata = Database.query(query);
                                                // List<StagechangeRules__mdt> stageChangeMetadata = [SELECT Id,Button__c,Message__c,Profile__c,Stage_from__c,Stage_to__c,Sub_stage_from__c,Sub_stage_to__c,TAT_Code__c 
            //                                                    FROM StagechangeRules__mdt
            //                                                    WHERE Stage_from__c = :currentLoanApplicationDetails.StageName
            //                                                    AND Profile__c = :currentUserProfile
            //                                                    AND Button__c = :buttonName];
            //                                                    
                                                System.debug('stageChangeMetadata----'+ stageChangeMetadata);
                                                System.debug('currentLoanApplicationDetails.StageName>>'+currentLoanApplicationDetails.StageName);
                                                System.debug('currentUserProfile>>'+currentUserProfile);
                                                System.debug('buttonName>>'+buttonName);
                                                 System.debug('123>>>'+[SELECT Id,Button__c,Message__c,Profile__c,Stage_from__c,Stage_to__c,Sub_stage_from__c,Sub_stage_to__c,TAT_Code__c FROM StagechangeRules__mdt]);
                                                if (quickActionName == 'Send_Back' || buttonName == 'Mark as complete') {
                                                    List<ProcessInstanceWorkitem> procInstance = [
                    SELECT Id, ProcessInstanceId, ActorId FROM ProcessInstanceWorkitem
                    WHERE ProcessInstance.TargetObjectId = :loanApplicationId AND ProcessInstance.Status = 'Pending'
                ];
                                                    if (!procInstance.isEmpty()) {
                                                        if(buttonName == 'Send Back' && procInstance[0].ActorId != UserInfo.getUserId()){
                                                            return 'Loan application cannot be sent back as an approval process is already in progress.';
                                                        }else if(buttonName == 'Send Back' && procInstance[0].ActorId == UserInfo.getUserId()){
                                                            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                                                            req.setWorkitemId(procInstance[0].Id);
                                                            req.setAction('Removed');
                                                            Approval.ProcessResult result = Approval.process(req);
                                                            if (result.isSuccess()) {
                                                                System.debug('Approval process recall successful');
                                                            } else {
                                                                System.debug('Failed to recall approval process');
                                                            }
                                                        }
                                                        if(buttonName == 'Mark as complete'){
                                                            return 'Loan application cannot be marked as complete as an approval process is already in progress.';
                                                        }
                                                    }
                                                }
                                                if(!stageChangeMetadata.isEmpty()){
                                                    List<Opportunity> oppList = new List<Opportunity>();
                                                    for(StagechangeRules__mdt metadataRecords : stageChangeMetadata){
                                                        Set<String> metadataSubStages = new Set<String>(metadataRecords.Sub_stage_from__c.split(';'));
                                                        System.debug('metadataSubStages----'+ metadataSubStages);
                                                        Set<String> currentAppSubStage = new Set<String>(currentLoanApplicationDetails.Sub_stage__c.split(';'));
                                                        System.debug('currentAppSubStage----'+ currentAppSubStage);
                                                        Boolean containsSubStage = metadataSubStages.equals(currentAppSubStage);
                                                        if(containsSubStage){
                                                            System.debug('containsSubStage'+containsSubStage);
                                                            if(!oppListId.contains(currentLoanApplicationDetails.id)){
                                                                System.debug('inside if');
                                                                Opportunity newUpdatedOpportunity = new Opportunity();
                                                                newUpdatedOpportunity.Id = currentLoanApplicationDetails.Id;
                                                                newUpdatedOpportunity.StageName = metadataRecords.Stage_to__c;
                                                                newUpdatedOpportunity.Sub_stage__c = metadataRecords.Sub_stage_to__c;
                                                                newProfile = AHL_LoanApplicationActionController.subStageTONewole(metadataRecords.Sub_stage_to__c);
                                                                // if(buttonName != 'Mark as complete' && currentLoanApplicationDetails.StageName == 'Sales login' && currentLoanApplicationDetails.Sub_stage__c == 'Login in-progress'){
                                                                    //     createSalesOppTeamMember = true;
                                                                    
                                                                // }
                                                                if(quickActionName == 'Send_Back' && metadataRecords.Stage_to__c == 'Sales login'){
                                                                    newUpdatedOpportunity.toggleHomePage__c = true;
                                                                    newProfile = 'Sales';
                                                                }
                                                                
                                                                
                                                                if(quickActionName == 'Send_Back' && (metadataRecords.Stage_to__c == 'Credit Underwriting' || metadataRecords.Stage_to__c == 'Sales login')){
                                                                    newUpdatedOpportunity.Approval_Status__c = 'In Progress';
                                                                    newUpdatedOpportunity.Approval_Sub_Status__c = '';
                                                                    if (currentLoanApplicationDetails.Send_Back_Remarks__c != null) {
                                                                newUpdatedOpportunity.Send_Back_Remarks__c = currentLoanApplicationDetails.Send_Back_Remarks__c + ' || { Send Back } ' + ' { ' + metadataRecords.Stage_from__c + ' to ' + metadataRecords.Stage_to__c + ' } ' + remarks;
                                                            } else {
                                                        newUpdatedOpportunity.Send_Back_Remarks__c = '{ Send Back } ' + ' { ' + metadataRecords.Stage_from__c + ' to ' + metadataRecords.Stage_to__c + ' } ' + remarks;
                                                    }
                                                    newUpdatedOpportunity.Resanction__c = true;
                                                    if(quickActionName == 'Send_Back' && metadataRecords.Stage_to__c == 'Sales login'){
                                                        
                                                        checkAndUpdateDocDetails = true;
                                                        
                                                    }
                                                }
                                                else {
                                                    if (currentLoanApplicationDetails.Send_Back_Remarks__c != null) {
                                            newUpdatedOpportunity.Send_Back_Remarks__c = currentLoanApplicationDetails.Send_Back_Remarks__c + ' || { Mark as complete } ' + ' { ' + metadataRecords.Stage_from__c + ' to ' + metadataRecords.Stage_to__c + ' } ' + remarks;
                                        } else {
                                    newUpdatedOpportunity.Send_Back_Remarks__c =  '{ Mark as complete } ' + ' { ' + metadataRecords.Stage_from__c + ' to ' + metadataRecords.Stage_to__c + ' } ' + remarks;
                                }
                            }
                            
                            newUpdatedOpportunity.Is_Send_Back__c = True;
                            returnMessage = metadataRecords.Message__c;
                            oppList.add(newUpdatedOpportunity);
                            oppListId.add(currentLoanApplicationDetails.id);
                            // if(metadataRecords.TAT_Code__c != null){
                            //     List<TAT__c> tatRecList = Utility.insertTATRecords(metadataRecords.TAT_Code__c, loanApplicationId, '');
                            //     if(tatRecList.size()>0){
                            //         insert tatRecList;
                            //     }
                            // }
                            break;
                        }
                    }
                }
                if(quickActionName == 'Send_Back'){
                    
                    List<OpportunityTeamMember> allOppTeamMember = [SELECT Id,TeamMemberRole,UserId ,OpportunityId,User.ManagerId,Opportunity.Lead__r.Channel__c,
                                                                    Opportunity.Lead__r.Dsa_Area_Manager__c,Opportunity.Sourcing_Manager__c
                                                                    FROM OpportunityTeamMember 
                                                                    WHERE OpportunityId = :loanApplicationId
                                                                    AND Associated_With_Loan_Application__c = true
                                                                    ];
                    System.debug('allOppTeamMember>>>'+allOppTeamMember);
                    
                    
                    //List<Id>applicableUserIds = new List<Id>();
                    Map<Id,Id>oppIdToOwner = new Map<Id,Id>();
                    OpportunityTeamMember editAccessOtm = NULL;
                    Boolean isSales = false;
                    String managerId = null;
                    List<OpportunityTeamMember>updatedOtm = new List<OpportunityTeamMember>();
                    for(OpportunityTeamMember otm : allOppTeamMember){
                        System.debug('otm.TeamMemberRole>>'+otm.TeamMemberRole);
                        System.debug('newProfile>>'+newProfile);
                        //String profileToCompare = (otm.TeamMemberRole == 'OPS Maker' || otm.TeamMemberRole == 'OPS Author') ? 'OPS' : otm.TeamMemberRole;
                        
                        // System.debug('profileToCompare>>'+profileToCompare);
                        
                        //System.debug('otm.TeamMemberRole.contains(newProfile)>>'+newProfile.toLowerCase().contains(otm.TeamMemberRole.toLowerCase()));
                        //System.debug('newProfile.toLowerCase().contains(profileToCompare)>>'+newProfile.toLowerCase().contains(profileToCompare.toLowerCase()));
                        if (otm.TeamMemberRole != null && newProfile == otm.TeamMemberRole){
                            System.debug('270>>>');
                            OpportunityTeamMember newOtm = new OpportunityTeamMember();
                            newOtm.Id = otm.Id;
                            newOtm.OpportunityAccessLevel = 'Edit';
                            updatedOtm.add(newOtm);
                            System.debug('updatedOtm>>'+updatedOtm);
                            oppIdToOwner.put(otm.OpportunityId,otm.UserId);
                            editAccessOtm = otm;
                            if(otm.TeamMemberRole == 'Sales'){
                                isSales = true;
                                //managerId = otm.User.ManagerId;
                                managerId = otm.Opportunity.Lead__r.Channel__c != 'Direct' ? otm.Opportunity.Lead__r.Dsa_Area_Manager__c : otm.Opportunity.Sourcing_Manager__c;
                            }
                        }
                        
                    }
                    System.debug('managerId>.'+managerId);
                    System.debug('isSales>>'+isSales);
                    
                    if(isSales){
                        
                        List<OpportunityTeamMember> salesManagerOtm = [SELECT OpportunityId,Opportunity.StageName,Opportunity.OwnerId,UserId,Opportunity.Branch_Master__c 
                                                                        FROM OpportunityTeamMember
                                                                        WHERE OpportunityId = :loanApplicationId
                                                                        AND Associated_With_Loan_Application__c = false
                                                                         AND UserId = :managerId
                                                        ];
                        System.debug('salesManagerOtm>>'+salesManagerOtm);
                        if(!salesManagerOtm.isEmpty()){
                            salesManagerOtm[0].OpportunityAccessLevel = 'Edit';
                            updatedOtm.add(salesManagerOtm[0]);
                            List<Application_Applicant__c> applicants = [SELECT Id, OwnerId, Loan_Application__c 
                                                                               FROM Application_Applicant__c
                                                                               WHERE Loan_Application__c = :loanApplicationId];
                            System.debug('applicants>>'+applicants);
                            
                            for(Application_Applicant__c app : applicants){
                                Application_Applicant__Share shareApplicant = new Application_Applicant__Share();
                                shareApplicant.parentId = app.Id;
                                shareApplicant.UserOrGroupId = salesManagerOtm[0].UserId;
                                shareApplicant.AccessLevel = 'Edit';
                                shareList.add(shareApplicant);
                                
                            }
                            System.debug('shareList>>'+shareList);
                        }
                        System.debug('updatedOtm>>'+updatedOtm);
                        if(!updatedOtm.isEmpty()){
                            update updatedOtm;
                        }
                        
                        
                        
                        
                        
                    }else{
                        List<OpportunityTeamMember> updatedOTMS = new List<OpportunityTeamMember>();
                        if(editAccessOtm.TeamMemberRole == 'Credit'){
                            List<OpportunityTeamMember> revokeEditOnOtm = [SELECT Id ,User.Position_Title__c
                                                                     FROM OpportunityTeamMember
                                                                     WHERE TeamMemberRole = 'Sales'
                                                                     AND OpportunityAccessLevel = 'Edit'
                                                                     AND Associated_With_Loan_Application__c = false
                                                                     AND User.Position_Title__c = 'Area Manager'
                                                                     AND OpportunityId = :loanApplicationId];
                            if(!revokeEditOnOtm.isEmpty()){
                                revokeEditOnOtm[0].OpportunityAccessLevel = 'Read';
                                updatedOTMS.add(revokeEditOnOtm[0]);
                            }
                            
                            
                        }
                        
                        editAccessOtm.OpportunityAccessLevel = 'Edit';
                        updatedOTMS.add(editAccessOtm);
                        update updatedOTMS;
                    }
                    
                    System.debug('oppIdToOwner>>'+oppIdToOwner);
                    for(Opportunity opp:oppList){
                        opp.ByPassOwnerChangeValidation__c = true;
                        opp.OwnerId = oppIdToOwner.get(opp.Id);
                    }
                    System.debug('oppList>>'+oppList);
                    
                    
                    List<Application_Applicant__c> applicationApplicantList = [SELECT Id, OwnerId, Loan_Application__c 
                                                                               FROM Application_Applicant__c
                                                                               WHERE Loan_Application__c = :loanApplicationId];
                    System.debug('applicationApplicantList >> ' + applicationApplicantList);
                    for (Application_Applicant__c applicantRec : applicationApplicantList) {
                        Application_Applicant__c updatedApplicationApplicantRec = new Application_Applicant__c();
                        updatedApplicationApplicantRec.Id = applicantRec.Id;
                        System.debug('oppIdToOwner.get(applicantRec.Loan_Application__c)>>'+oppIdToOwner.get(applicantRec.Loan_Application__c));
                        updatedApplicationApplicantRec.OwnerId = oppIdToOwner.get(applicantRec.Loan_Application__c);
                        updatedApplicationApplicant.add(updatedApplicationApplicantRec);
                    }
                    System.debug('updatedApplicationApplicant>>'+updatedApplicationApplicant);
                    
                    
                    
                }
                if(checkAndUpdateDocDetails){
                    List<Document_Details__c> docDetails = [SELECT Id FROM Document_Details__c WHERE Loan_Application__c = :loanApplicationId AND Name = 'Loan Application Form' AND Active__c = true ORDER BY CreatedDate DESC];
                    for(Document_Details__c dd : docDetails){
                        Document_Details__c updatedDocDetails = new Document_Details__c();
                        updatedDocDetails.Id = dd.Id;
                        updatedDocDetails.Active__c = false;
                        updatedDocDetailsList.add(updatedDocDetails);
                        
                    }
                    
                }
                if(!updatedDocDetailsList.isEmpty()){
                    update updatedDocDetailsList;
                    String lightningUrl = System.Url.getOrgDomainUrl().toExternalForm() + '/lightning/r/Opportunity/' + loanApplicationId + '/view';
                    AHL_LoanApplicationActionController.sendLoanApplicationReturnedEmailHTML(currentLoanApplicationDetails.owner.Name,currentLoanApplicationDetails.owner.Email,userName,currentLoanApplicationDetails.Name,remarks,lightningUrl);
                }
                if(currentLoanApplicationDetails.StageName == 'Sales Login'){
                    List<Application_Applicant__c> appList = [
                        SELECT Id, Name,Loan_Application__r.name,Applicant_Type__c,Name_of_Organization__c,Customer_Type__c,Customer_LMS_Id__c,Customer__r.SF_Customer_ID__c, Salutation__c,First_Name__c, Last_Name__c, Company__c, Loan_Application__r.Product__c, Email__c, Mobile_Number__c, Loan_Application__r.Owner.Name FROM Application_Applicant__c 
                        WHERE Loan_Application__c = :currentLoanApplicationDetails.Id 
                    ];
                    

                    //AHL_LoanApplicationActionController.updateLoanSanctionTenureField(currentLoanApplicationDetails.Id);
                    
                    List<Integration_Details__c> communicationList= [SELECT Id FROM Integration_Details__c WHERE Loan_Application__c = :currentLoanApplicationDetails.Id AND Endpoint__c = 'Acknowledge of login'];
                    
                    if (!appList.isEmpty()) {
                        String loanProduct;
                        String messageWrapper;
                        List<product2> productList= [SELECT Id, name, Description FROM product2 WHERE  Loan_Application__c = :currentLoanApplicationDetails.Id AND RecordType.name = 'Variant' AND Product__r.Product__r.name = 'Business Loan'];
                        List<CommunicationEventWrapper.LoginAcknowledgeWrapper> loginAcknowledgeList= new List<CommunicationEventWrapper.LoginAcknowledgeWrapper>();
                        List<String> toAddresses = new List<String>();
                        if(productList.size()>0){
                            loanProduct= productList[0].name;
                        }
                        // Gather all email addresses
                        for (Application_Applicant__c app : appList) {
                            List<String> sfId= app.Customer__r.SF_Customer_ID__c.split('-');
                            String cifNumber = sfId[1].trim();
                            if (!String.isEmpty(app.Email__c)) {
                                toAddresses.add(app.Email__c);
                            }
                            
                            if(app.Applicant_Type__c == 'Primary Applicant'){
                                // loanProduct = app.Loan_Application__r.Product__c;
                                CommunicationEventWrapper.LoginAcknowledgeWrapper loginWrapper = new CommunicationEventWrapper.LoginAcknowledgeWrapper();
                                loginWrapper.Salutation = app.Customer_Type__c == 'Individual' ? (String.isNotBlank(app.Salutation__c) ? app.Salutation__c: '') : 'M/s';
                                loginWrapper.FirstName = String.isNotBlank(app.First_Name__c)? app.First_Name__c :'';
                                loginWrapper.LastName = String.isNotBlank(app.Last_Name__c) ? app.Last_Name__c: '';
                                loginWrapper.CompanyName = app.Customer_Type__c == 'Individual' ? (String.isNotBlank(app.Company__c) ?  app.Company__c: '') :  (String.isNotBlank(app.Name_of_Organization__c) ?  app.Name_of_Organization__c: '');
                                loginWrapper.ProductName = loanProduct != null ? (loanProduct == 'Term Loan' ? 'BL': (loanProduct == 'Flexi Funds' ? 'BD': '')): '';
                                loginWrapper.LANNumber = String.isNotBlank(app.Loan_Application__r.name) ? app.Loan_Application__r.name : '';
                                loginWrapper.CustomerCategory = app.Customer_Type__c == 'Individual' ? 'RETAIL': (app.Customer_Type__c == 'Non Individual' ? 'CORP' :'' );
                                loginWrapper.emailId = String.isNotBlank(app.Email__c) ? app.Email__c: '';
                                loginWrapper.NoofDays = constants.get('Days_to_process_loan');
                                loginWrapper.mobile_number = app.Mobile_Number__c != null ? String.valueOf(app.Mobile_Number__c): '';
                                loginWrapper.applicantType = String.isNotBlank(app.Applicant_Type__c) ? app.Applicant_Type__c: '';
                                loginWrapper.whatsaap_number = app.Mobile_Number__c != null ? String.valueOf(app.Mobile_Number__c): '';
                                loginWrapper.ProductDescription = productList.size()>0 ? (productList[0].Description != null? productList[0].Description : '') : '';
                                loginWrapper.cif = String.isNotBlank(app.Customer_LMS_Id__c) ? app.Customer_LMS_Id__c: cifNumber;
                                loginAcknowledgeList.add(loginWrapper);
                            }
                            
                        }
                        
                        if(communicationList.size()<=0){
                            messageWrapper = JSON.serialize(loginAcknowledgeList);
                            messageWrapper = messageWrapper.replace('NoofDays', 'No.ofDays');
                            
                            if(messageWrapper != null && messageWrapper!= '' && loanProduct!= null && loanProduct!= ''){
                                Integration_Details__c integration = new Integration_Details__c();
                                integration.name = 'Communication Event';
                                integration.Loan_Application__c = currentLoanApplicationDetails.Id;
                                integration.Endpoint__c = 'Acknowledge of login';
                                integration.Communication_Status__c = 'Published';
                                integration.Request_JSON__c = messageWrapper;
                                insert integration;
                                
                                System.debug('Message wrapper----'+messageWrapper);
                                String commProduct = loanProduct != null ? (loanProduct == 'Term Loan' ? 'Business Loan': (loanProduct == 'Flexi Funds' ? 'Business Loan Flexi Funds': '')): '';
                                Communication__e event = new Communication__e(
                                    Message__c = messageWrapper,
                                Record_Id__c = integration.Id,
                                Type__c = 'Acknowledge of login',
                                product__c = commProduct
                                    );
                                
                                Database.SaveResult result = EventBus.publish(event);
                                if (result.isSuccess()) {
                                    System.debug('Platform Event for login published successfully.'+result);
                                } else {
                                    // Log errors if publishing failed
                                    for (Database.Error error : result.getErrors()) {
                                        System.debug('Error publishing event: ' + error.getMessage());
                                    }
                                }
                            }
                        }
                    }
                }
                List<Opportunity> loanAppData = [SELECT Id, StageName FROM Opportunity WHERE Id = :loanApplicationId];
                if( loanAppData.size()>0 && loanAppData[0].StageName == 'PSV' && buttonName == 'Mark as complete'){
                    List<Integration_Details__c> inDetails = [SELECT Id, Request_JSON__c FROM Integration_Details__c WHERE Loan_Application__c = :loanApplicationId AND Name = 'Sanction Letter Generation' ORDER BY CreatedDate DESC LIMIT 1];
                    if(inDetails.size()>0){
                        COMM_SanctionLetterController.generateSanctionLetterEvent(loanApplicationId, inDetails[0].Request_JSON__c);
                    }
                }
                       System.debug('oppList 456>>>>>'+oppList);                             
                if(!oppList.isEmpty()){
                    update oppList;
                    for(Opportunity loan : oppList){
                        loan.ByPassOwnerChangeValidation__c = false;
                    }
                    OpportunityTriggerHandler.isTriggerDisabled = true;
                    update oppList;
                    OpportunityTriggerHandler.isTriggerDisabled = false;
                    String lightningUrl = System.Url.getOrgDomainUrl().toExternalForm() + '/lightning/r/Opportunity/' + loanApplicationId + '/view';
                    if(!updatedApplicationApplicant.isEmpty()){
                        update updatedApplicationApplicant;
                    }
                    if(!shareList.isEmpty()){
                        insert shareList;
                        System.debug('List inserted>>>');
                    }
                }else{
                    System.debug('inside main else');
                    throw new CustomException('We are unable to process you request at the moment.');
                }
            }
Utility.byPassOwnershipUpdate = false;
            return returnMessage;
        }catch(Exception e){
            throw new CustomException(e.getMessage()+' '+e.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static List<String> creditUnderwritingToPSVValidations(String oppId,Boolean isApproval) {
        List<String> errorMessages = new List<String>();
        Opportunity currentLoanApplicationDetails = [SELECT Id,StageName,Sub_stage__c ,Approval_Status__c,Sanction_Loan_Amount__c,
        Sanction_Rate_Of_Interest__c,Approval_Type__c
        FROM Opportunity 
        WHERE Id = :oppId 
        LIMIT 1];
        
       list <Product2> prod =[SELECT Id ,Sanctioned_Loan_Amount__c, Sanctioned_ROI__c,Sanctioned_Tenor__c ,EMI_Amount__c, Product__r.Name FROM Product2 where RecordType.Name ='Sub Product' AND Loan_Application__c = :oppId] ;
        
        List<Application_Applicant__c> lstApplicants = [SELECT id,Applicant_Type__c,name,Customer__r.SF_Customer_ID__c,Customer_Type__c,Employment_Type__c,Marital_Status__c,Sector__c,PEP__c,
                                                        Sub_Employment_Type_Non_Individual__c,Sub_Employment_Type__c,PAN_Number__c,DOB__c,DOI__c,Loan_Application__r.Name,CIBIL_Score__c,Nature_of_Business__c,Address_Ownership__c,
                                                       
                                                        Qualification__c,Industry__c,Is_Key_Applicant__c,Total_Work_Experience_Years__c,Office_Ownership__c FROM Application_Applicant__c WHERE 
                                                        Loan_Application__c =:oppId];
        
        for(Application_Applicant__c iterAppli : lstApplicants) {
            if(iterAppli.PEP__c != 'NO' && iterAppli.PEP__c != 'YES'){
                errorMessages.add('Missing PEP value for applicant -'+iterAppli.name);
            }
        }
        
        if(prod.size() > 0){
        for(Product2 p : prod){

            String prodName = (p.Product__r.Name);

            if(p.Sanctioned_Tenor__c == null || p.Sanctioned_Tenor__c == 0) {
                errorMessages.add('Missing Sanction Tenure for product: ' + prodName);
            }

            if(p.Sanctioned_Loan_Amount__c == null || p.Sanctioned_Loan_Amount__c == 0) {
                errorMessages.add('Missing Sanction Loan Amount for product: ' + prodName);
            }

            if(p.Sanctioned_ROI__c == null || p.Sanctioned_ROI__c == 0) {
                errorMessages.add('Missing Sanction ROI for product: ' + prodName);
            }

            // if(p.EMI_Amount__c == null || p.EMI_Amount__c == 0) {
            //     errorMessages.add('Missing Sanction EMI for product: ' + prodName);
            // }
        }
    } else {
        errorMessages.add('No product found for this loan application.');
    }

        
         //added by oj
        if (!isApproval) {
            
            List<Application_Deviation__c> deviationList = [
                 SELECT Id, Approval_Status__c
                 FROM Application_Deviation__c
                 WHERE Loan_Application__c = :oppId
                 ORDER BY CreatedDate DESC ];
            List<Application_Deviation__c> updateList = new List<Application_Deviation__c>();
            
            for (Application_Deviation__c deviation : deviationList) {
                
                if (deviation.Approval_Status__c != 'Approved') {
                    deviation.Approval_Status__c = 'Approved';
                    updateList.add(deviation);
                }
            }
            if (!updateList.isEmpty()) {
                update updateList;
            }
          }//end oj

        List<Application_Collateral__c> appColla = [SELECT Id,Collateral__c,Assigned_Percentage__c,Collateral__r.APF__c, Collateral__r.RERA_End_Date__c, Collateral__r.Primary_Secondary__c  FROM Application_Collateral__c  WHERE HL_Loan_Application__c =:oppId AND Collateral__r.IsActive__c = true];
        if (appColla.size() > 0) {
            Set<Id> collateralIds = new Set<Id>();
            Map<Id, Decimal> collateralAssignedPercentMap = new Map<Id, Decimal>();
 
            for (Application_Collateral__c ac : appColla) {
                if (ac.Collateral__c != null) {
                    collateralIds.add(ac.Collateral__c);
                    collateralAssignedPercentMap.put(ac.Collateral__c, ac.Assigned_Percentage__c);
                }
            }
            system.debug('collateralIds--553'+collateralIds);
            if (!collateralIds.isEmpty()) {
                // Query all needed collateral fields including Market Value
                List<Collateral__c> collaterals = [
                    SELECT Id, Name, Mortgage_Type__c, House_Flat_Shop_Unit_No__c, Pocket__c,
                        Plot_Number__c, Survey_Number_Gat_No__c, Building_Name__c, Street_Name__c,
                        Market_Value__c
                    FROM Collateral__c
                    WHERE Id IN :collateralIds
                ];
 
                // Validate required fields
                for (Collateral__c col : collaterals) {
                    List<String> missingFields = new List<String>();
                    if (String.isBlank(col.Mortgage_Type__c)) missingFields.add('Mortgage Type');
                    if (String.isBlank(col.House_Flat_Shop_Unit_No__c)) missingFields.add('House/Flat/Shop/Unit No');
                    if (String.isBlank(col.Pocket__c)) missingFields.add('Pocket');
                    if (String.isBlank(col.Plot_Number__c)) missingFields.add('Plot Number');
                    if (String.isBlank(col.Survey_Number_Gat_No__c)) missingFields.add('Survey Number/Gat No');
                    if (String.isBlank(col.Building_Name__c)) missingFields.add('Building Name');
                    if (String.isBlank(col.Street_Name__c)) missingFields.add('Street Name');
 
                    if (!missingFields.isEmpty()) {
                        system.debug('missingFields--576'+missingFields);
                        errorMessages.add('Please provide ' + String.join(missingFields, ', ') + ' on Collateral: ' + col.Name);
                    }
                }
 
                // Calculate total market value adjusted by assigned percentage
                Decimal totalMarketValue = 0;
                for (Collateral__c col : collaterals) {
                    Decimal mv = col.Market_Value__c;
                    Decimal assignedPct = collateralAssignedPercentMap.get(col.Id);
 
                    if (mv != null) {
                        if (assignedPct != null && assignedPct > 0) {
                            totalMarketValue += (mv * (assignedPct / 100));
                        } else {
                            // Default to 100% if percentage not provided
                            totalMarketValue += mv;
                        }
                    }
                }
 
                // Compare total market value with sanctioned loan amount
                if (currentLoanApplicationDetails.Sanction_Loan_Amount__c != null && totalMarketValue < currentLoanApplicationDetails.Sanction_Loan_Amount__c) {
                    errorMessages.add(
                        'The total adjusted market value of all collaterals (' + totalMarketValue +
                        ') is less than the sanctioned loan amount (' + currentLoanApplicationDetails.Sanction_Loan_Amount__c +
                        '). Kindly arrange for additional collateral.'
                    );
                }
            }
        }else {
            if(currentLoanApplicationDetails.Approval_Type__c == 'Final Approval' && prod.size() > 0){
                for(Product2 p : prod){
                    String prodName = (p.Product__r.Name);
                    if(p.Product__r.Name != 'Flexi Loan'){
                        errorMessages.add('Please add collateral.'+prodName);
                    }
                }
            }
        }

            if (appColla.size() > 0) {
                
                // 2. Filter APF = Yes
                List<Application_Collateral__c> apfYesList = new List<Application_Collateral__c>();
                for (Application_Collateral__c ac : appColla) {
                if (ac.Collateral__r.APF__c == 'Yes') {
                        apfYesList.add(ac);
                    }
                }

                if (apfYesList.size() > 0) {
                

                // 3. Pick primary (if multiple)
                Application_Collateral__c selectedColl;

                if (apfYesList.size() == 1) {
                    selectedColl = apfYesList[0];
                } else {
                        for (Application_Collateral__c ac : apfYesList) {
                            if (ac.Collateral__r.Primary_Secondary__c == 'Primary') {
                                    selectedColl = ac;
                                        break;
                                }
                        }
                        if (selectedColl == null) {
                                selectedColl = apfYesList[0];
                        }
                    }

                // 4. Get RERA End Date
                Date reraDate = selectedColl.Collateral__r.RERA_End_Date__c;

                if (reraDate == null) {
                    errorMessages.add('RERA End Date is not present in the APF Collateral.Please add in order to proceed.');
                }

                // Calculate LOWEROF (RERA - 2 months OR Today + 48 months)
                Date reraMinus2Months = reraDate.addMonths(-2);
                Date fortyEightMonths = Date.today().addMonths(48);

                Date lowerOfValue;

                if (reraMinus2Months < Date.today()) {
                    lowerOfValue = fortyEightMonths;
                } else {
                    lowerOfValue = (reraMinus2Months < fortyEightMonths) ? reraMinus2Months : fortyEightMonths;
                }
                // 5. Query Hybrid Tenure product list
                Id hybridRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Hybrid Tenure').getRecordTypeId();

                List<Product2> productList = [SELECT Id, Name FROM Product2 WHERE RecordTypeId = :hybridRecordTypeId AND Loan_Application__c = :oppId];

                // 6. Compare tenure with lowerOfValue
                for (Product2 p : productList) {
                        Integer prodMonths = Integer.valueOf(p.Name);
                        Date prodDate = Date.today().addMonths(prodMonths);

                        if (prodDate > lowerOfValue) {
                                errorMessages.add('The Interest Only Tenure should be less than or equals to 48 months');
                        }
                }
            }
            }
    
        
        String pdRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Personal_Discussion');
        List<Application_Verification__c> lstApplicationVerification = [SELECT id,Disposition__c,Credit_Managers_Disposition__c,Personal_Discussion_Type__c FROM Application_Verification__c WHERE Loan_Application__c =: oppId AND recordTypeId =: pdRecordTypeId AND IsParent__c = false];
        // if(lstApplicationVerification.size() > 0) {
        //     for(Application_Verification__c pdsIter : lstApplicationVerification) {
        //         if(pdsIter.Disposition__c == null && pdsIter.Personal_Discussion_Type__c != 'Vendor PD') {
        //             errorMessages.add('Missing disposition of PD(s) initiated/performed.');
        //             break;
        //         }
        //         //if(pdsIter.Credit_Managers_Disposition__c == null && pdsIter.Personal_Discussion_Type__c == 'Vendor PD') {
        //             //    errorMessages.add('Missing disposition of PD(s) initiated/performed.');
        //             //    break;
        //         //}
        //     }
        // }
         List<Bank_Details__c> bankObj = [Select id,Name,Account_Number__c,Account_Holder_Name__c,Account_Type__c,Is_Repayment_Account__c,Is_Disbursal_Account__c from Bank_Details__c 
                                          where Application_Applicant__r.Loan_Application__c  =: oppId 
                                          ];

        Boolean missingHolderName = false;
        Boolean missingAccNumber = false;
        Boolean missingBankName = false;
        Boolean invalidAccNumber = false;
        if(bankObj.size() > 0) {
            for(Bank_Details__c iterBanks : bankObj) {
                 if (!missingHolderName && String.isBlank(iterBanks.Account_Holder_Name__c)) {
                    missingHolderName = true;
                }
                if (!missingAccNumber && String.isBlank(iterBanks.Account_Number__c)) {
                    missingAccNumber = true;
                }
                if (!missingBankName && String.isBlank(iterBanks.Name)) {
                    missingBankName = true;
                }
                // Check special characters in Account Number
              // Check invalid account number (special chars, alphabets, X-masked)
                if (!invalidAccNumber && !String.isBlank(iterBanks.Account_Number__c)) {
                    String accNum = iterBanks.Account_Number__c;
                    // Any character not 0–9 OR any X/x means invalid
                    if (!Pattern.matches('^[0-9]+$', accNum) || accNum.toUpperCase().contains('X')) {
                        invalidAccNumber = true;
                    }
                }
            }
        }else {
        }
         if (missingHolderName) {
            errorMessages.add('Please fill Account Holder Name.');
        }
        if (missingAccNumber) {
            errorMessages.add('Please fill Account Number.');
        }
        if (missingBankName) {
            errorMessages.add('Please fill Bank Name.');
        }
        if (invalidAccNumber) {
            errorMessages.add('Account Number should contain only digits. Special characters are not allowed.');
        }
        Boolean isRepaymentBank = false;
        String regex = '^[a-zA-Z0-9 ._]+$';
        List<Bank_Details__c> bankObjs = [Select id,Name,Is_Repayment_Account__c,Account_Holder_Name__c from Bank_Details__c 
                                          where Application_Applicant__r.Loan_Application__c  =: oppId 
                                          AND (Is_Repayment_Account__c = true OR Is_Disbursal_Account__c = true)];
        if(bankObjs.size() > 0) {
            for(Bank_Details__c iterBanks : bankObjs) {
                String accountHolderName = iterBanks.Account_Holder_Name__c;
                if (Pattern.matches(regex, accountHolderName)){
                    
                }else {
                    if(Label.Account_Holder_Name_Validation == 'true') {
                        errorMessages.add(accountHolderName + ' account holder name cannot contain special characters except "." or "_".');
                    }
                    
                }
                String bName = iterBanks.Name;
                if (Pattern.matches(regex, bName)){
                    
                }else {
                    if(Label.Bank_Name_Validation == 'true') {
                        errorMessages.add(bName + ' name cannot contain special characters except "." or "_".');
                    }
                    
                }
                if(iterBanks.Is_Repayment_Account__c) {
                    isRepaymentBank = true;
                }
            }
        }else {
            errorMessages.add('Please select repayment bank.');
        }
        if(!isRepaymentBank) {
            errorMessages.add('Please select repayment bank.');
        }
        if(!isApproval) {
            if(currentLoanApplicationDetails.Approval_Status__c != 'Approved') {
                errorMessages.add('Loan application must be approved before moving forward.');
            }
        }
        
        List<Negative_dedupe__c> negativeListDisp = [SELECT Id, Match_found__c FROM Negative_dedupe__c WHERE Negative_list_dispostion__c =: oppId AND Application_Applicant__c != null AND Match_found__c = null];
        if (!negativeListDisp.isEmpty()) {
            errorMessages.add('Please add disposition for all negative list dedupe matches found.');
        }
        
        return errorMessages;
    }
        
    /*@AuraEnabled
    public static List<string> checkPsvSalesToPsvCreditValidation(string loanApplicationId) {
        List<string> result = new List<string>();
        List<ProcessInstanceWorkitem> procInstance = [SELECT Id, ProcessInstanceId, ActorId FROM ProcessInstanceWorkitem
        WHERE ProcessInstance.TargetObjectId = :loanApplicationId AND ProcessInstance.Status = 'Pending'];
        if (!procInstance.isEmpty()) {
            result.add('There are pending approvals on this application');
        } // -------------------------------
        // HL Related + APF + Tenure Formula Validation (Updated)
        // -------------------------------
        Map<String,String> inputMapUtility = new  Map<String,String>();
        Utility_V1.ProductWrapper isHLRelatedFinal = Utility_V1.getProductDetails(inputMapUtility);
        Boolean isHlRelated = isHLRelatedFinal.isHLRelated;
        if(isHLRelated){
            String collateralOwnerError = AHL_LoanApplicationActionController.validateCollateralOwners(loanApplicationId);
            if(collateralOwnerError != ''){
                result.add(collateralOwnerError);
            }
        }

        if (isHlRelated) {

            // 1. Fetch collateral
            List<Application_Collateral__c> collList = [SELECT Id, Collateral__c,Collateral__r.APF__c, Collateral__r.RERA_End_Date__c, Collateral__r.Primary_Secondary__c FROM Application_Collateral__c WHERE HL_Loan_Application__c = :loanApplicationId AND Collateral__r.IsActive__c = true];
            if (collList.isEmpty()) {
            }

            // 2. Filter APF = Yes
            List<Application_Collateral__c> apfYesList = new List<Application_Collateral__c>();
            for (Application_Collateral__c ac : collList) {
            if (ac.Collateral__r.APF__c == 'Yes') {
                    apfYesList.add(ac);
                }
            }

            if (apfYesList.isEmpty()) {
            }

            // 3. Pick primary (if multiple)
            Application_Collateral__c selectedColl;

            if (apfYesList.size() == 1) {
                selectedColl = apfYesList[0];
            } else {
                    for (Application_Collateral__c ac : apfYesList) {
                        if (ac.Collateral__r.Primary_Secondary__c == 'Primary') {
                                selectedColl = ac;
                                    break;
                            }
                    }
                    if (selectedColl == null) {
                            selectedColl = apfYesList[0];
                    }
                }

            // 4. Get RERA End Date
            Date reraDate = selectedColl.Collateral__r.RERA_End_Date__c;

            if (reraDate == null) {
                result.add('RERA End Date is not present in the APF Collateral.Please add in order to proceed.');
            }

            // Calculate LOWEROF (RERA - 2 months OR Today + 48 months)
            Date reraMinus2Months = reraDate.addMonths(-2);
            Date fortyEightMonths = Date.today().addMonths(48);

            Date lowerOfValue;

            if (reraMinus2Months < Date.today()) {
                lowerOfValue = fortyEightMonths;
            } else {
                lowerOfValue = (reraMinus2Months < fortyEightMonths) ? reraMinus2Months : fortyEightMonths;
            }
            // 5. Query Hybrid Tenure product list
            Id hybridRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Hybrid Tenure').getRecordTypeId();

            List<Product2> productList = [SELECT Id, Name FROM Product2 WHERE RecordTypeId = :hybridRecordTypeId AND Loan_Application__c = :loanApplicationId];

            // 6. Compare tenure with lowerOfValue
            for (Product2 p : productList) {
                    Integer prodMonths = Integer.valueOf(p.Name);
                    Date prodDate = Date.today().addMonths(prodMonths);

                    if (prodDate > lowerOfValue) {
                            result.add('The Interest Only Tenure should be less than or equals to 48 months');
                    }
            }
        }
        if(result.isEmpty()){
            result.add('Success');
        }
        return result;
    }*/
}