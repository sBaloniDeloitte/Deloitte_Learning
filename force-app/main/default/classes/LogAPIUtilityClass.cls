/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-12-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class LogAPIUtilityClass {
    public static void logAPIcallouts(Id recordId, string request, string response, string source, Integer responsecode){
        Integration_Details__c log = new Integration_Details__c();
        log.Name = source;
        log.Request_JSON__c = request;
        log.Endpoint__c = source;
        log.Response_JSON__c = response;
        log.Loan_Application__c = recordId;
        log.Status__c = String.valueof(responsecode);
        insert log;
    }
}