public class InstrumentMandateHandler {
    
    @AuraEnabled
    public static String reHitEnach(Id mandateId) { //for manual button api calling
        try {
            if (mandateId == null) {
                throw new AuraHandledException('Mandate Id is required');
            }
            
            List<Instrument_Mandate__c> mandates = [SELECT Id, ENACH_Status__c,ENACH_Ext_ID__c,Loan_Application__c, Loan_Application__r.Name, Loan_Application__r.Sanction_Loan_Amount__c, Loan_Application__r.EMI_Amount_Repayment_Schedule__c, Mandate_Type__c, Application_Applicant__c, Start_Date__c, End_Date__c, Periodicity__c, Application_Applicant__r.First_Name__c,
                                                    Application_Applicant__r.Middle_Name__c, Application_Applicant__r.Last_Name__c, Application_Applicant__r.Mobile_Number__c, Application_Applicant__r.Email__c,
                                                    Bank_Details__r.Account_Number__c, Application_Applicant__r.Customer_Type__c, Bank_Details__r.Bank_Master__r.Bank_Code__c, Application_Applicant__r.PAN_Number__c, Bank_Details__r.Account_Holder_Name__c FROM Instrument_Mandate__c WHERE
                                                    Id= :mandateId];
            if (mandates.isEmpty()) {
                throw new AuraHandledException('No Mandate found');
            }
            handleAfterInsert(mandates);
            return 'SUCCESS';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static void handleAfterInsert(List<Instrument_Mandate__c> mandates) {
        List<Integration_Details__c> integrationDetailsList = new List<Integration_Details__c>();
        List<Communication__e> communicationEvents = new List<Communication__e>();
        Set<Id> loanIds = new Set<Id>();
        Set<Id> mandateIds = new Set<Id>();
        
        for(Instrument_Mandate__c mandate : mandates){
            mandateIds.add(mandate.Id);
            loanIds.add(mandate.Loan_Application__c);
        }
        
        List<Instrument_Mandate__c> imList = [SELECT Id, Loan_Application__c, Loan_Application__r.Name, Loan_Application__r.Sanction_Loan_Amount__c, Loan_Application__r.EMI_Amount_Repayment_Schedule__c, Mandate_Type__c, Application_Applicant__c, Start_Date__c, End_Date__c, Periodicity__c, Application_Applicant__r.First_Name__c,
                                              Application_Applicant__r.Middle_Name__c, Application_Applicant__r.Last_Name__c, Application_Applicant__r.Mobile_Number__c, Application_Applicant__r.Email__c,
                                              Bank_Details__r.Account_Number__c, Application_Applicant__r.Customer_Type__c, Bank_Details__r.Bank_Master__r.Bank_Code__c, Application_Applicant__r.PAN_Number__c, Bank_Details__r.Account_Holder_Name__c FROM Instrument_Mandate__c WHERE
                                              Id IN :mandateIds];
        
        List<Loan_Transaction__c> loanTransactionList = [
            SELECT Id, Loan_Application__c, Yearly_Selection__c, Half_Yearly_Selection__c, Quarterly_Selection__c, 
            Interest_Frequency__c, Next_First_Payment_Date__c, Interest_Due_date__c 
            FROM Loan_Transaction__c 
            WHERE Loan_Application__c IN :loanIds AND Interest_Frequency__c != NULL
        ];
        
        Map<Id, Loan_Transaction__c> loanTransactionMap = new Map<Id, Loan_Transaction__c>();
        for(Loan_Transaction__c lt : loanTransactionList){
            loanTransactionMap.put(lt.Loan_Application__c, lt);
        }
        
        List<product2> productList= [SELECT Id, name, Description, Loan_Application__c, Product__r.name FROM product2 WHERE  Loan_Application__c In :loanIds AND RecordType.name = 'Variant'];
        List<product2> mainProduct= [SELECT Id, name,Loan_Application__c FROM product2 WHERE Loan_Application__c In :loanIds AND RecordType.name = 'Product'];
        Map<String, String> productNameMap= new Map<String, String>();
        Map<String, String> subproductNameMap= new Map<String, String>();
        //for(product2 prod: productList){
        //    productNameMap.put(prod.Loan_Application__c, prod.Name);
        //}
        for(product2 prod: mainProduct){
            productNameMap.put(prod.Loan_Application__c, prod.Name);
        }
        for(product2 prod: productList){
            subproductNameMap.put(prod.Loan_Application__c, prod.Product__r.name);
        }
        Map<String, Communication_Event_Product_Mapping__mdt> productMetaMapping = Communication_Event_Product_Mapping__mdt.getAll();
        Map<String, Communication_Event_Product_Mapping__mdt> productMapping= new Map<String, Communication_Event_Product_Mapping__mdt>();
        for (Communication_Event_Product_Mapping__mdt metadata : productMetaMapping.values()){
            productMapping.put(metadata.Product_Name__c, metadata);
        }
        
        
        for (Instrument_Mandate__c mandate : imList) {
            
            System.debug('Mandate Type ' + mandate.Mandate_Type__c);
            if(mandate.Mandate_Type__c == 'Repayment Mandate'){
                String loanApplicationId = mandate.Loan_Application__c;
                String loanApplicationName = mandate.Loan_Application__r.Name;
                String SanctionAmount = String.valueOf(mandate.Loan_Application__r.Sanction_Loan_Amount__c);
                System.debug('loanApplicationName' + loanApplicationName);
                String mandateType = mandate.Mandate_Type__c;
                DateTime startDt = mandate.Start_Date__c;
                DateTime endDt = mandate.End_Date__c;
                String periodicity = mandate.Periodicity__c;
                
                Loan_Transaction__c loanTransaction = loanTransactionMap.get(loanApplicationId);
                
                if (loanTransaction != null) {
                    String frequencyCode = (loanTransaction.Interest_Frequency__c != null)
                        ? loanTransaction.Interest_Frequency__c
                        : 'M';
                    
                    String dueDateCode = (loanTransaction.Interest_Due_date__c != null)
                        ? loanTransaction.Interest_Due_date__c
                        : '0003';
                    
                    String mmCode = '00';
                    
                    if (frequencyCode == 'Y') {
                        mmCode = (loanTransaction.Yearly_Selection__c != null)
                            ? loanTransaction.Yearly_Selection__c
                            : '01';
                    } else if (frequencyCode == 'H') {
                        mmCode = (loanTransaction.Half_Yearly_Selection__c != null)
                            ? loanTransaction.Half_Yearly_Selection__c
                            : '01';
                    } else if (frequencyCode == 'Q') {
                        mmCode = (loanTransaction.Quarterly_Selection__c != null)
                            ? loanTransaction.Quarterly_Selection__c
                            : '01';
                    }
                    
                    System.debug('frequencyCode' + frequencyCode);
                    System.debug('mmCode' + mmCode);
                    System.debug('dueDateCode' + dueDateCode);
                    
                    String finalFrequencyCode = frequencyCode + mmCode + dueDateCode;
                    
                    List<CommunicationEventWrapper.EnachWrapper> wrappers = new List<CommunicationEventWrapper.EnachWrapper>();
                    
                    CommunicationEventWrapper.EnachWrapper wrapper = new CommunicationEventWrapper.EnachWrapper();
                    wrapper.finassetvalue = SanctionAmount;
                    wrapper.finreference   = loanApplicationName != null ? loanApplicationName : '';
                    wrapper.enach          = 1;
                    wrapper.lastmnton      = System.now().format('yyyy-MM-dd\'T\'HH:mm:ss');
                    wrapper.custid         = '';
                    wrapper.nextrolecode   = '';
                    wrapper.custfname      = mandate.Application_Applicant__r.First_Name__c != null ? mandate.Application_Applicant__r.First_Name__c : '';
                    wrapper.custmname      = mandate.Application_Applicant__r.Middle_Name__c != null ? mandate.Application_Applicant__r.Middle_Name__c : '';
                    wrapper.custlname      = mandate.Application_Applicant__r.Last_Name__c != null ? mandate.Application_Applicant__r.Last_Name__c : '';
                    wrapper.phonenumber    = mandate.Application_Applicant__r.Mobile_Number__c	 != null ? mandate.Application_Applicant__r.Mobile_Number__c : '';
                    wrapper.custemail      = mandate.Application_Applicant__r.Email__c != null ? mandate.Application_Applicant__r.Email__c : '';
                    wrapper.startdate  = startDt != null ? startDt.format('yyyy-MM-dd\'T\'HH:mm:ss') : '';
                    wrapper.expirydate = endDt != null ? endDt.format('yyyy-MM-dd\'T\'HH:mm:ss') : '';
                    wrapper.accnumber      = mandate.Bank_Details__r.Account_Number__c != null ? mandate.Bank_Details__r.Account_Number__c : '';
                    wrapper.currentdatetime = System.now().format('yyyy-MM-dd\'T\'HH:mm:ss');
                    wrapper.repaypftfrq    = finalFrequencyCode != null ? finalFrequencyCode : '';
                    wrapper.repayfrq       = finalFrequencyCode != null ? finalFrequencyCode : '';
                    if (mandate.Loan_Application__r.EMI_Amount_Repayment_Schedule__c != null) {
                        wrapper.firstrepay = mandate.Loan_Application__r.EMI_Amount_Repayment_Schedule__c;
                    }
                    String rawBankCode = String.valueOf(mandate.Bank_Details__r.Bank_Master__r.Bank_Code__c);
                    
                    if (mandate.Bank_Details__r.Bank_Master__r.Bank_Code__c != null) {
                        Integer codeLength = rawBankCode.length();
                        if (codeLength == 1) {
                            wrapper.bankcode = '00' + rawBankCode;
                        } else if (codeLength == 2) {
                            wrapper.bankcode = '0' + rawBankCode;
                        } else {
                            wrapper.bankcode = rawBankCode;
                        }
                    } else {
                        wrapper.bankcode = '';
                    }
                    wrapper.periodicity    = finalFrequencyCode != null ? finalFrequencyCode : '';
                    wrapper.custcrcpr      = mandate.Application_Applicant__r.PAN_Number__c != null ? mandate.Application_Applicant__r.PAN_Number__c : '';
                    wrapper.custshrtname   = '';
                    if (mandate.Application_Applicant__r.Customer_Type__c == 'Individual') {
                        wrapper.custctgcode = 'RETAIL';
                    } else if (mandate.Application_Applicant__r.Customer_Type__c == 'Non-Individual') {
                        wrapper.custctgcode = 'CORPORATE';
                    }
                    //wrapper.accholdername  = mandate.Bank_Details__r.Account_Holder_Name__c != null ? mandate.Bank_Details__r.Account_Holder_Name__c : '';
                    //Armnn replacing all the special chars before enach hits
                    wrapper.accholdername = mandate.Bank_Details__r.Account_Holder_Name__c !=null ? mandate.Bank_Details__r.Account_Holder_Name__c.replaceAll('[^A-Za-z ]', '') : '';
                    
                    System.debug('Start Date' + wrapper.startdate);
                    System.debug('End Date' + wrapper.expirydate);
                    System.debug('currentdatetime' + wrapper.currentdatetime);
                    System.debug('phonenumber' + wrapper.phonenumber);
                    System.debug('custemail' + wrapper.custemail);
                    System.debug('custctgcode' + wrapper.custctgcode);
                    System.debug('firstrepay' + wrapper.firstrepay);
                    System.debug('custid' + wrapper.custid);
                    System.debug('repaypftfrq' + wrapper.repaypftfrq);
                    System.debug('Bank Code' + wrapper.bankcode);
                    
                    wrappers.add(wrapper);
                    
                    String serializedWrapperList = JSON.serialize(wrappers);
                    
                    Integration_Details__c integration = new Integration_Details__c();
                    integration.Name = 'Communication ENACH Event';
                    integration.Loan_Application__c = loanApplicationId;
                    integration.Endpoint__c = 'ENACH';
                    integration.Communication_Status__c = 'Published';
                    integration.Request_JSON__c = serializedWrapperList;
                    integrationDetailsList.add(integration);
                    
                    String commProduct;
                    if(productNameMap.size() > 0 && productNameMap.containsKey(loanApplicationId)) {
                        if(productNameMap.get(loanApplicationId) == 'Affordable Home Loan') {
                            commProduct = 'Affordable Housing loan';
                        }else if(productNameMap.get(loanApplicationId) == 'Affordable Non-Home Loan') {
                            commProduct = 'Affordable LAP';
                        }
                        else if(productNameMap.get(loanApplicationId) == 'Flexi Loan') {
                            commProduct = 'Flexible Loan';
                        }
                        else {
                            commProduct= productMapping.get(subproductNameMap.get(loanApplicationId)).Product_Field__c;
                        }
                    }
                    
                    Communication__e event = new Communication__e(
                        Type__c = 'ENACH',
                        Product__c = commProduct,
                        Message__c = serializedWrapperList
                    );
                    event.Record_Id__c = null;
                    communicationEvents.add(event);
                }
            }
        }
        
        if (!integrationDetailsList.isEmpty()) {
            insert integrationDetailsList;
            
            for (Integer i = 0; i < integrationDetailsList.size(); i++) {
                communicationEvents[i].Record_Id__c = integrationDetailsList[i].Id;
            }
        }
        
        System.debug('communicationEvents: ----' + communicationEvents);
        
        if (!communicationEvents.isEmpty()) {
            Database.SaveResult[] results = EventBus.publish(communicationEvents);
            System.debug('Results' + results);
        }
    }
    
    public static void handleAfterDelete(List<Instrument_Mandate__c> mandates) {
        Set<Id> parentIdsToCheck = new Set<Id>();
        
        for (Instrument_Mandate__c deletedChild : mandates) {
            if (deletedChild.Type_of_Instrument_Record__c == 'Child' && deletedChild.Instrument_Mandate__c != null) {
                parentIdsToCheck.add(deletedChild.Instrument_Mandate__c);
            }
        }
        
        if (!parentIdsToCheck.isEmpty()) {
            Map<Id, Integer> parentToChildCount = new Map<Id, Integer>();
            List<AggregateResult> results = [
                SELECT Instrument_Mandate__c parentId, COUNT(Id) childCount
                FROM Instrument_Mandate__c
                WHERE Type_of_Instrument_Record__c = 'Child'
                AND Instrument_Mandate__c IN :parentIdsToCheck
                GROUP BY Instrument_Mandate__c
            ];
            
            for (AggregateResult ar : results) {
                parentToChildCount.put((Id) ar.get('parentId'), (Integer) ar.get('childCount'));
            }
            List<Instrument_Mandate__c> parentsToDelete = new List<Instrument_Mandate__c>();
            for (Id parentId : parentIdsToCheck) {
                if (!parentToChildCount.containsKey(parentId)) {
                    parentsToDelete.add(new Instrument_Mandate__c(Id = parentId));
                }
            }
            if (!parentsToDelete.isEmpty()) {
                delete parentsToDelete;
            }
        }
    }
}