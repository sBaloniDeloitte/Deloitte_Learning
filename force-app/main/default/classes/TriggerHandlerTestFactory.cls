public class TriggerHandlerTestFactory {

    @TestVisible
    public static Boolean isTestMode = false;

    public static Map<String, Map<String, List<SObject>>>
        getObjectRecordsByProducts(String objectName, List<SObject> records, String productField) {

        if (Test.isRunningTest() && isTestMode) {
            Map<String, Map<String, List<SObject>>> mockMap = new Map<String, Map<String, List<SObject>>>();

            Map<String, List<SObject>> helperMap = new Map<String, List<SObject>>();
            helperMap.put('LegalTriggerHandler', records);

            mockMap.put('TestProduct', helperMap);
            return mockMap;
        }

        // existing real logic
        return new Map<String, Map<String, List<SObject>>>();
    }
}