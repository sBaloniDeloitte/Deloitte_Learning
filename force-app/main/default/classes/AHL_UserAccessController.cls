public with sharing class AHL_UserAccessController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> canSeeVerifyCheckbox() {
        Map<String, Object> res = new Map<String, Object>();

        Profile p = [
            SELECT Name
            FROM Profile
            WHERE Id = :UserInfo.getProfileId()
            LIMIT 1
        ];

        // Match tolerantly in lowercase
        String nameLower = p.Name != null ? p.Name.toLowerCase() : '';
        Boolean allowed = nameLower.contains('credit');

        res.put('allowed', allowed);
        res.put('profileName', p.Name);
        return res;
    }
}