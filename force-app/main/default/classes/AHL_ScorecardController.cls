public class AHL_ScorecardController {
@AuraEnabled
public static String updateScoreForKeyApplicant(String applicantId, String loanId) {
    try {
        List<Application_Applicant__c> appRec = [
            SELECT Id, Scorecard_Category__c, Is_Key_Applicant__c
            FROM Application_Applicant__c
            WHERE Id = :applicantId
            LIMIT 1
        ];

        if (appRec.isEmpty() || String.isBlank(appRec[0].Scorecard_Category__c)) {
            return 'Error: No Scorecard Category found on applicant';
        }

        List<Opportunity> oppRec = [
            SELECT Id, Score_Segment__c
            FROM Opportunity
            WHERE Id = :loanId
            LIMIT 1
        ];

        if (!oppRec.isEmpty()
            && appRec[0].Is_Key_Applicant__c
            && oppRec[0].Score_Segment__c != appRec[0].Scorecard_Category__c) {
            oppRec[0].Score_Segment__c = appRec[0].Scorecard_Category__c;
            update oppRec;
        }

        return 'Success';
    } catch (Exception e) {
        System.debug('Error in updateScoreForKeyApplicant: ' + e.getMessage());
        return 'Error: ' + e.getMessage();
    }
}
@AuraEnabled
public static Boolean isScoreSegmentMissing(String applicantId, String loanId) {
    try {
        List<Application_Applicant__c> appRec = [
            SELECT Id, Scorecard_Category__c
            FROM Application_Applicant__c
            WHERE Id = :applicantId
            LIMIT 1
        ];
        if (appRec.isEmpty() || String.isNotBlank(appRec[0].Scorecard_Category__c)) {
            return false;
        }
        List<Document_Details__c> crifDoc = [
            SELECT Id
            FROM Document_Details__c
            WHERE Loan_Application__c = :loanId
              AND Applicant__c = :applicantId
              AND Content_Document_Id__c != null
              AND Name = 'CRIF Response'
            LIMIT 1
        ];
        return !crifDoc.isEmpty();
    } catch (Exception e) {
        return false;
    }
}

    @AuraEnabled
    public static String initiateAPIRequest(Map<String, String> inputMap) {
        String loanId = inputMap.get('loanId');
        String applicantId = inputMap.get('applicantId');
        String processName = inputMap.get('processName');

        try {
           List<Integration_Master__mdt> metadataList = [
                SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c,
                       Client_Id__c, Client_Secret__c, Allowed_Retry__c, Gestation_Period__c,
                       Refresh_Allowed__c, Activity_Name__c
                FROM Integration_Master__mdt
                WHERE Activity_Name__c = :processName
                LIMIT 1
            ];
            if (metadataList.isEmpty()) {
                return 'Error: No integration metadata found for process ' + processName;
            }
            Integration_Master__mdt metadata = metadataList[0];

            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper();
            wrapper.loanApplicationId = loanId;
            wrapper.applicantId = applicantId;
            wrapper.type = processName;
            wrapper.endpoint = metadata.Endpoint__c;
            wrapper.requestMethod = metadata.Request_Method__c;
            wrapper.handlerClass = metadata.Handler_Class__c;
            wrapper.handlername = metadata.Handler_Class__c;
            wrapper.clientId = metadata.Client_Id__c;
            wrapper.clientSecret = metadata.Client_Secret__c;
            wrapper.allowedRetry = metadata.Allowed_Retry__c;
            wrapper.gestationPeriod = metadata.Gestation_Period__c;
            wrapper.activityname = metadata.Activity_Name__c;
            wrapper.refreshallowed = metadata.Refresh_Allowed__c;

            IntHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);

            Integration_Details__c integrationDetail = new Integration_Details__c();
            integrationDetail.Name = processName;
            integrationDetail.Object_Name__c = 'Application_Applicant__c';
            integrationDetail.Loan_Application__c = loanId;
            integrationDetail.Related_Record_Id__c = applicantId;
integrationDetail.endpoint__c = metadata.Endpoint__c;
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                String resultMessage = String.join(respWrapper.prerequisiteError, ', ');
                integrationDetail.Status__c = '412';
                integrationDetail.Prerequisite__c = resultMessage;
                insert integrationDetail;
                return 'Error: ' + resultMessage;
            }

            String bearer = Utility.getAccessToken();
            String endpoint = String.isNotBlank(metadata.Endpoint__c)
                ? metadata.Endpoint__c
                : 'Callout:AHL_Scorecard';

            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + bearer);
            request.setHeader('Origin', System.URL.getOrgDomainUrl().toExternalForm());
            request.setHeader('Content-Type', 'application/json');
            request.setBody(respWrapper.payload);
            request.setTimeout(120000);

            HttpResponse resp;
            try {
                resp = new Http().send(request);
            } catch (CalloutException ce) {
                integrationDetail.Response_JSON__c = ce.getMessage();
                integrationDetail.Calling_Source__c = wrapper.type;
                integrationDetail.Method_Type__c = wrapper.requestMethod;
                integrationDetail.EndPoint__c = endpoint;
                insert integrationDetail;
                return 'Error: Callout failed - ' + ce.getMessage();
            }

            String apiResponse = resp.getBody();
            integrationDetail.Calling_Source__c = wrapper.type;
            integrationDetail.Status__c = String.valueOf(resp.getStatusCode());
            integrationDetail.Method_Type__c = wrapper.requestMethod;
            integrationDetail.EndPoint__c = endpoint;

            if (resp.getStatusCode() != 200) {
                integrationDetail.Response_JSON__c = apiResponse;
                insert integrationDetail;
                return 'Error: Scorecard API returned status ' + resp.getStatusCode();
            }

            Map<String, Object> root;
            try {
                root = (Map<String, Object>) JSON.deserializeUntyped(apiResponse);
            } catch (Exception e) {
                integrationDetail.Response_JSON__c = apiResponse;
                insert integrationDetail;
                return 'Error: Malformed scorecard response';
            }

            if (root == null || !root.containsKey('Response')) {
                integrationDetail.Response_JSON__c = apiResponse;
                insert integrationDetail;
                return 'Error: The response does not contain a Response node';
            }

            Map<String, Object> responseNode = (Map<String, Object>) root.get('Response');
            String responseJson = JSON.serialize(responseNode);
            integrationDetail.Response_JSON__c = responseJson;
            insert integrationDetail;

            ResponseWrapper typedResponse = (ResponseWrapper) JSON.deserialize(responseJson, ResponseWrapper.class);
            if (typedResponse == null || typedResponse.CalculatedVariable == null) {
                return 'Success';
            }

            String scorecardCategory;
            for (CalculatedVariable cv : typedResponse.CalculatedVariable) {
                if (cv.fieldName == 'AHL_Scorecard_Category') {
                    scorecardCategory = cv.fieldValue;
                    break;
                }
            }
            if (String.isBlank(scorecardCategory)) {
                return 'Success';
            }

            List<Application_Applicant__c> appRec = [
                SELECT Id, Scorecard_Category__c, Is_Key_Applicant__c
                FROM Application_Applicant__c
                WHERE Id = :applicantId
                LIMIT 1
            ];
            List<Opportunity> oppRec = [
                SELECT Id, Score_Segment__c
                FROM Opportunity
                WHERE Id = :loanId
                LIMIT 1
            ];

            if (!appRec.isEmpty() && appRec[0].Scorecard_Category__c != scorecardCategory) {
                appRec[0].Scorecard_Category__c = scorecardCategory;
                update appRec;
            }
            if (!appRec.isEmpty() && !oppRec.isEmpty()
                && appRec[0].Is_Key_Applicant__c
                && oppRec[0].Score_Segment__c != scorecardCategory) {
                oppRec[0].Score_Segment__c = scorecardCategory;
                update oppRec;
            }

            return 'Success';
        } catch (Exception e) {
            system.debug('the exception is '+e.getMessage()+e.getstacktracestring());
            throw new AuraHandledException('AHL Scorecard failed: ' + e.getMessage());
        }
    }

    public class ResponseWrapper {
        public List<CalculatedVariable> CalculatedVariable;
        public List<ScoreCardDetail> ScoreCardDetail;
    }

    public class CalculatedVariable {
        public String fieldName;
        public String fieldType;
        public String fieldValue;
        public String productCode;
        public String entityId;
        public String entityType;
        public String purpose;
    }

    public class ScoreCardDetail {
        public String scorecardName;
        public String scorecardScore;
        public String characteristicCount;
        public String scorecardKey;
        public String entityId;
        public String entityType;
        public List<ScoreCardCharacteristic> ScoreCardCharacteristicsDetail;
    }

    public class ScoreCardCharacteristic {
        public String characteristicName;
        public String characteristicValue;
        public String partialScore;
        public String reasonCode;
    }
}