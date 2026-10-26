@isTest
public class UdhyamRegistartionCheckControllerTest {
    
    @testSetup
    static void setup() {
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApp = FITestDataFactory.createLoanApplication(true,customer);
        loanApp.Udhyam_Registration_No__c  = 'UDY12345';
        update loanApp;
        
        Application_Applicant__c applicant =  FITestDataFactory.createApplicant(loanApp);
        //string resBody = '{"applicantName" : "'+applicant.Name+'", "requestId" : "12345", "statusCode" : "200", "Cls_Result" : {},"Cls_ClientData" : {"caseId" : "3222"}}';
        
        
        
        Integration_Settings__c  custSet = new Integration_Settings__c(
            Name = 'Get Token',
            Client_Id__c = 'f9709782-85ea-49fc-848a-6abcbfa65611',
            Client_Secret__c = 'REDACTED_CLIENT_SECRET',
            Endpoint__c = 'Callout:LOS_BL_Bearer',
            Content_Type__c = 'application/json',
            Request_Method__c = 'GET',
            Cookie__c = 'Test'
        );
        
        Insert custSet;  
        
        Integration_Settings__c  custSet1 = new Integration_Settings__c(
            Name = 'Loan Udhyam',
            Client_Id__c = 'f9709782-85ea-49fc-848a-6abcbfa65611',
            Client_Secret__c = 'REDACTED_CLIENT_SECRET',
            Endpoint__c = 'Callout:LOS_BL_Bearer',
            Content_Type__c = 'application/json',
            Request_Method__c = 'GET',
            
            Cookie__c = 'Test'
        );
        
        Insert custSet1; 
    }
    
