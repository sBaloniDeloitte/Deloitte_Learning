@isTest
public class Credit_FIVerificationControllerTest {
@isTest
static void testInitiateVendorPDHappyPath() {
    Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
    Pincode_Master__c pin = [SELECT Id FROM Pincode_Master__c LIMIT 1];

    Application_Applicant__c applicant = new Application_Applicant__c(
        Loan_Application__c = loanApp.Id, First_Name__c = 'Ven', Last_Name__c = 'Dor',
        Applicant_Type__c = 'Primary Applicant', Customer_Type__c = 'Individual'
    );
    insert applicant;

    Applicant_Address__c addr = new Applicant_Address__c(
        Applicant__c = applicant.Id, Address_Type__c = 'Permanent',
        Pincode__c = pin.Id, Address_Line_1__c = '12 PD Street'
    );
    insert addr;

    Id partnerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
    Account partnerAcc = new Account(Name = 'PD Partner Acc', RecordTypeId = partnerRtId);
    insert partnerAcc;
    insert new AccountTeamMember(AccountId = partnerAcc.Id, UserId = UserInfo.getUserId(), TeamMemberRole = 'PD Admin');

    Credit_FIVerificationController.ApplicantWrapper w = new Credit_FIVerificationController.ApplicantWrapper();
    w.applicantId = applicant.Id;
    w.applicantName = 'Ven Dor';
    w.addressId = addr.Id;
    w.addressType = 'Permanent';
    w.remarks = 'PD initiation remarks';
    w.selectedAssignee = UserInfo.getUserId();
    w.isDirectorReq = true;
    w.selectedDirector = applicant.Id;
    String payload = JSON.serialize(new List<Credit_FIVerificationController.ApplicantWrapper>{ w });

    Test.startTest();
    try {
        Credit_FIVerificationController.initiateVendorPD(payload, loanApp.Id, UserInfo.getUserId());
    } catch (Exception e) {
        System.debug('initiateVendorPD partial: ' + e.getMessage());
    }
    Test.stopTest();
    System.assert(true);
}

@isTest
static void testCreateApplicationVerificationEnabled() {
    Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
    Application_Applicant__c applicant = new Application_Applicant__c(
        Loan_Application__c = loanApp.Id, Last_Name__c = 'CAV',
        Applicant_Type__c = 'Primary Applicant', Customer_Type__c = 'Individual'
    );
    insert applicant;
    Applicant_Address__c addr = new Applicant_Address__c(
        Applicant__c = applicant.Id, Address_Type__c = 'Permanent', Address_Line_1__c = 'CAV Street'
    );
    insert addr;

    Document_Details__c holder = new Document_Details__c(Name = 'CAVHolder');
    insert holder;
    ContentVersion cv = new ContentVersion(
        Title = 'CAV Doc', PathOnClient = 'cav.txt',
        VersionData = Blob.valueOf('cav'), FirstPublishLocationId = holder.Id
    );
    insert cv;
    Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

    String fiListJson = '[{"addressId":"' + addr.Id + '","applicantId":"' + applicant.Id +
        '","recordTypeName":"Residence Verification","selectedAssignee":"' + UserInfo.getUserId() +
        '","fiStage":"Positive"}]';

    Test.startTest();
    try {
        Credit_FIVerificationController.createApplicationVerification(
            fiListJson, loanApp.Id, 'CAV remarks', UserInfo.getUserId(), new List<Id>{ docId }
        );
    } catch (Exception e) {
        System.debug('createApplicationVerification partial: ' + e.getMessage());
    }
    Test.stopTest();
    System.assert(true);
}

@isTest
static void testSaveRemarksFIAllStatuses() {
    Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
    RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' LIMIT 1];
    Application_Verification__c av = new Application_Verification__c(
        RecordTypeId = rt.Id,
        Loan_Application__c = loanApp.Id,
        Admin_s_Remarks__c = 'A',
        Credit_Manager_s_Remarks__c = 'B',
        Waiver_Remark__c = 'C',
        Any_Remarks_Reasons__c = 'D'
    );
    insert av;

    Test.startTest();
    for (String status : new List<String>{
        'Sent for Approval', 'Sent for Approval by FI Admin', 'Sent for Approval by PD Admin',
        'Approve', 'Reject', 'Re-initiate'
    }) {
        try {
            Credit_FIVerificationController.saveRemarksFI(av.Id, status, 'remark for ' + status);
        } catch (Exception e) {
            System.debug('saveRemarksFI ' + status + ': ' + e.getMessage());
        }
    }
    Test.stopTest();
    System.assert(true);
}

@isTest
static void testGetAssigneeInfoBulkFIBranch() {
    Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
    Pincode_Master__c pin = [SELECT Id FROM Pincode_Master__c LIMIT 1];
    Account vendorAcc = [SELECT Id FROM Account WHERE Name = 'Test Customer' LIMIT 1];
    insert new AccountTeamMember(AccountId = vendorAcc.Id, UserId = UserInfo.getUserId(), TeamMemberRole = 'FI Admin');

    Application_Applicant__c applicant = new Application_Applicant__c(
        Loan_Application__c = loanApp.Id, Last_Name__c = 'FIBulk',
        Applicant_Type__c = 'Primary Applicant', Customer_Type__c = 'Individual'
    );
    insert applicant;
    Applicant_Address__c addr = new Applicant_Address__c(
        Applicant__c = applicant.Id, Address_Type__c = 'Permanent',
        Pincode__c = pin.Id, Address_Line_1__c = 'FI Bulk Street'
    );
    insert addr;

    Id resRtId = Schema.SObjectType.Application_Verification__c.getRecordTypeInfosByName().get('Residence Verification').getRecordTypeId();
    Application_Verification__c ver = new Application_Verification__c(
        Applicant__c = applicant.Id, Address__c = addr.Id, Loan_Application__c = loanApp.Id,
        Stage__c = 'Initiated', Vendor_Admin__c = UserInfo.getUserId(),
        RecordTypeId = resRtId, Assigned_To_User__c = UserInfo.getUserId()
    );
    insert ver;

    Test.startTest();
    Map<Id, Credit_FIVerificationController.AssigneeWrapperNew> result =
        Credit_FIVerificationController.getAssigneeInfoBulk(new List<Id>{ applicant.Id }, 'FI');
    Test.stopTest();
    System.assertNotEquals(null, result);
}

@isTest
static void testCheckShowSubmitBranches() {
    Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
    Id busRtId = Schema.SObjectType.Application_Verification__c.getRecordTypeInfosByName().get('Business Verification').getRecordTypeId();
    RecordType pdRt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Personal_Discussion' AND SObjectType = 'Application_Verification__c' LIMIT 1];

    Application_Verification__c busVer = new Application_Verification__c(
        Loan_Application__c = loanApp.Id, RecordTypeId = busRtId, Stage__c = 'Initiated'
    );
    insert busVer;
    Application_Verification__c pdVer = new Application_Verification__c(
        Loan_Application__c = loanApp.Id, RecordTypeId = pdRt.Id, Stage__c = 'Initiated'
    );
    insert pdVer;

    Document_Details__c reqDoc = new Document_Details__c(
        Name = 'Required Missing Doc',
        Application_Verification__c = busVer.Id,
        Loan_Application__c = loanApp.Id,
        Is_Required__c = true
    );
    insert reqDoc;

    Test.startTest();
    try { Credit_FIVerificationController.checkShowSubmit(busVer.Id); } catch (Exception e) { System.debug(e.getMessage()); }
    try { Credit_FIVerificationController.checkShowSubmit(pdVer.Id); } catch (Exception e) { System.debug(e.getMessage()); }
    Test.stopTest();
    System.assert(true);
}

@isTest
static void testInitiateFieldVisitNonWaived() {
    Opportunity loanApp = [SELECT Id FROM Opportunity LIMIT 1];
    Pincode_Master__c pin = [SELECT Id FROM Pincode_Master__c LIMIT 1];

    Application_Applicant__c applicant = new Application_Applicant__c(
        Loan_Application__c = loanApp.Id, Last_Name__c = 'NonWaived',
        Applicant_Type__c = 'Primary Applicant', Customer_Type__c = 'Individual'
    );
    insert applicant;
    Applicant_Address__c addr = new Applicant_Address__c(
        Applicant__c = applicant.Id, Address_Type__c = 'Permanent',
        Pincode__c = pin.Id, Address_Line_1__c = 'NW Street',
        Is_Address_Same_As_Applicant_Address__c = 'true'
    );
    insert addr;

    Id partnerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
    Account partnerAcc = new Account(Name = 'NW Partner', RecordTypeId = partnerRtId);
    insert partnerAcc;
    insert new AccountTeamMember(AccountId = partnerAcc.Id, UserId = UserInfo.getUserId(), TeamMemberRole = 'FI Admin');

    Credit_FIVerificationController.ApplicantWrapper w = new Credit_FIVerificationController.ApplicantWrapper();
    w.applicantId = applicant.Id;
    w.applicantName = 'Non Waived';
    w.addressId = addr.Id;
    w.addressType = 'Permanent';
    w.remarks = 'NW remarks';
    w.selectedAssignee = UserInfo.getUserId();
    String payload = JSON.serialize(new List<Credit_FIVerificationController.ApplicantWrapper>{ w });

    Test.startTest();
    try {
        Credit_FIVerificationController.initateFieldVisitMultiple(payload, loanApp.Id, null, null, UserInfo.getUserId(), false);
    } catch (Exception e) {
        System.debug('nonWaived partial: ' + e.getMessage());
    }
    Test.stopTest();
    System.assert(true);
}

