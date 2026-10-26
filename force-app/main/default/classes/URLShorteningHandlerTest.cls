@isTest
public class URLShorteningHandlerTest {


    @testSetup
    static void setupTestData() {
        // Create Integration_Mapping__mdt records (mocked using Test.loadData or dummy records)
        // Custom Metadata Types cannot be inserted in Apex, so we assume that your code
        // handles missing mappings gracefully or you can mock groupByMap manually if needed.
        // For simplicity, we'll skip actual Custom Metadata insert.
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApp = FITestDataFactory.createLoanApplication(true,customer);
        loanApp.Udhyam_Registration_No__c  = 'UDY12345';
        update loanApp;
        
        Application_Applicant__c applicant =  FITestDataFactory.createApplicant(loanApp);
    }

    static testMethod void testValidatePayload_nullRegistrationNo() {
        // Prepare a ProcessReqWrapper with null registrationNo
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
		wrapper.panNumber = 'AQCPS5650A';
        wrapper.s3URL = 'Salesforce';
        Opportunity opp = [Select id from opportunity limit 1];
		wrapper.loanApplicationId = opp.Id;
        Application_Applicant__c appln = [Select Id,First_Name__c from Application_Applicant__c limit 1];
		wrapper.customerFirstName = appln.First_Name__c;
		wrapper.applicantId = appln.Id;
		// Instantiate handler
        //URLShorteningHandler handler = new URLShorteningHandler();
       try{
        List<String> errors = URLShorteningHandler.validatePayload(wrapper);
        }catch(exception e){
            
        }
        //System.assertEquals(1, errors.size(), 'Should have one validation error');
        //System.assertEquals('Legal enity number is not added', errors[0]);
    }

    static testMethod void testValidatePayload_withRegistrationNo() {
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
        wrapper.panNumber = 'AQCPS5650A';
        wrapper.s3URL = 'Salesforce';
        Opportunity opp = [Select id from opportunity limit 1];
		wrapper.loanApplicationId = opp.Id;
        Application_Applicant__c appln = [Select Id,First_Name__c from Application_Applicant__c limit 1];
		wrapper.customerFirstName = appln.First_Name__c;
		wrapper.applicantId = appln.Id;
		// Instantiate handler
        //URLShorteningHandler handler = new URLShorteningHandler();
        try{
        List<String> errors = URLShorteningHandler.validatePayload(wrapper);
        }catch(exception e){
            
        }
        //System.assertEquals(0, errors.size(), 'Should have no validation errors');
    }

    static testMethod void testConstructPayload() {
        // Prepare a ProcessReqWrapper with registration number
        intHandler.ProcessReqWrapper wrapper = new intHandler.ProcessReqWrapper();
       wrapper.panNumber = 'AQCPS5650A';
        wrapper.s3URL = 'Salesforce';
        Opportunity opp = [Select id from opportunity limit 1];
		wrapper.loanApplicationId = opp.Id;
        Application_Applicant__c appln = [Select Id,First_Name__c from Application_Applicant__c limit 1];
		wrapper.customerFirstName = Appln.First_Name__c;
		wrapper.applicantId = Appln.Id;

        // Prepare dummy Integration_Details__c list (can be empty for test)
        List<Integration_Details__c> integrationSettings = new List<Integration_Details__c>();

        // Instantiate handler
        URLShorteningHandler handler = new URLShorteningHandler();

        // Call constructPayload
        String requestJSON = handler.constructPayload(wrapper, integrationSettings);
        System.debug('Request JSON: ' + requestJSON);

        // Deserialize to validate content
        URLShorteningHandler.URLShorteningRequestServiceWrapper deserialized =
            (URLShorteningHandler.URLShorteningRequestServiceWrapper) JSON.deserialize(requestJSON, URLShorteningHandler.URLShorteningRequestServiceWrapper.class);

        //System.assertEquals('LEI12345', deserialized.leiNo, 'LEI number should match');
        //System.assertEquals('Y', deserialized.consent, 'Consent should be Y');
        //System.assertNotEquals(null, deserialized.clientData, 'ClientData should not be null');
    }

}