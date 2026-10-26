public class TechnicalEvaluationPDFController {
    
    public Technical_Evaluation__c techEval { get; set; }
    public List<Technical_Detail__c> floorDetails { get; set; }
    public Decimal totalPlanBUA { get; set; }
    public Decimal totalActualBUA { get; set; }
    public Decimal totalDocumentedArea { get; set; }
    public Decimal totalPermissibleArea { get; set; }
    public Decimal totalAdoptedArea { get; set; }
    //dimensions and boundary
    public List<Technical_Detail__c> dimensionDetails { get; set; }
    public List<Technical_Detail__c> boundaryDetails { get; set; }
    //Floor Estimation
    public List<Technical_Detail__c> floorEstimations { get; set; }
    //VALUE AS PER GOVERNMENT
    public List<GovtValueWrapper> governmentValues { get; set; }
    public Decimal totalGovernmentValue { get; set; }
    public class GovtValueWrapper {
        
        public String particulars { get; set; }
        public Decimal area { get; set; }
        public Decimal rate { get; set; }
        public Decimal calculatedValue { get; set; }
        public String valueLabel { get; set; }
        public GovtValueWrapper() {}
        public GovtValueWrapper(Technical_Detail__c rec) {
            
            this.particulars = rec.Particulars__c;
            this.area = rec.Area__c != null ? rec.Area__c : 0;
            this.rate = rec.Rate__c != null ? rec.Rate__c : 0;
            this.calculatedValue = (this.area * this.rate).setScale(2);
            
            if (rec.Particulars__c == 'Value of land  Sq. FT') {
                this.valueLabel = 'DLC Value in Rs.';
            } else {
                this.valueLabel = 'Market Value in Rs.';
            }
        }
    }
    //fairMarketValues
    public List<FairMarketValueWrapper> fairMarketValues { get; set; }
    public Decimal totalFairMarketValue { get; set; }
    
    public class FairMarketValueWrapper {
        public FairMarketValueWrapper() {}
        public String particulars { get; set; }
        public Decimal area { get; set; }
        public Decimal rate { get; set; }
        public Decimal calculatedValue { get; set; }
        public String valueLabel { get; set; }
        
        public FairMarketValueWrapper(Technical_Detail__c rec) {
            
            this.particulars = rec.Particulars__c;
            this.area = rec.Area__c != null ? rec.Area__c : 0;
            this.rate = rec.Rate__c != null ? rec.Rate__c : 0;
            this.calculatedValue = (this.area * this.rate).setScale(2);
            
            // Label logic
            if (rec.Particulars__c == 'Value of land  Sq. FT') {
                this.valueLabel = 'Market Rate';
            } else {
                this.valueLabel = 'Market Value in Rs.';
            }
        }
    }
    //postCompletionValues
    public List<FairMarketValueWrapper> postCompletionValues { get; set; }
    public Decimal totalPostCompletionValue { get; set; }
    //photograph
    public List<List<PhotoWrapper>> photoRows { get; set; }
    public class PhotoWrapper {
        public String title { get; set; }
        public String downloadUrl { get; set; }
        
        public PhotoWrapper(Document_Details__c doc, ContentVersion cv) {
            title = doc.Name;
            
            downloadUrl = '/sfc/servlet.shepherd/version/download/' +
                cv.Id;
        }
    }
    //Application_applicant__c
    public Application_applicant__c applicant { get; set; }
    
    
    
    public TechnicalEvaluationPDFController(ApexPages.StandardController stdCtrl) {
        Id recordId = stdCtrl.getId();
        techEval = [SELECT Id, Name, HL_Loan_Application__c,Date_of_Report__c FROM Technical_Evaluation__c WHERE Id = :recordId LIMIT 1];
        floorDetails = [
            SELECT Id,Floor__c,Accommodation_and_Occupancy__c,As_per_Plan_BUA_SFT__c,Actual_BUA_SFT__c,Documented_Area_SFT__c,Permissible_Area_SFT__c,Adopted_Area_for_Valuation_SFT__c
            FROM Technical_Detail__c
            WHERE Technical_Evaluation__c = :recordId and Sections__c='Property Details'
            ORDER BY Floor__c
        ];
        totalPlanBUA = 0;totalActualBUA = 0;totalDocumentedArea = 0;totalPermissibleArea = 0;totalAdoptedArea = 0;
        for (Technical_Detail__c row : floorDetails) {
            totalPlanBUA += (row.As_per_Plan_BUA_SFT__c != null) ? row.As_per_Plan_BUA_SFT__c : 0;
            totalActualBUA += (row.Actual_BUA_SFT__c != null) ? row.Actual_BUA_SFT__c : 0;
            totalDocumentedArea += (row.Documented_Area_SFT__c != null) ? row.Documented_Area_SFT__c : 0;
            totalPermissibleArea += (row.Permissible_Area_SFT__c != null) ? row.Permissible_Area_SFT__c : 0;
            totalAdoptedArea += (row.Adopted_Area_for_Valuation_SFT__c != null) ? row.Adopted_Area_for_Valuation_SFT__c : 0;
        }
        // Fetch Dimension & Boundary records
        List<Technical_Detail__c> allDetails = [
            SELECT Id,Description_Dimension_of_Property__c,North__c,East__c,West__c,South__c,Property_Details_Category__c
            FROM Technical_Detail__c
            WHERE Technical_Evaluation__c = :recordId and Sections__c='Dimension of Property (For Land & Building , Offices & Shops)'
        ];
        
        dimensionDetails = new List<Technical_Detail__c>();
        boundaryDetails = new List<Technical_Detail__c>();
        
        for (Technical_Detail__c rec : allDetails) {
            if (rec.Property_Details_Category__c == 'Dimension of Property (For Land & Building , Offices & Shops)') {
                dimensionDetails.add(rec);
            } 
            else if (rec.Property_Details_Category__c == 'Boundaries Details') {
                boundaryDetails.add(rec);
            }
        }
        /* FLOOR-WISE ESTIMATION */
        
        floorEstimations = [
            SELECT Floor__c,
            Estimation_as_per_Customer_sqft__c,
            Vetted_Estimation_Permissible_sqft__c
            FROM Technical_Detail__c
            WHERE Technical_Evaluation__c = :recordId and Sections__c='Proposed Estimate of Project'
            ORDER BY Floor__c 
        ];
        
        /* VALUE AS PER GOVERNMENT */
        
        governmentValues = new List<GovtValueWrapper>();
        totalGovernmentValue = 0;
        
        // 🔹 1. STATIC ROW (Land Value from Parent)
        Technical_Evaluation__c parentRec = [SELECT Id,Area_Government__c,Rate_Government__c,DLC_Value_in_Rs__c,Area_Fair_Market__c,Rate_Fair_Market__c,
                                             Market_Value_in_Rs_Fair_Market__c,Area_Post_Completion__c,Rate_Post_Completion__c,Market_Value_in_Rs_Post_Completion__c
                                             FROM Technical_Evaluation__c
                                             WHERE Id = :recordId LIMIT 1];
        
        if (parentRec != null) {
            GovtValueWrapper staticRow = new GovtValueWrapper();
            staticRow.particulars = 'Value of land Sq. FT';
            staticRow.area = parentRec.Area_Government__c != null ? parentRec.Area_Government__c : 0;
            staticRow.rate = parentRec.Rate_Government__c != null ? parentRec.Rate_Government__c : 0;
            staticRow.calculatedValue = parentRec.DLC_Value_in_Rs__c != null ? parentRec.DLC_Value_in_Rs__c : 0;
            staticRow.valueLabel = 'DLC Value in Rs.';
            
            governmentValues.add(staticRow);
            totalGovernmentValue += staticRow.calculatedValue;
        }
        
        // 🔹 2. DYNAMIC ROWS (From Property Details)
        List<Technical_Detail__c> govChildRecords = [
            SELECT Id, Floor__c, Area__c, Rate__c, Market_Value_in_Rs_Government__c
            FROM Technical_Detail__c
            WHERE Technical_Evaluation__c = :recordId
            AND Sections__c = 'Property Details'
            ORDER BY CreatedDate
        ];
        
        for (Technical_Detail__c rec : govChildRecords) {
            
            GovtValueWrapper wrapperRow = new GovtValueWrapper();
            wrapperRow.particulars = 'Value of Const/ Flat/ Shop/ Office on ' + rec.Floor__c + ' in Sq. Ft';
            wrapperRow.area = rec.Area__c != null ? rec.Area__c : 0;
            wrapperRow.rate = rec.Rate__c != null ? rec.Rate__c : 0;
            wrapperRow.calculatedValue = rec.Market_Value_in_Rs_Government__c != null ? rec.Market_Value_in_Rs_Government__c : 0;
            wrapperRow.valueLabel = 'Market Value in Rs.';
            
            governmentValues.add(wrapperRow);
            totalGovernmentValue += wrapperRow.calculatedValue;
        }
        
        /* PRESENT FAIR MARKET VALUE */
        
        fairMarketValues = new List<FairMarketValueWrapper>();
        totalFairMarketValue = 0;
        
        // 🔹 1. STATIC ROW (Parent)
        if (parentRec != null) {
            
            FairMarketValueWrapper staticRow = new FairMarketValueWrapper();
            staticRow.particulars = 'Value of land Sq. FT';
            staticRow.area = parentRec.Area_Fair_Market__c != null ? parentRec.Area_Fair_Market__c : 0;
            staticRow.rate = parentRec.Rate_Fair_Market__c != null ? parentRec.Rate_Fair_Market__c : 0;
            staticRow.calculatedValue = parentRec.Market_Value_in_Rs_Fair_Market__c != null ?
                parentRec.Market_Value_in_Rs_Fair_Market__c : 0;
            staticRow.valueLabel = 'Market Rate';
            
            fairMarketValues.add(staticRow);
            totalFairMarketValue += staticRow.calculatedValue;
        }
        
        // 🔹 2. DYNAMIC ROWS
        List<Technical_Detail__c> fairChildRecords = [
            SELECT Id, Floor__c, Area_Fair_Market_Value__c, Rate_Fair_Market_Value__c, Market_Value_in_Rs__c
            FROM Technical_Detail__c
            WHERE Technical_Evaluation__c = :recordId
            AND Sections__c = 'Property Details'
            ORDER BY CreatedDate
        ];
        
        for (Technical_Detail__c rec : fairChildRecords) {
            
            FairMarketValueWrapper wrapperRow = new FairMarketValueWrapper();
            wrapperRow.particulars = 'Value of Const/ Flat/ Shop/ Office on ' + rec.Floor__c + ' in Sq. Ft';
            wrapperRow.area = rec.Area_Fair_Market_Value__c != null ? rec.Area_Fair_Market_Value__c : 0;
            wrapperRow.rate = rec.Rate_Fair_Market_Value__c != null ? rec.Rate_Fair_Market_Value__c : 0;
            wrapperRow.calculatedValue = rec.Market_Value_in_Rs__c != null ? rec.Market_Value_in_Rs__c : 0;
            wrapperRow.valueLabel = 'Market Value in Rs.';
            
            fairMarketValues.add(wrapperRow);
            totalFairMarketValue += wrapperRow.calculatedValue;
        }
        
        /* POST COMPLETION FAIR MARKET VALUE */
        
        postCompletionValues = new List<FairMarketValueWrapper>();
        totalPostCompletionValue = 0;
        
        // 🔹 1. STATIC ROW
        if (parentRec != null) {
            
            FairMarketValueWrapper staticRow = new FairMarketValueWrapper();
            staticRow.particulars = 'Value of land Sq. FT';
            staticRow.area = parentRec.Area_Post_Completion__c != null ? parentRec.Area_Post_Completion__c : 0;
            staticRow.rate = parentRec.Rate_Post_Completion__c != null ? parentRec.Rate_Post_Completion__c : 0;
            staticRow.calculatedValue = parentRec.Market_Value_in_Rs_Post_Completion__c != null ?
                parentRec.Market_Value_in_Rs_Post_Completion__c : 0;
            staticRow.valueLabel = 'Market Rate';
            
            postCompletionValues.add(staticRow);
            totalPostCompletionValue += staticRow.calculatedValue;
        }
        
        // 🔹 2. DYNAMIC ROWS
        List<Technical_Detail__c> postChildRecords = [
            SELECT Id, Floor__c, Area_Post_Completion__c, Rate_Post_Completion__c, Market_Value_Post_Completion__c
            FROM Technical_Detail__c
            WHERE Technical_Evaluation__c = :recordId
            AND Sections__c = 'Property Details'
            ORDER BY CreatedDate
        ];
        
        for (Technical_Detail__c rec : postChildRecords) {
            
            FairMarketValueWrapper wrapperRow = new FairMarketValueWrapper();
            wrapperRow.particulars = 'Value of Const/ Flat/ Shop/ Office on ' + rec.Floor__c + ' in Sq. Ft';
            wrapperRow.area = rec.Area_Post_Completion__c != null ? rec.Area_Post_Completion__c : 0;
            wrapperRow.rate = rec.Rate_Post_Completion__c != null ? rec.Rate_Post_Completion__c : 0;
            wrapperRow.calculatedValue = rec.Market_Value_Post_Completion__c != null ?
                rec.Market_Value_Post_Completion__c : 0;
            wrapperRow.valueLabel = 'Market Value in Rs.';
            
            postCompletionValues.add(wrapperRow);
            totalPostCompletionValue += wrapperRow.calculatedValue;
        }
        
        
        
        // ================= PHOTO SECTION =================
        photoRows = new List<List<PhotoWrapper>>();
        List<Document_Details__c> docDetails = [
            SELECT Id, Name, Content_Document_Id__c
            FROM Document_Details__c
            WHERE Technical__c = :recordId and Content_Document_Id__c!=null
            AND Name != 'Technical Report' AND Name != 'Technical Report PDF'
        ];
        // Collect all ContentDocumentIds
        Set<Id> contentDocIds = new Set<Id>();
        for (Document_Details__c doc : docDetails) {
            contentDocIds.add(doc.Content_Document_Id__c);
        }
        // Query Latest ContentVersions
        Map<Id, ContentVersion> versionMap = new Map<Id, ContentVersion>();
        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId, FileExtension
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocIds
            AND IsLatest = true
        ]) {
            versionMap.put(cv.ContentDocumentId, cv);
        }
        // Build Wrapper List
        List<PhotoWrapper> tempList = new List<PhotoWrapper>();
        for (Document_Details__c doc : docDetails) {
            if (versionMap.containsKey(doc.Content_Document_Id__c)) {
                ContentVersion cv = versionMap.get(doc.Content_Document_Id__c);
                tempList.add(new PhotoWrapper(doc, cv));
            }
        }
        for (Integer i = 0; i < tempList.size(); i += 2) {
            List<PhotoWrapper> row = new List<PhotoWrapper>();
            row.add(tempList[i]);
            if (i + 1 < tempList.size()) {
                row.add(tempList[i + 1]);
            }
            photoRows.add(row);
        }
        if (techEval.HL_Loan_Application__c != null) {
            
            List<Application_applicant__c> appList = [SELECT Id, Name, Mobile_Number__c FROM Application_applicant__c
                                                      WHERE Loan_Application__c = :techEval.HL_Loan_Application__c and Applicant_Type__c='Primary Applicant' LIMIT 1];
            
            if (!appList.isEmpty()) {
                applicant = appList[0];
            }
        }
        
    }
    @AuraEnabled
    public static Map<String, String> generateAndSavePDF(Id recordId) {
        
        // 🔹 Get VF page reference
        PageReference pdfPage = Page.VFGenerateTechnicalReport;
        pdfPage.getParameters().put('id', recordId);
        
        // 🔹 Generate PDF Blob
        Blob pdfBlob;
        if(test.isRunningTest()){
            pdfBlob = Blob.valueOf('test');
        }else{
            pdfBlob = pdfPage.getContentAsPDF();
        }
        
        // 🔹 Create ContentVersion (Salesforce File)
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Generated PDF';
        cv.PathOnClient = 'GeneratedPDF.pdf';
        cv.VersionData = pdfBlob;
        cv.FirstPublishLocationId = recordId; // Attach to record
        insert cv;
        
        // 🔹 Get ContentDocumentId
        cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
        Technical_Evaluation__c techRecord = [ SELECT Id,Is_Report_Uploaded__c,Date_of_Technical_Request_Receipt__c, HL_Application_Collateral__r.Collateral__c, HL_Application_Collateral__c, HL_Loan_Application__c FROM Technical_Evaluation__c WHERE Id = :recordId LIMIT 1];
        techRecord.Is_Report_Uploaded__c=true;
        techRecord.Date_of_Technical_Request_Receipt__c=Date.ValueOf(System.now());
        update techRecord;
        // 🔹 Return both IDs
        Map<String, String> result = new Map<String, String>();
        result.put('ContentVersionId', cv.Id);
        result.put('ContentDocumentId', cv.ContentDocumentId);
        Document_Details__c doc = new Document_Details__c(
            Technical__c=recordId,
            Name = 'Technical Report',
            Active__c = true,
            Status__c = null,
            Content_Document_Id__c=cv.ContentDocumentId,
            Content_Version_Id__c=cv.Id,
            Document_Category__c='Technical Documents',
            Application_Collateral__c=techRecord.HL_Application_Collateral__c,
            Document_Required__c='Required',
            Loan_Application__c=techRecord.HL_Loan_Application__c,
            Requirement_At__c='Collateral Level'
        );
        insert doc;
        // 🔹 Link File to Document_Details__c record
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = doc.Id;   // Link to Document_Details__c
        cdl.ShareType = 'V';           // View permission
        cdl.Visibility = 'AllUsers';
        
        insert cdl;
        
        
        return result;
    }
    @AuraEnabled
    public static List<ProductWrapper> fetchAllProducts(String loanId) {
        try {
            
            Id productRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
            Id subProductRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
            Id variantRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();
            Id subVariantRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Variant').getRecordTypeId();
        	Technical_Evaluation__c techRecord = [ SELECT Id, HL_Loan_Application__c FROM Technical_Evaluation__c WHERE Id = :loanId LIMIT 1];
            List<Product2> products = [
                SELECT Id, Name, RecordTypeId, Product__c, Loan_Purpose__c
                FROM Product2
                WHERE Loan_Application__c = :techRecord.HL_Loan_Application__c
                ORDER BY CreatedDate ASC
            ];
            
            Map<Id, ProductWrapper> productMap = new Map<Id, ProductWrapper>();
            Map<Id, Id> subProductToProductMap = new Map<Id, Id>();
            Map<Id, Id> subVariantToProductMap = new Map<Id, Id>();
            
            // 1️⃣ Product
            for (Product2 prod : products) {
                if (prod.RecordTypeId == productRecordId) {
                    ProductWrapper wrapper = new ProductWrapper();
                    wrapper.Id = prod.Id;
                    wrapper.prodName = prod.Name;
                    productMap.put(prod.Id, wrapper);
                }
            }
            
            // 2️⃣ Sub Product
            for (Product2 prod : products) {
                if (prod.RecordTypeId == subProductRecordId && prod.Product__c != null) {
                    if (productMap.containsKey(prod.Product__c)) {
                        ProductWrapper wrapper = productMap.get(prod.Product__c);
                        wrapper.subProdName = prod.Name;
                        wrapper.loanPurpose = prod.Loan_Purpose__c;
                        subProductToProductMap.put(prod.Id, prod.Product__c);
                    }
                }
            }
            
            // 3️⃣ Variant
            for (Product2 prod : products) {
                if (prod.RecordTypeId == variantRecordId && prod.Product__c != null) {
                    if (subProductToProductMap.containsKey(prod.Product__c)) {
                        Id parentProductId = subProductToProductMap.get(prod.Product__c);
                        if (productMap.containsKey(parentProductId)) {
                            ProductWrapper wrapper = productMap.get(parentProductId);
                            wrapper.variant = prod.Name;
                        }
                    }
                }
            }
            
            // 4️⃣ Sub Variant
            for (Product2 prod : products) {
                if (prod.RecordTypeId == subVariantRecordId && prod.Product__c != null) {
                    if (subProductToProductMap.containsKey(prod.Product__c)) {
                        Id parentProductId = subProductToProductMap.get(prod.Product__c);
                        if (productMap.containsKey(parentProductId)) {
                            ProductWrapper wrapper = productMap.get(parentProductId);
                            wrapper.subvariantName = prod.Name;
                        }
                    }
                }
            }
            
            return productMap.values();
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching product records: ' + e.getMessage());
        }
    }
    
    public class ProductWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String prodName;
        @AuraEnabled public String subProdName;
        @AuraEnabled public String loanPurpose;
        @AuraEnabled public String variant;
        @AuraEnabled public String subvariantName;
    }
    
    
}