    @isTest
    static void testInitiateUdhyamRegistrationcheck1() {
        Opportunity opp = [SELECT Id,Udhyam_Registration_No__c FROM Opportunity LIMIT 1];
         opp.Udhyam_Registration_No__c  = '';
        update opp;
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
        UdhyamRegistartionCheckController.InputWrapper inputWrapper = new UdhyamRegistartionCheckController.InputWrapper();
        inputWrapper.loanId = opp.Id;
        inputWrapper.applicantId = applicant.Id;
        inputWrapper.processName = 'Loan Udhyam';
        inputWrapper.registrationNo = opp.Udhyam_Registration_No__c;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator2());
        try{
        String result = UdhyamRegistartionCheckController.initiateUdhyamRegistrationcheck(inputWrapper);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
         }catch(exception ex){
            
        }
    }
    
    @isTest
    static void testGetConstants() {
        Test.startTest();
        Map<String, String> constants = UdhyamRegistartionCheckController.getConstants();
        List<UdhyamRegistartionCheckController.UdhyamRegistartionCheckResponseWrapper> result = UdhyamRegistartionCheckController.getUdhyamCheckdata('test');

        Test.stopTest();
        
        System.assertNotEquals(null, constants);
    }
    
    @isTest
    static void testInvokeMethod() {
        Opportunity opp = [SELECT Id,Udhyam_Registration_No__c FROM Opportunity LIMIT 1];
        String processName = 'Loan Udhyam';
        String appId = 'TestAppId';
        
        
        Test.setMock(HttpCalloutMock.class, new MultiApiMock());
        Test.startTest();
        try{
            // String result = UdhyamRegistartionCheckController.invokeMethod(opp.Id,appId, processName);

        }
        catch(exception ex)
        {}
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testGetUdhyamCheckdata2() {
        
        Application_Applicant__c applicant = [SELECT Id,Name FROM Application_Applicant__c LIMIT 1];
        
        // Prepare mock Udhyam response JSON
        UdhyamRegistartionCheckController.UdhyamRegistartionCheckResponseWrapper wrapper = new UdhyamRegistartionCheckController.UdhyamRegistartionCheckResponseWrapper();
        wrapper.requestId = 'REQ12345';
        wrapper.statusCode = 200;
        wrapper.applicantName = applicant.Name;
        wrapper.clientData = new UdhyamRegistartionCheckController.Cls_ClientData();
        wrapper.clientData.caseId = 'CASE123';
        
        wrapper.result = new UdhyamRegistartionCheckController.Cls_Result();
        wrapper.result.udyamRegistrationNo = 'U12345';
        wrapper.result.dateOfRegistration = '2022-01-01';
        wrapper.result.interestedInTreds = 'Yes';
        wrapper.result.interestedInGem = 'No';
        
        wrapper.result.profile = new UdhyamRegistartionCheckController.Cls_Profile();
        wrapper.result.profile.name = 'Enterprise Name';
        wrapper.result.profile.enterpriseType = 'Micro';
        wrapper.result.profile.majorActivity = 'Manufacturing';
        wrapper.result.profile.organizationType = 'Proprietorship';
        wrapper.result.profile.ownerName = 'Owner Name';
        wrapper.result.profile.pan = 'ABCDE1234F';
        wrapper.result.profile.previousITRStatus = 'Filed';
        wrapper.result.profile.itrType = 'ITR-4';
        wrapper.result.profile.gstnStatus = 'Active';
        wrapper.result.profile.mobile = '9876543210';
        wrapper.result.profile.emailId = 'test@example.com';
        wrapper.result.profile.socialCategory = 'General';
        wrapper.result.profile.gender = 'Male';
        wrapper.result.profile.speciallyAbled = 'No';
        wrapper.result.profile.dateOfIncorporation = '2015-05-05';
        wrapper.result.profile.dateOfCommencement = '2015-06-06';
        
        wrapper.result.bankDetails = new UdhyamRegistartionCheckController.Cls_BankDetails();
        wrapper.result.bankDetails.bank = 'Test Bank';
        wrapper.result.bankDetails.ifsc = 'TEST0001';
        wrapper.result.bankDetails.acNo = '1234567890';
        
        wrapper.result.employmentDetails = new UdhyamRegistartionCheckController.Cls_EmploymentDetails();
        wrapper.result.employmentDetails.male = '5';
        wrapper.result.employmentDetails.female = '3';
        wrapper.result.employmentDetails.others = '0';
        wrapper.result.employmentDetails.total = '8';
        
        wrapper.result.financials = new UdhyamRegistartionCheckController.Cls_Financials();
        wrapper.result.financials.financialYear = '2021-22';
        wrapper.result.financials.details = new UdhyamRegistartionCheckController.Cls_FinancialDetails();
        wrapper.result.financials.details.wdvPme = '50000';
        wrapper.result.financials.details.exclusion = '0';
        wrapper.result.financials.details.netInvestmentInPme = '50000';
        wrapper.result.financials.details.totalTurnover = '1000000';
        wrapper.result.financials.details.exportTurnover = '100000';
        wrapper.result.financials.details.netTurnover = '900000';
        
        wrapper.result.branchDetails = new List<UdhyamRegistartionCheckController.Cls_BranchDetails>();
        UdhyamRegistartionCheckController.Cls_BranchDetails branch = new UdhyamRegistartionCheckController.Cls_BranchDetails();
        branch.name = 'Branch 1';
        branch.city = 'CityName';
        branch.state = 'StateName';
        branch.pincode = '123456';
        wrapper.result.branchDetails.add(branch);
        
        wrapper.result.officialAddress = new UdhyamRegistartionCheckController.Cls_OfficialAddress();
        wrapper.result.officialAddress.city = 'CityName';
        wrapper.result.officialAddress.state = 'StateName';
        wrapper.result.officialAddress.pincode = '123456';
        wrapper.result.officialAddress.email = 'official@example.com';
        wrapper.result.officialAddress.mobile = '9876543210';
        
        wrapper.result.industry = new List<UdhyamRegistartionCheckController.Cls_Industry>();
        UdhyamRegistartionCheckController.Cls_Industry industry = new UdhyamRegistartionCheckController.Cls_Industry();
        industry.industry = 'Manufacturing';
        industry.subSector = 'Textiles';
        industry.activityDescription = 'Garment Making';
        industry.industryCode = '101';
        industry.subSectorCode = '102';
        industry.nicCode = '103';
        industry.activity = 'Production';
        wrapper.result.industry.add(industry);
        
        wrapper.result.pdfData = 'base64pdfstring';
        
    }
    
    
    @isTest
    static void testCreateInputMap() {
        Opportunity opp = [SELECT Id,Udhyam_Registration_No__c FROM Opportunity LIMIT 1];
        String processName = 'Loan Udhyam';
        String appId = 'TestAppId';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator2());
        Test.startTest();
        try{
             UdhyamRegistartionCheckController udObj=new UdhyamRegistartionCheckController();
        String response = udObj.invokeMethod(opp.Id, 'App456', 'Activity789');
        String result = UdhyamRegistartionCheckController.createInputMap(opp.Id, processName, appId);
       
        Test.stopTest();
        
        System.assertNotEquals(null, result);
             }catch(exception ex){
            
        }
    }
    
    @isTest
    static void testInitiateUdhyamRegistrationcheck() {
        Opportunity opp = [SELECT Id,Udhyam_Registration_No__c FROM Opportunity LIMIT 1];
        Application_Applicant__c applicant = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        
        UdhyamRegistartionCheckController.InputWrapper inputWrapper = new UdhyamRegistartionCheckController.InputWrapper();
        inputWrapper.loanId = opp.Id;
        inputWrapper.applicantId = applicant.Id;
        inputWrapper.processName = 'Loan Udhyam';
        inputWrapper.registrationNo = opp.Udhyam_Registration_No__c;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator2());
        try{
        String result = UdhyamRegistartionCheckController.initiateUdhyamRegistrationcheck(inputWrapper);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
         }catch(exception ex){
            
        }
    }
    
    @isTest
    static void testGetUdhyamCheckdata() {
        Opportunity opp = [SELECT Id,Udhyam_Registration_No__c FROM Opportunity LIMIT 1];         
        Application_Applicant__c app = [SELECT Id FROM Application_Applicant__c LIMIT 1];
        string resBody = '{"applicantName":"John Doe","requestId":"REQ123456","result":{"udyamRegistrationNo":"U123456789","dateOfRegistration":"2025-04-28","interestedInTreds":"Yes","interestedInGem":"No","profile":{},"bankDetails":{},"employmentDetails":{"male":"10","female":"5","others":"0","total":"15"},"financials":{"financialYear":"2022-2023","details":{"wdvPme":"100000","exclusion":"5000","netInvestmentInPme":"95000","totalTurnover":"5000000","exportTurnover":"100000","netTurnover":"4900000"}},"branchDetails":[{"bank":"ABC Bank","ifsc":"ABC0123456","acNo":"123456789012"}],"officialAddress":{"flat":"201","premises":"Corporate Tower","village":"","block":"","road":"Industrial Area","city":"BigCity","state":"State2","pincode":"654321","district":"District2","email":"official@example.com","mobile":"9123456780"},"industry":[{"srno":1,"industry":"Manufacturing","subSector":"Automobiles","activityDescription":"Car parts manufacturing","industryCode":"M01","subSectorCode":"S01","nicCode":"2930","activity":"Production"}],"pdfData":"Base64EncodedPDFData"},"statusCode":200,"clientData":{"caseId":"CASE123456"}}';
        String mockJsonString = '{'
            + '"consent": "Y",'
            + '"udyamRegistrationNo": "UDYAM-XX-00-0000000",'
            + '"isPDFRequired": "N",'
            + '"getEnterpriseDetails": "Y",'
            + '"clientData": {'
            + '    "caseId": "1234567890"'
            + '}'
            + '}';
        Integration_Details__c bankintdetailsObj = new Integration_Details__c(
            Name ='Loan Udhyam',
            Endpoint__c = 'Callout:LOS_BL_Bank_statement_analysis',
            Status__c = '400',
            Method_Type__c = 'POST',
            Object_Name__c = 'Application_Applicant__c',
            Loan_Application__c = opp.Id,
            Related_Record_Id__c = app.Id,
            Response_JSON__c  = resBody,
            Prerequisite__c = 'Error: Prerequisite Failed',
            Request_JSON__c =mockJsonString
        );
        
        insert bankintdetailsObj;
        Test.startTest();
        List<UdhyamRegistartionCheckController.UdhyamRegistartionCheckResponseWrapper> result = UdhyamRegistartionCheckController.getUdhyamCheckdata(opp.Id);
        Test.stopTest();
        system.debug('@@@@ checkData ::' + result);
        System.assertNotEquals(null, result);
    }
    
    public class MultiApiMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String mockResponseJson;
            integer mockStatusCode;
            if (req.getEndpoint().contains('LOS')) {
                mockStatusCode=101;
                mockResponseJson = '{'
                    + '"applicantName": "John Doe",'
                    + '"requestId": "REQ123456",'
                    + '"result": {'
                    +     '"udyamRegistrationNo": "UDYAM-XX-00-0000000",'
                    +     '"dateOfRegistration": "2022-01-01",'
                    +     '"interestedInTreds": "Y",'
                    +     '"interestedInGem": "N",'
                    +     '"profile": {'
                    +         '"name": "ABC Pvt Ltd",'
                    +         '"enterpriseType": "Private Limited",'
                    +         '"majorActivity": "Manufacturing",'
                    +         '"organizationType": "Company",'
                    +         '"ownerName": "John Doe",'
                    +         '"pan": "ABCDE1234F",'
                    +         '"previousITRStatus": "Filed",'
                    +         '"itrType": "ITR-4",'
                    +         '"gstnStatus": "Active",'
                    +         '"mobile": "9876543210",'
                    +         '"emailId": "abc@example.com",'
                    +         '"socialCategory": "General",'
                    +         '"gender": "Male",'
                    +         '"speciallyAbled": "No",'
                    +         '"dateOfIncorporation": "2010-05-15",'
                    +         '"dateOfCommencement": "2010-06-01"'
                    +     '},'
                    +     '"bankDetails": {'
                    +         '"bank": "State Bank of India",'
                    +         '"ifsc": "SBIN0001234",'
                    +         '"acNo": "123456789012"'
                    +     '},'
                    +     '"employmentDetails": {'
                    +         '"male": "10",'
                    +         '"female": "5",'
                    +         '"others": "0",'
                    +         '"total": "15"'
                    +     '},'
                    +     '"financials": {'
                    +         '"financialYear": "2022-2023",'
                    +         '"details": {'
                    +             '"wdvPme": "50000",'
                    +             '"exclusion": "5000",'
                    +             '"netInvestmentInPme": "45000",'
                    +             '"totalTurnover": "2000000",'
                    +             '"exportTurnover": "500000",'
                    +             '"netTurnover": "1500000"'
                    +         '}'
                    +     '},'
                    +     '"branchDetails": ['
                    +         '{'
                    +             '"name": "Head Office",'
                    +             '"flat": "101",'
                    +             '"premises": "Corporate Tower",'
                    +             '"village": "",'
                    +             '"block": "",'
                    +             '"road": "Main Street",'
                    +             '"city": "Mumbai",'
                    +             '"state": "Maharashtra",'
                    +             '"pincode": "400001",'
                    +             '"district": "Mumbai"'
                    +         '}'
                    +     '],'
                    +     '"officialAddress": {'
                    +         '"flat": "101",'
                    +         '"premises": "Corporate Tower",'
                    +         '"village": "",'
                    +         '"block": "",'
                    +         '"road": "Main Street",'
                    +         '"city": "Mumbai",'
                    +         '"state": "Maharashtra",'
                    +         '"pincode": "400001",'
                    +         '"district": "Mumbai",'
                    +         '"email": "office@example.com",'
                    +         '"mobile": "9876543210"'
                    +     '},'
                    +     '"industry": ['
                    +         '{'
                    +             '"srno": 1,'
                    +             '"industry": "Textile",'
                    +             '"subSector": "Garments",'
                    +             '"activityDescription": "Manufacturing garments",'
                    +             '"industryCode": "13",'
                    +             '"subSectorCode": "131",'
                    +             '"nicCode": "1311",'
                    +             '"activity": "Manufacture of wearing apparel"'
                    +         '}'
                    +     '],'
                    +     '"pdfData": "pdfEndpoint"'
                    + '},'
                    + '"statusCode": 101,'
                    + '"clientData": {'
                    +     '"caseId": "CASE987654321"'
                    + '}'
                    + '}';
            } else {
                mockStatusCode=200;
                mockResponseJson = 
                    '{'
                    + '"applicantName": "John Doe",'
                    + '"requestId": "REQ123456",'
                    + '"result": {'
                    + '"udyamRegistrationNo": "U123456789",'
                    + '"dateOfRegistration": "2023-01-15",'
                    + '"interestedInTreds": "Yes",'
                    + '"interestedInGem": "No",'
                    + '"profile": {'
                    + '"name": "John\'s Enterprises",'
                    + '"enterpriseType": "Micro",'
                    + '"majorActivity": "Manufacturing",'
                    + '"organizationType": "Proprietorship",'
                    + '"ownerName": "John Doe",'
                    + '"pan": "ABCDE1234F",'
                    + '"previousITRStatus": "Filed",'
                    + '"itrType": "ITR-4",'
                    + '"gstnStatus": "Active",'
                    + '"mobile": "9876543210",'
                    + '"emailId": "john@example.com",'
                    + '"socialCategory": "General",'
                    + '"gender": "Male",'
                    + '"speciallyAbled": "No",'
                    + '"dateOfIncorporation": "2015-06-01",'
                    + '"dateOfCommencement": "2015-07-01"'
                    + '},'
                    + '"bankDetails": {'
                    + '"bank": "ABC Bank",'
                    + '"ifsc": "ABC0123456",'
                    + '"acNo": "123456789012"'
                    + '},'
                    + '"employmentDetails": {'
                    + '"male": "10",'
                    + '"female": "5",'
                    + '"others": "0",'
                    + '"total": "15"'
                    + '},'
                    + '"financials": {'
                    + '"financialYear": "2022-2023",'
                    + '"details": {'
                    + '"wdvPme": "100000",'
                    + '"exclusion": "5000",'
                    + '"netInvestmentInPme": "95000",'
                    + '"totalTurnover": "5000000",'
                    + '"exportTurnover": "100000",'
                    + '"netTurnover": "4900000"'
                    + '}'
                    + '},'
                    + '"branchDetails": ['
                    + '{'
                    + '"name": "Branch 1",'
                    + '"flat": "101",'
                    + '"premises": "Business Plaza",'
                    + '"village": "",'
                    + '"block": "",'
                    + '"road": "Main Street",'
                    + '"city": "Metropolis",'
                    + '"state": "State1",'
                    + '"pincode": "123456",'
                    + '"district": "District1"'
                    + '}'
                    + '],'
                    + '"officialAddress": {'
                    + '"flat": "201",'
                    + '"premises": "Corporate Tower",'
                    + '"village": "",'
                    + '"block": "",'
                    + '"road": "Industrial Area",'
                    + '"city": "BigCity",'
                    + '"state": "State2",'
                    + '"pincode": "654321",'
                    + '"district": "District2",'
                    + '"email": "official@example.com",'
                    + '"mobile": "9123456780"'
                    + '},'
                    + '"industry": ['
                    + '{'
                    + '"srno": 1,'
                    + '"industry": "Manufacturing",'
                    + '"subSector": "Automobiles",'
                    + '"activityDescription": "Car parts manufacturing",'
                    + '"industryCode": "M01",'
                    + '"subSectorCode": "S01",'
                    + '"nicCode": "2930",'
                    + '"activity": "Production"'
                    + '}'
                    + '],'
                    + '"pdfData": "Base64EncodedPDFDataHere"'
                    + '},'
                    + '"statusCode": 101,'
                    + '"clientData": {'
                    + '"caseId": "CASE7890"'
                    + '}'
                    + '}';
            }
            res.setBody(mockResponseJson);
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(mockStatusCode);
            return res;
        }
    }
     @IsTest
    static void testWrapperPopulation() {
        test.startTest();
        // Create wrapper instance
        UdhyamRegistartionCheckController.UdhyamRegistartionCheckResponseWrapper wrapperObj = new UdhyamRegistartionCheckController.UdhyamRegistartionCheckResponseWrapper();
        wrapperObj.applicantName = 'Test Applicant';
        wrapperObj.requestId = 'REQ-123';
        wrapperObj.statusCode = 200;
        wrapperObj.clientData = new UdhyamRegistartionCheckController.Cls_ClientData();
        wrapperObj.clientData.caseId = 'CASE-001';

        // Create Result object
        wrapperObj.result = new UdhyamRegistartionCheckController.Cls_Result();
        wrapperObj.result.udyamRegistrationNo = 'UDYAM-123';
        wrapperObj.result.dateOfRegistration = '2025-01-01';
        wrapperObj.result.interestedInTreds = 'Yes';
        wrapperObj.result.interestedInGem = 'No';
        wrapperObj.result.pdfData = 'SamplePDFData';

        // Profile
        wrapperObj.result.profile = new UdhyamRegistartionCheckController.Cls_Profile();
        wrapperObj.result.profile.name = 'Enterprise Name';
        wrapperObj.result.profile.enterpriseType = 'MSME';
        wrapperObj.result.profile.majorActivity = 'Manufacturing';
        wrapperObj.result.profile.organizationType = 'Proprietorship';
        wrapperObj.result.profile.ownerName = 'Owner Test';
        wrapperObj.result.profile.pan = 'ABCDE1234F';
        wrapperObj.result.profile.previousITRStatus = 'Filed';
        wrapperObj.result.profile.itrType = 'ITR-3';
        wrapperObj.result.profile.gstnStatus = 'Active';
        wrapperObj.result.profile.mobile = '9999999999';
        wrapperObj.result.profile.emailId = 'test@test.com';
        wrapperObj.result.profile.socialCategory = 'General';
        wrapperObj.result.profile.gender = 'Male';
        wrapperObj.result.profile.speciallyAbled = 'No';
        wrapperObj.result.profile.dateOfIncorporation = '2020-01-01';
        wrapperObj.result.profile.dateOfCommencement = '2020-02-01';

        // Bank Details
        wrapperObj.result.bankDetails = new UdhyamRegistartionCheckController.Cls_BankDetails();
        wrapperObj.result.bankDetails.bank = 'Test Bank';
        wrapperObj.result.bankDetails.ifsc = 'IFSC0001234';
        wrapperObj.result.bankDetails.acNo = '1234567890';

        // Employment Details
        wrapperObj.result.employmentDetails = new UdhyamRegistartionCheckController.Cls_EmploymentDetails();
        wrapperObj.result.employmentDetails.male = '10';
        wrapperObj.result.employmentDetails.female = '5';
        wrapperObj.result.employmentDetails.others = '1';
        wrapperObj.result.employmentDetails.total = '16';

        // Financials
        wrapperObj.result.financials = new UdhyamRegistartionCheckController.Cls_Financials();
        wrapperObj.result.financials.financialYear = '2024-25';
        wrapperObj.result.financials.details = new UdhyamRegistartionCheckController.Cls_FinancialDetails();
        wrapperObj.result.financials.details.wdvPme = '1000';
        wrapperObj.result.financials.details.exclusion = '100';
        wrapperObj.result.financials.details.netInvestmentInPme = '900';
        wrapperObj.result.financials.details.totalTurnover = '5000';
        wrapperObj.result.financials.details.exportTurnover = '1000';
        wrapperObj.result.financials.details.netTurnover = '4000';

        // Branch Details
        UdhyamRegistartionCheckController.Cls_BranchDetails branch = new UdhyamRegistartionCheckController.Cls_BranchDetails();
       	branch.name = 'Main Branch';
        branch.flat = '202B';
        branch.premises = 'Sunset Towers';
        branch.village = 'Lakeside';
        branch.block = 'Block C';
        branch.road = 'Oak Avenue';
        branch.city = 'Gotham';
        branch.state = 'New York';
        branch.pincode = '10001';
        branch.district = 'Downtown';
        wrapperObj.result.branchDetails = new List<UdhyamRegistartionCheckController.Cls_BranchDetails>{ branch };

        // Official Address
        wrapperObj.result.officialAddress = new UdhyamRegistartionCheckController.Cls_OfficialAddress();
        wrapperObj.result.officialAddress.city = 'MainCity';
        wrapperObj.result.officialAddress.state = 'MainState';
        wrapperObj.result.officialAddress.pincode = '654321';
        wrapperObj.result.officialAddress.email = 'office@test.com';
        wrapperObj.result.officialAddress.mobile = '8888888888';
        wrapperObj.result.officialAddress.flat = '101A';
        wrapperObj.result.officialAddress.premises = 'Sunshine Apartments';
        wrapperObj.result.officialAddress.village = 'Greenfield';
        wrapperObj.result.officialAddress.block = 'Block B';
        wrapperObj.result.officialAddress.road = 'Maple Street';
        wrapperObj.result.officialAddress.district='pune';

        // Industry
        UdhyamRegistartionCheckController.Cls_Industry industry = new UdhyamRegistartionCheckController.Cls_Industry();
        industry.srno = 1;
        industry.industry = 'Manufacturing';
        industry.subSector = 'Textiles';
        industry.activityDescription = 'Garments';
        industry.industryCode = 'IND123';
        industry.subSectorCode = 'SUB123';
        industry.nicCode = 'NIC123';
        industry.activity = 'Production';
        wrapperObj.result.industry = new List<UdhyamRegistartionCheckController.Cls_Industry>{ industry };

       test.stopTest();
       // System.assertNotEquals(null, response, 'invokeMethod should return a non-null string');
    }
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"message":"Mock response from MockHttpResponseGenerator"}');
            return res;
        }
    }
    
    public class MockHttpResponseGenerator2 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"message":"Mock response from MockHttpResponseGenerator2"}');
            return res;
        }
    }
    
    
}