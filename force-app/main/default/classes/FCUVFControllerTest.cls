@isTest
public class FCUVFControllerTest {
    @testSetup static void setupData(){
        Trigger_Settings__c triggerSettings = new Trigger_Settings__c(
            Name='Trigger Settings',
            Application_Applicant_Trigger__c = true, 
            City_Master_Trigger__c = true, 
            Lead_Trigger__c = true, 
            Opportunity_Trigger__c = true, 
            Application_Verification_Trigger__c = true
        );
        insert triggerSettings;
        // Create Account
        Account acc = TestDataFactory.getTestAccounts(1, 'Partner', false)[0];
        insert acc;
        List<Opportunity> oppRecList = TestDataFactory.getTestOpportunityData(1, false);
        oppRecList[0].Requested_Amount__c = 10000;
        insert oppRecList;
        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, oppRecList[0].Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = oppRecList[0].Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        insert applicant;
        List<ContentVersion> versions = new List<ContentVersion>{
            new ContentVersion(Title='TestFile1', PathOnClient='TestFile1.pdf', VersionData=Blob.valueOf('Test content 1')),
                new ContentVersion(Title='TestFile2', PathOnClient='TestFile2.pdf', VersionData=Blob.valueOf('Test content 2'))
                };
                    insert versions;
        List<ContentVersion> contentVersionRecList = [SELECT Id, ContentDocumentId FROM ContentVersion];
        Document_Master__c docMaster = new Document_Master__c(
            Document_Name__c = 'Driving License',
            Name = 'Driving License',
            Is_Active__c = true,
            Document_Category__c = 'KYC',
            Is_Required__c = false,
            Product__c = 'Business Loan',
            Requirement_At__c = 'Loan Application',
            Requirement_Level__c= 'Loan Application Level',
            Mandatory_Non_Mandatory__c='Required',
            Stage__c='Sales login',
            Document_Type__c = 'Proof of practice'
        );
        insert docMaster;
        Document_Details__c doc1 = new Document_Details__c(
            Loan_Application__c = oppRecList[0].Id,
            Applicant__c=applicant.Id,
            Name = 'CRIF',
            Document_Master__c = docMaster.Id,
            Verification_Status__c = 'Pending',
            Active__c = true,
            Status__c = null,
            Content_Document_Id__c = contentVersionRecList[0].ContentDocumentId
        );
        insert doc1;
        Application_Verification__c applicationVerificationRec = TestDataFactory.createApplicationVerification(applicant.Id, oppRecList[0].Id, 'test credit mart', 'Waiver_Remark', 'Admin_s_Remark', 'Any_Remarks_Reasons');
        applicationVerificationRec.Vendor__c = acc.Id;
        applicationVerificationRec.Verification_Status__c = 'Positive';
        applicationVerificationRec.Sample_Date__c = date.today();
        insert applicationVerificationRec;
        Application_Verification__c applicationVerificationChildRec = TestDataFactory.createApplicationVerification(applicant.Id, oppRecList[0].Id, 'test credit mart', 'Waiver_Remark 1', 'Admin_s_Remark', 'Any_Remarks_Reasons');
        applicationVerificationChildRec.Parent_FCU__c = applicationVerificationRec.Id;
        applicationVerificationChildRec.Report_Name__c = '';
        applicationVerificationChildRec.Document_Detail__c = doc1.Id;
        insert applicationVerificationChildRec;
        
        
        
        List<Document_Details__c> documentDetailsToInsertList = new List<Document_Details__c>();
        Document_Details__c doc = new Document_Details__c(
            Loan_Application__c = oppRecList[0].Id,
            Applicant__c=applicant.Id,
            Application_Verification__c = applicationVerificationChildRec.Id,
            Name = 'CRIF',
            Document_Master__c = docMaster.Id,
            Verification_Status__c = 'Pending',
            Active__c = true,
            Status__c = null,
            Content_Document_Id__c = contentVersionRecList[0].ContentDocumentId
        );
        
        documentDetailsToInsertList.add(doc);
        insert documentDetailsToInsertList;
    }
    @isTest static void FCUVFContTest(){
        Test.startTest();
        Application_Verification__c appVerRec = [SELECT Id FROM Application_Verification__c order by Createddate ASC LIMIT 1];
        // Simulating the Page with the recordId passed in the URL parameters
        ApexPages.currentPage().getParameters().put('Id', appVerRec.Id);
        
        // Create the controller instance
        FCUVFController controller = new FCUVFController();
        
        // Assertions
        /*System.assertNotEquals(null, controller, 'Controller should not be null');
        System.assertEquals('FCU Report', controller.headerData, 'Header data should be set correctly');
        System.assertEquals('Sample Report', controller.sampledDocs, 'Sampled Docs should be set correctly');
        System.assertEquals('Verified', controller.status, 'Status should be set correctly');
        System.assertNotEquals(null, controller.images, 'Images list should not be null');
        System.assertTrue(controller.isImagePresent, 'Image should be present');*/
        
        Test.stopTest();
    }
}