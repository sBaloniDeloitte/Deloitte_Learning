@IsTest
private class InvoiceManagementControllerTest {

    @TestSetup
    static void setupData() {

        // Get Record Types
        Id invoiceRT = Schema.SObjectType.Vendor_Invoice__c
            .getRecordTypeInfosByName().get('Invoice').getRecordTypeId();

        Id payoutRT = Schema.SObjectType.Vendor_Invoice__c
            .getRecordTypeInfosByName().get('Payout').getRecordTypeId();

        RecordType acctRT = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Account'
            AND Name = 'Customer'
            LIMIT 1
        ];
		 Trigger_Settings__c settings = new Trigger_Settings__c(
            Name = 'Trigger Settings',
            City_Master_Trigger__c = true 
        );
        insert settings;
        
        // Create City
        City_Master__c city = new City_Master__c(
            Country__c = 'IN',
            Name = 'Kachchh',
            State__c = 'GJ',
            State_Name__c = 'Gujarat'
        );
        insert city;
        
        // Create Pincode
        Pincode_Master__c pin = new Pincode_Master__c(
            Name = '400001',
            City__c = city.Id
            //State__c = 'Maharashtra'
        );
        insert pin;
        
        // Branch Account
        Account branch = new Account(
            Name = 'Test Branch',
            GST_Number__c = '22AAAAA0000A1Z5',
            Pincode__c = pin.Id
        );
        insert branch;

        // DSA Account
        Account dsa = new Account(
            Name = 'Test DSA',
            PAN_Number__c = 'ABCDE1234F',
            HSN_HAC_Code__c = '9983',
            RecordTypeId = acctRT.Id,
			GST_Number__c = '22AAAAA0000A1Z5',
    		Pincode__c = pin.Id 
        );
        insert dsa;

        // Bank
        Bank_Details__c bank = new Bank_Details__c(
            Name = 'Test Bank',
            Account_Number__c = '1234567890',
            Customer__c = dsa.Id,
            Bank_Related_To__c = 'DSA',
            Account_Holder_Name__c = 'Holder'
        );
        insert bank;

        // Address
        Customer_Address__c addr = new Customer_Address__c(
            Customer__c = dsa.Id,
            GST_Number__c = '22AAAAA0000A1Z5',
            Address_Related_To__c = 'DSA'
        );
        insert addr;

        // Invoice (CGST Path)
        Vendor_Invoice__c invoice = new Vendor_Invoice__c(
            RecordTypeId = invoiceRT,
            Name = 'INV-001',
            // Amount__c = 1000,
            Disbursed_Amount__c = 1000,
            GST_Applicable__c = 'Yes',
            GST_Type__c = 'CGST',
            CGST_Type__c = 'SGST',
            CGST__c = 50,
            SGST__c = 50,
            Customer_Name__c = 'Godrej Finance Limited',
            DSA__c = dsa.Id,
            DSA_Bank__c = bank.Id,
            DSA_Address__c = addr.Id,
            Branch_Master__c = branch.Id,
            Status__c = 'Invoice Approved'
        );
        insert invoice;

        // Payout
        Vendor_Invoice__c payout = new Vendor_Invoice__c(
            RecordTypeId = payoutRT,
            Name = 'PAY-001',
            Invoice__c = invoice.Id,
            Loan_No__c = 'LN001',
            Disbursed_Amount__c = 1000,
            Amount__c = 100,
            CustomerName__c = 'Customer A',
            Branch_Master__c = branch.Id
        );
        insert payout;