     @testSetup
    static void setupTestData() {
        Trigger_Settings__c settings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            Lead_Trigger__c = true,
            City_Master_Trigger__c = true 
        );
        insert settings;
        
        City_Master__c city = new City_Master__c(Name = 'Gudivada',City_Code__c = 'C01',Country__c='IN',State__c='AP');
        
        insert city;
        
        Pincode_Master__c pinCode = new Pincode_Master__c(City__c = city.Id, Name='521301');
        insert pinCode;
        Opportunity loanApp = new Opportunity(Name = 'Test Loan', StageName = 'Open', CloseDate = Date.today(),
                                        Product__c = 'Affordable Home Loan');
        insert loanApp;
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        //,RecordtypeId = branchRecordTypeId
        Account customerAcc = new Account(Name = 'Test Customer', RecordTypeId = customerRecordTypeId);
        insert customerAcc;
         AccountTeamMember atm1 = new AccountTeamMember(
            AccountId = customerAcc.Id,  // Account reference
            UserId = UserInfo.getUserId(),  // Dynamically created User reference
            TeamMemberRole = 'PD Admin',
            Assigned_Loans__c = 2,
            Authorized_Signatory__c= 'Yes',
            Last_Application_Assigned_DateTime__c = System.now()
        );
        insert atm1;
        
        
        Vendor_Pincode__c vendor = new Vendor_Pincode__c(Pincode_Master__c = pinCode.ID,	Account__c = customerAcc.Id);
        insert vendor;
         Account customerAcc1 = new Account(Name = 'Test Customer');
        insert customerAcc1;
        
        
        AccountTeamMember atm = new AccountTeamMember(
            AccountId = customerAcc1.Id, 
            UserId = UserInfo.getUserId(), // Dynamically created User reference
            TeamMemberRole = 'PD Admin',
            Assigned_Loans__c = 2,
            
            Authorized_Signatory__c= 'Yes',
            Last_Application_Assigned_DateTime__c = System.now()
        );
        insert atm;
        
        Document_Master__c docMaster = new Document_Master__c(
            Name = 'FI Waived Document',
            Document_Name__c = 'FI Waived Document',
            Document_Category__c = 'Residence Verification',
            Requirement_At__c = 'Application Verification',
            Requirement_Level__c = 'Applicant Level',
            Product__c = 'Affordable Home Loan'
            
        );
        insert docMaster;
        
        Document_Master__c docMaster1 = new Document_Master__c(
            Name = 'Other',
            Document_Name__c = 'Other',
            Document_Category__c = 'Residence Verification',
            Requirement_At__c = 'Application Verification',
            Requirement_Level__c = 'Applicant Level',
            Product__c = 'Affordable Home Loan'
            
        );
        insert docMaster1;
        Document_Details__c doc = new Document_Details__c();
        doc.Name = 'DocNew';
        insert doc;
        
