public class COMM_CreateCollateralApiHandler implements IntegrationInterface {

    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String applicationId = wrapper.loanApplicationId;
        String primaryAppCif = wrapper.applicantId;
        String appColId      = wrapper.appColId;          // NEW: read appColId from wrapper
        String disableFlag    = Label.CreateFinanceDisableFlag;
        String disableMessage = Label.CreateFinanceDisableMessage;

        if (disableFlag == 'true') {
            errorMessages.add(disableMessage);
        }

        // Defensive guard - prevents List index out of bounds if appColId is missing
        if (String.isBlank(appColId)) {
            errorMessages.add('Application Collateral Id is missing in the request');
            return errorMessages;
        }

        // CHANGED: query by Id (appColId) instead of HL_Loan_Application__c + ORDER BY ... LIMIT 1
        List<Application_Collateral__c> appColList = [
            SELECT Id, Collateral__c, Collateral__r.Pincode__r.City__r.Country__c, Collateral__r.Project__r.Record_Sync__c,
                   Collateral__r.Project__r.Project_Id__c, Collateral__r.Street_Name__c, Collateral__r.Project__r.New_APF_No__c,
                   Collateral__r.Pincode__r.City__r.Name, Collateral__r.Unit_Project__r.Name,
                   Collateral__r.Collateral_Type__c, Collateral__r.Unit_Property_Type__c, Collateral__r.Pincode__r.District__c,
                   Collateral__r.Pincode__r.Country__c, Collateral__r.Survey_Number_Gat_No__c, Collateral__r.Market_Value__c,
                   Collateral__r.Pocket__c, Collateral__r.Project__c, Collateral__r.Unit_Project__c,
                   Construction_RR_Estimate__c, HL_Loan_Application__c, Name_of_Collateral__c, Collateral_Sampling_Check__c,
                   Asset_Type__c, State__c, Total_Valuation__c, Collateral__r.Current_Usage__c,
                   Collateral__r.Project__r.Total_Units__c, Collateral__r.Builder__r.Name, Collateral__r.Builder__c,
                   Collateral__r.House_Flat_Shop_Unit_No__c, Collateral__r.Building_Name__c, Collateral__r.Plot_Number__c,
                   Collateral__r.Unit_Project__r.Price__c, Collateral__r.Construction_Stage__c, Collateral__r.Pincode__c,
                   Collateral__r.Pincode__r.City__r.City_Code__c, Collateral__r.Project__r.APF_No__c, Collateral__r.Mortgage_Type__c,
                   Collateral__r.Address_Line_1__c, Collateral__r.Address_Line_2__c, Collateral__r.Address_Line_3__c,
                   Collateral__r.Project__r.APF_ID__c, Collateral__r.Pincode__r.Name, Collateral__r.Estimated_Value__c,
                   Collateral__r.Pincode__r.City__r.State__c, Collateral__r.Unit_Project__r.Unit_Type__c,
                   Collateral__r.Floor_Number__c, Collateral__r.Unit_Number__c, Collateral__r.Unit_Project__r.Tower__c,
                   Collateral__r.Reason__c
            FROM   Application_Collateral__c
            WHERE  Id = :appColId
            LIMIT  1
        ];

        if (appColList.isEmpty()) {
            errorMessages.add('No Application Collateral found for the provided Id');
            return errorMessages;
        }

        Application_Collateral__c appColObj = appColList[0];

