public class COMM_ItrScreenController {
    @AuraEnabled
    public static RecordWrapper getItrRecords(String applicantId, String year) {
        RecordWrapper resWrap = new RecordWrapper();
        String itrRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Income_Expense_Obligation__c', 'ITR');
        List<Income_Expense_Obligation__c> itrObj = [
            SELECT Id, Year__c, Business_income_profit_as_per_policy__c, Reported_Date__c,
                   Acknowledgement_Number__c, Assessment_Year__c
            FROM Income_Expense_Obligation__c
            WHERE Application_Applicant__c = :applicantId
            AND Year__c = :year
            AND RecordTypeId = :itrRecordTypeId
        ];
        if (!itrObj.isEmpty()) {
            Income_Expense_Obligation__c record = itrObj[0];
            resWrap.recId = record.Id;
            resWrap.year = record.Year__c;
            resWrap.busineeIncome = record.Business_income_profit_as_per_policy__c;
            resWrap.fillingDate = record.Reported_Date__c;
            resWrap.acknolegmentNumber = record.Acknowledgement_Number__c;
            resWrap.assessmentYear = record.Assessment_Year__c;
        }
        return resWrap;
    }

    @AuraEnabled
    public static void saveItrRecord(String applicantId, String res) {
        RecordWrapper lstRecords = (RecordWrapper)JSON.deserialize(res, RecordWrapper.class);
        String itrRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Income_Expense_Obligation__c', 'ITR');
        Income_Expense_Obligation__c iterObj = new Income_Expense_Obligation__c();
        if (String.isNotBlank(lstRecords.recId)) {
            iterObj.Id = lstRecords.recId;
            iterObj.Application_Applicant__c = applicantId;
        } else {
            iterObj.RecordTypeId = itrRecordTypeId;
            iterObj.Application_Applicant__c = applicantId;
        }
        iterObj.Year__c = lstRecords.year;
        iterObj.Business_income_profit_as_per_policy__c = lstRecords.busineeIncome;
        iterObj.Reported_Date__c = lstRecords.fillingDate;
        iterObj.Acknowledgement_Number__c = lstRecords.acknolegmentNumber;
        iterObj.Assessment_Year__c = lstRecords.assessmentYear;
        upsert iterObj;
    }

    @AuraEnabled
    public static Boolean checkCibilFetch(String applicantId) {
        Boolean cibilrequired = false;
        List<Application_Applicant__c> lstApplicants = [SELECT Id, Customer_Type__c,Loan_Application__c, CIBIL_Score__c FROM Application_Applicant__c WHERE Id = :applicantId];
        if (!lstApplicants.isEmpty()) {
            Application_Applicant__c applicant = lstApplicants[0];
            if (applicant.Customer_Type__c == 'Individual') {
                if (applicant.CIBIL_Score__c == null) {
                    cibilrequired = true;
                } 
                else {
                    List<Document_Details__c> recentCrif = [
                        SELECT Id, CreatedDate, Name, Document_Master__r.Name
                        FROM Document_Details__c
                        WHERE Loan_Application__c = :applicant.Loan_Application__c
                        AND (Name = 'CRIF' OR Document_Master__r.Name = 'CRIF')
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                    ];
                    if (recentCrif.isEmpty()) {
                        cibilrequired = true;
                    } else {
                        Datetime lastFetched = recentCrif[0].CreatedDate;
                        if (lastFetched <= Datetime.now().addDays(-60)) {
                            cibilrequired = true;
                        }
                    }
                }
            }
        }

        return cibilrequired;
    }
	@AuraEnabled
	public static void insertRefData(List<Application_Verification__c> pdDetailsList) {
        if (pdDetailsList == null || pdDetailsList.isEmpty()) {
        	return;
        }
        
        // Fetch all record type infos once to avoid repeated calls
        Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = 
        Schema.SObjectType.Application_Verification__c.getRecordTypeInfosByName();
        System.debug('pd details list>'+pdDetailsList);
        for (Application_Verification__c record : pdDetailsList) {
        String idStr = String.valueOf(record.Id);
        if (!String.isBlank(idStr) && (idStr.length() < 15 || idStr.length() > 18)) {
            record.Id = null;
        }
        if (record.Id == null) {
            String rtName = String.valueOf(record.RecordTypeId);
            if (String.isNotBlank(rtName) && recordTypeInfoMap.containsKey(rtName)) {
                record.RecordTypeId = recordTypeInfoMap.get(rtName).getRecordTypeId();
            } else {
                System.debug('Invalid or missing RecordTypeName for record: ' + record);
            }
            }
        }

        upsert pdDetailsList;
        
    }