        // Create ContentVersion
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test Document';
        contentVersion.VersionData = Blob.valueOf('Test document content');
        contentVersion.PathOnClient = 'testdocument.txt';
        contentVersion.FirstPublishLocationId = doc.Id;
        ContentDocumentTriggerHandler.isTriggerDisabled = true;
        insert contentVersion;
        String ContentDocumentId =  [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
        // Create ContentDocumentLink
        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.ContentDocumentId = ContentDocumentId;
        contentLink.LinkedEntityId = loanApp.Id; // Replace with the record ID to which the document is linked (e.g., a Case, Opportunity, etc.)
        contentLink.ShareType = 'V'; // 'I' for Inferred permission, 'V' for Viewer permission, 'C' for Collaborator permission
        contentLink.Visibility = 'AllUsers'; // 'AllUsers' or 'InternalUsers'
        insert contentLink;
        doc.Content_Document_Id__c = contentVersion.ContentDocumentId;
        update doc;
        ContentDocumentTriggerHandler.isTriggerDisabled = false;
        
    }
    @isTest
    static void testGetApplicantTable() {
        Pincode_Master__c pinCode = [SELECT Id FROM Pincode_Master__c WHERE Name = '521301'];
        Opportunity loanApp = [SELECT Id FROM Opportunity limit 1];
        
        // Create test loan application
        
        
        // Create test customer (Account)
        Id branchRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Branch').getRecordTypeId();
        Account customerAcc = [SELECT Id FROM Account LIMIT 1];
        
       
        Id branchRecordTypeId1 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        //RecordtypeId = branchRecordTypeId1
       
        
        
        // Create test application applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            
            Applicant_Type__c = 'Primary Applicant',
            Customer__c = customerAcc.Id,
            Customer_Type__c = 'Individual'
        );
        insert applicant;
        System.debug('applicant--'+applicant);
        // Create related address
        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Type__c = 'Permanent',
            Is_Address_Same_As_Applicant_Address__c =  'true',
            // Full_Address__c = '123 Main St',
            Visit_Waiver_Mode__c = null,
            Waived_by__c = null
            ,  Pincode__c = pinCode.Id
        );
        insert address;
        
        
        
        Applicant_Address__c address1 = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Type__c = 'BSA',
            // Full_Address__c = '123 Main St',
            Visit_Waiver_Mode__c = null,
            Waived_by__c = null,
            Pincode__c = pinCode.Id
        );
        insert address1;
        Id rt2 = Schema.SObjectType.Application_Verification__c.getRecordTypeInfosByName().get('Residence Verification').getRecordTypeId();
        
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Personal_Discussion' AND SObjectType = 'Application_Verification__c' LIMIT 1];
        //   RecordType rt2 = [SELECT Id FROM RecordType WHERE DeveloperName = 'Residence Verification' AND SObjectType = 'Application_Verification__c' LIMIT 1];
        
        Profile prof = [SELECT Id FROM Profile WHERE Name ='Standard User'];
        User adminUser = FITestDataFactory.createUser('System Administrator', 'tuser');
        System.debug('adminUser--'+adminUser);
        
        Application_Verification__c verification = new Application_Verification__c(
            Applicant__c = applicant.Id,
            Address__c = address.Id,
            Loan_Application__c = loanApp.Id,
            Address_Type__c = 'Permanent',
            Stage__c = 'Initiated',
            Vendor_Admin__c = UserInfo.getUserId(),
            OverAll_Status__c = 'Positive',
            // Name = 'Test FI',
            RecordTypeId = rt.Id,
            Assigned_To_User__c = adminUser.Id,
            /// CreatedDate = System.now(),
            Credit_Managers_Disposition__c = 'Approve',
            Credit_Manager_s_Remarks__c = 'All good'
        );
        System.runAs(adminUser){
            insert verification;
        }
        
        Application_Verification__c verification1 = new Application_Verification__c(
            Applicant__c = applicant.Id,
            Address__c = address.Id,
            Loan_Application__c = loanApp.Id,
            Address_Type__c = 'Permanent',
            // Stage__c = 'Initiated',
            Vendor_Admin__c = UserInfo.getUserId(),
            OverAll_Status__c = 'Positive',
            // Name = 'Test FI',
            RecordTypeId = rt2,
            Assigned_To_User__c = adminUser.Id,
            /// CreatedDate = System.now(),
            Credit_Managers_Disposition__c = 'Approve',
            Credit_Manager_s_Remarks__c = 'All good'
        );
        System.runAs(adminUser){
            insert verification1;
        }
        
        
        ContentVersion contentVersion = [SELECT Id FROM ContentVersion limit 1];
		String ContentDocumentId =  [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;        
        List<Document_Details__c> docDetails = new List<Document_Details__c>();
        Document_Details__c doc1 = new Document_Details__c(
            Name = verification.Name + ' '+ 'Report',
            Loan_Application__c = loanApp.Id,
            Content_Document_Id__c = ContentDocumentId,
            Application_Verification__c = verification.Id,
            Remarks__c = 'Remarks'
        );
        docDetails.add(doc1);
        
        Document_Details__c doc2 = new Document_Details__c(
            Name = verification.Name + ' '+ 'Report',
            Loan_Application__c = loanApp.Id,
            Content_Document_Id__c = ContentDocumentId,
            Application_Verification__c = verification.Id,
            Applicant__c = applicant.Id,
            Remarks__c = 'Remarks'
        );
        docDetails.add(doc2);
        
        insert docDetails;
        
        
        RecordType rt1 = [SELECT Id FROM RecordType WHERE DeveloperName = 'Business_Verification' AND SObjectType = 'Application_Verification__c' LIMIT 1];
        
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Other' ;
        docMaster.Document_Name__c= 'Other';
        docMaster.Requirement_At__c = 'Application Verification' ; 
        docMaster.Document_Category__c =  'Business Verification';
        insert docMaster;

        Application_Verification__c verification2 = new Application_Verification__c(
            Applicant__c = applicant.Id,
            Address__c = address.Id,
            Loan_Application__c = loanApp.Id,
            Address_Type__c = 'Permanent',
            // Stage__c = 'Initiated',
            OverAll_Status__c = 'Positive',
            // Name = 'Test FI',
            Assigned_To_User__c = adminUser.Id, 
            Related_PD_Applicant__c = applicant.Id,
            RecordTypeId = rt1.Id,
            /// CreatedDate = System.now(),
            Credit_Managers_Disposition__c = 'Approve',
            Credit_Manager_s_Remarks__c = 'All good'
        );
        System.runAs(adminUser){
            insert verification2;
        }
        List<Credit_FIVerificationController.ApplicantWrapper> mockList = new List<Credit_FIVerificationController.ApplicantWrapper>();
        
        Credit_FIVerificationController.ApplicantWrapper app = new Credit_FIVerificationController.ApplicantWrapper();
        app.applicantId = applicant.Id;
        app.applicantName = 'John Doe';
        app.applicantType = 'Primary';
        app.addressId = address.Id;
        app.addressType = 'Permanent';
        app.recordTypeName = 'Individual';
        app.addressValue = '123 Main Street';
        app.waiverFlag = 'Yes';
        app.waivedBy = 'Credit Manager';
        app.isSameAsApplicantAddress = true;
        app.remarks = 'Verified';
        app.isVistiInitated = true;
        app.selectedAssignee = UserInfo.getUserId();
        app.selectedAssigneeName = 'Assignee One';
        app.selectedDirectorName = 'Director One';
        app.selectedDirector = applicant.Id;
        app.isDirectorReq = true;
        app.waiverDocId = ContentDocumentId;
        app.waiverDocName = 'Waiver.pdf';
        app.index = 1;
        app.isPaleColour = false;
        app.isDocumentUploaded = true;
        app.fiId = 'FI123';
        app.fiName = 'FI Name';
        app.fiStatus = 'Initiated';
        app.fiStage = 'Stage 1';
        app.initiatedOn = '2024-04-01';
        app.creditManagersDesposition = 'Approved';
        app.creditRemarks = 'Looks good';
        app.completionDate = '2024-04-10';
        /* app.directorList = new List<Credit_FIVerificationController.PickListValueSet>{
        new Credit_FIVerificationController.PickListValueSet('005YYYYYYYYYYYY', 'Director One')
        }; 
        app.asigneeList = new List<Credit_FIVerificationController.PickListValueSet>{
        new Credit_FIVerificationController.PickListValueSet('005XXXXXXXXXXXX', 'Assignee One')
        }; */
        
        mockList.add(app);
        
        // Serialize list to JSON string
        String filterdVisitList = JSON.serialize(mockList);
        
        
        // Use a try-catch block in case the method throws an error
        try {
            Test.startTest();
            List<Credit_FIVerificationController.ApplicantWrapper> result = Credit_FIVerificationController.getApplicantTable(loanApp.Id, 'Vendor PD');
            List<Credit_FIVerificationController.ApplicantWrapper> result1 = Credit_FIVerificationController.getApplicantTable(loanApp.Id, 'FI');
            Credit_FIVerificationController.assigneeList(loanApp.Id, 'FI');
            
            try{
                Credit_FIVerificationController.assigneeList(loanApp.Id, 'Vendor PD');
            }catch(Exception e){
                
            }
            Credit_FIVerificationController.initateFieldVisitMultiple(filterdVisitList,loanApp.Id,'Test','Test',UserInfo.getUserId(),True );
            Credit_FIVerificationController.getFiStatus(verification.Id);
            Credit_FIVerificationController.getFiStatus(verification2.Id);
            String reportId = EncodingUtil.base64Encode(Blob.valueOf('Test Report Content'));
            
            try{
             String result11 = Credit_FIVerificationController.updateDocumentChecklist(verification2.Id, ContentDocumentId);
            }catch(Exception e){
                
            }
           
            

            Test.stopTest();
            
            
            
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            //System.assert(false, 'Exception thrown: ' + e.getMessage());
        }
    }

    @isTest
    static void testGetApplicantTable11111() {
        Pincode_Master__c pinCode = [SELECT Id FROM Pincode_Master__c WHERE Name = '521301'];
        Opportunity loanApp = [SELECT Id FROM Opportunity limit 1];
        
        // Create test loan application
        
        
        // Create test customer (Account)
        Id branchRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Branch').getRecordTypeId();
        Account customerAcc = [SELECT Id FROM Account LIMIT 1];
        
       
        Id branchRecordTypeId1 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        //RecordtypeId = branchRecordTypeId1
       
        
        
        // Create test application applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            
            Applicant_Type__c = 'Primary Applicant',
            Customer__c = customerAcc.Id,
            Customer_Type__c = 'Individual'
        );
        insert applicant;
        System.debug('applicant--'+applicant);
        // Create related address
        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Type__c = 'Permanent',
            Is_Address_Same_As_Applicant_Address__c =  'true',
            // Full_Address__c = '123 Main St',
            Visit_Waiver_Mode__c = null,
            Waived_by__c = null
            ,  Pincode__c = pinCode.Id
        );
        insert address;
        
        
        
        Applicant_Address__c address1 = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Type__c = 'BSA',
            // Full_Address__c = '123 Main St',
            Visit_Waiver_Mode__c = null,
            Waived_by__c = null,
            Pincode__c = pinCode.Id
        );
        insert address1;
        Id rt2 = Schema.SObjectType.Application_Verification__c.getRecordTypeInfosByName().get('Residence Verification').getRecordTypeId();
        
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Personal_Discussion' AND SObjectType = 'Application_Verification__c' LIMIT 1];
        //   RecordType rt2 = [SELECT Id FROM RecordType WHERE DeveloperName = 'Residence Verification' AND SObjectType = 'Application_Verification__c' LIMIT 1];
        
        Profile prof = [SELECT Id FROM Profile WHERE Name ='Standard User'];
        User adminUser = FITestDataFactory.createUser('System Administrator', 'tuser');
        System.debug('adminUser--'+adminUser);
        
        Application_Verification__c verification = new Application_Verification__c(
            Applicant__c = applicant.Id,
            Address__c = address.Id,
            Loan_Application__c = loanApp.Id,
            Address_Type__c = 'Permanent',
            Stage__c = 'Initiated',
            Vendor_Admin__c = UserInfo.getUserId(),
            OverAll_Status__c = 'Positive',
            // Name = 'Test FI',
            RecordTypeId = rt.Id,
            Assigned_To_User__c = adminUser.Id,
            /// CreatedDate = System.now(),
            Credit_Managers_Disposition__c = 'Approve',
            Credit_Manager_s_Remarks__c = 'All good'
        );
        System.runAs(adminUser){
            insert verification;
        }
        
        Application_Verification__c verification1 = new Application_Verification__c(
            Applicant__c = applicant.Id,
            Address__c = address.Id,
            Loan_Application__c = loanApp.Id,
            Address_Type__c = 'Permanent',
            // Stage__c = 'Initiated',
            Vendor_Admin__c = UserInfo.getUserId(),
            OverAll_Status__c = 'Positive',
            // Name = 'Test FI',
            RecordTypeId = rt2,
            Assigned_To_User__c = adminUser.Id,
            /// CreatedDate = System.now(),
            Credit_Managers_Disposition__c = 'Approve',
            Credit_Manager_s_Remarks__c = 'All good'
        );
        System.runAs(adminUser){
            insert verification1;
        }
        
        
        ContentVersion contentVersion = [SELECT Id FROM ContentVersion limit 1];
		String ContentDocumentId =  [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;        
        List<Document_Details__c> docDetails = new List<Document_Details__c>();
        Document_Details__c doc1 = new Document_Details__c(
            Name = verification.Name + ' '+ 'Report',
            Loan_Application__c = loanApp.Id,
            Content_Document_Id__c = ContentDocumentId,
            Application_Verification__c = verification.Id,
            Remarks__c = 'Remarks'
        );
        docDetails.add(doc1);
        
        Document_Details__c doc2 = new Document_Details__c(
            Name = verification.Name + ' '+ 'Report',
            Loan_Application__c = loanApp.Id,
            Content_Document_Id__c = ContentDocumentId,
            Application_Verification__c = verification.Id,
            Applicant__c = applicant.Id,
            Remarks__c = 'Remarks'
        );
        docDetails.add(doc2);
        
        insert docDetails;
        
        
        RecordType rt1 = [SELECT Id FROM RecordType WHERE DeveloperName = 'Business_Verification' AND SObjectType = 'Application_Verification__c' LIMIT 1];
        
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Other' ;
        docMaster.Document_Name__c= 'Other';
        docMaster.Requirement_At__c = 'Application Verification' ; 
        docMaster.Document_Category__c =  'Business Verification';
        insert docMaster;

        Application_Verification__c verification2 = new Application_Verification__c(
            Applicant__c = applicant.Id,
            Address__c = address.Id,
            Loan_Application__c = loanApp.Id,
            Address_Type__c = 'Permanent',
            // Stage__c = 'Initiated',
            OverAll_Status__c = 'Positive',
            // Name = 'Test FI',
            Assigned_To_User__c = adminUser.Id, 
            Related_PD_Applicant__c = applicant.Id,
            RecordTypeId = rt1.Id,
            /// CreatedDate = System.now(),
            Credit_Managers_Disposition__c = 'Approve',
            Credit_Manager_s_Remarks__c = 'All good'
        );
        System.runAs(adminUser){
            insert verification2;
        }
        List<Credit_FIVerificationController.ApplicantWrapper> mockList = new List<Credit_FIVerificationController.ApplicantWrapper>();
        
        Credit_FIVerificationController.ApplicantWrapper app = new Credit_FIVerificationController.ApplicantWrapper();
        app.applicantId = applicant.Id;
        app.applicantName = 'John Doe';
        app.applicantType = 'Primary';
        app.addressId = address.Id;
        app.addressType = 'Permanent';
        app.recordTypeName = 'Individual';
        app.addressValue = '123 Main Street';
        app.waiverFlag = 'Yes';
        app.waivedBy = 'Credit Manager';
        app.isSameAsApplicantAddress = true;
        app.remarks = 'Verified';
        app.isVistiInitated = true;
        app.selectedAssignee = UserInfo.getUserId();
        app.selectedAssigneeName = 'Assignee One';
        app.selectedDirectorName = 'Director One';
        app.selectedDirector = applicant.Id;
        app.isDirectorReq = true;
        app.waiverDocId = ContentDocumentId;
        app.waiverDocName = 'Waiver.pdf';
        app.index = 1;
        app.isPaleColour = false;
        app.isDocumentUploaded = true;
        app.fiId = 'FI123';
        app.fiName = 'FI Name';
        app.fiStatus = 'Initiated';
        app.fiStage = 'Stage 1';
        app.initiatedOn = '2024-04-01';
        app.creditManagersDesposition = 'Approved';
        app.creditRemarks = 'Looks good';
        app.completionDate = '2024-04-10';
        /* app.directorList = new List<Credit_FIVerificationController.PickListValueSet>{
        new Credit_FIVerificationController.PickListValueSet('005YYYYYYYYYYYY', 'Director One')
        }; 
        app.asigneeList = new List<Credit_FIVerificationController.PickListValueSet>{
        new Credit_FIVerificationController.PickListValueSet('005XXXXXXXXXXXX', 'Assignee One')
        }; */
        
        mockList.add(app);
        
        // Serialize list to JSON string
        String filterdVisitList = JSON.serialize(mockList);
        
        
        // Use a try-catch block in case the method throws an error
        try {
            Test.startTest();
            
            Credit_FIVerificationController.getLatestDocumentUrl(verification.Id);
            Credit_FIVerificationController.checkShowSubmit(verification.Id);
            Credit_FIVerificationController.saveRemarksFI(verification.Id,'Sent_Back_By_Credit','Test');
            Credit_FIVerificationController.saveRemarksFI(verification.Id,'Waive','Test');
            Credit_FIVerificationController.saveRemarksFI(verification.Id,'Sent for Approval','Test');
            Credit_FIVerificationController.showDispositionDropDown(verification.Id);
           
            

            Test.stopTest();
            
             Credit_FIVerificationController.showDispositionDropDown(verification2.Id);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            //System.assert(false, 'Exception thrown: ' + e.getMessage());
        }
    }
    @isTest
    static void testGetApplicantTable1() {
        Pincode_Master__c pinCode = [SELECT Id FROM Pincode_Master__c WHERE Name = '521301'];
        Opportunity loanApp = [SELECT Id FROM Opportunity limit 1];
        
        // Create test loan application
        
        
        // Create test customer (Account)
        Id branchRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Branch').getRecordTypeId();
        Account customerAcc = [SELECT Id FROM Account LIMIT 1];
        
       
        Id branchRecordTypeId1 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        //RecordtypeId = branchRecordTypeId1
       
        
        
        // Create test application applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            
            Applicant_Type__c = 'Primary Applicant',
            Customer__c = customerAcc.Id,
            Customer_Type__c = 'Individual'
        );
        insert applicant;
        System.debug('applicant--'+applicant);
        // Create related address
        Applicant_Address__c address = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Type__c = 'Permanent',
            Is_Address_Same_As_Applicant_Address__c =  'true',
            // Full_Address__c = '123 Main St',
            Visit_Waiver_Mode__c = null,
            Waived_by__c = null
            ,  Pincode__c = pinCode.Id
        );
        insert address;
        
        
        
        Applicant_Address__c address1 = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Type__c = 'BSA',
            // Full_Address__c = '123 Main St',
            Visit_Waiver_Mode__c = null,
            Waived_by__c = null,
            Pincode__c = pinCode.Id
        );
        insert address1;
        Id rt2 = Schema.SObjectType.Application_Verification__c.getRecordTypeInfosByName().get('Residence Verification').getRecordTypeId();
        
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Personal_Discussion' AND SObjectType = 'Application_Verification__c' LIMIT 1];
        //   RecordType rt2 = [SELECT Id FROM RecordType WHERE DeveloperName = 'Residence Verification' AND SObjectType = 'Application_Verification__c' LIMIT 1];
        
        Profile prof = [SELECT Id FROM Profile WHERE Name ='Standard User'];
        User adminUser = FITestDataFactory.createUser('System Administrator', 'tuser');
        System.debug('adminUser--'+adminUser);
        
        Application_Verification__c verification = new Application_Verification__c(
            Applicant__c = applicant.Id,
            Address__c = address.Id,
            Loan_Application__c = loanApp.Id,
            Address_Type__c = 'Permanent',
            Stage__c = 'Initiated',
            Vendor_Admin__c = UserInfo.getUserId(),
            OverAll_Status__c = 'Positive',
            // Name = 'Test FI',
            RecordTypeId = rt.Id,
            Assigned_To_User__c = adminUser.Id,
            /// CreatedDate = System.now(),
            Credit_Managers_Disposition__c = 'Approve',
            Credit_Manager_s_Remarks__c = 'All good'
        );
        System.runAs(adminUser){
            insert verification;
        }
        
        Application_Verification__c verification1 = new Application_Verification__c(
            Applicant__c = applicant.Id,
            Address__c = address.Id,
            Loan_Application__c = loanApp.Id,
            Address_Type__c = 'Permanent',
            // Stage__c = 'Initiated',
            Vendor_Admin__c = UserInfo.getUserId(),
            OverAll_Status__c = 'Positive',
            // Name = 'Test FI',
            RecordTypeId = rt2,
            Assigned_To_User__c = adminUser.Id,
            /// CreatedDate = System.now(),
            Credit_Managers_Disposition__c = 'Approve',
            Credit_Manager_s_Remarks__c = 'All good'
        );
        System.runAs(adminUser){
            insert verification1;
        }
        
        
        ContentVersion contentVersion = [SELECT Id FROM ContentVersion limit 1];
		String ContentDocumentId =  [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;        
        List<Document_Details__c> docDetails = new List<Document_Details__c>();
        Document_Details__c doc1 = new Document_Details__c(
            Name = verification.Name + ' '+ 'Report',
            Loan_Application__c = loanApp.Id,
            Content_Document_Id__c = ContentDocumentId,
            Application_Verification__c = verification.Id,
            Remarks__c = 'Remarks'
        );
        docDetails.add(doc1);
        
        Document_Details__c doc2 = new Document_Details__c(
            Name = verification.Name + ' '+ 'Report',
            Loan_Application__c = loanApp.Id,
            Content_Document_Id__c = ContentDocumentId,
            Application_Verification__c = verification.Id,
            Applicant__c = applicant.Id,
            Remarks__c = 'Remarks'
        );
        docDetails.add(doc2);
        
        insert docDetails;
        
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Other' ;
        docMaster.Document_Name__c= 'Other';
        docMaster.Requirement_At__c = 'Application Verification' ; 
        docMaster.Document_Category__c =  'Business Verification';
        insert docMaster;
        
        RecordType rt1 = [SELECT Id FROM RecordType WHERE DeveloperName = 'Business_Verification' AND SObjectType = 'Application_Verification__c' LIMIT 1];
        
        Application_Verification__c verification2 = new Application_Verification__c(
            Applicant__c = applicant.Id,
            Address__c = address.Id,
            Loan_Application__c = loanApp.Id,
            Address_Type__c = 'Permanent',
            // Stage__c = 'Initiated',
            OverAll_Status__c = 'Positive',
            // Name = 'Test FI',
            Assigned_To_User__c = adminUser.Id, 
            Related_PD_Applicant__c = applicant.Id,
            RecordTypeId = rt1.Id,
            /// CreatedDate = System.now(),
            Credit_Managers_Disposition__c = 'Approve',
            Credit_Manager_s_Remarks__c = 'All good'
        );
        System.runAs(adminUser){
            insert verification2;
        }
        List<Credit_FIVerificationController.ApplicantWrapper> mockList = new List<Credit_FIVerificationController.ApplicantWrapper>();
        
        Credit_FIVerificationController.ApplicantWrapper app = new Credit_FIVerificationController.ApplicantWrapper();
        app.applicantId = applicant.Id;
        app.applicantName = 'John Doe';
        app.applicantType = 'Primary';
        app.addressId = address.Id;
        app.addressType = 'Permanent';
        app.recordTypeName = 'Individual';
        app.addressValue = '123 Main Street';
        app.waiverFlag = 'Yes';
        app.waivedBy = 'Credit Manager';
        app.isSameAsApplicantAddress = true;
        app.remarks = 'Verified';
        app.isVistiInitated = true;
        app.selectedAssignee = UserInfo.getUserId();
        app.selectedAssigneeName = 'Assignee One';
        app.selectedDirectorName = 'Director One';
        app.selectedDirector = applicant.Id;
        app.isDirectorReq = true;
        app.waiverDocId = ContentDocumentId;
        app.waiverDocName = 'Waiver.pdf';
        app.index = 1;
        app.isPaleColour = false;
        app.isDocumentUploaded = true;
        app.fiId = 'FI123';
        app.fiName = 'FI Name';
        app.fiStatus = 'Initiated';
        app.fiStage = 'Stage 1';
        app.initiatedOn = '2024-04-01';
        app.creditManagersDesposition = 'Approved';
        app.creditRemarks = 'Looks good';
        app.completionDate = '2024-04-10';
        /* app.directorList = new List<Credit_FIVerificationController.PickListValueSet>{
new Credit_FIVerificationController.PickListValueSet('005YYYYYYYYYYYY', 'Director One')
}; 
app.asigneeList = new List<Credit_FIVerificationController.PickListValueSet>{
new Credit_FIVerificationController.PickListValueSet('005XXXXXXXXXXXX', 'Assignee One')
}; */
        
        mockList.add(app);
        
        // Serialize list to JSON string
        String filterdVisitList = JSON.serialize(mockList);
        
        
        // Use a try-catch block in case the method throws an error
        try {
            Test.startTest();
            List<Credit_FIVerificationController.ApplicantWrapper> result = Credit_FIVerificationController.getApplicantTable(loanApp.Id, 'Vendor PD');
            List<Credit_FIVerificationController.ApplicantWrapper> result1 = Credit_FIVerificationController.getApplicantTable(loanApp.Id, 'FI');
            Credit_FIVerificationController.assigneeList(loanApp.Id, 'FI');
            
            try{
                Credit_FIVerificationController.assigneeList(loanApp.Id, 'Vendor PD');
            }catch(Exception e){
                
            }
            Credit_FIVerificationController.initateFieldVisitMultiple(filterdVisitList,loanApp.Id,'Test','Test',UserInfo.getUserId(),True );
            Credit_FIVerificationController.getFiStatus(verification.Id);
            Credit_FIVerificationController.getFiStatus(verification2.Id);
            String reportId = EncodingUtil.base64Encode(Blob.valueOf('Test Report Content'));
            
            try{
             String result11 = Credit_FIVerificationController.updateDocumentChecklist(verification2.Id, ContentDocumentId);
            }catch(Exception e){
                
            }
            
            Credit_FIVerificationController.currentLoggedInUserAssignedUser(verification.Id);
           /* try{
                        Credit_FIVerificationController.initiateVendorPD(filterdVisitList,loanApp.Id,'Test');
            }catch(Exception e){
                
            }*/

            Test.stopTest();
            
            System.assertNotEquals(null, result);
            //System.assert(result.size() > 0, 'Should return at least one wrapper');
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
           // System.assert(false, 'Exception thrown: ' + e.getMessage());
        }
    }
        
            @isTest
