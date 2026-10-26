/**
* @File Name : GenericInitiateController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : May 19, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 19, 2025 |   | Initial Version
**/

public class GenericInitiateController {
	
	@AuraEnabled
    public static List<CheckBoxWrapper> getDocumentNames(String docName){
        try {
            List<CheckBoxWrapper> wrapper = new List<CheckBoxWrapper>();
            //String formattedDocName = '%'+docName+'%';
            //system.debug('formattedDocName'+formattedDocName);
            for(Document_Master__c doc : [SELECT Id,Document_Name__c FROM Document_Master__c WHERE Type__c = 'Loan Application' AND Document_Name__c LIKE : ('%'+docName+'%')]){
                wrapper.add(new CheckBoxWrapper(doc.Document_Name__c ,doc.Id));
            }
            return wrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Document_Details__c> insertDocumentCheckList(Id recordId,List<String> docNames,String type, String requirementAt, String applicationColl){
        //try {
            Map<String,String> inputMap = new  Map<String,String>();
            inputMap.put('oppId',recordId);
            Utility_V1.ProductWrapper pw = Utility_V1.getProductDetails(inputMap);
            String product = pw.loanProduct;
            System.debug('Type:'+ type);
            List<Document_Details__c> docCheckList = new List<Document_Details__c>();
            for(String docName : docNames){
                docCheckList.add(
                    new Document_Details__c(
                        Name = docName,
                        Document_Category__c = type,
                        Loan_Application__c = recordId,
                        Is_Required__c = true,
                        Requirement_At__c = requirementAt,
                        Application_Collateral__c = applicationColl,
                        //HL-Ishi-3/9/2025
                        HL_Document_Available_for_Soft_Delete__c = false
                        //HL-Ishi-3/9/2025
                    )
                );
            }
            insert docCheckList;
            //return docCheckList;//updated-Ayushi
            return docCheckList != null ? docCheckList : new List<Document_Details__c>();
            //System.debug('Doc Checklist inserted successfully');
        //} catch (Exception e) {
           // throw new AuraHandledException(e.getLineNumber() + '-' + e.getMessage());
        //}
    }

	@AuraEnabled
    public static List<CheckBoxWrapper> getDocumentMasterList( String objectType, String docCategoryType, String recordId,Id applicationCollId){
        try {
            //HL-Ishi-1/9/2025
            Map<String,String> inputMap = new  Map<String,String>();
            inputMap.put('oppId',recordId);
            Utility_V1.ProductWrapper pw = Utility_V1.getProductDetails(inputMap);
            String product = pw.loanProduct;
            //HL-Ishi-1/9/2025
            List<CheckBoxWrapper> wrapper = new List<CheckBoxWrapper>();
            Map<String,Document_Details__c> docNameToDocIdMap = new Map<String,Document_Details__c>();
            // fill the map for doc detail and doc master mapping
            for(Document_Details__c doc : [SELECT Id,Name, Document_Master__c,Document_Master__r.Document_Name__c FROM Document_Details__c WHERE Loan_Application__c =:recordId AND Application_Collateral__c =:applicationCollId AND Is_Required__c = true AND Document_Category__c = :docCategoryType AND Requirement_At__c = 'Collateral Level' AND (Legal__c = null OR Technical__c = null) ]){
                docNameToDocIdMap.put(doc.Name,doc); //putting Name as key since doc master is only being used to fetch the name and doc details have the same name
            }
            //check if doc detail already there in current application from doc master
            for(Document_Master__c doc :  [SELECT Id,Document_Name__c FROM Document_Master__c WHERE  Type__c = :objectType AND Name NOT IN :docNameToDocIdMap.keySet()]){ /*Type__c = 'Loan Application' AND*/
                wrapper.add(new CheckBoxWrapper(doc.Document_Name__c ,doc.Id));
            }
            return wrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void deleteContent(Id contentId, Id recordId) {
        try {
            List<Document_Details__c> docsToUpdate = new List<Document_Details__c>();
            List<ContentDocumentLink> linksToDelete = [SELECT Id FROM ContentDocumentLink WHERE ContentDocumentId = :contentId AND LinkedEntityId = :recordId];
            for (Document_Details__c doc :  [SELECT Id, Name, Is_Required__c, Document_Uploaded__c, Content_Document_Id__c FROM Document_Details__c WHERE Loan_Application__c = :recordId AND Content_Document_Id__c = :contentId]) { //matching docs
                doc.Content_Document_Id__c = null;
                docsToUpdate.add(doc);
            }
            if (!docsToUpdate.isEmpty()) { //updated doc details with the contetntdocid field
                update docsToUpdate;
            }
            if (!linksToDelete.isEmpty()) {
                Database.delete(linksToDelete);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error during content deletion: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }
    //HL-Ishi-1/9/2025
    @AuraEnabled
    public static List<CheckBoxWrapper> getSalesUploadedDocuments( String objectType, String docCategoryType, String recordId,Id applicationCollId){
        try {
            //HL-Ishi-1/9/2025
            Map<String,String> inputMap = new  Map<String,String>();
            inputMap.put('oppId',recordId);
            Utility_V1.ProductWrapper pw = Utility_V1.getProductDetails(inputMap);
            String product = pw.loanProduct;
            //HL-Ishi-1/9/2025
            String docCategory;
            List<CheckBoxWrapper> wrapper = new List<CheckBoxWrapper>();
            Map<String,Document_Details__c> docNameToDocIdMap = new Map<String,Document_Details__c>();
            List<Document_Details__c> docList = new  List<Document_Details__c>();
            // fill the map for doc detail and doc master mapping
            for(Document_Details__c doc : [Select id,Collateral_Master__c,Name,Content_Document_Id__c,Document_Name__c,HL_Document_Available_for_Soft_Delete__c,HL_Show_Document_In_Table__c from Document_Details__c where Loan_Application__c =:recordId and Collateral_Master__c !=null and Content_Document_Id__c!=null]){
                if(!doc.HL_Document_Available_for_Soft_Delete__c){
                    doc.HL_Document_Available_for_Soft_Delete__c=  true;
                    doc.HL_Show_Document_In_Table__c = true;
                    docList.add(doc);
                }
                if(!doc.HL_Show_Document_In_Table__c){
                    doc.HL_Show_Document_In_Table__c=  true;
                    docList.add(doc);
                }
            }
            if(!docList.isEmpty()){
                 update docList;
            }
            for(Document_Details__c doc : [Select id,Collateral_Master__c,Name,Content_Document_Id__c,Document_Name__c,HL_Document_Available_for_Soft_Delete__c from Document_Details__c where Loan_Application__c =:recordId and Collateral_Master__c !=null and Content_Document_Id__c!=null  ]){
                wrapper.add(new CheckBoxWrapper(doc.Name ,doc.Id));
            }
            return wrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

	public class CheckBoxWrapper{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public CheckBoxWrapper(String label,String value){
            this.label = label;
            this.value = value;
        }
    }
}