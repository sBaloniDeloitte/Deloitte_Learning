/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-29-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CKYCIndividualController {
    static string conLabels = 'CKYC_API,Current,Permanent';
    
    public static Map<string, string> constants = Utility.getConstants(conLabels);
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
    @AuraEnabled 
    public static String initiateAPIRequest(Map<String, String> inputMap){
        try {
            
            List<string> validatemandate = new List<string>();
            List<string> constructpayload = new List<string>();
            String resultMessage;
            String loanId = inputMap.get('loanId');
            String applicantId = inputMap.get('applicantId');
            String processName = inputMap.get('processName');
            String panNum = inputMap.get('panNum');
            String dob = inputMap.get('dob');
            
            Application_Applicant__c app = [Select id,Applicant_Name__c,Customer_Type__c, Customer__c, Pan_Name__c, PAN_Number__c,DOB__c,DOI__c,CKYC_LastName__c,CKYC_FullName__c,CKYC_PAN__c,CKYC_Gender__c,CKYC_DOB__c,
                                            CKYC_Aadhar__c,CKYC_KIN__c from Application_Applicant__c where id = :applicantId];
            String returnResp;
            Integration_Master__mdt metadata = [SELECT 
                                                Process_Name__c,
                                                Handler_Class__c,
                                                Endpoint__c,
                                                Request_Method__c,
                                                Client_Id__c,
                                                Client_Secret__c,
                                                Allowed_Retry__c,
                                                Gestation_Period__c,
                                                Refresh_Allowed__c,
                                                Activity_Name__c
                                                FROM Integration_Master__mdt 
                                                WHERE Activity_Name__c = :processName LIMIT 1];
            
            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
            
            wrapper.recordId =applicantId ;
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
            wrapper.handlername =  metadata.Handler_Class__c;
            wrapper.panNumber = panNum ;
            wrapper.customerDOB =Date.valueof(dob);
            
            intHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                                                            FROM Integration_Settings__c WHERE Name = 'Loan Applicant CKYC' LIMIT 1];
            Integration_Settings__c intSetting = intSettingList[0];
                        System.debug('respWrapper.prerequisiteError--'+respWrapper);

            System.debug('respWrapper.prerequisiteError--'+respWrapper.prerequisiteError);
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = String.valueof('412');
                integrationDetail.Prerequisite__c =  String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Name =processName ;
                integrationDetail.Object_Name__c = 'Application_Applicant__c';
                resultMessage =  String.join(respWrapper.prerequisiteError, ', ');//'Error: Prerequisite Failed';
                integrationDetail.Loan_Application__c = loanId;
                integrationDetail.Related_Record_Id__c = applicantId;
                integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                returnResp = resultMessage;
            }
            else{
                Map<String,String> integrationRequestMap = new Map<String,String>();
                integrationRequestMap.put('intSettingName',constants.get('CKYC_API'));
                integrationRequestMap.put('requestJSON',respWrapper.payload);
                String bearer=Utility.getAccessToken();
                System.debug('bearer----'+bearer);
                integrationRequestMap.put('bearer',bearer);
                HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
                System.debug('ckycResp resp getStatusCode '+resp.getStatusCode());
                                System.debug('ckycResp resp resp.getBody() '+resp.getBody());

                if(resp.getStatusCode() == 200){
                    CKYCIndividualResponseServiceWrapper ckycResp = (CKYCIndividualResponseServiceWrapper) JSON.deserialize(resp.getBody(), CKYCIndividualResponseServiceWrapper.class);
                    System.debug('ckycResp '+ckycResp);
                    System.debug('intSetting.EndPoint__c '+intSetting.EndPoint__c);
                    List<Applicant_Address__c> addListCurrent =[Select id, Address_Type__c from Applicant_Address__c where Applicant__c=:app.id And Address_Type__c=:constants.get('Current')];
                    List<Applicant_Address__c> addListPermanent =[Select id, Address_Type__c from Applicant_Address__c where Applicant__c=:app.id And Address_Type__c=:constants.get('Permanent')];
                    integrationDetail.Status__c = String.valueof(resp.getStatusCode());
                    integrationDetail.Name =processName ;
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                    integrationDetail.Loan_Application__c = loanId;
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.Request_JSON__c = respWrapper.payload;
                    integrationDetail.Response_JSON__c = resp.getBody();
                    Account accCust = new Account();
                    System.debug('app.Applicant_Name__c '+app.Applicant_Name__c);
                    System.debug('app.Customer_Type__c '+app.Customer_Type__c);
                    System.debug('app.Customer__c '+app.Customer__c);
                    if(app.Customer__c==null){
                        accCust.Name=app.Applicant_Name__c;
                        //accCust.Customer_Type__c=app.Customer_Type__c;
                        
                        insert accCust;
                        System.debug('accCust '+accCust);
                        app.Customer__c=accCust.id;
                    }
                    if(ckycResp.PID_DATA!=null){
                        app.CKYC_LastName__c = ckycResp.PID_DATA.PERSONAL_DETAILS.LNAME;
                        app.CKYC_FullName__c=ckycResp.PID_DATA.PERSONAL_DETAILS.FULLNAME;
                        app.CKYC_PAN__c=ckycResp.PID_DATA.PERSONAL_DETAILS.PAN;
                        app.CKYC_Gender__c=ckycResp.PID_DATA.PERSONAL_DETAILS.GENDER;
                        String[] dateParts = ckycResp.PID_DATA.PERSONAL_DETAILS.DOB.split('-');
                        Integer day = Integer.valueOf(dateParts[0]);
                        Integer month = Integer.valueOf(dateParts[1]);
                        Integer year = Integer.valueOf(dateParts[2]);
                        
                        // Assign the formatted Date to the field
                        
                        app.CKYC_DOB__c = Date.newInstance(year, month, day);
                        
                        app.CKYC_Aadhar__c=ckycResp.PID_DATA.IDENTITY_DETAILS.IDENTITY.IDENT_NUM;
                        if(ckycResp.PID_DATA.PERSONAL_DETAILS!=null){
                            app.CKYC_KIN__c = ckycResp.PID_DATA.PERSONAL_DETAILS.CKYC_REFERENCE_ID;
                        }
                        
                        Applicant_Address__c appPermAdd = new  Applicant_Address__c();
                        if(addListPermanent.size()!=0){
                            appPermAdd.id=addListPermanent[0].id;
                        }
                        else{
                            Customer_Address__c newCustomerAddressPermanent = new Customer_Address__c();
                            newCustomerAddressPermanent.Customer__c = app.Customer__c;
                            newCustomerAddressPermanent.Address_Type__c=constants.get('Permanent');
                            insert newCustomerAddressPermanent; 
                            appPermAdd.Customer_Address__c=newCustomerAddressPermanent.id;
                        }
                        appPermAdd.Address_Type__c=constants.get('Permanent');
                        appPermAdd.CKYC_AddressLine3__c=ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_LINE3;
                        appPermAdd.CKYC_AddressLine2__c=ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_LINE2;
                        appPermAdd.CKYC_AddressLine1__c=ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_LINE1;
                        appPermAdd.CKYC_City__c =ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_CITY;
                        appPermAdd.CKYC_Pincode__c =String.valueof(ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_PIN);
                        appPermAdd.CKYC_District__c =ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_DIST;
                        appPermAdd.CKYC_Country__c =ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_COUNTRY;
                        appPermAdd.CKYC_State__c =ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_STATE;
                        appPermAdd.Applicant__c=app.id;
                        Upsert appPermAdd;
                        
                        Applicant_Address__c appCurrentAdd = new  Applicant_Address__c();
                        if(addListCurrent.size()!=0){
                            appCurrentAdd.id=addListCurrent[0].id;
                        }
                        else{
                            Customer_Address__c newCustomerAddressCurrent = new Customer_Address__c();
                            newCustomerAddressCurrent.Customer__c = app.Customer__c;
                            newCustomerAddressCurrent.Address_Type__c=constants.get('Current');
                            insert newCustomerAddressCurrent;
                            appCurrentAdd.Customer_Address__c=newCustomerAddressCurrent.id;
                        }
                        appCurrentAdd.Applicant__c=app.id;
                        appCurrentAdd.Address_Type__c=constants.get('Current');
                        appCurrentAdd.CKYC_AddressLine3__c=ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_LINE3;
                        appCurrentAdd.CKYC_AddressLine2__c=ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_LINE2;
                        appCurrentAdd.CKYC_AddressLine1__c=ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_LINE1;
                        appCurrentAdd.CKYC_City__c =ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_CITY;
                        appCurrentAdd.CKYC_Pincode__c =String.valueof(ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_PIN);
                        appCurrentAdd.CKYC_District__c =ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_DIST;
                        appCurrentAdd.CKYC_Country__c =ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_COUNTRY;
                        appCurrentAdd.CKYC_State__c =ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_STATE;
                        Upsert appCurrentAdd;
                        
                        Update app;
                        returnResp=JSON.serialize(ckycResp);

                        List<Triangulation_Data__c> triangulationDatas = [SELECT Id, Loan_Application__c, Application_Applicant__c, Name__c, Pan__c, Gender__c, CKYC_Number__c, 
                                                                            Date_Of_Birth__c, Father__c, Mother__c, Mobile_Number__c, KYC_Employee_Code__c, Address__c FROM Triangulation_Data__c 
                                                                            WHERE Loan_Application__c =: loanId AND Application_Applicant__c =: app.id AND Source_Type__c ='CKYC'];
                        if(!triangulationDatas.isEmpty()) {
                            triangulationDatas[0].CKYC_Number__c = ckycResp.PID_DATA.PERSONAL_DETAILS.CKYC_NO;
                            triangulationDatas[0].Name__c = ckycResp.PID_DATA.PERSONAL_DETAILS.FULLNAME;
                            triangulationDatas[0].Pan__c = ckycResp.PID_DATA.PERSONAL_DETAILS.PAN;
                            triangulationDatas[0].Gender__c = ckycResp.PID_DATA.PERSONAL_DETAILS.GENDER;
                            triangulationDatas[0].Father__c = ckycResp.PID_DATA.PERSONAL_DETAILS.FATHER_FULLNAME;
                            triangulationDatas[0].Date_Of_Birth__c = ckycResp.PID_DATA.PERSONAL_DETAILS.GENDER;
                            triangulationDatas[0].Mother__c = ckycResp.PID_DATA.PERSONAL_DETAILS.MOTHER_FULLNAME;
                            triangulationDatas[0].Mobile_Number__c = ckycResp.PID_DATA.PERSONAL_DETAILS.MOB_NUM;
                            triangulationDatas[0].KYC_Employee_Code__c = ckycResp.PID_DATA.PERSONAL_DETAILS.KYC_EMPCODE;
                            triangulationDatas[0].Address__c = 'Current - '+ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_LINE1 + ', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_LINE2 + ', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_LINE3 +', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_CITY + ', '+
                                                                String.valueof(ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_PIN)+', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_DIST+', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_COUNTRY+', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_STATE+' || '+
                                                                'Premanent - '+ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_LINE1 + ', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_LINE2 + ', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_LINE3 +', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_CITY + ', '+
                                                                String.valueof(ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_PIN)+', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_DIST+', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_COUNTRY+', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_STATE;
                            update triangulationDatas;
                        } else {
                            Triangulation_Data__c triangulationData = new Triangulation_Data__c();
                            triangulationData.CKYC_Number__c = ckycResp.PID_DATA.PERSONAL_DETAILS.CKYC_NO;
                            triangulationData.Name__c = ckycResp.PID_DATA.PERSONAL_DETAILS.FULLNAME;
                            triangulationData.Pan__c = ckycResp.PID_DATA.PERSONAL_DETAILS.PAN;
                            triangulationData.Gender__c = ckycResp.PID_DATA.PERSONAL_DETAILS.GENDER;
                            triangulationData.Father__c = ckycResp.PID_DATA.PERSONAL_DETAILS.FATHER_FULLNAME;
                            triangulationData.Date_Of_Birth__c = ckycResp.PID_DATA.PERSONAL_DETAILS.GENDER;
                            triangulationData.Mother__c = ckycResp.PID_DATA.PERSONAL_DETAILS.MOTHER_FULLNAME;
                            triangulationData.Mobile_Number__c = ckycResp.PID_DATA.PERSONAL_DETAILS.MOB_NUM;
                            triangulationData.KYC_Employee_Code__c = ckycResp.PID_DATA.PERSONAL_DETAILS.KYC_EMPCODE;
                            triangulationData.Address__c = 'Current - '+ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_LINE1 + ', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_LINE2 + ', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_LINE3 +', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_CITY + ', '+
                                                                String.valueof(ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_PIN)+', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_DIST+', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_COUNTRY+', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.CORRES_STATE+' || '+
                                                                'Premanent - '+ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_LINE1 + ', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_LINE2 + ', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_LINE3 +', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_CITY + ', '+
                                                                String.valueof(ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_PIN)+', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_DIST+', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_COUNTRY+', '+
                                                                ckycResp.PID_DATA.PERSONAL_DETAILS.PERM_STATE;
                            // parameter setting
                            triangulationData.Application_Applicant__c = app.id;
                            triangulationData.Loan_Application__c = loanId;
                            triangulationData.Source_Type__c = 'CKYC';
                            insert triangulationData;
                        }
                    }
                }
                else{
                    returnResp = 'Api server failure';
                    integrationDetail.Status__c = String.valueof(resp.getStatusCode());
                    integrationDetail.Name =processName ;
                    integrationDetail.Object_Name__c = 'Application_Applicant__c';
                    integrationDetail.EndPoint__c = intSetting.EndPoint__c;
                    integrationDetail.Loan_Application__c = loanId;
                    integrationDetail.Related_Record_Id__c = applicantId;
                    integrationDetail.Request_JSON__c =respWrapper.payload;
                    integrationDetail.Response_JSON__c = resp.getBody();
                }
            } //suhrit
            insert integrationDetail;
            return returnResp;
        }
        catch (Exception e) {
             System.debug('Exception occurred: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
           
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    public class CKYCIndividualResponseServiceWrapper {
        @AuraEnabled public cls_PID_DATA PID_DATA;
    }
    
    public class cls_PID_DATA {
        @AuraEnabled public cls_RECORD_COUNT_DETAILS RECORD_COUNT_DETAILS;
        @AuraEnabled public String RELATED_PERSON_DETAILS;  //
        @AuraEnabled public cls_PERSONAL_DETAILS PERSONAL_DETAILS;
        @AuraEnabled public cls_IDENTITY_DETAILS IDENTITY_DETAILS;
        @AuraEnabled public cls_IMAGE_DETAILS IMAGE_DETAILS;
    }
    
    public class cls_RECORD_COUNT_DETAILS {
        @AuraEnabled public String UPDATE_COUNT;  // 0
        @AuraEnabled public Integer DOWNLOAD_COUNT;  // 11
    }
    
    public class cls_PERSONAL_DETAILS {
        @AuraEnabled public String CORRES_COUNTRY;  // IN
        @AuraEnabled public String MAIDEN_MNAME;  //
        @AuraEnabled public String PERM_LINE3;  //
        @AuraEnabled public String LNAME;  // Thorat
        @AuraEnabled public String PERM_DIST;  // Mumbai
        @AuraEnabled public String REMARKS;  //
        @AuraEnabled public String EMAIL;  //
        @AuraEnabled public String DEC_PLACE;  // Mumbai
        @AuraEnabled public String CORRES_POA;  // 01
        @AuraEnabled public String KYC_EMPCODE;  // G124265
        @AuraEnabled public String PERM_COUNTRY;  // IN
        @AuraEnabled public String PERM_POA;  // 01
        @AuraEnabled public String CKYC_REFERENCE_ID;  // INAGQJ62576883
        @AuraEnabled public String MOTHER_MNAME;  //
        @AuraEnabled public String MAIDEN_LNAME;  //
        @AuraEnabled public String DOB;  // 01-01-1984
        @AuraEnabled public String KYC_DESIGNATION;  // SM
        @AuraEnabled public String MOTHER_PREFIX;  // Mrs
        @AuraEnabled public String RESI_STD_CODE;  //
        @AuraEnabled public String PERM_CORRES_SAMEFLAG;  // Y
        @AuraEnabled public String PERM_LINE2;  // CVD
        @AuraEnabled public String FULLNAME;  // Mr Rohan Laxman Thorat
        @AuraEnabled public String PERM_LINE1;  // ABC
        @AuraEnabled public String FATHER_PREFIX;  //
        @AuraEnabled public String OFF_TEL_NUM;  //
        @AuraEnabled public String CORRES_PIN;  // 400015
        @AuraEnabled public String FATHER_FNAME;  //
        @AuraEnabled public String KYC_DATE;  // 06-01-2025
        @AuraEnabled public String DOC_SUB;  // 01
        @AuraEnabled public String CORRES_CITY;  // mumbai
        @AuraEnabled public String CONSTI_TYPE;  // 01
        @AuraEnabled public String MAIDEN_FULLNAME;  //
        @AuraEnabled public String MOB_CODE;  //
        @AuraEnabled public String FNAME;  // Rohan
        @AuraEnabled public String MOTHER_FNAME;  // Sheela
        @AuraEnabled public String NUM_RELATED;  // 0
        @AuraEnabled public String FATHERSPOUSE_FLAG;  //
        @AuraEnabled public String PREFIX;  // Mr
        @AuraEnabled public String ORG_CODE;  // IN10265
        @AuraEnabled public String MNAME;  // Laxman
        @AuraEnabled public String RESI_TEL_NUM;  //
        @AuraEnabled public String NUM_IMAGES;  // 3
        @AuraEnabled public String KYC_NAME;  // SB
        @AuraEnabled public String FATHER_FULLNAME;  //
        @AuraEnabled public String PERM_CITY;  // mumbai
        @AuraEnabled public String GENDER;  // M
        @AuraEnabled public String MOB_NUM;  // 8850513345
        @AuraEnabled public String OFF_STD_CODE;  //
        @AuraEnabled public String CORRES_LINE3;  //
        @AuraEnabled public String CORRES_LINE2;  // CVD
        @AuraEnabled public String FATHER_MNAME;  //
        @AuraEnabled public String CORRES_LINE1;  // ABC
        @AuraEnabled public String MOTHER_LNAME;  //
        @AuraEnabled public String CORRES_STATE;  // MH
        @AuraEnabled public String KYC_BRANCH;  // thane
        @AuraEnabled public String PERM_PIN;  // 400015
        @AuraEnabled public String ORG_NAME;  // Godrej Finance Limited
        @AuraEnabled public String DEC_DATE;  // 06-01-2025
        @AuraEnabled public String FATHER_LNAME;  //
        @AuraEnabled public String MOTHER_FULLNAME;  // Mrs Sheela
        @AuraEnabled public String CKYC_NO;  // 50035986410749
        @AuraEnabled public String NUM_IDENTITY;  // 1
        @AuraEnabled public String CORRES_DIST;  // Mumbai
        @AuraEnabled public String PERM_STATE;  // MH
        @AuraEnabled public String MAIDEN_PREFIX;  //
        @AuraEnabled public String MAIDEN_FNAME;  //
        @AuraEnabled public String ACC_TYPE;  // 01
        @AuraEnabled public String PAN;  // VZWPT2211A
    }
    
    public class cls_IDENTITY_DETAILS {
        @AuraEnabled public cls_IDENTITY IDENTITY;
    }
    
    public class cls_IDENTITY {
        @AuraEnabled public String IDENT_NUM;  // XXXXXX1987
        @AuraEnabled public String IDENT_TYPE;  // E
        @AuraEnabled public String SEQUENCE_NO;  // 1
        @AuraEnabled public String IDVER_STATUS;  // 02
    }
    
    public class cls_IMAGE_DETAILS {
        @AuraEnabled public cls_IMAGE[] IMAGE;
    }
    
    public class cls_IMAGE {
        @AuraEnabled public String IMAGE_TYPE;  // jpg
        @AuraEnabled public String GLOBAL_FLAG;  //
        @AuraEnabled public String IMAGE_CODE;  // 02
        @AuraEnabled public String IMAGE_DATA;  //
        @AuraEnabled public String SEQUENCE_NO;  // 1
        @AuraEnabled public Integer BRANCH_CODE;  // 1001
    }
}