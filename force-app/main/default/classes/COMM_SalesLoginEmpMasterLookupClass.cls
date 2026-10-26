public without sharing class COMM_SalesLoginEmpMasterLookupClass {

    @AuraEnabled
    public static List<recordWrapper> getSearchRecords(
        String objectName,
        String searchText,
        String filterCriteria,
        List<String> searchFields,
        List<String> returnFields,
        String sortColumn,
        String sortOrder,
        Integer maxResults
    ) {
        if (maxResults == null || maxResults <= 0) maxResults = 50;
        if (String.isBlank(searchText)) return new List<recordWrapper>();

        // Default fields if none provided
        if (returnFields == null || returnFields.isEmpty()) {
            returnFields = new List<String>{ 'Id', 'Name' };
        }
        String fieldList = String.join(returnFields, ',');

        // Build SOSL query (note: SOSL doesn’t support ORDER BY)
        String soslQuery = 'FIND \'' + String.escapeSingleQuotes(searchText) + '*\' IN ALL FIELDS RETURNING ' +
                           objectName + '(' + fieldList + ' LIMIT ' + maxResults + ')';
        System.debug('soslQuery==>'+soslQuery);
        List<List<SObject>> searchLists = Search.query(soslQuery);
        System.debug('searchLists-->'+searchLists);
        List<SObject> matchedRecords = (searchLists != null && !searchLists.isEmpty()) ? searchLists[0] : new List<SObject>();

        // Filter (post-SOSL)
        List<SObject> filteredList = new List<SObject>();
        if (!String.isBlank(filterCriteria)) {
            List<String> criteriaList = filterCriteria.removeStart('[').removeEnd(']').split(';');
            for (SObject rec : matchedRecords) {
                Boolean match = true;
                for (String criteria : criteriaList) {
                    if (String.isBlank(criteria)) continue;
                    List<String> keyVal = criteria.split('=');
                    if (keyVal.size() < 2) continue;
                    String field = keyVal[0].trim();
                    List<String> expectedValues = keyVal[1].trim().split(',');
                    Object actualValue = rec.get(field);
                    if (actualValue == null || !expectedValues.contains(String.valueOf(actualValue))) {
                        match = false; break;
                    }
                }
                if (match) filteredList.add(rec);
            }
        } else {
            filteredList = matchedRecords;
        }

        // Manual sorting (if requested) – string sort
        if (!String.isBlank(sortColumn) && !String.isBlank(sortOrder)) {
            filteredList.sort(new SObjectComparator(sortColumn, sortOrder));
        }

        // Build result
        List<recordWrapper> result = new List<recordWrapper>();
        getRecords(objectName, returnFields, filteredList, result);
        return result;
    }

    @AuraEnabled
    public static List<recordWrapper> getRecentRecords(String objectName, String filterCriteria, List<String> returnFields, Integer maxResults) {
        if (maxResults == null || maxResults == 0) maxResults = 5;
        if (returnFields == null || returnFields.isEmpty()) {
            returnFields = new List<String>{ 'Id', 'Name' };
        }

        String recentQuery = 'SELECT Id FROM RecentlyViewed WHERE Type =: objectName ORDER BY LastViewedDate DESC LIMIT ' + maxResults;
        List<Id> recentIds = new List<Id>();
        for (RecentlyViewed rv : Database.query(recentQuery)) recentIds.add(rv.Id);
        if (recentIds.isEmpty()) return new List<recordWrapper>();

        String sQuery = 'SELECT ' + String.join(returnFields, ', ') + ' FROM ' + objectName + ' WHERE Id IN :recentIds';

        if (!String.isBlank(filterCriteria)) {
            List<String> criteriaList = filterCriteria.removeStart('[').removeEnd(']').split(';');
            for (String criteria : criteriaList) {
                if (String.isBlank(criteria)) continue;
                List<String> keyVal = criteria.split('=');
                if (keyVal.size() < 2) continue;
                String field = keyVal[0].trim();
                List<String> values = keyVal[1].trim().split(',');
                String inClause = '(' + String.join(values, ',') + ')';
                sQuery += ' AND ' + field + ' IN ' + inClause;
            }
        }

        List<recordWrapper> result = new List<recordWrapper>();
        getRecords(objectName, returnFields, Database.query(sQuery), result);
        return result;
    }

    private static void getRecords(String objectName, List<String> returnFields, List<SObject> recList, List<recordWrapper> result) {
        if (recList.isEmpty()) return;

        for (SObject itr : recList) {
            recordWrapper rw = new recordWrapper();

            // id / primary / secondary keep your UI happy
            rw.id = safeGetFieldValue(returnFields, itr, 0); // often 'Id'
            rw.primaryValue = (returnFields.size() > 1) ? safeGetFieldValue(returnFields, itr, 1) : '';
            rw.secondaryValue = (returnFields.size() > 2) ? safeGetFieldValue(returnFields, itr, 2) : '';

            // NEW: a full map of every requested field -> value
            rw.fields = new Map<String, String>();
            for (Integer i = 0; i < returnFields.size(); i++) {
                String api = returnFields[i];
                rw.fields.put(api, safeGetFieldValue(returnFields, itr, i));
            }

            List<String> iconCss = getIconAndCssClass(objectName, itr);
            rw.cssClass = iconCss[0];
            rw.iconName = iconCss[1];

            // Keep the raw SObject as before (useful if you already rely on it)
            rw.searchRecord = itr;

            result.add(rw);
        }
    }

    @TestVisible
    private static String safeGetFieldValue(List<String> returnFields, SObject itr, Integer position) {
        if (position >= returnFields.size()) return '';
        String fieldPath = returnFields[position];
        // Guard: don’t support functions like toLabel() here
        if (fieldPath.contains('(')) return ''; // avoid dynamic expressions

        List<String> relList = fieldPath.split('\\.');
        SObject current = itr;
        for (Integer i = 0; i < relList.size(); i++) {
            String token = relList[i];
            if (i == relList.size() - 1) {
                return String.valueOf(current.get(token));
            } else {
                SObject nextHop = current.getSObject(token);
                if (nextHop == null) return '';
                current = nextHop;
            }
        }
        return '';
    }

    @TestVisible
    private static List<String> getIconAndCssClass(String objectName, SObject record) {
        List<String> result = new List<String>();
        switch on objectName {
            when 'Pincode_Master__c' {
                String css = Boolean.valueOf(record.get('Serviceable_For_Business_Loan__c')) ? 'css-green' : 'css-gray';
                result.add(css); result.add('standard:address');
            }
            when 'Account' { result.add('css-gray'); result.add('custom:custom24'); }
            when 'AccountTeamMember' { result.add('css-gray'); result.add('standard:people'); }
            when 'Bank_Branch_Master__c' { result.add('css-gray'); result.add('custom:custom16'); }
            when 'Document_Master__c' { result.add('css-gray'); result.add('standard:document'); }
            when 'User' { result.add('css-gray'); result.add('standard:user'); }
            when 'Employer_Master__c' { result.add('css-green'); result.add('standard:company'); }
            when else { result.add('css-gray'); result.add('standard:info'); }
        }
        return result;
    }

    public class recordWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String primaryValue;
        @AuraEnabled public String secondaryValue;
        @AuraEnabled public String iconName;
        @AuraEnabled public String cssClass;
        @AuraEnabled public SObject searchRecord;
        // NEW: all fields you requested, keyed by API name / path
        @AuraEnabled public Map<String, String> fields;
    }

    public class SObjectComparator implements System.Comparator<SObject> {
        String fieldName; String direction;
        public SObjectComparator(String fieldName, String direction) { this.fieldName = fieldName; this.direction = direction; }
        public Integer compare(SObject a, SObject b) {
            String strA = String.valueOf(a.get(fieldName)); if (strA == null) strA = '';
            String strB = String.valueOf(b.get(fieldName)); if (strB == null) strB = '';
            Integer result = strA.toLowerCase().compareTo(strB.toLowerCase());
            return (direction != null && direction.toLowerCase() == 'desc') ? -result : result;
        }
    }
}