/*
* Created By : Romesh Somani
* Created Date : 15/10/2024
* Purpose : Exposing this class as a REST API to manage Lead, lead dedupe, pincode serviceability from outside sources
*/

@RestResource(urlMapping='/api/LeadManagement')
global with sharing class LeadManagementAPIREST
{
    @HttpGet
    global static ResponseWrapper getLeadDetailsByLeadNumber() {
        RestRequest restReq = RestContext.request;

        ResponseWrapper res = new ResponseWrapper();
        res.methodType = restReq.httpMethod;

        String requestBody = restReq.requestBody.toString();
        //system.debug('requestBody: '+requestBody);

        GetRequestWrapper req = new GetRequestWrapper();

        try{
            if(String.isBlank(requestBody)) {
                res.statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_REQUIRED_FIELD_MISSING').Value__c);
                res.errorMessage = Constants__mdt.getInstance('ERROR_MESSAGE_REQUEST_BODY').Value__c;
                return res;
            }

            req = (GetRequestWrapper)JSON.deserialize(requestBody, GetRequestWrapper.class);
            //System.debug('req: '+req);

            if(String.isBlank(req.apiSource)) {
                res.statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_REQUIRED_FIELD_MISSING').Value__c);
                res.errorMessage = Constants__mdt.getInstance('ERROR_MESSAGE_API_SOURCE').Value__c;
                return res;
            }

            if(string.isBlank(req.leadNumber)) {
                res.statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_REQUIRED_FIELD_MISSING').Value__c);
                res.errorMessage = Constants__mdt.getInstance('ERROR_MESSGAE_LEAD_NUMBER').Value__c;
                return res;
            }

            List<string> leadIds = req.leadNumber.deleteWhitespace().split(',');
            Integer limitValue = req.recordLimit == null ? 10 : req.recordLimit;

            // Query the Lead records
            res.leadRecord  = [
                                SELECT Id, Name, MobilePhone, Pincode__c, Lead_Number__c, Email, Company, Status, Lead_Sub_Status__c, Pan__c, 
                                Customer_Type__c ,Branch__r.Name
                                FROM Lead
                                WHERE Lead_Number__c IN : leadIds LIMIT : limitValue
                            ];

            res.statusCode =Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_SUCCESS').Value__c);
        }
        catch(Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'getLeadDetailsByLeadNumber', '', '') });
            
            res.statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_ERROR').Value__c);
            res.errorMessage = e.getMessage();
        }
        finally {
            string source = req.apiSource != null ? req.apiSource : restReq.remoteAddress;
            string endpoint = URL.getOrgDomainURL().toExternalForm() + restReq.resourcePath;

            Utility.createIntegrationRecord(new List<Integration_Details__c>{ Utility.fillIntegrationRecord(source, requestBody, JSON.serialize(res), res.statusCode.toString(), res.methodType, endpoint, '', '', 'LeadManagement GetLeadDetails', '') });
        }

        return res;
    }
    
    @HttpPost
    global static ResponseWrapper manageLead() {
        RestRequest restReq = RestContext.request;

        ResponseWrapper res = new ResponseWrapper();
        res.methodType = restReq.httpMethod;
        res.leadData = new List<LeadWrapper>();
        
        String requestBody = restReq.requestBody.toString();
        //system.debug('requestBody: '+requestBody);

        RequestWrapper req = new RequestWrapper();

        try{
            req = (RequestWrapper)JSON.deserialize(requestBody, RequestWrapper.class);
            //System.debug('req: '+req);

            if(String.isBlank(req.apiAction)) {
                res.statusCode =Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_REQUIRED_FIELD_MISSING').Value__c);
                res.errorMessage =Constants__mdt.getInstance('ERROR_MESSAGE_API_ACTION').Value__c;
                return res;
            }
    
            if(String.isBlank(req.apiSource)) {
                res.statusCode =Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_REQUIRED_FIELD_MISSING').Value__c);
                res.errorMessage =Constants__mdt.getInstance('ERROR_MESSAGE_API_SOURCE').Value__c;
                return res;
            }

            switch on req.apiAction.toUpperCase() {
                when 'MANAGELEAD' {	
                    checkLeadDedupe(req, res);

                    checkPincodeServiceability(req, res);
    
                    upsertLeadDetails(req, res);
                    
                    createLeadDocuments(res, req.apiSource);
                }
                when 'CHECKLEADDEDUPE' {
                    checkLeadDedupe(req, res);
                }
                when 'CHECKPINCODESERVICEABILITY' {
                    checkPincodeServiceability(req, res);
                }
            }
        }
        catch(Exception e) {
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 'manageLead', '', '') });
                        
            res.leadData = req.leadData;
            res.statusCode =Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_ERROR').Value__c);
            res.errorMessage = e.getMessage();
        }
        finally{
            string source = req.apiSource != null ? req.apiSource : restReq.remoteAddress;
            string endpoint = URL.getOrgDomainURL().toExternalForm() + restReq.resourcePath;

            Utility.createIntegrationRecord(new List<Integration_Details__c>{ Utility.fillIntegrationRecord(source, requestBody, JSON.serialize(res), res.statusCode.toString(), res.methodType, endpoint, '', '', 'LeadManagement '+ req.apiAction, '') });
        }
        
        //system.debug('res: '+ JSON.serialize(res));
        return res;
    }

    //Creating Lead Documents which are coming from API like Website,Chatbot
    private static void createLeadDocuments(ResponseWrapper res, string apiSource){
        //creating document for Leads
        DocumentManagementAPI_REST.RequestWrapper docReqWrapper = new DocumentManagementAPI_REST.RequestWrapper();
        docReqWrapper.documentData = new List<DocumentManagementAPI_REST.DocumentWrapper>();
        
        for(LeadWrapper lw : res.leadData){
            //system.debug('lw: '+lw);

            //Allowing document creation for new created lead and dedupe lead
            if((lw.statusCode == Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_SUCCESS').Value__c) || lw.statusCode == Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_DEDUPE_FOUND').Value__c)) && lw.documentData != null){
                string leadId = lw.leadId == null ? lw.existingLeadId : lw.leadId;
                //system.debug('leadId: '+leadId);

                for(DocumentManagementAPI_REST.DocumentWrapper dw : lw.documentData){
                    dw.linkRecordId = leadId;

                    docReqWrapper.documentData.add(dw);
                }
            }
        }

        if(!docReqWrapper.documentData.isEmpty() || Test.isRunningTest()) {
            docReqWrapper.apiAction = 'CREATEDOCUMENTFROMLEAD';
            docReqWrapper.apiSource = apiSource;
            docReqWrapper.linkObjectName = 'LEAD';

            DocumentManagementAPI_REST.ResponseWrapper documentRes = new DocumentManagementAPI_REST.ResponseWrapper();
            documentRes.documentData = new List<DocumentManagementAPI_REST.DocumentWrapper>();
            
            DocumentManagementAPI_REST.createDocument(docReqWrapper, documentRes);
        }

        //system.debug('res.leadData: '+res.leadData);
    }
    //Upserting Lead Details

    private static list<Configure_Mandatory_Parameter__mdt> getMDTdata(string processName){
        List<Configure_Mandatory_Parameter__mdt> configureMetadata = new List<Configure_Mandatory_Parameter__mdt>();
        if(Schema.sObjectType.Configure_Mandatory_Parameter__mdt.isAccessible()){
        return [Select Source__c, Mandatory_Parameters__c From Configure_Mandatory_Parameter__mdt Where Process__c =: processName];}
        return configureMetadata;
    }

    private static void upsertLeadDetails(RequestWrapper req, ResponseWrapper res){
        //System.debug('req: '+ JSON.serialize(req.leadData));
    
        res.leadData.clear();
        List<Lead> leadsToProcess = new List<Lead>();
        List<LeadWrapper> leadDataValidationOkList = new List<LeadWrapper>();
        List<LeadWrapper> leadDataValidationFailList = new List<LeadWrapper>();
        req.apiSource = req.apiSource.toUpperCase();

        // string arID = [select Id from AssignmentRule where SobjectType = 'Lead' and Active = true limit 1].Id;

        // Database.DMLOptions dmlOpts = new Database.DMLOptions();
        // dmlOpts.assignmentRuleHeader.assignmentRuleId = arID;

        for(LeadWrapper itr : req.leadData){
            //System.debug('itr: '+itr);

            //setting dummy value in case of missed call, only mobile number will come in request
            if(itr.leadSource == 'Missed Call'){
                itr.firstName = 'NA';
                itr.LastName = 'NA';
                itr.Company = 'NA';
                itr.customerType = 'Individual';
                itr.product = 'Business Loan';
            }

            if(String.isBlank(itr.customerType)){
                itr.errorMessage = Constants__mdt.getInstance('ERROR_MESSAGE_CUSTOMER_TYPE').Value__c;
                itr.statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_REQUIRED_FIELD_MISSING').Value__c);
                itr.existingLeadId = null;
                itr.existingLeadNumber = null;
                itr.tmpData = null;      //setting this field null as this was used for internal purpose only and not required to send in response
                
                leadDataValidationFailList.add(itr);
                continue;
            }

            List<String> requiredFieldList = new List<String>();
            Map<String,String> sourceToFieldMap = new Map<String,String>();
            String processName = 'Lead API '+ itr.customerType;

            for(Configure_Mandatory_Parameter__mdt iterConfig : getMDTdata(processName)){
                sourceToFieldMap.put(iterConfig.Source__c.toUpperCase(), iterConfig.Mandatory_Parameters__c);
            }
    
            if(sourceToFieldMap.containsKey(req.apiSource) && string.isNotBlank(sourceToFieldMap.get(req.apiSource))){
                requiredFieldList = sourceToFieldMap.get(req.apiSource).split(';');
            }

            sourceToFieldMap.clear();

            Lead lead = new Lead();
            lead.Status = Constants__mdt.getInstance('Open').Value__c;
            lead.Lead_Sub_Status__c = Constants__mdt.getInstance('Created').Value__c;
            // lead.setOptions(dmlOpts);

            //prefill the details from the existing lead record
            if(string.isNotBlank(itr.existingLeadId)){

                if(itr.customerType == Constants__mdt.getInstance('CUSTOMER_TYPE_INDIVIDUAL').Value__c){
                    itr.firstName = itr.tmpData.existingLeadRecord.FirstName;
                    itr.middleName = string.isNotBlank(itr.tmpData.existingLeadRecord.MiddleName) ? itr.tmpData.existingLeadRecord.MiddleName : itr.middleName;
                    itr.lastName = itr.tmpData.existingLeadRecord.LastName;
                }
                else{
                    itr.company = itr.tmpData.existingLeadRecord.Company;
                }
                
                itr.emailAddress = string.isNotBlank(itr.tmpData.existingLeadRecord.Email) ? itr.tmpData.existingLeadRecord.Email : itr.emailAddress;
                itr.tmpData.pinCodeMasterId = string.isNotBlank(itr.tmpData.existingLeadRecord.Pincode__c) ? itr.tmpData.existingLeadRecord.Pincode__c : itr.tmpData.pinCodeMasterId;
                itr.customerType = itr.tmpData.existingLeadRecord.Customer_Type__c;
                
                lead.Status = Constants__mdt.getInstance('STATUS_CLOSED').Value__c;
                lead.Lead_Sub_Status__c = Constants__mdt.getInstance('STATUS_DUPLICATE').Value__c;
                lead.Closed_Reasons__c = 'Duplicate Lead';
                lead.Existing_Lead__c = itr.existingLeadId;
            }

            List<String> missingFields = new List<String>();

            if(!requiredFieldList.isEmpty()){
                Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(itr));
                //system.debug('requestMap: '+requestMap);
                
                for(String fieldName : requiredFieldList) {
                    if(!requestMap.containsKey(fieldName) || String.isBlank(String.valueOf(requestMap.get(fieldName)))) {
                        missingFields.add(fieldName);
                    }
                }
                //system.debug('missingFields: '+missingFields);

                requiredFieldList.clear();
            }

            if(!missingFields.isEmpty()) {
                itr.errorMessage = Constants__mdt.getInstance('ERROR_REQUIRED_FIELD_MISSING').Value__c +': '+ String.join(missingFields, ', ');
                itr.statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_REQUIRED_FIELD_MISSING').Value__c);

                missingFields.clear();
                leadDataValidationFailList.add(itr);
                continue;
            }

            if(!(Utility.isValidMobileNumber(itr.mobileNumber))) {
                itr.errorMessage = Constants__mdt.getInstance('ERROR_MESSGAE_MOBILE_NUMBER').Value__c;
                itr.statusCode =  Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_VALIDATION_ERROR').Value__c);

                leadDataValidationFailList.add(itr);
                continue;
            }
            
            if(string.isNotBlank(itr.emailAddress) && !(Utility.isEmailValid(itr.emailAddress))) {
                itr.errorMessage = Constants__mdt.getInstance('ERROR_MESSAGE_EMAIL').Value__c;
                itr.statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_VALIDATION_ERROR').Value__c);
                
                leadDataValidationFailList.add(itr);
                continue;
            }

            //in case of missed call only mobile number will come in request
            if(itr.leadSource == 'Missed Call'){
                lead.firstName = 'NA';
                lead.LastName = 'NA';
                lead.Company = 'NA';
            }
            else{
                if(itr.customerType == Constants__mdt.getInstance('CUSTOMER_TYPE_INDIVIDUAL').Value__c){

                    if(!(Utility.isValidName(itr.firstName) || Utility.isValidName(itr.lastName))){
                        itr.errorMessage = Constants__mdt.getInstance('ERROR_MESSGAE_NAME').Value__c;
                        itr.statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_VALIDATION_ERROR').Value__c);
        
                        leadDataValidationFailList.add(itr);
                        continue;
                    }
    
                    lead.FirstName = itr.firstName;
                    lead.MiddleName = itr.middleName;
                    lead.LastName = itr.lastName;
                    lead.Company = 'NA';
                }
                else{
                    if(!Utility.isValidName(itr.company)) {
                        itr.errorMessage = Constants__mdt.getInstance('ERROR_MESSAGE_COMPANY_NAME').Value__c;
                        itr.statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_VALIDATION_ERROR').Value__c);
    
                        leadDataValidationFailList.add(itr);
                        continue;
                    }
    
                    lead.Company = itr.company;
                    lead.LastName = itr.company;
                }
            }
            
            lead.Email = itr.emailAddress;
            lead.MobilePhone = itr.mobileNumber;
            lead.LeadSource = itr.leadSource;
            lead.UTM_Camping__c = itr.utmCamping;
            lead.UTM_Content__c = itr.utmContent;
            lead.UTM_Source__c = itr.utmSource;
            lead.UTM_Medium__c = itr.utmMedium;
            lead.Customer_Type__c = itr.customerType;
            lead.Pincode__c = itr.tmpData.pinCodeMasterId;
            lead.Is_Mobile_Verified__c = itr.isMobileVerified != null ? itr.isMobileVerified : false;
            lead.COMM_Is_Consent_Received__c = itr.isConsentReceived != null ? itr.isConsentReceived : false;
            lead.Product__c = itr.product;

            if(String.isNotBlank(itr.leadId)) {
                lead.Id = itr.leadId;
            }
            
            itr.tmpData = null;      //setting these field null as this was used for internal purpose only and not required to send in response

            leadsToProcess.add(lead);
            leadDataValidationOkList.add(itr);
        }
        //system.debug('leadsToProcess: '+leadsToProcess);
        //System.debug('leadDataValidationFailList: '+leadDataValidationFailList);
        
        res.leadData.addAll(leadDataValidationFailList);
        leadDataValidationFailList.clear();

        integer successCount = 0;

        if(!leadsToProcess.isEmpty()){
            Set<Id> leadIdSet = new Set<Id>();
            List<LeadWrapper> leadSuccessWrapperList = new List<LeadWrapper>();

            List<Database.UpsertResult> saveResults = Database.upsert(leadsToProcess, false);
            //system.debug('saveResults: '+saveResults);

            for(integer i=0; i < saveResults.size(); i++){
                if(saveResults.get(i).isSuccess()) {

                    if(string.isNotBlank(leadDataValidationOkList[i].existingLeadId)){
                        leadDataValidationOkList[i].statusCode =  Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_DEDUPE_FOUND').Value__c);
                        leadDataValidationOkList[i].errorMessage = Constants__mdt.getInstance('ERROR_DEDUPE_FOUND').Value__c;
                        leadDataValidationOkList[i].leadId = null;
                        leadDataValidationOkList[i].leadNumber = null;
                    }
                    else{
                        leadDataValidationOkList[i].leadId = leadsToProcess[i].Id;
                        leadDataValidationOkList[i].statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_SUCCESS').Value__c);
                        leadDataValidationOkList[i].errorMessage = '';

                        leadIdSet.add(leadDataValidationOkList[i].leadId);
                        leadSuccessWrapperList.add(leadDataValidationOkList[i]);
                        successCount++;
                    }
                }
                else if(!saveResults.get(i).isSuccess()){
                    
                    for(Database.Error err : saveResults.get(i).getErrors()){
                        leadDataValidationOkList[i].errorMessage = err.getMessage() +', ';
                    }
    
                    leadDataValidationOkList[i].errorMessage = leadDataValidationOkList[i].errorMessage.removeEnd(', ');
                    leadDataValidationOkList[i].statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_ERROR').Value__c);
                }
            }

            saveResults.clear();
            //system.debug('leadIdSet: '+leadIdSet);
            //system.debug('leadSuccessWrapperList: '+leadSuccessWrapperList);
            if(Schema.sObjectType.Lead.isAccessible()){
            for(Lead itm : [SELECT Id, Lead_Number__c FROM Lead WHERE Id IN : leadIdSet]){
                for(LeadWrapper rw : leadSuccessWrapperList){
                    if(rw.leadId == itm.Id){
                        rw.leadNumber = itm.Lead_Number__c;
                    }
                }
                }
            }
            leadIdSet.clear();
            leadSuccessWrapperList.clear();

            res.leadData.addAll(leadDataValidationOkList);
            leadDataValidationOkList.clear();
        }

        res.statusCode =  Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_SUCCESS').Value__c);
        res.errorMessage = '';
    
        if(successCount == 0){
            res.statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_ALL_FAILURE').Value__c);
            res.errorMessage =  Constants__mdt.getInstance('ERROR_MESSAGE_ALL_FAILURE').Value__c;
        }
        else if(successCount < req.leadData.size()){
            res.statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_PARTIAL_SUCCESS').Value__c);
            res.errorMessage = Constants__mdt.getInstance('ERROR_MESSAGE_PARTIAL_SUCCESS').Value__c;
        }

        //system.debug('res: '+res.leadData);
    }
    //Checking where there's a duplicate Lead in the system already present or not

    private static void checkLeadDedupe(RequestWrapper req, ResponseWrapper res){
        //system.debug('req: '+req);
    
        Map<String, String> mobileNoToCustomerTypeMap = new Map<String, String>();
        List<LeadWrapper> leadDataValidationOkList = new List<LeadWrapper>();
        List<LeadWrapper> leadDataValidationFailList = new List<LeadWrapper>();
        
        for(LeadWrapper rw : req.leadData){

            rw.tmpData = new TemporaryDataWrapper();        //Initializing this here as this is the first method call

            if(!(Utility.isValidMobileNumber(rw.mobileNumber))) {
                rw.errorMessage = Constants__mdt.getInstance('ERROR_MESSGAE_MOBILE_NUMBER').Value__c;
                rw.statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_VALIDATION_ERROR').Value__c);

                leadDataValidationFailList.add(rw);
            }
            else{
                mobileNoToCustomerTypeMap.put(rw.mobileNumber, rw.customerType);
                leadDataValidationOkList.add(rw);
            }
        }

        res.leadData.addAll(leadDataValidationFailList);
        leadDataValidationFailList.clear();

        Map<String, Lead> mobileToExistingLeadMap = Comm_LeadUtility.getExistingLead(mobileNoToCustomerTypeMap, 'API');

        mobileNoToCustomerTypeMap.clear();
        //system.debug('mobileToExistingLeadMap: '+mobileToExistingLeadMap);
        //system.debug('leadDataValidationOkList: '+leadDataValidationOkList);

        integer successCount = 0;
        for(LeadWrapper rw : leadDataValidationOkList){

            if(mobileToExistingLeadMap.containsKey(rw.mobileNumber)){
                rw.tmpData.existingLeadRecord = mobileToExistingLeadMap.get(rw.mobileNumber);
                rw.existingLeadId = rw.tmpData.existingLeadRecord.Id;
                rw.existingLeadNumber = rw.tmpData.existingLeadRecord.Lead_Number__c;
                
                successCount++;
            }
            else{
                rw.statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_NO_DEDUPE_FOUND').Value__c);
                rw.errorMessage = Constants__mdt.getInstance('ERROR_NO_DEDUPE_FOUND').Value__c;
            }
        }

        res.leadData.addAll(leadDataValidationOkList);
        leadDataValidationOkList.clear();
        mobileToExistingLeadMap.clear();

        if(req.apiAction == 'CHECKLEADDEDUPE'){
            res.statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_SUCCESS').Value__c);
            res.errorMessage = '';

            if(successCount == 0){
                res.statusCode =  Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_ALL_FAILURE').Value__c);
                res.errorMessage =Constants__mdt.getInstance('ERROR_MESSAGE_ALL_FAILURE').Value__c;
            }
            else if(successCount < req.leadData.size()){
                res.statusCode =Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_PARTIAL_SUCCESS').Value__c);
                res.errorMessage =Constants__mdt.getInstance('ERROR_MESSAGE_PARTIAL_SUCCESS').Value__c;
            }

            req.leadData = res.leadData;
        }

        //system.debug('res.leadData: '+res.leadData);
    }

    //checking whether the current pincode is serviceable or not
    private static void checkPincodeServiceability(RequestWrapper req, ResponseWrapper res){
        //system.debug('req: '+ JSON.serialize(req.leadData));

        res.leadData.clear();
        Set<String> pinCodeSet = new Set<String>();
        List<LeadWrapper> leadDataValidationOkList = new List<LeadWrapper>();
        List<LeadWrapper> leadDataValidationFailList = new List<LeadWrapper>();

        for(LeadWrapper rw : req.leadData){

            if(string.isBlank(rw.pinCode)) {
                rw.errorMessage =Constants__mdt.getInstance('ERROR_MESSGAE_PINCODE').Value__c;
                rw.statusCode =Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_VALIDATION_ERROR').Value__c);

                leadDataValidationFailList.add(rw);
            }
            else{
                pinCodeSet.add(rw.pinCode);
                leadDataValidationOkList.add(rw);
            }
        }

        res.leadData.addAll(leadDataValidationFailList);
        leadDataValidationFailList.clear();

        Map<String, Pincode_Master__c> pinCodeMap = new Map<String, Pincode_Master__c>();
        if(Schema.sObjectType.Pincode_Master__c.isAccessible()){
        for(Pincode_Master__c pm : [Select Id, Name,Serviceable_For_Business_Loan__c From Pincode_Master__c where Name In : pinCodeSet Order by Serviceable_For_Business_Loan__c Desc]){
            if(!pinCodeMap.containsKey(pm.Name)){
                pinCodeMap.put(pm.Name, pm);
            }
        }
        //system.debug('pinCodeMap: '+pinCodeMap);
    }
        pinCodeSet.clear();

        integer successCount = 0;
        for(LeadWrapper rw : leadDataValidationOkList){
            //system.debug('rw.pinCode: '+rw.pinCode);

            if(pinCodeMap.containsKey(rw.pinCode)){
                Pincode_Master__c pm = pinCodeMap.get(rw.pinCode);
                //system.debug('pm: '+pm);

                rw.pinCodeServiceability = pm.Serviceable_For_Business_Loan__c;
                rw.tmpData.pinCodeMasterId = pm.Id;

                if(!pm.Serviceable_For_Business_Loan__c){
                    rw.statusCode =Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_PINCODE_SERVICEABILITY_NOT_FOUND').Value__c);
                    rw.errorMessage =Constants__mdt.getInstance('ERROR_PINCODE_SERVICEABILITY_NOT_FOUND').Value__c;
                }
                else{
                    successCount++;
                }
            }
            else{
                rw.statusCode =Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_PINCODE_NOT_FOUND').Value__c);
                rw.errorMessage =Constants__mdt.getInstance('ERROR_PINCODE_NOT_FOUND').Value__c;
            }
        }

        res.leadData.addAll(leadDataValidationOkList);
        leadDataValidationOkList.clear();
        pinCodeMap.clear();

        //system.debug('res.leadData: '+JSON.serialize(res.leadData));
		System.debug('apiAction here -->'+req.apiAction);
        if(req.apiAction == 'CHECKPINCODESERVICEABILITY'){
            res.statusCode =Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_SUCCESS').Value__c);
            res.errorMessage = '';
    
            if(successCount == 0){
                res.statusCode = Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_ALL_FAILURE').Value__c);
                res.errorMessage = Constants__mdt.getInstance('ERROR_MESSAGE_ALL_FAILURE').Value__c;
            }
            else if(successCount < req.leadData.size()){
                res.statusCode =Integer.valueOf(Constants__mdt.getInstance('STATUS_CODE_PARTIAL_SUCCESS').Value__c);
                res.errorMessage =Constants__mdt.getInstance('ERROR_MESSAGE_PARTIAL_SUCCESS').Value__c;
            }

            req.leadData = res.leadData;
        }

        //system.debug('res.leadData: '+res.leadData);
    }

    public class RequestWrapper {
        public String apiAction;                //This is used to capture what action this API will do like lead dedupe, pincode serviceable check, lead create/update etc.
        public String apiSource;                //This is used to capture from which source this API is being called
        public List<LeadWrapper> leadData;
    }
    
    public class LeadWrapper {
        public String customerType;
        public String leadId;
        public String leadNumber;
        public String firstName;
        public String middleName;
        public String lastName;
        public String mobileNumber;
        public String product;
        public Boolean isMobileVerified;
        public Boolean isConsentReceived;
        public string pinCode;
        public String panNumber;
        public String dob;
        public String leadSource;
        public String employmentType;
        public String company;                  //mandatory in lead object and for Non Individual
        public String existingLeadId;           //when lead dedupe api is called then this param will use to send the lead id for CheckLeadDedupe action
        public String existingLeadNumber;       //when lead dedupe api is called then this param will use to send the lead number for CheckLeadDedupe action
        public String errorMessage;
        public Integer statusCode;
        public boolean pinCodeServiceability;
        public String utmCamping;
        public String utmContent;
        public String utmMedium;
        public String utmSource;
        public String emailAddress;
        public TemporaryDataWrapper tmpData;    //this is used for internal purpose
        public List<DocumentManagementAPI_REST.DocumentWrapper> documentData;
    }

    //this class is used for internal purpose
    public class TemporaryDataWrapper {
        public Lead existingLeadRecord;
        public String pinCodeMasterId;
    }
    
    global class ResponseWrapper {
        public Integer statusCode;
        public List<Lead> leadRecord;           //This is used to send the Lead record for getLead details action
        public String errorMessage;
        public List<LeadWrapper> leadData;      //This is used to send the Lead data response
        public String methodType;
    }

    global class GetRequestWrapper {
        public String leadNumber;               //send leadNumber separated by comma for bulk
        public integer recordLimit;
        public String apiSource;                //This is used to capture from which source this API 
    }
}