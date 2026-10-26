@isTest
public class LeadTestDataFactory {
            Public static List<Charges_Insurance__c> createTestRecords(Integer count) {
        List<Charges_Insurance__c> records = new List<Charges_Insurance__c>();
        Opportunity opp = LeadTestDataFactory.createLoanApplicationRecord('New', 'Home Loan');
        insert opp;
        for (Integer i = 0; i < count; i++) {
            records.add(new Charges_Insurance__c(
                Name = 'Test Charge ' + i,
                Pincode__c = '712235',
                Loan_Application__c = opp.Id
            ));
        }
        return records;
    }
    public static List<Lead> getTestLeadData(Integer numberOfRecs,Boolean isInsert) {
        List<Lead> records = new List<Lead>();
        for(Integer i=1;i<= numberOfRecs;i++){
            Lead rec = new Lead();
            rec.FirstName = 'John';
            rec.LastName = 'Doe';
            rec.Company = 'ABC Corp';
            rec.MobilePhone = '999999999'+i;
            rec.Status = 'Open';
            rec.Customer_Type__c = 'Individual';
            rec.Product__c = 'Affordable Home Loan';
            rec.Pan__c = 'ABCDE1'+i+'34F';
            records.add(rec);   
        }
        if(isInsert){
            insert records;
        }
        return records;   
    }
    public static void setupTriggerSettings() {
        if (Trigger_Settings__c.getInstance('Trigger Settings') == null) {
            Trigger_Settings__c settings = new Trigger_Settings__c(
                Name = 'Trigger Settings',
                Lead_Trigger__c = true ,
                Opportunity_Trigger__c = true
            );
            insert settings;
        }
    }
    
    public static Lead createLeadRecord(String firstName, String middleName, String lastName, String mobileNumber, String company, String custType, String channel) {
        Lead testLead = new Lead();
        testLead.FirstName = firstName;
        testLead.MiddleName = middleName;
        testLead.LastName = lastName;
        testLead.MobilePhone = mobileNumber;
        testLead.Company = company;
        testLead.Customer_Type__c = custType;
        testLead.Status = 'Open';
        testLead.Remarks_History__c = 'Initial Remark';
        
        
        
        testLead.Channel__c = channel != null ? channel : 'Direct'; 
        
        return testLead;
    }
    
    public static void insertLeadRecords(Integer recordCount) {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < recordCount; i++) {
            leads.add(createLeadRecord(
                'First' + i,
                'Middle' + i,
                'Last' + i,
                '123456789' + i,
                'Company' + i,
                'Individual',
                'Direct' 
            ));
        }
        insert leads;
    }
    
    public static Opportunity createLoanApplicationRecord(String status, String Product){
        
        Opportunity opp = new Opportunity(Status__c = status,Product__c = Product, Name = 'Test Loan',
            StageName = 'Prospecting',CloseDate=Date.today().addDays(10)
            );
        //insert opp;
        return opp;  
    }
    
    public static Application_Applicant__c createApplicationApplicant(String Applicant_Type,String Loan_Application){
        Application_Applicant__c app = new Application_Applicant__c(Applicant_Type__c = Applicant_Type,Loan_Application__c = Loan_Application);
        return app;
    }
    
    
    public static Application_Verification__c createApplicationVerification(String applicantId,String Loan_ApplicationId,String Credit_Manager_Remark,String Waiver_Remark,String Admin_s_Remark,String Any_Remarks_Reasons){
        return  new Application_Verification__c(Loan_Application__c = Loan_ApplicationId, 
                                                Applicant__c = applicantId,
                                                Credit_Manager_s_Remarks__c = Credit_Manager_Remark,
                                                Waiver_Remark__c = Waiver_Remark,
                                                Admin_s_Remarks__c = Admin_s_Remark,
                                                Any_Remarks_Reasons__c = Any_Remarks_Reasons);
        
    }
    
    
    public static Document_Details__c createDocumentDetails(String ApplicVeriId){
        
        return  new Document_Details__c(
            Application_Verification__c = ApplicVeriId,
            Name = 'Test',
            Is_Required__c = True,
            Location__Latitude__s = 20.2,
            Location__Longitude__s = 23.1
        );
    }
    
    public static Document_Master__c createDocumentMaster(String Name){
        
        return  new Document_Master__c(Name = Name,
                                       Requirement_At__c = 'Applicant Level',
                                       Document_Category__c = 'Business Proof',
                                       Document_Name__c = 'Report',
                                       Is_Required__c = true
                                      );
    }
    
}