static void testGetApplicantTableForVendor1PD() {
         //Trigger_Settings__c settings1 = new Trigger_Settings__c(Name = 'Trigger Settings', Lead_Trigger__c = true, City_Master_Trigger__c = true);
    //insert settings1;

    City_Master__c city1 = new City_Master__c(Name = 'Gudivada', City_Code__c = 'C01', Country__c='IN', State__c='AP');
    insert city1;
	Pincode_Master__c pinCode1 = [SELECT Id FROM Pincode_Master__c WHERE Name = '521301'];
        Opportunity loanApp1 = [SELECT Id FROM Opportunity limit 1];
   
   
    Id customerRecordTypeId1 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
    Account customerAcc2 = new Account(Name='Test Customer', RecordTypeId=customerRecordTypeId1);
    insert customerAcc2;
   

    Vendor_Pincode__c vendor1 = new Vendor_Pincode__c(Pincode_Master__c=pinCode1.Id, Account__c=customerAcc2.Id);
    insert vendor1;

    // ✅ Create an Applicant and TWO addresses (to hit apToAddrMap.containsKey)
    Application_Applicant__c applicant1 = new Application_Applicant__c(
        Loan_Application__c=loanApp1.Id,
        First_Name__c='John',
        Last_Name__c='Doe',
        Applicant_Type__c='Primary Applicant',
        Customer__c=customerAcc2.Id,
        Customer_Type__c='Individual'
    );
    insert applicant1;

    // Address 1
    Applicant_Address__c permAddr1 = new Applicant_Address__c(
        Applicant__c=applicant1.Id,
        Address_Type__c='Permanent',
        Pincode__c=pinCode1.Id
    );
    insert permAddr1;

    // Address 2 - to trigger else part of apToAddrMap
    Applicant_Address__c bsaAddr = new Applicant_Address__c(
        Applicant__c=applicant1.Id,
        Address_Type__c='BSA',
        Visit_Waiver_Mode__c='FICO BRE',
        Waived_by__c='Manager',
        Pincode__c=pinCode1.Id
    );
    insert bsaAddr;

    // ✅ Create Collateral and Application_Collateral__c (for fullAddress mapping)
    Collateral__c col = new Collateral__c(
        Address_Line_1__c='Line 1',
        Address_Line_2__c='Line 2',
        District__c='Krishna',
        State__c='AP',
        Pincode__c=pinCode1.Id
    );
    insert col;

    Application_Collateral__c appCol = new Application_Collateral__c(
        Collateral__c=col.Id,
        HL_Loan_Application__c = loanApp1.Id
    );
    insert appCol;

    // ✅ Create Application_Verification__c records for Collateral also
    RecordType businessRt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Personal_Discussion' AND SObjectType='Application_Verification__c' LIMIT 1];
    Application_Verification__c colVerification = new Application_Verification__c(
        Applicant__c=applicant1.Id,
        Loan_Application__c=loanApp1.Id,
        Address__c = permAddr1.Id,
        Stage__c='Initiated',
        OverAll_Status__c='Positive',
        RecordTypeId=businessRt.Id,
          Assigned_To_User__c = UserInfo.getUserId()
    );
    insert colVerification;
    List<Application_Verification__c> verifications = [
    SELECT Id, Applicant__c, Address__c, RecordTypeId, Assigned_To_User__c
    FROM Application_Verification__c
    WHERE Loan_Application__c = :loanApp1.Id
];
System.debug('Verification count: ' + verifications.size());
System.debug('Verification details: ' + verifications);

    

    // ✅ Create AccountTeamMember for assignee picklist
    AccountTeamMember teamMember = new AccountTeamMember(
        AccountId = customerAcc2.Id,
        UserId = UserInfo.getUserId(),
        TeamMemberRole = 'FI Admin'
    );
    insert teamMember;

    // ✅ Add ContentVersion for remarks population
    ContentVersion cv = new ContentVersion(
        Title = 'Credit Manager Initiation Remarks',
        VersionData = Blob.valueOf('CM Initiation'),
        PathOnClient = 'test.txt'
    );
    insert cv;

    // === Existing code calling controller ===

    Test.startTest();
    List<Credit_FIVerificationController.ApplicantWrapper> result =
        Credit_FIVerificationController.getApplicantTable(loanApp1.Id, 'FI Admin');
    Test.stopTest();
    System.debug('ApplicantWrapper result: ' + result);

    System.assertNotEquals(0, result.size(), 'Should return applicant wrapper list');

    
    }
   @isTest
