@IsTest
private class LeadManagementAPIRESTTest {

    /* ===================== TEST SETUP ===================== */
    @TestSetup
    static void setupData() {

        insert new Trigger_Settings__c(
            Name = 'Trigger Settings',
            Lead_Trigger__c = true,
            City_Master_Trigger__c = true
        );

        City_Master__c city = new City_Master__c(
            Name = 'Gudivada',
            City_Code__c = 'C01',
            Country__c = 'IN',
            State__c = 'AP'
        );
        insert city;

        Pincode_Master__c pinServiceable = new Pincode_Master__c(
            City__c = city.Id,
            Name = '12345',
            Serviceable_For_Business_Loan__c = true
        );
        insert pinServiceable;

        Pincode_Master__c pinNotServiceable = new Pincode_Master__c(
            City__c = city.Id,
            Name = '99999',
            Serviceable_For_Business_Loan__c = false
        );
        insert pinNotServiceable;

        insert new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'Open',
            Product__c = 'Affordable Home Loan',
            MobilePhone = '9876543210',
            Email = 'test@example.com',
            Customer_Type__c = 'Individual',
            Pincode__c = pinServiceable.Id
        );
    }

    /* ===================== NULL REQUEST ===================== */
   /* @IsTest
    static void testNullRequest() {
        RestContext.request = null;

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.manageLead();
        Test.stopTest();

        System.assertNotEquals(null, res);
    } */

    /* ===================== GET LEAD DETAILS ===================== */
    @IsTest
    static void testGetLeadDetails_Success() {

        Lead l = [SELECT Lead_Number__c FROM Lead LIMIT 1];
        l.leadSource = 'Missed Call';
        update l;

        LeadManagementAPIREST.GetRequestWrapper body =
            new LeadManagementAPIREST.GetRequestWrapper();
        body.apiSource = 'TEST';
        body.leadNumber = l.Lead_Number__c;

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'GET';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(body));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.getLeadDetailsByLeadNumber();
        Test.stopTest();

        System.assertEquals(1, res.leadRecord.size());
    }

    @IsTest
    static void testGetLeadDetails_Success1() {

        Lead l = [SELECT Lead_Number__c FROM Lead LIMIT 1];
        l.leadSource = 'Missed Call';
        update l;

        LeadManagementAPIREST.GetRequestWrapper body =
            new LeadManagementAPIREST.GetRequestWrapper();
        body.apiSource = 'TEST';
        body.leadNumber = '';

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'GET';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(body));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.getLeadDetailsByLeadNumber();
        Test.stopTest();

    }
    @IsTest
    static void testGetLeadDetails_MissingBody() {

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'GET';
        RestContext.request.requestBody = Blob.valueOf('');

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.getLeadDetailsByLeadNumber();
        Test.stopTest();

        System.assertNotEquals(null, res.errorMessage);
    }
    
    @IsTest
    static void testGetLeadDetails_MissingApiSource() {
			
        LeadManagementAPIREST.LeadWrapper lw =
            new LeadManagementAPIREST.LeadWrapper();
        lw.customerType = 'Individual';
        lw.firstName = 'John';
        lw.mobileNumber = '9876543222';
        lw.pinCode = '12345';
        lw.product = 'Business Loan';
        lw.leadSource = 'Missed Call';

        LeadManagementAPIREST.RequestWrapper req =
            new LeadManagementAPIREST.RequestWrapper();
        req.apiAction = 'MANAGELEAD';
        req.apiSource = null;
        req.leadData = new List<LeadManagementAPIREST.LeadWrapper>{ lw };
        
        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'GET';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.getLeadDetailsByLeadNumber();
        Test.stopTest();

        System.assertNotEquals(null, res.errorMessage);
    }

    /* ===================== MANAGE LEAD ===================== */
    @IsTest
    static void testManageLead_Success() {

        LeadManagementAPIREST.LeadWrapper lw =
            new LeadManagementAPIREST.LeadWrapper();
        lw.customerType = 'Individual';
        lw.firstName = 'John';
        lw.mobileNumber = '9876543222';
        lw.pinCode = '12345';
        lw.product = 'Business Loan';
        lw.leadSource = 'Missed Call';
        lw.statusCode = 210;

        LeadManagementAPIREST.RequestWrapper req =
            new LeadManagementAPIREST.RequestWrapper();
        req.apiAction = 'MANAGELEAD';
        req.apiSource = 'TEST';
        req.leadData = new List<LeadManagementAPIREST.LeadWrapper>{ lw };

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.manageLead();
        Test.stopTest();

        System.assert(res.leadData.size() > 0);
    }
    
    @IsTest
    static void testManageLead_Success1() {

        LeadManagementAPIREST.LeadWrapper lw =
            new LeadManagementAPIREST.LeadWrapper();
        lw.customerType = 'Individual';
        lw.firstName = 'John';
        lw.mobileNumber = '9876543225';
        lw.pinCode = '12345';
        lw.product = 'Business Loan';
        lw.leadSource = 'Mobile Call';

        LeadManagementAPIREST.RequestWrapper req =
            new LeadManagementAPIREST.RequestWrapper();
        req.apiAction = 'CHECKPINCODESERVICEABILITY';
        req.apiSource = 'TEST';
        req.leadData = new List<LeadManagementAPIREST.LeadWrapper>{ lw };

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.manageLead();
        Test.stopTest();

        System.assert(res.leadData.size() > 0);
    }
    
    @IsTest
    static void testManageLead_Success2() {

        LeadManagementAPIREST.LeadWrapper lw =
            new LeadManagementAPIREST.LeadWrapper();
        lw.customerType = '';
        lw.firstName = 'John';
        lw.mobileNumber = '9876543225';
        lw.pinCode = '12345';
        lw.product = 'Business Loan';
        lw.leadSource = 'Missed Call';
        lw.statusCode = 210;

        LeadManagementAPIREST.RequestWrapper req =
            new LeadManagementAPIREST.RequestWrapper();
        req.apiAction = 'MANAGELEAD';
        req.apiSource = 'TEST';
        req.leadData = new List<LeadManagementAPIREST.LeadWrapper>{ lw };

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.manageLead();
        Test.stopTest();

        System.assert(res.leadData.size() > 0);
    }
	 @IsTest
    static void testManageLead_Success3() {

        LeadManagementAPIREST.LeadWrapper lw =
            new LeadManagementAPIREST.LeadWrapper();
        lw.customerType = 'INDIVIDUAL';
        lw.firstName = '1234';
        lw.mobileNumber = '9876543225';
        lw.pinCode = '12345';
        lw.product = 'Business Loan';
        lw.leadSource = 'Mobile Call';
        lw.statusCode = 210;

        LeadManagementAPIREST.RequestWrapper req =
            new LeadManagementAPIREST.RequestWrapper();
        req.apiAction = 'MANAGELEAD';
        req.apiSource = 'TEST';
        req.leadData = new List<LeadManagementAPIREST.LeadWrapper>{ lw };

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.manageLead();
        Test.stopTest();

        System.assert(res.leadData.size() > 0);
    }
    
    @IsTest
    static void testManageLead_Success4() {

        LeadManagementAPIREST.LeadWrapper lw =
            new LeadManagementAPIREST.LeadWrapper();
        lw.customerType = 'INDIVIDUAL';
        lw.firstName = 'John';
        lw.lastName = 'Sina';
        lw.mobileNumber = '9876543225';
        lw.pinCode = '12345';
        lw.product = 'Business Loan';
        lw.leadSource = 'Mobile Call';
        lw.statusCode = 210;

        LeadManagementAPIREST.RequestWrapper req =
            new LeadManagementAPIREST.RequestWrapper();
        req.apiAction = 'MANAGELEAD';
        req.apiSource = 'TEST';
        req.leadData = new List<LeadManagementAPIREST.LeadWrapper>{ lw };

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.manageLead();
        Test.stopTest();

        System.assert(res.leadData.size() > 0);
    }
     @IsTest
    static void testManageLead_Success5() {

        LeadManagementAPIREST.LeadWrapper lw =
            new LeadManagementAPIREST.LeadWrapper();
        lw.customerType = 'NON INDIVIDUAL';
        lw.company = '';
        lw.firstName = 'John';
        lw.lastName = 'Sina';
        lw.mobileNumber = '9876543225';
        lw.pinCode = '12345';
        lw.product = 'Business Loan';
        lw.leadSource = 'Mobile Call';

        LeadManagementAPIREST.RequestWrapper req =
            new LeadManagementAPIREST.RequestWrapper();
        req.apiAction = 'MANAGELEAD';
        req.apiSource = 'TEST';
        req.leadData = new List<LeadManagementAPIREST.LeadWrapper>{ lw };

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.manageLead();
        Test.stopTest();

        System.assert(res.leadData.size() > 0);
    }
    @IsTest
    static void testManageLead_Success6() {

        LeadManagementAPIREST.LeadWrapper lw =
            new LeadManagementAPIREST.LeadWrapper();
        lw.customerType = 'NON INDIVIDUAL';
        lw.company = 'ABC';
        lw.firstName = 'John';
        lw.lastName = 'Sina';
        lw.mobileNumber = '9876543225';
        lw.pinCode = '12345';
        lw.product = 'Business Loan';
        lw.leadSource = 'Mobile Call';
        lw.statusCode = 210;

        LeadManagementAPIREST.RequestWrapper req =
            new LeadManagementAPIREST.RequestWrapper();
        req.apiAction = 'MANAGELEAD';
        req.apiSource = 'TEST';
        req.leadData = new List<LeadManagementAPIREST.LeadWrapper>{ lw };

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.manageLead();
        Test.stopTest();

        System.assert(res.leadData.size() > 0);
    }
    @IsTest
    static void testManageLead_MissingApiAction() {

        LeadManagementAPIREST.LeadWrapper lw =
            new LeadManagementAPIREST.LeadWrapper();
        lw.customerType = 'Individual';
        lw.firstName = 'John';
        lw.mobileNumber = '9876543252';
        lw.pinCode = '123425';
        lw.product = 'Business Loan';
        lw.leadSource = 'Missed Call';
        lw.statusCode = 210;

        LeadManagementAPIREST.RequestWrapper req =
            new LeadManagementAPIREST.RequestWrapper();
        req.apiAction = 'MANAGELEAD';
        req.apiSource = null;
        req.leadData = new List<LeadManagementAPIREST.LeadWrapper>{ lw };

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.manageLead();
        Test.stopTest();
    }

   /* @IsTest
    static void testManageLead_InvalidApiAction() {

        LeadManagementAPIREST.RequestWrapper req =
            new LeadManagementAPIREST.RequestWrapper();
        req.apiAction = 'INVALID_ACTION';
        req.apiSource = 'TEST';

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.manageLead();
        Test.stopTest();

        System.assertNotEquals(null, res.errorMessage);
    } */

    @IsTest
    static void testManageLead_EmptyLeadData() {

        LeadManagementAPIREST.RequestWrapper req =
            new LeadManagementAPIREST.RequestWrapper();
        req.apiAction = '';
        req.apiSource = 'TEST';
        req.leadData = new List<LeadManagementAPIREST.LeadWrapper>();

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.manageLead();
        Test.stopTest();

        System.assertNotEquals(null, res.errorMessage);
    }

    /* ===================== MULTIPLE LEADS ===================== */
    @IsTest
    static void testManageLead_MultipleLeads() {

        List<LeadManagementAPIREST.LeadWrapper> listData =
            new List<LeadManagementAPIREST.LeadWrapper>();

        for (Integer i = 0; i < 2; i++) {
            LeadManagementAPIREST.LeadWrapper lw =
                new LeadManagementAPIREST.LeadWrapper();
            lw.customerType = null;
            lw.mobileNumber = '98765432' + (30 + i);
            lw.pinCode = '12345';
            lw.product = 'Business Loan';
            lw.leadSource = 'Missed Call';
            listData.add(lw);
        }

        LeadManagementAPIREST.RequestWrapper req =
            new LeadManagementAPIREST.RequestWrapper();
        req.apiAction = 'CHECKPINCODESERVICEABILITY';
        req.apiSource = 'TEST';
        req.leadData = listData;

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.manageLead();
        Test.stopTest();

        System.assertEquals(2, res.leadData.size());
    }

    /* ===================== CHECK LEAD DEDUPE ===================== */
    @IsTest
    static void testCheckLeadDedupe_Found() {

        Lead existing = [SELECT MobilePhone FROM Lead LIMIT 1];

        LeadManagementAPIREST.LeadWrapper lw =
            new LeadManagementAPIREST.LeadWrapper();
        lw.customerType = 'Individual';
        lw.mobileNumber = existing.MobilePhone;

        LeadManagementAPIREST.RequestWrapper req =
            new LeadManagementAPIREST.RequestWrapper();
        req.apiAction = 'CHECKLEADDEDUPE';
        req.apiSource = 'TEST';
        req.leadData = new List<LeadManagementAPIREST.LeadWrapper>{ lw };

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.manageLead();
        Test.stopTest();

        System.assertEquals(1, res.leadData.size());
    }
     @IsTest
    static void testCheckLeadDedupe_Found1() {

        Lead existing = [SELECT MobilePhone FROM Lead LIMIT 1];

        LeadManagementAPIREST.LeadWrapper lw =
            new LeadManagementAPIREST.LeadWrapper();
        lw.customerType = 'Individual';
        lw.mobileNumber = '894599';

        LeadManagementAPIREST.RequestWrapper req =
            new LeadManagementAPIREST.RequestWrapper();
        req.apiAction = 'CHECKLEADDEDUPE';
        req.apiSource = 'TEST';
        req.leadData = new List<LeadManagementAPIREST.LeadWrapper>{ lw };

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.manageLead();
        Test.stopTest();

        System.assertEquals(1, res.leadData.size());
    }

    @IsTest
    static void testCheckLeadDedupe_NotFound() {

        LeadManagementAPIREST.LeadWrapper lw =
            new LeadManagementAPIREST.LeadWrapper();
        lw.customerType = 'Individual';
        lw.mobileNumber = '0000000000';

        LeadManagementAPIREST.RequestWrapper req =
            new LeadManagementAPIREST.RequestWrapper();
        req.apiAction = 'CHECKLEADDEDUPE';
        req.apiSource = 'TEST';
        req.leadData = new List<LeadManagementAPIREST.LeadWrapper>{ lw };

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.manageLead();
        Test.stopTest();

        System.assertEquals(1, res.leadData.size());
    }

    /* ===================== PINCODE SERVICEABILITY ===================== */
    @IsTest
    static void testPincodeServiceable() {

        LeadManagementAPIREST.LeadWrapper lw =
            new LeadManagementAPIREST.LeadWrapper();
        lw.customerType = 'Individual';
        lw.mobileNumber = '9876543999';
        lw.pinCode = '12345';

        LeadManagementAPIREST.RequestWrapper req =
            new LeadManagementAPIREST.RequestWrapper();
        req.apiAction = 'CHECKPINCODESERVICEABILITY';
        req.apiSource = 'TEST';
        req.leadData = new List<LeadManagementAPIREST.LeadWrapper>{ lw };

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.manageLead();
        Test.stopTest();

        System.assertEquals(true, res.leadData[0].pinCodeServiceability);
    }
	@IsTest
    static void testPincodeBlank() {

        LeadManagementAPIREST.LeadWrapper lw =
            new LeadManagementAPIREST.LeadWrapper();
        lw.customerType = 'Individual';
        lw.mobileNumber = '9876543999';
        lw.pinCode = '';

        LeadManagementAPIREST.RequestWrapper req =
            new LeadManagementAPIREST.RequestWrapper();
        req.apiAction = 'CHECKPINCODESERVICEABILITY';
        req.apiSource = 'TEST';
        req.leadData = new List<LeadManagementAPIREST.LeadWrapper>{ lw };

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.manageLead();
        Test.stopTest();
    }
    @IsTest
    static void testPincodeNotServiceable() {

        LeadManagementAPIREST.LeadWrapper lw =
            new LeadManagementAPIREST.LeadWrapper();
        lw.customerType = 'Individual';
        lw.mobileNumber = '9876543888';
        lw.pinCode = '99999';

        LeadManagementAPIREST.RequestWrapper req =
            new LeadManagementAPIREST.RequestWrapper();
        req.apiAction = 'CHECKPINCODESERVICEABILITY';
        req.apiSource = 'TEST';
        req.leadData = new List<LeadManagementAPIREST.LeadWrapper>{ lw };

        RestContext.request = new RestRequest();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        LeadManagementAPIREST.ResponseWrapper res =
            LeadManagementAPIREST.manageLead();
        Test.stopTest();

        System.assertEquals(false, res.leadData[0].pinCodeServiceability);
    }
}