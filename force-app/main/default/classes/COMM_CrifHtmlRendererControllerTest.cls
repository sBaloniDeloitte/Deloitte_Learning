@isTest
private class COMM_CrifHtmlRendererControllerTest {

    @isTest
    static void testMethod1() {
        ContentVersion cv = new ContentVersion(
            Title = 'SampleHTML',
            PathOnClient = 'sample.html',
            VersionData = Blob.valueOf('<html><body>COMM_CrifHtmlRendererControllerTest test body</body></html>')
        );
        insert cv;

        Id contentVersionId = cv.Id;

        Test.startTest();
        PageReference pageRef = Page.CrifHtmlRendererPage; 
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('contentVersionId', String.valueOf(contentVersionId));


        COMM_CrifHtmlRendererController controller = new COMM_CrifHtmlRendererController();
        Test.stopTest();
    }
}