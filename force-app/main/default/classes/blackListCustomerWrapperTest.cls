@IsTest
public class blackListCustomerWrapperTest {

    @IsTest
    static void testWrapperInstantiation() {
        // Create FieldMetadata objects
        blackListCustomerWrapper.FieldMetadata mobileNumberMeta = new blackListCustomerWrapper.FieldMetadata();
        mobileNumberMeta.placeInOrder = 1;
        mobileNumberMeta.type = 'String';
        mobileNumberMeta.typeCode = 101;

        blackListCustomerWrapper.FieldMetadata addressMeta = new blackListCustomerWrapper.FieldMetadata();
        addressMeta.placeInOrder = 2;
        addressMeta.type = 'String';
        addressMeta.typeCode = 102;

        // Create Metadata object and assign FieldMetadata
        blackListCustomerWrapper.Metadata meta = new blackListCustomerWrapper.Metadata();
        meta.mobilenumber = mobileNumberMeta;
        meta.address = addressMeta;

        // Create wrapper object and populate values
        blackListCustomerWrapper wrapper = new blackListCustomerWrapper();
        wrapper.data = new List<List<String>>{
            new List<String>{'John', 'Doe', '1234567890'},
            new List<String>{'Jane', 'Smith', '0987654321'}
        };
        wrapper.done = true;
        wrapper.endTime = '2023-12-31T23:59:59Z';
        wrapper.metadata = meta;
        wrapper.queryId = 'TEST_QUERY_001';
        wrapper.rowCount = 2;
        wrapper.startTime = '2023-12-31T00:00:00Z';

        // Assertions to validate field assignments
        System.assertEquals(2, wrapper.data.size(), 'Data should contain 2 rows');
        System.assertEquals(true, wrapper.done, 'Done flag should be true');
        System.assertEquals('TEST_QUERY_001', wrapper.queryId, 'QueryId mismatch');
        System.assertNotEquals(null, wrapper.metadata, 'Metadata should not be null');
        System.assertEquals('String', wrapper.metadata.mobilenumber.type, 'Mobile number type mismatch');
        System.assertEquals(101, wrapper.metadata.mobilenumber.typeCode, 'Mobile number typeCode mismatch');
    }
}