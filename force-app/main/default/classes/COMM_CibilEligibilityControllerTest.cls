@isTest
public class COMM_CibilEligibilityControllerTest {
    
    @isTest
    static void testGetScreenFieldData() {
        // Setup Screen_Field__c test data
        Screen_Field__c sf = Testdatafactory.createScreenFieldRecords('CIBIL_SCREEN','CIBIL Score', 'CIBIL_SCORE', Null , Null) ;
            sf.Screen_Name__c = 'CIBIL_SCREEN';
            sf.Field_Label__c = 'CIBIL Score';
            sf.Read_Field_Name__c = 'CIBIL_SCORE';
            sf.Condition__c = 'Always';
            sf.Section_Seperator__c = true;
            sf.Section_Name__c = 'Credit Details';
            sf.Is_Active__c = true;
            sf.Field_Sequence__c = 1 ;
        
        Update sf;

        // Setup Applicant (fake SObject, replace with actual if Loan/Applicant custom object)
        Account applicant =  TestDataFactory.createAccountRecord('Test Application');
        insert applicant;

        // Prepare mock FICOResponse JSON
        String mockJson = '{'+
            '"response": {'+
                '"finalApprovalLevel": "APPROVED",'+
                '"calculatedVariables": ['+
                    '{"fieldName": "CIBIL_SCORE", "fieldValue": "750,green"}'+
                ']'+
            '}'+
        '}';
     //   Integration_Settings__c intSetting = TestDatafactory.setupIntegrationSetting('Loan Applicant Account Aggregator', 'NA','NA', 'Callout:LOS_BL_Account_aggregator_consentRequest','POST');

        // Insert Integration_Details__c record
        Integration_Details__c intDetails =TestDataFactory.getTestIntegrationDetails(1, Null,  True)[0];
            intDetails.Name = 'FICO cibil';
            intDetails.Endpoint__c = 'Callout:LOS_BL_Account_aggregator_consentRequest';
            intDetails.Related_Record_Id__c = applicant.Id;
            intDetails.Response_JSON__c = mockJson;
        
        update intDetails;

        // Call the method
        Test.startTest();
        List<COMM_CibilEligibilityController.ResponseWrapper> results =
            COMM_CibilEligibilityController.getScreenFieldData('CIBIL_SCREEN', applicant.Id);
        Test.stopTest();

        // Assertions
        System.assertEquals(1, results.size(), 'Should return one response wrapper');
        System.assertEquals('CIBIL Score', results[0].fieldLabel);
        System.assertEquals('750', results[0].fieldValue);
        System.assertEquals(true, results[0].isGreen);
        System.assertEquals('green', results[0].colourName);
    }
}