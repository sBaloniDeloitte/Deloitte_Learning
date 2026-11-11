// _______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________
@isTest
private class DummyOneTest {
    @isTest
    static void getMessageReturnsGreeting() {
        Test.startTest();
        String result = DummyOne.getMessage();
        Test.stopTest();
        Assert.areEqual('Hello from DummyOne', result, 'Unexpected message');
    }
}
// __________________________GenAI: Generated code ends here______________________________