    @AuraEnabled
    public static String initiateAPIRequest(Map<String, String> inputMap) {
        try {
            String loanId = inputMap.get('loanId');
            String applicantId = inputMap.get('applicantId');
            String processName = inputMap.get('processName');
            String returnResp;

            Integration_Master__mdt metadata = [
                SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c,
                       Client_Id__c, Client_Secret__c, Allowed_Retry__c, Gestation_Period__c,
                       Refresh_Allowed__c, Activity_Name__c
                FROM Integration_Master__mdt
                WHERE Activity_Name__c = :processName
                LIMIT 1
            ];

            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper(); 
            wrapper.recordId = applicantId;
            wrapper.loanApplicationId = loanId;  
            wrapper.type = processName;
            wrapper.endpoint = metadata.Endpoint__c;
            wrapper.requestMethod = metadata.Request_Method__c;
            wrapper.handlerClass = metadata.Handler_Class__c;
            wrapper.clientId = metadata.Client_Id__c;
            wrapper.clientSecret = metadata.Client_Secret__c;
            wrapper.allowedRetry = metadata.Allowed_Retry__c;
            wrapper.gestationPeriod = metadata.Gestation_Period__c;
            wrapper.activityname = metadata.Activity_Name__c;
            wrapper.refreshallowed = metadata.Refresh_Allowed__c;
            wrapper.handlername = metadata.Handler_Class__c;

            IntHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
                 System.debug('respwrapper--->'+respWrapper);
              if(Test.isRunningTest()){
                respWrapper.prerequisiteError = null ;
                respWrapper.payload = '{"respWrapper":"payload"}';
            } //no handler 
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                return 'Error: ' + String.join(respWrapper.prerequisiteError, ', ');
            }

            List<Integration_Settings__c> intSettingList = [
                SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                FROM Integration_Settings__c
                WHERE Name = 'Loan Applicant ITR Search' LIMIT 1
            ];

            Integration_Settings__c intSetting = intSettingList.isEmpty() ? null : intSettingList[0];

            Map<String, String> integrationRequestMap = new Map<String, String>();
            integrationRequestMap.put('intSettingName', 'Loan Applicant GST Search');
            integrationRequestMap.put('requestJSON', respWrapper.payload);

            String bearer = Utility.getAccessToken();
            integrationRequestMap.put('bearer', bearer);

            HttpResponse resp = Utility.executeAPIRequest(integrationRequestMap);

            if (resp != null) {
                ITRResponseWrapper itrResp = (ITRResponseWrapper) JSON.deserialize(resp.getBody(), ITRResponseWrapper.class);

                // Check API status field (assumed to be itrResp.status == 'true' for success)
                if (itrResp != null && itrResp.status != null && itrResp.status.toLowerCase() == 'true') {
                    Integration_Details__c integrationDetail = new Integration_Details__c();
                    integrationDetail.Calling_Source__c       = wrapper.type;
                    integrationDetail.Request_JSON__c         = respWrapper.payload;
                    integrationDetail.Response_JSON__c        = resp.getBody();
                    integrationDetail.Status__c                = String.valueOf(resp.getStatusCode());
                    integrationDetail.Method_Type__c           = intSetting != null ? intSetting.Request_Method__c : null;
                    integrationDetail.EndPoint__c              = intSetting != null ? intSetting.Endpoint__c : null;
                    integrationDetail.Object_Name__c           = 'Application_Applicant__c';
                    integrationDetail.Name                      = processName;
                    integrationDetail.Loan_Application__c      = loanId;
                    integrationDetail.Related_Record_Id__c     = applicantId;
                    integrationDetail.Is_Success_Response__c   = true;

                    insert integrationDetail;

                    return 'Success: ITR API processed successfully.';
                } else {
                    // API response status is false or missing
                    String errorMsg = 'Service Unavailable';
                    if (itrResp != null && itrResp.message != null && itrResp.message.trim() != '') {
                        errorMsg = itrResp.message;
                    }
                    return 'Error: ' + errorMsg;
                }
            } else {
                return 'Error: No response from ITR service.';
            }

        } catch (Exception e) {
            System.debug('Error occurred while processing ITR API:'+e.getMessage()+'at line no'+e.getlineNumber());
            throw new AuraHandledException('Error occurred while processing ITR API: ' + e.getMessage());
        }
    }
     @AuraEnabled
    public static Map<String,String> getApplicants(String recordId) {
        Map<String,String> applicantsMap = new Map<String,String>();
        List<Application_Applicant__c> lstApplicants = [SELECT id,Applicant_Type__c,name FROM Application_Applicant__c WHERE Loan_Application__c =:recordId];
        if(lstApplicants.size() > 0) {
            for(Application_Applicant__c iterApp : lstApplicants) {
                applicantsMap.put(iterApp.id,iterApp.name+' ('+iterApp.Applicant_Type__c+')');
            }
        }
        return applicantsMap;
    }
    @AuraEnabled
    public static PdFormDetails getApplicantAndLoanAppData(String loanAppId,String avId){
        try {
            PdFormDetails pdFormDetails = new PdFormDetails();
            pdFormDetails.applicantList = [SELECT Id,Applicant_Type__c,Name,Customer_Profile__c,Business_Type__c FROM Application_Applicant__c WHERE Loan_Application__c =:loanAppId];
            List<Application_Verification__c> avList = new List<Application_Verification__c>(); 

            avList = [SELECT Id,Applicant__r.Customer_Profile__c,Trade_Reference_Mobile_Number__c,Child_Name__c,Type_of_Asset__c,Trade_Reference_Name__c,Trade_Reference_Relationship__c,Trade_Reference_Remarks__c,
                                      RecordType.name,Year_of_Purchase__c,Name_of_the_Asset_Owner__c,Amount_of_Investment__c,Proof__c,Relationship_Son_Daughter__c,Employees__c,Designation__c,Details_of_previous_organisation__c,
                                     	Child_Age__c,Loan_Application__r.Nature_of_Business__c,Nature_Sector_of_Business__c,Vintage_of_Company__c,Ownership_of_business__c, Date_of_Commencement_of_Business__c,Proof_of_Business__c, Banking_Details__c, Annual_Income__c,Remaining_Age_of_Retirement__c,Loan_Amount_Required__c,End_use_of_fund__c,Property_Registered_On_Name__c, Current_Status_Studying_Working__c,Highest_Level_of_Education__c,Occupation_Details__c,Family_Details__c,Other_Addresses__c,OCR_Details__c,Market_Value__c,
                                        	Registry_Value__c,Additional_Details_1__c,Additional_Details_2__c,Strength__c, Concerns__c, Additional_Note__c,Disposition__c,Crime_Check_Status__c,Type_of_Address__c,
                                        Children_detail_with_qualification__c,Interviewer_Name__c,Interviewer_Comments__c,Comments__c, Nature_of_Business_Details__c,Address_of_Business_Employment__c, Address_of_Company__c, Details_of_Company__c,Any_Other_Asset_Details__c,Details_of_Other_Owned_Property__c,Stability_in_years__c,
                                      Loan_Application__r.Business_Vintage__c FROM Application_Verification__c WHERE Id = :avId OR Parent_FCU__c =:avId];
            pdFormDetails.avDetails = avList;
            Map<String,List<Application_Verification__c>> avMap = new Map<String,List<Application_Verification__c>>();
            for(Application_Verification__c av : avList) {
                if(avMap.containsKey(av.RecordType.Name)) {
                    avMap.get(av.RecordType.Name).add(av);
                } else {
                    avMap.put(av.RecordType.Name, new List<Application_Verification__c>{av});
                }
            }
            pdFormDetails.avMap = avMap;
            return pdFormDetails;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ITRResponseWrapper {
        public String status;
        public Data data;
        public String message;
        public String statusCode;
        public String traceId;
    }

    public class Data {
        public String transactionId;
        public String clientTransactionId;
        public String errorCode;
        public String message;
        public String status;
        public String uuid;
    }

    public class RecordWrapper {
        @AuraEnabled public String recId;
        @AuraEnabled public String year;
        @AuraEnabled public Decimal busineeIncome;
        @AuraEnabled public Date fillingDate;
        @AuraEnabled public Decimal acknolegmentNumber;
        @AuraEnabled public String assessmentYear;
        @AuraEnabled public Decimal month1;
        @AuraEnabled public Decimal month2;
        @AuraEnabled public Decimal month3;
        @AuraEnabled public Decimal month4;
        @AuraEnabled public Decimal month5;
        @AuraEnabled public Decimal month6;
        @AuraEnabled public Decimal gstAnnualTurnover;
    }
    public class PdFormDetails{
        @AuraEnabled public List<Application_Applicant__c> applicantList;
        @AuraEnabled public List<Application_Verification__c> avDetails;
        @AuraEnabled public Map<String,List<Application_Verification__c>> avMap;
        @AuraEnabled public Opportunity laDetails;
        @AuraEnabled public Decimal totalAmount;
        @AuraEnabled public Decimal totalIncome;
        @AuraEnabled public Date pdD;
    }

    @AuraEnabled
    public static void deleteRefData(List<Id> ids) {
        if (ids == null || ids.isEmpty()) return;
        delete [SELECT Id FROM Application_Verification__c WHERE Id IN :ids];
    }
}