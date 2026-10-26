/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-14-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class COMM_OCRHandler implements IntegrationInterface {
    public static List<String> validatePayload(IntHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();
        String loanApplicationId = wrapper.loanApplicationId;
        String base64 = wrapper.fileBase64;
       
        String applicantId = wrapper.recordId;
        // if(String.isBlank(applicantId) || String.isBlank(loanApplicationId)){
        //     errorMessages.add('Error: Applicant Id is missing');
        // }
        if(String.isBlank(base64)){
            errorMessages.add('Error: No Document Found');
        }
        return errorMessages;

    }

    public String constructPayload(IntHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        List<String> errorMessages = new List<String>();

        try {
            System.debug('are we inside construct??'+wrapper.contentVersionId);
            OcrRequestWrapper ocr = new OcrRequestWrapper();
            if(String.isNotBlank(wrapper.fileBase64)){
                ContentVersion cv = [SELECT VersionData,FileType  FROM ContentVersion WHERE ContentDocumentId =:wrapper.contentVersionId LIMIT 1];
                System.debug('are we cv construct??'+cv);
                if(cv != null) {
                    ocr.fileBase64 = EncodingUtil.base64Encode(cv.VersionData);
                    ocr.requiredOcr = true;
                    ocr.pdfPassword = '';
                    ocr.requiredConfidence = true;
                    ocr.responseType = 'BASE64';
                    ocr.parseQRdata = false;
                    ocr.maskQRdata = false;
                    ocr.tamperDetection = false;
                    ocr.maskAadhaarImage = '';
                    ocr.maskAadhaarText = '';
                    if( wrapper.docType.toLowerCase().contains('aadhar') || wrapper.docType.toLowerCase().contains('aadhaar') ){
                        ocr.maskAadhaarImage = 'EIGHT_DIGITS';
                        ocr.maskAadhaarText = '';   //Allowed values: COMPLETE, EIGHT_DIGITS //Make this configurable 
                        if(cv.FileType == 'PDF'){
                            ocr.responseFormat = 'FILE';
                        }
                    }
                    else if( wrapper.docType.toLowerCase().contains('driving') || wrapper.docType.toLowerCase().contains('license') || wrapper.docType.toLowerCase().contains('dl')){
                        ocr.docTypes = new List<String>();
                        ocr.docTypes.add('DL');
                    }
                    else{
                        ocr.docTypes = new List<String>();
                        ocr.docTypes.add('');
                    }
                }
            }
            String requestJSON = JSON.serialize(ocr);
            return requestJSON;
        }
    
    catch (Exception exp) {
        System.debug('Exception: ' + exp.getMessage());
        Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'Createhunterpayload', '', '') });
        throw new AuraHandledException('An error occurred: ' + exp.getMessage());
    }

    }

    public class OcrRequestWrapper{
        public String fileBase64;
        public String pdfPassword;
        public Boolean requiredConfidence;
        public Boolean requiredOcr;
        public cls_returnQualityChecks[] returnQualityChecks;  // Array type
        public String maskAadhaarImage;    // EIGHT_DIGITS
        public String maskAadhaarText;     // EIGHT_DIGITS
        public String responseFormat;      // DOCUMENT
        public String responseType;        // URL
        public List<String> docTypes;    // Array type
        public Boolean parseQRdata;
        public Boolean maskQRdata;
        public Boolean tamperDetection;
        public cls_clientData clientData;
    }
    public class cls_returnQualityChecks {
        public String qualityChecks;
    }
    public class cls_clientData {
        public String caseId;  // 123456
    }
}