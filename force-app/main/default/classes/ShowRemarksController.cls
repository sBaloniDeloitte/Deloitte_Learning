/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-06-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ShowRemarksController {
    
    //common method to get the remarks for records when needed according to logic
    @AuraEnabled
    public static RemarksWrapper getRemarksDetails(String recordId, string processName) {
        RemarksWrapper result = new RemarksWrapper();

        switch on processName {

            when 'Lead Remarks' {
                List<Lead> leads = [SELECT Remarks_History__c, Status FROM Lead WHERE Id =: recordId];

                if(!leads.isEmpty()){
                    result.remarks = leads[0].Remarks_History__c;
                    result.allowCreation = leads[0].Status == 'Open' ? true : false;
                }
            }
            when 'FI Remarks' {
                List<Application_Verification__c> fiRec = [SELECT Id,Stantard_Remark__c, Credit_Manager_s_Remarks__c, Waiver_Remark__c, Admin_s_Remarks__c, Any_Remarks_Reasons__c, RecordType.Name 
                                                           FROM Application_Verification__c WHERE Id =: recordId];
            
                if (!fiRec.isEmpty()) {
                    String combinedRemarks = '';
                    String finalRemarks = '';
                    System.debug('Any_Remarks_Reasons__c: ' + fiRec[0].Any_Remarks_Reasons__c);
                    System.debug('Is Blank Check: ' + String.isNotBlank(fiRec[0].Any_Remarks_Reasons__c));
                    Map<DateTime,String> dateTimeToRemarksMap = new Map<DateTime,String>();
                    //    if(fiRec[0].RecordType.Name == 'Personal Discussion'){
                        if (String.isNotBlank(fiRec[0].Stantard_Remark__c)) {
                            System.debug('Stantard_Remark__c 1: ' + fiRec[0].Stantard_Remark__c);
                            List<String> remarksList = fiRec[0].Stantard_Remark__c.split(',\n');
                            for(String iterRem : remarksList){
                                String dateTimeString = iterRem.split('- ')[1];
    
                                // First, split the date and time parts
                                List<String> parts = dateTimeString.split(', ');
                                String datePart = parts[0]; // "17/02/2025"
                                String timePart = parts[1]; // "11:39 am"
        
                                // Parse the date part
                                List<String> dateElements = datePart.split('-');
                                Integer day = Integer.valueOf(dateElements[0]);
                                Integer month = Integer.valueOf(dateElements[1]);
                                Integer year = Integer.valueOf(dateElements[2]);
        
                                // Parse the time part
                                timePart = timePart.toLowerCase();
                                List<String> timeElements = timePart.split(':');
                                Integer hour = Integer.valueOf(timeElements[0]);
                                Integer minute = Integer.valueOf(timeElements[1].substring(0, 2));
                                // String meridian = timeElements[1].substring(3, 5);
        
                                // // Convert 12-hour format to 24-hour format
                                // if (meridian == 'pm' && hour != 12) {
                                //     hour += 12;
                                // } else if (meridian == 'am' && hour == 12) {
                                //     hour = 0;
                                // }
        
                                // Create the Datetime instance
                                Datetime dt = Datetime.newInstance(year, month, day, hour, minute, 0);
                                dateTimeToRemarksMap.put(dt,iterRem);
                            }
                            
                            combinedRemarks += fiRec[0].Stantard_Remark__c + '\n';
                            System.debug('combinedRemarks: ' + combinedRemarks);
                        }
                    // }else {
                        if (String.isNotBlank(fiRec[0].Credit_Manager_s_Remarks__c)) {
                            List<String> remarksList = fiRec[0].Credit_Manager_s_Remarks__c.split(',\n');
                            for(String iterRem : remarksList){
                                String dateTimeString = iterRem.split('- ')[1];
    
                                // First, split the date and time parts
                                List<String> parts = dateTimeString.split(', ');
                                String datePart = parts[0]; // "17/02/2025"
                                String timePart = parts[1]; // "11:39 am"
        
                                // Parse the date part
                                List<String> dateElements = datePart.split('-');
                                Integer day = Integer.valueOf(dateElements[0]);
                                Integer month = Integer.valueOf(dateElements[1]);
                                Integer year = Integer.valueOf(dateElements[2]);
        
                                // Parse the time part
                                timePart = timePart.toLowerCase();
                                List<String> timeElements = timePart.split(':');
                                Integer hour = Integer.valueOf(timeElements[0]);
                                Integer minute = Integer.valueOf(timeElements[1].substring(0, 2));
                                // String meridian = timeElements[1].substring(3, 5);
        
                                // Create the Datetime instance
                                Datetime dt = Datetime.newInstance(year, month, day, hour, minute, 0);
                                dateTimeToRemarksMap.put(dt,iterRem);
                            }
                            
                            combinedRemarks +=  fiRec[0].Credit_Manager_s_Remarks__c + '\n';
                        }
                    // }
                    if (String.isNotBlank(fiRec[0].Admin_s_Remarks__c)) {
                        List<String> remarksList = fiRec[0].Admin_s_Remarks__c.split(',\n');
                        for(String iterRem : remarksList){
                            String dateTimeString = iterRem.split('- ')[1];

                            // First, split the date and time parts
                            List<String> parts = dateTimeString.split(', ');
                            String datePart = parts[0]; // "17/02/2025"
                            String timePart = parts[1]; // "11:39 am"
    
                            // Parse the date part
                            List<String> dateElements = datePart.split('-');
                            Integer day = Integer.valueOf(dateElements[0]);
                            Integer month = Integer.valueOf(dateElements[1]);
                            Integer year = Integer.valueOf(dateElements[2]);
    
                            // Parse the time part
                            timePart = timePart.toLowerCase();
                            List<String> timeElements = timePart.split(':');
                            Integer hour = Integer.valueOf(timeElements[0]);
                            Integer minute = Integer.valueOf(timeElements[1].substring(0, 2));
                            // String meridian = timeElements[1].substring(3, 5);
    
                            // Create the Datetime instance
                            Datetime dt = Datetime.newInstance(year, month, day, hour, minute, 0);
                            dateTimeToRemarksMap.put(dt,iterRem);
                        }
                        combinedRemarks += fiRec[0].Admin_s_Remarks__c + '\n';
                    }
                    if (String.isNotBlank(fiRec[0].Any_Remarks_Reasons__c)) {
                        System.debug('Any_Remarks_Reasons__c 1: ' + fiRec[0].Any_Remarks_Reasons__c);
                        List<String> remarksList = fiRec[0].Any_Remarks_Reasons__c.split(',\n');
                        for(String iterRem : remarksList){
                            String dateTimeString = iterRem.split('- ')[1];

                            // First, split the date and time parts
                            List<String> parts = dateTimeString.split(', ');
                            String datePart = parts[0]; // "17/02/2025"
                            String timePart = parts[1]; // "11:39 am"
    
                            // Parse the date part
                            List<String> dateElements = datePart.split('-');
                            Integer day = Integer.valueOf(dateElements[0]);
                            Integer month = Integer.valueOf(dateElements[1]);
                            Integer year = Integer.valueOf(dateElements[2]);
    
                            // Parse the time part
                            timePart = timePart.toLowerCase();
                            List<String> timeElements = timePart.split(':');
                            Integer hour = Integer.valueOf(timeElements[0]);
                            Integer minute = Integer.valueOf(timeElements[1].substring(0, 2));
                            // String meridian = timeElements[1].substring(3, 5);

    
                            // Create the Datetime instance
                            Datetime dt = Datetime.newInstance(year, month, day, hour, minute, 0);
                            dateTimeToRemarksMap.put(dt,iterRem);
                        }
                        
                        combinedRemarks += fiRec[0].Any_Remarks_Reasons__c + '\n';
                        System.debug('combinedRemarks: ' + combinedRemarks);
                    }
                    if (String.isNotBlank(fiRec[0].Waiver_Remark__c)) {
                        
                        List<String> remarksList = fiRec[0].Waiver_Remark__c.split(',\n');
                        for(String iterRem : remarksList){
                            String dateTimeString = iterRem.split('- ')[1];

                            // First, split the date and time parts
                            List<String> parts = dateTimeString.split(', ');
                            String datePart = parts[0]; // "17/02/2025"
                            String timePart = parts[1]; // "11:39 am"
    
                            // Parse the date part
                            List<String> dateElements = datePart.split('/');
                            Integer day = Integer.valueOf(dateElements[0]);
                            Integer month = Integer.valueOf(dateElements[1]);
                            Integer year = Integer.valueOf(dateElements[2]);
    
                            // Parse the time part
                            timePart = timePart.toLowerCase();
                            List<String> timeElements = timePart.split(':');
                            Integer hour = Integer.valueOf(timeElements[0]);
                            Integer minute = Integer.valueOf(timeElements[1].substring(0, 2));
                            String meridian = timeElements[1].substring(3, 5);
    
                            // Convert 12-hour format to 24-hour format
                            if (meridian == 'pm' && hour != 12) {
                                hour += 12;
                            } else if (meridian == 'am' && hour == 12) {
                                hour = 0;
                            }
    
                            // Create the Datetime instance
                            Datetime dt = Datetime.newInstance(year, month, day, hour, minute, 0);
                            dateTimeToRemarksMap.put(dt,iterRem);
                        }
                        combinedRemarks += fiRec[0].Waiver_Remark__c + '\n';
                    }
                    if(dateTimeToRemarksMap.size()>0){
                        DateTime dt = System.now();
                        for(DateTime d : dateTimeToRemarksMap.keySet()){
                            if(d<dt){
                                finalRemarks=dateTimeToRemarksMap.get(d)+ '\n'+finalRemarks + '\n';
                                dt=d;
                            }
                            else{
                                finalRemarks=finalRemarks+dateTimeToRemarksMap.get(d)+ '\n';
                            }
                        }
                    }
                    System.debug('combinedRemarks: 2' + combinedRemarks);
                    System.debug('finalRemarks: '+finalRemarks);
                    result.remarks = finalRemarks;
                    //result.remarks = combinedRemarks; // Trim any trailing newlines or spaces
                    System.debug('result.remarks: ' + result.remarks);
                    result.allowCreation = false;
                }
            }
            when 'Vendor PD' {
                List<Application_Verification__c> fiRec = [SELECT Id, Credit_Manager_s_Remarks__c, Waiver_Remark__c,Stantard_Remark__c, Admin_s_Remarks__c, Any_Remarks_Reasons__c 
                                                           FROM Application_Verification__c WHERE Id =: recordId];
            
                if (!fiRec.isEmpty()) {
                    String combinedRemarks = '';
                    String finalRemarks = '';
                    System.debug('Any_Remarks_Reasons__c: ' + fiRec[0].Any_Remarks_Reasons__c);
                    System.debug('Is Blank Check: ' + String.isNotBlank(fiRec[0].Any_Remarks_Reasons__c));
                    Map<DateTime,String> dateTimeToRemarksMap = new Map<DateTime,String>();
                    if (String.isNotBlank(fiRec[0].Stantard_Remark__c)) {
                        System.debug('Stantard_Remark__c 1: ' + fiRec[0].Stantard_Remark__c);
                        List<String> remarksList = fiRec[0].Stantard_Remark__c.split(',\n');
                        for(String iterRem : remarksList){
                            String dateTimeString = iterRem.split('- ')[1];

                            // First, split the date and time parts
                            List<String> parts = dateTimeString.split(', ');
                            String datePart = parts[0]; // "17/02/2025"
                            String timePart = parts[1]; // "11:39 am"
    
                            // Parse the date part
                            List<String> dateElements = datePart.split('/');
                            Integer day = Integer.valueOf(dateElements[0]);
                            Integer month = Integer.valueOf(dateElements[1]);
                            Integer year = Integer.valueOf(dateElements[2]);
    
                            // Parse the time part
                            timePart = timePart.toLowerCase();
                            List<String> timeElements = timePart.split(':');
                            Integer hour = Integer.valueOf(timeElements[0]);
                            Integer minute = Integer.valueOf(timeElements[1].substring(0, 2));
                            String meridian = timeElements[1].substring(3, 5);
    
                            // Convert 12-hour format to 24-hour format
                            if (meridian == 'pm' && hour != 12) {
                                hour += 12;
                            } else if (meridian == 'am' && hour == 12) {
                                hour = 0;
                            }
    
                            // Create the Datetime instance
                            Datetime dt = Datetime.newInstance(year, month, day, hour, minute, 0);
                            dateTimeToRemarksMap.put(dt,iterRem);
                        }
                        
                        combinedRemarks += fiRec[0].Stantard_Remark__c + '\n';
                        System.debug('combinedRemarks: ' + combinedRemarks);
                    }
                    
                    if (String.isNotBlank(fiRec[0].Admin_s_Remarks__c)) {
                        List<String> remarksList = fiRec[0].Admin_s_Remarks__c.split(',\n');
                        for(String iterRem : remarksList){
                            String dateTimeString = iterRem.split('- ')[1];

                            // First, split the date and time parts
                            List<String> parts = dateTimeString.split(', ');
                            String datePart = parts[0]; // "17/02/2025"
                            String timePart = parts[1]; // "11:39 am"
    
                            // Parse the date part
                            List<String> dateElements = datePart.split('/');
                            Integer day = Integer.valueOf(dateElements[0]);
                            Integer month = Integer.valueOf(dateElements[1]);
                            Integer year = Integer.valueOf(dateElements[2]);
    
                            // Parse the time part
                            timePart = timePart.toLowerCase();
                            List<String> timeElements = timePart.split(':');
                            Integer hour = Integer.valueOf(timeElements[0]);
                            Integer minute = Integer.valueOf(timeElements[1].substring(0, 2));
                            String meridian = timeElements[1].substring(3, 5);
    
                            // Convert 12-hour format to 24-hour format
                            if (meridian == 'pm' && hour != 12) {
                                hour += 12;
                            } else if (meridian == 'am' && hour == 12) {
                                hour = 0;
                            }
    
                            // Create the Datetime instance
                            Datetime dt = Datetime.newInstance(year, month, day, hour, minute, 0);
                            dateTimeToRemarksMap.put(dt,iterRem);
                        }
                        combinedRemarks += fiRec[0].Admin_s_Remarks__c + '\n';
                    }
                    if (String.isNotBlank(fiRec[0].Any_Remarks_Reasons__c)) {
                        System.debug('Any_Remarks_Reasons__c 1: ' + fiRec[0].Any_Remarks_Reasons__c);
                        List<String> remarksList = fiRec[0].Any_Remarks_Reasons__c.split(',\n');
                        for(String iterRem : remarksList){
                            String dateTimeString = iterRem.split('- ')[1];

                            // First, split the date and time parts
                            List<String> parts = dateTimeString.split(', ');
                            String datePart = parts[0]; // "17/02/2025"
                            String timePart = parts[1]; // "11:39 am"
    
                            // Parse the date part
                            List<String> dateElements = datePart.split('/');
                            Integer day = Integer.valueOf(dateElements[0]);
                            Integer month = Integer.valueOf(dateElements[1]);
                            Integer year = Integer.valueOf(dateElements[2]);
    
                            // Parse the time part
                            timePart = timePart.toLowerCase();
                            List<String> timeElements = timePart.split(':');
                            Integer hour = Integer.valueOf(timeElements[0]);
                            Integer minute = Integer.valueOf(timeElements[1].substring(0, 2));
                            String meridian = timeElements[1].substring(3, 5);
    
                            // Convert 12-hour format to 24-hour format
                            if (meridian == 'pm' && hour != 12) {
                                hour += 12;
                            } else if (meridian == 'am' && hour == 12) {
                                hour = 0;
                            }
    
                            // Create the Datetime instance
                            Datetime dt = Datetime.newInstance(year, month, day, hour, minute, 0);
                            dateTimeToRemarksMap.put(dt,iterRem);
                        }
                        
                        combinedRemarks += fiRec[0].Any_Remarks_Reasons__c + '\n';
                        System.debug('combinedRemarks: ' + combinedRemarks);
                    }
                    if (String.isNotBlank(fiRec[0].Waiver_Remark__c)) {
                        
                        List<String> remarksList = fiRec[0].Waiver_Remark__c.split(',\n');
                        for(String iterRem : remarksList){
                            String dateTimeString = iterRem.split('- ')[1];

                            // First, split the date and time parts
                            List<String> parts = dateTimeString.split(', ');
                            String datePart = parts[0]; // "17/02/2025"
                            String timePart = parts[1]; // "11:39 am"
    
                            // Parse the date part
                            List<String> dateElements = datePart.split('/');
                            Integer day = Integer.valueOf(dateElements[0]);
                            Integer month = Integer.valueOf(dateElements[1]);
                            Integer year = Integer.valueOf(dateElements[2]);
    
                            // Parse the time part
                            timePart = timePart.toLowerCase();
                            List<String> timeElements = timePart.split(':');
                            Integer hour = Integer.valueOf(timeElements[0]);
                            Integer minute = Integer.valueOf(timeElements[1].substring(0, 2));
                            String meridian = timeElements[1].substring(3, 5);
    
                            // Convert 12-hour format to 24-hour format
                            if (meridian == 'pm' && hour != 12) {
                                hour += 12;
                            } else if (meridian == 'am' && hour == 12) {
                                hour = 0;
                            }
    
                            // Create the Datetime instance
                            Datetime dt = Datetime.newInstance(year, month, day, hour, minute, 0);
                            dateTimeToRemarksMap.put(dt,iterRem);
                        }
                        combinedRemarks += fiRec[0].Waiver_Remark__c + '\n';
                    }
                    if(dateTimeToRemarksMap.size()>0){
                        DateTime dt = System.now();
                        for(DateTime d : dateTimeToRemarksMap.keySet()){
                            if(d<dt){
                                finalRemarks=dateTimeToRemarksMap.get(d)+ '\n'+finalRemarks + '\n';
                                dt=d;
                            }
                            else{
                                finalRemarks=finalRemarks+dateTimeToRemarksMap.get(d)+ '\n';
                            }
                        }
                    }
                    System.debug('combinedRemarks: 2' + combinedRemarks);
                    System.debug('finalRemarks: '+finalRemarks);
                    result.remarks = finalRemarks;
                    //result.remarks = combinedRemarks; // Trim any trailing newlines or spaces
                    System.debug('result.remarks: ' + result.remarks);
                    result.allowCreation = false;
                }
            }
            
            /*when 'FI Remarks' {
                List<Application_Verification__c> fiRec = [SELECT Id, Credit_Manager_s_Remarks__c, Waiver_Remark__c, Admin_s_Remarks__c, Any_Remarks_Reasons__c 
                                                        FROM Application_Verification__c WHERE Id =: recordId];

                if(!fiRec.isEmpty()){

                    if(string.isNotBlank(fiRec[0].Credit_Manager_s_Remarks__c)) {
                        result.remarks = fiRec[0].Credit_Manager_s_Remarks__c;
                    }
                    if(string.isNotBlank(fiRec[0].Admin_s_Remarks__c)) {
                        result.remarks =fiRec[0].Admin_s_Remarks__c;
                    }
                    if(string.isNotBlank(fiRec[0].Any_Remarks_Reasons__c)){
                        result.remarks = fiRec[0].Any_Remarks_Reasons__c;
                    }
                    if(string.isNotBlank(fiRec[0].Waiver_Remark__c)){
                        result.remarks = fiRec[0].Waiver_Remark__c;
                    }

                    result.allowCreation = false;
                }
            }*/
        }
        system.debug('result: '+result);

        return result;
    }

    //updating the remarks according to processname
    @AuraEnabled
    public static string updateRemark(String recordId, String remark, string processName) {
        
        string result = '';

        switch on processName {

            when 'Lead Remarks' {
                List<Lead> leadList = [SELECT Id, Remarks_History__c FROM Lead WHERE Id =: recordId];

                if(!leadList.isEmpty()) {
                    leadList[0].Remarks_History__c = utility.getFormattedRemarks(remark, leadList[0].Remarks_History__c);
        
                    LeadTriggerHandler.isTriggerDisabled = true;
                    update leadList;
                    LeadTriggerHandler.isTriggerDisabled = false;
                }
            }
        }        

        return result;
    }

    public class RemarksWrapper {
        @AuraEnabled public string remarks;
        @AuraEnabled public boolean allowCreation;
    }
}