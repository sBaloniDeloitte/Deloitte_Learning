public with sharing class COMM_CrifHtmlRendererController {
    public String htmlBase64 { get; set; }

    public COMM_CrifHtmlRendererController() {
        String contentVersionId = ApexPages.currentPage().getParameters().get('contentVersionId');
        //String contentVersionId = '068dN000006lAbZQAU';
        system.debug('contentVersionId----'+contentVersionId);
        if (String.isNotBlank(contentVersionId)) {
            ContentVersion cv = [
                SELECT VersionData 
                FROM ContentVersion 
                WHERE Id =: contentVersionId 
                LIMIT 1
            ];
            if (cv != null) {
                // Convert Blob → Base64 String
                htmlBase64 = EncodingUtil.base64Encode(cv.VersionData);
            }
        }
    }
}