/**
* @File Name : HL_RentalIncomeProgramController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 22, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 22, 2025 |   | Initial Version
**/

public class HL_RentalIncomeProgramController {
	@AuraEnabled
    public static List<ApplicantWrapper> getApplicants(String loanId, String recordTypeName){
        List<ApplicantWrapper> finalResult = new List<ApplicantWrapper>();
        List<Application_Applicant__c> appList = [Select Id, Applicant_Name__c from Application_Applicant__c where Loan_Application__c =: loanId And Applicant_Name__c != ''];
        
        if(!appList.isEmpty()){
            List<Income_Assessment__c> createdIncm = [Select Id, Applicant__c from Income_Assessment__c where Applicant__c in: appList and RecordType.Name =: recordTypeName And Parent__c = null];
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
                    wrap.parentRecordId = appToIncmMap.get(app.Id).Id;
                }
                finalResult.add(wrap);
            }
        }
        return finalResult;
    }

    public class ApplicantWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public String appId;
        @AuraEnabled public String parentRecordId;
        @AuraEnabled public Boolean isDataCreated;
    }

    @AuraEnabled
    public static void createCamRecordsOnLoad(String loanId, String apDetId){
        String rentalIncomeProgramRecTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Rental_Income_Program').getRecordTypeId();
        List<Income_Assessment__c> parentRecList = [Select Id, Loan_Application__c from Income_Assessment__c where Loan_Application__c =: loanId and Applicant__c =: apDetId and Parent__c = null and RecordType.Name = 'Rental Income Program'];
        if(parentRecList.isEmpty()){
            Income_Assessment__c parentRec = new Income_Assessment__c();
            parentRec.Loan_Application__c = loanId;
            parentRec.Applicant__c = apDetId;
            parentRec.RecordTypeId = rentalIncomeProgramRecTypeId;
            Insert parentRec;
            
            Income_Assessment__c childRec = new Income_Assessment__c();
            childRec.Loan_Application__c = loanId;
            childRec.Applicant__c = apDetId;
            childRec.Parent__c = parentRec.Id;
            childRec.RecordTypeId = rentalIncomeProgramRecTypeId;
            Insert childRec;

            List<Income_Assessment__c> grandChildCamToCreate = new List<Income_Assessment__c>();
            for(Integer i=0; i<6; i++){
                Income_Assessment__c grandChildRec = new Income_Assessment__c();
                grandChildRec.Loan_Application__c = loanId;
                grandChildRec.Applicant__c = apDetId;
                grandChildRec.Parent__c = childRec.Id;
                grandChildRec.RecordTypeId = rentalIncomeProgramRecTypeId;
                grandChildCamToCreate.add(grandChildRec);
            }
            if(!grandChildCamToCreate.isEmpty()){
                Insert grandChildCamToCreate;
            }
        }
    }

    @AuraEnabled
    public static void addPropertyIncomeAssessment(String loanId, String apDetId){
        String rentalIncomeProgramRecTypeId = Schema.SObjectType.Income_Assessment__c.getRecordTypeInfosByDeveloperName().get('Rental_Income_Program').getRecordTypeId();
        List<Income_Assessment__c> parentRecList = [Select Id, Loan_Application__c 
                                                    from Income_Assessment__c 
                                                    where Loan_Application__c =: loanId and Applicant__c =: apDetId 
                                                        and Parent__c = null and RecordType.Name = 'Rental Income Program'];
        if(!parentRecList.isEmpty()){
            Income_Assessment__c childRec = new Income_Assessment__c();
            childRec.Loan_Application__c = loanId;
            childRec.Applicant__c = apDetId;
            childRec.Parent__c = parentRecList[0].Id;
            childRec.RecordTypeId = rentalIncomeProgramRecTypeId;
            Insert childRec;

            List<Income_Assessment__c> grandChildCamToCreate = new List<Income_Assessment__c>();
            for(Integer i=0; i<6; i++){
                Income_Assessment__c grandChildRec = new Income_Assessment__c();
                grandChildRec.Loan_Application__c = loanId;
                grandChildRec.Applicant__c = apDetId;
                grandChildRec.Parent__c = childRec.Id;
                grandChildRec.RecordTypeId = rentalIncomeProgramRecTypeId;
                grandChildCamToCreate.add(grandChildRec);
            }
            if(!grandChildCamToCreate.isEmpty()){
                Insert grandChildCamToCreate;
            }
        }
    }

    @AuraEnabled
    public static MainWrapper getScreenData(String loanId, String apDetId){
        createCamRecordsOnLoad(loanId, apDetId);
        MainWrapper mainWrap = new MainWrapper();
        mainWrap.headerValues = new List<String>();
        mainWrap.headerValues.add('Particulars');
        List<Income_Assessment__c> parentRec = [Select Id, Loan_Application__c, Eligibility_Consideration__c 
                                                from Income_Assessment__c 
                                                where Loan_Application__c =: loanId and Applicant__c =: apDetId and
                                                Parent__c = null and RecordType.Name = 'Rental Income Program'];
        if(!parentRec.isEmpty()){
            mainWrap.recordId = parentRec[0].Id;
            mainWrap.eligibilityConsideration = parentRec[0].Eligibility_Consideration__c;
            List<LeaseWrapper> wrappers = new List<LeaseWrapper>();
            List<Income_Assessment__c> childRecs = [SELECT Id, Name,
                                                        HL_Lessor__c, HL_Lessee__c, HL_Property_Address__c,
                                                        HL_Agreement_Registered_Date__c, HL_Lease_Commencement_Date__c,
                                                        HL_Tenure_In_Months__c, HL_Locking_Period_In_Months__c,
                                                        HL_Security_Deposit__c, Hl_Escalation__c,
                                                        HL_Gross_Rent__c, HL_TDS__c, HL_GST__c, HL_Net_Rental__c,
                                                        HL_Bank_Details__c, HL_Amount_Without_GST__c, 
                                                        Average_Amount__c,Gross_Amount__c,
                                                        (SELECT Id, Name, HL_Month_Name__c, HL_Month_Value__c 
                                                        FROM Bankings__r 
                                                        ORDER BY CreatedDate)
                                                    FROM Income_Assessment__c
                                                    WHERE Parent__c IN :parentRec
                                                    ];
            for (Integer i = 0; i < childRecs.size(); i++) {
                Income_Assessment__c rec = childRecs[i];
                LeaseWrapper lw = new LeaseWrapper();
                lw.recordId = rec.Id;
                lw.lessor = rec.HL_Lessor__c;
                lw.lessee = rec.HL_Lessee__c;
                lw.propertyAddress = rec.HL_Property_Address__c;
                lw.agreementRegisteredDate = rec.HL_Agreement_Registered_Date__c != null 
                    ? rec.HL_Agreement_Registered_Date__c.format() : '';
                lw.leaseCommencementDate = rec.HL_Lease_Commencement_Date__c != null 
                    ? rec.HL_Lease_Commencement_Date__c.format() : '';
                lw.tenureInMonths = String.valueOf(rec.HL_Tenure_In_Months__c);
                lw.lockingPeriodInMonths = String.valueOf(rec.HL_Locking_Period_In_Months__c);
                lw.securityDeposit = rec.HL_Security_Deposit__c != null ? rec.HL_Security_Deposit__c.format() : '';
                lw.escalationPercent = String.valueOf(rec.HL_Escalation__c);
                lw.grossRent = rec.HL_Gross_Rent__c != null ? rec.HL_Gross_Rent__c.format() : '';
                lw.tds = rec.HL_TDS__c != null ? rec.HL_TDS__c.format() : '';
                lw.gst = rec.HL_GST__c != null ? rec.HL_GST__c.format() : '';
                lw.netRental = rec.HL_Net_Rental__c != null ? rec.HL_Net_Rental__c.format() : '';
                lw.amountWithoutGST = rec.HL_Amount_Without_GST__c != null ? rec.HL_Amount_Without_GST__c.format() : '';
                lw.bankDetails = rec.HL_Bank_Details__c;
                lw.totalAmount = String.valueOf(rec.Gross_Amount__c);
                lw.average = rec.Average_Amount__c != null ? rec.Average_Amount__c.format() : '';

                lw.monthData = new List<MonthWrapper>();
                for (Income_Assessment__c monthRec : rec.Bankings__r) {
                    MonthWrapper mw = new MonthWrapper();
                    mw.recordId = monthRec.Id;
                    mw.monthName = monthRec.HL_Month_Name__c;
                    mw.monthValue = monthRec.HL_Month_Value__c != null ? monthRec.HL_Month_Value__c.format() : '';
                    lw.monthData.add(mw);
                }
                wrappers.add(lw);  
                mainWrap.headerValues.add('Property ' + (i+1));      
            }
           mainWrap.leaseData = wrappers;
        }
        
        return mainWrap;
    }

    public class MonthWrapper {
        @AuraEnabled public String recordId;
        @AuraEnabled public String monthName;
        @AuraEnabled public String monthValue;
    }

    public class LeaseWrapper {
        @AuraEnabled public String recordId;
        @AuraEnabled public String lessor { get; set; }
        @AuraEnabled public String lessee { get; set; }
        @AuraEnabled public String propertyAddress { get; set; }
        @AuraEnabled public String agreementRegisteredDate { get; set; }
        @AuraEnabled public String leaseCommencementDate { get; set; }
        @AuraEnabled public String tenureInMonths { get; set; }
        @AuraEnabled public String lockingPeriodInMonths { get; set; }
        @AuraEnabled public String securityDeposit { get; set; }
        @AuraEnabled public String escalationPercent { get; set; }
        @AuraEnabled public String grossRent { get; set; }
        @AuraEnabled public String tds { get; set; }
        @AuraEnabled public String gst { get; set; }
        @AuraEnabled public String netRental { get; set; }
        @AuraEnabled public String bankDetails { get; set; }
        @AuraEnabled public String average { get; set; }
        @AuraEnabled public String totalAmount { get; set; }
        @AuraEnabled public String amountWithoutGST { get; set; }
        @AuraEnabled public List<MonthWrapper> monthData { get; set; }
    }

    public class MainWrapper{
        @AuraEnabled public String recordId;
        @AuraEnabled public List<LeaseWrapper> leaseData;
        @AuraEnabled public List<String> headerValues;
        @AuraEnabled public String eligibilityConsideration;
    }

	@AuraEnabled
    public static void deleteCamRecords(String loanId,List<Id> applicantIds){
        List<Income_Assessment__c> camList =[Select Id from Income_Assessment__c where Applicant__c IN : applicantIds and Loan_Application__c =: loanId and RecordType.Name = 'Rental Income Program'];
        if(!camList.isEmpty()){
            Delete camList;
        }
    }

    @AuraEnabled
    public static void updateEligibilityConsideration(String loanId, String apDetId, String eligibilityValue) {
        List<Income_Assessment__c> parentRec = [SELECT Id, Eligibility_Consideration__c 
                                                FROM Income_Assessment__c 
                                                WHERE Loan_Application__c =: loanId AND Applicant__c =: apDetId AND
                                                     Parent__c = null AND RecordType.Name = 'Rental Income Program' LIMIT 1];
        if (!parentRec.isEmpty()) {
            Income_Assessment__c rec = parentRec[0];
            rec.Eligibility_Consideration__c = eligibilityValue;
            update rec;
        }
    }

    @AuraEnabled
    public static void calculateTotalAndAverage(String recordId) {
        Income_Assessment__c parentRec = [
            SELECT Id, Average_Amount__c, Gross_Amount__c,
                (SELECT Id, HL_Month_Value__c FROM Bankings__r ORDER BY CreatedDate)
            FROM Income_Assessment__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        Decimal total = 0;
        Integer count = 0;
        if (parentRec.Bankings__r != null && !parentRec.Bankings__r.isEmpty()) {
            for (Income_Assessment__c bankingRec : parentRec.Bankings__r) {
                if (bankingRec.HL_Month_Value__c != null) {
                    total += bankingRec.HL_Month_Value__c;
                    count++;
                }
            }
        }
        Decimal average = (count > 0) ? (total / count) : 0;
        parentRec.Gross_Amount__c = total;
        parentRec.Average_Amount__c = average;

        update parentRec;
    }


    @AuraEnabled
    public static void updateMonthNames(String loanId, String apDetId, String startMonthYear){
        List<Income_Assessment__c> parentRec = [Select Id, Loan_Application__c, Eligibility_Consideration__c 
                                                from Income_Assessment__c 
                                                where Loan_Application__c =: loanId and Applicant__c =: apDetId and
                                                Parent__c = null and RecordType.Name = 'Rental Income Program'];
        if(!parentRec.isEmpty()){
            List<Income_Assessment__c> childRecs = [SELECT Id, Name,
                                                        (SELECT Id, Name, HL_Month_Name__c 
                                                        FROM Bankings__r 
                                                        ORDER BY CreatedDate)
                                                    FROM Income_Assessment__c
                                                    WHERE Parent__c IN :parentRec
                                                    ];
            List<String> monthNames = getLastSixMonths(startMonthYear);
            List<Income_Assessment__c> childToUpdate = new List<Income_Assessment__c>();
            for (Integer i = 0; i < childRecs.size(); i++) {
                Income_Assessment__c rec = childRecs[i];
                Integer index = 0;
                for (Income_Assessment__c monthRec : rec.Bankings__r) {
                    if (index < monthNames.size()) {
                            monthRec.HL_Month_Name__c = monthNames[index];
                            childToUpdate.add(monthRec);
                            index++;
                        } else {
                            break;
                        }
                }      
            }

            if (!childToUpdate.isEmpty()) {
                update childToUpdate;
            }
        }
    }

    public static List<String> getLastSixMonths(String inputMonthYear) {
    List<String> monthList = new List<String>();

    if (String.isBlank(inputMonthYear)) return monthList;

    List<String> parts = inputMonthYear.split('-');
    if (parts.size() != 2) {
        throw new AuraHandledException('Invalid format. Expected format: MMM-yy (e.g. Jun-25)');
    }

    String monthStr = parts[0];
    String yearStr = parts[1];

    // Convert 2-digit year to 4-digit
    if (yearStr.length() == 2) {
        yearStr = '20' + yearStr;
    }

    Integer monthNum;
    Map<String, Integer> monthMap = new Map<String, Integer>{
        'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4,
        'May' => 5, 'Jun' => 6, 'Jul' => 7, 'Aug' => 8,
        'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12
    };

    if (!monthMap.containsKey(monthStr)) {
        throw new AuraHandledException('Invalid month abbreviation: ' + monthStr);
    }

    monthNum = monthMap.get(monthStr);
    Integer yearNum = Integer.valueOf(yearStr);

    Date startDate = Date.newInstance(yearNum, monthNum, 1);

    for (Integer i = 0; i < 6; i++) {
        Date target = startDate.addMonths(-i);
        String formatted = DateTime.newInstance(target, Time.newInstance(0,0,0,0))
                            .format('MMM-yy');
        monthList.add(formatted);
    }

    return monthList;
}


}