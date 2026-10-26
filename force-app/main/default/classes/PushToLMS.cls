public without sharing class PushToLMS {
    
    @TestVisible private static String  testOverrideReturnText  = null;
    @TestVisible private static String  testOverrideNewLmsId    = null;
    @TestVisible private static Boolean testAllowCustAddrUpsert = false;
    
    private static final String VISUAL_MARKER = '🔴';
    
    
    public class InitialDataWrapper {
        @AuraEnabled public String  requiredLoanId;
        @AuraEnabled public Boolean childLoan;
        @AuraEnabled public List<ApplicantInfo>  applicants;
        @AuraEnabled public List<CollateralInfo> collaterals;
    }
    
    public class ApplicantInfo {
        @AuraEnabled public String  applicantId;
        @AuraEnabled public String  customerId;
        @AuraEnabled public Boolean existingCustomer;
        @AuraEnabled public String  applicantType;
        @AuraEnabled public String  customerLmsId;
    }
    
    public class CollateralInfo {
        @AuraEnabled public String appColId;
        @AuraEnabled public String collateralId;
        @AuraEnabled public String collateralName;
        @AuraEnabled public String plfId;
    }
    
    public class ApplicantUpsertResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String  lmsId;
        @AuraEnabled public String  customerId;
        @AuraEnabled public String  applicantType;
        @AuraEnabled public String  errorMessage;
        @AuraEnabled public String  existingCustMsg;
    }
    
    public class CollateralProcessResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String  colRef;
        @AuraEnabled public String  appColId;
        @AuraEnabled public String  errorMessage;
    }
    
    public class CreateFinanceResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String  finReference;
        @AuraEnabled public String  errorMessage;
    }
    
    
    @AuraEnabled
    public static void updateLoanTransactionQDPFields(Id loanApplicationId) {
        try {
            if (loanApplicationId == null) {
                return;
            }
            
            List<Loan_Transaction__c> updateList = new List<Loan_Transaction__c>();
            for (Loan_Transaction__c loan : [
                SELECT Id
                FROM   Loan_Transaction__c
                WHERE  Loan_Application__c      = :loanApplicationId
                AND    RecordType.DeveloperName IN ('Transaction_Details', 'Payment')
            ]) {
                Loan_Transaction__c updatedLoan = new Loan_Transaction__c();
                updatedLoan.Id                    = loan.Id;
                updatedLoan.Quick_Disbursement__c = true;
                updatedLoan.STP__c                = false;
                updatedLoan.QDP_Status__c         = 'Awaiting for confirmation';
                updatedLoan.Process_Stage__c      = 'OPS Maker2';
                updateList.add(updatedLoan);
            }
            
            if (!updateList.isEmpty()) {
                AHL_LoanTransactionTriggerHandler.isTriggerDisabled = true;
                try {
                    update updateList;
                } finally {
                    AHL_LoanTransactionTriggerHandler.isTriggerDisabled = false;
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
            'PushToLMS->updateLoanTransactionQDPFields :: ' + e.getMessage()
                + ' STACK: ' + e.getStackTraceString());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{
                Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(),
                'PushToLMS_updateLoanTransactionQDPFields', '', '')
            });
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    
    
    @AuraEnabled
    public static Boolean getUseLmsNewLogic() {
        lms_settings__c settings = [select use_new_logic__c from lms_settings__c limit 1];
        return settings.use_new_logic__c;
    }
    
    
    @AuraEnabled
    public static InitialDataWrapper getInitialData(Id loanApplicationId) {
        try {
            InitialDataWrapper wrapper = new InitialDataWrapper();
            
            Opportunity loanApp = [
                SELECT Id, Loan_Hierarchy__c, Split_Parent_Loan_Application__c
                FROM   Opportunity
                WHERE  Id = :loanApplicationId
                LIMIT  1
            ];
            
            String  requiredLoanId = loanApplicationId;
            Boolean childLoan      = false;
            if (loanApp.Loan_Hierarchy__c == 'Child'
            && loanApp.Split_Parent_Loan_Application__c != null) {
                requiredLoanId = loanApp.Split_Parent_Loan_Application__c;
                childLoan      = true;
            }
            
            wrapper.requiredLoanId = requiredLoanId;
            wrapper.childLoan      = childLoan;
            
            List<String> excludeAppTypeList =
                System.label.excludeAppTypeList.split(',');
            
            List<Application_Applicant__c> applicantList = [
                SELECT Id, Customer_LMS_Id__c, Customer__c,
                       Existing_Customer__c, Applicant_Type__c
                FROM   Application_Applicant__c
                WHERE  Loan_Application__c = :requiredLoanId
                AND    Applicant_Type__c NOT IN :excludeAppTypeList
            ];
            
            wrapper.applicants = new List<ApplicantInfo>();
            for (Application_Applicant__c app : applicantList) {
                ApplicantInfo ai    = new ApplicantInfo();
                ai.applicantId      = app.Id;
                ai.customerId       = app.Customer__c;
                ai.existingCustomer = app.Existing_Customer__c;
                ai.applicantType    = app.Applicant_Type__c;
                ai.customerLmsId    = app.Customer_LMS_Id__c;
                wrapper.applicants.add(ai);
            }
            
            List<Application_Collateral__c> appColList = [
                SELECT Id, HL_Loan_Application__c, Collateral__r.Name,
                       Collateral__c, Collateral__r.PLF_ID__c
                FROM   Application_Collateral__c
                WHERE  HL_Loan_Application__c = :requiredLoanId
                ORDER BY CreatedDate DESC
            ];
            
            wrapper.collaterals = new List<CollateralInfo>();
            for (Application_Collateral__c ac : appColList) {
                CollateralInfo ci = new CollateralInfo();
                ci.appColId       = ac.Id;
                ci.collateralId   = ac.Collateral__c;
                
                // Wrap the actual collateral name with the visual marker. The
                // LWC builds error messages as
                //     'For Collateral ' + collateral.collateralName + ': ' + ...
                // so the marker decoration here makes the name pop visually
                // without any LWC change. `collateralName` is only consumed by
                // the LWCs for error display, so this decoration has no other
                // side-effect. (Heads-up to test authors: tests asserting on
                // the exact name string need to account for this prefix/suffix.)
                String rawColName = (ac.Collateral__r != null
                    && String.isNotBlank(ac.Collateral__r.Name))
                    ? ac.Collateral__r.Name : '';
                ci.collateralName = String.isNotBlank(rawColName)
                    ? VISUAL_MARKER + ' ' + rawColName + ' ' + VISUAL_MARKER
                    : rawColName;
                
                ci.plfId = (ac.Collateral__r != null)
                    ? ac.Collateral__r.PLF_ID__c : null;
                wrapper.collaterals.add(ci);
            }
            
            return wrapper;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
            'PushToLMS->getInitialData :: ' + e.getMessage()
                + ' STACK: ' + e.getStackTraceString());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{
                Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(),
                'PushToLMS_getInitialData', '', '')
            });
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    
    
    @AuraEnabled
    public static ApplicantUpsertResult upsertApplicant(
    Id loanApplicationId, Id applicantId) {
        
        ApplicantUpsertResult result = new ApplicantUpsertResult();
        result.success = false;
        
        // Built right after the applicant SOQL; available to all error paths
        // and to the catch block (which wraps it into the thrown
        // AuraHandledException so the LWC's _isError fallback also surfaces
        // the applicant name/type). Stays empty if the applicant SOQL itself
        // fails - in which case the user just gets the raw error message.
        String applicantInfo = '';
        
        try {
            Application_Applicant__c applicant = [
                SELECT Id, Name, Customer_LMS_Id__c, Customer__c,
                       Existing_Customer__c, Applicant_Type__c
                FROM   Application_Applicant__c
                WHERE  Id = :applicantId
                LIMIT  1
            ];
            // Format: 🔴 [Applicant Name — Applicant Type]   (em-dash via \u2014)
            applicantInfo = VISUAL_MARKER + ' [' + applicant.Name
                + ' \u2014 ' + applicant.Applicant_Type__c + '] ';
            
            result.customerId    = applicant.Customer__c;
            result.applicantType = applicant.Applicant_Type__c;
            
            Integration_Master__mdt metadata = [
                SELECT Process_Name__c, Handler_Class__c, Endpoint__c,
                       Request_Method__c, Client_Id__c, Client_Secret__c,
                       Allowed_Retry__c, Gestation_Period__c,
                       Refresh_Allowed__c, Activity_Name__c
                FROM   Integration_Master__mdt
                WHERE  Activity_Name__c = 'Upsert Customer'
                LIMIT  1
            ];
            
            String checkEndpoint = String.isBlank(applicant.Customer_LMS_Id__c)
                ? 'Callout:LOS_BL_CREATE_CUSTOMER'
                : 'Callout:LOS_BL_UPDATE_CUSTOMER';
            
            List<Integration_Details__c> prevIntegrations = [
                SELECT Id FROM Integration_Details__c
                WHERE  Loan_Application__c = :loanApplicationId
                AND    Status__c            = '200'
                AND    Endpoint__c          = :checkEndpoint
                AND    Related_Record_Id__c = :applicantId
            ];
            Integer prevCount = prevIntegrations.size();
            
            List<Customer_Address__c> custAddrList = new List<Customer_Address__c>();
            if (prevCount == 0) {
                Set<String> applicantIdSet = new Set<String>{ applicantId };
                Map<String, Map<String, Applicant_Address__c>> mapApplicantAddr =
                    AHL_LoanApplicationActionController.getApplicantAddress(applicantIdSet);
                
                List<Applicant_Address__c> listAddr =
                    new List<Applicant_Address__c>();
                if (mapApplicantAddr.containsKey(applicantId)) {
                    listAddr.addAll(mapApplicantAddr.get(applicantId).values());
                }
                Map<String, String> mapcustomerAddrIds = new Map<String, String>();
                for (Applicant_Address__c addr : listAddr) {
                    mapcustomerAddrIds.put(addr.Id, addr.Customer_Address__c);
                }
                for (Applicant_Address__c appAddr : listAddr) {
                    Customer_Address__c custAddr = new Customer_Address__c();
                    if (String.isNotBlank(mapcustomerAddrIds.get(appAddr.Id))) {
                        custAddr.Id = mapcustomerAddrIds.get(appAddr.Id);
                    }
                    custAddr.Address_Type__c          = appAddr.Address_Type__c;
                    custAddr.Building_Street_Name__c  = appAddr.Building_Street_Name__c;
                    custAddr.Address_Line_1__c        = appAddr.Address_Line_1__c;
                    custAddr.Address_Line_2__c        = appAddr.Address_Line_2__c;
                    custAddr.Address_Line_3__c        = appAddr.Address_Line_3__c;
                    custAddr.Pincode__c               = appAddr.Pincode__c;
                    custAddr.Customer__c              = applicant.Customer__c;
                    custAddr.Is_Active__c             = true;
                    custAddrList.add(custAddr);
                }
            }
            
            IntHandler.ProcessReqWrapper reqWrapper =
                new IntHandler.ProcessReqWrapper();
            reqWrapper.recordId          = loanApplicationId;
            reqWrapper.loanApplicationId = loanApplicationId;
            reqWrapper.applicantId       = applicantId;
            reqWrapper.type              = 'Upsert Customer';
            reqWrapper.endpoint          = metadata.Endpoint__c;
            reqWrapper.requestMethod     = metadata.Request_Method__c;
            reqWrapper.clientId          = metadata.Client_Id__c;
            reqWrapper.clientSecret      = metadata.Client_Secret__c;
            reqWrapper.allowedRetry      = metadata.Allowed_Retry__c;
            reqWrapper.gestationPeriod   = metadata.Gestation_Period__c;
            reqWrapper.activityname      = metadata.Activity_Name__c;
            reqWrapper.refreshallowed    = metadata.Refresh_Allowed__c;
            reqWrapper.handlername       = metadata.Handler_Class__c;
            
            IntHandler.processResWrapper respWrapper =
                IntHandler.validateProcess(reqWrapper);
            System.debug('PushToLMS upsertApplicant respWrapper = ' + respWrapper);
            
            // ----- prerequisite errors -----
            if (respWrapper.prerequisiteError != null
            && !respWrapper.prerequisiteError.isEmpty()) {
                result.errorMessage = applicantInfo
                    + String.join(respWrapper.prerequisiteError, '; ');
                return result;
            }
            
            Map<String, String> requestInput = new Map<String, String>();
            String apiName;
            if (applicant.Existing_Customer__c) {
                apiName = 'Update Customer';
                requestInput.put('endPoint',    'callout:LOS_BL_UPDATE_CUSTOMER');
                requestInput.put('serviceName', 'updateCustomer');
            } else {
                apiName = 'Create Customer';
                requestInput.put('endPoint',    'callout:LOS_BL_CREATE_CUSTOMER');
                requestInput.put('serviceName', 'createCustomer');
            }
            requestInput.put('reqBody', respWrapper.payload);
            
            Integration_Settings__c intSettings = [
                SELECT Id, Name, Authorization__c, Content_Type__c, Cookie__c,
                       Request_Method__c, Message_Id__c, Entity_Id__c
                FROM   Integration_Settings__c
                WHERE  Name = :apiName
                LIMIT  1
            ];
            
            String bearer = Utility.getAccessToken();
            requestInput.put('Authorization', 'Bearer ' + bearer);
            requestInput.put('Cookie',        intSettings.Cookie__c);
            requestInput.put('MESSAGEID',     intSettings.Message_Id__c);
            requestInput.put('ENTITYID',      intSettings.Entity_Id__c);
            requestInput.put('Content-Type',  intSettings.Content_Type__c);
            requestInput.put('method',        intSettings.Request_Method__c);
            
            HTTPResponse res = executeHTTPRequest(requestInput);
            
            Map<String, String> intDetailInput = new Map<String, String>();
            intDetailInput.put('reqBody',     respWrapper.payload);
            intDetailInput.put('resBody',     res.getBody());
            intDetailInput.put('method',      requestInput.get('method'));
            intDetailInput.put('endPoint',    requestInput.get('endPoint'));
            intDetailInput.put('serviceName', requestInput.get('serviceName'));
            intDetailInput.put('loanId',      loanApplicationId);
            intDetailInput.put('applicantId', applicantId);
            
            if (res.getStatusCode() == 200) {
                
                String returnText   = '';
                String responseBody = res.getBody();
                String newLmsId     = '';
                
                if (testOverrideReturnText != null) {
                    returnText = testOverrideReturnText;
                    newLmsId   = testOverrideNewLmsId != null
                        ? testOverrideNewLmsId : '';
                    if (requestInput.get('serviceName') == 'createCustomer'
                    && String.isNotBlank(newLmsId)) {
                        result.lmsId = newLmsId;
                    }
                } else {
                    Map<String, Object> responseMap =
                        (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                    newLmsId = (String) responseMap.get('cif');
                    
                    if (requestInput.get('serviceName') == 'createCustomer') {
                        result.lmsId = String.isNotBlank(newLmsId) ? newLmsId : null;
                        Map<String, Object> returnStatus =
                            (Map<String, Object>) responseMap.get('returnStatus');
                        returnText = (String) returnStatus.get('returnText');
                    } else {
                        returnText = (String) responseMap.get('returnText');
                    }
                }
                
                System.debug('PushToLMS upsertApplicant returnText = ' + returnText);
                
                if (returnText == 'Success') {
                    intDetailInput.put('status', String.valueOf(res.getStatusCode()));
                    result.success = true;
                    
                    if (String.isNotBlank(newLmsId)) {
                        List<Account> accList = [
                            SELECT Id, Customer_LMS_Id__c, Exisiting_Customer__c
                            FROM   Account
                            WHERE  Id = :applicant.Customer__c
                        ];
                        if (!accList.isEmpty()
                        && String.isBlank(accList[0].Customer_LMS_Id__c)) {
                            accList[0].Customer_LMS_Id__c    = newLmsId;
                            accList[0].Exisiting_Customer__c = true;
                            update accList;
                        }
                    }
                    
                    if (!custAddrList.isEmpty()
                    && (!System.Test.isRunningTest() || testAllowCustAddrUpsert)) {
                        upsert custAddrList;
                    }
                    
                } else if (String.isNotBlank(returnText)
                && returnText.contains('already exists for Customer CIF:')) {
                    result.existingCustMsg = returnText;
                    intDetailInput.put('status', '304');
                    
                } else {
                    result.errorMessage = applicantInfo
                        + 'Create/Update Customer Error: ' + res.getBody();
                    intDetailInput.put('status', '304');
                }
                
            } else {
                intDetailInput.put('status', String.valueOf(res.getStatusCode()));
                result.errorMessage = applicantInfo
                    + 'Create/Update Customer Error: ' + res.getBody();
                System.debug('PushToLMS upsertApplicant HTTP error code = '
                    + res.getStatusCode());
            }
            
            Integration_Details__c intDetail =
                AHL_LoanApplicationActionController.createIntegrationDetail(intDetailInput);
            insert intDetail;
            
            return result;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
            'PushToLMS->upsertApplicant :: ' + e.getMessage()
                + ' STACK: ' + e.getStackTraceString());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{
                Utility.fillErrorRecord(e.getMessage(),
                e.getStackTraceString(),
                'PushToLMS_upsertApplicant', '', '')
            });
            // applicantInfo is included in the thrown message so even when the
            // LWC takes the .catch() (_isError) path - which builds the error
            // string client-side from err.body.message - the user still sees
            // which applicant failed.
            throw new AuraHandledException(applicantInfo + 'Error: ' + e.getMessage());
        }
    }
    
    
    @AuraEnabled
    public static Boolean handleExistingCIFUpdate(List<String> messages) {
        try {
            if (messages == null || messages.isEmpty()) return false;
            
            Map<Id, Account> cifToUpdate =
                AHL_LoanApplicationActionController.handleExistingCIF(messages);
            
            if (cifToUpdate != null && !cifToUpdate.isEmpty()) {
                update cifToUpdate.values();
                return true;
            }
            return false;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
            'PushToLMS->handleExistingCIFUpdate :: ' + e.getMessage()
                + ' STACK: ' + e.getStackTraceString());
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    
    
    @AuraEnabled
    public static CollateralProcessResult processCollateral(
        Id     loanApplicationId,
    Id     appColId,
    String primaryCif) {
        
        CollateralProcessResult result = new CollateralProcessResult();
        result.appColId = appColId;
        result.success  = false;
        
        try {
            Map<String, String> inputParamsCollateral = new Map<String, String>{
                'loanId'      => loanApplicationId,
                'processName' => 'Create Collateral',
                'appColId'    => appColId
            };
            inputParamsCollateral.put('primaryApplicantCif', primaryCif);
            
            Map<String, Object> colResp =
                COMM_CreateCollateralApiController.initiateAPIRequest(inputParamsCollateral);
            
            if (!colResp.containsKey('colRespObj')) {
                result.errorMessage = 'Collateral API returned no response object';
                return result;
            }
            
            COMM_CreateCollateralApiController.CollateralResponse respObj =
                (COMM_CreateCollateralApiController.CollateralResponse)
                colResp.get('colRespObj');
            
            if (colResp.containsKey('intDetailObj')) {
                Integration_Details__c intDet =
                    (Integration_Details__c) colResp.get('intDetailObj');
                if (intDet != null) {
                    insert intDet;
                }
            }
            
            if (respObj != null && respObj.returnStatus != null
            && respObj.returnStatus.returnText == 'Success') {
                
                result.colRef  = String.isNotBlank(respObj.collateralRef)
                    ? respObj.collateralRef : '';
                result.success = true;
                
                if (String.isNotBlank(result.colRef)) {
                    Application_Collateral__c appCol = [
                        SELECT Id, Collateral__c
                        FROM   Application_Collateral__c
                        WHERE  Id = :appColId
                        LIMIT  1
                    ];
                    List<Collateral__c> colList = [
                        SELECT Id, PLF_ID__c
                        FROM   Collateral__c
                        WHERE  Id = :appCol.Collateral__c
                        LIMIT  1
                    ];
                    if (!colList.isEmpty()
                    && String.isBlank(colList[0].PLF_ID__c)) {
                        colList[0].PLF_ID__c = result.colRef;
                        update colList[0];
                    }
                }
                
            } else {
                String returnText =
                    (respObj != null && respObj.returnStatus != null)
                    ? respObj.returnStatus.returnText
                    : 'Collateral processing failed';
                // Note: we deliberately do NOT prefix the collateral name
                // here. The LWC already builds the error string as
                //     'For Collateral ' + collateral.collateralName + ': ' + ...
                // and `collateralName` arrives from getInitialData already
                // wrapped with the visual marker, so prefixing here would
                // duplicate the name in the displayed message.
                result.errorMessage = returnText;
            }
            
            return result;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
            'PushToLMS->processCollateral :: ' + e.getMessage()
                + ' STACK: ' + e.getStackTraceString());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{
                Utility.fillErrorRecord(e.getMessage(),
                e.getStackTraceString(),
                'PushToLMS_processCollateral', '', '')
            });
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    
    
    // ─── callCreateFinance ───────────────────────────────────────────────────
    @AuraEnabled
    public static CreateFinanceResult callCreateFinance(
        Id      loanApplicationId,
    Boolean isQdp,
    String  colRefMapJSON,
    String  lmsIdMapJSON,
    Boolean childLoan) {
        
        CreateFinanceResult result = new CreateFinanceResult();
        result.success = false;
        
        try {
            Map<String, String> colRefMap =
                (Map<String, String>) JSON.deserialize(
                colRefMapJSON, Map<String, String>.class);
            Map<String, String> lmsIdMap =
                (Map<String, String>) JSON.deserialize(
                lmsIdMapJSON, Map<String, String>.class);
            
            Opportunity loanApp = [
                SELECT Id, Loan_Hierarchy__c, Split_Parent_Loan_Application__c
                FROM   Opportunity
                WHERE  Id = :loanApplicationId
                LIMIT  1
            ];
            String requiredLoanId = loanApplicationId;
            if (loanApp.Loan_Hierarchy__c == 'Child'
            && loanApp.Split_Parent_Loan_Application__c != null) {
                requiredLoanId = loanApp.Split_Parent_Loan_Application__c;
            }
            
            List<Application_Collateral__c> appColList = [
                SELECT Id, HL_Loan_Application__c, Collateral__c,
                       Collateral__r.Name, Collateral__r.PLF_ID__c
                FROM   Application_Collateral__c
                WHERE  HL_Loan_Application__c = :requiredLoanId
                ORDER BY CreatedDate DESC
            ];
            
            Map<String, Map<String, String>> cfInputMapForCollateral =
                new Map<String, Map<String, String>>();
            
            Map<String, String> inputMap = new Map<String, String>{
                'loanId'      => loanApplicationId,
                'processName' => 'Create Finance AHL',
                'isQdp'       => String.valueOf(isQdp)
            };
            
            Map<String, String> colRefIdMap = new Map<String, String>();
            for (Application_Collateral__c ac : appColList) {
                String colRef = '';
                if (colRefMap.containsKey(ac.Id)) {
                    colRef = colRefMap.get(ac.Id);
                } else if (String.isNotBlank(ac.Collateral__r.PLF_ID__c)) {
                    colRef = ac.Collateral__r.PLF_ID__c;
                }
                colRefIdMap.put(ac.Id, colRef);
            }
            
            cfInputMapForCollateral.put('colRefId', colRefIdMap);
            cfInputMapForCollateral.put('inputMap', inputMap);
            
            System.debug('PushToLMS callCreateFinance: invoking CreateFinanceAhlController');
            CreateFinanceResponseWrapper finResp =
                CreateFinanceAhlController.initiateAPIRequest(
                cfInputMapForCollateral, lmsIdMap);
            
            if (finResp != null && finResp.returnStatus != null) {
                
                if (finResp.returnStatus.returnText == 'Success') {
                    result.success      = true;
                    result.finReference = finResp.finReference;
                    
                    if (finResp.disbursement != null) {
                        Map<String, Integer> mapDisbursement =
                            new Map<String, Integer>();
                        for (CreateFinanceResponseWrapper.Disbursement disb
                        : finResp.disbursement) {
                            mapDisbursement.put(disb.remarks, disb.paymentId);
                        }
                        List<Loan_Transaction__c> disbRecs = [
                            SELECT Id, Name, Payment_Sequence__c, Payment_Ext_Id__c
                            FROM   Loan_Transaction__c
                            WHERE  Loan_Application__c      = :loanApplicationId
                            AND    RecordType.DeveloperName = 'Payment'
                        ];
                        for (Loan_Transaction__c disbRec : disbRecs) {
                            disbRec.Payment_Ext_Id__c =
                                mapDisbursement.containsKey(disbRec.Id)
                                ? mapDisbursement.get(disbRec.Id).toString()
                                : null;
                        }
                        update disbRecs;
                    }
                    
                } else {
                    result.errorMessage =
                        'Create Finance Error: '
                        + finResp.returnStatus.returnText;
                }
                
            } else {
                result.errorMessage =
                    'Something went wrong in the Create Finance API. '
                    + 'Please check';
            }
            
            Integer errorCount = result.success ? 0 : 1;
            publishStatusChange(loanApp, isQdp, errorCount);
            
            return result;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
            'PushToLMS->callCreateFinance :: ' + e.getMessage()
                + ' STACK: ' + e.getStackTraceString());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{
                Utility.fillErrorRecord(e.getMessage(),
                e.getStackTraceString(),
                'PushToLMS_callCreateFinance', '', '')
            });
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    
    
    private static void publishStatusChange(
        Opportunity loanApplication,
    Boolean     isQdp,
    Integer     errorCount) {
        
        String targetSubStage;
        if (errorCount == 0 && !isQdp) {
            targetSubStage = 'Disbursed';
        } else if (isQdp && errorCount > 0) {
            targetSubStage = 'Ops Maker';
        }
        
        LoanApplicationStageChange__e evt =
            new LoanApplicationStageChange__e(
            loanApplicationId__c = loanApplication.Id,
        Sub_Stage__c         = targetSubStage
            );
        
        Database.SaveResult sr = EventBus.publish(evt);
        if (!sr.isSuccess()) {
            for (Database.Error e : sr.getErrors()) {
                System.debug(LoggingLevel.ERROR,
                'PushToLMS publishStatusChange: Platform Event failed: '
                    + e.getMessage());
            }
        }
    }
    
    
    public static HTTPResponse executeHTTPRequest(
    Map<String, String> integrationInput) {
        try {
            Http        http    = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(integrationInput.get('endPoint'));
            request.setMethod(integrationInput.get('method'));
            request.setTimeout(120000);
            request.setHeader('Content-Type',
            integrationInput.get('Content-Type'));
            request.setHeader('Authorization',
            integrationInput.get('Authorization'));
            request.setHeader('Cookie',
            integrationInput.get('Cookie'));
            request.setHeader('MESSAGEID',
            integrationInput.get('MESSAGEID'));
            request.setHeader('Language',       'ENG');
            request.setHeader('ServiceName',
            integrationInput.get('serviceName'));
            request.setHeader('ENTITYID',
            integrationInput.get('ENTITYID'));
            request.setHeader('ServiceVersion', '1');
            request.setHeader('RequestTime',
            Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss'));
            request.setBody(integrationInput.get('reqBody'));
            
            System.debug('PushToLMS HTTP request body: '
                + integrationInput.get('reqBody'));
            HTTPResponse res = http.send(request);
            System.debug('PushToLMS HTTP response: ' + res.getBody());
            return res;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
            'PushToLMS->executeHTTPRequest :: ' + e.getMessage()
                + ' STACK: ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
}