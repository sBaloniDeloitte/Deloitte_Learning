public without sharing class LoanApplicationApprovalController {
    static string conLabels = 'Exception_select_disable,OrgWideFromAddressEmail,CC_Email_For_Loan_Approval,CC_Email_For_Sales_Exception_Approval';

    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }

    @AuraEnabled
    public static string submitLoanForExceptionApproval( String loanId, List<String> exceptReasons, String documentContentId, String comments){
        String res= 'fail';
        try {
            System.debug('commentss----'+comments);
            List<Opportunity> loanData= [SELECT Id, Branch_Master__c, Name FROM Opportunity WHERE Id = :loanId];

            Set<String> exceptionReasons= new Set<String>(exceptReasons);
            Map<Id, Integer> applicableUserToLevel= new Map<Id, Integer>();

            List<AccountTeamMember> acTeamMemberList= [SELECT Id, Eligible_Approver_Exception_Reasons__c, Level__c, UserId FROM AccountTeamMember WHERE AccountId = :loanData[0].Branch_Master__c AND Eligible_Approver_Exception_Reasons__c!= null];

            String approver;
            Boolean approverFound=false;
            for(AccountTeamMember acc:acTeamMemberList){
                List<String> reasonsList= acc.Eligible_Approver_Exception_Reasons__c.split(';');
                Set<String> reasonSet = new Set<String>(reasonsList);
                if(reasonSet.containsAll(exceptionReasons)){
                    approver = acc.UserId;
                    approverFound= true;
                    break;
                }else{
                    Set<String> listSet = new Set<String>(reasonsList);
                    listSet.retainAll(exceptionReasons);
                    if(!listSet.isEmpty() && acc.Level__c!= null){
                        String numericPart = acc.Level__c.substring(1);
                        Integer levelNumber = Integer.valueOf(numericPart); 
                        applicableUserToLevel.put(acc.UserId, levelNumber);
                    }
                }
            }
            
            Integer approverLevel=0;
            if(!approverFound){
                for(Id userId: applicableUserToLevel.keyset()){
                    Integer currentLevel= applicableUserToLevel.get(userId);
                    if(currentLevel > approverLevel){
                        approverLevel = currentLevel;
                        approver = userId;
                        approverFound= true;
                    }
                }
            }

            if(approver!= null && approver != '' && approverFound){
                Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                if(comments== null || comments== ''){
                    comments= 'Please review the exceptions in the loan.';
                }
                request.setComments(comments);
                request.setObjectId(loanId);
                request.setNextApproverIds(new Id[] { approver });
    
                request.setProcessDefinitionNameOrId('Sales_Exception_Approval');
    
                

                String currUserName= getCurrentUserName();
                Set<String> receipientIds= new Set<String>();
                receipientIds.add(approver);
                

                Document_Master__c dmObj = new Document_Master__c() ;
                List<Document_Master__c> masterList = [SELECT id, Name, Document_Name__c, Document_Category__c, Document_Categories__c FROM Document_Master__c WHERE Document_Name__c = 'Loan Exception Approval Document'] ;
                List<Document_Details__c> tempObj =  new List<Document_Details__c>() ;
                tempObj = [SELECT id, Version_Number__c FROM Document_Details__c WHERE Loan_Application__c = :loanId AND Name= 'Loan Exception Approval Document' ORDER BY Version_Number__c DESC] ;
                Integer version ;
                if(tempObj.size()>0){
                    version = (Integer)(tempObj[0].Version_Number__c) ;
                    version++ ;
                }
                else{
                    version = 1 ;
                }
                Document_Details__c newObj =  new Document_Details__c() ;
                newObj.Name = 'Loan Exception Approval Document' ;
                // newObj.Applicant__c = applicationId ;
                // newObj.Document_Master__c = dmObj.Id ;
                newObj.Loan_Application__c = loanId ;
                newObj.Content_Document_Id__c = documentContentId ;
                newObj.Active__c = true ;
                newObj.Version_Number__c = version ;
        
                insert newObj ;


                Opportunity loanApp= new Opportunity();
                loanApp.Id= loanId;
                loanApp.Exception_Approval_Status__c= 'Submitted For Approval';
                loanApp.Selected_Reasons_For_Exception_Approval__c  = String.join(exceptReasons, ';');
                update loanApp;

                Approval.process(request);

                List<String> sendToAddressesList = new List<String>();
                List<String> ccList= new List<String>();
                ccList.add(Constants.get('CC_Email_For_Sales_Exception_Approval'));
                // ccList.add('sales_exception_approval@xczvj8d9iatemlethm6pdjwg9lsvf369rxm4u6a4b1tz1hyx6.bi-1oxzwmau.ind14s.apex.sandbox.salesforce.com');
                List<User> userListMail= [SELECT Id, Name, Email FROM User WHERE Id =:approver];
                sendToAddressesList.add(userListMail[0].Email);
                // sendToAddressesList.add('yjangid@deloitte.com');
                List<Messaging.SingleEmailMessage> emailToUsers = new List<Messaging.SingleEmailMessage>();
                List<OrgWideEmailAddress> owdEmail =[SELECT Id FROM OrgWideEmailAddress WHERE Address=:constants.get('OrgWideFromAddressEmail')];
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                EMailTemplate temp= [SELECT Id,Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Sales_Exception_Approval' LIMIT 1];
                String body= temp.Body;
                // String body = temp.HtmlValue;
                body = body.replace('{#User}',userListMail[0].Name);
                body = body.replace('{#Name}',loanData[0].Name);
                body = body.replace('#ExceptionReasons', String.join(exceptReasons, ' ,'));
                body = body.replace('{#UserName}', currUserName);
                email.setOrgWideEmailAddressId(owdEmail[0].Id); 
                email.setTemplateId(temp.id);
                // email.setHTMLBody(body);
                email.setPlainTextBody(body);
                email.setToAddresses(sendToAddressesList);
                email.setCcAddresses(ccList);
                email.setSubject('Loan Application Exception '+loanData[0].Name+' - Approval Request');
                // email.setReplyTo('loan_application_approval@1zc1qf6ayshufdirj1p3qq3mu5o80rzoznahfyf53e5d9ojfh7.bi-1oxzwmau.ind14s.apex.sandbox.salesforce.com');  
                emailToUsers.add(email);

                Messaging.sendEmail(emailToUsers);

                sendActionNotification(loanId, 'Submit', receipientIds, currUserName, 'Exception Approval');
                res= 'success';
            }else {
                res= 'No approvers found for the exceptions';
            }         
        } catch (Exception e) {
            res= e.getMessage();
            
            // throw new AuraHandledException(e.getMessage());
        }
        return res;
    }

    public static String htmlToText(String html) {
        if (String.isBlank(html))return '';
        String plain = html.replaceAll('<[^>]+>', '');
        plain = plain.replaceAll('&nbsp;', ' ');
        plain = plain.replaceAll('&amp;', '&');
        plain = plain.replaceAll('&lt;', '<');
        plain = plain.replaceAll('&gt;', '>');
        System.debug('plain.trim() : '+plain.trim());
        return plain.trim();
    }

    
public static String buildEmailBody(Id loanAppId,String approverName,String comment) {
     User currentUser = [SELECT Id,Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    Opportunity loan = [
        SELECT Name, Loan_Purpose__c, Loan_Facility__c,
        (SELECT Id,Name  FROM Application_Applicant__r WHERE Applicant_Type__c = 'Primary Applicant')
        FROM Opportunity
        WHERE Id = :loanAppId
        LIMIT 1
    ];
    List<ProductWrapper> products = getAllProductData(loanAppId);
    List<Charges_Insurance__c> charges = getChargesRecords(loanAppId);

    String htmlBody = '<html><body style="font-family: Arial; font-size: 14px;">';
    htmlBody += '<p>Dear '+approverName+',</p>';
    htmlBody += '<p>Pricing approval request has been sent by '+ currentUser.Name +' for the loan application '+ loan.Name +' : '+ loan.Application_Applicant__r[0].Name+'.</p>';
   
    htmlBody += '<p><span style="color:red; font-weight:bold;">Kindly reply with "Approve", "Approved", "Ok" or "Reject", "Rejected", "Not ok"</span></p>';


    
if (!products.isEmpty()) {
    htmlBody += '<h3 style="font-size:14px;">Product Details</h3>';
    htmlBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%; font-size:12px;">';
    htmlBody += '<tr style="background-color:#f2f2f2;">' +
                '<th>Product</th><th>Sub Product</th><th>Transaction Type</th>' +
                '<th>Loan Purpose</th><th>Repayment Variant</th><th>Sub Variant</th>' +
                '<th>Loan Facility</th><th>Schema Name</th></tr>';

    for (ProductWrapper pw : products) {
        htmlBody += '<tr><td>' + safeValue(pw.productName) + '</td>';
        htmlBody += '<td>' + safeValue(pw.subProduct) + '</td>';
        htmlBody += '<td>' + safeValue(pw.transactionType) + '</td>';
        htmlBody += '<td>' + safeValue(pw.loanPurpose) + '</td>';
        htmlBody += '<td>' + safeValue(pw.repaymentVariant) + '</td>';
        htmlBody += '<td>' + safeValue(pw.subVariant) + '</td>';
        htmlBody += '<td>' + safeValue(pw.loanFacility) + '</td>';
        htmlBody += '<td>' + safeValue(pw.schemaName) + '</td></tr>';
    }

    htmlBody += '</table>';
}


    
    
if (!charges.isEmpty()) {
    htmlBody += '<h3 style="font-size:14px;">Charges Details :</h3>';
    htmlBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%; font-size:12px;">';
    htmlBody += '<tr style="background-color:#f2f2f2;">' +
                '<th>Product</th><th>Charge Type</th><th>Accrued Amount</th>' +
                '<th>Collected Fees(Excluding Tax)</th><th>Balance Fees</th>' +
                '<th>Waiver</th><th>Collected(Including Tax)</th><th>Fee Method</th></tr>';
    for (Charges_Insurance__c ch : charges) {
        htmlBody += '<tr><td>' + safeValue(ch.Product__r.Name) + '</td>';
        htmlBody += '<td>' + safeValue(String.valueOf(ch.Charges_Fee_Type__c)) + '</td>';
        htmlBody += '<td>' + safeValue(String.valueOf(ch.Default_Amount_INR__c)) + '</td>';
        htmlBody += '<td>' + safeValue(String.valueOf(ch.Login_Fees__c)) + '</td>';
        htmlBody += '<td>' + safeValue(String.valueOf(ch.Balance_Fees__c)) + '</td>';
        htmlBody += '<td>' + safeValue(String.valueOf(ch.Requested_Amount_INR__c)) + '</td>';
        htmlBody += '<td>' + safeValue(String.valueOf(ch.Final_Amount_INR__c)) + '</td>';
        htmlBody += '<td>' + safeValue(String.valueOf(ch.Fee_Method__c)) + '</td></tr>';
    }
    htmlBody += '</table>';
}

    
htmlBody += '<h3 style="font-size:14px;">Loan Details:</h3>';
htmlBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%; font-size:12px;">';
htmlBody += '<tr style="background-color:#f2f2f2;">' +
            '<th>Product</th><th>Parameters</th><th>Sanctioned Value</th><th>Negotiated Value</th></tr>';

for (ProductWrapper pw : products) {
    htmlBody += '<tr><td>' + safeValue(pw.productName) + '</td>';
    htmlBody += '<td>Loan Amount(INR)</td>';
    htmlBody += '<td>' + safeValue(pw.sanctionedLoanAmount) + '</td>';
    htmlBody += '<td>' + safeValue(pw.negotiatedLoanAmount) + '</td></tr>';

    htmlBody += '<tr><td>' + safeValue(pw.productName) + '</td>';
    htmlBody += '<td>ROI (In %)</td>';
    htmlBody += '<td>' + safeValue(pw.sanctionedLoanRoi) + '</td>';
    htmlBody += '<td>' + safeValue(pw.negotiatedLoanRoi) + '</td></tr>';

    htmlBody += '<tr><td>' + safeValue(pw.productName) + '</td>';
    htmlBody += '<td>Tenure(In Month)</td>';
    htmlBody += '<td>' + safeValue(pw.sanctionedLoanTenure) + '</td>';
    htmlBody += '<td>' + safeValue(pw.negotiatedLoanTenure) + '</td></tr>';
}

htmlBody += '</table>';

        htmlBody += '<p>Remarks: '+safeValue(comment)+'</p>';

    
    htmlBody += '<p>Thanks,</br>'+currentUser.Name+'</p>';
    htmlBody += '</body></html>';

    return htmlBody;
}


    public class ProductWrapper{
        @AuraEnabled public String productName;
        @AuraEnabled public String subProduct;
        @AuraEnabled public String loanAmount;
        @AuraEnabled public String loanRoi;
        @AuraEnabled public String loanTenure;
        @AuraEnabled public String transactionType;
        @AuraEnabled public String loanPurpose;
        @AuraEnabled public String repaymentVariant;
        @AuraEnabled public String subVariant;
        @AuraEnabled public String loanFacility;
        @AuraEnabled public String schemaName;
        @AuraEnabled public String negotiatedLoanAmount;
        @AuraEnabled public String negotiatedLoanRoi;
        @AuraEnabled public String negotiatedLoanTenure;
        @AuraEnabled public String sanctionedLoanAmount;
        @AuraEnabled public String sanctionedLoanRoi;
        @AuraEnabled public String sanctionedLoanTenure;

    }

    public static List<Charges_Insurance__c> getChargesRecords(String loanId){
        try{
        List<Charges_Insurance__c> chargesInsuranceList = [SELECT Id,Product__c,Charges_Fee_Type__c,Default_Amount_INR__c,Product__r.Name,
                                                                  Balance_Fees__c,Fee_Method__c,
                                                                  Login_Fees__c,Final_Amount_INR__c,Requested_Amount_INR__c
                                                                  FROM Charges_Insurance__c 
                                                                  WHERE Loan_Application__c = :loanId
                                                                  AND RecordType.Name ='Charges'];
        return chargesInsuranceList;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }

    }

   

    
public static List<ProductWrapper> getAllProductData(String loanId) {
    try {
        List<ProductWrapper> productList = new List<ProductWrapper>();
        List<Product2> productDetails = [
            SELECT Id, Name, RecordType.Name, Product__c, Loan_Application__r.Loan_Purpose__c,
                   Transaction_Type__c, Loan_Facility__c,Negotiated_Loan_Amount__c,Negotiated_ROI__c,
                   Negotiated_Tenure__c,Sanctioned_Loan_Amount__c,Sanctioned_Tenor__c,Sanctioned_ROI__c
            FROM Product2
            WHERE Loan_Application__c = :loanId
        ];

        Map<Id, Product2> parentProductToChild = new Map<Id, Product2>();
        List<Product2> parentProducts = new List<Product2>();

        for (Product2 rec : productDetails) {
            if (rec.Product__c != null) {
                parentProductToChild.put(rec.Product__c, rec);
            } else {
                parentProducts.add(rec);
            }
        }

        for (Product2 parent : parentProducts) {
            ProductWrapper wrapper = new ProductWrapper();
            wrapper.productName = safeValue(parent.Name);
            Product2 subProduct = parentProductToChild.get(parent.Id);
            if (subProduct != null) {
                wrapper.subProduct = safeValue(subProduct.Name);
                wrapper.transactionType = safeValue(subProduct.Transaction_Type__c);
                wrapper.loanPurpose = safeValue(subProduct.Loan_Application__r.Loan_Purpose__c);
                wrapper.loanFacility = safeValue(subProduct.Loan_Facility__c);
                wrapper.negotiatedLoanAmount = safeValue(String.valueOf(subProduct.Negotiated_Loan_Amount__c));
                wrapper.negotiatedLoanRoi = safeValue(String.valueOf(subProduct.Negotiated_ROI__c));
                wrapper.negotiatedLoanTenure = safeValue(String.valueOf(subProduct.Negotiated_Tenure__c));
                wrapper.sanctionedLoanAmount = safeValue(String.valueOf(subProduct.Sanctioned_Loan_Amount__c));
                wrapper.sanctionedLoanRoi = safeValue(String.valueOf(subProduct.Sanctioned_ROI__c));
                wrapper.sanctionedLoanTenure = safeValue(String.valueOf(subProduct.Sanctioned_Tenor__c));
                Product2 variant = parentProductToChild.get(subProduct.Id);
                if (variant != null) {
                    wrapper.repaymentVariant = safeValue(variant.Name);

                    Product2 subVariant = parentProductToChild.get(variant.Id);
                    if (subVariant != null) {
                        wrapper.subVariant = safeValue(subVariant.Name);

                        Product2 hybridTenure = parentProductToChild.get(subVariant.Id);
                        if (hybridTenure != null) {
                            Product2 scheme = parentProductToChild.get(hybridTenure.Id);
                            if (scheme != null) {
                                wrapper.schemaName = safeValue(scheme.Name);
                            } else {
                                wrapper.schemaName = '-';
                            }
                        }
                    }
                }
            }
            productList.add(wrapper);
        }
        return productList;

    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}


private static String safeValue(String val) {
    return (val != null && val.trim() != '') ? val : '-';
}






    
public static void sendEmailToAllApprovers(AccountTeamMember currentApprover, List<Opportunity> loanData, String decodedComment) {
    try{
    List<OrgWideEmailAddress> owdEmail = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :Label.Org_Wide_Address];

    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    List<String> sendToAddressesList = new List<String>();
    sendToAddressesList.add(currentApprover.User.Email);
    // sendToAddressesList.add('riagoel@deloitte.com');
    // sendToAddressesList.add('neawasthi@deloitte.com');
    // sendToAddressesList.add('sikarulkar@deloitte.com');

    email.setOrgWideEmailAddressId(owdEmail[0].Id);
    email.setSubject('Pricing Approval Request - ' + loanData[0].Name);
    email.setHtmlBody(buildEmailBody(loanData[0].Id,currentApprover.User.Name,decodedComment));
    email.setToAddresses(sendToAddressesList); // ✅ Add recipients here
    email.setReplyTo(Label.Pricing_Approval_Reply);

    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
    }catch(Exception e){
        throw new AuraHandledException(e.getMessage());
    }
}


    @AuraEnabled
    public static String submitLoanForApproval(String loanId, String approvalType,String comment){
        String res;
        String currentUserId= UserInfo.getuserId();
        try {
            List<Opportunity> loanData= [SELECT Id,Name, Branch_Master__c,Sanction_Tenure__c, Sanction_Rate_Of_Interest__c, Sanction_Loan_Amount__c, Negotiated_Tenure__c, Negotiated_Loan_Amount__c,Negotiated_Rate_Of_Interest__c,Pricing_Approval_Status__c FROM Opportunity WHERE Id = :loanId];
             List<String> loanApprovers;
           
            if(approvalType == 'pricing Approval'){
                loanApprovers =  getPricingApprover(loanId);
                if(loanApprovers.size() > 0){
                    loanApprovers.sort();
                }                
                System.debug('loanApprovers>>>>'+loanApprovers);      
            }
            else {
                loanApprovers = getLoanapprovers(loanId, approvalType);
            }

            if(loanApprovers.size() == 0){
                res = 'No approvers found for this loan';
            }else if(loanData.size()>0 && loanData[0].Branch_Master__c != null){
                String approverLevel= loanApprovers[loanApprovers.size()-1];

                List<AccountTeamMember> approverMembers = new List<AccountTeamMember>();
                if(approvalType == 'pricing Approval'){
                    //approverMembers = [SELECT Id, TeamMemberRole, Level__c, UserId FROM AccountTeamMember WHERE Level__c = :approverLevel AND TeamMemberRole = 'Credit' AND AccountId = :loanData[0].Branch_Master__c];
                    //commenting as of now to proceed with the build till we get a clarification
                    approverMembers = [SELECT Id, TeamMemberRole, Level__c, UserId,User.Email,User.Name FROM AccountTeamMember WHERE Level__c = :approverLevel AND TeamMemberRole = 'Sales' AND AccountId = :loanData[0].Branch_Master__c];
                }else{
                    System.debug('approverLevel  '+approverLevel);
                    System.debug('approverLevel  '+loanData[0].Branch_Master__c);
                    
                    approverMembers = [SELECT Id, TeamMemberRole, Level__c, UserId FROM AccountTeamMember WHERE Level__c = :approverLevel AND TeamMemberRole = 'Credit' AND AccountId = :loanData[0].Branch_Master__c];
                }
                Opportunity opp = [Select Id, Is_Eligible_for_Exception_Approval__c from Opportunity where Id = :loanId];
                ProcessDefinition prd = [SELECT Id, Name, DeveloperName, TableEnumOrId, Description FROM ProcessDefinition WHERE Name = 'Loan Application Approval'];
                if(approverMembers.size() > 0){
                    Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                    request.setComments(comment);
                    request.setObjectId(loanId);
                    request.setNextApproverIds(new Id[] { approverMembers[0].UserId });
        
                    request.setProcessDefinitionNameOrId('Loan_Application_Approval');
                    //request.setProcessDefinitionNameOrId(prd.Id);
        
                    Approval.ProcessResult result = Approval.process(request);

                    String commentDecoded;
                    if (comment != null) {
                        commentDecoded = htmlToText(comment);
                    }
                    

                    Opportunity loan= new Opportunity( Id = loanId);
                    System.debug('approvalType>>>'+approvalType);
                     if(approvalType == 'pricing Approval'){
                        System.debug('sending Email To approver>>');
                        sendEmailToAllApprovers(approverMembers[0],loanData,commentDecoded);

                    	
                    		 loan.Pricing_Approval_Status__c = 'Submitted For Approval';
                    update loan;
                         res= 'Succesfully Submitted For Approval';

                             List<OpportunityTeamMember> oppTeamMemberToBeAdded = new List<OpportunityTeamMember>();

                             List<OpportunityTeamMember> existingOpportunityTeamMembers = [SELECT Id,UserId, TeamMemberRole
                                                                                           FROM OpportunityTeamMember
                                                                                           WHERE OpportunityId = :loanId];
                             System.debug('existingOpportunityTeamMembers>>'+existingOpportunityTeamMembers);
                             Boolean matchFound = false;
                             for(OpportunityTeamMember otm : existingOpportunityTeamMembers){
                                System.debug('otm.UserId>>'+otm.UserId);
                                System.debug('approverMembers[0].UserId>>'+approverMembers[0].UserId);
                                if(otm.UserId == approverMembers[0].UserId){
                                    matchFound = true;
                                   

                                }
                                System.debug('oppTeamMemberToBeAdded>>'+oppTeamMemberToBeAdded);

                             }
                             if(!matchFound){
                                 OpportunityTeamMember newOtm = new OpportunityTeamMember();
                                    newOtm.UserId = approverMembers[0].UserId;
                                    newOtm.OpportunityAccessLevel = 'Edit';
                                    newOtm.TeamMemberRole = 'Sales';
                                    newOtm.OpportunityId = loanId;
                                    oppTeamMemberToBeAdded.add(newOtm);
                             }
                             System.debug('oppTeamMemberToBeAdded>>'+oppTeamMemberToBeAdded);
                             if(!oppTeamMemberToBeAdded.isEmpty()){
                                insert oppTeamMemberToBeAdded;
                             }                                                           
                     }

                   
                }else{
                    res = 'No approver for level '+approverLevel+' found for this loan';
                }
            }

            
            
        } catch (Exception e) {
            res= 'Error: '+e.getMessage();
            // throw new AuraHandledException(e.getMessage());
        }

        return res;
    }

    public static String getCurrentUserName(){
        String currUserName= [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()].Name;
        return currUserName;
    }

    @AuraEnabled
    public static ApprovalWrapper getLoanApprovalDetails( String loanId, String approvalType){
        ApprovalWrapper approvalData= new ApprovalWrapper();
        try {
            List<Opportunity> loanData= [SELECT Id, Branch_Master__c,Sanction_Loan_Amount__c,Draft_PD_Note__c,Exception_Approval_Status__c,Reasons_For_Execption_Approval__c,Selected_Reasons_For_Exception_Approval__c,Approval_Comments__c,
            Pricing_Approval_Status__c, 
            Approval_Sub_Status__c, Approval_Status__c FROM Opportunity WHERE Id = :loanId];

            List<Document_Details__c> docDetails= [SELECT Id, Content_Document_Id__c FROM Document_Details__c WHERE Loan_Application__c= :loanId AND Name= 'Loan Exception Approval Document' ORDER BY CreatedDate DESC];
            List<OpportunityTeamMember> oppTeamMember= [SELECT Id, UserId FROM OpportunityTeamMember WHERE OpportunityId= :loanId AND TeamMemberRole= 'Credit'];
            String currUserName= getCurrentUserName();
            String currentApprover= getCurrentApproverLevel(UserInfo.getUserId(), loanData[0].Branch_Master__c, approvalType)[0];
            String firstApproverLevel;
            String firstApprover;
            String highestApprover = getHighestApproverLevel(loanId, approvalType);
            if(approvalType == 'pricing Approval'){
                currentApprover = highestApprover;
            }
            System.debug('currentApprover--'+currentApprover);
            approvalData.showApprovalButtons = false;
            approvalData.draftComment = loanData[0].Draft_PD_Note__c;
            System.debug('approvalType--'+approvalType);
            List<ExceptionWrapper> exceptionList= new List<ExceptionWrapper>();
            List<String> loanException = new List<String>();
            Boolean disableCheckbox;
            Boolean allValuesApproved= false;
            if(approvalType == 'pricing Approval'){
                approvalData.showApprovalButtons = true;
                // approvalData.showSubmitApprovalButton = true;
                approvalData.currentStatus = loanData[0].Pricing_Approval_Status__c!= null? loanData[0].Pricing_Approval_Status__c: '';
            }else if(approvalType == 'Exception Approval'){
                if(docDetails.size()>0){
                    approvalData.contentId= docDetails[0].Content_Document_Id__c;
                }
                approvalData.currentStatus = (loanData[0].Exception_Approval_Status__c!= null || loanData[0].Exception_Approval_Status__c!= 'Rejected')? loanData[0].Exception_Approval_Status__c: '';

                List<String> allReasons= loanData[0].Reasons_For_Execption_Approval__c.split(';');
                List<String> selectedReasons= new List<String>();
                if(loanData[0].Selected_Reasons_For_Exception_Approval__c!= null){
                    selectedReasons = loanData[0].Selected_Reasons_For_Exception_Approval__c.split(';');
                }
                Set<String> approvedReasons = new Set<String>(selectedReasons);
                Set<String> allReasonsSet= new Set<String>(allReasons);
                allValuesApproved = approvedReasons.equals(allReasonsSet);

                Map<Id, Integer> applicableUserToLevel= new Map<Id, Integer>();

                if(constants.get('Exception_select_disable') == 'true'){
                    System.debug('at 295---');
                    loanException= allReasons;
                    disableCheckbox= true;
                }else{
                    if((loanData[0].Exception_Approval_Status__c== 'Not Started' || String.isBlank(loanData[0].Exception_Approval_Status__c) || loanData[0].Exception_Approval_Status__c== 'Rejected') && (loanData[0].Selected_Reasons_For_Exception_Approval__c == null || loanData[0].Selected_Reasons_For_Exception_Approval__c == '')) {
                        loanException= allReasons;
                        disableCheckbox= false;
                    }else if(loanData[0].Exception_Approval_Status__c== 'Submitted For Approval') {
                        loanException= selectedReasons;
                        disableCheckbox= true;
                    }else if( (loanData[0].Exception_Approval_Status__c== 'Not Started' || loanData[0].Exception_Approval_Status__c== '' || loanData[0].Exception_Approval_Status__c== 'Rejected' || loanData[0].Exception_Approval_Status__c== 'Approved') ) {
                        
                        List<String> remainingReasons = new List<String>();
                
                        for (String item : allReasons) {
                            if (!approvedReasons.contains(item)) {
                                remainingReasons.add(item);
                            }
                        }
        
                        loanException= remainingReasons;
                        disableCheckbox= false;
                    }
                }

                List<AccountTeamMember> acTeamMemberList= [SELECT Id, Eligible_Approver_Exception_Reasons__c, Level__c, UserId, User.Name FROM AccountTeamMember WHERE AccountId = :loanData[0].Branch_Master__c ];

                String approver;
                Boolean approverFound=false;
                Map<String, String> userDetails= new Map<String,String>();

                for(AccountTeamMember acc:acTeamMemberList){
                    if(acc.Eligible_Approver_Exception_Reasons__c != null){
                        List<String> reasonsList= acc.Eligible_Approver_Exception_Reasons__c.split(';');
                        Set<String> reasonSet = new Set<String>(reasonsList);
                        userDetails.put(acc.UserId, acc.User.Name + ' - '+acc.Level__c);
                        if(reasonSet.containsAll(loanException)){
                            approver = acc.UserId;
                            approverFound= true;
                            break;
                        }else{
                            Set<String> listSet = new Set<String>(reasonsList);
                            listSet.retainAll(loanException);
                            if(!listSet.isEmpty() && acc.Level__c!= null){
                                String numericPart = acc.Level__c.substring(1);
                                Integer levelNumber = Integer.valueOf(numericPart); 
                                applicableUserToLevel.put(acc.UserId, levelNumber);
                            }
                        }
                    }
                    if(oppTeamMember.size()>0 && acc.UserId == oppTeamMember[0].UserId && oppTeamMember[0].UserId == UserInfo.getUserId()){
                        firstApproverLevel= acc.Level__c;
                        firstApprover= acc.UserId;
                    }                    
                }
            
                Integer approverLevel=0;
                if(!approverFound){
                    for(Id userId: applicableUserToLevel.keyset()){
                        Integer currentLevel= applicableUserToLevel.get(userId);
                        if(currentLevel > approverLevel){
                            approverLevel = currentLevel;
                            approver = userId;
                            approverFound= true;
                        }
                    }
                }

                highestApprover = userDetails.containsKey(approver) ? userDetails.get(approver) : '';
            }else{
                List<AccountTeamMember> acTeamMemberList= [SELECT Id, Eligible_Approver_Exception_Reasons__c, Level__c, UserId, User.Name FROM AccountTeamMember WHERE AccountId = :loanData[0].Branch_Master__c ];


                for(AccountTeamMember acc:acTeamMemberList){
                    if(acc.UserId == UserInfo.getUserId() && loanData[0].Approval_Status__c== 'In Progress'){
                        firstApproverLevel= acc.Level__c;
                        firstApprover= acc.UserId;
                        break;
                    }else if(oppTeamMember.size()>0 && acc.UserId == oppTeamMember[0].UserId && oppTeamMember[0].UserId == UserInfo.getUserId()){
                        firstApproverLevel= acc.Level__c;
                        firstApprover= acc.UserId;
                        break;
                    }                  
                }
            	approvalData.currentStatus = loanData[0].Approval_Sub_Status__c!= null? loanData[0].Approval_Sub_Status__c: '';
            }
            approvalData.finalAuthority = highestApprover!= null ? highestApprover: '';
            if(approvalData.currentApprover == '' || approvalData.currentApprover == NULL){
            approvalData.currentApprover = 'Unassigned';
            }
            if(approvalData.currentStatus == '' || approvalData.currentStatus == NULL){
            approvalData.currentStatus = 'Pending for submission'; 
            }
            List<ProcessInstanceWorkitem> processList= [SELECT ActorId, Actor.Name, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :loanId AND ProcessInstance.Status = 'Pending' ORDER BY CreatedDate DESC];
            if(processList.size()>0 && currentApprover!= null){
                String approverLevel= getCurrentApproverLevel(processList[0].ActorId, loanData[0].Branch_Master__c, approvalType)[0];
                if(approvalType == 'pricing Approval'){
                    approverLevel = highestApprover;
                }
                approvalData.currentApprover = (approverLevel!= null && approverLevel!= 'No Level' ) ? processList[0].Actor.Name + ' - '+approverLevel: '';

                if(approvalType == 'Exception Approval' && processList[0].ActorId == UserInfo.getUserId()){
                    approvalData.showApproveButton = true;
                    approvalData.showRejectButton = true;
                    approvalData.showApprovalButtons = true;
                }else if(approvalType == 'pricing Approval' && processList[0].ActorId == UserInfo.getUserId()){
                    approvalData.showApproveButton = true;
                    approvalData.showApprovalButtons = true;
                    approvalData.showRejectButton = true;
                }
                    

                if(approvalType != 'Exception Approval' &&currentApprover!= null && currentApprover!= '' && currentApprover!= 'No Level' &&  processList[0].ActorId== UserInfo.getUserId() ){
                    
                    
                    List<AccountTeamMember> eligibleApprovers = [SELECT Id, Minimum_authority_loan_amount__c, Maximum_authority_loan_amount__c, Level__c, UserId FROM AccountTeamMember WHERE AccountId = :loanData[0].Branch_Master__c AND Minimum_authority_loan_amount__c <= :loanData[0].Sanction_Loan_Amount__c AND Maximum_authority_loan_amount__c >= :loanData[0].Sanction_Loan_Amount__c AND UserId = :UserInfo.getUserId()];

                     if(currentApprover == highestApprover || checkHigherApprovers(currentApprover, highestApprover, loanId, approvalType)
                    //  && eligibleApprovers.size()>0
                     ){
                        approvalData.showApproveButton = true;
                        approvalData.showApprovalButtons = true;
                        approvalData.showRejectButton =  approvalType == 'pricing Approval' ? true : false;
                        approvalData.showHoldButton = approvalType == 'pricing Approval' ? false : true;
                    }else {
                        if(approvalType == 'pricing Approval'){
                            system.debug('processList[0].ActorId:: '+processList[0].ActorId);
                            system.debug('UserInfo.getUserId():: '+UserInfo.getUserId());
                            approvalData.showSubmitApprovalButton = false;
                            approvalData.showRejectButton = true;
                            approvalData.showApprovalButtons = true;
                            //approvalData.showRejectButton =  approvalType == 'pricing Approval' ? true : false;
                            approvalData.showHoldButton = false;
                        }else{
                            approvalData.showRecommendButton = true;
                            approvalData.showApprovalButtons = true;
                            approvalData.showRejectButton = false;
                            approvalData.showHoldButton = true;
                        }
                    }
                }else if((currentApprover == highestApprover || checkHigherApprovers(currentApprover, highestApprover, loanId, approvalType) ) && approvalType != 'pricing Approval'){
                    approvalData.showApproveButton = true;
                    approvalData.showApprovalButtons = true;
                    approvalData.showRejectButton =  approvalType == 'pricing Approval' ? true : false;
                    approvalData.showHoldButton = approvalType == 'pricing Approval' ? false : true;
                }
            }else{
                if(approvalType == 'Exception Approval' && (loanData[0].Exception_Approval_Status__c == '' || loanData[0].Exception_Approval_Status__c== null || loanData[0].Exception_Approval_Status__c== 'Not Started' || loanData[0].Exception_Approval_Status__c== 'Rejected')){
                    approvalData.showSubmitApprovalButton = true;
                    approvalData.showApprovalButtons = true;
                    approvalData.currentApprover = highestApprover!= null ? highestApprover: '';
                }if(approvalType == 'Exception Approval' && loanData[0].Exception_Approval_Status__c == 'Approved' && !allValuesApproved){
                    approvalData.showSubmitApprovalButton = true;
                    approvalData.showApprovalButtons = true;
                }else if(approvalType == 'Loan Approval' && currentApprover!= null && currentApprover!= '' && currentApprover!= 'No Level' && currentApprover== firstApproverLevel){
                    approvalData.currentApprover = (currentApprover!= null && currentApprover!= 'No Level' ) ? currUserName + ' - '+firstApproverLevel: '';
                    if(loanData[0].Approval_Status__c != 'Approved'){
                        approvalData.showApprovalButtons = true;
                    }else {
                        approvalData.showApprovalButtons = false;
                    }
                    
                    //added & commented by vijayakrishna to hide the submit for approval btn when Pricing approval is approved
                    approvalData.showSubmitApprovalButton = (approvalType == 'pricing Approval' && loanData[0].Pricing_Approval_Status__c != 'Submitted For Approval' && loanData[0].Pricing_Approval_Status__c != 'Approved' && loanData[0].Pricing_Approval_Status__c != 'Rejected');
                    
                    approvalData.showRejectButton = false;
                    approvalData.showHoldButton = true;
                    if(currentApprover == highestApprover || checkHigherApprovers(currentApprover, highestApprover, loanId, approvalType)){
                        approvalData.showApproveButton= true;
                    }else {
                        approvalData.showRecommendButton = approvalType == 'pricing Approval' ? false : true;
                    }
                    
                    /*if(approvalType == 'pricing Approval'){
                         System.debug('Count1--'+'2');
                        approvalData.showSubmitApprovalButton = true;
                    }else{
                        approvalData.showRecommendButton = true;
                    }*/
                    //added & commented
                }else if(approvalType == 'pricing Approval' && loanData[0].Pricing_Approval_Status__c != 'Submitted For Approval'){
                     System.debug('Count1--'+'3');
                        approvalData.showSubmitApprovalButton = true;
                }
            }
            List<StatusHistoryWrapper> historyRecords= new List<StatusHistoryWrapper>();
            String query= 'SELECT Id, Comments, StepStatus, Actor.Name,Actor.Profile.Name, CreatedDate,CreatedBy.Name,OriginalActorId,OriginalActor.Name FROM ProcessInstanceStep WHERE ProcessInstance.TargetObjectId = :loanId ';
            if(approvalType == 'Exception Approval'){
                query = query + ' AND ProcessInstance.ProcessDefinition.DeveloperName= \'Sales_Exception_Approval\' ';
            }else if (approvalType == 'pricing Approval') {
            //     query += 'AND Actor.Profile.Name LIKE \'%Sales%\' ';
            query += ' AND (Actor.Profile.Name LIKE \'%Sales%\' OR Actor.Profile.Name = \'System Administrator\')';

            }
            query= query + ' ORDER BY CreatedDate DESC';
            // List<ProcessInstanceStep> approvalComments = [SELECT Id, Comments, StepStatus, Actor.Name, CreatedDate FROM ProcessInstanceStep WHERE ProcessInstance.TargetObjectId = :loanId ORDER BY CreatedDate DESC];
            System.debug('query---'+query);
            List<ProcessInstanceStep> approvalComments = Database.query(query);
            if(approvalType != 'Loan Approval'){
                if(approvalComments.size() > 0){
                    for(ProcessInstanceStep approvalStep: approvalComments){
                        StatusHistoryWrapper historyWrp= new StatusHistoryWrapper();
                        if(approvalStep.Comments != null && approvalStep.Comments.contains(';')){
                            List<String> remarksData = approvalStep.Comments.split(';');
                            if(remarksData[0] != 'No Level' && remarksData.size()==2){
                                historyWrp.status = remarksData[0];
                                historyWrp.remarks = (remarksData[1] == null ? '':remarksData[1]);    
                                historyWrp.timeStamp = approvalStep.CreatedDate;
                                if(approvalType == 'pricing Approval'){
                                    if(historyWrp.remarks == 'Pricing Approval via Email'){
                                    historyWrp.requestor = approvalStep.OriginalActor.Name;
                                    }else{
                                         historyWrp.requestor = approvalStep.Actor.Name;
                                    }
                                }else{
                                historyWrp.requestor=approvalStep.CreatedBy.Name;
                                }
                                historyRecords.add(historyWrp);
                            }
                        }else if(approvalStep.Comments != null && approvalType == 'Exception Approval'){
                            historyWrp.isRequestor =  approvalStep.StepStatus == 'Started' ? true : false;
                            historyWrp.status = approvalStep.StepStatus;
                            historyWrp.remarks = (approvalStep.Comments == null ? '': approvalStep.Comments);    
                            historyWrp.timeStamp = approvalStep.CreatedDate;
                            historyWrp.requestor=approvalStep.CreatedBy.Name;
                            historyRecords.add(historyWrp);
                        }else{
                            historyWrp.isRequestor =  approvalStep.StepStatus == 'Started' ? true : false;
                            historyWrp.status = approvalStep.StepStatus;
                            historyWrp.remarks = (approvalStep.Comments == null ? '': approvalStep.Comments);    
                            historyWrp.timeStamp = approvalStep.CreatedDate;
                            if(approvalType == 'pricing Approval'){
                                    if(historyWrp.remarks == 'Pricing Approval via Email'){
                                    historyWrp.requestor = approvalStep.OriginalActor.Name;
                                    }else{
                                         historyWrp.requestor = approvalStep.Actor.Name;
                                    }
                                }else{
                            historyWrp.requestor=approvalStep.CreatedBy.Name;
                                }
                            historyRecords.add(historyWrp);

                        }
                    }
                    approvalData.statusHistory = historyRecords;
                    approvalData.showApprovalHistory = true;
                }else {
                    approvalData.showApprovalHistory = false;
                }  
            }else{
                if(loanData[0].Approval_Comments__c != null && loanData[0].Approval_Comments__c != ''){
                    List<String> comments=  loanData[0].Approval_Comments__c.split('%%-');
                    for(Integer i =comments.size()-1; i>=0; i--){
                    // for(String comment: comments){
                        List<String> commentParts = comments[i].split('&&-');
                        if(commentParts.size() == 4){
                            StatusHistoryWrapper historyWrp= new StatusHistoryWrapper();
                            historyWrp.status = (commentParts[0] == null ? '':commentParts[0]);
                            historyWrp.remarks = (commentParts[1] == null ? '':commentParts[1]);    
                            historyWrp.timeStamp = (commentParts[2] == null ? null: DateTime.valueOf(commentParts[2].replace(',', ''))); 
                            historyWrp.requestor=(commentParts[3] == null ? '':commentParts[3]); 
                            historyRecords.add(historyWrp);
                        }
                    }
                    approvalData.statusHistory = historyRecords;
                    approvalData.showApprovalHistory = true;
                }else {
                    approvalData.showApprovalHistory = false;
                }  
            }          
            
            for(String exp: loanException){
                ExceptionWrapper exceptionWrp= new ExceptionWrapper();
                exceptionWrp.name = exp;
                exceptionWrp.selected=true;
                exceptionList.add(exceptionWrp);
            }
            approvalData.disableExceptionSelect= disableCheckbox;
            approvalData.exceptions = exceptionList;
            approvalData.commentLenth = loanData[0].Approval_Comments__c != null ? 131072 - (loanData[0].Approval_Comments__c.length()+50) :  131000;
        } catch (Exception e) {
            System.debug('e.getline'+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }

        return approvalData;
    }

    public static Boolean checkHigherApprovers( String currentLevel,String highestApprover ,String loanId, String approvalType){
        Boolean isApprover= false;
        try {

            if (String.isEmpty(currentLevel) || !currentLevel.startsWith('L')) {
                return false;
            }

            List<Opportunity> loanappList= [SELECT Id, OwnerId, Owner.Name, Branch_Master__c,Sanction_Loan_Amount__c FROM Opportunity WHERE Id = :loanId];
            String branchId = loanappList[0].Branch_Master__c;
            // String requestedAmount= String.valueOf(loanappList[0].Sanction_Loan_Amount__c);
            Decimal requestedAmount= loanappList[0].Sanction_Loan_Amount__c;
            String numericPart = currentLevel.substring(1);

            List<String> levelNumbers= new List<String>();
            Integer levelNumber = Integer.valueOf(numericPart); 
            String numericPartHighest = highestApprover != null ? highestApprover.substring(1) : '0';

            Integer numberHighest = Integer.valueOf(numericPartHighest); 
            Map<String, String> inputMap = new Map<String, String>();
            inputMap.put('oppId', loanId);
            Utility_V1.ProductWrapper productWrapper = Utility_V1.getProductDetails(inputMap);
            Boolean isHlRelated = productWrapper.isHLRelated;
            if((isHlRelated && levelNumber >= numberHighest) || (!isHlRelated && levelNumber > numberHighest)){
                for(Integer i= levelNumber; i<=10; i++){
                    levelNumbers.add('L'+String.valueOf(i));
                }
            }else {
                return false;
            }          
            
            String level;
            String query = 'SELECT Id, Level__c, UserId, User.Name FROM AccountTeamMember WHERE AccountId = :branchId AND User.IsActive = true ';
            
            // query = query + ' AND Level__c = :nextLevel';
            System.debug('query---'+query);
                List<AccountTeamMember> teamMembers = Database.query(query);
                for (String levelNum : levelNumbers) {
                    for (AccountTeamMember member : teamMembers) {
                        if (member.Level__c == levelNum && member.UserId == UserInfo.getUserId()) {
                            return true;
                        }
                    }
                }
            

        } catch (Exception e) {
            System.debug('Error in getCurrentApproverLevel ---'+ e.getMessage());
        }

        return isApprover;
    }

    @AuraEnabled
    public static boolean mitigantsFound (String loanId){
        List<Application_Deviation__c> deviationList = [SELECT Id, Mitigants__c FROM Application_Deviation__c WHERE Loan_Application__c =: loanId];
        for (Application_Deviation__c deviation : deviationList) {
            if (String.isBlank(deviation.Mitigants__c)) {
                return false;
            }
        }
        return true;
    }
    

    @AuraEnabled
    public static string getHighestApproverLevel( String loanId, String approvalType){
        String level;
        try {
             System.debug('approvalType 128'+approvalType);
             List<String> allApprovers;
            if(approvalType == 'pricing Approval'){
                 allApprovers =  getPricingApprover(loanId);
                 if(allApprovers.size() > 0)
                	allApprovers.sort();
                System.debug('allApprovers 131'+allApprovers);
             }
            else {
                allApprovers = getLoanapprovers(loanId, approvalType);
            }
           // List<String> allApprovers= getLoanapprovers(loanId,approvalType);
            System.debug('allApprovers----'+allApprovers);
            if(allApprovers.size() > 0){
                Integer lastIndex= allApprovers.size()-1;
                level = allApprovers.get(lastIndex);
            }

            System.debug('level----'+level);

        } catch (Exception e) {
            // throw new AuraHandledException(e.getMessage());
            System.debug('Error in fetch highest appprover---'+e.getMessage());
        }

        return level;
    }

    @AuraEnabled
    public static List<String> getLoanapprovers(String loanId, String approvalType){
        List<String> allApprovers= new List<String>();
        try {
            List<Opportunity> loanData= [SELECT Id,Sanction_Loan_Amount__c, Branch_Master__c FROM Opportunity WHERE Id = :loanId];

            if(loanData.size()>0 && loanData[0].Branch_Master__c!=null && loanData[0].Sanction_Loan_Amount__c!=null){
                
                List<AccountTeamMember> eligibleApprovers = [SELECT Id, Minimum_authority_loan_amount__c, Maximum_authority_loan_amount__c, Level__c, UserId FROM AccountTeamMember WHERE AccountId = :loanData[0].Branch_Master__c AND Minimum_authority_loan_amount__c <= :loanData[0].Sanction_Loan_Amount__c AND Maximum_authority_loan_amount__c >= :loanData[0].Sanction_Loan_Amount__c];
				
                if(eligibleApprovers.size()>0){
                    for(AccountTeamMember member: eligibleApprovers){
                        if(member.Level__c!= null && !allApprovers.contains(member.Level__c)){
                            allApprovers.add(member.Level__c);
                        }
                    }
                }
            }
            List<Application_Deviation__c> relatedDeviations= [SELECT Id, Approving_Authority__c FROM Application_Deviation__c WHERE Loan_Application__c = :loanId];
            for (Application_Deviation__c deviation : relatedDeviations) {
                if(deviation.Approving_Authority__c!=null && !allApprovers.contains(deviation.Approving_Authority__c)){
                    allApprovers.add('L'+deviation.Approving_Authority__c);
                }
            }  
            List<Income_Expense_Obligation__c> relatedIncomeExpenseObligations= [SELECT Id, Approver_s_Name__c FROM Income_Expense_Obligation__c WHERE Loan_Application__c = :loanId];
            for (Income_Expense_Obligation__c income : relatedIncomeExpenseObligations) {
                if(income.Approver_s_Name__c!=null && !allApprovers.contains(income.Approver_s_Name__c)){
                    allApprovers.add(income.Approver_s_Name__c);
                }
            }  

            if(allApprovers.size()>0){
                allApprovers.sort();
            } 
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return allApprovers;
    }

    public static List<string> getPricingApprover(String loanId){
        List<Opportunity> loanData= [SELECT Id,Branch_Master__c,Sanction_Tenure__c, Sanction_Rate_Of_Interest__c, 
        Sanction_Loan_Amount__c, Negotiated_Tenure__c, Negotiated_Loan_Amount__c,
        Negotiated_Rate_Of_Interest__c,Emi_amount__c,Resanction__c,Eligible_for_Resanction__c,
         Product__c,Sub_Product__c,Repayment_Facility__c,Scheme__c,Customer_Profile__c
          FROM Opportunity WHERE Id = :loanId];

        Decimal roiDiff = 0; 
        Decimal roi = 0; 
        List<Product2> currentProductValues = [SELECT Id,Sanctioned_ROI__c,Negotiated_ROI__c,Final_ROI__c
                                               FROM Product2
                                               WHERE RecordType.Name = 'Sub Product' AND Loan_Application__c = :loanId ];  
        
        for(Product2 product : currentProductValues){
            System.debug('product.Sanctioned_ROI__c9866:'+product.Sanctioned_ROI__c);
            System.debug('product.Negotiated_ROI__c9866:'+product.Negotiated_ROI__c);
           Decimal productRoiDiff = (product.Sanctioned_ROI__c != null ? product.Sanctioned_ROI__c : 0) - (product.Negotiated_ROI__c != null ? product.Negotiated_ROI__c: 0);
           if(productRoiDiff > 0){
              roiDiff = productRoiDiff;
              roi = product.Negotiated_ROI__c;
              break;
           }
        }     

        List<String> allApprovers = new List<String>();
        Map<String,Charges_Approval_Criteria__mdt> allMetaData = Charges_Approval_Criteria__mdt.getAll();
                   
        List<Charges_Insurance__c> listChargesInsurance = COMM_CreditChargesTableController.getChargesRecords(loanId);
		Map<String, String> feeTypePiclistMap =  COMM_CreditChargesTableController.getPicklistValues();
        Map<String,Decimal> mapNameOfChrgesWithProcesFeed = new Map<String,Decimal>();
        
        Decimal insuranceNegotiatePercent = 0.0;
                
        if(listChargesInsurance.size() > 0){
            for(Charges_Insurance__c obj : listChargesInsurance){
                 if(obj.RecordType.Name == 'Insurance') {
                     if(obj.Negotiated_Percentage__c > 0)
                        insuranceNegotiatePercent = insuranceNegotiatePercent + obj.Negotiated_Percentage__c;
            }
                if(obj.Charges_Fee_Type__c == 'PROCFEE')
                    mapNameOfChrgesWithProcesFeed.put('Processing Fee',obj.Negotiated_Percentage__c);
            }
        }
          Opportunity opp = new Opportunity();
          if(loanData.size() >= 0){
                opp  = loanData[0];
          }
        Product2 mainProduct = [
            SELECT Id
            FROM Product2
            WHERE RecordType.Name = 'Product' AND Name = :opp.Product__c AND Loan_Application__c = :opp.Id
            LIMIT 1
        ];
        Product2 subProduct = [
            SELECT Id
            FROM Product2
            WHERE RecordType.Name = 'Sub Product' AND Product__c = :mainProduct.Id AND Loan_Application__c = :opp.Id
            LIMIT 1
        ];
        Product2 variant = [
            SELECT Id, Name
            FROM Product2
            WHERE RecordType.Name = 'Variant' AND Product__c = :subProduct.Id AND Loan_Application__c = :opp.Id
            LIMIT 1
        ];
        Application_Applicant__c primaryApplicant = [
                SELECT Id, Customer_Profile__c 
                FROM Application_Applicant__c
                WHERE Loan_Application__c = :opp.Id AND Applicant_Type__c = 'Primary Applicant' LIMIT 1
            ]; 
        
            //Decimal tenureDiff = opp.Negotiated_Tenure__c - opp.Sanction_Tenure__c;
            //Decimal loanAmountDiff = opp.Negotiated_Loan_Amount__c - opp.Sanction_Loan_Amount__c;
            String variantType = (variant.name != null) ? variant.name : 'Term Loan';
            String customerProfile = (primaryApplicant.Customer_Profile__c != null) ? primaryApplicant.Customer_Profile__c : 'SENP';
              // Iterate over metadata records
            for (Charges_Approval_Criteria__mdt meta : allMetaData.values()) {
                Boolean isMatch = false;
                //if(!meta.Resanction__c){
            
                // if (meta.Type__c == 'Loan Amount' && loanAmountDiff < 0 && Decimal.valueOf(meta.Decreased_by__c) != null && Decimal.valueOf(meta.Decreased_by__c) > 0 && loanAmountDiff != null &&   Math.abs(loanAmountDiff) >=  Decimal.valueOf(meta.Decreased_by__c) && opp.Product__c == meta.Product__c && variantType == meta.Sub_Product__c /*&& opp.Repayment_Facility__c == meta.Re_Payment_Facility__c && opp.Scheme__c == meta.Scheme__c */&& customerProfile == meta.Customer_Profile__c){
                // isMatch = true;
                // }
                // else if (meta.Type__c == 'Loan Amount' &&  loanAmountDiff > 0 && Decimal.valueOf(meta.Increased_By__c) != null && Decimal.valueOf(meta.Increased_By__c) > 0 && loanAmountDiff != null &&   Math.abs(loanAmountDiff) >=  Decimal.valueOf(meta.Increased_By__c) && opp.Product__c == meta.Product__c && variantType == meta.Sub_Product__c/* && opp.Repayment_Facility__c == meta.Re_Payment_Facility__c && opp.Scheme__c == meta.Scheme__c*/ && customerProfile == meta.Customer_Profile__c){
                // isMatch = true;
                // }
                // if (meta.Type__c == 'Tenure' && tenureDiff != null && tenureDiff < 0 && Decimal.valueOf(meta.Decreased_by__c) != null && Decimal.valueOf(meta.Decreased_by__c) > 0 &&  Math.abs(tenureDiff) >= Decimal.valueOf(meta.Decreased_by__c) && opp.Product__c == meta.Product__c && variantType == meta.Sub_Product__c /*&& opp.Repayment_Facility__c == meta.Re_Payment_Facility__c && opp.Scheme__c == meta.Scheme__c*/ && customerProfile == meta.Customer_Profile__c) {
                //     isMatch = true;
                // }else if(meta.Type__c == 'Tenure' && tenureDiff != null && tenureDiff > 0 && Decimal.valueOf(meta.Increased_By__c) != null && Decimal.valueOf(meta.Increased_By__c) > 0 &&  Math.abs(tenureDiff) >= Decimal.valueOf(meta.Increased_By__c) && opp.Product__c == meta.Product__c && variantType == meta.Sub_Product__c /*&& opp.Repayment_Facility__c == meta.Re_Payment_Facility__c && opp.Scheme__c == meta.Scheme__c*/ && customerProfile == meta.Customer_Profile__c) {
                //     isMatch = true;
                // }
            
                //new loan amount implementation
                // if (meta.Type__c == 'Loan Amount' && loanAmountDiff != null && loanAmountDiff > 0 && meta.Range1__c != null && meta.Range2__c != null && opp.Negotiated_Loan_Amount__c > meta.Range1__c && opp.Negotiated_Loan_Amount__c <= meta.Range2__c && opp.Product__c == meta.Product__c && variantType == meta.Sub_Product__c /*&& opp.Repayment_Facility__c == meta.Re_Payment_Facility__c && opp.Scheme__c == meta.Scheme__c*/ && customerProfile == meta.Customer_Profile__c) {
                //     isMatch = true;
                // }else if(meta.Type__c == 'Loan Amount' && loanAmountDiff != null && loanAmountDiff > 0 && meta.Range1__c != null && meta.Range2__c == null && opp.Negotiated_Loan_Amount__c >= meta.Range1__c && opp.Product__c == meta.Product__c && variantType == meta.Sub_Product__c /*&& opp.Repayment_Facility__c == meta.Re_Payment_Facility__c && opp.Scheme__c == meta.Scheme__c*/ && customerProfile == meta.Customer_Profile__c) {
                //     isMatch = true;
                // }

                //new tenure implementation
                // if (meta.Type__c == 'Tenure' && tenureDiff != null && tenureDiff > 0 && meta.Range1__c != null && meta.Range2__c != null && opp.Negotiated_Tenure__c > meta.Range1__c && opp.Negotiated_Tenure__c <= meta.Range2__c && opp.Product__c == meta.Product__c && variantType == meta.Sub_Product__c /*&& opp.Repayment_Facility__c == meta.Re_Payment_Facility__c && opp.Scheme__c == meta.Scheme__c*/ && customerProfile == meta.Customer_Profile__c) {
                //     isMatch = true;
                // }else if(meta.Type__c == 'Tenure' && tenureDiff != null && tenureDiff > 0 && meta.Range1__c != null && meta.Range2__c == null && opp.Negotiated_Tenure__c >= meta.Range1__c && opp.Product__c == meta.Product__c && variantType == meta.Sub_Product__c /*&& opp.Repayment_Facility__c == meta.Re_Payment_Facility__c && opp.Scheme__c == meta.Scheme__c*/ && customerProfile == meta.Customer_Profile__c) {
                //     isMatch = true;
                // }

                // system.debug('roiDiff:: '+roiDiff + 'meta.Value__c: '+meta.Value__c + 'meta.Type__c:: '+meta.Type__c);
                // if (meta.Type__c == 'ROI' && roiDiff != 0 && roiDiff > 0 && roi == meta.Value__c && opp.Product__c == meta.Product__c && variantType == meta.Sub_Product__c && /*opp.Repayment_Facility__c == meta.Re_Payment_Facility__c && opp.Scheme__c == meta.Scheme__c && */customerProfile == meta.Customer_Profile__c){
                //     isMatch = true;
                // }

                //new roi implemetation 8 sep
                system.debug('roiDiff:: '+roiDiff + 'meta.Value__c: '+meta.Value__c + 'meta.Type__c:: '+meta.Type__c);
                system.debug('Range1>>'+meta.Range1__c+'Range2>>'+meta.Range2__c+'roi>>'+roi+'Opp Product'+opp.Product__c+'meta Product>'+meta.Product__c+'variantType>>'+variantType+'Sub_Product__c'+meta.Sub_Product__c+'Profile'+customerProfile+'Meta profile'+meta.Customer_Profile__c);
                if (meta.Type__c == 'ROI' && roiDiff != 0 && roiDiff > 0 && meta.Range1__c != null && meta.Range2__c != null && roi >= meta.Range1__c && roi <= meta.Range2__c && opp.Product__c == meta.Product__c && variantType == meta.Sub_Product__c && /*opp.Repayment_Facility__c == meta.Re_Payment_Facility__c && opp.Scheme__c == meta.Scheme__c && */customerProfile == meta.Customer_Profile__c){
                    isMatch = true;
                }
                else if(meta.Level__c == 'L4'){//Sanwar
                    isMatch = true;
                }
                
                /*if (meta.Type__c == 'Processing Fee' && mapNameOfChrgesWithProcesFeed.containskey(meta.Type__c) && mapNameOfChrgesWithProcesFeed.get(meta.Type__c) != null && mapNameOfChrgesWithProcesFeed.get(meta.Type__c) == meta.Value__c && opp.Product__c == meta.Product__c && variantType == meta.Sub_Product__c && customerProfile == meta.Customer_Profile__c) {
                    isMatch = true;
                }
                
            
                if (meta.Type__c == 'Insurance' && insuranceNegotiatePercent > 0 && insuranceNegotiatePercent  == meta.Value__c && opp.Product__c == meta.Product__c && variantType == meta.Sub_Product__c && customerProfile == meta.Customer_Profile__c) {
                    isMatch = true;
                }*/
                
                if (isMatch) {
                    if(meta.Level__c != null && meta.Designation__c != null)
                    allApprovers.add(meta.Level__c);
                }
                system.debug('allApprovers:: '+allApprovers);
            //}
        }
        return allApprovers;
    }

    //method to approve or reject the loan application
    @AuraEnabled
    public static List<String> performApprovalAction(String loanId, String action, String comments, String approvalType){
        Boolean isApproved = false;
        List<String> validations= new List<String>();
        try {
            Set<String> receipientIds= new Set<String>();
            String currentApproverLevel;
            String firstApprover;
            String firstApproverLevel;
            List<OpportunityTeamMember> oppTeamMember= [SELECT Id, UserId FROM OpportunityTeamMember WHERE OpportunityId= :loanId AND TeamMemberRole= 'Credit'];
            List<Opportunity> loanData= [SELECT Id,Sanction_Loan_Amount__c, Branch_Master__c, OwnerId, Name, Approval_Comments__c, Login_Completion_Stage__c FROM Opportunity WHERE Id = :loanId];
            List<AccountTeamMember> eligibleApprovers = [SELECT Id, Level__c, UserId FROM AccountTeamMember WHERE AccountId = :loanData[0].Branch_Master__c AND User.IsActive = true];
            for(AccountTeamMember acc:eligibleApprovers){
                if(oppTeamMember.size()>0 && acc.UserId == oppTeamMember[0].UserId){
                    firstApproverLevel= acc.Level__c;
                    firstApprover= acc.UserId;
                } 
            }
            String highestApprover = getHighestApproverLevel(loanId, approvalType);
            if(loanData.size()>0 && loanData[0].Branch_Master__c != null){
                currentApproverLevel=  getCurrentApproverLevel(UserInfo.getUserId(), loanData[0].Branch_Master__c,approvalType)[0];
                
                if(approvalType == 'pricing Approval'){
                    currentApproverLevel = highestApprover;
                }
                receipientIds.add(loanData[0].OwnerId);
            }
            List<String> validationList= new List<String>();
            if(approvalType != 'pricing Approval'){
               validationList= checkApprovedDeviations(loanId, currentApproverLevel);
             }
            if(validationList.size()>0){
                return validationList;
            }else {
                List<ProcessInstanceWorkitem> processsInstanceList = [SELECT Id, ProcessInstanceId,CreatedById FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: loanId];
                String approverComment;
                if(processsInstanceList.size()>0){
                    String currUserName= getCurrentUserName();
                    List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
                    String actionStatus;
                    for(ProcessInstanceWorkitem workItem : processsInstanceList){
                        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                        req.setWorkitemId(workItem.Id);
                        
                        if(action == 'Approv'){
                            actionStatus= 'Approve';
                        }else {
                            actionStatus= 'Reject';
                        }
                        req.setAction(actionStatus);        //Valid values are: Approve, Reject, or Removed and Only system administrators can specify Removed.
                        req.setComments(comments);
                        approverComment = currentApproverLevel + ' '+action +'ed' + '&&-'+comments+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
                        requests.add(req);
                    }
    
                    Approval.ProcessResult[] processResults = Approval.process(requests);
                      
                    // List<AccountTeamMember> eligibleApprovers = [SELECT Id, Level__c, UserId FROM AccountTeamMember WHERE AccountId = :loanData[0].Branch_Master__c AND User.IsActive = true];
                    if(approvalType=='Exception Approval'){
                        user u;
                        if(processsInstanceList.size() > 0){
                             u = [Select id ,Email,Name From user where Id =: processsInstanceList[0].CreatedById limit 1];
     
                        }
                        String loanName = '';
                        if(loanData.size() > 0){
                            loanName = loanData[0].Name;
                        }
                        String actionstat = '';
                        if(actionStatus == 'Reject' ){
                            actionstat = 'Rejected';
                        }else if(actionStatus == 'Approve'){
                             actionstat = 'Approved';
                        }
                        if(u != null){
                        sendExceptionApprovalEmail(u.Email,u.Name, loanData[0].Name,actionstat, currUserName);
                        }
                        receipientIds.add(processsInstanceList[0].CreatedById);
                    }else {
                        for(AccountTeamMember member: eligibleApprovers){
                            receipientIds.add(member.UserId);
                        }
                    }
                    
                  
                    sendActionNotification(loanId, actionStatus, receipientIds, currUserName+' - '+currentApproverLevel, approvalType);
                    Opportunity loan= new Opportunity( Id = loanId);
                    loan.Login_Completion_Stage__c = loanData.size() > 0 ? loanData[0].Login_Completion_Stage__c : '';
                    if(approvalType == 'pricing Approval'){
                         loan.Is_Pricing_Approval_Required__c = false;
                         loan.Pricing_Approval_Status__c = action +'ed';
                    }else if(approvalType=='Exception Approval'){
                        loan.Exception_Approval_Status__c = action +'ed';
                        if(action != 'Approv'){
                            loan.Selected_Reasons_For_Exception_Approval__c = '';
                        }
                        else if(action =='Approv'){
                            System.debug('in Exception Approval approv before:::' + loan.Login_Completion_Stage__c);
                            if(loan.Login_Completion_Stage__c== null){
                                    loan.Login_Completion_Stage__c = 'Exception Flow';
                            }
                            else{
                                if(!loan.Login_Completion_Stage__c.containsIgnoreCase('Exception Flow')){
                                    loan.Login_Completion_Stage__c =  loan.Login_Completion_Stage__c + ';'+ 'Exception Flow';
                                }
                            }
                            System.debug('in Exception Approval approv After:::' + loan.Login_Completion_Stage__c);
                        }                    
                    }else{
                        loan.Approval_Status__c = action +'ed';
                        loan.Draft_PD_Note__c = '';
                        loan.Approval_Sub_Status__c = currentApproverLevel + ' '+action +'ed';
                        if(loanData[0].Approval_Comments__c!= null && loanData[0].Approval_Comments__c != ''){
                            loan.Approval_Comments__c = loanData[0].Approval_Comments__c+'%%-'+approverComment;
                        }else {
                            loan.Approval_Comments__c = approverComment;
                        }
                    }
                    update loan;
    
                    isApproved = true;
                    validations.add('success');
                }
                else if(approvalType == 'Loan Approval' && (currentApproverLevel == 'L1' || UserInfo.getUserId() == firstApprover || checkHigherApprovers(currentApproverLevel, highestApprover, loanId, approvalType))){
                    Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                    request.setComments(currentApproverLevel + ' ' +''+ ';'+null);
                    request.setObjectId(loanId);
                    request.setNextApproverIds(new Id[] { UserInfo.getUserId() });
    
                    request.setProcessDefinitionNameOrId('Loan_Application_Approval');
    
                    Approval.process(request);
    
                    List<ProcessInstanceWorkitem> processsInstanceListNew = [SELECT Id, ProcessInstanceId,CreatedById FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: loanId];
                    if(processsInstanceListNew.size()>0){
                        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
                        String actionStatus;
                        for(ProcessInstanceWorkitem workItem : processsInstanceListNew){
                            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                            req.setWorkitemId(workItem.Id);
                            
                            if(action == 'Approv'){
                                actionStatus= 'Approve';
                            }else {
                                actionStatus= 'Reject';
                            }
                            req.setAction(actionStatus);        //Valid values are: Approve, Reject, or Removed and Only system administrators can specify Removed.
                            req.setComments(currentApproverLevel + ' '+action +'ed' );
                            requests.add(req);
                        }
        
                        Approval.ProcessResult[] processResults = Approval.process(requests);
                        String currUserName= getCurrentUserName();
                        
                        
                        for(AccountTeamMember member: eligibleApprovers){
                            receipientIds.add(member.UserId);
                        }
                                            
                      
                        sendActionNotification(loanId, actionStatus, receipientIds, currUserName+' - '+currentApproverLevel, approvalType);
                        Opportunity loan= new Opportunity( Id = loanId);
                        
                        loan.Approval_Status__c = action +'ed';
                        loan.Approval_Sub_Status__c = currentApproverLevel + ' '+action +'ed';
                        loan.Draft_PD_Note__c = '';
                        update loan;
        
                        isApproved = true;
                        validations.add('success');
                    }
                }
            }
           
        } catch (Exception e) {
            System.debug('Error during approving record---'+ e.getMessage());
            validations.add('fail');
        }

        return validations;
    }

    @AuraEnabled
    public static List<String> recommendLoanApproval( String loanId, String comments, String approvalType){
        Boolean isApproved = false;
        List<String> validations= new List<String>();
        try {
            List<OpportunityTeamMember> oppTeamMember= [SELECT Id, UserId FROM OpportunityTeamMember WHERE OpportunityId= :loanId AND TeamMemberRole= 'Credit'];
            if(comments== null || comments == ''){
                comments = 'No comments added';
            }
            List<Opportunity> loanData= [SELECT Id,Sanction_Loan_Amount__c, Approval_Sub_Status__c, Approval_Status__c,Branch_Master__c, Name, Approval_Comments__c FROM Opportunity WHERE Id = :loanId];
            if(loanData.size()>0 && loanData[0].Branch_Master__c != null){
                Set<String> receipientIds= new Set<String>();
                String currentApproverLevel=  getCurrentApproverLevel(UserInfo.getUserId(), loanData[0].Branch_Master__c,approvalType)[0];
                List<String> validationList= checkApprovedDeviations(loanId, currentApproverLevel);
                Boolean allMitigantsFound = mitigantsFound(loanId);
                if(allMitigantsFound == false) {
                    validationList.add('Please enter mitigants for all deviations before recommending the case.');
                }
                if(validationList.size()>0){
                    return validationList;
                }else {
                    String highestApprover= getHighestApproverLevel(loanId, approvalType);
                    Boolean isFinalApprover= false;
                    String firstApproverLevel;
                    String firstApprover;
                    String subStatus;
                    String currUserName= getCurrentUserName();
                    String approverComment;
                    List<AccountTeamMember> actmList = [SELECT Id, Minimum_authority_loan_amount__c, Maximum_authority_loan_amount__c, Level__c, UserId FROM AccountTeamMember WHERE AccountId = :loanData[0].Branch_Master__c ];
                    for(AccountTeamMember acc:actmList){
                        if(acc.UserId == UserInfo.getUserId() && loanData[0].Approval_Status__c== 'In Progress'){
                            firstApproverLevel= acc.Level__c;
                            firstApprover= acc.UserId;
                            break;
                        }else if(oppTeamMember.size()>0 && acc.UserId == oppTeamMember[0].UserId  ){
                            firstApproverLevel= acc.Level__c;
                            firstApprover= acc.UserId;
                            break;
                        } 
                    }
                    if(currentApproverLevel == highestApprover){
                        List<AccountTeamMember> eligibleApprovers = [SELECT Id, Minimum_authority_loan_amount__c, Maximum_authority_loan_amount__c, Level__c, UserId FROM AccountTeamMember WHERE AccountId = :loanData[0].Branch_Master__c AND Minimum_authority_loan_amount__c <= :loanData[0].Sanction_Loan_Amount__c AND Maximum_authority_loan_amount__c >= :loanData[0].Sanction_Loan_Amount__c AND UserId = :UserInfo.getUserId()];
                        if(eligibleApprovers.size()>0){
                            isFinalApprover=true;
                        }
                    }
                    String nextApproverLevel= getNextApproverLevel(currentApproverLevel, highestApprover, loanId, approvalType, isFinalApprover);
    
                    if(currentApproverLevel.contains('L1')){
                        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                        request.setComments(currentApproverLevel + ' ' +'Recommended');
                        request.setObjectId(loanId);
                        request.setNextApproverIds(new Id[] { nextApproverLevel });
                        approverComment = currentApproverLevel + ' '+'Recommended' + '&&-'+comments+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
    
                        request.setProcessDefinitionNameOrId('Loan_Application_Approval');
    
                        Approval.process(request);
     
                    }else{
                        List<ProcessInstanceWorkitem> workItems = [SELECT Id, ActorId, OriginalActorId, ProcessInstance.CreatedById, ProcessInstance.CreatedDate, ProcessInstance.TargetObjectId, ProcessInstance.Status 
                                                                    FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: loanId AND ProcessInstance.Status = 'Pending'];
    
                        System.debug('UserInfo.getUserId()----'+UserInfo.getUserId());
                        System.debug('firstApprover-----'+firstApprover);
                        if(!workItems.isEmpty()){
                            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
                            for(ProcessInstanceWorkitem workItem : workItems){
                                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                                req.setWorkitemId(workItem.Id);
                                req.setAction('Approve');        
                                req.setComments(currentApproverLevel + ' ' +'Recommended');//add loan approval status for status historyyy
                                approverComment = currentApproverLevel + ' '+'Recommended' + '&&-'+comments+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
                                requests.add(req);
                            }
    
                            if(requests.size()>0){
                                Approval.ProcessResult[] processResults = Approval.process(requests);
                                // List<String> approvalLevels= getLoanapprovers(loanId);
        
                                
                                if (nextApproverLevel!= null && nextApproverLevel!= '') {
                                    Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                                    request.setComments('No Level;Please review the loan application.');
                                    request.setObjectId(loanId);
                                    request.setNextApproverIds(new Id[] { nextApproverLevel });
    
                                    request.setProcessDefinitionNameOrId('Loan_Application_Approval');
    
                                    Approval.process(request);
                                }
                            }
                        }else if(UserInfo.getUserId() == firstApprover){
                            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                            request.setComments(currentApproverLevel + ' ' +'Recommended');
                            request.setObjectId(loanId);
                            request.setNextApproverIds(new Id[] { nextApproverLevel });
                            approverComment = currentApproverLevel + ' '+'Recommended' + '&&-'+comments+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
    
                            request.setProcessDefinitionNameOrId('Loan_Application_Approval');
    
                            Approval.process(request);
                        }
                    }
                    Opportunity loan= new Opportunity( Id = loanId);
                    loan.Approval_Status__c = 'Recommended';
                    loan.Draft_PD_Note__c = '';
                    loan.Approval_Sub_Status__c = currentApproverLevel + ' Recommended';
                    if(loanData[0].Approval_Comments__c!= null && loanData[0].Approval_Comments__c != ''){
                        loan.Approval_Comments__c = loanData[0].Approval_Comments__c+'%%-'+approverComment;
                    }else {
                        loan.Approval_Comments__c = approverComment;
                    }
                    update loan;
        
                    isApproved= true;
                    validations.add('success');

                    if(nextApproverLevel!= null && nextApproverLevel!= ''){
                        receipientIds.add(nextApproverLevel);
                        //send email
                        List<String> sendToAddressesList = new List<String>();
                        List<String> ccList= new List<String>();
                        ccList.add(Constants.get('CC_Email_For_Loan_Approval'));
                        // ccList.add('loan_application_approval@1zc1qf6ayshufdirj1p3qq3mu5o80rzoznahfyf53e5d9ojfh7.bi-1oxzwmau.ind14s.apex.sandbox.salesforce.com');
                        List<User> userListMail= [SELECT Id, Email FROM User WHERE Id =:nextApproverLevel];
                        sendToAddressesList.add(userListMail[0].Email);
                        // sendToAddressesList.add('yjangid@deloitte.com');
                        List<Messaging.SingleEmailMessage> emailToUsers = new List<Messaging.SingleEmailMessage>();
                        List<OrgWideEmailAddress> owdEmail =[SELECT Id FROM OrgWideEmailAddress WHERE Address=:constants.get('OrgWideFromAddressEmail')];
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        EMailTemplate temp= [SELECT Id,Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Loan_Application_Approval' LIMIT 1];
                        String body= temp.Body;
                        // String body = temp.HtmlValue;
                        body = body.replace('{#Name}',loanData[0].Name);
                        body = body.replace('{#ApprovalStatus}', currentApproverLevel + ' Recommended');
                        body = body.replace('{#UserName}', currUserName);
                        email.setOrgWideEmailAddressId(owdEmail[0].Id); 
                        email.setTemplateId(temp.id);
                        // email.setHTMLBody(body);
                        email.setPlainTextBody(body);
                        email.setToAddresses(sendToAddressesList);
                        email.setCcAddresses(ccList);
                        email.setSubject('Loan Application '+loanData[0].Name+' - Approval Request');
                        // email.setReplyTo('loan_application_approval@1zc1qf6ayshufdirj1p3qq3mu5o80rzoznahfyf53e5d9ojfh7.bi-1oxzwmau.ind14s.apex.sandbox.salesforce.com');  
                        emailToUsers.add(email);

                        Messaging.sendEmail(emailToUsers);
                    }

                    
                    sendActionNotification(loanId, 'Recommend', receipientIds, currUserName+' - '+currentApproverLevel, approvalType);
                }
            }
            
        } catch (Exception e) {
            System.debug('Error in recommendLoanApproval ---'+ e.getMessage());
            validations.add('fail');
        }

        return validations;
    }

    @AuraEnabled
    public static Boolean sendBackLoan( String loanId, String comments, String sendBackType, String selectedUserId, String approvalType){
		Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('oppId', loanId);
        Utility_V1.ProductWrapper productWrapper = Utility_V1.getProductDetails(inputMap);
        Boolean isHlRelated = productWrapper.isHLRelated;
        Boolean isSentBack = false;

        try {
            List<Opportunity> loanData= [SELECT Id,Sanction_Loan_Amount__c, Branch_Master__c FROM Opportunity WHERE Id = :loanId];
            if(loanData.size()>0 && loanData[0].Branch_Master__c != null){
                Set<String> receipientIds= new Set<String>();
                List<string> currentApproverLevelDetails = LoanApplicationApprovalController.getCurrentApproverLevel(UserInfo.getUserId(), loanData[0].Branch_Master__c, approvalType);
                String currentApproverLevel = currentApproverLevelDetails[0];
                String currentApproverLevelDisplay = currentApproverLevelDetails[1];
                    
                if (sendBackType == 'Originator') {
                    List<AccountTeamMember> eligibleApprovers = [SELECT Id, Level__c, UserId FROM AccountTeamMember WHERE AccountId = :loanData[0].Branch_Master__c AND User.IsActive = true AND Level__c = 'L1'];
                    if(eligibleApprovers.size()>0){
                        selectedUserId = eligibleApprovers[0].UserId;
                    }
                }else if (sendBackType == 'Search') {
                    List<OpportunityTeamMember> teamMembers = [SELECT Id, UserId, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId = :loanId AND TeamMemberRole = 'Credit' AND UserId= :selectedUserId];

                    if(teamMembers.size()==0){
                        OpportunityTeamMember member= new OpportunityTeamMember();
                        member.OpportunityId = loanId;
                        member.UserId = selectedUserId;
                        member.TeamMemberRole = 'Credit';
                        member.OpportunityAccessLevel = 'Edit';
                        insert member;
                    }
                    else if(teamMembers.size()>0){
                        for(OpportunityTeamMember member: teamMembers){
                            // member.UserId = null;
                            //delete member;
                        }
                    }
                    
                }

                List<ProcessInstanceWorkitem> workItems = [SELECT Id, ActorId, OriginalActorId, ProcessInstance.CreatedById, ProcessInstance.CreatedDate, ProcessInstance.TargetObjectId, ProcessInstance.Status 
                                            FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: loanId AND ProcessInstance.Status = 'Pending'];

                List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
                for(ProcessInstanceWorkitem workItem : workItems){
                    Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                    req.setWorkitemId(workItem.Id);
                    req.setAction('Reject');        
                    req.setComments(isHlRelated ? currentApproverLevelDisplay : currentApproverLevel + ' ' +'Sent Back');//add loan approval status for status historyyy
                    requests.add(req);
                }
                if(requests.size()>0){
                    Approval.ProcessResult[] processResults = Approval.process(requests);
                }

                if(selectedUserId!= null && selectedUserId!= ''){
                    receipientIds.add(selectedUserId);
                    Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                    request.setComments('No Level;Please review the loan application.');
                    request.setObjectId(loanId);
                    request.setNextApproverIds(new Id[] { selectedUserId });

                    request.setProcessDefinitionNameOrId('Loan_Application_Approval');

                    Approval.process(request);
                }

                String currUserName= getCurrentUserName();
                String currentApproverLevelFinal = isHlRelated ? currentApproverLevelDisplay : currentApproverLevel;
                sendActionNotification(loanId, 'Sent', receipientIds, currUserName+' - '+currentApproverLevelFinal, approvalType);

                Opportunity loan= new Opportunity( Id = loanId);
                 if(approvalType == 'pricing Approval'){
                      loan.Pricing_Approval_Status__c = 'Sent Back';
                 }else{
                loan.Approval_Status__c = 'Sent Back';
                 
                loan.Approval_Sub_Status__c = isHlRelated ? currentApproverLevelDisplay : currentApproverLevel + ' Sent Back';
                 }
                update loan;
    
                isSentBack= true;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return isSentBack;
    }

    public static List<String> getCurrentApproverLevel( String approverUserId, String loanId,String approvalType){
        List<String> level = new List<string>();
        level.add('No Level');
        level.add('No Level');

        system.debug('approvalTypeL::'+approvalType);

        List<AccountTeamMember> teamMembers = new List<AccountTeamMember>();
        List<String> allApprovers;
        String type = 'Credit';
        try {
            if(approvalType == 'Exception Approval'){
                type = 'Sales';
            }
            teamMembers = [SELECT Id, TeamMemberRole, Level__c, Approving_Authority_FICO__c FROM AccountTeamMember WHERE UserId = :approverUserId AND TeamMemberRole = :type AND AccountId = :loanId And Level__c != null];
                if(teamMembers.size() > 0){
                level.clear();
                level.add(teamMembers[0].Level__c);
                level.add(teamMembers[0].Approving_Authority_FICO__c);
                }            
        } catch (Exception e) {
            System.debug('Error in getCurrentApproverLevel ---'+ e.getMessage());
        }
        system.debug('level: '+level);
        return level;
    }


    public static String getNextApproverLevel( String currentLevel,String highestApprover ,String loanId, String approvalType, Boolean isFinalApprover){
        String userId;
        try {

            if (String.isEmpty(currentLevel) || !currentLevel.startsWith('L')) {
                return 'Invalid Input';
            }

            List<Opportunity> loanappList= [SELECT Id, OwnerId, Owner.Name, Branch_Master__c,Sanction_Loan_Amount__c FROM Opportunity WHERE Id = :loanId];
            String branchId = loanappList[0].Branch_Master__c;
            // String requestedAmount= String.valueOf(loanappList[0].Sanction_Loan_Amount__c);
            Decimal requestedAmount= loanappList[0].Sanction_Loan_Amount__c;
            String numericPart = currentLevel.substring(1);

            List<String> levelNumbers= new List<String>();
            Integer levelNumber = Integer.valueOf(numericPart); 
            String numericPartHighest = highestApprover.substring(1);

            Integer numberHighest = Integer.valueOf(numericPartHighest); 
            for(Integer i= levelNumber+1; i<=numberHighest; i++){
                levelNumbers.add('L'+String.valueOf(i));
            }

            System.debug('levelNumbers---'+levelNumbers);
            levelNumber += 1; 

            String nextLevel;
            System.debug('nextLevel---'+nextLevel);
            

            
            String level;
            String query = 'SELECT Id, Level__c, UserId, User.Name FROM AccountTeamMember WHERE AccountId = :branchId AND User.IsActive = true ';
            if(levelNumber == numberHighest && !isFinalApprover){
                nextLevel = 'L' + Integer.valueOf(numericPart);
                query = query + ' AND Minimum_authority_loan_amount__c <= '+requestedAmount+'  AND Maximum_authority_loan_amount__c >= '+requestedAmount ;
            }
            if(levelNumber<= numberHighest){
                nextLevel= 'L' + String.valueOf(levelNumber); 
            }
            // query = query + ' AND Level__c = :nextLevel';
            System.debug('query---'+query);
            if(nextLevel!= null){
                List<AccountTeamMember> teamMembers = Database.query(query);
                for (String levelNum : levelNumbers) {
                    for (AccountTeamMember member : teamMembers) {
                        if (member.Level__c == levelNum) {
                            return member.UserId;
                        }
                    }
                }
                // for(AccountTeamMember member: teamMembers){

                // }
                // if(teamMembers.size() > 0){
                //     userId= teamMembers[0].UserId;
                // }
            }
            

        } catch (Exception e) {
            System.debug('Error in getCurrentApproverLevel ---'+ e.getMessage());
        }

        return userId;
    }
    
    @AuraEnabled
    public static Map<Id, String> getOriginator( String loanId){
        Map<Id, String> originatorMap = new Map<Id, String>();

        try {
            List<Opportunity> loanappList= [SELECT Id, OwnerId, Owner.Name, Branch_Master__c FROM Opportunity WHERE Id = :loanId];
            if(loanappList.size() > 0){
                List<AccountTeamMember> eligibleApprovers = [SELECT Id, Level__c, UserId, User.Name FROM AccountTeamMember WHERE AccountId = :loanappList[0].Branch_Master__c AND User.IsActive = true AND Level__c = 'L1'];
                if(eligibleApprovers.size()>0){

                    originatorMap.put(eligibleApprovers[0].UserId, eligibleApprovers[0].User.Name+ ' - '+eligibleApprovers[0].Level__c);
                }
            
                // originatorMap.put(loanappList[0].OwnerId, loanappList[0].Owner.Name);
            }
            System.debug('originatorMap-----'+originatorMap);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return originatorMap;
    }

    public class ApprovalWrapper {
        @AuraEnabled public Boolean showApprovalButtons;
        @AuraEnabled public String currentStatus;
        @AuraEnabled public String finalAuthority;
        @AuraEnabled public String currentApprover;
        @AuraEnabled public Boolean showApproveButton=false;
        @AuraEnabled public Boolean showSubmitApprovalButton=false;
        @AuraEnabled public Boolean showHoldButton=false;
        @AuraEnabled public Boolean showUnholdButton = false;
        @AuraEnabled public Boolean showRecommendButton=false;
        @AuraEnabled public Boolean showApprovalHistory=false;
        @AuraEnabled public Boolean showRejectButton=false;
        @AuraEnabled public Boolean showPullBackButton=false;
        @AuraEnabled public Boolean showSendBackButton=false;
        @AuraEnabled public String contentId;
        @AuraEnabled public Boolean disableExceptionSelect=true;
        @AuraEnabled public List<StatusHistoryWrapper> statusHistory;
        @AuraEnabled public List<ExceptionWrapper> exceptions;
        @AuraEnabled public Integer commentLenth;
        @AuraEnabled public String remarks;
        @AuraEnabled public String draftComment;
    }

    public class StatusHistoryWrapper{
        @AuraEnabled public String status;
        @AuraEnabled public String remarks;
        @AuraEnabled public String requestor;
        @AuraEnabled public DateTime timeStamp;
        @AuraEnabled public Boolean isRequestor= false;
    }

    public class ExceptionWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public Boolean selected;
    }
    
    public static void sendExceptionApprovalEmail(
        String ownerEmail,
        String ownerName,
        String loanNumber,
        String decision,
        String approver
    ) {
			System.debug('ownerEmail--'+ownerEmail +'ownerName--'+ownerName +'loanNumber--'+ loanNumber +'decisio--'+decision+'approver--'+approver);       
        String htmlBody =
            '<p>Dear <b>' + ownerName + '</b>,</p>' +

            '<p>Your exception approval request for loan application number ' +
            '<b>' + loanNumber + '</b> has been <b>' + decision + '</b> by ' +
            '<b>' + approver + '</b>.</p>' +
            '<p>Regards,<br/>' + approver + '</p>';

        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        msg.setToAddresses(new List<String>{ ownerEmail });
        msg.setSubject('Exception Approval ' + decision + ' – ' + loanNumber);
        msg.setHtmlBody(htmlBody);
        msg.setSaveAsActivity(false);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ msg });
    }

    public static void sendActionNotification( String loanId, String action, Set<String> recepients, String actionPerson,String approvalType){
        try {
            Map<String, String> inputMap = new Map<String, String>();
            inputMap.put('oppId', loanId);
            Utility_V1.ProductWrapper productWrapper = Utility_V1.getProductDetails(inputMap);
            Boolean isHlRelated = productWrapper.isHLRelated;
            List<Opportunity> loanData= [SELECT Id,Sanction_Loan_Amount__c, Branch_Master__c, Loan_Application_Number__c FROM Opportunity WHERE Id = :loanId];
            CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'Loan_Approval_Notification'];
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(loanId);
            String title;
            String body;
            if(approvalType == 'Loan Approval'){
                if(action == 'Approve'){
                    title = 'Loan Approved';
                    body = 'Loan Application '+ loanData[0].Loan_Application_Number__c+' has been approved.';
                }else if(action == 'Reject'){
                    title = 'Loan Rejected';
                    body = 'Loan Application '+ loanData[0].Loan_Application_Number__c+' has been rejected.';
                }else if(action == 'Sent'){
                    title = 'Loan Sent Back';
                    body = 'Loan Application '+ loanData[0].Loan_Application_Number__c+' has been sent back to you by '+actionPerson+'.';
                }else if(action == 'Recommend'){
                    title = isHlRelated? 'Loan Submitted' : 'Loan Recommended';
                    body = 'Loan Application '+ loanData[0].Loan_Application_Number__c+' has been ' + (isHlRelated? 'submitted' : 'recommended' ) + ' to you by '+actionPerson+'.';
                }
            }else if(approvalType == 'Exception Approval'){
                if(action == 'Approve'){
                    title = 'Exceptions Approved';
                    body = 'Loan Application '+ loanData[0].Loan_Application_Number__c+' has been approved.';
                }else if(action=='Reject'){
                    title = 'Exceptions Rejected';
                    body = 'Loan Application '+ loanData[0].Loan_Application_Number__c+' has been rejected.';
                }else if(action=='Submit'){
                    title = 'Exceptions Submitted';
                    body = 'Loan Application '+ loanData[0].Loan_Application_Number__c+' has been submitted for approval to you by '+actionPerson+'.';
                }
            }
            

            if(title!= null && body!= null){
                notification.setTitle(title);
                notification.setBody(body);
                if(recepients.size()>0){
                    notification.send(recepients);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<Id, String> getRecommendUsers(String loanId){
        Map<Id, String> recommendUsers = new Map<Id, String>();
        try {
            List<Opportunity> loanData= [SELECT Id,Sanction_Loan_Amount__c, Branch_Master__c, Loan_Application_Number__c FROM Opportunity WHERE Id = :loanId];
            List<AccountTeamMember> creditMembers= [SELECT Id, UserId, User.Name, Level__c FROM AccountTeamMember WHERE TeamMemberRole = 'Credit' AND AccountId = :loanData[0].Branch_Master__c];

            String currentLevel;
            for(AccountTeamMember member : creditMembers){
                if(member.UserId == UserInfo.getUserId()){
                    currentLevel = member.Level__c;
                }
            }

            for(AccountTeamMember member: creditMembers){
                if(Integer.valueOf(member.Level__c) >= Integer.valueOf(currentLevel) && member.UserId != UserInfo.getUserId()){
                    recommendUsers.put(member.UserId, member.User.Name + ' - L'+member.Level__c);
                }
            }

            System.debug('recommendUsers----'+recommendUsers);

        } catch (Exception e) {
            System.debug('Error fetching users----'+e.getMessage());
            // throw new AuraHandledException(e.getMessage());
        }

        return recommendUsers;
    }

    @AuraEnabled
    public static List<String> checkApprovedDeviations( String loanId, String currentApprover){
        Map<String, String> inputMap = new Map<String, String>();
        inputMap.put('oppId', loanId);
        Utility_V1.ProductWrapper productWrapper = Utility_V1.getProductDetails(inputMap);
        Boolean isHlRelated = productWrapper.isHLRelated;
        List<String> approvalValidationList= new List<String>();
        try {
            List<Opportunity> loanData= [SELECT Id, Eligible_Loan_Amount__c,StageName FROM Opportunity WHERE Id = :loanId];
            List<Application_Deviation__c> deviationList = [SELECT id,Approving_Authority__c, Approval_Status__c FROM Application_Deviation__c WHERE Loan_Application__c =:loanId order by CreatedDate DESC];
            Integer userLevel = Integer.valueOf(currentApprover.substring(1));
            List<Application_Verification__c> lstApplicationVerification = new List<Application_Verification__c>();
            if(!isHlRelated){
                String pdRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Personal_Discussion');
                lstApplicationVerification = [SELECT id,Disposition__c,Call_Status__c,Credit_Managers_Disposition__c,Personal_Discussion_Type__c FROM Application_Verification__c WHERE Loan_Application__c =: loanId AND recordTypeId =: pdRecordTypeId AND IsParent__c = false];
            }
            

            Boolean isDeviationApproved= false;
            if(!isHlRelated && loanData.size()>0){
                if((loanData[0].Eligible_Loan_Amount__c == null)&& loanData[0].StageName != 'PSV'){
                    approvalValidationList.add('Please hit eligibility to proceed further.');
                }
            }
            for(Application_Deviation__c deviation : deviationList){
                Integer approvingAuthority= Integer.valueOf(deviation.Approving_Authority__c);
                if(approvingAuthority <= userLevel && deviation.Approval_Status__c == 'Pending'){
                    isDeviationApproved = true;
                    if(currentApprover== 'L1'){
                        approvalValidationList.add('Please approve deviations of level '+currentApprover+'.');
                    }else{
                        approvalValidationList.add('Please approve deviations of level '+currentApprover+' and below.');
                    }
                    
                    break;
                }
            }
            if(!isHlRelated && lstApplicationVerification.size() > 0) {
                for(Application_Verification__c pdsIter : lstApplicationVerification) {
                    if(pdsIter.Personal_Discussion_Type__c != 'Tele PD') {
                    
                        if(pdsIter.Disposition__c == null && pdsIter.Personal_Discussion_Type__c != 'Vendor PD') {
                            approvalValidationList.add('Missing disposition of PD(s) initiated/performed.');
                            break;
                        }
                        if(pdsIter.Credit_Managers_Disposition__c == null && pdsIter.Personal_Discussion_Type__c == 'Vendor PD') {
                            approvalValidationList.add('Missing disposition of PD(s) initiated/performed.');
                            break;
                        }
                    }else {
                        if(pdsIter.Disposition__c == null && String.isNotBlank(pdsIter.Call_Status__c)) {
                            approvalValidationList.add('Missing disposition of Tele PD initiated/performed.');
                            break;
                    
                        }
                    
                    }
                }
            }
        } catch (Exception e) {
            // throw new AuraHandledException(e.getMessage());
            System.debug('Error in validation--'+e.getMessage());
            approvalValidationList.add(e.getMessage());
        }
        return approvalValidationList;
    }

    @AuraEnabled
    public static void unHoldApplication(String loanId, String comment){
        try {
            Opportunity opp= new Opportunity();
            opp.Id= loanId;
            opp.Approval_Status__c = 'In Progress';
            opp.Approval_Sub_Status__c = comment;
            opp.Sub_stage__c = 'Credit in-progress';
            update opp;
        
            List<TAT__c> tatRecordList = new List<TAT__c>();
            List<TAT__c> existingTatRecords= [SELECT Id, Activity__c FROM TAT__c WHERE Loan_Application__c = :loanId AND Activity__c= 'Hold'];

            for(TAT__c tat: existingTatRecords){
                //tat.End_Timestamp__c = System.now();
                tatRecordList.add(tat);
            }
            if(tatRecordList.size() > 0){
                upsert tatRecordList;
            }

            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string holdLoanApp( String loanId, String comment){
        String res;
        try {
            List<Opportunity> loanData= [SELECT Id,Sanction_Loan_Amount__c, Branch_Master__c, OwnerId, Name, Approval_Comments__c, StageName FROM Opportunity WHERE Id = :loanId];
            String currUserName= getCurrentUserName();
            String currentApproverLevel=  LoanApplicationApprovalController.getCurrentApproverLevel(UserInfo.getUserId(), loanData[0].Branch_Master__c,'Loan Approval')[1];
            String approverComment = currentApproverLevel + ' '+'Hold' + '&&-'+comment+ '&&-'+System.now().format('yyyy-MM-dd, HH:mm:ss')+ '&&-'+currUserName;
            Opportunity opp= new Opportunity();
            opp.Id= loanId;
            opp.Approval_Sub_Status__c = currentApproverLevel +' Hold';
            opp.Approval_Status__c = 'Hold';
            opp.Sub_stage__c = 'Hold';
            List<Document_Details__c> documentList= [SELECT Id, Content_Document_Id__c FROM Document_Details__c WHERE Loan_Application__c= :loanId AND Name = 'Loan Approval Comments'];
            if (documentList.size()>0){
                ContentVersion latestVer = [
                    SELECT Id, VersionData
                    FROM ContentVersion
                    WHERE ContentDocumentId = :documentList[0].Content_Document_Id__c
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                List<ContentDocumentLink> cdList = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :documentList[0].Id];
                if (cdList.size()>0) {
                    Database.delete(cdList);
                }
                String oldText = latestVer.VersionData != null ? latestVer.VersionData.toString() : '';
                ContentVersion cv = new ContentVersion(
                    ContentDocumentId = documentList[0].Content_Document_Id__c,
                    Title = 'Approval Comments',
                    PathOnClient = 'LoanApprovalComments.txt',
                    VersionData = Blob.valueOf(oldText +'%%-'+approverComment)
                );
                insert cv;
            }else {

                ContentVersion cv = new ContentVersion(
                    Title = 'Approval Comments',
                    PathOnClient = 'LoanApprovalComments.txt',
                    VersionData = Blob.valueOf(approverComment)
                );
                insert cv;
                String contentDocId= [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
                Document_Details__c document= new Document_Details__c(
                    Name= 'Loan Approval Comments',
                    Content_Document_Id__c= contentDocId,
                    Loan_Application__c = loanId
                );
                insert document;

                insert new ContentDocumentLink(
                    ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
                    LinkedEntityId = document.Id,
                    ShareType = 'V'
                );
            }
            // if(loanData[0].Approval_Comments__c!= null && loanData[0].Approval_Comments__c != ''){
            //     opp.Approval_Comments__c = loanData[0].Approval_Comments__c+'%%-'+approverComment;
            // }else {
            //     opp.Approval_Comments__c = approverComment;
            // }

            TAT__c tatRecord = new TAT__c();
            tatRecord.Stage__c = loanData[0].StageName;
            tatRecord.Activity__c = 'Hold';
            tatRecord.Sub_Activity__c = 'Case is on hold';
            tatRecord.User_Name__c = UserInfo.getUserId();
            tatRecord.Timestamp__c = System.now();
            tatRecord.Loan_Application__c = loanId;
            // tatRecord.Code__c = 'C-014';
            insert tatRecord;
            
            update opp;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return res;
    }

}