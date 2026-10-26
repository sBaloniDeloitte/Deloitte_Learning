public class LOSQueryService {
    
    public class LOSQueryRequest {
        public String finReference;
        public String loanApplication;
        public String custSector;
        public Decimal reqLoanAmt;
        public Double repaymentInterestRate;
        public Decimal reqLoanTenor;
        public String finPurpose;
        public String custSubSector;
        public Decimal age;
        public Integer maxDPD6M;
        public Decimal cibil;
        public Decimal totalWorkExperienceYear;
        public String officeType;
        public Decimal businessCreditFor12Months;
        public Decimal monthlyABB12Months;
        public Boolean qualificationProof;
        public Boolean proofOfPractice;
        public Boolean proofOfOffice;
        public Boolean poaUploaded;
        public Boolean addressLineOne;
        public Boolean pincode;
        public Boolean pooUploaded;
        public Boolean pooAddressLineOne;
        public Boolean pooPincode;
        public Boolean perfiosPopsUp;
        public Boolean derogatoryCommentsInCIBIL;
        public String caLetter;
        public Boolean prescriptionLetterhead;
        public String confidenceScore;
        public String eligibilityProgram;
        public String incomeTaxReturn;
        public String gstCertificate;
        public String perfiosPopsUp2;
        public String poaUploaded2;
        public String addressLine1;
        public String pincode2;
        public String proofOfOwnership;
        public String udhyamRegistrationCertificate;
        public Decimal registrationNumber;
        public String msmeCategory;
        public String email;
    }
    
    public class ResponseWrapper {
        public ResponseDetails details;
        public Integer predictedPersonaId;
        public String queryString;
        public String error;
    }
    public class ResponseDetails {
        public Decimal averageLoanAmount;
        public Integer averageLoanTenure;
        public Integer averageMaxDPDIn6Months;
        public Decimal averageMonthlyObligation;
        public Integer averageTotalWorkExp;
        public Integer averageOfAge;
        public Decimal averageOfInterestRate;
        public Integer averageOfCibil;
        public Integer countOfCases;
        public String personaDescription;
        public Integer personaID;
        public String predictedQuery;
    }
    
    
    
    //private static final String LOS_QUERY_ENDPOINT = 'https://uat-hl-sf.godrejhf.com/los_query/api/v1/predict';
    
    public string callLOSQueryAPI(String accessToken, string request, Map<String,String> requestDetails) {
        String response;
        Integration_Details__c integrationDetails = new Integration_Details__c();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(requestDetails.get('endPoint'));
        req.setMethod(requestDetails.get('method'));
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setTimeout(120000);
        system.debug('accessToken'+accessToken);
        req.setBody(request);
        system.debug('req'+req);
        system.debug('body'+request);
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            System.debug('Response: ' + res.getBody());
            ResponseWrapper responseWrapper = new ResponseWrapper();
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            System.debug('responseMap'+responseMap);
            if(responseMap.get('error') != null){
                responseWrapper.error = (string) responseMap.get('error');
                System.debug('responseWrapper.error ' + responseWrapper.error);
                response = responseWrapper.error;
                             
            }else if (responseMap.get('details') != null){
                responseWrapper.details = new ResponseDetails();
                Map<String, Object> detailsMap = (Map<String, Object>) responseMap.get('details');
                responseWrapper.details.averageLoanAmount = detailsMap.get('Average Loan Amount') != null ? (Decimal) detailsMap.get('Average Loan Amount') : 0;
                responseWrapper.details.averageLoanTenure = detailsMap.get('Average Loan tenure') != null ? (Integer) detailsMap.get('Average Loan tenure') : 0;
                responseWrapper.details.averageMaxDPDIn6Months = detailsMap.get('Average Max DPD in 6 Months') != null ? (Integer) detailsMap.get('Average Max DPD in 6 Months') : 0;
                responseWrapper.details.averageMonthlyObligation = detailsMap.get('Average Monthly Obligation') != null ? (Decimal) detailsMap.get('Average Monthly Obligation') : 0;
                responseWrapper.details.averageTotalWorkExp = detailsMap.get('Average Total Work Exp') != null ? (Integer) detailsMap.get('Average Total Work Exp') : 0;
                responseWrapper.details.averageOfAge = detailsMap.get('Average of Age') != null ? (Integer) detailsMap.get('Average of Age') : 0;
                responseWrapper.details.averageOfInterestRate = detailsMap.get('Average of Interest Rate') != null ? (Decimal) detailsMap.get('Average of Interest Rate') : 0;
                responseWrapper.details.averageOfCibil = detailsMap.get('Average of cibil') != null ? (Integer) detailsMap.get('Average of cibil') : 0;
                responseWrapper.details.countOfCases = detailsMap.get('Count of cases') != null ? (Integer) detailsMap.get('Count of cases') : 0;
                responseWrapper.details.personaDescription = detailsMap.get('Persona Description') != null ? (String) detailsMap.get('Persona Description') : '';
                responseWrapper.details.personaID = detailsMap.get('Persona_ID') != null ? (Integer) detailsMap.get('Persona_ID') : 0;
                responseWrapper.details.predictedQuery = detailsMap.get('Predicted Query') != null ? (String) detailsMap.get('Predicted Query') : '';
                System.debug('responseWrapper.details.predictedQuery' + responseWrapper.details.predictedQuery);
                responseWrapper.predictedPersonaId = responseMap.get('predicted_persona_id') != null ? (Integer) responseMap.get('predicted_persona_id') : 0;
                responseWrapper.queryString = responseMap.get('query_string') != null ? (String) responseMap.get('query_string') : '';
                system.debug('responseWrapper.queryString'+responseWrapper.queryString);
                system.debug('responseWrapper'+responseWrapper); 
                response = responseWrapper.queryString;
               
            }
             integrationDetails = Utility.fillIntegrationRecord(requestDetails.get('processName'), JSON.serialize(request), JSON.serialize(responseMap), String.valueof(res.getStatusCode()), requestDetails.get('method'), requestDetails.get('endPoint'), 'Loan_Application__c', '', requestDetails.get('processName'), requestDetails.get('sObjId'));
             System.debug('integrationDetails>>'+ integrationDetails);       
            
        } else {
            System.debug('Error: ' + res.getStatus());
            integrationDetails = Utility.fillIntegrationRecord(requestDetails.get('processName'), JSON.serialize(request), JSON.serialize(res.getBody()), String.valueof(res.getStatusCode()), requestDetails.get('method'), requestDetails.get('endPoint'), 'Loan_Application__c', '', requestDetails.get('processName'), requestDetails.get('sObjId'));

        }
        if(integrationDetails != null){
            insert integrationDetails;
        }
        return response;
    }
    
    public static String executeLOSQuery(Map<String, String> inputMap) {
        String resultMessage; 
        String processName = inputMap.get('processName');
        String sObjId = inputMap.get('sObjId');
        system.debug('sObjId'+ sObjId);
        LOSQueryService service = new LOSQueryService();
        String accessToken = Utility.getAccessToken();
        
        if (accessToken != null) {
            Integration_Settings__c metadata = [Select Id,Name,Request_Method__c,Endpoint__c from Integration_Settings__c where Name =:processName LIMIT 1];
            Map<String, String> requestDetails = new Map<String, String>();
            requestDetails.put('endPoint',metadata.Endpoint__c);
            requestDetails.put('method',metadata.Request_Method__c);
            requestDetails.put('processName',processName);
            requestDetails.put('sObjId',sObjId);
            string requestJSON = service.constructPayload(sObjId);
            system.debug('requestJSON'+requestJSON);
            if(requestJSON != null && requestDetails != null){
               resultMessage = service.callLOSQueryAPI(accessToken, requestJSON, requestDetails);  
            }
            
        } else {
            System.debug('Failed to obtain access token.');
        }
        return resultMessage;
    }
    
    public String constructPayload(string recordId) {
        //List<String> errorMessages = new List<String>();
        String requestJSON;
        try {
            Opportunity opportunity = [Select Id,Name,Final_Rate_Of_Interest__c,Loan_Purpose__c,Program__c,Registration_Number__c,Requested_Amount__c,Final_Tenure__c from Opportunity where Id =:recordId LIMIT 1];
            Application_Applicant__c applicant = [Select Id,Industry__c,Applicant_s_Age__c,CIBIL_Score__c,Total_Work_Experience_Years__c,Office_Ownership__c,Reference_Address_1__c,Pincode__c,PSL__c,Owner.Email,Sector__c from Application_Applicant__c where Applicant_Type__c = 'Primary Applicant' and Loan_Application__c =: recordId LIMIT 1];
            Applicant_Address__c applicantAddress = [Select Id,Address_Line_1__c from Applicant_Address__c where Applicant__c =: applicant.Id LIMIT 1];
            List<Charges_Insurance__c> chargsInsurance = [Select Id,Loan_tenure__c,Loan_Application__c from Charges_Insurance__c where Loan_Application__c =:recordId LIMIT 1];
            List<Bank_Statement_Analysis__c> bankStatementAnalysis = [Select Id,Sum_of_business_credits_6_months_manual__c,Loan_Application__c,ABB__c from Bank_Statement_Analysis__c where Loan_Application__c =:recordId LIMIT 1];
            LOSQueryRequest request = new LOSQueryRequest();
            request.finReference = ( opportunity.Name != null && opportunity.Name != '') ?  opportunity.Name : '';
            //request.finReference = 'GFL3001BL0080911';
            request.loanApplication = ( opportunity.Name != null && opportunity.Name != '') ?  opportunity.Name : '';
            //request.loanApplication = 'GFL3001BL0080911';
            request.custSector = ( applicant.Sector__c != null && applicant.Sector__c != '') ?  applicant.Sector__c : '';
            //request.custSector = 'SEP1';
            request.reqLoanAmt = ( opportunity.Requested_Amount__c != null) ?  opportunity.Requested_Amount__c : null;
            request.repaymentInterestRate = ( opportunity.Final_Rate_Of_Interest__c != null) ?  opportunity.Final_Rate_Of_Interest__c : null;
            request.reqLoanTenor = (opportunity.Final_Tenure__c != null) ?  opportunity.Final_Tenure__c : null;
            //request.reqLoanTenor = 20;
            request.finPurpose = ( opportunity.Loan_Purpose__c != null && opportunity.Loan_Purpose__c != '') ?  opportunity.Loan_Purpose__c : '';
            //request.finPurpose = 'BEXP';
            request.custSubSector = ( applicant.Industry__c != null && applicant.Industry__c != '') ?  applicant.Industry__c : '';
            //request.custSubSector = 'SBSC806';
            request.age = ( applicant.Applicant_s_Age__c != null) ?  applicant.Applicant_s_Age__c : null;
            request.maxDPD6M = 0;
            request.cibil = ( applicant.CIBIL_Score__c != null) ?  applicant.CIBIL_Score__c : null;
            request.totalWorkExperienceYear = ( applicant.Total_Work_Experience_Years__c != null) ?  applicant.Total_Work_Experience_Years__c : null;
            request.officeType = ( applicant.Office_Ownership__c != null && applicant.Office_Ownership__c != '') ?  applicant.Office_Ownership__c : '';
            //request.officeType = 'RENT';
            if (!bankStatementAnalysis.isEmpty()) {
            request.businessCreditFor12Months = ( bankStatementAnalysis.size() > 0 && bankStatementAnalysis[0].Sum_of_business_credits_6_months_manual__c != null) ?  bankStatementAnalysis[0].Sum_of_business_credits_6_months_manual__c : null;
            request.monthlyABB12Months = ( bankStatementAnalysis.size() > 0  && bankStatementAnalysis[0].ABB__c != null) ?  bankStatementAnalysis[0].ABB__c : null;
            }
            request.qualificationProof = false;
            request.proofOfPractice = true;
            request.proofOfOffice = true;
            request.poaUploaded = true;
            request.addressLineOne = false;
            request.pincode = true;
            request.pooUploaded = true;
            request.pooAddressLineOne = false;
            request.pooPincode = true;
            request.perfiosPopsUp = false;
            request.derogatoryCommentsInCIBIL = false;
            request.caLetter = null;
            request.prescriptionLetterhead = false;
            request.confidenceScore = null;
            request.eligibilityProgram = (opportunity.Program__c != null && opportunity.Program__c != '') ? opportunity.Program__c : '';
            request.incomeTaxReturn = null;
            request.gstCertificate = null;
            request.perfiosPopsUp2 = null;
            request.poaUploaded2 = null;
            request.addressLine1 = (applicantAddress.Address_Line_1__c != null && applicantAddress.Address_Line_1__c != '') ? applicantAddress.Address_Line_1__c : '';
            request.pincode2 = null;
            request.proofOfOwnership = null;
            request.udhyamRegistrationCertificate = null;
            request.registrationNumber = (opportunity.Registration_Number__c != null) ? opportunity.Registration_Number__c : null;
            request.msmeCategory = (applicant.PSL__c != null && applicant.PSL__c != '') ? applicant.PSL__c : '';
            request.email = (applicant.Owner.Email != null && applicant.Owner.Email != '') ? applicant.Owner.Email : '';
            //request.email = 'sidharth.chopra@godrejcapital.com';
            requestJSON = JSON.serialize(request);
            system.debug('requestJSON'+requestJSON);
        }catch(exception ex){
            system.debug('exception'+ex.getLineNumber());
        }
        return requestJSON;
    }
}