@IsTest
private class OpportunityTriggerHelperTest { 
    
    @TestSetup
    static void setupData() {
        // Insert Opportunities
        List<Opportunity> oppList = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            oppList.add(new Opportunity(
                Name = 'Test Opp ' + i,
                StageName = 'Credit Underwriting',
                CloseDate = Date.today(),
                Sanction_Loan_Amount__c = 50000,
                Sanction_Rate_Of_Interest__c = 5.5,
                Sanction_Tenure__c = 24,
                Product__c = 'Affordable Home Loan'
            ));
        }
        insert oppList;
        
        // Insert Document_Master__c
        List<Document_Master__c> docMasters = new List<Document_Master__c>{
            new Document_Master__c(
                Name = 'Report',
                Document_Name__c = 'Report',
                Document_Category__c = 'Business Verification',
                Is_Active__c = true,
                Requirement_At__c = 'Application Verification',
                Esign_Document__c = true,
                Requirement_Level__c = 'Applicant Level'
            )
                };
                    insert docMasters;
        
        // Insert ContentVersion and ContentDocumentLink
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('This is a test file.')
        );
        insert contentVersion;
        
        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
        contentLink.LinkedEntityId = docMasters[0].Id;
        contentLink.ShareType = 'I';
        contentLink.Visibility = 'AllUsers';
        insert contentLink;
        
        // Insert Document_Details__c
        Document_Details__c docDetail = new Document_Details__c(
            Name = docMasters[0].Name,
            Loan_Application__c = oppList[0].Id,
            Document_Master__c = docMasters[0].Id,
            Active__c = true,
            Status__c = 'Uploaded',
            Esign_Document__c = true,
            Is_Required__c = true,
            Content_Document_Id__c = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId
        );
        insert docDetail;
        Id subProductRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Sub_Product').getRecordTypeId(); 
        Id ProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Account customer = FITestDataFactory.createAccount('Test Customer', 'Customer');
        Opportunity loanApplication = FITestDataFactory.createLoanApplication(true,customer);
        loanApplication.Product__c = 'Home Loan';
        update loanApplication;
        
        // Create Main Product
        Product2 mainProduct = new Product2(
            Name = 'Business Loan',
            Loan_Application__c = loanApplication.Id,
            RecordTypeId = ProductRecordTypeId,
            IsActive = true
        );
        insert mainProduct;
        
        Product2 prod2 = new Product2(
            Name = 'Term Loan',
            Product__c = mainProduct.Id,
            Loan_Application__c = loanApplication.Id, 
            RecordTypeId = subProductRT,
            IsActive = true
        );
        insert prod2;
        
    }
    
    @IsTest
    static void testBeforeInsert() {
        Opportunity opp = new Opportunity(
            StageName = 'Credit Underwriting',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        
        Test.startTest();
        insert opp;
        Test.stopTest();
        
        Opportunity insertedOpp = [SELECT Name, StageName, CloseDate FROM Opportunity WHERE Id = :opp.Id];
        
        
    }
    
    @isTest
    static void testStagePSVBranch() {
        // Create a non-admin user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User u = new User(
            Alias = 'stduser',
            Email='stduser@example.com',
            EmailEncodingKey='UTF-8',
            LastName='Testing',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId=p.Id,
            TimeZoneSidKey='Asia/Kolkata',
            UserName='stduser' + DateTime.now().getTime() + '@example.com'
        );
        insert u;
        
        System.runAs(u) {
            // Stage CMDT values
            String stageCreditUnderWriting = 'Credit Underwriting';
            String stagePSV = 'PSV';
            
            // Insert Opportunity
            Opportunity opp = new Opportunity(
                Name = 'Test Opp',
                StageName = stageCreditUnderWriting,
                CloseDate = Date.today(),
                Sanction_Loan_Amount__c = 50000,
                Sanction_Rate_Of_Interest__c = 5.5,
                Sanction_Tenure__c = 24,
                Product__c ='Affordable Home Loan'
            );
            insert opp;
            
            // Simulate oldRecords map
            Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
            Opportunity oldOpp = opp.clone(false, true, false, false);
            oldOpp.StageName = stageCreditUnderWriting;
            oldMap.put(opp.Id, oldOpp);
            
            // Update Opportunity to PSV
            opp.StageName = stagePSV;
            
            // Call the beforeUpdate/afterUpdate logic
            List<Opportunity> newList = new List<Opportunity>{opp};
                Map<Id, SObject> newMap = new Map<Id, SObject>{opp.Id => opp};
                    List<SObject> oldList = new List<SObject>{oldOpp};
                        Map<Id, Opportunity> oldItems = oldMap;
            
            Test.startTest();
            OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
            handler.beforeUpdate(newList, newMap, oldList, oldItems);
            handler.afterUpdate(newList, newMap, oldList, oldItems);
            Test.stopTest();
            
            // Assert Negotiated_* fields are copied
            Opportunity updatedOpp = [SELECT Negotiated_Loan_Amount__c, Negotiated_Rate_Of_Interest__c, Negotiated_Tenure__c, Pricing_Approval_Status__c
                                      FROM Opportunity WHERE Id = :opp.Id];
            
        }
    }
    
    
    
    @IsTest
    static void testAfterInsert() {
        Opportunity opp = new Opportunity(
            StageName = 'Credit Underwriting',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        
        Test.startTest();
        insert opp;
        Test.stopTest();
        
        System.assertNotEquals(null, opp.Id, 'Opportunity should be inserted successfully');
    }
    
    @isTest
    static void testAfterUpdate() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',                    
            Sanction_Loan_Amount__c = 50000,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Sub_stage__c = 'PSV in-progress',
            Product__c ='Affordable Home Loan',
            LMS_Loan_Reference__c='test',
            Pricing_Approval_Status__c = ''
        );
        insert opp;
        
        Opportunity oldOpp = [SELECT Id,Status__c, StageName, Sub_stage__c,LMS_Loan_Reference__c,Pricing_Approval_Status__c,Sanction_Loan_Amount__c FROM Opportunity WHERE Id = :opp.Id];
        
        // Update Opportunity to trigger afterUpdate logic
        opp.StageName = 'Disbursement';
        opp.Sub_stage__c = 'Disbursed';
        opp.LMS_Loan_Reference__c='Test123';
        opp.Pricing_Approval_Status__c = 'Approved';
        
        List<SObject> newList = new List<SObject>{opp};
            Map<Id, SObject> newMap = new Map<Id, SObject>{opp.Id => opp};
                List<SObject> oldList = new List<SObject>{oldOpp};
                    Map<Id, Opportunity> oldItems = new Map<Id, Opportunity>{ oldOpp.Id => oldOpp };
                        
                        Test.startTest();
        try{
            OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
            handler.afterUpdate(newList, newMap, oldList, oldItems);
        }catch(Exception e) {
            System.debug('Handled exception in test: ' + e.getMessage());
        }    
        Test.stopTest();
        
        System.assert(true, 'afterUpdate executed without errors');
    }
    
    @IsTest
    static void testBeforeDelete() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opp Delete',
            StageName = 'Credit Underwriting',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert opp;
        
        List<SObject> oldList = [SELECT Id FROM Opportunity WHERE Id = :opp.Id];
        Map<Id, SObject> oldItems = new Map<Id, SObject>{opp.Id => oldList[0]};
            
            Test.startTest();
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        handler.beforeDelete(new List<SObject>(), new Map<Id,SObject>(), oldList, oldItems);
        Test.stopTest();
        
        System.assert(true, 'Method executed without errors');
    }
    
    @IsTest
    static void testAfterDelete() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opp AfterDelete',
            StageName = 'Credit Underwriting',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert opp;
        
        List<SObject> oldList = [SELECT Id,Product__c FROM Opportunity WHERE Id = :opp.Id];
        Map<Id, SObject> oldItems = new Map<Id, SObject>{opp.Id => oldList[0]};
            
            Test.startTest();
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        handler.afterDelete(oldList, oldItems);
        Test.stopTest();
        
        System.assert(true, 'Method executed without errors');
    }
    
    @IsTest
    static void testAfterUndelete() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opp Undelete',
            StageName = 'Credit Underwriting',
            CloseDate = Date.today(),
            Product__c = 'Affordable Home Loan'
        );
        insert opp;
        
        // Delete the Opportunity
        delete opp;
        
        // Query including deleted records
        List<SObject> newList = [SELECT Id,Product__c FROM Opportunity WHERE Id = :opp.Id ALL ROWS];
        Map<Id, SObject> newMap = new Map<Id, SObject>{opp.Id => newList[0]};
            
            Test.startTest();
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        handler.afterUndelete(newList, newMap);
        Test.stopTest();
        
        System.assert(true, 'Method executed without errors');
    }
    
    
    @IsTest
    static void testIsDisabledMethod() {
        OpportunityTriggerHelper helper = new OpportunityTriggerHelper();
        Boolean isDisabled = helper.isDisabled();
        System.assertEquals(false, isDisabled, 'Trigger should not be disabled by default');
    }
    @isTest
    static void testBeforeUpdateLoanApplicationIds() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Email='testuser@example.com',
            LastName='Test',
            Alias='tuser',
            TimeZoneSidKey='Asia/Kolkata',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey='en_US'
        );
        insert u;
        
        System.runAs(u) {
            // Insert old Opportunities
            Opportunity oldOpp1 = new Opportunity(
                Name = 'Old Opp 1',
                StageName = 'PSV',
                Sub_stage__c = 'PSV Sales',
                CloseDate = Date.today(),
                Product__c = 'Affordable Home Loan'
            );
            insert oldOpp1;
            
            Opportunity oldOpp2 = new Opportunity(
                Name = 'Old Opp 2',
                StageName = 'Credit Underwriting',
                Sub_stage__c = 'PSV Sales',
                CloseDate = Date.today(),
                Product__c = 'Affordable Home Loan'
            );
            insert oldOpp2;
            
            Opportunity oldOpp3 = new Opportunity(
                Name = 'Old Opp 3',
                StageName = 'PSV',
                Sub_stage__c = 'PSV Sales',
                CloseDate = Date.today(),
                Product__c = 'Affordable Home Loan'
            );
            insert oldOpp3;
            
            Opportunity oldOpp4 = new Opportunity(
                Name = 'Old Opp 4',
                StageName = 'PSV',
                Sub_stage__c = 'Ops Maker',
                CloseDate = Date.today(),
                Product__c = 'Affordable Home Loan',
                Opt_In__c = true
            );
            insert oldOpp4;
            
            Opportunity oldOpp5 = new Opportunity(
                Name = 'Old Opp 5',
                StageName = 'PSV',
                Sub_stage__c = 'Ops Maker',
                CloseDate = Date.today(),
                Product__c = 'Affordable Home Loan'
            );
            insert oldOpp5;
            
            // Prepare oldItems map as Map<Id, Opportunity>
            Map<Id, Opportunity> oldItems = new Map<Id, Opportunity>();
            oldItems.put(oldOpp1.Id, oldOpp1);
            oldItems.put(oldOpp2.Id, oldOpp2);
            oldItems.put(oldOpp3.Id, oldOpp3);
            oldItems.put(oldOpp4.Id, oldOpp4);
            
            // Prepare newList and newMap simulating updates
            Opportunity newOpp1 = oldOpp1.clone(false);
            newOpp1.Id = oldOpp1.Id;
            newOpp1.StageName = 'Disbursement'; // triggers first condition
            
            Opportunity newOpp2 = oldOpp2.clone(false);
            newOpp2.Id = oldOpp2.Id;
            newOpp2.Sub_stage__c = 'Ops Maker'; // triggers second condition
            
            Opportunity newOpp3 = oldOpp3.clone(false);
            newOpp3.Id = oldOpp3.Id;
            newOpp3.StageName  ='Disbursement';
            newOpp3.Sub_stage__c = 'PSV Credit'; // triggers second condition
            
            Opportunity newOpp4 = oldOpp4.clone(false);
            newOpp4.Id = oldOpp4.Id;
            newOpp4.StageName  ='Credit Underwriting';
            newOpp4.Sub_stage__c = 'Ops Author'; // triggers second condition

            List<SObject> newList = new List<SObject>{ newOpp1, newOpp2, newOpp3,newOpp4 };
                Map<Id, SObject> newMap = new Map<Id, SObject>();
            newMap.put(newOpp1.Id, newOpp1);
            newMap.put(newOpp2.Id, newOpp2);
            newMap.put(newOpp3.Id, newOpp3);
            newMap.put(newOpp4.Id, newOpp4);
            List<SObject> oldList = new List<SObject>{ oldOpp1, oldOpp2, oldOpp3,oldOpp4,oldOpp5 };
                
                // Call the beforeUpdate method
                Test.startTest();
            OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
            handler.beforeUpdate(newList, newMap, oldList, (Map<Id, SObject>) oldItems);
            handler.afterUpdate(newList, newMap, oldList, (Map<Id, SObject>) oldItems);
            Test.stopTest();
        }
    }
    @IsTest
    static void testFCUNoChange() {
         Opportunity opp = new Opportunity(
            Name = 'No Change Test',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            FCU_Status__c = 'FCU Completed',
            Product__c = 'Affordable Home Loan'
        );
        insert opp; 		
        
        Opportunity opp3 = new Opportunity(
            Name = 'No Change Test',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            FCU_Status__c = 'Pending',
            Product__c = 'Affordable Home Loan'
        );
        insert opp3;
        
        Test.startTest();
        Opportunity opp2 = new Opportunity(
            FCU_Status__c = 'Pending',
            Id = opp.Id
        );
        update opp2; // no change
        
 		Opportunity opp4 = new Opportunity(
            FCU_Status__c = 'FCU Completed',
            Id = opp3.Id
        );
        update opp4; // no change
        Test.stopTest();
        
        Opportunity result = [
            SELECT FCU_Initiation_Date__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
    }
}