public with sharing class COMM_CrifAPIHandlerCommercial implements IntegrationInterface {
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

        // 🔹 Query applicant
        List<Application_Applicant__c> applicants = [
            SELECT Id, First_Name__c, Last_Name__c, DOI__c
            FROM Application_Applicant__c
            WHERE Loan_Application__c = :loanApplicationId
            AND Id = :applicantId
            LIMIT 1
        ];

        Application_Applicant__c applicant = applicants[0];

          //Validate DOI
        if (applicant.DOI__c == null) {
            errorMessages.add('Error: DOI is missing for applicant.');
        }

        // 🔹 Query addresses separately
        List<Applicant_Address__c> addresses = [
            SELECT Id
            FROM Applicant_Address__c
            WHERE Applicant__c = :applicant.Id AND Address_Type__c != null
            LIMIT 1
        ];

        if (addresses.isEmpty()) {
            errorMessages.add('Error: No address for applicant.');
        }

        return errorMessages;
    }

    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        try {
            String applicantId = wrapper.recordId;
            String loanApplicationId = wrapper.loanApplicationId;

            Application_Applicant__c app = [
                SELECT Id, First_Name__c, Last_Name__c, DOI__c,DOB__c,Sector__c, PAN_Number__c, Mobile_Number__c, Email__c,
                       Loan_Application__c, Loan_Application__r.Lead__c
                FROM Application_Applicant__c WHERE Id = :applicantId LIMIT 1
            ];

            Lead ld = [SELECT Requested_Loan_Amount__c FROM Lead WHERE Id = :app.Loan_Application__r.Lead__c LIMIT 1];

            Applicant_Address__c addr = [
                SELECT Pincode__r.City__r.Name, Pincode__r.City__r.State__c, Pincode__r.Country__c, Pincode__r.Name, 
                       Address_Line_1__c,Address_Line_2__c,Address_Line_3__c, Address_Type__c,Pincode__r.City__r.Country__c FROM Applicant_Address__c WHERE Applicant__c = :app.Id AND Address_Type__c != null LIMIT 1];
            

           // State_Metadata__mdt stateMeta = State_Metadata__mdt.getInstance(addr.Pincode__r.State__c);

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

            Integration_Master__mdt custMetadata = [
                SELECT UserId__c, Password__c, CustomerId__c,Product_Type__c,Product_Version__c FROM Integration_Master__mdt WHERE Activity_Name__c = 'Loan Crif Commercial' LIMIT 1];

            HeaderSegment header = new HeaderSegment();
            header.LOS_VERSION = '';
            header.LOS_VENDER = '';
            header.LOS_NAME = '';
            header.RES_FRMT_EMBD = 'N';
            header.MEMBER_PRE_OVERRIDE = 'N';
            header.RES_FRMT = 'XML/HTML';
            header.AUTH_TITLE = 'USER';
            header.AUTH_FLG = 'N';
            header.PWD = custMetadata.Password__c;
            header.USER_ID = custMetadata.UserId__c;
            header.TEST_FLG = 'Y';
            header.REQ_ACTN_TYP = 'AT01';
            header.REQ_VOL_TYP = 'INDV';
            header.INQ_DT_TM = DateTime.now().format('dd-MM-yyyy');
            header.SUB_MBR_ID = 'GODREJ HOUSING FINANCE LIMITED';
            header.REQ_MBR = custMetadata.CustomerId__c;
            header.PRODUCT_VER = custMetadata.Product_Version__c;
            header.PRODUCT_TYP = custMetadata.Product_Type__c;

            header.COMMERCIAL = new Commercial();
            header.COMMERCIAL.SCORE = 'true';
            header.COMMERCIAL.CIR = 'true';

            header.CONSUMER = new Consumer();
            header.CONSUMER.SCORE = 'true';
            header.CONSUMER.CIR = 'true';

            CommApplicantSegment applicantSegment = new CommApplicantSegment();
            applicantSegment.CLASS_OF_ACTIVITY_1 = 'OTHER COMMUNITY, SOCIAL AND PERSONAL SERVICE ACTIVITIES'; //Need to discuss
            applicantSegment.LEGAL_CONSTITUTION = crifApiMap.containsKey('Legal Constitution') && crifApiMap.get('Legal Constitution').containsKey(app.Sector__c)? crifApiMap.get('Legal Constitution').get(app.Sector__c) : null;
            //applicantSegment.LEGAL_CONSTITUTION = '20';
            applicantSegment.DOI = app.DOI__c.format();
           //applicantSegment.DOI = app.DOB__c.format();
            applicantSegment.BORROWER_SHORT_NAME = app.First_Name__c;
            applicantSegment.BORROWER_NAME = app.First_Name__c + ' ' + app.Last_Name__c;

            applicantSegment.IDS = new List<IDTypeValue>{
                new IDTypeValue('ID07', app.PAN_Number__c)
            };

            applicantSegment.PHONES = new List<PhoneTypeValue>{
                new PhoneTypeValue(app.Mobile_Number__c, 'P01')
            };

            applicantSegment.EMAIL_IDS = new EmailIds(app.Email__c, '', '');

            CommAddressSegment addressSegment = new CommAddressSegment();
            Address address = new Address();
            addressSegment.ADDRESS = address;
            address.PIN = addr.Pincode__r.Name;
            address.STATE = addr.Pincode__r.City__r.State__c;
            address.CITY = addr.Pincode__r.City__r.Name;
            address.ADDRESS_LINE =  (addr.Address_Line_1__c != null ? addr.Address_Line_1__c + ' ' : '') +
    (addr.Address_Line_2__c != null ? addr.Address_Line_2__c + ' ' : '') +
    (addr.Address_Line_3__c != null ? addr.Address_Line_3__c : '');
            address.TYPE = crifApiMap.containsKey('Address Type') && crifApiMap.get('Address Type').containsKey(addr.Address_Type__c)? crifApiMap.get('Address Type').get(addr.Address_Type__c) : 'D08';


            ApplicationSegment applicationSegment = new ApplicationSegment();
            applicationSegment.LOAN_AMOUNT = String.valueOf(ld.Requested_Loan_Amount__c);
            applicationSegment.LOAN_TYPE = '9999'; //Need to discuss Appendix H
            applicationSegment.LOS_APP_ID = app.Loan_Application__c;
            applicationSegment.BRANCH_ID = '';
            applicationSegment.KENDRA_ID = '';
            applicationSegment.MBR_ID = custMetadata.CustomerId__c;
            applicationSegment.CREDT_RPT_TRN_DT_TM = Datetime.now().format('dd-MM-yyyy HH:mm:ss');
            applicationSegment.CREDT_REQ_TYP = 'INDV';
            applicationSegment.CREDT_RPT_ID = 'CRDRQINQR';
            applicationSegment.CREDIT_INQUIRY_STAGE = 'PRE_DISB';
            applicationSegment.CREDT_INQ_PURPS_TYP = 'ACCT-ORI';
            applicationSegment.INQUIRY_UNIQUE_REF_NO = COMM_CrifAPIHandler.generateInquiryRef(loanApplicationId);

            Inquiry inquiry = new Inquiry();
            inquiry.APPLICATION_SEGMENT = applicationSegment;
            inquiry.COMM_ADDRESS_SEGMENT = addressSegment;
            inquiry.COMM_APPLICANT_SEGMENT = applicantSegment;

            RequestFile requestFile = new RequestFile();
            requestFile.INQUIRY = inquiry;
            requestFile.HEADER_SEGMENT = header;

            System.debug('134--'+requestFile);

            String finalMap = createMapFromRequestFile(requestFile);
			//String jsonStr = JSON.serialize(requestFile).replaceAll('(?<=[A-Za-z])_(?=[A-Za-z])', '-');
             System.debug('Final Request JSON: ' + finalMap);
			String xmlPayload = JSONTOXMLConvertor.convertJsonToXml(finalMap, 'REQUEST-REQUEST-FILE');
           //test1 String xmlPayload1 = '<REQUEST-REQUEST-FILE><HEADER-SEGMENT><PRODUCT-TYP>COMM_ACE_PLUS_REPORT</PRODUCT-TYP><PRODUCT-VER>4.0</PRODUCT-VER><REQ-MBR>HFC0000126</REQ-MBR><SUB-MBR-ID>GODREJ HOUSING FINANCE LIMITED</SUB-MBR-ID><INQ-DT-TM>01-12-2021</INQ-DT-TM><REQ-VOL-TYP>INDV</REQ-VOL-TYP><REQ-ACTN-TYP>SUBMIT</REQ-ACTN-TYP><TEST-FLG>Y</TEST-FLG><USER-ID>godrejhousing_uat</USER-ID><PWD>6DF60F86F86F70130E464C07472FF59ADB106EFC</PWD><AUTH-FLG>N</AUTH-FLG><AUTH-TITLE>USER</AUTH-TITLE><RES-FRMT>XML/HTML</RES-FRMT><MEMBER-PRE-OVERRIDE>N</MEMBER-PRE-OVERRIDE><RES-FRMT-EMBD>N</RES-FRMT-EMBD><LOS-NAME>TEST</LOS-NAME><LOS-VENDER>TEST</LOS-VENDER><LOS-VERSION>0.0</LOS-VERSION><COMMERCIAL><CIR>true</CIR><SCORE>true</SCORE></COMMERCIAL><CONSUMER><CIR>true</CIR><SCORE>true</SCORE></CONSUMER></HEADER-SEGMENT><INQUIRY><COMM-APPLICANT-SEGMENT><BORROWER-NAME>ANKUR DRUGS AND PHARMA LTD</BORROWER-NAME><BORROWER-SHORT-NAME>ADARSH</BORROWER-SHORT-NAME><LEGAL-CONSTITUTION>20</LEGAL-CONSTITUTION><IDS><ID><TYPE>ID07</TYPE><VALUE>AACCA2062M</VALUE></ID><ID><TYPE>ID08</TYPE><VALUE>CIN111111</VALUE></ID></IDS><CLASS-OF-ACTIVITY-1>OTHER COMMUNITY SOCIAL AND PERSONAL SERVICE ACTIVITIES</CLASS-OF-ACTIVITY-1><PHONES><PHONE><TELE-NO>9875987468</TELE-NO><TELE-NO-TYPE>P01</TELE-NO-TYPE></PHONE></PHONES></COMM-APPLICANT-SEGMENT><COMM-ADDRESS-SEGMENT><ADDRESS><TYPE>D01</TYPE><ADDRESS-LINE><![CDATA[C-306 CRYSTAL PLAZA ANDHERI LINK ROAD]]></ADDRESS-LINE><LOCALITY>ANDHERI</LOCALITY><CITY>Mumbai</CITY><STATE>MH</STATE><PIN>400053</PIN></ADDRESS></COMM-ADDRESS-SEGMENT><APPLICATION-SEGMENT><INQUIRY-UNIQUE-REF-NO>1908927821COMM54647</INQUIRY-UNIQUE-REF-NO><CREDT-INQ-PURPS-TYP>ACCT-ORI</CREDT-INQ-PURPS-TYP><CREDT-INQ-PURPS-TYP-DESC>Loan_Purpose_Desc</CREDT-INQ-PURPS-TYP-DESC><CREDIT-INQUIRY-STAGE>PRE_DISB</CREDIT-INQUIRY-STAGE><CREDT-RPT-ID>CRDRQINQR</CREDT-RPT-ID><CREDT-REQ-TYP>INDV</CREDT-REQ-TYP><CREDT-RPT-TRN-DT-TM>24-08-2017 21:10:00</CREDT-RPT-TRN-DT-TM><MBR-ID>BOROCTSAN005</MBR-ID><KENDRA-ID>PUNE</KENDRA-ID><BRANCH-ID>PUNE</BRANCH-ID><LOS-APP-ID>0507RE2015003215</LOS-APP-ID><LOAN-TYPE>9999</LOAN-TYPE><LOAN-AMOUNT>100000</LOAN-AMOUNT></APPLICATION-SEGMENT><INDIVIDUAL-ENTITIES-SEGMENT><INDIVIDUAL-ENTITY><ENTITY-ID>ANHJL0098G12092019</ENTITY-ID><INDIVIDUAL-ENTITY-TYPE>60</INDIVIDUAL-ENTITY-TYPE><DIN>123456</DIN><INDV-APPLICANT-SEGMENT><APPLICANT-NAME><NAME-1>TEST</NAME-1><NAME-2>TEST</NAME-2><NAME-3>TEST</NAME-3></APPLICANT-NAME><GENDER>G01</GENDER><DOB><DOB-DATE>03-03-1989</DOB-DATE></DOB><IDS><ID><TYPE>ID07</TYPE><VALUE>BJXPR9987H</VALUE></ID></IDS><PHONES><PHONE><TELE-NO>8978632434</TELE-NO><TELE-NO-TYPE>P01</TELE-NO-TYPE></PHONE></PHONES></INDV-APPLICANT-SEGMENT><INDV-ADDRESS-SEGMENT><ADDRESS><TYPE>D01</TYPE><ADDRESS-LINE><![CDATA[MG Road]]></ADDRESS-LINE><LOCALITY/><CITY>RAMPUR</CITY><STATE>UP</STATE><PIN>247001</PIN></ADDRESS></INDV-ADDRESS-SEGMENT></INDIVIDUAL-ENTITY></INDIVIDUAL-ENTITIES-SEGMENT></INQUIRY></REQUEST-REQUEST-FILE>';
           // String xmlPayload1 = '<REQUEST-REQUEST-FILE><HEADER-SEGMENT><PRODUCT-TYP>COMM_ACE_PLUS_REPORT</PRODUCT-TYP><PRODUCT-VER>4.0</PRODUCT-VER><REQ-MBR>HFC0000126</REQ-MBR><SUB-MBR-ID>GODREJ HOUSING FINANCE LIMITED</SUB-MBR-ID><INQ-DT-TM>01-12-2021</INQ-DT-TM><REQ-VOL-TYP>INDV</REQ-VOL-TYP><REQ-ACTN-TYP>SUBMIT</REQ-ACTN-TYP><TEST-FLG>Y</TEST-FLG><USER-ID>godrejhousing_uat</USER-ID><PWD>6DF60F86F86F70130E464C07472FF59ADB106EFC</PWD><AUTH-FLG>N</AUTH-FLG><AUTH-TITLE>USER</AUTH-TITLE><RES-FRMT>XML/HTML</RES-FRMT><MEMBER-PRE-OVERRIDE>N</MEMBER-PRE-OVERRIDE><RES-FRMT-EMBD>N</RES-FRMT-EMBD><LOS-NAME>TEST</LOS-NAME><LOS-VENDER>TEST</LOS-VENDER><LOS-VERSION>0.0</LOS-VERSION><COMMERCIAL><CIR>true</CIR><SCORE>true</SCORE></COMMERCIAL><CONSUMER><CIR>true</CIR><SCORE>true</SCORE></CONSUMER></HEADER-SEGMENT><INQUIRY><COMM-APPLICANT-SEGMENT><BORROWER-NAME>NATRAJ CONSTRUCTION  CO</BORROWER-NAME><BORROWER-SHORT-NAME>ADARSH</BORROWER-SHORT-NAME><LEGAL-CONSTITUTION>20</LEGAL-CONSTITUTION><IDS><ID><TYPE>ID07</TYPE><VALUE>QDJCW0732S</VALUE></ID></IDS><CLASS-OF-ACTIVITY-1>OTHER COMMUNITY SOCIAL AND PERSONAL SERVICE ACTIVITIES</CLASS-OF-ACTIVITY-1><PHONES><PHONE><TELE-NO>5482958671</TELE-NO><TELE-NO-TYPE>P01</TELE-NO-TYPE></PHONE></PHONES></COMM-APPLICANT-SEGMENT><COMM-ADDRESS-SEGMENT><ADDRESS><TYPE>D01</TYPE><ADDRESS-LINE><![CDATA[1 ST FLOOR VIKAS COMPLEX, NR RDP ROAD, JAKAT NAKA, .]]></ADDRESS-LINE><LOCALITY></LOCALITY><CITY>MEHSANA</CITY><STATE>GJ</STATE><PIN>384002</PIN></ADDRESS></COMM-ADDRESS-SEGMENT><APPLICATION-SEGMENT><INQUIRY-UNIQUE-REF-NO>1908927821COMM54647</INQUIRY-UNIQUE-REF-NO><CREDT-INQ-PURPS-TYP>ACCT-ORI</CREDT-INQ-PURPS-TYP><CREDT-INQ-PURPS-TYP-DESC>Loan_Purpose_Desc</CREDT-INQ-PURPS-TYP-DESC><CREDIT-INQUIRY-STAGE>PRE_DISB</CREDIT-INQUIRY-STAGE><CREDT-RPT-ID>CRDRQINQR</CREDT-RPT-ID><CREDT-REQ-TYP>INDV</CREDT-REQ-TYP><CREDT-RPT-TRN-DT-TM>24-08-2017 21:10:00</CREDT-RPT-TRN-DT-TM><MBR-ID>BOROCTSAN005</MBR-ID><KENDRA-ID>PUNE</KENDRA-ID><BRANCH-ID>PUNE</BRANCH-ID><LOS-APP-ID>0507RE2015003215</LOS-APP-ID><LOAN-TYPE>9999</LOAN-TYPE><LOAN-AMOUNT>100000</LOAN-AMOUNT></APPLICATION-SEGMENT></INQUIRY></REQUEST-REQUEST-FILE>';
            System.debug('Final Request JSON: ' + xmlPayload);
            String encryptedXML = COMM_CrifEncryptionUtil.prepareEncryptedCrifRequest(xmlPayload);
            Map<String, String> requestMap = new Map<String, String>();
				requestMap.put('encryptedData', encryptedXML);
                requestMap.put('hit', '0');
				requestMap.put('fileFormate', 'XML');
           
           String encryptedRequestJson = JSON.serialize(requestMap);
            

            Map<String, String> finalResMap = new Map<String, String>();
            finalResMap.put('originalXML', xmlPayload);
            finalResMap.put('encryptedRequestJson', encryptedRequestJson);

             System.debug('Final Request JSON: ' + finalResMap);
           return JSON.serialize(finalResMap);

        } catch (Exception ex) {
            System.debug('Payload construction error: ' + ex.getMessage());
            return null;
        }
    }

    public static String createMapFromRequestFile(RequestFile requestFile) {
        List<Object> idsList = new List<Object>();
        for (IDTypeValue idVal : requestFile.INQUIRY.COMM_APPLICANT_SEGMENT.IDS) {
            // Wrap each ID map inside another map with key 'ID'
            idsList.add(new Map<String, Object>{
                'ID' => new Map<String, Object>{
                    'TYPE' => idVal.TYPE,
                    'VALUE' => idVal.VALUE
                }
            });
        }
        List<Object> phonesList = new List<Object>();
        for (PhoneTypeValue phone : requestFile.INQUIRY.COMM_APPLICANT_SEGMENT.PHONES) {
            phonesList.add(new Map<String, Object>{
                'TELE-NO-TYPE' => phone.TELE_NO_TYPE,
                'TELE-NO' => phone.TELE_NO
            });
        }

        Map<String, Object> emailIdsMap = new Map<String, Object>{
            'EMAIL-ID_3' => requestFile.INQUIRY.COMM_APPLICANT_SEGMENT.EMAIL_IDS.EMAIL_ID_3,
            'EMAIL-ID_2' => requestFile.INQUIRY.COMM_APPLICANT_SEGMENT.EMAIL_IDS.EMAIL_ID_2,
            'EMAIL-ID_1' => requestFile.INQUIRY.COMM_APPLICANT_SEGMENT.EMAIL_IDS.EMAIL_ID_1
        };

        Map<String, Object> applicantMap = new Map<String, Object>{
            'EMAIL-IDS' => emailIdsMap,
            'PHONES' => phonesList,
            'CLASS-OF-ACTIVITY_1' => requestFile.INQUIRY.COMM_APPLICANT_SEGMENT.CLASS_OF_ACTIVITY_1,
             'IDS' => idsList,
            'LEGAL-CONSTITUTION' => requestFile.INQUIRY.COMM_APPLICANT_SEGMENT.LEGAL_CONSTITUTION,
            'DOI' => requestFile.INQUIRY.COMM_APPLICANT_SEGMENT.DOI,
            'BORROWER-SHORT-NAME' => requestFile.INQUIRY.COMM_APPLICANT_SEGMENT.BORROWER_SHORT_NAME,
            'BORROWER-NAME' => requestFile.INQUIRY.COMM_APPLICANT_SEGMENT.BORROWER_NAME
        };

        Map<String, Object> addressMap = new Map<String, Object>{
            'TYPE' => requestFile.INQUIRY.COMM_ADDRESS_SEGMENT.ADDRESS.TYPE,
            'ADDRESS-LINE' => requestFile.INQUIRY.COMM_ADDRESS_SEGMENT.ADDRESS.ADDRESS_LINE,
            'CITY' => requestFile.INQUIRY.COMM_ADDRESS_SEGMENT.ADDRESS.CITY,
            'STATE' => requestFile.INQUIRY.COMM_ADDRESS_SEGMENT.ADDRESS.STATE,
            'PIN' => requestFile.INQUIRY.COMM_ADDRESS_SEGMENT.ADDRESS.PIN
        };

        Map<String, Object> applicationMap = new Map<String, Object>{
            'LOAN-AMOUNT' => requestFile.INQUIRY.APPLICATION_SEGMENT.LOAN_AMOUNT,
            'LOAN-TYPE' => requestFile.INQUIRY.APPLICATION_SEGMENT.LOAN_TYPE,
            'LOS-APP-ID' => requestFile.INQUIRY.APPLICATION_SEGMENT.LOS_APP_ID,
            'BRANCH-ID' => requestFile.INQUIRY.APPLICATION_SEGMENT.BRANCH_ID,
            'KENDRA-ID' => requestFile.INQUIRY.APPLICATION_SEGMENT.KENDRA_ID,
            'MBR-ID' => requestFile.INQUIRY.APPLICATION_SEGMENT.MBR_ID,
            'CREDT-RPT-TRN-DT-TM' => requestFile.INQUIRY.APPLICATION_SEGMENT.CREDT_RPT_TRN_DT_TM,
            'CREDT-REQ-TYP' => requestFile.INQUIRY.APPLICATION_SEGMENT.CREDT_REQ_TYP,
            'CREDT-RPT-ID' => requestFile.INQUIRY.APPLICATION_SEGMENT.CREDT_RPT_ID,
            'CREDIT-INQUIRY-STAGE' => requestFile.INQUIRY.APPLICATION_SEGMENT.CREDIT_INQUIRY_STAGE,
            'CREDT-INQ-PURPS-TYP' => requestFile.INQUIRY.APPLICATION_SEGMENT.CREDT_INQ_PURPS_TYP,
            'INQUIRY-UNIQUE-REF-NO' => requestFile.INQUIRY.APPLICATION_SEGMENT.INQUIRY_UNIQUE_REF_NO
        };

        Map<String, Object> inquiryMap = new Map<String, Object>{
            'APPLICATION-SEGMENT' => applicationMap,
            'COMM-ADDRESS-SEGMENT' => new Map<String, Object>{
                'ADDRESS' => addressMap
            },
            'COMM-APPLICANT-SEGMENT' => applicantMap
        };

        Map<String, Object> commercialMap = new Map<String, Object>{
            'SCORE' => requestFile.HEADER_SEGMENT.COMMERCIAL.SCORE,
            'CIR' => requestFile.HEADER_SEGMENT.COMMERCIAL.CIR
        };

        Map<String, Object> consumerMap = new Map<String, Object>{
            'SCORE' => requestFile.HEADER_SEGMENT.CONSUMER.SCORE,
            'CIR' => requestFile.HEADER_SEGMENT.CONSUMER.CIR
        };

        Map<String, Object> headerMap = new Map<String, Object>{
            'CONSUMER' => consumerMap,
            'COMMERCIAL' => commercialMap,
            'LOS-VERSION' => requestFile.HEADER_SEGMENT.LOS_VERSION,
            'LOS-VENDER' => requestFile.HEADER_SEGMENT.LOS_VENDER,
            'LOS-NAME' => requestFile.HEADER_SEGMENT.LOS_NAME,
            'RES-FRMT-EMBD' => requestFile.HEADER_SEGMENT.RES_FRMT_EMBD,
            'MEMBER-PRE-OVERRIDE' => requestFile.HEADER_SEGMENT.MEMBER_PRE_OVERRIDE,
            'RES-FRMT' => requestFile.HEADER_SEGMENT.RES_FRMT,
            'AUTH-TITLE' => requestFile.HEADER_SEGMENT.AUTH_TITLE,
            'AUTH-FLG' => requestFile.HEADER_SEGMENT.AUTH_FLG,
            'USER-ID' => requestFile.HEADER_SEGMENT.USER_ID,
            'PWD' => requestFile.HEADER_SEGMENT.PWD,
            'TEST-FLG' => requestFile.HEADER_SEGMENT.TEST_FLG,
            'REQ-ACTN-TYP' => requestFile.HEADER_SEGMENT.REQ_ACTN_TYP,
            'REQ-VOL-TYP' => requestFile.HEADER_SEGMENT.REQ_VOL_TYP,
            'INQ-DT-TM' => requestFile.HEADER_SEGMENT.INQ_DT_TM,
            'SUB-MBR-ID' => requestFile.HEADER_SEGMENT.SUB_MBR_ID,
            'REQ-MBR' => requestFile.HEADER_SEGMENT.REQ_MBR,
            'PRODUCT-VER' => requestFile.HEADER_SEGMENT.PRODUCT_VER,
            'PRODUCT-TYP' => requestFile.HEADER_SEGMENT.PRODUCT_TYP
        };

        Map<String, Object> requestFileMap = new Map<String, Object>{
            'INQUIRY' => inquiryMap,
            'HEADER-SEGMENT' => headerMap
        };

        return JSON.serialize(requestFileMap);
    }

    public class RequestFile {
        public HeaderSegment HEADER_SEGMENT;
        public Inquiry INQUIRY;
    }

    public class FinalWrapper {
        public RequestFile REQUEST_REQUEST_FILE;
    }

    public class HeaderSegment {
        public String PRODUCT_TYP;
        public String PRODUCT_VER;
        public String REQ_MBR;
        public String SUB_MBR_ID;
        public String INQ_DT_TM;
        public String REQ_VOL_TYP;
        public String REQ_ACTN_TYP;
        public String TEST_FLG;
        public String USER_ID;
        public String PWD;
        public String AUTH_FLG;
        public String AUTH_TITLE;
        public String RES_FRMT;
        public String MEMBER_PRE_OVERRIDE;
        public String RES_FRMT_EMBD;
        public String LOS_NAME;
        public String LOS_VENDER;
        public String LOS_VERSION;
        public Commercial COMMERCIAL;
        public Consumer CONSUMER;
    }

    public class Commercial {
        public String CIR;
        public String SCORE;
    }

    public class Consumer {
        public String CIR;
        public String SCORE;
    }

    public class CommApplicantSegment {
        public String BORROWER_NAME;
        public String BORROWER_SHORT_NAME;
        public String DOI;
        public String LEGAL_CONSTITUTION;
        public String CLASS_OF_ACTIVITY_1;
        public List<IDTypeValue> IDS;
        public List<PhoneTypeValue> PHONES;
        public EmailIds EMAIL_IDS;
    }

    public class IDTypeValue {
        public String TYPE;
        public String VALUE;
        public IDTypeValue(String type, String value) {
            this.TYPE = type;
            this.VALUE = value;
        }
    }

    public class PhoneTypeValue {
        public String TELE_NO;
        public String TELE_NO_TYPE;
        public PhoneTypeValue(String teleNo, String teleNoType) {
            this.TELE_NO = teleNo;
            this.TELE_NO_TYPE = teleNoType;
        }
    }

    public class EmailIds {
        public String EMAIL_ID_1;
        public String EMAIL_ID_2;
        public String EMAIL_ID_3;
        public EmailIds() {}
        public EmailIds(String email1, String email2, String email3) {
            this.EMAIL_ID_1 = email1;
            this.EMAIL_ID_2 = email2;
            this.EMAIL_ID_3 = email3;
        }
    }

    public class CommAddressSegment {
        public Address ADDRESS;
    }

    public class Address {
        public String TYPE;
        public String ADDRESS_LINE;
        public String CITY;
        public String STATE;
        public String PIN;
    }

    public class ApplicationSegment {
        public String INQUIRY_UNIQUE_REF_NO;
        public String CREDT_INQ_PURPS_TYP;
        public String CREDIT_INQUIRY_STAGE;
        public String CREDT_RPT_ID;
        public String CREDT_REQ_TYP;
        public String CREDT_RPT_TRN_DT_TM;
        public String MBR_ID;
        public String KENDRA_ID;
        public String BRANCH_ID;
        public String LOS_APP_ID;
        public String LOAN_TYPE;
        public String LOAN_AMOUNT;
    }

    public class Inquiry {
        public CommApplicantSegment COMM_APPLICANT_SEGMENT;
        public CommAddressSegment COMM_ADDRESS_SEGMENT;
        public ApplicationSegment APPLICATION_SEGMENT;
    }
}