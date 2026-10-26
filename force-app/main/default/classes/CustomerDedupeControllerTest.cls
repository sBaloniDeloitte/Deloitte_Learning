@isTest
public class CustomerDedupeControllerTest {
    @isTest
    static void testGetDuplicateCustomerList() {
        CustomerDedupeWrapper custWrap = new CustomerDedupeWrapper();

        Test.startTest();
        CustomerDedupeWrapper result = CustomerDedupeController.getDuplicateCustomerList(custWrap);
        Test.stopTest();

        System.assertNotEquals(null, result, 'The result should not be null');
    }
}