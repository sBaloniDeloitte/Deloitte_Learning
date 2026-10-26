public without sharing class HL_LoanApplicationApprovalController {
    
    @AuraEnabled
    public static ApprovalWrapper getLoanApprovalDetails(String loanId){
        ApprovalWrapper approvalData = new ApprovalWrapper();

        try {
            approvalData.showApprovalButtons = false;
            approvalData.showApproveButton = false;
            approvalData.showRecommendButton = false;
            approvalData.showHoldButton = false;
            approvalData.showUnholdButton = false;
            approvalData.showRejectButton = false;
            approvalData.disableApproverLevel = true;
            approvalData.disableApprovalType = true;
            approvalData.isAssignedToUser = false;

            List<Opportunity> loanData = [SELECT Id, StageName, Sub_stage__c, Branch_Master__c, Approval_Status__c, IsApprovalAssignedToLevel__c, 
                                            Approval_Type__c, Loan_Hierarchy__c 
                                            FROM Opportunity WHERE Id =: loanId And Branch_Master__c != ''];

            if(!loanData.isEmpty()){
                approvalData.crApprovalType = loanData[0].Approval_Type__c;
                approvalData.isAssignedToUser = !loanData[0].IsApprovalAssignedToLevel__c;

                List<OpportunityTeamMember> oppTeamMember = [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId =: loanId AND TeamMemberRole = 'Credit' 
                                                            And UserId =: UserInfo.getUserId()];

                List<string> currentApproverDetails = getCurrentApproverLevel(UserInfo.getUserId(), loanData[0].Branch_Master__c);
                String currentApprover = currentApproverDetails[0];
                String currentApproverDisplay = currentApproverDetails[1];
                String firstApproverLevel = '';

                for(AccountTeamMember acc : [SELECT Id, Approving_Authority_FICO__c FROM AccountTeamMember WHERE AccountId =: loanData[0].Branch_Master__c
                                                And TeamMemberRole = 'Credit' And UserId =: UserInfo.getUserId()]){
                    
                    if(!oppTeamMember.isEmpty()){
                        firstApproverLevel = acc.Approving_Authority_FICO__c;
                    }

                    switch on loanData[0].Approval_Status__c {
                        when 'Hold' {
                            approvalData.showApprovalButtons = true;
                            approvalData.showRejectButton = true;
                            approvalData.showUnholdButton = true;
                        }
                        when 'In Progress' {
                            approvalData.showApprovalButtons = true;
                            approvalData.showRecommendButton = true;
                            approvalData.showApproveButton = true;
                            approvalData.showHoldButton = true;
                            approvalData.disableApproverLevel = false;
                            approvalData.disableApprovalType = false;

                            firstApproverLevel = acc.Approving_Authority_FICO__c;
                        }
                        when 'Sent Back' {
                            approvalData.showApprovalButtons = true;
                            approvalData.showRecommendButton = true;
                            approvalData.disableApproverLevel = false;
                            approvalData.disableApprovalType = false;
                        }
                        when 'Submitted' {
                            approvalData.showApprovalButtons = true;
                            approvalData.showRecommendButton = true;
                            approvalData.showApproveButton = true;
                            approvalData.showHoldButton = true;
                            approvalData.disableApproverLevel = false;
                        }
                    }
                }
                
                if(String.isNotBlank(currentApprover) && currentApprover != 'No Level' && currentApproverDisplay == firstApproverLevel){ 
                    approvalData.showRejectButton = false;
                }

                List<ProductWrapper> pwList = new List<ProductWrapper>();
                Map<String, String> productToConDocIdMap = new Map<String, String>();
                Map<Id, ContentVersion> contDocIdToContVersionMap = new Map<Id, ContentVersion>();

                List<string> loanHirchy = new List<string>();
                loanHirchy.add('Parent');
                loanHirchy.add('Child');

                if(loanData[0].StageName != 'Credit Underwriting'){
                    loanHirchy.clear();
                    loanHirchy.add(string.isNotBlank(loanData[0].Loan_Hierarchy__c) ? loanData[0].Loan_Hierarchy__c : 'Parent');
                }

                List<Product2> prodList = [SELECT Id, Name, Draft_PD_Note__c FROM Product2 WHERE RecordType.Name = 'Product' 
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
                    pw.productId = p.Id;
                    pw.prodComment = p.Draft_PD_Note__c;
                    pw.showApprovalHistory = false;

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
                                    historyWrp.remarks = commentParts[1] == null ? '' : commentParts[1];
                                    historyWrp.timeStamp = commentParts[2] == null ? null : DateTime.valueOf(commentParts[2].replace(',', ''));
                                    historyWrp.user = commentParts[3] == null ? '' : commentParts[3];
                                    historyWrp.approvalType = commentPartsSize == 5 ? (commentParts[4] == null ? '' : commentParts[4]) : '';
                            historyRecords.add(historyWrp);
                        }
                            }

                            pw.statusHistory = historyRecords;
                        pw.showApprovalHistory = true;
                    }
                    }

                    pwList.add(pw);
                }

                approvalData.products = pwList;
            }
        }
        catch (Exception e) {
            System.debug('e.getline: '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }

        return approvalData;
    }

    @AuraEnabled
    public static List<String> checkProductValidations(String loanId){
        try {
            List<String> validations = new List<String>();

            for(Product2 itrProd : [SELECT Id, Name, RecordType.Name, Loan_Application__r.Loan_Hierarchy__c FROM Product2 WHERE Loan_Application__c =: loanId 
                                    And RecordType.Name = 'Hybrid Tenure' Limit 1]){
                
                string validationMsg = checkCollateralValidation(loanId, itrProd.Loan_Application__r.Loan_Hierarchy__c, itrProd.Name);
                if(string.isNotBlank(validationMsg)){
                    validations.add(validationMsg);
                }
            }
            return validations;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static string checkCollateralValidation(string loanId, string loanHierarchy, string tenure){
        string result = '';

        List<Product2> prod = [SELECT Id, Name FROM Product2 WHERE Loan_Application__c =: loanId And RecordType.Name = 'Product' Limit 1];

        //skipping validation for stand alone FL
        if(loanHierarchy != 'Child' && prod[0].Name == 'Home Loan'){
            Integer prodMonths = Integer.valueOf(tenure);
            Date prodDate = Date.today().addMonths(prodMonths);

            for(Application_Collateral__c coll : [SELECT Id, Collateral__r.RERA_End_Date__c FROM Application_Collateral__c WHERE HL_Loan_Application__c =: loanId
                                                    AND Collateral__r.IsActive__c = true AND Collateral__r.APF__c = 'Yes']) {
                
                Date reraDate = coll.Collateral__r.RERA_End_Date__c;
                if(reraDate == null) { ////Added by Suhrit
                    result = 'RERA End Date is not present in the APF Collateral. Please add in order to proceed.';
                    break;
                }

                Date reraMinus2Months = reraDate.addMonths(-2);
                Date fortyEightMonths = Date.today().addMonths(48);
                Date lowerOfValue;
                if(reraMinus2Months < Date.today()) {
                    lowerOfValue = fortyEightMonths;
                } else {
                    lowerOfValue = (reraMinus2Months < fortyEightMonths) ? reraMinus2Months : fortyEightMonths;
                }

                if(prodDate > lowerOfValue) {
                    result = 'Interest Only Tenure cannot exceed the lower of RERA End Date - 2 months or 48 months.';
                    break;
                }
            }
        }

        return result;
    }

    private static void manageRecoNote(string loanId, List<Product2> mainProdList, string currentApproverLevelDisplay, string action, string approvalType){
        Set<Id> conDocIdSet = new Set<Id>();
        Set<Id> docDetailIdSet = new Set<Id>();
        List<Document_Details__c> docToInsert = new List<Document_Details__c>();
        Map<Id, ContentVersion> contDocIdToContVersionMap = new Map<Id, ContentVersion>();
        Map<Id, Document_Details__c> productToDocumentMap = new Map<Id, Document_Details__c>();

        for(Document_Details__c doc : [SELECT Id, Content_Document_Id__c, Product__c FROM Document_Details__c WHERE Loan_Application__c =: loanId 
                                        AND Name = 'Loan Approval Comments' And Product__c IN : mainProdList]){
            
            productToDocumentMap.put(doc.Product__c, doc);
            conDocIdSet.add(doc.Content_Document_Id__c);
            docDetailIdSet.add(doc.Id);
        }

        for(ContentVersion ver : [SELECT ContentDocumentId, VersionData FROM ContentVersion WHERE ContentDocumentId IN : conDocIdSet 
                                    And IsLatest = true ORDER BY CreatedDate Desc]){
            
            if(!contDocIdToContVersionMap.containsKey(ver.ContentDocumentId)){
                contDocIdToContVersionMap.put(ver.ContentDocumentId, ver);
            }
        }

        for(Product2 prod : mainProdList){
            string pComments = String.isNotBlank(prod.Draft_PD_Note__c) ? prod.Draft_PD_Note__c : 'No comments added';
            string approverComment = currentApproverLevelDisplay +' '+ action +'&&-'+ pComments +'&&-'+ System.now().format('yyyy-MM-dd, HH:mm:ss') +'&&-'+ UserInfo.getName() +'&&-'+ approvalType;

            List<String> splitData = approverComment.split('%%-');
            String commentData = splitData[splitData.size()-1].replace('&amp;&amp;-', '&&-');

            if(productToDocumentMap.containsKey(prod.Id)){
                String oldText = '';
                Document_Details__c doc = productToDocumentMap.get(prod.Id);

                if(contDocIdToContVersionMap.containsKey(doc.Content_Document_Id__c)){
                    ContentVersion latestVer = contDocIdToContVersionMap.get(doc.Content_Document_Id__c);
                    oldText = latestVer.VersionData != null ? latestVer.VersionData.toString() : '';
                }
                
                ContentVersion cv = new ContentVersion(
                    ContentDocumentId = doc.Content_Document_Id__c,
                    Title = 'Approval Comments',
                    PathOnClient = 'LoanApprovalComments.txt',
                    VersionData = Blob.valueOf(oldText +'%%-'+ commentData)
                );

                insert cv;
            }
            else {
                ContentVersion cv = new ContentVersion(
                    Title = 'Approval Comments',
                    PathOnClient = 'LoanApprovalComments.txt',
                    VersionData = Blob.valueOf(commentData)
                );

                insert cv;

                String contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
                
            Document_Details__c document = new Document_Details__c(
                Name = 'Loan Approval Comments',
                    Content_Document_Id__c = contentDocId,
                Loan_Application__c = loanId,
                Product__c = prod.Id
            );

            docToInsert.add(document);
            }

            prod.Draft_PD_Note__c = '';
        }

        contDocIdToContVersionMap.clear();

        update mainProdList;

        if(!docToInsert.isEmpty()){
            insert docToInsert;

            List<ContentDocumentLink> cdlToInsert = new List<ContentDocumentLink>();

            for(integer i=0; i< docToInsert.size(); i++){
                ContentDocumentLink cdl = new ContentDocumentLink(
                    ContentDocumentId = docToInsert[i].Content_Document_Id__c,
                    LinkedEntityId = docToInsert[i].Id,
                    ShareType = 'V'
                );

                cdlToInsert.add(cdl);
            }

            if(!cdlToInsert.isEmpty()){
                insert cdlToInsert;
            }
        }
    }

    //method to approve or reject the loan application
    @AuraEnabled
    public static List<String> performApprovalAction(String loanId, String action, string comments, String approvalType){
        List<String> validations = new List<String>();
        
        try {
            List<Opportunity> loanData = [SELECT Id, Sourcing_Manager__c, Branch_Master__c, OwnerId, is_Multiproduct_Loan__c, Is_Top_Up__c, Approval_Type__c, 
                                            Product__c, Loan_Hierarchy__c FROM Opportunity WHERE Id =: loanId And Branch_Master__c != ''];
            
            if(!loanData.isEmpty()){
                List<string> currentApproverLevelData = getCurrentApproverLevel(UserInfo.getUserId(), loanData[0].Branch_Master__c);
                System.debug('currentApproverLevelData: '+currentApproverLevelData);

                String approverComment;
                String currentApproverLevelDisplay = currentApproverLevelData[1];
                List<String> validationList = checkProductValidations(loanData[0].Id);
                
                if(!validationList.isEmpty()){
                    System.debug('validationList>>>'+validationList);
                    return validationList;
                }
                else{
                    Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                    request.setComments(currentApproverLevelDisplay +' Submitted');
                    request.setObjectId(loanId);
                    request.setNextApproverIds(new Id[] { UserInfo.getUserId() });
                    approverComment = currentApproverLevelDisplay +' Submitted&&-'+ comments +'&&-'+ System.now().format('yyyy-MM-dd, HH:mm:ss') + '&&-'+ UserInfo.getName();
                    request.setProcessDefinitionNameOrId('Loan_Application_Approval');

                    Approval.process(request);
                }

                List<ProcessInstanceWorkitem> processsInstanceList = [SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: loanId];
                system.debug('processsInstanceList: '+processsInstanceList);

                if(!processsInstanceList.isEmpty()){
                    String actionStatus = action == 'Approv' ? 'Approve' : 'Reject';
                    List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();

                    for(ProcessInstanceWorkitem workItem : processsInstanceList){
                        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                        req.setWorkitemId(workItem.Id);
                        req.setAction(actionStatus);        //Valid values are: Approve, Reject, or Removed and Only system administrators can specify Removed.
                        req.setComments(action);
                        approverComment = currentApproverLevelDisplay +' '+ action +'ed&&-'+ comments +'&&-'+ System.now().format('yyyy-MM-dd, HH:mm:ss') +'&&-'+ UserInfo.getName();
                        requests.add(req);
                    }
    
                    Approval.ProcessResult[] processResults = Approval.process(requests);

                    Opportunity loan = new Opportunity(Id = loanId);
                    loan.Approval_Status__c = action +'ed';
                    loan.Approval_Sub_Status__c = currentApproverLevelDisplay +' '+ action +'ed';
                    loan.Sub_stage__c = 'Credit in-progress';

                    Boolean isError = false;
                    List<Product2> subProdList = new List<Product2>();
                    List<Product2> mainProdList = new List<Product2>();
                    Map<string, List<Decimal>> subProdToValuesMap = new Map<string, List<Decimal>>();

                    for(Product2 itrProd : [SELECT Id, Name, Sanctioned_Tenor__c, Product__r.Name, Product__r.Product__r.Name, RecordType.Name, 
                                            Draft_PD_Note__c, Sanctioned_Loan_Amount__c, Sanctioned_ROI__c, Final_Loan_Amount__c
                                            FROM Product2 WHERE Loan_Application__c =: loanId Order By Product__r.Product_Type__c Desc]){

                        if(itrProd.RecordType.Name == 'Product'){
                            mainProdList.add(itrProd);
                        }
                        else if(itrProd.RecordType.Name == 'Hybrid Tenure'){
                            string validationMsg = checkCollateralValidation(loanId, loanData[0].Loan_Hierarchy__c, itrProd.Name);
                            if(string.isNotBlank(validationMsg)){
                                validations.add(validationMsg);
                                isError = true;
                            }
                        }
                        else if(itrProd.RecordType.Name == 'Sub Product'){
                            subProdList.add(itrProd);

                            if((itrProd.Product__r.Name == 'Home Loan' || itrProd.Product__r.Name == 'Flexi Loan')){
                                if(subProdToValuesMap.containsKey(itrProd.Name)){
                                    subProdToValuesMap.get(itrProd.Name).add(itrProd.Sanctioned_Tenor__c);
                                }
                                else{
                                    subProdToValuesMap.put(itrProd.Name, new List<Decimal> {itrProd.Sanctioned_Tenor__c});
                                }
                            }
                        }
                        else if(itrProd.RecordType.Name == 'Full EMI' && (itrProd.Product__r.Product__r.Name == 'Home Loan' || itrProd.Product__r.Product__r.Name == 'Flexi Loan')){
                            if(subProdToValuesMap.containsKey(itrProd.Product__r.Name)){
                                subProdToValuesMap.get(itrProd.Product__r.Name).add(Decimal.valueOf(itrProd.Name));
                            }
                            else{
                                subProdToValuesMap.put(itrProd.Product__r.Name, new List<Decimal> {Decimal.valueOf(itrProd.Name)});
                            }
                        }
                    }
                    
                    if(action == 'Approv'){
                        loan.Final_Rate_Of_Interest__c = subProdList[0].Sanctioned_ROI__c;

                        if(approvalType == 'Income Approval'){
                            loan.Sub_stage__c = 'Offer Discussion In Progress';
                        }
                        else if(approvalType == 'Final Approval'){
                            loan.StageName = 'PSV';
                            loan.Sub_stage__c = 'PSV Sales';
                            loan.Eligible_for_Resanction__c = false;
                            
                            //Multi-CR-Ishi
                            if(!subProdList.isEmpty() && subProdList.size() > 1){
                                loan.is_Multiproduct_Loan__c = true;
                            }
                            else{
                                loan.is_Multiproduct_Loan__c = false;
                            }
                            //Multi-CR-Ishi

                            decimal sanctionAmount = 0;

                            for(Product2 rec : subProdList){
                                if(rec.Sanctioned_Loan_Amount__c == null){
                                    validations.add('Sanction Loan Amount is required for '+ rec.Name);
                                    isError = true;
                                }
                                else if(rec.Final_Loan_Amount__c < 0){
                                    validations.add('Eligibility Amount should not be negative for '+ rec.Name);
                                    isError = true;
                                }
                                else if(rec.Name != 'Flexi Loan'){
                                    sanctionAmount += rec.Sanctioned_Loan_Amount__c;
                                }

                                if(rec.Sanctioned_ROI__c == null){
                                    validations.add('Sanction ROI is required for '+ rec.Name);
                                    isError = true;
                                }
                                if(rec.Sanctioned_Tenor__c == null){
                                    validations.add('Sanction Tenor is required for '+ rec.Name);
                                    isError = true;
                                }
                            }
                            
                            for(string key : subProdToValuesMap.keySet()){
                                List<Decimal> values = subProdToValuesMap.get(key);
                                if(values.size() == 2 && values[0] != values[1]){
                                    validations.add('The Sanctioned Tenor and Full EMI Tenor in Product table do not match for '+ key +'. Kindly enter the Sanctioned Tenor received from BRE into the full EMI Tenor in product table in order to proceed');
                                    isError = true;
                                }
                            }
                            
                            //skipping this validation for stand alone FL
                            if(loanData[0].Loan_Hierarchy__c != 'Child' && subProdList[0].Product__r.Name == 'Home Loan'){
                                //Added by Suhrit
                                decimal techValidationAmount = Decimal.valueOf(System.Label.TechValidationAmount);

                                if(loanData[0].Is_Top_Up__c == 'Yes' && loanData[0].Product__c != 'Flexi Loan'){
                                    sanctionAmount += loanData[0].Parent_Loan_Amount__c;
                                }
                                system.debug('sanctionAmount: '+sanctionAmount);

                                List<Technical_Evaluation__c> techEvalList = [Select Id From Technical_Evaluation__c Where HL_Loan_Application__c =: loanId 
                                                                                And HL_Stage__c = 'Accepted by Technical Manager'];
                                
                                if(techEvalList.size() <2 && sanctionAmount > techValidationAmount){
                                    validations.add('Please ensure that a minimum of two Technical Evaluation records are created for the loan application where the sanction amount is greater than '+ techValidationAmount +'.');
                                    isError = true;
                                }
                                else if(techEvalList.size() <1){
                                    validations.add('Atleast one Technical Evaluation is required.');
                                    isError = true;
                                }

                                for(Application_Collateral__c rec : [SELECT Id, Name, Collateral__r.Market_Value__c, Collateral__r.Remarks__c FROM Application_Collateral__c 
                                                                        WHERE HL_Loan_Application__c =: loanId ]){
                                    
                                    if(rec.Collateral__r.Market_Value__c == null || rec.Collateral__r.Remarks__c == null){
                                        validations.add('Valuation or Remarks missing for Collateral - '+ rec.Name);
                                        isError = true;
                                    }
                                }
                            }

                            String primaryApplicantId;
                            Set<string> applicantIds = new Set<string>();
                            for(Application_Applicant__c appRec : [SELECT Id, Name, Applicant_Type__c, Customer_Profile__c, Borrower_Profile__c FROM Application_Applicant__c
                                                                    WHERE Loan_Application__c =: loanId
                                                                    AND Applicant_Type__c IN ('Primary Applicant','Co Applicant','Guarantor','Beneficiary Owner','Financial Co-Applicant')]){

                                if(appRec.Applicant_Type__c == 'Primary Applicant'){
                                    primaryApplicantId = appRec.Id;
                                }

                                if((appRec.Customer_Profile__c == 'SEP' || appRec.Customer_Profile__c == 'SENP') && String.isBlank(appRec.Borrower_Profile__c)){
                                    String displayName = String.isNotBlank(appRec.Name) ? (appRec.Name +' ('+ appRec.Applicant_Type__c +')') : appRec.Applicant_Type__c;
                                    validations.add('Borrower Profile is missing for ' + displayName);
                                    isError = true;
                                }

                                applicantIds.add(appRec.Id);
                            }

                            if(primaryApplicantId == null){
                                validations.add('Primary Applicant not found for this loan application.');
                                isError = true;
                            }
                            else {
                                List<Bank_Details__c> repaymentAccounts = [SELECT Id FROM Bank_Details__c WHERE Application_Applicant__c IN : applicantIds AND Is_Repayment_Account__c = true];
                                
                                if(repaymentAccounts.isEmpty()){
                                    validations.add('Please add a repayment account to proceed further.');
                                    isError = true;
                                }
                            }
                        }
                        
                        for(SalesDocumentValidationChecklist.AddressWrapper wrapper : SalesDocumentValidationChecklist.checkAddressType(loanId)){
                            validations.add(wrapper.errorMsg);
                            isError = true;
                        }

                        for(Application_Deviation__c rec : [Select Id, Mitigants__c From Application_Deviation__c Where Loan_Application__c =: loanId And 
                                                            Approval_Status__c = 'Pending']){

                            if(rec.Mitigants__c == null){
                                validations.add('All Deviations should have Mitigant before approve.');
                                isError = true;
                                break;
                            }
                        }

                        if(isError){
                            return validations;
                        }
                    }
                    
                    update loan;

                    //adding OTM record if it is not there
                    List<OpportunityTeamMember> salesOtmCheck = [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId =: loanId AND TeamMemberRole = 'Sales' 
                                                                    AND Associated_With_Loan_Application__c = true];
                    if(salesOtmCheck.isEmpty()){
                        OpportunityTeamMember rec = new OpportunityTeamMember(
                            OpportunityId = loanId,
                            UserId = loanData[0].Sourcing_Manager__c,
                            TeamMemberRole = 'Sales',
                            Associated_With_Loan_Application__c = true,
                            OpportunityAccessLevel = 'All'
                        );
                        insert rec ;
                    }

                    Set<String> receipientIds = new Set<String>();
                    receipientIds.add(loanData[0].OwnerId);

                    sendActionNotification(loanId, actionStatus, receipientIds, UserInfo.getName() +' - '+ currentApproverLevelDisplay, approvalType);

                    validations.add('success');

                    manageRecoNote(loanId, mainProdList, currentApproverLevelDisplay, action +'ed', loanData[0].Approval_Type__c);
                }
            }
        }
        catch (Exception e) {
            System.debug('Approval ERROR STACK: ' + e.getStackTraceString());
            validations.add('fail: '+e.getMessage());

            Utility_V1.removePendingApprovalProcess(loanId);
        }

        return validations;
    }

    @AuraEnabled
    public static List<String> recommendLoanApproval(String loanId, String approvalType, string selectedApprovalLevel, Boolean isFinalApproval){
        List<String> validations = new List<String>();

        try {
            List<Opportunity> loanData = [SELECT Id, Sanction_Loan_Amount__c, Product__c, Approval_Sub_Status__c, Approval_Status__c, Branch_Master__c, 
                                            Is_Top_Up__c, Parent_Loan_Application__c, Loan_Hierarchy__c, Approval_Type__c FROM Opportunity WHERE Id =: loanId 
                                            And Branch_Master__c != ''];
            
            if(!loanData.isEmpty()){
                boolean isError = false;
                List<Product2> mainProdList = new List<Product2>();
                List<Product2> subProdList = new List<Product2>();
                Map<string, List<Decimal>> subProdToValuesMap = new Map<string, List<Decimal>>();

                for(Product2 itrProd : [SELECT Id, Name, Sanctioned_Tenor__c, Product__r.Name, Product__r.Product__r.Name, RecordType.Name, Draft_PD_Note__c,
                                        Sanctioned_Loan_Amount__c, Sanctioned_ROI__c, Final_Loan_Amount__c
                                        FROM Product2 WHERE Loan_Application__c =: loanId Order By Product__r.Product_Type__c DESC]){
                    
                    if(itrProd.RecordType.Name == 'Product'){
                        mainProdList.add(itrProd);
                    }
                    else if(itrProd.RecordType.Name == 'Hybrid Tenure'){
                        string validationMsg = checkCollateralValidation(loanId, loanData[0].Loan_Hierarchy__c, itrProd.Name);
                        if(string.isNotBlank(validationMsg)){
                            validations.add(validationMsg);
                            isError = true;
                        }
                    }
                    else if(itrProd.RecordType.Name == 'Sub Product'){
                        subProdList.add(itrProd);

                        if((itrProd.Product__r.Name == 'Home Loan' || itrProd.Product__r.Name == 'Flexi Loan')){
                            if(subProdToValuesMap.containsKey(itrProd.Name)){
                                subProdToValuesMap.get(itrProd.Name).add(itrProd.Sanctioned_Tenor__c);
                            }
                            else{
                                subProdToValuesMap.put(itrProd.Name, new List<Decimal> {itrProd.Sanctioned_Tenor__c});
                            }
                        }
                    }
                    else if(itrProd.RecordType.Name == 'Full EMI' && (itrProd.Product__r.Product__r.Name == 'Home Loan' || itrProd.Product__r.Product__r.Name == 'Flexi Loan')){
                        if(subProdToValuesMap.containsKey(itrProd.Product__r.Name)){
                            subProdToValuesMap.get(itrProd.Product__r.Name).add(Decimal.valueOf(itrProd.Name));
                        }
                        else{
                            subProdToValuesMap.put(itrProd.Product__r.Name, new List<Decimal> {Decimal.valueOf(itrProd.Name)});
                        }
                    }
                }

                List<Application_Applicant__c> appList = [SELECT Id FROM Application_Applicant__c WHERE Loan_Application__c =: loanId And 
                                                            Applicant_Type__c IN ('Primary Applicant','Co Applicant','Guarantor','Beneficiary Owner','Financial Co-Applicant')];
                
                List<Bank_Details__c> repaymentAccounts = [SELECT Id FROM Bank_Details__c WHERE Application_Applicant__c IN : appList AND Is_Repayment_Account__c = true];
                
                if(repaymentAccounts.isEmpty()){
                    validations.add('Please add a repayment account to proceed further.');
                    isError = true;
                }

                for(SalesDocumentValidationChecklist.AddressWrapper wrapper : SalesDocumentValidationChecklist.checkAddressType(loanId)){
                    validations.add(wrapper.errorMsg);
                    isError = true;
                }

                for(Application_Deviation__c rec : [Select Id, Mitigants__c From Application_Deviation__c Where Loan_Application__c =: loanId And 
                                                    Approval_Status__c = 'Pending']){
                    if(rec.Mitigants__c == null){
                        validations.add('All Deviations should have Mitigant before submit.');
                        isError = true;
                        break;
                    }
                }

                if(isFinalApproval){
                    decimal sanctionAmount = 0;

                    for(Product2 rec : subProdList){
                        if(rec.Sanctioned_Loan_Amount__c == null){
                            validations.add('Sanction Loan Amount is required for '+ rec.Name);
                            isError = true;
                        }
                        else if(rec.Final_Loan_Amount__c < 0){
                            validations.add('Eligibility Amount should not be negative for '+ rec.Name);
                            isError = true;
                        }
                        else if(rec.Name != 'Flexi Loan'){
                            sanctionAmount += rec.Sanctioned_Loan_Amount__c;
                        }

                        if(rec.Sanctioned_ROI__c == null){
                            validations.add('Sanction ROI is required for '+ rec.Name);
                            isError = true;
                        }
                        if(rec.Sanctioned_Tenor__c == null){
                            validations.add('Sanction Tenor is required for '+ rec.Name);
                            isError = true;
                        }
                    }

                    for(string key : subProdToValuesMap.keySet()){
                        List<Decimal> values = subProdToValuesMap.get(key);
                        if(values.size() == 2 && values[0] != values[1]){
                            validations.add('The Sanctioned Tenor and Full EMI Tenor in Product table do not match for '+ key +'. Kindly enter the Sanctioned Tenor received from BRE into the full EMI Tenor in product table in order to proceed');
                            isError = true;
                        }
                    }

                    //skipping this validation for stand alone FL
                    if(loanData[0].Loan_Hierarchy__c != 'Child' && subProdList[0].Product__r.Name == 'Home Loan'){
                        decimal techValidationAmount = Decimal.valueOf(System.Label.TechValidationAmount);

                        if(loanData[0].Is_Top_Up__c == 'Yes' &&  loanData[0].Product__c != 'Flexi Loan'){
                            sanctionAmount += loanData[0].Parent_Loan_Amount__c;
                        }
                        system.debug('sanctionAmount: '+sanctionAmount);
                        
                        List<Technical_Evaluation__c> techEvalList = [Select Id From Technical_Evaluation__c Where HL_Loan_Application__c =: loanId 
                                                                        And HL_Stage__c = 'Accepted by Technical Manager'];

                        system.debug('techEvalList.size(): '+techEvalList.size());
                        
                        if(techEvalList.size() <2 && sanctionAmount > techValidationAmount){
                            validations.add('Please ensure that a minimum of two Technical Evaluation records are created for the loan application where the sanction amount is greater than '+ techValidationAmount +'.');
                            isError = true;
                        }
                        else if(techEvalList.size() <1){
                            validations.add('Atleast one Technical Evaluation is required.');
                            isError = true;
                        }

                        for(Application_Collateral__c rec : [SELECT Id, Name, Collateral__r.Market_Value__c, Collateral__r.Remarks__c FROM Application_Collateral__c 
                                                                WHERE HL_Loan_Application__c =: loanId]){
                            
                            if(rec.Collateral__r.Market_Value__c == null || rec.Collateral__r.Remarks__c == null){
                                validations.add('Valuation or Remarks missing for Collateral - '+ rec.Name);
                                isError = true;
                            }
                        }
                    }
                }

                if(isError){
                    return validations;
                }

                List<string> currentApproverLevelDetails = getCurrentApproverLevel(UserInfo.getUserId(), loanData[0].Branch_Master__c);
                String currentApproverLevelDisplay = currentApproverLevelDetails[1];

                Opportunity loan = new Opportunity(Id = loanId);
                loan.Approval_Status__c = 'Submitted';
                loan.Approval_Sub_Status__c = currentApproverLevelDisplay +' Submitted';
                loan.Sub_stage__c = 'Credit in-progress';
                loan.Credit_Submitter__c = UserInfo.getUserId();
                loan.IsApprovalAssignedToLevel__c = true;
                update loan;

                Set<String> receipientIds = new Set<String>();
                List<OpportunityTeamMember> otmList = new List<OpportunityTeamMember>();

                List<AccountTeamMember> atmUsers = [Select Id, UserId, Level__c From AccountTeamMember Where AccountId =: loanData[0].Branch_Master__c And 
                                                    Level__c =: selectedApprovalLevel And TeamMemberRole = 'Credit' And User.IsActive = true];

                for(AccountTeamMember atm : atmUsers){
                    if(String.isNotBlank(atm.Level__c) && (atm.Level__c!= 'L1' || atm.Level__c!= 'l1')){
                        receipientIds.add(atm.UserId);
                        OpportunityTeamMember otm = new OpportunityTeamMember();
                        otm.OpportunityId = loanId;
                        otm.UserId = atm.UserId;
                        otm.TeamMemberRole = 'Credit';
                        otm.OpportunityAccessLevel = 'Edit';
                        otmList.add(otm);
                    }
                }
                
                if(!otmList.isEmpty()){
                    upsert otmList;
                }

                sendActionNotification(loanId, 'Recommend', receipientIds, UserInfo.getName() +' - '+ currentApproverLevelDisplay, approvalType);

                validations.add('success');

                manageRecoNote(loanId, mainProdList, currentApproverLevelDisplay, 'Submitted', loanData[0].Approval_Type__c);
            }
        }
        catch (Exception e) {
            System.debug('Error in recommendLoanApproval ---'+ e.getStackTraceString());
            validations.add('fail: '+e.getMessage());
        }

        return validations;
    }

    @AuraEnabled
    public static void unHoldApplication(String loanId){
        try {
            List<Opportunity> loanData = [SELECT Id, Branch_Master__c, Approval_Type__c FROM Opportunity WHERE Id =: loanId And Branch_Master__c != ''];
            if(!loanData.isEmpty()){
                Opportunity opp = new Opportunity();
                opp.Id = loanId;
                opp.Approval_Status__c = 'In Progress';
                opp.Approval_Sub_Status__c = '';
                opp.Sub_stage__c = 'Credit in-progress';
                update opp;
                
                // List<TAT__c> tatRecordList = [SELECT Id, Activity__c FROM TAT__c WHERE Loan_Application__c =: loanId AND Activity__c = 'Hold'];
                // if(!tatRecordList.isEmpty()){
                //     for(TAT__c tat : [SELECT Id, Activity__c FROM TAT__c WHERE Loan_Application__c =: loanId AND Activity__c = 'Hold']){
                //         //tat.End_Timestamp__c = System.now();
                //         tatRecordList.add(tat);
                //     }
                //     upsert tatRecordList;
                // }

                List<string> currentApproverLevelDetails = getCurrentApproverLevel(UserInfo.getUserId(), loanData[0].Branch_Master__c);
                String currentApproverLevelDisplay = currentApproverLevelDetails[1];
                List<Product2> mainProdList = [SELECT Id, Draft_PD_Note__c FROM Product2 WHERE Loan_Application__c =: loanId And RecordType.Name = 'Product'];

                manageRecoNote(loanId, mainProdList, currentApproverLevelDisplay, 'Un Hold', loanData[0].Approval_Type__c);
            }
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string holdLoanApp(String loanId){
        String res;

        try {
            List<Opportunity> loanData = [SELECT Id, Branch_Master__c, StageName, Approval_Type__c FROM Opportunity WHERE Id =: loanId And Branch_Master__c != ''];
            if(!loanData.isEmpty()){
                List<string> currentApproverLevelDetails = getCurrentApproverLevel(UserInfo.getUserId(), loanData[0].Branch_Master__c);
                String currentApproverLevelDisplay = currentApproverLevelDetails[1];
                
                Opportunity opp = new Opportunity();
                opp.Id = loanId;
                opp.Approval_Sub_Status__c = currentApproverLevelDisplay +' Hold';
                opp.Approval_Status__c = 'Hold';
                opp.Sub_stage__c = 'Hold';
                update opp;

                TAT__c tatRecord = new TAT__c();
                tatRecord.Stage__c = loanData[0].StageName;
                tatRecord.Activity__c = 'Hold';
                tatRecord.Sub_Activity__c = 'Case is on hold';
                tatRecord.User_Name__c = UserInfo.getUserId();
                tatRecord.Timestamp__c = System.now();
                tatRecord.Loan_Application__c = loanId;
                // tatRecord.Code__c = 'C-014';
                insert tatRecord;

                List<Product2> mainProdList = [SELECT Id, Draft_PD_Note__c FROM Product2 WHERE Loan_Application__c =: loanId And RecordType.Name = 'Product'];

                manageRecoNote(loanId, mainProdList, currentApproverLevelDisplay, 'Hold', loanData[0].Approval_Type__c);
            }
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return res;
    }

    //added new check for deviation
    @AuraEnabled
    public static Boolean checkIfAllDeviationsApproved(Id loanId) {
        List<Application_Deviation__c> deviations = [SELECT Id, Mitigants__c FROM Application_Deviation__c WHERE Loan_Application__c =: loanId 
                                                        And Approval_Status__c = 'Pending'];
        //Auto-approve all deviations
        for(Application_Deviation__c dev : deviations) {
            if(dev.Mitigants__c != null){
                dev.Approval_Status__c = 'Approved';
            }
        }

        update deviations;
        return true;
    }

    @AuraEnabled
    public static Boolean checkUserAuthorisationForApprove(string loanId){
        Boolean result = false;

        List<Opportunity> opp = [Select Branch_Master__c, Sanction_Loan_Amount_Original__c, Resanction__c From Opportunity Where Id =: loanId And Branch_Master__c != ''];

        if(!opp.isEmpty()){
            Integer deviationHighestApp = 1;

            List<Product2> prod = [SELECT Id, Sanctioned_Loan_Amount__c, Sanctioned_ROI__c, Sanctioned_Tenor__c FROM Product2 Where Loan_Application__c =: loanId 
                                    AND RecordType.Name = 'Sub Product' Limit 1];
            
            for(Application_Deviation__c rec : [Select Approving_Authority__c From Application_Deviation__c Where Loan_Application__c =: loanId 
                                                And Approval_Status__c = 'Pending' And Approving_Authority__c != null Order By Approving_Authority__c Desc]){
                
                Integer level = Integer.valueOf(rec.Approving_Authority__c.replace('L', ''));
                deviationHighestApp = level > deviationHighestApp ? level : deviationHighestApp;
            }
            system.debug('deviationHighestApp: '+deviationHighestApp);

            List<AccountTeamMember> branchUsers;
            if(!opp[0].Resanction__c){
                branchUsers = [SELECT Id, Level__c FROM AccountTeamMember WHERE AccountId =: opp[0].Branch_Master__c And TeamMemberRole = 'Credit' AND 
                                UserId =: UserInfo.getUserId() AND Maximum_authority_loan_amount__c >=: prod[0].Sanctioned_Loan_Amount__c];
            }
            else {
                Decimal currentSanctionAmt = prod[0].Sanctioned_Loan_Amount__c;
                Decimal originalSanctionAmt = opp[0].Sanction_Loan_Amount_Original__c != null ? opp[0].Sanction_Loan_Amount_Original__c : currentSanctionAmt;

                if(currentSanctionAmt > originalSanctionAmt){
                    branchUsers = [SELECT Id, Level__c FROM AccountTeamMember WHERE AccountId =: opp[0].Branch_Master__c And TeamMemberRole = 'Credit' And 
                                    UserId =: UserInfo.getUserId() AND Maximum_authority_loan_amount__c >=: currentSanctionAmt];
                }
                else {
                    branchUsers = [SELECT Id, Level__c FROM AccountTeamMember WHERE AccountId =: opp[0].Branch_Master__c AND TeamMemberRole = 'Credit' And 
                                    UserId =: UserInfo.getUserId()];
                }
            }

            if(branchUsers != null && !branchUsers.isEmpty()){
                Integer level = Integer.valueOf(branchUsers[0].Level__c.replace('L', ''));
                if(level >= deviationHighestApp){
                    result = true;
                }
            }
        }

        return result;
    }

    private static List<String> getCurrentApproverLevel(String approverUserId, String branchId){
        List<String> level = new List<string>();
        level.add('No Level');
        level.add('No Level');

        for(AccountTeamMember atm : [SELECT Id, Level__c, Approving_Authority_FICO__c FROM AccountTeamMember WHERE AccountId =: branchId And 
                                        TeamMemberRole = 'Credit' And UserId =: approverUserId And Level__c != null Limit 1]){
            level.clear();
            level.add(atm.Level__c);
            level.add(atm.Approving_Authority_FICO__c);
        }

        system.debug('level: '+level);
        return level;
    }

    private static void sendActionNotification(String loanId, String action, Set<String> recepients, String actionPerson, String approvalType){
        
        List<Opportunity> loanData = [SELECT Id, Loan_Application_Number__c FROM Opportunity WHERE Id =: loanId];
        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'Loan_Approval_Notification' Limit 1];
        
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(loanId);
        String title;
        String body;

        if(action == 'Approve'){
            title = 'Loan Approved';
            body = 'Loan Application '+ loanData[0].Loan_Application_Number__c +' has been approved.';
        }else if(action == 'Reject'){
            title = 'Loan Rejected';
            body = 'Loan Application '+ loanData[0].Loan_Application_Number__c +' has been rejected.';
        }else if(action == 'Recommend'){
            title = 'Loan Submitted';
            body = 'Loan Application '+ loanData[0].Loan_Application_Number__c +' has been submitted to you by '+ actionPerson +'.';
        }
        
        if(title != null && body != null){
            notification.setTitle(title);
            notification.setBody(body);

            if(!recepients.isEmpty()){
                notification.send(recepients);
            }
        }
    }

    @AuraEnabled
    public static Map<string, string> getApprovalLevel(string loanId){
        Map<string, string> result = new Map<string, string>();

        List<Opportunity> opp = [Select Id, Branch_Master__c From Opportunity Where Id =: loanId And Branch_Master__c != ''];
        if(!opp.isEmpty()){
            for(AggregateResult ar : [Select Level__c From AccountTeamMember Where AccountId =: opp[0].Branch_Master__c And TeamMemberRole = 'Credit'
                                        And Level__c != '' And User.IsActive = true Group By Level__c Order By Level__c]){
                result.put(ar.get('Level__c').toString(), ar.get('Level__c').toString());
            }
        }
        return result;
    }

    @AuraEnabled
    public static string assignToMe(string loanId){
        List<Opportunity> opp = [Select Id, IsApprovalAssignedToLevel__c From Opportunity Where Id =: loanId];
        if(!opp[0].IsApprovalAssignedToLevel__c){
            return 'Someone has already taken this Loan Application.';
        }
        else{
            Utility.byPassOwnershipUpdate = true;
            opp[0].OwnerId = UserInfo.getUserId();
            opp[0].IsApprovalAssignedToLevel__c = false;
            opp[0].ByPassOwnerChangeValidation__c = true;
            update opp;

            OpportunityTriggerHandler.isTriggerDisabled = true;
            opp[0].ByPassOwnerChangeValidation__c = false;
            update opp;
            OpportunityTriggerHandler.isTriggerDisabled = false;
            Utility.byPassOwnershipUpdate = false;

            List<Application_Applicant__c> applicantList = [SELECT Id, OwnerId FROM Application_Applicant__c WHERE Loan_Application__c =: loanId];

            if(!applicantList.isEmpty()){
                for(Application_Applicant__c app : applicantList){
                    app.OwnerId = UserInfo.getUserId();
                }

                update applicantList;
            }
        }

        return 'Success';
    }

    @AuraEnabled
    public static List<string> checkPolicyLTV(string loanId){
        List<string> result = new List<string>();
        
        for(Product2 rec : [SELECT Id, HL_Final_LTVSanctioned_Terms__c, Product__r.Name, Product__r.HL_Maximum_LTV_as_per_Policy_1__c, 
                            Product__r.HL_Maximum_LTV_as_per_Policy_2__c, Product__r.HL_Maximum_LTV_as_per_Policy_3__c, Final_Loan_Amount__c
                            FROM Product2 WHERE Loan_Application__c =: loanId AND RecordType.Name = 'Sub Product' AND Product__r.RecordType.Name = 'Product'
                            And Final_Loan_Amount__c != null]){

            if(rec.Final_Loan_Amount__c < 3000000){
                if(rec.HL_Final_LTVSanctioned_Terms__c > rec.Product__r.HL_Maximum_LTV_as_per_Policy_1__c){
                    result.add(rec.Product__r.Name + ' - Final LTV ('+ rec.HL_Final_LTVSanctioned_Terms__c +') can not be more then '+ rec.Product__r.HL_Maximum_LTV_as_per_Policy_1__c);
                }
            }
            else if(rec.Final_Loan_Amount__c >= 3000000 && rec.Final_Loan_Amount__c < 7500000){
                if(rec.HL_Final_LTVSanctioned_Terms__c > rec.Product__r.HL_Maximum_LTV_as_per_Policy_2__c){
                    result.add(rec.Product__r.Name + ' - Final LTV ('+ rec.HL_Final_LTVSanctioned_Terms__c +') can not be more then '+ rec.Product__r.HL_Maximum_LTV_as_per_Policy_2__c);
                }
            }
            else {
                //Final_Loan_Amount__c >= 7500000 case
                if(rec.HL_Final_LTVSanctioned_Terms__c > rec.Product__r.HL_Maximum_LTV_as_per_Policy_3__c){
                    result.add(rec.Product__r.Name + ' - Final LTV ('+ rec.HL_Final_LTVSanctioned_Terms__c +') can not be more then '+ rec.Product__r.HL_Maximum_LTV_as_per_Policy_3__c);
                }
            }
        }

        if(result.isEmpty()){
            result.add('success');
        }

        return result;
    }

    public class ApprovalWrapper {
        @AuraEnabled public Boolean showApprovalButtons = false;
        @AuraEnabled public Boolean showApproveButton = false;
        @AuraEnabled public Boolean showHoldButton = false;
        @AuraEnabled public Boolean showUnholdButton = false;
        @AuraEnabled public Boolean showRecommendButton = false;
        @AuraEnabled public Boolean showRejectButton = false;
        @AuraEnabled public Boolean disableApproverLevel = false;
        @AuraEnabled public Boolean disableApprovalType = false;
        @AuraEnabled public Boolean isAssignedToUser = false;
        @AuraEnabled public String crApprovalType;
        @AuraEnabled public List<ProductWrapper> products;
    }

    public class StatusHistoryWrapper{
        @AuraEnabled public String status;
        @AuraEnabled public String remarks;
        @AuraEnabled public String user;
        @AuraEnabled public DateTime timeStamp;
        @AuraEnabled public String approvalType;
    }

    public class ProductWrapper{
        @AuraEnabled public String productId{get; set;}
        @AuraEnabled public String productName{get; set;}
        @AuraEnabled public String prodComment{get; set;}
        @AuraEnabled public List<StatusHistoryWrapper> statusHistory;
        @AuraEnabled public Boolean showApprovalHistory = false;
    }
    
    @AuraEnabled
    public static String performApproval(String loanId,String approvalType) {
        String res = 'fail';
        Opportunity loan= [SELECT Id,Sanction_Loan_Amount__c, Branch_Master__c, OwnerId, Name, Approval_Comments__c, Send_Back_Remarks__c,
                           StageName ,Negotiated_Loan_Amount__c,Final_Tenure__c,
                           Sanction_Tenure__c,Sanction_Rate_Of_Interest__c,Final_Amount__c,Final_Amount_in_Words__c,
                           Final_Rate_Of_Interest__c,Negotiated_Rate_Of_Interest__c,Resanction__c
                           FROM Opportunity WHERE Id = :loanId limit 1];
        String timestamp = Datetime.now().format('hh:mm:ss a , MMM dd, yyyy');
        String currentUserName = UserInfo.getName();
        String remarkEntry = '{ '+ timestamp + ' } { ' + currentUserName + ' } { Converted from Credit To PSV }';
        Boolean goToPsv = false;
        if(approvalType == 'Income Approval') {
            //loan.StageName = 'PSV';
        	loan.Sub_stage__c = 'Credit in-progress';
            remarkEntry = '{ '+ timestamp + ' } { ' + currentUserName + ' } { Converted from Credit Provess Verification to Credit in-progress }';
            if (loan.Send_Back_Remarks__c != null) {
            loan.Send_Back_Remarks__c = loan.Send_Back_Remarks__c + ' || { Mark as complete } ' + ' { Credit Provess Verification to Credit in-progress } ' + remarkEntry;
        } else {
            loan.Send_Back_Remarks__c =  '{ Mark as complete } ' + ' { Credit Provess Verification to Credit in-progress } ' + remarkEntry;
        }
        }else {
            goToPsv = true;
            loan.StageName = 'PSV';
        	loan.Sub_stage__c = 'PSV Sales';
            if (loan.Send_Back_Remarks__c != null) {
            loan.Send_Back_Remarks__c = loan.Send_Back_Remarks__c + ' || { Mark as complete } ' + ' { Credit Underwriting to PSV } ' + remarkEntry;
        } else {
            loan.Send_Back_Remarks__c =  '{ Mark as complete } ' + ' { Credit Underwriting to PSV } ' + remarkEntry;
        }
        }
        Decimal sanctionedAmount = loan.Sanction_Loan_Amount__c != null ? loan.Sanction_Loan_Amount__c : 0;
        Decimal sanctionedTenure = loan.Sanction_Tenure__c != null ? loan.Sanction_Tenure__c : 0;
        Decimal sanctionedROI = loan.Sanction_Rate_Of_Interest__c != null ? loan.Sanction_Rate_Of_Interest__c : 0;
        loan.Negotiated_Loan_Amount__c = sanctionedAmount;
        loan.Final_Amount__c = sanctionedAmount;
        Decimal decimalValue = (Decimal) loan.Final_Amount__c; 
        loan.Final_Amount_in_Words__c = Utility.getNumberTOWordConvertion(decimalValue);
        loan.Final_Tenure__c = sanctionedTenure;
        
            loan.Negotiated_Rate_Of_Interest__c = sanctionedROI;
        loan.Final_Rate_Of_Interest__c = loan.Negotiated_Rate_Of_Interest__c;
        if (loan.Resanction__c == true) {
            //loan.Resanction_Pop_up_Flag__c = true;
        }
        loan.Resanction__c = false;
        Trigger_Bypass_Setting__c setting = Trigger_Bypass_Setting__c.getInstance();
        setting.Opportunity_Trigger_Bypass__c = true;
        upsert setting;
        update loan;
        setting.Opportunity_Trigger_Bypass__c = false;
        upsert setting;
        List<Opportunity> oppListData= [SELECT Id, Approval_Comments__c FROM Opportunity WHERE Id= :loanId];
        if(String.isBlank(oppListData[0].Approval_Comments__c)) {
            oppListData[0].Approval_Comments__c = 'test';
        }
        List<String> splitData= oppListData[0].Approval_Comments__c.split('%%-');
        String remData;
        List<String> imgTags = new List<String>();
        Pattern p = Pattern.compile('<img[^>]*>' );
        Matcher m = p.matcher(oppListData[0].Approval_Comments__c);
        while (m.find()) {
            imgTags.add(m.group());
        }
        remData = String.join(imgTags, '<br/>');
        String commentData= splitData[splitData.size()-1].replace('&amp;&amp;-', '&&-');
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
                VersionData = Blob.valueOf(oldText +'%%-'+commentData)
            );
            insert cv;
        }else {
            
            ContentVersion cv = new ContentVersion(
                Title = 'Approval Comments',
                PathOnClient = 'LoanApprovalComments.txt',
                VersionData = Blob.valueOf(commentData)
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
                ContentDocumentId =contentDocId,
                LinkedEntityId = document.Id,
                ShareType = 'V'
            ); 
        }
        if(goToPsv){
            Loan_Transaction__c newTxn = new Loan_Transaction__c();
        newTxn.RecordTypeId = '012dN000003FlhmQAC';
        newTxn.Loan_Application__c = loanId;
        newTxn.Disbursement_Party__c = 'Customer';
        newTxn.Emi_due_frequency__c = '6th of the month';
        newTxn.Grace_Base_Rate_Code__c = 'GHFPLR';
        newTxn.Interest_Frequency__c = 'M';
        newTxn.Payment_Method__c = 'NACH';
        newTxn.Rate_Type__c = 'R';
        newTxn.Schedule_Method__c = 'EQUAL';
        newTxn.First_Disbursement_Amount__c = 40000000;
        newTxn.Total_Disbursed_Amount__c = 40000000;
        newTxn.Loan_Start_Date__c = Date.valueOf('2036-06-30');
        newTxn.Interest_Due_date__c = '03'; 
        insert newTxn;
        }
        
        Opportunity newLoan= new Opportunity(Id = loanId);
        newLoan.Approval_Comments__c= remData;
        Trigger_Bypass_Setting__c setting1 = Trigger_Bypass_Setting__c.getInstance();
        setting1.Opportunity_Trigger_Bypass__c = true;
        upsert setting1;
        update newLoan;
        setting1.Opportunity_Trigger_Bypass__c = false;
        upsert setting1;
        return 'success';
    }
}