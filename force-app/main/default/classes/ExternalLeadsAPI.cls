@RestResource(urlMapping='/ExternalLeads/*')
global with sharing class ExternalLeadsAPI {
    
    @HttpPost
    global static ExternalLeadResponse createLead() {
        ExternalLeadResponse response = new ExternalLeadResponse();
        
        try {
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            
            String requestBody = req.requestBody.toString();
            System.debug('RAW_REQUEST_BODY=' + requestBody);
            ExternalLeadRequest leadRequest = (ExternalLeadRequest) JSON.deserialize(
                requestBody, 
                ExternalLeadRequest.class
            );
            
            String validationError = validateMandatoryFields(leadRequest);
            if (String.isNotBlank(validationError)) {
                response.success = false;
                response.message = validationError;
                response.errorCode = 'VALIDATION_ERROR';
                res.statusCode = 400;
                return response;
            }
            
            // For Online channel: check for duplicate (same mobile + product + customerType)
            // If found, mark existing lead Hot and return success without creating a new lead
            String resolvedChannelCheck = String.isNotBlank(leadRequest.leadChannel)
                ? leadRequest.leadChannel.trim()
                : (leadRequest.source != null ? leadRequest.source.trim() : '');
            if (resolvedChannelCheck.equalsIgnoreCase('Online')) {
                String dupMobile = String.isNotBlank(leadRequest.mobile) ? leadRequest.mobile : leadRequest.mobileNumber;
                Lead dupLead = findOnlineDuplicate(dupMobile, leadRequest.product, leadRequest.customerType);
                if (dupLead != null) {
                    dupLead.Lead_Type__c = 'Hot';
                    update dupLead;
                    response.success = true;
                    response.message = 'Lead already exists; marked as Hot.';
                    response.leadId = dupLead.Id;
                    RestContext.response.statusCode = 200;
                    return response;
                }
            }

            Lead newLead = createLeadRecord(leadRequest);
            insert newLead;
            
            // Assign OwnerId directly to the queue so all queue members are notified
            try {
                Group queue = [SELECT Id FROM Group WHERE DeveloperName = 'Telecaller_Lead_Queue' AND Type = 'Queue' LIMIT 1];
                if (queue != null) {
                    newLead.OwnerId = queue.Id;
                    update newLead;
                } else {
                    System.debug('Queue not found: Telecaller_Lead_Queue');
                }
            } catch (Exception e) {
                System.debug('Skipping owner assignment in ExternalLeadsAPI due to error: ' + e.getMessage());
            }
    
            response.success = true;
            response.message = 'Lead created successfully';
            response.leadId = newLead.Id;
            res.statusCode = 201;
            
        } catch (DmlException dmlEx) {
            response.success = false;
            response.message = 'Database error: ' + dmlEx.getMessage();
            response.errorCode = 'DML_ERROR';
            response.errorDetails = dmlEx.getStackTraceString();
            RestContext.response.statusCode = 500;
            
        } catch (JSONException jsonEx) {
            response.success = false;
            response.message = 'Invalid JSON format: ' + jsonEx.getMessage();
            response.errorCode = 'JSON_PARSE_ERROR';
            response.errorDetails = jsonEx.getStackTraceString();
            RestContext.response.statusCode = 400;
            
        } catch (Exception ex) {
            response.success = false;
            response.message = 'Unexpected error: ' + ex.getMessage();
            response.errorCode = 'SYSTEM_ERROR';
            response.errorDetails = ex.getStackTraceString();
            RestContext.response.statusCode = 500;
        }
        
        return response;
    }
    
    private static String getPincodeMasterId(String pincode) {
        if (String.isBlank(pincode)) {
            return null;
        }
        
        try {
            List<Pincode_Master__c> pincodeRecords = [
                SELECT Id, Name 
                FROM Pincode_Master__c 
                WHERE Name = :pincode 
                LIMIT 1
            ];
            
            if (!pincodeRecords.isEmpty()) {
                return pincodeRecords[0].Id;
            }
        } catch (Exception ex) {
            System.debug('Error looking up pincode: ' + ex.getMessage());
        }
        
        return null;
    }
    
    
    private static String checkDuplicateMobile(String mobileNumber) {
        if (String.isBlank(mobileNumber)) {
            return null;
        }
        
        try {
            List<Lead> existingLeads = [
                SELECT Id, MobilePhone, Status 
                FROM Lead 
                WHERE MobilePhone = :mobileNumber 
                AND Status = 'Open'
                LIMIT 1
            ];
            
            if (!existingLeads.isEmpty()) {
                return 'Lead with mobile number ' + mobileNumber + ' already exists with Open status';
            }
        } catch (Exception ex) {
            System.debug('Error checking duplicate mobile: ' + ex.getMessage());
        }
        
        return null;
    }
    
    private static Lead findOnlineDuplicate(String mobile, String product, String customerType) {
        if (String.isBlank(mobile) || String.isBlank(product) || String.isBlank(customerType)) {
            return null;
        }
        List<Lead> existing = [
            SELECT Id, Lead_Type__c
            FROM Lead
            WHERE MobilePhone = :mobile
            AND Product__c = :product
            AND Customer_Type__c = :customerType
            AND Status != 'Closed'
            LIMIT 1
        ];
        return existing.isEmpty() ? null : existing[0];
    }

    private static String validateMandatoryFields(ExternalLeadRequest leadRequest) {
        List<String> errors = new List<String>();

        // Determine channel — support both legacy 'source' and new 'leadChannel' fields
        String resolvedChannel = String.isNotBlank(leadRequest.leadChannel)
            ? leadRequest.leadChannel.trim()
            : (leadRequest.source != null ? leadRequest.source.trim() : '');

        // Only allow 'Online' or 'CSC' as valid channels
        Set<String> validChannels = new Set<String>{ 'online', 'csc' };
        if (String.isBlank(resolvedChannel) || !validChannels.contains(resolvedChannel.toLowerCase())) {
            return 'Invalid channel';
        }

        Boolean isOnline = resolvedChannel.equalsIgnoreCase('Online');

        String mobile = String.isNotBlank(leadRequest.mobile) ? leadRequest.mobile
            : (String.isNotBlank(leadRequest.mobileNumber) ? leadRequest.mobileNumber : null);

        // For non-Online channels only: block if an open lead already exists with same mobile
        if (!isOnline) {
            String duplicateError = checkDuplicateMobile(mobile);
            if (String.isNotBlank(duplicateError)) {
                errors.add(duplicateError);
            }
        }

        if (leadRequest.customerType == null || !leadRequest.customerType.equalsIgnoreCase('Non Individual')) {
            if (String.isBlank(leadRequest.customer_name) && String.isBlank(leadRequest.firstName)) {
                errors.add('customer_name or First Name is required');
            }
        }
        if (String.isBlank(mobile)) {
            errors.add('Mobile Number is required');
        }
        // Determine max loan amount based on product
        String productForValidation = String.isNotBlank(leadRequest.product) ? leadRequest.product.trim() : '';
        Set<String> hlProducts = new Set<String>{ 'Home Loan', 'Non Home Loan' };
        Decimal maxLoanAmt = hlProducts.contains(productForValidation) ? 100000000 : 50000000;
        String maxLoanAmtLabel = hlProducts.contains(productForValidation) ? '₹10,00,00,000' : '₹5,00,00,000';

        if (!isOnline) {
            Decimal loanAmt = leadRequest.loan_amount != null ? leadRequest.loan_amount : leadRequest.loanAmount;
            if (loanAmt == null || loanAmt <= 0) {
                errors.add('loan_amount is required and must be greater than 0');
            } else if (loanAmt < 50000 || loanAmt > maxLoanAmt) {
                errors.add('Loan Amount must be between ₹50,000 and ' + maxLoanAmtLabel);
            }
            if (String.isBlank(resolvedChannel)) {
                errors.add('source is required');
            }
        } else if (leadRequest.loan_amount != null && leadRequest.loan_amount > 0) {
            // Online: loan_amount is optional, but if provided, validate range
            if (leadRequest.loan_amount < 50000 || leadRequest.loan_amount > maxLoanAmt) {
                errors.add('Loan Amount must be between ₹50,000 and ' + maxLoanAmtLabel);
            }
        } else if (leadRequest.loanAmount != null && leadRequest.loanAmount > 0) {
            if (leadRequest.loanAmount < 50000 || leadRequest.loanAmount > maxLoanAmt) {
                errors.add('Loan Amount must be between ₹50,000 and ' + maxLoanAmtLabel);
            }
        }
        String channelUpper = resolvedChannel.toUpperCase();
        if (channelUpper == 'CSC' && String.isBlank(leadRequest.sub_source_csc_id)) {
            errors.add('sub_source_csc_id is required when source is CSC');
        }

        if (String.isBlank(leadRequest.product)) {
            errors.add('Product is required');
        }
        if (String.isBlank(leadRequest.customerType)) {
            errors.add('Customer Type is required');
        }
        if (!isOnline && String.isBlank(leadRequest.employmentType)) {
            errors.add('Employment Type is required');
        }
        String resolvedEmail = String.isNotBlank(leadRequest.email) ? leadRequest.email
            : (String.isNotBlank(leadRequest.emailAddress) ? leadRequest.emailAddress : null);
        if (!isOnline && String.isBlank(resolvedEmail)) {
            errors.add('Email is required');
        }
        String resolvedPincode = leadRequest.pincode;
        if (!isOnline && String.isBlank(leadRequest.purposeOfLoan)) {
            errors.add('Purpose of Loan is required');
        }

        if (String.isNotBlank(leadRequest.customerType)) {
            if (leadRequest.customerType.equalsIgnoreCase('Individual')) {
                if (!isOnline && leadRequest.dateOfBirth == null) {
                    errors.add('Date of Birth is required for Individual customers');
                }
            } else if (leadRequest.customerType.equalsIgnoreCase('Non Individual')) {
                if (String.isBlank(leadRequest.company)) {
                    errors.add('Company is required for Non-Individual customers');
                }
                if (String.isBlank(leadRequest.contactPersonName)) {
                    errors.add('Contact Person Name is required for Non-Individual customers');
                }
                if (leadRequest.dateOfIncorporation == null) {
                    errors.add('Date of Incorporation is required for Non-Individual customers');
                }
                if (String.isBlank(leadRequest.businessType)) {
                    errors.add('Business Type is required for Non-Individual customers');
                }
            }
        }

        return errors.isEmpty() ? '' : String.join(errors, '; ');
    }
    
    private static Lead createLeadRecord(ExternalLeadRequest leadRequest) {
        Lead newLead = new Lead();

        // Resolve channel from leadChannel (new) or source (legacy)
        String resolvedChannel = String.isNotBlank(leadRequest.leadChannel)
            ? leadRequest.leadChannel.trim()
            : (leadRequest.source != null ? leadRequest.source.trim() : '');
        Boolean isOnline = resolvedChannel.equalsIgnoreCase('Online');

        // Resolve field aliases
        String mobile = String.isNotBlank(leadRequest.mobile) ? leadRequest.mobile
            : (String.isNotBlank(leadRequest.mobileNumber) ? leadRequest.mobileNumber : null);
        String resolvedAlternateMobile = leadRequest.alternateMobileNumber;
        String resolvedEmail = String.isNotBlank(leadRequest.email) ? leadRequest.email
            : (String.isNotBlank(leadRequest.emailAddress) ? leadRequest.emailAddress : null);
        String resolvedPincode = String.isNotBlank(leadRequest.pincode) ? leadRequest.pincode : leadRequest.pincodeStr;
        String resolvedCity = leadRequest.city;
        String resolvedState = leadRequest.state;
        String resolvedPan = leadRequest.pan;
        String resolvedGender = leadRequest.genderIdentity;
        String resolvedOfficeOwnership = leadRequest.officeOwnership;
        String resolvedTurnoverYearly = leadRequest.turnoverYearly;
        String resolvedBusinessVintage = leadRequest.businessVintage;

        String firstName;
        String lastName;
        String middleName = leadRequest.middleName;

        if (leadRequest.customerType != null && leadRequest.customerType.equalsIgnoreCase('Non Individual')) {
            firstName = null;
            lastName = leadRequest.company;
        } else {
            String fullName = String.isNotBlank(leadRequest.customer_name) ? leadRequest.customer_name : '';
            firstName = leadRequest.firstName;
            lastName = leadRequest.lastName;

            if (String.isNotBlank(fullName) && String.isBlank(firstName)) {
                List<String> nameParts = fullName.trim().split(' ');
                if (nameParts.size() == 1) {
                    firstName = nameParts[0];
                    lastName = nameParts[0];
                } else if (nameParts.size() == 2) {
                    firstName = nameParts[0];
                    lastName = nameParts[1];
                } else {
                    // 3+ parts: first | middle parts | last
                    firstName = nameParts[0];
                    lastName = nameParts[nameParts.size() - 1];
                    if (String.isBlank(middleName)) {
                        List<String> middleParts = new List<String>();
                        for (Integer i = 1; i < nameParts.size() - 1; i++) {
                            middleParts.add(nameParts[i]);
                        }
                        middleName = String.join(middleParts, ' ');
                    }
                }
            }
        }

        String pincodeId = getPincodeMasterId(resolvedPincode);
        newLead.FirstName = firstName;
        newLead.MiddleName = middleName;
        newLead.LastName = lastName;
        newLead.Email = resolvedEmail;
        newLead.MobilePhone = mobile;
        newLead.Alternate_Mobile_Number__c = resolvedAlternateMobile;
        newLead.Product__c = leadRequest.product;
        newLead.Customer_Type__c = leadRequest.customerType;
        String resolvedEmploymentType = leadRequest.employmentType;
        Map<String, String> empTypeMapping = new Map<String, String>{
            'Business Self-Employed' => 'SENP',
            'Indian Resident Salaried' => 'Salaried Indian',
            'Non-Resident Indian Salaried' => 'Salaried NRI',
            'Professional Self-Employed' => 'SEP'
        };
        if (empTypeMapping.containsKey(resolvedEmploymentType)) {
            resolvedEmploymentType = empTypeMapping.get(resolvedEmploymentType);
        }

        newLead.Employment_Type__c = resolvedEmploymentType;

        if (String.isNotBlank(leadRequest.product)) {
            if (leadRequest.product.equalsIgnoreCase('Affordable Home Loan')) {
                newLead.RecordTypeId = System.Label.AHLRecordTypeId;
            } else if (leadRequest.product.equalsIgnoreCase('Home Loan')) {
                newLead.RecordTypeId = System.Label.HLRecordTypeId;
            }
        }
        if (String.isNotBlank(pincodeId)) {
            newLead.Pincode__c = pincodeId;
        }
        newLead.COMM_Purpose_of_Loan__c = leadRequest.purposeOfLoan;
        newLead.Channel__c = resolvedChannel;
        Decimal resolvedLoanAmount = leadRequest.loan_amount != null ? leadRequest.loan_amount
            : leadRequest.loanAmount;
        newLead.Requested_Loan_Amount__c = resolvedLoanAmount;

        // Address fields
        if (String.isNotBlank(resolvedCity)) {
            newLead.City__c = resolvedCity;
        }
        if (String.isNotBlank(resolvedState)) {
            newLead.State__c = resolvedState;
        }
        if (leadRequest.subProduct != null && !leadRequest.subProduct.isEmpty()) {
            newLead.Sub_Product__c = String.join(leadRequest.subProduct, ';');
        } else if (String.isNotBlank(leadRequest.subProductStr)) {
            newLead.Sub_Product__c = leadRequest.subProductStr;
        }

        // Consent
        if (leadRequest.isConsentReceived != null) {
            newLead.COMM_Is_Consent_Received__c = leadRequest.isConsentReceived;
        }

        // LAN
        if (String.isNotBlank(leadRequest.lanId)) {
            newLead.LAN__c = leadRequest.lanId;
        }

        // Business vintage
        if (String.isNotBlank(resolvedBusinessVintage)) {
            try {
                newLead.Business_Vintage__c = Decimal.valueOf(resolvedBusinessVintage);
            } catch (Exception ex) {
                System.debug('businessVintage parse error: ' + ex.getMessage());
            }
        }

        // Webpage URL
        if (String.isNotBlank(leadRequest.mx_Webpage_URL)) {
            newLead.mx_Webpage_URL__c = leadRequest.mx_Webpage_URL;
        }

        if (String.isNotBlank(leadRequest.sub_source_csc_id)) {
            try {
                Decimal subSourceVal = Decimal.valueOf(leadRequest.sub_source_csc_id);
                newLead.Sub_Source_csc__c = subSourceVal;
            } catch (Exception ex) {
                System.debug('Error converting sub_source_csc_id to Decimal: ' + ex.getMessage());
            }
        }

        String channelUpper = resolvedChannel.toUpperCase();
        if (channelUpper == 'CSC') {
            newLead.LeadSource = 'CSC';
        } else if (isOnline) {
            newLead.LeadSource = String.isNotBlank(leadRequest.leadSource) ? leadRequest.leadSource : 'Website';
        } else {
            newLead.LeadSource = null;
        }

        // UTM fields (Online only)
        if (isOnline) {
            newLead.UTM_Campaign__c = leadRequest.utmCampaign;
            newLead.UTM_Content__c = leadRequest.utmContent;
            newLead.UTM_Medium__c = leadRequest.utmMedium;
            newLead.UTM_Source__c = leadRequest.utmSource;
            //newLead.UTM_Term__c = leadRequest.utmTerm;
        }
        
        if (leadRequest.customerType != null && leadRequest.customerType.equalsIgnoreCase('Individual')) {
            newLead.Company = String.isNotBlank(leadRequest.company) ? leadRequest.company : 'NA';
            newLead.Date_of_Birth__c = leadRequest.dateOfBirth;
            if (String.isNotBlank(resolvedGender)) {
                newLead.GenderIdentity = resolvedGender;
            }
        } else if (leadRequest.customerType != null && leadRequest.customerType.equalsIgnoreCase('Non Individual')) {
            newLead.Company = leadRequest.company;
            newLead.COMM_Contact_Person_Name__c = leadRequest.contactPersonName;
            newLead.Date_of_Incorporation__c = leadRequest.dateOfIncorporation;
            newLead.Business_Type__c = leadRequest.businessType;
            if (String.isNotBlank(resolvedOfficeOwnership)) {
                newLead.Office_Ownership__c = resolvedOfficeOwnership;
            }
            if (String.isNotBlank(resolvedTurnoverYearly)) {
                newLead.Turnover_Yearly__c = resolvedTurnoverYearly;
                try {
                    newLead.COMM_Business_Turnover__c = Decimal.valueOf(resolvedTurnoverYearly);
                } catch (Exception ex) {
                    System.debug('turnoverYearly parse error for COMM_Business_Turnover__c: ' + ex.getMessage());
                }
            }
        }

        newLead.PAN__c = resolvedPan;
        newLead.cscVledistrict__c = leadRequest.cscVledistrict;
        newLead.cscVlemobile__c = leadRequest.cscVlemobile;
        newLead.cscVlestate__c = leadRequest.cscVlestate;
        newLead.cscVletype__c = leadRequest.cscVletype;
        newLead.cscSalesid__c = leadRequest.cscSalesid;
        newLead.CampaignType_leadType__c = leadRequest.campaigntype;
        newLead.Page_Url__c = leadRequest.pageUrl;
        newLead.mx_Refferal_Type__c = leadRequest.mx_Refferal_Type;
        newLead.mx_Refferral_URL__c = leadRequest.mx_Refferral_URL;
        System.debug('pageUrl=' + leadRequest.pageUrl + ' | mx_Refferal_Type=' + leadRequest.mx_Refferal_Type + ' | mx_Refferral_URL=' + leadRequest.mx_Refferral_URL);
        newLead.Reference_Field_1__c = leadRequest.reference1;
        newLead.Reference_Field_2__c = leadRequest.reference2;
        newLead.Reference_Field_4__c = leadRequest.reference4;
        newLead.Reference_Field_5__c = leadRequest.reference5;
        newLead.Reference_Field_6__c = leadRequest.reference6;
        newLead.Reference_Field_7__c = leadRequest.reference7;
        newLead.Reference_Field_8__c = leadRequest.reference8;
        newLead.Reference_Field_9__c = leadRequest.reference9;
        newLead.Reference_Field_10__c = leadRequest.reference10;
        return newLead;
    }
    
    global class ExternalLeadRequest {
        public String customer_name { get; set; }
        public String mobile { get; set; }
        public Decimal loan_amount { get; set; }
        public String source { get; set; }
        public String sub_source_csc_id { get; set; }
        public String company { get; set; }
        public String product { get; set; }
        public String customerType { get; set; }
        public String employmentType { get; set; }
        public String firstName { get; set; }
        public String lastName { get; set; }
        public String mobileNumber { get; set; }
        public String email { get; set; }
        public String pincode { get; set; }
        public String purposeOfLoan { get; set; }
        public Date dateOfBirth { get; set; }
        public String contactPersonName { get; set; }
        public Date dateOfIncorporation { get; set; }
        public String businessType { get; set; }
        public String cscVletype { get; set; }
        public String cscVlename { get; set; }
        public String cscVlemobile { get; set; }
        public String cscVlestate { get; set; }
        public String cscVledistrict { get; set; }
        public String cscSalesid { get; set; }
        public String pan { get; set; }
        public String middleName { get; set; }
        public String emailAddress { get; set; }
        public String leadChannel { get; set; }
        public String leadSource { get; set; }
        public String utmCampaign { get; set; }
        public String utmContent { get; set; }
        public String utmMedium { get; set; }
        public String utmSource { get; set; }
        //public String utmTerm { get; set; }
        public Boolean isMobileVerified { get; set; }
        public Boolean isConsentReceived { get; set; }
        public String customerCif { get; set; }
        public String lanId { get; set; }
        public String roi { get; set; }
        public String tenure { get; set; }
        public Decimal loanAmountCrossSell { get; set; }
        public String crossSellCampaignName { get; set; }
        public String offerTypeIdCrossSell { get; set; }
        public String offerId { get; set; }
        public List<String> subProduct { get; set; }
        public String subProductStr { get; set; }
        public String city { get; set; }
        public String state { get; set; }
        public String pincodeStr { get; set; }
        public String alternateMobileNumber { get; set; }
        public String genderIdentity { get; set; }
        public String officeOwnership { get; set; }
        public String turnoverYearly { get; set; }
        public String typeOfProperty { get; set; }
        public String businessVintage { get; set; }
        public String mx_Webpage_URL { get; set; }
        public String pageUrl { get; set; }
        public String mx_Refferal_Type { get; set; }
        public String mx_Refferral_URL { get; set; }
        public String campaigntype { get; set; }
        public Decimal loanAmount { get; set; }
        public List<Object> documentData { get; set; }
        // reference fields
        public String reference1 { get; set; }
        public String reference2 { get; set; }
        public String reference3 { get; set; }
        public String reference4 { get; set; }
        public String reference5 { get; set; }
        public String reference6 { get; set; }
        public String reference7 { get; set; }
        public String reference8 { get; set; }
        public String reference9 { get; set; }
        public String reference10 { get; set; }
    }
    
    global class ExternalLeadResponse {
        public Boolean success { get; set; }
        public String message { get; set; }
        public String leadId { get; set; }
        public String errorCode { get; set; }
        public String errorDetails { get; set; }
        
        public ExternalLeadResponse() {
            this.success = false;
            this.message = '';
            this.leadId = '';
            this.errorCode = '';
            this.errorDetails = '';
        }
    }
}