public with sharing class HL_SquareYardHandler implements IntegrationInterface{

    public static List<String> validatePayload(intHandler.ProcessReqWrapper wrapper) { 
        List<String> errorMessages = new List<String>();

        if(wrapper.type == 'SqYd Initiation'){
            system.debug('wrapper.recordId: '+wrapper.recordId);
            List<Technical_Evaluation__c> tech = [Select HL_Name_of_Project__c, HL_Pincode__c, HL_Area_of_Property__c, Unit_Type__c, HL_LAN_ID__c, HL_Name_of_Applicant__c,
                                                    HL_Area_Type__c, HL_SquareYard_ProjectId__c, HL_Architecture_Cert_Url__c, HL_Cost_Sheet_Url__c, HL_Image_Url__c
                                                    From Technical_Evaluation__c Where Id =: wrapper.recordId];

            system.debug('tech: '+ JSON.serialize(tech));
            if(String.isBlank(tech[0].HL_Name_of_Project__c)) {
                errorMessages.add('Error: Missing Project Name');
            }
            if(String.isBlank(tech[0].HL_Area_Type__c)) {
                errorMessages.add('Error: Missing Area Type');
            }
            if(String.isBlank(tech[0].HL_Area_of_Property__c)) {
                errorMessages.add('Error: Missing Area');
            }
            if(String.isBlank(tech[0].Unit_Type__c)) {
                errorMessages.add('Error: Missing Configuration');
            }
            if(String.isBlank(tech[0].HL_Pincode__c)) {
                errorMessages.add('Error: Missing Pincode');
            }
            if(String.isBlank(tech[0].HL_SquareYard_ProjectId__c)) {
                errorMessages.add('Error: Missing Project Id');
            }
            if(String.isBlank(tech[0].HL_Image_Url__c)) {
                errorMessages.add('Error: Missing Image');
            }
            if(String.isBlank(tech[0].HL_Architecture_Cert_Url__c)) {
                errorMessages.add('Error: Missing Architecture Cert');
            }
            if(String.isBlank(tech[0].HL_Cost_Sheet_Url__c)) {
                errorMessages.add('Error: Missing Cost Sheet');
            }
            if(String.isBlank(tech[0].HL_LAN_ID__c)) {
                errorMessages.add('Error: Missing Lan Id');
            }
            if(String.isBlank(tech[0].HL_Name_of_Applicant__c)) {
                errorMessages.add('Error: Missing Main Applicant Name');
            }
        }

        return errorMessages;
    }

    public String constructPayload(intHandler.ProcessReqWrapper wrapper, List<Integration_Details__c> integrationSettings) {
        
        try {
            string reqJson = '';
            if(wrapper.type == 'SqYd Initiation'){
                Integration_Details__c integrationDetails = new Integration_Details__c();
                
                List<Technical_Evaluation__c> tech = [Select HL_Name_of_Project__c, HL_Pincode__r.City__r.Name, HL_Area_of_Property__c, Unit_Type__c, HL_LAN_ID__c, HL_Name_of_Applicant__c,
                                                        HL_Area_Type__c, HL_SquareYard_ProjectId__c, HL_Architecture_Cert_Url__c, HL_Cost_Sheet_Url__c, HL_Image_Url__c
                                                        From Technical_Evaluation__c Where Id =: wrapper.recordId];
                
                SqYdCreateRequestWrapper request = new SqYdCreateRequestWrapper();
                request.projectName = tech[0].HL_Name_of_Project__c;
                request.areaType = tech[0].HL_Area_Type__c;
                request.area = Integer.valueOf(tech[0].HL_Area_of_Property__c);
                request.configuration = tech[0].Unit_Type__c;
                request.city = tech[0].HL_Pincode__r.City__r.Name;
                request.projectId = tech[0].HL_SquareYard_ProjectId__c;

                AdditionalInfo addInfo = new AdditionalInfo();
                addInfo.costSheet = tech[0].HL_Cost_Sheet_Url__c;
                addInfo.architectureCertificate = tech[0].HL_Architecture_Cert_Url__c;
                addInfo.applicantName = tech[0].HL_Name_of_Applicant__c;
                addInfo.lanId = tech[0].HL_LAN_ID__c;

                List<string> imagesList = new List<string>();
                imagesList.add(tech[0].HL_Image_Url__c);
                addInfo.images = imagesList;

                request.additionalInfo = addInfo;
                
                reqJson = JSON.serialize(request);
            }

            return reqJson;
        }
        catch (Exception exp) {
            System.debug('Exception: ' + exp.getMessage());
            Utility.createErrorLogRecord(new List<Error_Logs__c>{ Utility.fillErrorRecord(exp.getMessage(), exp.getStackTraceString(), 'AMLCheckHandler', '', '') });
            throw new AuraHandledException('An error occurred: ' + exp.getMessage());
        }
    }

    public class SqYdCreateRequestWrapper {
        public String projectName;	    //Piramal Revanta
        public String areaType;	    //carpet
        public Integer area;	    //450
        public String configuration;	    //1 BHK
        public String city;	    //Mumbai
        public String projectId;	    //8761
        public AdditionalInfo additionalInfo;
    }

    public class AdditionalInfo {
        public List<string> images;
        public String costSheet;	    //https://lt.godrejhf.com/GHFINC/EIUelmi
        public String applicantName;	    //Sumukh S N
        public String lanId;	    //GHF1401HL0042623
        public String architectureCertificate;	    //https://lt.godrejhf.com/GHFINC/81vfMLS
    }
}