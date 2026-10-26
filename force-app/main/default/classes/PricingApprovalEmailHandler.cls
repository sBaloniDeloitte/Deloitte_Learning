global class PricingApprovalEmailHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        String emailBody = email.plainTextBody != null ? email.plainTextBody.trim() : '';
        String subject = email.subject != null ? email.subject.toLowerCase().trim() : '';
        String replyBody = emailBody.split('-----Original Message-----')[0].trim();

        System.debug('Email Body: ' + emailBody);
        System.debug('Email Subject: ' + subject);
        System.debug('Reply Body: ' + replyBody);

        // Extract LA number (Opportunity Name)
        Pattern patternLoan = Pattern.compile('(LA-\\d+)');
        Matcher matcherLoan = patternLoan.matcher(emailBody);

        // Extract action (Approve/Reject)

        Pattern patternReply = Pattern.compile('^(\\w+)');
        Matcher matcherReply = patternReply.matcher(replyBody);

        String opportunityName = null;
        String extractedResponse = null;

        if (matcherLoan.find()) {
            opportunityName = matcherLoan.group(1).trim();
            System.debug('Extracted Opportunity Name: ' + opportunityName);
        }

        if (matcherReply.find()) {
            extractedResponse = matcherReply.group(1).trim().toLowerCase();
            System.debug('Extracted Response: ' + extractedResponse);
        }
        System.debug('opportunityName>>>'+opportunityName);

        if (opportunityName != null && extractedResponse != null) {
            List<Opportunity> oppList = [
                SELECT Id, Name, Pricing_Approval_Status__c 
                FROM Opportunity 
                WHERE Name = :opportunityName
            ];
            System.debug('oppList>>>'+oppList);

            if (!oppList.isEmpty() && (oppList[0].Pricing_Approval_Status__c != 'Approved' && oppList[0].Pricing_Approval_Status__c != 'Rejected')) {
                Opportunity opp = oppList[0];

                List<ProcessInstanceWorkitem> workItems = [
                    SELECT Id 
                    FROM ProcessInstanceWorkitem 
                    WHERE ProcessInstance.TargetObjectId = :opp.Id AND ProcessInstance.Status = 'Pending'
                ];

                List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
                //approve, approved, reject, rejected, ok, not ok
                String actionStatus = (extractedResponse == 'approved' || extractedResponse == 'approve' || extractedResponse == 'ok') ? 'Approve' : 
                                      (extractedResponse == 'rejected' || extractedResponse == 'reject' || extractedResponse == 'not') ?'Reject'
                                      :'';
                if(actionStatus != ''){
                for (ProcessInstanceWorkitem item : workItems) {
                    Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                    req.setWorkitemId(item.Id);
                    req.setAction(actionStatus);
                    req.setComments('Pricing Approval via Email');
                    requests.add(req);
                }

                if (!requests.isEmpty()) {
                    Approval.process(requests);
                }

                opp.Is_Pricing_Approval_Required__c = false;

                opp.Pricing_Approval_Status__c = (extractedResponse == 'approved' || extractedResponse == 'approve' || extractedResponse == 'ok')  ? 'Approved' :
                                                 (extractedResponse == 'rejected' || extractedResponse == 'reject' || extractedResponse == 'not ok')? 'Rejected': '';
                update opp;
            }
        }
        }

        result.success = true;
        return result;
    }
}