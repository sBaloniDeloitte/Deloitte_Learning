public with sharing class COMM_SalesIncomeEligibilityController {
    public class ResponseWrapper{
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String fieldValue;
        @AuraEnabled public Boolean isSectionSeperator;
        @AuraEnabled public String sectionSeperatorName;
        @AuraEnabled public boolean isGreen;
        @AuraEnabled public boolean isRed;
        @AuraEnabled public boolean isBlank ;


    }
    @AuraEnabled
    public static List<ResponseWrapper> getScreenFieldData(String screenName, String loanId) {
        List<ResponseWrapper> respList = new List<ResponseWrapper>();
        Map<String, FICOResponse.cls_calculatedVariables> fieldDataMap = new Map<String, FICOResponse.cls_calculatedVariables>();
        Map<String,String> finalOfferValuesMap = new Map<String,String>();
        List<Integration_Details__c> intDetList = [
            SELECT Id, Response_JSON__c, Eligibility_Status__c,Related_Record_Id__c,Object_Name__c 
            FROM Integration_Details__c 
            WHERE Loan_Application__c = :loanId AND Name = 'BANKINGSURROGATE' AND Object_Name__c ='Document_Details__c'
            ORDER BY CreatedDate DESC
        ];
         
        Opportunity opp = [SELECT id,Login_Completion_Stage__c,Banking_Index__c from Opportunity  WHERE ID =: loanId];
        if(opp!=null && intDetList.size()>0 && !intDetList.isEmpty()){
            if(opp.Login_Completion_Stage__c != ''){
                if(!opp.Login_Completion_Stage__c.containsIgnoreCase('Income Eligibility')){
                opp.Login_Completion_Stage__c =opp.Login_Completion_Stage__c + ';'+'Income Eligibility';
                }
            }
            else{
                opp.Login_Completion_Stage__c ='Income Eligibility';
            }
            update opp;
        }

        List<Document_Details__c> docLst= [SELECT id,createddate,Content_Document_Id__c,Applicant__c from Document_Details__c  where name = 'Income Eligibility Response' AND id=:intDetList[0].Related_Record_Id__c ORDER BY CreatedDate DESC LIMIT 1];
        List<ContentVersion> conversionLst = [SELECT id,VersionData,ContentDocumentId  FROM ContentVersion WHERE ContentDocumentId=:docLst[0].Content_Document_Id__c];
        
        String incomeResponse =conversionLst[0].VersionData.toString();



        List<Document_Details__c> docLstRequest= [SELECT id,createddate,Content_Document_Id__c,Applicant__c from Document_Details__c  where name = 'Income Eligibility Request' and Loan_Application__c=:loanId ORDER BY CreatedDate DESC LIMIT 1];
        List<ContentVersion> conversionLstRequest = [SELECT id,VersionData,ContentDocumentId  FROM ContentVersion WHERE ContentDocumentId=:docLstRequest[0].Content_Document_Id__c];
        System.debug('docLstRequest-------'+docLstRequest);
        String incomeRequest =conversionLstRequest[0].VersionData.toString();
        System.debug('incomeRequest-------'+incomeRequest);
       
        // FICOResponse incomeWrapper = (FICOResponse)JSON.deserialize(incomeResponse,FICOResponse.class);
           

        // if (!incomeWrapper.isEmpty()) {
            Integer startIndex = incomeResponse.indexOf('<response>');
            Integer endIndex = incomeResponse.indexOf('</response>') + '</response>'.length();
            String responseTag = incomeResponse.substring(startIndex, endIndex);
            Map<String, Object> xmlConvertedResp = XMLConvertor.xmlToMap(responseTag);
            String finalResponse = JSON.serialize(xmlConvertedResp);
            system.debug('finalResponse-------'+finalResponse);
            FICOResponse respWrap = (FICOResponse)JSON.deserialize(finalResponse, FICOResponse.class);


            Integer startIndexRequest = incomeRequest.indexOf('<request>');
            Integer endIndexRequest = incomeRequest.indexOf('</request>') + '</request>'.length();
            String requestTag = incomeRequest.substring(startIndexRequest, endIndexRequest);
            Map<String, Object> xmlConvertedRequest = XMLConvertor.xmlToMap(requestTag);
            System.debug('xmlConvertedRequest-------'+xmlConvertedRequest);
            String finalRequest= JSON.serialize(xmlConvertedRequest);
            System.debug('req-------'+finalRequest);
           Request req = (Request )JSON.deserialize(finalRequest,Request.class);
           System.debug('req-------'+req);
           Decimal ADBB  = Decimal.valueOf(req.request.application.applicationAdditionalDetails.balanceTransfer.btOutstanding).setScale(2);
            for (FICOResponse.cls_calculatedVariables iterVar : respWrap.response.calculatedVariables) {
                fieldDataMap.put(iterVar.fieldName, iterVar);
            }
            Integer startIndexOffer = incomeResponse.indexOf('<finalOffer>');
            Integer endIndexOffer = incomeResponse.indexOf('</finalOffer>') + '</finalOffer>'.length();
            String responseTagOffer = incomeResponse.substring(startIndexOffer, endIndexOffer);
            Map<String, Object> xmlConvertedRespOffer = XMLConvertor.xmlToMap(responseTagOffer);
            String finalResponseOffer = JSON.serialize(xmlConvertedRespOffer);
            FinalOfferResponseWrapper respWrapOffer = (FinalOfferResponseWrapper)JSON.deserialize(finalResponseOffer, FinalOfferResponseWrapper.class);
            finalOfferValuesMap.put('ROINTR', respWrapOffer.finalOffer.ROINTR);
            finalOfferValuesMap.put('MAXLTV', respWrapOffer.finalOffer.MAXLTV);
            finalOfferValuesMap.put('MAXLOELIGLTV', respWrapOffer.finalOffer.MAXLOELIGLTV);
            finalOfferValuesMap.put('MAXLOELIGINC', respWrapOffer.finalOffer.MAXLOELIGINC);
            finalOfferValuesMap.put('LOANTENU', respWrapOffer.finalOffer.LOANTENU);
            finalOfferValuesMap.put('LOANAMTOFFR', respWrapOffer.finalOffer.LOANAMTOFFR);
            finalOfferValuesMap.put('FINALLTV', respWrapOffer.finalOffer.FINALLTV);
            finalOfferValuesMap.put('FINALFOIR', respWrapOffer.finalOffer.FINALFOIR);
            finalOfferValuesMap.put('EMIFINOFF', respWrapOffer.finalOffer.EMIFINOFF);
            finalOfferValuesMap.put('additionalLtv', respWrapOffer.finalOffer.additionalLtv);
            finalOfferValuesMap.put('CombBalAverageEOD180Day_new_Non_OD',String.valueof(ADBB));
            // for(FinalOfferResponseWrapper.cls_finalOffer iterOffer : respWrapOffer.finalOffer){
            //     fieldDataMap.put(iterOffer.fieldName, iterOffer);
            // }
            // Add Eligibility_Status__c first if available
            // if (intDetList[0].Eligibility_Status__c != null) {
            //     ResponseWrapper rw = new ResponseWrapper();
            //     rw.fieldLabel = 'Crif Segment';
            //     rw.isBlank= true;
            //     rw.fieldValue = intDetList[0].Eligibility_Status__c;
            //     rw.sectionSeperatorName = 'Bureau paramenters for key applicant';
            //     rw.isSectionSeperator = true;
            //     respList.add(rw);
            // }
        

        // Define expected fields and their metadata
        List<Map<String, String>> expectedFields = new List<Map<String, String>>{
            // new Map<String, String>{'api' => 'cibilScore', 'label' => 'CIBIL Score', 'section' => 'Bureau paramenters for key applicant', 'separator' => 'false'},
            // new Map<String, String>{'api' => 'isUnsecuredInLast6M', 'label' => 'No of unsecured loans available in last 6 months', 'section' => 'Bureau paramenters for key applicant', 'separator' => 'false'},
            // new Map<String, String>{'api' => 'totalNumEnqLast90Days', 'label' => 'No of enquiries in last 3 months', 'section' => 'Bureau paramenters for key applicant', 'separator' => 'false'},
            // new Map<String, String>{'api' => 'MAXLOELIGINC', 'label' => 'Eligible loan amount', 'section' => 'Eligibility summary', 'separator' => 'true'},
            // new Map<String, String>{'api' => 'ROINTR', 'label' => 'ROI', 'section' => 'Eligibility summary', 'separator' => 'false'},
            // new Map<String, String>{'api' => 'LOANTENU', 'label' => 'Tenor', 'section' => 'Eligibility summary', 'separator' => 'false'},
          
            new Map<String, String>{'api' => 'BANKINGINDEX', 'label' => 'Banking Index', 'section' => 'Banking Parameters', 'separator' => 'true'},
            new Map<String, String>{'api' => 'CombBalAverageEOD180Day_new_Non_OD', 'label' => 'ADBB', 'section' => 'Banking Parameters', 'separator' => 'false'},
            new Map<String, String>{'api' => 'BANKINGTURNOVER', 'label' => 'Banking Turnover', 'section' => 'Banking Parameters', 'separator' => 'false'},
            new Map<String, String>{'api' => 'CHWQUEINWARDBOUNCE', 'label' => 'Count of ECS bounce in last 3 months', 'section' => 'Banking Parameters', 'separator' => 'false'},
            new Map<String, String>{'api' => 'DTO', 'label' => 'Debt to banking turnover', 'section' => 'Banking Parameters', 'separator' => 'false'},
            new Map<String, String>{'api' => 'ETO', 'label' => 'USL ETO to banking turnover', 'section' => 'Banking Parameters', 'separator' => 'false'}
        };

        // Loop through expected fields, populate values or show blank
        for (Map<String, String> fieldMeta : expectedFields) {
            String api = fieldMeta.get('api');
            String label = fieldMeta.get('label');
            String section = fieldMeta.get('section');
            Boolean isSep = Boolean.valueOf(fieldMeta.get('separator'));

            ResponseWrapper rw = new ResponseWrapper();
            rw.isBlank= true;
            rw.isRed=false;
            rw.isGreen=false;
            rw.fieldLabel = label;
            rw.sectionSeperatorName = section;
            rw.isSectionSeperator = isSep;

            if (fieldDataMap.containsKey(api)) {
                //rw.fieldValue = fieldDataMap.get(api).fieldValue;
                rw.fieldValue = convertScientificToPlain(fieldDataMap.get(api).fieldValue);
                if(rw.fieldValue.contains(',')){
                    if(rw.fieldValue.split(',')[1].containsIgnoreCase('green') || rw.fieldValue.split(',')[1].containsIgnoreCase('pass')){
                        rw.isGreen=true;
                        rw.isBlank = false;
                    }
                    else if(rw.fieldValue.split(',')[1].containsIgnoreCase('red')){ 
                        rw.isRed=true;
                        rw.isBlank = false;
                    }
                    rw.fieldValue = rw.fieldValue.split(',')[0];
                     if (fieldDataMap.containsKey('BANKINGINDEX')) {
                         
                        opp.BANKING_Index__c =fieldDataMap.get('BANKINGINDEX').fieldValue.split(',')[0];
                    }
                    rw.fieldValue = convertScientificToPlain(rw.fieldValue);
                }
            } 
            else if(finalOfferValuesMap.containsKey(api)){
                rw.fieldValue = finalOfferValuesMap.get(api);
                if(rw.fieldValue.contains(',')){
                    if(rw.fieldValue.split(',')[1].containsIgnoreCase('green') || rw.fieldValue.split(',')[1].containsIgnoreCase('pass')){
                        rw.isGreen=true;
                        rw.isBlank = false;
                    }
                    else if(rw.fieldValue.split(',')[1].containsIgnoreCase('red')){ 
                        rw.isRed=true;
                        rw.isBlank = false;
                    }
                    rw.fieldValue = rw.fieldValue.split(',')[0];
                    //rw.fieldValue = convertScientificToPlain(rw.fieldValue);
                }
                else{
                    rw.fieldValue = convertScientificToPlain(finalOfferValuesMap.get(api));
                }
            }
            else {
                rw.fieldValue = ''; // Empty if data not found
            }
            respList.add(rw);
        }
        update opp;
        return respList;
    }
    public class FinalOfferResponseWrapper{
        public cls_finalOffer finalOffer;
    }
    public class cls_finalOffer {
        public String ROINTR;	//18.0
        public String MAXLTV;	//0.0
        public String MAXLOELIGLTV;	//0.0
        public String MAXLOELIGINC;	//2000000.0
        public String LOANTENU;	//120.0
        public String LOANAMTOFFR;	//600000.0
        public String FINALLTV;	//0.0
        public String FINALFOIR;	//0.54
        public String EMIFINOFF;	//10811.11
        public String additionalLtv;	//0.0
    }
   
    public static String convertScientificToPlain(String value) {
        if (String.isBlank(value)) return '';
        // if(value.contains(',')){
        //     value = value.split(',')[0];
        // }
        // Regex pattern for exponential numbers like 1.23E4 or -5.6e+9
        // Optional sign, digits, optional decimal, E or e, optional +/-, then digits
        Pattern p = Pattern.compile('^[+-]?[0-9]+(\\.[0-9]+)?[eE][+-]?[0-9]+$');

        if (p.matcher(value).matches()) {
            try {
                Double d = Double.valueOf(value);
                return d.format(); // Converts to plain number string
            } catch (Exception e) {
                return value; // fallback if conversion fails
            }
        }
        System.debug('value=:'+value);
        return value; // not exponential format, return as-is
    }
    
    



        // @AuraEnabled
        // public static List<ResponseWrapper> getScreenFieldData(String screenName, String loanId) {
        //     List<ResponseWrapper> respList = new List<ResponseWrapper>();
        //     Set<String> addedFields = new Set<String>();

        //     List<Integration_Details__c> intDetList = [
        //         SELECT Id, Response_JSON__c, Eligibility_Status__c 
        //         FROM Integration_Details__c 
        //         WHERE Loan_Application__c = :loanId AND Name = 'BANKINGSURROGATE' 
        //         ORDER BY CreatedDate DESC
        //     ];

        //     if (!intDetList.isEmpty()) {
        //         Integer startIndex = intDetList[0].Response_JSON__c.indexOf('<response>');
        //         Integer endIndex = intDetList[0].Response_JSON__c.indexOf('</response>') + '</response>'.length();
        //         String responseTag = intDetList[0].Response_JSON__c.substring(startIndex, endIndex);
        //         Map<String, Object> xmlConvertedResp = XMLConvertor.xmlToMap(responseTag);
        //         String finalResponse = JSON.serialize(xmlConvertedResp);
        //         FICOResponse respWrap = (FICOResponse)JSON.deserialize(finalResponse, FICOResponse.class);
        //         if (intDetList[0].Eligibility_Status__c != null) {
        //             ResponseWrapper rw = new ResponseWrapper();
        //             rw.fieldLabel = 'Crif Segment';
        //             rw.fieldValue = intDetList[0].Eligibility_Status__c;
        //             rw.sectionSeperatorName = 'Bureau paramenters for key applicant';
        //             rw.isSectionSeperator = true;
        //             respList.add(rw);
        //         }

        //         for (FICOResponse.cls_calculatedVariables iterVar : respWrap.response.calculatedVariables) {
        //             if (addedFields.contains(iterVar.fieldName)) {
        //                 continue;
        //             }

        //             ResponseWrapper rw = new ResponseWrapper();
        //             rw.fieldValue = iterVar.fieldValue;
        //             if (iterVar.fieldName == 'cibilScore') {
        //                 rw.fieldLabel = 'CIBIL Score';
        //                 rw.isSectionSeperator = false;
        //                 rw.sectionSeperatorName = 'Bureau paramenters for key applicant';
        //             }
        //             else if (iterVar.fieldName == 'isUnsecuredInLast6M') {
        //                 rw.fieldLabel = 'No of unsecured loans available in last 6 months';
        //                 rw.isSectionSeperator = false;
        //                 rw.sectionSeperatorName = 'Bureau paramenters for key applicant';
        //             }  else if (iterVar.fieldName == 'totalNumEnqLast90Days') {
        //                 rw.fieldLabel = 'No of enquiries in last 3 months';
        //                 rw.sectionSeperatorName = 'Bureau paramenters for key applicant';
        //                 rw.isSectionSeperator = false;
        //             } 
        //             else if (iterVar.fieldName == 'MAXLOELIGINC') {
        //                 rw.fieldLabel = 'Eligible loan amount';
        //                 rw.isSectionSeperator = true;
        //                 rw.sectionSeperatorName = 'Eligibility summary';
        //             } else if (iterVar.fieldName == 'ROINTR') {
        //                 rw.fieldLabel = 'ROI';
        //                 rw.isSectionSeperator = true;
        //                 rw.sectionSeperatorName = 'Eligibility summary';
        //             } else if (iterVar.fieldName == 'LOANTENU') {
        //                 rw.fieldLabel = 'Tenor';
        //                 rw.isSectionSeperator = true;
        //                 rw.sectionSeperatorName = 'Eligibility summary';
        //             } else if (iterVar.fieldName == 'CombBalAverageEOD180Day_new_Non_OD') {
        //                 rw.fieldLabel = 'ADBB';
        //                 rw.isSectionSeperator = true;
        //                 rw.sectionSeperatorName = 'Eligibility summary';
        //             } 
                
                    
                    
        //             else if (iterVar.fieldName == 'BANKINGINDEX') {
        //                 rw.fieldLabel = 'Banking Index';
        //                 rw.isSectionSeperator = true;
        //                 rw.sectionSeperatorName = 'Banking Parameters';
        //             }
        //             // } else if (iterVar.fieldName == 'CUSTOMERSEGMENT') {
        //             //     rw.fieldLabel = 'Customer Segment';
        //             //     rw.isSectionSeperator = false;
        //             // }
        //             else if (iterVar.fieldName == 'BANKINGTURNOVER') {
        //                 rw.fieldLabel = 'Banking Turnover';
        //                 rw.isSectionSeperator = false;
        //                 rw.sectionSeperatorName = 'Banking Parameters';

        //             } else if (iterVar.fieldName == 'CHWQUEINWARDBOUNCE') {
        //                 rw.fieldLabel = 'Count of ECS bounce in last 3 months';
        //                 rw.isSectionSeperator = false;
        //                 rw.sectionSeperatorName = 'Banking Parameters';
        //             } 
        //             else if (iterVar.fieldName == 'DTO') {
        //                 rw.fieldLabel = 'Debt to banking turnover';
        //                 rw.isSectionSeperator = false;
                    
        //                 rw.sectionSeperatorName = 'Banking Parameters';
        //             }
        //             else {
        //                 continue; // if the field is not relevant, skip
        //             }

        //             respList.add(rw);
        //             addedFields.add(iterVar.fieldName); // Mark as processed
        //         }

            
        //     }

        //     return respList;
        // }



    public class Request{
        public cls_request request;
    }
   
	public class cls_request {
		public cls_application application;
	}
	class cls_application {
		public cls_applicationAdditionalDetails applicationAdditionalDetails;
		
	}

	class cls_applicationAdditionalDetails {
		
		public cls_balanceTransfer balanceTransfer;
	}
	
	class cls_balanceTransfer {
		public String topUpLanNo;	//1.000
		public String topUpAmount;	//34999.000
		public String specifyOtherEndUse;	//FALSE
		public String nameOfOtherFinancialInst;	//
		public String nameOfFinancialInstitute;	//
		public String moratoriumSchemeFlagging;	//
		public String endUseForTopUp;	//
		public String currentOccupancyOfProperty;	//
		public String consolidatedLtv;	//
		public String btOutstanding;	//120.008333333333333333333333333333
		public String btMob;	//0.000
		public String btLoanLanNo;	//250625.600
	}
	
}