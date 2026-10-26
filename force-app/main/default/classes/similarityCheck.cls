/**
* @File Name : similarityCheck.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : April 29, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 29, 2025 |   | Initial Version
**/

public class similarityCheck {

    public static Decimal getNormalizedLevenshtein(String input, String received) {
        if (String.isBlank(input) || String.isBlank(received)) return 0;
        String a = input.toLowerCase();
        String b = received.toLowerCase();
        //Integer dist = getLevenshtein(a, b);
        Integer dist =  a.getLevenshteinDistance(b);
        Integer maxLen = Math.max(a.length(), b.length());
        System.debug('String a ='+a +'----' + 'String b='+b);
        System.debug(Decimal.valueOf(1) - Decimal.valueOf(dist) / Decimal.valueOf(maxLen));
        return Decimal.valueOf(1) - Decimal.valueOf(dist) / Decimal.valueOf(maxLen);
    }

        @AuraEnabled
    public static void insertFileRecord(String fileContentDocumentId, String recordId,String loanAppId) {
       try {
            Application_Applicant__c app=[select id from Application_Applicant__c WHERE Loan_Application__c =:loanAppId and Applicant_Type__c ='Primary Applicant' limit 1];            // Create a ContentDocumentLink to associate the file with the record
            ContentDocumentLink docLink = new ContentDocumentLink();
            docLink.ContentDocumentId = fileContentDocumentId;
            docLink.LinkedEntityId = recordId; // Associate with the record
            docLink.ShareType = 'I'; // View permission --> changed to I as was giving insufficient access error
            docLink.Visibility = 'AllUsers'; // Set visibility to all users (adjust as necessary)
            insert docLink;
            //update doc Details Record too >>
            Document_Details__c doc = new Document_Details__c();
            doc.Id = recordId;
            doc.Content_Document_Id__c = fileContentDocumentId;
            doc.Status__c = 'Uploaded';
            doc.Active__c = true;
            doc.Consider_for_Loan_Application__c = true;
            doc.Loan_Application__c=loanAppId;
            doc.Applicant__c =app?.Id;
            doc.Uploaded_Date_Time__c=Date.today();
            update doc;
             //Added by kalpesh -start
            Document_Details__c docObj = [SELECT Id, Name,Technical__c FROM Document_Details__c WHERE id=:recordId];
            if(docObj.Technical__c!=null){
                Technical_Evaluation__c techRecord =new Technical_Evaluation__c();
                techRecord.Id=docObj.Technical__c;
                techRecord.Is_Report_Uploaded__c=True;
                update techRecord;
            }
             //Added by kalpesh -end
        } catch (Exception e) {
            System.debug('stack TRACE "'+e.getStackTraceString());
            throw new AuraHandledException('Error associating file with record: ' + e.getMessage() + e.getLineNumber());
        }
    }
}