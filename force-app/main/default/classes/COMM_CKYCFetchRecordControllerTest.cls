@isTest
public class COMM_CKYCFetchRecordControllerTest {

    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"response":{"A99ResponseData":{"CKYCDownloadResult":{"CKYCFormSixty":"No","CKYCIDDetails":{"CKYCIdentityDetails":{"CKYCIDType":"E","CKYCIDVerificationStatus":"02","CKYCIDSequence":1,"CKYCIDNumber":"XXXXXXXX7498"}},"CKYCStatus":"CKYCSuccess","CKYCNamePrefix":"Mr","CKYCKYCVerificationDesg":"Manager","CKYCCorAddPOA":"AadharCard","CKYCMaidenMiddleName":"","CKYCMotherFirstName":"Devi","CKYCPAN":"GNYPM9875D","CKYCMotherFullName":"Mrs Devi  Murugan","CKYCKYCVerificationBranch":"Mumbai","CKYCKYCVerificationName":"Manish Vichare","CKYCAccType":"01","CKYCFatherNamePrefix":"","CKYCLastName":"Murugan","CKYCPerAddCity":"Thane","CKYCOffTelNumber":"","CKYCMobileISD":91,"RequestId":1759222053397,"CKYCDateofDeclaration":"16-Aug-2025","CKYCDOB":"17-Mar-1996","CKYCMotherNamePrefix":"Mrs","CKYCCorAddCity":"Thane","CKYCMobileNumber":7738282592,"CKYCNumberofRelatedPersons":0,"CKYCCorAdd2":"1st Rabodi","CKYCCorAdd1":"Gulmohar apt","CKYCPlaceofDeclaration":"Mumbai","CKYCResTelSTD":"","CKYCFatherFullName":"","CKYCCorAdd3":"","CKYCReferenceID":"INTPFZ12598071","CKYCMaidenFirstName":"","ApplicationFormNo":"","CKYCResTelNumber":"","CKYCMaidenNamePrefix":"","CKYCPerAddPin":400601,"CKYCMaidenFullName":"","CKYCCorAddPin":400601,"CKYCMotherMiddletName":"","CKYCKYCVerificationDate":"19-Aug-2025","CKYCPerAddState":"MH","CKYCOffTelSTD":"","CKYCNumberofImages":2,"CKYCPerAddSameasCorAdd":"Y","CKYCRelatedPersonDetails":"","CKYCPerAddDistrict":"Thane","CKYCMiddleName":"","CKYCKYCVerificationEmpcode":716801,"CKYCFullName":"Mr Sreenivasan  Murugan","CKYCImageDetails":{"CKYCImageDetails":[{"CKYCImageData":"068C2000003qU3VIAU","CKYCImageBranch":"0011","CKYCImageType":"AadharCard","CKYCImageSequence":1,"CKYCImageGlobalorLocal":"","CKYCImageExtension":"jpg"},{"CKYCImageData":"068C2000003qS3LIAU","CKYCImageBranch":"0011","CKYCImageType":"Photograph","CKYCImageSequence":2,"CKYCImageGlobalorLocal":"","CKYCImageExtension":"jpg"}]},"CKYCConstiType":"01","CKYCPerAdd1":"Gulmohar apt","CKYCPerAdd3":"","CKYCMaidenLastName":"","CKYCPerAdd2":"1st Rabodi","CKYCNumber":30035676981122,"CKYCNumberofIds":1,"CKYCFatherLastName":"","CKYCCorAddCountry":"IN","CKYCEmailAdd":"","CKYCCorAddState":"MH","CKYCFatherFirstName":"","CKYCFatherMiddleName":"","CKYCFirstName":"Sreenivasan","CKYCPerAddPOA":"AadharCard","CKYCCorAddDistrict":"Thane","CKYCTypeofDocSubmitted":"01","CKYCGender":"M","CKYCPerAddCountry":"IN","ResidentialStatus":"Resident Individual","CKYCMotherLastName":"Murugan","CKYCRemarks":""},"xmlns:xsi":"http://www.w3.org/2001/XMLSchema-instance","xmlns:xs":"http://www.w3.org/2001/XMLSchema","CKYCSearchResult":"","RequestStatus":"AcceptedByTW"}}}');
            return res;
        }
    }
    

    @TestSetup
    static void setupData(){
        TestDataFactory.setupIntegrationSettings('AHL CKYC');
        TestDataFactory.setupIntegrationSettings('Get Token');
        insert new List<Document_Master__c>{
            new Document_Master__c(Name='Aadhaar Front', Requirement_At__c='Applicant Level', Document_Name__c= 'Aadhaar Front', Document_Category__c= 'Applicant Level'),
            new Document_Master__c(Name='Aadhaar Back', Requirement_At__c='Applicant Level', Document_Name__c= 'Aadhaar Back', Document_Category__c= 'Applicant Level'),
            new Document_Master__c(Name='Photograph', Requirement_At__c='Applicant Level', Document_Name__c= 'Photograph', Document_Category__c= 'Applicant Level')
        };

        ContentVersion cv1 = new ContentVersion(
            Title = 'AadharCard',
            VersionData = Blob.valueOf('Test'),
            PathOnClient = 'test.jpg'
        );
        insert cv1;

        Opportunity loanApplication = TestDataFactory.getTestOpportunityData(1, true)[0];
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        customer.Customer_LMS_Id__c = '106037';
        update customer;

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, loanApplication.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = loanApplication.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        applicant.Customer__c = customer.Id;
        insert applicant;

        Triangulation_Data__c triangulationData= new Triangulation_Data__c(
            CKYC_Transaction_Id__c= '123444',
            Loan_Application__c= loanApplication.Id, 
            Application_Applicant__c= applicant.Id,
            Source_Type__c= 'CKYC'
        );
        insert triangulationData;

        PLF_Master__c master1= new PLF_Master__c(
            Master_Type__c= 'Salutation CKYC',
            Description__c= 'Mr',
            FICO_Code__c= 'Mr.'
        );
        insert master1;

        PLF_Master__c master2= new PLF_Master__c(
            Master_Type__c= 'Gender CKYC',
            Description__c= 'M',
            FICO_Code__c= 'Male'
        );
        insert master2;

    }


    @IsTest static void getConstantsTest() {
        Test.startTest();
        Map<String, String> constants = COMM_CKYCFetchRecordController.getConstants();
        Map<String, String> constants1 = COMM_CKYCFetchRecordHandler.getConstants();
        Date d = COMM_CKYCFetchRecordController.stringToDateParsing('10-Aug-2025');
        Test.stopTest();
    }

    @IsTest static void storeCkycImageChecklistTest() {
        Id applicantId = [SELECT Id FROM Application_Applicant__c LIMIT 1].Id;
        Id loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        List<ContentVersion> cvList = [SELECT Id FROM ContentVersion LIMIT 1];
        List<String> cvIds = new List<String>{cvList[0].Id};

        Test.startTest();
        Map<String, Document_Details__c> mapDocs =
            COMM_CKYCFetchRecordController.storeCkycImageChecklist(cvIds, applicantId, loanId);
        Test.stopTest();
    }

    @IsTest static void processCkycFetchRecordAPITest() {
        Id applicantId = [SELECT Id FROM Application_Applicant__c LIMIT 1].Id;
        Id loanId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        List<ContentVersion> cvList = [SELECT Id FROM ContentVersion LIMIT 1];

        Map<String,String> inputMap = new Map<String,String>{
            'loanId' => loanId,
            'applicantId' => applicantId,
            'processName' => 'CKYC Fetch',
            'otpNumber' => '1234'
        };
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String result = COMM_CKYCFetchRecordController.processCkycFetchRecordAPI(inputMap);
        Test.stopTest();
    }
}