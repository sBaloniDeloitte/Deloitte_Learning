public with sharing class COMM_CrifAPIHandler implements IntegrationInterface {
    static String conLabels = 'CRIF_API';
    public static Map<String, String> constants = Utility.getConstants(conLabels);

    @AuraEnabled
    public static Map<String, String> getConstants() {
        return constants;
    }

    public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) {
        String loanApplicationId = wrapper.loanApplicationId;
        String applicantId = wrapper.recordId;
        List<String> errorMessages = new List<String>();

        if (String.isBlank(applicantId)) {
            errorMessages.add('Error: Applicant Id is missing');
            return errorMessages;
        }

        // 🔹 Step 1: Query applicant only
        List<Application_Applicant__c> applicants = [
            SELECT Id, First_Name__c, Middle_Name__c, Last_Name__c, Applicant_Type__c, 
                Mobile_Number__c, PAN_Number__c, Email__c, DOB__c, 
                Mother_s_First_Name__c, Mother_s_Last_Name__c, 
                Father_s_First_Name__c, Father_s_Last_Name__c
            FROM Application_Applicant__c
            WHERE Loan_Application__c = :loanApplicationId 
            AND Id = :applicantId
        ];

        Application_Applicant__c applicant = applicants[0];
          if (applicants[0].DOB__c == null) {
            errorMessages.add('Error: DOB is missing for applicant.');
        }

        // 🔹 Step 2: Query applicant addresses separately
        List<Applicant_Address__c> addresses = [
            SELECT Id, Address_Type__c, City__c 
            FROM Applicant_Address__c 
            WHERE Applicant__c = :applicant.Id  AND Address_Type__c != null
        ];

        if (addresses.isEmpty()) {
            errorMessages.add('Error: No address found for applicant: ' + applicant.First_Name__c);
        }

        return errorMessages;
    }


    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
            String applicantId = wrapper.recordId;
            String loanApplicationId = wrapper.loanApplicationId;

            System.debug('Step 1 - Applicant ID: ' + applicantId);
            System.debug('Step 2 - Loan Application ID: ' + loanApplicationId);

            // Fetch applicant
            Application_Applicant__c app = [
                SELECT Id, First_Name__c, Middle_Name__c,Spouse_First_Name__c,Spouse_Middle_Name__c,Spouse_Last_Name__c,Gender__c,Father_s_Middle_Name__c,Mother_s_Middle_Name__c,Mother_s_Last_Name__c,Mother_s_First_Name__c, Last_Name__c, DOB__c,Aadhaar_Number_Masked__c,Father_s_First_Name__c,Father_s_Last_Name__c, PAN_Number__c, Mobile_Number__c, Email__c, 
                       Loan_Application__c, Loan_Application__r.Lead__c,Loan_Application__r.Product__c,Loan_Application__r.StageName,
                       Reference_1_Relation_with_Applicant__c, Reference_2_Relation_with_Applicant__c
                FROM Application_Applicant__c 
                WHERE Id = :applicantId 
                LIMIT 1
            ];
            System.debug('Step 3 - Applicant Record: ' + app);

            // Fetch lead
            Lead ld = [SELECT Id, Requested_Loan_Amount__c FROM Lead WHERE Id = :app.Loan_Application__r.Lead__c LIMIT 1];
            System.debug('Step 4 - Lead Record: ' + ld);

            // Fetch address (LIMIT 1) including locality field
            Applicant_Address__c addr = [
                SELECT Pincode__r.City__r.Name, Pincode__r.City__r.State__c, Pincode__r.Country__c, Pincode__r.Name, Pincode__r.City__r.State_For_Crif__c,
                       Address_Line_1__c,Address_Line_2__c,Address_Line_3__c, Address_Type__c,Pincode__r.City__r.Country__c FROM Applicant_Address__c WHERE Applicant__c = :app.Id AND Address_Type__c != null LIMIT 1];
            
            Integration_Master__mdt custMetadata = [SELECT UserId__c,Product_Type__c,Product_Version__c, Password__c, CustomerId__c FROM Integration_Master__mdt WHERE Activity_Name__c = 'Loan CRIF' LIMIT 1];
            //State_Metadata__mdt stateMeta = [ SELECT Label ,Value__c FROM State_Metadata__mdt WHERE Label = :addr.Pincode__r.State__c LIMIT 1];

            // Step 1: Query all relevant metadata records
            List<CRIF_API_Metadata__mdt> allCrifApiMetadata = [SELECT MasterLabel, Value__c, CRIF_API_Request_Options__c FROM CRIF_API_Metadata__mdt];
            // Step 2: Create nested map: Map<OptionType, Map<Label, Value>>
            Map<String, Map<String, String>> crifApiMap = new Map<String, Map<String, String>>();

            for (CRIF_API_Metadata__mdt record : allCrifApiMetadata) {
                String optionType = record.CRIF_API_Request_Options__c;
                String label = record.MasterLabel;
                String value = record.Value__c;

                if (!crifApiMap.containsKey(optionType)) {
                    crifApiMap.put(optionType, new Map<String, String>());
                }

                crifApiMap.get(optionType).put(label, value);
            }
            
            // HEADER Segment
            HEADER_SEGMENT header = new HEADER_SEGMENT();
            header.PRODUCT_TYPE = custMetadata.Product_Type__c;
            header.PRODUCT_VER = custMetadata.Product_Version__c;
            header.USER_ID = custMetadata.UserId__c; 
            header.USER_PWD = custMetadata.Password__c; 
            header.REQ_MBR = custMetadata.CustomerId__c;
            header.INQ_DT_TM = System.now().format('dd-MM-yyyy HH:mm');
            header.REQ_VOL_TYPE = 'C04';
            header.REQ_ACTN_TYPE = 'AT01';
            header.AUTH_FLG = 'Y';
            header.AUTH_TITLE = 'USER';
            header.RES_FRMT = 'html';
            header.MEMBER_PREF_OVERRIDE = 'N';
            header.RES_FRMT_EMBD = 'Y';
            header.LOS_NAME = '';
            header.LOS_VENDOR = '';
            header.LOS_VERSION = '';
            header.REQ_SERVICES_TYPE = 'CIR';

            // DOB
            DOB dob = new DOB();
            dob.DOB_DT = app.DOB__c != null ? app.DOB__c.format() : null;
            dob.AGE = '';
            dob.AGE_AS_ON = '';

            List<Identification> ids = new List<Identification>();

           if (!String.isBlank(app.PAN_Number__c)) {
                    String panCode = crifApiMap.get('ID').get('Pan');
                    ids.add(new Identification(panCode, app.PAN_Number__c));
            } else if (!String.isBlank(app.Aadhaar_Number_Masked__c)) {
                String adharNumber = Utility.getDecryptedBase64String(app.Aadhaar_Number_Masked__c);
                    String aadhaarCode = crifApiMap.get('ID').get('Others');
                    ids.add(new Identification(aadhaarCode,adharNumber));
            }

            // Address list
            List<Address> addresses = new List<Address>();
            if (addr != null) {
                Address ad = new Address();
                ad.TYPE = crifApiMap.containsKey('Address Type') && crifApiMap.get('Address Type').containsKey(addr.Address_Type__c)? crifApiMap.get('Address Type').get(addr.Address_Type__c) : 'D08';
ad.ADDRESS_TEXT = 
    (addr.Address_Line_1__c != null ? addr.Address_Line_1__c + ' ' : '') +
    (addr.Address_Line_2__c != null ? addr.Address_Line_2__c + ' ' : '') +
    (addr.Address_Line_3__c != null ? addr.Address_Line_3__c : '');
                ad.CITY = addr.Pincode__r.City__r.Name;
                ad.STATE = String.isNotBlank(addr.Pincode__r.City__r.State_For_Crif__c) ? addr.Pincode__r.City__r.State_For_Crif__c : addr.Pincode__r.City__r.State__c;
                ad.PIN = addr.Pincode__r != null ? addr.Pincode__r.Name : '';
                ad.COUNTRY = addr.Pincode__r.City__r.Country__c;
                ad.LOCALITY = addr.Pincode__r.City__r.Name; 
                addresses.add(ad);
            }

            // Phones and Emails
            List<Phone> phones = new List<Phone>{ new Phone('P04', app.Mobile_Number__c) };
            List<Email> emails = new List<Email>{ new Email(app.Email__c) };

            // Relations
            String fatherFullName = ((String.isNotBlank(app.Father_s_First_Name__c) ? app.Father_s_First_Name__c + ' ' : '') +(String.isNotBlank(app.Father_s_Middle_Name__c) ? app.Father_s_Middle_Name__c + ' ' : '') +(String.isNotBlank(app.Father_s_Last_Name__c)   ? app.Father_s_Last_Name__c   : '')).trim();
            String motherFullName = ((String.isNotBlank(app.Mother_s_First_Name__c) ? app.Mother_s_First_Name__c + ' ' : '') +(String.isNotBlank(app.Mother_s_Middle_Name__c) ? app.Mother_s_Middle_Name__c + ' ' : '') +(String.isNotBlank(app.Mother_s_Last_Name__c)   ? app.Mother_s_Last_Name__c   : '')).trim();
            String spouseFullName = ((String.isNotBlank(app.Spouse_First_Name__c) ? app.Spouse_First_Name__c + ' ' : '') +(String.isNotBlank(app.Spouse_Middle_Name__c) ? app.Spouse_Middle_Name__c + ' ' : '') +(String.isNotBlank(app.Spouse_Last_Name__c)   ? app.Spouse_Last_Name__c   : '')).trim();

            List<Relation> relations = new List<Relation>();
            relations.add(new Relation('K01', fatherFullName));
            if (String.isNotBlank(motherFullName)) {
                relations.add(new Relation('K03', motherFullName));
            }
            if (String.isNotBlank(spouseFullName)) {
                String relationId = (app.Gender__c != null && app.Gender__c.equalsIgnoreCase('Male')) ? 'K06' : 'K02';
                relations.add(new Relation(relationId, spouseFullName));
            }

            // Applicant Segment
            ApplicantSegment applicant = new ApplicantSegment();
            applicant.APPLICANT_ID = app.Id;
            applicant.FIRST_NAME = app.First_Name__c;
            applicant.MIDDLE_NAME = app.Middle_Name__c;
            applicant.LAST_NAME = app.Last_Name__c;
            applicant.DOB = dob;
            applicant.RELATIONS = relations;
            applicant.IDS = ids;
            applicant.ADDRESSES = addresses;
            applicant.PHONES = phones;
            applicant.EMAILS = emails;
            applicant.ACCOUNT_NUMBER = '';
            applicant.GENDER = app.Gender__c == 'Female' ? 'G02' : 'G01';
            System.debug('Step 12 - Applicant Segment: ' + applicant);

            // Application Segment
            ApplicationSegment application = new ApplicationSegment();
            application.INQUIRY_UNIQUE_REF_NO = generateInquiryRef(loanApplicationId);
            application.CREDIT_RPT_TRN_DT_TM = System.now().format('HH:mm');
            application.CREDIT_INQ_PURPS_TYPE = 'CP10'; 
            application.CREDIT_INQUIRY_STAGE = crifApiMap.containsKey('Credit Inquiry Stage') && crifApiMap.get('Credit Inquiry Stage').containsKey(app.Loan_Application__r.StageName)? 
            crifApiMap.get('Credit Inquiry Stage').get(app.Loan_Application__r.StageName) : 'COLLECTION';
            application.CLIENT_CONTRIBUTOR_ID = custMetadata.CustomerId__c;
            application.BRANCH_ID = '';
            application.APPLICATION_ID = loanApplicationId;
            application.ACNT_OPEN_DT ='' ;
            application.LOAN_AMT = String.valueOf(ld.Requested_Loan_Amount__c);
            application.LTV = '';
            application.TERM = '';
            application.LOAN_TYPE = crifApiMap.containsKey('Loan Type') && crifApiMap.get('Loan Type').containsKey(app.Loan_Application__r.Product__c)? 
            crifApiMap.get('Loan Type').get(app.Loan_Application__r.Product__c) : 'A06';
            application.LOAN_TYPE_DESC = '';
            System.debug('Step 13 - Application Segment: ' + application);

            // Final Inquiry and Request
            Inquiry inquiry = new Inquiry();
            inquiry.APPLICANT_SEGMENT = applicant;
            inquiry.APPLICATION_SEGMENT = application;

            REQUEST_FILE requestFile = new REQUEST_FILE();
            requestFile.HEADER_SEGMENT = header;
            requestFile.INQUIRY = inquiry;

            FinalWrapper finalWrapper = new FinalWrapper();
            finalWrapper.REQUEST_FILE = requestFile;

         String requestJSON = createMapFromWrapper(finalWrapper);
         system.debug('205--'+requestJSON);
        //String requestJSON ='{"REQUEST-FILE":{"HEADER-SEGMENT":{"PRODUCT-TYPE":"CIR PRO V2","PRODUCT-VER":"2.0","USER-ID":"godrejhousing_uat","USER-PWD":"6DF60F86F86F70130E464C07472FF59ADB106EFC","REQ-MBR":"HFC0000126","INQ-DT-TM":"22-05-2025 11:14:45","REQ-VOL-TYPE":"C04","REQ-ACTN-TYPE":"AT01","AUTH-FLG":"Y","AUTH-TITLE":"USER","RES-FRMT":"html","MEMBER-PREF-OVERRIDE":"N","RES-FRMT-EMBD":"Y","LOS-NAME":"INHOUSE","LOS-VENDOR":"","LOS-VERSION":"","REQ-SERVICES-TYPE":"CIR"},"INQUIRY":{"APPLICANT-SEGMENT":{"APPLICANT-ID":"65004739048","FIRST-NAME":"Meesala Ravishankar ","MIDDLE-NAME":"","LAST-NAME":".","DOB":{"DOB-DT":"14-12-1998","AGE":"","AGE-AS-ON":""},"RELATIONS":[{"TYPE":"K01","VALUE":"Kumar"}],"IDS":[{"TYPE":"ID07","VALUE":"EGSPM2464J"}],"ADDRESSES":[{"TYPE":"D05","ADDRESS-TEXT":"D.no. 30-11-3, Lakshmi street, Dabagardens","CITY":"Visakhapatnam","STATE":"AP","LOCALITY":"","PIN":"530020","COUNTRY":"INDIA"}],"PHONES":[{"TYPE":"P01","VALUE":"7799273790"}],"EMAILS":[{"EMAIL":""}],"ACCOUNT-NUMBER":"EGSPM2464J"},"APPLICATION-SEGMENT":{"INQUIRY-UNIQUE-REF-NO":"78712352","CREDIT-RPT-TRN-DT-TM":"12:00","CREDIT-INQ-PURPS-TYPE":"CP10","CREDIT-INQUIRY-STAGE":"COLLECTION","CLIENT-CONTRIBUTOR-ID":"HFC0000126","BRANCH-ID":"","APPLICATION-ID":"95603","ACNT-OPEN-DT":"","LOAN-AMT":"600000","LTV":"12","TERM":"234","LOAN-TYPE":"A06","LOAN-TYPE-DESC":""}}}}';
       // String requestJSON = '{"REQUEST-FILE":{"HEADER-SEGMENT":{"PRODUCT-TYPE":"CIR PRO V2","PRODUCT-VER":"2.0","USER-ID":"godrejhousing_uat","USER-PWD":"6DF60F86F86F70130E464C07472FF59ADB106EFC","REQ-MBR":"HFC0000126","INQ-DT-TM":"22-05-2025 11:14:45","REQ-VOL-TYPE":"C04","REQ-ACTN-TYPE":"AT01","AUTH-FLG":"Y","AUTH-TITLE":"USER","RES-FRMT":"html","MEMBER-PREF-OVERRIDE":"N","RES-FRMT-EMBD":"Y","LOS-NAME":"INHOUSE","LOS-VENDOR":"","LOS-VERSION":"","REQ-SERVICES-TYPE":"CIR"},"INQUIRY":{"APPLICANT-SEGMENT":{"APPLICANT-ID":"65004739048","FIRST-NAME":"YOGRAJ ARORA","MIDDLE-NAME":"","LAST-NAME":".","DOB":{"DOB-DT":"14-05-1959","AGE":"","AGE-AS-ON":""},"RELATIONS":[{"TYPE":"K01","VALUE":"Kumar"}],"IDS":[{"TYPE":"ID07","VALUE":"YSBPZ0702B"}],"ADDRESSES":[{"TYPE":"D01","ADDRESS-TEXT":"2 N NIT FARIDABAD 121001","CITY":"FARIDABAD","STATE":"HR","LOCALITY":"","PIN":"121001","COUNTRY":"INDIA"}],"PHONES":[{"TYPE":"P01","VALUE":"6542982367"}],"EMAILS":[{"EMAIL":""}],"ACCOUNT-NUMBER":"YSBPZ0702B"},"APPLICATION-SEGMENT":{"INQUIRY-UNIQUE-REF-NO":"78712352","CREDIT-RPT-TRN-DT-TM":"12:00","CREDIT-INQ-PURPS-TYPE":"CP10","CREDIT-INQUIRY-STAGE":"COLLECTION","CLIENT-CONTRIBUTOR-ID":"HFC0000126","BRANCH-ID":"","APPLICATION-ID":"95603","ACNT-OPEN-DT":"","LOAN-AMT":"600000","LTV":"12","TERM":"234","LOAN-TYPE":"A01","LOAN-TYPE-DESC":""}}}}';
         String encryptedJson = COMM_CrifEncryptionUtil.prepareEncryptedCrifRequest(requestJSON);
				Map<String, String> requestMap = new Map<String, String>();
				requestMap.put('encryptedData', encryptedJson);
                requestMap.put('hit', '0');
				requestMap.put('fileFormate', 'JSON');
            requestJSON = JSON.serialize(requestMap);
            System.debug('Step 14 - Final Request JSON: ' + requestJSON);
            return requestJSON;

        } catch (Exception exp) {
            System.debug('❌ Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'CreateCibilPayload', '', '')
                }
            );
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
    }

    public String createMapFromWrapper(FinalWrapper finalWrapper) {
        try {
           Map<String, Object> headerSegmentMap = new Map<String, Object>{
                'REQ-SERVICES-TYPE' => finalWrapper.REQUEST_FILE.HEADER_SEGMENT.REQ_SERVICES_TYPE,
                'LOS-VERSION' => finalWrapper.REQUEST_FILE.HEADER_SEGMENT.LOS_VERSION,
                'LOS-VENDOR' => finalWrapper.REQUEST_FILE.HEADER_SEGMENT.LOS_VENDOR,
                'LOS-NAME' => finalWrapper.REQUEST_FILE.HEADER_SEGMENT.LOS_NAME,
                'RES-FRMT-EMBD' => finalWrapper.REQUEST_FILE.HEADER_SEGMENT.RES_FRMT_EMBD,
                'MEMBER-PREF-OVERRIDE' => finalWrapper.REQUEST_FILE.HEADER_SEGMENT.MEMBER_PREF_OVERRIDE,
                'RES-FRMT' => finalWrapper.REQUEST_FILE.HEADER_SEGMENT.RES_FRMT,
                'AUTH-TITLE' => finalWrapper.REQUEST_FILE.HEADER_SEGMENT.AUTH_TITLE,
                'AUTH-FLG' => finalWrapper.REQUEST_FILE.HEADER_SEGMENT.AUTH_FLG,
                'REQ-ACTN-TYPE' => finalWrapper.REQUEST_FILE.HEADER_SEGMENT.REQ_ACTN_TYPE,
                'REQ-VOL-TYPE' => finalWrapper.REQUEST_FILE.HEADER_SEGMENT.REQ_VOL_TYPE,
                'INQ-DT-TM' => finalWrapper.REQUEST_FILE.HEADER_SEGMENT.INQ_DT_TM,
                'REQ-MBR' => finalWrapper.REQUEST_FILE.HEADER_SEGMENT.REQ_MBR,
                'USER-PWD' => finalWrapper.REQUEST_FILE.HEADER_SEGMENT.USER_PWD,
                'USER-ID' => finalWrapper.REQUEST_FILE.HEADER_SEGMENT.USER_ID,
                'PRODUCT-VER' => finalWrapper.REQUEST_FILE.HEADER_SEGMENT.PRODUCT_VER,
                'PRODUCT-TYPE' => finalWrapper.REQUEST_FILE.HEADER_SEGMENT.PRODUCT_TYPE
            };


            // DOB map
            Map<String, Object> dobMap = new Map<String, Object>{
                'AGE-AS-ON' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICANT_SEGMENT.DOB.AGE_AS_ON,
                'AGE' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICANT_SEGMENT.DOB.AGE,
                'DOB-DT' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICANT_SEGMENT.DOB.DOB_DT
            };

           
            List<Object> relationsList = new List<Object>();
            for (Relation rel : finalWrapper.REQUEST_FILE.INQUIRY.APPLICANT_SEGMENT.RELATIONS) {
                relationsList.add(new Map<String, Object>{
                    'VALUE' => rel.REL_TYPE_VALUE,
                    'TYPE' => rel.REL_TYPE
                });
            }

            List<Object> idsList = new List<Object>();
            for (Identification id : finalWrapper.REQUEST_FILE.INQUIRY.APPLICANT_SEGMENT.IDS) {
                idsList.add(new Map<String, Object>{
                    'VALUE' => id.ID_VALUE,
                    'TYPE' => id.ID_TYPE
                });
            }


            List<Object> addressesList = new List<Object>();
            for (Address addr : finalWrapper.REQUEST_FILE.INQUIRY.APPLICANT_SEGMENT.ADDRESSES) {
                addressesList.add(new Map<String, Object>{
                    'COUNTRY' => addr.COUNTRY,
                    'PIN' => addr.PIN,
                    'LOCALITY' => addr.LOCALITY,
                    'STATE' => addr.STATE,
                    'CITY' => addr.CITY,
                    'ADDRESS-TEXT' => addr.ADDRESS_TEXT,
                    'TYPE' => addr.TYPE
                });
            }


            List<Object> phonesList = new List<Object>();
            for (Phone ph : finalWrapper.REQUEST_FILE.INQUIRY.APPLICANT_SEGMENT.PHONES) {
                phonesList.add(new Map<String, Object>{
                    'VALUE' => ph.PHONE_NUMBER,
                    'TYPE' => ph.PHONE_TYPE
                });
            }

            List<Object> emailsList = new List<Object>();
            for (Email em : finalWrapper.REQUEST_FILE.INQUIRY.APPLICANT_SEGMENT.EMAILS) {
                emailsList.add(new Map<String, Object>{
                    'EMAIL' => em.EMAIL_ID
                });
            }


           Map<String, Object> applicantSegmentMap = new Map<String, Object>{
                'GENDER' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICANT_SEGMENT.GENDER,
                'ACCOUNT-NUMBER' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICANT_SEGMENT.ACCOUNT_NUMBER,
                'EMAILS' => emailsList,
                'PHONES' => phonesList,
                'ADDRESSES' => addressesList,
                'IDS' => idsList,
                'RELATIONS' => relationsList,
                'DOB' => dobMap,
                'LAST-NAME' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICANT_SEGMENT.LAST_NAME,
                'MIDDLE-NAME' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICANT_SEGMENT.MIDDLE_NAME,
                'FIRST-NAME' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICANT_SEGMENT.FIRST_NAME,
                'APPLICANT-ID' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICANT_SEGMENT.APPLICANT_ID
            };


          Map<String, Object> applicationSegmentMap = new Map<String, Object>{
                'LOAN-TYPE-DESC' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICATION_SEGMENT.LOAN_TYPE_DESC,
                'LOAN-TYPE' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICATION_SEGMENT.LOAN_TYPE,
                'TERM' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICATION_SEGMENT.TERM,
                'LTV' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICATION_SEGMENT.LTV,
                'LOAN-AMT' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICATION_SEGMENT.LOAN_AMT,
                'ACNT-OPEN-DT' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICATION_SEGMENT.ACNT_OPEN_DT,
                'APPLICATION-ID' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICATION_SEGMENT.APPLICATION_ID,
                'BRANCH-ID' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICATION_SEGMENT.BRANCH_ID,
                'CLIENT-CONTRIBUTOR-ID' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICATION_SEGMENT.CLIENT_CONTRIBUTOR_ID,
                'CREDIT-INQUIRY-STAGE' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICATION_SEGMENT.CREDIT_INQUIRY_STAGE,
                'CREDIT-INQ-PURPS-TYPE' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICATION_SEGMENT.CREDIT_INQ_PURPS_TYPE,
                'CREDIT-RPT-TRN-DT-TM' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICATION_SEGMENT.CREDIT_RPT_TRN_DT_TM,
                'INQUIRY-UNIQUE-REF-NO' => finalWrapper.REQUEST_FILE.INQUIRY.APPLICATION_SEGMENT.INQUIRY_UNIQUE_REF_NO
            };

            // Inquiry map
            Map<String, Object> inquiryMap = new Map<String, Object>{
                'APPLICATION-SEGMENT' => applicationSegmentMap,
                'APPLICANT-SEGMENT' => applicantSegmentMap
            };

            // REQUEST-FILE map
            Map<String, Object> requestFileMap = new Map<String, Object>{
                'INQUIRY' => inquiryMap,
                'HEADER-SEGMENT' => headerSegmentMap
            };

            // Final wrapper map
            Map<String, Object> finalMap = new Map<String, Object>{
                'REQUEST-FILE' => requestFileMap
            };

            // Serialize to JSON string
            String jsonString = JSON.serialize(finalMap);
            return jsonString;

        } catch (Exception ex) {
            System.debug('Exception in createMapFromWrapper: ' + ex.getMessage());
            throw ex;
        }
    }

  
    public static String generateInquiryRef(String loanApplicationId) {
        String datetimeStr = DateTime.now().format('ddMMyyyyHHmmss');

        Integer randomNum = Crypto.getRandomInteger();
        if(randomNum < 0) {
            randomNum = -randomNum;
        }
        randomNum = Math.mod(randomNum, 1000000);

        String randomStr = String.valueOf(randomNum);
        while(randomStr.length() < 6) {
            randomStr = '0' + randomStr;
        }

        return datetimeStr + loanApplicationId + randomStr;
    }

    public class FinalWrapper {
        public REQUEST_FILE REQUEST_FILE;
    }

    public class REQUEST_FILE {
        public HEADER_SEGMENT HEADER_SEGMENT;
        public Inquiry INQUIRY;
    }

    public class HEADER_SEGMENT {
        public String PRODUCT_TYPE;
        public String PRODUCT_VER;
        public String USER_ID;
        public String USER_PWD;
        public String REQ_MBR;
        public String INQ_DT_TM;
        public String REQ_VOL_TYPE;
        public String REQ_ACTN_TYPE;
        public String AUTH_FLG;
        public String AUTH_TITLE;
        public String RES_FRMT;
        public String MEMBER_PREF_OVERRIDE;
        public String RES_FRMT_EMBD;
        public String LOS_NAME;
        public String LOS_VENDOR;
        public String LOS_VERSION;
        public String REQ_SERVICES_TYPE;
    }

     public class Inquiry {
        public ApplicantSegment APPLICANT_SEGMENT;
        public ApplicationSegment APPLICATION_SEGMENT;
    }

    public class DOB {
        public String DOB_DT;
        public String AGE;
        public String AGE_AS_ON;
    }

    public class Identification {
        public String ID_TYPE;
        public String ID_VALUE;
        public Identification(String idType, String idValue) {
            this.ID_TYPE = idType;
            this.ID_VALUE = idValue;
        }
    }

    public class Address {
        public String TYPE;
        public String ADDRESS_TEXT;
        public String CITY;
        public String STATE;
        public String LOCALITY;
        public String PIN;
        public String COUNTRY;
    }

    public class Phone {
        public String PHONE_TYPE;
        public String PHONE_NUMBER;
        public Phone(String phoneType, String phoneNumber) {
            this.PHONE_TYPE = phoneType;
            this.PHONE_NUMBER = phoneNumber;
        }
    }

    public class Email {
        public String EMAIL_ID;
        public Email(String emailId) {
            this.EMAIL_ID = emailId;
        }
    }

    public class Relation {
        public String REL_TYPE;
        public String REL_TYPE_VALUE;
        public Relation(String relType, String relTypeValue) {
            this.REL_TYPE = relType;
            this.REL_TYPE_VALUE = relTypeValue;
        }
    }

    public class ApplicantSegment {
        public String APPLICANT_ID;
        public String FIRST_NAME;
        public String MIDDLE_NAME;
        public String LAST_NAME;
        public DOB DOB;
        public List<Relation> RELATIONS;
        public List<Identification> IDS;
        public List<Address> ADDRESSES;
        public List<Phone> PHONES;
        public List<Email> EMAILS;
        public String ACCOUNT_NUMBER;
        public String GENDER;
    }

    public class ApplicationSegment {
        public String INQUIRY_UNIQUE_REF_NO;
        public String CREDIT_RPT_ID;
        public String CREDIT_RPT_TRN_DT_TM;
        public String CREDIT_INQUIRY_STAGE;
        public String CREDIT_INQ_PURPS_TYPE;
        public String CLIENT_CONTRIBUTOR_ID;
        public String BRANCH_ID;
        public String APPLICATION_ID;
        public String ACNT_OPEN_DT;
        public String LOAN_AMT;
        public String LTV;
        public String TERM;
        public String LOAN_TYPE;
        public String LOAN_TYPE_DESC;
    }

}