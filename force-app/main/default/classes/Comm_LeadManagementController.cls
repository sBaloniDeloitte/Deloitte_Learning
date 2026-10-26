public with sharing class Comm_LeadManagementController {

    static string conLabels = Constants__mdt.getInstance('LeadManagementController').Value__c;
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
    //method to create a single Lead
    @AuraEnabled
    public static String createLead(String firstName, String middleName, String lastName, String mobileNumber, String company,String contactPersonName, String custType, String Direct,String employementType,String productType, String pan, Boolean salesExecutive) {
        Map<String,String> inputMapUtility = new  Map<String,String>();
        Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
        Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
        Map<String, String> productToRecordType = new Map<String, String>{
            'Affordable Home Loan' => 'Affordable_Home_Loan',
            'Home Loan' => 'Home_Loan',
            'Non Home Loan'=>'Non_Home_Loan'
        };
        if(isHlRelated){
            productToRecordType.put('Flexi Loan','Home_Loan');
        }
          
        
        // try {
            /*System.debug('Input Parameters:');
            System.debug('First Name: ' + firstName);
            System.debug('Middle Name: ' + middleName);
            System.debug('Last Name: ' + lastName);
            System.debug('Mobile Number: ' + mobileNumber);
            System.debug('Company: ' + company);
            System.debug('Customer Type: ' + custType);
            System.debug('Channel: ' + channel);
    		System.debug('Product type:'+productType);*/
            Lead newLead = new Lead();
            newLead.FirstName = firstName;
            newLead.MiddleName = String.isNotBlank(middleName) ? middleName : '';
            newLead.LastName = String.isNotBlank(lastName) ? lastName : company;
            newLead.MobilePhone = mobileNumber;
            newLead.Company = String.isNotBlank(company) ? company : 'NA';
        	newLead.COMM_Contact_Person_Name__c = String.isNotBlank(contactPersonName) ? contactPersonName : 'NA';
            newLead.Customer_Type__c = custType;
    		newLead.Product__c = productType;
            newLead.PAN__c = pan;
            if(salesExecutive == true){
           Id currentUserId = UserInfo.getUserId();
           
           List<AccountTeamMember> accTeamList = [Select Id,User.Name,UserId ,User.Employee_ID__c, User.MobilePhone, TeamMemberRole,Account.Id 
           From AccountTeamMember  
           where UserId =: currentUserId  AND TeamMemberRole = 'Sales' 
           AND Account.Branch_Type__c = 'HUB'  Limit 1];
           if (!accTeamList.isEmpty()) {
           AccountTeamMember accTeam = accTeamList[0];
           if( accTeam.Account.Id != null){
           newLead.Branch__c =   accTeam.Account.Id;
           }
         }
        }
           String recordTypeDevName = productToRecordType.containsKey(productType) ? productToRecordType.get(productType) : null;
          if (recordTypeDevName != null) {
            Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(recordTypeDevName).getRecordTypeId();
            newLead.RecordTypeId = recordTypeId != null ? recordTypeId : '';
           }
            //System.debug('Customer Type (after assignment): ' + newLead.Customer_Type__c);
    
            // Check constants map
            /*if (constants == null || !constants.containsKey('Created') || !constants.containsKey('Open')) {
                System.debug('Constants map is not initialized or missing keys.');
                throw new CustomException('Constants map is not properly initialized.');
            }*/
    
            newLead.Lead_Sub_Status__c = constants.get('Created');
            newLead.Status = constants.get('Open');
            newLead.Channel__c = Direct;
            newLead.Employment_Type__c= employementType;
            if(newLead.Channel__c == 'Direct'){
                newLead.Dsa_Area_Manager__c = UserInfo.getUserId();
            }
    
            /*System.debug('Lead Fields After Assignment:');
            System.debug('Lead Sub Status: ' + newLead.Lead_Sub_Status__c);
            System.debug('Status: ' + newLead.Status);
            System.debug('Channel: ' + newLead.Channel__c);*/
    
            // Insert the lead and debug the ID
            // For Online channel, bypass the standard duplicate rule so the
            // trigger's custom Hot-lead logic can handle duplicates instead.
            if (newLead.Channel__c == 'Online' || newLead.LeadSource == 'CSC') {
                Database.DMLOptions dmlOptions = new Database.DMLOptions();
                dmlOptions.DuplicateRuleHeader.AllowSave = true;
                Database.insert(newLead, dmlOptions);
            } else {
            insert newLead;
            }
            //System.debug('Lead successfully inserted. Lead ID: ' + newLead.Id);
    
            return newLead.Id;
        // } catch (Exception e) {
        //     System.debug('Exception occurred: ' + e.getMessage());
        //     System.debug('Stack Trace: ' + e.getStackTraceString());
        //     // throw new CustomException('Failed to create Lead: ' + e.getMessage());
        // }
    }
    
    //fetching Lead details according to processname
    @AuraEnabled
    public static List<Lead> fetchLeadDetails(String leadId, string processName) {
        List<Lead> leadList;
        List<String> fieldsList = new List<String>();
        List<Constants__mdt> fields = [SELECT Value__c FROM Constants__mdt WHERE Process_Name__c = :processName];
        for (Constants__mdt part : fields) {
        fieldsList.add(part.Value__c);
        }
        if (!fieldsList.isEmpty()) {
           // Always include these fields regardless of metadata configuration
           List<String> alwaysInclude = new List<String>{
               'Assigned_Sales_User__c',
               'Sub_Product__c',
               'Alternate_Mobile_Number__c',
               'City__c',
               'State__c',
               'Pincode__c',
               'CampaignType_leadType__c',
               'Reference_Field_1__c',
               'Reference_Field_2__c',
               'Reference_Field_4__c',
               'Reference_Field_5__c',
               'Reference_Field_6__c',
               'Reference_Field_7__c',
               'Reference_Field_8__c',
               'Reference_Field_9__c',
               'Reference_Field_10__c'
           };
           for (String f : alwaysInclude) {
               if (!fieldsList.contains(f)) {
                   fieldsList.add(f);
               }
           }
           String query = 'SELECT Id, ' + String.join(fieldsList, ', ') + ' FROM Lead WHERE Id = :leadId';
           leadList = Database.query(query);
        }
        /*switch on processName {

            when 'LeadManagement' {
                leadList = [SELECT Id, FirstName, Requested_Loan_Amount__c,Closed_Reasons__c, Lead_Number__c, LastName, MiddleName, Status, Industry, Pan__c, MobilePhone, Pincode__r.Name, Email, Company, 
                            Business_Vintage__c, Is_Pincode_Serviceable__c, Lead_Sub_Status__c, Is_Mobile_Verified__c, Current_Page__c, LeadSource, Channel__c, Date_of_Birth__c, 
                            Is_Consent_Received__c, Customer_Type__c, Date_of_Incorporation__c, Lead_Type__c, Product__c, Customer__c,Customer__r.Customer_LMS_Id__c, GenderIdentity, Office_Ownership__c, 
                            Turnover_Yearly__c, Business_Type__c,Employment_Type__c, Referred_By_DSA__c, Referred_By_DSA__r.Name, Dsa_Area_Manager__c, Dsa_Area_Manager__r.Name, CreatedBy.Profile.Name,COMM_Contact_Person_Name__c,COMM_Purpose_of_Loan__c,COMM_Business_Turnover__c
                            FROM Lead WHERE Id =: leadId
                        ];
            }
            when 'ManageDedupe' {
                leadList = [SELECT Id, Assigned_Sales_User__c, OwnerId, Lead_Number__c FROM Lead WHERE Id =: leadId];
            }
            when 'DialerRemarks' {
                leadList = [SELECT Id, Dialer_History__c, Status, Call_Count__c, Dialer_Disposition__c FROM Lead WHERE Id =: leadId];
            }
        }*/
        //system.debug('leadList: '+leadList);

        return leadList;
    }
    @AuraEnabled
    public static List<Contact> fetchDSAContact(String leadId, string processName) {
         return [SELECT Id,Name,Account.Name,Account.Vendor_Code__c,Account.Corporate_DSA__c FROM Contact WHERE Id IN (SELECT ContactId FROM 
        User WHERE Id = :UserInfo.getUserId())];
    }
//fetching Lead number
    @AuraEnabled
    public static String getLeadNumber(String recordId) {
        String leadNumber = null;
        List<Lead> leads = [SELECT Lead_Number__c FROM Lead WHERE Id =: recordId];
        if(!leads.isEmpty()) {
            leadNumber = leads[0].Lead_Number__c;
            
        }

        return leadNumber;
    }
//fetching current lead stage
    @AuraEnabled
    public static Lead getLeadCurrectStage(String leadId) {
        return [SELECT Status, Lead_Sub_Status__c FROM Lead WHERE Id =: leadId LIMIT 1];
    }
//method to check whether required images are uploaded or not
    @AuraEnabled
    public static Boolean checkImageUploaded(String leadId) {
        Boolean returnVal = true;
        // Query for Document_Details__c with Is_Required__c = true, Status__c not equal to 'Uploaded', and the provided leadId
        List<Document_Details__c> incompleteDocs = [SELECT Id FROM Document_Details__c WHERE Lead__c =: leadId And Is_Required__c = true And Status__c = 'Pending'];
        
        if(!incompleteDocs.isEmpty()){
            //System.debug('false');
          returnVal = false;
        }
        return returnVal;
    }
    
    // @AuraEnabled
    // public static Boolean getPincodeServicable(String pinId) {
        
    //     List<Pincode_Master__c> pmList = [SELECT Id, Is_Pincode_Servicable__c FROM Pincode_Master__c WHERE Id = :pinId];
    //     if(pmList.isEmpty()) {
    //         throw new AuraHandledException('Pincode Master record not found for the given pincode.');
    //     }

    //     return pmList[0].Is_Pincode_Servicable__c;
    // }
//method to close the Lead
    @AuraEnabled
    public static Boolean closeLead(String leadId) {
       
        //Lead leadToUpdate = [SELECT Id, Status, Lead_Sub_Status__c FROM Lead WHERE Id = :leadId LIMIT 1];
        Lead leadToUpdate = new Lead();
        leadToUpdate.Id = leadId;
        leadToUpdate.Status = constants.get('Closed');
        leadToUpdate.Lead_Sub_Status__c = constants.get('Converted');
        
        update leadToUpdate;
        
        return true;
    }
//method to check past date entered
    @AuraEnabled
    public static Boolean checkpastDate(Date followUpDate){
        Boolean flag = false;
              
        Date today = Date.today();
        if(followUpDate < today){
            flag = true;
        }

        return flag;
    }
    @AuraEnabled
    public static string getNumberToWord(String laAmt){
        String reqAmt = Utility.getNumberTOWordConvertion(Decimal.valueOf(laAmt));
        return reqAmt;
    }

    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled
    public static Map<String, Object> businessSubSectorPicklist() {
        Map<String, Object> result = new Map<String, Object>();
        try {
        List<PLF_Master__c> plfMastRecs = [SELECT Id, Description__c FROM PLF_Master__c WHERE Master_Type__c = 'Sub sector'];
        List<PicklistOption> picklistOptions = new List<PicklistOption>();
        if (!plfMastRecs.isEmpty()) {
            for (PLF_Master__c rec : plfMastRecs) {
                String label = rec.Description__c;
                String value = rec.Description__c;
                picklistOptions.add(new PicklistOption(label, value));
            }
        }
        result.put('picklistOptions', picklistOptions);
        } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
        }
    return result;
    }

    @AuraEnabled(cacheable=true)
    public static string getAccountsForUser(Id userId) {
    User u = [SELECT AccountId, Account.Name FROM User WHERE Id =: userId];
    String accountName;
    if (u.AccountId != null) {
        accountName = u.Account.Name;
        System.debug('Account Name: ' + accountName);
    } else {
    System.debug('No Contact associated with this User.');
    }
    return accountName;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getCustomPermissionsByUserId() {
        List<String> permissionNames = new List<String>();
        Id currentUserId = UserInfo.getUserId();
        // Get permission sets assigned to the user
        List<PermissionSetAssignment> psaList = [
            SELECT PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :currentUserId
        ];

        Set<Id> permissionSetIds = new Set<Id>();
        for (PermissionSetAssignment psa : psaList) {
            permissionSetIds.add(psa.PermissionSetId);
        }

        // Get SetupEntityAccess records for CustomPermissions
        List<SetupEntityAccess> accessList = [
            SELECT SetupEntityId
            FROM SetupEntityAccess
            WHERE SetupEntityType = 'CustomPermission'
            AND ParentId IN :permissionSetIds
        ];

        Set<Id> customPermissionIds = new Set<Id>();
        for (SetupEntityAccess access : accessList) {
            customPermissionIds.add(access.SetupEntityId);
        }

        // Get CustomPermission names
        for (CustomPermission cp : [
            SELECT DeveloperName
            FROM CustomPermission
            WHERE Id IN :customPermissionIds
        ]) {
            permissionNames.add(cp.DeveloperName);
        }
        System.debug('permissionNames---'+permissionNames);
        return permissionNames;
    }
    @AuraEnabled
    public static Boolean maybeStampDSAAM(Id leadId, String channel) {
        try {
            if (leadId == null) return false;
            if (String.isBlank(channel) || channel.trim().toLowerCase() != 'direct') return false;

            Lead ld = [
                SELECT Id, Branch__c
                FROM Lead
                WHERE Id = :leadId
                LIMIT 1
            ];

            if (ld.Branch__c == null) return false;
            List<AccountTeamMember> atms = [
                SELECT Id
                FROM AccountTeamMember
                WHERE AccountId = :ld.Branch__c
                AND TeamMemberRole = 'Sales'
                AND UserId = :UserInfo.getUserId()
                LIMIT 1
            ];
            if (atms.isEmpty()) return false;
            User u = [
                SELECT Id, Position_Title__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            if (u.Position_Title__c != 'Relationship Manager' && u.Position_Title__c != 'Sales Manager') return false;

            update new Lead(
                Id = ld.Id,
                DSA_Area_Manager__c = u.Id
            );

            return true;
        } catch (Exception e) {
            System.debug('maybeStampDSAAM skipped: ' + e.getMessage());
            return false;
        }
    }

    @AuraEnabled
    public static String submitForApproval( Map<String, String> inputMap){
        String result= 'success';
        try {
            String leadId = inputMap.get('leadId');
            String oldLeadId= inputMap.get('oldLeadId');
            Lead lead = [SELECT Id, Dedupe_Approval_Status__c, Branch__c, Customer_Type__c, MobilePhone FROM Lead WHERE Id =:leadId LIMIT 1];
            List<Lead> leads = [
            SELECT Id,Lead_Number__c,MobilePhone,Status,Customer_Type__c FROM Lead WHERE MobilePhone = :lead.MobilePhone AND Status != 'Closed' AND Customer_Type__c = :lead.Customer_Type__c AND Id != :leadId LIMIT 1];
            lead.Dedupe_Approval_Status__c = 'Send for Approval';
            update lead;
            Lead oldLead = leads[0];
            oldLead.Dedupe_Approval_Status__c = 'Send for Approval';
            update oldLead;
            AccountTeamMember branchHead = [SELECT UserId, User.Email,User.Name FROM AccountTeamMember WHERE AccountId = :lead.Branch__c AND TeamMemberRole = 'Sales' AND Is_Branch_Head__c = TRUE LIMIT 1];
            if (branchHead == null) {
                throw new AuraHandledException('Error: Branch Head Approver or Email not found.');
            }


            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Lead dedupe found');
            req.setObjectId(leadId);
            req.setProcessDefinitionNameOrId('Dedupe_Waiver');
            req.setNextApproverIds(new List<Id>{branchHead.UserId}); 
            // Approval.ProcessResult approvalResult = Approval.process(req);

            sendEmailToAllApprovers(leadId, leads[0].Id,branchHead);
        } catch (Exception e) {
            result = e.getMessage();
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }
    private static String safeValue(String val) {
        return (val != null && val.trim() != '') ? val : '-';
    }

    public static void sendEmailToAllApprovers(String leadId, String oldLeadId, AccountTeamMember branchHead) {
        try{
        List<OrgWideEmailAddress> owdEmail = [SELECT Id FROM OrgWideEmailAddress WHERE Address =: Label.Org_Wide_Address ]; // :Label.Org_Wide_Address
        List<Lead> leadList= [SELECT Id, Name, Branch__c, Lead_Number__c, Owner.Email FROM Lead WHERE Id = :leadId];
        List<Lead> oldleadList= [SELECT Id, Name, Branch__c, Lead_Number__c, Owner.Email FROM Lead WHERE Id = :leadId];
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<String> sendToAddressesList = new List<String>();
        List<String> sendCCAddressesList = new List<String>();
        sendToAddressesList.add(branchHead.User.Email);
        sendToAddressesList.add(System.Label.Org_Wide_Address); // testing purpose //change by Kunal Bisht for Code analysis report
        sendCCAddressesList.add(leadList[0].Owner.Email);
        sendCCAddressesList.add(oldleadList[0].Owner.Email);

        email.setOrgWideEmailAddressId(owdEmail[0].Id);
        email.setSubject('Lead Dedupe Approval Request - ' + leadList[0].Lead_Number__c);
        email.setHtmlBody(buildEmailBody(leadId,branchHead.User.Name, oldLeadId));
        email.setToAddresses(sendToAddressesList); 
        email.setCCAddresses(sendCCAddressesList);
        email.setReplyTo(Label.Lead_Dedupe_Reply);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static String buildEmailBody(Id leadId,String approverName, String oldLeadId) {
        List<Lead> leadList= [SELECT Id, Name, Branch__c, Lead_Number__c, Owner.Email, Owner.Name, Product__c, Customer_Type__c,MobilePhone, Employment_Type__c, Full_Name_As_Per_Pan__c FROM Lead WHERE Id = :leadId];
        List<Lead> oldleadList= [SELECT Id, Name, Branch__c, Lead_Number__c, Owner.Email, Owner.Name, Product__c, Customer_Type__c,MobilePhone, Employment_Type__c, Full_Name_As_Per_Pan__c FROM Lead WHERE Id = :oldLeadId];
        User currentUser = [SELECT Id,Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        String htmlBody = '<html><body style="font-family: Arial; font-size: 14px;">';
        htmlBody += '<p>Dear '+approverName+',</p>';
        htmlBody += '<p>Duplicate Lead Login approval request has been sent by '+ currentUser.Name +' for the lead '+ leadList[0].Name +' : '+'.</p>';
    
        htmlBody += '<p><span style="color:red; font-weight:bold;">Kindly reply with "Approve", "Approved", "Ok" or "Reject", "Rejected", "Not ok"</span></p>';


    
        if (!leadList.isEmpty()) {
            htmlBody += '<h3 style="font-size:14px;">Duplicate Lead Details</h3>';
            htmlBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%; font-size:12px;">';

            htmlBody += '<tr style="background-color: #87CEEB;">';
            htmlBody += '<th>Product</th>';
            htmlBody += '<th>Lead Number</th>';
            htmlBody += '<th>Owner Name</th>';
            htmlBody += '<th>Applicant Type</th>';
            htmlBody += '<th>Applicant Profile</th>';
            htmlBody += '<th>Applicant Name</th>';
            htmlBody += '<th>Mobile No.</th>';
            htmlBody += '</tr>';

            htmlBody += '<tr>';
            htmlBody += '<td>' + safeValue(leadList[0].Product__c) + '</td>';
            htmlBody += '<td>' + safeValue(leadList[0].Lead_Number__c) + '</td>';
            htmlBody += '<td>' + safeValue(leadList[0].Owner.Name) + '</td>';
            htmlBody += '<td>' + safeValue(leadList[0].Customer_Type__c) + '</td>';
            htmlBody += '<td>' + safeValue(leadList[0].Employment_Type__c) + '</td>';
            htmlBody += '<td>' + safeValue(leadList[0].Full_Name_As_Per_Pan__c) + '</td>';
            htmlBody += '<td>' + safeValue(leadList[0].MobilePhone) + '</td>';
            htmlBody += '</tr>';

            htmlBody += '</table>';
        }


    
    
        if (!oldleadList.isEmpty()) {
            htmlBody += '<h3 style="font-size:14px;">Active Lead Details</h3>';
            htmlBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%; font-size:12px;">';
            /* htmlBody += '<tr style="background-color:#f2f2f2;">' +
                        '<th>Product</th><th>Lead Number</th><th>Owner Name</th>' +
                        '<th>Applicant Type</th><th>Applicant Profile</th><th>Applicant Name</th>' +
                        '<th>Mobile No.</th></tr>'; */

            htmlBody += '<tr style="background-color: #87CEEB;">'; // background-color: #f2f2f2
            htmlBody += '<th>Product</th>';
            htmlBody += '<th>Lead Number</th>';
            htmlBody += '<th>Owner Name</th>';
            htmlBody += '<th>Applicant Type</th>';
            htmlBody += '<th>Applicant Profile</th>';
            htmlBody += '<th>Applicant Name</th>';
            htmlBody += '<th>Mobile No.</th>';
            htmlBody += '</tr>';

            htmlBody += '<tr>';
            htmlBody += '<td>' + safeValue(oldleadList[0].Product__c) + '</td>';
            htmlBody += '<td>' + safeValue(oldleadList[0].Lead_Number__c) + '</td>';
            htmlBody += '<td>' + safeValue(oldleadList[0].Owner.Name) + '</td>';
            htmlBody += '<td>' + safeValue(oldleadList[0].Customer_Type__c) + '</td>';
            htmlBody += '<td>' + safeValue(oldleadList[0].Employment_Type__c) + '</td>';
            htmlBody += '<td>' + safeValue(oldleadList[0].Full_Name_As_Per_Pan__c) + '</td>';
            htmlBody += '<td>' + safeValue(oldleadList[0].MobilePhone) + '</td>';
            htmlBody += '</tr>';
            
            htmlBody += '</table>';
        }
    
        htmlBody += '<p>Thanks,</br>'+currentUser.Name+'</p>';
        htmlBody += '</body></html>';

        return htmlBody;
    }
}