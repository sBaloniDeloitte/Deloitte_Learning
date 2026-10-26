/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-17-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class SearchLookupController {

    static String conLabels = 'Sub_Branch_Type';

    public static Map <String,String> constants = Utility.getConstants(conLabels);

    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
    //search records on the basis of names and recordId
    @AuraEnabled
    public static List<RecordWrapper> getSearchRecords(String objectName, String searchText, String filterCriteria, List<String> searchFields, List<String> returnFields, String sortColumn, String sortOrder, Integer maxResults) {
        
        Map<String, Object> bindVars = new Map<String, Object>();
        bindVars.put('searchText', '%' + (searchText == null ? '' : searchText) + '%');
        bindVars.put('lookupId', searchText);
        
        String sQuery = 'SELECT ';
        
        if(returnFields != null && !returnFields.isEmpty()) {
            sQuery += String.join(returnFields, ', ');
        }else {
            sQuery += 'Id, Name';
        }
        
        sQuery += ' FROM ' + objectName + ' WHERE ';
        Boolean hasAnyCriteria = false;
        if(String.isNotBlank(filterCriteria)) {
            List<String> criteriaList = filterCriteria.removeStart('[').removeEnd(']').split(';');
    
        for (String criteria : criteriaList) {
                if (String.isBlank(criteria)) continue;
                criteria = criteria.trim();
    
            String operator;
            if (criteria.contains('!=')) {
                operator = '!=';
                } else if (criteria.contains(' INCLUDES ')) { // require spaces for safety
                    operator = 'INCLUDES';
            } else if (criteria.contains('=')) {
                operator = '=';
                } else {
                    continue; // unsupported
            }

                List<String> parts;
                if (operator == 'INCLUDES') {
                    parts = criteria.split('\\s+INCLUDES\\s+');
           }else{
                    parts = criteria.split('\\s*' + Pattern.quote(operator) + '\\s*');
                }
                if (parts.size() < 2) continue;
            String fieldName = parts[0].trim();
                String rawVal    = parts[1].trim();
            String bindKey = fieldName.replace('.', '_');
                if (operator == 'INCLUDES') {
                    sQuery += fieldName + ' INCLUDES ' + rawVal + ' AND ';
                    hasAnyCriteria = true;
                    continue;
                }
                Object typedVal = coerceValue(rawVal);
                if(typedVal == null){
                    sQuery += fieldName + ' ' + operator + ' null AND ';
            }else{
                    bindVars.put(bindKey, typedVal);
            sQuery += fieldName + ' ' + operator + ' :' + bindKey + ' AND ';
            }
                hasAnyCriteria = true;
            }
        }
        if (hasAnyCriteria && sQuery.endsWith(' AND ')) {
            sQuery = sQuery.substring(0, sQuery.length() - 5);
            sQuery += ' AND ';
        }
        if(searchFields == null || searchFields.isEmpty()) {
            sQuery += ' (Name LIKE :searchText OR Id = :lookupId) ';
        }else {
            String likeField = '';
            for (String field : searchFields) {
                likeField += ' OR ' + field + ' LIKE :searchText ';
            }
            sQuery += ' (' + likeField.removeStart(' OR ') + ') ';
        }

        if (String.isNotBlank(sortColumn) && String.isNotBlank(sortOrder)) {
            sQuery += ' ORDER BY ' + sortColumn + ' ' + sortOrder;
        }
        sQuery += ' LIMIT ' + maxResults;
        System.debug('sQuery: '+sQuery);
        SObject[] rows = Database.queryWithBinds(sQuery, bindVars, AccessLevel.USER_MODE);

        List<RecordWrapper> result = new List<RecordWrapper>();
        getRecords(objectName, returnFields, rows, result);
        return result;
    }
    private static Object coerceValue(String raw) {
        if (raw == null) return null;

        String val = raw.trim();

        // Strip surrounding single quotes: 'ABC' -> ABC
        if (val.startsWith('\'') && val.endsWith('\'') && val.length() >= 2) {
            val = val.substring(1, val.length() - 1);
        }

        // Boolean
        if (val.equalsIgnoreCase('true') || val.equalsIgnoreCase('false')) {
            return Boolean.valueOf(val);
        }

        // Null
        if (val.equalsIgnoreCase('null')) {
            return null;
        }
        // Integer / Long
        if (Pattern.compile('^-?\\d+$').matcher(val).matches()) {
            try {
                return Integer.valueOf(val);
            } catch (Exception e) {
                return Long.valueOf(val);
            }
        }

        // Decimal
        if (Pattern.compile('^-?\\d+\\.\\d+$').matcher(val).matches()) {
            return Decimal.valueOf(val);
        }
        // Date or Datetime (simple ISO-like formats)
        if (Pattern.compile('^\\d{4}-\\d{2}-\\d{2}(?:[ T].*)?$').matcher(val).matches()) {
            try {
                if (val.contains('T') || val.contains(' ')) {
                    // e.g., '2025-03-31 10:20:30'
                    return Datetime.valueOf(val);
                } else {
                    return Date.valueOf(val);
                }
            } catch (Exception ignore) {
                // Fall through to string if parsing fails
            }
        }
        return val;
    }

    //getting recent records searched or selected before by the user
    @AuraEnabled
    public static List<RecordWrapper> getRecentRecords(String objectName, string filterCriteria, List<String> returnFields, Integer maxResults) {
        
        //if(maxResults == null || maxResults == 0) { maxResults = 5; }

        string recentQuery = 'SELECT Id FROM RecentlyViewed WHERE Type =: objectName ORDER BY LastViewedDate DESC LIMIT '+ maxResults;
        //System.debug('recentQuery: '+recentQuery);

        List<Id> recentIds = new List<Id>();

        for(RecentlyViewed recent : Database.query(recentQuery)) {
            recentIds.add(recent.Id);
        }
        //System.debug('recentIds: '+recentIds);

        Map<string, Object> bindVars = new Map<string, Object>();
        bindVars.put('recentIds', recentIds);

        string sQUERY = 'SELECT ';

        if(returnFields != null && !returnFields.isEmpty()) {
            sQuery += String.join(returnFields, ', ');
        }else {
            sQuery += 'Id, Name';
        }

        sQuery += ' FROM ' + objectName + ' WHERE Id IN : recentIds ';

        if(string.isNotBlank(filterCriteria)) {
            //System.debug('filterCriteria: '+filterCriteria);
            List<string> criteriaList = filterCriteria.removeStart('[').removeEnd(']').split(';');
           
            for(string criteria : criteriaList) {
				system.debug('criteria: '+criteria);
				
				if(criteria.contains('!=')){
					List<string> criteriaValList = criteria.split('!=');
                    string bindKey = criteriaValList[0].trim().replace('!', '_');
					system.debug(bindKey +' value: '+criteriaValList[1].trim().split(','));
					
                    bindVars.put(bindKey, criteriaValList[1].trim().split(','));
                    sQuery += ' And '+ criteriaValList[0].trim() + ' !=: '+ bindKey;
				}
                else if(!criteria.contains(' INCLUDES ')){
                List<string> criteriaValList = criteria.split('=');
                string bindKey = criteriaValList[0].trim().replace('.', '_');

                bindVars.put(bindKey, criteriaValList[1].trim().split(','));
                sQuery += ' And '+ criteriaValList[0].trim() + ' =: '+ bindKey;
            }
                else{
                    List<string> criteriaValList = criteria.split(' INCLUDES ');
                    string bindKey = criteriaValList[0].trim().replace('.', '_');
					system.debug(bindKey +' value: '+criteriaValList[1].trim());
					
                    bindVars.put(bindKey, criteriaValList[1].trim());
                    sQuery += ' And '+ criteriaValList[0].trim() + ' INCLUDES (:'+ bindKey +')';
                }
            }
        }
        System.debug('sQuery: '+sQuery);
        
        List<RecordWrapper> result = new List<RecordWrapper>();

        getRecords(objectName, returnFields, Database.queryWithBinds(sQuery, bindVars, AccessLevel.USER_MODE), result);

        return result;
    }

    //getting record on serch with the name of the record
    private static void getRecords(string objectName, List<String> returnFields, List<sObject> recList, List<RecordWrapper> result) {
        //System.debug('recList: '+recList);
        List<sObject> recListTemp = new List<sObject>();
        Set<String> options = new Set<String>();
        if(returnFields.contains('Deviation_Category__c') && objectName == 'Deviation_Mitigant_Master__c' && !recList.isEmpty()) {
            for(sObject iterObj : recList) {
                String val = string.valueOf(iterObj.get('Deviation_Category__c'));
                if(!options.contains(val)) {
                    options.add(val);
                    recListTemp.add(iterObj);
                }
                
            }
            recList = recListTemp;
        }

        if(!recList.isEmpty()) {
            if(!returnFields.isEmpty()) {

                for(sObject itr : recList){
                    RecordWrapper rw = new RecordWrapper();
                    rw.id = getFieldValue(returnFields, itr, 0);
                    rw.primaryValue = getFieldValue(returnFields, itr, 1);
                    
                    if(returnFields.size() >2){
                        rw.secondaryValue = getFieldValue(returnFields, itr, 2);
                    }
                    
                    List<string> iconCss = getIconAndCssClass(objectName, itr);
                    rw.cssClass = iconCss[0];
                    rw.iconName = iconCss[1];
                    rw.searchRecord = itr;
        
                    result.add(rw);
                }
            }
            else{
    
                for(sObject itr : recList){
                    RecordWrapper rw = new RecordWrapper();
                    rw.id = itr.Id;
                    rw.primaryValue = string.valueOf(itr.get('Name'));
                    rw.secondaryValue = '';
    
                    List<string> iconCss = getIconAndCssClass(objectName, itr);
                    rw.cssClass = iconCss[0];
                    rw.iconName = iconCss[1];
                    rw.searchRecord = itr;
        
                    result.add(rw);
                }
            }
        }
    }

    //getting values of the search typed
    @TestVisible
    private static string getFieldValue(List<string> returnFields, sObject itr, Integer position) {
        string fieldValue = '';
        List<string> relList = returnFields[position].split('\\.');
        Integer relSize = relList.size();

        switch on relSize {
            when 1 {
                fieldValue = string.valueOf(itr.get(relList[0]));
            }
            when 2 {
                fieldValue = string.valueOf(itr.getSobject(relList[0]).get(relList[1]));
            }
            when 3 {
                fieldValue = string.valueOf(itr.getSobject(relList[0]).getSobject(relList[1]).get(relList[2]));
            }
        }

        //System.debug('fieldValue: '+fieldValue);
        return fieldValue;
    }

    //get icons and css of the searched item according to the object searched
    @TestVisible
    private static List<string> getIconAndCssClass(string objectName, sObject record) {

        List<string> result = new List<string>();
        
        switch on objectName {

            when 'Pincode_Master__c' {
                string css = Boolean.valueOf(record.get('Is_Pincode_Servicable__c')) ? 'css-green' : 'css-gray';
                result.add(css);
                result.add('standard:address');
            }
            when 'Account' {
                result.add('css-gray');
                result.add('custom:custom24');
            }
            when 'AccountTeamMember' {
                result.add('css-gray');
                result.add('standard:people');
            }
            when 'Bank_Branch_Master__c' {
                result.add('css-gray');
                result.add('custom:custom16');
            }
            when 'Document_Master__c' {
                result.add('css-gray');
                result.add('standard:document');
            }
            when 'User' {
                result.add('css-gray');
                result.add('standard:user');
            }
            when else {
                result.add('css-gray');
                result.add('standard:info');
            }
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<RecordWrapper> searchSalesUsersForBranch(Id loanId, String searchText, Integer maxResults, Id branchId) {
        List<RecordWrapper> out = new List<RecordWrapper>();
        if (loanId == null) return out;
        if (maxResults == null || maxResults <= 0) maxResults = 50;

        Id branchToUse = branchId;
        if (branchToUse == null && loanId != null) {
        Opportunity opp = [
            SELECT Branch_Master__c
            FROM Opportunity
            WHERE Id = :loanId
            LIMIT 1
        ];
        branchToUse = opp.Branch_Master__c;
        }
        if (branchToUse == null) return out;
        List<AccountTeamMember> atms = [
            SELECT UserId
            FROM AccountTeamMember
            WHERE AccountId = :branchToUse
              AND TeamMemberRole = 'Sales'
        ];
        Set<Id> userIds = new Set<Id>();
        for (AccountTeamMember atm : atms) {
            if (atm.UserId != null) userIds.add(atm.UserId);
        }
        if (userIds.isEmpty()) return out;
        String likeTxt = '%' + (searchText == null ? '' : searchText) + '%';
        String domainIncl = '%godrejcapital.com%';
        Set<Id> allowed = new Set<Id>();
        for (User u : [SELECT Id FROM User WHERE Id IN :userIds AND Username LIKE : domainIncl]) {
            allowed.add(u.Id);
        }
        if (allowed.isEmpty()) return out;
        List<User> users = [SELECT Id, Name, Email, Username FROM User WHERE Id IN :allowed AND (Name LIKE :likeTxt OR Email LIKE :likeTxt OR Username LIKE :likeTxt) ORDER BY Name LIMIT :maxResults];
        for (User u : users) {
            RecordWrapper rw = new RecordWrapper();
            rw.id = String.valueOf(u.Id);
            rw.primaryValue = u.Name;
            rw.secondaryValue = u.Email;
            rw.cssClass= '';
            rw.iconName = '';
            rw.searchRecord = u;
            out.add(rw);
        }
        return out;
    }

    public class RecordWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String primaryValue;
        @AuraEnabled public String secondaryValue;
        @AuraEnabled public String iconName;
        @AuraEnabled public String cssClass;
        @AuraEnabled public sObject searchRecord;
    }
     @AuraEnabled
    public static void updateIFSCCode(String bankId, String ifscCode,String branchId) {
        List<Bank_Details__c> bankDets = [SELECT Id, IFSC__c,Bank_Master__c FROM Bank_Details__c WHERE Id =: bankId LIMIT 1];
        bankDets[0].IFSC__c = String.isNotBlank(ifscCode) ? ifscCode : ''; //Sanwar-31/12/25 > Arman 19th January > Sanwar commented this > this should update if the record is there
        bankDets[0].Bank_Master__c = branchId;
        update bankDets;
    }

    @AuraEnabled
    public static string fetchIFSCCode(String bankId) {
        List<Bank_Details__c> bankDets = [SELECT Id, IFSC__c,Bank_Master__c, Bank_Master__r.IFSC__c FROM Bank_Details__c WHERE Id =: bankId LIMIT 1]; //Sanwar-31/12/25
        if (bankDets[0].Bank_Master__c != null && bankDets[0].Bank_Master__r.IFSC__c != null) { //Sanwar-31/12/25
            return bankDets[0].Bank_Master__r.IFSC__c;
        } else {
            return 'Not Found';
        }
        
    }
    @AuraEnabled(cacheable=true)
    public static List<Bank_Branch_Master__c> searchBankBranches(String searchTerm) {
        return [
            SELECT Id, IFSC__c,MICR__c
            FROM Bank_Branch_Master__c
            WHERE RecordType.Name = 'Branch'
            AND Bank__r.Institution_Id__c != null
            AND IFSC__c LIKE :('%' + searchTerm + '%')
            LIMIT 10
        ];
    }
}