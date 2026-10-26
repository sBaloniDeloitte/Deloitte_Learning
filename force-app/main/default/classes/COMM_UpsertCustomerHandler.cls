public without  sharing class COMM_UpsertCustomerHandler implements IntegrationInterface {
    
    // **AD - ADD CACHES TO AVOID REPEATED SOQL EXECUTION**
    private static Map<String, Application_Applicant__c> applicantCache = new Map<String, Application_Applicant__c>();
    private static Map<String, Map<String, Applicant_Address__c>> applicantAddressCache = new Map<String, Map<String, Applicant_Address__c>>();
    
    private static Map<String, Map<String, String>> masterCodeCache;
    private static Map<String, Map<String, String>> subSectorCodeCache;
    private static Map<String, Map<String, String>> salutationCodeCache;
    //added
    // **Validation Method**
    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) {
        system.debug('wrapper:: '+wrapper);
        String applicantId = wrapper.applicantId;
        List<String> validateErrors = new List<String>();
        String disableFlag = Label.CreateFinanceDisableFlag;
        String disableMessage = Label.CreateFinanceDisableMessage;
        
        if(disableFlag == 'true'){
            validateErrors.add(disableMessage);
        }
        return validateErrors;
    }
    
    // **Construct Payload Method**
    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
            system.debug('wrapper:: '+wrapper);
            String applicantId = wrapper.applicantId;
            
            Map<String,List<String>> mapInputJSON = getRequestInputJSON(applicantId);
            List<String> reqBodyList = mapInputJSON.get('reqBody');
            String requestJSON = reqBodyList[0];// JSON request
            System.debug('Request JSON: ' + requestJSON);
            return requestJSON;
        } catch (Exception e) {
            system.debug('line number'+e.getLineNumber());
            system.debug('msg>>>'+e.getMessage());
            throw new AuraHandledException('There is a Salesforce Exception, please contact your Salesforce Administrator.');
        }
    }
    
    public static map<String, List<String>> getRequestInputJSON(String applicantId){
        
        Application_Applicant__c applicant = getApplicant(applicantId);
        
        Map<String, Map<String, Applicant_Address__c>> mapApplicantAddr = getApplicantAddress(new Set<String>{applicantId});
        System.debug('PLF COUNT BEFORE METHOD = ' +[SELECT COUNT() FROM PLF_Master__c]);
        Map<String, Map<String, String>> mapMasterCode =  getMasterCode();
        Map<String, Map<String, String>> mapSubSectorCode =  getSubSectorCode();
        Map<String, Map<String, String>> mapSalutationCode =  getSalutationCode();
        
        Map<String,List<String>> mapInputJSON = customerJSON(applicant, mapMasterCode, mapApplicantAddr, mapSubSectorCode, mapSalutationCode);
        return mapInputJSON;
    }
    
    public static map<String, List<String>> customerJSON(Application_Applicant__c app, Map<String, Map<String, String>> mapMasterCode, Map<String, Map<String,Applicant_Address__c>> mapApplicantAddr, Map<String, Map<String, String>> mapSubSectorCode, Map<String, Map<String, String>> mapSalutationCode) {
        List<String> errorCode = new List<String>();
        System.debug('Application --------'+app);
        Map<String,List<String>> mapInput = new   Map<String,List<String>>();
        CustomerApiWrapper wrap = new CustomerApiWrapper();
        boolean isUpdateCustomerCase = false;
        
        //check and revert later
        if(!String.isBlank(app.Customer_LMS_Id__c) || app.Existing_Customer__c){
            wrap.cif = app.Customer_LMS_Id__c;
            isUpdateCustomerCase = true;
        }
        else {
            wrap.categoryCode = app.Customer_Type__c == 'Individual' ? 'RETAIL' : 'CORP';
        }
        
        wrap.defaultBranch = app.Loan_Application__r.Branch_Master__r.Branch_Code__c ?? null;
        wrap.baseCurrency = 'INR';
        if(!isUpdateCustomerCase) {
            wrap.coreBankID = String.isNotBlank(app.Customer__r.UCIC_Number__c) ? app.Customer__r.UCIC_Number__c : '';
        }
        wrap.primaryRelationOfficer = '774';
        
        // Personal Info wrap
        PersonalInfo perInfo = new PersonalInfo();
        List<PLF_Master__c> sectorRec = [SELECT Id,Master_Type__c, Description__c, FICO_Code__c FROM PLF_Master__c where Master_Type__c = 'Sector' AND Customer_Type__c =:app.Customer_Profile__c AND Description__c =: app.Sector__c limit 1];
        if(sectorRec.size() > 0) {
            perInfo.sector = sectorRec[0].FICO_Code__c;
        }
        //perInfo.sector= (app.Sector__c != null) ? mapMasterCode.get('sector').get(app.Sector__c.toLowerCase()) : '';
        perInfo.industry = (app.Industry__c != null) ? mapMasterCode.get('industry').get(app.Industry__c.toLowerCase()) : '';
        
        if(app.Customer_Type__c == 'Individual'){
            perInfo.firstName = app.First_Name__c;
            perInfo.lastName = (app.Last_Name__c != null && !String.isBlank(app.Last_Name__c)) ? app.Last_Name__c : '';
            perInfo.middleName = app.Middle_Name__c;
            perInfo.dateofBirth =  formatDateString(app.DOB__c);
            perInfo.motherName = app.Mother_s_First_Name__c ?? '';
            perInfo.fatherName = app.Father_s_First_Name__c ?? '';
            if(app.Customer_Profile__c == 'Salaried Indian​' || app.Customer_Profile__c == 'Salaried NRI'){
                perInfo.subCategory = 'SALARIED';
            }
            else {
                perInfo.subCategory =(app.Customer_Profile__c != null) ? mapMasterCode.get('customer type').get(app.Customer_Profile__c.toLowerCase()) : '';
            }
            System.debug('app.Gender__c=' + app.Gender__c);
System.debug('mapMasterCode=' + mapMasterCode);
System.debug('mapMasterCode.containsKey(gender)=' +
             mapMasterCode.containsKey('gender'));

System.debug('genderMap=' +
             mapMasterCode.get('gender'));
            
            perInfo.gender = (app.Gender__c != null) ? mapMasterCode.get('gender').get(app.Gender__c.toLowerCase()) : '';
            perInfo.type= '21';
            perInfo.maritalStatus =  (app.Marital_Status__c != null) ? mapMasterCode.get('marital status').get(app.Marital_Status__c.toLowerCase()) : '';
            
            if(perInfo.gender != ''){
                string gender = perInfo.gender;
                perInfo.salutation = (app.Salutation__c != null) ? mapSalutationCode.get(gender.toLowerCase()).get(app.Salutation__c.toLowerCase()) : '';
            }
            
        } else {
            perInfo.dateofBirth =  formatDateString(app.DOI__c);
            perInfo.shortName = app.Applicant_Name__c;
            perInfo.type= 'C9';
        }
        
        perInfo.segment = (app.Sub_Employment_Type_Non_Individual__c != null) ? mapMasterCode.get('segment').get(app.Sub_Employment_Type_Non_Individual__c.toLowerCase()) : '';
        perInfo.relationship='';
        perInfo.countryOfBirth = (app.Nationality__c != null) ? mapMasterCode.get('nationality').get(app.Nationality__c.toLowerCase()) : '' ;
        perInfo.numofDependents=null;
        perInfo.nationality =   (app.Nationality__c != null) ? mapMasterCode.get('nationality').get(app.Nationality__c.toLowerCase()) : '';
        perInfo.custCRCPR = (app.PAN_Number__c != null) ? app.PAN_Number__c : '';
        perInfo.qualification =  (app.Qualification__c != null) ? mapMasterCode.get('qualification').get(app.Qualification__c.toLowerCase()) : '';
        perInfo.profession='';
        perInfo.caste= (app.Cast_Category__c != null) ?  mapMasterCode.get('caste').get(app.Cast_Category__c.toLowerCase()) : '';
        perInfo.religion =  (app.Religion__c != null) ?  mapMasterCode.get('religion').get(app.Religion__c.toLowerCase()) : '';
        perInfo.residentialSts =  (app.Residency_Status__c != null) ?  mapMasterCode.get('residency status').get(app.Residency_Status__c.toLowerCase()) : '';
        
        if(perInfo.sector != ''){
            string sector = perInfo.sector;
            List<PLF_Master__c> subsectorRec = [SELECT Id,Master_Type__c, Description__c, FICO_Code__c FROM PLF_Master__c where Master_Type__c = 'Sub sector' AND Sector_Code__c =:sector AND Description__c =: app.Industry__c limit 1];
            if(subsectorRec.size() > 0) {
                perInfo.subSector = subsectorRec[0].FICO_Code__c;
            }
            //perInfo.subSector = (app.Industry__c != null) ? (mapSubSectorCode.containsKey(sector.toLowerCase()) ? mapSubSectorCode.get(sector.toLowerCase()).get(app.Industry__c.toLowerCase()) : '') : '';
        }
        
        wrap.PersonalInfo =  perInfo;
        
        // Add validation code
        if(wrap.cif == '' && isUpdateCustomerCase){ errorCode.add(validationMessage('CIF')); }
        if(perInfo.sector == ''){ errorCode.add(validationMessage('Sector')); }
        if(perInfo.industry == ''){ errorCode.add(validationMessage('Industry')); }
        if(perInfo.salutation == '' && wrap.categoryCode == 'RETAIL') { errorCode.add(validationMessage('Salutation')); }
        if(perInfo.firstName == '' && wrap.categoryCode == 'RETAIL') { errorCode.add(validationMessage('FirstName')); }
        if(perInfo.lastName == '' && wrap.categoryCode == 'RETAIL') { errorCode.add(validationMessage('LastName')); }
        if(perInfo.gender == '' && wrap.categoryCode == 'RETAIL') { errorCode.add(validationMessage('Gender')); }
        if(perInfo.dateofBirth == '') { errorCode.add(validationMessage('Date of Birth')); }
        if(perInfo.maritalStatus == '' && wrap.categoryCode == 'RETAIL') { errorCode.add(validationMessage('Marital Status')); }
        if(perInfo.segment == ''){ errorCode.add(validationMessage('Segment')); }
        
        // Address wrap
        List<addresses> addrList = new List<addresses>();
        Map<String, Applicant_Address__c> addrMap = new Map<String, Applicant_Address__c>();
        if(mapApplicantAddr.containsKey(app.Id)){
            addrMap = mapApplicantAddr.get(app.Id);
        }
        List<Applicant_Address__c> listAddr = addrMap.values();
        
        for(Applicant_Address__c appAddr : listAddr){
            addresses addr = new addresses();
            Boolean enableAddrType = false;
            
            if(app.Customer_Type__c == 'Individual'){
                if(appAddr.Address_Type__c == 'Permanent' || appAddr.Address_Type__c == 'Current'){
                    enableAddrType = true;
                }
            } else {
                if(appAddr.Address_Type__c == 'Registered Office'){
                    enableAddrType = true;
                }
            }
            
            if(enableAddrType){
                addr.addrType =  (appAddr.Address_Type__c != null) ?  mapMasterCode.get('address type').get(appAddr.Address_Type__c.toLowerCase()) : '';
                addr.buildingNo = appAddr.Address_Line_1__c;
                addr.addrLine1 = 'NA';
                addr.addrLine2 = 'NA';
                addr.country = (appAddr.Pincode__r != null && appAddr.Pincode__r.City__r != null) ? appAddr.Pincode__r.City__r.Country__c : null;//'IN';
                addr.state = (appAddr.Pincode__r != null && appAddr.Pincode__r.City__r != null) ? appAddr.Pincode__r.City__r.State__c : null;
                addr.city = (appAddr.Pincode__r != null && appAddr.Pincode__r.City__r != null) ? appAddr.Pincode__r.city__r.City_Code__c : null;
                addr.pinCode = (appAddr.Pincode__r != null) ? appAddr.Pincode__r.name : null;
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
        
        //Email__c
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
        // extended details
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
        if(!isUpdateCustomerCase) {
            wrap.documents = getForm60DocumentData(app); //commenting as per https://godrejhf.atlassian.net/browse/SFHL-1895 for BOTH HL AND AHL >>uncommenting again as it wil be passed for create customer
        }
        
        List<String> listReqBody = new List<String>();
        listReqBody.add(JSON.serialize(wrap, true)); //the second param makes sure that null tags get removed from the API > Armann
        mapInput.put('reqBody', listReqBody);
        mapInput.put('errors', errorCode);
        
        return mapInput;
    }
    
    public static String validationMessage(string fieldName){
        String msg = 'Please enter valid data for '+ fieldName;
        return msg;
    }
    
    public static List<documents> getForm60DocumentData(Application_Applicant__c applicant){
        List<documents> decWrapperList= new List<documents>();
        List<String> docNames = new List<String>{'Aadhaar Front','Form 60','Voter Front','Passport Front','Driving licence','PAN'};
        
        List<Document_Details__c> documentListnonUnique = [
        SELECT Id, Name, Document_Master__r.Document_Code__c, 
               Content_Document_Id__c, Applicant__c, Document_URI__c 
        FROM Document_Details__c 
        WHERE Applicant__c = :applicant.Id 
              AND Name IN :docNames 
              AND Content_Document_Id__c != null 
              AND Active__c = true
    ];
        
        Map<String, Document_Details__c> uniqueDocMap = new Map<String, Document_Details__c>();
        
        for (Document_Details__c doc : documentListnonUnique) {
            if (!uniqueDocMap.containsKey(doc.Content_Document_Id__c)) {
                uniqueDocMap.put(doc.Content_Document_Id__c, doc);
            }
        }
        
        Map<String, Document_Details__c> uniqueDocCodeMap = new Map<String, Document_Details__c>();
        
        for (Document_Details__c doc : uniqueDocMap.values()) {
            if (doc.Document_Master__r != null && doc.Document_Master__r.Document_Code__c != null) {
                if (!uniqueDocCodeMap.containsKey(doc.Document_Master__r.Document_Code__c)) {
                    uniqueDocCodeMap.put(doc.Document_Master__r.Document_Code__c, doc);
                }
            }
        }
        
        List<Document_Details__c> documentList = uniqueDocCodeMap.values();
        
        List<String> contentDocIds= new List<String>();
        for(Document_Details__c doc: documentList){
            contentDocIds.add(doc.Content_Document_Id__c);
        }
        
        List<ContentVersion> contentVersionList = [
        SELECT FileExtension, Title, VersionData,ContentDocumentId, FileType, PathOnClient
        FROM ContentVersion
        WHERE ContentDocumentId IN :contentDocIds
        ORDER BY CreatedDate DESC
    ];
        
        Map<String, ContentVersion> contentDocMap= new Map<String, ContentVersion>();
        for(ContentVersion cv: contentVersionList){
            if(!contentDocMap.containsKey(cv.ContentDocumentId)){
                contentDocMap.put(cv.ContentDocumentId, cv);
            }
        }
        
        for(Document_Details__c document: documentList){
            documents doWrap= new documents();
            String docfor ='';
            if(contentDocMap.get(document.Content_Document_Id__c)!=null){
                docfor=contentDocMap.get(document.Content_Document_Id__c).FileType;
            }
            
            if(docfor.equalsIgnoreCase('pdf')) {
                
            }else {
                docfor = 'IMG';
            }
            
            doWrap.docFormat= docfor;
            doWrap.docName=  contentDocMap.get(document.Content_Document_Id__c).PathOnClient;
            doWrap.docCategory=  document.Document_Master__r.Document_Code__c;
            doWrap.custDocIssuedAuth=  'IN';
            doWrap.custDocIssuedCountry= 'IN' ;
            doWrap.docContent=  '';
            doWrap.docRefId = document.Id;
            
            if (document.Name == 'Driving licence') {
                doWrap.custDocExpDate = applicant.Drivers_License_Validity__c != null ? formatDateString(applicant.Drivers_License_Validity__c) : '';
            }else if(document.Name == 'Passport Front'){
                doWrap.custDocExpDate = applicant.Passport_Date_of_Expiry__c != null ? formatDateString(applicant.Passport_Date_of_Expiry__c) : '';
            }
            
            if (document.Name == 'Aadhaar Front') {
                doWrap.custDocTitle = applicant.Masked_Aadhar_Number__c != null ? (String) applicant.Masked_Aadhar_Number__c : '';
            }else if(document.Name == 'Voter Front'){
                doWrap.custDocTitle = applicant.Voter_ID_Number__c != null ? (String) applicant.Voter_ID_Number__c : '';
            }else if(document.Name == 'Driving licence'){
                doWrap.custDocTitle = applicant.Drivers_License_Number__c != null ? (String) applicant.Drivers_License_Number__c : '';
            }else if(document.Name == 'Passport Front'){
                doWrap.custDocTitle = applicant.Passport_Number__c != null ? (String) applicant.Passport_Number__c : '';
            }else if(document.Name == 'PAN'){
                doWrap.custDocTitle = applicant.PAN_Number__c != null ? (String) applicant.PAN_Number__c : '';
            }else{
                doWrap.custDocTitle = '';
            }
            
            decWrapperList.add(doWrap);
        }
        return decWrapperList;
    }
    // --- CACHED LOOKUPS ---
    public static Map<String, Map<String, String>> getMasterCode(){
        System.debug('masterCodeCache=' + masterCodeCache);
        if (masterCodeCache == null) {
            masterCodeCache = new Map<String, Map<String, String>>();
            List<PLF_Master__c> masterRecords = [
                SELECT Id,Master_Type__c, Description__c, FICO_Code__c 
                FROM PLF_Master__c where Master_Type__c != 'Sub sector'
            ];
            
            System.debug('masterRecords size = ' + masterRecords.size());

for(PLF_Master__c rec : masterRecords){
    System.debug(
        rec.Master_Type__c + ' | ' +
        rec.Description__c + ' | ' +
        rec.FICO_Code__c
    );
}
            for (PLF_Master__c record : masterRecords) {
                String key = record.Master_Type__c.toLowerCase();
                if (!masterCodeCache.containsKey(key)) {
                    masterCodeCache.put(key, new Map<String, String>());
                }
                if(String.isNotBlank(record.Description__c) && String.isNotBlank(record.FICO_Code__c)){
                    masterCodeCache.get(key).put(record.Description__c.toLowerCase(), record.FICO_Code__c);
                }
            }
        }
        System.debug('masterCodeCache=' + masterCodeCache);
        return masterCodeCache;
    }
    
    public static Map<String, Map<String, String>> getSubSectorCode(){
        if (subSectorCodeCache == null) {
            subSectorCodeCache = new Map<String, Map<String, String>>();
            List<PLF_Master__c> masterRecords = [
                SELECT Id,Master_Type__c, Description__c, FICO_Code__c,Sector_Code__c 
                FROM PLF_Master__c
                WHERE Master_Type__c = 'Sub sector'
            ];
            
            for (PLF_Master__c record : masterRecords) {
                String key = (record.Sector_Code__c != null) ? record.Sector_Code__c.toLowerCase() : '';
                if (!subSectorCodeCache.containsKey(key)) {
                    subSectorCodeCache.put(key, new Map<String, String>());
                }
                subSectorCodeCache.get(key).put(record.Description__c.toLowerCase(), record.FICO_Code__c);
            }
        }
        return subSectorCodeCache;
    }
    
    public static Map<String, Map<String, String>> getSalutationCode(){
        if (salutationCodeCache == null) {
            salutationCodeCache = new Map<String, Map<String, String>>();
            List<PLF_Master__c> masterRecords = [
                SELECT Id,Master_Type__c, Description__c, FICO_Code__c,Gender_Code__c 
                FROM PLF_Master__c
                WHERE Master_Type__c = 'Salutation'
            ];
            
            for (PLF_Master__c record : masterRecords) {
                String key = (record.Gender_Code__c != null) ? record.Gender_Code__c.toLowerCase() : '';
                if (!salutationCodeCache.containsKey(key)) {
                    salutationCodeCache.put(key, new Map<String, String>());
                }
                salutationCodeCache.get(key).put(record.Description__c.toLowerCase(), record.FICO_Code__c);
            }
        }
        return salutationCodeCache;
    }
    
    // Applicant caching
    public static Application_Applicant__c getApplicant(String applicantId) {
        if (!applicantCache.containsKey(applicantId)) {
            Application_Applicant__c a = [
                SELECT Id, Customer_Type__c, Applicant_Type__c, Industry__c, Salutation__c, First_Name__c,
                       Existing_Customer__c, Customer_LMS_Id__c, Last_Name__c, Middle_Name__c, Gender__c, 
                       Mother_s_First_Name__c, Father_s_First_Name__c, DOB__c, Marital_Status__c, Nationality__c,
                       PAN_Number__c, Masked_Aadhar_Number__c, GSTIN__c, Sub_Employment_Type_Non_Individual__c,
                       Qualification__c, Religion__c, Residency_Status__c, Email__c, Loan_Application__c, Sector__c,
                       Customer__r.Customer_LMS_Id__c, Customer__r.Exisiting_Customer__c, Customer__r.UCIC_Number__c, Customer__c, Mobile_Number__c,
                       DOI__c, Customer_Profile__c, Applicant_Name__c, Cast_Category__c, Sub_Employment_Type__c,
                       Loan_Application__r.Branch_Master__r.Branch_Code__c,Drivers_License_Validity__c,Passport_Date_of_Expiry__c,
                       Voter_ID_Number__c,Drivers_License_Number__c,Passport_Number__c
                FROM Application_Applicant__c
                WHERE Id = :applicantId
            ];
            applicantCache.put(applicantId, a);
        }
        return applicantCache.get(applicantId);
    }
    
    public static Map<String, Map<String, Applicant_Address__c>> getApplicantAddress(Set<String> applicantIds){
        Map<String, Map<String, Applicant_Address__c>> result = new Map<String, Map<String, Applicant_Address__c>>();
        Set<String> idsToFetch = new Set<String>();
        
        for (String idStr : applicantIds) {
            if (!applicantAddressCache.containsKey(idStr)) {
                idsToFetch.add(idStr);
            }
        }
        
        if (!idsToFetch.isEmpty()) {
            List<String> addressTypes = new List<String>{ 'Permanent','Current','Registered Office','Factory Outlet','Godown','Other'};
            List<Applicant_Address__c> appAddrList = new List<Applicant_Address__c>();
            
            //tried making it HL Specific but theres no application Id so lets see where it goes with this in AHL
            appAddrList = [SELECT Id, Applicant__c, Address_Type__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Address_Priority__c,
            Building_Street_Name__c,City__c,State__c,Pincode__c,Pincode__r.name,pincode__r.City__r.State__c,Pincode__r.City__r.Country__c, pincode__r.city__r.City_Code__c, Customer_Address__c
            FROM Applicant_Address__c 
            WHERE Address_Type__c != 'BSA' AND (Address_Type__c IN :addressTypes) AND (Applicant__c IN :idsToFetch) AND (Address_Priority__c IN ('5','4','3'))
            ];
            
            // initialize empty maps for fetched ids
            for (String fetchedId : idsToFetch) {
                applicantAddressCache.put(fetchedId, new Map<String, Applicant_Address__c>());
            }
            
            for (Applicant_Address__c record : appAddrList) {
                String key = record.Applicant__c;
                if (!applicantAddressCache.containsKey(key)) {
                    applicantAddressCache.put(key, new Map<String, Applicant_Address__c>());
                }
                applicantAddressCache.get(key).put(record.Id, record);
            }
        }
        
        // Prepare result map for requested ids
        for (String idStr : applicantIds) {
            if (applicantAddressCache.containsKey(idStr)) {
                result.put(idStr, applicantAddressCache.get(idStr));
            } else {
                result.put(idStr, new Map<String, Applicant_Address__c>());
            }
        }
        
        return result;
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
        public String coreBankID;
        public String defaultBranch;
        public String baseCurrency;
        public String primaryRelationOfficer;
        public PersonalInfo personalInfo;
        public List<documents> documents;
        public List<addresses> addresses;
        public List<phones> phones;
        public List<Email> emails;
        public List<Employment> employments;
        public CustomersBankInfo customersBankInfo;
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
    
    public class documents {
        public String docFormat;
        public String docName;
        public String docCategory;
        public String custDocTitle;
        public String custDocIssuedAuth;
        public String custDocIssuedCountry;
        public String docContent;
        public String docRefId;
        public String custDocExpDate;
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
        // Define fields if needed
    }
    
    public class CustomersBankInfo {
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