        if (appColObj.Collateral__r.Pincode__c != null
                && appColObj.Collateral__r.Pincode__r.City__c != null
                && String.isBlank(appColObj.Collateral__r.Pincode__r.City__r.City_Code__c)) {
            errorMessages.add('City Code is missing for the Collateral');
        }
        if (appColObj.Collateral__c == null) {
            errorMessages.add('Collateral is Not Present');
        }
        if (appColObj.Collateral__c != null) {
            if (appColObj.Collateral__r.Pincode__c == null) {
                errorMessages.add('Pin code is missing for the Collateral');
            }
            if (appColObj.Collateral__r.Estimated_Value__c == null) {
                errorMessages.add('Estimated Value is missing for the Collateral');
            }
            if (String.isBlank(appColObj.Collateral__r.Address_Line_1__c)
                    || String.isBlank(appColObj.Collateral__r.Address_Line_2__c)
                    || String.isBlank(appColObj.Collateral__r.Address_Line_3__c)) {
                errorMessages.add('Address Line 1/2/3 is missing for the Collateral');
            }
            if (appColObj.Collateral__r.Market_Value__c == null) {
                errorMessages.add('Market Value is missing for the Collateral');
            }
            if (appColObj.Collateral__r.Collateral_Type__c == null) {
                errorMessages.add('Collateral Type is missing for the Collateral');
            }
            if (appColObj.Collateral__r.Current_Usage__c == null) {
                errorMessages.add('Current Usage is missing for the Collateral');
            }
            if (appColObj.Collateral__r.Unit_Property_Type__c == null) {
                errorMessages.add('Property Type is missing for the Collateral');
            }
            if (appColObj.Collateral__r.Construction_Stage__c == null) {
                errorMessages.add('Construction Stage is missing for the Collateral');
            }
            if (appColObj.Collateral__r.Pincode__c != null
                    && appColObj.Collateral__r.Pincode__r.City__c == null) {
                errorMessages.add('City is missing on Collateral Pincode');
            }
            if (String.isBlank(appColObj.Collateral__r.Survey_Number_Gat_No__c)) {
                errorMessages.add('Survey Number / GAT Number is missing for the Collateral');
            }
            if (String.isBlank(appColObj.Collateral__r.Street_Name__c)) {
                errorMessages.add('Street Name is missing for the Collateral');
            }
            if (String.isBlank(appColObj.Collateral__r.Pocket__c)) {
                errorMessages.add('Pocket Name is missing for the Collateral');
            }
            if (appColObj.Collateral__r.Plot_Number__c == null) {
                errorMessages.add('Plot Number is missing for the Collateral');
            }
            if (appColObj.Collateral__r.Mortgage_Type__c == null) {
                errorMessages.add('Mortgage Type is missing for the Collateral');
            }
            if (String.isBlank(appColObj.Collateral__r.House_Flat_Shop_Unit_No__c)) {
                errorMessages.add('House/Flat/Shop/Unit Number is missing for the Collateral');
            }
            if (String.isBlank(appColObj.Collateral__r.Building_Name__c)) {
                errorMessages.add('Building Name is missing for the Collateral');
            }
        }
        System.debug('ERROR MESSAGES IN VALIDATE PAYLOAD++' + errorMessages);
        return errorMessages;
    }


    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
            String applicationId = wrapper.loanApplicationId;
            String primaryAppCif = wrapper.applicantId;
            String appColId      = wrapper.appColId;       // NEW: read appColId from wrapper

            // Defensive guard
            if (String.isBlank(appColId)) {
                throw new AuraHandledException('Application Collateral Id is missing in the request');
            }

            // CHANGED: query by Id (appColId) instead of HL_Loan_Application__c + ORDER BY ... LIMIT 1
            List<Application_Collateral__c> appColList = [
                SELECT Id, Collateral__c, Collateral__r.Pincode__r.City__r.Country__c, Collateral__r.Project__r.Record_Sync__c,
                       Collateral__r.Project__r.Project_Id__c, Collateral__r.Project__r.New_APF_No__c,
                       Collateral__r.Pincode__r.City__r.Name, Collateral__r.Unit_Project__r.Name, Collateral__r.Street_Name__c,
                       Collateral__r.Collateral_Type__c, Collateral__r.Current_Usage__c, Collateral__r.Unit_Property_Type__c,
                       Collateral__r.Pincode__r.District__c, Collateral__r.Pincode__r.Country__c,
                       Collateral__r.Survey_Number_Gat_No__c, Collateral__r.Building_Name__c,
                       Collateral__r.Pocket__c, Collateral__r.Market_Value__c, Collateral__r.Project__c,
                       Collateral__r.Unit_Project__c, Construction_RR_Estimate__c,
                       HL_Loan_Application__c, Name_of_Collateral__c, Collateral_Sampling_Check__c, Asset_Type__c,
                       State__c, Total_Valuation__c, Collateral__r.Project__r.Total_Units__c, Collateral__r.Builder__r.Name,
                       Collateral__r.Unit_Project__r.Price__c, Collateral__r.Construction_Stage__c, Collateral__r.Pincode__c,
                       Collateral__r.Pincode__r.City__r.City_Code__c, Collateral__r.Project__r.APF_No__c,
                       Collateral__r.Mortgage_Type__c, Collateral__r.Address_Line_1__c, Collateral__r.Address_Line_2__c,
                       Collateral__r.Address_Line_3__c, Collateral__r.Project__r.APF_ID__c, Collateral__r.Pincode__r.Name,
                       Collateral__r.Estimated_Value__c, Collateral__r.Pincode__r.City__r.State__c,
                       Collateral__r.Unit_Project__r.Unit_Type__c, Collateral__r.Floor_Number__c, Collateral__r.Unit_Number__c,
                       Collateral__r.Unit_Project__r.Tower__c, Collateral__r.Plot_Number__c,
                       Collateral__r.Reason__c, Collateral__r.House_Flat_Shop_Unit_No__c
                FROM   Application_Collateral__c
                WHERE  Id = :appColId
                LIMIT  1
            ];

            if (appColList.isEmpty()) {
                throw new AuraHandledException('No Application Collateral found for the provided Id');
            }

            Map<String, List<String>> mapInputJSON = createRequestJSON(applicationId, appColList[0], primaryAppCif);
            List<String> reqBodyList = mapInputJSON.get('reqBody');
            String requestJSON = reqBodyList[0];

            System.debug('Request JSON: ' + requestJSON);
            return requestJSON;
        } catch (Exception ex) {
            System.debug('Error: ' + ex.getMessage());
            System.debug('Line: ' + ex.getLineNumber());
            throw new AuraHandledException('Error in Create Collateral Construct Payload' + ex.getStackTraceString());
        }
    }


    public static Map<String, List<String>> createRequestJSON(String loanId, Application_Collateral__c appColObj, String primaryAppCif) {
        Map<String, List<String>> mapInput   = new Map<String, List<String>>(); 
        Map<String, String>       plfCurr    = new Map<String, String>();
        List<String>              errorCode  = new List<String>();

        List<PLF_Master__c> plfm = [
            SELECT Id, Description__c, FICO_Code__c, Master_Type__c
            FROM   PLF_Master__c
            WHERE  (Master_Type__c = 'Current Usage LMS'
                OR  Master_Type__c = 'Address Type'
                OR  Master_Type__c = 'Collateral Type'
                OR  Master_Type__c = 'Property Type')
        ];
        for (PLF_Master__c plf : plfm) {
            if (plf.Master_Type__c == 'Current Usage LMS' 
                    || plf.Description__c == 'Semi-Urban'
                    || plf.Description__c == 'RESIDENTIAL-CUM-COMMERCIAL'
                    || plf.Description__c == 'PLOT+CONSTRUCTION') {
                plfCurr.put(plf.Description__c, plf.FICO_Code__c);
            }
        }

        String projName = '';
        if (appColObj.Collateral__c != null) {
            if (appColObj.Collateral__r.Project__c != null) {
                projName = appColObj.Collateral__r.Project__r.Record_Sync__c == true
                    ? (String.isNotBlank(appColObj.Collateral__r.Project__r.Project_Id__c)
                        ? appColObj.Collateral__r.Project__r.Project_Id__c
                        : '')
                    : (String.isNotBlank(appColObj.Collateral__r.Project__r.APF_ID__c)
                        ? String.valueOf(appColObj.Collateral__r.Project__r.APF_ID__c).replaceFirst('^0+(?!$)', '')
                        : '');
            }
        }

        Map<String, List<Application_Applicant__c>> applicantTypeToApplicantListMap =
            CreateFinanceHandler.getApplicantMap(loanId);

        try {
            CreateCollateralRequestWrapper col = new CreateCollateralRequestWrapper();
            col.cif = applicantTypeToApplicantListMap.containsKey('primary')
                ? (String.isNotBlank(applicantTypeToApplicantListMap.get('primary')[0].Customer_LMS_Id__c)
                    ? applicantTypeToApplicantListMap.get('primary')[0].Customer_LMS_Id__c
                    : primaryAppCif)
                : primaryAppCif;
            col.collateralRef        = '';
            col.collateralType       = 'PROPERTY';
            col.collateralCcy        = 'INR';
            col.maxCollateralValue   = 0;
            col.splLtv               = 0;
            col.collateralLoc        = '';
            col.valuator             = '';
            col.expiryDate           = '';
            col.alwMultiLoanAssign   = 'true';
            col.alwThirdPartyAssign  = 'true';
            col.entityCode           = 'GHF';
            col.remarks              = String.isNotBlank(appColObj.Collateral__r.Reason__c)
                                            ? appColObj.Collateral__r.Reason__c : '';

            Integer totalUnitTrim = appColObj.Collateral__r.Project__c != null
                ? (appColObj.Collateral__r.Project__r.Total_Units__c != null
                    ? Integer.valueOf(String.valueOf(appColObj.Collateral__r.Project__r.Total_Units__c)
                        .substring(0, Math.min(3, String.valueOf(appColObj.Collateral__r.Project__r.Total_Units__c).length())))
                    : null)
                : null;

            Map<String, Object> fieldMapping = new Map<String, Object>{
                'NOOFUNITS'         => totalUnitTrim ?? 1,
                'DEVELOPERNAME'     => appColObj.Collateral__r.Builder__r.Name ?? 'DEVELOPER',
                'UNITPRICE'         => appColObj.Collateral__r.Market_Value__c != null
                                        ? Utility.addTwoZeros(appColObj.Collateral__r.Market_Value__c).longValue() : null,
                'PROPERTYTYPE'      => plfCurr.containsKey(appColObj.Collateral__r.Unit_Property_Type__c)
                                        ? plfCurr.get(appColObj.Collateral__r.Unit_Property_Type__c)
                                        : appColObj.Collateral__r.Unit_Property_Type__c,
                'CONSTRUCTIONTYPE'  => appColObj.Collateral__r.Construction_Stage__c != null
                                        ? appColObj.Collateral__r.Construction_Stage__c.toUpperCase() : null,
                'CITY'              => appColObj.Collateral__r.Pincode__r.City__r.City_Code__c,
                'APFNO'             => appColObj.Collateral__r.Project__r.New_APF_No__c,
                'PROPERTYADDRESS1'  => appColObj.Collateral__r.Address_Line_1__c,
                'PROPERTYADDRESS2'  => appColObj.Collateral__r.Address_Line_2__c,
                'PROJECTNAME'       => String.isNotBlank(projName) ? projName : null,
                'PROPERTYADDRESS3'  => appColObj.Collateral__r.Address_Line_3__c,
                'PINCODE'           => appColObj.Collateral__r.Pincode__r.Name,
                'DOCVALUE'          => appColObj.Collateral__r.Estimated_Value__c != null
                                        ? Utility.addTwoZeros(appColObj.Collateral__r.Estimated_Value__c).longValue() : null,
                'COLLATERAL_TYPE'   => plfCurr.containsKey(appColObj.Collateral__r.Collateral_Type__c)
                                        ? plfCurr.get(appColObj.Collateral__r.Collateral_Type__c)
                                        : appColObj.Collateral__r.Collateral_Type__c,
                'CURRENT_USAGE'     => plfCurr.get(appColObj.Collateral__r.Current_Usage__c),
                'STATE'             => appColObj.Collateral__r.Pincode__r.City__r.State__c,
                'UNITTYPE'          => appColObj.Collateral__r.Unit_Project__r.Unit_Type__c,
                'FLOORNUMBER'       => appColObj.Collateral__r.Floor_Number__c,
                'UNIT'              => appColObj.Collateral__r.Unit_Project__r.Name,
                'TOWER'             => appColObj.Collateral__r.Unit_Project__r.Tower__c,
                'BUILDING_NAME'     => appColObj.Collateral__r.Building_Name__c,
                'HOUSEFLATSHOPUNIT' => String.isBlank(appColObj.Collateral__r.House_Flat_Shop_Unit_No__c)
                                        ? ''
                                        : appColObj.Collateral__r.House_Flat_Shop_Unit_No__c.substring(
                                            0, Math.min(3, appColObj.Collateral__r.House_Flat_Shop_Unit_No__c.length())),
                'MORTGAGE_TYPE'     => appColObj.Collateral__r.Mortgage_Type__c,
                'PLOTNUMBER'        => appColObj.Collateral__r.Plot_Number__c,
                'POCKET'            => appColObj.Collateral__r.Pocket__c,
                'STREET_NAME'       => appColObj.Collateral__r.Street_Name__c,
                'SURVEYNUMBERGATNO' => appColObj.Collateral__r.Survey_Number_Gat_No__c,
                'COUNTRY'           => appColObj.Collateral__r.Pincode__r.Country__c,
                'DISTRICT'          => appColObj.Collateral__r.Pincode__r.District__c,
                'LOCALITY'          => appColObj.Collateral__r.Pincode__r.City__r.Name
            };

            List<ExtendedFields> extendedFieldsList = new List<ExtendedFields>();
            for (String fieldName : fieldMapping.keySet()) {
                Object value = fieldMapping.get(fieldName);
                ExtendedFields ef = new ExtendedFields();
                if (value != null) {
                    ef.fieldName  = fieldName;
                    ef.fieldValue = String.valueOf(value);
                    extendedFieldsList.add(ef);
                }
            }

            System.debug('extendedfieldlist' + extendedFieldsList);
            ExtendedDetails ed = new ExtendedDetails();
            ed.extendedFields = extendedFieldsList;
            col.extendedDetails = new List<ExtendedDetails>{ ed };

            List<CoOwnerDetails> coOwnerDetails = new List<CoOwnerDetails>(); 
            col.coOwnerDetails = coOwnerDetails;
            List<Documents> documents = new List<Documents>(); 
            col.documents = documents;

            List<String> listReqBody = new List<String>();
            listReqBody.add(JSON.serialize(col));
            System.debug('reqBody' + JSON.serialize(col));
            mapInput.put('reqBody', listReqBody);
            mapInput.put('errors',  errorCode);
        } catch (Exception ex) {
            System.debug('Error: ' + ex.getMessage() + ex.getLineNumber() + ex.getStackTraceString());
            throw new AuraHandledException('Error in Create Collateral Construct Payload' + ex.getStackTraceString());
        }
        return mapInput;
    }


    public static Integer addTwoZeros(Decimal inputNumber) {
        return Integer.valueOf(inputNumber * 100);
    }


    public class CreateCollateralRequestWrapper {
        public String  cif;                  // 100002
        public String  collateralRef;        //
        public String  collateralType;       // PROPERTY
        public String  collateralCcy;        // INR
        public Integer maxCollateralValue;   // 44504500
        public Integer splLtv;               // 0
        public String  collateralLoc;        // MMB
        public String  valuator;             //
        public String  expiryDate;           //
        public String  rvwFrq;               // M0006
        public String  alwMultiLoanAssign;   // false
        public String  alwThirdPartyAssign;  // false
        public String  entityCode;           // N
        public String  remarks;              //
        public ExtendedDetails[] extendedDetails;
        public CoOwnerDetails[]  coOwnerDetails;
        public Documents[]       documents;
    }

    public class ExtendedDetails {
        public ExtendedFields[] extendedFields;
    }

    public class ExtendedFields {
        public String fieldName;   // NOOFUNITS
        public String fieldValue;  // 1
    }

    public class CoOwnerDetails {}

    public class Documents {
        public String custDocTitle;          // COST_SHEET
        public String docCategory;           // cost_sheet_2
        public String custDocIssuedCountry;  // IN
        public String custDocIssuedAuth;     // IN
        public String docFormat;             // IMG
        public String docRefId;
        public String custDocIssuedOn;
        public String docName;               // cost_sheet.png
        public Blob   docContent;
    }
}