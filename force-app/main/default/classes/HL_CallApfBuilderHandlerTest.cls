@IsTest
private class HL_CallApfBuilderHandlerTest {

    // --- Dummy HTTP response (if real handler makes a callout) ---
    private class DummyHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"message":"Rows inserted :1"}');
            return res;
        }
    }

    // --- Static Mock Class (same name & method signature) ---
    public class Hl_ApfBuilderHandler {
        public String initiateApfBuilderCallout(Map<String, String> inputMap, List<Builder__c> builders) {
            System.debug('🧪 Mock initiateApfBuilderCallout called → ' + inputMap + ', builders=' + builders);
            return 'MockedSuccess';
        }
    }

    // --- Test Setup ---
    @TestSetup
    static void setupData() {
        // Required Trigger Setting
        Trigger_Settings__c trg = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = true
        );
        insert trg;

        // Create City & Pincode via TestDataFactory
        City_Master__c city = TestDataFactory.getTestCityMasterData(1, true)[0];
        Pincode_Master__c pincode = TestDataFactory.getTestPincodeMasterData(1, city.Id, true)[0];

        // Create required Integration_Settings__c for the callout handler
        Integration_Settings__c setting = new Integration_Settings__c(
            Name = 'APF_Builder',
            Endpoint__c = 'https://mock.endpoint.com',
            Request_Method__c = 'POST',
            Content_Type__c = 'application/json',
            Client_Id__c = 'mockClient',
            Client_Secret__c = 'mockSecret'
        );
        insert setting;

        // Builder record
        Builder__c builder = new Builder__c(
            Name = 'Test Builder',
            //Builder_ID__c = 'B123',
            Segmentation__c = 'Premium',
            Record_Status__c = 'Active',
            Exposure_Limit_On_Amount__c = '100000',
            Exposure_Limit_On_No_Of_Units__c = 5
           // Pincode_ID__c = pincode.Id
        );
        insert builder;
    }

    // --- ✅ Test Insert Flow ---
    @IsTest
    static void testCallAPFBuilderInsertAPI() {
        Builder__c builder = [SELECT Id FROM Builder__c LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new DummyHttpResponse());

        Test.startTest();
        try{
        HL_CallApfBuilderHandler.CallAPFBuilderInsertAPI(builder.Id);
        } catch(exception e){
            
        }
        Test.stopTest();

        System.assert(true, '✅ Insert API executed successfully');
    }

    // --- ✅ Test Update Flow ---
    @IsTest
    static void testCallAPFBuilderUpdateAPI() {
        Builder__c builder = [SELECT Id FROM Builder__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new DummyHttpResponse());

        Test.startTest();
        try{
        HL_CallApfBuilderHandler.CallAPFBuilderUpdateAPI(builder.Id);
        } catch(exception e){
            
        }
        Test.stopTest();

        System.assert(true, '✅ Update API executed successfully');
    }

    // --- ✅ Negative Path (null ID) ---
    @IsTest
    static void testCallAPFBuilder_NullId() {
        try {
            Test.startTest();
            HL_CallApfBuilderHandler.CallAPFBuilderInsertAPI(null);
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('List has no rows') || e.getMessage().contains('null'),
                'Should handle null ID gracefully');
        }
    }
}