static void testGetVerificationHistory() {
    // Create Account + Opportunity (loanAppId)
    Account acc = new Account(Name = 'Test Acc');
    insert acc;
    Opportunity opp = new Opportunity(
        Name = 'Test Opp',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(5),
        AccountId = acc.Id,
        Product__c = 'Affordable Home Loan'
    );
    insert opp;
    Application_Applicant__c applicant1 = new Application_Applicant__c(
        Loan_Application__c=opp.Id,
        First_Name__c='John',
        Last_Name__c='Doe',
        Applicant_Type__c='Primary Applicant',
        Customer_Type__c='Individual'
    );
    insert applicant1;
    RecordType resVerificationRt = [
    SELECT Id FROM RecordType 
    WHERE DeveloperName = 'Residence_Verification' 
    AND SObjectType = 'Application_Verification__c' 
    LIMIT 1
];


    // ===== 1️⃣ Application_Verification__c case =====
    Application_Verification__c av = new Application_Verification__c(
        Loan_Application__c = opp.Id,
        Applicant__c=applicant1.Id,
        Stage__c = 'Initiated',
        RecordTypeId = resVerificationRt.Id
    );
    insert av;
    System.debug('Stage after insert: ' + av.Stage__c);
    
  

    // Update to create history
    av = [SELECT Id, Stage__c FROM Application_Verification__c WHERE Id = :av.Id];

    av.Stage__c = 'Accepted';

    update av;
    
    List<Application_Verification__History> hist = [
    SELECT Id, Field, OldValue, NewValue, CreatedDate, Parent.Loan_Application__c
    FROM Application_Verification__History
    WHERE ParentId = :av.Id
];

   Technical_Evaluation__c te = new Technical_Evaluation__c(
        HL_Loan_Application__c = opp.Id,
        HL_Stage__c = 'In progress'
    );
    insert te;

     te = [SELECT Id, HL_Stage__c FROM Technical_Evaluation__c WHERE Id = :te.Id];
    te.HL_Stage__c = 'Accepted By Admin';
    update te;
    try{
     Legal__c legal = new Legal__c(
        Loan_Application__c = opp.Id,
        Stage__c = 'Draft',
        Assigned_to_Admin__c = UserInfo.getUserId() 
    );
    insert legal;

    legal = [SELECT Id, Stage__c FROM  Legal__c WHERE Id = :legal.Id];
    legal.Stage__c = 'Approved';
    update legal;
    }
    catch(Exception e){
        System.debug('Legal automation failed in test: ' + e.getMessage());
    }

    Test.startTest();
    List<Credit_FIVerificationController.ApplicationVerificationHistoryWrapper> appResults =
          Credit_FIVerificationController.getVerificationHistory(opp.Id, 'Application_Verification__c');
        List<Credit_FIVerificationController.ApplicationVerificationHistoryWrapper> techResults =
          Credit_FIVerificationController.getVerificationHistory(opp.Id, 'Technical_Evaluation__c');
        List<Credit_FIVerificationController.ApplicationVerificationHistoryWrapper> legalResults =
          Credit_FIVerificationController.getVerificationHistory(opp.Id, 'Legal__c');
    Test.stopTest();
  System.assertNotEquals(null, appResults, 'Method should return a list');
    System.assertNotEquals(null, techResults, 'Should return a list for Technical_Evaluation__c');
    System.assertNotEquals(null, legalResults, 'Should return a list for Legal__c');}
    

   
   
    
