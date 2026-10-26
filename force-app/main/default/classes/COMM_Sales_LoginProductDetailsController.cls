public without sharing class COMM_Sales_LoginProductDetailsController {
    @AuraEnabled
    public static selectedProductWrapper getSlectedProductDetails(Id loanId, Id productId) {
        selectedProductWrapper prodWrap = new selectedProductWrapper();
        try {
            Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Product2.getRecordTypeInfosByName();
            Id subProductRecordTypeId = rtMap.get('Sub Product').getRecordTypeId();
            Id totalTenureRecordTypeId = rtMap.get('Total Tenure').getRecordTypeId();
            Id hybridTenureRecordId = rtMap.get('Hybrid Tenure').getRecordTypeId();
            Id schemeRecordTypeId = rtMap.get('Scheme').getRecordTypeId();
            Id fullEMIRecordTypeId = rtMap.get('Full EMI').getRecordTypeId();

            List<Product2> subProductRecords = [SELECT Id, Name, Product__c, Product__r.Name, Product__r.Product_Master__c, Product_Master__c
                                                FROM Product2 WHERE Loan_Application__c = :loanId AND Product__c = :productId
                                                AND RecordTypeId = :subProductRecordTypeId LIMIT 1];

            if (!subProductRecords.isEmpty()) {
                Product2 subProd = subProductRecords[0];

                // Product Info
                prodWrap.productId = subProd.Product__c;
                prodWrap.productName = subProd.Product__r.Name;
                prodWrap.productMaster = subProd.Product__r.Product_Master__c;
               // prodWrap.isApplicableForHl = subProd.Product_Master__r.IsApplicableForHL__c;
               // prodWrap.approvalStatusValue = subProd.Approval_Status__c;
               // prodWrap.rejectionRemarks = subProd.Rejection_Remarks__c;
               //  prodWrap.isRejected = (subProd.Approval_Status__c == 'Rejected');

                // Sub Product Info
                prodWrap.subProductId = subProd.Id;
                prodWrap.subProductName = subProd.Name;
                prodWrap.subProductMaster = subProd.Product_Master__c;

                List<Product2> relatedProducts = [SELECT Id, Name, RecordTypeId, Product_Master__c, Variant__c, Variant__r.Name, Variant__r.Product_Master__c, Variant__r.Product_Master__r.PLR_Value__c,
                                                    Sub_Variant__c, Sub_Variant__r.Name, Sub_Variant__r.Product_Master__c FROM Product2 WHERE Loan_Application__c = :loanId
                                                    AND Product__c = :subProd.Id AND RecordTypeId IN :new List<Id>{totalTenureRecordTypeId, schemeRecordTypeId, fullEMIRecordTypeId}];

                for (Product2 p : relatedProducts) {
                    if (p.RecordTypeId == totalTenureRecordTypeId) {
                        // Total Tenure Info
                        prodWrap.totalTenureProductId = p.Id;
                        prodWrap.totalTenureProductName = p.Name;
                        prodWrap.totalTenureProductMaster = p.Product_Master__c;

                        // Variant Info
                        prodWrap.variantProductId = p.Variant__c;
                        prodWrap.variantProductName = (p.Variant__r != null) ? p.Variant__r.Name : null;
                        prodWrap.variantProductMaster = (p.Variant__r != null) ? p.Variant__r.Product_Master__c : null;
                        if (p.Variant__r.Product_Master__c != null && p.Variant__r.Product_Master__r.PLR_Value__c != null) {
                            prodWrap.pLRValue = p.Variant__r.Product_Master__r.PLR_Value__c;
                        } 

                        // Sub Variant Info
                        prodWrap.subVariantProductId = p.Sub_Variant__c;
                        prodWrap.subVariantProductName = (p.Sub_Variant__r != null) ? p.Sub_Variant__r.Name : null;
                        prodWrap.subVariantProductMaster = (p.Sub_Variant__r != null) ? p.Sub_Variant__r.Product_Master__c : null;

                    } else if (p.RecordTypeId == schemeRecordTypeId) {
                        // Scheme Info
                        prodWrap.schemeProductId = p.Id;
                        prodWrap.schemeProductName = p.Name;
                        prodWrap.schemeProductMaster = p.Product_Master__c;

                    } else if (p.RecordTypeId == fullEMIRecordTypeId) {
                        // Full EMI Info
                        prodWrap.fullEMIProductId = p.Id;
                        prodWrap.fullEMIProductName = p.Name;
                        prodWrap.fullEMIProductMaster = p.Product_Master__c;
                    }
                }
                System.debug('prodWrap.subVariantProductId :- '+prodWrap.subVariantProductId);
                List<Product2> hybridTenureRecords = [SELECT Id, Name, RecordTypeId, Product_Master__c FROM Product2 WHERE RecordTypeId =: hybridTenureRecordId AND Product__c =: prodWrap.subVariantProductId];
                if (!hybridTenureRecords.isEmpty()) {
                    Product2 hybridRec = hybridTenureRecords[0];
                    prodWrap.hybridRecProductId = hybridRec.Id;
                    prodWrap.hybridRecProductName = hybridRec.Name;
                    prodWrap.hybridRecProductMaster = hybridRec.Product_Master__c;
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching product details: ' + e.getMessage());
        }
        System.debug('prodWrap: '+prodWrap);
        return prodWrap;
    }

    public class selectedProductWrapper {
        // Main Product
        @AuraEnabled public Id productId;
        @AuraEnabled public String productName;
        @AuraEnabled public Id productMaster;

        // Sub Product
        @AuraEnabled public Id subProductId;
        @AuraEnabled public String subProductName;
        @AuraEnabled public Id subProductMaster;
      //  @AuraEnabled public Boolean isApplicableForHl;
      //  @AuraEnabled public String approvalStatusValue;
      //  @AuraEnabled public String rejectionRemarks;
      //  @AuraEnabled public Boolean isRejected;

        // Variant
        @AuraEnabled public Id variantProductId;
        @AuraEnabled public String variantProductName;
        @AuraEnabled public Id variantProductMaster;
        @AuraEnabled public Decimal pLRValue;

        // Sub Variant
        @AuraEnabled public Id subVariantProductId;
        @AuraEnabled public String subVariantProductName;
        @AuraEnabled public Id subVariantProductMaster;

        // Scheme
        @AuraEnabled public Id schemeProductId;
        @AuraEnabled public String schemeProductName;
        @AuraEnabled public Id schemeProductMaster;

        // Full EMI
        @AuraEnabled public Id fullEMIProductId;
        @AuraEnabled public String fullEMIProductName;
        @AuraEnabled public Id fullEMIProductMaster;

        // Hybrid Tenure
        @AuraEnabled public Id hybridRecProductId;
        @AuraEnabled public String hybridRecProductName;
        @AuraEnabled public Id hybridRecProductMaster;

        // Total Tenure
        @AuraEnabled public Id totalTenureProductId;
        @AuraEnabled public String totalTenureProductName;
        @AuraEnabled public Id totalTenureProductMaster;

        // Loan & BT Details
        @AuraEnabled public Decimal reqLoanAmount;
        @AuraEnabled public String loanFacility;
        @AuraEnabled public String productType;
        @AuraEnabled public String loanPurpose;
        @AuraEnabled public String transactionType;
        @AuraEnabled public Decimal originalSanctionedAmount;
        @AuraEnabled public Decimal requestedROI;
        @AuraEnabled public String financialInstitutionName;
        @AuraEnabled public Decimal numberOfInstallmentsPaid;
        @AuraEnabled public Date existingLoanStartDate;
        @AuraEnabled public Boolean isVASOnly;
        @AuraEnabled public String repaymentFacility;
    }

    public class ProductWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String prodName;
        @AuraEnabled public String prodMaster;
        @AuraEnabled public String subVariantMaster;
        @AuraEnabled public String subProductMaster;
        @AuraEnabled public String variantMaster;
        @AuraEnabled public String loanPurposeMaster;
        @AuraEnabled public String propertyMaster;
        @AuraEnabled public String transactionTypeMaster;
        @AuraEnabled public String schemeMaster;
        @AuraEnabled public String RecordTypeId;
        @AuraEnabled public String RepaymentFacility;
        @AuraEnabled public String LoanApplication;
        @AuraEnabled public String ProductName;
        @AuraEnabled public String subProdName;
        @AuraEnabled public String subProdId;
        @AuraEnabled public String schemeProdId;   
       //  @AuraEnabled public Boolean isApplicableForHl;
      //  @AuraEnabled public String approvalStatusValue;   
      //  @AuraEnabled public String rejectionRemarks;   
      //  @AuraEnabled public Boolean isRejected; 
        @AuraEnabled public String variant;
        @AuraEnabled public String variantId;         
        @AuraEnabled public String schemeProdName;
        @AuraEnabled public String subvariantName;
        @AuraEnabled public String subvariantId;       
        @AuraEnabled public String hybridTenureName;
        @AuraEnabled public String hybridTenureId;     
        @AuraEnabled public String ProductCode;
        @AuraEnabled public Boolean isEmptyWrapper;
        @AuraEnabled public Boolean isVASOnly;
        @AuraEnabled public String fullEMI;
        @AuraEnabled public String fullEMIId;         
        @AuraEnabled public String totalTenure;
        @AuraEnabled public String totalTenureId;      
        @AuraEnabled public Decimal loanAmoutReq;
        @AuraEnabled public Decimal sanctionedAmount;
        @AuraEnabled public Decimal originalSanctionedAmount;
        @AuraEnabled public String loanFacility;
        @AuraEnabled public String moratPeriod;
        @AuraEnabled public String productType;
        @AuraEnabled public Decimal requestedROI;
        @AuraEnabled public String loanPurpose;
        @AuraEnabled public String transactionType;
        @AuraEnabled public Date existingLoanStartDate;
        @AuraEnabled public String financialInstitutionName;
        @AuraEnabled public Decimal numberOfInstallmentsPaid;
        @AuraEnabled public String transactionTypeId;
        @AuraEnabled public String transactionTypeName; 
        @AuraEnabled public String loanPurposeName;
        @AuraEnabled public String loanPurposeId; 
        @AuraEnabled public String propertyTypeName;
        @AuraEnabled public String propertyTypeId; 
        @AuraEnabled public Boolean isFlexiLoan= false; 
    }

    @AuraEnabled
    public static List<ProductWrapper> fetchAllProducts(String loanId) {
        try {
            Id productRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
            Id subProductRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
            Id variantRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();
            Id productSchemeRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Scheme').getRecordTypeId();
            Id subVariantRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Variant').getRecordTypeId();
            Id hybridTenureRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Hybrid Tenure').getRecordTypeId();
            Id fullEMIRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Full EMI').getRecordTypeId();
            Id totalTenureRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Total Tenure').getRecordTypeId();
            Id transactionTypeRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Transaction Type').getRecordTypeId();
            Id loanPurposeRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Loan Purpose').getRecordTypeId();
            Id propertyTypeRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Property Type').getRecordTypeId();

            List<Product2> products = [SELECT Id,Product_Type__c,Sanctioned_Loan_Amount__c,Product_Master__c,
            Name,Requested_ROI__c, RecordTypeId,Loan_Purpose__c,Transaction_Type__c, HL_Moratorium_Period__c,
            Original_Sanctioned_Amount__c, Number_of_Installments_Paid__c, 
            Financial_Institution_Name__c, Existing_Loan_Start_Date__c, Loan_Facility__c,
             Requested_Loan_Amount__c, Repayment_Facility__c, Is_loan_VAS_only__c, Loan_Application__c,
              Product__c FROM Product2 
                                        WHERE Loan_Application__c = :loanId ORDER BY CreatedDate ASC];

            Map<Id, ProductWrapper> productMap = new Map<Id, ProductWrapper>();
            Map<Id, Id> subProductToProductMap = new Map<Id, Id>();
            Map<Id, Id> subVariantToProductMap = new Map<Id, Id>();

            for (Product2 prod : products) {
                if (prod.RecordTypeId == productRecordId) {
                    ProductWrapper wrapper = new ProductWrapper();
                    wrapper.Id = prod.Id;
                    wrapper.prodMaster = prod.Product_Master__c;
                    wrapper.productType = prod.Product_Type__c;
                    wrapper.LoanApplication = prod.Loan_Application__c;
                    wrapper.prodName = prod.Name;
                    wrapper.isVASOnly = prod.Is_loan_VAS_only__c;
                    wrapper.isFlexiLoan = prod.Name == 'Flexi Loan' ? true: false;
                    productMap.put(prod.Id, wrapper);
                }
            }

            for (Product2 prod : products) {
                if (prod.RecordTypeId == subProductRecordId && prod.Product__c != null) {
                    if (productMap.containsKey(prod.Product__c)) {
                        Id parentProductId = prod.Product__c;
                        ProductWrapper wrapper = productMap.get(parentProductId);
                        wrapper.subProdName = prod.Name;
                        wrapper.subProductMaster = prod.Product_Master__c;
                       // wrapper.isApplicableForHl = prod.Product_Master__r.IsApplicableForHL__c;
                       // wrapper.approvalStatusValue = prod.Approval_Status__c;
                       // wrapper.rejectionRemarks = prod.Rejection_Remarks__c;
                      //  wrapper.isRejected = (prod.Approval_Status__c == 'Rejected');
                        wrapper.subProdId = prod.Id; // <-- Added sub product Id
                        wrapper.loanAmoutReq = prod.Requested_Loan_Amount__c;
                        wrapper.loanFacility = prod.Loan_Facility__c;
                        wrapper.requestedROI = prod.Requested_ROI__c;
                        wrapper.loanPurpose = prod.Loan_Purpose__c;
                        wrapper.transactionType = prod.Transaction_Type__c;
                        wrapper.sanctionedAmount = prod.Sanctioned_Loan_Amount__c;
                        wrapper.originalSanctionedAmount = prod.Original_Sanctioned_Amount__c;
                        wrapper.existingLoanStartDate = prod.Existing_Loan_Start_Date__c;
                        wrapper.financialInstitutionName = prod.Financial_Institution_Name__c;
                        wrapper.numberOfInstallmentsPaid = prod.Number_of_Installments_Paid__c;
                        subProductToProductMap.put(prod.Id, prod.Product__c);
                    }
                }
            }

            for (Product2 prod : products) {
                if (prod.RecordTypeId == transactionTypeRecordId && prod.Product__c != null) {
                    if (subProductToProductMap.containsKey(prod.Product__c)) {
                        Id parentProductId = subProductToProductMap.get(prod.Product__c);
                        if (productMap.containsKey(parentProductId)) {
                            ProductWrapper wrapper = productMap.get(parentProductId);
                            wrapper.transactionTypeName = prod.Name;
                            wrapper.transactionTypeId = prod.Id;
                            wrapper.transactionTypeMaster = prod.Product_Master__c;
                        }
                    }
                }
            }

            for (Product2 prod : products) {
                if (prod.RecordTypeId == loanPurposeRecordId && prod.Product__c != null) {
                    if (subProductToProductMap.containsKey(prod.Product__c)) {
                        Id parentProductId = subProductToProductMap.get(prod.Product__c);
                        if (productMap.containsKey(parentProductId)) {
                            ProductWrapper wrapper = productMap.get(parentProductId);
                            wrapper.loanPurposeName = prod.Name;
                            wrapper.loanPurposeId = prod.Id;
                            wrapper.loanPurposeMaster = prod.Product_Master__c;
                        }
                    }
                }
            }

            for (Product2 prod : products) {
                if (prod.RecordTypeId == propertyTypeRecordId && prod.Product__c != null) {
                    if (subProductToProductMap.containsKey(prod.Product__c)) {
                        Id parentProductId = subProductToProductMap.get(prod.Product__c);
                        if (productMap.containsKey(parentProductId)) {
                            ProductWrapper wrapper = productMap.get(parentProductId);
                            wrapper.propertyTypeName = prod.Name;
                            wrapper.propertyTypeId = prod.Id;
                            wrapper.propertyMaster = prod.Product_Master__c;
                        }
                    }
                }
            }

            for (Product2 prod : products) {
                if (prod.RecordTypeId == variantRecordId && prod.Product__c != null) {
                    if (subProductToProductMap.containsKey(prod.Product__c)) {
                        Id parentProductId = subProductToProductMap.get(prod.Product__c);
                        if (productMap.containsKey(parentProductId)) {
                            ProductWrapper wrapper = productMap.get(parentProductId);
                            wrapper.variant = prod.Name;
                            wrapper.variantMaster = prod.Product_Master__c;
                            wrapper.variantId = prod.Id; // <-- Added variant Id
                        }
                    }
                }
            }

            for (Product2 prod : products) {
                if (prod.RecordTypeId == subVariantRecordId && prod.Product__c != null) {
                    if (subProductToProductMap.containsKey(prod.Product__c)) {
                        Id parentProductId = subProductToProductMap.get(prod.Product__c);
                        if (productMap.containsKey(parentProductId)) {
                            ProductWrapper wrapper = productMap.get(parentProductId);
                            wrapper.subvariantName = prod.Name;
                            wrapper.moratPeriod = prod.HL_Moratorium_Period__c;
                            wrapper.subVariantMaster = prod.Product_Master__c;
                            wrapper.subvariantId = prod.Id; // <-- Added subvariant Id
                            subVariantToProductMap.put(prod.Id, parentProductId);
                        }
                    }
                }
            }

            for (Product2 prod : products) {
                if (prod.RecordTypeId == hybridTenureRecordId && prod.Product__c != null) {
                   System.debug('prod===>'+prod);
                    System.debug('prod===>'+prod.Product__c);
                    System.debug(subVariantToProductMap);
                    System.debug('productMap==>'+productMap);
                    if (subVariantToProductMap.containsKey(prod.Product__c)) {
                        Id parentProductId = subVariantToProductMap.get(prod.Product__c);
                        if (productMap.containsKey(parentProductId)) {
                            ProductWrapper wrapper = productMap.get(parentProductId);
                            wrapper.hybridTenureName = prod.Name;
                            wrapper.hybridTenureId = prod.Id; // <-- Added hybridTenure Id
                        }
                    }
                }
            }

            for (Product2 prod : products) {
                if (prod.RecordTypeId == productSchemeRecordId && prod.Product__c != null) {
                    if (subProductToProductMap.containsKey(prod.Product__c)) {
                        Id parentProductId = subProductToProductMap.get(prod.Product__c);
                        if (productMap.containsKey(parentProductId)) {
                            ProductWrapper wrapper = productMap.get(parentProductId);
                            wrapper.schemeProdName = prod.Name;
                            wrapper.schemeMaster = prod.Product_Master__c;
                            wrapper.schemeProdId = prod.Id; // <-- Added scheme Id
                        }
                    }
                }
            }

            for (Product2 prod : products) {
                if (prod.RecordTypeId == fullEMIRecordId && prod.Product__c != null) {
                    if (subProductToProductMap.containsKey(prod.Product__c)) {
                        Id parentProductId = subProductToProductMap.get(prod.Product__c);
                        if (productMap.containsKey(parentProductId)) {
                            ProductWrapper wrapper = productMap.get(parentProductId);
                            wrapper.fullEMI = prod.Name;
                            wrapper.fullEMIId = prod.Id; // <-- Added fullEMI Id
                        }
                    }
                }
            }

            for (Product2 prod : products) {
                if (prod.RecordTypeId == totalTenureRecordId && prod.Product__c != null) {
                    if (subProductToProductMap.containsKey(prod.Product__c)) {
                        Id parentProductId = subProductToProductMap.get(prod.Product__c);
                        if (productMap.containsKey(parentProductId)) {
                            ProductWrapper wrapper = productMap.get(parentProductId);
                            wrapper.totalTenure = prod.Name;
                            wrapper.totalTenureId = prod.Id; // <-- Added totalTenure Id
                        }
                    }
                }
            }

            for (ProductWrapper wrapper : productMap.values()) {
                if (String.isBlank(wrapper.prodName) || String.isBlank(wrapper.subProdName) || String.isBlank(wrapper.schemeProdName)) {
                    wrapper.isEmptyWrapper = true;
                }
            }

            return productMap.values();

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching product records: ' + e.getMessage());
        }
    }

    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        
        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getProductMasterPicklist(String recordTypeName, Id productRecordSelected, Id subProductRecordSelected, Id subVariantSelected, Id variantRecId) {
        try {
            //HL-Ishi-10/10/2025
            Map<String,String> inputMapUtility = new  Map<String,String>();
            Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
            Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
              //HL-Ishi-10/10/2025
            Id recordTypeId = Schema.SObjectType.Product_Master__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
            System.debug('recordTypeId-->' + recordTypeId);

            String query = 'SELECT Id, Name, Loan_Purpose__c FROM Product_Master__c WHERE RecordType.Name = :recordTypeName';
            if(recordTypeName == 'Product'){
                /*if(isHlRelated){
                    query += ' AND IsApplicableForHL__c = :isHlRelated';
                }
                else{
                    query += ' AND IsApplicableForHL__c = :isHlRelated';
                }*/
            }
            if (recordTypeName == 'Sub Product' && productRecordSelected != null) {
                query += ' AND Product__c = :productRecordSelected';
            } else if (recordTypeName == 'Transaction Type' && subProductRecordSelected != null) {
                query += ' AND Sub_Product__c = :subProductRecordSelected';
            }else if (recordTypeName == 'Scheme' && productRecordSelected != null) {
                query += ' AND Product__c = :productRecordSelected';
            } else if (recordTypeName == 'Variant' && productRecordSelected != null) {
                query += ' AND Product__c = :productRecordSelected';
            } else if (recordTypeName == 'Sub Variant' && productRecordSelected != null) {
                query += ' AND Product__c = :productRecordSelected';
            } else if (recordTypeName == 'Property Type' && productRecordSelected != null) {
                query += ' AND Product__c = :productRecordSelected'; // Anish
            } else if (recordTypeName == 'Hybrid Tenure' && subVariantSelected != null) {
                query += ' AND Sub_Variant__c = :subVariantSelected'; // Anish
            } else if (recordTypeName == 'Full EMI' && subVariantSelected != null) {
                query += ' AND Sub_Variant__c = :subVariantSelected'; // Anish
            } else if (recordTypeName == 'Loan Purpose' && subProductRecordSelected != null) {
                query += ' AND Sub_Product__c = :subProductRecordSelected'; // Anish
            }
            //HL-Ishi-10/10/2025
            if (isHlRelated) {
               // query += ' AND IsApplicableForHL__c = true';
            }
            //HL-Ishi-10/10/2025

            query += ' ORDER BY Name ASC';
            System.debug('picklist query --> ' + query);

            List<Product_Master__c> productMasters = Database.query(query);
            System.debug('productMasters --> ' + productMasters);

            List<PicklistOption> picklistOptions = new List<PicklistOption>();
            Map<Id, String> loanPurposeMap = new Map<Id, String>();
            Map<Id, String> productMap = new Map<Id, String>();
            for (Product_Master__c productMast : productMasters) {
                String label = productMast.Name;
                picklistOptions.add(new PicklistOption(label, productMast.Id));

                if (recordTypeName == 'Transaction Type') {
                    loanPurposeMap.put(productMast.Id, productMast.Loan_Purpose__c);
                }
                if(recordTypeName == 'Product') {
                    productMap.put(productMast.Id, productMast.Name);
                }
            }

            System.debug(recordTypeName + ' Picklist Options: ' + picklistOptions);

            Map<String, Object> result = new Map<String, Object>{
                'picklistOptions' => picklistOptions
            };
            if (recordTypeName == 'Transaction Type') {
                result.put('loanPurposeMap', loanPurposeMap);
            }
            if(recordTypeName == 'Product') {
                result.put('productMap', productMap);
            }
            return result;

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching picklist: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static string checkProductDedupe(String loanId, String product, String productId, String subProduct) {
        List<Product2> productList = [SELECT Id, Name, RecordTypeId, Repayment_Facility__c, Loan_Application__c, Product__c FROM Product2 
                                        WHERE Loan_Application__c = :loanId];
        List<Id> affordableHomeLoanProducts = new List<Id>();
        List<Id> affordableHomeLoanSubProducts = new List<Id>();
        if(!productList.isEmpty()) {
            for(Product2 prdt : productList) {
                if (prdt.Name == product) {
                    affordableHomeLoanProducts.add(prdt.Id);
                }else if(prdt.Name == subProduct){
                    affordableHomeLoanSubProducts.add(prdt.Id);
                }
            }
                if(!affordableHomeLoanProducts.isEmpty() && !affordableHomeLoanSubProducts.isEmpty()) {
                    return 'Loan can have only one product for one sub product.';
                } else {
                    return 'Valid Product';
                }
            }   else {
                return 'Valid Product'; 
            }
    }

    /*@AuraEnabled
    public static void updateProductAndSubProduct(Map<String, Object> payload) {
        if (payload == null) return;

        try {
            String oppId=  (String)payload.get('oppId');
            // Extract Sub Product Id
            Id subProductId = (Id) payload.get('subProductId');
            Id hybridTenureRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Hybrid Tenure').getRecordTypeId();
            Id productSchemeRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Scheme').getRecordTypeId();
            Id fullEMIRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Full EMI').getRecordTypeId();
            Id totalTenureRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Total Tenure').getRecordTypeId();
            Id recTypeIdTenure = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Hybrid_Tenure').getRecordTypeId();
            Id recTypeIdFullEmiTenure = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Full_EMI').getRecordTypeId();
            Id recTypeIdScheme = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Scheme').getRecordTypeId();
            Id recTypeIdTotalTnr = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Total_Tenure').getRecordTypeId();
             List<Product_Master__c> prodMaster = [Select Id, Name, RecordType.Name from Product_Master__c];
            Map<String,Product_Master__c> nameToMasterMap = new Map<String,Product_Master__c>();
            for(Product_Master__c iterMstr : prodMaster){
                nameToMasterMap.put(iterMstr.Name, iterMstr);
            }
            // Extract Product Ids and values safely
            Map<Object, Object> hybridTenureObj = (Map<Object, Object>) payload.get('hybridTenure');
            Map<Object, Object> fullEmiObj = (Map<Object, Object>) payload.get('fullEMI');
            Map<Object, Object> totalTenureObj = (Map<Object, Object>) payload.get('totalTenure');

            List<Product2> productsToUpdate = new List<Product2>();

            // === Update Names for related Product2 records ===
            if (hybridTenureObj != null && hybridTenureObj.get('id') != null) {
                Id hybridTenureId = (Id) hybridTenureObj.get('id');
                Product2 prod = [SELECT Id, Name FROM Product2 WHERE Id = :hybridTenureId LIMIT 1];
                prod.Name = String.valueOf(hybridTenureObj.get('value'));
                productsToUpdate.add(prod);
            }
            else{
                Product2 hybridTenure = new Product2();
                hybridTenure.Loan_Application__c =oppId;
                hybridTenure.Name = String.valueOf(hybridTenureObj.get('value'));
                hybridTenure.RecordTypeId = recTypeIdTenure;
                //intOnlyTnr.Product_Master__c = nameToMasterMap.get(String.valueOf(hybridTenureObj.get('value'))).Id;
                hybridTenure.Product__c =   (Id) payload.get('subvariantId');
                hybridTenure.Sub_Variant__c =  (Id) payload.get('subvariantId');
                Insert hybridTenure;
                // Integer totalTnrName = (Integer)hybridTenureObj.get('value');
                // insert intOnlyTnr;
                
            }

            if (fullEmiObj != null && fullEmiObj.get('id') != null) {
                Id fullEmiId = (Id) fullEmiObj.get('id');
                Product2 prod = [SELECT Id, Name FROM Product2 WHERE Id = :fullEmiId LIMIT 1];
                prod.Name = String.valueOf(fullEmiObj.get('value'));
                productsToUpdate.add(prod);
            }
            else{
                 Product2 fullEmiTnr = new Product2();
                fullEmiTnr.Loan_Application__c = oppId;
                fullEmiTnr.Name =  String.valueOf(fullEmiObj.get('value'));
                fullEmiTnr.RecordTypeId = recTypeIdFullEmiTenure;
                //fullEmiTnr.Product_Master__c = nameToMasterMap.get(String.valueOf(fullEmiObj.get('value'))).Id;
                fullEmiTnr.Product__c =subProductId;
                fullEmiTnr.Variant__c = (Id) payload.get('subvariantId');
                fullEmiTnr.Sub_Variant__c =(Id) payload.get('subvariantId');
                Insert fullEmiTnr;
            }

            if (totalTenureObj != null && totalTenureObj.get('id') != null) {
                Id totalTenureId = (Id) totalTenureObj.get('id');
                Product2 prod = [SELECT Id, Name FROM Product2 WHERE Id = :totalTenureId LIMIT 1];
                prod.Name = String.valueOf(totalTenureObj.get('value'));
                productsToUpdate.add(prod);
            }
            else{
                Product2 totalTnr = new Product2();
                totalTnr.Loan_Application__c = oppId;
                totalTnr.Name =String.valueOf(totalTenureObj.get('value'));
                totalTnr.RecordTypeId = recTypeIdTotalTnr;
                //totalTnr.Product_Master__c = nameToMasterMap.get(String.valueOf(totalTenureObj.get('value'))).Id;
                totalTnr.Product__c = (Id) payload.get('subvariantId');
                
                totalTnr.Sub_Variant__c =(Id) payload.get('subvariantId');
                Insert totalTnr;
            }

            if (!productsToUpdate.isEmpty()) {
                update productsToUpdate;
            }

             // === Update Sub Variant details ===
            Boolean customerNegotiationHL = (Boolean) payload.get('customerNegotiationHL');
            if (customerNegotiationHL == true) {

                Id subvariantId = (Id) payload.get('subvariantId');
                Product2 subVariant = [SELECT Id,Name,Product_Master__c,Product__r.Product__c FROM Product2 WHERE Id = :subvariantId LIMIT 1];
                String oldName = subVariant.Name;
                subVariant.Name = (String) payload.get('savedSubVarient');
                subVariant.Product_Master__c = (String) payload.get('subVarianMastertId');

                update subVariant;
                // --- Update related Loan_Transaction__c ---
                List<Loan_Transaction__c> txnList = [SELECT Id, Allow_Grace__c, Allow_Payment_in_Grace_Period__c FROM Loan_Transaction__c WHERE Product__c = :subVariant.Product__r.Product__c LIMIT 1];
                if (!txnList.isEmpty()) {
                    Loan_Transaction__c txn = txnList[0];
                    String subName = subVariant.Name != null ? subVariant.Name.toUpperCase() : '';
                    txn.Allow_Grace__c = (subName == 'PEMI' || subName == 'MORAT');
                    txn.Allow_Payment_in_Grace_Period__c = (subName == 'PEMI');

                    update txn;

                    if (oldName == 'DEMI' && subName != 'DEMI') {
                        List<Loan_Transaction__c> toDelete = [SELECT Id FROM Loan_Transaction__c WHERE Related_Transaction__c = :txn.Id ];
                        if (!toDelete.isEmpty()) {
                            delete toDelete;
                        }
                    }
                 }
            }

            // === Update Sub Product details ===
            Product2 subProd = [
                SELECT Id,Name,Product_Master__c, Loan_Facility__c, Loan_Purpose__c, Transaction_Type__c,
                    Requested_Loan_Amount__c, Requested_ROI__c,
                    Original_Sanctioned_Amount__c, Financial_Institution_Name__c,
                    Number_of_Installments_Paid__c, Existing_Loan_Start_Date__c,
                    Product__c, Product__r.Id, Product__r.Product_Type__c, Product__r.Name,
                    Product__r.Loan_Application__c
                FROM Product2
                WHERE Id = :subProductId
                LIMIT 1
            ];

            if (subProd == null) return;

            subProd.Loan_Facility__c = (String) payload.get('loanFacility');
            subProd.Requested_Loan_Amount__c = (payload.get('requestedLoanAmount') != null && String.isNotBlank(String.valueOf(payload.get('requestedLoanAmount'))))
                ? Decimal.valueOf(String.valueOf(payload.get('requestedLoanAmount'))) : null;
            subProd.Requested_ROI__c = (payload.get('requestedROI') != null && String.isNotBlank(String.valueOf(payload.get('requestedROI'))))
                ? Decimal.valueOf(String.valueOf(payload.get('requestedROI'))) : null;

            Map<Object, Object> btDetailsObj = (Map<Object, Object>) payload.get('btDetails');
            if (btDetailsObj != null) {
                subProd.Original_Sanctioned_Amount__c = btDetailsObj.get('originalSanctionedAmount') != null
                    ? Decimal.valueOf(String.valueOf(btDetailsObj.get('originalSanctionedAmount')))
                    : null;
                subProd.Number_of_Installments_Paid__c = btDetailsObj.get('numberOfInstallmentsPaid') != null
                    ? Integer.valueOf(String.valueOf(btDetailsObj.get('numberOfInstallmentsPaid')))
                    : null;
                subProd.Financial_Institution_Name__c = (String) btDetailsObj.get('financialInstitutionName');
                subProd.Existing_Loan_Start_Date__c = String.isNotBlank((String) btDetailsObj.get('existingLoanStartDate'))
                    ? Date.valueOf((String) btDetailsObj.get('existingLoanStartDate'))
                    : null;
            }

            update subProd;

            // === Step 3: Check if Product record type needs update ===
            if (subProd.Product__c != null && payload.containsKey('productType')) {
                String newProductType = (String) payload.get('productType');

                Product2 productRecord = [
                    SELECT Id, Name, Product_Type__c, Loan_Application__c
                    FROM Product2
                    WHERE Id = :subProd.Product__c
                    LIMIT 1
                ];

                if (productRecord != null && newProductType != null &&
                    productRecord.Product_Type__c != newProductType) {

                    // Update current product’s Product_Type__c
                    productRecord.Product_Type__c = newProductType;
                    update productRecord;

                    // Query another record with same Name on same Loan_Application__c
                    List<Product2> sameNameProds = [
                        SELECT Id, Product_Type__c
                        FROM Product2
                        WHERE Loan_Application__c = :productRecord.Loan_Application__c
                        AND Name = :productRecord.Name
                        AND Id != :productRecord.Id
                        LIMIT 1
                    ];

                    if (!sameNameProds.isEmpty()) {
                        Product2 otherProd = sameNameProds[0];
                        // Flip product type
                        otherProd.Product_Type__c = (newProductType == 'Parent') ? 'Child' : 'Parent';
                        update otherProd;
                    }
                }
            }

        } catch (Exception ex) {
            System.debug('Error in updateProductAndSubProduct: ' + ex.getMessage());
        }
    }*/
    @AuraEnabled
    public static void updateProductAndSubProduct(Map<String, Object> payload) {
        if (payload == null) return;

        try {
            System.debug('payload----'+payload);
            String oppId = (String) payload.get('oppId');
            Id subProductId = (Id) payload.get('subProductId');

            Id hybridTenureRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Hybrid Tenure').getRecordTypeId();
            Id productSchemeRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Scheme').getRecordTypeId();
            Id fullEMIRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Full EMI').getRecordTypeId();
            Id totalTenureRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Total Tenure').getRecordTypeId();

            Id recTypeIdTenure = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Hybrid_Tenure').getRecordTypeId();
            Id recTypeIdFullEmiTenure = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Full_EMI').getRecordTypeId();
            Id recTypeIdScheme = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Scheme').getRecordTypeId();
            Id recTypeIdTotalTnr = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Total_Tenure').getRecordTypeId();
            Id transactionTypeRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Transaction Type').getRecordTypeId();
            Id loanPurposeRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Loan Purpose').getRecordTypeId();
            Id propertyTypeRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Property Type').getRecordTypeId();

            List<Product2> productsToUpdate = new List<Product2>();

            // Temporary holders for HL CO User overrides for subProduct
            String overrideSubProductName = null;
            Id overrideSubProductMasterId = null;

            // Fetch configs
            Map<Object, Object> hybridTenureObj = (Map<Object, Object>) payload.get('hybridTenure');
            Map<Object, Object> fullEmiObj = (Map<Object, Object>) payload.get('fullEMI');
            Map<Object, Object> totalTenureObj = (Map<Object, Object>) payload.get('totalTenure');

            // === HYBRID TENURE ===
            if (hybridTenureObj != null && hybridTenureObj.get('id') != null) {
                Id hybridTenureId = (Id) hybridTenureObj.get('id');
                Product2 prod = [SELECT Id, Name FROM Product2 WHERE Id = :hybridTenureId LIMIT 1];
                prod.Name = String.valueOf(hybridTenureObj.get('value'));
                productsToUpdate.add(prod);
            } else if (hybridTenureObj != null) {
                Product2 hybridTenure = new Product2();
                hybridTenure.Loan_Application__c = oppId;
                hybridTenure.Name = String.valueOf(hybridTenureObj.get('value'));
                hybridTenure.RecordTypeId = recTypeIdTenure;
                hybridTenure.Product__c = (Id) payload.get('subvariantId');
                hybridTenure.Sub_Variant__c = (Id) payload.get('subvariantId');
                insert hybridTenure;
            }

            // === FULL EMI TENURE ===
            if (fullEmiObj != null && fullEmiObj.get('id') != null) {
                Id fullEmiId = (Id) fullEmiObj.get('id');
                Product2 prod = [SELECT Id, Name FROM Product2 WHERE Id = :fullEmiId LIMIT 1];
                prod.Name = String.valueOf(fullEmiObj.get('value'));
                productsToUpdate.add(prod);
            } else if (fullEmiObj != null) {
                Product2 fullEmiTnr = new Product2();
                fullEmiTnr.Loan_Application__c = oppId;
                fullEmiTnr.Name = String.valueOf(fullEmiObj.get('value'));
                fullEmiTnr.RecordTypeId = recTypeIdFullEmiTenure;
                fullEmiTnr.Product__c = subProductId;
                fullEmiTnr.Variant__c = (Id) payload.get('subvariantId');
                fullEmiTnr.Sub_Variant__c = (Id) payload.get('subvariantId');
                insert fullEmiTnr;
            }

            // === TOTAL TENURE ===
            if (totalTenureObj != null && totalTenureObj.get('id') != null) {
                Id totalTenureId = (Id) totalTenureObj.get('id');
                Product2 prod = [SELECT Id, Name FROM Product2 WHERE Id = :totalTenureId LIMIT 1];
                prod.Name = String.valueOf(totalTenureObj.get('value'));
                productsToUpdate.add(prod);
            } else if (totalTenureObj != null) {
                Product2 totalTnr = new Product2();
                totalTnr.Loan_Application__c = oppId;
                totalTnr.Name = String.valueOf(totalTenureObj.get('value'));
                totalTnr.RecordTypeId = recTypeIdTotalTnr;
                totalTnr.Product__c = subProductId;
                totalTnr.Sub_Variant__c = (Id) payload.get('subvariantId');
                insert totalTnr;
            }

            if (!productsToUpdate.isEmpty()) {
                update productsToUpdate;
            }

            // === CUSTOMER NEGOTIATION HL (existing logic) ===
            Boolean customerNegotiationHL = (Boolean) payload.get('customerNegotiationHL');
            Boolean hlCOUser = (Boolean) payload.get('hlCOUser');
            if (customerNegotiationHL == true || hlCOUser == true) {

                Id subvariantId = (Id) payload.get('subvariantId');
                Product2 subVariant = [
                    SELECT Id, Name, Product_Master__c, Product__r.Product__c
                    FROM Product2 WHERE Id = :subvariantId LIMIT 1
                ];

                String oldName = subVariant.Name;
                if((String) payload.get('savedSubVarient')!='MORAT'){
                  subVariant.HL_Moratorium_Period__c=null;  
                }
                else{
                    subVariant.HL_Moratorium_Period__c=(String)payload.get('moratPeriod');
                }
                subVariant.Name = (String) payload.get('savedSubVarient');
                subVariant.Product_Master__c = (Id) payload.get('subVarianMastertId');
                update subVariant;

                // Update loan transaction
                List<Loan_Transaction__c> txnList = [
                    SELECT Id, Allow_Grace__c, Allow_Payment_in_Grace_Period__c
                    FROM Loan_Transaction__c
                    WHERE Product__c = :subVariant.Product__r.Product__c
                    LIMIT 1
                ];

                if (!txnList.isEmpty()) {
                    Loan_Transaction__c txn = txnList[0];
                    String subName = subVariant.Name != null ? subVariant.Name.toUpperCase() : '';

                    txn.Allow_Grace__c = (subName == 'PEMI' || subName == 'MORAT');
                    txn.Allow_Payment_in_Grace_Period__c = (subName == 'PEMI');

                    update txn;

                    if (oldName == 'DEMI' && subName != 'DEMI') {
                        List<Loan_Transaction__c> toDelete = [
                            SELECT Id FROM Loan_Transaction__c
                            WHERE Related_Transaction__c = :txn.Id
                        ];
                        delete toDelete;
                    }
                }
            }

            // === HL CO USER UPDATES ===
            if (hlCOUser == true) {
                system.debug('859----');
                // =====================================================
                // ================== UPDATE VARIANT ====================
                // =====================================================
                if (payload.containsKey('variantId') && payload.get('variantId') != null) {

                    Product2 variantRec = [
                        SELECT Id, Name, Product_Master__c
                        FROM Product2
                        WHERE Id = :((Id) payload.get('variantId'))
                        LIMIT 1
                    ];

                    variantRec.Name = (String) payload.get('savedVarient');
                    variantRec.Product_Master__c = (Id) payload.get('variantMasterId');

                    update variantRec;
                }


                // =====================================================
                // =================== UPDATE SCHEME ====================
                // =====================================================
                if (payload.containsKey('schemeId') && payload.get('schemeId') != null) {

                    Product2 schemeRec = [
                        SELECT Id, Name, Product_Master__c
                        FROM Product2
                        WHERE Id = :((Id) payload.get('schemeId'))
                        LIMIT 1
                    ];

                    schemeRec.Name = (String) payload.get('savedScheme');
                    schemeRec.Product_Master__c = (Id) payload.get('schemeMasterId');

                    update schemeRec;
                }


                // =====================================================
                // =============== CAPTURE SUB PRODUCT ==================
                // =====================================================
                if (payload.containsKey('subProductId') && payload.get('subProductId') != null) {

                    if (payload.containsKey('savedSubProduct') && payload.get('savedSubProduct') != null) {
                        overrideSubProductName = (String) payload.get('savedSubProduct');
                    }
                    if (payload.containsKey('subProductMasterId') && payload.get('subProductMasterId') != null) {
                        overrideSubProductMasterId = (Id) payload.get('subProductMasterId');
                    }
                }


                // =====================================================
                // =============== UPDATE TRANSACTION TYPE ==============
                // =====================================================
                if (payload.containsKey('savedTransactionMaster') && payload.get('savedTransactionMaster') != null) {

                    if(!payload.containsKey('transactionId') && String.valueOf(payload.get('savedSubProduct')).contains('Flexi')){
                        Product2 transactionTypeRec = new Product2();
                        transactionTypeRec.Name = (String) payload.get('savedTransactionType');
                        transactionTypeRec.RecordTypeId = transactionTypeRecordId;
                        transactionTypeRec.Loan_Application__c = oppId;
                        transactionTypeRec.Product_Master__c = (Id) payload.get('savedTransactionMaster');
                        transactionTypeRec.Product__c = (Id) payload.get('subProductId');
                        insert transactionTypeRec;
                    }else {
                        Product2 transTypeRec = [
                            SELECT Id, Name, Product_Master__c
                            FROM Product2
                            WHERE Id = :((Id) payload.get('transactionId'))
                            LIMIT 1
                        ];

                        transTypeRec.Name = (String) payload.get('savedTransactionType');
                        transTypeRec.Product_Master__c = (Id) payload.get('savedTransactionMaster');
                        if(payload.get('savedTransactionType')!= null){
                            update transTypeRec;
                        }
                        
                    }
                }


                // =====================================================
                // ================= UPDATE LOAN PURPOSE ================
                // =====================================================
                if (payload.containsKey('savedLoanPurposeMaster') && payload.get('savedLoanPurposeMaster') != null) {
                    if(!payload.containsKey('loanPurposeId') && String.valueOf(payload.get('savedSubProduct')).contains('Flexi')){
                        Product2 loanPurposeRec = new Product2();
                        loanPurposeRec.Name = (String) payload.get('savedLoanPurpose');
                        loanPurposeRec.RecordTypeId = loanPurposeRecordId;
                        loanPurposeRec.Loan_Application__c = oppId;
                        loanPurposeRec.Product_Master__c = (Id) payload.get('savedLoanPurposeMaster');
                        loanPurposeRec.Product__c = (Id) payload.get('subProductId');
                        insert loanPurposeRec;
                    }else{
                        Product2 loanPurposeRec = [
                            SELECT Id, Name, Product_Master__c
                            FROM Product2
                            WHERE Id = :((Id) payload.get('loanPurposeId'))
                            LIMIT 1
                        ];

                        loanPurposeRec.Name = (String) payload.get('savedLoanPurpose');
                        loanPurposeRec.Product_Master__c = (Id) payload.get('savedLoanPurposeMaster');
                        if(payload.get('savedLoanPurpose')!= null){
                            update loanPurposeRec;
                        }
                    }
                    
                }


                // =====================================================
                // ================= UPDATE PROPERTY TYPE ===============
                // =====================================================
                if (payload.containsKey('savedPropertyMaster') && payload.get('savedPropertyMaster') != null) {
                    if(!payload.containsKey('propertyTypeId') && String.valueOf(payload.get('savedSubProduct')).contains('Flexi')){
                        Product2 propertyTypeRec = new Product2();
                        propertyTypeRec.Name = (String) payload.get('savedPropertyType');
                        propertyTypeRec.RecordTypeId = propertyTypeRecordId;
                        propertyTypeRec.Loan_Application__c = oppId;
                        propertyTypeRec.Product_Master__c = (Id) payload.get('savedPropertyMaster');
                        propertyTypeRec.Product__c = (Id) payload.get('subProductId');
                        insert propertyTypeRec;
                    }else{
                        Product2 propertyTypeRec = [
                            SELECT Id, Name, Product_Master__c
                            FROM Product2
                            WHERE Id = :((Id) payload.get('propertyTypeId'))
                            LIMIT 1
                        ];

                        propertyTypeRec.Name = (String) payload.get('savedPropertyType');
                        propertyTypeRec.Product_Master__c = (Id) payload.get('savedPropertyMaster');
                        if(payload.get('savedPropertyType')!= null){
                            update propertyTypeRec;
                        }                        
                    }
                }
            }

            // === SUB PRODUCT UPDATE (already present logic – untouched, but now applies HL overrides if any) ===
            Product2 subProd = [
                SELECT Id, Name, Product_Master__c, Loan_Facility__c, Loan_Purpose__c, Transaction_Type__c,
                    Requested_Loan_Amount__c, Requested_ROI__c,
                    Original_Sanctioned_Amount__c, Financial_Institution_Name__c,
                    Number_of_Installments_Paid__c, Existing_Loan_Start_Date__c,
                    Product__c, Product__r.Id, Product__r.Product_Type__c,
                    Product__r.Name, Product__r.Loan_Application__c
                FROM Product2
                WHERE Id = :subProductId
                LIMIT 1
            ];

            if (subProd == null) return;

            // Apply HL CO overrides to subProd name/master if captured
            if (hlCOUser == true) {
                if (overrideSubProductName != null) {
                    subProd.Name = overrideSubProductName;
                }
                if (overrideSubProductMasterId != null) {
                    subProd.Product_Master__c = overrideSubProductMasterId;
                }
            }
             system.debug('subProd859----'+subProd.Name);
             system.debug('subProd859----'+subProd.Product_Master__c);

            //subProd.Approval_Status__c = (String) payload.get('approvalStatus');
           // subProd.Rejection_Remarks__c = (String) payload.get('rejectionRemarks');
            subProd.Loan_Facility__c = (String) payload.get('loanFacility');

            if (payload.get('requestedLoanAmount') != null && String.isNotBlank(String.valueOf(payload.get('requestedLoanAmount')))) {
                subProd.Requested_Loan_Amount__c = Decimal.valueOf(String.valueOf(payload.get('requestedLoanAmount')));
            }

            if (payload.get('requestedROI') != null && String.isNotBlank(String.valueOf(payload.get('requestedROI')))) {
                subProd.Requested_ROI__c = Decimal.valueOf(String.valueOf(payload.get('requestedROI')));
            }

            Map<Object, Object> btDetailsObj = (Map<Object, Object>) payload.get('btDetails');

            if (btDetailsObj != null) {
                subProd.Original_Sanctioned_Amount__c =
                    btDetailsObj.get('originalSanctionedAmount') != null ?
                    Decimal.valueOf(String.valueOf(btDetailsObj.get('originalSanctionedAmount'))) : null;

                subProd.Number_of_Installments_Paid__c =
                    btDetailsObj.get('numberOfInstallmentsPaid') != null ?
                    Integer.valueOf(String.valueOf(btDetailsObj.get('numberOfInstallmentsPaid'))) : null;

                subProd.Financial_Institution_Name__c =
                    (String) btDetailsObj.get('financialInstitutionName');

                subProd.Existing_Loan_Start_Date__c =
                    String.isNotBlank((String) btDetailsObj.get('existingLoanStartDate')) ?
                    Date.valueOf((String) btDetailsObj.get('existingLoanStartDate')) : null;
            }

            update subProd;

            // === PRODUCT TYPE UPDATE LOGIC (untouched) ===
            if (subProd.Product__c != null && payload.containsKey('productType')) {
                String newProductType = (String) payload.get('productType');

                Product2 productRecord = [
                    SELECT Id, Name, Product_Type__c, Loan_Application__c
                    FROM Product2
                    WHERE Id = :subProd.Product__c
                    LIMIT 1
                ];

                if (productRecord != null && newProductType != null &&
                    productRecord.Product_Type__c != newProductType) {

                    productRecord.Product_Type__c = newProductType;
                    update productRecord;

                    List<Product2> sameNameProds = [
                        SELECT Id, Product_Type__c
                        FROM Product2
                        WHERE Loan_Application__c = :productRecord.Loan_Application__c
                        AND Name = :productRecord.Name
                        AND Id != :productRecord.Id
                        LIMIT 1
                    ];

                    if (!sameNameProds.isEmpty()) {
                        Product2 otherProd = sameNameProds[0];
                        otherProd.Product_Type__c = (newProductType == 'Parent') ? 'Child' : 'Parent';
                        update otherProd;
                    }
                }
            }
            updateProductDetailsOnLoan(oppId);

        } catch (Exception ex) {
            System.debug('Error in updateProductAndSubProduct: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static void saveProductRecord(Map<String, Object> productData) {
        // try {
            System.debug('Received productData: ' + JSON.serialize(productData));

            String loanId = (String) productData.get('loanId');
            Decimal reqLoanAmount = productData.containsKey('reqLoanAmount') && productData.get('reqLoanAmount') != null ? Decimal.valueOf(String.valueOf(productData.get('reqLoanAmount'))): null;
            String loanFacility = (String) productData.get('loanFacility');
            String loanPurpose = (String) productData.get('loanPurpose');
            String transactionType = (String) productData.get('transactionType');
            Decimal originalSanctionedAmount = (productData.containsKey('originalSanctionedAmount') && productData.get('originalSanctionedAmount') != null && String.isNotBlank(String.valueOf(productData.get('originalSanctionedAmount')).trim()))? Decimal.valueOf(String.valueOf(productData.get('originalSanctionedAmount')).trim()): null;
            Date existingLoanStartDate = (productData.containsKey('existingLoanStartDate') && productData.get('existingLoanStartDate') != null && String.isNotBlank(String.valueOf(productData.get('existingLoanStartDate')).trim()))? (productData.get('existingLoanStartDate') instanceof Date ? (Date)productData.get('existingLoanStartDate'): (String.valueOf(productData.get('existingLoanStartDate')).trim().length() == 10 ? Date.valueOf(String.valueOf(productData.get('existingLoanStartDate')).trim()): null)): null;

            Integer numberOfInstallmentsPaid = (productData.containsKey('numberOfInstallmentsPaid') && productData.get('numberOfInstallmentsPaid') != null && String.isNotBlank(String.valueOf(productData.get('numberOfInstallmentsPaid')).trim()))? Integer.valueOf(String.valueOf(productData.get('numberOfInstallmentsPaid')).trim()): null;
            String financialInstitutionName = (String) productData.get('financialInstitutionName');
            Decimal requestedROI = productData.containsKey('requestedROI') && productData.get('requestedROI') != null ? Decimal.valueOf(String.valueOf(productData.get('requestedROI'))): null;

            Map<String, Object> productMap = (productData.containsKey('product') && productData.get('product') != null) 
                ? (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(productData.get('product'))) 
                : new Map<String, Object>();

            Map<String, Object> subProductMap = (productData.containsKey('subProduct') && productData.get('subProduct') != null) 
                ? (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(productData.get('subProduct'))) 
                : new Map<String, Object>();

            Map<String, Object> variantMap = (productData.containsKey('variant') && productData.get('variant') != null) 
                ? (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(productData.get('variant'))) 
                : new Map<String, Object>();

            Map<String, Object> subVariantMap = (productData.containsKey('subVariant') && productData.get('subVariant') != null) 
                ? (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(productData.get('subVariant'))) 
                : new Map<String, Object>();

            Map<String, Object> hybridTenure = (productData.containsKey('hybridTenure') && productData.get('hybridTenure') != null) 
                ? (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(productData.get('hybridTenure'))) 
                : new Map<String, Object>();

            Map<String, Object> schemeMap = (productData.containsKey('scheme') && productData.get('scheme') != null) 
                ? (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(productData.get('scheme'))) 
                : new Map<String, Object>();
            
            Map<String, Object> fullEMIMap = (productData.containsKey('fullEMI') && productData.get('fullEMI') != null) 
                ? (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(productData.get('fullEMI'))) 
                : new Map<String, Object>();

            Map<String, Object> totalTenureMap = (productData.containsKey('totalTenure') && productData.get('totalTenure') != null) 
                ? (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(productData.get('totalTenure'))) 
                : new Map<String, Object>();
            
            Map<String, Object> transactionTypeMap = (productData.containsKey('transaction') && productData.get('transaction') != null) 
                ? (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(productData.get('transaction'))) 
                : new Map<String, Object>();

            Map<String, Object> purposeLoanMap = (productData.containsKey('purposeLoan') && productData.get('purposeLoan') != null) 
                ? (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(productData.get('purposeLoan'))) 
                : new Map<String, Object>();

            Map<String, Object> propertyTypeMap = (productData.containsKey('propertyType') && productData.get('propertyType') != null) 
                ? (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(productData.get('propertyType'))) 
                : new Map<String, Object>();

            String productId = productMap.containsKey('prodId') ? String.valueOf(productMap.get('prodId')) : null;
            String productName = productMap.containsKey('name') ? String.valueOf(productMap.get('name')) : null;

            String subProductId = subProductMap.containsKey('prodId') ? String.valueOf(subProductMap.get('prodId')) : null;
            String subProductName = subProductMap.containsKey('name') ? String.valueOf(subProductMap.get('name')) : null;

            String variantId = variantMap.containsKey('prodId') ? String.valueOf(variantMap.get('prodId')) : null;
            String variantName = variantMap.containsKey('name') ? String.valueOf(variantMap.get('name')) : null;

            String subVariantId = subVariantMap.containsKey('prodId') ? String.valueOf(subVariantMap.get('prodId')) : null;
            String subVariantName = subVariantMap.containsKey('name') ? String.valueOf(subVariantMap.get('name')) : null;

           // String hybridTenureId = hybridTenure.containsKey('prodId') ? String.valueOf(hybridTenure.get('prodId')) : null;
            String hybridTenureName = hybridTenure.containsKey('name') ? String.valueOf(hybridTenure.get('name')) : null;

            String schemeId = schemeMap.containsKey('prodId') ? String.valueOf(schemeMap.get('prodId')) : null;
            String schemeName = schemeMap.containsKey('name') ? String.valueOf(schemeMap.get('name')) : null;

           // String fullEMIId = fullEMIMap.containsKey('prodId') ? String.valueOf(fullEMIMap.get('prodId')) : null;
            String fullEMIName = fullEMIMap.containsKey('name') ? String.valueOf(fullEMIMap.get('name')) : null;

           // String totalTenureId = totalTenureMap.containsKey('prodId') ? String.valueOf(totalTenureMap.get('prodId')) : null;
            String totalTenureName = totalTenureMap.containsKey('name') ? String.valueOf(totalTenureMap.get('name')) : null;

            String repaymentFacility = schemeMap.containsKey('repaymentFacility') ? String.valueOf(schemeMap.get('repaymentFacility')) : null;

            Boolean disabledProduct = (Boolean) productData.get('isDisabledProduct'); 
            Boolean isVasOnly= (Boolean) productData.get('isVasOnly');

            String transactionTypeId = transactionTypeMap.containsKey('prodId') ? String.valueOf(transactionTypeMap.get('prodId')) : null;
            String transactionTypeName = transactionTypeMap.containsKey('name') ? String.valueOf(transactionTypeMap.get('name')) : null;

            String propertyTypeId = propertyTypeMap.containsKey('prodId') ? String.valueOf(propertyTypeMap.get('prodId')) : null;
            String propertyTypeName = propertyTypeMap.containsKey('name') ? String.valueOf(propertyTypeMap.get('name')) : null;

            String purposeLoanId = purposeLoanMap.containsKey('prodId') ? String.valueOf(purposeLoanMap.get('prodId')) : null;
            String purposeLoanName = purposeLoanMap.containsKey('name') ? String.valueOf(purposeLoanMap.get('name')) : null;
            String moratDuration = ((productData.containsKey('moratDuration') && productData.get('moratDuration') != null)) ? String.valueOf(productData.get('moratDuration')): '';

            System.debug('Product ID: ' + productId + ' | Product Name: ' + productName);
            System.debug('SubProduct ID: ' + subProductId + ' | SubProduct Name: ' + subProductName);
            System.debug('Scheme ID: ' + schemeId + ' | Scheme Name: ' + schemeName + ' | Repayment Facility: ' + repaymentFacility);
            System.debug('subVariantName--'+ subVariantName);
            System.debug('hybridTenureName--'+ hybridTenureName);
            System.debug('fullEMIName--'+ fullEMIName);
            System.debug('totalTenureName--'+ totalTenureName);

            Id productRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
            Id subProductRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();
            Id variantRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Variant').getRecordTypeId();
            Id subVariantRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Variant').getRecordTypeId();
            Id hybridTenureRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Hybrid Tenure').getRecordTypeId();
            Id productSchemeRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Scheme').getRecordTypeId();
            Id fullEMIRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Full EMI').getRecordTypeId();
            Id totalTenureRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Total Tenure').getRecordTypeId();
            Id transactionTypeRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Transaction Type').getRecordTypeId();
            Id loanPurposeRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Loan Purpose').getRecordTypeId();
            Id propertyTypeRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Property Type').getRecordTypeId();

            Product2 prodRecord;
            Product2 subProdRecord;
            Product2 variant;
            Product2 subVariant;
            Product2 totalTenure;
            Product2 fullEMI;
            Product2 transactionTypeRec;
            Product2 loanPurposeRec;
            List<Product2> productRecord;

            System.debug('subProductId: '+subProductId);
            List<Product_Master__c> prodMaster = [SELECT Id, Min_ROI__c,MAX_ROI__c, Min_Loan_Amount__c, Max_Loan_Amount__c, Min_Tenure_in_years__c, Max_Tenure__c, 
                                                    PLR_Code__c, PLR_Value__c, Interest_Days_Basis__c, BPI_Interest_Days_Basis__c, Product__r.HL_Maximum_LTV_as_per_Policy_1__c, 
                                                    Product__r.HL_Maximum_LTV_as_per_Policy_2__c, Product__r.HL_Maximum_LTV_as_per_Policy_3__c
                                                    FROM Product_Master__c WHERE Id =: subProductId LIMIT 1];
                                                    
            System.debug('prodMaster: '+prodMaster[0]);

            // List<Product2> productRecord = [SELECT Id, RecordTypeId, Loan_Application__c, Product_Master__c FROM Product2 WHERE RecordTypeId = :productId AND Loan_Application__c = :loanId LIMIT 1];
            if(disabledProduct == false) {
                System.debug('disable prod false');
                productRecord = [SELECT Id, RecordTypeId, Loan_Application__c, Product_Master__c FROM Product2 WHERE RecordTypeId = :productId AND Loan_Application__c = :loanId LIMIT 1];
            } else {
                System.debug('disable prod true');
                productRecord = [SELECT Id, RecordTypeId, Loan_Application__c, Product_Master__c FROM Product2 WHERE RecordTypeId = :productRecordId AND Loan_Application__c = :loanId LIMIT 1];
            }
            if (!productRecord.isEmpty()) {
                prodRecord = productRecord[0];
                prodRecord.Name = productName;
                prodRecord.RecordTypeId = productRecordId;
                prodRecord.Loan_Application__c = loanId;
                prodRecord.Product_Master__c = productId;
                prodRecord.Is_loan_VAS_only__c = isVasOnly;
                prodRecord.HL_Maximum_LTV_as_per_Policy_1__c = prodMaster[0].Product__r.HL_Maximum_LTV_as_per_Policy_1__c;
                prodRecord.HL_Maximum_LTV_as_per_Policy_2__c = prodMaster[0].Product__r.HL_Maximum_LTV_as_per_Policy_2__c;
                prodRecord.HL_Maximum_LTV_as_per_Policy_3__c = prodMaster[0].Product__r.HL_Maximum_LTV_as_per_Policy_3__c;
                update prodRecord;
            } else {
                prodRecord = new Product2();
                prodRecord.Name = productName;
                prodRecord.RecordTypeId = productRecordId;
                prodRecord.Loan_Application__c = loanId;
                prodRecord.Product_Master__c = productId;
                prodRecord.Is_loan_VAS_only__c = isVasOnly;
                prodRecord.HL_Maximum_LTV_as_per_Policy_1__c = prodMaster[0].Product__r.HL_Maximum_LTV_as_per_Policy_1__c;
                prodRecord.HL_Maximum_LTV_as_per_Policy_2__c = prodMaster[0].Product__r.HL_Maximum_LTV_as_per_Policy_2__c;
                prodRecord.HL_Maximum_LTV_as_per_Policy_3__c = prodMaster[0].Product__r.HL_Maximum_LTV_as_per_Policy_3__c;
                // prodRecord.ProductCode = randomNo;
                insert prodRecord;
            }
            
            List<Product2> subProductRecord = [SELECT Id, RecordTypeId,Requested_Loan_Amount__c,Existing_Loan_Start_Date__c,Number_of_Installments_Paid__c,Financial_Institution_Name__c,Original_Sanctioned_Amount__c, Loan_Application__c, Product_Master__c, Product__c, Min_ROI__c, MAX_ROI__c, Min_Loan_Amount__c, Max_Loan_Amount__c, Min_Tenure_in_years__c, Max_Tenure__c, PLR_Code__c, PLR_Value__c FROM Product2 WHERE RecordTypeId = :subProductId AND Loan_Application__c = :loanId LIMIT 1];
            if (!subProductRecord.isEmpty()) {
                subProdRecord = subProductRecord[0];
                subProdRecord.Name = subProductName;
                subProdRecord.RecordTypeId = subProductRecordId;
                subProdRecord.Loan_Application__c = loanId;
                subProdRecord.Product_Master__c = subProductId;
                subProdRecord.Product__c = prodRecord.Id;
                subProdRecord.Min_ROI__c = prodMaster[0].Min_ROI__c;
                subProdRecord.MAX_ROI__c = prodMaster[0].MAX_ROI__c;
                subProdRecord.Min_Loan_Amount__c = prodMaster[0].Min_Loan_Amount__c;
                subProdRecord.Max_Loan_Amount__c = prodMaster[0].Max_Loan_Amount__c;
                subProdRecord.Min_Tenure_in_years__c = prodMaster[0].Min_Tenure_in_years__c;
                subProdRecord.Max_Tenure__c = prodMaster[0].Max_Tenure__c;
                subProdRecord.PLR_Code__c = prodMaster[0].PLR_Code__c;
                subProdRecord.PLR_Value__c = prodMaster[0].PLR_Value__c;
                subProdRecord.Interest_Days_Basis__c = prodMaster[0].Interest_Days_Basis__c;
                subProdRecord.BPI_Interest_Days_Basis__c = prodMaster[0].BPI_Interest_Days_Basis__c;
                subProdRecord.Requested_Loan_Amount__c = reqLoanAmount;
                subProdRecord.Loan_Facility__c = loanFacility;
                subProdRecord.Loan_Purpose__c = loanPurpose;
                subProdRecord.Transaction_Type__c = transactionType;
                subProdRecord.Requested_ROI__c = requestedROI;
                subProdRecord.Original_Sanctioned_Amount__c = originalSanctionedAmount;
                subProdRecord.Financial_Institution_Name__c = financialInstitutionName;
                subProdRecord.Number_of_Installments_Paid__c = numberOfInstallmentsPaid;
                subProdRecord.Existing_Loan_Start_Date__c = existingLoanStartDate;
                update subProdRecord;
            } else {
                subProdRecord = new Product2();
                subProdRecord.Name = subProductName;
                subProdRecord.RecordTypeId = subProductRecordId;
                subProdRecord.Loan_Application__c = loanId;
                subProdRecord.Product_Master__c = subProductId;
                subProdRecord.Product__c = prodRecord.Id; 
                subProdRecord.Min_ROI__c = prodMaster[0].Min_ROI__c;
                subProdRecord.MAX_ROI__c = prodMaster[0].MAX_ROI__c;
                subProdRecord.Min_Loan_Amount__c = prodMaster[0].Min_Loan_Amount__c;
                subProdRecord.Max_Loan_Amount__c = prodMaster[0].Max_Loan_Amount__c;
                subProdRecord.Min_Tenure_in_years__c = prodMaster[0].Min_Tenure_in_years__c;
                subProdRecord.Max_Tenure__c = prodMaster[0].Max_Tenure__c;
                subProdRecord.PLR_Code__c = prodMaster[0].PLR_Code__c;
                subProdRecord.PLR_Value__c = prodMaster[0].PLR_Value__c;
                subProdRecord.Interest_Days_Basis__c = prodMaster[0].Interest_Days_Basis__c;
                subProdRecord.BPI_Interest_Days_Basis__c = prodMaster[0].BPI_Interest_Days_Basis__c;
                subProdRecord.Requested_Loan_Amount__c = reqLoanAmount;
                subProdRecord.Loan_Facility__c = loanFacility;
                subProdRecord.Requested_ROI__c = requestedROI;
                subProdRecord.Loan_Purpose__c = loanPurpose;
                subProdRecord.Transaction_Type__c = transactionType;
                subProdRecord.Original_Sanctioned_Amount__c = originalSanctionedAmount;
                subProdRecord.Financial_Institution_Name__c = financialInstitutionName;
                subProdRecord.Number_of_Installments_Paid__c = numberOfInstallmentsPaid;
                subProdRecord.Existing_Loan_Start_Date__c = existingLoanStartDate;
                insert subProdRecord;
            }
            updateRequestedAmount(loanId);
            Map<String,String> inputMapUtility = new  Map<String,String>();
        Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
        Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
        if(isHlRelated){
            List<Product2> transactionRecord = [SELECT Id, Repayment_Facility__c, RecordTypeId, Loan_Application__c, Product_Master__c, Product__c FROM Product2 WHERE Id = :transactionTypeId AND Loan_Application__c = :loanId LIMIT 1];
            if (!transactionRecord.isEmpty()) {
                transactionTypeRec = transactionRecord[0];
                transactionTypeRec.RecordTypeId = transactionTypeRecordId;
                transactionTypeRec.Loan_Application__c = loanId;
                transactionTypeRec.Product_Master__c = transactionTypeId;
                transactionTypeRec.Product__c = subProdRecord.Id;
                update transactionTypeRec;
            } else {
                transactionTypeRec = new Product2();
                transactionTypeRec.Name = transactionTypeName;
                transactionTypeRec.RecordTypeId = transactionTypeRecordId;
                transactionTypeRec.Loan_Application__c = loanId;
                transactionTypeRec.Product_Master__c = transactionTypeId;
                transactionTypeRec.Product__c = subProdRecord.Id;
                insert transactionTypeRec;
            }

            List<Product2> loanPurposeRecord = [SELECT Id, Repayment_Facility__c, RecordTypeId, Loan_Application__c, Product_Master__c, Product__c FROM Product2 WHERE Id = :purposeLoanId AND Loan_Application__c = :loanId LIMIT 1];
            if (!loanPurposeRecord.isEmpty()) {
                loanPurposeRec = loanPurposeRecord[0];
                loanPurposeRec.RecordTypeId = loanPurposeRecordId;
                loanPurposeRec.Loan_Application__c = loanId;
                loanPurposeRec.Product_Master__c = purposeLoanId;
                loanPurposeRec.Product__c = subProdRecord.Id;
                update loanPurposeRec;
            } else {
                loanPurposeRec = new Product2();
                loanPurposeRec.Name = purposeLoanName;
                loanPurposeRec.RecordTypeId = loanPurposeRecordId;
                loanPurposeRec.Loan_Application__c = loanId;
                loanPurposeRec.Product_Master__c = purposeLoanId;
                loanPurposeRec.Product__c = subProdRecord.Id;
                insert loanPurposeRec;
            }

            List<Product2> propertyTypeRecord = [SELECT Id, Repayment_Facility__c, RecordTypeId, Loan_Application__c, Product_Master__c, Product__c FROM Product2 WHERE Id = :propertyTypeId AND Loan_Application__c = :loanId LIMIT 1];
            if (!propertyTypeRecord.isEmpty()) {
                // Note: This was incorrectly assigning loanPurposeRec to propertyTypeRecord
                Product2 propertyTypeRec = propertyTypeRecord[0];
                propertyTypeRec.RecordTypeId = propertyTypeRecordId;
                propertyTypeRec.Loan_Application__c = loanId;
                propertyTypeRec.Product_Master__c = propertyTypeId;
                propertyTypeRec.Product__c = subProdRecord.Id;
                update propertyTypeRec;
            } else {
                Product2 propertyTypeRec = new Product2();
                propertyTypeRec.Name = propertyTypeName;
                propertyTypeRec.RecordTypeId = propertyTypeRecordId;
                propertyTypeRec.Loan_Application__c = loanId;
                propertyTypeRec.Product_Master__c = propertyTypeId;
                propertyTypeRec.Product__c = subProdRecord.Id;
                insert propertyTypeRec;
            }
        }
            List<Product_Master__c> prodVariantMaster = [SELECT Id, Min_ROI__c,MAX_ROI__c, Min_Loan_Amount__c, Max_Loan_Amount__c, Min_Tenure_in_years__c, Max_Tenure__c, PLR_Code__c, PLR_Value__c, Interest_Days_Basis__c, BPI_Interest_Days_Basis__c FROM Product_Master__c WHERE Id = :variantId LIMIT 1];
            List<Product2> variantRecord = [SELECT Id, Repayment_Facility__c, RecordTypeId, Loan_Application__c, Product_Master__c, Product__c FROM Product2 WHERE Id = :variantId AND Loan_Application__c = :loanId LIMIT 1];
            if (!variantRecord.isEmpty()) {
                variant = variantRecord[0];
                variant.RecordTypeId = variantRecordId;
                variant.Loan_Application__c = loanId;
                variant.Product_Master__c = variantRecordId;
                variant.Product__c = subProdRecord.Id;
                variant.PLR_Code__c = prodVariantMaster[0].PLR_Code__c;
                variant.PLR_Value__c = prodVariantMaster[0].PLR_Value__c;
                variant.Interest_Days_Basis__c = prodVariantMaster[0].Interest_Days_Basis__c;
                variant.BPI_Interest_Days_Basis__c = prodVariantMaster[0].BPI_Interest_Days_Basis__c;
                update variant;
            } else {
                variant = new Product2();
                variant.Name = variantName;
                variant.RecordTypeId = variantRecordId;
                variant.Loan_Application__c = loanId;
                variant.Product_Master__c = variantId;
                variant.Product__c = subProdRecord.Id;
                variant.PLR_Code__c = prodVariantMaster[0].PLR_Code__c;
                variant.PLR_Value__c = prodVariantMaster[0].PLR_Value__c;
                variant.Interest_Days_Basis__c = prodVariantMaster[0].Interest_Days_Basis__c;
                variant.BPI_Interest_Days_Basis__c = prodVariantMaster[0].BPI_Interest_Days_Basis__c;
                // schemeProdRecord.ProductCode = randomNo;
                insert variant;
            }

            List<Product2> subVariantRecord = [SELECT Id, Repayment_Facility__c, RecordTypeId, Loan_Application__c, Product_Master__c, Product__c FROM Product2 WHERE Id = :subVariantId AND Loan_Application__c = :loanId LIMIT 1];
            if (!subVariantRecord.isEmpty()) {
                subVariant = subVariantRecord[0];
                subVariant.RecordTypeId = subVariantRecordId;
                subVariant.Loan_Application__c = loanId;
                subVariant.Product_Master__c = subVariantId;
                subVariant.Product__c = subProdRecord.Id;
                subVariant.Variant__c = variant.Id;
                subVariant.HL_Moratorium_Period__c = moratDuration;
                update subVariant;
            } else {
                subVariant = new Product2();
                subVariant.Name = subVariantName;
                subVariant.RecordTypeId = subVariantRecordId;
                subVariant.Loan_Application__c = loanId;
                subVariant.Product_Master__c = subVariantId;
                subVariant.Product__c = subProdRecord.Id;
                subVariant.Variant__c = variant.Id;
                subVariant.HL_Moratorium_Period__c = moratDuration;
                // schemeProdRecord.ProductCode = randomNo;
                insert subVariant;
            }

            List<Product2> hybridTenureRecord = [SELECT Id, Repayment_Facility__c, RecordTypeId, Loan_Application__c, Product_Master__c, Product__c FROM Product2 WHERE Name = :hybridTenureName  AND Product__c =:subProdRecord.Id AND Variant__c =: variant.Id AND Sub_Variant__c =: subVariant.Id AND Loan_Application__c = :loanId LIMIT 1];
            if (!hybridTenureRecord.isEmpty()) {
                Product2 hydbridTenure = hybridTenureRecord[0];
                hydbridTenure.RecordTypeId = hybridTenureRecordId;
                hydbridTenure.Loan_Application__c = loanId;
               // hydbridTenure.Product_Master__c = hybridTenureId;
                hydbridTenure.Product__c = subVariant.Id;
                hydbridTenure.Variant__c = variant.Id;
                hydbridTenure.Sub_Variant__c = subVariant.Id;
                update hydbridTenure;
            } else {
                Product2 hydbridTenure = new Product2();
                hydbridTenure.Name = hybridTenureName;
                hydbridTenure.RecordTypeId = hybridTenureRecordId;
                hydbridTenure.Loan_Application__c = loanId;
               // hydbridTenure.Product_Master__c = hybridTenureId;
                hydbridTenure.Product__c = subVariant.Id;
                hydbridTenure.Variant__c = variant.Id;
                hydbridTenure.Sub_Variant__c = subVariant.Id;
                insert hydbridTenure;
            }

            List<Product2> schemeRecord = [SELECT Id, Repayment_Facility__c, RecordTypeId, Loan_Application__c, Product_Master__c, Product__c FROM Product2 WHERE Id = :schemeId AND Loan_Application__c = :loanId LIMIT 1];
            if (!schemeRecord.isEmpty()) {
                Product2 schemeProdRecord = schemeRecord[0];
                // schemeProdRecord.Repayment_Facility__c = repaymentFacility;
                schemeProdRecord.RecordTypeId = productSchemeRecordId;
                schemeProdRecord.Loan_Application__c = loanId;
                schemeProdRecord.Product_Master__c = schemeId;
                schemeProdRecord.Product__c = subProdRecord.Id;
                schemeProdRecord.Variant__c = variant.Id;
                schemeProdRecord.Sub_Variant__c = subVariant.Id;
                update schemeProdRecord;
            } else {
                Product2 schemeProdRecord = new Product2();
                schemeProdRecord.Name = schemeName;
                schemeProdRecord.Repayment_Facility__c = repaymentFacility;
                schemeProdRecord.RecordTypeId = productSchemeRecordId;
                schemeProdRecord.Loan_Application__c = loanId;
                schemeProdRecord.Product_Master__c = schemeId;
                schemeProdRecord.Product__c = subProdRecord.Id;
                schemeProdRecord.Variant__c = variant.Id;
               schemeProdRecord.Sub_Variant__c = subVariant.Id;
                // schemeProdRecord.ProductCode = randomNo;
                insert schemeProdRecord;
            }

            List<Product2> fullEMIRecord = [SELECT Id, Repayment_Facility__c, RecordTypeId, Loan_Application__c, Product_Master__c, Product__c FROM Product2 WHERE Name = :fullEMIName  AND Product__c =:subProdRecord.Id AND Variant__c =: variant.Id AND Sub_Variant__c =: subVariant.Id AND Loan_Application__c = :loanId LIMIT 1];
            if (!fullEMIRecord.isEmpty()) {
                Product2 fullEMIProdRecord = fullEMIRecord[0];
                fullEMIProdRecord.RecordTypeId = fullEMIRecordId;
                fullEMIProdRecord.Loan_Application__c = loanId;
                //fullEMIProdRecord.Product_Master__c = fullEMIId;
                fullEMIProdRecord.Product__c = subProdRecord.Id;
                fullEMIProdRecord.Variant__c = variant.Id;
                fullEMIProdRecord.Sub_Variant__c = subVariant.Id;
                update fullEMIProdRecord;
            } else {
                Product2 fullEMIProdRecord = new Product2();
                fullEMIProdRecord.Name = fullEMIName;
                fullEMIProdRecord.RecordTypeId = fullEMIRecordId;
                fullEMIProdRecord.Loan_Application__c = loanId;
               // fullEMIProdRecord.Product_Master__c = fullEMIId;
                fullEMIProdRecord.Product__c = subProdRecord.Id;
                fullEMIProdRecord.Variant__c = variant.Id;
                fullEMIProdRecord.Sub_Variant__c = subVariant.Id;
                insert fullEMIProdRecord;
            }

            List<Product2> totalTenureRecords = [SELECT Id, Repayment_Facility__c, RecordTypeId, Loan_Application__c, Product_Master__c, Product__c FROM Product2 WHERE Name = :totalTenureName AND Product__c =:subProdRecord.Id AND Variant__c =: variant.Id AND Sub_Variant__c =: subVariant.Id  AND Loan_Application__c = :loanId AND RecordTypeId =: totalTenureRecordId LIMIT 1];
            if (!totalTenureRecords.isEmpty()) {
                Product2 totalTenureRecord = totalTenureRecords[0];
                totalTenureRecord.RecordTypeId = totalTenureRecordId;
                totalTenureRecord.Loan_Application__c = loanId;
               // totalTenureRecord.Product_Master__c = totalTenureId;
                totalTenureRecord.Product__c = subProdRecord.Id;
                totalTenureRecord.Variant__c = variant.Id;
                totalTenureRecord.Sub_Variant__c = subVariant.Id;
                update totalTenureRecord;
            } else {
                Product2 totalTenureRecord = new Product2();
                totalTenureRecord.Name = totalTenureName;
                totalTenureRecord.RecordTypeId = totalTenureRecordId;
                totalTenureRecord.Loan_Application__c = loanId;
                //totalTenureRecord.Product_Master__c = totalTenureId;
                totalTenureRecord.Product__c = subProdRecord.Id;
                totalTenureRecord.Variant__c = variant.Id;
                totalTenureRecord.Sub_Variant__c = subVariant.Id;
                insert totalTenureRecord;
            }
             updateProductTypes(loanId);

        // } catch (Exception e) {
        //     System.debug('Error in saveProductRecord: ' + e.getMessage());
        //     throw new AuraHandledException('Error saving product details: ' + e.getMessage());
        // }
    }


    @AuraEnabled
    public static string deleteProduct(String loanId, String prod) {
        Map<String,String> inputMapUtility = new  Map<String,String>();
        Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
        Boolean isHlRelated =isHLRelatedFinal.isHLRelated;
        //HL-Ishi-10/10/2025
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Product2.getRecordTypeInfosByName();
        Id productRecordTypeId       = rtMap.get('Product').getRecordTypeId();
        Id subProductRecordTypeId    = rtMap.get('Sub Product').getRecordTypeId();
        Id totalTenureRecordTypeId   = rtMap.get('Total Tenure').getRecordTypeId();
        Id schemeRecordTypeId        = rtMap.get('Scheme').getRecordTypeId();
        Id fullEMIRecordTypeId       = rtMap.get('Full EMI').getRecordTypeId();
        Id hybridTenureRecordId      = rtMap.get('Hybrid Tenure').getRecordTypeId();
        String status = 'Deletion Process';
        Set<Id> productIdsToDelete = new Set<Id>();
        Id subVariantId;
        Boolean allowDelete = true;
        List<Product2> subProductList = [SELECT Id, Product__r.Name FROM Product2 WHERE Product__c = :prod AND RecordTypeId = :subProductRecordTypeId 
                                        AND Loan_Application__c = :loanId LIMIT 1];
        List<Product2> mainprod = [SELECT Id, Product__r.Name FROM Product2 WHERE id = :prod AND RecordType.Name = 'Product' 
                                        AND Loan_Application__c = :loanId and Product_Type__c='Parent' LIMIT 1];
        if(isHLRelated && mainprod.size()>0){
             status = 'HL restricted deletion';
             return status;
        }
        if (!subProductList.isEmpty()) {
            if (subProductList[0].Product__r.Name == 'BL') {
                List<Product2> prodList = [SELECT Id FROM Product2 WHERE Loan_Application__c =: loanId AND RecordTypeId=: productRecordTypeId];
                System.debug('prodList.size: '+prodList.size());
                if (prodList.size() > 1) {
                    allowDelete = false;
                }
            }
            if (allowDelete == true) {
                Product2 subProduct = subProductList[0];

                productIdsToDelete.add(prod);
                productIdsToDelete.add(subProduct.Id);

                List<Product2> relatedProducts = [SELECT Id, RecordTypeId, Variant__c, Sub_Variant__c FROM Product2 WHERE Loan_Application__c = :loanId
                                                    AND RecordTypeId IN :new List<Id>{totalTenureRecordTypeId, schemeRecordTypeId, fullEMIRecordTypeId} AND Product__c = :subProduct.Id];

                for (Product2 prd : relatedProducts) {
                    productIdsToDelete.add(prd.Id);

                    if (prd.RecordTypeId == totalTenureRecordTypeId) {
                        if (prd.Variant__c != null) {
                            productIdsToDelete.add(prd.Variant__c);
                        }
                        if (prd.Sub_Variant__c != null) {
                            productIdsToDelete.add(prd.Sub_Variant__c);
                            subVariantId = prd.Sub_Variant__c;
                        }
                    }
                }

                if (subVariantId != null) {
                    List<Product2> hybridTenureList = [SELECT Id FROM Product2 WHERE RecordTypeId = :hybridTenureRecordId AND Product__c = :subVariantId LIMIT 1];
                    if (!hybridTenureList.isEmpty()) {
                        productIdsToDelete.add(hybridTenureList[0].Id);
                    }
                }
                if (!productIdsToDelete.isEmpty()) {
                    List<Product2> productsToDelete = [SELECT Id FROM Product2 WHERE Id IN :productIdsToDelete];
                    status = 'Success';
                    
                    List<Opportunity> chileProd = [SELECT id,stageName FROM Opportunity WHERE Split_Parent_Loan_Application__c =:loanId];
                    if(chileProd.size() > 0) {
                        List<Product2> prodList = [SELECT Id,Loan_Application__c FROM Product2 WHERE Clone_From_Product__c =:prod];
                        if(prodList.size() > 0 ) {
                            Opportunity oppRec = new Opportunity();
                            oppRec.id = prodList[0].Loan_Application__c;
                            oppRec.stageName = 'Abandoned';
                            update oppRec;
                        }
                    }
                    delete productsToDelete;
                }
            } else {
                status = 'AH restricted';
            }
        }
        updateRequestedAmount(loanId);
        updateProductTypes(loanId);
        return status;
    }


@AuraEnabled
public static void updateProductTypes(String loanId) {
    try {
        List<Product2> productsToUpdate = [
            SELECT Id, Name, Product_Type__c, CreatedDate
            FROM Product2
            WHERE Loan_Application__c = :loanId
            AND RecordType.Name = 'Product'
            ORDER BY CreatedDate ASC
        ];

        if (productsToUpdate.isEmpty()) return;

        // HL-related user
        Map<String,String> inputMapUtility = new Map<String,String>();
        Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
        Boolean isHlRelated = isHLRelatedFinal.isHLRelated;

        // Determine Parent product names
        String homeParentName = isHlRelated ? 'Home Loan' : 'Affordable Home Loan';
        String nonHomeParentName = 'Affordable Non-Home Loan';

        // Group products by Name
        Map<String, List<Product2>> productsByName = new Map<String, List<Product2>>();
        for (Product2 p : productsToUpdate) {
            if (!productsByName.containsKey(p.Name)) {
                productsByName.put(p.Name, new List<Product2>());
            }
            productsByName.get(p.Name).add(p);
        }

        // Check if any Home/Affordable Home exists
        Boolean anyHomeExists = productsByName.containsKey(homeParentName);

        for (String prodName : productsByName.keySet()) {
            List<Product2> recordsByName = productsByName.get(prodName);

            // Count existing Parents in this group
            List<Product2> existingParents = new List<Product2>();
            for (Product2 p : recordsByName) {
                if (p.Product_Type__c == 'Parent') existingParents.add(p);
            }

            if (existingParents.size() > 1) {
                // Skip this group if more than one Parent exists
                continue;
            }

            Product2 recordToParent;

            if (!anyHomeExists) {
                // No Home exists → normal rules apply
                if (existingParents.size() == 1) {
                    recordToParent = existingParents[0];
                } else {
                    // Pick Parent according to rules
                    if (prodName == homeParentName) {
                        recordToParent = recordsByName[0];
                    } else if (prodName == nonHomeParentName) {
                        recordToParent = recordsByName[0];
                    } else {
                        recordToParent = null;
                    }
                }
            } else {
                // Home exists → only Home/Affordable Home can be Parent
                if (prodName == homeParentName) {
                    if (existingParents.size() == 1) {
                        recordToParent = existingParents[0];
                    } else {
                        recordToParent = recordsByName[0]; // make Home record Parent
                    }
                } else {
                    // Any Non-Home product → cannot be Parent
                    recordToParent = null;
                }
            }

            // Assign Parent/Child
            for (Product2 p : recordsByName) {
                if (recordToParent != null && p.Id == recordToParent.Id) {
                    p.Product_Type__c = 'Parent';
                } else {
                    p.Product_Type__c = 'Child';
                }
            }
        }

        if (!productsToUpdate.isEmpty()) {
            update productsToUpdate;
            updateProductDetailsOnLoan(loanId);
        }

    } catch (Exception ex) {
        System.debug('Unexpected Exception: ' + ex.getMessage());
    }
}

    
    @AuraEnabled
    public static void updateProductDetailsOnLoan(String loanId) {
        List<Product2> productsToUpdate = [SELECT Id, Loan_Purpose__c,Product__r.name FROM Product2 
                                           WHERE Loan_Application__c = :loanId AND RecordType.Name = 'Sub Product' AND
                                           Product__r.Product_Type__c = 'Parent' ORDER BY CreatedDate ASC ];

        Map<String,String> inputMapUtility = new Map<String,String>();
        Utility_V1.ProductWrapper isHLRelatedFinal  = Utility_V1.checkIfLoggedInUserIsHLRelated(inputMapUtility);
        Boolean isHlRelated =isHLRelatedFinal.isHLRelated;

        if(productsToUpdate.size() > 0) {
            List<Opportunity> opp = [SELECT id,Product__c,Loan_Purpose__c FROM Opportunity WHERE id =: loanId];
            if(opp.size() > 0) {
                Boolean isUpdate = false;
                if(opp[0].Product__c != productsToUpdate[0].Product__r.name) {
                    opp[0].Product__c = productsToUpdate[0].Product__r.name;
                    isUpdate = true;
                }
                if(!isHlRelated){
                    if(opp[0].Loan_Purpose__c != productsToUpdate[0].Loan_Purpose__c) {
                        opp[0].Loan_Purpose__c = productsToUpdate[0].Loan_Purpose__c;
                        isUpdate = true;
                    }
                }else if(isHlRelated){
                    List<Product2> productsPurpose = [SELECT Id, Name, Loan_Purpose__c,Product__r.name FROM Product2 
                                           WHERE Loan_Application__c = :loanId AND RecordType.Name = 'Loan Purpose' AND Product__c = :productsToUpdate[0].Id];
                    if(productsPurpose.size() > 0 && opp[0].Loan_Purpose__c != productsPurpose[0].Name) {
                        opp[0].Loan_Purpose__c = productsPurpose[0].Name;
                        isUpdate = true;
                    }
                }
                
                if(isUpdate) {
                    update opp;
                }
                
            }
            
        }
        
    }


    @AuraEnabled
    public static Map<String, String> getPendingProduct(String loanId) {
        Map<String, String> productDetails = new Map<String, String>();
        try {
            List<Product2> products = [SELECT Id, Product_Master__c, Product_Master__r.Name FROM Product2 WHERE Loan_Application__c = :loanId  LIMIT 1]; // AND Name ='Business Loan'
            if (!products.isEmpty()) {
                Product2 product = products[0];
                productDetails.put('productMasterId', product.Product_Master__c);
                productDetails.put('productName', product.Product_Master__r.Name != null ? product.Product_Master__r.Name : null);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving product: ' + e.getMessage());
        }
        return productDetails;
    }
   

    @AuraEnabled
    public static Boolean saveVASOnly( String loanId, Boolean vasValue){
        Boolean res= false;
        try {
            List<Product2> productList= [SELECT Id, Is_loan_VAS_only__c FROM Product2 WHERE Loan_Application__c = :loanId AND Name = 'VAS'];

            if(productList.size()>0){
                Product2 product = productList[0];
                product.Is_loan_VAS_only__c = vasValue;
                update product;
            }

            res = true;
        } catch (Exception e) {
            // throw new AuraHandledException(e.getMessage());
        }
        return res;
    }

    @AuraEnabled
    public static SubProductWrapper getProductLimitations(Id loanId){
        try {
            List<Opportunity> loanList = [SELECT Id, Product__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
            if (!loanList.isEmpty()) {
                if (loanList[0].Product__c != null) {
                    String loanProduct = loanList[0].Product__c;
                    System.debug('loanProduct: '+loanProduct);
                    Id subProductRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Sub Product').getRecordTypeId();

                    List<Product2> productList = [SELECT Id, Name, Min_ROI__c,MAX_ROI__c, Min_Loan_Amount__c, Max_Loan_Amount__c, Min_Tenure_in_years__c, Max_Tenure__c, 
                                                    Product_Master__c FROM Product2 WHERE RecordTypeId =: subProductRecordId AND Product__r.Name =: loanProduct AND Loan_Application__c =: loanId LIMIT 1];
                    System.debug('productList: '+productList);
                    if(!productList.isEmpty()) {
                        Product2 prod = productList[0];
                        SubProductWrapper wrapper = new SubProductWrapper();
                        wrapper.Id = prod.Id;
                        wrapper.Name = prod.Name;
                        wrapper.minROI = prod.Min_ROI__c;
                        wrapper.maxROI = prod.MAX_ROI__c;
                        wrapper.minLoanAmount = prod.Min_Loan_Amount__c;
                        wrapper.maxLoanAmount = prod.Max_Loan_Amount__c;
                        wrapper.minTenure = prod.Min_Tenure_in_years__c;
                        wrapper.maxTenure = prod.Max_Tenure__c;
                        System.debug('wrapper: '+wrapper);
                        return wrapper;
                    }
                }
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class SubProductWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public Decimal minROI;
        @AuraEnabled public Decimal maxROI;
        @AuraEnabled public Decimal minLoanAmount;
        @AuraEnabled public Decimal maxLoanAmount;
        @AuraEnabled public Decimal minTenure;
        @AuraEnabled public Decimal maxTenure;
    }

    @AuraEnabled
    public static void updateEditedProduct(Map<String, Object> editProduct, String totalTenureValue,String stageName, String loanId,Boolean resanction, Boolean isTransactionDelete) {
        try {
            Set<Id> product2Ids = new Set<Id>();
            Map<String, Id> productFieldMap = new Map<String, Id>();
            Map<String, String> variantProdMap = new Map<String, String>();
            for (String key : editProduct.keySet()) {
                if (key.endsWith('ProductId')) {
                    Id pId = (Id)editProduct.get(key);
                    if (pId != null) {
                        product2Ids.add(pId);
                        productFieldMap.put(key, pId);
                    }
                }
            }
            System.debug('product2Ids: '+product2Ids);
            System.debug('productFieldMap: '+productFieldMap);

            Set<Id> masterIds = new Set<Id>();
            Map<String, Id> masterFieldMap = new Map<String, Id>();

            for (String key : editProduct.keySet()) {
                if (key.endsWith('ProductMaster')) {
                    Id mId = (Id)editProduct.get(key);
                    if (mId != null) {
                        masterIds.add(mId);
                        masterFieldMap.put(key, mId);
                    }
                }
            }
            System.debug('masterIds: '+masterIds);
            System.debug('masterFieldMap: '+masterFieldMap);
            Map<Id, Product2> product2Map = new Map<Id, Product2>(
                [SELECT Id, Name, Product_Master__c FROM Product2 WHERE Id IN :product2Ids]
            );

            Map<Id, Product_Master__c> masterMap = new Map<Id, Product_Master__c>(
                [SELECT Id, Name FROM Product_Master__c WHERE Id IN :masterIds]
            );

            for (String key : productFieldMap.keySet()) {
                Id product2Id = productFieldMap.get(key);
                Product2 prod = product2Map.get(product2Id);
                System.debug('key: '+key);
                String masterKey = key.replace('ProductId', 'ProductMaster');
                if (masterFieldMap.containsKey(masterKey)) {
                    Id masterId = masterFieldMap.get(masterKey);
                    prod.Product_Master__c = masterId;
                    System.debug('prod.Product_Master__c : '+prod.Product_Master__c);
                    if (masterMap.containsKey(masterId)) {
                        System.debug('prod.Name: '+prod.Name);
                        System.debug('key2: '+key);
                        if (key == 'totalTenureProductId'){
                            prod.Name = totalTenureValue;
                        } else {
                            if (key == 'variantProductId'){
                                prod.Name = masterMap.get(masterId).Name;
                                System.debug('Master Id: '+masterId);
                                System.debug('prod.Id: '+prod.Id);
                                variantProdMap.put('Master Id', masterId);
                                variantProdMap.put('Product Id', prod.Id);
                            } else {
                                prod.Name = masterMap.get(masterId).Name;
                            }
                        }
                    }
                }
            }
            System.debug('product2Map: '+product2Map);
            update product2Map.values();
            if (!variantProdMap.isEmpty()){
                updateVariantDetails(variantProdMap, loanId);
            }
            // Set Eligible for Resanction if required
            if (stageName == 'PSV' && resanction == true && String.isNotBlank(loanId)) {
                Opportunity opp = [
                    SELECT Id, Eligible_for_Resanction__c 
                    FROM Opportunity 
                    WHERE Id = :loanId 
                    LIMIT 1
                ];
                if(opp.Eligible_for_Resanction__c == true){
                    throw new CustomException('Approval already in progress');
                }else{
                    opp.Eligible_for_Resanction__c = true;
                    update opp;
                }
            }
            if (stageName == 'PSV' && isTransactionDelete == true && String.isNotBlank(loanId)) {
                List<Opportunity> oppList = [
                    SELECT Id, Product__c FROM Opportunity WHERE Id = :loanId LIMIT 1
                ];
    
                if (!oppList.isEmpty()) {
                    // Delete and Recreate using utility method
                    OpportunityUtility.createLoanTransaction(oppList);
                    OpportunityUtility.updateLMSChargesBasedOnProductChange(oppList);

                }
            }

        } catch (Exception e) {
            throw new AuraHandledException('Error updating Product2 records: ' + e.getMessage());
        }
    }

    public static void updateVariantDetails(Map<String, String> variantProdMap, String loanId) {
        Id masterId = variantProdMap.get('Master Id');
        Id productId = variantProdMap.get('Product Id');

        List<Product_Master__c> prodMaster = [SELECT Id, PLR_Value__c, PLR_Code__c, BPI_Interest_Days_Basis__c, Interest_Days_Basis__c 
                                        FROM Product_Master__c WHERE Id = :masterId LIMIT 1];
        System.debug('prodMaster: updateVariant --> '+prodMaster[0]);
        List<Product2> prodRecord = [SELECT Id, PLR_Value__c, PLR_Code__c, BPI_Interest_Days_Basis__c, Interest_Days_Basis__c 
                                FROM Product2 WHERE Id = :productId AND Loan_Application__c = :loanId LIMIT 1];
        
        if (!prodRecord.isEmpty()) {
            System.debug('prodRecord: updateVariant --> '+prodRecord[0]);
            prodRecord[0].PLR_Value__c = prodMaster[0].PLR_Value__c;
            prodRecord[0].PLR_Code__c = prodMaster[0].PLR_Code__c;
            prodRecord[0].BPI_Interest_Days_Basis__c = prodMaster[0].BPI_Interest_Days_Basis__c;
            prodRecord[0].Interest_Days_Basis__c = prodMaster[0].Interest_Days_Basis__c;
            update prodRecord;
        }
    }

    @AuraEnabled
    public static ProductUpdateResponseWrapper getPSVRelatedProductFlags(Map<String, Object> editProduct, String totalTenureValue, String stageName, String loanId) {
        try {
            Boolean isToSubVariantHybridOrInterestOnly = false;
            Boolean isVariantChangeTriggeringDelete = false;

            Set<Id> product2Ids = new Set<Id>();
            Map<String, Id> productFieldMap = new Map<String, Id>();
            if (stageName == 'PSV') {
                String toVariantId = (String) editProduct.get('variantProductMaster');
                String toSubVariantId = (String) editProduct.get('subVariantProductMaster');
                String fromVariant = (String) editProduct.get('variantProductName');
                String fromSubVariant = (String) editProduct.get('subVariantProductName');
                Set<Id> masterIds = new Set<Id>();
                if (toVariantId != null) masterIds.add((Id)toVariantId);
                if (toSubVariantId != null) masterIds.add((Id)toSubVariantId);

                Map<Id, Product_Master__c> masterMap = new Map<Id, Product_Master__c>(
                    [SELECT Id, Name FROM Product_Master__c WHERE Id IN :masterIds]
                );
                String toVariant = masterMap.containsKey(toVariantId) ? masterMap.get(toVariantId).Name : '';
                String toSubVariant = masterMap.containsKey(toSubVariantId) ? masterMap.get(toSubVariantId).Name : '';


                if (toSubVariant.toLowerCase().contains('hybrid') || toSubVariant.toLowerCase().contains('interest only')) {
                    isToSubVariantHybridOrInterestOnly = true;
                }
            
                if ((toVariant.toLowerCase().contains('term loan') && fromVariant.toLowerCase().contains('flexi funds') || toVariant.toLowerCase().contains('flexi funds') && fromVariant.toLowerCase().contains('term loan')) &&
                    !(toSubVariant.toLowerCase().contains('hybrid') || toSubVariant.toLowerCase().contains('interest only'))) {
                    isVariantChangeTriggeringDelete = true;
                }
            } 
              
            return new ProductUpdateResponseWrapper(isToSubVariantHybridOrInterestOnly, isVariantChangeTriggeringDelete);         

        } catch (Exception e) {
            throw new AuraHandledException('Error updating Product2 records: ' + e.getMessage());
        }
    }
	public static void updateRequestedAmount(Id loanId){
        if (loanId == null) return;

        // Query the sum across all line items for SubProduct type
        AggregateResult[] agg = [
            SELECT SUM(Requested_Loan_Amount__c) totalReq
            FROM Product2
            WHERE Loan_Application__c = :loanId
              AND RecordType.DeveloperName = 'Sub_Product'
              AND Requested_Loan_Amount__c != NULL
        ];

        Decimal sumVal = 0;
        if (!agg.isEmpty() && agg[0].get('totalReq') != null) {
            sumVal = (Decimal) agg[0].get('totalReq');
        }

        // Update the Opportunity
        if(sumVal == 0) {
            List<Opportunity> oppList = [SELECT Id, Lead__r.Requested_Loan_Amount__c FROM Opportunity WHERE Id = :loanId LIMIT 1];
            if (!oppList.isEmpty()) {
                sumVal = oppList[0].Lead__r.Requested_Loan_Amount__c != null ? oppList[0].Lead__r.Requested_Loan_Amount__c : 0;
            }
        }
        Opportunity oppToUpdate = new Opportunity(
            Id = loanId,
            Requested_Amount__c = sumVal
        );
        update oppToUpdate;
    }
	public class ProductUpdateResponseWrapper {
        @AuraEnabled public Boolean isToSubVariantHybridOrInterestOnly;
        @AuraEnabled public Boolean isVariantChangeTriggeringDelete;

        public ProductUpdateResponseWrapper(Boolean hybridOrInterestOnly, Boolean variantTriggerDelete) {
            this.isToSubVariantHybridOrInterestOnly = hybridOrInterestOnly;
            this.isVariantChangeTriggeringDelete = variantTriggerDelete;
        }
    }

    @AuraEnabled
    public static List<Application_Applicant__c> fetchApplicantDetails(String recordId, String applicantType) {
        List<Application_Applicant__c> applicantList = [SELECT Id FROM Application_Applicant__c WHERE Loan_Application__c =:recordId AND Applicant_Type__c = :applicantType ORDER BY CreatedDate ASC LIMIT 1];
        return applicantList;
    }
     @AuraEnabled   
public static String getBuilderName(string loanId){
    List<Application_Collateral__c> getBuilderName=new List<Application_Collateral__c>();
   getBuilderName= [select id,HL_Loan_Application__c,Name_of_Collateral__c,Name,
   Collateral__r.APF__c,Collateral__r.Builder__r.name from Application_Collateral__c 
   where  HL_Loan_Application__c=:loanId and Collateral__r.APF__c='Yes'];
   if(getBuilderName.size()>0){
    return getBuilderName[0].Collateral__r.Builder__r.name;
   }else{
    return '';
   }
}
}