        // Document Master (needed for doc methods)
        Document_Master__c docMaster = new Document_Master__c(
            Requirement_At__c = 'Application Level',
            Document_Name__c = 'AadharCard',
            Document_Category__c = 'Agreement',
            Is_Active__c = true,
            Is_Required__c = true,
            Name = 'AadharCard'
        );
        insert docMaster;
    }

    // ================= CONSTRUCTOR =================
    /* @IsTest
    static void testConstructor_CGST() {

        Vendor_Invoice__c inv = [SELECT Id FROM Vendor_Invoice__c LIMIT 1];

        Test.setCurrentPage(Page.InvoicePage);
        ApexPages.currentPage().getParameters().put('Id', inv.Id);

        Test.startTest();
        InvoiceManagementController ctrl =
            new InvoiceManagementController(
                new ApexPages.StandardController(inv)
            );
        Test.stopTest();

        System.assertEquals(true, ctrl.showTax);
        System.assertEquals(true, ctrl.showCGST);
    }

    @IsTest
    static void testConstructor_IGST() {

        Vendor_Invoice__c inv =
            [SELECT Id FROM Vendor_Invoice__c LIMIT 1];

        inv.GST_Type__c = 'IGST';
        inv.IGST__c = 200;
        update inv;

        Test.setCurrentPage(Page.InvoicePage);
        ApexPages.currentPage().getParameters().put('Id', inv.Id);

        Test.startTest();
        InvoiceManagementController ctrl =
            new InvoiceManagementController(
                new ApexPages.StandardController(inv)
            );
        Test.stopTest();

        System.assertEquals(true, ctrl.showIGST);
    } */

    // ================= QUERY METHODS =================
    /* @IsTest
    static void testGetInvoiceRecords() {

        Test.startTest();
        List<InvoiceManagementController.InvoiceWrapper> result =
            InvoiceManagementController.getInvoiceRecords(
                null, null, null, null,
                'Invoice Approved',
                'TestProcess',
                'TestProfile'
            );
        Test.stopTest();

        System.assert(result != null);
    } */

    @IsTest
    static void testGetInvoiceDetails() {

        Vendor_Invoice__c inv =
            [SELECT Id,CustomerName__c FROM Vendor_Invoice__c Where CustomerName__c = 'Customer A' LIMIT 1];

        Test.startTest();
        Map<String, Object> result =
            InvoiceManagementController.getInvoiceDetails(inv.Id);
        Test.stopTest();

        System.assert(result.containsKey('invoiceDetails'));
    }

    @IsTest
    static void testGetPayoutRecsFromInvoice() {

        Vendor_Invoice__c inv =
            [SELECT Id FROM Vendor_Invoice__c LIMIT 1];

        Test.startTest();
        List<Vendor_Invoice__c> payout =
            InvoiceManagementController.getPayoutRecsFromInvoice(inv.Id);
        Test.stopTest();

        System.assert(payout.size() > 0);
    }

    // ================= SAVE FLOW =================
    @IsTest
    static void testSaveInvoiceRecord() {

        Vendor_Invoice__c payout =
            [SELECT Id, DSA__c, DSA_Bank__c, DSA_Address__c,
                    Branch_Master__c
             FROM Vendor_Invoice__c
             WHERE RecordType.Name='Payout'
             LIMIT 1];

        Map<String,String> param = new Map<String,String>{
            'customerName' => 'Godrej Finance Limited',
            'cinNumber' => 'CIN123',
            'totalAmount' => '500',
            'totalDisbursedAmount' => '500',
            'selectedGSTApplicable' => 'No',
            'selectedPayoutId' => payout.Id,
            'selectedGSTType' => '',
            'selectedCGSTType' => '',
            'dsaId' => payout.DSA__c,
            'selectedBank' => payout.DSA_Bank__c,
            'selectedAddress' => payout.DSA_Address__c,
            'branchMaster' => payout.Branch_Master__c,
            'selectedInvoiceType' => 'Generate Invoice',
            'hsnhacCode' => '9983',
            'supplierLogoUploaded' => 'false',
            'existingInvNo' => ''    
        };

        Test.startTest();
        List<String> result =
            InvoiceManagementController.saveInvoiceRecord(
                JSON.serialize(param),
                'Partner Community User',
                'Generate Invoice'
            );
        Test.stopTest();

        System.assert(result.size() > 0);
    }

    // ================= UPDATE FLOW =================
    @IsTest
    static void testUpdateInvoiceRecords() {

        Vendor_Invoice__c inv =
            [SELECT Id, Remarks__c FROM Vendor_Invoice__c LIMIT 1];

        inv.Remarks__c = 'Test';
        update inv;
		
        Test.startTest();
        List<String> result =
            InvoiceManagementController.updateInvoiceRecords(
                JSON.serialize(new List<Vendor_Invoice__c>{inv}),
                'GC Finance Team',
                'Approve'
            );
        Test.stopTest();

        System.assert(result.size() > 0);
    }

    // ================= UTILITY METHODS =================
    @IsTest
    static void testValidateInvoiceNumber() {

        Vendor_Invoice__c inv =
            [SELECT Id, Name FROM Vendor_Invoice__c LIMIT 1];

        Boolean exists =
            InvoiceManagementController.validateInvoiceNumber(
                inv.Id, inv.Name
            );
		InvoiceManagementController.getBranchDetails(inv.Id);
        System.assertEquals(false, exists);
    }

    //@IsTest
    //static void testGetAgencyDetails() {
        /*Account acc =
            InvoiceManagementController.getAgencyDetails();
        System.assert(acc != null);*/
    //}

    @IsTest
    static void testGetAddressAndBank() {

        Map<String,String> addMap =
            InvoiceManagementController.getAddressToShow();

        Map<String,String> bankMap =
            InvoiceManagementController.getBanksToShow();

        System.assert(addMap != null);
        System.assert(bankMap != null);
    }

    @IsTest
    static void testBuildFilterQuery() {

        Map<String,Object> bindVars = new Map<String,Object>();

        String q =
            InvoiceManagementController.buildFilterQuery(
                '2024-01-01', '2024-01-31', null, null,
                null, 'Completed Records', 'GC Finance Team',
                bindVars
            );

        System.assert(q.contains('Order By'));
    }
    
    @IsTest
    static void testgetInvoice(){
       Vendor_Invoice__c inv = [SELECT Id FROM Vendor_Invoice__c LIMIT 1];

        ContentVersion cv = new ContentVersion(
                Title = 'MergedDocument',
                PathOnClient = 'MergedDocument.pdf',
                VersionData = Blob.valueOf('Test Content')
            );
            insert cv;
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
            Document_Details__c docDetailO = new Document_Details__c(
                Name = 'PAN',
                //Content_Document_Id__c = contentDocId,
               // Document_Type__c = 'PAN',
                Esign_Document__c = false,
             	EntityReferenceId__c = '123456',
                EntityReferenceName__c = 'Vendor_Invoice__c',
             	Active__c = true,
             	// Process_Name__c = 'Invoice Creation',
                Description__c = 'Desc'
            );
            insert docDetailo;
        
        Document_Details__c docDetail = new Document_Details__c(
                Name = 'PAN',
                //Content_Document_Id__c = contentDocId,
               // Document_Type__c = 'PAN',
                Esign_Document__c = false,
             	EntityReferenceId__c = docDetailO.Id,
                EntityReferenceName__c = 'Vendor_Invoice__c',
             	Active__c = true,
             	// Process_Name__c = 'Invoice Creation',
            	Description__c = 'Desc'
            );
            insert docDetail;
        City_Master__c city = new City_Master__c(Name = 'Gudivada',Country__c='IN',State__c='GJ',State_Name__c ='Gujarat');
        insert city;
        Pincode_Master__c pinCode = new Pincode_Master__c(City__c = city.Id, Name='521301');
        insert pinCode;
        Account acc =  new Account(
        Name = 'HL Test Branch',
        Pincode__c = pinCode.Id
        );
        insert acc;
        

		InvoiceManagementController.getInvoice(docDetailo.Id,'PAN',contentDocId);
        //InvoiceManagementController.reGenerateInvoiceFile(inv.Id,'Invoice New');
        inv.Branch_Master__c = acc.Id;
        update inv;
        InvoiceManagementController.getPayoutRecMaster(inv.Id);
        InvoiceManagementController.deleteInvoiceRecord(inv.Id,'Partner Community User','Delete Invoice');
        InvoiceManagementController.getContentVersionIds(docDetail.Id + ',');
    }
    
    @IsTest
    static void testGetAddressDetails_fullPath() {
    
        Account dsa = [
            SELECT Id
            FROM Account
            WHERE RecordType.Name = 'Customer'
            LIMIT 1
        ];
    
        // Create a City + Pincode so relationship fields are available
        City_Master__c city = new City_Master__c(
            Country__c = 'IN',
            Name = 'TestCity',
            State__c = 'GJ',       
            State_Name__c = 'Gujarat'
        );
        insert city;
    
        Pincode_Master__c pin = new Pincode_Master__c(
            Name = '400002',
            City__c = city.Id
        );
        insert pin;
    
        Customer_Address__c addr = new Customer_Address__c(
            Customer__c = dsa.Id,
            GST_Number__c = '22AAAAA0000A1Z5',
            State_Code__c = 'GJ',
            Place_of_Supply_State__c = 'GJ',
            Pincode__c = pin.Id,
            Address_Related_To__c = 'DSA'
        );
        insert addr;
    
        Test.startTest();
        Customer_Address__c result = InvoiceManagementController.getAddressDetails(addr.Id);
        Test.stopTest();
    
        System.assertEquals('GJ', result.State_Code__c);
        System.assertEquals('GJ', result.Place_of_Supply_State__c);
        System.assertEquals('24', result.Pincode__r.City__r.State_Code__c); // Match your schema
    }
    
    @IsTest
    static void testGetAgencyDetails_internalUser_throws() {
        // Run as current (internal) test user
        Boolean thrown = false;
        try {
            Test.startTest();
            InvoiceManagementController.getAgencyDetails();
            Test.stopTest();
        } catch (QueryException qe) {
            thrown = true;
        }
        System.assert(thrown, 'Expected QueryException for internal user without AccountId');
    }
    
    @IsTest
    static void testSaveInvoiceRecord_triggersDelink_and_DeleteDocument_fixed() {
        // 1) Get the invoice (from your @TestSetup)
        Vendor_Invoice__c inv = [
            SELECT Id, DSA__c, DSA_Bank__c, DSA_Address__c, Branch_Master__c
            FROM Vendor_Invoice__c
            WHERE RecordType.Name = 'Invoice'
            LIMIT 1
        ];
    
        // 2) Get the currently linked payout (from @TestSetup)
        Vendor_Invoice__c linkedPayout = [
            SELECT Id, Invoice__c
            FROM Vendor_Invoice__c
            WHERE RecordType.Name = 'Payout' AND Invoice__c = :inv.Id
            LIMIT 1
        ];
        System.assertNotEquals(null, linkedPayout.Invoice__c, 'Expect at least one payout already linked to invoice');
    
        // 3) Create a NEW payout that we will select in the update (valid Id, not linked yet)
        Id payoutRT = Schema.SObjectType.Vendor_Invoice__c
            .getRecordTypeInfosByName().get('Payout').getRecordTypeId();
    
        // Minimal fields; mirror what your org requires for Payout
        Vendor_Invoice__c newPayout = new Vendor_Invoice__c(
            RecordTypeId         = payoutRT,
            Name                 = 'PAY-NEW',
            Loan_No__c           = 'LN-NEW-001',
            Disbursed_Amount__c  = 1000,
            Amount__c            = 100,
            CustomerName__c      = 'Customer B',
            Branch_Master__c     = inv.Branch_Master__c
            // leave Invoice__c = null (unlinked initially)
        );
        insert newPayout;
    
        // 4) Pre-set an old existing invoice number on the invoice (so oldExistingInvNo is non-blank)
        inv.Existing_Invoice_No__c = 'INV-EXIST-123';
        update inv;
    
        // 5) Seed a Document_Details__c that deleteDocument() should deactivate
        //    Must match Name pattern 'Inv_<InvoiceId>' and be Active__c = true
        Document_Details__c existingInvDoc = new Document_Details__c(
            Name                   = 'Inv_' + inv.Id,
            EntityReferenceId__c   = inv.Id,
            EntityReferenceName__c = 'Vendor_Invoice__c',
            Active__c              = true
            // Process_Name__c        = 'Invoice Creation'
        );
        insert existingInvDoc;
    
        // (Optional) Pick a Metadata row that has both Next & Previous status populated
        // If your org already uses 'Partner Community User' + 'Update Invoice', you can hardcode those.
        List<Vendor_Invoice_Action_Master__mdt> mdList = [
            SELECT Profile__c, Action__c
            FROM Vendor_Invoice_Action_Master__mdt
            WHERE Next_Status__c != '' AND Previous_Status__c != ''
            LIMIT 1
        ];
        String testProfile = mdList.isEmpty() ? 'Partner Community User' : mdList[0].Profile__c;
        String testAction  = mdList.isEmpty() ? 'Update Invoice'        : mdList[0].Action__c;
    
        // 6) Build UPDATE params:
        //    - recordId = inv.Id (to take update path and load existingPayoutMap)
        //    - selectedPayoutId = newPayout.Id (VALID ID; NO trailing comma)
        //    - existingInvNo = '' (blank now) → triggers deleteDocument (since oldExistingInvNo was set above)
        Map<String, String> param = new Map<String, String>{
            'recordId'               => inv.Id,
            'customerName'           => 'Godrej Finance Limited',
            'cinNumber'              => 'CIN123',
            'totalAmount'            => '1000',
            'totalDisbursedAmount'   => '1000',
            'selectedGSTApplicable'  => 'No',
            'selectedPayoutId'       => newPayout.Id,   // ✅ VALID ID; no empty string, no trailing comma
            'selectedGSTType'        => '',
            'selectedCGSTType'       => '',
            'dsaId'                  => inv.DSA__c,
            'selectedBank'           => inv.DSA_Bank__c,
            'selectedAddress'        => inv.DSA_Address__c,
            'branchMaster'           => inv.Branch_Master__c,
            'selectedInvoiceType'    => 'Generate Invoice',
            'hsnhacCode'             => '9983',
            'supplierLogoUploaded'   => 'false',
            'existingInvNo'          => ''               // <-- blank now (UI removed existing invoice no)
            // Don't send 'invoiceFileId' or 'supLogoFileId' so delete paths can run
        };
    
        // 7) Invoke saveInvoiceRecord
        Test.startTest();
        List<String> res = InvoiceManagementController.saveInvoiceRecord(
            JSON.serialize(param),
            testProfile,
            testAction
        );
        Test.stopTest();
    
        // 8) Assert controller returned Success
        System.assertNotEquals(null, res, 'Expected a non-null result');
        System.assert(!res.isEmpty(), 'Expected a non-empty result');
        System.assertEquals('Success', res[0], 'Expected Success from saveInvoiceRecord');
    
        // 9) Assert the previously linked payout is now DELINKED
        linkedPayout = [
            SELECT Id, Invoice__c, Status__c
            FROM Vendor_Invoice__c
            WHERE Id = :linkedPayout.Id
            LIMIT 1
        ];
        System.assertEquals(null, linkedPayout.Invoice__c, 'Old payout should be delinked (not in selected list)');
    
        // 10) Assert the NEW payout is now linked to the invoice
        newPayout = [
            SELECT Id, Invoice__c
            FROM Vendor_Invoice__c
            WHERE Id = :newPayout.Id
            LIMIT 1
        ];
        System.assertEquals(inv.Id, newPayout.Invoice__c, 'New payout should be linked to the invoice');
    
        // 11) Assert the document was deactivated by deleteDocument()
        existingInvDoc = [
            SELECT Id, Active__c
            FROM Document_Details__c
            WHERE Id = :existingInvDoc.Id
            LIMIT 1
        ];
        System.assertEquals(false, existingInvDoc.Active__c,
            'Expected Inv_<InvoiceId> doc to be deactivated by deleteDocument');
    }


}