/*
* Created By : Ishi Jain
* Created Date : 15/10/2024
* Purpose : Used to store constants
*/

public without sharing class Constants {
    
    PUBLIC STATIC FINAL STRING COMMA = ','; 
    
    public static final Integer STATUS_CODE_SUCCESS = 200;
    
    public static final Integer STATUS_CODE_PARTIAL_SUCCESS = 210;
    public static final String ERROR_MESSAGE_PARTIAL_SUCCESS = 'Partial success';
    
    public static final Integer STATUS_CODE_VALIDATION_ERROR = 220;
    
    public static final Integer STATUS_CODE_ALL_FAILURE = 230;
    public static final String ERROR_MESSAGE_ALL_FAILURE = 'All failure';

    public static final Integer STATUS_CODE_REQUIRED_FIELD_MISSING = 240;
    public static final String ERROR_REQUIRED_FIELD_MISSING = 'Required Field is missing';
    
    public static final Integer STATUS_CODE_NO_DEDUPE_FOUND = 260;
    public static final String ERROR_NO_DEDUPE_FOUND = 'No dedupe found';

    public static final Integer STATUS_CODE_DEDUPE_FOUND = 270;
    public static final String ERROR_DEDUPE_FOUND = 'Dedupe found';

    public static final Integer STATUS_CODE_PINCODE_SERVICEABILITY_NOT_FOUND = 280;
    public static final String ERROR_PINCODE_SERVICEABILITY_NOT_FOUND = 'Pin code serviceability not found';

    public static final Integer STATUS_CODE_PINCODE_NOT_FOUND = 290;
    public static final String ERROR_PINCODE_NOT_FOUND = 'Pin code not found';

    public static final Integer STATUS_CODE_ERROR = 300;

    public static final String ERROR_MESSGAE_LEAD_NUMBER = 'Lead number is required';
    public static final String ERROR_MESSGAE_NAME = 'Please enter name in correct format';
    public static final String ERROR_MESSGAE_MOBILE_NUMBER = 'Please enter mobile number in correct format';
    public static final String ERROR_MESSGAE_COMPANY_NAME = 'Company name is required';
    public static final String ERROR_MESSAGE_API_SOURCE = 'API source is required';
    public static final String ERROR_MESSAGE_API_ACTION = 'API action is required';
    public static final String ERROR_MESSAGE_LINK_RECORDID = 'Link record id is required';
    public static final String ERROR_MESSAGE_LINK_OBJECT_NAME = 'Link object name is required';
    public static final String ERROR_MESSGAE_PINCODE = 'Pincode is required';
    //public static final String ERROR_MESSAGE_BANK_MASTER_TYPE = 'Bank Master Type is required';
    public static final String ERROR_MESSAGE_CUSTOMER_TYPE = 'Customer type is required';
    public static final String ERROR_MESSAGE_EMAIL = 'Please enter email in correct format';
    public static final String ERROR_MESSAGE_COMPANY_NAME = 'Please enter company name in correct format';
    public static final String ERROR_MESSAGE_REQUEST_BODY = 'Request body is required';
    public static final String ERROR_MESSAGE_EXTERNALID = 'ExternalId is required';
    public static final String ERROR_MESSAGE_DOCTYPE = 'Document type is not correct';
    public static final string DOCUMENT_TYPE_TECHNICAL_REQUIRED = 'Technical';
    public static final string DOCUEMNT_TYPE_TECHNICAL_TYPE = 'Technical Documents';
    public static final string TECHNICAL_DOCUMENT_NAME = 'Technical Report';
    public static final string DOCUMENT_CHECKLIST_REQUIRED = 'Mandatory';
    public static final string DOCUMENT_CHECKLIST_OPTIONAL = 'Optional';
    public static final string TECHNICAL_MANAGER_PROFILE = 'Technical Manager';
    public static final string APPLICANT_TYPE_APPLICANT = 'Primary Applicant';
    public static final string APPLICANT_TYPE_CO_APPLICANT = 'Co-Applicant';
    
    public static final String METHOD_TYPE_GET  = 'GET';
    public static final String METHOD_TYPE_POST = 'POST';
    public static final String CONTENT_TYPE_JSON = 'application/json';

    public static final String STATUS_NEW = 'New';
    public static final String STATUS_CLOSED = 'Closed';
    public static final String STATUS_OPEN = 'Open';
    public static final String STATUS_UPLOADED = 'Uploaded';
    public static final String STATUS_PENDING = 'Pending';
    public static final string STATUS_CREATED = 'Created';
    public static final string STATUS_DUPLICATE = 'Duplicate';
    
    public static final string LEAD_GEN_OBJECT_NAME = 'User For Lead Generator';
    public static final string LEAD_OBJECT_NAME = 'Lead';
    public static final string TASK_OBJECT_NAME = 'Task';
    public static final string USER_OBJECT_NAME = 'User';
    public static final string LEAD_CLASS_5 = 'GenericLookUpController';
    public static final string KM = 'km';
    public static final string EDIT_ACCESS = 'Edit';
    public static final string READ_ACCESS = 'Read';
    public static final string ROW_CAUSE_MANUAL = 'Manual';

    public static final String CUSTOMER_TYPE_INDIVIDUAL = 'INDIVIDUAL';
    public static final String CUSTOMER_TYPE_NON_INDIVIDUAL = 'NON INDIVIDUAL';
    public static final String CATEGORY_CODE_RETAIL = 'RETAIL'; 
    public static final String CATEGORY_CODE_CORPORATE = 'CORP'; 
    //12/11
    public static final string FRAUD_CONTROL_UNIT = 'Application_Verification__c';
    public static final string FCU_CLASS_1 = 'FCUController';
    public static final string FCU_RECORD_TYPE_PARENT = 'FCU';
    public static final string FCU_RECORD_TYPE_DOCUMENT = 'Document';
    public static final string FCU_RECORD_TYPE_PROFILE = 'Profile';
    public static final string FCU_RECORD_TYPE_COLLATERAL = 'Collateral';
    public static final string FCU_RECORD_TYPE_LOCATION = 'Location';
    public static final string FCU_PROFILE_AREA_MANAGER = 'FCU Area Manager';
    public static final string FCU_PROFILE_AGENT = 'FCU Agent';
    public static final string FCU_PROFILE_SAMPLER = 'FCU Sampler';
    public static final string FCU_APPROVAL_APPROVED = 'Approved';
    public static final string FCU_Accepted = 'Accepted By Admin';
    public static final string FCU_APPROVAL_NOT_INITIATED = 'Pending';
    public static final string FCU_APPROVAL_INITIATED = 'Sent for Approval';
    public static final string FCU_APPROVAL_SENT_BACK = 'Sent Back';
    public static final string FCU_APPROVAL_REASSIGNED = 'Re-Assigned';
    public static final string FCU_APPROVAL_REJECTED = 'Rejected';
    public static final string FCU_APPROVAL_APPROVED1 = 'Approved 1';
    public static final String DOCUMENTCHECKLISTS_OBJECT_NAME = 'Document_Checklist__c';
    public static final string DOCUMENT_NOT_SAVE_ERROR = 'Error in uploading documents';
    public static final String CONTENT_VERSION_OBJECT_NAME = 'ContentVersion';
    public static final string FCU_NOTIFICATION_TITLE_3 = 'FCU reassigned.';
    public static final string FCU_NOTIFICATION_BODY_3 = '{#var1#} report for {#var2#} has been sent back to you by {#var3#}';
    public static final string FCU_NOTIFICATION = 'FCU_Notification';
    public static final string FCU_NOTIFICATION_TITLE_1 = 'New approval required.';
    public static final string FCU_NOTIFICATION_BODY_1 = '{#var1#} report for {#var2#} has been sent to you for approval by {#var3#}';
    public static final string FCU_NOTIFICATION_TITLE_2 = 'New FCU assigned.';
    public static final string FCU_NOTIFICATION_BODY_2 = '{#var1#} report for {#var2#} has been sent to you by {#var3#}';
    public static final string FCU_NOTIFICATION_TITLE_4 = 'FCU Updated.';
    public static final string FCU_NOTIFICATION_BODY_4 = '{#var1#} report for {#var2#} has been updated by {#var3#}';
    public static final string FCU_NOTIFICATION_BODY_temp = '{#var1#} report for {#var2#} has been assigned to you';

    public static final string FCU_NOTIFICATION_TITLE_5 = 'FCU Updated.';
    public static final string FCU_NOTIFICATION_BODY_5 = '{#var1#} report for {#var2#} has been updated with additional sampling and sent to you by {#var3#}';
    public static final string LEAD_NOTIFICATION_1 = 'Lead_Assigned_To_CCE';

    // Login Form
    public static final string LOAN_LOGIN_FORM_IDENTIFIER = 'Loan Application Login Form';
    public static final string LABEL_CONSTANT = 'label';
    public static final string VALUE_CONSTANT = 'value';
    public static final string FIELD_INVESTIGATION_OBJECT_NAME = 'Application_Verification__c';

    //FI
    public static final string FIELD_INVESTIGATION = 'Field Investigation';

    //Profiles
    public static final string SYSTEM_ADMINISTRATOR='System Administrator';
    public static final string PARTNER_COMMUNITY_USER='Partner Community User';
    
     //Loan Transaction 
    public static final string LOAN_TRANSACTION_API_NAME = 'Loan_Transaction__c';
	public static final string STEP_LOAN_RECORD_TYPE_DEVELOPER_NAME = 'Step_Loan_Details';
    public static final String PRIMARY_APPLICANT = 'Primary Applicant';
    public static final String CO_APPLICANT = 'Co Applicant';
    public static final String LEI_VALIDATION_PATTERN = '^[A-Za-z0-9 .><!@$%&#*()\\[\\]{}]*$';
    public static final String CUSTOMER_PROFILE_SENP = 'SENP';

    //Cross Sell
    public Static final String OFFERS_OBJECT_LABEL = 'Offers';

    public static final String FCU_VERIFICATION_SERVICE     = 'Godrej Capital-BL';
    public static final String FCU_WEBHOOK_PATH              = '/services/apexrest/FCU/status-webhook';

    public static final Set<String> RESUBMITTABLE_STATUSES = new Set<String>{ 'Hold', 'Rejected' };
    public static final Set<String> COMPLETED_STATUSES     = new Set<String>{ 'Screened', 'Sampled', 'Eyeballed' };

    public static final String SCREENING_STATUS_SCREENED  = 'Screened';
    public static final String SCREENING_STATUS_SAMPLED   = 'Added to sampling queue';
    public static final String SCREENING_STATUS_EYEBALLED = 'FCU Completed';
    public static final String SCREENING_STATUS_HOLD      = 'On Hold';
    public static final String SCREENING_STATUS_REJECTED  = 'Rejected';
    public static final String FCU_VERIFICATION_STATUS_BLANK  = '';


    public static final Map<String, Integer> MONTH_MAP = new Map<String, Integer>{
        'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4,
        'May' => 5, 'Jun' => 6, 'Jul' => 7, 'Aug' => 8,
        'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12
    };

        public static final String OrgWideFromAddressEmail = System.Label.Org_Wide_Address; //change by Kunal Bisht for Code analysis report
    public static final String LEGAL_OBJECT_NAME ='Legal__c';
    public static final String LOAN_APPLICATIONS_OBJECT ='Opportunity';
     public static final String CA_Degree_Check ='CA Degree Check';
    public static final string LEGAL_RECORD_TYPE_SEARCH_DEV = 'Legal_Search_Report';
    public static final string LEGAL_RECORD_TYPE_VETTING_DEV = 'Legal_Vetting_Report';
    public static final string LEGAL_RECORD_TYPE_SCRUTINY_DEV = 'Legal_Scrutiny_Report';
    public static final string LEGAL_RECORD_TYPE_SCRUTINY = 'Legal Scrutiny Report';
    public static final string LEGAL_RECORD_TYPE_SEARCH = 'Legal Search Report';
    public static final string LEGAL_RECORD_TYPE_VETTING = 'Legal Vetting Report';
    public static final string LEGAL_RECORD_TYPE_SCRUTINY_LIMITED = 'Legal Scrutiny Report Limited';
    public static final string LEGAL_STAGE_IN_PROGRESS = 'In progress';
    public static final string LEGAL_STAGE_ASSIGNED_TO_ADMIN =	'Assigned to Admin';
    public static final string LEGAL_INITIATED_STATUS = 'legalRecords';
    public static final string LEGAL_STAGE_SUCCESS = 'Success';
    public static final string LEGAL_PROFILE = 'External Legal';
    public static final string DOCUMENT_TYPE_LEGAL_UPLOADED = 'Legal Documents Uploaded';
    public static final string DOCUMENT_TYPE_LOAN_APPLICATION = 'Loan Application';
    public static final string LEGAL_NOT_INITIATED_STATUS = 'lsrlegalRecords not initiated';
    public static final string LEGAL_DOCUMENT_NAME_SEARCH = 'Search Receipt';
    public static final string LEGAL_RECORD_TYPE_SCRUTINY_WITH_TITLE_SEARCH_DEV = 'Legal_Scrutiny_Report_With_Title_Search';
	  public static final string LEGAL_RECORD_TYPE_SCRUTINY_WITH_TITLE_SEARCH = 'Legal Scrutiny Report With Title Search';
    public static final string LEGAL_NOC = 'NOC';
    public static final string LEGAL_YES = 'Yes';

    //legal errors
    public static final string LEGAL_ERROR_NO_MASTER_DOCUMENT = '• Upload Documents - Please upload all the mandatory documents';
    public static final string LEGAL_ERROR_VETTING = '• Please add vetting status and vetting remarks for the following documents:';
    public static final string LEGAL_ERROR_NO_DOCUMENT = '• Please add the list of documents which are to be collected for creating a mortgage.';
    public static final string LEGAL_ERROR_NO_NOC = '• Please add atleast one NOC document which are to be collected for creating mortgage.';

    //legal Mail
    public static final string LEGAL_MAIL_TEMPLATE_1 = 'Legal_Initiate';
    public static final string LEGAL_MAIL_TEMPLATE_2 = 'Legal_Initiate_Search';
    public static final string LEGAL_MAIL_FULL_NAME = '{!Legal__c.OwnerFullName}';
    public static final string LEGAL_MAIL_NAME = '{!Legal__c.Name}';
    public static final string LEGAL_MAIL_APPLICATION_NUMBER = '{!Legal__c.Loan_Application_Number__c}';
    public static final string LEGAL_MAIL_PRODUCT = '{!Legal__c.Product__c}';
    public static final string LEGAL_MAIL_RECORDTYPE = '{!Legal__c.RecordType}';
    public static final string LEGAL_MAIL_SF_LINK = '{legal link}';
    public static final string LEGAL_MAIL_SEARCH_YEAR = '{!Legal__c.Legal_Search_Report_Years__c}';
    public static final string LEGAL_MAIL_BORROWER = '{!Legal__c.Name_of_the_Borrower_Applicant__c}';
    public static final string LEGAL_MAIL_COLLATERAL_ADDRESS = '{!Legal__c.Collateral_Address__c}';
    public static final string LEGAL_MAIL_DOCUMENT_NAME = '{!Legal__c.Documents_Name__c}';
    public static final string LEGAL_MAIL_SUBJECT = 'New Legal Report Assigned.';
  	public static final string TECHNICAL_TYPE_EXTERNAL = 'External';

    public static final string DOCUMENT_TYPE_1 = 'pdf';
    public static final string DOCUMENT_TYPE_2 = 'PDF';
    public static final string DOCUMENT_TYPE_3 = 'jpg';
    public static final string DOCUMENT_TYPE_4 = 'png';
    public static final string DOCUMENT_TYPE_5 = 'jpeg';
    public static final string LEGAL_VENDOR_ACCESS_LIMITED = 'Limited Access';


    public static final string LEGAL_NOTIFICATION_TITLE = 'Legal Initiated';
    public static final string LEGAL_NOTIFICATION_BODY = ' is initiated to you.';
    public static final string DOCUMENT_TYPE_LEGAL_MASTER = 'Legal Documents Master';
    public static final string LEGAL_DOCUMENT_NAME_SCRUTINY = 'Legal Report';
    public static final string LEGAL_DOCUMENT_NAME_VETTING = 'Legal Report';
    public static final string DOCUEMNT_TYPE_LEGAL_SCRUTINY = 'Legal Scrutiny Document';
    public static final string DOCUMENT_TYPE_LEGAL_MORTGAGE = 'Legal Mortgage Document';
    public static final string DOCUMENT_TYPE_TECHNICAL_ADITIONAL = 'Additional Image ';

    public static final string DOCUMENT_CHECKLIST_URL = '/sfc/servlet.shepherd/document/download/';
}