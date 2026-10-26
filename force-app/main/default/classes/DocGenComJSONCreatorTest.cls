@IsTest
public class DocGenComJSONCreatorTest {

    @IsTest
    static void testConstructorInitialization() {

        
        String contentId = '069000000000001AAA';
        String fileName = 'TestDocument.pdf';
        Integer compressionQuality = 75;

        
        DocGenComJSONCreator obj =
            new DocGenComJSONCreator(contentId, fileName, compressionQuality);

        
        System.assertEquals(contentId, obj.contentId, 'ContentId should be set correctly');
        System.assertEquals(fileName, obj.fileName, 'FileName should be set correctly');
        System.assertEquals(compressionQuality, obj.compressionQuality, 'Compression quality should be set correctly');
    }
}