/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 02-26-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
public class OneView {
    public class DetailsWrapper {
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public List<String> fieldValue; // Fixed List type
        @AuraEnabled public Object lookUpfieldValue;
        @AuraEnabled public Double sequence;
    }
    
    @AuraEnabled
    public static List<DetailsWrapper> getLoanDetailsFromStorageObject(String screenName, String loanId, String formIdentifier) {
        try {
            List<DetailsWrapper> rowFields = new List<DetailsWrapper>();
            
            List<Screen_Field__c> screenFieldList = [
                SELECT Id, Field_Label__c, Field_Placement__c, Storage_Field__c, Storage_Object__c, 
                       Field_Sequence__c, is_Lookup__c, Read_Field_Name__c ,Read_Object_Name__c
                FROM Screen_Field__c 
                WHERE Is_Active__c = true 
                      AND Parent_Screen__r.Is_Screen_Active__c = true 
                      AND Parent_Screen__r.Master_Screen_Name__c = :screenName 
                      AND Parent_Screen__r.Form_Name__c = :formIdentifier
                ORDER BY Field_Sequence__c ASC
            ];
            
            // Maps to store field mappings
            Map<String, List<String>> objectToFieldsMap = new Map<String, List<String>>();
            Map<String, String> fieldApiToLabelMap = new Map<String, String>();
            
            for (Screen_Field__c sc : screenFieldList) {
                fieldApiToLabelMap.put(sc.Read_Field_Name__c, sc.Field_Label__c);
                if (!objectToFieldsMap.containsKey(sc.Read_Object_Name__c)) {
                    objectToFieldsMap.put(sc.Read_Object_Name__c, new List<String>());
                }
                objectToFieldsMap.get(sc.Read_Object_Name__c).add(sc.Read_Field_Name__c);
            }
            
            Map<String, List<SObject>> objectValuesMap = new Map<String, List<SObject>>();
            String sn = (screenName == null) ? '' : screenName.trim();
            
            for (String objectName : objectToFieldsMap.keySet()) {
                List<String> fieldApiNames = objectToFieldsMap.get(objectName);
                String query = 'SELECT Id';
                
                for (String field : fieldApiNames) {
                    if(String.isNotBlank(field)) {
                        query += ', ' + field;
                    }
                    
                }
                //Id = :recordId
                if (objectName == 'Opportunity') {
                    query += ' FROM ' + objectName + ' WHERE Id = :loanId LIMIT 1';
                } else if (objectName == 'Application_Applicant__c') {
                    query += ' FROM ' + objectName + ' WHERE Loan_Application__c = :loanId';
                }
                else if (objectName == 'Bank_Details__c') {
                    query += ' FROM ' + objectName + ' WHERE Application_Applicant__r.Loan_Application__c = :loanId ';
                }
                else if(objectName == 'Sanction_Condition__c'){
                    query += ' FROM ' + objectName + ' WHERE Loan_Application__c = :loanId ';
                }
                else if(objectName == 'Income_Expense_Obligation__c'){
                    query += ' FROM ' + objectName + ' WHERE Loan_Application__c = :loanId ';
                }
                else if(objectName == 'Bank_Statement_Analysis__c'){
                    query += ' FROM ' + objectName + ' WHERE Loan_Application__c = :loanId ';
                }
                else if(objectName == 'Application_Deviation__c'){
                    query += ' FROM ' + objectName + ' WHERE Loan_Application__c = :loanId ';
                }
                else if(objectName == 'Applicant_Address__c'){
                    query += ' FROM ' + objectName + ' WHERE Loan_Application__c = :loanId ';
                }
                else if(objectName == 'Technical_Evaluation__c'){
                    query += ' FROM ' + objectName + ' WHERE HL_Loan_Application__c = :loanId ';
                }
                else if(objectName == 'Legal__c'){
                    query += ' FROM ' + objectName + ' WHERE Loan_Application__c = :loanId ';
                }
                else if (objectName == 'Application_Verification__c') {
                    query += ' FROM ' + objectName + ' WHERE Loan_Application__c = :loanId';
                    if (sn.equalsIgnoreCase('Personal Discussion Details')) {
                        query += ' AND RecordType.DeveloperName = \'Personal_Discussion\'';
                    }
                    if (sn.equalsIgnoreCase('FCU')) {
                        query += ' AND RecordType.DeveloperName = \'FCU\'';
                    }
                    else if (sn.equalsIgnoreCase('Field Investigations') || sn.equalsIgnoreCase('FI')) {
                        query += ' AND RecordType.DeveloperName IN (\'Business_Verification\', \'Residence_Verification\', \'Collateral_Verification\')';
                    }
                    else if (sn.equalsIgnoreCase('Asset or Wealth Created')) {
                         query += ' AND RecordType.DeveloperName = \'Asset\'';
                    }
                }
                System.debug('Object Name: ' + objectName);//
                System.debug('Query: ' + query);
                List<SObject> sObjList = Database.query(query);
                if (!sObjList.isEmpty()) {
                    objectValuesMap.put(objectName, sObjList);
                }
            }
            
            for (Screen_Field__c sc : screenFieldList) {
                if (objectValuesMap.containsKey(sc.Read_Object_Name__c)) {
                    List<SObject> sObjList = objectValuesMap.get(sc.Read_Object_Name__c);
                    
                    for (SObject sObj : sObjList) {
                        if(String.isNotBlank(sc.Read_Field_Name__c)) {
                            DetailsWrapper dw = new DetailsWrapper();
                            dw.fieldLabel = sc.Field_Label__c;
                            dw.fieldApiName = sc.Read_Field_Name__c;
                            
                            Object rawValue;
                            
                            rawValue = ScreenGenerationController.get(sObj,String.valueOf(sc.Read_Field_Name__c));
                            
                            
                            if (rawValue instanceOf List<Object>) {
                                if (((List<Object>) rawValue).isEmpty()) {
                                    dw.fieldValue = new List<String>{'--'}; // Set 'NA' if the list is empty
                                } else {
                                    dw.fieldValue = (List<String>) rawValue;
                                }
                            } else {
                                dw.fieldValue = new List<String>{rawValue != null ? String.valueOf(rawValue) : '--'}; // Set 'NA' if value is null
                            }
                            
                            dw.sequence = sc.Field_Sequence__c;
                            rowFields.add(dw);
                        }
                    }
                }
            }
            
            return rowFields;
        } catch (Exception e) {
            System.debug('Error: ' + e);
            System.debug('Error message: ' + e.getMessage() + ' \n StackTrace: ' + e.getStackTraceString());
            
            return new List<DetailsWrapper>();
        }
    }
    
    
    
