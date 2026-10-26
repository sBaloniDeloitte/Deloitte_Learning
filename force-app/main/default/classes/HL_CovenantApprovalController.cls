public class HL_CovenantApprovalController {

	@AuraEnabled
    public static Map<Id, String> getCreditATMs(Id opportunityId) {
        System.debug('getCreditATMs called with Opp Id = ' + opportunityId);

        if (opportunityId == null) {
            throw new AuraHandledException('No Opportunity Id provided.');
        }

        Opportunity opp = [
            SELECT Id, Branch_Master__c 
            FROM Opportunity 
            WHERE Id = :opportunityId 
            LIMIT 1
        ];

        if (opp.Branch_Master__c == null) {
            throw new AuraHandledException('Opportunity has no Branch Master associated.');
        }

        List<AccountTeamMember> creditATMs = [
            SELECT Id, UserId, TeamMemberRole, User.Name
            FROM AccountTeamMember
            WHERE AccountId = :opp.Branch_Master__c
              AND TeamMemberRole = 'Credit'
              AND UserId != null
        ];

        if (creditATMs.isEmpty()) {
            throw new AuraHandledException('No Credit team members found on this Branch.');
        }

        Map<Id, String> assigneeMap = new Map<Id, String>();
        for (AccountTeamMember atm : creditATMs) {
            assigneeMap.put(atm.UserId, atm.User.Name);
        }

        return assigneeMap;
    }
    
	@AuraEnabled
	public static String sendForApproval(Id approver,Id opportunityId, List<Id> documentDetailsRecords, Boolean fromDocument, Boolean fromSanction) {
        System.debug('sendForApproval approver = ' + approver);
        System.debug('sendForApproval documentDetailsRecords = ' + documentDetailsRecords);
		String res = 'fail';
        try {
            if(approver != null){
                Id docId;
                if(fromDocument){
                    docId = createDocumentDetailsParent(approver, documentDetailsRecords);    
                }else if(fromSanction){
                    docId = createSanctionConditionParent(approver, documentDetailsRecords); 
                }
                System.debug('sendForApproval document Id = ' + docId);
                Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
                String comments = 'Please review  and approve the covenent documents.';
                request.setComments(comments);
                request.setObjectId(docId);
                request.setNextApproverIds(new Id[] { approver });
                Approval.process(request);sendCustomApprovalEmail(approver, docId, opportunityId, fromDocument, fromSanction);//updated Ayushi
                res = 'success';
            } else {
                res = 'No approvers found for the Covenent';
            }         
        } catch (Exception e) {
            res = e.getMessage();
        }
        return res;
	}

	@AuraEnabled
	public static Id createDocumentDetailsParent(Id approver, List<Id> documentDetailsRecords) {
        Document_Details__c docParent = new Document_Details__c(
                                        Name = 'Covenant Document Detail Parent', 
                                        Covenant_Approval_Status__c = 'Pending',
                                        Covenant_Approved_by__c = approver);
        insert docParent;
        
        List<Document_Details__c> docChildList = [SELECT Id, Covenant_Parent_ID__c
                        					FROM Document_Details__c 
                        					WHERE Id IN: documentDetailsRecords];
		if(docChildList.size() > 0){
			for(Document_Details__c doc: docChildList){
				doc.Covenant_Parent_ID__c = docParent.Id;
                doc.Covenant_Approval_Status__c='Submitted';
			}
            update docChildList;
		}
        return docParent.Id;
	}

    @AuraEnabled
	public static Id createSanctionConditionParent(Id approver, List<Id> documentDetailsRecords) {
        Sanction_Condition__c docParent = new Sanction_Condition__c(
                                        Sanction_Covenant_Approval_Status__c = 'Pending',
                                        HL_Covenant_Approved_by__c = approver);
        insert docParent;
        
        List<Sanction_Condition__c> docChildList = [SELECT Id, HL_Parent_For_Covenant_Sanction__c
                        					FROM Sanction_Condition__c 
                        					WHERE Id IN: documentDetailsRecords];
		if(docChildList.size() > 0){
			for(Sanction_Condition__c doc: docChildList){
				doc.HL_Parent_For_Covenant_Sanction__c = docParent.Id;
			}
            update docChildList;
		}
        return docParent.Id;
	}

    public Id parentRecordId { get; set; }
    public List<Document_Details__c> childDocList { get; set; }
    public Id parentSanctionRecordId { get; set; }
    public List<Sanction_Condition__c> childSanctionList { get; set; }

    public HL_CovenantApprovalController() { }

    public HL_CovenantApprovalController(ApexPages.StandardController sc) {
        parentRecordId = sc.getId();
    }

    public List<Document_Details__c> getChildDocList() {
        system.debug('IN getChildDocList' + childDocList + ' :::: '  + parentRecordId);
        if (childDocList == null) {
            childDocList = [
                SELECT Id, Name, Document_Type__c, Nature_of_Document__c,
                       Target_Date__c, Remarks__c
                FROM Document_Details__c
                WHERE Covenant_Parent_ID__c = :parentRecordId
            ];
        }
        system.debug('IN getChildDocList ::: final:: ' + childDocList);
        return childDocList;
    }

    public Integer getChildDocCount() {
        if (childDocList == null) {
            getChildDocList();
        }
        return (childDocList == null) ? 0 : childDocList.size();
    }

    public List<Sanction_Condition__c> getChildSanctionList() {
        system.debug('IN getChildSanctionList' + childSanctionList + ' :::: '  + parentSanctionRecordId);
        if (childSanctionList == null) {
            childSanctionList = [
                SELECT Id, Condition_Approval__c, Name, Document_Type__c, Condition_Name__c 
                FROM Sanction_Condition__c
                WHERE HL_Parent_For_Covenant_Sanction__c = :parentSanctionRecordId
            ];
        }
        system.debug('IN getChildSanctionList ::: final:: ' + childSanctionList);
        return childSanctionList;
    }

    public Integer getChildSanctionCount() {
        if (childSanctionList == null) {
            getChildSanctionList();
        }
        return (childSanctionList == null) ? 0 : childSanctionList.size();
    }

    //updated Ayushi
    public static void sendCustomApprovalEmail(Id approverId,Id parentRecordId,Id opportunityId,Boolean fromDocument,Boolean fromSanction) {
    User approver = [SELECT Id, Name, Email FROM User WHERE Id = :approverId LIMIT 1];
    Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
    List<Document_Details__c> docs = new List<Document_Details__c>();
    if (fromDocument) {
        docs = [SELECT Name, Document_Type__c, Nature_of_Document__c, Target_Date__c FROM Document_Details__c WHERE Covenant_Parent_ID__c = :parentRecordId];
    }
    //Document Table
    String tableHtml = '';
    tableHtml += '<table border="1" cellpadding="6" cellspacing="0" width="100%" ';
    tableHtml += 'style="border-collapse:collapse;font-family:Arial;font-size:13px;">';
    tableHtml += '<tr style="background-color:#f2f2f2;font-weight:bold;">';
    tableHtml += '<th>Document Name</th>';
    tableHtml += '<th>Document Type</th>';
    tableHtml += '<th>Nature</th>';
    tableHtml += '<th>Target Date</th>';
    tableHtml += '<th>Remarks</th>';
    tableHtml += '</tr>';

    for (Document_Details__c d : docs) {
        tableHtml += '<tr>';
        tableHtml += '<td>' + d.Name + '</td>';
        tableHtml += '<td>' + d.Document_Type__c + '</td>';
        tableHtml += '<td>' + d.Nature_of_Document__c + '</td>';
        tableHtml += '<td>' + d.Target_Date__c + '</td>';
        tableHtml += '<td>' + d.Remarks__c + '</td>';
        tableHtml += '</tr>';
    }
    tableHtml += '</table>';
    
    //Email Body
    String htmlBody = '';
    htmlBody += '<html><body style="font-family:Arial;">';
    htmlBody += '<p>Dear ' + approver.Name + ',</p>';

    htmlBody += '<p><b>Loan Application Number:</b> ' + opp.Name + '</p>';

    htmlBody += '<p>Requestor <b>' + UserInfo.getName() +
                '</b> has sent a CSD / PDD / Waiver approval request.</p>';

    htmlBody += '<h3>Document Details</h3>';
    htmlBody += tableHtml;

    htmlBody += '<h3 style="margin-top:25px;">Action Required</h3>';
    htmlBody += '<p>Reply to this email with <b>APPROVE</b> or <b>REJECT</b>.</p>';

    htmlBody += '<p style="font-size:12px;color:#999;">';
    htmlBody += 'This is a system generated email.</p>';

    htmlBody += '</body></html>';

    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(new String[] { approver.Email });
    mail.setSubject('Covenant Approval Request'+ + opp.Name);
    mail.setHtmlBody(htmlBody);

    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
}

    //end updated

}