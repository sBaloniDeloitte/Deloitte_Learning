/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-11-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class HL_directorRenumaration {
    @AuraEnabled
    public static Boolean checkCustomerType(String recordId){
        List<Application_Applicant__c> aac = [Select Id,Customer_Type__c from Application_Applicant__c where Loan_Application__C=:recordId and Applicant_Type__c='Primary Applicant' and Customer_Type__c='Non Individual'];
        if(!aac.isEmpty()){
            return true;
        }
        else{
            return false;
        }
    }

@AuraEnabled
public static List<Map<String, Object>> getEligibilityAmount(String recordId) {
    List<Map<String, Object>> resultList = new List<Map<String, Object>>();
 List<Income_Assessment__c> applicants = [Select Id,Applicant__c,Applicant__r.Applicant_Name__c,Applicant__r.AmountConsideredForEligibilityPurpos__c,ParentorChild__c,Loan_Application__c from Income_Assessment__c where ParentorChild__c = 'Parent' and Type_of_Income_Assesment__c = 'Director Renumeration' and Loan_Application__c=:recordId]; 
 for (Income_Assessment__c app : applicants) {
        resultList.add(new Map<String, Object>{
            'Id' => app.Applicant__c,
            'Name' => app.Applicant__r.Applicant_Name__c,
            'AmountConsideredForEligibilityPurpos' => app.Applicant__r.AmountConsideredForEligibilityPurpos__c
        });
    }

    return resultList;
}


    @AuraEnabled
    public static List<String> fetchDirectors(String recordId){
        List<String> mapOfDirectors = new  List<String>();
        List<Income_Assessment__c> aac = [
            SELECT Id, Applicant__c,Applicant__r.Applicant_Name__c
            FROM Income_Assessment__c
            WHERE Loan_Application__C =:recordId
            AND Type_of_Income_Assesment__c = 'Director Renumeration' and ParentorChild__c = 'Parent'
        ];
            if(!aac.isEmpty()){
            for(Income_Assessment__c a : aac){
               mapOfDirectors.add(a.Applicant__r.Applicant_Name__c);
            }
        }
        return mapOfDirectors;
    }
@AuraEnabled
public static Boolean createorCheckAlreadyCreated(String recordId){
    // Fetch all non-primary individual applicants related to the Loan Application
    Id recTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Director_Renumeration').getRecordTypeId();
    List<Application_Applicant__c> aac = [
        Select Id, Applicant_Name__c, Customer_Type__c
        from Application_Applicant__c
        where Loan_Application__C = :recordId 
        and Applicant_Type__c != 'Primary Applicant'
        and Customer_Type__c = 'Individual'
    ];

    if(!aac.isEmpty()) {
        // Collect all applicant IDs
        Set<Id> applicantIds = new Set<Id>();
        for(Application_Applicant__c a : aac){
            applicantIds.add(a.Id);
        }
        
        // Query existing Income_Assessment__c records related to those applicants
        List<Income_Assessment__c> ias = [
            Select Id, Applicant__c 
            from Income_Assessment__c 
            where Applicant__c IN :applicantIds and Type_of_Income_Assesment__c = 'Director Renumeration'
        ];
        
        // Create a set of Applicant IDs that already have Income Assessment records
        Set<Id> applicantsWithIncomeAssessment = new Set<Id>();
        for(Income_Assessment__c ia : ias){
            applicantsWithIncomeAssessment.add(ia.Applicant__c);
        }
        
        // Find applicants without Income Assessment records
        List<Income_Assessment__c> incomeAssessmentsToCreate = new List<Income_Assessment__c>();
        for(Id applicantId : applicantIds){
            if(!applicantsWithIncomeAssessment.contains(applicantId)){
                // Create a new Income Assessment record for missing applicants
                incomeAssessmentsToCreate.add(new Income_Assessment__c(
                    Applicant__c = applicantId,
                    Loan_Application__c = recordId,
                    ParentorChild__c = 'Parent',
                    Type_of_Income_Assesment__c = 'Director Renumeration',
                    RecordTypeId= recTypeId
                ));
            }
        }
        if(!incomeAssessmentsToCreate.isEmpty()){
            insert incomeAssessmentsToCreate;
            return true; // Indicates records were created
        }
    }
    return true; // Indicates all applicants already had Income Assessment records
}
@AuraEnabled
public static void updateEligibilityAmount(String recordId, String newAmount) {
    Application_Applicant__c recordToUpdate = [
        SELECT Id FROM Application_Applicant__c WHERE Id = :recordId LIMIT 1
    ];
    recordToUpdate.AmountConsideredForEligibilityPurpos__c = newAmount;
    update recordToUpdate;
}

@AuraEnabled
public static void updateMonthNameChildrows(String recordId, Integer monthNumber, String monthName){
    List<Income_Assessment__c> incomeAssessment = [SELECT id, Month_Number__c, Month_And_Year__c
        FROM Income_Assessment__c 
        WHERE  Loan_Application__C = :recordId AND ParentorChild__c = 'Child' 
               AND Type_of_Income_Assesment__c = 'Director Renumeration'
               AND Month_Number__c = :monthNumber
        ];

    for(Income_Assessment__c ia : incomeAssessment){
        ia.Month_And_Year__c = monthName;
    }

    update incomeAssessment;

}


@AuraEnabled
public static List<IncomeMonthWrapper> fetchChildrows(String recordId){
Id recTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Director_Renumeration').getRecordTypeId();
List<Income_Assessment__c> applicants = [Select Id,Applicant__c,Applicant__r.Applicant_Name__c,ParentorChild__c,Loan_Application__c from Income_Assessment__c where ParentorChild__c = 'Parent' and Type_of_Income_Assesment__c = 'Director Renumeration' and RecordTypeId =:recTypeId and Loan_Application__c=:recordId];
    if(applicants.isEmpty()) return new List<IncomeMonthWrapper>();

    Set<Id> applicantIds = new Set<Id>();
    Map<Id, String> applicantIdToName = new Map<Id, String>();
    for(Income_Assessment__c a : applicants){
        applicantIds.add(a.Applicant__c);
        applicantIdToName.put(a.Applicant__c, a.Applicant__r.Applicant_Name__c);
    }

    List<Income_Assessment__c> parents = [SELECT Id FROM Income_Assessment__c 
        WHERE Applicant__c IN :applicantIds AND ParentorChild__c = 'Parent'];

    if(parents.isEmpty()) return new List<IncomeMonthWrapper>();

    List<Id> parentIds = new List<Id>();
    for(Income_Assessment__c p : parents) {
        parentIds.add(p.Id);
    }

    List<Income_Assessment__c> children = [SELECT Applicant__c, Salary_For_Month__c, Month_Number__c, Month_And_Year__c
        FROM Income_Assessment__c 
        WHERE Parent__c IN :parentIds AND ParentorChild__c = 'Child' AND Type_of_Income_Assesment__c = 'Director Renumeration'
        ORDER BY Month_Number__c ASC];

    Map<Integer, IncomeMonthWrapper> monthToWrapper = new Map<Integer, IncomeMonthWrapper>();

    Set<String> allDirectorNames = new Set<String>(applicantIdToName.values());

    for(Income_Assessment__c child : children){
        Integer month = (Integer)child.Month_Number__c;
        String monthName = child.Month_And_Year__c != null ? child.Month_And_Year__c: '';
        String directorName = applicantIdToName.get(child.Applicant__c);
        String salary = child.Salary_For_Month__c != null ? String.valueOf(child.Salary_For_Month__c) : '';
        String monthRecordId = child.Id;

        if(!monthToWrapper.containsKey(month)){
            IncomeMonthWrapper wrapper = new IncomeMonthWrapper(month, monthName);

            // Initialize salaries with empty string for all directors
            for(String dName : allDirectorNames){
                wrapper.directorSalaries.add(new DirectorSalary(dName, ''));
            }
            monthToWrapper.put(month, wrapper);
        }

        IncomeMonthWrapper currentWrapper = monthToWrapper.get(month);

        // Update the salary for the director
        for(DirectorSalary ds : currentWrapper.directorSalaries){
            if(ds.directorName == directorName){
                ds.salary = salary;
                ds.monthRecordId = monthRecordId;
                break;
            }
        }
    }

    List<Integer> sortedMonths = new List<Integer>(monthToWrapper.keySet());
    sortedMonths.sort();

    List<IncomeMonthWrapper> result = new List<IncomeMonthWrapper>();
    for(Integer m : sortedMonths){
        result.add(monthToWrapper.get(m));
    }

    System.debug('147 :'+result);
    return result;
}

public class IncomeMonthWrapper {
    @AuraEnabled public Integer month;
    @AuraEnabled public String monthName;
    @AuraEnabled public Boolean monthDisabled;
    @AuraEnabled public Id monthRecordId;
    @AuraEnabled public List<DirectorSalary> directorSalaries;

    public IncomeMonthWrapper(Integer month, String monthName) {
        this.month = month;
        this.monthName = monthName;
        this.monthDisabled = monthName != ''? true : false;
        this.monthRecordId = null;
        this.directorSalaries = new List<DirectorSalary>();
    }
}

public class DirectorSalary {
    @AuraEnabled public String directorName;
    @AuraEnabled public Id monthRecordId;
    @AuraEnabled public String salary;

    public DirectorSalary(String directorName, String salary) {
        this.directorName = directorName;
        this.salary = salary;
        this.monthRecordId = null;
    }
}

    @AuraEnabled
    public static void addRow(String recordId) {
        // Get all applicants (directors)
        map<String,String> parenttoId = new map<String,String>();
        Id recTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Director_Renumeration').getRecordTypeId();
        // List<Application_Applicant__c> applicants = [SELECT Id, Applicant_Name__c, Customer_Type__c 
        //     FROM Application_Applicant__c WHERE Loan_Application__C = :recordId AND Applicant_Type__c != 'Primary Applicant' 
        //     AND Customer_Type__c = 'Individual'];
        List<Income_Assessment__c> applicants = [Select Id,Applicant__c,ParentorChild__c,Loan_Application__c from Income_Assessment__c where ParentorChild__c = 'Parent' and Type_of_Income_Assesment__c = 'Director Renumeration' and RecordTypeId =:recTypeId and Loan_Application__c=:recordId];
            List<Income_Assessment__c> parentRec = [Select Id,Applicant__c from Income_Assessment__c where Loan_Application__c =:recordId and ParentorChild__c = 'Parent' and Type_of_Income_Assesment__c = 'Director Renumeration'];
            for(Income_Assessment__c iac : parentRec){
                parenttoId.put(iac.Applicant__c,iac.Id);
            }
        // If no directors found, exit early
        System.debug('applicants : '+applicants);
        // if(applicants.isEmpty()) {
        //     return;
        // }
        // Aggregate query to find the maximum existing Month_Number__c in child income assessments
        AggregateResult maxMonthResult = [
            SELECT MAX(Month_Number__c) maxMonth FROM Income_Assessment__c WHERE Loan_Application__c = :recordId 
            AND ParentorChild__c = 'Child' AND Type_of_Income_Assesment__c = 'Director Renumeration'];
        Integer maxMonth = 0; // Default to 0 if no child records found
        // Check if the aggregate returned a value
        if(maxMonthResult != null && maxMonthResult.get('maxMonth') != null) {
            // Cast Decimal to Integer
            maxMonth = ((Decimal)maxMonthResult.get('maxMonth')).intValue();
        }
        // If no child records exist, maxMonth stays 0,
        // so the new month number will start at 1
        Integer newMonthNumber = maxMonth + 1; // Next month number
        // Prepare new child income assessment records for all directors
        List<Income_Assessment__c> newChildRecords = new List<Income_Assessment__c>();
        System.debug('applicants 195 : '+applicants);
        for(Income_Assessment__c applicant : applicants) {
            Income_Assessment__c newRecord = new Income_Assessment__c();
            newRecord.Loan_Application__c = recordId;
            newRecord.Applicant__c = applicant.Applicant__c;
            newRecord.ParentorChild__c = 'Child';
            newRecord.Type_of_Income_Assesment__c = 'Director Renumeration';
            newRecord.Parent__c = parenttoId.get(applicant.Applicant__c);
            newRecord.Month_Number__c = newMonthNumber; // Assign calculated month number
            newRecord.RecordTypeId = recTypeId;
            newChildRecords.add(newRecord);
        }
        // Insert all new records if list is not empty
        if(!newChildRecords.isEmpty()) {
            System.debug('newChildRecords : '+newChildRecords);
            System.debug('newChildRecords : '+newChildRecords.size());
            insert newChildRecords;
        }
    }
public class DirectorTotal {
    @AuraEnabled public String directorName;
    @AuraEnabled public String totalSalary;
    @AuraEnabled public String parentId;
}

@AuraEnabled
public static List<DirectorTotal> fetchTotals(String recordId) {
    List<DirectorTotal> totals = new List<DirectorTotal>();
    List<Income_Assessment__c> parent = [SELECT Id,Gross_Salary__c,Applicant__c,Applicant__r.Applicant_Name__c ,Salary_For_Month__c, Month_Number__c 
        FROM Income_Assessment__c 
        WHERE Loan_Application__C = :recordId AND ParentorChild__c = 'Parent' AND Type_of_Income_Assesment__c = 'Director Renumeration'];
        for(Income_Assessment__c iac : parent){
            DirectorTotal dt = new DirectorTotal();
            dt.directorName = iac.Applicant__r.Applicant_Name__c;
            dt.totalSalary = String.valueOf(iac.Gross_Salary__c);
            dt.parentId = iac.Id;
            totals.add(dt);
        }
    return totals;
}
@AuraEnabled
public static List<DirectorTotal> fetchTotalAfterDeleting(String recordId) {
    List<DirectorTotal> totals = new List<DirectorTotal>();

    // Query parent records (directors)
    List<Income_Assessment__c> parents = [
        SELECT Id, Applicant__r.Applicant_Name__c 
        FROM Income_Assessment__c 
        WHERE Loan_Application__C = :recordId 
          AND ParentorChild__c = 'Parent' 
          AND Type_of_Income_Assesment__c = 'Director Renumeration'
    ];

    if (parents.isEmpty()) {
        return totals;
    }

    // Query child records for all parents
    List<Income_Assessment__c> children = [
        SELECT Parent__c, Salary_For_Month__c 
        FROM Income_Assessment__c 
        WHERE Parent__c IN :parents 
          AND ParentorChild__c = 'Child' 
          AND Type_of_Income_Assesment__c = 'Director Renumeration'
    ];

    // Map to hold total salaries by parent Id
    Map<Id, Decimal> parentToSalaryMap = new Map<Id, Decimal>();

    // Sum salaries per parent
    for (Income_Assessment__c child : children) {
        if (String.isNotBlank(child.Salary_For_Month__c)) {
            try {
                Decimal sal = Decimal.valueOf(child.Salary_For_Month__c.replaceAll(',', ''));
                Decimal currentTotal = 0;
                if (parentToSalaryMap.containsKey(child.Parent__c)) {
                    currentTotal = parentToSalaryMap.get(child.Parent__c);
                }
                parentToSalaryMap.put(child.Parent__c, currentTotal + sal);
            } catch (Exception e) {
                System.debug('Skipping invalid salary: ' + child.Salary_For_Month__c);
            }
        }
    }

    // Build totals list for all parents, defaulting to 0 if no child records found
    for (Income_Assessment__c parent : parents) {
        DirectorTotal dt = new DirectorTotal();
        dt.directorName = parent.Applicant__r.Applicant_Name__c;
        Decimal totalSalary = parentToSalaryMap.containsKey(parent.Id) ? parentToSalaryMap.get(parent.Id) : 0;
        dt.totalSalary = String.valueOf(totalSalary);
        dt.parentId = parent.Id;
        totals.add(dt);
    }
       
    for(DirectorTotal dtt : totals){
        Income_Assessment__c acc = new Income_Assessment__c();
        acc.Id = dtt.parentId;
        acc.Gross_Salary__c = Decimal.valueOf(dtt.totalSalary);
        update acc;
    }


    return totals;
}

@AuraEnabled
public static Decimal checkandUpdateTotal(Id parentId, String previousValue, String salary) {
    Decimal prev = Decimal.valueOf(String.isNotBlank(previousValue) ? previousValue : '0');
    Decimal current = Decimal.valueOf(String.isNotBlank(salary) ? salary : '0');
    Decimal delta = current - prev;

    // Query all children under this parent
    List<Income_Assessment__c> children = [
        SELECT Id, Salary_For_Month__c
        FROM Income_Assessment__c
        WHERE Parent__c = :parentId AND ParentorChild__c = 'Child' AND Type_of_Income_Assesment__c = 'Director Renumeration'
    ];

    Decimal totalSalary = 0;

    // Sum salaries after converting to Decimal
    for (Income_Assessment__c child : children) {
        if (String.isNotBlank(child.Salary_For_Month__c)) {
            try {
                totalSalary += Decimal.valueOf(child.Salary_For_Month__c);
            } catch (Exception e) {
                // Handle parsing errors gracefully
                System.debug('Skipping invalid salary value: ' + child.Salary_For_Month__c);
            }
        }
    }

    // Add delta (the difference from the edited salary)
    // totalSalary += delta;

    // Update parent record's Gross_Salary__c field
    Income_Assessment__c parentRecord = [
        SELECT Id, Gross_Salary__c
        FROM Income_Assessment__c
        WHERE Id = :parentId
        LIMIT 1
    ];

    if (parentRecord != null) {
        parentRecord.Gross_Salary__c = totalSalary;
        update parentRecord;
    }

    return totalSalary;
}
@AuraEnabled
public static void deleteHighestMonth(Id recordId) {
    List<AggregateResult> aggResults = [
        SELECT MAX(Month_Number__c) maxMonth
        FROM Income_Assessment__c
        WHERE Loan_Application__C = :recordId
          AND ParentorChild__c = 'Child'
          AND Type_of_Income_Assesment__c = 'Director Renumeration'
    ];
    
    if (aggResults.isEmpty()) {
        System.debug('No records found for deletion.');
        return;
    }
    
    Decimal maxMonthDecimal = (Decimal)aggResults[0].get('maxMonth');
    Integer highestMonth = maxMonthDecimal != null ? maxMonthDecimal.intValue() : null;

    if (highestMonth == null) {
        System.debug('No child records with Month_Number__c found.');
        return;
    }

    System.debug('Highest month to delete: ' + highestMonth);

    List<Income_Assessment__c> recordsToDelete = [
        SELECT Id
        FROM Income_Assessment__c
        WHERE Loan_Application__C = :recordId
          AND ParentorChild__c = 'Child'
          AND Type_of_Income_Assesment__c = 'Director Renumeration'
          AND Month_Number__c = :highestMonth
    ];

    if (!recordsToDelete.isEmpty()) {
        delete recordsToDelete;
        System.debug(recordsToDelete.size() + ' records deleted for month ' + highestMonth);
    } else {
        System.debug('No records found for highest month ' + highestMonth);
    }
}

@AuraEnabled
public static List<DirectorTotal> fetchAverages(String recordId) {
    List<DirectorTotal> averages = new List<DirectorTotal>();

    List<Income_Assessment__c> parents = [
        SELECT Id, Applicant__r.Applicant_Name__c
        FROM Income_Assessment__c
        WHERE Loan_Application__C = :recordId
        AND ParentorChild__c = 'Parent'
        AND Type_of_Income_Assesment__c = 'Director Renumeration'
    ];

    if (parents.isEmpty()) {
        return averages;
    }

    List<Income_Assessment__c> children = [
        SELECT Parent__c, Salary_For_Month__c
        FROM Income_Assessment__c
        WHERE Parent__c IN :parents
        AND ParentorChild__c = 'Child'
        AND Type_of_Income_Assesment__c = 'Director Renumeration'
    ];

    Map<Id, Decimal> parentToTotalMap = new Map<Id, Decimal>();
    Map<Id, Integer> parentToCountMap = new Map<Id, Integer>();

    for (Income_Assessment__c child : children) {
        if (String.isNotBlank(child.Salary_For_Month__c)) {
            try {
                Decimal sal = Decimal.valueOf(child.Salary_For_Month__c.replaceAll(',', ''));
                Decimal currentTotal = parentToTotalMap.containsKey(child.Parent__c) ? parentToTotalMap.get(child.Parent__c) : 0;
                Integer currentCount = parentToCountMap.containsKey(child.Parent__c) ? parentToCountMap.get(child.Parent__c) : 0;

                parentToTotalMap.put(child.Parent__c, currentTotal + sal);
                parentToCountMap.put(child.Parent__c, currentCount + 1);
            } catch (Exception e) {
                System.debug('Skipping invalid salary: ' + child.Salary_For_Month__c);
            }
        }
    }

    List<Income_Assessment__c> recordsToUpdate = new List<Income_Assessment__c>();

    for (Income_Assessment__c parent : parents) {
        DirectorTotal dt = new DirectorTotal();
        Income_Assessment__c record = new Income_Assessment__c();

        dt.directorName = parent.Applicant__r.Applicant_Name__c;
        Decimal total = parentToTotalMap.containsKey(parent.Id) ? parentToTotalMap.get(parent.Id) : 0;
        Integer count = parentToCountMap.containsKey(parent.Id) ? parentToCountMap.get(parent.Id) : 0;
        Decimal average = count > 0 ? total.divide(count, 2) : 0;

        dt.totalSalary = String.valueOf(average);
        dt.parentId = parent.Id;

        // Update fields
        record.Id = parent.Id;
        record.Gross_Monthly_Salary__c = average;

        recordsToUpdate.add(record);
        averages.add(dt);
    }

    if (!recordsToUpdate.isEmpty()) {
        update recordsToUpdate;
    }

    return averages;
}
@AuraEnabled
public static List<ApplicantWrapper> getApplicants(String loanId){
        List<ApplicantWrapper> finalResult = new List<ApplicantWrapper>();
        List<Application_Applicant__c> appList = [Select Id, Applicant_Name__c from Application_Applicant__c where Loan_Application__c =: loanId];
        List<Income_Assessment__c> createdIncm = [Select Id, Applicant__c from Income_Assessment__c where Applicant__c in: appList and Type_of_Income_Assesment__c = 'Director Renumeration' and ParentorChild__c = 'Parent'];
        if(!appList.isEmpty()){
            Map<String,Income_Assessment__c> appToIncmMap = new Map<String,Income_Assessment__c>();
            for(Income_Assessment__c incm : createdIncm){
                appToIncmMap.put(incm.Applicant__c,incm);
            }
            for(Application_Applicant__c app : appList){
                ApplicantWrapper wrap = new ApplicantWrapper();
                wrap.name = app.Applicant_Name__c;
                wrap.appId = app.Id;
                wrap.isDataCreated = false;
                if(appToIncmMap.containsKey(app.Id)){
                    wrap.isDataCreated = true;
                }
                finalResult.add(wrap);
            }
        }
        return finalResult;
    }
    public class ApplicantWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public String appId;
        @AuraEnabled public Boolean isDataCreated;
    }
