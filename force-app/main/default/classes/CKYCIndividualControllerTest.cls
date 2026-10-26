@isTest
public class CKYCIndividualControllerTest {
    
   /*  @isTest
    static void testInitiateAPIRequestSuccess() {
        
         Trigger_Settings__c settings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger__c = true 
        );
        insert settings;
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        opp.Product__c = 'Affordable Home Loan';
        // opp.Branch__c = bm.Id;
        update opp;
        
        // Create Applicant
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
        
        Account customerAcc = FITestDataFactory.createAccount('TestAccount','Customer');
        Customer_Address__c customerAdd = new Customer_Address__c(
            Address_Type__c = 'Permanent',
            Address_Source__c = 'Manual',
            Customer__c = customerAcc.Id
        );
        
        insert customerAdd;
        
        Applicant_Address__c address = new Applicant_Address__c(
            Loan_Application__c = opp.Id,
            Applicant__c = applicant.Id,
            Screening_Status__c = 'Added to sampling queue',
            FCU_Initiated__c = false,
            Customer_Address__c = customerAdd.Id,
            Address_Type__c = 'Permanent',
            Address_Line_1__c = 'Old Line 1'           
        );
        insert address; 
        
          Integration_Settings__c intDetails1 = new Integration_Settings__c(
        Name = 'Get Token',
        Client_Id__c = 'testClientId',
        Cookie__c = 'testCookie',
        Client_Secret__c = 'testClientSecret',
        Endpoint__c = 'https://test.token.com',
        Content_Type__c = 'application/json',
        Authorization__c = 'Bearer testAuthorization',
        Request_Method__c = 'POST'
    );
    insert intDetails1;
    
        Integration_Settings__c intDetails2 = new Integration_Settings__c(
        Name = 'intSettingName',
        Client_Id__c = 'testClientId',
        Cookie__c = 'testCookie',
        Client_Secret__c = 'testClientSecret',
        Endpoint__c = 'https://test.token.com',
        Content_Type__c = 'application/json',
        Authorization__c = 'Bearer testAuthorization',
        Request_Method__c = 'POST'
    );
    insert intDetails2;
    
    Integration_Settings__c setting = new Integration_Settings__c(
        Name = 'Loan Applicant CKYC',
        Client_Id__c = 'testClientId',
         Cookie__c = 'testCookie',
        Client_Secret__c = 'testSecret',
        Endpoint__c = 'https://test.endpoint.com',
        Content_Type__c = 'application/json',
        Request_Method__c = 'POST'
    );
    insert setting;
    
        
        Test.startTest();

        // Mock callout
        Test.setMock(HttpCalloutMock.class, new FSSAIAPIMock());

        // Input map
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id ,
            'applicantId' => applicant.Id,
            'processName' => 'Loan Applicant CKYC',
              'dob' => '2007-04-23',
            'registrationNumber' => 'REG123456'
        };
            
            try {
                // Call method
                String result = CKYCIndividualController.initiateAPIRequest(inputMap);
            } catch(Exception e) {
                System.debug(e.getStackTraceString());
            }
        Test.stopTest();

       // System.assertEquals('success', result, 'Expected result to be success');
    }
   
    
       @isTest
    static void testInitiateAPIRequestSuccessElse() {
        
         Trigger_Settings__c settings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger__c = true 
        );
        insert settings;
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        opp.Product__c = 'Affordable Home Loan';
        // opp.Branch__c = bm.Id;
        update opp;
        
        // Create Applicant
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
         applicant.Loan_Application__c = opp.Id;
        applicant.PAN_Number__c = 'AGUPF2300R';
        applicant.Customer_Type__c = 'Individual';
        
        update applicant;
    
     Trigger_Settings__c settings1 = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = true 
        );
        insert settings1;
    
     City_Master__c city = new City_Master__c(Name = 'Gudivada',City_Code__c = 'C01',Country__c='IN',State__c='AP');
        
        insert city;
        
        Pincode_Master__c pinCode = new Pincode_Master__c(City__c = city.Id, Name='521301');
        insert pinCode;
    
        Applicant_Address__c appAdd = new Applicant_Address__c(
        Applicant__c = applicant.Id,
        Address_Type__c = 'Current',
        PinCode__c = pinCode.Id, 
        Address_Source__c = 'Manual'
    );
    
    insert appAdd;
       
     Application_Applicant__c primary1 = new Application_Applicant__c(
        Loan_Application__c = opp.Id,
        First_Name__c = 'John',
        Last_Name__c = 'Doe',
        PAN_Number__c = 'AGUPF2300R',
        Applicant_Type__c = 'Co Applicant'
      
    );
   insert primary1;
        
          Triangulation_Data__c triData = new Triangulation_Data__c(
            Loan_Application__c = opp.Id,
            Application_Applicant__c = applicant.Id,
          
            Document_Type__c = 'Voter Front',
              Source_Type__c ='CKYC'
        );
        insert triData;
    
        Applicant_Address__c appAdd1 = new Applicant_Address__c(
        Applicant__c = primary1.Id,
        Address_Type__c = 'Current',
             PinCode__c = pinCode.Id, 
        Address_Source__c = 'Manual'
    );
    
    insert appAdd1;
        
          Integration_Settings__c intDetails1 = new Integration_Settings__c(
        Name = 'Get Token',
        Client_Id__c = 'testClientId',
        Cookie__c = 'testCookie',
        Client_Secret__c = 'testClientSecret',
        Endpoint__c = 'https://test.token.com',
        Content_Type__c = 'application/json',
        Authorization__c = 'Bearer testAuthorization',
        Request_Method__c = 'POST'
    );
    insert intDetails1;
    
        Integration_Settings__c intDetails2 = new Integration_Settings__c(
        Name = 'intSettingName',
        Client_Id__c = 'testClientId',
        Cookie__c = 'testCookie',
        Client_Secret__c = 'testClientSecret',
        Endpoint__c = 'https://test.token.com',
        Content_Type__c = 'application/json',
        Authorization__c = 'Bearer testAuthorization',
        Request_Method__c = 'POST'
    );
    insert intDetails2;
    
    Integration_Settings__c setting = new Integration_Settings__c(
        Name = 'Loan Applicant CKYC',
        Client_Id__c = 'testClientId',
         Cookie__c = 'testCookie',
        Client_Secret__c = 'testSecret',
        Endpoint__c = 'https://test.endpoint.com',
        Content_Type__c = 'application/json',
        Request_Method__c = 'POST'
    );
    insert setting;
        
        
          Integration_Details__c idc = new Integration_Details__c(
        Loan_Application__c = opp.Id,
        Name = 'Loan Applicant CKYC',
        Endpoint__c = 'Callout:LOS_BL_CKYC_Individual',
        Status__c = '200'
    );
    insert idc;
    
        
        Test.startTest();

        // Mock callout
        Test.setMock(HttpCalloutMock.class, new FSSAIAPIMock());

        // Input map
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id ,
            'applicantId' => applicant.Id,
            'processName' => 'Loan Applicant CKYC',
              'dob' => '2007-04-23',
            'registrationNumber' => 'REG123456',
                 'panNum' => 'AGUPF2300R'
        };
        try{
            String result = CKYCIndividualController.initiateAPIRequest(inputMap);
        }
        catch(Exception e){
            System.debug(e.getStackTraceString());
        }
        Test.stopTest();
   }
    
        @isTest
    static void testInitiateAPIRequestSuccessElseElse() {
        
         Trigger_Settings__c settings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger__c = true 
        );
        insert settings;
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        opp.Product__c = 'Affordable Home Loan';
        // opp.Branch__c = bm.Id;
        update opp;
        
        // Create Applicant
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
         applicant.Loan_Application__c = opp.Id;
        applicant.PAN_Number__c = 'AGUPF2300R';
        applicant.Customer_Type__c = 'Individual';
        
        update applicant;
    
     Trigger_Settings__c settings1 = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = true 
        );
        insert settings1;
    
     City_Master__c city = new City_Master__c(Name = 'Gudivada',City_Code__c = 'C01',Country__c='IN',State__c='AP');
        
        insert city;
        
        Pincode_Master__c pinCode = new Pincode_Master__c(City__c = city.Id, Name='521301');
        insert pinCode;
    
        Applicant_Address__c appAdd = new Applicant_Address__c(
        Applicant__c = applicant.Id,
        Address_Type__c = 'Current',
        PinCode__c = pinCode.Id, 
        Address_Source__c = 'Manual'
    );
    
    insert appAdd;
       
     Application_Applicant__c primary1 = new Application_Applicant__c(
        Loan_Application__c = opp.Id,
        First_Name__c = 'John',
        Last_Name__c = 'Doe',
        PAN_Number__c = 'AGUPF2300R',
        Applicant_Type__c = 'Co Applicant'
      
    );
   insert primary1;
        
          Triangulation_Data__c triData = new Triangulation_Data__c(
            Loan_Application__c = opp.Id,
            Application_Applicant__c = applicant.Id,
          
            Document_Type__c = 'Voter Front',
              Source_Type__c ='CKYC'
        );
       // insert triData;
    
        Applicant_Address__c appAdd1 = new Applicant_Address__c(
        Applicant__c = primary1.Id,
        Address_Type__c = 'Current',
             PinCode__c = pinCode.Id, 
        Address_Source__c = 'Manual'
    );
    
    insert appAdd1;
        
          Integration_Settings__c intDetails1 = new Integration_Settings__c(
        Name = 'Get Token',
        Client_Id__c = 'testClientId',
        Cookie__c = 'testCookie',
        Client_Secret__c = 'testClientSecret',
        Endpoint__c = 'https://test.token.com',
        Content_Type__c = 'application/json',
        Authorization__c = 'Bearer testAuthorization',
        Request_Method__c = 'POST'
    );
    insert intDetails1;
    
        Integration_Settings__c intDetails2 = new Integration_Settings__c(
        Name = 'intSettingName',
        Client_Id__c = 'testClientId',
        Cookie__c = 'testCookie',
        Client_Secret__c = 'testClientSecret',
        Endpoint__c = 'https://test.token.com',
        Content_Type__c = 'application/json',
        Authorization__c = 'Bearer testAuthorization',
        Request_Method__c = 'POST'
    );
    insert intDetails2;
    
    Integration_Settings__c setting = new Integration_Settings__c(
        Name = 'Loan Applicant CKYC',
        Client_Id__c = 'testClientId',
         Cookie__c = 'testCookie',
        Client_Secret__c = 'testSecret',
        Endpoint__c = 'https://test.endpoint.com',
        Content_Type__c = 'application/json',
        Request_Method__c = 'POST'
    );
    insert setting;
        
        
          Integration_Details__c idc = new Integration_Details__c(
        Loan_Application__c = opp.Id,
        Name = 'Loan Applicant CKYC',
        Endpoint__c = 'Callout:LOS_BL_CKYC_Individual',
        Status__c = '200'
    );
    insert idc;
    
        
        Test.startTest();

        // Mock callout
        Test.setMock(HttpCalloutMock.class, new FSSAIAPIMock());

        // Input map
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id ,
            'applicantId' => applicant.Id,
            'processName' => 'Loan Applicant CKYC',
              'dob' => '2007-04-23',
            'registrationNumber' => 'REG123456',
                 'panNum' => 'AGUPF2300R'
        };

		try{
             String result = CKYCIndividualController.initiateAPIRequest(inputMap);
        }
        catch(Exception e){
            System.debug(e.getStackTraceString());
        }
        
        Test.stopTest();
   }
   
  
   
      // Successful Callout Mock
    public class FSSAIAPIMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"PID_DATA":{"RECORD_COUNT_DETAILS":{"UPDATE_COUNT":"0","DOWNLOAD_COUNT":11},"RELATED_PERSON_DETAILS":"","PERSONAL_DETAILS":{"CORRES_COUNTRY":"IN","MAIDEN_MNAME":"","PERM_LINE3":"","LNAME":"Thorat","PERM_DIST":"Mumbai","REMARKS":"","EMAIL":"","DEC_PLACE":"Mumbai","CORRES_POA":"01","KYC_EMPCODE":"G124265","PERM_COUNTRY":"IN","PERM_POA":"01","CKYC_REFERENCE_ID":"INAGQJ62576883","MOTHER_MNAME":"","MAIDEN_LNAME":"","DOB":"01-01-1984","KYC_DESIGNATION":"SM","MOTHER_PREFIX":"Mrs","RESI_STD_CODE":"","PERM_CORRES_SAMEFLAG":"Y","PERM_LINE2":"CVD","FULLNAME":"Mr Rohan Laxman Thorat","PERM_LINE1":"ABC","FATHER_PREFIX":"","OFF_TEL_NUM":"","CORRES_PIN":"400015","FATHER_FNAME":"","KYC_DATE":"06-01-2025","DOC_SUB":"01","CORRES_CITY":"mumbai","CONSTI_TYPE":"01","MAIDEN_FULLNAME":"","MOB_CODE":"","FNAME":"Rohan","MOTHER_FNAME":"Sheela","NUM_RELATED":"0","FATHERSPOUSE_FLAG":"","PREFIX":"Mr","ORG_CODE":"IN10265","MNAME":"Laxman","RESI_TEL_NUM":"","NUM_IMAGES":"3","KYC_NAME":"SB","FATHER_FULLNAME":"","PERM_CITY":"mumbai","GENDER":"M","MOB_NUM":"8850513345","OFF_STD_CODE":"","CORRES_LINE3":"","CORRES_LINE2":"CVD","FATHER_MNAME":"","CORRES_LINE1":"ABC","MOTHER_LNAME":"","CORRES_STATE":"MH","KYC_BRANCH":"thane","PERM_PIN":"400015","ORG_NAME":"Godrej Finance Limited","DEC_DATE":"06-01-2025","FATHER_LNAME":"","MOTHER_FULLNAME":"Mrs Sheela","CKYC_NO":"50035986410749","NUM_IDENTITY":"1","CORRES_DIST":"Mumbai","PERM_STATE":"MH","MAIDEN_PREFIX":"","MAIDEN_FNAME":"","ACC_TYPE":"01","PAN":"VZWPT2211A"},"IDENTITY_DETAILS":{"IDENTITY":{"IDENT_NUM":"XXXXXX1987","IDENT_TYPE":"E","SEQUENCE_NO":"1","IDVER_STATUS":"02"}},"IMAGE_DETAILS":{"IMAGE":[{"IMAGE_TYPE":"jpg","GLOBAL_FLAG":"","IMAGE_CODE":"02","IMAGE_DATA":"","SEQUENCE_NO":"1","BRANCH_CODE":1001}]}}}');
            return res;
        }
    }

    // Error Code Mock
    public class ErrorCodeMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"status_code":999}');
            return res;
        }
    }
            @isTest
    static void testInitiateAPIRequestSuccess2ndelse() {
        
         Trigger_Settings__c settings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            Opportunity_Trigger__c = true 
        );
        insert settings;
        
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        
        Opportunity opp = FITestDataFactory.createOpportunity(customer);
        opp.Product__c = 'Affordable Home Loan';
        // opp.Branch__c = bm.Id;
        update opp;
        
        // Create Applicant
        Application_Applicant__c applicant = FITestDataFactory.createApplicant(opp);
         applicant.Loan_Application__c = opp.Id;
        applicant.PAN_Number__c = 'AGUPF2300R';
        applicant.Customer_Type__c = 'Individual';
        
        update applicant;
    
     Trigger_Settings__c settings1 = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = true 
        );
        insert settings1;
    
     City_Master__c city = new City_Master__c(Name = 'Gudivada',City_Code__c = 'C01',Country__c='IN',State__c='AP');
        
        insert city;
        
        Pincode_Master__c pinCode = new Pincode_Master__c(City__c = city.Id, Name='521301');
        insert pinCode;
    
        Applicant_Address__c appAdd = new Applicant_Address__c(
        Applicant__c = applicant.Id,
        Address_Type__c = 'Current',
        PinCode__c = pinCode.Id, 
        Address_Source__c = 'Manual'
    );
    
    insert appAdd;
               Applicant_Address__c appAdd2 = new Applicant_Address__c(
        Applicant__c = applicant.Id,
        Address_Type__c = 'Permanent',
        PinCode__c = pinCode.Id, 
        Address_Source__c = 'Manual'
    );
    
    insert appAdd2;
     Application_Applicant__c primary1 = new Application_Applicant__c(
        Loan_Application__c = opp.Id,
        First_Name__c = 'John',
        Last_Name__c = 'Doe',
        PAN_Number__c = 'AGUPF2300R',
        Applicant_Type__c = 'Co Applicant'
      
    );
   insert primary1;
        
          Triangulation_Data__c triData = new Triangulation_Data__c(
            Loan_Application__c = opp.Id,
            Application_Applicant__c = applicant.Id,
          
            Document_Type__c = 'Voter Front',
              Source_Type__c ='CKYC'
        );
       // insert triData;
    
        Applicant_Address__c appAdd1 = new Applicant_Address__c(
        Applicant__c = primary1.Id,
        Address_Type__c = 'Current',
             PinCode__c = pinCode.Id, 
        Address_Source__c = 'Manual'
    );
    
    insert appAdd1;
        
          Integration_Settings__c intDetails1 = new Integration_Settings__c(
        Name = 'Get Token',
        Client_Id__c = 'testClientId',
        Cookie__c = 'testCookie',
        Client_Secret__c = 'testClientSecret',
        Endpoint__c = 'https://test.token.com',
        Content_Type__c = 'application/json',
        Authorization__c = 'Bearer testAuthorization',
        Request_Method__c = 'POST'
    );
    insert intDetails1;
    
        Integration_Settings__c intDetails2 = new Integration_Settings__c(
        Name = 'intSettingName',
        Client_Id__c = 'testClientId',
        Cookie__c = 'testCookie',
        Client_Secret__c = 'testClientSecret',
        Endpoint__c = 'https://test.token.com',
        Content_Type__c = 'application/json',
        Authorization__c = 'Bearer testAuthorization',
        Request_Method__c = 'POST'
    );
    insert intDetails2;
    
    Integration_Settings__c setting = new Integration_Settings__c(
        Name = 'Loan Applicant CKYC',
        Client_Id__c = 'testClientId',
         Cookie__c = 'testCookie',
        Client_Secret__c = 'testSecret',
        Endpoint__c = 'https://test.endpoint.com',
        Content_Type__c = 'application/json',
        Request_Method__c = 'POST'
    );
    insert setting;
        
        
          Integration_Details__c idc = new Integration_Details__c(
        Loan_Application__c = opp.Id,
        Name = 'Loan Applicant CKYC',
        Endpoint__c = 'Callout:LOS_BL_CKYC_Individual',
        Status__c = '200'
    );
    insert idc;
    
        
        Test.startTest();

        // Mock callout
        Test.setMock(HttpCalloutMock.class, new FSSAIAPIMock());

        // Input map
        Map<String, String> inputMap = new Map<String, String>{
            'loanId' => opp.Id ,
            'applicantId' => applicant.Id,
            'processName' => 'Loan Applicant CKYC',
              'dob' => '2007-04-23',
            'registrationNumber' => 'REG123456',
                 'panNum' => 'AGUPF2300R'
        };

		try{
             String result = CKYCIndividualController.initiateAPIRequest(inputMap);
        }
        catch(Exception e){
            System.debug(e.getStackTraceString());
        }
        
        Test.stopTest();
   }*/
   
    
}