/**
* @File Name : ContentVersionService.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 17, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 17, 2025 |   | Initial Version
**/

public class COMM_ContentVersionService {
@AuraEnabled
public static String fetchBase64FromContentVersion(Id contentVersionId) {
try {
System.debug('>>> fetchBase64FromContentVersion called with ID:' + contentVersionId);

if (contentVersionId == null) {
            throw new AuraHandledException('Content Version ID cannot be null');
        }
        
        // Query with proper error handling
        List<ContentVersion> cvList = [
            SELECT VersionData 
            FROM ContentVersion 
            WHERE Id = :contentVersionId 
            LIMIT 1
        ];
        
        if (cvList.isEmpty()) {
            System.debug('No ContentVersion found for ID: ' + contentVersionId);
            throw new AuraHandledException('No ContentVersion found for the provided ID');
        }
        
        ContentVersion cv = cvList[0];
        if (cv.VersionData == null) {
            throw new AuraHandledException('ContentVersion has no file data');
        }
        
        String base64String = EncodingUtil.base64Encode(cv.VersionData);
        System.debug('Successfully retrieved base64 data, length: ' + base64String.length());
        
        return base64String;
        
    } catch (Exception e) {
        System.debug('Error in fetchBase64FromContentVersion: ' + e.getMessage());
        System.debug('Stack trace: ' + e.getStackTraceString());
        throw new AuraHandledException('Error retrieving file data: ' + e.getMessage());
    }
}


}