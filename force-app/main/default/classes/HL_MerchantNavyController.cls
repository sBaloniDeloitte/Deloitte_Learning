public with sharing class HL_MerchantNavyController {
	@AuraEnabled
    public static List<IncomeAssessmentWrapper> getMerNavyIncomeExpenses(String loanId,List<Id> applicantIds,List<String> incomeValues,List<String> obligationValues,List<String> sailingValues) {
        List<IncomeAssessmentWrapper> wrapperList = new List<IncomeAssessmentWrapper>();
        system.debug('incomeValues>>>>>>>>>>>>>>>>'+incomeValues);
        system.debug('obligationValues>>>>>>>>>>>>>>>>'+obligationValues);
        system.debug('sailingValues>>>>>>>>>>>>>>>>'+sailingValues);
        Id merchantNavyRecordId = Utility.getRecordTypeIdByDeveloperName(
            'Income_Assessment__c', 'Merchant_Navy'
        );
        Map<Id, List<Income_Assessment__c>> existingMap = new Map<Id, List<Income_Assessment__c>>();
        for (Income_Assessment__c ia : [SELECT Id, Name, Applicant__c, Applicant__r.Applicant_Name__c, Loan_Application__c, Type_of_Income_Assesment__c, Particulars__c, Amount_in_INR__c, Is_Default_Record__c,
                                        Amount_in_Foreign__c, Exchange_Rate__c, ParentorChild__c, Parent__c,Sailing_From__c,Sailing_To__c 
                                        FROM Income_Assessment__c 
                                        WHERE RecordTypeId = :merchantNavyRecordId
                                        AND Loan_Application__c = :loanId 
                                        AND Applicant__c IN :applicantIds]) {
            if (!existingMap.containsKey(ia.Applicant__c)) {
                existingMap.put(ia.Applicant__c, new List<Income_Assessment__c>());
            }
            existingMap.get(ia.Applicant__c).add(ia);
        }

        List<Income_Assessment__c> toInsert = new List<Income_Assessment__c>();
        Map<Id, List<Income_Assessment__c>> newChildrenMap = new Map<Id, List<Income_Assessment__c>>();

        for (Id appId : applicantIds) {
            Set<String> existingKeys = new Set<String>();
            Set<String> existingSailingKeys = new Set<String>();
            Map<String, Id> parentIds = new Map<String, Id>();
			Map<String, Id> merchantParentIds = new Map<String, Id>();
            
            if (existingMap.containsKey(appId)) {
                for (Income_Assessment__c e : existingMap.get(appId)) {
                    existingKeys.add(e.Type_of_Income_Assesment__c + '|' + e.Particulars__c);
                    if(/*e.Sailing_From__c != null && e.Sailing_To__c != null ||*/ e.name == 'Sailing Period') {
                    	existingSailingKeys.add(e.Sailing_From__c+'|'+e.Sailing_To__c);
                    }
                    if (e.ParentorChild__c == 'Parent') {
                        parentIds.put(e.Type_of_Income_Assesment__c, e.Id);
                        merchantParentIds.put('Sailing Period',e.Id);
                    }
                }
            }
			system.debug(existingKeys);
            for (String val : incomeValues) {
                if (!existingKeys.contains('Income|' + val)) {
                    Income_Assessment__c child = new Income_Assessment__c(
                        RecordTypeId = merchantNavyRecordId,
                        Applicant__c  = appId,
                        Loan_Application__c = loanId,
                        Type_of_Income_Assesment__c = 'Income',
                        Particulars__c = val,
                        ParentorChild__c = 'Child',
                        Is_Default_Record__c = true,
                        Name = val
                    );
                    toInsert.add(child);
                    if (!newChildrenMap.containsKey(appId)) newChildrenMap.put(appId, new List<Income_Assessment__c>());
                    newChildrenMap.get(appId).add(child);
                }
            }

            for (String val : obligationValues) {
                if (!existingKeys.contains('Obligations|' + val)) {
                    Income_Assessment__c child = new Income_Assessment__c(
                        RecordTypeId = merchantNavyRecordId,
                        Applicant__c  = appId,
                        Loan_Application__c = loanId,
                        Type_of_Income_Assesment__c = 'Obligations',
                        Particulars__c = val,
                        ParentorChild__c = 'Child',
                        Is_Default_Record__c = true,
                        Name = val
                    );
                    toInsert.add(child);
                    if (!newChildrenMap.containsKey(appId)) newChildrenMap.put(appId, new List<Income_Assessment__c>());
                    newChildrenMap.get(appId).add(child);
                }
            }
            /*
            for (String val : sailingValues) {
                if (!existingKeys.contains('Sailings|' + val)) {
                    Income_Assessment__c child = new Income_Assessment__c(
                        RecordTypeId = merchantNavyRecordId,
                        Applicant__c  = appId,
                        Loan_Application__c = loanId,
                        Type_of_Income_Assesment__c = 'Sailings',
                        Particulars__c = val,
                        ParentorChild__c = 'Child',
                        Is_Default_Record__c = true,
                        Name = val
                    );
                    toInsert.add(child);
                    if (!newChildrenMap.containsKey(appId)) newChildrenMap.put(appId, new List<Income_Assessment__c>());
                    newChildrenMap.get(appId).add(child);
                }
            }
			*/
            system.debug('existingSailingKeys>>>>'+existingSailingKeys);
            system.debug('existingSailingKeys>>>>'+existingSailingKeys.isEmpty());
            if(existingSailingKeys.isEmpty()){
                Income_Assessment__c child = new Income_Assessment__c(
                    RecordTypeId = merchantNavyRecordId,
                    Applicant__c  = appId,
                    Loan_Application__c = loanId,
                    ParentorChild__c = 'Child',
                    Name = 'Sailing Period',
                    Type_of_Income_Assesment__c = 'Sailings',
                    Is_Default_Record__c = true
                );
                toInsert.add(child);
                if (!newChildrenMap.containsKey(appId)) newChildrenMap.put(appId, new List<Income_Assessment__c>());
                    newChildrenMap.get(appId).add(child);
            }
            if (!parentIds.containsKey('Income')) {
                toInsert.add(new Income_Assessment__c(
                    RecordTypeId = merchantNavyRecordId,
                    Applicant__c  = appId,
                    Loan_Application__c = loanId,
                    Type_of_Income_Assesment__c = 'Income',
                    Particulars__c = 'Income Total',
                    ParentorChild__c = 'Parent',
                    Is_Default_Record__c = true,
                    Name = 'Income Total'
                ));
            }
            if (!parentIds.containsKey('Obligations')) {
                toInsert.add(new Income_Assessment__c(
                    RecordTypeId = merchantNavyRecordId,
                    Applicant__c  = appId,
                    Loan_Application__c = loanId,
                    Type_of_Income_Assesment__c = 'Obligations',
                    Particulars__c = 'Obligations Total',
                    ParentorChild__c = 'Parent',
                    Name = 'Obligations Total'
                ));
            }
            if (!merchantParentIds.containsKey('Sailing Period')) {
                toInsert.add(new Income_Assessment__c(
                    RecordTypeId = merchantNavyRecordId,
                    Applicant__c  = appId,
                    Loan_Application__c = loanId,
                    ParentorChild__c = 'Parent',
                    Name = 'Sailing Period Total',
                    Type_of_Income_Assesment__c = 'Sailings',
                    Is_Default_Record__c = true
                ));
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }

        Map<Id, Map<String, Id>> parentMap = new Map<Id, Map<String, Id>>();
        for (Income_Assessment__c rec : [SELECT Id, Applicant__c, Type_of_Income_Assesment__c, Is_Default_Record__c FROM Income_Assessment__c WHERE RecordTypeId = :merchantNavyRecordId
                                            AND Loan_Application__c = :loanId AND ParentorChild__c = 'Parent' AND Applicant__c IN :applicantIds]) {
            if (!parentMap.containsKey(rec.Applicant__c)) {
                parentMap.put(rec.Applicant__c, new Map<String, Id>());
            }
            parentMap.get(rec.Applicant__c).put(rec.Type_of_Income_Assesment__c, rec.Id);
        }

        List<Income_Assessment__c> childrenToUpdate = new List<Income_Assessment__c>();
        for (Id appId : newChildrenMap.keySet()) {
            for (Income_Assessment__c child : newChildrenMap.get(appId)) {
                if (parentMap.containsKey(appId)) {
                    Id pId = parentMap.get(appId).get(child.Type_of_Income_Assesment__c);
                    if (pId != null) {
                        child.Parent__c = pId;
                        childrenToUpdate.add(child);
                    }
                }
            }
        }
        if (!childrenToUpdate.isEmpty()) {
            update childrenToUpdate;
        }

        List<Income_Assessment__c> parentsToUpdate = new List<Income_Assessment__c>();
        AggregateResult[] rollups = [SELECT Parent__c pId, SUM(Amount_in_Foreign__c) totalForeign, SUM(Amount_in_INR__c) totalINR
                                        FROM Income_Assessment__c WHERE RecordTypeId = :merchantNavyRecordId AND Loan_Application__c = :loanId
                                        AND ParentorChild__c = 'Child' AND Applicant__c IN :applicantIds GROUP BY Parent__c];
        for (AggregateResult ar : rollups) {
            Id pid = (Id)ar.get('pId');
            parentsToUpdate.add(new Income_Assessment__c(
                Id = pid,
                Amount_in_Foreign__c = (Decimal)ar.get('totalForeign'),
                Amount_in_INR__c     = (Decimal)ar.get('totalINR'),
                Exchange_Rate__c     = null
            ));
        }
        if (!parentsToUpdate.isEmpty()) {
            update parentsToUpdate;
        }
        for (Id appId : applicantIds) {
            for (Income_Assessment__c r : [SELECT Id, Name, Applicant__r.Applicant_Name__c, Type_of_Income_Assesment__c, Particulars__c, Amount_in_Foreign__c, Exchange_Rate__c,
                                           Amount_in_INR__c, ParentorChild__c, Parent__c, Is_Default_Record__c,Minimum_Income_Norms_Met__c,Foreign_currency_in_which_salary_earned__c,
                                           Name_of_the_country_NRI_is_working_on__c,Sailing_From__c,Sailing_To__c,Monthly_Gross_Remuneration__c,Less_Monthly_Deductions__c,
                                           Monthly_Net_Remuneration__c,Number_of_Days__c,Total_Sailing_Days_In_Two_Years__c,Average_Sailing_Days_Monthly__c,Average_Salary_per_month__c
                                           FROM Income_Assessment__c 
                                           WHERE RecordTypeId = :merchantNavyRecordId 
                                           AND Loan_Application__c = :loanId AND Applicant__c = :appId]) {
                IncomeAssessmentWrapper w = new IncomeAssessmentWrapper();
                w.applicantId = appId;
                w.applicantName = r.Applicant__r.Applicant_Name__c;
                w.incomeAssessmentId = r.Id;
                w.incomeAssesmentName = r.Name;
                w.typeOfAssessment = r.Type_of_Income_Assesment__c;
                w.foreignAmt = r.Amount_in_Foreign__c;
                w.exchangeRate = r.Exchange_Rate__c;
                w.inrAmt = r.Amount_in_INR__c;
                w.particular = r.Particulars__c;
                w.parentIncomeAssessmentId = r.Parent__c;
                w.parentOrChild = r.ParentorChild__c;
                w.isDefaultRecord = r.Is_Default_Record__c;
                w.fromDate = r.Sailing_From__c;
                w.toDate = r.Sailing_To__c;
                w.nriCountry = r.Name_of_the_country_NRI_is_working_on__c;
                w.nriCurrency = r.Foreign_currency_in_which_salary_earned__c;
                w.minIncomeNormsMet = r.Minimum_Income_Norms_Met__c;
                w.monthlyGrossRenumeration = r.Monthly_Gross_Remuneration__c;
                w.monthlyRenumerationDeductions = r.Less_Monthly_Deductions__c;
                w.monthlyNetRenumeration = r.Monthly_Net_Remuneration__c;
                w.diffInDays = r.Number_of_Days__c;
                w.totalSailInTwoYears = r.Total_Sailing_Days_In_Two_Years__c;
                w.averageMonthlySail = r.Average_Sailing_Days_Monthly__c;
                w.averageMonthlySalary = r.Average_Salary_per_month__c;
                wrapperList.add(w);
            }
        }
        return wrapperList;
    }
    
    @AuraEnabled
    public static void saveSailingIncomeAssessment(Map<String,Object> recordData) {
        if (recordData == null || String.isBlank((String)recordData.get('applicantId')) || String.isBlank((String)recordData.get('typeOfAssessment'))) {
            throw new AuraHandledException('Missing required parameters.');
        }
        Id applicantId = (Id)recordData.get('applicantId');
        String loanId  = (String)recordData.get('loanId');
        String typeVal = (String)recordData.get('typeOfAssessment');
        Id merchantNavyRecordId = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c', 'Merchant_Navy');
        Income_Assessment__c parentRec = [SELECT Id FROM Income_Assessment__c WHERE RecordTypeId = :merchantNavyRecordId AND Loan_Application__c = :loanId
                                            AND Applicant__c = :applicantId AND ParentorChild__c = 'Parent' AND Type_of_Income_Assesment__c = :typeVal LIMIT 1];
        if (parentRec != null) {
            Income_Assessment__c ia = new Income_Assessment__c();
            ia.Applicant__c = (String)recordData.get('applicantId');
            ia.Loan_Application__c = (String)recordData.get('loanId');
            ia.recordTypeId = merchantNavyRecordId;
            ia.Type_of_Income_Assesment__c = (String)recordData.get('typeOfAssessment');
            //ia.Particulars__c = (String)recordData.get('particular');
            ia.Name = 'Sailing Period';//(String)recordData.get('particular');
            ia.ParentorChild__c = 'Child';
            ia.Parent__c = parentRec.Id;
            if (recordData.containsKey('fromDate'))
                ia.Sailing_From__c = Date.valueOf(String.valueOf(recordData.get('fromDate')));
            if (recordData.containsKey('toDate'))
                ia.Sailing_To__c = Date.valueOf(String.valueOf(recordData.get('toDate')));
            if (recordData.containsKey('diffInDays'))
                ia.Number_of_Days__c = Decimal.valueOf(String.valueOf(recordData.get('diffInDays')));
            insert ia;
            
            AggregateResult agg = [SELECT SUM(Amount_in_Foreign__c) sumForeign, SUM(Amount_in_INR__c) sumINR, SUM(Number_of_Days__c) totalDays 
                                   FROM Income_Assessment__c 
                                   WHERE Parent__c = :parentRec.Id
                                   AND ParentorChild__c = 'Child'];
            //Query Parent to get Monthly net Renumeration
            Income_Assessment__c incomeAssessment = [SELECT Id,Monthly_Net_Remuneration__c 
                                                     FROM Income_Assessment__c 
                                                     WHERE Id =: parentRec.Id
                                                     AND ParentorChild__c = 'Parent' 
                                                     AND RecordType.Name = 'Merchant Navy'];
            update new Income_Assessment__c(
                Id = parentRec.Id,
                //Amount_in_Foreign__c = (Decimal)agg.get('sumForeign'),
                //Amount_in_INR__c     = (Decimal)agg.get('sumINR'),
                //Exchange_Rate__c     = null
                Total_Sailing_Days_In_Two_Years__c = (Decimal)agg.get('totalDays'),
                Average_Sailing_Days_Monthly__c = ((Decimal)agg.get('totalDays')/24).setScale(2, RoundingMode.HALF_UP),
                Average_Salary_per_month__c = ((incomeAssessment.Monthly_Net_Remuneration__c*(Decimal)agg.get('totalDays')/24)/30).setScale(2, RoundingMode.HALF_UP)
            );
        }
    }
    
    @AuraEnabled
    public static void updateSailingDates(Id recordId, string dateType, string dateValue, decimal diffDays) {
        system.debug('>>>>>>>>');
        if(dateType == 'fromDate') {
         Income_Assessment__c rec = new Income_Assessment__c(
            Id = recordId,
            Sailing_From__c = date.valueOf(dateValue),
            Number_of_Days__c = diffDays//Decimal.valueOf(String.valueOf(diffDays))
        );
        update rec;   
        }
        else if(dateType == 'toDate') {
            Income_Assessment__c rec = new Income_Assessment__c(
            Id = recordId,
            Sailing_To__c = date.valueOf(dateValue),
            Number_of_Days__c = diffDays//Decimal.valueOf(String.valueOf(recordData.get('diffInDays')))
        );
        update rec; 
        }
        
        Income_Assessment__c child = [
            SELECT Parent__c
            FROM Income_Assessment__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        if (child.Parent__c != null) {
            AggregateResult agg = [SELECT SUM(Amount_in_Foreign__c) sumForeign, SUM(Amount_in_INR__c) sumINR, SUM(Number_of_Days__c) totalDays 
                                   FROM Income_Assessment__c
                                   WHERE Parent__c = :child.Parent__c 
                                   AND ParentorChild__c = 'Child'];
            //Query Parent to get Monthly net Renumeration
            Income_Assessment__c incomeAssessment = [SELECT Id,Monthly_Net_Remuneration__c 
                                                     FROM Income_Assessment__c 
                                                     WHERE Id =: child.Parent__c 
                                                     AND ParentorChild__c = 'Parent' 
                                                     AND RecordType.Name = 'Merchant Navy'];
            system.debug('incomeAssessment.Monthly_Net_Remuneration__c>>> '+incomeAssessment.Monthly_Net_Remuneration__c);
            List<Income_Assessment__c> updateIncomeAssessmentList = new List<Income_Assessment__c>();
            if(incomeAssessment.Monthly_Net_Remuneration__c != null) {
            	Income_Assessment__c inc = new Income_Assessment__c();
                inc.Id = child.Parent__c;
                if((Decimal)agg.get('totalDays') != null) {
                    inc.Total_Sailing_Days_In_Two_Years__c = (Decimal)agg.get('totalDays');
                    inc.Average_Sailing_Days_Monthly__c = ((Decimal)agg.get('totalDays')/24).setScale(2, RoundingMode.HALF_UP);
                    inc.Average_Salary_per_month__c = ((incomeAssessment.Monthly_Net_Remuneration__c*(Decimal)agg.get('totalDays')/24)/30).setScale(2, RoundingMode.HALF_UP);
                }
                updateIncomeAssessmentList.add(inc);
            }
            if(updateIncomeAssessmentList.size()>0) {
                update updateIncomeAssessmentList;
            }
        }
    }
    
    @AuraEnabled
    public static void updateParentSailing(Id recordId, string nriCountry, string nriCurrency, string minIncomeNormsMet, 
                                           Decimal monthlyGrossRenumeration, Decimal monthlyRenumerationDeductions, Decimal monthlyNetRenumeration) {
        system.debug('monthlyGrossRenumeration>>>>>>>>'+monthlyGrossRenumeration);
        system.debug('monthlyRenumerationDeductions>>>>>>>>'+monthlyRenumerationDeductions);
        system.debug('monthlyNetRenumeration>>>>>>>>'+monthlyNetRenumeration);
        List<Income_Assessment__c> updateAssessmentList = new List<Income_Assessment__c>();                                       
        // Get existing Parent record to check the current summation values
        List<Income_Assessment__c> incomeAssessmentParent = [SELECT Id,Monthly_Net_Remuneration__c,Total_Sailing_Days_In_Two_Years__c,Average_Sailing_Days_Monthly__c,
                                                               Average_Salary_per_month__c,Number_of_Days__c 
                                                         	  FROM Income_Assessment__c 
                                                         	  WHERE Id =: recordId 
                                                         	  AND ParentorChild__c = 'Parent' 
                                                         	  AND RecordType.Name = 'Merchant Navy'];
                                               
        system.debug('>>>>>>>>>>incomeAssessmentParent>> '+incomeAssessmentParent);
        system.debug('NNNNNNNNNNNNNNNN>>> '+incomeAssessmentParent[0].Average_Sailing_Days_Monthly__c);
        if(incomeAssessmentParent.size() >0) {                                      
        	Income_Assessment__c rec = new Income_Assessment__c();
                rec.Id = recordId;
                rec.Name_of_the_country_NRI_is_working_on__c = nriCountry;
                rec.Foreign_currency_in_which_salary_earned__c = nriCurrency;
                rec.Minimum_Income_Norms_Met__c = minIncomeNormsMet;
                rec.Monthly_Gross_Remuneration__c = monthlyGrossRenumeration;
                rec.Less_Monthly_Deductions__c = monthlyRenumerationDeductions;
                rec.Monthly_Net_Remuneration__c = monthlyNetRenumeration;
            	if(incomeAssessmentParent[0].Average_Sailing_Days_Monthly__c != null && incomeAssessmentParent[0].Average_Sailing_Days_Monthly__c != 0) {
                	rec.Average_Salary_per_month__c = ((monthlyNetRenumeration*incomeAssessmentParent[0].Average_Sailing_Days_Monthly__c)/30).setScale(2, RoundingMode.HALF_UP);
            	}
                updateAssessmentList.add(rec);
        }
        
       	if(updateAssessmentList.size()>0) {
        	update updateAssessmentList;
        }
        /*
        Income_Assessment__c child = [
            SELECT Parent__c
            FROM Income_Assessment__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        if (child.Parent__c != null) {
            AggregateResult agg = [SELECT SUM(Amount_in_Foreign__c) sumForeign, SUM(Amount_in_INR__c) sumINR 
                                   FROM Income_Assessment__c
                                   WHERE Parent__c = :child.Parent__c 
                                   AND ParentorChild__c = 'Child'];
            update new Income_Assessment__c(
                Id = child.Parent__c,
                Amount_in_Foreign__c = (Decimal)agg.get('sumForeign'),
                Amount_in_INR__c     = (Decimal)agg.get('sumINR'),
                Exchange_Rate__c     = null
            );
        }
		*/
    }
    
    @AuraEnabled
    public static void deleteIncomeAssessment(String recordId) {
        Decimal deleteDays = 0;
        //try {
        	List<Income_Assessment__c> parentListToUpdate = new List<Income_Assessment__c>();
            List<Income_Assessment__c> incomeAssessments = [SELECT Id,Parent__c,Number_of_Days__c 
                                                            FROM Income_Assessment__c 
                                                            WHERE Id =: recordId 
                                                            AND RecordType.Name = 'Merchant Navy' LIMIT 1];
            if(!incomeAssessments.isEmpty()){
                //Starts HERE
                deleteDays = incomeAssessments[0].Number_of_Days__c;
                //Query Parent to get Monthly net Renumeration
            	Income_Assessment__c incomeAssessmentParent = [SELECT Id,Monthly_Net_Remuneration__c,Total_Sailing_Days_In_Two_Years__c,Average_Sailing_Days_Monthly__c,
                                                               Average_Salary_per_month__c,Number_of_Days__c 
                                                         	  FROM Income_Assessment__c 
                                                         	  WHERE Id =: incomeAssessments[0].Parent__c 
                                                         	  AND ParentorChild__c = 'Parent' 
                                                         	  AND RecordType.Name = 'Merchant Navy'];
                
                incomeAssessmentParent.Total_Sailing_Days_In_Two_Years__c = incomeAssessmentParent.Total_Sailing_Days_In_Two_Years__c - deleteDays;
                incomeAssessmentParent.Average_Sailing_Days_Monthly__c = ((incomeAssessmentParent.Total_Sailing_Days_In_Two_Years__c)/24).setScale(2, RoundingMode.HALF_UP);
                incomeAssessmentParent.Average_Salary_per_month__c = ((incomeAssessmentParent.Monthly_Net_Remuneration__c*incomeAssessmentParent.Average_Sailing_Days_Monthly__c)/30).setScale(2, RoundingMode.HALF_UP);
                parentListToUpdate.add(incomeAssessmentParent);
                //Ends HERE
                delete incomeAssessments;
                if(!parentListToUpdate.isEmpty()) {
                    update parentListToUpdate;
                }
            }
        //} catch (Exception e) {
        //    throw new AuraHandledException('Error deleting address: ' + e.getMessage());
       // }
    }

    @AuraEnabled
    public static void deleteIncomeExpences(String loanId, List<Id> applicantIds){
        try {
            List<Income_Assessment__c> incomeAssessments = [SELECT Id FROM Income_Assessment__c WHERE Applicant__c IN: applicantIds AND Loan_Application__c =: loanId AND RecordType.Name = 'Merchant Navy'];
            if(!incomeAssessments.isEmpty()){
                delete incomeAssessments;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void deleteIncomeOBligation(String recordId) {
        try {
            // Income_Assessment__c incomeAsses = new Income_Assessment__c();
            // incomeAsses.Id = recordId;
            // delete incomeAsses;
            List<Income_Assessment__c> incomeAssessments = [SELECT Id FROM Income_Assessment__c WHERE Id =: recordId AND RecordType.Name = 'Merchant Navy' LIMIT 1];
            if(!incomeAssessments.isEmpty()){
                delete incomeAssessments;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting address: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void saveNRIIncomeExpense(Map<String,Object> recordData) {
        if (recordData == null || String.isBlank((String)recordData.get('applicantId')) || String.isBlank((String)recordData.get('typeOfAssessment'))) {
            throw new AuraHandledException('Missing required parameters.');
        }
        Id applicantId = (Id)recordData.get('applicantId');
        String loanId  = (String)recordData.get('loanId');
        String typeVal = (String)recordData.get('typeOfAssessment');
        Id salariedNRIRecordId = Utility.getRecordTypeIdByDeveloperName('Income_Assessment__c', 'Merchant_Navy');
        Income_Assessment__c parentRec = [SELECT Id FROM Income_Assessment__c WHERE RecordTypeId = :salariedNRIRecordId AND Loan_Application__c = :loanId
                                            AND Applicant__c = :applicantId AND ParentorChild__c = 'Parent' AND Type_of_Income_Assesment__c = :typeVal LIMIT 1];
        if (parentRec != null) {
            Income_Assessment__c ia = new Income_Assessment__c();
            ia.Applicant__c = (String)recordData.get('applicantId');
            ia.Loan_Application__c = (String)recordData.get('loanId');
            ia.recordTypeId = salariedNRIRecordId;
            ia.Type_of_Income_Assesment__c = (String)recordData.get('typeOfAssessment');
            ia.Particulars__c = (String)recordData.get('particular');
            ia.Name = (String)recordData.get('particular');
            ia.ParentorChild__c = 'Child';
            ia.Parent__c = parentRec.Id;
            if (recordData.containsKey('foreignAmt'))
                ia.Amount_in_Foreign__c = Decimal.valueOf(String.valueOf(recordData.get('foreignAmt')));
            if (recordData.containsKey('exchangeRate'))
                ia.Exchange_Rate__c = Decimal.valueOf(String.valueOf(recordData.get('exchangeRate')));
            if (recordData.containsKey('inrAmt'))
                ia.Amount_in_INR__c = Decimal.valueOf(String.valueOf(recordData.get('inrAmt')));
            insert ia;
            
            AggregateResult agg = [SELECT SUM(Amount_in_Foreign__c) sumForeign, SUM(Amount_in_INR__c) sumINR FROM Income_Assessment__c WHERE Parent__c = :parentRec.Id
                                    AND ParentorChild__c = 'Child'];
            update new Income_Assessment__c(
                Id = parentRec.Id,
                Amount_in_Foreign__c = (Decimal)agg.get('sumForeign'),
                Amount_in_INR__c     = (Decimal)agg.get('sumINR'),
                Exchange_Rate__c     = null
            );
        }
    }
    
    @AuraEnabled
    public static void updateIncomeAssessment(Id recordId, Decimal foreignAmt, Decimal exchangeRate, Decimal inrAmt) {
        Income_Assessment__c rec = new Income_Assessment__c(
            Id = recordId,
            Amount_in_Foreign__c = foreignAmt,
            Exchange_Rate__c = exchangeRate,
            Amount_in_INR__c = inrAmt
        );
        update rec;
        Income_Assessment__c child = [
            SELECT Parent__c
            FROM Income_Assessment__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        if (child.Parent__c != null) {
            AggregateResult agg = [SELECT SUM(Amount_in_Foreign__c) sumForeign, SUM(Amount_in_INR__c) sumINR FROM Income_Assessment__c
                                    WHERE Parent__c = :child.Parent__c AND ParentorChild__c = 'Child'];
            update new Income_Assessment__c(
                Id = child.Parent__c,
                Amount_in_Foreign__c = (Decimal)agg.get('sumForeign'),
                Amount_in_INR__c     = (Decimal)agg.get('sumINR'),
                Exchange_Rate__c     = null
            );
        }
    }
        
    public class IncomeAssessmentWrapper {
        @AuraEnabled public Id applicantId { get; set; }
        @AuraEnabled public Id incomeAssessmentId { get; set; }
        @AuraEnabled public Id  parentIncomeAssessmentId{ get; set; }
        @AuraEnabled public String incomeAssesmentName { get; set; }
        @AuraEnabled public String typeOfAssessment { get; set; }
        @AuraEnabled public String particular { get; set; }
        @AuraEnabled public String applicantName {get; set;}
        @AuraEnabled public Decimal foreignAmt {get; set;}
        @AuraEnabled public Decimal exchangeRate {get; set;}
        @AuraEnabled public Decimal inrAmt {get; set;}
        @AuraEnabled public String parentOrChild {get; set;}
        @AuraEnabled public Boolean isDefaultRecord {get; set;}
        @AuraEnabled public Date fromDate {get; set;}
    	@AuraEnabled public Date toDate {get; set;}
        @AuraEnabled public string nriCountry{get; set;}
        @AuraEnabled public string nriCurrency	{get; set;}
        @AuraEnabled public string minIncomeNormsMet {get; set;}
        @AuraEnabled public Decimal monthlyGrossRenumeration {get; set;}
        @AuraEnabled public Decimal monthlyRenumerationDeductions {get; set;}
        @AuraEnabled public Decimal monthlyNetRenumeration {get; set;}
        @AuraEnabled public Decimal diffInDays {get; set;}
        @AuraEnabled public Decimal totalSailInTwoYears {get; set;}
        @AuraEnabled public Decimal averageMonthlySail {get; set;}
        @AuraEnabled public Decimal averageMonthlySalary {get; set;}
    }
}