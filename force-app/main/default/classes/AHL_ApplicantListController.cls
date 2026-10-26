public with sharing class AHL_ApplicantListController {
    @AuraEnabled(cacheable=true)
    public static List<Application_Applicant__c> fetchApplicantsByProfile(Id loanAppId) {
        List<String> profiles = new List<String>{
            'SEP',
            'Salaried',
            'Salaried Indian',
            'Salaried NRI'
        };
        
        return [
            SELECT
                Id,
                Name,
                Applicant_Type__c,
                Qualification__c,
                Employer_Name__r.Employer_Name__c,
                Designation__c
            FROM Application_Applicant__c
            WHERE Loan_Application__c = :loanAppId
              AND Customer_Profile__c IN :profiles AND (Applicant_Type__c = 'Primary Applicant' or Applicant_Type__c = 'Co Applicant' )
            AND Is_Financial_applicant__c = 'Yes'
            ORDER BY Name
        ];
    }

    @AuraEnabled(cacheable=true)
  public static List<Application_Applicant__c> getSepSenpApplicants(Id loanApplicationId) {
    List<String> profiles = new List<String>{ 'SENP' };
    return [
      SELECT
        Id,
        Business_Entity_Name__c,
        Applicant_Type__c,
        Customer_Profile__c,
        Sector__c, Nature_of_Business__c, Business_Vintage__c
      FROM Application_Applicant__c
      WHERE Loan_Application__c = :loanApplicationId
        AND Customer_Profile__c IN :profiles AND (Applicant_Type__c = 'Primary Applicant' or Applicant_Type__c = 'Co Applicant' )
            AND Is_Financial_applicant__c = 'Yes'
      ORDER BY Name
    ];
  }

  @AuraEnabled(cacheable=true)
    public static List<Application_Applicant__c> getSalariedApplicants(Id loanAppId) {
        return [
            SELECT 
                Id,
                Name,
                Monthly_Gross_Salary__c,
        Monthly_Net_Salary__c,
        Variable_Income__c,
        Other_Income__c,
        Rent__c,
        Interest__c,
        Total_Income__c,
        Remarks__c
                
            FROM Application_Applicant__c
            WHERE Loan_Application__c = :loanAppId
              AND Customer_Profile__c IN ('SEP','Salaried','Salaried Indian','Salaried NRI') AND (Applicant_Type__c = 'Primary Applicant' or Applicant_Type__c = 'Co Applicant' )
            AND Is_Financial_applicant__c = 'Yes'
        ];
    }


    @AuraEnabled(cacheable=true)
    public static List<Application_Applicant__c> getSelfEmployedApplicants(Id loanAppId) {
        return [
            SELECT
                Id,
                Name,
                Annual_Sales__c,
                Annual_Expenses__c,
                Annual_Operating_Income__c,
                Annual_Net_Earnings__c,
                Annual_Other_Income__c,
                Annual_Rent__c,
                Annual_Interest__c,
                Annual_Total_Income__c,
                
                /* Monthly */
                Monthly_Sales__c,
                Monthly_Expenses__c,
                Monthly_Operating_Income__c,
                Monthly_Net_Earnings__c,
                Monthly_Other_Income__c,
                Monthly_Rent__c,
                Monthly_Interest__c,
                Monthly_Total_Income__c
                
            FROM Application_Applicant__c
            WHERE Loan_Application__c = :loanAppId
              AND Customer_Profile__c IN ('SENP') AND (Applicant_Type__c = 'Primary Applicant' or Applicant_Type__c = 'Co Applicant' )
            AND Is_Financial_applicant__c = 'Yes'
        ];
    }

    @AuraEnabled
    public static Decimal recalcPY1(Id opportunityId) {
        if (opportunityId == null) {
            throw new AuraHandledException('opportunityId is required');
        }

        // Pull all applicants tied to this loan application (Opportunity)
        List<Application_Applicant__c> apps = [SELECT Id, Customer_Type__c, Annual_Total_Income__c, Monthly_Gross_Salary__c 
                                               FROM Application_Applicant__c WHERE Loan_Application__c = :opportunityId AND Customer_Profile__c = 'SENP'];

        Decimal sumIncome = 0;
        for (Application_Applicant__c a : apps) {
            if(a.Customer_Type__c == 'Individual' && a.Monthly_Gross_Salary__c != null && a.Monthly_Gross_Salary__c > 0) {
                sumIncome = sumIncome + (a.Monthly_Gross_Salary__c * 12);
            }else {
                if(a.Annual_Total_Income__c != null && a.Annual_Total_Income__c > 0) {
                    sumIncome = sumIncome + a.Annual_Total_Income__c;
                }
            }
        }

        // Persist to Opportunity.Amount_of_Cash_Surplus_for_PY1_Rs__c
        Opportunity o = new Opportunity(
            Id = opportunityId,
            Amount_of_Cash_Surplus_for_PY1_Rs__c = sumIncome
        );
        update o;

        return sumIncome;
    }
    
    @AuraEnabled
    public static List<Application_Verification__c> getAssests(Id loanAppId) {
        return [SELECT Id,RecordType.name,Type_of_Asset__c,Year_of_Purchase__c,Name_of_the_Asset_Owner__c,Amount_of_Investment__c,Proof__c
                FROM Application_Verification__c  WHERE Loan_Application__c = :loanAppId and RecordType.name = 'Asset'];
    }
    @AuraEnabled
    public static List<Application_Verification__c> getPDs(Id loanAppId) {
        return     [SELECT Id,RecordType.name,Applicant__r.Applicant_Name__c,Applicant__r.Applicant_Type__c,Personal_Discussion_Type__c,
                    Additional_Note__c,Additional_Details_2__c,Crime_Check_Status__c FROM Application_Verification__c  WHERE
                    Loan_Application__c =:loanAppId and RecordType.name = 'Personal Discussion AHL'];
    }

    @AuraEnabled
    public static List<ApplicationWrap> getApplicants(String recordId) {
        List<ApplicationWrap> applicantsMap = new List<ApplicationWrap>();
        Map<String,String> inputMapUtility = new Map<String,String>();
        Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
        Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
        if(!isHlRelated){
            Set<String> applicationOption = new Set<String>();
            List<Application_Applicant__c> lstApplicants = [SELECT id,Applicant_Type__c,name,Customer_Type__c,Customer_Profile__c,
                                                            Loan_Application__r.Income_Method__c,KYC_Risk_Categorisation_Category__c FROM 
                                                            Application_Applicant__c WHERE Loan_Application__c =:recordId AND 
                                                            (Applicant_Type__c = 'Primary Applicant' or Applicant_Type__c = 'Co Applicant' or 
                                                             Applicant_Type__c = 'Guarantor')];
            
            if(lstApplicants.size() > 0) {
                for(Application_Applicant__c iterApp : lstApplicants) {
                    ApplicationWrap temObj = new ApplicationWrap();
                    temObj.recId = iterApp.id;
                    temObj.appName = iterApp.name+' ('+iterApp.Applicant_Type__c+')';
                    temObj.selectedValue = iterApp.KYC_Risk_Categorisation_Category__c;
                    applicantsMap.add(temObj);
                }
            }
        }else {
            Set<String> applicationOption = new Set<String>();
            List<Application_Applicant__c> lstApplicants = [SELECT id,Applicant_Type__c,name,Customer_Type__c,Customer_Profile__c,
                                                            Loan_Application__r.Income_Method__c,KYC_Risk_Categorisation_Category__c FROM 
                                                            Application_Applicant__c WHERE Loan_Application__c =:recordId AND 
                                                            (Applicant_Type__c = 'Primary Applicant' or Applicant_Type__c = 'Co Applicant') AND 
                                                           Is_Financial_applicant__c = 'Yes'];
            
            if(lstApplicants.size() > 0) {
                for(Application_Applicant__c iterApp : lstApplicants) {
                    ApplicationWrap temObj = new ApplicationWrap();
                    temObj.recId = iterApp.id;
                    temObj.appName = iterApp.name+' ('+iterApp.Applicant_Type__c+')';
                    temObj.selectedValue = iterApp.KYC_Risk_Categorisation_Category__c;
                    applicantsMap.add(temObj);
                }
            }
        }
        
        System.debug('applicantsMap '+applicantsMap);
        return applicantsMap;
    }

    @AuraEnabled
    public static List<ApplicationWrap> getApplicantsPEP(String recordId) {
        List<ApplicationWrap> applicantsMap = new List<ApplicationWrap>();
        
        Map<String,String> inputMapUtility = new Map<String,String>();
        Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
        Boolean isHlRelated =isHLRelatedFinal.isHLRelated;

        if(!isHlRelated){
            Set<String> applicationOption = new Set<String>();
            List<Application_Applicant__c> lstApplicants = [SELECT id,Applicant_Type__c,name,Customer_Type__c,Customer_Profile__c,
                                                            Loan_Application__r.Income_Method__c,PEP__c FROM 
                                                            Application_Applicant__c WHERE Loan_Application__c =:recordId AND 
                                                        (Applicant_Type__c = 'Primary Applicant' or Applicant_Type__c = 'Co Applicant' or 
                                                        Applicant_Type__c = 'Guarantor')];
            
            if(lstApplicants.size() > 0) {
                for(Application_Applicant__c iterApp : lstApplicants) {
                    ApplicationWrap temObj = new ApplicationWrap();
                    temObj.recId = iterApp.id;
                    temObj.appName = iterApp.name+' ('+iterApp.Applicant_Type__c+')';
                    temObj.selectedValue = iterApp.PEP__c;
                    applicantsMap.add(temObj);
                }
            }
        }
        else if(isHlRelated){
            Set<String> applicationOption = new Set<String>();
            List<Application_Applicant__c> lstApplicants = [SELECT id,Applicant_Type__c,name,Customer_Type__c,Customer_Profile__c,
                                                            Loan_Application__r.Income_Method__c,PEP__c FROM 
                                                            Application_Applicant__c WHERE Loan_Application__c =:recordId AND 
                                                        (Applicant_Type__c = 'Primary Applicant' or Applicant_Type__c = 'Co Applicant' )];
            
            if(lstApplicants.size() > 0) {
                for(Application_Applicant__c iterApp : lstApplicants) {
                    ApplicationWrap temObj = new ApplicationWrap();
                    temObj.recId = iterApp.id;
                    temObj.appName = iterApp.name+' ('+iterApp.Applicant_Type__c+')';
                    temObj.selectedValue = iterApp.PEP__c;
                    applicantsMap.add(temObj);
                }
            }
        }
        
        System.debug('applicantsMap '+applicantsMap);
        return applicantsMap;
    }
    public class ApplicationWrap {
        @AuraEnabled public String recId;
        @AuraEnabled public String appName;
        @AuraEnabled public String selectedValue;
    }

}