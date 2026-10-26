public with sharing class EligibilityCriteriaController {

    @AuraEnabled
    public static List<EligibilityWrap> getAllApplicableEligibilities(String recordId, Boolean setDefaultCheckboxFalse) {
        List<EligibilityWrap> wrapLst = new List<EligibilityWrap>();
        Boolean isBHMSBAMS = false;
        List<Application_Applicant__c> lstApplicant = [SELECT id,Employment_Type__c,Customer_Type__c,Customer_Profile__c,Qualification__c,Loan_Application__r.Program_Type__c FROM Application_Applicant__c WHERE Loan_Application__c =:recordId AND Applicant_Type__c = 'Primary Applicant'];
        if(String.isNotBlank(lstApplicant[0].Qualification__c) && (lstApplicant[0].Qualification__c == 'BHMS' || lstApplicant[0].Qualification__c == 'BAMS'))  {
            isBHMSBAMS = true;
        }
        if(lstApplicant.size() > 0) {
            Set<String> eligibilityNames = new Set<String>();
            List<PLF_Master__c> masterLst = new List<PLF_Master__c>();
            List<PLF_Master__c> masterLst1 = [SELECT id,Description__c,FICO_Code__c FROM PLF_Master__c WHERE  Applicant_Type_SF__c =: lstApplicant[0].Customer_Type__c AND  Master_Type__c = 'Program types' AND Customer_Type__c =:lstApplicant[0].Customer_Profile__c] ;
            if(isBHMSBAMS) {
                masterLst = masterLst1;
            }else {
                for(PLF_Master__c iterMST : masterLst1) {
                    if(iterMST.Description__c != 'Banking Program - BAMS or BHMS') {
                        masterLst.add(iterMST);
                    }
                }
            }
            if(masterLst.size() > 0) {
                for(PLF_Master__c iterMaster : masterLst) {
                    eligibilityNames.add(iterMaster.FICO_Code__c);
                }
            }
            List<Integration_Details__c> lstIntgration = [SELECT id,Name,Response_JSON__c,IsConsideredEligibility__c,createddate,Eligibility_Status__c,Related_Record_Id__c FROM Integration_Details__c WHERE Loan_Application__c=:recordId AND Status__c = '200' AND Name IN : eligibilityNames];
            Map<String,Integration_Details__c> intMap = new Map<String,Integration_Details__c>();
            for(Integration_Details__c iterIntegra : lstIntgration) {
                if(intMap.containsKey(iterIntegra.Name)) {
                    Integration_Details__c temp = intMap.get(iterIntegra.Name);
                    if(iterIntegra.createddate > temp.createddate) {
                        intMap.put(iterIntegra.Name,iterIntegra);
                    }
                }else {
                    intMap.put(iterIntegra.Name,iterIntegra);
                }
                
            }
            Map<String,Integration_Details__c> docListIds = new Map<String,Integration_Details__c>();
            if(intMap.size() > 0) {
                for(Integration_Details__c iterInte : intMap.values()) {
                    docListIds.put(iterInte.Related_Record_Id__c,iterInte);
                }
            }
            Map<String,String> contentDocIds = new Map<String,String>();
            if(docListIds.size() > 0) {
                List<Document_Details__c> docLst= [SELECT id,createddate,Content_Document_Id__c from Document_Details__c  where name = 'Income Eligibility Response' AND id IN:docListIds.keySet()];
                if(docLst.size() > 0) {
                    for(Document_Details__c iterDosCheck : docLst) {
                        contentDocIds.put(iterDosCheck.id,iterDosCheck.Content_Document_Id__c);
                    }
                }
            }
            Map<String,String> contverToXMString = new Map<String,String>();
            if(contentDocIds.size() > 0) {
                List<ContentVersion> conversionLst = [SELECT id,VersionData,ContentDocumentId  FROM ContentVersion WHERE ContentDocumentId IN:contentDocIds.values()];
                for(ContentVersion iterConVersion : conversionLst) {
                    String xmlResponse = iterConVersion.VersionData.toString();
                    Integer startIndex = xmlResponse.indexOf('<finalOffer>');
                    Integer endIndex = xmlResponse.indexOf('</finalOffer>');
                    endIndex = endIndex + ('</finalOffer>'.length());
                    xmlResponse = xmlResponse.substring(startIndex,endIndex);
                    System.debug('xmlResponse '+xmlResponse);
                    contverToXMString.put(iterConVersion.ContentDocumentId,xmlResponse);
                    //applicantTuffRes.put(conDocIds.get(iterConVersion.ContentDocumentId),xmlResponse);
                }
            }


               
            
            for(PLF_Master__c iterMaster : masterLst) {
                EligibilityWrap objTemp = new EligibilityWrap();
                
                //Not Eligible
                objTemp.eligibilityType = iterMaster.Description__c;
                objTemp.eligibilityTypeFicoName = iterMaster.FICO_Code__c;
                objTemp.consideredEligibility = false;
                objTemp.isLock = true;
                if(intMap.containsKey(iterMaster.FICO_Code__c)) {
                    String finalOffer = '';
                     finalOffer = contverToXMString.get(contentDocIds.get(intMap.get(iterMaster.FICO_Code__c).Related_Record_Id__c));
                    if(String.isNotBlank(finalOffer)) {
                        Integration_Details__c iterTemp = intMap.get(iterMaster.FICO_Code__c);
                        //String finalOffer = iterTemp.Response_JSON__c;
                        Integer startIndex = finalOffer.indexOf('<finalOffer>');
                        Integer endIndex = finalOffer.indexOf('</finalOffer>');
                        endIndex = endIndex + ('</finalOffer>'.length());
                        finalOffer = finalOffer.substring(startIndex,endIndex);
                        String JSONRes = XmlToJSONParser.XMLToJSON(finalOffer);
                        EligibilityCriteriaController objRecords = (EligibilityCriteriaController)JSON.deserialize(JSONRes, EligibilityCriteriaController.class);
                        System.debug(objRecords.finalOffer.EMIFINOFF);
                        if(iterTemp.Eligibility_Status__c == 'Not Eligible') {
                            objTemp.eligibleLoanAmount = 'Not Eligible';
                            objTemp.finalLoanEmi = 'Not Eligible';
                            //objTemp.finalLoanAmount = 'Not Eligible';
                            objTemp.tenor = 'Not Eligible';
                        }else {
                        objTemp.eligibleLoanAmount = objRecords.finalOffer.MAXLOELIGINC;
                        objTemp.finalLoanEmi = objRecords.finalOffer.EMIFINOFF;
                        //objTemp.finalLoanAmount = objRecords.finalOffer.EMIFINOFF;
                        objTemp.tenor = objRecords.finalOffer.LOANTENU;
                        }
                        objTemp.integrationId = iterTemp.id;
                        if (setDefaultCheckboxFalse == false) {
                            System.debug('Inside if');
                            if(lstApplicant[0].Loan_Application__r.Program_Type__c == iterTemp.name) {
                                System.debug('Inside if1');
                                objTemp.consideredEligibility = true;
                            } else {
                                System.debug('Inside else1');
                            }
                        } else {
                            System.debug('Inside else');
                            objTemp.consideredEligibility = false;
                        }
                        
                        objTemp.isLock = false;
                    }

                    
                }
                wrapLst.add(objTemp);

            }
        }
        return wrapLst;
        

    }

    public class EligibilityWrap {
        @AuraEnabled public String eligibilityType;
        @AuraEnabled public String eligibilityTypeFicoName;
        @AuraEnabled public String eligibleLoanAmount;
        @AuraEnabled public String finalLoanEmi;
        @AuraEnabled public String finalLoanAmount;
        @AuraEnabled public String tenor;
        @AuraEnabled public String integrationId;
        @AuraEnabled public Boolean consideredEligibility;
        @AuraEnabled public Boolean isLock;
    }
/*
    @AuraEnabled(cacheable=true)
    public static List<Eligibility_Criterias__mdt> getEligibilityCriteria() {
        return [SELECT Id, MasterLabel, Active__c,Activated_on__c,Field_Name__c,Field_Api_Name__c,Type__c FROM Eligibility_Criterias__mdt where Type__c = 'Income Method' AND Active__c = true];
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<Eligibility_Criterias__mdt> getEligibilityMethod() {
        return [SELECT Id, MasterLabel, Active__c,Activated_on__c,Field_Name__c,Field_Api_Name__c,Type__c FROM Eligibility_Criterias__mdt where Type__c = 'Eligibility Method' AND Active__c = true];
    }
*/

        @AuraEnabled
    public static void insertIntegrationDetails(Id loanId, String masterRecordId, Decimal eligibleAmount) {
            try {
                List<Integration_Details__c> existingIntegrations = [SELECT Id, Calling_Source__c, Eligible_Loan_Amount__c, Name, Loan_Application__c FROM Integration_Details__c 
                WHERE Loan_Application__c = :loanId AND Name = :masterRecordId];


                if (!existingIntegrations.isEmpty()) {
                    Integration_Details__c existingIntegration = existingIntegrations[0];
                    existingIntegration.Eligible_Loan_Amount__c = eligibleAmount;
                    update existingIntegration;
                } else {
                    Integration_Details__c integration = new Integration_Details__c();
                    integration.Loan_Application__c = loanId;
                    integration.Name = masterRecordId;
                    integration.Calling_Source__c = 'Manual';
                    integration.Eligible_Loan_Amount__c = eligibleAmount;
                    integration.Endpoint__c = 'Its Manual';
                    insert integration;
                }

        } catch (Exception e) {
            throw new AuraHandledException('Error inserting or updating integration details: ' + e.getMessage());
        }
    }

    public class IntegrationWrapper {
        @AuraEnabled public Id integrationId;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal eligibleLoanAmount;
    }

    @AuraEnabled
    public static List<IntegrationWrapper> getIntegrationDataByLoanId(Id loanId, List<String> eligibleFicoNamesList) {
        List<IntegrationWrapper> wrappers = new List<IntegrationWrapper>();

        try {
            // Null check and convert List to Set to avoid duplicates in query
            if (loanId == null || eligibleFicoNamesList == null || eligibleFicoNamesList.isEmpty()) {
                return wrappers;
            }

            Set<String> eligibleFicoNames = new Set<String>(eligibleFicoNamesList);

            List<Integration_Details__c> integrations = [SELECT Id, Name, Eligible_Loan_Amount__c FROM Integration_Details__c WHERE Loan_Application__c = :loanId AND Name IN :eligibleFicoNames ];

            if (!integrations.isEmpty()) {
            for (Integration_Details__c integration : integrations) {
                    IntegrationWrapper wrap = new IntegrationWrapper();
                    wrap.integrationId = integration.Id;
                    wrap.name = integration.Name;
                    wrap.eligibleLoanAmount = integration.Eligible_Loan_Amount__c;
                    wrappers.add(wrap);
                }
            }
        } catch (Exception e) {
            System.debug('Error in getIntegrationDataByLoanId: ' + e.getMessage());
        }

        return wrappers;
    }



    @AuraEnabled
    public static String checkEligibility(String recordId,String eligibilityName, Decimal adb,Boolean isCallForDeviation,Boolean fromSales) {
        Map<String,String> inputMap = new Map<String,String>();
        /*List<Income_Expense_Obligation__c> parent = [SELECT id,DTO__c,DTO_API__c from Income_Expense_Obligation__c where Loan_Application__c =:recordId AND Type__c='Obligation' AND IsParent__c = true];
        if(parent.size() > 0) {
            if(parent[0].DTO__c != null || parent[0].DTO__c != 0) {
                inputMap.put('dto',String.valueOf(parent[0].DTO__c));
            }
            
        }*/
        String res;
        Opportunity loanApp = [SELECT Id, Sanction_Loan_Amount__c FROM Opportunity WHERE Id =: recordId LIMIT 1];
        inputMap.put('loanId',recordId);
        inputMap.put('processName','Credit Eligibility');
        inputMap.put('eligibilityType',eligibilityName);
        inputMap.put('adb',String.valueof(adb));
        inputMap.put('callForDeviation',String.valueOf(isCallForDeviation));
        inputMap.put('isIncomeFromSales',String.valueof(fromSales));
        
        if(isCallForDeviation == true) {
            // if(loanApp.Sanction_Loan_Amount__c == null || loanApp.Sanction_Loan_Amount__c <= 0) {
                // res = 'Please fill sanction loan amount and check eligibility to fetch correct deviation.';
            // }else {
                res = EligibilityApiController.initiateAPIRequest(inputMap);
            // }
        }else {
            res = EligibilityApiController.initiateAPIRequest(inputMap);
        }
        
        System.debug('res '+res);
        return res;
    }

    @AuraEnabled
    public static EligibilityWrap getIntegrationData(String integrationId) {
        EligibilityWrap objTemp = new EligibilityWrap();
        List<Integration_Details__c> lstIntgration = [SELECT id,Name,Response_JSON__c,IsConsideredEligibility__c,createddate,Loan_Application__c, Related_Record_Id__c   FROM Integration_Details__c WHERE Id=:integrationId];
        if(lstIntgration.size() > 0) {
            String docId= lstIntgration[0].Related_Record_Id__c;
            List<Document_Details__c> docLst= [SELECT id,createddate,Content_Document_Id__c from Document_Details__c  where name = 'Income Eligibility Response' AND id = :docId];
            List<ContentVersion> conversionLst = [SELECT id,VersionData,ContentDocumentId  FROM ContentVersion WHERE ContentDocumentId = :docLst[0].Content_Document_Id__c LIMIT 1];
            String finalOffer = conversionLst[0].VersionData.toString();
            Integer startIndex = finalOffer.indexOf('<finalOffer>');
            Integer endIndex = finalOffer.indexOf('</finalOffer>');
            endIndex = endIndex + ('</finalOffer>'.length());
            finalOffer = finalOffer.substring(startIndex,endIndex);
            String JSONRes = XmlToJSONParser.XMLToJSON(finalOffer);
            EligibilityCriteriaController objRecords = (EligibilityCriteriaController)JSON.deserialize(JSONRes, EligibilityCriteriaController.class);
            System.debug(objRecords.finalOffer.EMIFINOFF);
            objTemp.eligibleLoanAmount = objRecords.finalOffer.MAXLOELIGINC;
            objTemp.finalLoanEmi = objRecords.finalOffer.EMIFINOFF;
            //objTemp.finalLoanAmount = objRecords.finalOffer.EMIFINOFF;
            objTemp.tenor = objRecords.finalOffer.LOANTENU;
            objTemp.integrationId = lstIntgration[0].id;
            objTemp.consideredEligibility = lstIntgration[0].IsConsideredEligibility__c;
            objTemp.isLock = false;
            Opportunity loan = [SELECT id,Sanction_Tenure__c, Sanction_Loan_Amount__c,Sanction_Rate_Of_Interest__c,Emi_amount__c,Eligible_Loan_Amount__c FROM Opportunity WHERE id=:lstIntgration[0].Loan_Application__c];
            List<Product2> prodObj = [SELECT Id, Name FROM Product2 WHERE Loan_Application__c  =: lstIntgration[0].Loan_Application__c AND RecordType.name = 'Total Tenure' AND Product__r.Product__r.name = 'Business Loan' LIMIT 1];
            if(prodObj.size() > 0) {
                loan.Sanction_Tenure__c = Decimal.valueOf(prodObj[0].Name);
            }
            loan.Sanction_Loan_Amount__c = Decimal.valueOf(objRecords.finalOffer.MAXLOELIGINC);
            
            loan.Program_Type__c = lstIntgration[0].Name;

            loan.Eligible_Loan_Amount__c = Decimal.valueOf(objRecords.finalOffer.MAXLOELIGINC);
            
                //loan.Sanction_Tenure__c = Decimal.valueOf(objRecords.finalOffer.LOANTENU);
     
           
                loan.Sanction_Rate_Of_Interest__c = Decimal.valueOf(objRecords.finalOffer.ROINTR);
            
            // loan.Emi_amount__c = Decimal.valueOf(objRecords.finalOffer.EMIFINOFF);
            loan.Emi_amount__c = Decimal.valueOf(Math.round(Decimal.valueOf(objRecords.finalOffer.EMIFINOFF)));
            loan.Eligible_Tenure__c = Decimal.valueOf(objRecords.finalOffer.LOANTENU);
            loan.Eligible_Rate_Of_Interest__c = Decimal.valueOf(objRecords.finalOffer.ROINTR);
            update loan;
       }
       return objTemp;
    }

    public cls_finalOffer finalOffer;
	public class cls_finalOffer {
		public String ROINTR;	//18.0
		public String MAXLTV;	//0.0
		public String MAXLOELIGLTV;	//0.0
		public String MAXLOELIGINC;	//1500000.0
		public String LOANTENU;	//120.0
		public String LOANAMTOFFR;	//600000.0
		public String FINALLTV;	//0.0
		public String FINALFOIR;	//0.72
		public String EMIFINOFF;	//10811.11
		public String additionalLtv;	//0.0
	}
}