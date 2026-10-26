@IsTest
public class HL_AvailabilityControllerTest {
    
    @IsTest
    static void testMarkUserAvailable() {
        Test.startTest();
        HL_AvailabilityController.markUserAvailable();
        Test.stopTest();
    }
}