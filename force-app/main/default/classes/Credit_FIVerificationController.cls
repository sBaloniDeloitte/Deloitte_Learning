public with sharing class Credit_FIVerificationController {

    
   

    static string conLabels = 
    (Constants__mdt.getInstance('FiInitiation1') != null ? Constants__mdt.getInstance('FiInitiation1').Value__c : '') + ',' + 
    (Constants__mdt.getInstance('FiInitiation2') != null ? Constants__mdt.getInstance('FiInitiation2').Value__c : '') + ',' + 
    (Constants__mdt.getInstance('FiInitiation3') != null ? Constants__mdt.getInstance('FiInitiation3').Value__c : '');

public static Map<string, string> constants = Utility.getConstants(conLabels);

    public static Set<Id> assignedUsers = new Set<Id>();
    //getting the value of constants
    @AuraEnabled
    public static Map<string, string> getConstants(){
        return constants;
    }
        
@AuraEnabled
public static Map<Id, AssigneeWrapperNew> getAssigneeInfoBulk(List<Id> applicantIds, String verificationType) {
    // Defensive check
    if (applicantIds == null || applicantIds.isEmpty()) {
        return new Map<Id, AssigneeWrapperNew>();
    }

    List<String> recordTypes = new List<String>{'Business Verification', 'Residence Verification','Collateral Verification'};
    List<String> recordTypesPD = new List<String>{'Personal Discussion'};
    Set<Id> assignedUsers = new Set<Id>();
    Set<Id> acMem = new Set<Id>();
    String memberRole = (verificationType == 'Vendor PD') ? 'PD Admin' : 'FI Admin';
    List<String> stages = new List<String>{constants.get('Approved_1'), constants.get('Approved_2')};
     List<Application_Applicant__c> apps = [
        SELECT Loan_Application__c 
        FROM Application_Applicant__c 
        WHERE Id IN :applicantIds 
        LIMIT 1
    ];

    Id loanAppId  = apps.isEmpty() ? null : apps[0].Loan_Application__c;

    // 1. Query all addresses for all applicants in bulk
    List<Applicant_Address__c> applicantAddresses = [
        SELECT Id, Applicant__c, City__c, Name, Applicant__r.Name, Address_Type__c, Pincode__c, Address_Line_1__c, Full_Address1__c 
        FROM Applicant_Address__c 
        WHERE Applicant__c IN :applicantIds
        AND Address_Type__c != 'BSA' 
        AND Pincode__c != null 
        AND Address_Line_1__c != null
        AND Full_Address1__c != null
    ];
    List<Application_Collateral__c> collaterals = [
        SELECT Id, Collateral__c, Collateral__r.Address_Line_1__c, Collateral__r.Address_Line_2__c, 
                                                    Collateral__r.Address_Line_3__c, Collateral__r.Block_Taluka__c, Collateral__r.Building_Street_Name__c, Collateral__r.District__c, Collateral__r.Landmark__c, Collateral__r.Plot_Number__c, 
                                                    Collateral__r.State__c,Collateral__r.Pincode__c,Collateral__r.Pincode__r.City__c
 FROM Application_Collateral__c WHERE HL_Loan_Application__c = :loanAppId
    ];
    List<AddressWrapper> allAddresses = new List<AddressWrapper>();

// Applicant Addresses
for (Applicant_Address__c addr : applicantAddresses) {
    allAddresses.add(new AddressWrapper(
        addr.Id,
        addr.Applicant__c,
        addr.City__c,
        addr.Name,
        String.valueOf(addr.Pincode__c),
        addr.Address_Line_1__c,
        addr.Full_Address1__c
    ));
}
/*for (Application_Collateral__c col : collaterals) {
    if (col.Collateral__r != null) {
        allAddresses.add(new AddressWrapper(
            col.Id,
            'a00Bg00000IczJRIAZ',
            col.Collateral__r.Pincode__r.City__c,
            '',
            String.valueOf(col.Collateral__r.Pincode__c),
            col.Collateral__r.Address_Line_1__c,
            ''
        ));
    }
}*/
    // Map to group addresses by applicant Id
    Map<Id, List<AddressWrapper>> applicantToAddresses = new Map<Id, List<AddressWrapper>>();
    Set<String> citySet = new Set<String>();
    Set<Id> allAddressIds = new Set<Id>();
    
    for (AddressWrapper addr : allAddresses) {
        if (!applicantToAddresses.containsKey(addr.applicantId)) {
            applicantToAddresses.put(addr.applicantId, new List<AddressWrapper>());
        }
        applicantToAddresses.get(addr.applicantId).add(addr);

        citySet.add(addr.city);
        allAddressIds.add(addr.addressId);
    }

    // 2. Query Application_Verification__c for all these addresses in bulk
    String baseQuery = 'SELECT Id, Vendor__c, Vendor_Admin__c, CreatedDate, Stage__c, RecordType.Name, Address__c, Personal_Discussion_Type__c '
                     + 'FROM Application_Verification__c WHERE Address__c IN :allAddressIds AND Stage__c NOT IN :stages ';
    if (verificationType == 'Vendor PD') {
        baseQuery += 'AND RecordType.Name IN :recordTypesPD AND Personal_Discussion_Type__c = :verificationType';
    } else if (verificationType == 'FI') {
        baseQuery += 'AND RecordType.Name IN :recordTypes';
    }
    List<Application_Verification__c> allVerifications = Database.query(baseQuery);

    // Map Address Id to verifications
    Map<Id, List<Application_Verification__c>> addressToVerifications = new Map<Id, List<Application_Verification__c>>();
    for (Application_Verification__c av : allVerifications) {
        if (!addressToVerifications.containsKey(av.Address__c)) {
            addressToVerifications.put(av.Address__c, new List<Application_Verification__c>());
        }
        addressToVerifications.get(av.Address__c).add(av);

        if (av.Vendor_Admin__c != null) {
            assignedUsers.add(av.Vendor_Admin__c);
        }
    }

    // 3. Query Vendor_Pincode__c by city in bulk
    List<Vendor_Pincode__c> serviceablePincodes = [
        SELECT Id, Account__c, Pincode_Master__r.City__r.Name 
        FROM Vendor_Pincode__c 
        WHERE Pincode_Master__r.City__r.Name IN :citySet
    ];

    Map<String, Set<Id>> cityToAccountIdsMap = new Map<String, Set<Id>>();
    for (Vendor_Pincode__c pincode : serviceablePincodes) {
        if (!cityToAccountIdsMap.containsKey(pincode.Pincode_Master__r.City__r.Name)) {
            cityToAccountIdsMap.put(pincode.Pincode_Master__r.City__r.Name, new Set<Id>());
        }
        cityToAccountIdsMap.get(pincode.Pincode_Master__r.City__r.Name).add(pincode.Account__c);
    }

    // 4. Query AccountTeamMember by all accounts
    List<Id> accountIdsList = new List<Id>();
    for (Set<Id> accountIds : cityToAccountIdsMap.values()) {
        accountIdsList.addAll(accountIds);
    }

    List<AccountTeamMember> accountTeamMembers = [
        SELECT Id, UserId, User.Name, AccountId 
        FROM AccountTeamMember 
        WHERE AccountId IN :accountIdsList 
        AND TeamMemberRole = :memberRole
    ];

    Map<Id, List<AccountTeamMember>> accountIdToTeamMembersMap = new Map<Id, List<AccountTeamMember>>();
    for (AccountTeamMember atm : accountTeamMembers) {
        if (!accountIdToTeamMembersMap.containsKey(atm.AccountId)) {
            accountIdToTeamMembersMap.put(atm.AccountId, new List<AccountTeamMember>{atm});
        } else {
            accountIdToTeamMembersMap.get(atm.AccountId).add(atm);
        }
        acMem.add(atm.UserId);
    }

    // 5. Build results per applicant
    Map<Id, Map<String, List<Map<String, String>>>> resultMap = new Map<Id, Map<String, List<Map<String, String>>>>();
    Map<Id, Map<String, String>> assigneeMap1 = new Map<Id, Map<String, String>>();
    Set<Id> currentAssigneeIds = new Set<Id>();
    Id lastAssigneeId = null;

    for (Id applicantId : applicantIds) {
        List<AddressWrapper> addresses = applicantToAddresses.get(applicantId);
        if (addresses == null || addresses.isEmpty()) {
            continue;
        }

        for (AddressWrapper address : addresses) {
            String city = address.city;
            Set<Id> accountIds = cityToAccountIdsMap.get(city);

            if (accountIds == null || accountIds.isEmpty()) {
                continue;
            }

            List<Map<String, String>> vendorList = new List<Map<String, String>>();
            for (Id accountId : accountIds) {
                if (accountIdToTeamMembersMap.containsKey(accountId)) {
                    for (AccountTeamMember atm : accountIdToTeamMembersMap.get(accountId)) {
                        Map<String, String> vendorMap = new Map<String, String>();
                        vendorMap.put('value', atm.UserId);
                        vendorMap.put('label', atm.User.Name);
                        vendorList.add(vendorMap);
                    }
                }
            }

            if (!vendorList.isEmpty()) {
                if (!resultMap.containsKey(applicantId)) {
                    resultMap.put(applicantId, new Map<String, List<Map<String, String>>>());
                }
                resultMap.get(applicantId).put(address.addressId, vendorList);
            }

            List<Application_Verification__c> verificationRecords = addressToVerifications.get(address.addressId);
            String currentAssignee = null;
            if (verificationRecords != null && !verificationRecords.isEmpty()) {
                Map<Id, DateTime> vendorToCreatedDateMap = new Map<Id, DateTime>();
                for (Application_Verification__c record : verificationRecords) {
                    vendorToCreatedDateMap.put(record.Vendor_Admin__c, record.CreatedDate);
                }

                DateTime latestDate = System.now();
                for (Id vendorId : vendorToCreatedDateMap.keySet()) {
                    if (vendorToCreatedDateMap.get(vendorId) < latestDate) {
                        latestDate = vendorToCreatedDateMap.get(vendorId);
                        currentAssignee = vendorId;
                        assignedUsers.add(currentAssignee);
                    }
                }
            }

            if (assignedUsers.size() == acMem.size()) {
                assignedUsers.clear();
            }

            if (currentAssignee != null) {
                currentAssigneeIds.add(currentAssignee);
                lastAssigneeId = currentAssignee;
            } else {
                if (!accountIdToTeamMembersMap.isEmpty()) {
                    Boolean assigned = false;
                    for (Id accId : accountIds) {
                        if (accountIdToTeamMembersMap.containsKey(accId)) {
                            for (AccountTeamMember atm : accountIdToTeamMembersMap.get(accId)) {
                                if (!assignedUsers.contains(atm.UserId)) {
                                    assigneeMap1.put(address.addressId, new Map<String, String>{
                                        'assigneeID' => atm.UserId,
                                        'assigneeName' => atm.User.Name
                                    });
                                    assigned = true;
                                    break;
                                }
                            }
                        }
                        if (assigned) break;
                    }
                }
            }
        }
        system.debug('check the assignemnt-->'+assigneeMap1);
        system.debug('check the size-->'+assignedUsers.size());

    }

    // 6. Get last assignee name for all applicants collectively (optional - adapt if needed)
    Map<Id, User> usersMap = new Map<Id, User>();
    if (!currentAssigneeIds.isEmpty()) {
        usersMap = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN :currentAssigneeIds]);
    }

    // 7. Construct return map per applicantId
    Map<Id, AssigneeWrapperNew> result = new Map<Id, AssigneeWrapperNew>();
    for (Id applicantId : applicantIds) {
        String assigneeName = null;
        Id assigneeID = null;
        
        if (lastAssigneeId != null && usersMap.containsKey(lastAssigneeId)) {
            assigneeName = usersMap.get(lastAssigneeId).Name;
            assigneeID = usersMap.get(lastAssigneeId).Id;
        }

        Map<String, List<Map<String, String>>> resMapForApplicant = resultMap.containsKey(applicantId) ? resultMap.get(applicantId) : new Map<String, List<Map<String, String>>>();
        Map<Id, Map<String, String>> assigneeMapForApplicant = new Map<Id, Map<String, String>>();
        // Filter assigneeMap1 entries only for this applicant's addresses
        for (Id addrId : assigneeMap1.keySet()) {
            Boolean found = false;
            List<AddressWrapper> addrs = applicantToAddresses.get(applicantId);
            if (addrs != null) {
                for (AddressWrapper addr : addrs) {
                    if (addr.addressId == addrId) {
                        //assigneeMapForApplicant = assigneeMap1.get(addrId);
                         assigneeMapForApplicant.put(addr.addressId, assigneeMap1.get(addr.addressId));
                        // found = true;
                        // break;
                    }
                }
            }
            // if (found) break;
        }

        AssigneeWrapperNew aw = new AssigneeWrapperNew(resMapForApplicant, assigneeMapForApplicant, assigneeName, assigneeID);
        result.put(applicantId, aw);
    }

    return result;
}


    @AuraEnabled
    public static AssigneeWrapperMain assigneeList(String loanId, String verificationType) {
        AssigneeWrapperMain am = New AssigneeWrapperMain();
        am.assigneeList= new List<PickListValueSet>();
        String memberRole= 'FI Admin';
        if(verificationType== 'Vendor PD'){
            memberRole= 'PD Admin';
        }
        if(constants.get('FI_Timestamp')=='true') {
            Opportunity loan = [SELECT Branch_Master__c
                                FROM Opportunity 
                                WHERE Id = :loanId
                                LIMIT 1];
            List<String> stages= new List<String>();
            stages.add(constants.get('Approved_1'));
            stages.add(constants.get('Approved_2'));

            List<String> recordTypes = new List<String>{'Business Verification', 'Residence Verification', 'Personal Discussion'};
            String branchId = loan.Branch_Master__c;
            String query = 'SELECT Id, Vendor__c, Loan_Application__r.Branch_Master__c, CreatedDate FROM Application_Verification__c Where Loan_Application__r.Branch_Master__c=:branchId and Stage__c NOT IN :stages and RecordType.Name IN :recordTypes ';

            if(verificationType== 'Vendor PD'){
                query = query + ' AND Personal_Discussion_Type__c = \'Vendor PD\' ';
            }

            query = query + ' ORDER BY CreatedDate ASC';
            List<Application_Verification__c>  latestFi = Database.query(query);
            // List<Application_Verification__c>  latestFi = [SELECT Id, Vendor__c, Loan_Application__r.Branch_Master__c, CreatedDate 
            //                                                 FROM Application_Verification__c 
            //                                                 Where Loan_Application__r.Branch_Master__c=:loan.Branch_Master__c and (Stage__c!=:constants.get('Approved_1') AND Stage__c!=:constants.get('Approved_2')) and RecordType.Name!=: constants.get('FCU') and RecordType.Name != 'Hunter Verification' //dynamic query
            //                                                 ORDER BY CreatedDate ASC 
            //                                                 ];
            system.debug('latestFi:: '+latestFi);

            List<AccountTeamMember> actMembersBranch = [Select Id, UserId, User.Name from AccountTeamMember where AccountId =: loan.Branch_Master__c and Account.RecordType.Name = 'Branch' and TeamMemberRole = :memberRole];
            system.debug('actMembersBranch:: '+actMembersBranch);
            List<Id> branchUserIds = new List<Id>();
            for(AccountTeamMember ac: actMembersBranch){
                branchUserIds.add(ac.UserId);
            }
            List<AccountTeamMember> actMemberVendor = [Select Id, UserId, User.Name, AccountId from AccountTeamMember where UserId in: branchUserIds and Account.RecordType.Name = 'Partner'];
            system.debug('actMemberVendor:: '+actMemberVendor);
            List<Id> vendorAccIds = new List<Id>();
            Map<Id,AccountTeamMember> vendorToMemberMap = new Map<Id,AccountTeamMember>();
            for(AccountTeamMember ac:actMemberVendor){
                vendorAccIds.add(ac.AccountId);
                vendorToMemberMap.put(ac.AccountId,ac);
            }
            if(latestFi.size()>0){
                Map<Id,DateTime> vendorToCreatedDateMap =new Map<Id,DateTime>();
                for(Application_Verification__c ap : latestFi){
                    vendorToCreatedDateMap.put(ap.Vendor__c,ap.CreatedDate);
                }
                system.debug('vendorToCreatedDateMap:: '+vendorToCreatedDateMap);
                String currentAssignee;
                for(Id i : vendorAccIds){
                    if(!vendorToCreatedDateMap.containsKey(i)){
                        currentAssignee = i;
                        break;
                    }
                }
                system.debug('currentAssignee:: '+currentAssignee);
                if(currentAssignee == null){
                    DateTime dt = System.now();
                    for(Id i : vendorToCreatedDateMap.keySet()){
                        if(vendorToCreatedDateMap.get(i)<dt){
                            dt = vendorToCreatedDateMap.get(i);
                            currentAssignee = i;
                        }
                    }
                    if(currentAssignee != null){
                        am.assigneeName=vendorToMemberMap.get(currentAssignee).User.Name;
                        am.assigneeID=vendorToMemberMap.get(currentAssignee).UserId;
                    }
                }
                else{
                    am.assigneeName=vendorToMemberMap.get(currentAssignee).User.Name;
                    am.assigneeID=vendorToMemberMap.get(currentAssignee).UserId;
                }
                system.debug('currentAssignee1:: '+currentAssignee);
            }
            else{
                if(!actMemberVendor.isEmpty()){
                am.assigneeName=actMemberVendor[0].User.Name;
                am.assigneeID=actMemberVendor[0].UserId;
                system.debug('actMemberVendor:: '+actMemberVendor[0]);
                }
            }
            for(AccountTeamMember ac:actMemberVendor){
                PickListValueSet pickListValue = new PickListValueSet();
                // pickListValue.label = branchUserMap.get(ids).User__r.Name;
                // pickListValue.value = branchUserMap.get(ids).User__c;
                pickListValue.label = ac.User.Name;
                pickListValue.value = ac.UserId;
                am.assigneeList.add(pickListValue);
            }

          return am;
        } 
       
        return am;
    }



    public class AssigneeWrapperMain{
        @AuraEnabled
        public string assigneeName {get;set;}
        @AuraEnabled
        public Id assigneeID {get;set;}
        @AuraEnabled
        public List<PickListValueSet> assigneeList {get;set;}
    }

    @AuraEnabled
    public static List<ApplicantWrapper> getApplicantTable(String loanId, string verificationType){
        try {
            
            String vendorPDRecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c','Personal_Discussion');
            List<String> recordTypes = new List<String>{'Business Verification', 'Residence Verification','Collateral Verification'};
            List<ApplicantWrapper> applicantWrapperList = new  List<ApplicantWrapper>();
            List<ApplicantWrapper> applicantWrapperListWaivedList = new  List<ApplicantWrapper>();
            List<ApplicantWrapper> applicantWrapperListNotWaivedList = new  List<ApplicantWrapper>();
            Map<String, String> applicantToCustomer= new Map<String, String>();
            Map<String,FI_Applicable_Address_type__mdt> allMetaData = FI_Applicable_Address_type__mdt.getAll();
            List<Application_Applicant__c> apDetList = [Select Id, Name, First_Name__c, Last_Name__c, Applicant_Type__c, Applicant_Name__c, Customer__c,Customer_Type__c,Loan_Application__r.Product__c from Application_Applicant__c where Loan_Application__c=:loanId ORDER BY Applicant_Type__c ];
            List<Applicant_Address__c> addrList = [Select Id,Address_Type__c,Full_Address__c,Waived_by__c,Visit_Waiver_Mode__c,Applicant__c,Plot_Number__c,Floor_Number__c,Building_Street_Name__c,Landmark__c ,Pincode__r.Name,Full_Address1__c,State__c,Address_Line_1__c from Applicant_Address__c where Applicant__c in: apDetList and Address_Type__c!=null AND Address_Type__c !='BSA' AND Full_Address1__c != null AND Address_Line_1__c != null];
           Map<Id,List<Applicant_Address__c>> apToAddrMap = new Map<Id,List<Applicant_Address__c>>();
           List<Id> applicantIds = new List<Id>(); 
           List<PickListValueSet> directorList= new List<PickListValueSet>();
            List<PickListValueSet> internalList= new List<PickListValueSet>();
            String productName = apDetList[0].Loan_Application__r.Product__c;
           for(Applicant_Address__c apAddr : addrList){
              if(apToAddrMap.containsKey(apAddr.Applicant__c)){
                   apToAddrMap.get(apAddr.Applicant__c).add(apAddr);
                }else{
                   apToAddrMap.put(apAddr.Applicant__c,new List<Applicant_Address__c>{apAddr});
                }
            }
            for(Application_Applicant__c app: apDetList){
                 applicantIds.add(app.Id);
                if(app.Customer__c!= null){
                    applicantToCustomer.put(app.Customer__c, app.Id);
                }
                if(app.Customer_Type__c == 'Individual' 
                ){
                    PickListValueSet newContact= new PickListValueSet();
                    newContact.label = app.Name;
                    newContact.value = app.Id;
                    directorList.add(newContact);
                }

            }
            Map<Id, String> appColIdToColAddressMap = new Map<Id, String>();
            Map<String,String> inputMap = new Map<String,String>{'oppId' => loanId};
            Utility_v1.ProductWrapper productInfo = Utility_v1.getProductDetails(inputMap);
             if(productInfo != null && productInfo.isHLRelated == false){
                
            for (Application_Collateral__c itrAppCol : [SELECT Id, Collateral__c, Collateral__r.Address_Line_1__c, Collateral__r.Address_Line_2__c, 
                                                    Collateral__r.Address_Line_3__c, Collateral__r.Block_Taluka__c, Collateral__r.Building_Street_Name__c, Collateral__r.District__c, Collateral__r.Landmark__c, Collateral__r.Plot_Number__c, 
                                                    Collateral__r.State__c FROM Application_Collateral__c WHERE HL_Loan_Application__c = :loanId]) 
            {
                Collateral__c col = itrAppCol.Collateral__r;
                List<String> addressString = new List<String>();
                addressString.add(String.isNotBlank(col.Address_Line_1__c) ? col.Address_Line_1__c : '');
                addressString.add(String.isNotBlank(col.Address_Line_2__c) ? col.Address_Line_2__c : '');
                addressString.add(String.isNotBlank(col.Address_Line_3__c) ? col.Address_Line_3__c : '');
                addressString.add(String.isNotBlank(col.Block_Taluka__c) ? col.Block_Taluka__c : '');
                addressString.add(String.isNotBlank(col.Building_Street_Name__c) ? col.Building_Street_Name__c : '');
                addressString.add(String.isNotBlank(col.District__c) ? col.District__c : '');
                addressString.add(String.isNotBlank(col.Landmark__c) ? col.Landmark__c : '');
                addressString.add(String.isNotBlank(col.Plot_Number__c) ? col.Plot_Number__c : '');
                addressString.add(String.isNotBlank(col.State__c) ? col.State__c : '');
                String fullAddress = String.join(addressString, ', ');
                appColIdToColAddressMap.put(itrAppCol.Id, fullAddress);
            }
            system.debug('appColIdToColAddressMap ' + appColIdToColAddressMap);

             }
            
            List<AccountTeamMember> teamMembers = [
            SELECT Id, UserId,User.name, TeamMemberRole, Account.Name
            FROM AccountTeamMember
            WHERE Account.Name = 'Internal Employee FI' 
            AND TeamMemberRole = 'FI admin'
            ];

        for(AccountTeamMember atm : teamMembers) {
            PickListValueSet pickVal = new PickListValueSet();
            pickVal.label = atm.User.name;
            pickVal.value = atm.UserId;
            internalList.add(pickVal);
        }
            
            List<Contact> contactList = [SELECT Id, Name, Title, AccountId  FROM Contact WHERE AccountId = :applicantToCustomer.keySet()];
            Map<Id, AssigneeWrapperNew> assigneeWrapperMap = getAssigneeInfoBulk(applicantIds, verificationType);
            system.debug('apDetList:: '+apDetList);
            system.debug('addrList:: '+addrList);
 
            for(Application_Applicant__c ap : apDetList){
                if(apToAddrMap.containsKey(ap.id)){
                    AssigneeWrapperNew assigneeWrapper = assigneeWrapperMap.get(ap.Id);
                        //  Map<String, Map<String, List<Map<String, String>>>> assigneeMap = assigneeWrapper.assigneeInfo; 
                        //  Map<String , Map<String,String>> assigneeMap1 = assigneeWrapper.assigneeMap1;
                        Map<String, List<Map<String, String>>> assigneeMap = (assigneeWrapper != null) ? assigneeWrapper.assigneeInfo : new Map<String, List<Map<String, String>>>();                    
                        Map<Id, Map<String, String>>assigneeMap1 = (assigneeWrapper != null) ? assigneeWrapper.assigneeMap : new Map<Id, Map<String, String>>();
                        //Map<String, String> assigneeMap1 = (assigneeWrapper != null) ? assigneeWrapper.assigneeMap : new Map<String, String>();
                        System.debug('assigneeMap: ' + assigneeMap);
                        System.debug('assigneeMap1: ' + assigneeMap1);
                List<Applicant_Address__c> appAddList=apToAddrMap.get(ap.id);
                system.debug('appAddList:: '+appAddList);
                    for(Applicant_Address__c iterAdd:appAddList){
                        FI_Applicable_Address_type__mdt applicableMeta = new FI_Applicable_Address_type__mdt();
                     
                        for(FI_Applicable_Address_type__mdt fiMeta : allMetaData.values()){
                            if(fiMeta.Applicable_Address_type__c==iterAdd.Address_Type__c){
                                applicableMeta= fiMeta;
                                break;
                            }
                        }
                        
                        if(applicableMeta.Visit_type__c!= null){
                            ApplicantWrapper a = new ApplicantWrapper();
                            a.applicantId = ap.Id;
                            a.applicantName = ap.Applicant_Name__c; // ap.First_Name__c+' '+(ap.Last_Name__c != null ? ap.Last_Name__c : '');
                            a.applicantType = ap.Applicant_Type__c;
                            a.addressId = iterAdd.Id;
                            a.recordTypeName=applicableMeta.Visit_type__c.replaceAll('_',' ');
                            if(verificationType == 'Vendor PD'){
                                a.addressType = iterAdd.Address_Type__c;
                                a.waiverFlag = constants.get('Not_Waived');
                                a.waivedBy='';
                                a.addressValue=iterAdd.Full_Address1__c ;
                            }else{
                                a.addressType = iterAdd.Address_Type__c;
                                a.waiverFlag = iterAdd.Visit_Waiver_Mode__c!=null?constants.get('Waived'):constants.get('Not_Waived');
                                if(iterAdd.Visit_Waiver_Mode__c!=null){
                                    a.isPaleColour=true;
                                }
                                a.waivedBy=iterAdd.Waived_by__c;
                                a.addressValue=iterAdd.Full_Address1__c ;
                            }
                            

                                if (assigneeMap.containsKey(iterAdd.Id)) {
                                List<Map<String, String>> assigneeList = assigneeMap.get(iterAdd.Id);
                                system.debug('Assignee list for applicant --> ' + assigneeList);
                                if (!assigneeList.isEmpty() && Constants__mdt.getInstance('roundRobinAllocation').value__c == 'True') {
   
                                    if (!assigneeMap1.isEmpty() && assigneeMap1.containsKey(iterAdd.Id)) {
                                        Map<String, String> assigneeDetails = assigneeMap1.get(iterAdd.Id);
                                        a.selectedAssignee = assigneeDetails.get('assigneeID');
                                        a.selectedAssigneeName = assigneeDetails.get('assigneeName');
                                    }
                                }
                                // Iterate through the assignees and create the picklist
                                List<PickListValueSet> pickList = new List<PickListValueSet>();
                                for (Map<String, String> assignee : assigneeList) {
                                    PickListValueSet newPickList = new PickListValueSet();
                                    newPickList.label = assignee.get('label');
                                    newPickList.value = assignee.get('value');
                                    pickList.add(newPickList);
                                }
                                a.asigneeList = pickList;
                            } else {
                                a.asigneeList = new List<PickListValueSet>();
                            }
                            
                            if( ap.Customer_Type__c== 'Non Individual' ){
                                a.directorList = directorList;
                                a.isDirectorReq= true;
                            }
                             a.internalList = internalList;
                            if(verificationType == 'Vendor PD'){
                                applicantWrapperListNotWaivedList.add(a);
                            }else {
                                if(iterAdd.Visit_Waiver_Mode__c==null){
                                    applicantWrapperListNotWaivedList.add(a);
                                }else{
                                    applicantWrapperListWaivedList.add(a);
                                }
                            }
                            
                        }
                        
                    }
                }
            }
            applicantWrapperList.addAll(applicantWrapperListNotWaivedList);
            applicantWrapperList.addAll(applicantWrapperListWaivedList);
            //Set<Id> appColIdsList = appColIdToColAddressMap.keySet(); //since not working in database query string
            String query= 'SELECT Name, Id,Shared_Applicant_Ids__c, Customer_Name__c, Applicant__c, Stage__c, Stantard_Remark__c, Address__c, Address_Type__c,RecordTypeId, RecordType.Name, Assigned_To_User__c,';
            query+= 'Assigned_To_User__r.Name,Status__c, OverAll_Status__c,Vendor_Admin__c,Applicant__r.Name,Applicant__r.First_Name__c, Applicant__r.Last_Name__c,';
            query+= 'Owner.Name, CreatedDate,Createdby.Name,Credit_Managers_Disposition__c,Application_Collateral__r.Collateral__r.Pincode__c,Application_Collateral__r.Collateral__c,Application_Collateral__c, Credit_Manager_s_Remarks__c,Completion_Date__c, Related_PD_Applicant__c,';
            query+= 'Related_PD_Applicant__r.Name FROM Application_Verification__c WHERE (Applicant__c IN :apDetList)'; //OR Application_Collateral__c IN :appColIdsList

            if(verificationType == 'Vendor PD'){
                query = query + ' AND RecordTypeId = :vendorPDRecordTypeId AND Personal_Discussion_Type__c= :verificationType ';
            }
            if(verificationType == 'FI'){
                query = query + ' AND RecordType.Name = :recordTypes';
            }
            query = query + ' ORDER BY CreatedDate';
            System.debug('queryy----'+query);
            List<Application_Verification__c> fiList = Database.query(query);

        
            System.debug('fiList:: '+fiList);
            Set<Id> appVerificationIdSet = new Set<Id>();
            Map<Id,String> applicationIdToNoteRemarkMap = new Map<Id,String>();
            Map<Id,String> creditAppverIdToNoteRemarkMap = new Map<Id,string>();
            
            for(Application_Verification__c iterFi : fiList){
                appVerificationIdSet.add(iterFi.Id);
            }
            System.debug('appVerificationIdSet :: ' + appVerificationIdSet);
            // List<Note> noteList = [SELECT Id, ParentId, Body,Title FROM Note WHERE ParentId IN:appVerificationIdSet AND (title = 'Credit Manager Initiation Remarks' OR title='Approved by CM' OR title='Rejected by CM' OR title='Re-initiate by CM')];
            // System.debug('noteList :: ' + noteList);
            // for(ContentNote notes : noteList) {
            //     if(notes.title == 'Credit Manager Initiation Remarks'){
            //          applicationIdToNoteRemarkMap.put(notes.ParentId, notes.Body + '');
            //     }
            //       if(notes.title == 'Approved by CM'){
            //          creditAppverIdToNoteRemarkMap.put(notes.ParentId, notes.Body + '');
            //     }
            //        if(notes.title == 'Rejected by CM'){
            //          creditAppverIdToNoteRemarkMap.put(notes.ParentId, notes.Body + '');
            //     }
            //      if(notes.title == 'Re-initiate by CM'){
            //          creditAppverIdToNoteRemarkMap.put(notes.ParentId, notes.Body + '');
            //     }
               
            // }
            // System.debug('applicationIdToNoteRemarkMap :: ' + applicationIdToNoteRemarkMap);

            // Step 1: Get ContentDocumentLinks for the Application_Verification__c records
List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
 if (!appVerificationIdSet.isEmpty()) {
    cdlList = [
                SELECT ContentDocumentId, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :appVerificationIdSet
            ];
}

            Set<Id> contentDocIds = new Set<Id>();
            Map<Id, Id> docIdToAppVerMap = new Map<Id, Id>();

            for (ContentDocumentLink cdl : cdlList) {
                contentDocIds.add(cdl.ContentDocumentId);
                docIdToAppVerMap.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
            }

            // Step 2: Query related ContentVersion records
            List<ContentVersion> versionList = [
                SELECT Id, Title, ContentDocumentId, VersionData
                FROM ContentVersion
                WHERE ContentDocumentId IN :contentDocIds
      AND (Title = 'Credit Manager Initiation Remarks' OR Title='Approved by CM' OR Title='Rejected by CM' OR Title='Re-initiate by CM')
            ];

            //Map<Id, String> applicationIdToNoteRemarkMap = new Map<Id, String>();
            //Map<Id, String> creditAppverIdToNoteRemarkMap = new Map<Id, String>();

            // Step 3: Match to App Verification record and map based on title
            for (ContentVersion ver : versionList) {
                Id appVerId = docIdToAppVerMap.get(ver.ContentDocumentId);
                String body = ver.VersionData != null ? ver.VersionData.toString() : '';
                system.debug('line 655-->>'+body);

                if (ver.Title == 'Credit Manager Initiation Remarks') {
                    applicationIdToNoteRemarkMap.put(appVerId, body);
                }
                if (ver.Title == 'Approved by CM' || ver.Title == 'Rejected by CM' || ver.Title == 'Re-initiate by CM') {
                    creditAppverIdToNoteRemarkMap.put(appVerId, body);
                }
            }


            for(ApplicantWrapper iterCustomer : applicantWrapperList){
                for(Application_Verification__c iterFi : fiList){
                    if(iterCustomer.addressId == iterFi.Address__c){
                        if(/*iterFi.Stage__c!=constants.get('Approved_2') && */ iterFi.Stage__c!=constants.get('Waived') && iterFI.Stage__c!='Re Initiate' )
                        {
                            iterCustomer.isVistiInitated=true;
                            iterCustomer.selectedAssignee = iterFi.Assigned_To_User__c;
                            iterCustomer.selectedAssigneeName = iterFi.Assigned_To_User__r.Name;
                        }
                        iterCustomer.fiId = iterFi.Id;
                        iterCustomer.fiName = iterFi.Name;
                        iterCustomer.combinedCustomername = iterFi.Customer_Name__c;
                        iterCustomer.fiStatus = iterFi.Stage__c;
                        iterCustomer.fiStage = iterFi.OverAll_Status__c;
                        iterCustomer.sharedApplicantIds = iterFi.Shared_Applicant_Ids__c;//updated Ayushi
                        iterCustomer.creditManagersDesposition=iterFi.Credit_Managers_Disposition__c;
                        iterCustomer.creditRemarks=iterFi.Credit_Manager_s_Remarks__c;
                        iterCustomer.completionDate = iterFi.Completion_Date__c != null?iterFi.Completion_Date__c.format('MM/dd/yy HH:mm:ss'):'-';
                        iterCustomer.initiatedOn=iterFi.CreatedDate != null?iterFi.CreatedDate.format('MM/dd/yy HH:mm:ss'):'-';
                        if(iterFi.Related_PD_Applicant__c!= null){
                            iterCustomer.selectedDirectorName = iterFi.Related_PD_Applicant__r.Name;
                            iterCustomer.selectedDirector = iterFi.Related_PD_Applicant__c;
                        }
                    }
                }
            }
            // need to filter cityyyy
            List<String> cityList = new List<String>();
            /*for(Application_Collateral__c itrappCol : [SELECT Id,Collateral__c,Collateral__r.Pincode__c,Collateral__r.Pincode__r.City__c,Collateral__r.Pincode__r.City__r.Name
                from Application_Collateral__c WHERE Id IN :appColIdToColAddressMap.keySet()]){
                if(itrappCol.Collateral__r.Pincode__c!=null && itrappCol.Collateral__r.Pincode__r.City__c!=null){
                    cityList.add(itrappCol.Collateral__r.Pincode__r.City__r.Name);
                }
            }*/
            List<PickListValueSet> assigneeListCol = new List<PickListValueSet>();
            Set<Id> vpAccountIdSet = new Set<Id>();
            for (Vendor_Pincode__c vp : [SELECT Account__c, Pincode_Master__r.City__r.Name FROM Vendor_Pincode__c WHERE Pincode_Master__r.City__r.Name IN:cityList]) {
                vpAccountIdSet.add(vp.Account__c);
            }
            for (AccountTeamMember atm : [SELECT UserId, User.Name FROM AccountTeamMember WHERE AccountId IN:vpAccountIdSet AND TeamMemberRole = :((verificationType == 'Vendor PD') ? 'PD Admin' : 'FI Admin')]) {
                PickListValueSet pick = new PickListValueSet();
                pick.label = atm.User.Name;
                pick.value = atm.UserId;
                assigneeListCol.add(pick);
            }
             // >>>Add Collateral as new ApplicantWrapper recor
             if(productInfo != null && productInfo.isHLRelated == false){
                 for (Id appColId : appColIdToColAddressMap.keySet()) {
                ApplicantWrapper a = new ApplicantWrapper();
                a.applicantName = 'Collateral Address';
                a.appCollateralId = appColId;
                a.applicantType = 'Collateral';
                a.addressId = appColId;
                a.recordTypeName = 'Collateral Verification';
                a.addressType = 'Collateral';
                a.waiverFlag = constants.get('Not_Waived');
                a.addressValue = appColIdToColAddressMap.get(appColId);
                a.internalList = internalList;
                //a.applicantId = 'a00Bg00000IczJRIAZ'; //NEED TO REMOVE>> ADDED BY YASH
                a.asigneeList = assigneeListCol;
                for (Application_Verification__c iterFi : fiList) {
                    if (iterFi.Application_Collateral__c == appColId) {
                        if (iterFi.Stage__c != constants.get('Waived') && iterFi.Stage__c != 'Re Initiate') {
                            a.isVistiInitated = true;
                            a.remarks = iterFi.Stantard_Remark__c;
                            system.debug('line 727-->>'+iterFi.Stantard_Remark__c);
                            a.selectedAssignee = iterFi.Assigned_To_User__c;
                            a.selectedAssigneeName = iterFi.Assigned_To_User__r.Name;
                        }
                        a.fiId = iterFi.Id;
                        a.fiName = iterFi.Name;
                        a.combinedCustomername = iterFi.Customer_Name__c;
                        a.fiStatus = iterFi.Stage__c;
                        a.fiStage = iterFi.OverAll_Status__c;
                        a.creditManagersDesposition = iterFi.Credit_Managers_Disposition__c;
                        a.creditRemarks = iterFi.Credit_Manager_s_Remarks__c;
                        a.completionDate = iterFi.Completion_Date__c != null ? iterFi.Completion_Date__c.format('MM/dd/yy HH:mm:ss') : '-';
                        a.initiatedOn = iterFi.CreatedDate != null ? iterFi.CreatedDate.format('MM/dd/yy HH:mm:ss') : '-';
                        if(productName != 'Home Loan' && productName != 'Flexi Loan'){
                            applicantWrapperListNotWaivedList.add(a);
                        }
                        
                        //Add as wrapper row for collateral assignee
                    }
                }

                if(productName != 'Home Loan' && productName != 'Flexi Loan'){
                    applicantWrapperList.add(a);
                }
                
            }

             }
            
            system.debug('check the meta here -->'+constants);
            for(ApplicantWrapper iterCustomer : applicantWrapperList){
                if(productName == 'Home Loan'){
                   iterCustomer.remarks = '';
                }
                else{
                iterCustomer.remarks = applicationIdToNoteRemarkMap.get(iterCustomer.fiId);
                }
                system.debug('line 749-->>'+iterCustomer.remarks);
                //iterCustomer.creditRemarks = creditAppverIdToNoteRemarkMap.get(iterCustomer.fiId);
                //updated Ayushi
                String noteRemark = creditAppverIdToNoteRemarkMap.get(iterCustomer.fiId);
                if (String.isNotBlank(noteRemark)) {
                    iterCustomer.creditRemarks = noteRemark;
                }
    //end updated
            }
            return applicantWrapperList;
        } catch (Exception e) {
            System.debug('Error ------'+e.getMessage()+' '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage()+' '+e.getStackTraceString());
        }
    }

    public class ApplicantAndCollateralAddressWrapper{
        @AuraEnabled public List<Applicant_Address__c> applicantAddressList;
        @AuraEnabled public List<String> collateralAddressList;
        @AuraEnabled public Boolean isApplicant = false;
        @AuraEnabled public Boolean isCollateral = false;
    }

    @AuraEnabled
    public static string initateFieldVisitMultiple(String filterdVisitList,String recordId,String waiverComment,String waiverDocumentId,String selectedAssignee, Boolean isWaived ){
            try {
                
                Set<id> addressId = new Set<id> ();
                String recordTypeName;
               Map<String, Id> recordTypeNameToIdMap = new Map<String, Id>();
                for (RecordType rt : [
                    SELECT Id, DeveloperName 
                    FROM RecordType 
                    WHERE SObjectType = 'Application_Verification__c'
                ]) {
                    recordTypeNameToIdMap.put(rt.DeveloperName, rt.Id);
                }
                Map<Id,ApplicantWrapper> addressToApplicantMap = new  Map<Id,ApplicantWrapper>();
                Map<Id,String> appVerIdToRemarks = new Map<id,string>();
                Map<String,FI_Applicable_Address_type__mdt> allMetaData = FI_Applicable_Address_type__mdt.getAll();
                // List<Branch_User__c> bu=[Select id,Vendor__c from Branch_User__c where User__c=:selectedAssignee];
                List<AccountTeamMember> ac = [Select id, AccountId from AccountTeamMember where UserId =: selectedAssignee and Account.RecordType.Name = 'Partner'];
                system.debug('filterdVisitList##### ' + filterdVisitList);
                List<ApplicantWrapper> applicantList = (List<ApplicantWrapper>) JSON.deserialize(filterdVisitList, List<ApplicantWrapper>.class);
                system.debug('applicantList:: '+applicantList);
                List<User> usList=[Select id,Name,Employee_Id__c from User where id=:UserInfo.getUserId()];
                List<Application_Verification__c> fieldInvList = new List<Application_Verification__c>();
                List<Applicant_Address__c> addListToUpdate = new List<Applicant_Address__c>();
               Application_Applicant__c apDetList = [Select Id,Loan_Application__r.Product__c from Application_Applicant__c where Loan_Application__c=:recordId limit 1];
                List<String> addressIdList = new List<String>();
                List<String> assigneeList = new List<String>();
                for(ApplicantWrapper iter:applicantList){
                    addressIdList.add(iter.addressId); //id of applicant address selected on checkbox from the component >> need to send app col ID here for Col Address >>
                    assigneeList.add(iter.selectedAssignee);
                    system.debug('addressIdList:: '+addressIdList);
                    system.debug('IterList##### ' + iter);
                    system.debug('IterRemarks#### '+ iter.remarks);
                }
                List<AccountTeamMember> acList = [Select id, AccountId,UserId from AccountTeamMember where UserId in: assigneeList and Account.RecordType.Name = 'Partner'];
                Map<Id,Id> userToVendorMap = new Map<Id,Id>();
                for(AccountTeamMember a : acList){
                    userToVendorMap.put(a.UserId,a.AccountId);
                }
                Map<Id,ApplicantAndCollateralAddressWrapper> applicantAddressMap = new Map<Id,ApplicantAndCollateralAddressWrapper>(); //NEW

                //Map<Id, List<Applicant_Address__c>> applicantAddressMap = new Map<Id, List<Applicant_Address__c>>(); // need to do something about this.. change this to a wrapper.

                /*List<Applicant_Address__c> applicantAddressList = [SELECT Id, Floor_Number__c, Plot_Number__c, Building_Street_Name__c, Visit_Waiver_Mode__c, Waived_by__c, 
                                  Landmark__c, Pincode__r.Name, Pincode__c, Town__c, District__c, State__c, Post_Office__c, Name, Address_Type__c, 
                                  Applicant__r.Applicant_Type__c, Applicant__r.Applicant_Name__c 
                                  FROM Applicant_Address__c WHERE Id IN :addressIdList];*/ //   COMMENTING IT FOR CODE QUALITY 
                List<Applicant_Address__c> addrList = [Select Id, Applicant__r.Applicant_Name__c from Applicant_Address__c where Applicant__r.Loan_Application__c=: recordId and Is_Address_Same_As_Applicant_Address__c = 'true'];
                                  //system.debug('applicantAddressList Jayoti:: '+applicantAddressList); //TOCHECK : done I guess when some two addresses are same..
                                  system.debug('addrList Jayoti:: '+addrList);

                for (Applicant_Address__c record : [SELECT Id, Floor_Number__c, Plot_Number__c, Building_Street_Name__c, Visit_Waiver_Mode__c, Waived_by__c, 
                    Landmark__c, Pincode__r.Name, Pincode__c, Town__c, District__c, State__c, Post_Office__c, Name, Address_Type__c, 
                    Applicant__r.Applicant_Type__c, Applicant__r.Applicant_Name__c 
                    FROM Applicant_Address__c WHERE Id IN :addressIdList]) {
                    if (!applicantAddressMap.containsKey(record.Id)) {
                        ApplicantAndCollateralAddressWrapper wrapper = new ApplicantAndCollateralAddressWrapper();
                        wrapper.applicantAddressList = new List<Applicant_Address__c>();
                        wrapper.collateralAddressList = new List<String>();
                        wrapper.isApplicant = true;
                        applicantAddressMap.put(record.Id, wrapper);
                        //applicantAddressMap.put(record.Id, new List<Applicant_Address__c>());
                    }
                    applicantAddressMap.get(record.Id).applicantAddressList.add(record); //adding in the wrapper
                    //applicantAddressMap.get(record.Id).add(record);
                    system.debug('applicantAddressMap Jayoti:: '+applicantAddressMap);
                }
                //for app Col
                for(Application_Collateral__c itrAppCol : [SELECT Id, Collateral__c, Collateral__r.Address_Line_1__c, Collateral__r.Address_Line_2__c, 
                                                    Collateral__r.Address_Line_3__c, Collateral__r.Block_Taluka__c, Collateral__r.Building_Street_Name__c, Collateral__r.District__c, Collateral__r.Landmark__c, Collateral__r.Plot_Number__c, 
                                                    Collateral__r.State__c FROM Application_Collateral__c WHERE ID IN:addressIdList]){

                    Collateral__c col = itrAppCol.Collateral__r;
                    List<String> addressString = new List<String>();
                    addressString.add(String.isNotBlank(col.Address_Line_1__c) ? col.Address_Line_1__c : '');
                    addressString.add(String.isNotBlank(col.Address_Line_2__c) ? col.Address_Line_2__c : '');
                    addressString.add(String.isNotBlank(col.Address_Line_3__c) ? col.Address_Line_3__c : '');
                    addressString.add(String.isNotBlank(col.Block_Taluka__c) ? col.Block_Taluka__c : '');
                    addressString.add(String.isNotBlank(col.Building_Street_Name__c) ? col.Building_Street_Name__c : '');
                    addressString.add(String.isNotBlank(col.District__c) ? col.District__c : '');
                    addressString.add(String.isNotBlank(col.Landmark__c) ? col.Landmark__c : '');
                    addressString.add(String.isNotBlank(col.Plot_Number__c) ? col.Plot_Number__c : '');
                    addressString.add(String.isNotBlank(col.State__c) ? col.State__c : '');
                    String fullAddress = String.join(addressString, ', ');
                    if (!applicantAddressMap.containsKey(itrAppCol.Id)) {
                        ApplicantAndCollateralAddressWrapper wrapper = new ApplicantAndCollateralAddressWrapper();
                        wrapper.applicantAddressList = new List<Applicant_Address__c>();
                        wrapper.collateralAddressList = new List<String>();
                        wrapper.isCollateral = true;
                        applicantAddressMap.put(itrAppCol.Id, wrapper);
                    }
                    applicantAddressMap.get(itrAppCol.Id).collateralAddressList.add(fullAddress);
                }

                for(ApplicantWrapper iter:applicantList){
                    addressToApplicantMap.put(iter.addressId,iter);
                    FI_Applicable_Address_type__mdt applicableMeta = new FI_Applicable_Address_type__mdt();
                    for(FI_Applicable_Address_type__mdt fiMeta : allMetaData.values()){
                        if(fiMeta.Applicable_Address_type__c==iter.addressType){
                            applicableMeta= fiMeta;
                            break;
                        }
                    }
                    recordTypeName=applicableMeta.Visit_type__c;
                    Application_Verification__c newInvestigation = new Application_Verification__c();
                    newInvestigation.RecordTypeId = recordTypeNameToIdMap.get(recordTypeName);//Utility.getRecordTypeIdByDeveloperName('Application_Verification__c', recordTypeName);
                    newInvestigation.Loan_Application__c = recordId;
                    newInvestigation.Applicant__c = String.isNotBlank(iter.applicantId) ? iter.applicantId : null;
                    newInvestigation.Application_Collateral__c = String.isNotBlank(iter.appCollateralId) ? iter.appCollateralId : null;
                    newInvestigation.Assigned_To_User__c = iter.selectedAssignee;
                    newInvestigation.Vendor_Admin__c=iter.selectedAssignee;
                    newInvestigation.Address__c = iter.addressType != 'Collateral' ? iter.addressId : null;//ADDED CHECK TO REMOVE ADDRESS LOOKUP IN COLLATERAL CASE
                    newInvestigation.Address_Type__c = iter.addressType;
                    if(isWaived){
                        newInvestigation.Credit_Manager_s_Remarks__c=iter.remarks;
                    }
                System.debug('beforeRemarks### ' +iter.remarks );
                if(iter.remarks != null && iter.remarks != '')
                {
                  //  newInvestigation.Stantard_Remark__c= Utility.getFormattedRemarks(iter.remarks != null ? iter.remarks : '',newInvestigation.Stantard_Remark__c);//iter.remarks;
                  System.debug('afterRemarks### ' +iter.remarks );
                }
                else{
                    newInvestigation.Stantard_Remark__c = '';
                    System.debug('else Remarks### ' +iter.remarks );
                }
                //newInvestigation.Stantard_Remark__c= Utility.getFormattedRemarks(iter.remarks != null ? iter.remarks : '',newInvestigation.Stantard_Remark__c);//iter.remarks;
                    //newInvestigation.Vendor__c=bu[0].Vendor__c;
                    newInvestigation.Vendor__c = userToVendorMap.get(iter.selectedAssignee);//ac[0].AccountId;
                    String custName;
                    List<Applicant_Address__c> applicantaddress = new List<Applicant_Address__c>();
                    //applicantaddress=applicantAddressMap.get(iter.addressId); COMMENTING THIS AS LISR CHNAGED TO WRAPPER
                    
                    ApplicantAndCollateralAddressWrapper wrapper = applicantAddressMap.get(iter.addressId);
                    if (wrapper != null && wrapper.applicantAddressList != null) {
                        applicantaddress.addAll(wrapper.applicantAddressList);
                        //newInvestigation.Full_Address__c = wrapper.collateralAddressList
                    }
                    

                    /*WONT WORK FOR COLLATERAL STARTS */
                    if(String.isBlank(newInvestigation.Application_Collateral__c) || newInvestigation.Application_Collateral__c == null){
                        if(applicantaddress.size()>0 && applicantaddress[0].Applicant__r.Applicant_Type__c == constants.get('Primary_Applicant')){
                        custName = applicantaddress[0].Applicant__r.Applicant_Name__c;
                            Set<String> addedNames = new Set<String>();
                            addedNames.add(custName);
                            if(addrList.size()>0){ // for address same as applicant address query >>
                                for(Applicant_Address__c ad : addrList){
                                    if (ad.Id != iter.addressId && !addedNames.contains(ad.Applicant__r.Applicant_Name__c)) {
                                        custName = custName + ' ,'+ad.Applicant__r.Applicant_Name__c;
                                        addedNames.add(ad.Applicant__r.Applicant_Name__c); 
                                    }
                                }
                            }
                            newInvestigation.Customer_Name__c = custName;
                        }
                        else{
                            custName = applicantaddress[0].Applicant__r.Applicant_Name__c;
                        newInvestigation.Customer_Name__c = custName;
                        }
                    }   
                    /*WONT WORK FOR COLLATERAL ENDS */
                    if(isWaived){
                         //WAIVER SCENARIO >>
                        newInvestigation.Stage__c = constants.get('Waived');
                        newInvestigation.Waiver_Remark__c=waiverComment;
                        newInvestigation.Assigned_To_User__c=UserInfo.getUserId();
                        if(String.isBlank(newInvestigation.Application_Collateral__c) || newInvestigation.Application_Collateral__c == null){
                            Applicant_Address__c add= new Applicant_Address__c();
                            add.id=iter.addressId;
                            add.Waived_by__c=usList[0].Name+' '+(usList[0].Employee_Id__c!=null?usList[0].Employee_Id__c:'');
                            add.Visit_Waiver_Mode__c=constants.get('Manually');
                            addListToUpdate.add(add); //address fields get updated in case of waive scenario
                        }
                    }
                    fieldInvList.add(newInvestigation);
                }
                if(addListToUpdate.size()>0){
                    update addListToUpdate;
                }
                insert fieldInvList;
                String remarks;
                String formattedRemark;
                for (Integer i = 0; i < fieldInvList.size(); i++) {
                    Application_Verification__c verification = fieldInvList[i];
                    System.debug('applicantList[i].remarks### ' +applicantList[i].remarks );
                    
                        remarks = applicantList[i].remarks; 
                          formattedRemark = Utility.getFormattedRemarks(remarks,'');
                   
                       appVerIdToRemarks.put(verification.Id, formattedRemark);
                }

                system.debug('line 966-->>' +apDetList.Loan_Application__r.Product__c);
                system.debug('line 967-->>' +remarks);
                if(apDetList.Loan_Application__r.Product__c == 'Home Loan' && remarks!= null && remarks != ''){
                    //Utility.createNotesRecords('Credit Manager Initiation Remarks',appVerIdToRemarks);
                }
                else if(apDetList.Loan_Application__r.Product__c != 'Home Loan'){
                    //Utility.createNotesRecords('Credit Manager Initiation Remarks',appVerIdToRemarks);
                }

                List<Application_Verification__c> fiRecord = [SELECT Id,Assigned_To_User__c,Address__c, RecordType.Name,OwnerId,Name, Applicant__c  FROM Application_Verification__c WHERE Id IN : fieldInvList and Loan_Application__c=:recordId ORDER BY CreatedDate DESC];
                system.debug('fiRecord Jayoti:: '+fiRecord);
                List<String> fiRecordName = new  List<String>();
                List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
                List<String> appDetIds = new List<String>();
                List<String> assignedToUserIds = new List<String>();
                for(Application_Verification__c fi:fiRecord){
                    fiRecordName.add(fi.RecordType.Name);
                    appDetIds.add(fi.Applicant__c);
                    assignedToUserIds.add(fi.Assigned_To_User__c);
                    Utility.SharingInfo si = new Utility.SharingInfo();
                    si.objectName = constants.get('Application_Verification');
                    si.userOrGroupId = fi.Assigned_To_User__c;
                    si.recordToShareId = fi.Id;
                    si.sharingAccess = 'Edit';//constants.get('EDIT_ACCESS');
                    sharingList.add(si);
                }
                List<OpportunityTeamMember> otmList = new List<OpportunityTeamMember>();
                List<OpportunityShare> oppShareList = new   List<OpportunityShare>();
                List<Application_Applicant__Share> applicantShareList = new   List<Application_Applicant__Share>();
                system.debug('check sharing list-->'+sharingList);
                if(!Test.isRunningTest()){
                    Utility.createShareRecord(JSON.serialize(sharingList));
                }
                
                //Sharing record at the time of checklist
                Opportunity opp=[Select id, OwnerId from Opportunity where id=:recordId];
                List<Application_Applicant__c> app =[Select id,OwnerId from Application_Applicant__c where id in: appDetIds];
                Map<Id,Id> appToOwnerMap = new Map<Id,Id>();
                for(Application_Applicant__c a:app){
                    appToOwnerMap.put(a.id,a.ownerId);
                }
                List<Application_Applicant__Share> existingShares = [
                    SELECT Id,ParentId,UserOrGroupId
                    FROM Application_Applicant__Share
                    WHERE ParentId in: app
                    AND UserOrGroupId in: assignedToUserIds
                ];
                Map<Id,List<Id>> parentToShareRecMap = new Map<Id,List<Id>>();
                for(Application_Applicant__Share a:existingShares){
                    if(parentToShareRecMap.containsKey(a.ParentId)){
                        parentToShareRecMap.get(a.ParentId).add(a.UserOrGroupId);
                    }else{
                        parentToShareRecMap.put(a.ParentId,new List<Id>{a.UserOrGroupId});
                    }
                }
                List<Utility.SharingInfo> sharingListApp = new List<Utility.SharingInfo>();
                
                List<OpportunityTeamMember> existingOtm = [SELECT id,UserId FROM OpportunityTeamMember WHERE OpportunityId =:recordId AND UserId IN :assignedToUserIds];
                Set<String> userIds = new Set<String>();
                if(existingOtm.size() > 0) {
                    for(OpportunityTeamMember iterOTM : existingOtm) {
                        userIds.add(iterOTM.UserId);
                    }
                }
                for(Application_Verification__c fi:fiRecord){
                    if(!isWaived){
                    Utility.sendInAppNotification(fi.Id,constants.get('FI_Record_Assigned'),constants.get('Visit_Assignment_Message'), new Set<String> {fi.Assigned_To_User__c}, 'Duplicate_Lead');
                    }
                    
                    /*if(!userIds.contains(fi.Assigned_To_User__c)) {
                    OpportunityTeamMember otm = new OpportunityTeamMember (OpportunityId = recordId,UserId = fi.Assigned_To_User__c,TeamMemberRole ='Field Investigation',OpportunityAccessLevel=constants.get('Edit'));
                    otmList.add(otm);
                    }*/
                    


                    System.debug('appToOwnerMap.get(fi.Applicant__c)=:'+appToOwnerMap.get(fi.Applicant__c));
                    System.debug('parentToShareRecMap.get(fi.Applicant__c)=:'+parentToShareRecMap.get(fi.Applicant__c));
                    System.debug('fi.Assigned_To_User__c=:'+fi.Assigned_To_User__c);
                    
                    if(appToOwnerMap.get(fi.Applicant__c)!=fi.Assigned_To_User__c){
                        system.debug('Are we in here');
                        if(parentToShareRecMap.containsKey(fi.Applicant__c) && parentToShareRecMap.get(fi.Applicant__c) != null && !parentToShareRecMap.get(fi.Applicant__c).contains(fi.Assigned_To_User__c)){
                            system.debug('Are we in here');
                            Utility.SharingInfo sApp = new Utility.SharingInfo();
                            sApp.objectName = 'Application_Applicant__c';
                            sApp.userOrGroupId = fi.Assigned_To_User__c;
                            sApp.recordToShareId = fi.Applicant__c;
                            sApp.sharingAccess = constants.get('Read');
                            sharingListApp.add(sApp);
                        }
                        else if(parentToShareRecMap.get(fi.Applicant__c) == null){

                            Utility.SharingInfo sApp = new Utility.SharingInfo();
                            sApp.objectName = 'Application_Applicant__c';
                            sApp.userOrGroupId = fi.Assigned_To_User__c;
                            sApp.recordToShareId = fi.Applicant__c;
                            sApp.sharingAccess = constants.get('Read');
                            sharingListApp.add(sApp);
                        }
                    }
                }
                //Sharing record at the time of checklist
                insert otmList;
                if(!Test.isRunningTest() && sharingListApp.size()>0){
                    Utility.createShareRecord(JSON.serialize(sharingListApp));
                }
                List<Document_Master__c> fiMasterList = new List<Document_Master__c>();
                system.debug('fiRecordName:: '+fiRecordName);
                if(isWaived){
                    fiMasterList=[SELECT Id, Requirement_At__c, Document_Category__c, Document_Name__c, Is_Required__c 
                    FROM Document_Master__c WHERE Requirement_At__c =: constants.get('Application_Verification_Req_Level')
                    and Document_Name__c=: constants.get('FI_Waived_Document') and Document_Category__c IN : fiRecordName ];
                }
                if(!isWaived){
                    fiMasterList=[SELECT Id, Requirement_At__c, Document_Category__c, Document_Name__c, Is_Required__c 
                    FROM Document_Master__c 
                    WHERE Requirement_At__c = :constants.get('Application_Verification_Req_Level')
                    AND Is_Active__c=true AND Document_Name__c != : constants.get('Other') and Document_Category__c IN : fiRecordName ];
                }
                
                Map<String, String> nameMandatory = new Map<String, String>();
                Map<String, String> nameMandatoryId = new Map<String, String>();
                Map<String, List<Document_Master__c>> categoryToMasterMap = new  Map<String, List<Document_Master__c>>();
            
                for(Document_Master__c iterName : fiMasterList){
                    if(categoryToMasterMap.containsKey(iterName.Document_Category__c)){
                        categoryToMasterMap.get(iterName.Document_Category__c).add(iterName);
                    }
                    else{
                        categoryToMasterMap.put(iterName.Document_Category__c,new List<Document_Master__c>{iterName});
                    }
                    nameMandatory.put(iterName.Document_Name__c, iterName.Is_Required__c==true?constants.get('Required'):constants.get('Optional'));
                    nameMandatoryId.put(iterName.Document_Name__c, iterName.Id);
                }
                List<Document_Details__c> docChecklistToCreate = new List<Document_Details__c>();
                for(Application_Verification__c fi :fiRecord){

                    List<Document_Master__c> docMasterList = categoryToMasterMap.containsKey(fi.RecordType.Name) ? categoryToMasterMap.get(fi.RecordType.Name) : new List<Document_Master__c>();
                    for(Document_Master__c doc:docMasterList){
                        Document_Details__c docChecklist = new Document_Details__c();
                        docChecklist.Application_Verification__c = fi.Id;
                        docChecklist.Loan_Application__c = recordId;
                        docChecklist.Name = doc.Document_Name__c;
                        docCheckList.Applicant__c = fi.Applicant__c;
                        docCheckList.Added_from_Add_more__c = false;
                        docCheckList.Is_Required__c = nameMandatory.get(doc.Document_Name__c).contains(constants.get('Application_Verification_Req_Level')) ? true : false;
                        docCheckList.Document_Master__c = nameMandatoryId.get(doc.Document_Name__c);
                        if(!isWaived && doc.Document_Name__c==constants.get('Other') & addressToApplicantMap.containsKey(fi.Address__c)){
                            docCheckList.Content_Document_Id__c = addressToApplicantMap.get(fi.Address__c).waiverDocId;
                        }
                        if(isWaived &&  doc.Document_Name__c== constants.get('FI_Waived_Document') && addressToApplicantMap.containsKey(fi.Address__c)){
                            docCheckList.Content_Document_Id__c = addressToApplicantMap.get(fi.Address__c).waiverDocId;
                        }
                        docChecklistToCreate.add(docChecklist);
                    }
                    
                }
                if(docChecklistToCreate.size()>0){
                    insert docChecklistToCreate;
                }
                List<ContentDocumentLink> cdList= new List<ContentDocumentLink>();
                List<Document_Details__c> doc=[Select id,Content_Document_Id__c,Application_Verification__c from Document_Details__c where id IN :docChecklistToCreate and Content_Document_Id__c!=null];
                for(Document_Details__c d: doc){
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.LinkedEntityId = d.Id; 
                    cdl.ContentDocumentId = d.Content_Document_Id__c;
                    cdl.ShareType = constants.get('V');
                    cdl.Visibility = constants.get('AllUsers'); 
                    cdList.add(cdl);
                }
                insert cdList;
                List<Utility.SharingInfo> sharingListDoc = new List<Utility.SharingInfo>();
                for(Document_Details__c doc1:docChecklistToCreate){
                    for(Application_Verification__c fi :fiRecord){
                        Utility.SharingInfo siDoc = new Utility.SharingInfo();
                        siDoc.objectName = constants.get('Document_Details_Object');
                        siDoc.userOrGroupId =fi.Assigned_To_User__c ;
                        siDoc.recordToShareId = doc1.Id;
                        siDoc.sharingAccess = constants.get('Edit');
                        sharingListDoc.add(siDoc);
                    }
                }
                if(!Test.isRunningTest()){
                    Utility.createShareRecord(JSON.serialize(sharingListDoc));
                }
                
                return constants.get('SUCCESS');
            } 
            catch (Exception e) {
                System.debug('error 903'+e.getStackTraceString());
                throw new AuraHandledException(e.getMessage() + e.getStackTraceString());
            }
        }

    @AuraEnabled
        public static Boolean getFiStatus(String recordId) {
        try {
            Boolean flag=true;
                Application_Verification__c fiRecord = [
                    SELECT Stage__c ,Assigned_To_User__c,Vendor_Admin__c, RecordType.Name
                    FROM Application_Verification__c 
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                system.debug('fiRecord:: '+fiRecord);
                User currentUser = [
                    SELECT Profile.Name 
                    FROM User 
                    WHERE Id = :UserInfo.getUserId()
                    LIMIT 1
                ];
                system.debug('currentUser:: '+currentUser);
                List<AccountTeamMember> bu=[Select id, UserId, TeamMemberRole from AccountTeamMember where UserId=:UserInfo.getUserId() LIMIT 1 ];
                system.debug('bu:: '+bu);
                if(fiRecord.RecordType.Name== 'Personal Discussion'){
                    List<FI_Record_Editiability__mdt> fieldMeta = [
                        SELECT Id, Profile__c, Role__c, Stage__c, Is_Active__c 
                        FROM FI_Record_Editiability__mdt 
                        WHERE Is_Active__c = true and Role__c=:bu[0].TeamMemberRole AND Profile__c=:currentUser.Profile.Name AND Stage__c=:fiRecord.Stage__c AND Is_For_Vendor_PD__c = true AND Is_Active__c = true
                    ];
                    system.debug('fieldMeta:: '+fieldMeta);
                    if(fieldMeta.size()>0 && (fiRecord.Assigned_To_User__c==UserInfo.getUserId()||fiRecord.Vendor_Admin__c==UserInfo.getUserId())){
                        flag=false;
                    }
                }else {
                    List<FI_Record_Editiability__mdt> fieldMeta = [
                        SELECT Id, Profile__c, Role__c, Stage__c, Is_Active__c 
                        FROM FI_Record_Editiability__mdt 
                        WHERE Is_Active__c = true and Role__c=:bu[0].TeamMemberRole AND Profile__c=:currentUser.Profile.Name AND Stage__c=:fiRecord.Stage__c
                    ];
                    system.debug('fieldMeta:: '+fieldMeta);
                    if(fieldMeta.size()>0 && (fiRecord.Assigned_To_User__c==UserInfo.getUserId()||fiRecord.Vendor_Admin__c==UserInfo.getUserId())){
                        flag=false;
                    }
            }
            
            return flag;
            
        } 
        catch (Exception e) {
            System.debug('Exception in getFiStatus: ' + e.getMessage());
            throw new AuraHandledException('Error: ' + e.getMessage() + e.getStackTraceString());
        }
    }

   
    @AuraEnabled
    public static String updateDocumentChecklist(String fiId, String reportId) {
        try {
            System.debug('Starting updateDocumentChecklist...');
            System.debug('fiId: ' + fiId + ', reportId: ' + reportId);
            Set<Id> assigneeID = new Set<Id>();
            Application_Verification__c fi = [
                SELECT Id, Loan_Application__c, Vendor_Admin__c, Assigned_To_User__c, Name, Applicant__c, RecordType.Name, Loan_Application__r.Name
                FROM Application_Verification__c
                WHERE Id = :fiId
            ];
            System.debug('Fetched Application_Verification__c: ' + fi);
            List<Document_Master__c> docMaster = [
                SELECT Id, Document_Name__c, Document_Category__c
                FROM Document_Master__c
                WHERE Document_Category__c = :fi.RecordType.Name
                // AND Document_Name__c =: constants.get('Report')
                AND Document_Name__c = 'Other'
            ];
            System.debug('Fetched Document_Master__c: ' + docMaster);
            String baseDocName = fi.Name + ' '+constants.get('Report'); 
            Integer counter = 1;  
            List<Document_Details__c> docDetail = [
                SELECT Id, Name
                FROM Document_Details__c
                WHERE Name LIKE :baseDocName + '%'
            
            ];
            System.debug('Fetched docDetail: ' + docDetail);
            for (Document_Details__c doc : docDetail) {
                String docName = doc.Name;
            
                if (docName.contains(' Report ')) {
                    String[] parts = docName.split(' Report ');
                    if (parts.size() > 1) {
                        try {
                            Integer existingCounter = Integer.valueOf(parts[1]);
                            counter = Math.max(counter, existingCounter + 1); 
                            System.debug(' counter: ' + counter);
                        } catch (Exception e) {
                            
                        }
                    }
                }
            }
            String docName = fi.Name + ' '+constants.get('Report') + counter;
            System.debug('Fetched docName: ' + docName);
            // Create ContentVersion for the report
            Blob contentBlob = EncodingUtil.base64Decode(reportId);
            ContentVersion cv = new ContentVersion();
            cv.Title = fi.Loan_Application__r.Name + constants.get('FI_Report');
            cv.PathOnClient = constants.get('FI_Report');
            cv.VersionData = contentBlob;
            cv.IsMajorVersion = true;
            insert cv;
            
            // Retrieve the ContentDocumentId from the inserted ContentVersion
            ContentVersion insertedVersion = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :cv.Id
            ];
            System.debug('Fetched insertedVersion: ' + insertedVersion);
            String contentDocumentId = insertedVersion.ContentDocumentId;
            System.debug('Fetched contentDocumentId: ' + insertedVersion.ContentDocumentId);
            // Prepare Document_Details__c record
            Document_Details__c docDetails = new Document_Details__c();
            docDetails.Application_Verification__c = fiId;
            docDetails.Content_Document_Id__c = reportId;
            docDetails.Loan_Application__c = fi.Loan_Application__c;
            //docDetails.Applicant__c = fi.Applicant__c;
            if(fi.RecordType.Name=='Personal Discussion'){
                docDetails.Is_Required__c = true;
            }else {
                docDetails.Document_Master__c = docMaster[0].Id;
            }
            docDetails.Status__c = constants.get('Uploaded');
            docDetails.Name = docName;
            
            insert docDetails;
           
            // Determine assignee IDs for sharing permissions
            List<Document_Details__c> doc = [
                SELECT Id, OwnerId
                FROM Document_Details__c
                WHERE Id = :docDetails.Id
            ];
            System.debug('Fetched doc: ' + doc);
            if (doc.size() > 0) {
                System.debug('Fetched fi.Vendor_Admin__c: ' + fi.Vendor_Admin__c);
                System.debug('Fetched fi.Assigned_To_User__c: ' + fi.Assigned_To_User__c);
                if (fi.Vendor_Admin__c != doc[0].OwnerId) {
                    assigneeID.add(fi.Vendor_Admin__c);
                }
                if (fi.Assigned_To_User__c != doc[0].OwnerId) {
                    assigneeID.add(fi.Assigned_To_User__c);
                }
            }

            // Create sharing records for the document
            List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
            for (Id i : assigneeID) {
                Utility.SharingInfo si = new Utility.SharingInfo();
                si.objectName = constants.get('Document_Details_Object');
                si.userOrGroupId = i;
                si.recordToShareId = docDetails.Id;
                si.sharingAccess = constants.get('Edit');
                sharingList.add(si);
            }
            if((!Test.isRunningTest())){
                Utility.createShareRecord(JSON.serialize(sharingList));
            }
            

            // Create ContentDocumentLink to link the document
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = docDetails.Id;
            cdl.ContentDocumentId = reportId;
            cdl.ShareType = constants.get('V');
            cdl.Visibility = constants.get('AllUsers'); 
            insert cdl;

            return reportId;
        } catch (Exception e) {
            System.debug('Exception in updateDocumentChecklist: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static String getLatestDocumentUrl (Id recordId) {
        try {
            String url;
            List<Application_Verification__c> fi = [
            SELECT id, Name, Loan_Application__r.Name 
            FROM Application_Verification__c 
            WHERE id = :recordId
        ];
        String docName = fi[0].Name +' '+constants.get('Report');
       List<Document_Details__c> docDetails = [
            SELECT id, Document_URL__c, Content_Document_Id__c
            FROM Document_Details__c 
            WHERE Application_Verification__c = :recordId 
            AND Name LIKE :docName + '%'  
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        if (!docDetails.isEmpty()) {
            url = docDetails[0].Content_Document_Id__c; // Or use Content_Document_Id__c if you need the document ID
        }return url;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean checkShowSubmit(String recId){
        Boolean showSubmit = true;
        try {
            List<Screen_Field__c> screenFields = new List<Screen_Field__c>();
            String query='Select id';
            List<Application_Verification__c> fiList = [Select Id, RecordType.Name,Details_Filled__c,Images_Captured__c, Stage__c from Application_Verification__c where id =: recId];
            List<Document_Details__c> docDetails=[Select id, Application_Verification__c from Document_Details__c where Application_Verification__c=:recId and Is_Required__c=true and Content_Document_Id__c=null];
            if(docDetails.size()>0){
                showSubmit=false;
            }
            if(fiList[0].RecordType.Name==constants.get('Residence_Verification_Recordtype')){
                screenFields = [SELECT Id,Form_Name__c , Parent_Screen__r.Form_Name__c, Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c, 
                Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,
                Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c,Read_Field_Name__c,Read_Object_Name__c,Section_Seperator__c,Section_Name__c,
                Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c
                FROM Screen_Field__c
                WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Form_Name__c =: constants.get('Field_Investigation_Form') And Is_Mandatory__c=true
                order by Field_Sequence__c ASC];

            }else if(fiList[0].RecordType.Name==constants.get('Business_Verification_Recordtype')){
                screenFields = [SELECT Id,Form_Name__c , Parent_Screen__r.Form_Name__c, Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c, 
                Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,
                Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c,Read_Field_Name__c,Read_Object_Name__c,Section_Seperator__c,Section_Name__c,
                Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c
                FROM Screen_Field__c
                WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Form_Name__c =: constants.get('Field_Investigation_Form_Business') And Is_Mandatory__c=true
                order by Field_Sequence__c ASC];

            }else if(fiList[0].RecordType.Name=='Personal Discussion'){
                screenFields = [SELECT Id,Form_Name__c , Parent_Screen__r.Form_Name__c, Name,Parent_Screen__r.Screen_Sequence__c, Parent_Screen__r.Master_Screen_Name__c,Screen_Object__c, 
                Is_Picklist__c,Is_Active__c, Field_Label__c, Is_Mandatory__c, Storage_Object__c, Storage_Field__c, Field_Sequence__c,
                Field_Type__c, is_Lookup__c,Custom_Component_Name__c,Is_Controlling_Picklist__c,Dependent_Picklist__c,Read_Field_Name__c,Read_Object_Name__c,Section_Seperator__c,Section_Name__c,
                Visibility_Controlled_By__c,Visibility_Controlled_By_Value__c,Is_Hidden__c,Applicable_Login_Stage__c,Is_Disabled__c,Maximum_Length__c, Is_Formula_Feild__c
                FROM Screen_Field__c
                WHERE Is_Active__c = true AND Parent_Screen__r.Is_Screen_Active__c = true AND Parent_Screen__r.Form_Name__c = 'Vendor PD' And Is_Mandatory__c=true
                order by Field_Sequence__c ASC];

            }
            for(Screen_Field__c sf : screenFields){
                query= query+ ','+ sf.Storage_Field__c;
            }
            String queryFields= query+' from Application_Verification__c where id=:recId';
            Sobject sObj = Database.query(queryFields);
            
            for(Screen_Field__c sf: screenFields){
                
                if(sObj.get(sf.Storage_Field__c) == null||sObj.get(sf.Storage_Field__c) == ''){
                  
                    showSubmit=false;
                    break;
                }
            }
            
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return showSubmit;
    }

  
    public class PickListValueSet{
        @AuraEnabled
        public string label {get;set;}
        @AuraEnabled
        public string value {get;set;}
    }
    public class ApplicantWrapper{
        @AuraEnabled public String applicantId;
        @AuraEnabled public String appCollateralId;
        @AuraEnabled public String applicantName;
        @AuraEnabled public String applicantType;
        @AuraEnabled public String addressId;
        @AuraEnabled public String addressType;
        @AuraEnabled public String recordTypeName;
        @AuraEnabled public String addressValue;
        @AuraEnabled public String waiverFlag;
        @AuraEnabled public String waivedBy;
        @AuraEnabled public Boolean isSameAsApplicantAddress;
        @AuraEnabled public String remarks;
        @AuraEnabled public boolean isVistiInitated=false;
        @AuraEnabled public string selectedAssignee;
        @AuraEnabled public string selectedAssigneeName;
        @AuraEnabled public string selectedDirectorName;
        @AuraEnabled public string selectedDirector;
        @AuraEnabled public string selectedInternalAssignee;
        @AuraEnabled public string selectedInternalAssigneeName;
        @AuraEnabled public boolean isDirectorReq=false;
        @AuraEnabled public string  waiverDocId;
        @AuraEnabled public String waiverDocName;
        @AuraEnabled public Integer index=0;
        @AuraEnabled public boolean isPaleColour=false;
        @AuraEnabled public boolean isDocumentUploaded=false;
        @AuraEnabled public String fiId;
        @AuraEnabled public String fiName;
        @AuraEnabled public String fiStatus;
        @AuraEnabled public String fiStage;
        @AuraEnabled public String initiatedOn;
        @AuraEnabled public String creditManagersDesposition;
        @AuraEnabled public String creditRemarks;
        @AuraEnabled public String completionDate;
        @AuraEnabled public List<PickListValueSet> directorList;
        @AuraEnabled public List<PickListValueSet> asigneeList;
        @AuraEnabled public List<PickListValueSet> internalList;
        @AuraEnabled public String combinedCustomername;
        @AuraEnabled public String sharedApplicantIds;//updated Ayushi
    }
    
    @AuraEnabled
    public static string recordTypeId(String recordId){
        try {
            List<Application_Verification__c> fi =[Select id, RecordType.Name from Application_Verification__c where id=:recordId];
            return fi[0].RecordType.Name;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class AssigneeWrapperNew {
    public Map<String, List<Map<String, String>>> assigneeInfo { get; set; }
    public Map<Id, Map<String, String>> assigneeMap { get; set; }
    public String assigneeName { get; set; }
    public Id assigneeID { get; set; }

    public AssigneeWrapperNew(
        Map<String, List<Map<String, String>>> assigneeInfo, 
        Map<Id, Map<String, String>> assigneeMap, 
        String assigneeName, 
        Id assigneeID
    ) {
        this.assigneeInfo = assigneeInfo;
        this.assigneeMap = assigneeMap;
        this.assigneeName = assigneeName;
        this.assigneeID = assigneeID;
    }
}
        // @AuraEnabled
        // public String assigneeName { get; set; }
        
        // @AuraEnabled
        // public Id assigneeID { get; set; }
    
        // @AuraEnabled
        // public Map<String , Map<String,String>> assigneeMap1 {get;set;}

        // @AuraEnabled
        // public Map<String, Map<String, List<Map<String, String>>>> assigneeInfo { get; set; }

        // public AssigneeWrapperNew(String assigneeName, Id assigneeID, Map<String, Map<String, List<Map<String, String>>>> assigneeInfo , Map<String , Map<String,String>> assigneeMap1) {
        //     this.assigneeName = assigneeName;
        //     this.assigneeID = assigneeID;
        //     this.assigneeInfo = assigneeInfo;
        //     this.assigneeMap1 = assigneeMap1;
        // }
    //}
    @AuraEnabled
    public static void saveRemarksFI(String recordId, String status, String comment) {
        Map<Id,String> appVerToRem = new Map<Id,String>();
        try {
            List<Application_Verification__c> fiList = [
                SELECT Id, Credit_Manager_s_Remarks__c, Waiver_Remark__c, Admin_s_Remarks__c, Any_Remarks_Reasons__c 
                FROM Application_Verification__c 
                WHERE Id = :recordId
            ];
            if (!fiList.isEmpty()) {
               Application_Verification__c record = fiList[0];
               String title = '';
               String formattedRemarks = '';
                System.debug(' record.Any_Remarks_Reasons__c =:'+ record.Any_Remarks_Reasons__c );
                
                if (status == constants.get('Sent_Back_By_Credit')) {
                    title = 'Sent Back By Credit';
                    formattedRemarks = Utility.getFormattedRemarks(comment, record.Credit_Manager_s_Remarks__c);
                    // record.Credit_Manager_s_Remarks__c = Utility.getFormattedRemarks(comment, record.Credit_Manager_s_Remarks__c);
                } 
                if (status == constants.get('Sent_Back_By_Admin')) {
                     title = 'Sent Back By Admin';
                      formattedRemarks = Utility.getFormattedRemarks(comment, record.Admin_s_Remarks__c);
                   // record.Admin_s_Remarks__c =Utility.getFormattedRemarks(comment, record.Admin_s_Remarks__c);
                } 
                if (status == constants.get('Waive')) {
                     title = 'Waiver';
                      formattedRemarks = Utility.getFormattedRemarks(comment, record.Waiver_Remark__c);
                   // record.Waiver_Remark__c = Utility.getFormattedRemarks(comment, record.Waiver_Remark__c);
                } 
                if (status == 'Sent for Approval'){
                     title = 'Sent for Approval';
                    formattedRemarks = Utility.getFormattedRemarks(comment,  record.Any_Remarks_Reasons__c);
                    System.debug('v=:'+Utility.getFormattedRemarks(comment, record.Any_Remarks_Reasons__c));
                 //   record.Any_Remarks_Reasons__c = Utility.getFormattedRemarks(comment, record.Any_Remarks_Reasons__c);
                    System.debug(' record.Any_Remarks_Reasons__=:'+ record.Any_Remarks_Reasons__c);
                } 
                if(status == 'Sent for Approval by FI Admin') {
                     title = 'Sent for Approval by FI Admin';
                      formattedRemarks = Utility.getFormattedRemarks(comment, record.Any_Remarks_Reasons__c);
                   // record.Any_Remarks_Reasons__c = Utility.getFormattedRemarks(comment, record.Any_Remarks_Reasons__c);
                }
                if(status == 'Approve') {
                     title = 'Approved by CM';
                      formattedRemarks = Utility.getFormattedRemarks(comment, record.Credit_Manager_s_Remarks__c);
                   // record.Any_Remarks_Reasons__c = Utility.getFormattedRemarks(comment, record.Any_Remarks_Reasons__c);
                }
                 if(status == 'Reject') {
                     title = 'Rejected by CM';
                      formattedRemarks = Utility.getFormattedRemarks(comment, record.Credit_Manager_s_Remarks__c);
                   // record.Any_Remarks_Reasons__c = Utility.getFormattedRemarks(comment, record.Any_Remarks_Reasons__c);
                }
                 if(status == 'Re-initiate') {
                     title = 'Re-initiate by CM';
                      formattedRemarks = Utility.getFormattedRemarks(comment, record.Credit_Manager_s_Remarks__c);
                   // record.Any_Remarks_Reasons__c = Utility.getFormattedRemarks(comment, record.Any_Remarks_Reasons__c);
                }
                if(status == 'Sent for Approval by PD Admin') {
                    System.debug('In Sent for Approval by PD Admin');
                    title = 'Sent for Approval by PD Admin';
                     formattedRemarks = Utility.getFormattedRemarks(comment,record.Any_Remarks_Reasons__c);
                  //  record.Any_Remarks_Reasons__c = Utility.getFormattedRemarks(comment, record.Any_Remarks_Reasons__c);
                    System.debug('remarks after update---'+record.Any_Remarks_Reasons__c);
                }
                if (String.isNotBlank(formattedRemarks)) {
                List<Application_Verification__c> recordList = new List<Application_Verification__c>{ record };
                Map<Id, String> remarksMap = new Map<Id, String>();
                remarksMap.put(record.Id, formattedRemarks);
                //Utility.createNotesRecords(title, remarksMap);
                }
               // update record;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static boolean showDispositionDropDown(String recordId){
        system.debug('check labels-->'+conLabels);
        try {
            User currentUser = [
                    SELECT Profile.Name 
                    FROM User 
                    WHERE Id = :UserInfo.getUserId()
                    LIMIT 1
                ];
            Application_Verification__c fi=[Select id,Stage__c, RecordType.Name from Application_Verification__c where id=:recordId];
            System.debug('constants.get---'+constants.get('Approved_1'));
            System.debug('constants.--'+constants.get('System_Administrator'));
            if(fi.RecordType.Name=='Personal Discussion'){
                if(fi.Stage__c!='Approved' && (currentUser.Profile.Name==constants.get('System_Administrator') || currentUser.Profile.Name== 'Credit Manager' )){
                    System.debug('constants.--'+constants.get('System_Administrator'));
                    return true;
                }else{
                    return false;
                } 
            }else{
                if((fi.Stage__c==constants.get('Sent_for_Approval_by_FI_Admin')||fi.Stage__c==constants.get('Approved_1')||fi.Stage__c==constants.get('Sent_for_Approval_by_PD_Admin'))&& (currentUser.Profile.Name==constants.get('System_Administrator') || currentUser.Profile.Name== 'Credit Manager' )){
                    System.debug('constants.--'+constants.get('System_Administrator'));
                    return true;
                }else{
                    return false;
                } 
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean currentLoggedInUserAssignedUser(String recordId){
        try {

            List<Application_Verification__c> appVeri = [Select id, Assigned_To_User__c from Application_Verification__c where id =:recordId];
            if(appVeri[0].Assigned_To_User__c == UserInfo.getUserId()){
                return true;
            }
            else{
                return false; 
            }
            
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static string initiateVendorPD(String filterdVisitList,String recordId,String selectedAssignee ){
        try {
            Set<id> addressId = new Set<id> ();
            
            Map<Id,ApplicantWrapper> addressToApplicantMap = new  Map<Id,ApplicantWrapper>();
            // List<Branch_User__c> bu=[Select id,Vendor__c from Branch_User__c where User__c=:selectedAssignee];
            List<AccountTeamMember> ac = [Select id, AccountId from AccountTeamMember where UserId =: selectedAssignee and Account.RecordType.Name = 'Partner'];
            List<ApplicantWrapper> applicantList = (List<ApplicantWrapper>) JSON.deserialize(filterdVisitList, List<ApplicantWrapper>.class);
            system.debug('applicantList:: '+applicantList);
            List<User> usList=[Select id,Name,Employee_Id__c from User where id=:UserInfo.getUserId()];
            List<Application_Verification__c> fieldInvList = new List<Application_Verification__c>();
            
            
            List<String> addressIdList = new List<String>();
            List<String> assigneeList = new List<String>();
            for(ApplicantWrapper iter:applicantList){
                addressIdList.add(iter.addressId);
                assigneeList.add(iter.selectedAssignee);
                system.debug('addressIdList:: '+addressIdList);
            }
            List<AccountTeamMember> acList = [Select id, AccountId,UserId from AccountTeamMember where UserId in: assigneeList and Account.RecordType.Name = 'Partner'];
            Map<Id,Id> userToVendorMap = new Map<Id,Id>();
            for(AccountTeamMember a : acList){
                userToVendorMap.put(a.UserId,a.AccountId);
            }
            Map<Id, List<Applicant_Address__c>> applicantAddressMap = new Map<Id, List<Applicant_Address__c>>();

            List<Applicant_Address__c> applicantAddressList = [SELECT Id, Floor_Number__c, Plot_Number__c, Building_Street_Name__c, Visit_Waiver_Mode__c, Waived_by__c, 
                                Landmark__c, Pincode__r.Name, Pincode__c, Town__c, District__c, State__c, Post_Office__c, Name, Address_Type__c, 
                                Applicant__r.Applicant_Type__c, Applicant__r.Applicant_Name__c 
                                FROM Applicant_Address__c WHERE Id IN :addressIdList];
                                List<Applicant_Address__c> addrList = [Select Id, Applicant__r.Applicant_Name__c from Applicant_Address__c where Applicant__r.Loan_Application__c=: recordId and Is_Address_Same_As_Applicant_Address__c = 'true'];
                                system.debug('applicantAddressList Jayoti:: '+applicantAddressList);
                                system.debug('addrList Jayoti:: '+addrList);
            for (Applicant_Address__c record : applicantAddressList) {
                if (!applicantAddressMap.containsKey(record.Id)) {
                    applicantAddressMap.put(record.Id, new List<Applicant_Address__c>());
                }
                applicantAddressMap.get(record.Id).add(record);
                system.debug('applicantAddressMap Jayoti:: '+applicantAddressMap);
            }
            for(ApplicantWrapper iter:applicantList){
                addressToApplicantMap.put(iter.addressId,iter);

                Application_Verification__c newInvestigation = new Application_Verification__c();
                newInvestigation.RecordTypeId = Utility.getRecordTypeIdByDeveloperName('Application_Verification__c', 'Personal_Discussion');
                newInvestigation.Loan_Application__c = recordId;
                newInvestigation.Applicant__c = iter.applicantId;
                newInvestigation.Assigned_To_User__c = iter.selectedAssignee;
                newInvestigation.Vendor_Admin__c=iter.selectedAssignee;
                newInvestigation.Address__c = iter.addressId;
                newInvestigation.Address_Type__c = iter.addressType;
                newInvestigation.Stantard_Remark__c=Utility.getFormattedRemarks(iter.remarks,newInvestigation.Stantard_Remark__c);
                newInvestigation.Customer_Name__c = iter.applicantName;
                newInvestigation.Personal_Discussion_Type__c = 'Vendor PD';
                newInvestigation.Vendor__c = userToVendorMap.get(iter.selectedAssignee);//ac[0].AccountId;
                newInvestigation.Stage__c = constants.get('Draft');
                if(iter.isDirectorReq && iter.selectedDirector !=  null){
                    newInvestigation.Related_PD_Applicant__c = iter.selectedDirector ;
                }
                fieldInvList.add(newInvestigation);
            }
            insert fieldInvList;
            List<Application_Verification__c> fiRecord = [SELECT Id,Assigned_To_User__c,Address__c, RecordType.Name,OwnerId,Name, Applicant__c  FROM Application_Verification__c WHERE Id IN : fieldInvList and Loan_Application__c=:recordId ORDER BY CreatedDate DESC];
            system.debug('fiRecord Jayoti:: '+fiRecord);
            List<String> fiRecordName = new  List<String>();
            List<Utility.SharingInfo> sharingList = new List<Utility.SharingInfo>();
            List<String> appDetIds = new List<String>();
            List<String> assignedToUserIds = new List<String>();
            for(Application_Verification__c fi:fiRecord){
                fiRecordName.add(fi.RecordType.Name);
                appDetIds.add(fi.Applicant__c);
                assignedToUserIds.add(fi.Assigned_To_User__c);
                Utility.SharingInfo si = new Utility.SharingInfo();
                si.objectName = constants.get('Application_Verification');
                si.userOrGroupId = fi.Assigned_To_User__c;
                si.recordToShareId = fi.Id;
                si.sharingAccess = constants.get('Edit');
                sharingList.add(si);
            }
            List<OpportunityTeamMember> otmList = new List<OpportunityTeamMember>();
            
            List<Application_Applicant__Share> applicantShareList = new   List<Application_Applicant__Share>();
            if(!Test.isRunningTest()){
                Utility.createShareRecord(JSON.serialize(sharingList));
            }
            
            //Sharing record at the time of checklist
            Opportunity opp=[Select id, OwnerId from Opportunity where id=:recordId];
            List<Application_Applicant__c> app =[Select id,OwnerId from Application_Applicant__c where id in: appDetIds];
            Map<Id,Id> appToOwnerMap = new Map<Id,Id>();
            for(Application_Applicant__c a:app){
                appToOwnerMap.put(a.id,a.ownerId);
            }
            List<Application_Applicant__Share> existingShares = [
                SELECT Id,ParentId,UserOrGroupId
                FROM Application_Applicant__Share
                WHERE ParentId in: app
                AND UserOrGroupId in: assignedToUserIds
            ];
            Map<Id,List<Id>> parentToShareRecMap = new Map<Id,List<Id>>();
            for(Application_Applicant__Share a:existingShares){
                if(parentToShareRecMap.containsKey(a.ParentId)){
                    parentToShareRecMap.get(a.ParentId).add(a.UserOrGroupId);
                }else{
                    parentToShareRecMap.put(a.ParentId,new List<Id>{a.UserOrGroupId});
                }
            }
            List<Utility.SharingInfo> sharingListApp = new List<Utility.SharingInfo>();
            for(Application_Verification__c fi:fiRecord){
                Utility.sendInAppNotification(fi.Id,constants.get('PD_Record_Assigned'),constants.get('PD_Assigned_Message'), new Set<String> {fi.Assigned_To_User__c}, 'Duplicate_Lead');
                OpportunityTeamMember otm = new OpportunityTeamMember (OpportunityId = recordId,UserId = fi.Assigned_To_User__c,TeamMemberRole ='Personal Discussion',OpportunityAccessLevel=constants.get('Edit'));
                otmList.add(otm);
                // }

                System.debug('appToOwnerMap.get(fi.Applicant__c)=:'+appToOwnerMap.get(fi.Applicant__c));
                System.debug('parentToShareRecMap.get(fi.Applicant__c)=:'+parentToShareRecMap.get(fi.Applicant__c));
                System.debug('fi.Assigned_To_User__c=:'+fi.Assigned_To_User__c);
                
                if(appToOwnerMap.get(fi.Applicant__c)!=fi.Assigned_To_User__c){
                    if(parentToShareRecMap.containsKey(fi.Applicant__c) && parentToShareRecMap.get(fi.Applicant__c) != null && !parentToShareRecMap.get(fi.Applicant__c).contains(fi.Assigned_To_User__c)){

                        Utility.SharingInfo sApp = new Utility.SharingInfo();
                        sApp.objectName = 'Application_Applicant__c';
                        sApp.userOrGroupId = fi.Assigned_To_User__c;
                        sApp.recordToShareId = fi.Applicant__c;
                        sApp.sharingAccess = constants.get('Read');
                        sharingListApp.add(sApp);
                    }
                    else if(parentToShareRecMap.get(fi.Applicant__c) == null){

                        Utility.SharingInfo sApp = new Utility.SharingInfo();
                        sApp.objectName = 'Application_Applicant__c';
                        sApp.userOrGroupId = fi.Assigned_To_User__c;
                        sApp.recordToShareId = fi.Applicant__c;
                        sApp.sharingAccess = constants.get('Read');
                        sharingListApp.add(sApp);
                    }
                }
            }
            //Sharing record at the time of checklist
            insert otmList;
            if(!Test.isRunningTest() && sharingListApp.size()>0){
                Utility.createShareRecord(JSON.serialize(sharingListApp));
            }
            
            return constants.get('SUCCESS');
        } 
        catch (Exception e) {

            throw new AuraHandledException(e.getMessage());
        }
    } 
    @AuraEnabled(cacheable=true)
    public static List<ApplicationVerificationHistoryWrapper> getVerificationHistory(String loanAppId,String objectApiName) {

        List<ApplicationVerificationHistoryWrapper> results = new List<ApplicationVerificationHistoryWrapper>();

        if(objectApiName == 'Application_Verification__c'){
             List<Application_Verification__History> records = [
            SELECT Id, OldValue, NewValue, Field, ParentId, Parent.Name 
            FROM Application_Verification__History 
            WHERE (Parent.RecordType.Name = 'Residence Verification' OR Parent.RecordType.Name = 'Business Verification' OR Parent.RecordType.Name = 'Collateral Verification')
            AND Parent.Loan_Application__c = :loanAppId
            AND Field IN ('Assigned_To_User__c', 'Stage__c', 'Credit_Managers_Disposition__c')
        ];

        // Wrap results to flatten Parent.Name (for easier handling in LWC)
        for(Application_Verification__History rec : records){
            results.add(new ApplicationVerificationHistoryWrapper(
            rec.Id,
            rec.OldValue == null ? null : String.valueOf(rec.OldValue),
            rec.NewValue == null ? null : String.valueOf(rec.NewValue),
            rec.Field,
            rec.ParentId,
            rec.Parent.Name
        ));
        }
        return results;
    }
        else if(objectApiName == 'Technical_Evaluation__c'){
            List<Technical_Evaluation__History> technicalrecords = [
                SELECT Id, OldValue, NewValue, Field, ParentId, Parent.Name 
                FROM Technical_Evaluation__History 
                WHERE Parent.HL_Loan_Application__c = :loanAppId
                AND Field IN ('HL_Assigned_to_Technical_Admin__c', 'HL_Stage__c', 'HL_Assigned_to_Technical_Executive__c','HL_Assigned_to_Technical_Manager__c')
            ];

            // Wrap results to flatten Parent.Name (for easier handling in LWC)
            for(Technical_Evaluation__History rec : technicalrecords){
                results.add(new ApplicationVerificationHistoryWrapper(
                    rec.Id,
                    rec.OldValue == null ? null : String.valueOf(rec.OldValue),
                    rec.NewValue == null ? null : String.valueOf(rec.NewValue),
                    rec.Field,
                    rec.ParentId,
                    rec.Parent.Name
                ));
            }
            return results;
        }
        else if(objectApiName == 'Legal__c'){
            List<Legal__History> legalHistoryRecords = [
                SELECT Id, OldValue, NewValue, Field, ParentId, Parent.Name 
                FROM Legal__History 
                WHERE Parent.Loan_Application__c = :loanAppId
                AND Field IN ('Assigned_to_Admin__c', 'Stage__c', 'Assigned_to_Executive__c	')
            ];
            // Wrap results to flatten Parent.Name (for easier handling in LWC)
            for(Legal__History rec : legalHistoryRecords){
                results.add(new ApplicationVerificationHistoryWrapper(
                    rec.Id,
                    rec.OldValue == null ? null : String.valueOf(rec.OldValue),
                    rec.NewValue == null ? null : String.valueOf(rec.NewValue),
                    rec.Field,
                    rec.ParentId,
                    rec.Parent.Name
                ));
            }
            return results;
        }
        return null;
    }

       
  @AuraEnabled(cacheable=true)
  public static string getProductName(string recordId){
    string productName;
    Opportunity opp = [select Id,Product__c from Opportunity where Id =: recordId limit 1];
    productName = opp.Product__c;
    return productName;
  }

  @AuraEnabled(cacheable=true)
  public static string getOwnerName(string recordId){
    string OwnerName;
    List<Application_Verification__c> fiRecord = [SELECT Id,OwnerId,Name  FROM Application_Verification__c WHERE Id =:recordId limit 1];
    if(fiRecord.size()>0){
        OwnerName = fiRecord[0].OwnerId;
    }
    return OwnerName;
  }

   @AuraEnabled(cacheable=true)
  public static string getProductNameFromLA(string recordId){
    string productName;
    Application_Verification__c opp = [SELECT Id,Loan_Application__r.Product__c FROM Application_Verification__c where Id =: recordId limit 1];
    productName = opp.Loan_Application__r.Product__c;
    return productName;
  }
       
    // Wrapper class to include Parent.Name directly
    public class ApplicationVerificationHistoryWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String OldValue;
        @AuraEnabled public String NewValue;
        @AuraEnabled public String Field;
        @AuraEnabled public Id ParentId;
        @AuraEnabled public String ParentName;

        public ApplicationVerificationHistoryWrapper(Id Id, String OldValue, String NewValue, String Field, Id ParentId, String ParentName) {
            this.Id = Id;
            this.OldValue = OldValue;
            this.NewValue = NewValue;
            this.Field = Field;
            this.ParentId = ParentId;
            this.ParentName = ParentName;
        }
    }   

  @AuraEnabled
public static void createApplicationVerification(String fiList, Id loanApplicationId, String remarks, String selectedAssignee, List<Id> documentIds) {
    System.debug('fiList JSON -- ' + fiList);
    System.debug('documentIds -- ' + documentIds);
    System.debug('documentIds -- ' + selectedAssignee);

    // Deserialize the JSON string into a list of wrapper objects
    List<ApplicantWrapper> applicantList = (List<ApplicantWrapper>) JSON.deserialize(fiList, List<ApplicantWrapper>.class);
    
    Map<Id,String> appVerIdToRemarksMap = new Map<Id,String>();
   // Map<Application_Verification__c, String> tempRemarkMap = new Map<Application_Verification__c, String>();
     List<String> formattedRemarks = new List<String>();
    System.debug('applicantList size: ' + (applicantList == null ? 0 : applicantList.size()));

    List<Application_Verification__c> verifications = new List<Application_Verification__c>();
    Map<String, Id> recordTypeNameToIdMap = new Map<String, Id>();
  //  Map<Id,String>appVerIdToRemMap = new Map<Id,string>();
                for (RecordType rt : [
                    SELECT Id, DeveloperName 
                    FROM RecordType 
                    WHERE SObjectType = 'Application_Verification__c'
                ]) {
                    recordTypeNameToIdMap.put(rt.DeveloperName, rt.Id);
                }
    // Create Application_Verification__c records
    for (ApplicantWrapper fi : applicantList) {
        System.debug('fi.recordTypeName -- ' + fi.recordTypeName);
        Application_Verification__c appVer = new Application_Verification__c();
        appVer.Address__c = fi.addressId;
        appVer.Applicant__c = fi.applicantId;
        appVer.Loan_Application__c = loanApplicationId;
        // appVer.Credit_Manager_s_Remarks__c = Utility.getFormattedRemarks(remarks, '');
        appVer.Stage__c = 'Approved by CM';
        appver.Assigned_To_User__c = fi.selectedAssignee;
        String developerName = fi.recordTypeName.replace(' ', '_');
        appVer.RecordTypeId = recordTypeNameToIdMap.get(developerName);
        appVer.Overall_Status__c = fi.fiStage;
        verifications.add(appVer);
        formattedRemarks.add(Utility.getFormattedRemarks(remarks, ''));
      //tempRemarkMap.put(appVer, Utility.getFormattedRemarks(remarks, ''));
    }


    if (!verifications.isEmpty()) {
        insert verifications;
    }

  for (Integer i = 0; i < verifications.size(); i++) {
    appVerIdToRemarksMap.put(verifications[i].Id, formattedRemarks[i]);
}

    system.debug('appVerIdToRemarksMap' + appVerIdToRemarksMap);
    system.debug('verifications----'+verifications);
    system.debug('verifications----'+verifications.size());

    // Now insert Document_Detail__c records linked to the newly inserted Application_Verification__c records
    // Assuming documentIds apply to all verifications — if not, modify accordingly.
            verifications = [SELECT Id, Name,Credit_Manager_s_Remarks__c FROM Application_Verification__c WHERE Id IN :verifications];

            List<Document_Details__c> docs = new List<Document_Details__c>();

            for (Application_Verification__c insertedVer : verifications) {
                for (Id docId : documentIds) {
                    docs.add(new Document_Details__c(
                        Application_Verification__c = insertedVer.Id,
                        Content_Document_Id__c = docId,
                        Name = insertedVer.Name + ' Report1'  // Now insertedVer.Name will have a value
                    ));
                }
            }

            if (!docs.isEmpty()) {
                insert docs;
            }

            // Insert ContentDocumentLink records to share documents (bulk insert)
            List<ContentDocumentLink> contentDocLinks = new List<ContentDocumentLink>();

            for (Application_Verification__c insertedVer : verifications) {
                for (Id docId : documentIds) {
                    contentDocLinks.add(new ContentDocumentLink(
                        ContentDocumentId = docId,
                        LinkedEntityId = insertedVer.Id,
                        ShareType = 'V',       // Viewer access
                        Visibility = 'AllUsers' // Visible to all users
                    ));
                }
            }

            if (!contentDocLinks.isEmpty()) {
                insert contentDocLinks;
            }
            //Utility.createNotesRecords('Credit Manager Initiation Remarks',appVerIdToRemarksMap);
            system.debug('map####'+ appVerIdToRemarksMap);
        }
        public class AddressWrapper {
    public Id addressId;
    public Id applicantId;
    public String city;
    public String name;
    public String pincode;
    public String addressLine1;
    public String fullAddress;

    public AddressWrapper(Id addressId, Id applicantId, String city, String name, String pincode, String addressLine1, String fullAddress) {
        this.addressId = addressId;
        this.applicantId = applicantId;
        this.city = city;
        this.name = name;
        this.pincode = pincode;
        this.addressLine1 = addressLine1;
        this.fullAddress = fullAddress;
    }
}
 @AuraEnabled(cacheable=true)
    public static List<OpportunityTeamMember> getOpportunityTeamMembers(Id loanId){
        Application_Verification__c appVerification=[select id,Loan_Application__c from Application_Verification__c where id=:loanId limit 1];
        return [SELECT Id,Name,TeamMemberRole,User.EmployeeNumber, OpportunityAccessLevel,UserId FROM OpportunityTeamMember WHERE OpportunityId = :appVerification.Loan_Application__c AND TeamMemberRole IN ('DSA Executive','Sales Rep','OPS Maker','OPS Author', 'Credit', 'Sales')];
    }
}