/**
 * @description       : Controller to initiate GST calculation API request and process response
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-07-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class AHL_CalculateGstController {
    
    @AuraEnabled
    public static String initiateAPIRequest(Map<String,String> inputMap) {
        String returnResp = '';
        try {
            String loanId = inputMap.get('loanId');
            String processName = inputMap.get('processName');
            String productName = inputMap.get('productName');
            String feeType = inputMap.get('feeType');
            String waiverAmountCalcFlag = inputMap.get('isWaiverAmountCalc');
            Boolean isWaiverAmountCalc = Boolean.valueOf(waiverAmountCalcFlag);
            Decimal gstAmountForApi = String.isNotBlank(inputMap.get('gstAmountForApi')) ? Decimal.valueOf(inputMap.get('gstAmountForApi')) : null;
            // Fetch Integration Metadata
            List<Integration_Master__mdt> metadataList = [
                SELECT Process_Name__c, Handler_Class__c, Endpoint__c, Request_Method__c, 
                       Client_Id__c, Client_Secret__c, Allowed_Retry__c, Gestation_Period__c, 
                       Refresh_Allowed__c, Activity_Name__c
                FROM Integration_Master__mdt 
                WHERE Activity_Name__c = :processName 
                LIMIT 1
            ];
            if (metadataList.isEmpty()) {
                throw new AuraHandledException('No integration metadata found for process: ' + processName);
            }
            Integration_Master__mdt metadata = metadataList[0];
            // Prepare request wrapper
            IntHandler.ProcessReqWrapper wrapper = new IntHandler.ProcessReqWrapper(); 
            wrapper.loanApplicationId = loanId;  
            wrapper.type = processName;
            wrapper.feeType = feeType;
            wrapper.endpoint = metadata.Endpoint__c;
            wrapper.requestMethod = metadata.Request_Method__c;
            wrapper.handlerClass = metadata.Handler_Class__c;
            wrapper.clientId = metadata.Client_Id__c;
            wrapper.clientSecret = metadata.Client_Secret__c;
            wrapper.allowedRetry = metadata.Allowed_Retry__c;
            wrapper.gestationPeriod = metadata.Gestation_Period__c;
            wrapper.activityname = metadata.Activity_Name__c;
            wrapper.refreshallowed = metadata.Refresh_Allowed__c;
            wrapper.handlername = metadata.Handler_Class__c;
            wrapper.productName = productName;
            wrapper.isWaiverAmountCalc = isWaiverAmountCalc;
            wrapper.gstAmountForApi = gstAmountForApi;
            // Validate process & get payload
            IntHandler.processResWrapper respWrapper = IntHandler.validateProcess(wrapper);
            respWrapper.payload = null;
            // Fetch Integration Settings for 'Eseal'
            List<Integration_Settings__c> intSettingList = [
                SELECT Client_Id__c, Client_Secret__c, Endpoint__c, Content_Type__c, Request_Method__c
                FROM Integration_Settings__c 
                WHERE Name = 'CalculateGST' 
                LIMIT 1
            ];
            if (intSettingList.isEmpty()) {
                throw new AuraHandledException('Integration Settings "Eseal" not found.');
            }
            Integration_Settings__c intSetting = intSettingList[0];
            Integration_Details__c integrationDetail = new Integration_Details__c();
            integrationDetail.Name = processName;
            integrationDetail.Object_Name__c = 'Opportunity';
            integrationDetail.Loan_Application__c = loanId;
            integrationDetail.EndPoint__c = intSetting.Endpoint__c;
            integrationDetail.Request_JSON__c = null;//respWrapper.payload;
            // Handle prerequisite errors
            if (respWrapper.prerequisiteError != null && !respWrapper.prerequisiteError.isEmpty()) {
                integrationDetail.Status__c = '412';
                integrationDetail.Prerequisite__c = String.join(respWrapper.prerequisiteError, ', ');
                insert integrationDetail;
                returnResp = integrationDetail.Prerequisite__c;
                return returnResp;
            }
            Decimal apiAmount = 0;
            if (String.isNotBlank(respWrapper.payload)) {
                Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(respWrapper.payload);
                List<Object> feesList = (List<Object>) payloadMap.get('fees');
                if (feesList != null && !feesList.isEmpty()) {
                    Map<String, Object> firstFee = (Map<String, Object>) feesList[0];
                    Object amtObj = firstFee.get('amount');
                    apiAmount = (amtObj != null) ? Decimal.valueOf(String.valueOf(amtObj)) : 0;
                }
            }
            if (apiAmount == 0) {
                if (gstAmountForApi == null) {
                    List<Charges_Insurance__c> cIP = [
                        SELECT Id, Tax_INR__c, Final_Amount_INR__c, Waiver_Amount__c
                        FROM Charges_Insurance__c 
                        WHERE Loan_Application__c = :loanId
                            AND Name = :feeType
                            AND Product__c = :productName
                        LIMIT 1
                    ];
                    if (!cIP.isEmpty()) {
                        if (isWaiverAmountCalc == true) {
                            cIP[0].Waiver_Amount__c = 0;
                        } else {
                            cIP[0].Tax_INR__c = 0;
                            cIP[0].Final_Amount_INR__c = 0;
                        }
                        update cIP;
                    }
                    returnResp = 'Success: GST calculation completed.';
                } else {
                    returnResp = 'Success:0';
                }
                integrationDetail.Status__c = '200';
                insert integrationDetail;
                return returnResp;
            }
            // Prepare request map for utility class
            String bearer = Utility.getAccessToken();
            Map<String, String> integrationRequestMap = new Map<String, String>();
            integrationRequestMap.put('intSettingName', 'CalculateGST');
            integrationRequestMap.put('serviceName', 'gstSimulation');
            integrationRequestMap.put('requestJSON', respWrapper.payload);
            integrationRequestMap.put('MESSAGEID','167036797111');
            integrationRequestMap.put('ENTITYID','14589954555');
            integrationRequestMap.put('ServiceVersion','1');
            integrationRequestMap.put('RequestTime', String.valueof(DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss')));
            integrationRequestMap.put('Language','ENG');
            integrationRequestMap.put('bearer', bearer);
            // Execute HTTP API Request
            System.debug('75 '+respWrapper.payload);
            HTTPResponse resp = Utility.executeAPIRequest(integrationRequestMap);
            Integer statusCode = resp.getStatusCode();
            integrationDetail.Status__c = String.valueOf(statusCode);
            integrationDetail.Response_JSON__c = resp.getBody();
            integrationDetail.Related_Record_Id__c = loanId;
            if (statusCode == 200) {
                String jsonResponse = resp.getBody();
                ResponseWrapper gstResp = (ResponseWrapper) JSON.deserialize(jsonResponse, ResponseWrapper.class);

                if (gstResp != null && gstResp.returnStatus != null) {
                    if (gstResp.returnStatus.returnText == 'Success') {
                        Cls_Fees feeRec =
                            gstResp.fees != null && !gstResp.fees.isEmpty()
                                ? gstResp.fees[0]
                                : null;

                        if (feeRec == null) {
                            returnResp = 'Error: GST details missing in response.';
                            insert integrationDetail;
                            return returnResp;
                        }

                        // Fetch Charges
                        if(gstAmountForApi==null){
                            List<Charges_Insurance__c> cIP = [
                                SELECT Id, Tax_INR__c, Final_Amount_INR__c, Waiver_Amount__c
                                FROM Charges_Insurance__c 
                                WHERE Loan_Application__c = :loanId
                                    AND Name = :feeType
                                    AND Product__c = :productName
                                LIMIT 1
                            ];

                            if (!cIP.isEmpty()) {

                                if (isWaiverAmountCalc == true) {
                                    cIP[0].Waiver_Amount__c = Utility.truncateTwoZeros(feeRec.totalAmount);
                                } else {
                                    cIP[0].Tax_INR__c = Utility.truncateTwoZeros(feeRec.netGST);
                                    cIP[0].Final_Amount_INR__c = Utility.truncateTwoZeros(feeRec.totalAmount);
                                }
                                update cIP;
                            }
                            
                            returnResp = 'Success: GST calculation completed.';
                        }
                        else{
                            returnResp = 'Success:' + Utility.truncateTwoZeros(feeRec.netGST);
                        }

                       

                    } else {
                        returnResp = 'Error from API: ' + gstResp.returnStatus.returnText;
                    }
                } else {
                    returnResp = 'Success: GST calculation completed, but response parsing failed.';
                }
            }
            else if (statusCode == 503) {
                returnResp = 'Error: Service Temporarily Unavailable';
            } else {
                returnResp = 'Error: Unexpected response status ' + statusCode;
            }
            insert integrationDetail;
        } catch (Exception e) {
            //system.debug('e.getMessage()'+ e.getMessage()+ e.getLineNumber());
            throw new AuraHandledException('Error during processing: ' + e.getMessage());
        }
        
        return returnResp;
    }

    public class ResponseWrapper {
        public List<Cls_Fees> fees;
        public Cls_ReturnStatus returnStatus;
    }

    public class Cls_Fees {
        public Integer sequence;
        public Decimal amount;
        public Decimal netGST;
        public Decimal totalAmount;
        public Decimal igst;
        public Decimal sgst;
        public Decimal cgst;
        public Decimal ugst;
    }

    public class Cls_ReturnStatus {
        public String returnCode;
        public String returnText;
    }
}