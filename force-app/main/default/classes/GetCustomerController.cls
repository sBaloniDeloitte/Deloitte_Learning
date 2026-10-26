public with sharing class GetCustomerController {
    @AuraEnabled
    public static String getCustomerDetails(String customerId,String processName) {
        try {
            Integration_Details__c integrationDetail = new Integration_Details__c();
            List<Integration_Settings__c> intSettingList = [SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
            FROM Integration_Settings__c WHERE Name = 'Get Customer' LIMIT 1];
            Integration_Settings__c intSetting = intSettingList[0];
            Map<String,String> integrationRequestMap = new Map<String,String>();
            String endpoint  = intSetting.Endpoint__c+'/'+customerId;
            integrationRequestMap.put('intSettingName','Get Customer');
            integrationRequestMap.put('endPoint',endpoint);
            integrationRequestMap.put('serviceName','getCustomerDetails');
            integrationRequestMap.put('MESSAGEID','167036797899');
            integrationRequestMap.put('ENTITYID','14589954555');
            integrationRequestMap.put('ServiceVersion','1');
            integrationRequestMap.put('RequestTime', String.valueof(DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss')));
            integrationRequestMap.put('Language','ENG');
            HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
            // String jsonResponse = '{"cif":"102629","coreBankID":"","categoryCode":"CORP","defaultBranch":"3001","baseCurrency":"INR","primaryRelationOfficer":774,"personalInfo":{"firstName":"Radhika","middleName":"Pathak","lastName":"Pathak","shortName":"Radhika Pathak","fatherName":"","language":"EN","dateofBirth":"1999-09-13","countryofBirth":"IN","nationality":"IN","gender":"OTH","numofDependents":0,"type":"C9","sector":"SAL2","subSector":"SBSC218","industry":"MANU","groupID":0,"parentCountry":"IN","riskCountry":"IN","staff":false,"staffID":"","saleAgent":"","emiCardEligibilityAmt":0,"caste":0,"religion":0,"othersName":"","custCRCPR":"AAAPH1234H","version":78,"marginDeviation":false,"applicationNo":""},"employments":[],"addresses":[{"addrType":"EMPADD","buildingNo":"addre1","FlatNo":"kjdhahdaj","Street":"jsjdjad","addrLine1":"","addrLine2":"","poBox":"","city":"MMB","state":"MH","country":"IN","pinCode":"400007","priority":5,"version":1,"countryName":"INDIA","stateName":"Maharashtra","cityName":"Mumbai"}],"phones":[{"phoneTypeCode":"MOBILE","phoneNumber":"9930277019","priority":5,"version":0}],"emails":[],"customersIncome":[],"documents":[],"customersBankInfo":[],"accountsBehaviour":[],"customersExtLiability":[{"liabilitySeq":2,"finType":"GL","instalmentAmount":900000,"outStandingBal":0,"originalAmount":300000,"finDate":"2019-06-11","finStatus":"S","version":1,"rateOfInterest":0,"tenure":3,"balanceTenure":0,"bounceInstalments":0,"principalOutstanding":0,"overdueAmount":0,"foir":false,"source":0,"checkedBy":0,"securityDetails":"","loanPurpose":"CAPINV","repayBank":"006","otherFinInstitute":"","imputedEmi":0,"ownerShip":"","lastTwentyFourMonths":false,"lastSixMonths":false,"lastThreeMonths":false,"currentOverDue":0,"repayFromAccNo":"","remarks":"","noOfBouncesInSixMonths":0,"noOfBouncesInTwelveMonths":0,"consideredBasedOnRTR":false,"mob":0,"extLiabilitiesPayments":[{"version":2,"emiType":"May-2030","emiClearance":"#"},{"version":2,"emiType":"Apr-2030","emiClearance":"#"},{"version":2,"emiType":"Mar-2030","emiClearance":"#"}],"bankName":"006"},{"liabilitySeq":1,"finType":"BL","instalmentAmount":1000000,"outStandingBal":0,"originalAmount":3000000,"finDate":"2014-06-18","finStatus":"S","version":1,"rateOfInterest":0,"tenure":0,"balanceTenure":0,"bounceInstalments":0,"principalOutstanding":0,"overdueAmount":0,"foir":false,"source":0,"checkedBy":0,"securityDetails":"","loanPurpose":"BEXP","repayBank":"009","otherFinInstitute":"","imputedEmi":0,"ownerShip":"","lastTwentyFourMonths":false,"lastSixMonths":false,"lastThreeMonths":false,"currentOverDue":0,"repayFromAccNo":"","remarks":"","noOfBouncesInSixMonths":0,"noOfBouncesInTwelveMonths":0,"consideredBasedOnRTR":false,"mob":0,"extLiabilitiesPayments":[],"bankName":"002"}],"dedupReq":false,"extendedDetails":[{"extendedFields":[{"fieldName":"entitytype","fieldValue":" PARTNERSHIP"},{"fieldName":"numberofassocentit","fieldValue":0},{"fieldName":"applicantonloan","fieldValue":"#"},{"fieldName":"beneficialowner","fieldValue":"#"},{"fieldName":"kyccollected","fieldValue":"#"},{"fieldName":"registeredwithgst","fieldValue":"#"},{"fieldName":"occupiedsince","fieldValue":0},{"fieldName":"natureofbusiness","fieldValue":"#"},{"fieldName":"cc_od_utilization","fieldValue":"#"},{"fieldName":"debt_equity_ratio","fieldValue":0.00},{"fieldName":"abb_to_emi_ratio","fieldValue":0.00},{"fieldName":"prevyrturnover","fieldValue":0},{"fieldName":"prevyrgrprofit","fieldValue":0},{"fieldName":"prevyrnetpbt","fieldValue":0},{"fieldName":"prevyrdepreciation","fieldValue":0},{"fieldName":"prevyrsalpaidtopd","fieldValue":0},{"fieldName":"prevyrintpaidtop","fieldValue":0},{"fieldName":"preyrintpaidtocl","fieldValue":0},{"fieldName":"preyrintpaidlntobk","fieldValue":0},{"fieldName":"preyronetimeexp","fieldValue":0},{"fieldName":"preyronetimeincome","fieldValue":0},{"fieldName":"turnover","fieldValue":0},{"fieldName":"grossprofit","fieldValue":0},{"fieldName":"netpbt","fieldValue":0},{"fieldName":"depreciation","fieldValue":0},{"fieldName":"salpdtopartdirect","fieldValue":0},{"fieldName":"intpdtopartdirect","fieldValue":0},{"fieldName":"intpaidtoclose","fieldValue":0},{"fieldName":"intpaid_loantobank","fieldValue":0},{"fieldName":"onetimeexpense","fieldValue":0},{"fieldName":"onetimeincome","fieldValue":0},{"fieldName":"annsalarydirector","fieldValue":0},{"fieldName":"avgmnbalfrmperfios","fieldValue":0},{"fieldName":"addfoir","fieldValue":0.00},{"fieldName":"overrideabbemirati","fieldValue":0.00},{"fieldName":"addgromargin","fieldValue":0.00},{"fieldName":"rentincomeprg","fieldValue":"#"},{"fieldName":"incomeprogram","fieldValue":"#"},{"fieldName":"isgroturnsustain","fieldValue":"#"},{"fieldName":"isgroprgrosustain","fieldValue":"#"},{"fieldName":"iscashprgrosustain","fieldValue":"#"},{"fieldName":"rentalinc","fieldValue":0},{"fieldName":"otherinc","fieldValue":0},{"fieldName":"crntres","fieldValue":"#"},{"fieldName":"residentialstatus","fieldValue":"#"},{"fieldName":"residenceownership","fieldValue":"#"},{"fieldName":"officeownership","fieldValue":"#"},{"fieldName":"keyperson","fieldValue":"YES"}]}],"blackListReq":false,"customerDirector":[],"customerGstLists":[],"custCardSales":[],"customerFinanceDetailList":[{"version":0,"finReference":"GFL3001BL0001491","finBranch":"3001","finType":"BL","finAmount":0,"curOddays":0,"firstEmiAmount":0,"loanTenor":12},{"version":0,"finReference":"GFL3001BL0001446","finBranch":"3001","finType":"BL","finAmount":50000000,"curOddays":0,"firstEmiAmount":4606900,"loanTenor":12}],"returnStatus":{"returnCode":"0000","returnText":"Success"}}';
             System.debug('responseJSON -->'+resp.getBody());
             return resp.getBody();
            //return jsonResponse;

        }
        catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }


    public class Response{
        @AuraEnabled public String cif;	//102629
        @AuraEnabled public String coreBankID;	//
        @AuraEnabled public String categoryCode;	//CORP
        @AuraEnabled public String defaultBranch;	//3001
        @AuraEnabled public String baseCurrency;	//INR
        @AuraEnabled public Integer primaryRelationOfficer;	//774
        @AuraEnabled public cls_personalInfo personalInfo;
        @AuraEnabled public cls_employments[] employments;
        @AuraEnabled public cls_addresses[] addresses;
        @AuraEnabled public cls_phones[] phones;
        @AuraEnabled public cls_emails[] emails;
        @AuraEnabled public cls_customersIncome[] customersIncome;
        @AuraEnabled public cls_documents[] documents;
        @AuraEnabled public cls_customersBankInfo[] customersBankInfo;
        @AuraEnabled public cls_accountsBehaviour[] accountsBehaviour;
        @AuraEnabled public cls_customersExtLiability[] customersExtLiability;
        @AuraEnabled public boolean dedupReq;
        @AuraEnabled public cls_extendedDetails[] extendedDetails;
        @AuraEnabled public boolean blackListReq;
        @AuraEnabled public cls_customerDirector[] customerDirector;
        @AuraEnabled public cls_customerGstLists[] customerGstLists;
        @AuraEnabled public cls_custCardSales[] custCardSales;
        @AuraEnabled public cls_customerFinanceDetailList[] customerFinanceDetailList;
        @AuraEnabled public cls_returnStatus returnStatus;
        }
        public class cls_personalInfo {
            @AuraEnabled  public String firstName;	//Radhika
            @AuraEnabled  public String middleName;	//Pathak
            @AuraEnabled public String lastName;	//Pathak
            @AuraEnabled public String shortName;	//Radhika Pathak
            @AuraEnabled public String fatherName;	//
            @AuraEnabled public String language;	//EN
            @AuraEnabled public String dateofBirth;	//1999-09-13
            @AuraEnabled public String countryofBirth;	//IN
            @AuraEnabled public String nationality;	//IN
            @AuraEnabled public String gender;	//OTH
            @AuraEnabled public Integer numofDependents;	//0
            @AuraEnabled public String type;	//C9
            @AuraEnabled public String sector;	//SAL2
            @AuraEnabled public String subSector;	//SBSC218
            @AuraEnabled public String industry;	//MANU
            @AuraEnabled public Integer groupID;	//0
            @AuraEnabled public String parentCountry;	//IN
            @AuraEnabled  public String riskCountry;	//IN
            @AuraEnabled public boolean staff;
            @AuraEnabled  public String staffID;	//
            @AuraEnabled public String saleAgent;	//
            @AuraEnabled public Integer emiCardEligibilityAmt;	//0
            @AuraEnabled public Integer caste;	//0
            @AuraEnabled public Integer religion;	//0
            @AuraEnabled public String othersName;	//
            @AuraEnabled public String custCRCPR;	//AAAPH1234H
            @AuraEnabled public Integer version;	//78
            @AuraEnabled public boolean marginDeviation;
            @AuraEnabled public String applicationNo;	//
        }
        class cls_employments {
        }
        public class cls_addresses {
            @AuraEnabled   public String addrType;	//EMPADD
            @AuraEnabled public String buildingNo;	//addre1
            @AuraEnabled public String FlatNo;	//kjdhahdaj
            @AuraEnabled public String Street;	//jsjdjad
            @AuraEnabled public String addrLine1;	//
            @AuraEnabled public String addrLine2;	//
            @AuraEnabled public String poBox;	//
            @AuraEnabled public String city;	//MMB
            @AuraEnabled public String state;	//MH
            @AuraEnabled  public String country;	//IN
            @AuraEnabled  public String pinCode;	//400007
            @AuraEnabled public Integer priority;	//5
            @AuraEnabled public Integer version;	//1
            @AuraEnabled public String countryName;	//INDIA
            @AuraEnabled public String stateName;	//Maharashtra
            @AuraEnabled  public String cityName;	//Mumbai
        }
        public class cls_phones {
            @AuraEnabled public String phoneTypeCode;	//MOBILE
            @AuraEnabled public String phoneNumber;	//9930277019
            @AuraEnabled  public Integer priority;	//5
            @AuraEnabled public Integer version;	//0
        }
        class cls_emails {
        }
        class cls_customersIncome {
        }
        class cls_documents {
        }
        class cls_customersBankInfo {
        }
        class cls_accountsBehaviour {
        }
        public class cls_customersExtLiability {
            @AuraEnabled  public Integer liabilitySeq;	//2
            @AuraEnabled public String finType;	//GL
            @AuraEnabled public Integer instalmentAmount;	//900000
            @AuraEnabled public Integer outStandingBal;	//0
            @AuraEnabled  public Integer originalAmount;	//300000
            @AuraEnabled public String finDate;	//2019-06-11
            @AuraEnabled public String finStatus;	//S
            @AuraEnabled public Integer version;	//1
            @AuraEnabled public Integer rateOfInterest;	//0
            @AuraEnabled  public Integer tenure;	//3
            @AuraEnabled public Integer balanceTenure;	//0
            @AuraEnabled public Integer bounceInstalments;	//0
            @AuraEnabled public Integer principalOutstanding;	//0
            @AuraEnabled public Integer overdueAmount;	//0
            @AuraEnabled public boolean foir;
            @AuraEnabled public Integer source;	//0
            @AuraEnabled public Integer checkedBy;	//0
            @AuraEnabled public String securityDetails;	//
            @AuraEnabled public String loanPurpose;	//CAPINV
            @AuraEnabled public String repayBank;	//006
            @AuraEnabled public String otherFinInstitute;	//
            @AuraEnabled public Integer imputedEmi;	//0
            @AuraEnabled public String ownerShip;	//
            @AuraEnabled public boolean lastTwentyFourMonths;
            @AuraEnabled public boolean lastSixMonths;
            @AuraEnabled public boolean lastThreeMonths;
            @AuraEnabled public Integer currentOverDue;	//0
            @AuraEnabled public String repayFromAccNo;	//
            @AuraEnabled public String remarks;	//
            @AuraEnabled public Integer noOfBouncesInSixMonths;	//0
            @AuraEnabled public Integer noOfBouncesInTwelveMonths;	//0
            @AuraEnabled public boolean consideredBasedOnRTR;
            @AuraEnabled public Integer mob;	//0
            @AuraEnabled  public cls_extLiabilitiesPayments[] extLiabilitiesPayments;
            @AuraEnabled public String bankName;	//006
        }
        public class cls_extLiabilitiesPayments {
            @AuraEnabled public Integer version;	//2
            @AuraEnabled public String emiType;	//May-2030
            @AuraEnabled public String emiClearance;	//#
        }
        public class cls_extendedDetails {
            @AuraEnabled public cls_extendedFields[] extendedFields;
        }
        public class cls_extendedFields {
            @AuraEnabled public String fieldName;	//entitytype
            @AuraEnabled  public String fieldValue;	// PARTNERSHIP
        }
        class cls_customerDirector {
        }
        class cls_customerGstLists {
        }
        class cls_custCardSales {
        }
        public class cls_customerFinanceDetailList {
            @AuraEnabled  public Integer version;	//0
            @AuraEnabled  public String finReference;	//GFL3001BL0001491
            @AuraEnabled  public String finBranch;	//3001
            @AuraEnabled  public String finType;	//BL
            @AuraEnabled public Integer finAmount;	//0
            @AuraEnabled public Integer curOddays;	//0
            @AuraEnabled public Integer firstEmiAmount;	//0
            @AuraEnabled public Integer loanTenor;	//12
        }
        public class cls_returnStatus {
            @AuraEnabled  public String returnCode;	//0000
            @AuraEnabled  public String returnText;	//Success
        }
    
   
}