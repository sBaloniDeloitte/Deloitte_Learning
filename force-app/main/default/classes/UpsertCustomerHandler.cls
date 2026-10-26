public with sharing class UpsertCustomerHandler implements IntegrationInterface{

    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        system.debug('wrapper:: '+wrapper);
        String applicantId = wrapper.applicantId;
        List<String> validateErrors = new List<String>();
        
        Map<String,List<string>> mapInputJSON = getRequestInputJSON(applicantId);
        validateErrors = mapInputJSON.get('errors');
        system.debug('@@@@ customerJSON validateErrors :: '+ validateErrors.size());

        return validateErrors;
    }

    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
            system.debug('wrapper:: '+wrapper);
            String applicantId = wrapper.applicantId;

            Map<String,List<string>> mapInputJSON = getRequestInputJSON(applicantId);
            List<string> reqBodyList = mapInputJSON.get('reqBody');
            String requestJSON = reqBodyList[0];
            System.debug('Request JSON: ' + requestJSON);
            return requestJSON;
        } catch (Exception e) {
            throw new AuraHandledException('There is a Salesforce Exception, please contact your Salesforce Administrator.');
        }
    }

    public static map<String, List<String>> getRequestInputJSON(String applicantId){
            Map<String, Application_Applicant__c> mapApplicantList = new Map<String, Application_Applicant__c>();

            Map<String, Map<String, String>> mapMasterCode =  getMasterCode();
            Map<String, Map<String, String>> mapSubSectorCode =  getSubSectorCode();
            Map<String, Map<String, String>> mapSalutationCode =  getSalutationCode();

            List<Application_Applicant__c> applicantList = [SELECT Id,Customer_Type__c, Applicant_Type__c, Industry__c,Salutation__c,First_Name__c,
                    Existing_Customer__c, Customer_LMS_Id__c, Last_Name__c,Middle_Name__c,Gender__c, Mother_s_First_Name__c,
                    Father_s_First_Name__c,DOB__c,Marital_Status__c,Nationality__c,PAN_Number__c,Masked_Aadhar_Number__c,GSTIN__c,
                    Sub_Employment_Type_Non_Individual__c,Qualification__c,Religion__c,Residency_Status__c,Email__c,Loan_Application__c,Sector__c,
                    Customer__r.Customer_LMS_Id__c, Customer__r.Exisiting_Customer__c, Customer__c, Mobile_Number__c,
                    DOI__c ,Customer_Profile__c,Applicant_Name__c,Cast_Category__c,
                    Loan_Application__r.Branch_Master__r.Branch_Code__c	
                    FROM Application_Applicant__c  
                    WHERE Id =: applicantId];

            system.debug('customer API applicantList ::: '+ applicantList);  
            
            for(Application_Applicant__c applicant : applicantList){
                if(!mapApplicantList.containsKey(applicant.Id)){
                    mapApplicantList.put(applicant.Id, applicant);
                }                
            } 

            Map<String, Map<String,Applicant_Address__c>> mapApplicantAddr = getApplicantAddress(mapApplicantList.keySet());
            Map<String,List<string>> mapInputJSON = customerJSON(applicantList[0], mapMasterCode, mapApplicantAddr, mapSubSectorCode, mapSalutationCode);
            return mapInputJSON;
    }

    public static map<String, List<String>> customerJSON(Application_Applicant__c app, Map<String, Map<String, String>> mapMasterCode, Map<String, Map<String,Applicant_Address__c>> mapApplicantAddr, Map<String, Map<String, String>> mapSubSectorCode, Map<String, Map<String, String>> mapSalutationCode) {
        List<String> errorCode = new List<String>();
        Map<String,List<String>> mapInput = new   Map<String,List<String>>();
        CustomerApiWrapper wrap = new CustomerApiWrapper();
        boolean isUpdateCustomerCase = false;
        
        if(!String.isBlank(app.Customer_LMS_Id__c) || app.Existing_Customer__c){
            wrap.cif = app.Customer_LMS_Id__c;
            isUpdateCustomerCase = true;
        }
        else {
            wrap.categoryCode = app.Customer_Type__c == 'Individual' ? 'RETAIL' : 'CORP'; 
        }
        
        wrap.defaultBranch = '1006';
        wrap.baseCurrency = 'INR';
        wrap.primaryRelationOfficer = '774';
        
        PersonalInfo perInfo = new PersonalInfo();
        perInfo.sector= (app.Sector__c != null) ? mapMasterCode.get('Sector'.toLowerCase()).get(app.Sector__c.toLowerCase()) : '';  
        perInfo.industry = (app.Industry__c != null) ? mapMasterCode.get('Industry'.toLowerCase()).get(app.Industry__c.toLowerCase()) : ''; 
        
        if(app.Customer_Type__c == 'Individual'){         
            perInfo.firstName = app.First_Name__c;
            perInfo.lastName = app.Last_Name__c;
            perInfo.middleName = app.Middle_Name__c;
            perInfo.dateofBirth =  formatDateString(app.DOB__c);
            perInfo.motherName = app.Mother_s_First_Name__c ?? '';
            perInfo.fatherName = app.Father_s_First_Name__c ?? '';
            perInfo.subCategory = 'DOMESTIC' ;
            perInfo.gender = (app.Gender__c != null) ? mapMasterCode.get('Gender'.toLowerCase()).get(app.Gender__c.toLowerCase()) : '';
            perInfo.type= '21';
            perInfo.maritalStatus =  (app.Marital_Status__c != null) ? mapMasterCode.get('Marital Status'.toLowerCase()).get(app.Marital_Status__c.toLowerCase()) : ''; 
            
            if(perInfo.gender != ''){
                string gender = perInfo.gender;
                perInfo.salutation = (app.Salutation__c != null) ? mapSalutationCode.get(gender.toLowerCase()).get(app.Salutation__c.toLowerCase()) : '';  
            }
       
        } else {
            perInfo.dateofBirth =  formatDateString(app.DOI__c);
            perInfo.shortName = app.Applicant_Name__c;
            perInfo.type= 'C9';
        }      
        
        perInfo.segment = 'clinic';
        perInfo.relationship='';     
        perInfo.countryOfBirth = (app.Nationality__c != null) ? mapMasterCode.get('Nationality'.toLowerCase()).get(app.Nationality__c.toLowerCase()) : '' ; 
        perInfo.numofDependents=null;
        perInfo.nationality =   (app.Nationality__c != null) ? mapMasterCode.get('Nationality'.toLowerCase()).get(app.Nationality__c.toLowerCase()) : '';  
        perInfo.custCRCPR = (app.PAN_Number__c != null) ? app.PAN_Number__c : '';
        perInfo.qualification =  (app.Qualification__c != null) ? mapMasterCode.get('Qualification'.toLowerCase()).get(app.Qualification__c.toLowerCase()) : ''; 
        perInfo.profession='';
        perInfo.caste= (app.Cast_Category__c != null) ?  mapMasterCode.get('Caste'.toLowerCase()).get(app.Cast_Category__c.toLowerCase()) : '';   
        perInfo.religion =  (app.Religion__c != null) ?  mapMasterCode.get('Religion'.toLowerCase()).get(app.Religion__c.toLowerCase()) : '';  
        perInfo.residentialSts =  (app.Residency_Status__c != null) ?  mapMasterCode.get('Residency Status'.toLowerCase()).get(app.Residency_Status__c.toLowerCase()) : '';  
        
        if(perInfo.sector != ''){
            string sector = perInfo.sector;
            perInfo.subSector = (app.Industry__c != null) ? mapSubSectorCode.get(sector.toLowerCase()).get(app.Industry__c.toLowerCase()) : '';  
        }
        
        wrap.PersonalInfo =  perInfo;   
        
        if(wrap.cif == '' && isUpdateCustomerCase){ errorCode.add(validationMessage('CIF')); }
        if(perInfo.sector == ''){ errorCode.add(validationMessage('Sector')); }
        if(perInfo.industry == ''){ errorCode.add(validationMessage('Industry')); }
        if(perInfo.salutation == '' && wrap.categoryCode == 'RETAIL') { errorCode.add(validationMessage('Salutation')); }
        if(perInfo.firstName == '' && wrap.categoryCode == 'RETAIL') { errorCode.add(validationMessage('FirstName')); }
        if(perInfo.lastName == '' && wrap.categoryCode == 'RETAIL') { errorCode.add(validationMessage('LastName')); }
        if(perInfo.gender == '' && wrap.categoryCode == 'RETAIL') { errorCode.add(validationMessage('Gender')); }
        if(perInfo.dateofBirth == '') { errorCode.add(validationMessage('Date of Birth')); }
        if(perInfo.maritalStatus == '' && wrap.categoryCode == 'RETAIL') { errorCode.add(validationMessage('Marital Status')); }        
        if(perInfo.custCRCPR == ''){ errorCode.add(validationMessage('PAN')); } 
        if(perInfo.segment == ''){ errorCode.add(validationMessage('Segment')); } 
       
        List<addresses> addrList = new List<addresses>();
        List<Applicant_Address__c> listAddr = mapApplicantAddr.get(app.Id).values();

        for(Applicant_Address__c appAddr : listAddr){
            addresses addr = new addresses();
            Boolean enableAddrType = false;

            if(app.Customer_Type__c == 'Individual'){
                if((appAddr.Address_Type__c == 'Permanent' && appAddr.Address_Priority__c == '4') || 
                   (appAddr.Address_Type__c == 'Current' && appAddr.Address_Priority__c == '5')){
                    enableAddrType = true;
                }
            } else {
                if((appAddr.Address_Type__c == 'Registered Office' && (appAddr.Address_Priority__c == '5' || appAddr.Address_Priority__c == '3')) ||
                   (appAddr.Address_Type__c == 'Business Operational' && appAddr.Address_Priority__c == '2') ||
                   appAddr.Address_Type__c == 'Factory Outlet' || 
                   appAddr.Address_Type__c == 'Godown' || 
                   appAddr.Address_Type__c == 'Other'){
                    enableAddrType = true;
                }
            }
            
            if(enableAddrType){
                addr.addrType =  (appAddr.Address_Type__c != null) ?  mapMasterCode.get('Address Type'.toLowerCase()).get(appAddr.Address_Type__c.toLowerCase()) : ''; 
                addr.buildingNo = appAddr.Address_Line_1__c;
                addr.addrLine1 = 'NA';
                addr.addrLine2 = 'NA';
                addr.country = 'IN';
                addr.state = appAddr.pincode__r.City__r.State__c;
                addr.city = appAddr.pincode__r.city__r.City_Code__c;
                addr.pinCode = appAddr.Pincode__r.name;
                addr.priority = (appAddr.Address_Priority__c != null ) ? integer.valueOf(appAddr.Address_Priority__c) : 0 ; 
                addr.FlatNo = appAddr.Address_Line_2__c;
                addr.Street = appAddr.Address_Line_3__c;
                addrList.add(addr);

                if(addr.buildingNo == '' ) { errorCode.add(validationMessage('Building No')); }
                if(addr.Street == '' ) { errorCode.add(validationMessage('Street')); }
                if(addr.city == '' ) { errorCode.add(validationMessage('City')); }
                if(addr.state == '' ) { errorCode.add(validationMessage('State')); }
                if(addr.priority == null ) { errorCode.add(validationMessage('Priority')); }
            }                        
        } 
      
        wrap.addresses = addrList;
        List<phones> phoneList = new List<phones>();
        phones ph = new phones();
        ph.phoneTypeCode = 'MOBILE';
        ph.phoneNumber = app.Mobile_Number__c; 
        ph.priority = 5;      
        phoneList.add(ph);
        wrap.phones = phoneList;

        if(ph.phoneNumber == '' ) { errorCode.add(validationMessage('Phone Number')); }
        
        Email mail = new Email();
        List<Email> mailList = new List<Email>();
        mail.custEMailTypeCode =  'PER';
        mail.custEMailPriority =  5;
        mail.custEmail =  app.Email__c;
        mailList.add(mail);
        wrap.emails = mailList;

        if(mail.custEmail == '' ) { errorCode.add(validationMessage('Customer Email')); }

        app.Masked_Aadhar_Number__c = (app.Masked_Aadhar_Number__c != null) ? app.Masked_Aadhar_Number__c : '';
        if(app.Masked_Aadhar_Number__c == ''){ errorCode.add(validationMessage('Aadhar')); } 
        
        List<extendedDetail> extDetList = new List<extendedDetail>();
        List<extendedField> extFldList = new List<extendedField>();
        extendedDetail extDet = new extendedDetail();      
        List<String> fieldList = new List<String>{'ADDRESSPROOF'};

		if(app.Customer_Type__c == 'Individual'){
            fieldList.add('IDNUMBER');
        }
        
        for(String fieldName: fieldList){
            extendedField extFld = new extendedField();

            if(fieldName == 'ADDRESSPROOF'){
                extFld.fieldName = fieldName;
                extFld.fieldValue = app.Customer_Type__c == 'Individual' ? 'AADHAR CARD' : 'GST CERTIFICATE' ;
            } else if(app.Customer_Type__c == 'Individual' && fieldName == 'IDNUMBER'){
                extFld.fieldName = fieldName;
                extFld.fieldValue = app.Masked_Aadhar_Number__c;
            }
            extFldList.add(extFld); 
        }
        
        extDet.extendedFields = extFldList;
        extDetList.add(extDet);
        wrap.extendedDetails = extDetList;      
        
        List<String> listReqBody = new List<String>();
        listReqBody.add(JSON.serialize(wrap));
        mapInput.put('reqBody', listReqBody);
        mapInput.put('errors', errorCode);
        
        return mapInput;
    }

    public static String validationMessage(string fieldName){
        String msg = 'Please enter valid data for '+ fieldName;
        return msg;
    }

    public static Map<String, Map<String, String>> getMasterCode(){
        try {
            Map<String, Map<String, String>> masterDataMap = new Map<String, Map<String, String>>();
            List<PLF_Master__c> masterRecords = [
                SELECT Id,Master_Type__c, Description__c, FICO_Code__c 
                FROM PLF_Master__c
            ];

            for (PLF_Master__c record : masterRecords) {
                if (!masterDataMap.containsKey(record.Master_Type__c.toLowerCase())) {
                    masterDataMap.put(record.Master_Type__c.toLowerCase(), new Map<String, String>());
                }                
                masterDataMap.get(record.Master_Type__c.toLowerCase()).put(record.Description__c.toLowerCase(), record.FICO_Code__c);
            }

            return masterDataMap;
        } catch (Exception e) {
            System.debug('CustomerApiHandler->getMasterCode ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        } 
    }

    public static Map<String, Map<String, String>> getSubSectorCode(){
        try {
            String subSector = 'Sub sector';
            Map<String, Map<String, String>> masterDataMap = new Map<String, Map<String, String>>();
            List<PLF_Master__c> masterRecords = [
                SELECT Id,Master_Type__c, Description__c, FICO_Code__c,Sector_Code__c 
                FROM PLF_Master__c
                WHERE Master_Type__c =: subSector
            ];

            for (PLF_Master__c record : masterRecords) {
                if (!masterDataMap.containsKey(record.Sector_Code__c.toLowerCase())) {
                    masterDataMap.put(record.Sector_Code__c.toLowerCase(), new Map<String, String>());
                }                
                masterDataMap.get(record.Sector_Code__c.toLowerCase()).put(record.Description__c.toLowerCase(), record.FICO_Code__c);
            }

            return masterDataMap;
        } catch (Exception e) {
            System.debug('CustomerApiHandler->getSubSectorCode ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        } 
    }

    public static Map<String, Map<String, String>> getSalutationCode(){
        try {
            String salutation = 'Salutation';
            Map<String, Map<String, String>> masterDataMap = new Map<String, Map<String, String>>();
            List<PLF_Master__c> masterRecords = [
                SELECT Id,Master_Type__c, Description__c, FICO_Code__c,Gender_Code__c 
                FROM PLF_Master__c
                WHERE Master_Type__c =: salutation
            ];

            for (PLF_Master__c record : masterRecords) {
                if (!masterDataMap.containsKey(record.Gender_Code__c.toLowerCase())) {
                    masterDataMap.put(record.Gender_Code__c.toLowerCase(), new Map<String, String>());
                }                
                masterDataMap.get(record.Gender_Code__c.toLowerCase()).put(record.Description__c.toLowerCase(), record.FICO_Code__c);
            }

            return masterDataMap;
        } catch (Exception e) {
            System.debug('CustomerApiHandler->getSalutationCode ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        } 
    }

    public static Map<String, Map<String, Applicant_Address__c>> getApplicantAddress(Set<String> applicantIds){
        try {
            Map<String, Map<String, Applicant_Address__c>> mapApplicantAddr = new Map<String, Map<String, Applicant_Address__c>>();
            List<String> addressTypes = new List<String>{ 'Permanent','Current','Registered Office','Factory Outlet','Godown','Other'};
            List<Applicant_Address__c> appAddrList = [
                SELECT Id, applicant__r.name,Address_Type__c, Address_Line_1__c,Address_Line_2__c,Address_Line_3__c, Address_Priority__c,
                Building_Street_Name__c,City__c,State__c,Pincode__c,Pincode__r.name,pincode__r.City__r.State__c,pincode__r.city__r.City_Code__c, Applicant__c,
                Customer_Address__c
                FROM Applicant_Address__c 
                WHERE Address_Type__c != 'BSA' AND (Address_Type__c IN :addressTypes) AND (Applicant__c  IN: applicantIds)
            ];

            for (Applicant_Address__c record : appAddrList) {
                if (!mapApplicantAddr.containsKey(record.Applicant__c)) {
                    mapApplicantAddr.put(record.Applicant__c, new Map<String, Applicant_Address__c>());
                }

                mapApplicantAddr.get(record.Applicant__c).put(record.Id, record);
            }

            return mapApplicantAddr;

        } catch (Exception e) {
            System.debug('CustomerApiHandler->getApplicantAddress ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        } 
    }

    public static string formatDateString(date myDate){
        try{
            String formattedDate;

            if(myDate != null){
                DateTime myDateTime = DateTime.newInstance(myDate.year(), myDate.month(), myDate.day());
                formattedDate = myDateTime.format('yyyy-MM-dd');

                if(formattedDate != ''){
                    formattedDate = formattedDate + 'T00:00:00';
                }
            }
            System.debug('Convert Date String Format : ' + formattedDate);

            return formattedDate;

        } catch(Exception e){
            System.debug('FinanceApiHandler->formatDateString ::' + e.getMessage() +' AT '+ e.getLineNumber() + ' STACKTRACE '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class CustomerApiWrapper {
        public String cif;
        public String categoryCode;
        public String defaultBranch;
        public String baseCurrency;
        public String primaryRelationOfficer;
        public PersonalInfo personalInfo;
        public List<addresses> addresses;
        public List<phones> phones;
        public List<Email> emails;
        public List<Employment> employments;
        public Object customersBankInfo;
        public List<CustomersExtLiability> customersExtLiability;
        public List<ExtendedDetail> extendedDetails;       
    }
     
    public class PersonalInfo {
        public String sector;
        public String industry;
        public String segment;
        public String type;
        public String salutation;
        public String firstName;
        public String shortName;
        public String lastName;
        public String middleName;
        public String gender;
        public String motherName;
        public String fatherName;
        public String relationship;
        public String dateofBirth;
        public String countryOfBirth;
        public String maritalStatus;
        public Integer numofDependents;
        public String nationality;
        public String custCRCPR;
        public String subCategory;
        public String qualification;
        public String profession;
        public String caste;
        public String religion;
        public String residentialSts;
        public String subSector;
    }

    public class addresses {
        public String addrType;
        public String buildingNo;
        public String addrLine1;
        public String addrLine2;
        public String country;
        public String state;
        public String city;
        public String pinCode;
        public Integer priority;
        public String FlatNo;
        public String Street;
    }

    public class phones {
        public String phoneTypeCode;
        public String phoneNumber;
        public Integer priority;
        public DeclaredFieldValues declaredFieldValues;
    }

    public class DeclaredFieldValues {
        public Integer priority;
        public String phoneTypeCode;
        public String phoneNumber;
    }

    public class Email {
        public String custEMailTypeCode;
        public Integer custEMailPriority;
        public String custEMail;
    }

    public class Employment {
    }

    public class customersBankInfo {
        public String bankId;
        public String bankName;
        public String accountNumber;
        public String accountType; 
    }

    public class CustomersExtLiability {
        public Integer liabilitySeq;
        public String finType;
        public String bankName;
        public Decimal instalmentAmount;
        public Decimal outStandingBal;
        public Decimal originalAmount;
        public Date finDate;
        public Decimal rateOfInterest;
        public Integer tenure;
        public Integer balanceTenure;
        public Integer bounceInstalments;
        public Decimal overdueAmount;
        public Integer source;
        public String finStatus;
        public String remarks;
    }

    public class ExtendedDetail {
        public List<ExtendedField> extendedFields;        
    }

    public class ExtendedField {
        public String fieldName;
        public String fieldValue;
    }
}