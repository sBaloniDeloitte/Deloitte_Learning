/**
* @File Name : Sales_LoanLoginDetailsController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : March 7, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | March 7, 2025 |   | Initial Version
**/

public class Sales_LoanLoginDetailsController {
   @AuraEnabled
    public static List<SubStageWrapper> getSubStageList(String loanId, String applicableStage) {
        List<SubStageWrapper> subStageList = new List<SubStageWrapper>();
        Set<String> addedSubStages = new Set<String>(); 
        // Fetch screens based on the selected applicable stage
        List<Screen_Field__c> screenDetails = [
            SELECT Id, Master_Screen_Name__c, Applicable_Login_Stage__c,Screen_Sequence__c
            FROM Screen_Field__c
            WHERE Form_Name__c = 'Login Checklist'
                AND Is_Screen_Active__c = TRUE
                AND Applicable_Login_Stage__c = :applicableStage
            ORDER BY Screen_Sequence__c ASC
        ];

        for (Screen_Field__c screen : screenDetails) {
            SubStageWrapper subWrap = new SubStageWrapper();
            if (screen.Master_Screen_Name__c!= null && !addedSubStages.contains(screen.Master_Screen_Name__c)) {
            subWrap.name = screen.Master_Screen_Name__c;
            subWrap.isCompleted =false; // Assuming this field tracks completion status
            subWrap.sequence = String.valueof(screen.Screen_Sequence__c);
            subStageList.add(subWrap);
            addedSubStages.add(screen.Master_Screen_Name__c);
            }
        }

        System.debug(subStageList);
        return subStageList;
    }

	@AuraEnabled
    public static List<ApplicantWrapper> getPrimaryApplicantList(String loanId, String applicableStage) {
    try {
        List<ApplicantWrapper> applicantWrapperList = new List<ApplicantWrapper>();
        
        // Fetch applicants for the given LoanId
        List<Application_Applicant__c> appList = [
            SELECT Id, Applicant_Name__c, Applicant_Type__c,Pan_OCR_Confirmed__c 
            FROM Application_Applicant__c 
            WHERE Loan_Application__c = :loanId  AND Applicant_Type__c = 'Primary Applicant'
        ];
        System.debug('applicableStage'+applicableStage);
        List<Screen_Field__c> screenDetails = [
            SELECT Id, Master_Screen_Name__c, Applicable_Login_Stage__c, Screen_Sequence__c
            FROM Screen_Field__c
            WHERE Form_Name__c = 'Login Checklist'
                AND Is_Screen_Active__c = TRUE
                AND Applicable_Login_Stage__c = :applicableStage
            ORDER BY Screen_Sequence__c ASC
        ];

        for (Application_Applicant__c app : appList) {
            ApplicantWrapper iterapp = new ApplicantWrapper();
            iterapp.name = app.Applicant_Name__c;
            iterapp.sequence = appList.size();
            iterapp.type = app.Applicant_Type__c;
            iterapp.applicantId = app.Id;
           

            // Fetch sub-stages for this applicant based on the given stage
            List<SubStageWrapper> subStageList = new List<SubStageWrapper>();
            Set<String> addedSubStages = new Set<String>();

           

            for (Screen_Field__c screen : screenDetails) {
                if (screen.Master_Screen_Name__c != null && !addedSubStages.contains(screen.Master_Screen_Name__c)) {
                    SubStageWrapper subWrap = new SubStageWrapper();
                    subWrap.name = screen.Master_Screen_Name__c;
                    subWrap.isCompleted = false;
                    subWrap.sequence = String.valueOf(screen.Screen_Sequence__c);
                    if(app.Pan_OCR_Confirmed__c == false &&screen.Master_Screen_Name__c != 'PAN/Form 60 Details'){
                        subWrap.disableAccordian= true;
                    }
                    else{
                        subWrap.disableAccordian= false;
                    }
                    subWrap.isApplicantCmp = true;
                    subWrap.isConsent = false;
                    subWrap.isDeDupeScreen = false;
                    subWrap.isSwapApplicant = false;
                    subWrap.isBasicDetails = false;
                    subWrap.isPanValidation = false;
                    subWrap.isDocument = false;
                    String applicantScreenName = 'PAN/Form 60 Details';
                    String applicantScreenNameBasicDetail = 'Applicant\'s Basic Information';
                    subStageList.add(subWrap);
                    addedSubStages.add(screen.Master_Screen_Name__c);
                }
            }
            if (iterapp.stages == null) {
                iterapp.stages = new List<SubStageWrapper>();
            }
            iterapp.stages = subStageList;
            applicantWrapperList.add(iterapp);
            
        }
        
        return applicantWrapperList;

    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
  }

      @AuraEnabled
    public static String getNextScreenDetails(String currentAppSeq,String activeSectionName,String formIdentifier){
        try {
            String nextScreenName = '';
            Integer nextSequence = Integer.valueOf(currentAppSeq) + 1;

            List<Screen_Field__c> screenList = [Select id,Master_Screen_Sequence__c, Master_Screen_Name__c,Screen_Sequence__c, Screen_Name__c, Form_Name__c
                                                from Screen_Field__c where Form_Name__c   ='Loan Login Form' 
                                                and Is_Active__c =true and Is_Screen_Active__c = true
                                                and Screen_Sequence__c =: nextSequence];

            if(!screenList.isEmpty()){
                nextScreenName = screenList[0].Master_Screen_Name__c;
            }
            return nextScreenName;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class ApplicantWrapper {
        @AuraEnabled public String name;
        @AuraEnabled public String type;
        @AuraEnabled public Integer sequence;
        @AuraEnabled public String applicantId;
        @AuraEnabled public List <SubStageWrapper> stages;
        @AuraEnabled public String panNumber;
        @AuraEnabled public String panName;
        @AuraEnabled public String fathersName;
        @AuraEnabled public String dobORDoi;
        @AuraEnabled public boolean isOCRConfirmed;
        @AuraEnabled public String contentDocumentID;
        @AuraEnabled public Boolean reHitDeDupe;
        @AuraEnabled public Boolean isSwapApplicant;
    }
	    public class SubStageWrapper {
        @AuraEnabled public String name;
        @AuraEnabled public Boolean isCompleted;
        @AuraEnabled public String sequence;
        @AuraEnabled public Boolean isApplicantCmp;
        @AuraEnabled public Boolean isConsent;
        @AuraEnabled public Boolean isDeDupeScreen;
        @AuraEnabled public Boolean isBasicDetails;
        @AuraEnabled public Boolean isApplicantCmpActive;
        @AuraEnabled public Boolean isConsentActive;
        @AuraEnabled public Boolean isDeDupeScreenActive;
        @AuraEnabled public Boolean isBasicDetailsActive;
        @AuraEnabled public Boolean isSwapApplicant;
        @AuraEnabled public Boolean disableAccordian;
        @AuraEnabled public Boolean isPanValidation;
        @AuraEnabled public Boolean isDocument;
        @AuraEnabled public Boolean isBureau;
    }
}