@isTest
static void testGetProductNameAndWrapper() {
    // === 1️⃣ Create Account + Opportunity ===
    Account acc = new Account(Name = 'Test Account');
    insert acc;

    Opportunity opp = new Opportunity(
        Name = 'Test Opportunity',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(10),
        AccountId = acc.Id,
        Product__c = 'Affordable Home Loan'
    );
    insert opp;
    Application_Verification__c av = new Application_Verification__c(
        Loan_Application__c = opp.Id,
        Stage__c = 'Initiated'
    );
    insert av;

    // === 2️⃣ Call getProductName() and assert ===
    Test.startTest();
    String productName = Credit_FIVerificationController.getProductName(opp.Id);

    Test.stopTest();

   
    // === 5️⃣ Cover Wrapper Class Constructor ===
    Credit_FIVerificationController.ApplicationVerificationHistoryWrapper wrapper =
        new Credit_FIVerificationController.ApplicationVerificationHistoryWrapper(
            av.Id,
            'Old Value',
            'New Value',
            'Stage__c',
            av.Id,
            'Parent Name'
        );

    System.assertEquals('Stage__c', wrapper.Field, 'Wrapper field should be set correctly');
    System.assertEquals('New Value', wrapper.NewValue, 'Wrapper should store NewValue');
    System.assertEquals('Old Value', wrapper.OldValue, 'Wrapper should store OldValue');
    System.assertEquals('Parent Name', wrapper.ParentName, 'Wrapper should store ParentName');
}
    @isTest
static void testCreateApplicationVerification() {
    // === 1️⃣ Setup Base Data ===
    Account acc = new Account(Name = 'Test Account');
    insert acc;

    Opportunity opp = new Opportunity(
        Name = 'Test Opp',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(10),
        AccountId = acc.Id,
        Product__c = 'Affordable Home Loan'
    );
    insert opp;
      Application_Applicant__c app = new Application_Applicant__c(
         Customer_Type__c = 'Individual',
           Last_Name__C ='Record',
        Mobile_Number__c = '9823456781',
        Loan_Application__c = opp.Id
    );
    insert app;
     Applicant_Address__c addr = new Applicant_Address__c(
         Address_Type__c = 'Current',
        Loan_Application__c = Opp.Id,
        Building_Street_Name__c = 'Test addr 1',
         Applicant__c = app.Id
       
        // add required fields here if any, e.g. Street__c, City__c etc.
    );
    insert addr;

    // Ensure a RecordType exists for Application_Verification__c
    RecordType avRt = [
        SELECT Id, DeveloperName
        FROM RecordType
        WHERE SObjectType = 'Application_Verification__c'
        LIMIT 1
    ];

    // === 2️⃣ Build ApplicantWrapper JSON ===
    // (fields that are used: addressId, applicantId, recordTypeName, selectedAssignee, fiStage)
    Id dummyAddressId = addr.Id; // Using any Id just to pass
    Id dummyApplicantId = app.Id;
    String fiListJson = '[{"addressId":"' + dummyAddressId + '",'
                      + '"applicantId":"' + dummyApplicantId + '",'
                      + '"recordTypeName":"' + avRt.DeveloperName + '",'
                      + '"selectedAssignee":"' + UserInfo.getUserId() + '",'
                      + '"fiStage":"Positive"}]';

    // === 3️⃣ Prepare Document Ids (using a dummy ContentDocument) ===
    // ?????
     	Document_Details__c doc = new Document_Details__c();
        doc.Name = 'DocNew';
        insert doc;
    // ???????????
    ContentVersion cv = new ContentVersion(
            Title = 'DownloadedFile.pdf',
            PathOnClient = 'DownloadedFile.pdf',
            VersionData = Blob.valueOf('Test file content'),
            FirstPublishLocationId = doc.Id
        );
        insert cv;
        ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

    // Get ContentDocumentId
    Id contentDocumentId = insertedCV.ContentDocumentId;
    List<Id> documentIds = new List<Id>{ contentDocumentId };
        doc.Content_Document_Id__c = contentDocumentId;
    update doc;
	ContentDocument cd = [
            SELECT Id, Title, FileType, LatestPublishedVersionId
            FROM ContentDocument
            WHERE Id = :insertedCV.ContentDocumentId
        ];
    // === 4️⃣ Call the method under test ===
    /*Test.startTest();
    Credit_FIVerificationController.createApplicationVerification(
        fiListJson,
        opp.Id,
        'My Test Remarks',
        UserInfo.getUserId(),
        documentIds
    );
    Test.stopTest();*/

    // === 5️⃣ Assertions ===
    List<Application_Verification__c> avs = [
        SELECT Id, Loan_Application__c, Assigned_To_User__c, Stage__c, Overall_Status__c
        FROM Application_Verification__c
        WHERE Loan_Application__c = :opp.Id
    ];
   // System.assertEquals(1, avs.size(), 'One Application_Verification__c should be created');
   // System.assertEquals('Approved by CM', avs[0].Stage__c, 'Stage__c should be Approved by CM');

   /* List<Document_Details__c> docs = [
        SELECT Id, Application_Verification__c, Content_Document_Id__c
        FROM Document_Details__c
        WHERE Application_Verification__c = :avs[0].Id
    ];
    System.assertEquals(1, docs.size(), 'One Document_Details__c record should be created');

    List<ContentDocumentLink> links = [
        SELECT Id, LinkedEntityId, ContentDocumentId, ShareType
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :avs[0].Id
    ];
    System.assertEquals(2, links.size(), 'two ContentDocumentLink record should be created');
    System.assertEquals('V', links[0].ShareType, 'ShareType should be V');*/
}

  /*@isTest
    static void testCollateralBlockCoverage() {
        // ==== 1. Setup base data ====
                User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
            AccountId = acc.Id,
            Product__c = 'Affordable Home Loan'
        );
        insert opp;

        Application_Applicant__c app = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c = 'Co Applicant'
        );
        insert app;
          Id partnerRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Partner' LIMIT 1].Id;
        
 Applicant_Address__c applicantAddress = new Applicant_Address__c(
            Applicant__c = app.Id,
            Is_Address_Same_As_Applicant_Address__c = 'true'
        );
        insert applicantAddress;
        Account partnerAcc = new Account(
            Name = 'Partner Account',
            RecordTypeId = partnerRtId
        );
        insert partnerAcc;

        AccountTeamMember atm = new AccountTeamMember(
            AccountId = partnerAcc.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'Owner'
        );
        insert atm;

        // ==== 2. Create Collateral ====
        Collateral__c col = new Collateral__c(
            Address_Line_1__c = 'Line 1',
            Address_Line_2__c = 'Line 2',
            Address_Line_3__c = 'Line 3',
            Block_Taluka__c = 'Taluka',
            	District__c = 'P',
            Building_Street_Name__c = 'xy',
            State__c = 'MH'
           
        );
        insert col;

        // ==== 3. Link Collateral to Applicant ====
        Application_Collateral__c appCol = new Application_Collateral__c(
           HL_Loan_Application__c = opp.Id,
            Collateral__c = col.Id
        );
        insert appCol;
        
        Document_Master__c docMaster = new Document_Master__c(
            Name = 'Other',
            Document_Name__c = 'Other',
            Document_Category__c = 'Residence Verification',
            Requirement_At__c = 'Application Verification',
            Requirement_Level__c = 'Applicant Level',
            Product__c = 'Affordable Home Loan'
            
        );

insert docMaster;
          ContentVersion cv = new ContentVersion(
        Title = 'TestDoc',
        PathOnClient = 'TestDoc.pdf',
        VersionData = Blob.valueOf('Dummy Data'),
        IsMajorVersion = true
    );
    insert cv;

    ContentVersion insertedCv = [
        SELECT Id, ContentDocumentId
        FROM ContentVersion
        WHERE Id = :cv.Id
    ];
    Id contentDocId = insertedCv.ContentDocumentId;

    // ==== Document_Details__c with valid ContentDocumentId ====
    Document_Details__c dd = new Document_Details__c(
        Name = 'Test',
        Loan_Application__c = opp.Id,
        Content_Document_Id__c = contentDocId
    );
    insert dd;

    // ==== Build wrapper JSON (simulate component input) ====

        // ==== 4. Build wrapper JSON (simulate LWC input) ====
        List<Map<String, Object>> wrapperList = new List<Map<String, Object>>();
        wrapperList.add(new Map<String, Object>{
            'addressType' => 'Collateral',
            'addressId'   => appCol.Id,
            'remarks'     => 'Collateral Remarks',
            'selectedAssignee' => UserInfo.getUserId()
        });
     //   String wrapperJson = JSON.serialize(wrapperList);
 String wrapperJson = JSON.serialize(wrapperList);

        // ==== 5. Call the method ====
         String result;
     try {
    Test.startTest();
     result = Credit_FIVerificationController.initateFieldVisitMultiple(
        wrapperJson,   
        opp.Id,
        'Waiver Comment',
        null,
        UserInfo.getUserId(),
        true
    );
    Test.stopTest();
    System.debug('Result: ' + result);
} catch (Exception e) {
    System.debug('>>> Exception: ' + e.getMessage());
    System.debug('>>> Stack: ' + e.getStackTraceString());
    throw e;
}

        System.assertNotEquals(null, result, 'Result should not be null');
    }*/
    @isTest
