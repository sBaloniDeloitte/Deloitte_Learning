public without sharing class SalesDocumentValidationChecklist {
    public class DocValidationWrapper{
        @AuraEnabled public Id documentDetailId;
         @AuraEnabled public String applicantName;
        @AuraEnabled public String applicanttype;
        @AuraEnabled public String documentType;
        @AuraEnabled public Id contentDocumentId;
       
        @AuraEnabled public String addressType;
        @AuraEnabled public String missingparam;
        @AuraEnabled public String applicantProfile;
        @AuraEnabled public String customerType;
        @AuraEnabled public String loanNumber;
        @AuraEnabled public String docName;
        @AuraEnabled public String applicantId;
      
        @AuraEnabled public String missingType;
    }
    @AuraEnabled
    public static List<DocValidationWrapper> validateMandatoryDocuments(String recordId) {
        Map<String,String> inputMap = new Map<String,String>();
        inputMap.put('oppId',recordId);
        Utility_V1.ProductWrapper productWrapper = Utility_V1.getProductDetails(inputMap);
        Boolean isHlRelated = (productWrapper.loanProduct == 'Home Loan'||productWrapper.loanProduct == 'Non Home Loan'||productWrapper.loanProduct == 'Flexi Loan');
        List<DocValidationWrapper> errorList = new List<DocValidationWrapper>();
        List < Application_Applicant__c > applicants = [
            SELECT Id, Loan_Application__c, Customer_Profile__c, Loan_Application__r.Name, Applicant_Type__c,Applicant_Name__c
            FROM Application_Applicant__c
            WHERE Loan_Application__c =: recordId and Applicant_Type__c!='Builder'
        ];
        Set <Id> applicantIds = new Set <Id> ();
        for (Application_Applicant__c app: applicants) {
            applicantIds.add(app.Id);
        }
        
        List < Document_Details__c > documentList = [
            SELECT Id, Name, Applicant__c, Applicant__r.Customer_Profile__c, Is_Uploaded__c,Status__c,Document_Master__r.Document_Type__c, Applicant__r.Customer_Type__c,
            Content_Document_Id__c, Document_Master__r.Name, Applicant__r.Applicant_Name__c, Applicant__r.Sub_Employment_Type_Non_Individual__c, Applicant__r.Applicant_Type__c,
            Loan_Application__r.Name, Applicant__r.Sector__c,Loan_Application__r.PSL__c,Applicant__r.Name
            FROM Document_Details__c
            WHERE(Loan_Application__c =: recordId OR Applicant__c IN: applicantIds) AND Active__c=true AND Consider_for_Loan_Application__c = true
        ];
        Map<String,List<Document_Details__c>> appToDocMap = new Map<String,List<Document_Details__c>>();
        Set<Id> docDetIdSet = new Set<Id>();
        System.debug('documentList KD----'+documentList);
       // System.debug('applicants KD----'+documentList[0].Applicant__c);
        //Added by Kshitiz AHL 24/11
        Set<String> formIdentifiers = new Set<String>(); // Collect all form identifiers (document names) we need config for
        for(Document_Details__c doc : documentList){
           if (doc.Document_Master__r != null && String.isNotBlank(doc.Document_Master__r.Name) && doc.Document_Master__r.Document_Type__c == 'POA' && doc.Status__c == 'Uploaded') {
                formIdentifiers.add(doc.Document_Master__r.Name);
                docDetIdSet.add(doc.Id);
            }
            if(appToDocMap.containsKey(doc.Applicant__c)){
                appToDocMap.get(doc.Applicant__c).add(doc);
            }
            else{
                appToDocMap.put(doc.Applicant__c, new List<Document_Details__c>{doc});
            }
        }
        System.debug('appToDocMap KD1----'+appToDocMap);
        List<Screen_Field__c> screenConfigs = [SELECT Id,Parent_Screen__r.Form_Name__c,Storage_Field__c,Read_Object_Name__c,
                                                Field_Label__c,Is_Mandatory__c FROM Screen_Field__c WHERE Parent_Screen__r.Form_Name__c IN :formIdentifiers
                                                AND Is_Mandatory__c = true AND (Read_Object_Name__c = 'Applicant_Address__c' OR Read_Object_Name__c = 'Application_Applicant__c')];
        // Added by Kshitiz AHL 24/11 Group screen configs: form identifier -> (field api name -> Screen_Fields__c)
        Map<String, Map<String, Screen_Field__c>> formToFieldConfigMap = new Map<String, Map<String, Screen_Field__c>>();
        Map<Id, Set<String>> populatedFieldsByDocDetId = new Map<Id, Set<String>>();
        // Also collect unique Applicant_Address__c field API names we must query
        Set<String> applicantAddressFieldApiNames = new Set<String>();
        Set<String> applicationApplicantFieldApiNames = new Set<String>();
        for (Screen_Field__c cfg : screenConfigs) {
            if (String.isBlank(cfg.Parent_Screen__r.Form_Name__c) || String.isBlank(cfg.Storage_Field__c)) {
            continue;
        }
        if( cfg.Read_Object_Name__c == 'Applicant_Address__c'){
        applicantAddressFieldApiNames.add(cfg.Storage_Field__c);
        }
        else if(cfg.Read_Object_Name__c == 'Application_Applicant__c'){
            // Handle Application_Applicant__c fields if needed
            applicationApplicantFieldApiNames.add(cfg.Storage_Field__c);
        }

        Map<String, Screen_Field__c> fieldMap = formToFieldConfigMap.get(cfg.Parent_Screen__r.Form_Name__c);
        if (fieldMap == null) {
            fieldMap = new Map<String, Screen_Field__c>();
            formToFieldConfigMap.put(cfg.Parent_Screen__r.Form_Name__c, fieldMap);
        }
            fieldMap.put(cfg.Storage_Field__c, cfg);
        }
       
        // 5) Build dynamic SOQL to load Applicant_Address__c with all required fields
        String baseSoql = 'SELECT Id, Document_Details__c';
        for (String fieldName : applicantAddressFieldApiNames) {
            System.debug('fieldName KD----'+fieldName);
            baseSoql += ', ' + fieldName;
        }
        baseSoql += ' FROM Applicant_Address__c WHERE Document_Details__c IN :docDetIdSet';
        String baseSoqlApp = 'SELECT Id, Name';
        for (String fieldName : applicationApplicantFieldApiNames) {
            System.debug('fieldName KD----'+fieldName);
            baseSoqlApp += ', ' + fieldName;
        }
        baseSoqlApp += ' FROM Application_Applicant__c WHERE Loan_Application__c =:recordId';
        List<Applicant_Address__c> addrList = (List<Applicant_Address__c>) Database.query(baseSoql);
        List<Application_Applicant__c> appList = (List<Application_Applicant__c>) Database.query(baseSoqlApp);
        System.debug('addrList KD----'+addrList);
        for(Applicant_Address__c addr : addrList){
            if (addr.Document_Details__c == null) continue;
            Set<String> populated =
            populatedFieldsByDocDetId.get(addr.Document_Details__c);
            if (populated == null) {
                populated = new Set<String>();
                populatedFieldsByDocDetId.put(addr.Document_Details__c, populated);
            }
            for (String fieldName : applicantAddressFieldApiNames) {
          //  Object val = addr.get(fieldName);
           System.debug('fieldName KD 2----'+fieldName);
           if(fieldName == 'Pincode__r.Name'){
                fieldName = 'Pincode__c';
           }
           // Object val = fieldName.contains('.') ? addr.getSObject(fieldName.split('\\.')[0]).get(fieldName.split('\\.')[1]) : addr.get(fieldName);
            Object val = addr.get(fieldName);
            if (val == null) continue;
            String strVal = String.valueOf(val).trim();
            if (!String.isBlank(strVal)) {
                populated.add(fieldName);
            }
        }
    }
    for(Application_Applicant__c app : appList){
            Set<String> populated =
            populatedFieldsByDocDetId.get(app.Id);
            if (populated == null) {
                populated = new Set<String>();
                populatedFieldsByDocDetId.put(app.Id, populated);
            }
            for (String fieldName : applicationApplicantFieldApiNames) {
           System.debug('fieldName KD App----'+fieldName);
           // Object val = fieldName.contains('.') ? addr.getSObject(fieldName.split('\\.')[0]).get(fieldName.split('\\.')[1]) : addr.get(fieldName);
            Object val = app.get(fieldName);
            if (val == null) continue;
            String strVal = String.valueOf(val).trim();
            if (!String.isBlank(strVal)) {
                populated.add(fieldName);
            }
        }
    }
    System.debug('populatedFieldsByDocDetId KD----'+populatedFieldsByDocDetId);
        // 6) Now validate per applicant
        String formId;
        Set<String> populatedForDoc = new Set<String>();
        for(Application_Applicant__c app : applicants){
            Boolean hasPan = false;
            Boolean hasForm60 = false;
            Boolean hasAadharFront = false;
            Boolean hasAadharBack = false;
            Boolean hasphoto = false;
            List<Document_Details__c> docList = appToDocMap.get(app.Id);
            if(docList == null || docList.isEmpty()){
            }
            else{
                for(Document_Details__c d : docList){
                    if (d.Content_Document_Id__c == null || d.Is_Uploaded__c == false) {
                        continue;
                    }
                    if(d.Document_Master__r.Document_Type__c == 'POI' && d.Name == 'PAN' && d.Content_Document_Id__c != null){
                        hasPan = true;
                    }
                    else if(d.Document_Master__r.Document_Type__c == 'POI' && d.Name == 'Form 60' && d.Content_Document_Id__c != null){
                        hasForm60 = true;
                    }
                    if(d.Name == 'Aadhaar Front' && d.Content_Document_Id__c != null){
                        hasAadharFront = true;
                         System.debug('hasAadharBack----'+hasAadharBack);
                    }
                    if(d.Name == 'Aadhaar Back' && d.Content_Document_Id__c != null){
                        hasAadharBack = true;
                        System.debug('hasAadharBack----'+hasAadharBack);
                    }
                    if(d.Name == 'Photograph' && d.Content_Document_Id__c != null){
                        hasphoto = true;
                        System.debug('hasAadharBack----'+hasAadharBack);
                    }
                    formId =(d.Document_Master__r != null) ? d.Document_Master__r.Name : null;
                    System.debug('formId KD----'+formId);   
                    populatedForDoc = populatedFieldsByDocDetId.get(d.Id);
                    System.debug('populatedForDoc KD----'+populatedForDoc);
                    if (populatedForDoc == null) {
                        populatedForDoc = new Set<String>();
                    }
                }
            }
            System.debug('Populated Fields for Doc KD----'+populatedFieldsByDocDetId);
            System.debug('Populated For Doc KD----'+populatedForDoc);
            if(!hasPan && !hasForm60){
                DocValidationWrapper dw = new DocValidationWrapper();
                dw.applicantName = app.Applicant_Name__c;
                dw.applicanttype = app.Applicant_Type__c;
                dw.documentType = 'Pan or Form 60';
                errorList.add(dw);
            }
            System.debug('hasAadharBack----'+hasAadharBack);
            if(!hasAadharBack){
                DocValidationWrapper dw = new DocValidationWrapper();
                dw.applicantName = app.Applicant_Name__c;
                dw.applicanttype = app.Applicant_Type__c;
                dw.documentType = 'Aadhaar Back';
                errorList.add(dw);
            }
            if(!hasAadharFront){
                DocValidationWrapper dw = new DocValidationWrapper();
                dw.applicantName = app.Applicant_Name__c;
                dw.applicanttype = app.Applicant_Type__c;
                dw.documentType = 'Aadhaar Front';
                errorList.add(dw);
            }
            if(!hasphoto){
                DocValidationWrapper dw = new DocValidationWrapper();
                dw.applicantName = app.Applicant_Name__c;
                dw.applicanttype = app.Applicant_Type__c;
                dw.documentType = 'Photograph';
                errorList.add(dw);
            }
            Map<String, Screen_Field__c> fieldCfgMap = new Map<String, Screen_Field__c>();
            if(docList !=null){
            for(Document_Details__c d : docList){
             formId =
             (d.Document_Master__r != null) ? d.Document_Master__r.Name : null;
            System.debug('formId KD 7----'+formId);
            if (String.isBlank(formId)) {
                continue;
            }
            System.debug('formToFieldConfigMap KD----'+formToFieldConfigMap);
            System.debug('formId KD 3----'+formId);
            fieldCfgMap =
                formToFieldConfigMap.get(formId);
                System.debug('fieldCfgMap KD----'+fieldCfgMap);
                if (fieldCfgMap == null || fieldCfgMap.isEmpty()) {
                continue; // no mandatory  address fields configured for this doc/form
                }

        
            System.debug('fieldCfgMap KD final----'+fieldCfgMap);   
            // For Aadhaar Back etc. we simply follow config – no hardcoding
            System.debug('populatedForDocDetId KD final----'+populatedFieldsByDocDetId);
            for (Screen_Field__c cfg : fieldCfgMap.values()) {
            String apiName = cfg.Storage_Field__c;
            if(apiName == 'Pincode__r.Name'){
                apiName = 'Pincode__c';
            }
            if(d.Document_Master__r.Document_Type__c == 'POA'){

                if ((populatedFieldsByDocDetId.containsKey(d.Id) && populatedFieldsByDocDetId.get(d.Id).contains(apiName)) || (populatedFieldsByDocDetId.containsKey(app.Id) && populatedFieldsByDocDetId.get(app.Id).contains(apiName))) {
                continue; // this field is filled in some Applicant_Address__c row
                }

                String label = String.isNotBlank(cfg.Field_Label__c)
                ? cfg.Field_Label__c
                : apiName;

                String msg = label + ' is mandatory for document ' + formId
                + ' but is not filled.';
                DocValidationWrapper dw = new DocValidationWrapper();
                    dw.applicantName = app.Applicant_Name__c;
                    dw.applicanttype = app.Applicant_Type__c;
                    dw.documentType = formId;
                    dw.missingparam = msg;
                errorList.add(
                dw
                );
            }
            }
                System.debug('errorList KD----'+errorList); }
            }
        }
        if(!isHlRelated){
             return errorList;
        }
        else{
           errorList=validateMandatoryDocumentsHL(recordId);
           return errorList;
        }
    

    }
    
     @AuraEnabled
    public static List<MainMissingFieldsWrapper> validateMandatoryFields( String loanId){
        Set<MainMissingFieldsWrapper> mainWrapList= new Set<MainMissingFieldsWrapper>();
        try {
            List<Document_Details__c> validDocs = [Select Id, Name, Applicant__c, Loan_Application__c,Consider_for_Loan_Application__c, Document_Master__c, Document_Master__r.Document_Type__c from Document_Details__c where Loan_Application__c =: loanId and Content_Document_Id__c != null AND Active__c = true 
                                                   AND Document_Master__r.Stage__c ='Sales login' and Consider_for_Loan_Application__c = true];
            List<String> applicantIds = new List<String>();
            List<String> formNameList = new List<String>();
            Map<String,List<String>> docNameToAppIds = new Map<String,List<String>>();
            Map<String,List<Document_Details__c>> appToDocMap = new Map<String,List<Document_Details__c>>();
            for (Document_Details__c doc: validDocs) {
                applicantIds.add(doc.Applicant__c);
                formNameList.add(doc.Name);
                if(docNameToAppIds.containsKey(doc.Name)){
                    docNameToAppIds.get(doc.Name).add(doc.Applicant__c);
                }
                else{
                    docNameToAppIds.put(doc.Name, new List<String>{doc.Applicant__c});
                }
                System.debug('formNameList----'+formNameList);
                if(appToDocMap.containsKey(doc.Applicant__c)){
                    appToDocMap.get(doc.Applicant__c).add(doc);
                }
                else{
                    appToDocMap.put(doc.Applicant__c, new List<Document_Details__c>{doc});
                }
            }

            List < Screen_Field__c > screenFields = [
                SELECT Storage_Object__c, Storage_Field__c, Parent_Screen__r.Form_Name__c, Field_Label__c, is_Lookup__c,Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Visibility_Controlled_By__r.Storage_Field__c, Visibility_Controlled_By__r.Storage_Object__c
                FROM Screen_Field__c
                WHERE Parent_Screen__r.Form_Name__c IN: formNameList AND Storage_Object__c IN ('Application_Applicant__c', 'Applicant_Address__c')
                AND Is_Mandatory__c = true AND Parent_Screen__c != null AND Is_Active__c = true
            ];

            Map<String, Map<String, List<Screen_Field__c>>> formFieldMap = new Map<String, Map<String, List<Screen_Field__c>>>();
            Set<String> applicantFieldNames = new Set<String>();
            Set<String> addressFieldNames = new Set<String>();
            for (Screen_Field__c sf : screenFields) {
                system.debug('screenFields'+ sf.Field_Label__c);
                String form = sf.Parent_Screen__r.Form_Name__c;
                String objectName = sf.Storage_Object__c;
                if (!formFieldMap.containsKey(form)) {
                    formFieldMap.put(form, new Map<String, List<Screen_Field__c>>());
                }
                if (!formFieldMap.get(form).containsKey(objectName)) {
                    formFieldMap.get(form).put(objectName, new List<Screen_Field__c>());
                }
                formFieldMap.get(form).get(objectName).add(sf);

                if(objectName == 'Application_Applicant__c'){
                    applicantFieldNames.add(sf.Storage_Field__c);
                }else  if(objectName == 'Applicant_Address__c'){
                    addressFieldNames.add(sf.Storage_Field__c);
                }
            }
            System.debug('formFieldMap=:'+formFieldMap);

            Set<Screen_Field__c> applicantFields = new Set<Screen_Field__c>();
            Set<Screen_Field__c> addressFields = new Set<Screen_Field__c>();
            Set<Id> uniqueAddressId = new Set<Id>();

            for (Map<String, List<Screen_Field__c>> objMap : formFieldMap.values()) {
                if (objMap.containsKey('Application_Applicant__c')){
                    applicantFields.addAll(objMap.get('Application_Applicant__c'));
                }
                if (objMap.containsKey('Applicant_Address__c')){
                    addressFields.addAll(objMap.get('Applicant_Address__c'));
                }
            }

            List<Applicant_Address__c> allAddresses = [
                SELECT Id, Applicant__c,Applicant__r.Name, Document_Details__r.Name
                FROM Applicant_Address__c
                WHERE Document_Details__c in: validDocs AND Document_Details__r.Document_Master__r.Document_Type__c = 'POA'
            ];

            List<Id> addressIds = new List<Id>();
            Map<String, List<String>> applicantToAddresses= new Map<String, List<String>>();

            Map<String, List<Applicant_Address__c>> docToAddresses = new Map<String, List<Applicant_Address__c>>();
            for (Applicant_Address__c addr : allAddresses) {
                if (!docToAddresses.containsKey(addr.Document_Details__r.Name)) {
                    docToAddresses.put(addr.Document_Details__r.Name, new List<Applicant_Address__c>());
                }
                docToAddresses.get(addr.Document_Details__r.Name).add(addr);

                if (!applicantToAddresses.containsKey(addr.Applicant__c)) {
                    applicantToAddresses.put(addr.Applicant__c, new List<String>());
                }
                applicantToAddresses.get(addr.Applicant__c).add(addr.Id);
                addressIds.add(addr.Id);
            }
            
            

            Map<Id, SObject> addressMap = new Map<Id, SObject>();
            if (!addressIds.isEmpty()) {
                String addressQuery = 'SELECT ' + String.join(new List<String>(addressFieldNames), ',') +
                                    ' FROM Applicant_Address__c WHERE Id IN :addressIds';
                for (SObject addr : Database.query(addressQuery)) {
                    addressMap.put(addr.Id, addr);
                }
            }

            String applicantQuery = 'SELECT Id, Applicant_Name__c, ' + String.join(new List<String>(applicantFieldNames), ',') +
                                ' FROM Application_Applicant__c WHERE Id IN :applicantIds';
            List<SObject> applicantsList = Database.query(applicantQuery);
            Map<Id, SObject> appMap = new Map<Id, SObject>();
            for (SObject app : applicantsList) {
                appMap.put((Id)app.get('Id'), app);
            }

            Set<String> fieldNames = new Set<String>();
            for (Screen_Field__c sf : screenFields) {
                if (sf.Storage_Object__c == 'Application_Applicant__c') {
                    fieldNames.add(sf.Storage_Field__c);
                }
            }

            system.debug('1345'+docNameToAppIds.keySet());
            for (String formName : docNameToAppIds.keySet()) {
                system.debug('1378'+formName);
                system.debug('1379'+formFieldMap.get(formName));
                Map<String, List<Screen_Field__c>> objToFields = formFieldMap.get(formName);
                if (objToFields == null) continue;

                List<Screen_Field__c> applicantFieldList = objToFields.get('Application_Applicant__c');
                List<Screen_Field__c> addressFieldList = objToFields.get('Applicant_Address__c');

                system.debug('1386 '+docNameToAppIds.get(formName));
                for (String appId : docNameToAppIds.get(formName)) {
                    List<String> addresses= applicantToAddresses.containsKey(appId) ? applicantToAddresses.get(appId) : new List<String>();
                    SObject app = appMap.get(appId);
                    if (app == null) continue;
                    String applicantName = (String)app.get('Applicant_Name__c');

                    // Check Application_Applicant__c fields
                    Set<String> missingFieldsList= new Set<String>();
                    if (applicantFieldList != null) {
                        for (Screen_Field__c f : applicantFieldList) {
                            Object val = app.get(f.Storage_Field__c);
                            if(f.Visibility_Controlled_By__c != null){
                                Object controlledData;
                                
                                if(f.Visibility_Controlled_By__r.Storage_Object__c == 'Document_Details__c'){
                                    List<Document_Details__c> docList = appToDocMap.get(appId);
                                    for(Document_Details__c d : docList){
                                        if(d.Name == formName){
                                            System.debug('f.Visibility_Controlled_By__r.Storage_Field__c=:'+f.Visibility_Controlled_By__r.Storage_Field__c);
                                            //controlledData = d.get(f.Visibility_Controlled_By__r.Storage_Field__c);
                                            if(f.Visibility_Controlled_By__r.Storage_Field__c.contains('__r.')){
                                                Object val2 = get(d,String.valueOf(f.Visibility_Controlled_By__r.Storage_Field__c));
                                                String fieldVal = (String) val2;
                                                System.debug(fieldVal);
                                                controlledData = fieldVal;//parenObj.get(String.valueOf(sc.Storage_Field__c).split('\\.')[1]);
                                                if(f.Visibility_Controlled_By__r.Storage_Field__c.contains('__r.')){
                                                    String lookUpfieldValue = d.get(f.Visibility_Controlled_By__r.Storage_Field__c.replaceAll('__r','__c').split('\\.')[0]) != null ? String.valueOf(d.get(f.Visibility_Controlled_By__r.Storage_Field__c.replaceAll('__r','__c').split('\\.')[0])):'';
                                                    // dw.lookupFieldId = sObj.get(sc.Storage_Field__c) != null ? String.valueOf(sObj.get(sc.Storage_Field__c)):'';
                                                }
                                            }
                                            else{
                                                controlledData = d.get(f.Visibility_Controlled_By__r.Storage_Field__c);
                                            }
                                        }
                                    }
                                }
                                else if(f.Visibility_Controlled_By__r.Storage_Object__c == 'Application_Applicant__c'){
                                    controlledData = app.get(f.Visibility_Controlled_By__r.Storage_Field__c);
                                }
                                if(controlledData != null && controlledData == f.Visibility_Controlled_By_Value__c){
                                    if (val == null || String.valueOf(val).trim() == '') {
                                        missingFieldsList.add(f.Field_Label__c);
                                    }
                                }
                            }else{
                                if (val == null || String.valueOf(val).trim() == '') {                            
                                    missingFieldsList.add(f.Field_Label__c);
                                }
                            }
                        }
                    }

                    System.debug('missingFieldsList----- at 1458-'+missingFieldsList);
                    // Check Applicant_Address__c fields
                    system.debug('addressFieldList'+addressFieldList);
                    if (addressFieldList != null && docToAddresses.containsKey(formName)) {
                        for (Applicant_Address__c addr : docToAddresses.get(formName)) {
                            if(addresses.contains(addr.Id)){
                                if(!uniqueAddressId.contains(addr.Id)){
                                        system.debug('1379 --->'+addr.Id);
                                        uniqueAddressId.add(addr.Id);
                                        system.debug('1381 --->'+uniqueAddressId);
                                        SObject fullAddr = addressMap.get(addr.Id);
                                        if (fullAddr == null) continue;
                                        for (Screen_Field__c f : addressFieldList) {
                                            if(f.is_Lookup__c){
                                                Object val = ScreenGenerationController.get(fullAddr,String.valueOf(f.Storage_Field__c));
                                                if (val == null || String.valueOf(val).trim() == '') {
                                                    system.debug('1379 -->'+ missingFieldsList);
                                                    if(f.Field_Label__c != 'Address Type'){
                                                    missingFieldsList.add(f.Field_Label__c);
                                                    }
                                                }
                                            }else {
                                                Object val = fullAddr.get(f.Storage_Field__c);
                                                if (val == null || String.valueOf(val).trim() == '') {
                                                    system.debug('1385 -->'+ missingFieldsList);
                                                    if(f.Field_Label__c != 'Address Type'){
                                                    missingFieldsList.add(f.Field_Label__c);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                   
                    
                    system.debug('final List -->'+ missingFieldsList);
                    if(missingFieldsList.size()>0){
                        MainMissingFieldsWrapper wrapper= new MainMissingFieldsWrapper();
                        wrapper.applicantName = applicantName;
                        wrapper.documentName = formName;
                        wrapper.missingFields = String.join(missingFieldsList, ', ');
                        if(!mainWrapList.contains(wrapper)){
                        mainWrapList.add(wrapper);
                        }
                    }
                }
            }
            System.debug('mainWrapList-----'+mainWrapList);

        } catch (Exception e) {
            // throw new AuraHandledException(e.getMessage());
        }

        List<MainMissingFieldsWrapper> mainList= new List<MainMissingFieldsWrapper>();
        mainList.addAll(mainWrapList);
        return mainList;
    }
    public static Object get(SObject record, String field)
    {
        if (record == null) return null;
        if (!field.contains('.')) return record.get(field);
        return get(
            record.getSObject(field.substringBefore('.')),
            field.substringAfter('.')
        );
    }
     @AuraEnabled
    public static List<String> validateAddresses(String loanId){
        List<String> result= new List<String>();
        Set<Id> docIds = new Set<Id>();
        try {
            List<Document_Details__c> validDocs = [SELECT Id, Name, Applicant__c, Loan_Application__c FROM Document_Details__c WHERE Loan_Application__c =: loanId AND Content_Document_Id__c != null AND Active__c = true 
                                                   AND Document_Master__r.Stage__c ='Sales login'];
                                                
            List<Applicant_Address__c> addrList = [SELECT Id, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Applicant__r.Name, Document_Details__c, Document_Details__r.Name FROM Applicant_Address__c WHERE Document_Details__c IN: validDocs];

            Map<String, Applicant_Address__c> documentToAddressMap= new Map<String, Applicant_Address__c>();
            for(Applicant_Address__c address: addrList){
                if(!docIds.contains(address.Document_Details__c)){
                    docIds.add(address.Document_Details__c);
                    if(address.Address_Line_1__c!=null && address.Address_Line_1__c.length()> 50 || address.Address_Line_2__c!=null &&  address.Address_Line_2__c.length()> 50  || address.Address_Line_3__c!=null &&  address.Address_Line_3__c.length()> 50 ){
                    result.add('For applicant '+address.Applicant__r.Name+' Please check the address for the document '+address.Document_Details__r.Name+'. Address lines 1, 2 and 3 must not have more than 50 characters.');
                    }
                }
            }
        } catch (Exception e) {
            // throw new AuraHandledException(e.getMessage());
            result.add('Error- '+e.getMessage());
        }
        return result;
    }

    @AuraEnabled
    public static List<FilteredDocumentWrapper> validateConsideredDocs(String recordId) {
        List<FilteredDocumentWrapper> out = new List<FilteredDocumentWrapper>();

        // collect applicant ids for the loan (covers applicant-level docs)
        Set<Id> applicantIds = new Set<Id>();
        for (Application_Applicant__c a : [
            SELECT Id
            FROM Application_Applicant__c
            WHERE Loan_Application__c = :recordId
        ]) {
            applicantIds.add(a.Id);
        }

        // find docs that SHOULD be considered for the loan but have no file
        List<Document_Details__c> missing = [
            SELECT Id, Name,
                Applicant__c,
                Applicant__r.Applicant_Name__c,
                Applicant__r.Customer_Type__c,
                Applicant__r.Customer_Profile__c,
                Applicant__r.Applicant_Type__c,
                Document_Master__r.Document_Type__c,
                Content_Document_Id__c,
                Consider_for_Loan_Application__c,
                Active__c
            FROM Document_Details__c
            WHERE Active__c = true
            AND Consider_for_Loan_Application__c = true
            AND (Loan_Application__c = :recordId OR Applicant__c IN :applicantIds)
            AND (Content_Document_Id__c = null OR Content_Document_Id__c = '')
        ];

        for (Document_Details__c d : missing) {
            FilteredDocumentWrapper w = new FilteredDocumentWrapper();
            w.documentDetailId  = d.Id;
            w.documentType      = (d.Document_Master__r != null) ? d.Document_Master__r.Document_Type__c : 'Document';
            w.missingType       = 'Document';
            w.missingparam      = d.Name; // show the exact missing doc name in the modal
            if (d.Applicant__c != null) {
                w.applicantName    = d.Applicant__r.Applicant_Name__c;
                w.customerType     = d.Applicant__r.Customer_Type__c;
                w.applicantProfile = d.Applicant__r.Customer_Profile__c;
                w.applicanttype    = d.Applicant__r.Applicant_Type__c;
            } else {
                // loan-level doc
                w.applicantName    = 'Loan Level';
                w.customerType     = '-';
                w.applicantProfile = '-';
                w.applicanttype    = '-';
            }
            out.add(w);
        }
        return out;
    }

    
    public class FilteredDocumentWrapper {
        @AuraEnabled public Id documentDetailId;
        @AuraEnabled public String documentType;
        @AuraEnabled public Id contentDocumentId;
        @AuraEnabled public String applicantName;
        @AuraEnabled public String addressType;
        @AuraEnabled public String missingparam;
        @AuraEnabled public String applicantProfile;
        @AuraEnabled public String customerType;
        @AuraEnabled public String loanNumber;
        @AuraEnabled public String docName;
        @AuraEnabled public String applicantId;
        @AuraEnabled public String applicanttype;
        @AuraEnabled public String missingType;
        
    }
    public class MainMissingFieldsWrapper{
        @AuraEnabled public String applicantName;
        @AuraEnabled public String documentName;
        @AuraEnabled public String missingFields;
    }
    @AuraEnabled
    public static List<AddressWrapper> checkAddressType(String loanId){
        List<AddressWrapper> errorList = new List<AddressWrapper>();
        List<Application_Applicant__c> appList = [Select Id, Customer_Type__c, Applicant_Name__c from Application_Applicant__c where Loan_Application__c =: loanId and Applicant_Type__c != 'Builder'];
        List<Applicant_Address__c> addrList = [SELECT Id, Address_Type__c,Address_Priority__c,Applicant__c, Applicant__r.Applicant_Name__c from Applicant_Address__c where Applicant__c in: appList];
        Map<Id, List<Applicant_Address__c>> appToAddrMap = new Map<Id, List<Applicant_Address__c>>();
        for(Applicant_Address__c addr : addrList){
            if(appToAddrMap.containsKey(addr.Applicant__c)){
                appToAddrMap.get(addr.Applicant__c).add(addr);
            }
            else{
                appToAddrMap.put(addr.Applicant__c, new List<Applicant_Address__c>{addr});
            }
        }
        for(Application_Applicant__c ap : appList){
            if(ap.Customer_Type__c == 'Individual'){
                if(appToAddrMap.containsKey(ap.Id)){
                    Integer countPerm = 0;
                    Integer countCurr = 0;
                    Integer highAdd =0;
                    Integer verHighAdd =0;
                    List<Applicant_Address__c> addresses = appToAddrMap.get(ap.Id);
                    for(Applicant_Address__c ad : addresses){
                        if(ad.Address_Type__c == 'Permanent'){
                            countPerm++;
                        }
                        else if(ad.Address_Type__c == 'Current'){
                            countCurr++;
                        }
                        if(ad.Address_Priority__c =='4'){
                            highAdd++;
                        }
                         if(ad.Address_Priority__c =='5'){
                            verHighAdd++;
                        }
                    }
                    if(countPerm == 0){
                        AddressWrapper adw = new AddressWrapper();
                        adw.errorMsg = 'Please add Permanent address for '+ ap.Applicant_Name__c;
                        errorList.add(adw);
                    }
                    if(countCurr == 0){
                        AddressWrapper adw = new AddressWrapper();
                        adw.errorMsg = 'Please add Current address for '+ ap.Applicant_Name__c;
                        errorList.add(adw);
                    }
                    if(highAdd==0){
                         AddressWrapper adw = new AddressWrapper();
                        adw.errorMsg = 'Please add Permanent address with high priority for '+ ap.Applicant_Name__c;
                        errorList.add(adw);
                    }
                     if(verHighAdd==0){
                         AddressWrapper adw = new AddressWrapper();
                        adw.errorMsg = 'Please add Current address with very high priority for '+ ap.Applicant_Name__c;
                        errorList.add(adw);
                    }
                }
                else{
                    AddressWrapper adw = new AddressWrapper();
                    adw.errorMsg = 'Please add Current and Permanent address for '+ ap.Applicant_Name__c;
                    errorList.add(adw);
                }
            }
            else{
                if(appToAddrMap.containsKey(ap.Id)){
                    Integer countBusiness = 0;
                    Integer countOper = 0;
                    Integer highAdd =0;
                    Integer verHighAdd =0;
                    List<Applicant_Address__c> addresses = appToAddrMap.get(ap.Id);
                    for(Applicant_Address__c ad : addresses){
                        if(ad.Address_Type__c == 'Registered Office'){
                            countBusiness++;
                        }
                        else if(ad.Address_Type__c == 'Business operational'){
                            countOper++;
                        }
                        if(ad.Address_Priority__c =='5'){
                            verHighAdd++;
                        }
                         if(ad.Address_Priority__c =='2'){
                            highAdd++;
                        }
                    }
                    if(countBusiness == 0){
                        AddressWrapper adw = new AddressWrapper();
                        adw.errorMsg = 'Please add registered business address for '+ ap.Applicant_Name__c;
                        errorList.add(adw);
                    }
                    if(countOper == 0){
                        AddressWrapper adw = new AddressWrapper();
                        adw.errorMsg = 'Please add business operational address for '+ ap.Applicant_Name__c;
                        errorList.add(adw);
                    }
                    if(verHighAdd==0){
                         AddressWrapper adw = new AddressWrapper();
                        adw.errorMsg = 'Please add registered address with very high priority for '+ ap.Applicant_Name__c;
                        errorList.add(adw);
                    }
                     if(highAdd==0){
                         AddressWrapper adw = new AddressWrapper();
                        adw.errorMsg = 'Please add business operational address with high priority for '+ ap.Applicant_Name__c;
                        errorList.add(adw);
                    }
                }
                else{
                    AddressWrapper adw = new AddressWrapper();
                    adw.errorMsg = 'Please add registered business and business operational address for '+ ap.Applicant_Name__c;
                    errorList.add(adw);
                }
            }
        }
        return errorList;
    }
    public class AddressWrapper{
        @AuraEnabled public String errorMsg;
    }
    
    @AuraEnabled
    public static void deleteWithoutAddressTypeDoc(String recordId){
        try {
            Set<Id> addressIdsToDelete = new Set<Id>();
            List<Applicant_Address__c> addressTobeDelete = new List<Applicant_Address__c>();
            List<Applicant_Address__c> addressList = [SELECT Id,Address_Type__c,Applicant__c,Document_Details__r.Name,Document_Details__r.Document_Details__c
            FROM Applicant_Address__c WHERE Applicant__r.Loan_Application__c =:recordId AND Document_Details__c!=null ORDER BY Applicant__c];
            Map<String, Applicant_Address__c> addressMap = new Map<String, Applicant_Address__c>();

            for (Applicant_Address__c address : addressList) {
                String key = address.Applicant__c + '-' + address.Document_Details__r.Name + '-' + address.Document_Details__r.Document_Details__c;
                if(address.Address_Type__c == null){
                    if (addressMap.containsKey(key)) {
                        if (!addressIdsToDelete.contains(address.Id)) {
                            addressTobeDelete.add(address);
                            addressIdsToDelete.add(address.Id);
                        }
                    } else {
                        addressMap.put(key, address);
                    }
                } else {
                    if (addressMap.containsKey(key) && String.isBlank(addressMap.get(key).Address_Type__c)) {
                        Applicant_Address__c oldAddress = addressMap.get(key);
                        if (!addressIdsToDelete.contains(oldAddress.Id)) {
                            addressTobeDelete.add(oldAddress);
                            addressIdsToDelete.add(oldAddress.Id);
                        }
                    }else{
                        addressMap.put(key, address);
                    }
                }
            }
            system.debug('addressTobeDelete'+addressTobeDelete);
            if(addressTobeDelete.size()>0){
                delete addressTobeDelete;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
      @AuraEnabled
    public static List<AddressWrapper> validateOVDDocuments (String recordId){
        List<AddressWrapper> errorList = new List<AddressWrapper>();
        List<AddressWrapper> dummyerrorList = new List<AddressWrapper>();

        Boolean hasFlexiLoan       = false;
        Boolean hasNonFlexiProduct = false;
        Boolean noCollateralAdded = false;
         Map<String,String> inputMap = new Map<String,String>();
        inputMap.put('oppId',recordId);
        Utility_V1.ProductWrapper productWrapper = Utility_V1.getProductDetails(inputMap);
        Boolean isHlRelated = (productWrapper.loanProduct == 'Home Loan'||productWrapper.loanProduct == 'Non Home Loan'||productWrapper.loanProduct == 'Flexi Loan');
        List<Product2> prodList = [Select id,Name,Product_Type__c from Product2 where Loan_Application__c=:recordId and Recordtype.Name='Product' and Product_Type__c!='Parent'];
        for(Product2 productDetailsList : prodList){
            if(productDetailsList.Name=='Flexi Loan'){
                hasFlexiLoan = true;
                
            }
            else{
                hasNonFlexiProduct = true;
            }
        }
        if(hasFlexiLoan){
            List<Application_Collateral__c> appCollList = [Select id,Collateral__c from Application_Collateral__c where HL_Loan_Application__c =:recordId];
            if(appCollList.size()==0){
               noCollateralAdded = true;
               
            }
       
        }
        List<Application_Applicant__c> appList = [Select Id, Customer_Type__c,Sector__c,Industry__c,Sub_Employment_Type_Non_Individual__c,Applicant_Name__c,Customer_Profile__c, Loan_Application__r.Dsa_Area_Manager__c, Loan_Application__r.Sourcing_Manager__c from Application_Applicant__c where Loan_Application__c =: recordId AND Applicant_Type__c != 'Seller' AND Applicant_Type__c != 'Builder'];
        List<Document_Details__c> docChecklist = [SELECT Id,Name,Content_Document_Id__c,Applicant__c from Document_Details__c where Applicant__c in: appList];
        Map<Id, List<Document_Details__c>> docMap = new Map<Id, List<Document_Details__c>>();
        List<Applicant_Address__c> addressList= [SELECT Id, Address_Type__c, Applicant__c FROM Applicant_Address__c WHERE Applicant__r.Loan_Application__c = :recordId AND Address_Type__c = 'Registered Office'];
        
        Set<String> appAddIds= new Set<String>();
        for(Applicant_Address__c addr : addressList){
            appAddIds.add(addr.Applicant__c);
        }
        if(!isHlRelated){
if(appList.size() > 0){
                if(appList[0].Loan_Application__r.Dsa_Area_Manager__c == null ) {
                AddressWrapper adw = new AddressWrapper();
                adw.errorMsg = 'Please fill Relationship Manager/Area Manager.';
                errorList.add(adw);
                }
            }
        }
            
        
        Map<String,String> errorMap = new Map<String,String>{'Sector__c'=>'Sector',
            'Industry__c'=>'Industry'};
        for(Document_Details__c doc : docChecklist){
            if(docMap.containsKey(doc.Applicant__c)){
                docMap.get(doc.Applicant__c).add(doc);
            }
            else{
                docMap.put(doc.Applicant__c, new List<Document_Details__c>{doc});
            }
        }
        for(Application_Applicant__c ap : appList){
            Integer countForm60 = 0;
            Integer countOVD = 0;
            Integer industryCount = 0;
            List<Document_Details__c> docs = new List<Document_Details__c>();
            if(docMap.containsKey(ap.id)){
                docs =docMap.get(ap.Id);
            }
             for(Document_Details__c doc : docs){
                if(((doc.Name =='Voter Back'||doc.Name == 'Voter Front') && doc.Content_Document_Id__c != null)||((doc.Name =='Passport Front' || doc.Name == 'Passport Back') && doc.Content_Document_Id__c != null)||
                            (doc.Name =='Driving licence' && doc.Content_Document_Id__c != null)){
                            countOVD++;
                }
                if((doc.Name == 'Form 60'||doc.Name == 'Form-60') && doc.Content_Document_Id__c != null){
                       countForm60++;
                }
                
             }

                if(countForm60 >= 1 && countOVD==0 ){
                    AddressWrapper adw = new AddressWrapper();
                    adw.errorMsg = 'Please add at least one OVD  for '+ ap.Applicant_Name__c;
                    errorList.add(adw);
                }
                if(ap.Customer_Type__c=='Non Individual'){
                    if(String.isBlank(ap.Industry__c)){
                        AddressWrapper adw = new AddressWrapper();
                        adw.errorMsg = 'Please select Industry' +' for '+ ap.Applicant_Name__c;
                        errorList.add(adw);
                    }
                }
                else{
                    if(String.isBlank(ap.Sector__c)){
                        AddressWrapper adw = new AddressWrapper();
                        adw.errorMsg = 'Please select Sector' +' for '+ ap.Applicant_Name__c;
                        errorList.add(adw);
                    }
                    if(String.isBlank(ap.Sub_Employment_Type_Non_Individual__c)){
                        AddressWrapper adw = new AddressWrapper();
                        adw.errorMsg = 'Please select segment' +' for '+ ap.Applicant_Name__c;
                        errorList.add(adw);
                    }
                }

                if( isHlRelated && (ap.Customer_Profile__c == 'Salaried Indian' || ap.Customer_Profile__c == 'Salaried NRI')){
                    if(appAddIds.size() == 0 || !appAddIds.contains(ap.Id)){
                        AddressWrapper adw = new AddressWrapper();
                        adw.errorMsg = 'Please add registered office' +' for '+ ap.Applicant_Name__c;
                        errorList.add(adw);
                    }
                }
                
                // for(String fieldApi : errorMap.keySet()){
                //     if(ap.get(fieldApi) == null || ap.get(fieldApi) == ''){
                //         AddressWrapper adw = new AddressWrapper();
                //         adw.errorMsg = 'Please select '+ errorMap.get(fieldApi) +' for '+ ap.Applicant_Name__c;
                //         errorList.add(adw);
                //     }
                // }
               
             /* if(ap.Sector__c == null || ap.Sector__c == ''){
                    AddressWrapper adw = new AddressWrapper();
                    adw.errorMsg = 'Please select Sector for '+ ap.Applicant_Name__c;
                    errorList.add(adw);
                }
                if(ap.Industry__c == null || ap.Industry__c == ''){
                    AddressWrapper adw = new AddressWrapper();
                    adw.errorMsg = 'Please select Industry for '+ ap.Applicant_Name__c;
                    errorList.add(adw);
            }*/
            // else{
            //     AddressWrapper adw = new AddressWrapper();
            //     adw.errorMsg = 'Please add Current and Permanent address for '+ ap.Applicant_Name__c;
            //     errorList.add(adw);
            // }
        }
        if(noCollateralAdded){
            AddressWrapper adw = new AddressWrapper();
            adw.errorMsg = 'Please ensure that at least one collateral is added whenever a Flexi Loan is selected as a secondary product on the loan application.';
            errorList.add(adw);
        }
        //return errorList;
        return dummyerrorList;
    } 

     
    @AuraEnabled
    public static List<MainMissingFieldsWrapper> checkRelatedAddress(string recordId){
        List<MainMissingFieldsWrapper> wrapList = new List<MainMissingFieldsWrapper>();
        List < Application_Applicant__c > applicants = [SELECT Id, Loan_Application__c, Customer_Profile__c, Loan_Application__r.Name FROM Application_Applicant__c WHERE Loan_Application__c =: recordId];
        Set <Id> applicantIds = new Set <Id> ();
        for (Application_Applicant__c app: applicants) {
            applicantIds.add(app.Id);
        }
            
        List < Document_Details__c > documentList = [
            SELECT Id, Name,Applicant__r.Name, Applicant__c, Applicant__r.Customer_Profile__c, Document_Master__r.Document_Type__c, Applicant__r.Customer_Type__c,
            Content_Document_Id__c, Document_Master__r.Name, Applicant__r.Applicant_Name__c, Applicant__r.Sub_Employment_Type_Non_Individual__c, Applicant__r.Applicant_Type__c,
            Loan_Application__r.Name, Applicant__r.Sector__c,Applicant__r.PSL__c,Document_Details__c
            FROM Document_Details__c WHERE Applicant__c IN: applicantIds AND Active__c = true AND Consider_for_Loan_Application__c = true AND Content_Document_Id__c != null AND Document_Master__r.Stage__c ='Sales login' ORDER By  Applicant__r.Applicant_Type__c,Applicant__r.Applicant_Name__c
        ];
        List<Applicant_Address__c> addrList = [SELECT Id, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Applicant__r.Name, Document_Details__c, Document_Details__r.Name FROM Applicant_Address__c WHERE Document_Details__c IN: documentList];
        Map<String, List<Applicant_Address__c>> documentToAddressMap= new Map<String, List<Applicant_Address__c>>();

        for(Applicant_Address__c addr: addrList){
            if(documentToAddressMap.containsKey(addr.Document_Details__c)){
                documentToAddressMap.get(addr.Document_Details__c).add(addr);
            }
            else{
                documentToAddressMap.put(addr.Document_Details__c, new List<Applicant_Address__c>{addr});
            }
        }
         System.debug('documentList-----'+documentList);
         System.debug('documentToAddressMap-----'+documentToAddressMap);
        for(Document_Details__c doc : documentList){
            String customerProfile = '%'+doc.Applicant__r.Customer_Profile__c+'%';
            String segment = '%'+doc.Applicant__r.Sub_Employment_Type_Non_Individual__c+'%';
            System.debug('segment-----'+segment);
             System.debug('customerProfile-----'+customerProfile);
            List<Document_with_required_address__mdt> metadataList = [SELECT Id,Document_Name__c,Document_Category__c,Customer_Type__c,Customer_Profile__c,Constitution__c FROM Document_with_required_address__mdt 
            WHERE Document_Name__c =: doc.Document_Master__r.Name AND Document_Category__c =: doc.Document_Details__c AND Customer_Type__c =: doc.Applicant__r.Customer_Type__c AND Customer_Profile__c like: customerProfile AND Constitution__c like:segment LIMIT 1];
            System.debug('metadataList-----'+metadataList);
            if(!metadataList.isEmpty()){
                 System.debug('documentToAddressMap-----'+documentToAddressMap.keySet());
                    System.debug('documentList-----'+doc.Id);
                if(!documentToAddressMap.containsKey(doc.Id)){
                    System.debug('documentToAddressMap-----'+documentToAddressMap);
                    System.debug('documentList-----'+doc.Id);
                    MainMissingFieldsWrapper wrap = new MainMissingFieldsWrapper();
                    wrap.applicantName = doc.Applicant__r.Name;
                    wrap.documentName = doc.Document_Master__r.Name;
                    wrap.missingFields = 'Address';
                    wrapList.add(wrap);
                }
            }
        }
        return wrapList;
    }


     @AuraEnabled
    public static List<DocValidationWrapper> validateMandatoryDocumentsHL(String recordId) {
        // List<DocValidationWrapper> errorList = new List<DocValidationWrapper>();
        List < Application_Applicant__c > applicants = [
            SELECT Id, Loan_Application__c, Customer_Profile__c, Loan_Application__r.Name, Applicant_Type__c,Applicant_Name__c
            FROM Application_Applicant__c
            WHERE Loan_Application__c =: recordId AND Applicant_Type__c!='Builder'
        ];
        Set <Id> applicantIds = new Set <Id> ();
        for (Application_Applicant__c app: applicants) {
            applicantIds.add(app.Id);
        }
        
        List < Document_Details__c > documentList = [
            SELECT Id, Name, Applicant__c, Applicant__r.Customer_Profile__c, Document_Master__r.Document_Type__c, Applicant__r.Customer_Type__c,
            Content_Document_Id__c, Document_Master__r.Name, Applicant__r.Applicant_Name__c, Applicant__r.Sub_Employment_Type_Non_Individual__c, Applicant__r.Applicant_Type__c,
            Loan_Application__r.Name, Applicant__r.Sector__c,Loan_Application__r.PSL__c,Applicant__r.Name,Document_Master__r.Document_Name__c
            FROM Document_Details__c
            WHERE(Loan_Application__c =: recordId OR Applicant__c IN: applicantIds) AND Active__c=true
        ];
        Map<String,List<Document_Details__c>> applicantToDocMap = new Map<String,List<Document_Details__c>>();
        
        for(Document_Details__c doc : documentList){
            if(applicantToDocMap.containsKey(doc.Applicant__c)){
                applicantToDocMap.get(doc.Applicant__c).add(doc);
            }
            else{
                applicantToDocMap.put(doc.Applicant__c, new List<Document_Details__c>{doc});
            }
        }
        List < DocValidationWrapper > result = new List < DocValidationWrapper > ();
        List < String > uniqueDocCategory = new List < String > ();
        Map <String,String> docToSourceMap = new Map <String,String> ();
        docToSourceMap.put('Aadhaar Front', 'Aadhaar');
        docToSourceMap.put('Aadhaar Back', 'Aadhaar');
        docToSourceMap.put('Passport', 'Passport');
        docToSourceMap.put('DL', 'Driving License');
        docToSourceMap.put('Voter id', 'Voter Id');
        docToSourceMap.put('Letter issued by national population register', 'National Population Register');
        docToSourceMap.put('Registered Rent Agreement', 'Registered Rent');
        docToSourceMap.put('Notarized rent agreement with utility bill', 'Notarized Rent');
        docToSourceMap.put('Utility Bill not more than 2 months old', 'Utility Bill');

        Map <Id,List<Applicant_Address__c>> addressMapPerm = new Map <Id,List<Applicant_Address__c>> ();
        Map <Id,List<Applicant_Address__c>> addressMapCurr = new Map <Id, List< Applicant_Address__c>> ();
        Map <Id,List<Applicant_Address__c>> addressMapPermWithPr = new Map <Id,List<Applicant_Address__c>> ();
        Map <Id,List<Applicant_Address__c>> addressMapCurrWithPr = new Map <Id, List< Applicant_Address__c>> ();
        Map <Id,List<Applicant_Address__c>> addressMapOffice = new Map <Id,List< Applicant_Address__c>> ();
        Map <Id,List<Applicant_Address__c>> addressMapOfficeWithPr = new Map <Id,List< Applicant_Address__c>> ();
        Map <Id,List<Applicant_Address__c>> addressMapClinic = new Map <Id,List<Applicant_Address__c>> ();
        Map <Id,List<Applicant_Address__c>> addressMapReg = new Map <Id,List<Applicant_Address__c>> ();
        Map <Id,List<Applicant_Address__c>> addressMapRegWithPr = new Map <Id,List<Applicant_Address__c>> ();
        Map <Id,List<Applicant_Address__c>> addressMapOther = new Map <Id,List<Applicant_Address__c>> ();
        Map <Id,List<Applicant_Address__c>> addressMapFatory = new Map <Id,List <Applicant_Address__c>> ();
        Map <Id,List<Applicant_Address__c>> addressMapGodown = new Map <Id,List <Applicant_Address__c>> ();
        Map <Id,List <Applicant_Address__c>> addressMapOwned = new Map <Id,List <Applicant_Address__c>> ();

        //Salaried Indian
        Set<String> salariedIndianSVPOneReq = new Set<String>{'Bankers Verification Document', 'PAN', 'Passport Front', 'IPF Cheque Clearance'};
        Set<String> salariedIndianIncomeOneReq = new Set<String>{'Salary Certificate on letter head', 'Salary Slip - 1'};

        //Salaried NRI
        Set<String> salariedNRIPOIAnyoneReq= new Set<String>{'Overseas Citizen Card/ Person of Indian Origin Card', 'VISA Copy'};
        Set<String> salariedNRIPOAAnyoneReq= new Set<String>{'Document issued by Government Department of Foreign Jurisdiction', 'Letter Issued by Foreign Embassy or Mission in India', 'Certificate from Statutory Authority of foreign country','Registered Rent Agreement','Utility bill less than 2 months old','Company letter of Accomodation'};
        Set<String> salariedNRIEmploymentProofanyoneReq= new Set<String>{'Proof of Employment','Contract Copy or Appointment Letter','Overseas Credit Bureau Report'};
        Set<String> salariedNRIIncomeProofanyoneReq= new Set<String>{'Salary Slip - 1'};

        //SENP
        Set<String> senpProprietorshipPoBanytwo= new Set<String>{'Registration Certificate','Udhyam registration certificate','Certificate of license issued by professional body','Income tax return','GST Certificate'};
        Set<String> senplimitedPoBanyone= new Set<String>{'Certificate of Incorporation','Memorandum of Association','Articles of Association','Resolution of board of directors','Shareholding Pattern'};
        Set<String> senppartnershipPoBanyone= new Set<String>{'COI','Certificate of license issued by professional body','GST Certificate','Partnership Deed (Registered or Notarized)'};
        Set<String> senpHUFPoBanyone=new Set<String>{'HUF Deed','CA certified ITR with UDIN','CA certified list of co-parceners with UDIN'};

        for (Applicant_Address__c addr: [
                SELECT Id, Applicant__c, Address_Type__c, Address_Source__c, Document_Details__c,Flag_PO_as_High__c,Flag_Current_Registred_as_Very_High__c
                FROM Applicant_Address__c
                WHERE Applicant__c IN: applicantIds
                AND Address_Type__c IN('Permanent', 'Current','Owned')
                AND(Document_Details__c != null)
            ]) 
        {
            System.debug('addr.Address_Type__c  218'+ addr.Address_Type__c );
            if (addr.Address_Type__c == 'Permanent') {
                if (!addressMapPerm.containsKey(addr.Applicant__c)) {
                    addressMapPerm.put(addr.Applicant__c, new List < Applicant_Address__c > ());
                }
                addressMapPerm.get(addr.Applicant__c).add(addr);
            } else if (addr.Address_Type__c == 'Current') {
                if (!addressMapCurr.containsKey(addr.Applicant__c)) {
                    addressMapCurr.put(addr.Applicant__c, new List < Applicant_Address__c > ());
                }
                addressMapCurr.get(addr.Applicant__c).add(addr);
            }
            if (addr.Address_Type__c == 'Permanent' && addr.Flag_PO_as_High__c == true) {
                if (!addressMapPermWithPr.containsKey(addr.Applicant__c)) {
                    addressMapPermWithPr.put(addr.Applicant__c, new List < Applicant_Address__c > ());
                }
                addressMapPermWithPr.get(addr.Applicant__c).add(addr);
            } else if (addr.Address_Type__c == 'Current' && addr.Flag_Current_Registred_as_Very_High__c == true) {
                if (!addressMapCurrWithPr.containsKey(addr.Applicant__c)) {
                    addressMapCurrWithPr.put(addr.Applicant__c, new List < Applicant_Address__c > ());
                }
                addressMapCurrWithPr.get(addr.Applicant__c).add(addr);
            }
        }
        for (Applicant_Address__c addr: [
                SELECT Id, Applicant__c, Address_Type__c, Address_Source__c, Document_Details__c,Flag_PO_as_High__c,Flag_Current_Registred_as_Very_High__c
                FROM Applicant_Address__c
                WHERE Applicant__c IN: applicantIds
                AND Address_Type__c IN('Business Operational','Registered Office')
                /*AND Address_Source__c in: docToSourceMap.values()*/
                AND(Document_Details__c != null)
            ]) {
                
                if (addr.Address_Type__c == 'Business Operational') {
                    if (!addressMapOffice.containsKey(addr.Applicant__c)) {
                        addressMapOffice.put(addr.Applicant__c, new List < Applicant_Address__c > ());
                    }
                    addressMapOffice.get(addr.Applicant__c).add(addr);
                }
                if (addr.Address_Type__c == 'Business Operational' && addr.Flag_PO_as_High__c == true) {
                    if (!addressMapOfficeWithPr.containsKey(addr.Applicant__c)) {
                        addressMapOfficeWithPr.put(addr.Applicant__c, new List < Applicant_Address__c > ());
                    }
                    addressMapOfficeWithPr.get(addr.Applicant__c).add(addr);
                }
                if (addr.Address_Type__c == 'Registered Office') {
                    if (!addressMapReg.containsKey(addr.Applicant__c)) {
                        addressMapReg.put(addr.Applicant__c, new List < Applicant_Address__c > ());
                    }
                    addressMapReg.get(addr.Applicant__c).add(addr);
                } 
                if (addr.Address_Type__c == 'Registered Office' && addr.Flag_Current_Registred_as_Very_High__c == true) {
                    if (!addressMapRegWithPr.containsKey(addr.Applicant__c)) {
                        addressMapRegWithPr.put(addr.Applicant__c, new List < Applicant_Address__c > ());
                    }
                    addressMapRegWithPr.get(addr.Applicant__c).add(addr);
                }
            }
        for(String appId : applicantToDocMap.keySet()){
            Boolean hasPan = false;
            Boolean hasForm60 = false;
            Boolean hasAadharFront = false;
            Boolean hasAadharBack = false;
            Boolean hasphoto = false;
            String docType='';
            String appName;
            String customerType;
            String customerCategory;
            String customerProfile;
            String applicantType;
            String documentName;
            Boolean form60valid=false;
            Boolean bankStatementPresent= false;
            //Salaried Indian
            Integer salariedIndianSVPCount=0;
            Integer salariedIndianIncomeCount=0;
            //Salaried Indian
            //Salaried NRI
            Integer salariedNriPOICount=0;
            Integer salariedNriPOACount=0;
            Integer salariedNriIncomeCount=0;
            Integer salariedNriEmploymentCount=0;
            //Salaried NRI
            //SENP
            Integer senpProprietorPoBCount=0;
            Integer senpLimitedPoBCount=0;
            Integer senpPartnerPoBCount=0;
            Integer senpHUFPoBCount=0;
            //SENP
            Boolean isSameAsPrimaryPresent = false;
            Boolean hasOthersDoc = false;
            Boolean isCoApplicant = false;
            List<Document_Details__c> docList = applicantToDocMap.get(appId);
            if(!docList.isEmpty()){
                isCoApplicant = docList[0].Applicant__r.Applicant_Type__c == 'Co Applicant';
            }
            if(isCoApplicant){
                isSameAsPrimaryPresent = [SELECT COUNT() FROM Applicant_Address__c WHERE Applicant__c = :appId AND Same_As_Primary_Applicant__c = true AND Document_Details__r.Document_Master__r.Document_Category__c = 'POA'] > 0;
            }
            for (Document_Details__c doc: docList){
                docType = doc.Document_Master__r.Document_Type__c;
                appName = doc.Applicant__r.Applicant_Name__c;
                customerType = doc.Applicant__r.Customer_Type__c;
                customerCategory = doc.Applicant__r.Customer_Profile__c;
                customerProfile = doc.Applicant__r.Sub_Employment_Type_Non_Individual__c;
                applicantType= doc.Applicant__r.Applicant_Type__c;
                documentName= doc.Name;
                if(doc.Document_Master__r.Document_Type__c == 'Others' &&doc.Document_Master__r.Document_Name__c != null && doc.Content_Document_Id__c != null && doc.Document_Master__r.Name.startsWith('Additional Document')){
                    hasOthersDoc = true;
                }
                if((documentName== 'Bank Statement' || documentName== '12 months bank statement' || documentName == '12 months bank statement-PDF') && doc.Content_Document_Id__c != null){
                    bankStatementPresent= true;
                }
                if (doc.Document_Master__r != null && doc.Document_Master__r.Document_Type__c != null && doc.Applicant__c != null){
                    String custProfile = doc.Applicant__r.Customer_Profile__c;
                    String custSector = doc.Applicant__r.Sub_Employment_Type_Non_Individual__c;
                    String custSegment = doc.Applicant__r.Sector__c;
                    if (documentName.equalsIgnoreCase('PAN') && !String.isBlank(doc.Content_Document_Id__c)){}    hasPAN = true;
                    if (documentName.equalsIgnoreCase('Form-60') && !String.isBlank(doc.Content_Document_Id__c)) hasForm60 = true;
                    if(documentName == 'Aadhaar Front' && doc.Content_Document_Id__c != null){
                        hasAadharFront = true;
                        System.debug('hasAadharBack----'+hasAadharBack);
                    }
                    if(documentName == 'Aadhaar Back' && doc.Content_Document_Id__c != null){
                        hasAadharBack = true;
                        System.debug('hasAadharBack----'+hasAadharBack);
                    }
                    if((documentName== 'Bank Statement' || documentName== '12 months bank statement' || documentName == '12 months bank statement-PDF') && doc.Content_Document_Id__c != null){
                        bankStatementPresent= true;
                    }
                    //common
                    if((customerCategory == 'SEP' || customerCategory == 'Salaried Indian' || customerCategory == 'SENP')){
                        if(!hasPAN && !hasForm60){
                            DocValidationWrapper wrapper = new DocValidationWrapper();
                            wrapper.documentType = docType;
                            wrapper.applicantName = doc.Applicant__r.Applicant_Name__c;
                            wrapper.applicanttype  =applicantType;
                            wrapper.missingparam = 'PAN or Form 60';
                            wrapper.missingType ='Document';
                            wrapper.applicantProfile = customerCategory;
                            wrapper.customerType = customerType;
                            result.add(wrapper); 
                        }
                        if(!hasPAN && hasForm60){
                            if(((doc.Name =='Voter Back'||doc.Name == 'Voter Front') && doc.Content_Document_Id__c != null)||((doc.Name =='Passport Front' || doc.Name == 'Passport Back') && doc.Content_Document_Id__c != null)||
                            (doc.Name =='Driving licence' && doc.Content_Document_Id__c != null)){
                                form60valid= true;
                            }
                        }
                        if(hasPAN && (customerCategory == 'SEP' || customerCategory == 'Salaried Indian')){
                            salariedIndianSVPCount= salariedIndianSVPCount+1;
                        }
                        
                    }
                    if (docType == 'POA'&& customerType == 'Individual' && (customerCategory == 'SEP' || customerCategory == 'Salaried Indian' || customerCategory == 'SENP')){
                        if (!addressMapCurr.containsKey(doc.Applicant__c)|| !addressMapCurrWithPr.containsKey(doc.Applicant__c)) {
                            DocValidationWrapper wrapper = new DocValidationWrapper();
                            wrapper.documentType = docType;
                            wrapper.applicantName = doc.Applicant__r.Applicant_Name__c;
                            wrapper.addressType = 'Current';
                            wrapper.missingparam = 'Current Address with very high priority';
                            wrapper.missingType ='Address';
                            wrapper.applicantProfile = customerCategory;
                            wrapper.applicanttype  =applicantType;
                            wrapper.customerType = customerType;
                            String uniqueKey = docType + doc.Applicant__r.Applicant_Name__c+wrapper.missingparam;
                            if (!uniqueDocCategory.contains(uniqueKey)) {
                                uniqueDocCategory.add(uniqueKey);
                                result.add(wrapper);
                            }
                        }
                        if (!addressMapPerm.containsKey(doc.Applicant__c) || !addressMapPermWithPr.containsKey(doc.Applicant__c)) {
                            DocValidationWrapper wrapper = new DocValidationWrapper();
                            wrapper.documentType = docType;
                            wrapper.applicantName = doc.Applicant__r.Applicant_Name__c;
                            wrapper.addressType = 'Permanent';
                            wrapper.applicanttype  =applicantType;
                            wrapper.missingType ='Address';
                            wrapper.missingparam = 'Permanent Address with high priority';
                            wrapper.applicantProfile = customerCategory;
                            wrapper.customerType = customerType;
                            wrapper.applicanttype  =applicantType;
                            System.debug('addressMapPerm-----'+addressMapPerm);
                            System.debug('doc.Applicant__c-----'+doc.Applicant__c);
                            String uniqueKey = docType + doc.Applicant__r.Applicant_Name__c+wrapper.missingparam;
                            System.debug('doc.uniqueKey-----'+uniqueKey);
                            if (!uniqueDocCategory.contains(uniqueKey)) {
                                System.debug('uniqueDocCategory---'+uniqueDocCategory);
                                uniqueDocCategory.add(uniqueKey);
                                System.debug('uniqueKey---'+uniqueKey);
                                result.add(wrapper);
                            }
                            
                        }
                    }
                    if (docType == 'Others' && customerType == 'Individual' && (customerCategory == 'SEP' || customerCategory == 'Salaried Indian' || customerCategory == 'Salaried NRI') && doc.Name == 'Photograph' && String.isBlank(doc.Content_Document_Id__c)) {
                        DocValidationWrapper wrapper = new DocValidationWrapper();
                        wrapper.documentType = docType;
                        wrapper.applicantName = doc.Applicant__r.Applicant_Name__c;
                        wrapper.applicanttype  =applicantType;
                        wrapper.missingparam = 'Photograph';
                        wrapper.missingType ='Document';
                        wrapper.applicantProfile = customerCategory;
                        wrapper.customerType = customerType;
                        result.add(wrapper); 
                    }
                    if (customerType == 'Non Individual' && customerCategory == 'SENP' && docType == 'POA') {
                        if (!addressMapOffice.containsKey(doc.Applicant__c) || !addressMapOfficeWithPr.containsKey(doc.Applicant__c)) {
                            System.debug('addressMapOffice-----'+addressMapOffice);
                            System.debug('addressMapOfficeWithPr-----'+addressMapOfficeWithPr);
                            DocValidationWrapper wrapper = new DocValidationWrapper();
                            wrapper.documentType = docType;
                            wrapper.applicantName = doc.Applicant__r.Applicant_Name__c;
                            wrapper.addressType = 'Business Operational';
                            wrapper.applicanttype  =applicantType;
                            wrapper.missingparam = 'Business Operational with priority "High"';
                            wrapper.missingType ='Address';
                            wrapper.applicantProfile = customerCategory;
                            wrapper.customerType = customerType;
                            String uniqueKey = docType + doc.Applicant__r.Applicant_Name__c+wrapper.missingparam;
                            if (!uniqueDocCategory.contains(uniqueKey)) {
                                uniqueDocCategory.add(uniqueKey);
                                result.add(wrapper);
                            }
                        }
                        if (!addressMapReg.containsKey(doc.Applicant__c) || !addressMapRegWithPr.containsKey(doc.Applicant__c)) {
                            DocValidationWrapper wrapper = new DocValidationWrapper();
                            wrapper.documentType = docType;
                            wrapper.applicantName = doc.Applicant__r.Applicant_Name__c;
                            
                            wrapper.applicanttype = applicantType;
                            wrapper.missingparam = 'Registered Office Address with priority "Very High"';
                            wrapper.missingType ='Address';
                            wrapper.applicantProfile = customerCategory;
                            wrapper.customerType = customerType;
                            String uniqueKey = docType + doc.Applicant__r.Applicant_Name__c+wrapper.missingparam;
                            if (!uniqueDocCategory.contains(uniqueKey)) {
                                uniqueDocCategory.add(uniqueKey);
                                result.add(wrapper);
                            }
                        }
                    }
                    //common

                    //Salaried Indian
                    if(customerCategory == 'Salaried Indian'){
                        if(salariedIndianSVPOneReq.contains(documentName) && doc.Content_Document_Id__c != null && docType == 'Proof of Signature'){
                            salariedIndianSVPCount= salariedIndianSVPCount+1;
                        }
                        if(salariedIndianIncomeOneReq.contains(documentName) && doc.Content_Document_Id__c != null && docType == 'Income Documents and Bank Statements'){
                            salariedIndianIncomeCount= salariedIndianIncomeCount+1;
                        }
                    }
                    //Salaried Indian

                    //SEP
                    if(customerCategory == 'SEP'){
                        if(salariedIndianSVPOneReq.contains(documentName) && doc.Content_Document_Id__c != null && docType == 'Proof of Signature'){
                            salariedIndianSVPCount= salariedIndianSVPCount+1;
                        }
                    }
                    //SEP

                    //Salaried NRI
                    if(customerCategory == 'Salaried NRI'){
                        if(salariedNRIPOIAnyoneReq.contains(documentName) && doc.Content_Document_Id__c != null && docType == 'POI'){
                            salariedNriPOICount= salariedNriPOICount+1;
                        }
                        if(salariedNRIPOAAnyoneReq.contains(documentName) && doc.Content_Document_Id__c != null && docType == 'POA'){
                            salariedNriPOACount= salariedNriPOACount+1;
                        }
                        if(hasPAN || (salariedIndianSVPOneReq.contains(documentName) && doc.Content_Document_Id__c != null && docType == 'Proof of Signature')){
                            salariedIndianSVPCount= salariedIndianSVPCount+1;
                        }
                        if(salariedNRIIncomeProofanyoneReq.contains(documentName) && doc.Content_Document_Id__c != null && docType == 'Income Documents and Bank Statements'){
                            salariedNriIncomeCount= salariedNriIncomeCount+1;
                        }
                        if(salariedNRIEmploymentProofanyoneReq.contains(documentName) && doc.Content_Document_Id__c != null && docType == 'Income Documents and Bank Statements'){
                            salariedNriEmploymentCount= salariedNriEmploymentCount+1;
                        }
                    }
                    //Salaried NRI
                    
                    //SENP
                    if(customerCategory == 'SENP'){
                        if(customerProfile== 'Proprietorship'){
                            if(senpProprietorshipPoBanytwo.contains(documentName) && doc.Content_Document_Id__c != null ){
                                senpProprietorPoBCount= senpProprietorPoBCount+1;
                            }
                        }
                        if(customerProfile== 'Private Limited' || customerProfile== 'Public Limited'){
                            if(senplimitedPoBanyone.contains(documentName) && doc.Content_Document_Id__c != null){
                                senpLimitedPoBCount= senpLimitedPoBCount+1;
                            }
                        }
                        if(customerProfile== 'Partnership' || customerProfile== 'LLP'){
                            if(senppartnershipPoBanyone.contains(documentName) && doc.Content_Document_Id__c != null ){
                                senpPartnerPoBCount= senpPartnerPoBCount+1;
                            }
                        }
                        if(customerProfile== 'HUF'){
                            if(senpHUFPoBanyone.contains(documentName) && doc.Content_Document_Id__c != null ){
                                senpHUFPoBCount= senpHUFPoBCount+1;
                            }
                        }
                    }
                    //SENP
                }
            }
            if(isCoApplicant && isSameAsPrimaryPresent && !hasOthersDoc){
                String uniqueKey = appId + '_SamePrimary_Others';
                if(!uniqueDocCategory.contains(uniqueKey)){
                    uniqueDocCategory.add(uniqueKey);
                    DocValidationWrapper wrapper = new DocValidationWrapper();
                    wrapper.applicantName = docList[0].Applicant__r.Applicant_Name__c;
                    wrapper.applicanttype = 'Co Applicant';
                    wrapper.documentType = 'Others';
                    wrapper.missingparam = 'Upload at least one "Others" document when Same as Primary Applicant Address is selected';
                    wrapper.missingType = 'Document';

                    result.add(wrapper);
                }
            }
            //common
            if((customerCategory == 'SEP' || customerCategory == 'Salaried Indian' || customerCategory == 'SENP')){
                if(customerType== 'Individual'){
                    if(!hasPAN && !hasForm60){
                        DocValidationWrapper wrapper = new DocValidationWrapper();
                        wrapper.documentType = 'POI';
                        wrapper.applicantName = appName;
                        wrapper.applicanttype  =applicantType;
                        wrapper.missingparam = 'PAN or Form 60';
                        wrapper.missingType ='Document';
                        wrapper.applicantProfile = customerCategory;
                        wrapper.customerType = customerType;
                        result.add(wrapper); 
                    }
                    if(!hasPAN && hasForm60 && !form60valid){
                        DocValidationWrapper wrapper = new DocValidationWrapper();
                        wrapper.documentType = 'POI';
                        wrapper.applicantName = appName;
                        wrapper.applicanttype  =applicantType;
                        wrapper.missingparam = 'Voter ID/ Passport/ Drivers License with Form 60';
                        wrapper.missingType ='Document';
                        wrapper.applicantProfile = customerCategory;
                        wrapper.customerType = customerType;
                        result.add(wrapper); 
                    }
                
                    if(!hasAadharFront){
                        DocValidationWrapper wrapper = new DocValidationWrapper();
                        wrapper.documentType = 'POA';
                        wrapper.applicantName = appName;
                        wrapper.applicanttype  =applicantType;
                        wrapper.missingparam = 'Aadhaar Front';
                        wrapper.missingType ='Document';
                        wrapper.applicantProfile = customerCategory;
                        wrapper.customerType = customerType;
                        result.add(wrapper); 
                    }
                    if(!hasAadharBack){
                        DocValidationWrapper wrapper = new DocValidationWrapper();
                        wrapper.documentType = 'POA';
                        wrapper.applicantName = appName;
                        wrapper.applicanttype  =applicantType;
                        wrapper.missingparam = 'Aadhaar Back';
                        wrapper.missingType ='Document';
                        wrapper.applicantProfile = customerCategory;
                        wrapper.customerType = customerType;
                        result.add(wrapper); 
                    }
                }
                
            }
            //Salaried Indian
            if(customerCategory == 'Salaried Indian'){
                if(salariedIndianSVPCount< 1){
                    DocValidationWrapper wrapper = new DocValidationWrapper();
                    wrapper.documentType = 'Signature Verification Proof';
                    wrapper.applicantName = appName;
                    wrapper.applicanttype  =applicantType;
                    wrapper.missingparam = 'Banker’s verification /Passport / PAN Card/ Driving License/ IPF Cheque Clearance';
                    wrapper.missingType ='Document';
                    wrapper.applicantProfile = customerCategory;
                    wrapper.customerType = customerType;
                    result.add(wrapper); 
                }
                if(salariedIndianIncomeCount< 1){
                    DocValidationWrapper wrapper = new DocValidationWrapper();
                    wrapper.documentType = 'Income Document';
                    wrapper.applicantName = appName;
                    wrapper.applicanttype  =applicantType;
                    wrapper.missingparam = 'Salary Certificate on letter head/ Salary Slip';
                    wrapper.missingType ='Document';
                    wrapper.applicantProfile = customerCategory;
                    wrapper.customerType = customerType;
                    result.add(wrapper); 
                }
                if(!bankStatementPresent){
                    DocValidationWrapper wrapper = new DocValidationWrapper();
                    wrapper.documentType = 'Bank Statement';
                    wrapper.applicantName = appName;
                    wrapper.applicanttype  =applicantType;
                    wrapper.missingparam = 'Bank Statement';
                    wrapper.missingType ='Document';
                    wrapper.applicantProfile = customerCategory;
                    wrapper.customerType = customerType;
                    result.add(wrapper); 
                }
            }
            //Salaried Indian
            //SEP
            if(customerCategory == 'SEP'){
                if(salariedIndianSVPCount< 1){
                    DocValidationWrapper wrapper = new DocValidationWrapper();
                    wrapper.documentType = 'Signature Verification Proof';
                    wrapper.applicantName = appName;
                    wrapper.applicanttype  =applicantType;
                    wrapper.missingparam = 'Banker’s verification /Passport / PAN Card/ Driving License/ IPF Cheque Clearance';
                    wrapper.missingType ='Document';
                    wrapper.applicantProfile = customerCategory;
                    wrapper.customerType = customerType;
                    result.add(wrapper); 
                }
                // if(salariedIndianIncomeCount< 0){
                //     DocValidationWrapper wrapper = new DocValidationWrapper();
                //     wrapper.documentType = 'Income Document';
                //     wrapper.applicantName = appName;
                //     wrapper.applicanttype  =applicantType;
                //     wrapper.missingparam = 'Salary Certificate on letter head/ Salary Slip';
                //     wrapper.missingType ='Document';
                //     wrapper.applicantProfile = customerCategory;
                //     wrapper.customerType = customerType;
                //     result.add(wrapper); 
                // }
                if(!bankStatementPresent){
                    DocValidationWrapper wrapper = new DocValidationWrapper();
                    wrapper.documentType = 'Bank Statement';
                    wrapper.applicantName = appName;
                    wrapper.applicanttype  =applicantType;
                    wrapper.missingparam = 'Bank Statement';
                    wrapper.missingType ='Document';
                    wrapper.applicantProfile = customerCategory;
                    wrapper.customerType = customerType;
                    result.add(wrapper); 
                }
            }
            //SEP
            //Salaried NRI
            if(customerCategory == 'Salaried NRI'){
                if(!hasPAN){
                    DocValidationWrapper wrapper = new DocValidationWrapper();
                    wrapper.documentType = 'POI';
                    wrapper.applicantName = appName;
                    wrapper.applicanttype  =applicantType;
                    wrapper.missingparam = 'PAN';
                    wrapper.missingType ='Document';
                    wrapper.applicantProfile = customerCategory;
                    wrapper.customerType = customerType;
                    result.add(wrapper); 
                }
                if(salariedNriPOICount<1){
                    DocValidationWrapper wrapper = new DocValidationWrapper();
                    wrapper.documentType = 'POI';
                    wrapper.applicantName = appName;
                    wrapper.applicanttype  =applicantType;
                    wrapper.missingparam = 'Overseas Citizen Card/ Person of Indian Origin Card/ VISA Copy';
                    wrapper.missingType ='Document';
                    wrapper.applicantProfile = customerCategory;
                    wrapper.customerType = customerType;
                    result.add(wrapper);
                }
                if(salariedNriPOACount<1){
                    DocValidationWrapper wrapper = new DocValidationWrapper();
                    wrapper.documentType = 'POA';
                    wrapper.applicantName = appName;
                    wrapper.applicanttype  =applicantType;
                    wrapper.missingparam = 'Any one POA document.';
                    wrapper.missingType ='Document';
                    wrapper.applicantProfile = customerCategory;
                    wrapper.customerType = customerType;
                    result.add(wrapper);
                }
                if(!bankStatementPresent){
                    DocValidationWrapper wrapper = new DocValidationWrapper();
                    wrapper.documentType = 'Bank Statement';
                    wrapper.applicantName = appName;
                    wrapper.applicanttype  =applicantType;
                    wrapper.missingparam = 'Bank Statement';
                    wrapper.missingType ='Document';
                    wrapper.applicantProfile = customerCategory;
                    wrapper.customerType = customerType;
                    result.add(wrapper); 
                }
                if(salariedIndianSVPCount< 1){
                    DocValidationWrapper wrapper = new DocValidationWrapper();
                    wrapper.documentType = 'Signature Verification Proof';
                    wrapper.applicantName = appName;
                    wrapper.applicanttype  =applicantType;
                    wrapper.missingparam = 'Banker’s verification /Passport / PAN Card/ Driving License/ IPF Cheque Clearance';
                    wrapper.missingType ='Document';
                    wrapper.applicantProfile = customerCategory;
                    wrapper.customerType = customerType;
                    result.add(wrapper); 
                }
                if(salariedNriIncomeCount< 1){
                    DocValidationWrapper wrapper = new DocValidationWrapper();
                    wrapper.documentType = 'Income Document';
                    wrapper.applicantName = appName;
                    wrapper.applicanttype  =applicantType;
                    wrapper.missingparam = 'Salary Slip';
                    wrapper.missingType ='Document';
                    wrapper.applicantProfile = customerCategory;
                    wrapper.customerType = customerType;
                    result.add(wrapper); 
                }
                if(salariedNriEmploymentCount< 1){
                    DocValidationWrapper wrapper = new DocValidationWrapper();
                    wrapper.documentType = 'Employment Proof';
                    wrapper.applicantName = appName;
                    wrapper.applicanttype  =applicantType;
                    wrapper.missingparam = 'Any one Employment proof document.';
                    wrapper.missingType ='Document';
                    wrapper.applicantProfile = customerCategory;
                    wrapper.customerType = customerType;
                    result.add(wrapper); 
                }
            }
            //Salaried NRI
            //SENP
            if(customerCategory == 'SENP' && customerType!= 'Individual'){
                if(!hasPAN){
                    DocValidationWrapper wrapper = new DocValidationWrapper();
                    wrapper.documentType = 'POI';
                    wrapper.applicantName = appName;
                    wrapper.applicanttype  =applicantType;
                    wrapper.missingparam = 'PAN';
                    wrapper.missingType ='Document';
                    wrapper.applicantProfile = customerCategory;
                    wrapper.customerType = customerType;
                    result.add(wrapper); 
                }
                if(customerProfile== 'Proprietorship'){
                    if(senpProprietorPoBCount<2){
                        DocValidationWrapper wrapper = new DocValidationWrapper();
                        wrapper.documentType = 'Proof of Registration';
                        wrapper.applicantName = appName;
                        wrapper.applicanttype  =applicantType;
                        wrapper.missingparam = 'Any two documents.';
                        wrapper.missingType ='Document';
                        wrapper.applicantProfile = customerCategory;
                        wrapper.customerType = customerType;
                        result.add(wrapper);
                    }
                }
                if(customerProfile== 'Private Limited' || customerProfile== 'Public Limited'){
                    if(senpLimitedPoBCount<1){
                        DocValidationWrapper wrapper = new DocValidationWrapper();
                        wrapper.documentType = 'Proof of Registration';
                        wrapper.applicantName = appName;
                        wrapper.applicanttype  =applicantType;
                        wrapper.missingparam = 'Any one document.';
                        wrapper.missingType ='Document';
                        wrapper.applicantProfile = customerCategory;
                        wrapper.customerType = customerType;
                        result.add(wrapper);
                    }
                }
                if(customerProfile== 'Partnership' || customerProfile== 'LLP'){
                    if(senpPartnerPoBCount<1){
                        DocValidationWrapper wrapper = new DocValidationWrapper();
                        wrapper.documentType = 'Proof of Registration';
                        wrapper.applicantName = appName;
                        wrapper.applicanttype  =applicantType;
                        wrapper.missingparam = 'Any one document.';
                        wrapper.missingType ='Document';
                        wrapper.applicantProfile = customerCategory;
                        wrapper.customerType = customerType;
                        result.add(wrapper);
                    }
                }
                if(customerProfile== 'HUF'){
                    if(senpHUFPoBCount<1){
                        DocValidationWrapper wrapper = new DocValidationWrapper();
                        wrapper.documentType = 'Proof of Registration';
                        wrapper.applicantName = appName;
                        wrapper.applicanttype  =applicantType;
                        wrapper.missingparam = 'Any one document.';
                        wrapper.missingType ='Document';
                        wrapper.applicantProfile = customerCategory;
                        wrapper.customerType = customerType;
                        result.add(wrapper);
                    }
                }
            }
            //SENP
        }

        List<DocValidationWrapper> docErrorList = new List<DocValidationWrapper>();
        List<DocValidationWrapper> addressErrorList = new List<DocValidationWrapper>();
        List<DocValidationWrapper> otherErrorList = new List<DocValidationWrapper>();
        for(DocValidationWrapper res : result){
            if(res.missingType == 'Address'){
                addressErrorList.add(res);
            }
            else if(res.missingType == 'Document'){
                docErrorList.add(res);
            }
            else{
                otherErrorList.add(res);
            }
        }
        result = new List<DocValidationWrapper>();
        result.addAll(docErrorList);
        result.addAll(addressErrorList);
        result.addAll(otherErrorList);
        Map<String,List<DocValidationWrapper>> nameToResult  = new Map<String,List<DocValidationWrapper>>();
        for(DocValidationWrapper resultMap : result){
            if(nameToResult.containskey(resultMap.applicantName)){
                nameToResult.get(resultMap.applicantName).add(resultMap);
            }else{
                nameToResult.put(resultMap.applicantName, new List<DocValidationWrapper>{resultMap});
            }
        }
        result = new List<DocValidationWrapper>();
        for(String key : nameToResult.keyset()){
            result.addAll(nameToResult.get(key));
        }
        return result;
    }
    
    
}