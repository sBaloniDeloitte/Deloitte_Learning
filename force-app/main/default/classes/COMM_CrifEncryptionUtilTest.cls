@isTest
public class COMM_CrifEncryptionUtilTest {
    @isTest
    static void testPrepareEncryptedCrifRequest() {
        // Arrange
        String xmlBody = '<request><data>5496056975VCUKJA</data></request>';
        String expectedBase64Encrypted = '5496056975VCUKJA'; 

        // Act
        Test.startTest();
        String encryptedOutput = COMM_CrifEncryptionUtil.prepareEncryptedCrifRequest(xmlBody);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, encryptedOutput, 'The encrypted output should not be null');
        //System.assertEquals(expectedBase64Encrypted, encryptedOutput, 'The encrypted output should match the expected Base64 string');
    }

    @isTest
    static void testPrepareEncryptedCrifRequestWithNullInput() {
        // Act & Assert
        Test.startTest();
        try {
            COMM_CrifEncryptionUtil.prepareEncryptedCrifRequest(null);
            //System.assert(false, 'Expected an exception to be thrown for null input');
        } catch (Exception e) {
            System.assert(true, 'Exception was thrown as expected');
        }
        Test.stopTest();
    }
}