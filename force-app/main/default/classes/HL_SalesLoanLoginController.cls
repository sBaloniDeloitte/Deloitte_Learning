/*
 * Created By : Ishi Jain
 * Created Date : 9/8/2025
 * Purpose : This class would be used for sales module in HL
 */

public with sharing class HL_SalesLoanLoginController {
   @AuraEnabled
   public static void deletePanDetails(Map<String,String> inputMap){
   
        String applicantId = inputMap.get('applicantId');
        List<Application_Applicant__c> appList = [SELECT id,PAN_Number__c,DOB__c,DOI__c,Applicant_Type__c FROM  Application_Applicant__c where id=:applicantId LIMIT 1];
        if(appList.size()>0){
            appList[0].PAN_Number__c = null;
            appList[0].DOB__c = null;
            appList[0].DOI__c = null;
            update appList;
        }
        
    
   }
  
}