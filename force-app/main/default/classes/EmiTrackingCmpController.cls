public class EmiTrackingCmpController {

    @AuraEnabled(cacheable=true)
    public static List<Bank_Details__c> getEligibleBankIds(String recordId) {
        System.debug('record id in getEligible Bank Ids =>'+recordId);
        List<Application_Applicant__c> lstOfApplicant = [Select id from Application_Applicant__c where Loan_Application__c =: recordId];
        Set<Id> setOfApplicant = new Set<Id>();
        for(Application_Applicant__c objApplicant : lstOfApplicant){
            setOfApplicant.add(objApplicant.Id);
        }
        List<Bank_Details__c> lstBnks = [SELECT id,Name,Account_Number__c,Account_Holder_Name__c FROM Bank_Details__c WHERE Application_Applicant__r.Id IN :setOfApplicant ];
        return lstBnks;
    }

    /*@AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTransposedData() {
        
        // Fetch records from Salesforce
        List<Bank_Statement_Analysis__c> records = [
            SELECT Category__c, Amount__c, Emi_Date__c 
            FROM Bank_Statement_Analysis__c 
            WHERE Bank_Details__c ='a0hBi000000bFePIAU' 
            AND Emi_Date__c != null 
            ORDER BY Amount__c, Emi_Date__c
        ];

        // Map to store transformed data
        Map<String, Map<String, List<String>>> dataMap = new Map<String, Map<String, List<String>>>();
        Map<String, Map<String, String>> metaMap = new Map<String, Map<String, String>>();
        Set<Date> allDates = new Set<Date>();

        for (Bank_Statement_Analysis__c rec : records) {
            String key = rec.Amount__c + '-' + rec.Category__c;

            // Extract date components
            Date emiDate = rec.Emi_Date__c;
            String monthYear = getMonthName(emiDate.month()) + '-' + emiDate.year(); // Format as "MMM-YYYY"
            String day = String.valueOf(emiDate.day());

            allDates.add(emiDate); // Store the actual date for sorting

            // Initialize meta info (Amount & Category)
            if (!metaMap.containsKey(key)) {
                metaMap.put(key, new Map<String, String>{
                    'Amount' => String.valueOf(rec.Amount__c),
                    'Category' => rec.Category__c
                });
            }

            // Initialize data map for dates
            if (!dataMap.containsKey(key)) {
                dataMap.put(key, new Map<String, List<String>>());
            }
            Map<String, List<String>> dateMap = dataMap.get(key);

            if (!dateMap.containsKey(monthYear)) {
                dateMap.put(monthYear, new List<String>());
            }
            dateMap.get(monthYear).add(day);
        }

        // Sort the dates chronologically
        List<Date> sortedDates = new List<Date>(allDates);
        sortedDates.sort();

        // Convert map to list format for LWC
        List<Map<String, String>> resultList = new List<Map<String, String>>();
        for (String key : dataMap.keySet()) {
            Map<String, String> row = new Map<String, String>();

            // Add meta info (Amount & Category)
            row.put('Amount', metaMap.get(key).get('Amount'));
            row.put('Category', metaMap.get(key).get('Category'));

            // Add date values
            for (Date dates : sortedDates) {
                String monthYear = getMonthName(dates.month()) + '-' + dates.year(); // Format as "MMM-YYYY"
                List<String> daysList = dataMap.get(key).get(monthYear);
                String daysString = (daysList != null) ? String.join(daysList, ',') : '';
                row.put(monthYear, daysString);
            }

            resultList.add(row);
        }

        System.debug('resultList => ' + resultList);
        return resultList;
    }*/


    @AuraEnabled
    public static List<Map<String, String>> getFilteredTransposedData(Id bankRecordId) {
        
        // Fetch records from Salesforce
        List<Bank_Statement_Analysis__c> records = [
            SELECT Category__c, Amount__c, Emi_Date__c 
            FROM Bank_Statement_Analysis__c 
            WHERE Bank_Details__c =:bankRecordId //'a0hBi000000bFePIAU' 
            AND Emi_Date__c != null 
            ORDER BY Amount__c, Emi_Date__c
        ];

        // Map to store transformed data
        Map<String, Map<String, List<String>>> dataMap = new Map<String, Map<String, List<String>>>();
        Map<String, Map<String, String>> metaMap = new Map<String, Map<String, String>>();
        Set<Date> allDates = new Set<Date>();

        for (Bank_Statement_Analysis__c rec : records) {
            String key = rec.Amount__c + '-' + rec.Category__c;

            // Extract date components
            Date emiDate = rec.Emi_Date__c;
            String monthYear = getMonthName(emiDate.month()) + '-' + emiDate.year(); // Format as "MMM-YYYY"
            String day = String.valueOf(emiDate.day());

            allDates.add(emiDate); // Store the actual date for sorting

            // Initialize meta info (Amount & Category)
            if (!metaMap.containsKey(key)) {
                metaMap.put(key, new Map<String, String>{
                    'Amount' => String.valueOf(rec.Amount__c),
                    'Category' => rec.Category__c
                });
            }

            // Initialize data map for dates
            if (!dataMap.containsKey(key)) {
                dataMap.put(key, new Map<String, List<String>>());
            }
            Map<String, List<String>> dateMap = dataMap.get(key);

            if (!dateMap.containsKey(monthYear)) {
                dateMap.put(monthYear, new List<String>());
            }
            dateMap.get(monthYear).add(day);
        }

        // Sort the dates chronologically
        List<Date> sortedDates = new List<Date>(allDates);
        sortedDates.sort();

        // Convert map to list format for LWC
        List<Map<String, String>> resultList = new List<Map<String, String>>();
        for (String key : dataMap.keySet()) {
            Map<String, String> row = new Map<String, String>();

            // Add meta info (Amount & Category)
            row.put('Amount', metaMap.get(key).get('Amount'));
            row.put('Category', metaMap.get(key).get('Category'));

            // Add date values
            for (Date dates : sortedDates) {
                String monthYear = getMonthName(dates.month()) + '-' + dates.year(); // Format as "MMM-YYYY"
                List<String> daysList = dataMap.get(key).get(monthYear);
                String daysString = (daysList != null) ? String.join(daysList, ',') : '';
                row.put(monthYear, daysString);
            }

            resultList.add(row);
        }

        System.debug('resultList => ' + resultList);
        return resultList;
    }

    // Helper method to get month name from month number
    public static String getMonthName(Integer month) {
        switch on month {
            when 1 { return 'Jan'; }
            when 2 { return 'Feb'; }
            when 3 { return 'Mar'; }
            when 4 { return 'Apr'; }
            when 5 { return 'May'; }
            when 6 { return 'Jun'; }
            when 7 { return 'Jul'; }
            when 8 { return 'Aug'; }
            when 9 { return 'Sep'; }
            when 10 { return 'Oct'; }
            when 11 { return 'Nov'; }
            when 12 { return 'Dec'; }
            when else { return ''; } // Default case
        }
    }
}