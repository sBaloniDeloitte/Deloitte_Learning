public with sharing class LeadManagementController {

    static string conLabels = Constants__mdt.getInstance('LeadManagementController').Value__c;
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
    //method to create a single Lead
    @AuraEnabled
    public static String createLead(String firstName, String middleName, String lastName, String mobileNumber, String company,String contactPersonName, String custType, String channel,String employementType,String productType,Boolean salesExecutive) {
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
            if(salesExecutive == true){
           Id currentUserId = UserInfo.getUserId();
           List<AccountTeamMember> accTeamList = [Select Id,User.Name,UserId ,User.Employee_ID__c, User.MobilePhone, TeamMemberRole,Account.Id From AccountTeamMember  where UserId =: currentUserId  AND TeamMemberRole = 'Relationship Manager' Limit 1];
           if (!accTeamList.isEmpty()) {
           AccountTeamMember accTeam = accTeamList[0];
           if( accTeam.Account.Id != null){
           newLead.Branch__c =   accTeam.Account.Id;
           }
         }
        }
            //System.debug('Customer Type (after assignment): ' + newLead.Customer_Type__c);
    
            // Check constants map
            /*if (constants == null || !constants.containsKey('Created') || !constants.containsKey('Open')) {
                System.debug('Constants map is not initialized or missing keys.');
                throw new CustomException('Constants map is not properly initialized.');
            }*/
    
            newLead.Lead_Sub_Status__c = constants.get('Created');
            newLead.Status = constants.get('Open');
            newLead.Channel__c = channel;
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
            if (newLead.Channel__c == 'Online') {
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
}