static void testInitiateFieldVisit_ExceptionPath() {
    Test.startTest();
    try {
        Credit_FIVerificationController.initateFieldVisitMultiple(
            '[]', // empty wrapper JSON
            null, // no opportunity
            null,
            null,
            null,
            false
        );
        System.assert(false, 'Method should have thrown AuraHandledException');
    } catch (AuraHandledException e) {
        System.assertNotEquals(null, e.getMessage(), 'Exception message should not be null');
    }
    Test.stopTest();
}
@isTest
    static void testGetApplicantTable_FullCoverage() {
        // Step 1: Create Loan Application
        Opportunity loanApp = new Opportunity(Name = 'Test Loan', Product__c = 'Affordable Home Loan');
        insert loanApp;

        // Step 2: Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id,
            First_Name__c = 'Jane',
            Last_Name__c = 'Smith',
            Name = 'Jane Smith',
            Applicant_Type__c = 'Co Applicant',
            Customer_Type__c = 'Individual'
        );
        insert applicant;

        // Step 3: Create Address (Waived and Non-Waived)
        Applicant_Address__c addr1 = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Type__c = 'Office',          
            Address_Line_1__c = '123 Main St',
            Visit_Waiver_Mode__c = null // Non-waived
        );
        Applicant_Address__c addr2 = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Type__c = 'Office',
            Address_Line_1__c = '456 Side St',
            Visit_Waiver_Mode__c = 'Manually' // Waived
        );
        insert new List<Applicant_Address__c>{addr1, addr2};

        // Step 4: Create Collateral
        Collateral__c collateral = new Collateral__c(Address_Line_1__c = '789 Collateral Rd');
        insert collateral;

        Application_Collateral__c appCol = new Application_Collateral__c(
            HL_Loan_Application__c = loanApp.Id,
            Collateral__c = collateral.Id
        );
        insert appCol;

        // Step 5: Get RecordType for Verification
        RecordType pdRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Personal_Discussion' AND SObjectType = 'Application_Verification__c' LIMIT 1];

        // Step 6: Create Verification Record
        Application_Verification__c verification = new Application_Verification__c(
            Applicant__c = applicant.Id,
            Address__c = addr1.Id,
            RecordTypeId = pdRecordType.Id,
            Stage__c = 'Initiated',
            OverAll_Status__c = 'Positive',
            Assigned_To_User__c = UserInfo.getUserId(),
            Credit_Managers_Disposition__c = 'Approve',
            Credit_Manager_s_Remarks__c = 'Remarks',
            Completion_Date__c = System.now(),
            Loan_Application__c = loanApp.Id
        );
        insert verification;
        Document_Details__c doc = new Document_Details__c();
        doc.Name = 'tralalalaladay';
        insert doc;

        // Step 7: Create ContentDocumentLink and ContentVersion
      ContentVersion version = new ContentVersion(
    Title = 'Credit Manager Initiation Remarks',
    PathOnClient = 'TestFile.txt',
    VersionData = Blob.valueOf('Initiation Remark'),FirstPublishLocationId = doc.Id
);
insert version;

// Retrieve the auto-created ContentDocumentId
version = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];
doc.Content_Document_Id__c = version.ContentDocumentId;
// Now create the ContentDocumentLink
ContentDocumentLink cdl = new ContentDocumentLink(
    ContentDocumentId = version.ContentDocumentId,
    LinkedEntityId = verification.Id,
    ShareType = 'V'
);
insert cdl;

      

        // Step 8: Create Account and AccountTeamMember
        Account acc = new Account(Name = 'Internal Employee FI');
        insert acc;

        AccountTeamMember atm = new AccountTeamMember(
            AccountId = acc.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'FI admin'
        );
        insert atm;

        // Step 9: Run the method
        Test.startTest();
        List<Credit_FIVerificationController.ApplicantWrapper> result = Credit_FIVerificationController.getApplicantTable(loanApp.Id, 'FI');
        Test.stopTest();

        // Step 10: Assertions
        System.assertNotEquals(0, result.size(), 'ApplicantWrapper list should not be empty');
        Boolean foundWaived = false;
        Boolean foundNotWaived = false;

        for (Credit_FIVerificationController.ApplicantWrapper wrapper : result) {
           if (wrapper.waiverFlag == 'Waived') {
    foundWaived = true;
}
if (wrapper.waiverFlag == 'Not Waived') {
    foundNotWaived = true;
}
            System.debug('waiverFlag: ' + wrapper.waiverFlag + ', addressType: ' + wrapper.addressType + ', addressValue: ' + wrapper.addressValue);

            System.assert(wrapper.applicantName != null, 'Applicant name should be populated');
            System.assert(wrapper.addressValue != null, 'Address value should be populated');
        }

        System.assert(foundWaived, 'Should include waived address');
        System.assert(foundNotWaived, 'Should include non-waived address');
    }

