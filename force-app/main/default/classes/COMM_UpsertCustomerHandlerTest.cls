@isTest
public class COMM_UpsertCustomerHandlerTest {

    @testSetup 
    static void dataSetup(){
        Opportunity opp = TestDataFactory.getTestOpportunityData(1,false)[0];
        opp.Name = 'Test Opp';
        opp.StageName = 'Prospecting';
        opp.CloseDate = Date.today().addDays(10);
        opp.Negotiated_Loan_Amount__c = 100000;
        opp.Sanction_Loan_Amount__c = 100000;
        insert opp;

        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        customer.Customer_LMS_Id__c = '106037';
        update customer;

        Application_Applicant__c applicant = TestDataFactory.getTestApplicationApplicantData(1, opp.Id, false)[0];
        applicant.Gender__c = 'Male';
        applicant.Mobile_Number__c = '9876543210';
        applicant.PAN_Number__c = 'ABCPE1234F';
        applicant.Pan_Name__c = 'Test PAN Name';
        applicant.DOB__c = Date.newInstance(1990, 1, 1);
        applicant.DOI__c = Date.newInstance(2010, 1, 1);
        applicant.Loan_Application__c = opp.Id;
        applicant.Employment_Type__c ='SEP';
        applicant.Customer_Type__c ='Individual';
        applicant.First_Name__c ='Test';
        applicant.Last_Name__c = 'Last';
        applicant.Customer__c = customer.Id;
        applicant.Customer_Profile__c= 'SEP';
        applicant.Sector__c = 'Chartered Accountant';
        applicant.Industry__c = 'Airlines';
        applicant.Applicant_Type__c ='Primary Applicant';
        applicant.Marital_Status__c = 'Single';
        applicant.Salutation__c = 'CA';
        applicant.Religion__c = 'Hindu';
        applicant.Sub_Employment_Type_Non_Individual__c = 'SEP-CA';
        applicant.Nationality__c = 'Indian';
        applicant.Qualification__c = 'MBBS';
        applicant.Cast_Category__c = 'General';
        applicant.Residency_Status__c = 'Resident';
        applicant.Email__c = 'fgh@ghb.com';
        applicant.Masked_Aadhar_Number__c = '456767896789';
        insert applicant;

        TestDataFactory.setupTriggerSettings();
        City_Master__c city = TestDataFactory.getTestCityMasterData(1,true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1,city.Id,true)[0];

        Customer_Address__c custAddRecord = new Customer_Address__c();
        custAddRecord.Customer__c = customer.Id;
        insert custAddRecord;
        Applicant_Address__c appadd=   TestDataFactory.getTestApplicantAddressData(1, applicant.Id, custAddRecord.Id, pinCode.Id, false)[0];
        appadd.Address_Priority__c = '5';
        appadd.Address_Type__c = 'Permanent';
        appadd.Document_Details__c = TestDataFactory.getTestDocumentDetailsData(1, opp.Id, true)[0].Id;
        appadd.Address_Line_1__c ='djjfd';
        insert appadd;

        List<PLF_Master__c> plfList= new List<PLF_Master__c>();
        PLF_Master__c master1= new PLF_Master__c(
            Master_Type__c= 'Sub sector',
            Description__c= 'FOOTWEAR',
            FICO_Code__c= 'SBSC2020',
            Sector_Code__c = 'SEP3'
        );
        plfList.add(master1);

        PLF_Master__c master2= new PLF_Master__c(
            Master_Type__c= 'Salutation',
            Description__c= 'CA',
            FICO_Code__c= '17',
            Gender_Code__c = 'M'
        );
        plfList.add(master2);

        PLF_Master__c master3= new PLF_Master__c(
            Master_Type__c= 'Sector',
            Description__c= 'Chartered Accountant',
            FICO_Code__c= 'SEP2'
        );
        plfList.add(master3);

        PLF_Master__c master4= new PLF_Master__c(
            Master_Type__c= 'Industry',
            Description__c= 'Wholesaler',
            FICO_Code__c= 'WHS'
        );
        plfList.add(master4);

        PLF_Master__c master5= new PLF_Master__c(
            Master_Type__c= 'Gender',
            Description__c= 'Male',
            FICO_Code__c= 'M'
        );
        plfList.add(master5);

        PLF_Master__c master6= new PLF_Master__c(
            Master_Type__c= 'Marital Status',
            Description__c= 'Single',
            FICO_Code__c= 'S'
        );
        plfList.add(master6);

        PLF_Master__c master7= new PLF_Master__c(
            Master_Type__c= 'Segment',
            Description__c= 'SEP-CA',
            FICO_Code__c= 'SEG4'
        );
        plfList.add(master7);

        PLF_Master__c master8= new PLF_Master__c(
            Master_Type__c= 'Nationality',
            Description__c= 'Indian',
            FICO_Code__c= 'IN'
        );
        plfList.add(master8);

        PLF_Master__c master9= new PLF_Master__c(
            Master_Type__c= 'Qualification',
            Description__c= 'MBBS',
            FICO_Code__c= 'MBBS'
        );
        plfList.add(master9);

        PLF_Master__c master10= new PLF_Master__c(
            Master_Type__c= 'Caste',
            Description__c= 'General',
            FICO_Code__c= '40'
        );
        plfList.add(master10);

        PLF_Master__c master11= new PLF_Master__c(
            Master_Type__c= 'Religion',
            Description__c= 'Hindu',
            FICO_Code__c= '13'
        );
        plfList.add(master11);

        PLF_Master__c master12= new PLF_Master__c(
            Master_Type__c= 'Residency Status',
            Description__c= 'Resident',
            FICO_Code__c= 'Re'
        );
        plfList.add(master12);

        PLF_Master__c master13= new PLF_Master__c(
            Master_Type__c= 'Address Type',
            Description__c= 'Permanent',
            FICO_Code__c= 'Re'
        );
        plfList.add(master13);
        PLF_Master__c master14= new PLF_Master__c(
            Master_Type__c= 'Customer Type',
            Description__c= 'Permanent',
            FICO_Code__c= 'Re'
        );
        plfList.add(master14);

        insert plfList;

        Integration_Details__c idetails = new Integration_Details__c(
        	EndPoint__c = 'Callout:Create_Schedule_Simulation_API_LOS',
            Loan_Application__c = opp.Id,
            Status__c = '200',
            Calling_Source__c = 'Loan Scheduler Create Charges', 
            Comments__c = 'Charges API Invocation',
            Is_Success_Response__c = true
        );
       insert idetails;

        
        
    }

    @isTest
    public static void testMethod1(){
        Application_Applicant__c applicant= [SELECT Id FROM Application_Applicant__c LIMIT 1];
        List<Integration_Details__c> intList= [SELECT Id FROM Integration_Details__c];

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper(); 
        wrapper.applicantId = applicant.Id;

        Test.startTest();
        List<String> resList= COMM_UpsertCustomerHandler.validatePayload(wrapper);
        String result=  new COMM_UpsertCustomerHandler().constructPayload(wrapper, intList);
        COMM_UpsertCustomerHandler.validationMessage('String');
        Test.stopTest();
    }

    @isTest
    public static void testMethod2(){
        Application_Applicant__c applicant= [SELECT Id FROM Application_Applicant__c LIMIT 1];
        applicant.PAN_Number__c = null;
        update applicant;
        List<Integration_Details__c> intList= [SELECT Id FROM Integration_Details__c];

        IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper(); 
        wrapper.applicantId = applicant.Id;

        Test.startTest();
        List<String> resList= COMM_UpsertCustomerHandler.validatePayload(wrapper);
        String result=  new COMM_UpsertCustomerHandler().constructPayload(wrapper, intList);
        Test.stopTest();
    }
}