public class ReinstateLoanApplicationActionController {
    
    /*
	* @description :- We are using this method to update the stage of loan application record as "Sales login".
	* @param loanId :- Storing the id of loan application
	*/
    @AuraEnabled
    public static void updateLoanApplication(String loanId) {
        try {
            if(String.isNotBlank(loanId)) {
                List<Opportunity> oppList= [SELECT  Id, StageName FROM Opportunity WHERE Id= : loanId];
                Opportunity oppRec = new Opportunity();
                oppRec.Id = loanId;
                //oppRec.StageName = 'Sales login';
                oppRec.Approval_Status__c = 'In Progress';
                Update oppRec;
                
                TAT__c tatRecord = new TAT__c();
                tatRecord.Stage__c = 'Sales login';
                tatRecord.Activity__c = 'Stage Change';
                if(oppList[0].StageName == 'Sales login'){
                    tatRecord.Sub_Activity__c = 'Lead to Loan';
                }else if(oppList[0].StageName == 'Credit Underwriting'){
                    tatRecord.Sub_Activity__c = 'Sales Login to Credit Underwriting';
                }
                
                tatRecord.User_Name__c = UserInfo.getUserId();
                tatRecord.Timestamp__c = System.now();
                tatRecord.Loan_Application__c = loanId;
                insert tatRecord;
                
                //change by Kunal Bisht for TAT__c record creation after ReInstate - start
                TAT__c lastSubStageChangeTAT = [Select Id, Loan_Application__c, Loan_Application__r.Name, Stage__c, Activity__c, Sub_Activity__c, Timestamp__c, End_Timestamp__c from TAT__c where Loan_Application__c = :loanId and Activity__c ='Sub Stage Change' order by createddate desc limit 1];
                TAT__c newSubStageChangeTAT = new TAT__c();
                newSubStageChangeTAT.Stage__c = lastSubStageChangeTAT.Stage__c;
                newSubStageChangeTAT.Activity__c = lastSubStageChangeTAT.Activity__c;
                newSubStageChangeTAT.Sub_Activity__c = lastSubStageChangeTAT.Sub_Activity__c;
                newSubStageChangeTAT.Timestamp__c = lastSubStageChangeTAT.End_Timestamp__c;
                newSubStageChangeTAT.User_Name__c = UserInfo.getUserId();
                newSubStageChangeTAT.Loan_Application__c = lastSubStageChangeTAT.Loan_Application__c;
                insert newSubStageChangeTAT;
                //change by Kunal Bisht for TAT__c record creation after ReInstate - end

                List<TAT__c> existingTatRecords= [SELECT Id, End_Timestamp__c, Activity__c FROM TAT__c WHERE Loan_Application__c = :loanId AND End_Timestamp__c = null AND (Activity__c = 'Hard Rejection' OR Activity__c = 'Soft Rejection')];
                for(TAT__c tat: existingTatRecords){
                    tat.End_Timestamp__c = System.now();
                }
                update existingTatRecords;
            }
        } catch(Exception e) {
            System.debug('e.getMessage()  :-  '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /*
	* @description :- We are using this method to sending mail to loan application owner.
	* @param loanId :- Storing the id of loan application
	*/
    @AuraEnabled
    public static void notifyLoanOwnerToReinstate(String loanId) {
        List<Opportunity> oppRecords = [SELECT Id, Name, Owner.Email, Owner.Name 
                                        FROM Opportunity 
                                        WHERE Id =: loanId];
        
        if(!oppRecords.isEmpty()) {
            Map<String,String> inputMap = new Map<String,String>();
            String opportunityDetailUrl = System.Url.getOrgDomainUrl().toExternalForm().replace('my.salesforce.com', 'lightning.force.com');
            opportunityDetailUrl += '/lightning/r/Opportunity/' + oppRecords.get(0).Id + '/view';
            /*String emailBody = 'Dear ' + oppRecords.get(0).Owner.Name + ',\n\n'
                + 'loan application number ' + oppRecords.get(0).Name + ' is successfully reinstated. Kindly click on the link below to navigate.\n\n'
                + opportunityDetailUrl+ '\n\n' +
                'Thanks and Regards,'+ '\n' +
                'Godrej Capital';*/
            
            EmailTemplate emailTemplate =[SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Reinstate_Loan_Application' LIMIT 1];
            String emailBody =  emailTemplate.HtmlValue;
            emailBody = emailBody.replace('{receiverName}', oppRecords.get(0).Owner.Name);
            emailBody = emailBody.replace('{loanNumber}', oppRecords.get(0).Name);
            emailBody = emailBody.replace('{loanLink}', opportunityDetailUrl);
            inputMap.put('content',emailBody) ;
            inputMap.put('subject','Loan application successfully reinstated') ;
            //inputMap.put('email', 'ijain4@deloitte.com');//oppRecords.get(0).Owner.Email) ;
            inputMap.put('email', oppRecords.get(0).Owner.Email) ;
            inputMap.put('loanId',oppRecords.get(0).Id) ;
            inputMap.put('processName','Email');
            EmailController.initiateAPIRequest(inputMap);
        }
    }
}