    public static Object get(SObject record, String field) {
        if (record == null) return null;
        if (!field.contains('.')) return record.get(field);
        return get(record.getSObject(field.substringBefore('.')), field.substringAfter('.'));
    }
    
    
    @AuraEnabled
    public static List<SourcingDetailsWrapRow> getSourcingDetailsFields(String loanId){
        List<SourcingDetailsWrapRow> rowsDataLst = new List<SourcingDetailsWrapRow>();
        Opportunity opp = [SELECT Id, Product__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
        String formName = 'Cam Details';
        
        // Step 2: Switch form based on Product
        if (opp.Product__c != null && opp.Product__c.equalsIgnoreCase('HOME LOAN')) {
            formName = 'HL Cam Details'; // 👈 Load HL version dynamically
        }
        
        System.debug('Using formName: ' + formName);
        
        List<Screen_Field__c> screenListMain = ScreenGenerationController.getScreenDetails(formName,null);
        List<Screen_Field__c> screenList = new List<Screen_Field__c>();
        Set<String> fieldApiList = new Set<String>();
        for(Screen_Field__c sc : screenListMain){
            if(sc.Parent_Screen__r.Master_Screen_Name__c == 'Sourcing Details'){
                if(sc.Storage_Object__c == 'Opportunity'){
                    screenList.add(sc);
                    if(String.isNotBlank(sc.Read_Field_Name__c)) {
                        fieldApiList.add(sc.Read_Field_Name__c);
                    }
                    
                }
            }
        }
        //List<Opportunity> loan = [SELECT id,Lead__c FROM Opportunity WHERE  id=:loanId];
        if (fieldApiList.isEmpty()) {
            return rowsDataLst;
        }
        
        String sQUERY;
        sQUERY = 'SELECT '+String.join(fieldApiList,',')+' FROM Opportunity'+' WHERE id = \''+loanId+'\'';
        
        List<Opportunity> apDetList = DataBase.query(sQUERY);
        
        for (Integer i = 0; i < screenList.size(); i += 3) {
            SourcingDetailsWrapRow rowData = new SourcingDetailsWrapRow();
            List<SourcingDetailsWrapData> lstdata = new List<SourcingDetailsWrapData>();
            for (Integer j = i; j < Math.min(i + 3, screenList.size()); j++) {
                Object val;
                if(fieldApiList.contains(screenList[j].Read_Field_Name__c)) {
                    val = ScreenGenerationController.get((Sobject)apDetList[0],String.valueOf(screenList[j].Read_Field_Name__c));
                }
                
                String fieldVal = String.valueOf(val);
                SourcingDetailsWrapData tempObj = new SourcingDetailsWrapData();
                tempObj.header = screenList[j].Field_Label__c;
                if(fieldVal != null) {
                    tempObj.value = fieldVal;
                }else {
                    tempObj.value = '';
                }
                lstdata.add(tempObj);
            }
            rowData.tableData = lstdata;
            rowsDataLst.add(rowData);
        }
        System.debug('rowsDataLst '+rowsDataLst);
        
        return rowsDataLst;
    }
    @AuraEnabled
    
    public static void uploadPDF(String base64Data, String loanId) {
        
        List<Opportunity> opObj = [SELECT id, Name FROM Opportunity WHERE Id =:loanId ];
        
        List<Application_Applicant__c> applicantList = [ SELECT Id, Name, Applicant_Type__c  FROM Application_Applicant__c  WHERE Loan_Application__c = :loanId ];
        
        ContentVersion cv = new ContentVersion();
        
        cv.Title = opObj[0].Name;
        
        cv.PathOnClient =  opObj[0].Name+ '.pdf';
        
        cv.VersionData = EncodingUtil.base64Decode(base64Data);
        
        insert cv;
        
        ContentVersion cvObj = [SELECT id,ContentDocumentId FROM ContentVersion WHERE id=:cv.id];
        
        List<Document_Master__c> dm = [SELECT id FROM Document_Master__c WHERE Name = 'CAM'];
        
        Document_Details__c crimeCheckDoc = new Document_Details__c();
        
        crimeCheckDoc.Name = 'CAM_PDF';
        
        if(dm.size() > 0) {
            
            crimeCheckDoc.Document_Master__c = dm[0].id;
            
        }
        
        crimeCheckDoc.Content_Document_Id__c = cvObj.ContentDocumentId;
        
        crimeCheckDoc.Loan_Application__c = loanId;
        
        crimeCheckDoc.Status__c = 'Uploaded';
        
        crimeCheckDoc.Consider_for_Loan_Application__c = true;
        
        crimeCheckDoc.Remarks__c = 'CAM PDF';
        
        if(!Test.isRunningTest()){
        crimeCheckDoc.Document_Category__c ='CAM';
        }
        
        
        if (!applicantList.isEmpty()) {
            crimeCheckDoc.Applicant__c = applicantList[0].Id;
        }
        
        insert crimeCheckDoc;
        
        List<ContentDocumentLink> cdList= new List<ContentDocumentLink>();
        
        List<Document_Details__c> doc=[Select id,Content_Document_Id__c from Document_Details__c where id =:crimeCheckDoc.id and Content_Document_Id__c!=null];
        
        for(Document_Details__c d: doc){
            
            ContentDocumentLink cdl = new ContentDocumentLink();
            
            cdl.LinkedEntityId = d.Id;
            
            cdl.ContentDocumentId = d.Content_Document_Id__c;
            
            cdl.ShareType = 'V';
            
            cdl.Visibility = 'AllUsers';
            
            cdList.add(cdl);
            
        }
        
        insert cdList;
        
    }
        //added new
        @AuraEnabled(cacheable=true)
        public static Boolean checkIfPDFExists(String loanId) {
            List<Document_Details__c> existingDocs = [
        SELECT Id
        FROM Document_Details__c
        WHERE Loan_Application__c = :loanId
        AND Name = 'CAM_PDF'
        LIMIT 1
    ];
            return existingDocs.size() > 0;
        }//new added
        
        public class SourcingDetailsWrap {
            public List<SourcingDetailsWrapRow> tableDataRow;
        }
        public class SourcingDetailsWrapRow {
            @AuraEnabled public List<SourcingDetailsWrapData> tableData;
        }
        public class SourcingDetailsWrapData {
            @AuraEnabled public String header;
            @AuraEnabled public String value;
        }

        @AuraEnabled
        public static Map<string, List<object>> getSalaryDetails(String loanId) {
            Map<string, List<object>> result = new Map<string, List<object>>();
            
            for(Income_Assessment__c item : [Select Id, Applicant__c, Applicant__r.Applicant_Name__c from Income_Assessment__c where Loan_Application__c =: loanId and 
                                                RecordType.Name = 'Salaried Individual' And Parent__c = null]){

                result.put(item.Applicant__r.Applicant_Name__c, new List<object> { HL_SalariedScreenController.getSalaryDetails(item.Id) });
                result.get(item.Applicant__r.Applicant_Name__c).add(HL_SalariedScreenController.getAllYearlyComponent(item.Id));
                result.get(item.Applicant__r.Applicant_Name__c).add(HL_SalariedScreenController.getAllIncentiveDetails(item.Id));

                List<Income_Assessment__c> rec = [Select Id, Yearly_Amount__c From Income_Assessment__c Where Loan_Application__c =: loanId And 
                                                    Applicant__c =: item.Applicant__c And RecordType.Name = 'Child Rental Income'];
                if(!rec.isEmpty()){
                    result.get(item.Applicant__r.Applicant_Name__c).add(rec[0].Yearly_Amount__c.toString());
                }
            }

            return result;
        }

        @AuraEnabled
        public static List<ProductWrapper> getRecoNotesDetails(String loanId) {
            List<ProductWrapper> pwList = new List<ProductWrapper>();
            Map<String, String> productToConDocIdMap = new Map<String, String>();
            Map<Id, ContentVersion> contDocIdToContVersionMap = new Map<Id, ContentVersion>();
            List<Opportunity> loanData = [SELECT Id, StageName, Loan_Hierarchy__c FROM Opportunity WHERE Id =: loanId];

            List<string> loanHirchy = new List<string>();
            loanHirchy.add('Parent');
            loanHirchy.add('Child');

            if(loanData[0].StageName != 'Credit Underwriting'){
                loanHirchy.clear();
                loanHirchy.add(string.isNotBlank(loanData[0].Loan_Hierarchy__c) ? loanData[0].Loan_Hierarchy__c : 'Parent');
            }
            
            List<Product2> prodList = [SELECT Id, Name FROM Product2 WHERE RecordType.Name = 'Product' 
                                        And Loan_Application__c =: loanId And Product_Type__c IN : loanHirchy];

            for(Document_Details__c doc : [SELECT Id, Content_Document_Id__c, Product__c FROM Document_Details__c WHERE Loan_Application__c =: loanId 
                                            AND Name = 'Loan Approval Comments' And Product__c IN : prodList]){
                
                productToConDocIdMap.put(doc.Product__c, doc.Content_Document_Id__c);
            }

            for(ContentVersion ver : [SELECT ContentDocumentId, VersionData FROM ContentVersion WHERE ContentDocumentId IN : productToConDocIdMap.values() 
                                        And IsLatest = true ORDER BY CreatedDate Desc]){
                
                if(!contDocIdToContVersionMap.containsKey(ver.ContentDocumentId)){
                    contDocIdToContVersionMap.put(ver.ContentDocumentId, ver);
                }
            }
            
            for(Product2 p : prodList) {
                ProductWrapper pw = new ProductWrapper();
                pw.productName = p.Name;
                
                if(productToConDocIdMap.containsKey(p.Id)) {
                    string conDocId = productToConDocIdMap.get(p.Id);

                    if(contDocIdToContVersionMap.containsKey(conDocId)){
                        List<StatusHistoryWrapper> historyRecords = new List<StatusHistoryWrapper>();
                        List<String> comments = contDocIdToContVersionMap.get(conDocId).VersionData.toString().split('%%-');

                        for(Integer i= comments.size()-1; i>=0; i--){
                            List<String> commentParts = comments[i].split('&&-');
                            integer commentPartsSize = commentParts.size();
                            
                            if(commentPartsSize >= 4){
                                StatusHistoryWrapper historyWrp = new StatusHistoryWrapper();
                                historyWrp.status = commentParts[0] == null ? '' : commentParts[0];
                                historyWrp.remarks = commentParts[1] == null ? '' : commentParts[1].replace('<p>', '').replace('</p>', '\n');
                                historyWrp.timeStamp = commentParts[2] == null ? null : (DateTime.valueOf(commentParts[2].replace(',', ''))).format('dd/MM/yyyy hh:mm:ss');
                                historyWrp.user = commentParts[3] == null ? '' : commentParts[3];
                                historyWrp.approvalType = commentPartsSize == 5 ? (commentParts[4] == null ? '' : commentParts[4]) : '';
                                historyRecords.add(historyWrp);
                            }
                        }

                        pw.statusHistory = historyRecords;
                    }
                }

                pwList.add(pw);
            }

            return pwList;
        }
        
        public class StatusHistoryWrapper{
            @AuraEnabled public String status;
            @AuraEnabled public String remarks;
            @AuraEnabled public String user;
            @AuraEnabled public String timeStamp;
            @AuraEnabled public String approvalType;
        }

        public class ProductWrapper{
            @AuraEnabled public String productName{get; set;}
            @AuraEnabled public List<StatusHistoryWrapper> statusHistory;
        }
    }