@AuraEnabled
public static void deleteCamRecords(String loanId, String apDetId){
    try {
        System.debug('loanId : '+loanId);
        System.debug('apDetId : '+apDetId);
        // Fetch parent Income Assessment records
        List<Income_Assessment__c> ias = [
            SELECT Id, Applicant__c
            FROM Income_Assessment__c
            WHERE Applicant__c = :apDetId AND ParentorChild__c = 'Parent'
            AND Type_of_Income_Assesment__c = 'Director Renumeration'
        ];
        // If parent exists, fetch child rows
        List<Income_Assessment__c> childRows = new List<Income_Assessment__c>();
        if (!ias.isEmpty()) {
            childRows = [
                SELECT Id, Applicant__c, Salary_For_Month__c, Month_Number__c, Month_And_Year__c
                FROM Income_Assessment__c
                WHERE Parent__c = :ias[0].Id
                  AND ParentorChild__c = 'Child'
                  AND Type_of_Income_Assesment__c = 'Director Renumeration'
                ORDER BY Month_Number__c ASC
            ];
        }
        // Delete children first, then parents
        if (!childRows.isEmpty()) {
            delete childRows;
        }
        if (!ias.isEmpty()) {
            delete ias;
        }
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}
@AuraEnabled
public static Boolean createCamRecordsOnLoad(String loanId, String apDetId) {
    try {
        // Get Director Remuneration Record Type Id
        Id recTypeId = Schema.SObjectType.Income_Assessment__c
            .getRecordTypeInfosByDeveloperName()
            .get('Director_Renumeration')
            .getRecordTypeId();
        // -------------------------------
        // 1. CREATE PARENT RECORD
        // -------------------------------
        Income_Assessment__c parentRec = new Income_Assessment__c(
            Applicant__c = apDetId,
            Loan_Application__c = loanId,
            ParentorChild__c = 'Parent',
            Type_of_Income_Assesment__c = 'Director Renumeration',
            RecordTypeId = recTypeId
        );
        insert parentRec;
        // -------------------------------
        // 2. GET MAX EXISTING CHILD MONTH
        // -------------------------------
        AggregateResult[] maxMonthResult = [
            SELECT MAX(Month_Number__c) maxMonth
            FROM Income_Assessment__c
            WHERE Loan_Application__c = :loanId
              AND ParentorChild__c = 'Child'
              AND Type_of_Income_Assesment__c = 'Director Renumeration'
        ];
        Integer maxMonth = 0;
        if (maxMonthResult.size() > 0 && maxMonthResult[0].get('maxMonth') != null) {
            maxMonth = ((Decimal) maxMonthResult[0].get('maxMonth')).intValue();
        }
        // newMonthNumber = maxMonth + 1
        Integer newMonthNumber = maxMonth + 1;
        // -------------------------------
        // 3. CREATE CHILD RECORDS
        // -------------------------------
        List<Income_Assessment__c> newChildRecords = new List<Income_Assessment__c>();
        // B → Create (newMonthNumber - 1) child records
        for (Integer i = 1; i < newMonthNumber; i++) {
            newChildRecords.add(
                new Income_Assessment__c(
                    Loan_Application__c = loanId,
                    Applicant__c = apDetId,
                    ParentorChild__c = 'Child',
                    Type_of_Income_Assesment__c = 'Director Renumeration',
                    Parent__c = parentRec.Id,
                    Month_Number__c = i,
                    RecordTypeId = recTypeId
                )
            );
        }

        if (!newChildRecords.isEmpty()) {
            insert newChildRecords;
        }

        return true;

    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}




}