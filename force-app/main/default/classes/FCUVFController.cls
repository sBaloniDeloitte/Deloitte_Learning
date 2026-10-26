/*
* Author    :   Deloitte India
* Purpose   :   FCU report generation controller class
* @last modified on  : 
* @last modified by  : 
*/

public with sharing class FCUVFController {
    private Id recordId;
    public String headerData{get;set;}
    //public String samplingDate{get;set;}
    //public String reportDate{get;set;}
    public String loanNumber{get;set;}
    public Decimal loanAmount{get;set;}
    public String cluster{get;set;}
    public String branchName{get;set;}
    public String state{get;set;}
    public String product{get;set;}
    public String customerName{get;set;}
    public String sampledDocs{get;set;}
    public String status{get;set;}
    public String agencyName{get;set;}
    public String verificationRemark{get;set;}
    public Boolean isImagePresent {get;set;}
    public List<ImageWrapper> images {get;set;}
    public String initiationDate{get;set;}
    public String closedDate{get;set;}
    public String vendorName{get;set;}
    public String applicantName{get;set;}
    public String samplername{get;set;}
    
    

    public Map<String, List<DocumentInfo>> reportNameToDocumentsMap { get; private set; }
    public Map<String, List<fcuRecords>> reportNameToDocumentsMap1 {get; set;}


    public FCUVFController(ApexPages.StandardController controller){
        this();
    }

    public FCUVFController() {
        try {
            this.recordId = ApexPages.currentPage().getParameters().get('Id');
            System.debug('this.recordId -->'+this.recordId);
            this.headerData = 'FCU Report';          

            String query = 'SELECT Id,Loan_Application__r.Loan_Application_Number__c, Loan_Application__r.Product__c,Applicant__r.Name,Loan_Application__r.Requested_Amount__c, Vendor__r.name ,Sample_Date__c, Approved_Date__c, Verification_Status__c, Owner.Name, Report_Name__c, Loan_Application__r.Name, Primary_Applicant__c, Co_Applicant_s__c, Report_Date__c, Cluster__c, Product__c, State__c, Branch__r.Name, Sampler_Remarks__c, Approval_Status__c,CreatedBy.name FROM Application_Verification__c  WHERE Id = \'' + this.recordId + '\' LIMIT 1'; 
            Application_Verification__c parentFraudStatus = Database.query(query);

            this.loanNumber = parentFraudStatus.Loan_Application__r.Name;
            this.loanAmount = parentFraudStatus.Loan_Application__r.Requested_Amount__c;
            this.cluster = parentFraudStatus.Cluster__c;
            this.branchName = parentFraudStatus.Branch__r.Name;
            this.state = parentFraudStatus.State__c;
            this.product = parentFraudStatus.Loan_Application__r.Product__c;
            this.customerName = parentFraudStatus.Primary_Applicant__c + ', ' + parentFraudStatus.Co_Applicant_s__c;
            this.status = parentFraudStatus.Verification_Status__c;
            this.agencyName = parentFraudStatus.Owner.Name;
            this.vendorName = parentFraudStatus.Vendor__r.name;
            this.initiationDate = Datetime.valueOf(parentFraudStatus.Sample_Date__c).format('yyyy-MM-dd HH:mm:ss');
            this.closedDate = Datetime.valueOf(parentFraudStatus.Sample_Date__c).format('yyyy-MM-dd HH:mm:ss');
            this.applicantName = parentFraudStatus.Applicant__r.Name;
            this.samplername = parentFraudStatus.CreatedBy.name;
            List<Id> childIds = new List<Id>();
            for(Application_Verification__c iterFraud : [SELECT Id, Report_Name__c, Verification_Remarks__c,Sampler_Name__c /*Verification_Remark_History__c*/ FROM Application_Verification__c WHERE Parent_FCU__c =: this.recordId and Stage__c != 'Not Accepted By Admin']){
                childIds.add(iterFraud.Id);
                this.sampledDocs = this.sampledDocs != '' && this.sampledDocs != null ? this.sampledDocs + ', ' + iterFraud.Report_Name__c : iterFraud.Report_Name__c;
                system.debug('sample docs are -->'+sampledDocs);
                this.verificationRemark = this.verificationRemark != '' && this.verificationRemark != null ? this.verificationRemark + iterFraud.Report_Name__c + '\n' + iterFraud.Verification_Remarks__c/*Verification_Remark_History__c*/ + '\n \n' : iterFraud.Report_Name__c + '\n' + iterFraud.Verification_Remarks__c/*Verification_Remark_History__c*/ + '\n \n';
            }
            this.verificationRemark = this.verificationRemark.replace('\n', '<br/>');

            String reverify = '';
            String reinitiate = '';

            this.images = new List<ImageWrapper>();
            List<Id> contentIds = new List<Id>();
            Map<String, List<Id>> contentIdsMap = new Map<String, List<Id>>();
            Integer documentSize = 0,currentDocument = 0;

            Map<String, List<DocumentInfo>> tempreportNameToDocumentsMap = new Map<String, List<DocumentInfo>>();
            
                for (Application_Verification__c documents : [SELECT Id, Name, Report_Name__c, Sampler_Remarks__c, Document_Detail__r.Content_Document_Id__c,Document_Detail__r.Name,(SELECT id,name,Content_Document_Id__c FROM Document_Details__r where Content_Document_Id__c!=null)from Application_Verification__c where id IN : childIds and Document_Detail__r.Content_Document_Id__c != null and stage__c != 'Cancelled']){
                contentIds.add(documents.Document_Detail__r.Content_Document_Id__c);
                DocumentInfo docInfo = new DocumentInfo(documents.Document_Detail__r.Name, documents.Document_Detail__r.Content_Document_Id__c, 'URL');
                String reportName = documents.Report_Name__c;
                if (!tempreportNameToDocumentsMap.containsKey(reportName)) {
                    tempreportNameToDocumentsMap.put(reportName, new List<DocumentInfo>());
                }
                    tempreportNameToDocumentsMap.get(reportName).add(docInfo);
                    if(documents.Document_Details__r.size() > 0) {
                        for(Document_Details__c iterDocs : documents.Document_Details__r) {
                            contentIds.add(iterDocs.Content_Document_Id__c);
                            DocumentInfo docInfoinner = new DocumentInfo(iterDocs.Name, iterDocs.Content_Document_Id__c, 'URL');
                            //String reportName = documents.Report_Name__c;
                            if (!tempreportNameToDocumentsMap.containsKey(reportName)) {
                                tempreportNameToDocumentsMap.put(reportName, new List<DocumentInfo>());
                            }
                            tempreportNameToDocumentsMap.get(reportName).add(docInfoinner);
                        }
                    }
            }
            System.debug('tempreportNameToDocumentsMap -->'+tempreportNameToDocumentsMap);
            Map<String, List<fcuRecords>> tempreportNameToDocumentsMap1 = new Map<String, List<fcuRecords>>();

            // Query the Document_Details__c object
            for(Application_Verification__c documents1 : [SELECT Id, Name, Report_Name__c, Sampler_Remarks__c, Full_Address__c , Document_Detail__r.Content_Document_Id__c,FCU_Check_type__c,Applicant__r.name,Document_Detail__r.Description__c ,Document_Detail__r.Name ,Status__c,Verification_Remarks__c,Verification_Status__c,stage__c   from Application_Verification__c WHERE id IN :childIds]){      //AND Content_Document_Id__c != null]) {
                if(documents1.stage__c != 'Cancelled')
               {
                String reportName = documents1.Report_Name__c;
                String remarks = documents1.Sampler_Remarks__c  ;
                String description = documents1.FCU_Check_type__c == 'Document'?documents1.Document_Detail__r.Name + '--'+ documents1.Document_Detail__r.Description__c:documents1.Applicant__r.name +'--'+documents1.Full_Address__c;
                String fcuCategory = documents1.Report_Name__c;
                string status = documents1.Verification_Status__c;
                string Remkars = documents1.Verification_Remarks__c;

                fcuRecords record = new fcuRecords(description, remarks, fcuCategory,status,Remkars);

                if (!tempreportNameToDocumentsMap1.containsKey(reportName)) {
                    tempreportNameToDocumentsMap1.put(reportName, new List<fcuRecords>());
                }
                
                tempreportNameToDocumentsMap1.get(reportName).add(record);
            }
        }
            this.reportNameToDocumentsMap1 = tempreportNameToDocumentsMap1;
            System.debug('tempreportNameToDocumentsMap1 -->'+tempreportNameToDocumentsMap1);
            List<ContentVersion> documents =  [SELECT Id, Title, VersionDataUrl, ContentDocumentId,FileType FROM ContentVersion WHERE ContentDocumentId =:contentIds];
            Map<String, String> contentVersionMap = new Map<String, String>();
            Map<String, String> contentFileTypeMap = new Map<String, String>();
            for (ContentVersion content : documents) {
                contentVersionMap.put(content.ContentDocumentId, content.VersionDataUrl);
                contentFileTypeMap.put(content.ContentDocumentId, content.FileType);
            }

            for (String reportName : tempreportNameToDocumentsMap.keySet()) {
                List<DocumentInfo> docList = tempreportNameToDocumentsMap.get(reportName);
                Integer index = 1;
                for (DocumentInfo docInfo : docList) {
                    if (contentVersionMap.containsKey(docInfo.contentId)) {
                        docInfo.imageUrl = contentVersionMap.get(docInfo.contentId);
                        docInfo.fileType = contentFileTypeMap.get(docInfo.contentId);
                    }
                }
            }

            this.reportNameToDocumentsMap = tempreportNameToDocumentsMap;
            
            System.debug('this.reportNameToDocumentsMap -->'+tempreportNameToDocumentsMap);

            this.isImagePresent = !tempreportNameToDocumentsMap.isEmpty();

            if(!this.isImagePresent){return;} 
        } catch (Exception exp) {
            Utility.generateException(exp, Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, 'FCUVFController');
        }
    }

    public class DocumentInfo {
        public String docName{get;set;}
        public String contentId{get;set;}
        public String imageUrl{get;set;}
        public String fileType { get; set; }
        
        public DocumentInfo(String docName, String contentId, String imageUrl) {
            this.docName = docName;
            this.contentId = contentId;
            this.imageUrl = imageUrl;
        }
    }

    public class ImageWrapper{
        public ContentVersion leftImageUrl{get;set;}
        public ContentVersion rightImageUrl{get;set;}

        public ImageWrapper(ContentVersion leftImageUrl,ContentVersion rightImageUrl){
            this.leftImageUrl = leftImageUrl;
            this.rightImageUrl = rightImageUrl;
        }
    }

    public class fcuRecords{
        public String description{get;set;}
        public String remarks{get;set;}
        public String fcuCategory{get;set;}
        public String status{get;set;}
        public String Remkars{get;set;}

        public fcuRecords(string description , String remarks, String fcuCategory , string status , string Remkars){
            this.description = description;
            this.remarks = remarks;
            this.fcuCategory = fcuCategory;
            this.status = status;
            this.Remkars = Remkars;
        }
    }
}