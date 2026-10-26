/*
* Author    :   Deloitte Inida
* Purpose   :   Loan application form
* @last modified on  : 1/6/25
* @last modified by  : Deloitte India
*/

public with sharing class FCULAController {
    private Id recordId;
    public List<Application_Applicant__c> applicants { get; set; }
    public List<ApplicantWrapper> applicantWrappers { get; set; }
    public List<ApplicantWrapper> applicantWrappersMorethenFive { get; set; }
    public String loanType{get;set;}
    public String loanPurpose{get;set;}
    public String loanfacilitytype{get;set;}
    public String PSL{get;set;}
    public String URN{get;set;}
    public Date loandate{get;set;}
    public Decimal loanAmount{get;set;}
    public String loanAmountInwords{get;set;}
    public Decimal loantenure{get;set;}
    public string applicanttype {get;set;}
    public boolean ind {get;set;}
    public date dob{get;set;}
    public string salutation{get;set;}
    //public string firstname{get;set;}
    // public string middlename{get;set;}
    // public string lastname{get;set;}
    // public string relegion{get;set;}
    // public string castt{get;set;}
    public string gender{get;set;}
    // public string mothersname{get;set;}
    // public string fathersname{get;set;}
    public string nationality{get;set;}
    public string status{get;set;}
    public string spouse{get;set;}
    public string pan{get;set;}
    public string DL{get;set;}
    public string qualification{get;set;}
    public string segment{get;set;}
    // public string subsegment{get;set;}
    // public Decimal currentworkexp{get;set;}
    // public Decimal totalworkexp{get;set;}
    public string refname1{get;set;}
    public string refphone1{get;set;}
    public string refadd1{get;set;}
    public string refname2{get;set;}
    public string refphone2{get;set;}
    public string refadd2{get;set;}
    public string citizenship{get;set;}
    public string phone {get;set;}
    // public date dlvalid {get;set;}
    // public date panvalid {get;set;}
    public List<Charges_Insurance_Master__c> chargesList { get; set; }
    public List<Income_Expense_Obligation__c> obligationList {get; set;}
    public List<Terms_Conditions_Loan_Acknowledgement__mdt> termsAndConditionsList { get; set; }
    public String areamanager { get; set; }
    public String branchname { get; set; }
    public String channel { get; set; }
    public String branchcode { get; set; }
    public String productcode { get; set; }
    public String natureofbusiness { get; set; }
    // public String ContentDocumentId { get; set; }
    public Integer monthlyObligation { get; set; }
    public Map<String, String> applicantpoaMap { get; set; }
    public Map<String, String> applicantpoaNumberMap { get; set; }
    public Map<String, String> applicantpoaValidMap { get; set; }
    public Map<String, String> chargesMap  { get; set; }
    public Boolean hasCoApplicant { get; set; }
    public Boolean isApplicantIndividual{get;set;}
    public List<Applicant_Address__c> applicantAddresses{ get; set; }
    
    public class ApplicantWrapper {
        public Application_Applicant__c applicant { get; set; }
        public String documentId { get; set; }
        
        public ApplicantWrapper(Application_Applicant__c app, String docId) {
            this.applicant = app;
            this.documentId = docId;
        }
    }
    public FCULAController(ApexPages.StandardController controller){
        this();
    }
    public FCULAController() {
        try {
            this.recordId = ApexPages.currentPage().getParameters().get('Id');
            System.debug('this.recordId -->'+this.recordId);
            string loanid ;
            String sObjName = recordId.getSObjectType().getDescribe().getName();
            Map<String, String> chargesMap1 = new Map<String, String>();
            chargesList = [SELECT Id , Name , Default_Text_Value__c ,Charges_Fee_Type__c , Loan_Application__c FROM Charges_Insurance_Master__c where Loan_Application__c = true ];
            for (Charges_Insurance_Master__c charge : chargesList) {
                
                chargesMap1.put(charge.Charges_Fee_Type__c, charge.Default_Text_Value__c);
            }
            this.chargesMap = chargesMap1;
            termsAndConditionsList = [SELECT Id, Sr_No__c, Terms__c FROM Terms_Conditions_Loan_Acknowledgement__mdt ORDER BY Sr_No__c ];
            if(sObjName == 'Application_Verification__c'){
                Application_Verification__c fc = [Select Id,Name,Loan_Application__c from Application_Verification__c where Id =: this.recordId limit 1];
                this.recordId = fc.Loan_Application__c;
            }
            obligationList = [SELECT Id, Imputed_EMI__c 
                              FROM Income_Expense_Obligation__c 
                              WHERE Loan_Application__c = :recordId];
            
            monthlyObligation = 0;
            if (!obligationList.isEmpty()) {
                for(Income_Expense_Obligation__c obligation : obligationList){
                    if(obligation.Imputed_EMI__c != null && obligation.Imputed_EMI__c != 0){
                        system.debug(obligation.Imputed_EMI__c);
                        monthlyObligation += Integer.valueOf(obligation.Imputed_EMI__c);
                        system.debug(monthlyObligation);
                    }
                }
            } else {
                monthlyObligation = 0;
            }
            
            Map<String, List<Applicant_Address__c>> applicantAddressesMap= new Map<String, List<Applicant_Address__c>>();
            List<Applicant_Address__c> applicantAddressesList = [SELECT Id,Applicant__c, Document_Details__r.Name , Document_Details__r.Document_Master__r.Document_Type__c,Address_Priority__c FROM Applicant_Address__c WHERE Address_Source__c != null AND Document_Details__c !=  null AND Applicant__r.Loan_Application__c = :recordId AND Document_Details__r.Document_Master__r.Document_Type__c = 'POA'];
            
            // if(sObjName == 'Opportunity'){
            for(Applicant_Address__c address: applicantAddressesList ){
                if(!applicantAddressesMap.containsKey(address.Applicant__c)){
                    applicantAddressesMap.put(address.Applicant__c, new List<Applicant_Address__c>{address});
                }else {
                    applicantAddressesMap.get(address.Applicant__c).add(address);
                }
            }
            // Id leadId;
            // opportunity relatedLoan = [
            //     SELECT  Lead__c 
            //     FROM opportunity 
            //     WHERE Id = :recordId 
            //     LIMIT 1
            // ];
            // leadId = relatedLoan.Lead__c; 
            // System.debug('Lead ID: ' + leadId);
            // if (leadId != null) {
            //     Lead [] leadrec = [
            //         SELECT Id, Dsa_Area_Manager__r.Name, Channel__c, Product__c ,Branch__c, 
            //         Branch__r.Name, Branch__r.Branch_Code__c,Referred_By_DSA__c,Referred_By_DSA__r.Vendor_Code__c
            //         FROM Lead 
            //         WHERE Id = :leadId 
            //         LIMIT 1
            //     ];
            //     if(!leadrec.isEmpty()){
            //         Lead relatedLead = leadrec[0];
            //         this.areamanager = relatedLead.Dsa_Area_Manager__r.Name != null ? relatedLead.Dsa_Area_Manager__r.Name : '';
            //         this.channel = relatedLead.Referred_By_DSA__r.Vendor_Code__c != null ? relatedLead.Referred_By_DSA__r.Vendor_Code__c : '';
            //         this.productcode = relatedLead.Product__c != null ? relatedLead.Product__c : '';
            //     }
            //     else{
            //         this.areamanager = '';
            //         this.channel = '';
            //         this.productcode = '';
            //     }
            // }
            String labelValue = System.Label.App_form_image_conditions;
            List<String> applicantTypesToExclude = new List<String>();
            if(String.isNotBlank(labelValue)){
                for(String val : labelValue.split(',')){
                    applicantTypesToExclude.add(val.trim());
                }
            }
           List<Opportunity> Loan = [Select id,Tenor_Months__c,Branch_Master__r.name , Branch_Master__r.Branch_Code__c,PSL__c,Udhyam_Registration_No__c,tolabel(Loan_Facility__c),Loan_Purpose__c,CreatedDate, Requested_Amount__c, Requested_Tenure_in_Months__c, Product__c, Variant__c, Sub_Variant__c,Reference_Name_1__c,Reference_Last_Name_1__c,Reference_Address_1__c,Reference_Phone_1__c,Reference_Name_2__c,Reference_Last_Name_2__c,Reference_Address_2__c,Reference_Phone_2__c,Nature_of_Business__c,Lead__r.Dsa_Area_Manager__r.Name,
           Lead__r.Channel__c,
           Lead__r.Product__c,
           Lead__r.Branch__c,
           Lead__r.Branch__r.Name,
           Lead__r.Branch__r.Branch_Code__c,
           Lead__r.Referred_By_DSA__c,
        //    Lead__r.Referred_By_DSA__r.Vendor_Code__c,(select id,UtilityBillId__c,SaleDeedId__c,CLIPB_ID__c,COI_ID__c,Bank_Statement_ID__c, Applicant_Name__c,Masked_Aadhar_Number__c,Passport_Number__c,Voter_ID_Number__c,PSL__c,Udhyam_Registration_No__c,NPR_Letter_ID__c,Notarized_Rent_Agreement_Registration__c,Rent_Agreement_Registration_Number__c,Disability__c,GSTIN__c,GST_Exempt__c,CKYC_Aadhar__c,CKYC_KIN__c,DOI__c,Entity_1__c,Entity_2__c,No_of_Associated_Entities__c,Registration_Number__c,Name_of_Organization__c,Email__c,Nature_of_Business__c,Office_Ownership__c,Alternate_Email__c,Applicant_Type__c , Customer_Type__c ,DOB__c,Salutation__c,First_Name__c,Middle_Name__c,Last_Name__c,Religion__c,Cast_Category__c,Passport_Mother_s_Name__c,Passport_Nationality__c,Aadhaar_Gender__c,Passport_Spouse_Name__c,Marital_Status__c,Mobile_Number__c,PAN_Number__c,Drivers_License_Number__c,Drivers_License_Validity__c,Mother_s_First_Name__c,Mother_s_Last_Name__c,Father_s_First_Name__c,Father_s_Last_Name__c,Qualification__c,Business_Type__c,Employment_Type__c,Sub_Employment_Type__c,Current_Work_Experience_Years__c,Current_Work_Experience_Months__c,Total_Work_Experience_Years__c,Total_Work_Experience_Months__c,Reference_Name_1__c,Reference_Phone_1__c,Reference_Name_2__c,Reference_Phone_2__c,Reference_Address_1__c,Reference_Address_2__c,Nationality__c,Gender__c,Spouse_First_Name__c,Spouse_Last_Name__c,Citizenship__c,Relationship_with_Primary_Applicant__c,Specialization__c,Sub_Employment_Type_Non_Individual__c,Sub_Segment__c,Address_Ownership__c,Customer_Profile__c,Sector__c    from Application_Applicant__r WHERE Applicant_Type__c != 'Guarantor' Order by Applicant_Type__c ASC ) from Opportunity WHERE Id = :this.recordId LIMIT 1];
           Lead__r.Referred_By_DSA__r.Vendor_Code__c,(select id,UtilityBillId__c,SaleDeedId__c,CLIPB_ID__c,COI_ID__c,Bank_Statement_ID__c, Applicant_Name__c,Masked_Aadhar_Number__c,Passport_Number__c,Voter_ID_Number__c,PSL__c,Udhyam_Registration_No__c,NPR_Letter_ID__c,Notarized_Rent_Agreement_Registration__c,Rent_Agreement_Registration_Number__c,Disability__c,GSTIN__c,GST_Exempt__c,CKYC_Aadhar__c,CKYC_KIN__c,DOI__c,Entity_1__c,Entity_2__c,No_of_Associated_Entities__c,Registration_Number__c,Name_of_Organization__c,Email__c,Nature_of_Business__c,Office_Ownership__c,Alternate_Email__c,Applicant_Type__c , Customer_Type__c ,DOB__c,Salutation__c,First_Name__c,Middle_Name__c,Last_Name__c,Religion__c,Cast_Category__c,Passport_Mother_s_Name__c,Passport_Nationality__c,Aadhaar_Gender__c,Passport_Spouse_Name__c,Marital_Status__c,Mobile_Number__c,PAN_Number__c,Drivers_License_Number__c,Drivers_License_Validity__c,Mother_s_First_Name__c,Mother_s_Last_Name__c,Father_s_First_Name__c,Father_s_Last_Name__c,Qualification__c,Business_Type__c,Employment_Type__c,Sub_Employment_Type__c,Current_Work_Experience_Years__c,Current_Work_Experience_Months__c,Total_Work_Experience_Years__c,Total_Work_Experience_Months__c,Reference_Name_1__c,Reference_Phone_1__c,Reference_Name_2__c,Reference_Phone_2__c,Reference_Address_1__c,Reference_Address_2__c,Nationality__c,Gender__c,Spouse_First_Name__c,Spouse_Last_Name__c,Citizenship__c,Relationship_with_Primary_Applicant__c,Specialization__c,Sub_Employment_Type_Non_Individual__c,Sub_Segment__c,Address_Ownership__c,Customer_Profile__c,Sector__c    from Application_Applicant__r WHERE Applicant_Type__c NOT IN :applicantTypesToExclude Order by Applicant_Type__c ASC ) from Opportunity WHERE Id = :this.recordId LIMIT 1];
            if (!Loan.isEmpty()) {
                Opportunity parentfcu = Loan[0];
                Id recId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Variant').getRecordTypeId();
                system.debug(recId);
                List<Product2> productList = [SELECT Name FROM Product2 WHERE Loan_Application__c =: parentfcu.Id AND Product__r.Product__r.Name =: parentfcu.Product__c AND RecordTypeId =: recId LIMIT 1];
				
                this.loandate = Date.valueOf(parentfcu.CreatedDate);
                this.loanAmount = parentfcu.Requested_Amount__c;
                this.loanAmountInwords = Utility.getNumberTOWordConvertion(this.loanAmount);
                this.loantenure = parentfcu.Tenor_Months__c;
                this.loanType = parentfcu.Product__c;
                this.loanPurpose = parentfcu.Loan_Purpose__c;
                if(productList.size()>0 && productList[0].Name != null){
                	this.loanfacilitytype = productList[0].Name;
                }
                if (parentfcu.Lead__r != null) {
                    this.areamanager = parentfcu.Lead__r.Dsa_Area_Manager__r != null ? parentfcu.Lead__r.Dsa_Area_Manager__r.Name : '';
                        
                    this.channel = parentfcu.Lead__r.Referred_By_DSA__r != null ? parentfcu.Lead__r.Referred_By_DSA__r.Vendor_Code__c : '';
                        
                    this.productcode = parentfcu.Lead__r.Product__c != null ? parentfcu.Lead__r.Product__c : '';
                }
                this.branchcode = parentfcu.Branch_Master__r.Branch_Code__c != null ? parentfcu.Branch_Master__r.Branch_Code__c : 'NA';
                this.branchname = parentfcu.Branch_Master__r.Name != null ? parentfcu.Branch_Master__r.Name : 'NA';
                this.refname1 = parentfcu.Reference_Name_1__c + ' ' + parentfcu.Reference_Last_Name_1__c;
                this.refadd1 = parentfcu.Reference_Address_1__c;
                this.refphone1 = parentfcu.Reference_Phone_1__c;
                this.refname2 = parentfcu.Reference_Name_2__c + ' ' + parentfcu.Reference_Last_Name_2__c;
                this.refadd2 = parentfcu.Reference_Address_2__c;
                this.refphone2 = parentfcu.Reference_Phone_2__c;
                this.applicants = parentfcu.Application_Applicant__r;
                this.natureofbusiness = parentfcu.Nature_of_Business__c;
                List<Id> applicantIds = new List<Id>();
                Map<String, String> applicantpoa= new Map<String, String>();
                Map<String, String> applicantpoaNumber= new Map<String, String>();
                Map<String, String> applicantpoavalid= new Map<String, String>();
                for (Application_Applicant__c applicant : parentfcu.Application_Applicant__r) {
                    if(applicant.Applicant_Type__c == 'Primary Applicant' && applicant.Customer_Type__c == 'Individual'){
                        isApplicantIndividual = true;
                    }
                    if(applicant.Applicant_Type__c == 'Primary Applicant'){
                        this.URN = applicant.Udhyam_Registration_No__c != null ? applicant.Udhyam_Registration_No__c : 'NA';
                        this.PSL = applicant.PSL__c != null? applicant.PSL__c : 'NA';
                    }
                    List<Applicant_Address__c> applicantAdd= applicantAddressesMap.containskey(applicant.Id) ? applicantAddressesMap.get(applicant.Id) : new List<Applicant_Address__c>();
                    Set<String> poaList = new Set<String>();
                    for (Applicant_Address__c address : applicantAdd) {
                        if (address.Address_Priority__c == '5') {
                            String docName = address.Document_Details__r.Name != null ? address.Document_Details__r.Name.toLowerCase() : '';
                    
                            if (docName.contains('aadhaar')) {
                                poaList.add('Aadhaar');
                            } else if (docName.contains('voter')) {
                                poaList.add('Voter ID');
                            } else if (docName.contains('passport')) {
                                poaList.add('Passport');
                            } else {
                                poaList.add(address.Document_Details__r.Name);
                            }
                            break;
                        }
                    }
                    system.debug('check POA List -->'+poaList);
                    if (applicant.Applicant_Type__c == 'Co Applicant') {
                        hasCoApplicant = true;
                    }
                    String poaDetailsList ='';
                    if(poaList.size()>0){
                        poaDetailsList = String.join(poaList, ', ');
                    }
                    system.debug('check POA List -->'+poaDetailsList);
                    String poaNumber = '';
                    String poavalid = '';
                    if(poaList.contains('Aadhaar'))
                    {
                        poaNumber = applicant.Masked_Aadhar_Number__c;
                        poavalid = 'NA';
                    }else if(poaList.contains('Voter ID'))
                    {
                        poaNumber = applicant.Voter_ID_Number__c;
                        poavalid = 'NA';
                    }else if(poaList.contains('Passport'))
                    {
                        poaNumber = applicant.Passport_Number__c;
                        poavalid = applicant.Passport_Date_of_Expiry__c != null ? applicant.Passport_Date_of_Expiry__c.format() : 'NA';
                    }else if(poaList.contains('DL')){
                        poaNumber = applicant.Drivers_License_Number__c;
                        poavalid = applicant.Drivers_License_Validity__c != null ? applicant.Drivers_License_Validity__c.format() : 'NA';
                    }
                    else if(poaList.contains('GST Certificate')){
                        poaNumber = applicant.GSTIN__c;
                        poavalid = 'NA';
                    }else if(poaList.contains('Letter issued by the National Population Register')){
                        poaNumber = applicant.NPR_Letter_ID__c;
                        poavalid = 'NA';
                    }else if(poaList.contains('Registered Rent Agreement')){
                        poaNumber = applicant.Rent_Agreement_Registration_Number__c;
                        poavalid = 'NA';
                    }else if(poaList.contains('Notarized rent agreement with utility bill')){
                        poaNumber = applicant.Notarized_Rent_Agreement_Registration__c;
                        poavalid = 'NA';
                    }else if(poaList.contains('Udhyam Registration')){
                        poaNumber = applicant.Udhyam_Registration_No__c;
                        poavalid = 'NA';
                    }else if(poaList.contains('Utility Bill not more than 2 months old')){
                        poaNumber = applicant.UtilityBillId__c;
                        poavalid = 'NA';
                    }else if(poaList.contains('Sale Deed')){
                        poaNumber = applicant.SaleDeedId__c;
                        poavalid = 'NA';
                    }else if(poaList.contains('Bank Statement')){
                        poaNumber = applicant.Bank_Statement_ID__c;
                        poavalid = 'NA';
                    }else if(poaList.contains('Certificate of Incorporation')){
                        poaNumber = applicant.COI_ID__c;
                        poavalid = 'NA';
                    }else if(poaList.contains('Certificate of license issued by professional body')){
                        poaNumber = applicant.CLIPB_ID__c;
                        poavalid = 'NA';
                    }
                    
                    applicantIds.add(applicant.Id);
                    if(poaDetailsList!= null && poaDetailsList!= ''){
                        applicantpoa.put(applicant.Id, poaDetailsList);
                    }else{
                        applicantpoa.put(applicant.Id, 'NA');
                    }
                    if(poaNumber!= null && poaNumber!= ''){
                        applicantpoaNumber.put(applicant.Id, poaNumber);
                    }else{
                        applicantpoaNumber.put(applicant.Id, 'NA');
                    }
                    if(poavalid != null && poavalid != '')
                    {
                        applicantpoavalid.put(applicant.Id, poavalid);
                    }
                    else{
                        applicantpoavalid.put(applicant.Id, 'NA');
                    }
                }
                this.applicantpoaMap = applicantpoa;
                this.applicantpoaNumberMap = applicantpoaNumber;
                this.applicantpoaValidMAp = applicantpoavalid;
                system.debug('check POA List -->'+applicantpoaMap);
                List<Document_Details__c> documentDetails = [SELECT Content_Document_Id__c,Applicant__c,Document_Master__r.Name FROM Document_Details__c WHERE Applicant__c IN :applicantIds AND  (Document_Master__r.Name = 'Photograph') AND Active__c = true AND Applicant__r.Applicant_Type__c NOT IN :applicantTypesToExclude];
                List<Applicant_Address__c>applicantAddressList = [SELECT Applicant__c,Address_Type__c, Full_Address1__c, Full_Address__c,Address_Source__c,Document_Details__c FROM Applicant_Address__c WHERE Applicant__c IN :applicantIds AND Address_Type__c != 'BSA' AND (Full_Address1__c != null OR Full_Address__c != null)];
                List<Applicant_Address__c> tempApplicantAddress = new List<Applicant_Address__c>();
                for(Applicant_Address__c address : applicantAddressList){
                    system.debug(address);
                    if(!(address.Address_Source__c == 'Manual' && address.Address_Type__c == 'Current' && address.Document_Details__c == null)){
                        tempApplicantAddress.add(address);
                        system.debug(tempApplicantAddress);
                    }
                }
                this.applicantAddresses = tempApplicantAddress;
                applicantWrappers = new List<ApplicantWrapper>();
                applicantWrappersMorethenFive = new List<ApplicantWrapper>();
                
                Integer i = 0;
                for (Application_Applicant__c applicant : applicants) {
                    String docId = null;
                    i++;
                    for (Document_Details__c doc : documentDetails) {
                        if (doc.Applicant__c == applicant.Id && doc.Content_Document_Id__c != null) {
                            docId = doc.Content_Document_Id__c;
                            break; 
                        }
                    }
                    if(i<=5){
                        applicantWrappers.add(new ApplicantWrapper(applicant, docId));
                        system.debug('applicant wrapper---??'+applicantWrappers);
                    }if(i>5){
                        applicantWrappersMorethenFive.add(new ApplicantWrapper(applicant, docId));
                        system.debug('applicant wrapper??'+applicantWrappersMorethenFive);
                    }
                }
                this.applicanttype = parentfcu.Application_Applicant__r[0].Customer_Type__c;
            }
            
        } catch (Exception exp) {
            Utility.generateException(exp, Constants__mdt.getInstance('FRAUD_CONTROL_UNIT').value__c, 'FCULAController');
        }
    }
    
}