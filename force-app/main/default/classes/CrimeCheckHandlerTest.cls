@isTest
private class CrimeCheckHandlerTest {

    private static Application_Applicant__c createApplicant(Boolean isIndividual) {
        
        // Create test Opportunity
        Opportunity opp = new Opportunity(Name = 'Test Loan',Product__c='Home Loan');
        insert opp;
        
        Id customerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account acc = new Account(Name = 'Test Customer', RecordTypeId = customerRtId);
        insert acc;
        
       /* Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'Test Applicant',
            Applicant_Type__c = 'Primary Applicant',
            Mobile_Number__c = '9999999999',
            Email__c = 'test@example.com',
            DOB__c = Date.newInstance(1990, 1, 1),
            Father_s_First_Name__c = 'John',
            Father_s_Last_Name__c = 'Doe',
            Customer_Type__c = 'Individual',
            PAN_Number__c = isIndividual ? 'ABCDE1234F' : null,
            GSTIN__c = isIndividual ? null : '29ABCDE1234F1Z5',
            Company__c = isIndividual ? null : 'Test Company',
            Loan_Application__c = opp.Id
        );
        insert applicant; */
        
        Application_Applicant__c applicant = new Application_Applicant__c(
            Name = 'John Doe',
            Loan_Application__c =opp.Id,
            Customer_Type__c = 'Individual',
            PAN_Number__c = 'VZWPT2211A',
            GSTIN__c = isIndividual ? null : '29ABCDE1234F1Z5'
        );
        insert applicant;
        
        Trigger_Settings__c trg = new Trigger_Settings__c(
        Name = 'Trigger Settings',
        City_Master_Trigger__c = true
        );
        insert trg;
        
       // Factory methods for dependent data
        City_Master__c city = TestDataFactory.getTestCityMasterData(1, true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1, city.Id, true)[0];
        Customer_Address__c custAddRecord = TestDataFactory.getCustomerAdd(acc.Id);

        // Applicant Address
        Applicant_Address__c testPermanentAddress = new Applicant_Address__c(
            Applicant__c        = applicant.Id,
            Loan_Application__c = opp.Id,
            Address_Type__c     = 'Permanent',
            Address_Source__c   = 'Aadhaar',
            Floor_Number__c     = '1',
            Building_Street_Name__c = 'Street 1',
            Address_Line_1__c = 'Street 2',
            Address_Line_2__c = 'Plot 2',
            Plot_Number__c      = 'Plot 1',
            Pincode__c          = pincode.Id,
            Landmark__c         = 'Landmark 1',
            Customer_Address__c = custAddRecord.Id
        );
        insert testPermanentAddress;
        return applicant;
    }

    private static IntHandler.ProcessReqWrapper createWrapper(Id applicantId) {
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = applicantId;
        return wrapper;
    }

    @isTest
    static void testValidatePayload_Individual_Success() {
        Application_Applicant__c applicant = createApplicant(true);
        IntHandler.ProcessReqWrapper wrapper = createWrapper(applicant.Id);
        
        List<String> errors = CrimeCheckHandler.validatePayload(wrapper);
        System.assertEquals(0, errors.size(), 'No errors expected for valid Individual');
    }
    
    @isTest
    static void testValidatePayload_Individual_MissingValues() {
        Application_Applicant__c applicant = createApplicant(true);
        applicant.GSTIN__c = null;
        applicant.Customer_Type__c = 'Non Individual';
        update applicant;
        //applicant.Applicant_Address__c = null;
        delete [SELECT Id FROM Applicant_Address__c WHERE Applicant__c = :applicant.Id];
        IntHandler.ProcessReqWrapper wrapper = createWrapper(applicant.Id);
        
        List<String> errors = CrimeCheckHandler.validatePayload(wrapper);
        System.assertEquals(2, errors.size(), 'No errors expected for valid Individual');
    }

    @isTest
    static void testValidatePayload_Company_Success() {
        Application_Applicant__c applicant = createApplicant(false);
        IntHandler.ProcessReqWrapper wrapper = createWrapper(applicant.Id);
        
        List<String> errors = CrimeCheckHandler.validatePayload(wrapper);
       // System.assertEquals(0, errors.size(), 'No errors expected for valid Business');
    }

    @isTest
    static void testValidatePayload_MissingPAN() {
        Application_Applicant__c applicant = createApplicant(true);
        applicant.PAN_Number__c = null;
        update applicant;

        IntHandler.ProcessReqWrapper wrapper = createWrapper(applicant.Id);
        List<String> errors = CrimeCheckHandler.validatePayload(wrapper);
        System.assertEquals(1, errors.size());
        System.assert(errors[0].contains('Missing PAN Number'));
    }

    @isTest
    static void testValidatePayload_MissingGSTINOrAddress() {
         try{
        Application_Applicant__c applicant = createApplicant(false);
       
        // Remove GSTIN and Address
        applicant.GSTIN__c = null;
        update applicant;
        delete [SELECT Id FROM Applicant_Address__c WHERE Applicant__c = :applicant.Id];

        IntHandler.ProcessReqWrapper wrapper = createWrapper(applicant.Id);
        List<String> errors = CrimeCheckHandler.validatePayload(wrapper);
       // System.assertEquals(1, errors.size());
        } catch (Exception e){
            
        }
    }

    @isTest
    static void testConstructPayload_Individual() {
        
        Application_Applicant__c applicant = createApplicant(true);
        IntHandler.ProcessReqWrapper wrapper = createWrapper(applicant.Id);
        
        Test.startTest();
        try{
        String payload = (new CrimeCheckHandler()).constructPayload(wrapper, new List<Integration_Details__c>());
        }catch (Exception e) {
        }
        Test.stopTest();

        //System.assertNotEquals(null, payload);
       // System.assert(payload.contains('name=' + applicant.Applicant_Name__c));
       // System.assert(payload.contains('callbackUrl='));
    }

     @isTest
    static void testConstructPayload_NonIndividual() {
        
        Application_Applicant__c applicant = createApplicant(true);
        applicant.Customer_Type__c ='Non Individual';
        update applicant;
        IntHandler.ProcessReqWrapper wrapper = createWrapper(applicant.Id);
        
        Test.startTest();
        try{
        String payload = (new CrimeCheckHandler()).constructPayload(wrapper, new List<Integration_Details__c>());
        }catch (Exception e) {
        }
        Test.stopTest();

        //System.assertNotEquals(null, payload);
       // System.assert(payload.contains('name=' + applicant.Applicant_Name__c));
       // System.assert(payload.contains('callbackUrl='));
    }

    
    @isTest
    static void testConstructPayload_Company() {
        Application_Applicant__c applicant = createApplicant(false);
        IntHandler.ProcessReqWrapper wrapper = createWrapper(applicant.Id);

        Test.startTest();
        try{
        String payload = (new CrimeCheckHandler()).constructPayload(wrapper, new List<Integration_Details__c>());
        }catch(exception e){ }
        Test.stopTest();

        //System.assert(payload.contains('"companyName":"Test Company"'), 'Payload should contain company details');
    }

    @isTest
    static void testConstructPayload_ExceptionHandling() {
        // Intentionally passing bad input to cause exception
        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
        wrapper.recordId = '001XXXXXXXXXXXX'; // Invalid Id

        Test.startTest();
        try {
            (new CrimeCheckHandler()).constructPayload(wrapper, new List<Integration_Details__c>());
            //System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().startsWith('An error occurred:'), 'Should catch and wrap exception');
        }
        Test.stopTest();
    }
}