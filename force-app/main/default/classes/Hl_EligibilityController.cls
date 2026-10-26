public class Hl_EligibilityController {

    @AuraEnabled
    public static List<ApplicationWrap> getApplicants(String recordId) {
        List<ApplicationWrap> applicantsMap = new List<ApplicationWrap>();
        ApplicationWrap onj = new ApplicationWrap();
        onj.recId = recordId;
        onj.appName = 'Loan Application';
        
        Boolean isAdded = false;
        Set<String> applicationOption = new Set<String>();
        List<Application_Applicant__c> lstApplicants = [SELECT id,Applicant_Type__c,name,Customer_Type__c,Customer_Profile__c,
                                                        Loan_Application__r.Income_Method__c,Income_Method__c FROM 
                                                        Application_Applicant__c WHERE Loan_Application__c =:recordId AND 
                                                       (Applicant_Type__c = 'Primary Applicant' or Applicant_Type__c = 'Co Applicant' ) AND 
                                                       Is_Financial_applicant__c = 'Yes'];
        List<PLF_Master__c> masterLst1 = [SELECT id,Description__c,FICO_Code__c,Applicant_Type_SF__c,Customer_Type__c
                                          FROM PLF_Master__c WHERE  Applicant_Type_SF__c != null
                                          AND  Master_Type__c = 'Program types' AND Customer_Type__c != null AND isActive__c = true] ;
        if (!lstApplicants.isEmpty()) {
            for (Application_Applicant__c iterApp : lstApplicants) {

                List<OptionWrapper> optionsLst = new List<OptionWrapper>();
                List<OptionWrapper> appOptionsLst = new List<OptionWrapper>();

                ApplicationWrap temObj = new ApplicationWrap();
                temObj.recId = iterApp.Id;
                temObj.appName = iterApp.Name + ' (' + iterApp.Applicant_Type__c + ')';

                for (PLF_Master__c iterPlr : masterLst1) {

                    if (!applicationOption.contains(iterPlr.Description__c) && !isAdded) {
                        applicationOption.add(iterPlr.Description__c);

                        appOptionsLst.add(new OptionWrapper(
                            iterPlr.Description__c,
                            iterPlr.Description__c
                        ));
                    }

                    if (iterPlr.Applicant_Type_SF__c == iterApp.Customer_Type__c &&
                        iterPlr.Customer_Type__c == iterApp.Customer_Profile__c) {

                        optionsLst.add(new OptionWrapper(
                            iterPlr.Description__c,
                            iterPlr.Description__c
                        ));
                    }
                }

                if (iterApp.Income_Method__c == 'Assessed Income') {
                    Boolean exists = false;

                    for (OptionWrapper opt : optionsLst) {
                        if (opt.value == 'Assessed Income') {
                            exists = true;
                            break;
                        }
                    }

                    if (!exists) {
                        optionsLst.add(new OptionWrapper('Assessed Income', 'Assessed Income'));
                    }
                }

                temObj.selectedValue = iterApp.Income_Method__c;

                if (!isAdded) {

                    String appVal = iterApp.Loan_Application__r.Income_Method__c;

                    if (appVal == 'Assessed Income') {
                        Boolean exists = false;

                        for (OptionWrapper opt : appOptionsLst) {
                            if (opt.value == 'Assessed Income') {
                                exists = true;
                                break;
                            }
                        }

                        if (!exists) {
                            appOptionsLst.add(new OptionWrapper('Assessed Income', 'Assessed Income'));
                        }
                    }

                    onj.selectedValue = appVal;
                    onj.options = appOptionsLst;

                    isAdded = true;
                    applicantsMap.add(onj);
                }

                temObj.options = optionsLst;
                applicantsMap.add(temObj);
            }
        }
        System.debug('applicantsMap '+applicantsMap);
        return applicantsMap;
    }
    
    
    public class ApplicationWrap {
        @AuraEnabled public String recId;
        @AuraEnabled public String appName;
        @AuraEnabled public List<OptionWrapper> options;
        @AuraEnabled public String selectedValue;
    }
    public class OptionWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        
        public OptionWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}