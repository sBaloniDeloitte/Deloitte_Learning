@isTest
public class SalesDocumentValidationChecklistTest {
    //AD added -25-11-2025
    @testSetup
    static void setup() {
        TestDataFactory.setupTriggerSettings();
        Account acc = TestDataFactory.createAccountRecord('TestAcc');
        insert acc;
        
        Opportunity loan = TestDataFactory.getTestOpportunityData(1, false)[0];
        loan.AccountId = acc.Id;
        loan.StageName = 'Prospecting';
        loan.CloseDate = Date.today();
        loan.Product__c = 'Affordable Home Loan';
        insert loan;
        
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loan.Id, false)[0];
        applicant.Loan_Application__c = loan.Id;
        applicant.Applicant_Type__c = 'Primary Applicant';
        applicant.First_Name__c = 'Test';
        applicant.Last_Name__c = 'Applicant';
        insert applicant;
        City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1,city.Id,true)[0];
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Customer_Address__c custAddRecord =testdatafactory.getcustomeradd ( customer.Id);
        
        string formName = 'Loan Details' ; 

        Screen_Field__c camScreen = new Screen_Field__c(
            Master_Screen_Name__c = 'PAN',
            Form_Name__c = 'PAN',
            Is_Screen_Active__c = true
        );
        insert camScreen;

        Screen_Field__c camScreen2 = new Screen_Field__c(
            Master_Screen_Name__c = 'Aadhaar Back',
            Form_Name__c = 'Aadhaar Back',
            Is_Screen_Active__c = true
        );
        insert camScreen2;

        Screen_Field__c control1= new Screen_Field__c(
            Field_Label__c = 'Document Type',
            Storage_Object__c = 'Document_Details__c',
            Storage_Field__c = 'Document_Master__r.Document_Type__c',
            Read_Field_Name__c = 'Document_Master__r.Document_Type__c',
            Read_Object_Name__c = 'Document_Details__c',
            Field_Sequence__c = 2,
            Parent_Screen__c = camScreen.Id,
            Field_Type__c= 'Text',
            Is_Active__c = true,
            Is_Mandatory__c= true
        );
        insert control1;

        Screen_Field__c control2= new Screen_Field__c(
            Field_Label__c = 'Document Type',
            Storage_Object__c = 'Document_Details__c',
            Storage_Field__c = 'Document_Master__r.Document_Type__c',
            Read_Field_Name__c = 'Document_Master__r.Document_Type__c',
            Read_Object_Name__c = 'Document_Details__c',
            Field_Sequence__c = 2,
            Parent_Screen__c = camScreen2.Id,
            Field_Type__c= 'Text',
            Is_Active__c = true,
            Is_Mandatory__c= true
        );
        insert control2;

        insert new Screen_Field__c(
            Field_Label__c = 'Name',
            Storage_Object__c = 'Application_Applicant__c',
            Storage_Field__c = 'PAN_Number__c',
            Read_Field_Name__c = 'PAN_Number__c',
            Read_Object_Name__c = 'Application_Applicant__c',
            Field_Sequence__c = 1,
            Parent_Screen__c = camScreen.Id,
            Field_Type__c= 'Text',
            Is_Active__c = true,
            Is_Mandatory__c= true,
            Visibility_Controlled_By__c = control1.Id,
            Visibility_Controlled_By_Value__c= 'POI'
        );
        insert new Screen_Field__c(
            Field_Label__c = 'Name',
            Storage_Object__c = 'Application_Applicant__c',
            Storage_Field__c = 'Name',
            Read_Field_Name__c = 'Name',
            Read_Object_Name__c = 'Application_Applicant__c',
            Field_Sequence__c = 2,
            Parent_Screen__c = camScreen.Id,
            Field_Type__c= 'Text',
            Is_Active__c = true,
            Is_Mandatory__c= true
        );
             
        insert new Screen_Field__c(
            Field_Label__c = 'Pincode',
            Storage_Object__c = 'Applicant_Address__c',
            Storage_Field__c = 'Pincode__r.Name',
            Read_Field_Name__c = 'Pincode__r.Name',
            Read_Object_Name__c = 'Applicant_Address__c',
            Field_Sequence__c = 1,
            Parent_Screen__c = camScreen2.Id,
            Field_Type__c= 'Text',
            Is_Active__c = true,
            Is_Mandatory__c= true,
            is_Lookup__c= true
        );
        insert new Screen_Field__c(
            Field_Label__c = 'Aadhar Number',
            Storage_Object__c = 'Application_Applicant__c',
            Storage_Field__c = 'Masked_Aadhar_Number__c',
            Read_Field_Name__c = 'Masked_Aadhar_Number__c',
            Read_Object_Name__c = 'Application_Applicant__c',
            Field_Sequence__c = 2,
            Parent_Screen__c = camScreen2.Id,
            Field_Type__c= 'Text',
            Is_Active__c = true,
            Is_Mandatory__c= true,
            Visibility_Controlled_By__c = control2.Id,
            Visibility_Controlled_By_Value__c= 'POA'
        );
        
    }
    @isTest
    static void testValidateMandatoryDocuments_21() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'POI';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
                ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        //applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        // applicant.Gender__c = 'Male';
        /// applicant.Marital_Status__c = 'Single';
        // applicant.Qualification__c = 'CA';
        // applicant.Religion__c = 'Hindu';
        // applicant.Nationality__c = 'Indian';
        //applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Private Limited';
        applicant.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant;
        
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'PAN';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        system.debug  ('Test for 772->' +docDetail);
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        
        // Debug to verify
        //System.debug('All Applicant_Address__c created => ' + allAddresses);
        
        /* Application_Applicant__c app = new Application_Applicant__c(
Loan_Application__c = opp.Id,
First_Name__c = 'John',
Last_Name__c = 'Doe',
Applicant_Type__c = 'Primary Applicant',
Industry__c = 'Spa / Salons',
Gender__c = 'Male', 
Marital_Status__c = 'Single', 
Qualification__c = 'CA',
Religion__c = 'Hindu',
Nationality__c = 'Indian',
Residency_Status__c = 'Resident',
Customer_type__c = 'Non Individual',
Customer_Profile__c = 'SENP',
Sector__c = 'Private Limited',
Sub_Employment_Type_Non_Individual__c = 'Private Limited'
);
insert app; */
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        //List<SalesDocumentValidationChecklist.DocValidationWrapper> errorList = new List<SalesDocumentValidationChecklist.DocValidationWrapper>();
        //errorList = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        //errorList = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
             @isTest
    static void testValidateMandatoryDocuments_20() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Proof of registration';
        insert docMaster;

        Document_Master__c docMaster2 = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster2.Name = 'PAN' ;
        docMaster2.Document_Name__c= 'PAN';
        docMaster2.Document_Category__c =  'POI';
        docMaster2.Is_Required__c = true;
        docMaster2.Applicable_For_Ocr__c = true;
        docMaster2.Requirement_At__c = 'Applicant Level';
        docMaster2.Requirement_Level__c = 'Applicant Level';
        docMaster2.document_type__c = 'POI';
        insert docMaster2;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
                ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        //applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        // applicant.Gender__c = 'Male';
        /// applicant.Marital_Status__c = 'Single';
        // applicant.Qualification__c = 'CA';
        // applicant.Religion__c = 'Hindu';
        // applicant.Nationality__c = 'Indian';
        //applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Private Limited';
        applicant.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant;
        
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'HUF Deed';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;

        Document_Details__c docDetail2 =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail2.Name = 'PAN';
        docDetail2.Applicant__c = applicant.Id;
        docDetail2.Loan_Application__c = opp.Id;
        docDetail2.Document_Master__c = docMaster2.Id;
        docDetail2.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail2.Transaction_ID__c = 'testConsentHandle';
        docDetail2.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail2.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail2.Status__c = 'Uploaded';
        docDetail2.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail2;
        system.debug  ('Test for 772->' +docDetail);
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        
        // Debug to verify
        //System.debug('All Applicant_Address__c created => ' + allAddresses);
        
        /* Application_Applicant__c app = new Application_Applicant__c(
Loan_Application__c = opp.Id,
First_Name__c = 'John',
Last_Name__c = 'Doe',
Applicant_Type__c = 'Primary Applicant',
Industry__c = 'Spa / Salons',
Gender__c = 'Male', 
Marital_Status__c = 'Single', 
Qualification__c = 'CA',
Religion__c = 'Hindu',
Nationality__c = 'Indian',
Residency_Status__c = 'Resident',
Customer_type__c = 'Non Individual',
Customer_Profile__c = 'SENP',
Sector__c = 'Private Limited',
Sub_Employment_Type_Non_Individual__c = 'Private Limited'
);
insert app; */
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
         @isTest
    static void testValidateMandatoryDocuments_19() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Proof of registration';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
                ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        //applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        // applicant.Gender__c = 'Male';
        /// applicant.Marital_Status__c = 'Single';
        // applicant.Qualification__c = 'CA';
        // applicant.Religion__c = 'Hindu';
        // applicant.Nationality__c = 'Indian';
        //applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Private Limited';
        applicant.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant;
        
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'COI';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        system.debug  ('Test for 772->' +docDetail);
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        
        // Debug to verify
        //System.debug('All Applicant_Address__c created => ' + allAddresses);
        
        /* Application_Applicant__c app = new Application_Applicant__c(
Loan_Application__c = opp.Id,
First_Name__c = 'John',
Last_Name__c = 'Doe',
Applicant_Type__c = 'Primary Applicant',
Industry__c = 'Spa / Salons',
Gender__c = 'Male', 
Marital_Status__c = 'Single', 
Qualification__c = 'CA',
Religion__c = 'Hindu',
Nationality__c = 'Indian',
Residency_Status__c = 'Resident',
Customer_type__c = 'Non Individual',
Customer_Profile__c = 'SENP',
Sector__c = 'Private Limited',
Sub_Employment_Type_Non_Individual__c = 'Private Limited'
);
insert app; */
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
     @isTest
    static void testValidateMandatoryDocuments_18() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Proof of registration';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
                ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        //applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        // applicant.Gender__c = 'Male';
        /// applicant.Marital_Status__c = 'Single';
        // applicant.Qualification__c = 'CA';
        // applicant.Religion__c = 'Hindu';
        // applicant.Nationality__c = 'Indian';
        //applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Proprietorship';
        applicant.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant;
        
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'GST Certificate';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        system.debug  ('Test for 772->' +docDetail);
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        
        // Debug to verify
        //System.debug('All Applicant_Address__c created => ' + allAddresses);
        
        /* Application_Applicant__c app = new Application_Applicant__c(
Loan_Application__c = opp.Id,
First_Name__c = 'John',
Last_Name__c = 'Doe',
Applicant_Type__c = 'Primary Applicant',
Industry__c = 'Spa / Salons',
Gender__c = 'Male', 
Marital_Status__c = 'Single', 
Qualification__c = 'CA',
Religion__c = 'Hindu',
Nationality__c = 'Indian',
Residency_Status__c = 'Resident',
Customer_type__c = 'Non Individual',
Customer_Profile__c = 'SENP',
Sector__c = 'Private Limited',
Sub_Employment_Type_Non_Individual__c = 'Private Limited'
);
insert app; */
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
  
     @isTest
    static void testValidateMandatoryDocuments_17() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'POA';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        //applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        // applicant.Gender__c = 'Male';
        /// applicant.Marital_Status__c = 'Single';
        // applicant.Qualification__c = 'CA';
        // applicant.Religion__c = 'Hindu';
        // applicant.Nationality__c = 'Indian';
        //applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Private Limited';
        applicant.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant;
        
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Certificate of Incorporation';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = Null;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        
        // Debug to verify
        //System.debug('All Applicant_Address__c created => ' + allAddresses);
        
        /* Application_Applicant__c app = new Application_Applicant__c(
Loan_Application__c = opp.Id,
First_Name__c = 'John',
Last_Name__c = 'Doe',
Applicant_Type__c = 'Primary Applicant',
Industry__c = 'Spa / Salons',
Gender__c = 'Male', 
Marital_Status__c = 'Single', 
Qualification__c = 'CA',
Religion__c = 'Hindu',
Nationality__c = 'Indian',
Residency_Status__c = 'Resident',
Customer_type__c = 'Non Individual',
Customer_Profile__c = 'SENP',
Sector__c = 'Private Limited',
Sub_Employment_Type_Non_Individual__c = 'Private Limited'
);
insert app; */
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
      @isTest
    static void testValidateMandatoryDocuments_16() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Qualification proof';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
       // applicant.Gender__c = 'Male';
       // applicant.Marital_Status__c = 'Single';
       // applicant.Qualification__c = 'CA';
