public class COMM_GstScreenController {
	@AuraEnabled
    public static COMM_ItrScreenController.RecordWrapper getGstRecords(String applicantId, String year) {
        COMM_ItrScreenController.RecordWrapper resWrap = new COMM_ItrScreenController.RecordWrapper();
        String gstRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Income_Expense_Obligation__c','GST');
        List<Income_Expense_Obligation__c> itrObj = [SELECT id,Year__c,Latest_Month_1_In_Lacs__c,Latest_Month_2_In_Lacs__c,
                                                     Latest_Month_3_In_Lacs__c,Latest_Month_4_In_Lacs__c,Latest_Month_5_In_Lacs__c,
                                                     Latest_Month_6_In_Lacs__c,Annualized_GST_Turnover_In_Lacs__c
                                                     FROM Income_Expense_Obligation__c WHERE Application_Applicant__c =: applicantId
                                                     AND Year__c =: year AND recordTypeId =:gstRecordTypeId ];
        if(itrObj.size() > 0) {
            resWrap.recId = itrObj[0].id;
            resWrap.year = itrObj[0].Year__c;
            resWrap.month1 = itrObj[0].Latest_Month_1_In_Lacs__c;
            resWrap.month2 = itrObj[0].Latest_Month_2_In_Lacs__c;
            resWrap.month3 = itrObj[0].Latest_Month_3_In_Lacs__c;
            resWrap.month4 = itrObj[0].Latest_Month_4_In_Lacs__c;
            resWrap.month5 = itrObj[0].Latest_Month_5_In_Lacs__c;
            resWrap.month6 = itrObj[0].Latest_Month_6_In_Lacs__c;
            resWrap.gstAnnualTurnover = itrObj[0].Annualized_GST_Turnover_In_Lacs__c;
            
        }
        return resWrap;
        
    }
    @AuraEnabled
    public static void saveGstRecord(String applicantId, String res) {
        COMM_ItrScreenController.RecordWrapper lstRecords = (COMM_ItrScreenController.RecordWrapper)JSON.deserialize(res, COMM_ItrScreenController.RecordWrapper.class);
        String gstRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Income_Expense_Obligation__c','GST');
        Income_Expense_Obligation__c iterObj = new Income_Expense_Obligation__c();
        if(String.isNotBlank(lstRecords.recId)) {
            iterObj.id = lstRecords.recId;
            iterObj.Application_Applicant__c = applicantId;
        }else {
            iterObj.RecordTypeId = gstRecordTypeId;
            iterObj.Application_Applicant__c = applicantId;  
        }
        iterObj.Year__c = lstRecords.year;
        iterObj.Latest_Month_1_In_Lacs__c = lstRecords.month1;
        iterObj.Latest_Month_2_In_Lacs__c = lstRecords.month2;
        iterObj.Latest_Month_3_In_Lacs__c = lstRecords.month3;
        iterObj.Latest_Month_4_In_Lacs__c = lstRecords.month4;
        iterObj.Latest_Month_5_In_Lacs__c = lstRecords.month5;
        iterObj.Latest_Month_6_In_Lacs__c = lstRecords.month6;
        iterObj.Annualized_GST_Turnover_In_Lacs__c = lstRecords.gstAnnualTurnover;
        upsert iterObj;
    }
}