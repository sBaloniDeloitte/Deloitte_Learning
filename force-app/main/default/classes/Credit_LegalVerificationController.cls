public without sharing  class  Credit_LegalVerificationController {

    @AuraEnabled
    public static Boolean getFiStatus(String recordId,String objectApiName) {
        try {
            Boolean flag=true;
            if(objectApiName == 'Legal__c'){
                Legal__c LegalRecord = [
                    SELECT Stage__c ,Assigned_to_Admin__c,Assigned_to_Executive__c,Vendor_Agency__c, RecordType.Name
                    FROM Legal__c 
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                User currentUser = [
                    SELECT Profile.Name 
                    FROM User 
                    WHERE Id = :UserInfo.getUserId()
                    LIMIT 1
                ];
                System.debug('currentUser '+ currentUser);
                 List<AccountTeamMember> bu=[Select id, UserId, TeamMemberRole from AccountTeamMember where UserId=:UserInfo.getUserId() LIMIT 1 ];
                 System.debug('bu '+ bu);
                  System.debug('LegalRecord.Stage__c '+ LegalRecord.Stage__c);
                   System.debug('currentUser.Profile.Name '+ currentUser.Profile.Name);
            
                    List<FI_Record_Editiability__mdt> fieldMeta = [
                        SELECT Id, Profile__c, Role__c, Stage__c, Is_Active__c 
                        FROM FI_Record_Editiability__mdt 
                        WHERE Is_Active__c = true and Role__c=:bu[0].TeamMemberRole AND Profile__c=:currentUser.Profile.Name AND Stage__c=:LegalRecord.Stage__c
                    ];
                    system.debug('fieldMeta:: '+fieldMeta);
                    if(fieldMeta.size()>0 && ((LegalRecord.Assigned_to_Admin__c==UserInfo.getUserId() && (LegalRecord.Stage__c == 'Assigned to Admin' || LegalRecord.Stage__c == 'Assigned To Executive' || LegalRecord.Stage__c == 'Submitted by Executive'))
                    ||LegalRecord.Assigned_to_Executive__c==UserInfo.getUserId() || LegalRecord.Vendor_Agency__c==UserInfo.getUserId())){
                        flag=false;
                    }
                
            }
            
            return flag;
            
        } 
        catch (Exception e) {
            System.debug('Exception in getFiStatus: ' + e.getMessage());
            throw new AuraHandledException('Error: ' + e.getMessage() + e.getStackTraceString());
        }
    }

   
   /* @AuraEnabled
    public static String updateDocumentChecklist(String fiId, String reportId) {
        try {
            System.debug('Starting updateDocumentChecklist...');
            System.debug('fiId: ' + fiId + ', reportId: ' + reportId);
            Set<Id> assigneeID = new Set<Id>();
            Application_Verification__c fi = [
                SELECT Id, Loan_Application__c, Vendor_Admin__c, Assigned_To_User__c, Name, Applicant__c, RecordType.Name, Loan_Application__r.Name
                FROM Application_Verification__c
                WHERE Id = :fiId
            ];
            System.debug('Fetched Application_Verification__c: ' + fi);
            List<Document_Master__c> docMaster = [
                SELECT Id, Document_Name__c, Document_Category__c
                FROM Document_Master__c
                WHERE Document_Category__c = :fi.RecordType.Name
                // AND Document_Name__c =: constants.get('Report')
                AND Document_Name__c = 'Other'
            ];
            System.debug('Fetched Document_Master__c: ' + docMaster);
            String baseDocName = fi.Name + ' '+constants.get('Report'); 
            Integer counter = 1;  
            List<Document_Details__c> docDetail = [
                SELECT Id, Name
                FROM Document_Details__c
                WHERE Name LIKE :baseDocName + '%'
            
            ];
            System.debug('Fetched docDetail: ' + docDetail);
            for (Document_Details__c doc : docDetail) {
                String docName = doc.Name;
            
                if (docName.contains(' Report ')) {
                    String[] parts = docName.split(' Report ');
                    if (parts.size() > 1) {
                        try {
                            Integer existingCounter = Integer.valueOf(parts[1]);
                            counter = Math.max(counter, existingCounter + 1); 
                            System.debug(' counter: ' + counter);
                        } catch (Exception e) {
                            
                        }
                    }
                }
            }
            String docName = fi.Name + ' '+constants.get('Report') + counter;
            System.debug('Fetched docName: ' + docName);
            // Create ContentVersion for the report
            Blob contentBlob = EncodingUtil.base64Decode(reportId);
            ContentVersion cv = new ContentVersion();
            cv.Title = fi.Loan_Application__r.Name + constants.get('FI_Report');
            cv.PathOnClient = constants.get('FI_Report');
            cv.VersionData = contentBlob;
            cv.IsMajorVersion = true;
            insert cv;
            
            // Retrieve the ContentDocumentId from the inserted ContentVersion
            ContentVersion insertedVersion = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :cv.Id
            ];
            System.debug('Fetched insertedVersion: ' + insertedVersion);
            String contentDocumentId = insertedVersion.ContentDocumentId;
            System.debug('Fetched contentDocumentId: ' + insertedVersion.ContentDocumentId);
            // Prepare Document_Details__c record
            Document_Details__c docDetails = new Document_Details__c();
            docDetails.Application_Verification__c = fiId;
            docDetails.Content_Document_Id__c = reportId;
            docDetails.Loan_Application__c = fi.Loan_Application__c;
            //docDetails.Applicant__c = fi.Applicant__c;
            if(fi.RecordType.Name=='Personal Discussion'){
                docDetails.Is_Required__c = true;
            }else {
                docDetails.Document_Master__c = docMaster[0].Id;
            }
            docDetails.Status__c = constants.get('Uploaded');
            docDetails.Name = docName;
            
            insert docDetails;
           
            // Determine assignee IDs for sharing permissions
            List<Document_Details__c> doc = [
                SELECT Id, OwnerId
                FROM Document_Details__c
                WHERE Id = :docDetails.Id
            ];
            System.debug('Fetched doc: ' + doc);
            if (doc.size() > 0) {
                System.debug('Fetched fi.Vendor_Admin__c: ' + fi.Vendor_Admin__c);
                System.debug('Fetched fi.Assigned_To_User__c: ' + fi.Assigned_To_User__c);
                if (fi.Vendor_Admin__c != doc[0].OwnerId) {
                    assigneeID.add(fi.Vendor_Admin__c);
                }
                if (fi.Assigned_To_User__c != doc[0].OwnerId) {
                    assigneeID.add(fi.Assigned_To_User__c);
                }
            }

            // Create sharing records for the document
            List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
            for (Id i : assigneeID) {
                Utility.SharingInfo si = new Utility.SharingInfo();
                si.objectName = constants.get('Document_Details_Object');
                si.userOrGroupId = i;
                si.recordToShareId = docDetails.Id;
                si.sharingAccess = constants.get('Edit');
                sharingList.add(si);
            }
            Utility.createShareRecord(JSON.serialize(sharingList));

            // Create ContentDocumentLink to link the document
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = docDetails.Id;
            cdl.ContentDocumentId = reportId;
            cdl.ShareType = constants.get('V');
            cdl.Visibility = constants.get('AllUsers'); 
            insert cdl;

            return reportId;
        } catch (Exception e) {
            System.debug('Exception in updateDocumentChecklist: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }*/

    /*@AuraEnabled
    public static String getLatestDocumentUrl (Id recordId) {
         String url = '';
        try {
            List<Application_Verification__c> fi = [
            SELECT id, Name, Loan_Application__r.Name FROM Application_Verification__c WHERE id = :recordId]; 
            System.debug('FI Application'+ fi);
            String docName = fi[0].Name +' '+constants.get('Report');
            System.debug('DocName'+ docName);
            List<Document_Details__c> docDetails = [SELECT id, Document_URL__c, Content_Document_Id__c FROM Document_Details__c 
                WHERE Application_Verification__c = :recordId AND Name LIKE :docName + '%'  ORDER BY CreatedDate DESC LIMIT 1
            ]; 
            System.debug('docDetails'+ docDetails);
            if (!docDetails.isEmpty()) {
                url = docDetails[0].Content_Document_Id__c; // Or use Content_Document_Id__c if you need the document ID
            return url;}
            else {

                throw new AuraHandledException('No document details found for this record');
                
            }
        }catch (Exception e) {
           throw new AuraHandledException(e.getMessage());
        }
    }*/

    @AuraEnabled
    public static Boolean checkShowSubmit(String recId,String objectAPIName){
        Boolean showSubmit = true;
        try {
            List<Screen_Field__c> screenFields = new List<Screen_Field__c>();
            String query='Select id';
            String queryFields;
            String prodName;
            if(objectAPIName == 'Legal__c'){
                String reportName;
                List<Legal__c> fiList = [Select Id,RecordType.Name from Legal__c where id =: recId];
                if(fiList[0].RecordType.Name=='Legal Scrutiny Report'){
                    reportName = 'Legal Scrutiny Report Limited';
                }
                else{
                    reportName = fiList[0].RecordType.Name;
                }
                screenFields = [SELECT Id,Form_Name__c , Parent_Screen__r.Form_Name__c, Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c, 
                Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,
                Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c,Read_Field_Name__c,Read_Object_Name__c,Section_Seperator__c,Section_Name__c,
                Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c
                FROM Screen_Field__c
                WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Form_Name__c =: reportName And Is_Mandatory__c=true
                order by Field_Sequence__c ASC];
                system.debug('sfiList: '+fiList);
                 
                Map<String,List<String>> objectToFieldsMap = new Map<String,List<String>>();
                Map<String,String> fieldApiTOLabelMap = new Map<String,String>();
                
                for(Screen_Field__c sc : screenFields){
                    system.debug('sc.Read_Object_Name__c: '+sc.Storage_Object__c);
                    system.debug('sc.Read_Field_Name__c: '+sc.Storage_Field__c);
                    system.debug('sc.Field_Label__c: '+sc.Field_Label__c);
                    
                    fieldApiTOLabelMap.put(sc.Storage_Field__c, sc.Field_Label__c);
                    
                    if(objectToFieldsMap.containsKey(sc.Storage_Object__c)){
                        if(!objectToFieldsMap.get(sc.Storage_Object__c).contains(sc.Storage_Field__c)){
                            objectToFieldsMap.get(sc.Storage_Object__c).add(sc.Storage_Field__c);
                        }
                    }
                    else{
                        objectToFieldsMap.put(sc.Storage_Object__c, new List<String>{sc.Storage_Field__c});
                    }
                }
                
                Map<String,List<SObject>> objectValuesMap = new Map<String,List<SObject>>();
                for(String objectName : objectToFieldsMap.keySet()){
                    List<String> fieldApiNames = objectToFieldsMap.get(objectName);
                    queryFields = 'SELECT ' + String.join(fieldApiNames,', ');
                    System.debug('objectName: '+objectName);
                    switch on objectName {
                        when 'Legal__c' {
                            queryFields += ' FROM '+ objectName +' where Id = \'' + recId + '\' LIMIT 1';
                        }
                        when 'Applicant_Address__c' {
                            queryFields += ' ,Pincode__c FROM '+ objectName +' where Legal__c = \''+ recId + '\'  LIMIT 1';
                        }
                    }
                    system.debug('line 1392-->>'+queryFields);
                    List<Sobject> sObj = Database.query(queryFields);
                    system.debug('line 1393-->>'+sObj);
                    if(sObj.size()>0){
                        for(Screen_Field__c sf: screenFields){
                            if (prodName == 'Home Loan' && sf.Storage_Field__c == 'Relationship_with_Applicant__c') {
                                continue; 
                            }
                            if (prodName != 'Home Loan' && sf.Storage_Field__c == 'Relationship_with_Applicant_HL__c') {
                                continue; 
                            }
                            System.debug('sf.Storage_Object__c----'+sf.Storage_Object__c);
                            System.debug('objectName'+objectName);
                            if(sf.Storage_Object__c == objectName && (sObj[0].get(sf.Storage_Field__c) == null||sObj[0].get(sf.Storage_Field__c) == '')){
                                system.debug('line 1398-->>'+sf.Storage_Field__c);
                                  System.debug('objectName'+objectName);
                                showSubmit=false;
                                break;
                            }
                          
                        }
                    }
                    else{
                         showSubmit=false;
                                break;
                    }
                }
            }
            if(objectAPIName != 'Legal__c'){
                system.debug('line 1392-->>'+queryFields);
                Sobject sObj = Database.query(queryFields);
                system.debug('line 1393-->>'+sObj);
                
                for(Screen_Field__c sf: screenFields){
                    if (prodName == 'Home Loan' && sf.Storage_Field__c == 'Relationship_with_Applicant__c') {
                        continue; 
                    }
                    if (prodName != 'Home Loan' && sf.Storage_Field__c == 'Relationship_with_Applicant_HL__c') {
                        continue; 
                    }
                    
                    if(sObj.get(sf.Storage_Field__c) == null||sObj.get(sf.Storage_Field__c) == ''){
                    system.debug('line 1398-->>'+sf.Storage_Field__c);
                        showSubmit=false;
                        break;
                    }
                }
            }
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        System.debug('showSubmit----'+showSubmit);
        return showSubmit;
    }
    
    @AuraEnabled
    public static string recordTypeId(String recordId, String objectName){
        try {
            String RecordTypeName;
            if(objectName == 'Legal__c'){
                 List<Legal__c> ld =[Select id, RecordType.Name from Legal__c where id=:recordId];
                 RecordTypeName = ld[0].RecordType.Name;
            }
            else if(objectName == 'Technical_Evaluation__c'){
                 List<Technical_Evaluation__c> ld =[Select id, RecordType.Name from Technical_Evaluation__c where id=:recordId];
                 RecordTypeName = ld[0].RecordType.Name;
            }
            else if(objectName == 'Product2'){
                List<Product2> prod =[Select id,RecordType.Name from Product2 where id=:recordId];
                 RecordTypeName = prod[0].RecordType.Name;
            }
            return RecordTypeName;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

   
    public class AssigneeWrapperNew {
    public Map<String, List<Map<String, String>>> assigneeInfo { get; set; }
    public Map<Id, Map<String, String>> assigneeMap { get; set; }
    public String assigneeName { get; set; }
    public Id assigneeID { get; set; }

    public AssigneeWrapperNew(
        Map<String, List<Map<String, String>>> assigneeInfo, 
        Map<Id, Map<String, String>> assigneeMap, 
        String assigneeName, 
        Id assigneeID
    ) {
        this.assigneeInfo = assigneeInfo;
        this.assigneeMap = assigneeMap;
        this.assigneeName = assigneeName;
        this.assigneeID = assigneeID;
    }
}
        // @AuraEnabled
        // public String assigneeName { get; set; }
        
        // @AuraEnabled
        // public Id assigneeID { get; set; }
    
        // @AuraEnabled
        // public Map<String , Map<String,String>> assigneeMap1 {get;set;}

        // @AuraEnabled
        // public Map<String, Map<String, List<Map<String, String>>>> assigneeInfo { get; set; }

        // public AssigneeWrapperNew(String assigneeName, Id assigneeID, Map<String, Map<String, List<Map<String, String>>>> assigneeInfo , Map<String , Map<String,String>> assigneeMap1) {
        //     this.assigneeName = assigneeName;
        //     this.assigneeID = assigneeID;
        //     this.assigneeInfo = assigneeInfo;
        //     this.assigneeMap1 = assigneeMap1;
        // }
    //}
    @AuraEnabled
    public static void saveRemarksFI(Id recordId, String status, String comment) {
        Map<Id,String> appVerToRem = new Map<Id,String>();
        try {
            //Hl-Ishi-17/09
            String sObjName = recordId.getSObjectType().getDescribe().getName();
            List<Application_Verification__c> fiList = new  List<Application_Verification__c>();
            List<Legal__c> legalRecord = new List<Legal__c>();
            //HL-Ishi-17/09
            if(sObjName =='Legal__c'){
                legalRecord = [ Select id,OwnerId,HL_Assigned_to_Admin__c,HL_Assigned_to_Executive__c,Stage__c from Legal__c
                                where id=:recordId
                ];
            }
          
            if(!legalRecord.isEmpty()){
                System.debug('Inside legal');
                String title = '';
                String formattedRemarks = '';
                 Map<String,String> inputMap = new Map<String,String>();
                Legal__c record = legalRecord[0];
                  if (status.trim() =='Assigned to Admin') {
                    title = 'Assigned to Admin';
                   
                    inputMap.put('newRemarks',comment);
                    formattedRemarks = Utility_V1.getFormattedRemarks(inputMap);
                     System.debug('Inside legal formattedRemarks' +formattedRemarks);
                    // record.Credit_Manager_s_Remarks__c = Utility.getFormattedRemarks(comment, record.Credit_Manager_s_Remarks__c);
                } 
                if (status.trim() =='Hold') {
                    title = 'Hold';
                   
                    inputMap.put('newRemarks',comment);
                    formattedRemarks = Utility_V1.getFormattedRemarks(inputMap);
                     System.debug('Inside legal formattedRemarks' +formattedRemarks);
                    // record.Credit_Manager_s_Remarks__c = Utility.getFormattedRemarks(comment, record.Credit_Manager_s_Remarks__c);
                } 
                if (String.isNotBlank(formattedRemarks)) {
                System.debug('Inside legal formattedRemarks' +formattedRemarks);
                List<Legal__c> recordList = new List<Legal__c>{ record };
                Map<Id, String> remarksMap = new Map<Id, String>();
                remarksMap.put(record.Id, formattedRemarks);
                Utility.createNotesRecords(title, remarksMap);
                }
            }
            //HL-Ishi-17/09
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
 
   /* @AuraEnabled(cacheable=true)
    public static List<ApplicationVerificationHistoryWrapper> getVerificationHistory(String loanAppId,String objectApiName) {

        List<ApplicationVerificationHistoryWrapper> results = new List<ApplicationVerificationHistoryWrapper>();

      if(objectApiName == 'Technical_Evaluation__c'){
            List<Technical_Evaluation__History> technicalrecords = [
                SELECT Id, OldValue, NewValue, Field, ParentId, Parent.Name 
                FROM Technical_Evaluation__History 
                WHERE Parent.HL_Loan_Application__c = :loanAppId
                AND Field IN ('HL_Assigned_to_Technical_Admin__c', 'HL_Stage__c', 'HL_Assigned_to_Technical_Executive__c','HL_Assigned_to_Technical_Manager__c')
            ];

            // Wrap results to flatten Parent.Name (for easier handling in LWC)
            for(Technical_Evaluation__History rec : technicalrecords){
                results.add(new ApplicationVerificationHistoryWrapper(
                    rec.Id,
                    rec.OldValue == null ? null : String.valueOf(rec.OldValue),
                    rec.NewValue == null ? null : String.valueOf(rec.NewValue),
                    rec.Field,
                    rec.ParentId,
                    rec.Parent.Name
                ));
            }
            return results;
        }
        else if(objectApiName == 'Legal__c'){
            List<Legal__History> legalHistoryRecords = [
                SELECT Id, OldValue, NewValue, Field, ParentId, Parent.Name 
                FROM Legal__History 
                WHERE Parent.Loan_Application__c = :loanAppId
                AND Field IN ('Assigned_to_Admin__c', 'Stage__c', 'Assigned_to_Executive__c	')
            ];
            // Wrap results to flatten Parent.Name (for easier handling in LWC)
            for(Legal__History rec : legalHistoryRecords){
                results.add(new ApplicationVerificationHistoryWrapper(
                    rec.Id,
                    rec.OldValue == null ? null : String.valueOf(rec.OldValue),
                    rec.NewValue == null ? null : String.valueOf(rec.NewValue),
                    rec.Field,
                    rec.ParentId,
                    rec.Parent.Name
                ));
            }
            return results;
        }
        return null;
    }*/

   @AuraEnabled(cacheable=true)
  public static string getOwnerName(string recordId){
    string OwnerName;
    List<Legal__c> fiRecord = [SELECT Id,OwnerId,Name  FROM Legal__c WHERE Id =:recordId limit 1];
    if(fiRecord.size()>0){
        OwnerName = fiRecord[0].OwnerId;
    }
    return OwnerName;
  }

   @AuraEnabled(cacheable=true)
  public static string getProductNameFromLA(string recordId){
    string productName;
    Legal__c opp = [SELECT Id,Loan_Application__r.Product__c FROM Legal__c where Id =: recordId limit 1];
    productName = opp.Loan_Application__r.Product__c;
    return productName;
  }
     
    // Wrapper class to include Parent.Name directly
   /* public class ApplicationVerificationHistoryWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String OldValue;
        @AuraEnabled public String NewValue;
        @AuraEnabled public String Field;
        @AuraEnabled public Id ParentId;
        @AuraEnabled public String ParentName;

        public ApplicationVerificationHistoryWrapper(Id Id, String OldValue, String NewValue, String Field, Id ParentId, String ParentName) {
            this.Id = Id;
            this.OldValue = OldValue;
            this.NewValue = NewValue;
            this.Field = Field;
            this.ParentId = ParentId;
            this.ParentName = ParentName;
        }
    }*/ 

   /* public class AddressWrapper {
    public Id addressId;
    public Id applicantId;
    public String city;
    public String name;
    public String pincode;
    public String addressLine1;
    public String fullAddress;

    public AddressWrapper(Id addressId, Id applicantId, String city, String name, String pincode, String addressLine1, String fullAddress) {
        this.addressId = addressId;
        this.applicantId = applicantId;
        this.city = city;
        this.name = name;
        this.pincode = pincode;
        this.addressLine1 = addressLine1;
        this.fullAddress = fullAddress;
    }
}*/

}