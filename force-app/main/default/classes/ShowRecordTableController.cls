/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-10-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ShowRecordTableController {
    //getting record list for datatable    
    @AuraEnabled
    public static TableWrapper getRecordList(String recordId, String processName, string filter){
        
        TableWrapper tw = new TableWrapper();
        string baseURL = URL.getOrgDomainURL().toExternalForm() +'/';

        switch on processName {

            when 'Linked Lead' {
                string mobileNo = [SELECT MobilePhone FROM Lead WHERE Id =: recordId LIMIT 1].MobilePhone;
                
                if(string.isNotBlank(mobileNo)) {

                    //adding header columns details
                    tw.headerColumns = new List<HeaderColumn>();
                    tw.headerColumns.add(createHeaderColumn(1, 'Sr. No.', 'width: 13%; text-align: center;', false));
                    tw.headerColumns.add(createHeaderColumn(2, 'Lead Number', 'text-align: center;', false));
                    tw.headerColumns.add(createHeaderColumn(3, 'Product', 'width: 25%; text-align: center;', false));
                    tw.headerColumns.add(createHeaderColumn(4, 'Channel', 'width: 22%; text-align: center;', false));
                    tw.headerColumns.add(createHeaderColumn(5, 'Status', 'width: 16%; text-align: center;', false));

                    tw.recordList = new List<RecordWrapper>();
                    integer counter = 1;

                    string sQuery = 'SELECT Lead_Number__c, Product__c, Channel__c, Status '+
                                    'FROM Lead WHERE MobilePhone =: mobileNo And Id !=: recordId '+ filter;

                    for(Lead rec : Database.query(sQuery)){

                        RecordWrapper rw = new RecordWrapper();
                        rw.id = rec.Id;
                        
                        //adding record columns details
                        rw.recordColumns = new List<RecordColumn>();
                        rw.recordColumns.add(createRecordColumn(1, 'text', '', counter.toString(), '', 'text-align: center;', false, false));
                        rw.recordColumns.add(createRecordColumn(2, 'text', '', rec.Lead_Number__c, '', 'text-align: center;', false, false));
                        rw.recordColumns.add(createRecordColumn(3, 'text', '', rec.Product__c, '', 'text-align: center;', false, false));
                        rw.recordColumns.add(createRecordColumn(4, 'text', '', rec.Channel__c, '', 'text-align: center;', false, false));
                        rw.recordColumns.add(createRecordColumn(5, 'text', '', rec.Status, '', 'text-align: center;', false, false));

                        tw.recordList.add(rw);
                        counter++;
                    }
                }
            }
            when 'Initiated FI' {

                //adding header columns details
                tw.headerColumns = new List<HeaderColumn>();
                tw.headerColumns.add(createHeaderColumn(1, 'Sr. No.', 'width: 2%; text-align: center;', false));
                tw.headerColumns.add(createHeaderColumn(2, 'Visit Number', 'width: 10%; text-align: center;', false));
                tw.headerColumns.add(createHeaderColumn(3, 'Status', 'width: 12%; text-align: center;', false));
                tw.headerColumns.add(createHeaderColumn(4, 'Report Status', 'width: 6%; text-align: center;', false));
                tw.headerColumns.add(createHeaderColumn(5, 'Visit Type', 'width: 12%; text-align: center;', false));
                tw.headerColumns.add(createHeaderColumn(6, 'Applicant Name', 'width: 12%; text-align: center;', false));
                tw.headerColumns.add(createHeaderColumn(7, 'Assignee', 'width: 12%; text-align: center;', false));
                tw.headerColumns.add(createHeaderColumn(8, 'Credit Managers Disposition', 'width: 6%; text-align: center;', false));
                tw.headerColumns.add(createHeaderColumn(9, 'Credit Managers Remarks', 'width: 12%; text-align: center;', false));
                tw.headerColumns.add(createHeaderColumn(10, 'Initiated Date', 'width: 8%; text-align: center;', false));
                tw.headerColumns.add(createHeaderColumn(11, 'Closed Date', 'width: 8%; text-align: center;', false));

                tw.recordList = new List<RecordWrapper>();
                integer counter = 1;

                string sQuery = 'SELECT Id, OverAll_Status__c, Assigned_To_User__r.Name, Applicant__r.Name, RecordType.Name, Name, Stage__c, '+
                                'CreatedDate, Applicant__r.Applicant_Type__c, Credit_Managers_Disposition__c, Credit_Manager_s_Remarks__c, Completion_Date__c '+
                                'FROM Application_Verification__c WHERE Loan_Application__c =: recordId AND (RecordType.Name = \'Business Verification\' OR RecordType.Name = \'Residence Verification\' OR RecordType.Name = \'Collateral Verification\'  ) '+ filter +' ORDER BY CreatedDate DESC';

                for(Application_Verification__c rec : Database.query(sQuery)){

                    RecordWrapper rw = new RecordWrapper();
                    rw.id = rec.Id;

                    switch on rec.Stage__c {

                        // when 'Approved 2' {
                        //     rw.styleTr = 'background-color: cornsilk;';
                        // }
                        when 'Approved by CM' {
                            rw.styleTr = 'background-color: cornsilk;';
                        }
                        when 'Waived' {
                            rw.styleTr = 'color: red;';
                        }
                    }

                    string applicantType = rec.Applicant__c!=null ? ' ('+ rec.Applicant__r.Applicant_Type__c +')' : ' (NA)';
                    
                    //adding record columns details
                    rw.recordColumns = new List<RecordColumn>();
                    rw.recordColumns.add(createRecordColumn(1, 'text', '', counter.toString(), '', 'text-align: center;', false, false));
                    rw.recordColumns.add(createRecordColumn(2, 'link', '', rec.Name, (baseURL + rec.Id), 'text-align: center;', false, false));
                    rw.recordColumns.add(createRecordColumn(3, 'text', '', rec.Stage__c, '', 'text-align: center;', false, false));
                    rw.recordColumns.add(createRecordColumn(4, 'text', '', rec.OverAll_Status__c, '', 'text-align: center;', false, false));
                    rw.recordColumns.add(createRecordColumn(5, 'text', '', rec.RecordType.Name, '', 'text-align: center;', false, false));
                    rw.recordColumns.add(createRecordColumn(6, 'text', rec.Applicant__c!=null ? rec.Applicant__r.Name : 'Not Applicable', applicantType, '', 'text-align: center;', false, false));
                    rw.recordColumns.add(createRecordColumn(7, 'text', '', rec.Assigned_To_User__r.Name, '', 'text-align: center;', false, false));
                    rw.recordColumns.add(createRecordColumn(8, 'text', '', rec.Credit_Managers_Disposition__c, '', 'text-align: center;', false, false));
                    rw.recordColumns.add(createRecordColumn(9, 'text', '', rec.Credit_Manager_s_Remarks__c, '', 'text-align: center;', false, false));
                    rw.recordColumns.add(createRecordColumn(10, 'text', '', rec.CreatedDate.format('dd/MM/yy HH:mm:ss'), '', 'text-align: center;', false, false));
                    rw.recordColumns.add(createRecordColumn(11, 'text', '', rec.Completion_Date__c != null?rec.Completion_Date__c.format('dd/MM/yy HH:mm:ss'):'-', '', 'text-align: center;', false, false));
        
                    tw.recordList.add(rw);
                    counter++;
                }
            }
            when 'Branch Users' {
                
                //adding header columns details
                tw.headerColumns = new List<HeaderColumn>();
                tw.headerColumns.add(createHeaderColumn(1, '', 'width: 3%; text-align: center;', false));
                tw.headerColumns.add(createHeaderColumn(2, 'Name', 'text-align: left;', false));
                tw.headerColumns.add(createHeaderColumn(3, 'Designation', 'width: 28%; text-align: center;', false));
                tw.headerColumns.add(createHeaderColumn(4, 'Mobile No', 'width: 20%; text-align: center;', false));

                tw.recordList = new List<RecordWrapper>();

                string sQuery = 'Select User.Name,UserId ,User.Employee_ID__c, User.MobilePhone, TeamMemberRole  '+
                                'From AccountTeamMember  where Account.Id =: recordId And UserId != null '+ filter +' Order By TeamMemberRole, User.Name';

                for(AccountTeamMember rec : Database.query(sQuery)){

                    RecordWrapper rw = new RecordWrapper();
                    rw.id = rec.UserId ;

                    string empId = string.isNotBlank(rec.User.Employee_ID__c) ? ' ('+ rec.User.Employee_ID__c +')' : '';
                    
                    //adding record columns details
                    rw.recordColumns = new List<RecordColumn>();
                    rw.recordColumns.add(createRecordColumn(1, 'radio', '', '', '', 'text-align: center;', false, false));
                    rw.recordColumns.add(createRecordColumn(2, 'text', rec.User.Name, empId, '', 'text-align: left;', false, false));
                    rw.recordColumns.add(createRecordColumn(3, 'text', '', rec.TeamMemberRole, '', 'text-align: center;', false, false));
                    rw.recordColumns.add(createRecordColumn(4, 'text', '', rec.User.MobilePhone, '', 'text-align: center;', false, false));

                    tw.recordList.add(rw);
                }
            }
            when 'Existing Customers'{
                string custId = [SELECT Customer__r.Customer_LMS_Id__c FROM Lead WHERE Id =: recordId LIMIT 1].Customer__r.Customer_LMS_Id__c;
                if((string.isNotBlank(custId))) {
                    tw.headerColumns = new List<HeaderColumn>();
                    tw.headerColumns.add(createHeaderColumn(1, 'UCIC Number', 'width: 25%; text-align: center;', false));
                    tw.headerColumns.add(createHeaderColumn(2, 'Name','width: 25%;text-align: center;', false));
                    tw.headerColumns.add(createHeaderColumn(3, 'Mobile Number', 'width: 25%; text-align: center;', false));
                    tw.headerColumns.add(createHeaderColumn(4, 'DOB/DOI', 'width: 25%; text-align: center;', false));
                    tw.recordList = new List<RecordWrapper>();

                    string sQuery = 'SELECT Id,Name,Customer_LMS_Id__c,Date_of_Birth__c,Mobile_Number__c From Account WHERE Customer_LMS_Id__c =:custId';
                    for(Account rec : Database.query(sQuery)){
                        RecordWrapper rw = new RecordWrapper();
                        rw.id = rec.Id;
                        //adding record columns details
                        rw.recordColumns = new List<RecordColumn>();
                        rw.recordColumns.add(createRecordColumn(1, 'text', '', custId, '', 'text-align: center;', false, false));
                        rw.recordColumns.add(createRecordColumn(2, 'text', '', rec.Name, '', 'text-align: center;', false, false));
                        rw.recordColumns.add(createRecordColumn(3, 'text', '', rec.Mobile_Number__c, '', 'text-align: center;', false, false));
                        rw.recordColumns.add(createRecordColumn(4, 'text', '', String.valueOf(rec.Date_of_Birth__c), '', 'text-align: center;', false, false)); 
                        tw.recordList.add(rw);
                }
            }
        }
    }
    return tw;
}
    //getting column headers and format for table headers
        private static HeaderColumn createHeaderColumn(integer srNo, string title, string styleTh, boolean showCheckbox){
            HeaderColumn hc = new HeaderColumn();
            hc.srNo = srNo;
            hc.title = title;
            hc.styleTh = styleTh;
            hc.showCheckbox = showCheckbox;
            return hc;
        }
    //getting the type of columns and links as needed in the table dynamically
        private static RecordColumn createRecordColumn(integer srNo, string colType, string valueInBold, string value, string linkURL, string styleTd, boolean isDisabled, boolean isChecked){
            RecordColumn rc = new RecordColumn(colType, valueInBold);
            rc.srNo = srNo;
            rc.colType = colType;
            rc.valueInBold = valueInBold;
            rc.value = value;
            rc.linkURL = linkURL;
            rc.styleTd = styleTd;
            rc.isDisabled = isDisabled;
            rc.isChecked = isChecked;
            return rc;
        }
    
        public class HeaderColumn {
            @AuraEnabled public Integer srNo;
            @AuraEnabled public String title;
            @AuraEnabled public String styleTh;
    
            @AuraEnabled public boolean showCheckbox;
        }
    
        public class RecordColumn {
            @AuraEnabled public Integer srNo;
            @AuraEnabled public String valueInBold;
            @AuraEnabled public String value;
            @AuraEnabled public String colType;
            @AuraEnabled public string linkURL;
            @AuraEnabled public String styleTd;
            @AuraEnabled public boolean isDisabled;
            @AuraEnabled public boolean isChecked;
    
            @AuraEnabled public boolean showLink;
            @AuraEnabled public boolean showCheckbox;
            @AuraEnabled public boolean showRadio;
            @AuraEnabled public boolean showBoldValue;
    
            //setting default values in constructor
            //type of record needed for the table
    
            RecordColumn(string colType, string valueInBold){
    
                showLink = false;
                showCheckbox = false;
                showRadio = false;
                showBoldValue = false;
    
                switch on colType {
                    when 'link' {
                        showLink = true;
                    }
                    when 'checkbox' {
                        showCheckbox = true;
                    }
                    when 'radio' {
                        showRadio = true;
                    }
                }
    
                if(string.isNotBlank(valueInBold)){
                    showBoldValue = true;
                }
            }
        }
    
        public class TableWrapper {
            @AuraEnabled public List<HeaderColumn> headerColumns;
            @AuraEnabled public List<RecordWrapper> recordList;
        }
    
        public class RecordWrapper {
            @AuraEnabled public String id;
            @AuraEnabled public String styleTr;
            @AuraEnabled public List<RecordColumn> recordColumns;
        }
    }