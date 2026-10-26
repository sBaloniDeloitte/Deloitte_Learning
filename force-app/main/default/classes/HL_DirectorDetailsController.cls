/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : HL_DirectorDetailsController
 * Author          : <YourName>
 * Created Date    : Apr 16, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Apr 16, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Apr 16, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class HL_DirectorDetailsController {

    
    @AuraEnabled
    public static List<Company_Director_Details__c> fetchDirectorDetails(String loanId) {
        if (String.isBlank(loanId)) {
            throw new AuraHandledException('Loan Id cannot be empty or null');
        }
        
        try {
            return [
                SELECT Id, Loan_Application__c, Director_Name__c, Director_DIN_Number__c,
                    Percentage_of_Shareholding__c, Director_Designation__c,
                    Date_of_Appointment__c, Address_Section__c
                FROM Company_Director_Details__c
                WHERE Loan_Application__c = :loanId
            ];
            
        } catch (Exception e) {
            System.debug('Error in fetchDirectorDetails: ' + e.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 
                'fetchDirectorDetails', 'Company_Director_Details__c', loanId) });
            throw new AuraHandledException('Unable to fetch director details');
        }
    }


        @AuraEnabled
        public static String saveDirectorDetails(Map<String, String> inputMap, String loanId) {
            String result = 'fail';
            try {
                Company_Director_Details__c dirDetails = new Company_Director_Details__c();
                dirDetails.put('Loan_Application__c', loanId);

                for (String fieldApiName : inputMap.keySet()) {
                    String value = inputMap.get(fieldApiName);

                    if (String.isNotBlank(value)) {
                        if (fieldApiName == 'Percentage_of_Shareholding__c') {
                            dirDetails.put(fieldApiName, Decimal.valueOf(value));
                        } else if (fieldApiName == 'Date_of_Appointment__c') {
                            dirDetails.put(fieldApiName, Date.valueOf(value));
                        } else {
                            dirDetails.put(fieldApiName, value);
                        }
                    }
                }

                insert dirDetails;
                result = 'success';
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error saving director details: '+ e);
                System.debug(LoggingLevel.ERROR, 'Error at line: '+ e.getLineNumber());
                throw new AuraHandledException('Error saving director details:: ' + e);
            }
            return result;
        }


        @AuraEnabled
        public static string deleteDirectorDetails( String refId){
            String result= 'success';
            try {
                List<Company_Director_Details__c> appList = [SELECT Id FROM Company_Director_Details__c WHERE Id = :refId];
                if(appList.size()>0){
                    delete appList;
                }
            } catch (Exception e) {
                result = e.getMessage();
                // throw new AuraHandledException(e.getMessage());
            }
            return result;
        }

        @AuraEnabled
        public static Boolean isDirectorDetailsApplicable(String loanId) {
            Boolean result = false;
            try {
                Application_Applicant__c primaryApplicantSector = [
                    SELECT Id, Customer_Type__c, Applicant_Type__c, Sector__c 
                    FROM Application_Applicant__c  
                    WHERE Loan_Application__c = :loanId 
                    AND Applicant_Type__c = :Constants.PRIMARY_APPLICANT
                    LIMIT 1
                ];

                List<String> sectorsToShowDirectorDetails = System.Label.Director_Details_Dependent_Sector_Values.split(',');

                if (primaryApplicantSector != null && sectorsToShowDirectorDetails.contains(primaryApplicantSector.Sector__c)) {
                    result = true;
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error in checking director details dependency: ' + e.getMessage());
                Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 
                    'isDirectorDetailsApplicable', 'Company_Director_Details__c', loanId) });
            }
            return result;
    }

    @AuraEnabled
    public static Boolean isDirectorDetailsPresent(String loanId) {
    
        try {
            List <Company_Director_Details__c> directorDetailsList = [
                SELECT Id
                FROM Company_Director_Details__c
                WHERE Loan_Application__c = :loanId
            ];

            return directorDetailsList.size() > 0;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in isDirectorDetailsPresent: ' + e.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 
                'isDirectorDetailsPresent', 'Company_Director_Details__c', loanId) });
                return false;
        }
    }

    @AuraEnabled
    public static Boolean updateDirectorDetails(Company_Director_Details__c directorRecord) {
        try {
            System.debug('Input Director Record to edit: '+ directorRecord);
            if (directorRecord == null || String.isBlank(directorRecord.Id)) {
                throw new AuraHandledException('Empty Director record provided for update');
            }

            update directorRecord;

            System.debug('Director record updated successfully: ' + directorRecord);
            return true;
        } catch (Exception e) {
            System.debug('Error updating director record: ' + e.getMessage());
            throw new AuraHandledException('Error updating director record: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static DirectorValidationResult validateDirectorDetailsForStage(String loanId, String currentStage) {
        DirectorValidationResult result = new DirectorValidationResult();
        result.isValid = true;
        result.errorMessage = '';

        try {
            Map<String, String> constants = Utility.getConstantsBasisNonStaticLabels('CreditStage,Credit_In_Progress_Stage_Value');
            String creditUnderwriting = constants.get('CreditStage');
            String creditInProgress = constants.get('Credit_In_Progress_Stage_Value');

            if (currentStage == creditUnderwriting || currentStage == creditInProgress) {
                Boolean isApplicable = isDirectorDetailsApplicable(loanId);

                if (isApplicable) {
                    Boolean isPresent = isDirectorDetailsPresent(loanId);

                    if (!isPresent) {
                        result.isValid = false;
                        result.errorMessage = System.Label.Director_Details_Missing_Error;
                    }
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in validateDirectorDetailsForStage: ' + e.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{
                Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(),
                    'validateDirectorDetailsForStage', 'Company_Director_Details__c', loanId)
            });
            result.isValid = false;
            result.errorMessage = 'Error while validating director details.';
        }

        return result;
    }

    public class DirectorValidationResult {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public String errorMessage;
    }
    
    public static Set<Id> getLoanIdsWithDirectorDetails(Set<Id> loanIds) {
        Set<Id> loanIdsWithDirectorDetailsList = new Set<Id>();
        
        try {
            if (loanIds == null || loanIds.isEmpty()) {
                return loanIdsWithDirectorDetailsList;
            }
            
            List<Company_Director_Details__c> directorDetailsList = [
                SELECT Id, Loan_Application__c
                FROM Company_Director_Details__c
                WHERE Loan_Application__c IN :loanIds
            ];
            
            for (Company_Director_Details__c directorDetailRecord : directorDetailsList) {
                loanIdsWithDirectorDetailsList.add(directorDetailRecord.Loan_Application__c);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getLoanIdsWithDirectorDetails: ' + e.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ 
                Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 
                    'getLoanIdsWithDirectorDetails', 'Company_Director_Details__c', '') 
            });
        }
        return loanIdsWithDirectorDetailsList;
    }

    public static Set<Id> isDirectorDetailsApplicableBulkified(Set<Id> loanIdSet) {
        Set<Id> directorDetailsApplicableSet = new Set<Id>();
        if (loanIdSet.isEmpty()) {
            return loanIdSet;
        }
        try {
            for (Id loanId : loanIdSet) {
            Application_Applicant__c primaryApplicant = [
                SELECT Id, Customer_Type__c, Applicant_Type__c, Sector__c 
                FROM Application_Applicant__c  
                WHERE Loan_Application__c = :loanId 
                AND Applicant_Type__c = :Constants.PRIMARY_APPLICANT
                LIMIT 1
            ];

            List<String> sectorsToShowDirectorDetails = System.Label.Director_Details_Dependent_Sector_Values.split(',');

            if (primaryApplicant != null && sectorsToShowDirectorDetails.contains(primaryApplicant.Sector__c)) {
                directorDetailsApplicableSet.add(loanId);
            }
        }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in checking director details dependency: ' + e.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(e.getMessage(), e.getStackTraceString(), 
                'isDirectorDetailsApplicable', 'Company_Director_Details__c', '') });
        }
        return directorDetailsApplicableSet;
}
}