public with sharing class COMM_SalesAddressDetailsController {
    // multiple builder seller start
@AuraEnabled
public static List<AddressWrapper> getApplicantAddressesForOpportunityBuilderSeller(Id opportunityId) {
    try {
        if (String.isBlank(opportunityId)) {
            return new List<AddressWrapper>();
        }

        List<Applicant_Address__c> addresses = [
            SELECT Id, Address_Type__c, Pincode__c, Address_Ownership__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Current_Address_Proof__c,
                   Address_Source__c, Pincode__r.Name, Pincode__r.City__r.Name, Pincode__r.State__c, Pincode__r.City__r.State_Name__c,
                   Applicant__c, Applicant__r.Name, Applicant__r.Loan_Application__c
            FROM Applicant_Address__c
            WHERE Applicant__r.Loan_Application__c = :opportunityId and(Applicant__r.Applicant_Type__c='Builder' or Applicant__r.Applicant_Type__c = 'Seller')
            Order by Applicant__r.Name ];

        List<AddressWrapper> wrappedAddresses = new List<AddressWrapper>();
         Set<Id> applicantIds = new Set<Id>();

        for (Applicant_Address__c addr : addresses) {
            if (addr.Applicant__c != null) {
                applicantIds.add(addr.Applicant__c);
            }
        }

        Map<Id, Boolean> crifApplicantMap = new Map<Id, Boolean>();

        for (Document_Details__c doc : [SELECT Applicant__c FROM Document_Details__c WHERE Applicant__c IN :applicantIds AND Loan_Application__c = :opportunityId AND Name = 'CRIF']) {
            crifApplicantMap.put(doc.Applicant__c, true);
        }

        for (Applicant_Address__c addr : addresses) {
            AddressWrapper wrapper = new AddressWrapper();
            wrapper.Id = addr.Id;
            wrapper.addType = addr.Address_Type__c;
            wrapper.addLine1 = addr.Address_Line_1__c;
            wrapper.addLine2 = addr.Address_Line_2__c;
            wrapper.addLine3 = addr.Address_Line_3__c;
            wrapper.source = addr.Address_Source__c;
            wrapper.pincode = addr.Pincode__r != null ? addr.Pincode__r.Name : null;
            wrapper.addPincode = addr.Pincode__c;
            wrapper.city = addr.Pincode__r != null && addr.Pincode__r.City__r != null ? addr.Pincode__r.City__r.Name : null;
            wrapper.state = addr.Pincode__r != null && addr.Pincode__r.City__r != null ? addr.Pincode__r.City__r.State_Name__c : null;
            wrapper.addProof = addr.Current_Address_Proof__c;
            wrapper.addOwnership = addr.Address_Ownership__c;
            wrapper.applicantId = addr.Applicant__c;
            wrapper.sellerName = addr.Applicant__r != null ? addr.Applicant__r.Name : null;
            wrapper.disableEdit = crifApplicantMap.containsKey(addr.Applicant__c);
            wrappedAddresses.add(wrapper);
        }

        return wrappedAddresses;

    } catch (Exception ex) {
        System.debug('Error in getApplicantAddressesForOpportunity: ' + ex.getMessage());
        throw new AuraHandledException('Failed to retrieve applicant addresses: ' + ex.getMessage());
    }
}

    @AuraEnabled
    public static List<Application_Applicant__c> getApplicantsForOpportunity(Id opportunityId) {
        System.debug('Fetching applicants for Opportunity Id: ' + opportunityId);
        if (String.isBlank(opportunityId)) return new List<Application_Applicant__c>();
        return [SELECT Id, Name, Applicant_Type__c FROM Application_Applicant__c WHERE Loan_Application__c = :opportunityId ];
    }
// multiple builder seller end 


    @AuraEnabled
    public static List<AddressWrapper> getAddressesByApplicantId(Id applicantId, Id recordId) {
        try {
            //HL-Ishi-15/9/2025
            Map<String,String> inputMapUtility = new  Map<String,String>();
            Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
            Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
            //HL-Ishi-15/9/2025

            String query =
                'SELECT Id, Address_Type__c, Pincode__c, Address_Ownership__c, ' +
                'Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, ' +
                'Current_Address_Proof__c, Address_Source__c,Document_Details__c,Document_Details__r.Name, ' +
                'Pincode__r.Name, Pincode__r.City__r.Name, ' +
                'Pincode__r.State__c, Pincode__r.City__r.State_Name__c, ' +
                'HL_Address_Line_1__c, HL_Address_Line_2__c, HL_Address_Line_3__c,Applicant__r.Name ' +
                'FROM Applicant_Address__c ' +
                'WHERE Applicant__c = :applicantId ';

           
            if (isHlRelated) {
                query += 
                    'AND (Address_Type__c = \'Registered Office\' ' +
                    'OR Address_Type__c = \'Current\' ' +
                    'OR Address_Type__c = \'Permanent\') ';
            }
            List<Applicant_Address__c> addresses = Database.query(query);
            
            List<AddressWrapper> wrappedAddresses = new List<AddressWrapper>();

            if (addresses != null && !addresses.isEmpty()) {
                for (Applicant_Address__c addr : addresses) {
                    AddressWrapper wrapper = new AddressWrapper();
                    wrapper.Id = addr.Id;
                    wrapper.addType = addr.Address_Type__c;
                    wrapper.addLine1 = addr.Address_Line_1__c;
                    wrapper.addLine2 = addr.Address_Line_2__c;
                    wrapper.addLine3 = addr.Address_Line_3__c;
                    wrapper.source = addr.Address_Source__c;
                    wrapper.pincode = addr.Pincode__r?.Name;
                    wrapper.addPincode = addr.Pincode__c;
                    wrapper.city = addr.Pincode__r?.City__r?.Name;
                    wrapper.state = addr.Pincode__r.City__r.State_Name__c;
                    wrapper.addProof = addr.Current_Address_Proof__c;
                    wrapper.addOwnership = addr.Address_Ownership__c;
                    wrapper.addressSourceDoc= addr.Document_Details__r.Name;
                    wrapper.sellerName = addr.Applicant__r != null ? addr.Applicant__r.Name : null;
                    if(isHlRelated){
                        wrapper.deleteAddressDisable = (addr.Document_Details__c == null)?false:true;
                    }
                    else{
                         wrapper.deleteAddressDisable = false;
                    }
                    wrappedAddresses.add(wrapper);

                }
            }
            System.debug('wrappedAddresses----'+wrappedAddresses);
            return wrappedAddresses;

        } catch (Exception ex) {
            System.debug('Error in getAddressesByApplicantId: ' + ex.getMessage());
            throw new AuraHandledException('Failed to retrieve addresses: ' + ex.getMessage());
        }
    }
        @AuraEnabled
        public static Application_Collateral__c getAddressesByBuilder(String recordId) {
            List<Application_Collateral__c> builderDetailList=new List<Application_Collateral__c>();
            try{
         builderDetailList=[select id,HL_Loan_Application__c,Name_of_Collateral__c,Name,HL_Loan_Application__r.name,Collateral__r.APF__c,Collateral__r.name ,
        Collateral__r.Builder__r.Address_1__c,Collateral__r.Builder__r.Address_2__c,Collateral__r.Builder__r.Address_3__c,Collateral__r.Builder__r.Pincode_Master__r.Name,
        Collateral__r.Builder__r.Pincode_Master__r.City__r.name,Collateral__r.Builder__r.Pincode_Master__r.State__c
        from Application_Collateral__c where HL_Loan_Application__c=:recordId AND Collateral__r.APF__c='Yes'];
        if(builderDetailList.size()>0){
            return builderDetailList[0];
        }else {
            
                return null;
            }
            }catch(exception e){
                system.debug('exception e'+e);
                return null;
            }
        }

    @AuraEnabled
    public static Map<String, String> upsertAddress(Map<String, String> inputMap) {
        try {
            String addressId = inputMap.get('Id');
            String addType = inputMap.get('addType');
            String addProof = inputMap.get('addProof');
            String addLine1 = inputMap.get('addLine1');
            String addLine2 = inputMap.get('addLine2');
            String addLine3 = inputMap.get('addLine3');
            String addPincode = inputMap.get('addPincode');
            String applicantId = inputMap.get('applicantId');
            String loanId = inputMap.get('loanId');
            String addOwnership = inputMap.get('addOwnership');
            Applicant_Address__c addr;

            if (!String.isBlank(addressId)) {
                addr = [SELECT Id, Address_Type__c,Applicant__c,Address_Ownership__c, Current_Address_Proof__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Address_Source__c, Pincode__c FROM Applicant_Address__c WHERE Id = :addressId LIMIT 1];
            } else {
                addr = new Applicant_Address__c();
            }

            addr.Address_Type__c = addType;
            addr.Current_Address_Proof__c = addProof;
            addr.Address_Ownership__c = addOwnership;
            addr.Address_Line_1__c = addLine1;
            addr.Address_Line_2__c = addLine2;
            addr.Address_Line_3__c = addLine3;
            addr.Address_Source__c = 'Manual';
            addr.Pincode__c = addPincode;
            addr.Applicant__c = applicantId;
            addr.Loan_Application__c = loanId;

            if (String.isBlank(addressId)) {
                insert addr;
            } else {
                update addr;
            }

            Map<String, String> response = new Map<String, String>();
            response.put('status', 'success');
            response.put('recordId', addr.Id);
            return response;

        } catch (Exception ex) {
            System.debug('Error in upsertAddress: ' + ex.getMessage());
            throw new AuraHandledException('Failed to save address: ' + ex.getMessage());
        }
    }

    public class AddressWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String addType;
        @AuraEnabled public String addLine1;
        @AuraEnabled public String addLine2;
        @AuraEnabled public String addLine3;
        @AuraEnabled public String source;
        @AuraEnabled public String pincode;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String addProof;
        @AuraEnabled public String addPincode;
        @AuraEnabled public String applicantId;
        @AuraEnabled public String addOwnership;
        @AuraEnabled public Boolean deleteAddressDisable;
        @AuraEnabled public String addressSourceDoc;
        @AuraEnabled public String sellerName; 
        @AuraEnabled public Boolean disableEdit;

        public AddressWrapper() {}
    }
}