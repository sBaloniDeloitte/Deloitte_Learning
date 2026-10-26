public with sharing class PayoutManagementController {

    @AuraEnabled(cacheable=true)
    public static List<String> getCurrentUserDetails(){
        List<string> result = new List<string>();
        result.add([Select Name From Profile Where Id =: UserInfo.getProfileId()].Name);
        result.add(UserInfo.getName());
        return result;
    }

    @AuraEnabled
    public static Map<string, string> getStatusToShow(string profile, string processName, string processType){
        
        Map<string, string> result = new Map<string, string>();
        result.put('All', '');

        List<Vendor_Invoice_Record_Display_Master__mdt> rec = [Select Status_to_Include__c From Vendor_Invoice_Record_Display_Master__mdt 
                                                                Where Profile__c =: profile And Screen_Type__c =: processName And Process_Name__c =: processType 
                                                                And Status_to_Include__c != '' Limit 1];
        if(!rec.isEmpty()){
            List<string> options = rec[0].Status_to_Include__c.split(',');
            options.sort();
            
            for(string item : options){
                result.put(item, item);
            }
        }

        return result;
    }

    @AuraEnabled
    public static List<PayoutWrapper> getPayoutRecords(string fromDate, string toDate, string loanPayoutId, string dsaId, string payoutId, string status, string processName, string profile){

        System.debug('fromDate: '+fromDate);
        System.debug('toDate: '+toDate);
        System.debug('loanPayoutId: '+loanPayoutId);
        System.debug('dsaId: '+dsaId);
        System.debug('payoutId: '+payoutId);
        System.debug('status: '+status);
        System.debug('processName: '+processName);
        Profile currentProfile = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId() LIMIT 1];
        Map<string, Object> bindVars = new Map<string, Object>();
        Set<Id> referredByDsaIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        string query = 'Select Id, Name, Loan_Number__c, Amount__c, Remarks__c, Status__c, Disbursed_Amount__c, Branch__c,Branch_Master__c,Branch_State__c, Additional__c,CustomerName__c,Sub_Product__c, Product__c, ROI__c, '+
                        'Sanction_Loan_Amount__c, Customer_Name__c, Channel_Name__c, Channel_Code__c, PF_Percentage__c, PF_Amount__c, Slab__c, Booking_Month__c, '+
                        'Loan_Type__c, Booking_Date__c, BT_Document__c, CSD_Document__c, PDD_Document__c, Subvention__c, Net_Premium__c, Value_Penetration__c, '+
                        'Total_Slab__c, Manager_Name__c, Type_Of_Channel__c, Login_Date__c, Total_Payout__c, DSA_Type__c, Insurance_Payout__c, Insurance_Rate__c, Type_Of_DSA__c, '+
                        'Cluster_Manager_Name__c, Is_Action_Taken__c, CreatedDate, Payout_Manager__c, Payout_Manager__r.Name From Vendor_Invoice__c Where RecordType.Name = \'Payout\' ';

        query += buildFilterQuery(fromDate, toDate, loanPayoutId, dsaId, payoutId, status, processName, profile, bindVars);
        
        System.debug('query: '+query);
        Set<Id> branchMasterIdSet = new Set<Id>();
        Map<Id, List<PayoutWrapper>> branchToPayoutMap = new Map<Id, List<PayoutWrapper>>();
        Map<Id, Map<String, List<PayoutWrapper>>> branchProductPayoutMap = new Map<Id, Map<String, List<PayoutWrapper>>>();
        List<PayoutWrapper> result = new List<PayoutWrapper>();
        System.debug('Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE>>>'+Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE));
        for(SObject rec : Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE)){
            
            PayoutWrapper payout = new PayoutWrapper();
            payout.recordId = (string) rec.get('Id');
            payout.name = (string) rec.get('Name');
            payout.status = (string) rec.get('Status__c');
            payout.customerName = (string) rec.get('Customer_Name__c');
            payout.loanType = (string) rec.get('Loan_Type__c');
            payout.disbursedAmount = (decimal) rec.get('Disbursed_Amount__c');
            payout.channelName = (string) rec.get('Channel_Name__c');
            payout.channelCode = (string) rec.get('Channel_Code__c');
            payout.pf = rec.get('PF_Percentage__c') != null ? (Decimal) rec.get('PF_Percentage__c') : null;
            payout.pfAmount = rec.get('PF_Amount__c') != null ? (Decimal) rec.get('PF_Amount__c') : null;
            payout.slab = rec.get('Slab__c') != null ? (Decimal) rec.get('Slab__c') : null;
            payout.totalSlab = rec.get('Total_Slab__c') != null ? (Decimal) rec.get('Total_Slab__c') : null;
            payout.subvention = rec.get('Subvention__c') != null ? (Decimal) rec.get('Subvention__c') : null;
            payout.amount = rec.get('Amount__c') != null ? (decimal) rec.get('Amount__c') : null;
            payout.netPremium = rec.get('Net_Premium__c') != null ? (Decimal) rec.get('Net_Premium__c') : null;
            payout.valuePenetration = rec.get('Value_Penetration__c') != null ? (Decimal) rec.get('Value_Penetration__c') : null;
            payout.managerName = (string) rec.get('Manager_Name__c');
            payout.clusterManagerName = (string) rec.get('Cluster_Manager_Name__c');
            payout.remarks = (string) rec.get('Remarks__c');
            payout.loanApplicationNo = (string) rec.get('Loan_Number__c');
            payout.branch = (string) rec.get('Branch__c');
            payout.branchmaster = (string) rec.get('Branch_Master__c');
            payout.branchstate = (string) rec.get('Branch_State__c');
            payout.product = (string) rec.get('Product__c');
            payout.sanctionAmount = (decimal) rec.get('Sanction_Loan_Amount__c');
            payout.subProduct = (string) rec.get('Sub_Product__c');
            payout.roi = (decimal) rec.get('ROI__c');
            payout.typeOfChannel = (string) rec.get('Type_Of_Channel__c');
            payout.month = (string) rec.get('Booking_Month__c');
            payout.csdDocument = (String) rec.get('CSD_Document__c');
            payout.pddDocument = (string) rec.get('PDD_Document__c');
            payout.btDocument = (string) rec.get('BT_Document__c');
            payout.dsaType = (string) rec.get('Type_Of_DSA__c');
            payout.typeOfDsa = (string) rec.get('Type_Of_DSA__c');
            payout.insuranceRate = (decimal) rec.get('Insurance_Rate__c');
            payout.insurancePayout = (decimal) rec.get('Insurance_Payout__c');
            payout.totalPayout = (decimal) rec.get('Total_Payout__c');
            payout.isActionTaken = (Boolean) rec.get('Is_Action_Taken__c');
            payout.isPayoutFromSFLoan = ((string) rec.get('Loan_Number__c')).startsWith('LA-');

            DateTime bookingDate = (DateTime) rec.get('Booking_Date__c');
            payout.bookingDate = bookingDate.format('dd-MM-yyyy');

            DateTime logindDate = (DateTime) rec.get('Login_Date__c');
            system.debug('login Date ==> '+logindDate);
            payout.loginDate = logindDate.format('dd-MM-yyyy');
            
            payout.additional = (decimal) rec.get('Additional__c');
            payout.customer = (string) rec.get('CustomerName__c');
            if (rec.get('Payout_Manager__c') != null)
            {
                payout.payoutmanager = (string) rec.getSObject('Payout_Manager__r').get('Name');

            }
            
            if (currentProfile.Name != 'GC Product Team' && currentProfile.Name != 'GC Product Head') {
                result.add(payout);
            } else {
                String branchId = (Id) rec.get('Branch_Master__c');
                System.debug('branchId>>>'+branchId);
                if (branchId != null) {
                    branchMasterIdSet.add(branchId);
                    if (!branchToPayoutMap.containsKey(branchId)) {
                        branchToPayoutMap.put(branchId, new List<PayoutWrapper>());
                    }
                    branchToPayoutMap.get(branchId).add(payout);
                }
                if(payout.product != null) {
                    if (!branchProductPayoutMap.containsKey(branchId)) {
                        branchProductPayoutMap.put(branchId,new Map<String, List<PayoutWrapper>>());
                    }
                }
                System.debug('branchProductPayoutMap : '+branchProductPayoutMap);
                Map<String, List<PayoutWrapper>> productMap = branchProductPayoutMap.get(branchId);
                if (!productMap.containsKey(payout.product)) {
                    productMap.put(payout.product, new List<PayoutWrapper>());
                }
                productMap.get(payout.product).add(payout);
            }   
        }
        if (currentProfile.Name != 'GC Product Team' && currentProfile.Name != 'GC Product Head') {
            return result;
        } else {
            List<PayoutWrapper> filteredResult = new List<PayoutWrapper>();
            if (!branchMasterIdSet.isEmpty()) {
                List<AccountTeamMember> accTeamMemberList = [SELECT Id, AccountId, Vertical__c FROM AccountTeamMember WHERE AccountId IN :branchMasterIdSet AND UserId = :UserInfo.getUserId()];
                Map<Id, Set<String>> branchToVerticalMap = new Map<Id, Set<String>>();
                if (!accTeamMemberList.isEmpty()) {
                    for (AccountTeamMember atm : accTeamMemberList) {
                        if (String.isBlank(atm.Vertical__c)) {
                            continue;
                        }
                        if (!branchToVerticalMap.containsKey(atm.AccountId)) {
                            branchToVerticalMap.put(atm.AccountId, new Set<String>());
                        }
                        for (String vertical : atm.Vertical__c.split(';')) {
                            if (!String.isBlank(vertical)) {
                                branchToVerticalMap.get(atm.AccountId).add(vertical.trim());
                            }
                        }
                        System.debug('branchToVerticalMap: '+branchToVerticalMap);
                    }
                    for (Id branchId : branchToVerticalMap.keySet()) {
                        if (!branchProductPayoutMap.containsKey(branchId)) {
                            continue;
                        }
                        Map<String, List<PayoutWrapper>> productMap = branchProductPayoutMap.get(branchId);
                        System.debug('productMap: '+productMap);
                        System.debug('branchToVerticalMap1: '+branchToVerticalMap);
                        for (String vertical : branchToVerticalMap.get(branchId)) {
                            if (productMap.containsKey(vertical)) {
                                System.debug('inside final add');
                                filteredResult.addAll(productMap.get(vertical));
                            }
                        }
                    }
                }
            }
            System.debug('filteredResult: ' + filteredResult);
            return filteredResult;

        }
    }

    public static string buildFilterQuery(string fromDate, string toDate, string loanPayoutId, string dsaId, string payoutId, string status, string processName, string profile, Map<string, Object> bindVars){

        string query = '';
        
        if(fromDate != null && toDate != null){
            query += 'And CreatedDate >= ' + (date.valueOf(fromDate).toString().replace(' 00:00:00', 'T00:00:00.001+0000')) +' And CreatedDate <= ' + (date.valueOf(toDate).toString().replace(' 00:00:00', 'T23:59:59.999+0000')) + ' ';
        }

        system.debug('query: '+query);

        if(String.isNotBlank(loanPayoutId)){
            bindVars.put('loanPayoutId', loanPayoutId);
            query += 'And Id =: loanPayoutId ';
        }
        else if(String.isNotBlank(payoutId)){
            bindVars.put('payoutId', payoutId);
            query += 'And Id =: payoutId ';
        }

        switch on profile { 
            when 'Partner Community User' {
                bindVars.put('dsaId', [Select AccountId From User Where Id =: UserInfo.getUserId()].AccountId);
                query += 'And DSA__c =: dsaId ';
            }
            when 'Sales' {
                bindVars.put('payoutManagerId', UserInfo.getUserId());
                query += ' AND Payout_Manager__c = :payoutManagerId ';
            }
            when else { 
                if(String.isNotBlank(dsaId)){
                    bindVars.put('dsaId', dsaId);
                    query += 'And DSA__c =: dsaId ';
                }
            }
        }

        string statusQuery = ' ';

        if(string.isNotBlank(status)){
            bindVars.put('status', status);
            statusQuery = 'And Status__c =: status ';
        }
        else {
            System.debug('profile: '+profile);
            statusQuery = 'And Status__c = \'\' ';

            List<Vendor_Invoice_Record_Display_Master__mdt> recstatusList = [Select Id, Status_to_Include__c From Vendor_Invoice_Record_Display_Master__mdt 
                                                                            Where Profile__c =: profile And Screen_Type__c =: processName 
                                                                            And Process_Name__c = 'Payout' And Status_to_Include__c != '' Limit 1];

            if(!recstatusList.isEmpty()){
                bindVars.put('statusIn', recstatusList[0].Status_to_Include__c.split(','));
                statusQuery = 'And Status__c IN : statusIn ';
            }
        }

        query += statusQuery + 'Order By Name ASC Limit 3000';

        return query;
    }

    @AuraEnabled
    public static List<String> updatePayoutRecords(string records, string profile, string action){
        system.debug('profile: '+profile);

        List<string> result = new List<string>();

        try {
            List<Vendor_Invoice_Action_Master__mdt> actionList = [SELECT Id, Next_Status__c, Success_Meaage__c FROM Vendor_Invoice_Action_Master__mdt 
                                                                    WHERE Profile__c =: profile AND Action__c =: action And Next_Status__c != '' LIMIT 1]; 
            system.debug('actionList: '+actionList);

            if(!actionList.isEmpty()){
                List<Object> recordList = (List<Object>)JSON.deserializeUntyped(records);
                system.debug('recordList: '+recordList);
    
                List<Vendor_Invoice__c> recToUpdate = new List<Vendor_Invoice__c>();

                //this flag is for keeping track if after submit payout any action taken or not to allow pullback
                Boolean actionTaken = true;
                if(actionList[0].Next_Status__c == 'Sent To Product Head' || actionList[0].Next_Status__c == 'Sent For Rework' || actionList[0].Next_Status__c == 'Ready For Invoicing'){
                    actionTaken = false;
                }
                Set<Id> vendorInvoiceRecId = new Set<Id>();
                for(Object item : recordList){
                    Vendor_Invoice__c rec = (Vendor_Invoice__c)JSON.deserialize(JSON.serialize(item), Vendor_Invoice__c.class);
                    rec.Remarks__c = '['+ actionList[0].Next_Status__c +'] - '+ rec.Remarks__c;
                    rec.Status__c = actionList[0].Next_Status__c;
                    rec.Is_Action_Taken__c = actionTaken;
                    vendorInvoiceRecId.add(rec.Id);
                    recToUpdate.add(rec);
                }
    
                System.debug('recToUpdate: '+recToUpdate);
                update recToUpdate;
                String userGroup = '';
                String title = 'Payout Assigned';
                if (action == 'Submit Payout') {
                    userGroup = 'All Product Head Users';
                } else if (action == 'Approve') {
                    userGroup = 'DSA';
                }
                if (!vendorInvoiceRecId.isEmpty()) {
                    for(Id record : vendorInvoiceRecId) {
                        sendNotificationToUsers(record, 'assigned to you', title, userGroup);
                    }
                }
                result.add('Success');
                result.add(actionList[0].Success_Meaage__c);
            }
            else{
                result.add('Master data not found, please contact to System Admin.');
            }
        } 
        catch (Exception e) {
            system.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
            result.add(e.getMessage());
        }

        return result;
    }

    
    @AuraEnabled
    public static List<Map<string, string>> getPayoutDataToExport(string fromDate, string toDate, string loanPayoutId, string dsaId, string payoutId, string status, string processName, string profile){
        
        List<Map<string, string>> result = new List<Map<string, string>>();

        try{
            Map<Integer, string> displaySeqMap = new Map<Integer, string>();
            Map<string, string> columnMap = new Map<string, string>();
            Integer counter = 1;
            for(BulkUpsertDetails__mdt iterMeta : [Select Label, FieldAPIName__c, Display_Sequence__c From BulkUpsertDetails__mdt 
                                                    Where ObjectName__c = 'Vendor_Invoice__c' And Process__c = 'Payout']) {
                columnMap.put(iterMeta.FieldAPIName__c, iterMeta.Label);

                Integer seq = iterMeta.Display_Sequence__c != null ? Integer.valueOf(iterMeta.Display_Sequence__c) : counter;
                displaySeqMap.put(seq, iterMeta.FieldAPIName__c);

                counter++;
            }
            
            if(!columnMap.isEmpty()) {

                //sorting the fields based on display sequence assigned in metadata
                Map<string, string> sortColumnMap = new Map<string, string>();

                for(Integer i=1; i<=counter; i++){
                    if(displaySeqMap.containsKey(i)){
                        sortColumnMap.put(displaySeqMap.get(i), columnMap.get(displaySeqMap.get(i)));
                    }
                }
                
                columnMap.clear();
                columnMap.putAll(sortColumnMap);
                sortColumnMap.clear();
                system.debug('columnMap: '+columnMap);
                //------

                Map<string, Object> bindVars = new Map<string, Object>();
                Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Vendor_Invoice__c').getDescribe().fields.getMap();

                string query = 'Select '+ String.join(columnMap.keySet(), ', ') +' From Vendor_Invoice__c Where RecordType.Name = \'Payout\' ';

                query += buildFilterQuery(fromDate, toDate, loanPayoutId, dsaId, payoutId, status, processName, profile, bindVars);
                System.debug('export query: '+query);
                
                for(SObject rec : Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE)){
                    Map<String, object> recordMap = (Map<String, object>) JSON.deserializeUntyped(JSON.serialize(rec));
                    //system.debug('--- '+ JSON.serialize(recordMap));
    
                    Map<string, string> fieldDataMap = new Map<string, string>();

                    for(string field : columnMap.keySet()){
                        string fieldValue = '';
                        system.debug('field: '+field);

                        Schema.DisplayType fielddataType = fieldMap.get(field).getDescribe().getType();
                        System.debug('fielddataType: '+fielddataType);
    
                        if(field.contains('__r.')){
                            List<string> lookupField = field.split('\\.');
                            system.debug('lookupField: '+lookupField);

                            Integer index = 0;
                            sObject parenObj = rec;
                            
                            while(index < (lookupField.size() -1)){
                                if(parenObj != null){
                                    parenObj = parenObj?.getSobject(lookupField[index]);
                                }
                                index++;
                            }

                            fieldValue = (string) parenObj?.get(lookupField[index]);
                        }
                        else{
                            if(fielddataType == Schema.DisplayType.Datetime || fielddataType == Schema.DisplayType.Date){
                                List<String> dateParts = recordMap.get(field).toString().split('T');

                                if(dateParts.size() >= 1) {
                                    List<String> dateSplit = dateParts[0].split('-');
                                    Integer year = Integer.valueOf(dateSplit[0]);
                                    Integer month = Integer.valueOf(dateSplit[1]);
                                    Integer day = Integer.valueOf(dateSplit[2]);
                                    fieldValue = day +'-'+ month +'-'+ year;
                                }
                            }
                            else {
                                fieldValue = string.valueOf(recordMap.get(field));
                            }
                        }
                        
                        fieldValue = fieldValue == null ? '' : fieldValue;
                        system.debug('fieldValue: '+fieldValue);

                        fieldDataMap.put(columnMap.get(field), fieldValue);
                    }

                    result.add(fieldDataMap);
                }
            }
            else {
                result.add(new Map<string, string>{'Error' => 'No master data found to export, please contact to System Admin'});
            }
        }
        catch(Exception e){
            system.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
            result.add(new Map<string, string>{'Error' => e.getMessage()});
        }
        
        system.debug('result: '+ JSON.serialize(result));
        return result;
    }

    public static string validateInput(String inputString) {
        string result = inputString.trim();
        // system.debug('result 309: '+result);

        // Characters that make Excel treat the field as a formula
        List<string> dangerous = new List<string> {'=', '+', '-', '@', '|'};

        // Escape if field starts with any dangerous character
        if(dangerous.contains(result.left(1))) {
            result = '\''+ result;   // Excel displays value as-is
        }
        // system.debug('result 407: '+result);

        // Escapes HTML special characters, rendering the script harmlessly as text
        result = result.escapeHtml4();
        // system.debug('result 411: '+result);

        //Returns String with the escape character (\) added before any single quotation mark (') or backslash (\) in the String.
        result = String.escapeSingleQuotes(result);
        // system.debug('result 415: '+result);

        return result;
    }

    @AuraEnabled
    public static List<String> saveFile(String fileID, String processName) {
            
        List<String> result = new List<String>();
        
        try{
            Map<String, BulkUpsertDetails__mdt> mapOfMetaData = new Map<String, BulkUpsertDetails__mdt>();
            
            for(BulkUpsertDetails__mdt iterMeta : [Select Label, FieldAPIName__c, Skip_Field__c, Is_Mandatory__c From BulkUpsertDetails__mdt 
                                                    Where ObjectName__c = 'Vendor_Invoice__c' And Process__c = 'Payout']) {
                
                mapOfMetaData.put(iterMeta.Label, iterMeta);
            }
            
            System.debug('mapOfMetaData>>'+mapOfMetaData);
            
            if(mapOfMetaData.isEmpty()) {
                result.add('No master data found.');
                return result;
            }

            ContentVersion objDoc = [SELECT id, VersionData FROM ContentVersion WHERE ContentDocumentId =: fileID];
            if(objDoc != null){
                Blob base64Data = objDoc.VersionData;
                String data = base64Data.toString();
                List<String> lstCSVLines = data.split('\n');
                
                Boolean isInvalidColumn = false;
                List<String> headerColumn = getHeader(lstCSVLines[0]);
                //System.debug('headerColumn: '+ JSON.serialize(headerColumn));
                //System.debug('mapOfMetaData: '+ JSON.serialize(mapOfMetaData));
    
                Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                Schema.SObjectType objSchema = schemaMap.get('Vendor_Invoice__c');
                Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe().fields.getMap();
    
                List<Vendor_Invoice__c> lstInvoices = new List<Vendor_Invoice__c>();
                Map<Integer, String> resultMap = new Map<Integer, String>();
                Map<Integer, Integer> validRecordToSheetRowNoMap = new Map<Integer, Integer>();
                integer seqNo = Utility.getVendorInvoiceNextNumber('Payout') -1;
                Integer rowNo = 1;

                Map<string, string> existingLoanNo = new Map<string, string>();
                Map<string, string> existingPayoutMap = new Map<string, string>();

                for(Vendor_Invoice__c rec : [Select Id, Name, Loan_Number__c, Status__c From Vendor_Invoice__c Where RecordType.Name = 'Payout' And Loan_Number__c != '']){
                    existingLoanNo.put(rec.Loan_Number__c.toLowerCase(), rec.Name);
                    existingPayoutMap.put(rec.Id, rec.Status__c);
                }

                Map<string, string> dsaMap = new Map<string, string>();
                for(Account acc : [SELECT Id, Vendor_Code__c FROM Account Where RecordType.Name = 'Partner' And Partner_Type__c = 'DSA' And Vendor_Code__c != '']){
                    dsaMap.put(acc.Vendor_Code__c, acc.Id);
                }

                //loop on rows
                for(Integer i = 1; i < lstCSVLines.size(); i++){
                    String csvLine = lstCSVLines[i];
                    System.debug('csvLine>>>'+csvLine);
                    Integer startIndex;
                    Integer endIndex;
                    Boolean isNewRecord = false;
                    System.debug('csvLine.indexOf()>>'+csvLine.indexOf('"'));
                    
                    while(csvLine.indexOf('"') > -1){
                        if(startIndex == null){
                            startIndex = csvLine.indexOf('"');
                            csvLine = csvLine.substring(0, startIndex) + ':quotes:' + csvLine.substring(startIndex +1, csvLine.length());
                        }
                        else{
                            if(endIndex == null){
                                endIndex = csvLine.indexOf('"');
                                csvLine = csvLine.substring(0, endIndex) + ':quotes:' + csvLine.substring(endIndex +1, csvLine.length());
                            }
                        }
    
                        if(startIndex != null && endIndex != null){
                            String sub = csvLine.substring(startIndex, endIndex);
                            sub = sub.replaceAll(',', ':comma:');
                            csvLine = csvLine.substring(0, startIndex) + sub + csvLine.substring(endIndex, csvLine.length());
                            startIndex = null;
                            endIndex = null;
                        }
                    }
    
                    System.debug('csvRow: '+csvLine);

                    List<String> csvRowData = new List<String>();
                    Integer indexCount = 0;
                    Vendor_Invoice__c invObj = new Vendor_Invoice__c();
                    List<String> errorMsg = new List<String>();
                    Boolean isError = false;
                    string recId = '';
                    string recName = '';
                    string loanNo = '';
                    string loanNoLabel = '';
    
                    //loop on columns
                    for(String column : csvLine.split(',')){
                        column = column.replaceAll(':quotes:', '').replaceAll(':comma:', ',');
                        column = column.replaceAll('\r', '');
                        column = validateInput(column);
                        csvRowData.add(column);

                        string fieldLabel = headerColumn[indexCount];
                        string fieldApi = mapOfMetaData.get(fieldLabel).FieldAPIName__c;
                        indexCount++;

                        switch on fieldApi {
                            when 'Id' {
                                recId = column;

                                //logic to assign auto record number
                                if(String.isBlank(column)){
                                    seqNo++;
                                    integer charSize = String.valueOf(seqNo).length();
                                    string seqName = 'P-';
                                    while (charSize <9) {
                                        seqName += '0';
                                        charSize++;
                                    }

                                    invObj.put('Name', seqName + seqNo);
                                    invObj.put('Created_By_Import__c', true);
                                    column = null;
                                    isNewRecord = true;
                                }
                                else {
                                    //handle the scenario where user change the status and try to update the existing payout
                                    if(existingPayoutMap.containsKey(recId) && existingPayoutMap.get(recId) != 'Draft' && existingPayoutMap.get(recId) != 'Sent For Rework'){
                                        errorMsg.add('Payout update is not allowed.');
                                        isError = true;
                                        continue;
                                    }
                                }

                                invObj.put(fieldApi, column);
                            }
                            when 'Name' {
                                recName = column;
                            }
                            when 'SF_Loan_No__c', 'Loan_No__c' {
                                loanNo = String.isBlank(loanNo) ? column.trim() : loanNo;
                                loanNoLabel += fieldLabel +' / ';

                                if(String.isNotBlank(loanNo) && String.isBlank(recId) && existingLoanNo.containsKey(loanNo.toLowerCase())){
                                    errorMsg.add(existingLoanNo.get(loanNo.toLowerCase()) +' Payout already exist for this Loan No: '+ loanNo);
                                    isError = true;
                                    continue;
                                }
                            }
                        }
                         system.debug('Field Label: '+fieldLabel);
                        System.debug('mapOfMetaData.get(fieldLabel).Skip_Field__c>>'+mapOfMetaData.get(fieldLabel).Skip_Field__c);

                        //skip field value to update in database
                        if(mapOfMetaData.get(fieldLabel).Skip_Field__c) {
                            System.debug('Skip field: '+fieldLabel);
                            continue;
                        }

                       

                        if(String.isBlank(column) && mapOfMetaData.get(fieldLabel).Is_Mandatory__c) {
                            errorMsg.add('['+ fieldLabel +'] - '+ Constants__mdt.getInstance('ERROR_REQUIRED_FIELD_MISSING').Value__c);
                            isError = true;
                            continue;
                        }
    
                        //if(!isError) {
                            Schema.DisplayType fielddataType = fieldMap.get(fieldApi).getDescribe().getType();
                            System.debug('fielddataType: '+fielddataType);
                            System.debug('Field Value: '+column);

                            if(fielddataType == Schema.DisplayType.CURRENCY || fielddataType == Schema.DisplayType.DOUBLE || fielddataType == Schema.DisplayType.PERCENT) {
                                column = column.trim();
                                invObj.put(fieldApi, (String.isNotBlank(column) ? Double.valueOf(column) : null));
                                System.debug('Field Value after: '+column);
                            }
                            else if(fielddataType == Schema.DisplayType.Date){
                                column = column.trim();
                                if(String.isNotBlank(column)) {
                                    List<String> dateSplit = column.contains('-') ? column.split('-') : column.split('/');
                                    
                                    if(dateSplit.size() == 3) {
                                        Integer month = Integer.valueOf(dateSplit[1]);
                                        Integer day = Integer.valueOf(dateSplit[0]);
                                        Integer year = Integer.valueOf(dateSplit[2]);
                                        invObj.put(fieldApi, Date.newInstance(year, month, day));
                                        System.debug('Field Value after: '+column);
                                    }
                                }
                            }
                            else{
                                switch on fieldApi { 
                                    when 'Channel_Code__c' {
                                        column = column.trim();
                                        if(!dsaMap.containsKey(column)){
                                            errorMsg.add('DSA with this Channel Code not found in the system.');
                                            isError = true;
                                            continue;
                                        }
                                        else{
                                            invObj.put('DSA__c', dsaMap.get(column));
                                        }
                                    }
                                    when 'Remarks__c'{
                                        if(isNewRecord){
                                            column = null;
                                        }
                                        else if(string.isNotBlank(column)){
                                            List<string> usrDetails = getCurrentUserDetails();
                                            string remarksHeader = usrDetails[1] +' ('+ usrDetails[0] +') - '+ Datetime.now().format('dd/MM/YYYY, hh:mm a') +': ';
                                            column = remarksHeader + column;
                                        }
                                        System.debug('Field Value after: '+column);
                                    }
                                }

                                invObj.put(fieldApi, column);
                            }
                        //}
                    }

                    //checking if data is populated in SF Loan No or Loan No field
                    if(String.isBlank(loanNo)){
                        errorMsg.add('['+ loanNoLabel.removeEnd(' / ') +'] - '+ Constants__mdt.getInstance('ERROR_REQUIRED_FIELD_MISSING').Value__c);
                        isError = true;
                    }
                    
                    if(!isError) {
                        lstInvoices.add(invObj);
                        validRecordToSheetRowNoMap.put(lstInvoices.size(), rowNo);
                    }

                    string respValue = errorMsg.isEmpty() ? (recId +','+ recName +',,') : (recId +','+ recName +',Error,'+(String.join(errorMsg, ' : ')));
                    resultMap.put(rowNo, respValue);
                    System.debug('resultMap: '+ JSON.serialize(resultMap));

                    rowNo++;
                }
    
                if(!lstInvoices.isEmpty()) {
                    System.debug('lstInvoices: '+ JSON.serialize(lstInvoices));
    
                    Database.UpsertResult[] results = Database.upsert(lstInvoices, false);
                    system.debug('Upsert results: '+JSON.serialize(results));
    
                    Set<Id> invIdSet = new Set<Id>();
                    Map<Id, String> recordNoMap = new Map<Id, String>();
                    for(Database.UpsertResult iterRes : results) {
                        if(iterRes.isSuccess()) {
                            invIdSet.add(iterRes.getId());
                        }
                    }
    
                    for(Vendor_Invoice__c rec : [SELECT ID, Name From Vendor_Invoice__c Where Id In : invIdSet]){
                        recordNoMap.put(rec.Id, rec.Name);
                    }
                    //System.debug('recordNoMap----'+ recordNoMap);
    
                    Integer index= 0;
                    for(Database.UpsertResult iterRes : results) {
                        
                        String responsedata = '';

                        if(iterRes.isSuccess()) {
                            responsedata = iterRes.getId() +','+ recordNoMap.get(iterRes.getId()) +',Success,';
                        }
                        else {
                            String errorMsg= '';
                            for(Database.Error err : iterRes.getErrors()) {
                                errorMsg = errorMsg + err.getMessage() + ' \n ';
                                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            }

                            responsedata = iterRes.getId() +','+ lstInvoices[index].Id +',Fail,'+ errorMsg;
                        }

                        resultMap.put(validRecordToSheetRowNoMap.get(index+1), responsedata);
                        index++;
                    }
                }
    
                result.add('Success');
                result.addAll(resultMap.values());
                
                System.debug('result---'+result);
                return result;
            }
            else{
                result.add('No master data found, please contact to System Admin.');
                return result;
            }
        }
        catch (System.Exception e){
            System.debug('Error message: ' + e.getMessage() + ' \n StackTrace: '+ e.getStackTraceString());
            result.add(e.getMessage());
            return result;
        }
    }

    //To read the data from the headers
    public static List<String> getHeader(String headerLine) {
        String csvLine = headerLine;
        Integer startIndex;
        Integer endIndex;

        while(csvLine.indexOf('"') > -1){
            if(startIndex == null){
                startIndex = csvLine.indexOf('"');
                csvLine = csvLine.substring(0, startIndex) + ':quotes:' + csvLine.substring(startIndex +1, csvLine.length());
            }
            else{
                if(endIndex == null){
                    endIndex = csvLine.indexOf('"');
                    csvLine = csvLine.substring(0, endIndex) + ':quotes:' + csvLine.substring(endIndex +1, csvLine.length());
                }
            }

            System.debug('endIndex: '+endIndex);
            System.debug('startIndex: '+startIndex);
            System.debug('csvLine: '+csvLine);

            if(startIndex != null && endIndex != null){
                String sub = csvLine.substring(startIndex, endIndex);
                sub = sub.replaceAll(',', ':comma:');
                csvLine = csvLine.substring(0, startIndex) + sub + csvLine.substring(endIndex, csvLine.length());
                startIndex = null;
                endIndex = null;
            }
        }

        List<String> csvRowData = new List<String>();
        for(String column : csvLine.split(',')){
            column = column.replaceAll(':quotes:', '').replaceAll(':comma:', ',');
            column = column.replaceAll('\r','');
            csvRowData.add(column);
        }

        return csvRowData;
    }

    public class PayoutWrapper {
        @AuraEnabled public string recordId;
        @AuraEnabled public string name;
        @AuraEnabled public string loanApplicationNo;
        @AuraEnabled public string status;
        @AuraEnabled public string customerName;
        @AuraEnabled public string branch;
        @AuraEnabled public string branchmaster;
        @AuraEnabled public string branchstate;
        @AuraEnabled public string product;
        @AuraEnabled public string loanType;
        @AuraEnabled public string month;
        @AuraEnabled public Decimal sanctionAmount;
        @AuraEnabled public decimal disbursedAmount;
        @AuraEnabled public string typeOfChannel;
        @AuraEnabled public string channelName;
        @AuraEnabled public string channelCode;
        @AuraEnabled public decimal roi;
        @AuraEnabled public decimal pf;
        @AuraEnabled public decimal slab;
        @AuraEnabled public decimal subvention;
        @AuraEnabled public decimal totalSlab;
        @AuraEnabled public decimal amount;
        @AuraEnabled public string dsaType;
        @AuraEnabled public string subProduct;
        @AuraEnabled public decimal pfAmount;
        @AuraEnabled public decimal netPremium;
        @AuraEnabled public decimal valuePenetration;
        @AuraEnabled public decimal insuranceRate;
        @AuraEnabled public decimal insurancePayout;
        @AuraEnabled public decimal totalPayout;
        @AuraEnabled public string managerName;
        @AuraEnabled public string clusterManagerName;
        @AuraEnabled public string bookingDate;
        @AuraEnabled public string loginDate;
        @AuraEnabled public string customer;
        @AuraEnabled public string payoutmanager;
        @AuraEnabled public decimal additional;
        @AuraEnabled public string remarks;
        @AuraEnabled public string btDocument;
        @AuraEnabled public string pddDocument;
        @AuraEnabled public string csdDocument;
        @AuraEnabled public string typeOfDsa;
        @AuraEnabled public Boolean isActionTaken;
        @AuraEnabled public Boolean isPayoutFromSFLoan;
    }

    @AuraEnabled
    public static string sendNotificationToUsers(String vendorInvoiceId, String message, String titleMessage, String userGroup) {
        if (String.isBlank(vendorInvoiceId)) {
            return 'Error: vendorInvoiceId is required';
        }
        List<Vendor_Invoice__c> vendorInvoiceList = [SELECT Id, Name, Branch_Master__c, DSA__c, CreatedById FROM Vendor_Invoice__c WHERE Id = :vendorInvoiceId LIMIT 1];
        if (vendorInvoiceList.isEmpty()) {
            return 'Error: No Vendor Invoice found';
        }
        String body = 'Payout : ' + vendorInvoiceList[0].Name + ' has been ' + message + ' by ' + UserInfo.getName() + '.';
        List<CustomNotificationType> notifType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = :'FCU_Notification' LIMIT 1];
        if (notifType.isEmpty()) {
            return 'Error: Notification type not found';
        }

        Set<String> userIds = new Set<String>();
        if (userGroup == 'All Product Users') {
            for (User u : [SELECT Id FROM User WHERE Profile.Name = 'GC Product Team' AND IsActive = true]) {
                userIds.add(u.Id);
            }
        } else if(userGroup == 'All Product Head Users')  {
            for (User u : [SELECT Id FROM User WHERE Profile.Name = 'GC Product Head' AND IsActive = true]) {
                userIds.add(u.Id);
            }
        } else if (userGroup == 'DSA') {
            if(vendorInvoiceList[0].DSA__c != null) {
                userIds.add(vendorInvoiceList[0].DSA__c);
            } else {
                System.debug('CreatedById : set as default in send as no DSA user found');
                userIds.add(vendorInvoiceList[0].CreatedById);
            }
        } else if (userGroup == 'All Finance Users'){
            for (User u : [SELECT Id FROM User WHERE Profile.Name = 'GC Finance Team' AND IsActive = true]) {
                userIds.add(u.Id);
            }
        } else {
            System.debug('CreatedById : set as default in send');
            userIds.add(vendorInvoiceList[0].CreatedById);
        }
        // if (userGroup == 'Branch') {
        //     userIds.addAll([SELECT Id FROM User WHERE Branch__c = :vendorInvoiceList[0].Branch__c].getIds());
        // }
        System.debug('setNotificationTypeId = notifType[0].Id : '+notifType[0].Id);
        System.debug('setTitle = titleMessage : '+titleMessage);
        System.debug('setTargetId = vendorInvoiceList[0].Id : '+vendorInvoiceList[0].Id);
        System.debug('setBody = body : '+body);
        System.debug('send = userIds : '+userIds);
        
        Messaging.CustomNotification notify = new Messaging.CustomNotification();
        notify.setNotificationTypeId(notifType[0].Id);
        notify.setSenderId(UserInfo.getUserId());
        notify.setTitle(titleMessage);
        notify.setBody(body);
        notify.setTargetId(vendorInvoiceList[0].Id);
        notify.send(userIds);
        return 'Success: Notification sent to ' + userIds.size() + ' user(s).';
    }
}