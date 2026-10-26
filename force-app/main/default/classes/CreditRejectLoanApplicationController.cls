public with sharing class CreditRejectLoanApplicationController {
    @AuraEnabled(cacheable=true)
    public static List<String> getRejectionReasons(){
        List<String> rejectionReasons= new List<String>();
        List<Rejection_Reason_Mapping__mdt> lstMeta = Rejection_Reason_Mapping__mdt.getAll().values();
        for( Rejection_Reason_Mapping__mdt pickListVal : lstMeta){
            rejectionReasons.add(pickListVal.Rejection_Reasons__c);
        }
        return rejectionReasons;
    }
    @AuraEnabled
    public static String getApprovalStatus(Id loanId){
        return [SELECT Approval_Status__c FROM Opportunity WHERE Id = :loanId LIMIT 1].Approval_Status__c;
    }


    @AuraEnabled
    public static string rejectLoan( String loanId, List<String> reason, String detailedReason){
        String res= 'fail';
        try {
            Boolean isSoftReject = false;
            Map<String,Rejection_Reason_Mapping__mdt> allMetaData = Rejection_Reason_Mapping__mdt.getAll();
            String loanStatus;
            for(Rejection_Reason_Mapping__mdt metadata: allMetaData.values()){
                if(reason.contains(metadata.Rejection_Reasons__c) && metadata.Rejection_Status__c == 'Soft Rejected 1'){
                    isSoftReject = true;
                }
            }
            
            Opportunity loan= new Opportunity();
            loan.Id= loanId;
            if(isSoftReject) {
                loan.Approval_Status__c = 'Soft Rejected 1';
            }else {
                loan.Approval_Status__c = 'Hard Rejected';
            }
            
                        
            loan.Reasons_for_Rejecting_Loan__c=String.join(reason, ';');
            loan.Detailed_Rejection_Reason__c=detailedReason;
            update loan;

            List<String> avaliableProducts= new List<String>{'Affordable Home Loan', 'Affordable Non-Home Loan', 'Home Loan', 'Non-Housing Loan', 'Flexi Loan'};
            List<Application_Applicant__c> applicantList= [SELECT Id,Customer_LMS_Id__c,Name_of_Organization__c, Loan_Application__r.name,Applicant_Type__c, Customer__r.SF_Customer_ID__c, Salutation__c,First_Name__c, Last_Name__c, Company__c, Loan_Application__r.Product__c, Email__c, Mobile_Number__c, Loan_Application__r.Owner.Name, Customer_Type__c FROM Application_Applicant__c WHERE Loan_Application__c = :loanId AND Applicant_Type__c = 'Primary Applicant'];
            List<product2> productList= [SELECT Id, name,Product__r.name, Description FROM product2 WHERE  Loan_Application__c = :loanId AND RecordType.name = 'Variant'];
            List<product2> mainProduct= [SELECT Id, name FROM product2 WHERE  Loan_Application__c = :loanId AND RecordType.name = 'Product' AND Product_Type__c = 'Parent'];
            //publish events
            String loanProduct;
            String messageWrapper;
            String type;
            Map<String, Communication_Event_Product_Mapping__mdt> productMetaMapping = Communication_Event_Product_Mapping__mdt.getAll();
            Map<String, Communication_Event_Product_Mapping__mdt> productMapping= new Map<String, Communication_Event_Product_Mapping__mdt>();
            for (Communication_Event_Product_Mapping__mdt metadata : productMetaMapping.values()){
                productMapping.put(metadata.Product_Name__c, metadata);
            }
            if(productList.size()>0){
                //loanProduct= productList[0].name;
            }
            if(mainProduct.size() > 0) {
                if(mainProduct[0].name == 'Affordable Home Loan') {
                    loanProduct = 'AH';
                }else if(mainProduct[0].name == 'Affordable Non-Home Loan') {
                    loanProduct = 'AL';
                }else if(mainProduct[0].name == 'Flexi Loan') {
                    loanProduct = 'FL';
                }
                else {
                    loanProduct= productMapping.get(productList[0].Product__r.name).Product_Name_in_Wrapper__c;
                }
            }
            if(!isSoftReject){
                type= 'Rejection-Hard Rejection';
                List<CommunicationEventWrapper.HardRejectWrapper> hardRejectList= new List<CommunicationEventWrapper.HardRejectWrapper>();
                for(Application_Applicant__c app:applicantList){
                    List<String> sfId= app.Customer__r.SF_Customer_ID__c.split('-');
                    String cifNumber = sfId[1].trim();
                    // loanProduct = app.Loan_Application__r.Product__c;
                    CommunicationEventWrapper.HardRejectWrapper rejectWrapper = new CommunicationEventWrapper.HardRejectWrapper();
                    rejectWrapper.Salutation = app.Customer_Type__c == 'Individual' ? (String.isNotBlank(app.Salutation__c) ? app.Salutation__c: '') : 'M/s';
                    rejectWrapper.FirstName = String.isNotBlank(app.First_Name__c)? app.First_Name__c :'';
                    rejectWrapper.LastName = String.isNotBlank(app.Last_Name__c) ? app.Last_Name__c: '';
                    rejectWrapper.CompanyName = app.Customer_Type__c == 'Individual' ? (String.isNotBlank(app.Company__c) ?  app.Company__c: '') :  (String.isNotBlank(app.Name_of_Organization__c) ?  app.Name_of_Organization__c: '');
                    rejectWrapper.ProductName = String.isNotBlank(loanProduct) ? loanProduct: '';
                    rejectWrapper.LANNumber = String.isNotBlank(app.Loan_Application__r.name) ? app.Loan_Application__r.name : '';
                    rejectWrapper.CustomerCategory = app.Customer_Type__c == 'Individual' ? 'RETAIL': (app.Customer_Type__c == 'Non Individual' ? 'CORP' :'' );
                    rejectWrapper.emailId = String.isNotBlank(app.Email__c) ? app.Email__c: '';
                    rejectWrapper.mobile_number = app.Mobile_Number__c != null ? String.valueOf(app.Mobile_Number__c): '';
                    rejectWrapper.applicantType = String.isNotBlank(app.Applicant_Type__c) ? app.Applicant_Type__c: '';
                    rejectWrapper.whatsaap_number = app.Mobile_Number__c != null ? String.valueOf(app.Mobile_Number__c): '';
                    rejectWrapper.ProductDescription = productList.size()>0 ? (productList[0].Description != null? productList[0].Description : '') : '';
                    rejectWrapper.cif = String.isNotBlank(app.Customer_LMS_Id__c) ? app.Customer_LMS_Id__c: cifNumber;
                    hardRejectList.add(rejectWrapper);
                }
                messageWrapper = JSON.serialize(hardRejectList);
            }else if(isSoftReject){
                type= 'Rejection-Soft Rejec1';
                List<OpportunityTeamMember> otm= [SELECT Id, User.Name FROM OpportunityTeamMember WHERE OpportunityId= :loanId AND TeamMemberRole = 'Sales' AND Associated_With_Loan_Application__c= true];
                List<CommunicationEventWrapper.SoftReject1Wrapper> softRejectList= new List<CommunicationEventWrapper.SoftReject1Wrapper>();
                for(Application_Applicant__c app:applicantList){
                    List<String> sfId= app.Customer__r.SF_Customer_ID__c.split('-');
                    String cifNumber = sfId[1].trim();
                    //loanProduct = app.Loan_Application__r.Product__c;
                    CommunicationEventWrapper.SoftReject1Wrapper rejectWrapper = new CommunicationEventWrapper.SoftReject1Wrapper();
                    rejectWrapper.Salutation = app.Customer_Type__c == 'Individual' ? (String.isNotBlank(app.Salutation__c) ? app.Salutation__c: '') : 'M/s';
                    rejectWrapper.FirstName = String.isNotBlank(app.First_Name__c)? app.First_Name__c :'';
                    rejectWrapper.LastName = String.isNotBlank(app.Last_Name__c) ? app.Last_Name__c: '';
                    rejectWrapper.CompanyName = app.Customer_Type__c == 'Individual' ? (String.isNotBlank(app.Company__c) ?  app.Company__c: '') :  (String.isNotBlank(app.Name_of_Organization__c) ?  app.Name_of_Organization__c: '');
                    rejectWrapper.ProductName = String.isNotBlank(loanProduct) ? loanProduct: '';
                    rejectWrapper.LANNumber = String.isNotBlank(app.Loan_Application__r.name) ? app.Loan_Application__r.name : '';
                    rejectWrapper.CustomerCategory = app.Customer_Type__c == 'Individual' ? 'RETAIL': (app.Customer_Type__c == 'Non Individual' ? 'CORP' :'' );
                    rejectWrapper.RelatioshipManager = otm.size()>0 ? otm[0].User.Name: '';
                    rejectWrapper.emailId = String.isNotBlank(app.Email__c) ? app.Email__c: '';
                    rejectWrapper.mobile_number = app.Mobile_Number__c != null ? String.valueOf(app.Mobile_Number__c): '';
                    rejectWrapper.applicantType = String.isNotBlank(app.Applicant_Type__c) ? app.Applicant_Type__c: '';
                    rejectWrapper.whatsaap_number = app.Mobile_Number__c != null ? String.valueOf(app.Mobile_Number__c): '';
                    rejectWrapper.ProductDescription = productList.size()>0 ? (productList[0].Description != null? productList[0].Description : '') : '';
                    rejectWrapper.cif = String.isNotBlank(app.Customer_LMS_Id__c) ? app.Customer_LMS_Id__c: cifNumber;
                    softRejectList.add(rejectWrapper);
                }
                messageWrapper = JSON.serialize(softRejectList);
            }

            if(messageWrapper != null && messageWrapper!= '' && loanProduct!= null && loanProduct!= ''){
                Integration_Details__c integration = new Integration_Details__c();
                integration.name = 'Communication Event';
                integration.Loan_Application__c = loanId;
                integration.Endpoint__c = type; 
                integration.Communication_Status__c = 'Published';
                integration.Request_JSON__c = messageWrapper;
                insert integration;

                System.debug('Message wrapper----'+messageWrapper);
                String commProduct;
                if(mainProduct.size() > 0) {
                    if(mainProduct[0].name == 'Affordable Home Loan') {
                        commProduct = 'Affordable Housing loan';
                    }else if(mainProduct[0].name == 'Affordable Non-Home Loan') {
                        commProduct = 'Affordable LAP';
                    }else if(mainProduct[0].name == 'Flexi Loan') {
                        commProduct = 'Flexible Loan';
                    }
                    else {
                        commProduct= productMapping.get(productList[0].Product__r.name).Product_Field__c;
                    }
                }
                
                Communication__e event = new Communication__e(
                    Message__c = messageWrapper,
                    Record_Id__c = integration.Id,
                    Type__c = type,
                    product__c = commProduct
                );
            
                Database.SaveResult result = EventBus.publish(event);
                if (result.isSuccess()) {
                    System.debug('Platform Event published successfully.'+result);
                } else {
                    // Log errors if publishing failed
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error publishing event: ' + error.getMessage());
                    }
                }
            }


            res='success';
        } catch (Exception e) {
            res = e.getMessage();
            throw new AuraHandledException(e.getMessage());
        }

        return res;
    }

    @AuraEnabled
   
    public static List<CommentsWrapper> fetchComments(String loanId)
    {
        List<OpportunityFieldHistory> remarksHistoryList= [SELECT Id, IsDeleted, OpportunityId, CreatedBy.Name, CreatedById, CreatedDate, Field, OldValue, NewValue FROM OpportunityFieldHistory WHERE OpportunityId= :loanId];
        
        List<CommentsWrapper> mainWrap = new list<CommentsWrapper>();
    
        for(OpportunityFieldHistory history:remarksHistoryList)
        {
            CommentsWrapper objWrap = new CommentsWrapper();
            
            objWrap.Comments=String.valueOf(history.NewValue);
            objWrap.Approvedby=history.CreatedBy.Name;
            
            mainWrap.add(objWrap);
        }
        return mainWrap;
    }

    public class CommentsWrapper{
        @AuraEnabled
        public String Comments;
        @AuraEnabled
        public String Approvedby;
        @AuraEnabled
        public String Action;
    }
}