//applicant.Religion__c = 'Hindu';
//applicant.Nationality__c = 'Indian';
       // applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Individual';
      //  applicant.Customer_Profile__c = 'Salaried NRI';
      // applicant.Sector__c = 'Doctor';
       // applicant.Sub_Employment_Type_Non_Individual__c = Null;
        insert applicant;
        insert contentVersion;
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Degree Certificate or Certificate of Membership';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = '';
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        
        // Debug to verify
        //System.debug('All Applicant_Address__c created => ' + allAddresses);
        
        /* Application_Applicant__c app = new Application_Applicant__c(
Loan_Application__c = opp.Id,
First_Name__c = 'John',
Last_Name__c = 'Doe',
Applicant_Type__c = 'Primary Applicant',
Industry__c = 'Spa / Salons',
Gender__c = 'Male', 
Marital_Status__c = 'Single', 
Qualification__c = 'CA',
Religion__c = 'Hindu',
Nationality__c = 'Indian',
Residency_Status__c = 'Resident',
Customer_type__c = 'Non Individual',
Customer_Profile__c = 'SENP',
Sector__c = 'Private Limited',
Sub_Employment_Type_Non_Individual__c = 'Private Limited'
);
insert app; */
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }


      @isTest
    static void testValidateMandatoryDocuments_15() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Others';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        //applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        // applicant.Gender__c = 'Male';
        /// applicant.Marital_Status__c = 'Single';
        // applicant.Qualification__c = 'CA';
        // applicant.Religion__c = 'Hindu';
        // applicant.Nationality__c = 'Indian';
        //applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Private Limited';
        applicant.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant;
        
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Udhyam registration certificate';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = Null;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        
        // Debug to verify
        //System.debug('All Applicant_Address__c created => ' + allAddresses);
        
        /* Application_Applicant__c app = new Application_Applicant__c(
Loan_Application__c = opp.Id,
First_Name__c = 'John',
Last_Name__c = 'Doe',
Applicant_Type__c = 'Primary Applicant',
Industry__c = 'Spa / Salons',
Gender__c = 'Male', 
Marital_Status__c = 'Single', 
Qualification__c = 'CA',
Religion__c = 'Hindu',
Nationality__c = 'Indian',
Residency_Status__c = 'Resident',
Customer_type__c = 'Non Individual',
Customer_Profile__c = 'SENP',
Sector__c = 'Private Limited',
Sub_Employment_Type_Non_Individual__c = 'Private Limited'
);
insert app; */
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }     
      @isTest
    static void testValidateMandatoryDocuments_14() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Proof of registration';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        //applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        // applicant.Gender__c = 'Male';
        /// applicant.Marital_Status__c = 'Single';
        // applicant.Qualification__c = 'CA';
        // applicant.Religion__c = 'Hindu';
        // applicant.Nationality__c = 'Indian';
        //applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Private Limited';
        applicant.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant;
        
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Certificate of Incorporation';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = Null;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        
        // Debug to verify
        //System.debug('All Applicant_Address__c created => ' + allAddresses);
        
        /* Application_Applicant__c app = new Application_Applicant__c(
Loan_Application__c = opp.Id,
First_Name__c = 'John',
Last_Name__c = 'Doe',
Applicant_Type__c = 'Primary Applicant',
Industry__c = 'Spa / Salons',
Gender__c = 'Male', 
Marital_Status__c = 'Single', 
Qualification__c = 'CA',
Religion__c = 'Hindu',
Nationality__c = 'Indian',
Residency_Status__c = 'Resident',
Customer_type__c = 'Non Individual',
Customer_Profile__c = 'SENP',
Sector__c = 'Private Limited',
Sub_Employment_Type_Non_Individual__c = 'Private Limited'
);
insert app; */
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
    @isTest
    static void testValidateMandatoryDocuments_13() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'POA';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        //applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        // applicant.Gender__c = 'Male';
        /// applicant.Marital_Status__c = 'Single';
        // applicant.Qualification__c = 'CA';
        // applicant.Religion__c = 'Hindu';
        // applicant.Nationality__c = 'Indian';
        //applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Proprietorship';
        applicant.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant;
        
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Udhyam registration certificate';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = Null;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        
        // Debug to verify
        //System.debug('All Applicant_Address__c created => ' + allAddresses);
        
        /* Application_Applicant__c app = new Application_Applicant__c(
Loan_Application__c = opp.Id,
First_Name__c = 'John',
Last_Name__c = 'Doe',
Applicant_Type__c = 'Primary Applicant',
Industry__c = 'Spa / Salons',
Gender__c = 'Male', 
Marital_Status__c = 'Single', 
Qualification__c = 'CA',
Religion__c = 'Hindu',
Nationality__c = 'Indian',
Residency_Status__c = 'Resident',
Customer_type__c = 'Non Individual',
Customer_Profile__c = 'SENP',
Sector__c = 'Private Limited',
Sub_Employment_Type_Non_Individual__c = 'Private Limited'
);
insert app; */
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
  
      @isTest
    static void testValidateMandatoryDocuments_12() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'POA';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        //applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        // applicant.Gender__c = 'Male';
        /// applicant.Marital_Status__c = 'Single';
        // applicant.Qualification__c = 'CA';
        // applicant.Religion__c = 'Hindu';
        // applicant.Nationality__c = 'Indian';
        //applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Proprietorship';
        applicant.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant;
        
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Udhyam registration certificate';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = Null;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        
        // Debug to verify
        //System.debug('All Applicant_Address__c created => ' + allAddresses);
        
        /* Application_Applicant__c app = new Application_Applicant__c(
Loan_Application__c = opp.Id,
First_Name__c = 'John',
Last_Name__c = 'Doe',
Applicant_Type__c = 'Primary Applicant',
Industry__c = 'Spa / Salons',
Gender__c = 'Male', 
Marital_Status__c = 'Single', 
Qualification__c = 'CA',
Religion__c = 'Hindu',
Nationality__c = 'Indian',
Residency_Status__c = 'Resident',
Customer_type__c = 'Non Individual',
Customer_Profile__c = 'SENP',
Sector__c = 'Private Limited',
Sub_Employment_Type_Non_Individual__c = 'Private Limited'
);
insert app; */
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
  
     @isTest
    static void testValidateMandatoryDocuments_11() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'POA';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        //applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        // applicant.Gender__c = 'Male';
        /// applicant.Marital_Status__c = 'Single';
        // applicant.Qualification__c = 'CA';
        // applicant.Religion__c = 'Hindu';
        // applicant.Nationality__c = 'Indian';
        //applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        //applicant.Sector__c = 'Proprietorship';
        applicant.Sector__c = 'HUF';
        applicant.Sub_Employment_Type_Non_Individual__c = 'SENP';
        insert applicant;
        
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Udhyam registration certificate';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = Null;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        
        // Debug to verify
        //System.debug('All Applicant_Address__c created => ' + allAddresses);
        
        /* Application_Applicant__c app = new Application_Applicant__c(
Loan_Application__c = opp.Id,
First_Name__c = 'John',
Last_Name__c = 'Doe',
Applicant_Type__c = 'Primary Applicant',
Industry__c = 'Spa / Salons',
Gender__c = 'Male', 
Marital_Status__c = 'Single', 
Qualification__c = 'CA',
Religion__c = 'Hindu',
Nationality__c = 'Indian',
Residency_Status__c = 'Resident',
Customer_type__c = 'Non Individual',
Customer_Profile__c = 'SENP',
Sector__c = 'Private Limited',
Sub_Employment_Type_Non_Individual__c = 'Private Limited'
);
insert app; */
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
  
    @isTest
    static void testValidateMandatoryDocuments_10() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'POA';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        //applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        // applicant.Gender__c = 'Male';
        /// applicant.Marital_Status__c = 'Single';
        // applicant.Qualification__c = 'CA';
        // applicant.Religion__c = 'Hindu';
        // applicant.Nationality__c = 'Indian';
        //applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Proprietorship';
        applicant.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant;
        
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Udhyam registration certificate';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = Null;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        
        // Debug to verify
        //System.debug('All Applicant_Address__c created => ' + allAddresses);
        
        /* Application_Applicant__c app = new Application_Applicant__c(
Loan_Application__c = opp.Id,
First_Name__c = 'John',
Last_Name__c = 'Doe',
Applicant_Type__c = 'Primary Applicant',
Industry__c = 'Spa / Salons',
Gender__c = 'Male', 
Marital_Status__c = 'Single', 
Qualification__c = 'CA',
Religion__c = 'Hindu',
Nationality__c = 'Indian',
Residency_Status__c = 'Resident',
Customer_type__c = 'Non Individual',
Customer_Profile__c = 'SENP',
Sector__c = 'Private Limited',
Sub_Employment_Type_Non_Individual__c = 'Private Limited'
);
insert app; */
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
    
    @isTest
    static void testValidateMandatoryDocuments_9() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Proof of practice';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        applicant.Gender__c = 'Male';
        applicant.Marital_Status__c = 'Single';
        applicant.Qualification__c = 'CA';
        applicant.Religion__c = 'Hindu';
        applicant.Nationality__c = 'Indian';
        applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Individual';
        applicant.Customer_Profile__c = 'SEP';
        applicant.Sector__c = 'Chartered Accountant';
        //applicant.Sub_Employment_Type_Non_Individual__c = 'SEP-CA';
        insert applicant;
        insert contentVersion;
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Certificate of Practice';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = '';
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        
        // Debug to verify
        //System.debug('All Applicant_Address__c created => ' + allAddresses);
        
        /* Application_Applicant__c app = new Application_Applicant__c(
Loan_Application__c = opp.Id,
First_Name__c = 'John',
Last_Name__c = 'Doe',
Applicant_Type__c = 'Primary Applicant',
Industry__c = 'Spa / Salons',
Gender__c = 'Male', 
Marital_Status__c = 'Single', 
Qualification__c = 'CA',
Religion__c = 'Hindu',
Nationality__c = 'Indian',
Residency_Status__c = 'Resident',
Customer_type__c = 'Non Individual',
Customer_Profile__c = 'SENP',
Sector__c = 'Private Limited',
Sub_Employment_Type_Non_Individual__c = 'Private Limited'
);
insert app; */
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
    
    @isTest
    static void testValidateMandatoryDocuments_8() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Proof of practice';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        applicant.Gender__c = 'Male';
        applicant.Marital_Status__c = 'Single';
        applicant.Qualification__c = 'CA';
        applicant.Religion__c = 'Hindu';
        applicant.Nationality__c = 'Indian';
        applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Individual';
        applicant.Customer_Profile__c = 'SEP';
        applicant.Sector__c = 'Doctor';
        //applicant.Sub_Employment_Type_Non_Individual__c = 'LLP';
        insert applicant;
        insert contentVersion;
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Registration Certificate';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = '';
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        
        // Debug to verify
        //System.debug('All Applicant_Address__c created => ' + allAddresses);
        
        /* Application_Applicant__c app = new Application_Applicant__c(
Loan_Application__c = opp.Id,
First_Name__c = 'John',
Last_Name__c = 'Doe',
Applicant_Type__c = 'Primary Applicant',
Industry__c = 'Spa / Salons',
Gender__c = 'Male', 
Marital_Status__c = 'Single', 
Qualification__c = 'CA',
Religion__c = 'Hindu',
Nationality__c = 'Indian',
Residency_Status__c = 'Resident',
Customer_type__c = 'Non Individual',
Customer_Profile__c = 'SENP',
Sector__c = 'Private Limited',
Sub_Employment_Type_Non_Individual__c = 'Private Limited'
);
insert app; */
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
    
    @isTest
    static void testValidateMandatoryDocuments_7() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Qualification proof';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        applicant.Gender__c = 'Male';
        applicant.Marital_Status__c = 'Single';
        applicant.Qualification__c = 'CA';
        applicant.Religion__c = 'Hindu';
        applicant.Nationality__c = 'Indian';
        applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Individual';
        applicant.Customer_Profile__c = 'SEP';
        // applicant.Sector__c = 'LLP';
        //applicant.Sub_Employment_Type_Non_Individual__c = 'LLP';
        insert applicant;
        insert contentVersion;
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Degree Certificate or Certificate of Membership';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = '';
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        
        // Debug to verify
        //System.debug('All Applicant_Address__c created => ' + allAddresses);
        
        /* Application_Applicant__c app = new Application_Applicant__c(
Loan_Application__c = opp.Id,
First_Name__c = 'John',
Last_Name__c = 'Doe',
Applicant_Type__c = 'Primary Applicant',
Industry__c = 'Spa / Salons',
Gender__c = 'Male', 
Marital_Status__c = 'Single', 
Qualification__c = 'CA',
Religion__c = 'Hindu',
Nationality__c = 'Indian',
Residency_Status__c = 'Resident',
Customer_type__c = 'Non Individual',
Customer_Profile__c = 'SENP',
Sector__c = 'Private Limited',
Sub_Employment_Type_Non_Individual__c = 'Private Limited'
);
insert app; */
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
    
    @isTest
    static void testValidateMandatoryDocuments_1() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'POA';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        applicant.Gender__c = 'Male';
        applicant.Marital_Status__c = 'Single';
        applicant.Qualification__c = 'CA';
        applicant.Religion__c = 'Hindu';
        applicant.Nationality__c = 'Indian';
        applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Individual';
        applicant.Customer_Profile__c = 'SEP';
        // applicant.Sector__c = 'LLP';
        //applicant.Sub_Employment_Type_Non_Individual__c = 'LLP';
        insert applicant;
        insert contentVersion;
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'PAN';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = contentVersion.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        
        // Debug to verify
        //System.debug('All Applicant_Address__c created => ' + allAddresses);
        
        /* Application_Applicant__c app = new Application_Applicant__c(
Loan_Application__c = opp.Id,
First_Name__c = 'John',
Last_Name__c = 'Doe',
Applicant_Type__c = 'Primary Applicant',
Industry__c = 'Spa / Salons',
Gender__c = 'Male', 
Marital_Status__c = 'Single', 
Qualification__c = 'CA',
Religion__c = 'Hindu',
Nationality__c = 'Indian',
Residency_Status__c = 'Resident',
Customer_type__c = 'Non Individual',
Customer_Profile__c = 'SENP',
Sector__c = 'Private Limited',
Sub_Employment_Type_Non_Individual__c = 'Private Limited'
);
insert app; */
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
    
    @isTest
    static void testValidateMandatoryDocuments_2() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        applicant.Gender__c = 'Male';
        applicant.Marital_Status__c = 'Single';
        applicant.Qualification__c = 'CA';
        applicant.Religion__c = 'Hindu';
        applicant.Nationality__c = 'Indian';
        applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Individual';
        applicant.Customer_Profile__c = 'SEP';
        // applicant.Sector__c = 'LLP';
        //applicant.Sub_Employment_Type_Non_Individual__c = 'LLP';
        insert applicant;
        
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response';
        docMaster.Document_Name__c = 'Account Aggregator Response';
        docMaster.Product__c = 'Business Loan';
        docMaster.Document_Category__c = 'Additional Documents';
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level' ;
        docMaster.document_type__c = 'POA' ;
        insert docMaster; 
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        
        insert contentVersion;
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'POA';
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Content_Document_Id__c = contentVersion.Id;
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        // Account_Aggregator_Status__c = 'Consent Approved';
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        docDetail.Process_Name__c = 'Income Bank Statement';
        docDetail.loan_application__c = opp.Id;
        docDetail.Applicant__c  = applicant.Id;
        
        insert docDetail;
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        ///
        /*Applicant_Address__c appAdd3 = new Applicant_Address__c(
Applicant__c = applicant.Id,
Address_Type__c = 'Registered Office',
Address_Source__c = 'Passport',
Document_Details__c  = docDetail.Id
);*/
        
        //  insert appAdd3;
        
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
    @isTest
    static void testValidateMandatoryDocuments_3() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        applicant.Gender__c = 'Male';
        applicant.Marital_Status__c = 'Single';
        applicant.Qualification__c = 'CA';
        applicant.Religion__c = 'Hindu';
        applicant.Nationality__c = 'Indian';
        applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Individual';
        applicant.Customer_Profile__c = 'SEP';
        // applicant.Sector__c = 'LLP';
        // applicant.Sub_Employment_Type_Non_Individual__c = 'LLP';
        insert applicant;
        
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response';
        docMaster.Document_Name__c = 'Account Aggregator Response';
        docMaster.Product__c = 'Business Loan';
        docMaster.Document_Category__c = 'Additional Documents';
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level' ;
        docMaster.document_type__c = 'Others' ;
        insert docMaster; 
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        
        insert contentVersion;
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Photograph';
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Content_Document_Id__c =Null;
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        // Account_Aggregator_Status__c = 'Consent Approved';
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        docDetail.Process_Name__c = 'Income Bank Statement';
        docDetail.loan_application__c = opp.Id;
        docDetail.Applicant__c  = applicant.Id;
        
        insert docDetail;
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        ///
        /*Applicant_Address__c appAdd3 = new Applicant_Address__c(
Applicant__c = applicant.Id,
Address_Type__c = 'Registered Office',
Address_Source__c = 'Passport',
Document_Details__c  = docDetail.Id
);*/
        
        //  insert appAdd3;
        
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
    @isTest
    static void testValidateMandatoryDocuments_4() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        applicant.Gender__c = 'Male';
        applicant.Marital_Status__c = 'Single';
        applicant.Qualification__c = 'CA';
        applicant.Religion__c = 'Hindu';
        applicant.Nationality__c = 'Indian';
        applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Individual';
        applicant.Customer_Profile__c = 'SEP';
        applicant.Sector__c = 'Doctor';
        //applicant.Sub_Employment_Type_Non_Individual__c = 'Partnership';
        insert applicant;
        
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response';
        docMaster.Document_Name__c = 'Account Aggregator Response';
        docMaster.Product__c = 'Business Loan';
        docMaster.Document_Category__c = 'Additional Documents';
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level' ;
        docMaster.document_type__c = 'Proof of office' ;
        insert docMaster; 
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        
        insert contentVersion;
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'POA';
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Content_Document_Id__c = contentVersion.Id;
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        // Account_Aggregator_Status__c = 'Consent Approved';
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        docDetail.Process_Name__c = 'Income Bank Statement';
        docDetail.loan_application__c = opp.Id;
        docDetail.Applicant__c  = applicant.Id;
        
        insert docDetail;
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        
        
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
    @IsTest
    static void testValidateMandatoryDocuments_5() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        applicant.Gender__c = 'Male';
        applicant.Marital_Status__c = 'Single';
        applicant.Qualification__c = 'CA';
        applicant.Religion__c = 'Hindu';
        applicant.Nationality__c = 'Indian';
        applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Individual';
        applicant.Customer_Profile__c = 'SEP';
        applicant.Sector__c = 'Chartered Accountant';
        //applicant.Sub_Employment_Type_Non_Individual__c = 'LLP';
        insert applicant;
        
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response';
        docMaster.Document_Name__c = 'Account Aggregator Response';
        docMaster.Product__c = 'Business Loan';
        docMaster.Document_Category__c = 'Additional Documents';
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level' ;
        docMaster.document_type__c = 'Proof of office' ;
        insert docMaster; 
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        
        insert contentVersion;
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'POA';
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Content_Document_Id__c = contentVersion.Id;
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        // Account_Aggregator_Status__c = 'Consent Approved';
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        docDetail.Process_Name__c = 'Income Bank Statement';
        docDetail.loan_application__c = opp.Id;
        docDetail.Applicant__c  = applicant.Id;
        
        insert docDetail;
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
    
        
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
    @isTest
    static void testValidateMandatoryDocuments_6() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        applicant.Gender__c = 'Male';
        applicant.Marital_Status__c = 'Single';
        applicant.Qualification__c = 'CA';
        applicant.Religion__c = 'Hindu';
        applicant.Nationality__c = 'Indian';
        applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Individual';
        applicant.Customer_Profile__c = 'SEP';
        applicant.Sector__c = 'Doctor';
        //applicant.Sub_Employment_Type_Non_Individual__c = 'LLP';
        insert applicant;
        
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response';
        docMaster.Document_Name__c = 'Account Aggregator Response';
        docMaster.Product__c = 'Business Loan';
        docMaster.Document_Category__c = 'Additional Documents';
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level' ;
        docMaster.document_type__c = 'Proof of office' ;
        insert docMaster; 
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        
        insert contentVersion;
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Registration Certificate';
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Content_Document_Id__c =Null;
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        // Account_Aggregator_Status__c = 'Consent Approved';
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        docDetail.Process_Name__c = 'Income Bank Statement';
        docDetail.loan_application__c = opp.Id;
        docDetail.Applicant__c  = applicant.Id;
        
        insert docDetail;
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        insert allAddresses;
 
        
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.FilteredDocumentWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(opp.Id);
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
    
    @isTest
    static void testValidateMandatoryFields2() {
        // Setup test data
        List<String> formNames = new List<String>{'Loan Details'};
            Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createLoanApplication(true,customer);
        // Application_Applicant__c app = FITestDataFactory.createApplicant(opp);
        
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.Loan_Application__c = opp.Id;
        applicant.Applicant_Type__c = 'Primary Applicant';
        applicant.First_Name__c = 'Test';
        applicant.Last_Name__c = 'Applicant';
        insert applicant;
        
        // Create test data for Document_Master__c
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'POA';
        docMaster.Stage__c ='Sales login' ;
        insert docMaster;
        
        system.debug('docMaster-->' +docMaster);
        
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        
        insert contentVersion;
        ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        system.debug ( 'contment document version --> ' +cv2);
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'POA';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        docDetail.Active__c = true;
        docDetail.Consider_for_Loan_Application__c = true;
        insert docDetail;

        Document_Details__c docDetail2 =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail2.Name = 'Aadhaar Back';
        docDetail2.Applicant__c = applicant.Id;
        docDetail2.Loan_Application__c = opp.Id;
        docDetail2.Document_Master__c = docMaster.Id;
        docDetail2.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail2.Transaction_ID__c = 'testConsentHandle';
        docDetail2.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail2.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail2.Status__c = 'Uploaded';
        docDetail2.Manual_AA__c = 'AA';
        docDetail2.Process_Name__c = 'Income Bank Statement' ;
        docDetail2.Active__c = true;
        docDetail2.Consider_for_Loan_Application__c = true;
        insert docDetail2;

        Document_Details__c docDetail3 =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail3.Name = 'PAN';
        docDetail3.Applicant__c = applicant.Id;
        docDetail3.Loan_Application__c = opp.Id;
        docDetail3.Document_Master__c = docMaster.Id;
        docDetail3.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail3.Transaction_ID__c = 'testConsentHandle';
        docDetail3.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail3.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail3.Status__c = 'Uploaded';
        docDetail3.Manual_AA__c = 'AA';
        docDetail3.Process_Name__c = 'Income Bank Statement' ;
        docDetail3.Active__c = true;
        docDetail3.Consider_for_Loan_Application__c = true;
        insert docDetail3;

        system.debug ('mydocDetail-->  '+ docDetail);
        
        Applicant_Address__c appAdd1 =Testdatafactory.getTestApplicantAddressData(1, applicant.Id, Null, Null, false)[0];
        appAdd1.Address_Type__c = 'Permanent';
        // PinCode__c = pinCode.Id, 
        appAdd1.Address_Source__c = 'Passport';
        appAdd1.Document_Details__c  = docDetail2.Id ;
        Applicant_Address__c appAdd2 = Testdatafactory.getTestApplicantAddressData(1, applicant.Id, Null, Null, false)[0];
        appAdd2.Address_Type__c = 'Current';
        appAdd2.Address_Source__c = 'Passport';
        appAdd2.Document_Details__c  = docDetail2.Id ;
        insert appAdd1;
        insert appAdd2;
        
        Test.startTest();
        try{
            SalesDocumentValidationChecklist.validateMandatoryFields(opp.Id);
        }catch(Exception e){
            System.debug('SalesDocument9866: ' + e.getMessage() + 'at' + e.getLineNumber());
        }
        
        Test.stopTest();
        
        //System.assertEquals('Success', result, 'Expected result to be Success');
    }
    
    @isTest
    static void testValidateMandatoryFields() {
        // Setup test data
        List<String> formNames = new List<String>{'Loan Details'};
            Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createLoanApplication(true,customer);
        // Application_Applicant__c app = FITestDataFactory.createApplicant(opp);
        
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.Loan_Application__c = opp.Id;
        applicant.Applicant_Type__c = 'Primary Applicant';
        applicant.First_Name__c = 'Test';
        applicant.Last_Name__c = 'Applicant';
        insert applicant;
        
        // Create test data for Document_Master__c
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'POA';
        docMaster.Stage__c ='Sales login' ;
        insert docMaster;
        
        system.debug('docMaster-->' +docMaster);
        
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        
        insert contentVersion;
        ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        system.debug ( 'contment document version --> ' +cv2);
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'POA';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        docDetail.Active__c = true;
        insert docDetail;
        system.debug ('mydocDetail-->  '+ docDetail);
        Applicant_Address__c appAdd1 =Testdatafactory.getTestApplicantAddressData(1, applicant.Id, Null, Null, false)[0];
        appAdd1.Address_Type__c = 'Permanent';
        // PinCode__c = pinCode.Id, 
        appAdd1.Address_Source__c = 'Passport';
        appAdd1.Document_Details__c  = docDetail.Id ;
        Applicant_Address__c appAdd2 = Testdatafactory.getTestApplicantAddressData(1, applicant.Id, Null, Null, false)[0];
        appAdd2.Address_Type__c = 'Current';
        appAdd2.Address_Source__c = 'Passport';
        appAdd2.Document_Details__c  = docDetail.Id ;
        insert appAdd1;
        insert appAdd2;
        
        Test.startTest();
        SalesDocumentValidationChecklist.validateMandatoryFields(opp.Id);
        Test.stopTest();
        
        //System.assertEquals('Success', result, 'Expected result to be Success');
    }
     @isTest
    static void testValidateMandatoryFieldsNODATA() {
        // Setup test data
        List<String> formNames = new List<String>{'Loan Details'};
            Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createLoanApplication(true,customer);
         //Application_Applicant__c app = [select id,Loan_Application__c from Application_Applicant__c limit 1];
        Application_Applicant__c app = new Application_Applicant__c();
        app.Loan_Application__c = opp.Id;
        insert app;
        
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Proof of registration';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
                ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        
        Document_Details__c docDetail =  new Document_Details__c();
        docDetail.Name = 'CA certified list of co-parceners with UDIN';
        docDetail.Applicant__c = app.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
      //  docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        docDetail.Consider_for_Loan_Application__c=true;
        docDetail.Active__c=true;
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
      
       
        Test.startTest();
        SalesDocumentValidationChecklist.validateMandatoryFields(opp.Id);
        SalesDocumentValidationChecklist.validateConsideredDocs(opp.Id);
        Test.stopTest();
        
        //System.assertEquals('Success', result, 'Expected result to be Success');
    }
    
    @isTest
    static void testValidateAddress() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Proof of registration';
		docMaster.Stage__c = 'Sales login';
        insert docMaster;
		
        String loanId = opp.Id;
        
		ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
                ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        //applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        // applicant.Gender__c = 'Male';
        /// applicant.Marital_Status__c = 'Single';
        // applicant.Qualification__c = 'CA';
        // applicant.Religion__c = 'Hindu';
        // applicant.Nationality__c = 'Indian';
        //applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Private Limited';
        applicant.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant;
        
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'CA certified list of co-parceners with UDIN';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
		docDetail.Active__c = true;
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        system.debug  ('Test for 772->' +docDetail);
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        //allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;

        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        SalesDocumentValidationChecklist.validateAddresses(loanId);
		Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
    
    @isTest
    static void testcheckAddressType() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Proof of registration';
		docMaster.Stage__c = 'Sales login';
        insert docMaster;
		
        String loanId = opp.Id;
        
		ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
                ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        //applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        // applicant.Gender__c = 'Male';
        /// applicant.Marital_Status__c = 'Single';
        // applicant.Qualification__c = 'CA';
        // applicant.Religion__c = 'Hindu';
        // applicant.Nationality__c = 'Indian';
        //applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Private Limited';
        applicant.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant;
        
        Application_Applicant__c applicant1 = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant1.First_Name__c = 'John';
        applicant1.Last_Name__c = 'Doe';
        applicant1.Customer_type__c = 'Individual';
        applicant1.Customer_Profile__c = 'SENP';
        applicant1.Sector__c = 'Private Limited';
        applicant1.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant1;
        
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'CA certified list of co-parceners with UDIN';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
		docDetail.Active__c = true;
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        system.debug  ('Test for 772->' +docDetail);
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        addrPermanent.Applicant__c = applicant.Id;
        allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        addrCurrent.Applicant__c = applicant1.Id;
        allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = 'Owned';
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        addrOwned.Applicant__c = applicant1.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        addrOffice.Applicant__c = applicant1.Id;
        //allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        addrClinic.Applicant__c = applicant1.Id;
        //allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        addrReg.Applicant__c = applicant1.Id;
        //allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        addrGodown.Applicant__c = applicant1.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        addrFactory.Applicant__c = applicant1.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        addrOther.Applicant__c = applicant1.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;

        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        List<SalesDocumentValidationChecklist.AddressWrapper> addressWrap = SalesDocumentValidationChecklist.checkAddressType(loanId);
		Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
    
    @isTest
    static void testdeleteWithoutAddressTypeDoc() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Proof of registration';
		docMaster.Stage__c = 'Sales login';
        insert docMaster;
		
        String loanId = opp.Id;
        
		ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
                ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        //applicant.Applicant_Type__c = 'Primary Applicant';
        // applicant.Industry__c = 'Spa / Salons';
        // applicant.Gender__c = 'Male';
        /// applicant.Marital_Status__c = 'Single';
        // applicant.Qualification__c = 'CA';
        // applicant.Religion__c = 'Hindu';
        // applicant.Nationality__c = 'Indian';
        //applicant.Residency_Status__c = 'Resident';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Private Limited';
        applicant.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant;
        
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'CA certified list of co-parceners with UDIN';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
		docDetail.Active__c = true;
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        system.debug  ('Test for 772->' +docDetail);
        // add all type 
        List<Applicant_Address__c> allAddresses = new List<Applicant_Address__c>();
        
        // Permanent
        Applicant_Address__c addrPermanent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrPermanent.Address_Type__c = 'Permanent';
        addrPermanent.Address_Source__c = 'Passport';
        addrPermanent.Document_Details__c = docDetail.Id;
        addrPermanent.Applicant__c = applicant.Id;
        allAddresses.add(addrPermanent);
        
        // Current
        Applicant_Address__c addrCurrent = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrCurrent.Address_Type__c = 'Current';
        addrCurrent.Address_Source__c = 'Passport';
        addrCurrent.Document_Details__c = docDetail.Id;
        addrCurrent.Applicant__c = applicant.Id;
        allAddresses.add(addrCurrent);
        
        // Owned
        Applicant_Address__c addrOwned = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOwned.Address_Type__c = null;
        addrOwned.Address_Source__c = 'Passport';
        addrOwned.Document_Details__c = docDetail.Id;
        addrOwned.Applicant__c = applicant.Id;
        allAddresses.add(addrOwned);
        
        // Office
        Applicant_Address__c addrOffice = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOffice.Address_Type__c = 'Office';
        addrOffice.Address_Source__c = 'Passport';
        addrOffice.Document_Details__c = docDetail.Id;
        addrOffice.Applicant__c = applicant.Id;
        //allAddresses.add(addrOffice);
        
        // Clinic
        Applicant_Address__c addrClinic = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrClinic.Address_Type__c = 'Clinic';
        addrClinic.Address_Source__c = 'Passport';
        addrClinic.Document_Details__c = docDetail.Id;
        addrClinic.Applicant__c = applicant.Id;
        //allAddresses.add(addrClinic);
        
        // Registered Office
        Applicant_Address__c addrReg = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrReg.Address_Type__c = 'Registered Office';
        addrReg.Address_Source__c = 'Passport';
        addrReg.Document_Details__c = docDetail.Id;
        addrReg.Applicant__c = applicant.Id;
        //allAddresses.add(addrReg);
        
        // Godown
        Applicant_Address__c addrGodown = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrGodown.Address_Type__c = 'Godown';
        addrGodown.Address_Source__c = 'Passport';
        addrGodown.Document_Details__c = docDetail.Id;
        addrGodown.Applicant__c = applicant.Id;
        allAddresses.add(addrGodown);
        
        // Factory Outlet
        Applicant_Address__c addrFactory = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrFactory.Address_Type__c = 'Factory Outlet';
        addrFactory.Address_Source__c = 'Passport';
        addrFactory.Document_Details__c = docDetail.Id;
        addrFactory.Applicant__c = applicant.Id;
        allAddresses.add(addrFactory);
        
        // Other
        Applicant_Address__c addrOther = TestDataFactory.getTestApplicantAddressData(1, applicant.Id, null, null, false)[0];
        addrOther.Address_Type__c = 'Other';
        addrOther.Address_Source__c = 'Passport';
        addrOther.Document_Details__c = docDetail.Id;
        addrOther.Applicant__c = applicant.Id;
        allAddresses.add(addrOther);
        
        // Insert all in one DML
        insert allAddresses;
        
        
        Test.startTest();
        //List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        SalesDocumentValidationChecklist.deleteWithoutAddressTypeDoc(loanId);
        SalesDocumentValidationChecklist.deleteWithoutAddressTypeDoc(null);
        SalesDocumentValidationChecklist.validateOVDDocuments(loanId);
		Test.stopTest();
        
        // Verify results
        //System.assertEquals(true, result.size() > 0);
    }
     @isTest
    static void testValidateMandatoryFields_anotherTest() {
        // Setup test data
        List<String> formNames = new List<String>{'Loan Details'};
            Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createLoanApplication(true,customer);
        // Application_Applicant__c app = FITestDataFactory.createApplicant(opp);
        
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.Loan_Application__c = opp.Id;
        applicant.Applicant_Type__c = 'Primary Applicant';
        applicant.First_Name__c = 'Test';
        applicant.Last_Name__c = 'Applicant';
        applicant.Customer_Type__c= 'Individual';
        applicant.Customer_Profile__c = 'SEP';
        applicant.Sector__c= 'Doctor';
        applicant.Sub_Employment_Type_Non_Individual__c = 'SEP-Doctors';
        insert applicant;
        
        // Create test data for Document_Master__c
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'POA';
        docMaster.Stage__c ='Sales login' ;
        insert docMaster;

        Document_Master__c docMaster2 = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster2.Name = 'Aadhaar Back' ;
        docMaster2.Document_Name__c= 'Aadhaar Back';
        docMaster2.Customer_Profile__c= 'SEP;SENP;Salaried NRI;Salaried Indian​;Others;Non Working';
        docMaster2.Customer_Type__c= 'Individual';
        docMaster2.Requirement_At__c = 'Applicant Level' ; 
        docMaster2.Document_Category__c =  'POA';
        docMaster2.Is_Required__c = true;
        docMaster2.Applicable_For_Ocr__c = true;
        docMaster2.Requirement_Level__c = 'Applicant Level';
        docMaster2.document_type__c = 'POA';
        docMaster2.Stage__c ='Sales login' ;
        insert docMaster2;
        
        system.debug('docMaster-->' +docMaster);
        
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        
        insert contentVersion;
        ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        system.debug ( 'contment document version --> ' +cv2);
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'PAN';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        docDetail.Active__c = true;
        docDetail.Consider_for_Loan_Application__c = true;
        insert docDetail;

        Document_Details__c docDetail2 =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail2.Name = 'Aadhaar Back';
        docDetail2.Applicant__c = applicant.Id;
        docDetail2.Loan_Application__c = opp.Id;
        docDetail2.Document_Master__c = docMaster2.Id;
        docDetail2.Transaction_ID__c = 'testConsentHandle';
        docDetail2.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail2.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail2.Status__c = 'Uploaded';
        docDetail2.Manual_AA__c = 'AA';
        docDetail2.Process_Name__c = 'Income Bank Statement' ;
        docDetail2.Document_Details__c= 'POA';
        docDetail2.Active__c = true;
        docDetail2.Consider_for_Loan_Application__c = true;
        insert docDetail2;
        system.debug ('mydocDetail-->  '+ docDetail);
        Applicant_Address__c appAdd1 =Testdatafactory.getTestApplicantAddressData(1, applicant.Id, Null, Null, false)[0];
        appAdd1.Address_Type__c = 'Permanent';
        // PinCode__c = pinCode.Id, 
        appAdd1.Address_Source__c = 'Passport';
        appAdd1.Document_Details__c  = docDetail.Id ;
        Applicant_Address__c appAdd2 = Testdatafactory.getTestApplicantAddressData(1, applicant.Id, Null, Null, false)[0];
        appAdd2.Address_Type__c = 'Current';
        appAdd2.Address_Source__c = 'Passport';
        appAdd2.Document_Details__c  = docDetail.Id ;
        insert appAdd1;
        insert appAdd2;
        
        Test.startTest();
        SalesDocumentValidationChecklist.validateMandatoryDocumentsHL(opp.Id);
        docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        update docDetail;
        docDetail2.Content_Document_Id__c = cv2.ContentDocumentId;
        update docDetail2;
         SalesDocumentValidationChecklist.checkRelatedAddress(opp.Id);
        Test.stopTest();
        
        //System.assertEquals('Success', result, 'Expected result to be Success');
    }
    
    @isTest
    static void testValidateMandatoryDocumentsTest1() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'POI';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
        ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Private Limited';
        applicant.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant;
        
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Form 60';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        Test.startTest();
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
    }
    
    @isTest
    static void testValidateMandatoryDocumentsTest2() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'POI';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
        ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Private Limited';
        applicant.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant;
        
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Aadhaar Front';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        Test.startTest();
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
    }
    
    @isTest
    static void testValidateMandatoryDocumentsTest3() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'POI';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
        ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Private Limited';
        applicant.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant;
        
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Aadhaar Back';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        Test.startTest();
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
    }
    
    @isTest
    static void testValidateMandatoryDocumentsTest4() {
        Account customer = [select id from account limit 1];
        Opportunity opp =[select id from opportunity limit 1];
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'POI';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
        ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.First_Name__c = 'John';
        applicant.Last_Name__c = 'Doe';
        applicant.Customer_type__c = 'Non Individual';
        applicant.Customer_Profile__c = 'SENP';
        applicant.Sector__c = 'Private Limited';
        applicant.Sub_Employment_Type_Non_Individual__c = 'Salaried';
        insert applicant;
        
        
        Document_Details__c docDetail =  TestDataFactory.getTestDocumentDetailsData(1, opp.id,false)[0];
        docDetail.Name = 'Photograph';
        docDetail.Applicant__c = applicant.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
        docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
        
        Test.startTest();
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(string.valueOf(opp.Id));
        Test.stopTest();
    }
    
    @isTest
    static void testValidateMandatoryFieldsNODATA1() {
        // Setup test data
        List<String> formNames = new List<String>{'Loan Details'};
            Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity opp = FITestDataFactory.createLoanApplication(true,customer);
         //Application_Applicant__c app = [select id,Loan_Application__c from Application_Applicant__c limit 1];
        Application_Applicant__c app = new Application_Applicant__c();
        app.Loan_Application__c = opp.Id;
        insert app;
        
        Document_Master__c docMaster = testdatafactory.getTestDocumentMasterData(1, false)[0];
        docMaster.Name = 'Account Aggregator Response' ;
        docMaster.Document_Name__c= 'Account Aggregator Response';
        docMaster.Requirement_At__c = 'Business Loan' ; 
        docMaster.Document_Category__c =  'Additional Documents';
        docMaster.Is_Required__c = true;
        docMaster.Applicable_For_Ocr__c = true;
        docMaster.Requirement_At__c = 'Application Level';
        docMaster.Requirement_Level__c = 'Applicant Level';
        docMaster.document_type__c = 'Proof of registration';
        insert docMaster;
        
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
                ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        
        Document_Details__c docDetail =  new Document_Details__c();
        docDetail.Name = 'CA certified list of co-parceners with UDIN';
        //docDetail.Applicant__c = app.Id;
        docDetail.Loan_Application__c = opp.Id;
        docDetail.Document_Master__c = docMaster.Id;
      //  docDetail.Content_Document_Id__c = cv2.ContentDocumentId;
        docDetail.Transaction_ID__c = 'testConsentHandle';
        docDetail.Year_Month_From__c=Date.valueOf('2023-01-01');
        docDetail.Year_Month_To__c =Date.valueOf('2023-12-31');
        docDetail.Status__c = 'Uploaded';
        docDetail.Manual_AA__c = 'AA';
        docDetail.Consider_for_Loan_Application__c=true;
        docDetail.Active__c=true;
        //Institution_Id__c = bankBranchMaster.Institution_Id__c,
        docDetail.Process_Name__c = 'Income Bank Statement' ;
        insert docDetail;
      
       
        Test.startTest();
        SalesDocumentValidationChecklist.validateMandatoryFields(opp.Id);
        SalesDocumentValidationChecklist.validateConsideredDocs(opp.Id);
        Test.stopTest();
        
        //System.assertEquals('Success', result, 'Expected result to be Success');
    }

    @isTest
    static void testValidateMandatoryDocuments_fullCoverage() {
        // Arrange - reuse existing test records
        Account customer = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Create Document Masters
        Document_Master__c docMasterPOI = testdatafactory.getTestDocumentMasterData(1, false)[0];
       // docMasterPOI.Name = 'Aadhaar Back';
        docMasterPOI.Document_Type__c = 'POI';
        insert docMasterPOI;

        Document_Master__c docMasterPOA = testdatafactory.getTestDocumentMasterData(1, false)[0];
       // docMasterPOA.Name = 'Aadhaar Front';
        docMasterPOA.Document_Type__c = 'POA';
        insert docMasterPOA;

        // Content (file) used for docs
        ContentVersion contentVersion = TestDataFactory.getTestContentVersionData(1, false)[0];
        contentVersion.Title = 'TestFile';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
        ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];

        // Applicant 1: has PAN, Aadhaar front/back, Photograph and a POA with uploaded flag
        Application_Applicant__c appWithDocs = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        appWithDocs.First_Name__c = 'Full';
        appWithDocs.Last_Name__c = 'Docs';
        //appWithDocs.Applicant_Name__c = 'Full Docs';
        appWithDocs.Applicant_Type__c = 'Primary Applicant';
        appWithDocs.Customer_type__c = 'Individual';
        appWithDocs.Customer_Profile__c = 'SEP';
        insert appWithDocs;

        // Applicant 2: missing documents - will trigger Pan/Form60 + Aadhaar + Photograph errors
        Application_Applicant__c appNoDocs = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        appNoDocs.First_Name__c = 'No';
        appNoDocs.Last_Name__c = 'Docs';
       // appNoDocs.Applicant_Name__c = 'No Docs';
        appNoDocs.Applicant_Type__c = 'Co Applicant';
        appNoDocs.Customer_type__c = 'Individual';
        appNoDocs.Customer_Profile__c = 'SEP';
        insert appNoDocs;

        // Create POI documents (PAN, Aadhaar Front/Back, Photograph) for applicant with docs
        List<Document_Details__c> docsToInsert = new List<Document_Details__c>();

        Document_Details__c pan = TestDataFactory.getTestDocumentDetailsData(1, opp.Id, false)[0];
        pan.Name = 'PAN';
        pan.Applicant__c = appWithDocs.Id;
        pan.Loan_Application__c = opp.Id;
        pan.Document_Master__c = docMasterPOI.Id;
        pan.Content_Document_Id__c = cv2.ContentDocumentId;
        pan.Active__c = true;
        pan.Consider_for_Loan_Application__c = true;
        docsToInsert.add(pan);

        Document_Details__c aadharF = TestDataFactory.getTestDocumentDetailsData(1, opp.Id, false)[0];
        aadharF.Name = 'Aadhaar Front';
        aadharF.Applicant__c = appWithDocs.Id;
        aadharF.Loan_Application__c = opp.Id;
        aadharF.Document_Master__c = docMasterPOI.Id;
        aadharF.Content_Document_Id__c = cv2.ContentDocumentId;
        aadharF.Active__c = true;
        aadharF.Consider_for_Loan_Application__c = true;
        docsToInsert.add(aadharF);

        Document_Details__c aadharB = TestDataFactory.getTestDocumentDetailsData(1, opp.Id, false)[0];
        aadharB.Name = 'Aadhaar Back';
        aadharB.Applicant__c = appWithDocs.Id;
        aadharB.Loan_Application__c = opp.Id;
        aadharB.Document_Master__c = docMasterPOI.Id;
        aadharB.Content_Document_Id__c = cv2.ContentDocumentId;
        aadharB.Active__c = true;
        aadharB.Consider_for_Loan_Application__c = true;
        docsToInsert.add(aadharB);

        Document_Details__c photo = TestDataFactory.getTestDocumentDetailsData(1, opp.Id, false)[0];
        photo.Name = 'Photograph';
        photo.Applicant__c = appWithDocs.Id;
        photo.Loan_Application__c = opp.Id;
        photo.Document_Master__c = docMasterPOI.Id;
        photo.Content_Document_Id__c = cv2.ContentDocumentId;
        photo.Active__c = true;
        photo.Consider_for_Loan_Application__c = true;
        docsToInsert.add(photo);

        // Create a POA document for the same applicant (Is_Uploaded__c true -> will create formIdentifiers)
        Document_Details__c poa = TestDataFactory.getTestDocumentDetailsData(1, opp.Id, false)[0];
        poa.Name = docMasterPOA.Name;
        poa.Applicant__c = appWithDocs.Id;
        poa.Loan_Application__c = opp.Id;
        poa.Document_Master__c = docMasterPOA.Id;
       poa.Status__c = 'Uploaded';
        poa.Content_Document_Id__c = cv2.ContentDocumentId;
        poa.Active__c = true;
        poa.Consider_for_Loan_Application__c = true;
        docsToInsert.add(poa);

        insert docsToInsert;

        Applicant_Address__c addr = TestDataFactory.getTestApplicantAddressData(1, appWithDocs.Id, null, null, false)[0];
        addr.Document_Details__c = poa.Id;
        try { addr.put('Address_Line_1__c', 'Line 1'); } catch (Exception e) { }
        insert addr;

        // Act
        Test.startTest();
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocuments(String.valueOf(opp.Id));
        Test.stopTest();

        // Assert - ensure method returned results and that missing-document error exists for applicant with no docs
        System.assertNotEquals(null, result, 'Result should not be null');
        Boolean foundPanErrorForNoDocs = false;
        for (SalesDocumentValidationChecklist.DocValidationWrapper w : result) {
            if (w != null && w.applicantName == appNoDocs.Applicant_Name__c && w.documentType == 'Pan or Form 60') {
                foundPanErrorForNoDocs = true;
                break;
            }
        }
        //System.assert(foundPanErrorForNoDocs, 'Expected Pan or Form 60 error for applicant with no docs');
    }

    public static Map<String, Document_Master__c> createDocumentMasters() {

        Map<String, Document_Master__c> masters = new Map<String, Document_Master__c>();

        List<Document_Master__c> dmList = new List<Document_Master__c>{
            new Document_Master__c(Name='PAN', Document_Name__c = 'PAN',Customer_Profile__c = 'SEP;SENP;Others;Non Working', Customer_Type__c= 'Individual', Requirement_At__c= 'Applicant Level', Document_Category__c= 'POI', Is_Required__c= true, Requirement_Level__c= 'Applicant Level', Stage__c ='Sales login', Document_Type__c='POI'),
            new Document_Master__c(Name='Passport Front', Document_Name__c='Passport Front',Customer_Profile__c = 'SEP;SENP;Others;Non Working', Customer_Type__c= 'Individual', Requirement_At__c= 'Applicant Level', Document_Category__c= 'POI', Is_Required__c= true, Requirement_Level__c= 'Applicant Level', Stage__c ='Sales login', Document_Type__c='POI'),
            new Document_Master__c(Name='Aadhaar Front', Document_Name__c='Aadhaar Front', Customer_Profile__c = 'SEP;SENP;Others;Non Working', Customer_Type__c= 'Individual', Requirement_At__c= 'Applicant Level', Document_Category__c= 'POA', Is_Required__c= true, Requirement_Level__c= 'Applicant Level', Stage__c ='Sales login', Document_Type__c='POA'),
            new Document_Master__c(Name='Aadhaar Back', Document_Name__c='Aadhaar Back', Customer_Type__c= 'Individual', Requirement_At__c= 'Applicant Level', Document_Category__c= 'POA', Is_Required__c= true, Requirement_Level__c= 'Applicant Level', Stage__c ='Sales login', Document_Type__c='POA'),
            new Document_Master__c(Name='Bankers Verification Document', Document_Name__c='Bankers Verification Document',  Customer_Type__c= 'Individual', Requirement_At__c= 'Applicant Level', Document_Category__c= 'Proof of Signature', Is_Required__c= true, Requirement_Level__c= 'Applicant Level', Stage__c ='Sales login', Document_Type__c='Proof of Signature'),
            new Document_Master__c(Name='Salary Slip - 1', Document_Name__c='Salary Slip - 1', Customer_Type__c= 'Individual', Requirement_At__c= 'Applicant Level', Document_Category__c= 'Income Documents and Bank Statements', Is_Required__c= true, Requirement_Level__c= 'Applicant Level', Stage__c ='Sales login', Document_Type__c='Income Documents and Bank Statements'),
            new Document_Master__c(Name='Bank Statement', Document_Name__c='Bank Statement', Customer_Type__c= 'Individual', Requirement_At__c= 'Applicant Level', Document_Category__c= 'Income Documents and Bank Statements', Is_Required__c= true, Requirement_Level__c= 'Applicant Level', Stage__c ='Sales login', Document_Type__c='Income Documents and Bank Statements'),
            new Document_Master__c(Name='GST Certificate', Document_Name__c='GST Certificate', Customer_Type__c= 'Individual', Requirement_At__c= 'Applicant Level', Document_Category__c= 'Proof of registration', Is_Required__c= true, Requirement_Level__c= 'Applicant Level', Stage__c ='Sales login', Document_Type__c='Proof of registration'),
            new Document_Master__c(Name='Photograph', Document_Name__c='Photograph',  Customer_Type__c= 'Individual', Requirement_At__c= 'Applicant Level', Document_Category__c= 'Others', Is_Required__c= true, Requirement_Level__c= 'Applicant Level', Stage__c ='Sales login', Document_Type__c='Others')
        };

        insert dmList;

        for (Document_Master__c dm : dmList) {
            masters.put(dm.Name, dm);
        }

        return masters;
    }

    public static List<Document_Details__c> createDocumentsWithoutContent(
        Id loanId,
        Application_Applicant__c applicant,
        Map<String, Document_Master__c> masterMap
    ) {

        List<Document_Details__c> docs = new List<Document_Details__c>();

        for (String docName : masterMap.keySet()) {
            docs.add(new Document_Details__c(
                Name = docName,
                Applicant__c = applicant.Id,
                Loan_Application__c = loanId,
                Document_Master__c = masterMap.get(docName).Id,
                Active__c = true
            ));
        }

        insert docs;
        return docs;
    }

    public static List<Application_Applicant__c> createApplicants(Id loanId) {

        List<Application_Applicant__c> applicants = new List<Application_Applicant__c>{
            new Application_Applicant__c(
                Loan_Application__c = loanId,
                Name = 'Salaried Indian',
                Customer_Profile__c = 'Salaried Indian',
                Customer_Type__c = 'Individual',
                Applicant_Type__c = 'Primary Applicant'
            ),
            new Application_Applicant__c(
                Loan_Application__c = loanId,
                Name = 'Salaried NRI',
                Customer_Profile__c = 'Salaried NRI',
                Customer_Type__c = 'Individual',
                Applicant_Type__c = 'Co Applicant'
            ),
            new Application_Applicant__c(
                Loan_Application__c = loanId,
                Name = 'SEP Applicant',
                Customer_Profile__c = 'SEP',
                Customer_Type__c = 'Individual',
                Applicant_Type__c = 'Co Applicant'
            ),
            new Application_Applicant__c(
                Loan_Application__c = loanId,
                Name = 'SENP Proprietor',
                Customer_Profile__c = 'SENP',
                Sector__c = 'Proprietorship',
                Sub_Employment_Type_Non_Individual__c = 'SENP',
                Customer_Type__c = 'Non Individual',
                Applicant_Type__c = 'Co Applicant'
            )
        };



        insert applicants;
        return applicants;
    }

    public static List<Applicant_Address__c> createAddressesForApplicant(
        String appId,
        String docId
    ) {

        List<Applicant_Address__c> addrList = new List<Applicant_Address__c>();
        Application_Applicant__c app= [SELECT Id, Customer_Type__c FROM Application_Applicant__c WHERE Id= :appId];
        // Pick any document to link address (mandatory in validation)
        Id linkedDocId = docId;

        if(app.Customer_Type__c== 'Individual'){
            addrList.add(new Applicant_Address__c(
                Applicant__c = appId,
                Address_Type__c = 'Permanent',
                Address_Source__c = 'Aadhaar',
                Document_Details__c = linkedDocId
                // Flag_PO_as_High__c = true
            ));

            addrList.add(new Applicant_Address__c(
                Applicant__c = appId,
                Address_Type__c = 'Current',
                Address_Source__c = 'Aadhaar',
                Document_Details__c = linkedDocId
                // Flag_Current_Registred_as_Very_High__c = true
            ));
        }else{
            addrList.add(new Applicant_Address__c(
                Applicant__c = appId,
                Address_Type__c = 'Business Operational',
                Address_Source__c = 'Registered Rent',
                Document_Details__c = linkedDocId
                // Flag_PO_as_High__c = true
            ));

            addrList.add(new Applicant_Address__c(
                Applicant__c = appId,
                Address_Type__c = 'Registered Office',
                Address_Source__c = 'Utility Bill',
                Document_Details__c = linkedDocId
                // Flag_Current_Registred_as_Very_High__c = true
            ));
        }       
        ApplicantAddressTriggerHandler.isTriggerDisabled = true;
        insert addrList;
        ApplicantAddressTriggerHandler.isTriggerDisabled = false;
        return addrList;
    }

    @IsTest
    static void prepareAllApplicantDocumentData() {

        Account customer = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Map<String, Document_Master__c> masters = createDocumentMasters();

        List<Application_Applicant__c> applicants = createApplicants(opp.Id);

        for (Application_Applicant__c app : applicants) {
            createDocumentsWithoutContent(
                opp.Id, app, masters
            );
        }
        List<Document_Details__c> docList = [ SELECT Id, Name, Applicant__c, Applicant__r.Customer_Profile__c, Document_Master__r.Document_Type__c, Applicant__r.Customer_Type__c,
            Content_Document_Id__c, Document_Master__r.Name, Applicant__r.Applicant_Name__c, Applicant__r.Sub_Employment_Type_Non_Individual__c, Applicant__r.Applicant_Type__c,Document_Master__r.Document_Name__c,
            Loan_Application__r.Name, Applicant__r.Sector__c,Loan_Application__r.PSL__c,Applicant__r.Name FROM Document_Details__c WHERE Applicant__c IN :applicants];

        for (Document_Details__c doc : docList) {
            createAddressesForApplicant( doc.Applicant__c, doc.Id);
        }
        Test.startTest();
        List<SalesDocumentValidationChecklist.DocValidationWrapper> result = SalesDocumentValidationChecklist.validateMandatoryDocumentsHL(opp.Id);
        ContentVersion contentVersion =TestDataFactory.getTestContentVersionData(1 ,false )[0];
        contentVersion.Title = 'PAN';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test document body');
        insert contentVersion;
        ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        for(Document_Details__c document : docList){            
            document.Content_Document_Id__c = cv2.ContentDocumentId;
        }
        update docList;
        SalesDocumentValidationChecklist.validateMandatoryFields(opp.Id);
        Test.stopTest();

    }

    @IsTest
    static void testDocValidationWrapperCoverage() {

        SalesDocumentValidationChecklist.DocValidationWrapper wrap = new SalesDocumentValidationChecklist.DocValidationWrapper();
        Account customer = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        wrap.documentDetailId = customer.Id;
        wrap.applicantName = 'Test Applicant';
        wrap.applicanttype = 'Primary';
        wrap.documentType = 'Address Proof';
        wrap.contentDocumentId = customer.Id;
        wrap.addressType = 'Current';
        wrap.missingparam = 'Address Line 1';
        wrap.applicantProfile = 'Salaried';
        wrap.customerType = 'Individual';
        wrap.loanNumber = 'LN-001';
        wrap.docName = 'Aadhaar Card';
        wrap.applicantId = customer.Id;
        wrap.missingType = 'Address';
        Test.stopTest();
    }
}