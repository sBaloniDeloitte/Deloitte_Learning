/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-26-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

public with sharing class DocGenEsignRequestWrapper {
   
    public static DocGenESignJSONCreator docusignRequest(Id loanId, List<Document_Details__c> mergedDocument){
    set<Id> contentDocId                            =   new  set<Id> ();
    DocGenESignJSONCreator docusignReq	            =	new DocGenESignJSONCreator(); 
    Boolean isStampPaperRequired = true;

    Opportunity loanApp = [SELECT Id, Loan_Hierarchy__c, Split_Parent_Loan_Application__c FROM Opportunity WHERE Id = :loanId Limit 1];
    String requiredLoanId = loanApp.Split_Parent_Loan_Application__c!=null && loanApp.Loan_Hierarchy__c == 'Child' ? loanApp.Split_Parent_Loan_Application__c : loanId;
    List<Application_Applicant__c> applicantsList   =   [SELECT Id, Applicant_Name__c, Email__c, Mobile_Number__c, Customer_Type__c, Applicant_Type__c FROM Application_Applicant__c WHERE Loan_Application__c = :requiredLoanId Limit 4];    
    Opportunity op = [Select Id,name,Stamp_Paper__c,Authorized_Signatory__c,Authorized_Signatory__r.Name,Authorized_Signatory__r.Email,Authorized_Signatory__r.MobilePhone from Opportunity where Id=:loanId Limit 1];
    for(Document_Details__c dd : mergedDocument)
    {
        contentDocId.add(dd.Content_Document_Id__c);
        break;
    } 
    List<ContentVersion> esignDocumentContentVersion  =   [select Id, ContentDocumentId, Title, FileType, ContentSize from ContentVersion where ContentDocumentId IN: contentDocId ]; 
    
    DocGenESignJSONCreator.cls_authSignatoryDetails authSignatory = new DocGenESignJSONCreator.cls_authSignatoryDetails();
    // authSignatory.emailID               = 'anandita.kakwani@godrejcapital.com';
    // authSignatory.mobileNumber          = '8817411157';
    // authSignatory.name                  = 'Anandita Kakwani';
    authSignatory.emailID               = op.Authorized_Signatory__r.Email;
    authSignatory.mobileNumber          = op.Authorized_Signatory__r.MobilePhone;
    authSignatory.name                  = op.Authorized_Signatory__r.Name;
    docusignReq.authSignatoryDetails    =  authSignatory;

    List<DocGenESignJSONCreator.cls_applicants> coAppList                   = new List<DocGenESignJSONCreator.cls_applicants>();
    DocGenESignJSONCreator.cls_coApplicantDetails coApplicantDetails        = new DocGenESignJSONCreator.cls_coApplicantDetails();
    Integer count = 1;
    for(Application_Applicant__c app : applicantsList)
    {
        DocGenESignJSONCreator.cls_applicants applicants        = new DocGenESignJSONCreator.cls_applicants(); 
        DocGenESignJSONCreator.cls_customerDetails custDetails  = new DocGenESignJSONCreator.cls_customerDetails(); 
        if (app.Applicant_Type__c == 'Primary Applicant') {
            custDetails.mobileNumber = app.Customer_Type__c == 'Individual' ? app.Mobile_Number__c : null;
            custDetails.name         = app.Applicant_Name__c;
            // custDetails.emailID      = app.Customer_Type__c == 'Non Individual' ? app.Email__c : null; // not accepting null in req json
            custDetails.emailID      = app.Customer_Type__c == 'Non Individual' ? app.Email__c : app.Email__c;
            docusignReq.customerDetails = custDetails;
        }
        if (app.Applicant_Type__c == 'Co Applicant') {
            applicants.id           = String.valueOf(count);
            applicants.name         = app.Applicant_Name__c;
            // Apply same logic for email and mobile as Primary Applicant
            if (app.Customer_Type__c == 'Individual') {
                applicants.mobileNumber = app.Mobile_Number__c;
                applicants.emailID = null;
                // applicants.emailID = app.Email__c; //null;
            } else if (app.Customer_Type__c == 'Non Individual') {
                applicants.emailID = app.Email__c;
                applicants.mobileNumber = null;
            }

            coAppList.add(applicants);
            count++;
        }

    }

    coApplicantDetails.applicants   =   coAppList;
    docusignReq.coApplicantDetails = coApplicantDetails;
    docusignReq.contentId           =   esignDocumentContentVersion[0].Id;

    /*DocGenESignJSONCreator.cls_customerDetails custDetails  = new DocGenESignJSONCreator.cls_customerDetails();
    custDetails.mobileNumber        =   '9137335330';
    custDetails.name                =   'Dhiraj Traders';
    custDetails.emailID             =   ''; 
    docusignReq.customerDetails     =   custDetails;*/
   
    system.debug('mergedDocument[0].Merged_Document_Detail__c   '+mergedDocument[0].Merged_Document_Detail__c);
    DocumentWrapper merDocdetails = (DocumentWrapper) JSON.deserialize(mergedDocument[0].Merged_Document_Detail__c, DocumentWrapper.class);
    system.debug('merDocdetails   '+merDocdetails);
    List<DocGenESignJSONCreator.cls_documentAndPageNumbers> uploadDocpageNumList    =   new List<DocGenESignJSONCreator.cls_documentAndPageNumbers>();
    Map<String, Integer> docNameCounter = new Map<String, Integer>();
    for(DocumentAndPageNumber item : merDocdetails.documentAndPageNumbers)
    {
        DocGenESignJSONCreator.cls_documentAndPageNumbers uploadDocpageNum  =   new DocGenESignJSONCreator.cls_documentAndPageNumbers();
        String finalDocumentName = item.documentName;

        if (docNameCounter.containsKey(item.documentName)) {
            Integer docCount = docNameCounter.get(item.documentName) + 1;
            docNameCounter.put(item.documentName, docCount);
            finalDocumentName = item.documentName + '_' + docCount;
        } else {
            docNameCounter.put(item.documentName, 0);
        }

        // uploadDocpageNum.documentName           =  item.documentName;                     //conVer.Title.contains('.') ? conVer.Title.split('\\.')[0] : conVer.Title;                //conVer.Title +'.' + conVer.FileType.toLowerCase();
        uploadDocpageNum.documentName           =  finalDocumentName;     
        uploadDocpageNum.pageNumbers            =  Integer.valueOf(item.pageNumbers);                                     //(Integer)eSignDocumentList[0].Document_Page_Number__c;        //43;  
        uploadDocpageNumList.add(uploadDocpageNum);
    } 
    docusignReq.documentAndPageNumbers          =   uploadDocpageNumList;
    
    DocGenESignJSONCreator.cls_estampDetails estampDetails1             =   new DocGenESignJSONCreator.cls_estampDetails();
    List<DocGenESignJSONCreator.cls_estampDetails> estampDetailsList    =   new List<DocGenESignJSONCreator.cls_estampDetails>();
    List<Object> rawList = (List<Object>) JSON.deserializeUntyped(op.Stamp_Paper__c);
    for (Object obj : rawList) {
        Map<String, Object> item = (Map<String, Object>) obj;

        DocGenESignJSONCreator.cls_estampDetails estampDetail = new DocGenESignJSONCreator.cls_estampDetails();
        estampDetail.tagName = String.valueOf(item.get('name')).toUpperCase(); // e.g., GA-100-GA-100
        estampDetail.tagQuantity = Integer.valueOf(item.get('count'));
        estampDetailsList.add(estampDetail);
    }

    if (estampDetailsList.isEmpty()) {
        isStampPaperRequired = false;
    }
    
    docusignReq.estampDetails               =  estampDetailsList;
    docusignReq.lan                         =  mergedDocument[0].Loan_Application__r.Loan_Application_Number__c;
    docusignReq.stamppaperRequired = isStampPaperRequired;
    return docusignReq;
 }

    public class DocumentWrapper {
        public List<DocumentAndPageNumber> documentAndPageNumbers;
        public String id;
    }

    public class DocumentAndPageNumber {
        public String pageNumbers;
        public String documentName;
    }
}