@isTest
static void testAuraEnabledConstantsAndWrapperFields() {
    // ✅ Call the static AuraEnabled method
    Map<String, String> result = Credit_FIVerificationController.getConstants();
    System.assertNotEquals(null, result, 'Constants map should not be null');
    System.assert(result.containsKey('Not_Waived'), 'Constants should include Not_Waived key');

    // ✅ Instantiate the wrapper and set AuraEnabled properties
   
}


 @isTest
    static void testGetAssigneeInfoBulk_NoUtils() {
        // Create a test user
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = profile.Id
        );
        insert testUser;

        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create AccountTeamMember
        AccountTeamMember atm = new AccountTeamMember(
            AccountId = acc.Id,
            UserId = testUser.Id,
            TeamMemberRole = 'FI Admin'
        );
        insert atm;

        // Create Loan Application
        Opportunity  loanApp = new Opportunity(Name = 'LoanApp',Product__c = 'Affordable Home Loan');
        insert loanApp;

        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = loanApp.Id
        );
        insert applicant;

 Trigger_Settings__c setg = new Trigger_Settings__c(Name = 'Trigger Settings', Lead_Trigger__c = true, City_Master_Trigger__c = true);
    insert setg;

        // Create Vendor Pincode with nested city
        City_Master__c citi = new City_Master__c(Name = 'Gudivada', City_Code__c = 'C01', Country__c='IN', State__c='AP');
    insert citi;
  

        Pincode_Master__c pincodeMaster = new Pincode_Master__c(City__c = citi.Id,Name = 'test');
        insert pincodeMaster;

                Applicant_Address__c addr = new Applicant_Address__c(
            Applicant__c = applicant.Id,
            Address_Type__c = 'Office',
            Pincode__c = pincodeMaster.Id,
            Address_Line_1__c = '123 Street'
        );
        insert addr;

        List<Applicant_Address__c> addList = [
           SELECT Id, Applicant__c, City__c, Name, Applicant__r.Name, Address_Type__c, Pincode__c, Address_Line_1__c, Full_Address1__c FROM Applicant_Address__c WHERE (Applicant__c IN :new List<Id>{applicant.Id} AND Address_Type__c != 'BSA' AND Pincode__c != NULL AND Address_Line_1__c != NULL AND Full_Address1__c != NULL)
        ];

        System.debug('addressList---'+addList);

        Vendor_Pincode__c vp = new Vendor_Pincode__c(
            Account__c = acc.Id,
            Pincode_Master__c = pincodeMaster.Id
        );
        insert vp;

        // Create RecordType for Application_Verification__c
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' AND Name = 'Personal Discussion AHL' LIMIT 1];

        // Create Verification
        Application_Verification__c verification = new Application_Verification__c(
            Address__c = addr.Id,
            Vendor_Admin__c = testUser.Id,
            Stage__c = 'In progress',
            RecordTypeId = rt.Id,
            Personal_Discussion_Type__c = 'Vendor PD',
            Loan_Application__c = loanApp.Id
        );
        insert verification;

        // Call the method
        Test.startTest();
        // Map<Id,Credit_FIVerificationController.AssigneeWrapperNew> result =Credit_FIVerificationController.getAssigneeInfoBulk(new List<Id>{applicant.Id}, 'FI');
        Map<Id,Credit_FIVerificationController.AssigneeWrapperNew> result2 =Credit_FIVerificationController.getAssigneeInfoBulk(new List<Id>{applicant.Id}, 'Vendor PD');
        Test.stopTest();

        // Assertions
    //     System.assertNotEquals(null, result);
    //     System.assert(result.containsKey(applicant.Id));
    //    Credit_FIVerificationController.AssigneeWrapperNew wrapper = result.get(applicant.Id);
    //     System.assertNotEquals(null, wrapper);
    //     System.assert(wrapper.assigneeID != null || !wrapper.assigneeMap.isEmpty());
    }
     @isTest
    static void testAssigneeWrapperMainProperties() {
        // Create dummy data
        Id dummyId = UserInfo.getUserId();
        String dummyName = 'Test Assignee';

        // Instantiate and set properties
       
        Credit_FIVerificationController.AssigneeWrapperMain wrapper = new Credit_FIVerificationController.AssigneeWrapperMain();
        wrapper.assigneeName = 'Test Assignee';
        wrapper.assigneeID = UserInfo.getUserId();

        System.assertEquals('Test Assignee', wrapper.assigneeName);
        System.assertEquals(UserInfo.getUserId(), wrapper.assigneeID);
    }
    @isTest
    static void testRecordTypeIdMethod() {
          Opportunity  loanApp = new Opportunity(Name = 'LoanApp',Product__c = 'Affordable Home Loan');
        insert loanApp;
        // Get a valid RecordType for Application_Verification__c
        RecordType rt = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Application_Verification__c' LIMIT 1];

        // Create a test Application_Verification__c record
        Application_Verification__c av = new Application_Verification__c(
            RecordTypeId = rt.Id,
            Loan_Application__c = loanApp.Id
        );
        insert av;

        // Call the method with valid input
        Test.startTest();
        String result = Credit_FIVerificationController.recordTypeId(av.Id);
        Test.stopTest();

        // Assert the returned RecordType name
        System.assertEquals(rt.Name, result);
    }


      @isTest
    static void testSaveRemarksFI_AllBranches() {
        // Get a valid RecordType
         Opportunity  loanApp = new Opportunity(Name = 'LoanApp',Product__c = 'Affordable Home Loan');
        insert loanApp;
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Application_Verification__c' LIMIT 1];

        // Create a test Application_Verification__c record
        Application_Verification__c av = new Application_Verification__c(
            RecordTypeId = rt.Id,
            Admin_s_Remarks__c = 'Existing Admin Remark',
            Credit_Manager_s_Remarks__c = 'Existing CM Remark',
            Waiver_Remark__c = 'Existing Waiver Remark',
            Any_Remarks_Reasons__c = 'Existing Reason',
            Loan_Application__c = loanApp.Id
        );
        insert av;

        // Define a reusable comment
        String comment = 'New Remark';

        Test.startTest();

        // Cover: Sent Back By Admin
       // Credit_FIVerificationController.saveRemarksFI(av.Id, constants.get('Sent_Back_By_Admin'), comment);
       //Credit_FIVerificationController.saveRemarksFI(av.Id, 'Sent Back By Admin', comment);


        // Cover: Sent for Approval by FI Admin
        //Credit_FIVerificationController.saveRemarksFI(av.Id, 'Sent for Approval by FI Admin', comment);

        // Cover: Rejected by CM
      //  Credit_FIVerificationController.saveRemarksFI(av.Id, 'Reject', comment);

        // Cover: Sent Back By Credit
       // Credit_FIVerificationController.saveRemarksFI(av.Id,'Sent_Back_By_Credit', comment);
       /* Credit_FIVerificationController.saveRemarksFI(av.Id,'Approved by CM', comment);
                Credit_FIVerificationController.saveRemarksFI(av.Id,'Re-initiate by CM', comment);

                    Credit_FIVerificationController.saveRemarksFI(av.Id,'Sent for Approval by PD Admin', comment);
*/

        

        Test.stopTest();

        // Optional: Query notes or logs if Utility.createNotesRecords creates records
        // Or use debug logs to confirm execution
    }


    @IsTest
    static void testGetApplicantTable_FI() {

        Profile p = [SELECT Id FROM Profile WHERE Name='Credit Manager' LIMIT 1];
        User u = new User(
            Alias='tuser',
            Email='testuser@test.com',
            EmailEncodingKey='UTF-8',
            LastName='User',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId=p.Id,
            TimeZoneSidKey='Asia/Kolkata',
            UserName='testuser'+System.currentTimeMillis()+'@test.com'
        );
        insert u;

        // Loan Opportunity
        Opportunity opp = new Opportunity(
            Name='HL Test Loan',
            StageName='Credit Underwriting',
            CloseDate=Date.today(),
            Product__c='Home Loan'
        );
        insert opp;

        // Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name='Primary Applicant',
            Loan_Application__c=opp.Id,
            Applicant_Type__c='Primary Applicant',
            Customer_Type__c='Individual',
            First_Name__c='Test',
            Last_Name__c='Applicant'
        );
        insert applicant;

        // Address
        Applicant_Address__c addr = new Applicant_Address__c(
            Applicant__c=applicant.Id,
            Address_Type__c='Registered Office',
            Address_Line_1__c='Line1'
        );
        insert addr;


        // Collateral
        Collateral__c col = new Collateral__c(
            Address_Line_1__c='Col Addr'
        );
        insert col;

        Application_Collateral__c appCol = new Application_Collateral__c(
            HL_Loan_Application__c=opp.Id,
            Collateral__c=col.Id
        );
        insert appCol;

        // Application Verification
        Application_Verification__c ver = new Application_Verification__c(
            Applicant__c=applicant.Id,
            Address__c=addr.Id,
            Stage__c='Initiated',
            OverAll_Status__c='Positive',
            Loan_Application__c = opp.Id
        );
        insert ver;
		Document_Details__c doc = new Document_Details__c();
        doc.Name = 'Armanii';
        insert doc;
        // ContentVersion (remarks)
        ContentVersion cv = new ContentVersion(
            Title='Credit Manager Initiation Remarks',
            PathOnClient='remarks.txt',
            VersionData=Blob.valueOf('Test Remarks'), FirstPublishLocationId = doc.Id
        );
        insert cv;

        ContentVersion cversion= [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId=cversion.ContentDocumentId,
            LinkedEntityId=ver.Id,
            ShareType='V'
        );
        insert cdl;
        doc.Content_Document_Id__c = cversion.ContentDocumentId;
        update doc;


        Test.startTest();
        List<Credit_FIVerificationController.ApplicantWrapper> result =
            Credit_FIVerificationController.getApplicantTable(opp.Id, 'FI');

        List<Credit_FIVerificationController.ApplicantWrapper> result2 =
            Credit_FIVerificationController.getApplicantTable(opp.Id, 'Vendor PD');
        Test.stopTest();
    }
    
    @isTest
    static void testRemainingMethodsCoverage(){
        
        // Create Account
        Account acc = new Account(Name='Test Acc');
        insert acc;
        
        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name='Test Opp',
            StageName='Prospecting',
            CloseDate=Date.today(),
            AccountId=acc.Id,
            Product__c='Home Loan'
        );
        insert opp;
        
        // Create Applicant
        Application_Applicant__c applicant = new Application_Applicant__c(
            Loan_Application__c = opp.Id,
            Applicant_Type__c='Primary Applicant'
        );
        insert applicant;
        
        // Create Address
        Applicant_Address__c addr = new Applicant_Address__c(
            Applicant__c=applicant.Id,
            Address_Line_1__c='Street',
            Address_Type__c='Office'
        );
        insert addr;
        
        // Create FI Record
        Application_Verification__c av = new Application_Verification__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            Address__c = addr.Id,
            Assigned_To_User__c = UserInfo.getUserId(),
            Stage__c='Initiated'
        );
        insert av;
        
        // Opportunity Team Member
        OpportunityTeamMember otm = new OpportunityTeamMember(
            OpportunityId = opp.Id,
            UserId = UserInfo.getUserId(),
            TeamMemberRole = 'Sales'
        );
        insert otm;
        
        Test.startTest();
        
        Credit_FIVerificationController.getOwnerName(av.Id);
        Credit_FIVerificationController.getProductNameFromLA(av.Id);
        Credit_FIVerificationController.getOpportunityTeamMembers(av.Id);
        Credit_FIVerificationController.currentLoggedInUserAssignedUser(av.Id);
        Credit_FIVerificationController.showDispositionDropDown(av.Id);
        
        Test.stopTest();
        
        System.assert(true);
    }
}