public class ITRCmpController {
	@AuraEnabled
    public static Application_Applicant__c getApplicantDetails(String applicantId) {
        List<Application_Applicant__c> appObj = [SELECT id,PAN_Number__c,DOB__c FROM Application_Applicant__c WHERE id=:applicantId];
        if(appObj.size() > 0 ) {
            return appObj[0];
        }
        return null;
    }
    
    @AuraEnabled
    public static Document_Details__c getItrDoc(String applicantId) {
        List<Document_Details__c> appObj = [SELECT id,Content_Document_Id__c,Applicant__r.Applicant_Name__c FROM Document_Details__c WHERE Applicant__c=:applicantId AND
                                           Name = 'ITR Report'];
        if(appObj.size() > 0 ) {
            return appObj[0];
        }
        return null;
    }
    
    @AuraEnabled
    public static String checkIfRequestInitiated(String applicantId) {
        String res = 'No request found!.';
        List<Integration_Details__c> appObj = [SELECT id FROM Integration_Details__c WHERE 
                                           Name = 'ITR Request Success' AND Related_Record_Id__c =:applicantId AND Status__c = '200'];
        if(appObj.size() > 0 ) {
            res = 'Request is in progress!.';
        }
        return res;
    }

    @AuraEnabled(cacheable=true)
    public static List<ITR_RESTCallback.cls_itrvInfoList> getItrvInfoUsingWrapper(Id applicantId) {
        List<ITR_RESTCallback.cls_itrvInfoList> out = new List<ITR_RESTCallback.cls_itrvInfoList>();

        List<Integration_Details__c> rows = [
            SELECT Response_JSON__c
            FROM Integration_Details__c
            WHERE Name = 'ITR Response'
              AND Related_Record_Id__c = :applicantId
              AND (Status__c = '200' OR Status__c = 'Success')
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (rows.isEmpty() || String.isBlank(rows[0].Response_JSON__c)) {
            return out;
        }
         String cleaned = rows[0].Response_JSON__c
            .replace('\r', ' ')
            .replace('\n', ' ');
        cleaned = cleaned.replaceAll('[\\u0000-\\u0008\\u000B\\u000C\\u000E-\\u001F]', ' ');
        cleaned = cleaned.replaceAll('"uploadedFile"\\s*:\\s*\\[[^\\]]*\\]\\s*,?', '');
        cleaned = cleaned.replaceAll(',\\s*,', ',');

        ITR_RESTCallback parsed =
            (ITR_RESTCallback) JSON.deserialize(cleaned, ITR_RESTCallback.class);

        if (parsed == null || parsed.data == null || parsed.data.jsonReport == null ||
            parsed.data.jsonReport.itrvDetails == null ||
            parsed.data.jsonReport.itrvDetails.itrvInfoList == null) {
            return out;
        }

        for (ITR_RESTCallback.cls_itrvInfoList it : parsed.data.jsonReport.itrvDetails.itrvInfoList) {
            if (it == null) continue;
            if (it.personalInfo == null) it.personalInfo = new ITR_RESTCallback.cls_personalInfo();
            if (it.incomeDetail == null) it.incomeDetail = new ITR_RESTCallback.cls_incomeDetail();
            if (it.incomeDetail.taxesPaid == null) it.incomeDetail.taxesPaid = new ITR_RESTCallback.cls_taxesPaid();
            if (it.incomeDetail.exemptIncome == null) it.incomeDetail.exemptIncome = new ITR_RESTCallback.cls_exemptIncome();

            if (it.dateOfSubmission != null) it.dateOfSubmission = it.dateOfSubmission.replace('\r',' ').replace('\n',' ').trim();
            if (it.dateOfVerification != null) it.dateOfVerification = it.dateOfVerification.replace('\r',' ').replace('\n',' ').trim();

            out.add(it);
        }
        return out;
    }
   
}