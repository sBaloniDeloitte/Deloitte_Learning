import { LightningElement, wire, track, api } from 'lwc';
import saveProductRecord from '@salesforce/apex/COMM_Sales_LoginProductDetailsController.saveProductRecord';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import PRODUCT_MASTER_OBJECT from '@salesforce/schema/Product_Master__c';
import PRODUCT2_OBJECT from '@salesforce/schema/Product2';
import LOAN_FACILITY_FIELD from '@salesforce/schema/Product2.Loan_Facility__c';
import REPAYMENT_FACILITY_FIELD from '@salesforce/schema/Product_Master__c.Repayment_facility__c';
import getProductMasterPicklist from '@salesforce/apex/COMM_Sales_LoginProductDetailsController.getProductMasterPicklist';
import updateProductAndSubProduct from '@salesforce/apex/COMM_Sales_LoginProductDetailsController.updateProductAndSubProduct';
import fetchAllProducts from '@salesforce/apex/COMM_Sales_LoginProductDetailsController.fetchAllProducts';
import checkProductDedupe from '@salesforce/apex/COMM_Sales_LoginProductDetailsController.checkProductDedupe';
import deleteProduct from '@salesforce/apex/COMM_Sales_LoginProductDetailsController.deleteProduct';
import getPendingProduct from '@salesforce/apex/COMM_Sales_LoginProductDetailsController.getPendingProduct';
import saveVASOnly from '@salesforce/apex/COMM_Sales_LoginProductDetailsController.saveVASOnly';
import { fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import APPROVAL_STATUS from '@salesforce/schema/Opportunity.Approval_Status__c';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/User.Name';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import Product_Editable_Stage from '@salesforce/label/c.Product_Editable_Stage';
import Product_Editable_Profile from '@salesforce/label/c.Product_Editable_Profile';
const FIELDS = ['Opportunity.StageName', 'Opportunity.Sub_stage__c','Opportunity.Requested_Amount__c','Opportunity.Product__c'];
const USER_FIELDS = [NAME_FIELD, PROFILE_NAME_FIELD];
import getSlectedProductDetails from '@salesforce/apex/COMM_Sales_LoginProductDetailsController.getSlectedProductDetails';
import updateEditedProduct from '@salesforce/apex/COMM_Sales_LoginProductDetailsController.updateEditedProduct';
import getPSVRelatedProductFlags from '@salesforce/apex/COMM_Sales_LoginProductDetailsController.getPSVRelatedProductFlags';
//HL-Ishi-10/10
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated'
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
//HL-Ishi--10/10


export default class SalesLoginProductDetailsCmp extends LightningElement {
    @api deviceType;
    @api isOneView = false;
    @api enableDisabled=false;
    @track requestedLoanAmount;
    @track customerNegotiationHL = false;
    @track showEditLayout = false;
    @track showEditLayoutHLCO = false;
    @track totalRequestedLoanAmount;
    @track loanFacilityOptions = [];
    @track selectedLoanFacility;
    @track productType='Primary';
    @api recordId;
    @track loan;
    @track hideNext = false;
    @track productOptions = [];
    @track repaymentOptions = [];
    @track subProductOptions = [];
    @track transactionTypeOptions = [];
    @track schemeOptions = [];
    @track subVariantOptions = [];
    @track totalTenureOptions = [];
    @track hybridTenureOptions = [];
    @track variantOptions = [];
    @track fullEMIOptions = [];
    @track savedProductName;
    @track savedSubProduct;
    @track savedSchemeName;
    @track repaymentValue;
    @track isHybridTenureDisabled = true;
    @track isHybridTenureRequired = true;
    @track savedSchemeId;
    @track savedSubProductId;
    @track savedProductId;
    @track savedSubVarientId;
    @track products = [];
    @track showAddNewProduct= false;
    @track showAllProducts = false;
    @track disableProduct = false;
    @track showVASConfirmation=false;
    @track isVASOnlyLoan=false;
    @track showEditLayout = false;
    @track savedSubVarient;
    @track disableProduct = false;
    @track hybridTenureId = 0;
    @track savedFullEMIId  = 0;
    @track totalTenure = 0;
    @track isSchemeSelected = true;
    @track requestedROI;
    @track hybridTenure;
    @track savedVarient;
    @track savedVarientId;
    @track savedFullEMIName;
    @track savedTotalTenureId;
    @track disableProductType = true;
    @track savedTotalTenureName;
    @track editMode = false;
    @track editProduct;
    @track hybridTenure;
    @track totalTenureName;
    @track instanceWisesavedTotalTenureName;
    @track psvStageName;
    @track isPSVStage = false;
    @track isDisbursementStage = false;
    @track showConfirmationForDeletion = false;
    @track showConfirmationForSendBack = false;
    @track isResanction = false;
    @track isTransactionDelete = false;
    @track hideBtDetails = true;
    @track showBTDetails = false;
    @track loanPurpose;
    @track transactionType;
    @track loanPurposeMap = {};
    @wire(getObjectInfo, { objectApiName: PRODUCT_MASTER_OBJECT })
    objectInfo;
    isloading = false;
    originalSanctionedAmount;
    financialInstitutionName;
    numberOfInstallmentsPaid;
    existingLoanStartDate;
    //HL-Ishi-25/9/2025
    isHLUser= false;
    //HL-Ishi-25/9/2025
    isRejected = false;

    // Anish
    @track transactionTypes;
    @track propertyTypeOptions = [];
    @track savedPropertyTypeId;
    @track savedPropertyType;
    @track loanPurposeOptions = [];
    @track savedLoanPurposeId;
    @track savedtransactionTypeId;
    @track savedLoanPurpose;
    @track loanPurposes;
    @track userProfileName;
    @track stageName;
    @track propertyType;
    @track disableEditField = true;
    subProductDetails = {};
    @track showDuration=false;
    @track totalDuration;
    // Anish
    isHLRelated=false;
    productName;
    isFlexiProd=false;

     @track loanFacilityOptions = [
        { label: 'Fixed', value: 'Fixed' },
        { label: 'Semi-fixed', value: 'Semi-fixed' },
        { label: 'Floating', value: 'Floating' }
    ];
   
   /* get getProductByDeviceType(){
        if(this.deviceType =='Mobile'){
            return 'slds-grid slds-grid_vertical slds-m-around_small';
        }
        return 'slds-grid slds-gutters slds-m-around_small';
    }
    get getProductByDeviceTypeCol(){
        if(this.deviceType =='Mobile'){
            return 'slds-col';
        }
        return 'slds-col slds-size_1-of-4';
    }
    get getNextByDeviceType(){
        if(this.deviceType =='Mobile'){
            return "slds-button save-button slds-float_center";
        }
        return "slds-button save-button slds-float_right";
    }*/
    @track productTypeOptions = [
        { label: 'Primary', value: 'Parent' },
        { label: 'Secondary', value: 'Child' }
    ];
    @wire(CurrentPageReference) pageRef;
    @wire(getPicklistValues, { 
        recordTypeId: '$objectInfo.data.defaultRecordTypeId', 
        fieldApiName: REPAYMENT_FACILITY_FIELD 
    })
    wiredPicklistValues({ error, data }) {
        if (data) {
            this.repaymentOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error('Error fetching picklist values:', error);
        }
        this.evaluateEditPermission();
    }

    recordTypeId;

    @wire(getObjectInfo, { objectApiName: PRODUCT2_OBJECT })
    productMetadata({ data, error }) {
        if (data) {
            this.recordTypeId = data.defaultRecordTypeId;
            console.log('120',this.recordTypeId);
        } else if (error) {
            console.error('Error getting object info:', error);
        }
        this.evaluateEditPermission();
    }

    @wire(getRecord, { recordId: USER_ID, fields: USER_FIELDS })
    wiredUser({ error, data }) {
        if (data) {
            this.userName = data.fields.Name.value;
            this.userProfileName =
                data.fields.Profile.displayValue ||
                data.fields.Profile.value.fields.Name.value;

            console.log('User Profile:', this.userProfileName);

            this.evaluateEditPermission();
        }
        if (error) {
            console.error('Error fetching user details:', error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: APPROVAL_STATUS
    })
    wiredPicklistValues({ error, data }) {
        if (data) {
            console.log('Picklist Data:', JSON.stringify(data));
            this.approvalStatusOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
            console.log('Approval Status Options:', JSON.stringify(this.approvalStatusOptions));
        } else if (error) {
            console.error('Error fetching APPROVAL_STATUS picklist values:', error);
        }
        this.evaluateEditPermission();
    }


   /* @wire(getPicklistValues, {recordTypeId: '$recordTypeId', fieldApiName: LOAN_FACILITY_FIELD })
    picklistValues({ data, error }) {
        if (data) {
            this.loanFacilityOptions = data.values;
            console.log('Picklist values:', JSON.stringify(this.loanFacilityOptions, null, 2));
        } else if (error) {
            console.error('Error getting picklist values:', error);
        }
    }*/

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ data, error }) {
        if (data) {
            this.loan = data;
            console.log('data in product---', this.loan);
            
            console.log('loan StageName:', this.loan.fields.StageName.value);
            this.stageName = this.loan.fields.StageName.value;
            if(this.loan.fields.StageName.value != 'Sales login' && this.loan.fields.StageName.value != 'Credit Underwriting' && this.loan.fields.Sub_stage__c.value && !this.loan.fields.Sub_stage__c.value.includes('Offer Discussion In Progress')) {
                this.hideNext = true;
            } else {
                this.hideNext = false;
            }
            if(this.loan.fields.StageName.value == 'Credit Underwriting' && this.loan.fields.Sub_stage__c.value && this.loan.fields.Sub_stage__c.value.includes('Offer Discussion In Progress') && this.isHLUser) {
                this.customerNegotiationHL = true;
            }
            if(this.loan.fields.StageName.value == 'PSV'){
                this.psvStageName = this.loan.fields.StageName.value;
                this.isPSVStage = true;
            }
            if(this.loan.fields.StageName.value == 'Disbursement'){
                this.isDisbursementStage = true;
            }
            if(this.loan.fields.Requested_Amount__c){
                this.totalRequestedLoanAmount = this.loan.fields.Requested_Amount__c.value;
                this.requestedLoanAmount =  this.loan.fields.Requested_Amount__c.value;
            }
            if(this.loan.fields.Product__c){
                this.savedProductName = this.loan.fields.Product__c.value;
            }
            console.log('loan Sub_stage__c:', this.loan.fields.Sub_stage__c.value);
            console.log('loan customerNegotiation:', this.customerNegotiationHL);
        } else if (error) {
            console.error('Error fetching loan record:', error);
        }
                    this.evaluateEditPermission();
    }

    evaluateEditPermission() {
        // If stage or profile not loaded → disable & return
        if (!this.stageName || !this.userProfileName) {
            this.isEditable = false;
            this.isLoading = false;
            return;
        }

        // Convert custom labels to arrays
        let editableStages = Product_Editable_Stage
            ? Product_Editable_Stage.split(',').map(s => s.trim())
            : [];

        let editableProfiles = Product_Editable_Profile
            ? Product_Editable_Profile.split(',').map(p => p.trim())
            : [];

        console.log('Editable Stages:', editableStages);
        console.log('Editable Profiles:', editableProfiles);
        console.log('stageName :', this.stageName);
        console.log('userProfileName :', this.userProfileName);
        console.log('isHLUser :', this.isHLUser);
        // Final condition
        if (
            editableStages.includes(this.stageName) &&
            editableProfiles.includes(this.userProfileName) &&
            this.isHLUser
        ) {
            this.isEditable = true;
        } else {
            this.isEditable = false;
        }

        this.isLoading = false;
        console.log('isEditable:', this.isEditable);
    }

    handleRequestedROIChange(event) {
        console.log('inside roi edit>>');
        event.preventDefault();
        let value = event.target.value;

        if (!value) {
            this.requestedROI = null;
            return;
        }

        // Convert and restrict to 2 decimals
        this.requestedROI = parseFloat(parseFloat(value).toFixed(2));
    }

    handleProductTypeChane(event) {
        this.productType = event.detail.value;
    }

    handleLoanFacilityChange(event) {
        this.selectedLoanFacility = event.detail.value;
    }

    handlereqLoanAmountChange(event) {
       this.requestedLoanAmount = event.target.value;
    }

    handleOriginalSanctionedAmountChange(event) {
        this.originalSanctionedAmount = event.target.value;
    }

    handleFinancialInstitutionNameChange(event) {
        this.financialInstitutionName = event.target.value;
    }

    handleNumberOfInstallmentsPaidChange(event) {
        this.numberOfInstallmentsPaid = event.target.value;
        console.log('test numberOfInstallmentsPaid 2::', this.numberOfInstallmentsPaid);
        if(Number(this.originalTenure) < Number(this.numberOfInstallmentsPaid)){
            this.showToast('Error', 'Number of Installments cannot be more than Original Tenure.', 'error');
           // this.numberOfInstallmentsPaid = '';
            this.originalTenure = '';
        }
    }
    handleOriginalTenureChange(event) { 
        console.log('Inside originalTenure change handler');
        this.originalTenure = event.target.value;
        console.log('test originalTenure:', this.originalTenure); 
        console.log('test numberOfInstallmentsPaid:', this.numberOfInstallmentsPaid);  
        try{
        if(Number(this.originalTenure) < Number(this.numberOfInstallmentsPaid)){
            this.showToast('Error', 'Number of Installments cannot be more than Original Tenure.', 'error');
            this.originalTenure = '';
            //this.numberOfInstallmentsPaid = '';
        }
    }
    catch(error){ 
        console.error('Error in originalTenure change handler:', error);
      }
     }
    handleExistingLoanStartDateChange(event) {
        const selectedDate = new Date(event.target.value);
        const today = new Date();

        if (selectedDate >= today) {
            this.existingLoanStartDate = null;
            this.showToast('Invalid Date', 'Existing Loan Start Date cannot be today or in the future.', 'error');
        } else {
            this.existingLoanStartDate = event.target.value;
        }
    }

    connectedCallback() {
        this.fetchProducDetails();
        console.log('SalesLoginProductDetailsCmp:deviceType: ', this.deviceType);
        console.log('this.recordId salesLoginProductDetailsCmp: '+this.recordId);
        this.loadProducts();
        this.fetchProductPicklist();
        this.isloading = true;
        setTimeout(() => {
            this.isloading = false;
        }, 2000);
        //HL-Ishi-10/10
        this.checkIfLoggedInUserIsHLRelated();
        //HL-Ishi-10/10
    }

    get isSubProductDisabled() {
        return !this.savedProductName;
    }

    get isVariantDisabled() {
        return !(this.savedProductName && this.savedSubProduct);
    }

    get isSubvariantDisabled(){
        return !(this.savedProductName && this.savedSubProduct && this.savedVarientId);
    }

    get isHybridDisabled(){
        return !(this.savedProductName && this.savedSubProduct && this.savedSubVarientId);
    }

    get isSchemeDisabled() {
        return !(this.savedProductName && this.savedSubProduct && this.savedSubVarientId && this.hybridTenureId);
    }

    get isFullEMIDisabled() {
        return !(this.savedProductName && this.savedSubProduct && this.savedSubVarientId && this.hybridTenureId && this.savedSchemeId);
    }

    get isTotalTenureDisabled() {
        return !(this.savedProductName && this.savedSubProduct && this.savedSubVarientId && this.hybridTenureId && this.savedSchemeId && this.savedFullEMIId);
    }

    loadProducts() {
        console.log('this.recordId209', this.recordId);
        fetchAllProducts({ loanId: this.recordId })
        .then((result) => {
            console.log('fetchAllProducts: ' + JSON.stringify(result));
            this.products = result;

            if (this.products.length > 0) {
                // Add a new field 'prodType' for UI display
                this.products.forEach(product => {
                    //c/addManualBankDACmpproduct.prodType = (product.productType === 'Parent') ? 'Primary' : 'Secondary';
                    product.prodType ='Primary';
                });

                this.showAllProducts = true;

                const hasEmptyWrapper = this.products.some(product => product.isEmptyWrapper);
                if (hasEmptyWrapper) {
                    this.disableProduct = true;
                    this.setDefaultProductPicklist();
                } else {
                    this.disableProduct = false;
                }

                const showVAS = this.products.some(product => product.prodName === 'VAS');
                const isVAS = this.products.some(product => product.isVASOnly);
                this.isVASOnlyLoan = isVAS;
                console.log('showVAS: ' + showVAS);

                if (showVAS) {
                    this.showVASConfirmation = true;
                }

                this.checkBTDetailsVisibility();
            } else {
                this.isloading = false;
                this.showAllProducts = false;
            }
        })
        .catch((error) => {
            this.isloading = false;
            console.error('Error fetching products:', error);
        });
    }

    checkBTDetailsVisibility() {
        this.isloading = false;
        this.showBTDetails = this.products.some(record => 
            record.subProdName && record.subProdName.toLowerCase().includes('bt')
        );
    }

    get showEditLayoutActive() {
        return !this.showEditLayout && !this.hideNext;
    }


    handleEditRow(event) {
        console.log('inside edit');
        const productId = event.target.dataset.id;
        console.log('productId=:'+productId);
        const product = this.products.find(p => p.Id == productId);
        console.log('product=:'+JSON.stringify(product));
        if(this.loan.fields.StageName.value == 'Credit Underwriting' && this.loan.fields.Sub_stage__c.value && this.loan.fields.Sub_stage__c.value.includes('Offer Discussion In Progress') && this.isHLUser){
            this.showToast('Error.', 'You are not allowed to edit the product.', 'error');
            return;
        }
        if (!product) return;
        console.log('Ayush');
        this.showEditLayout=true;
        this.hideNext=true;
        console.log('this.showEditLayoutActive====='+this.showEditLayoutActive);
        console.log('this.hideNext====='+this.hideNext);
        this.selectedProduct = product;
        console.log('Selected Product Snapshot:', JSON.parse(JSON.stringify(this.selectedProduct)));

        // Populate editable fields
        this.selectedLoanFacility = product.loanFacility;
        this.productType = product.productType;
        this.requestedROI = product.requestedROI;
        this.requestedLoanAmount = product.loanAmoutReq;
        this.hybridTenureId = product.hybridTenureName;
        this.savedFullEMIId = product.fullEMI;
        this.loanPurpose = product.loanPurpose;
        this.transactionType = product.transactionType;
        this.totalTenure = product.totalTenure;       
        this.originalSanctionedAmount = product.originalSanctionedAmount;
        this.financialInstitutionName = product.financialInstitutionName;
        this.numberOfInstallmentsPaid = product.numberOfInstallmentsPaid;
        this.existingLoanStartDate = product.existingLoanStartDate;
        // Anish
        this.transactionTypes = product.transactionTypeName;
        this.loanPurposes = product.loanPurposeName;
        this.propertyType = product.propertyTypeName;
        console.log('product.prodName-----'+product.prodName);
        if(product.prodName == 'Flexi Loan'){
            this.isFlexiProd = true;
        }else{
            this.isFlexiProd = false;
        }
        console.log('product.subProdId-----'+product.subProdId);
        // if (product.prodName.includes('Flexi Loan') && this.isHLUser && product.subProdId != null) {
        //     this.handleGetEditLoanPurposePicklist(product.subProdId, productId);
        //     this.handleGetEditTransactionTypePicklist(product.subProdId, productId);
        //     this.handleGetEditPropertyTypePicklist(product.subProdId, productId);
        //     this.disableEditField = false;
        //     this.enableDisabled=false;
            
        // }
        // Anish
        this.hideBtDetails = product.subProdName.includes('BT') ? false : true;
        this.isHybridTenureDisabled = (this.savedSubVarient === 'Regular');
        this.isHybridTenureRequired = !(this.savedSubVarient === 'Regular');
        const affordableHomeOrHomeCount = this.products.filter(p => p.prodName === 'Affordable Home Loan' || p.prodName === 'Home Loan').length;

        const affordableNonHomeCount = this.products.filter(p => p.prodName === 'Affordable Non-Home Loan').length;

        const isSelectedAffordableHomeOrHome = product.prodName === 'Affordable Home Loan' || product.prodName === 'Home Loan';

        const isSelectedAffordableNonHome =product.prodName === 'Affordable Non-Home Loan' || product.prodName === 'Non Home Loan';
        console.log('affordableHomeOrHomeCount--',affordableHomeOrHomeCount);
        console.log('isSelectedAffordableHomeOrHome--',isSelectedAffordableHomeOrHome);
        console.log('affordableNonHomeCount--',affordableNonHomeCount);
         console.log('isSelectedAffordableNonHome--',isSelectedAffordableNonHome);
         this.disableProductType = true;
        if ((affordableHomeOrHomeCount >= 2 && isSelectedAffordableHomeOrHome) || (affordableHomeOrHomeCount === 0 && affordableNonHomeCount >= 2 && isSelectedAffordableNonHome)) {
            this.disableProductType = false;
        }
        if(this.customerNegotiationHL || this.isEditable){
            this.savedSubVarientId = product.subVariantMaster;
            this.savedSubProduct = product.subProdName;
            this.savedSchemeName = product.schemeProdName;
            this.savedVarient = product.variant;
            this.savedSubVarient = product.subvariantName;
            if(this.savedSubVarient == 'Morat'){
                this.showDuration= true;
                this.totalDuration = product.moratPeriod;
            }
            this.savedLoanPurpose = product.loanPurposeName;
            this.savedSubProductId = product.subProductMaster;
            this.savedVarientId = product.variantMaster;
            this.savedSchemeId = product.schemeMaster;
            this.savedProductId = product.prodMaster;
            this.savedtransactionTypeId = product.transactionTypeMaster;
            this.savedLoanPurposeId = product.loanPurposeMaster;
            this.savedPropertyTypeId = product.propertyMaster;
            this.fetchSubVariantPicklist();
            this.fetchSubProductPicklist();
            this.fetchVariantPicklist();
            this.fetchSchemePicklist();
            this.fetchTransactionTypePicklist();
            this.fetchLoanPurposePicklist();
            this.fetchPropertyTypePicklist();
        }
        if(this.isEditable){
            this.showEditLayoutHLCO = true;
            this.showEditLayout = false;
        }else{
            this.showEditLayoutHLCO = false;
        this.showEditLayout = true;
        }
        console.log('this.showEditLayoutHLCO',this.showEditLayoutHLCO);
        console.log('this.showEditLayout',this.showEditLayout);
        console.log('this.isEditable',this.isEditable);
    }
     handleGetEditLoanPurposePicklist(subprod, prod){
        getProductMasterPicklist({ recordTypeName: 'Property Type', productRecordSelected: prod, subProductRecordSelected: subprod, variantRecId: null })
        .then(result => {
            this.propertyTypeOptions = result.picklistOptions;
            console.log('this.propertyTypeOptions --> '+JSON.stringify(this.propertyTypeOptions));
        })
        .catch(error => {
            console.error('Error fetching propertyTypeOptions:', error);
        });
    }

    handleGetEditPropertyTypePicklist(subprod, prod) {
        getProductMasterPicklist({ recordTypeName: 'Property Type', productRecordSelected: prod, subProductRecordSelected: subprod, variantRecId: null })
        .then(result => {
            this.propertyTypeOptions = result.picklistOptions;
            console.log('this.propertyTypeOptions Edit --> '+JSON.stringify(this.propertyTypeOptions));
        })
        .catch(error => {
            console.error('Error fetching propertyTypeOptions Edit:', error);
        });
    }
     handleGetEditTransactionTypePicklist(subprod, prod) {
        getProductMasterPicklist({ recordTypeName: 'Transaction Type', productRecordSelected: prod, subProductRecordSelected: subprod, variantRecId: null })
        .then(result => {
            this.transactionTypeOptions = result.picklistOptions;
            this.loanPurposeMap = result.loanPurposeMap || {};
            console.log('this.transactionTypeOptions --> '+JSON.stringify(this.transactionTypeOptions));
        })
        .catch(error => {
            console.error('Error fetching transactionTypeOptions:', error);
        });
    }


    // Cancel editing
    cancelEdit() {
        this.showEditLayout = false;
        this.showEditLayoutHLCO = false;
        this.hideNext = false;

        // Clear selected product
        this.selectedProduct = {};

        this.transactionType = '';
        this.transactionTypeId = '';
            this.savedSchemeId = '';
            this.savedProductId = '';
            this.savedSubProductId = '';
            this.loanPurpose = '';
            this.repaymentValue = '';
            this.savedVarientId = '';
            this.savedSubVarientId = '';
            this.hybridTenure = '';
            this.hybridTenureId = '';
            this.savedFullEMIId = '';
            this.savedTotalTenureId = '';
            this.isVASOnlyLoan = false;
            this.showVASConfirmation = false;
            this.savedTotalTenureName = '';
            this.savedFullEMIName = '';
            this.requestedLoanAmount = '';
            this.selectedLoanFacility = '';
             this.productType = '';
            this.totalTenure = '';
            this.originalSanctionedAmount ='';
            this.financialInstitutionName ='';
            this.numberOfInstallmentsPaid ='';
            this.originalTenure ='';
            this.existingLoanStartDate ='';
            this.hideBtDetails = true;
            this.requestedROI = '';


    }

    updateProductRecord() {
        console.log('Preparing payload for update');
        this.isloading = true;
        if ( (!this.hybridTenureId && this.savedSubVarient != 'Regular') || !this.savedFullEMIId || !this.totalTenure || !this.requestedLoanAmount || !this.selectedLoanFacility || !this.requestedROI) {
            this.isloading = false;
            this.showToast('Failed to save product.', 'Kindly fill all the details and try again.', 'error');
            return;
        }

        if(!this.hideBtDetails && (!this.originalSanctionedAmount || !this.numberOfInstallmentsPaid || !this.financialInstitutionName || !this.existingLoanStartDate)){
            this.showToast('Failed to save product.', 'Kindly fill all the bt details and try again.', 'error');
            this.isloading = false;
            return;
        }
        if(this.showEditLayoutHLCO){
            if (!this.savedSubProductId ||!this.savedVarientId || !this.savedSchemeId || !this.savedtransactionTypeId || !this.savedLoanPurposeId || (!this.isFlexiProd && !this.savedPropertyTypeId) || (!this.hybridTenureId &&  this.savedSubVarient != 'Regular') || !this.savedFullEMIId || !this.requestedLoanAmount || !this.selectedLoanFacility || !this.requestedROI ) {
                this.showToast('Failed to save product.', 'Kindly fill all the details and try again.', 'error');
                this.isloading = false;
                return;
            }
        }

        console.log('this.selectedProduct>>'+JSON.stringify(this.selectedProduct));

        console.log('this.isRejected>>>'+this.selectedProduct.approvalStatusValue);
        console.log('this.selectedProduct.rejectionRemarks>>>'+this.selectedProduct.rejectionRemarks);
        if(this.selectedProduct.approvalStatusValue == 'Rejected' && this.selectedProduct.rejectionRemarks == undefined){
            this.showToast('Failed to save product.', 'Kindly add rejection remarks.', 'error');
            this.isloading = false;
            return;
        }

        
        console.log('this.selectedProduct.approvalStatusValue 558>>'+this.selectedProduct.approvalStatusValue);

        const payload = {
            oppId : this.recordId,
            productId: this.selectedProduct.Id,       // main product Id from wrapper
            subProductId: this.selectedProduct.subProdId, // subproduct Id from wrapper
            loanFacility: this.selectedLoanFacility,
            productType: this.productType,
            requestedROI: this.requestedROI,
            requestedLoanAmount: this.requestedLoanAmount,
            hybridTenure: {
                id: this.selectedProduct.hybridTenureId, // Id from wrapper
                value: this.hybridTenureId?.toString() || '0'              // Current value entered
            },
            fullEMI: {
                id: this.selectedProduct.fullEMIId,    // Id from wrapper
                value: this.savedFullEMIId             // Current value entered
            },
            totalTenure: {
                id: this.selectedProduct.totalTenureId, // Id from wrapper
                value: this.totalTenure                 // Current value calculated
            },
            btDetails: {
                originalSanctionedAmount: this.originalSanctionedAmount,
                financialInstitutionName: this.financialInstitutionName,
                numberOfInstallmentsPaid: this.numberOfInstallmentsPaid,
                existingLoanStartDate: this.existingLoanStartDate,
                originalTenure: this.originalTenure
            }
        };
        if (this.customerNegotiationHL || this.showEditLayoutHLCO) {
            payload.subVarianMastertId = this.savedSubVarientId;
            payload.savedSubVarient = this.savedSubVarient;
            payload.customerNegotiationHL = true;
            payload.hlCOUser = false;
            payload.subvariantId = this.selectedProduct.subvariantId;
            payload.moratPeriod=this.totalDuration;
            if(this.showEditLayoutHLCO){
                payload.subProductMasterId = this.savedSubProductId;
                payload.savedSubProduct = this.savedSubProduct;
                payload.subProductId = this.selectedProduct.subProdId;
                payload.variantMasterId = this.savedVarientId;
                payload.savedVarient = this.savedVarient;
                payload.variantId = this.selectedProduct.variantId;
                payload.schemeMasterId = this.savedSchemeId;
                payload.savedScheme = this.savedSchemeName;
                payload.schemeId = this.selectedProduct.schemeProdId;
                payload.savedTransactionMaster = this.savedtransactionTypeId;
                payload.transactionId = this.selectedProduct.transactionTypeId;
                payload.savedTransactionType = this.transactionType;
                payload.savedLoanPurposeMaster = this.savedLoanPurposeId;
                payload.loanPurposeId = this.selectedProduct.loanPurposeId;
                payload.savedLoanPurpose = this.savedLoanPurpose;
                payload.savedPropertyMaster = this.savedPropertyTypeId;
                payload.propertyTypeId = this.selectedProduct.propertyTypeId;
                payload.savedPropertyType = this.savedPropertyType;
                payload.hlCOUser = true;
            }
        }else{
            payload.moratPeriod=this.totalDuration;
            payload.customerNegotiationHL = false;
            payload.hlCOUser = false;;
            payload.subvariantId = this.selectedProduct.subvariantId;
            payload.schemeId = this.selectedProduct.schemeId;
            payload.subProductId = this.selectedProduct.subProdId;
            payload.variantId = this.selectedProduct.varientId;
        }

        console.log('Payload:', payload);
        console.log('Payload:', JSON.stringify(payload));

        updateProductAndSubProduct({ payload })
            .then(() => {
                this.isloading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Product updated successfully',
                        variant: 'success',
                    })
                );
                if (this.customerNegotiationHL) {
                    this.dispatchEvent(new CustomEvent('productupdated'));
                }
                this.cancelEdit();
                this.loadProducts();
            })
            .catch(error => {
                this.isloading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating product',
                        message: error.body ? error.body.message : error.message,
                        variant: 'error',
                    })
                );
            });
    }

    setDefaultProductPicklist() {
        if (!this.recordId) {
            console.error('Loan ID is missing!');
            return;
        }

        getPendingProduct({ loanId: this.recordId })
        .then(result => {
            this.isloading = false;
            if (result && result.productMasterId && result.productName) {
                this.savedProductId = result.productMasterId;
                this.savedProductName = result.productName;
                console.log('Product retrieved:', this.savedProductId, this.savedProductName);

                if (this.savedProductId) {
                    console.log('Calling fetchSubProductPicklist');
                    this.fetchSubProductPicklist();
                }
            } else {
                console.warn('No product data found.');
            }
        })
        .catch(error => {
            this.isloading = false;
            console.error('Error fetching product:', error);
        });
    }


    fetchProductPicklist() {
        getProductMasterPicklist({ recordTypeName: 'Product', productRecordSelected: null, subProductRecordSelected: null })
        .then(result => {
            this.productOptions = result.picklistOptions;
            if (this.savedProductName && this.productOptions.length > 0) {
            const matchedProduct = this.productOptions.find(
                option => option.label === this.savedProductName
            );
            if (matchedProduct) {
                this.savedProductId = matchedProduct.value;
            }
            this.selectedLoanFacility = 'Floating';
        }
        this.loadProducts();
        this.fetchSubProductPicklist();
        })
        .catch(error => {
            console.error('Error fetching products:', error);
        });
    }


    fetchSubProductPicklist() {
        console.log('this.savedProductId --> '+this.savedProductId);
        getProductMasterPicklist({ recordTypeName: 'Sub Product', productRecordSelected: this.savedProductId, subProductRecordSelected: null })
        .then(result => {
            this.subProductOptions = result.picklistOptions;
            console.log('this.subProductOptions --> '+JSON.stringify(this.subProductOptions));
        })
        .catch(error => {
            console.error('Error fetching sub-products:', error);
        });
        this.fetchTransactionTypePicklist();
    }

    fetchTransactionTypePicklist() {
        console.log('this.savedProductId --> '+this.savedProductId);
        getProductMasterPicklist({ recordTypeName: 'Transaction Type', productRecordSelected: this.savedProductId, subProductRecordSelected: this.savedSubProductId, variantRecId: null })
        .then(result => {
            this.transactionTypeOptions = result.picklistOptions;
            this.loanPurposeMap = result.loanPurposeMap || {};
            console.log('this.subProductOptions --> '+JSON.stringify(this.subProductOptions));
        })
        .catch(error => {
            console.error('Error fetching transactionTypeOptions:', error);
        });
    }

    // Anish
    fetchPropertyTypePicklist() {
        console.log('this.savedProductId --> '+this.savedProductId);
        getProductMasterPicklist({ recordTypeName: 'Property Type', productRecordSelected: this.savedProductId, subProductRecordSelected: this.savedSubProductId, variantRecId: null })
        .then(result => {
            this.propertyTypeOptions = result.picklistOptions;
            console.log('this.propertyTypeOptions --> '+JSON.stringify(this.propertyTypeOptions));
        })
        .catch(error => {
            console.error('Error fetching propertyTypeOptions:', error);
        });
    }

    // Anish
    fetchLoanPurposePicklist() {
        console.log('this.savedSubProductId --> '+this.savedSubProductId);
        getProductMasterPicklist({ recordTypeName: 'Loan Purpose', productRecordSelected: this.savedProductId, subProductRecordSelected: this.savedSubProductId, variantRecId: null })
        .then(result => {
            this.loanPurposeOptions = result.picklistOptions;
            console.log('this.loanPurposeOptions --> '+JSON.stringify(this.loanPurposeOptions));
        })
        .catch(error => {
            console.error('Error fetching loanPurposeOptions:', error);
        });
    }

    fetchVariantPicklist() {
        console.log('this.savedProductId --> '+this.productRecordSelected);
        getProductMasterPicklist({ recordTypeName: 'Variant', productRecordSelected: this.savedProductId, subProductRecordSelected: this.savedSubProductId, variantRecId: null })
        .then(result => {
            this.variantOptions = result.picklistOptions;
            console.log('this.variantOptions --> '+JSON.stringify(this.variantOptions));
        })
        .catch(error => {
            console.error('Error fetching sub-products:', error);
        });
    }

    fetchSubVariantPicklist() {
        console.log('savedVarientId :'+this.savedVarientId);
        getProductMasterPicklist({ recordTypeName: 'Sub Variant', productRecordSelected: this.savedProductId, subProductRecordSelected: null, variantRecId: this.savedVarientId })
        .then(result => {
            this.subVariantOptions = result.picklistOptions;
        })
        .catch(error => {
            console.error('Error fetching sub variant:', error);
        });
    }

    fetchSchemePicklist() {
        getProductMasterPicklist({ recordTypeName: 'Scheme', productRecordSelected: this.savedProductId, subProductRecordSelected: null, variantRecId: null, subVariantSelected: null})
        .then(result => {
            this.schemeOptions = result.picklistOptions;
        })
        .catch(error => {
            console.error('Error fetching schemes:', error);
        });
    }
// Commented due to new requirement in AHL by prachi
   /* fetchHybridTenurePicklist() {
        console.log(' this.hybridTenureOptions');
        getProductMasterPicklist({ recordTypeName: 'Hybrid Tenure', productRecordSelected: null, subProductRecordSelected: null, subVariantSelected: null, variantRecId: null })
        .then(result => {
            this.hybridTenureOptions = result.picklistOptions;
            console.log(' this.hybridTenureOptions--> '+JSON.stringify(this.hybridTenureOptions));
        })
        .catch(error => {
            console.error('Error fetching hybrid tenures:', error);
        });
    }

    fetchFullEMIPicklist() {
        console.log('this.savedSubProductId: '+this.savedSubProductId + ' || this.savedSubVarientId: '+this.savedSubVarientId);
        getProductMasterPicklist({ recordTypeName: 'Full EMI', productRecordSelected: null, subProductRecordSelected: this.savedSubProductId, subVariantSelected: null, variantRecId: null})
        .then(result => {
            this.fullEMIOptions = result.picklistOptions;
            console.log('this.fullEMIOptions --> '+JSON.stringify(this.fullEMIOptions));
        })
        .catch(error => {
            console.error('Error fetching schemes:', error);
        });
    }

    fetchTotalTenurePicklist() {
        getProductMasterPicklist({ recordTypeName: 'Total Tenure', productRecordSelected: null, subProductRecordSelected: this.savedSubProductId, subVariantSelected: null, variantRecId: null })
        .then(result => {
            this.totalTenureOptions = result.picklistOptions;
            if (this.totalTenureOptions && this.totalTenureOptions.length > 0) {
                const firstOption = this.totalTenureOptions[0];
                this.savedTotalTenureId = firstOption.value;
                this.savedTotalTenureName = firstOption.label;
            }
        })
        .catch(error => {
            console.error('Error fetching schemes:', error);
        });
    }*/

    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;
            const style = document.createElement('style');
            style.innerText = `
            
            /* Hide border and apply only bottom border */
            .removeborder .slds-combobox__input {
                border: none !important;  /* Remove all default borders */
                border-bottom: 1px solid black !important; /* Add only bottom border */
                background-color: transparent;
                outline: none;
                box-shadow: none;
                border-radius: 0 !important; /* Remove curved edges */
                padding: 5px; /* Adjust padding if necessary */
            }

            .removeInputborder .slds-input {
                border: none !important;  /* Remove all default borders */
                border-bottom: 1px solid black !important; /* Add only bottom border */
                background-color: transparent;
                outline: none;
                box-shadow: none;
                border-radius: 0 !important; /* Remove curved edges */
                padding: 5px; /* Adjust padding if necessary */
            }
    
            /* Style the combobox container */
            .removecombo .slds-combobox {
                border: none !important;
                box-shadow: none !important;
                background-color: transparent;
                border-bottom: 1px solid black !important;
                border-radius: 0 !important;
            }
    
            /* Target form elements inside combobox */
            .hideBox .slds-combobox__form-element {
                border: none !important;
                box-shadow: none !important;
                background-color: transparent;
                border-bottom: 1px solid black !important;
                border-radius: 0 !important;
            }
    
            /* Ensure proper styling for combobox input field */
            .hideborder .slds-combobox__input {
                border: none !important;
                box-shadow: none !important;
                background-color: transparent;
                border-bottom: 1px solid black !important;
                border-radius: 0 !important;
                padding: 5px;
            }

            /* Force all lightning-input / lightning-combobox field labels
               (Product, Sub Product, Transaction Type, Loan Purpose, etc.)
               to render white - these labels have no public CSS custom
               property hook, so they must be styled via this injected
               stylesheet the same way the border rules above are. */
            .slds-form-element__label {
                color: #ffffff !important;
            }
            `;
    
            this.template.querySelector('.styleContainer').appendChild(style);
        }
    }

    handleProductChange(event) {
        if(this.isHLUser){
            for(var i=0;i<this.products.length;i++){
                if(this.products[i].prodName=='Flexi Loan' && this.products[i].productType=='Parent'){
                     this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'You cannot add another product with flexi product',
                            variant: 'error',
                        })
                    );
                    event.detail.value=null;
                    this.savedProductId = null;
                    event.target.value=null;
                    return;
                    
                }
            }
        }
        event.stopPropagation();
        console.log('handleProductChange event --> '+JSON.stringify(event.detail));
        this.savedProductId = event.detail.value;
        const selectedProduct = this.productOptions.find(option => option.value === this.savedProductId);
        this.savedProductName = selectedProduct ? selectedProduct.label : null;
        console.log('Selected Product: ', this.savedProductName, ', Master Id: ', this.savedProductId);
        if(this.savedProductName == 'Flexi Loan'){
            this.isFlexiProd = true;
        }else{
            this.isFlexiProd = false;
        }
        Promise.resolve()
        .then(() => {
            if(this.savedProductId != null) {
                console.log('calling sub product picklist');
                this.fetchSubProductPicklist();
                this.fetchPropertyTypePicklist();
                this.savedSubProductId = '';
                this.loanPurpose = '';
                this.savedSubProduct = '';
                this.savedVarientId = '';
                this.savedVarient = '';
                this.savedSubVarientId = '';
                this.savedSubVarient = '';
                this.hybridTenureId = '';
                 this.transactionType = '';
            this.transactionTypeId = '';
                this.hybridTenure = '';
                this.savedSchemeId = '';
                this.savedSchemeName = '';
                this.savedFullEMIId = '';
                this.savedFullEMIName = '';
                this.savedTotalTenureId = '';
                this.savedTotalTenureName = '';
            }
        }); 
    }

    handleSubProductChange(event) {
        event.stopPropagation();
        console.log('handleSubProductChange event --> '+JSON.stringify(event.detail));
        this.savedSubProductId = event.detail.value;

        const savedSubProduct = this.subProductOptions.find(option => option.value === this.savedSubProductId);
        this.savedSubProduct = savedSubProduct ? savedSubProduct.label : null;
        this.hideBtDetails = !(this.savedSubProduct && this.savedSubProduct.toUpperCase().includes('BT'));
        
        console.log('Selected Sub-Product: ', this.savedSubProduct, ', Master Id: ', this.savedSubProductId);
        if(this.savedSubProductId != null) {
            console.log('calling sub variant picklist',this.savedSubProductId);
            // this.fetchSubVariantPicklist();
            this.fetchTransactionTypePicklist();
            this.fetchVariantPicklist();
            this.fetchLoanPurposePicklist();
            this.fetchPropertyTypePicklist();
            this.savedVarientId = '';
            this.savedVarient = '';
             this.transactionType = '';
            this.transactionTypeId = '';
            this.savedSubVarientId = '';
            this.savedSubVarient = '';
            this.hybridTenureId = '';
            this.hybridTenure = '';
            this.savedSchemeId = '';
            this.savedSchemeName = '';
            this.savedFullEMIId = '';
            this.savedFullEMIName = '';
            this.savedTotalTenureId = '';
            this.savedTotalTenureName = '';
        }
    }

    // Anish
    handlePropertyTypeChange(event) {
        event.stopPropagation();
        console.log('handlePropertyTypeChange event --> '+JSON.stringify(event.detail));
        this.savedPropertyTypeId = event.detail.value;
        const savedPropertyType = this.propertyTypeOptions.find(option => option.value === this.savedPropertyTypeId);
        this.savedPropertyType = savedPropertyType ? savedPropertyType.label : null;
    }
    // Anish
    handleLoanPurposeChange(event) {
        event.stopPropagation();
        console.log('handlePropertyTypeChange event --> '+JSON.stringify(event.detail));
        this.savedLoanPurposeId = event.detail.value;
        const savedLoanPurpose = this.loanPurposeOptions.find(option => option.value === this.savedLoanPurposeId);
        this.savedLoanPurpose = savedLoanPurpose ? savedLoanPurpose.label : null;
        console.log('savedLoanPurpose---',this.savedLoanPurpose);
    }

    handleTransactionTypeChange(event) {
        event.stopPropagation();
        console.log('handleTransactionTypeChange event --> ' + JSON.stringify(event.detail));

        this.savedtransactionTypeId = event.detail.value;

        // Get selected transaction type label
        let savedTransactionType = this.transactionTypeOptions.find(
            option => option.value === this.savedtransactionTypeId
        );
        this.transactionType = savedTransactionType ? savedTransactionType.label : null;

        console.log('loanPurposeMap:', JSON.stringify(this.loanPurposeMap));
        console.log('transactionTypeId:', this.savedtransactionTypeId);

        // Set loan purpose based on transaction type
        if (this.loanPurposeMap && this.savedtransactionTypeId) {
            const key = this.savedtransactionTypeId.trim();
            this.loanPurpose = this.loanPurposeMap[key] || null;
            console.log('Loan Purpose set to:', this.loanPurpose);
        }

    }

    handleVariantChange(event) {
        event.stopPropagation();
        console.log('handleVariantChange event --> '+JSON.stringify(event.detail));
        this.savedVarientId = event.detail.value;
        const savedVarient = this.variantOptions.find(option => option.value === this.savedVarientId);
        this.savedVarient = savedVarient ? savedVarient.label : null;
        console.log('Selected Sub-Product: ', this.savedVarient, ', Master Id: ', this.savedVarientId);
        if(this.savedVarientId != null) {
            console.log('calling sub variant picklist');
            this.fetchSubVariantPicklist();// Commented for sub variant till business team confirms and added hybrid tenure
           // this.fetchHybridTenurePicklist();
           // this.fetchSchemePicklist();
           // this.fetchFullEMIPicklist();
            // this.fetchVariantPicklist();
            this.savedSubVarientId = '';
            this.savedSubVarient = '';
            this.hybridTenureId = '';
            this.hybridTenure = '';
            this.savedSchemeId = '';
            this.savedSchemeName = '';
            this.savedFullEMIId = '';
            this.savedFullEMIName = '';
            this.savedTotalTenureId = '';
            this.savedTotalTenureName = '';
        }
    }

    handleSubVariantChange(event) {
        event.stopPropagation();
        console.log('handleSubVariantChange event --> '+JSON.stringify(event.detail));
        this.savedSubVarientId = event.detail.value;
        const savedSubVarientId = this.subVariantOptions.find(option => option.value === this.savedSubVarientId);
        this.savedSubVarient = savedSubVarientId ? savedSubVarientId.label : null;
        console.log('Selected Sub-variant: ', this.savedSubVarientId, ', Master Id: ', this.savedSubVarientId);
        if(this.savedSubVarient === 'Morat'){
            this.showDuration= true;
        }else{
            this.showDuration= false;
        }
        this.isHybridTenureDisabled = (this.savedSubVarient === 'Regular');
        this.isHybridTenureRequired  = !(this.savedSubVarient === 'Regular');
        if(this.savedSubVarientId != null) {
            console.log('calling hybrid tenure picklist');
           // this.fetchHybridTenurePicklist();
            this.fetchSchemePicklist();
            this.hybridTenureId = '';
            this.hybridTenure = '';
            this.savedSchemeId = '';
            this.savedSchemeName = '';
            this.savedFullEMIId = '';
            this.savedFullEMIName = '';
            this.savedTotalTenureId = '';
            this.savedTotalTenureName = '';
        }
    }

    handleHybridTenureChange(event) {
        event.stopPropagation();
        console.log('handleHybridTenureChange event --> '+JSON.stringify(event.detail));
        this.hybridTenureId = event.detail.value;
        const hybridTenureId = this.hybridTenureOptions.find(option => option.value === this.hybridTenureId);
        this.hybridTenure = hybridTenureId ? hybridTenureId.label : null;
        console.log('Selected hybrid Tenure: ', this.hybridTenureId, ', Master Id: ', this.hybridTenureId);
        if(this.hybridTenureId != null) {
            console.log('calling scheme product picklist');
            this.fetchSchemePicklist();
            // this.savedSchemeId = '';
            // this.savedSchemeName = '';
            // this.savedFullEMIId = '';
            // this.savedFullEMIName = '';
            // this.savedTotalTenureId = '';
            // this.savedTotalTenureName = '';
            setTimeout(() => {
                if (this.hybridTenure && this.savedFullEMIName) {
                    const total = Number(this.hybridTenure) + Number(this.savedFullEMIName);
                    console.log('Total:', total);
                    console.log('this.instanceWiseFullEMIId: '+this.instanceWiseFullEMIId);
                    if (this.instanceWisesavedTotalTenureName) {
                        const minMatch = this.instanceWisesavedTotalTenureName.match(/Min\s*(\d+)/);
                        const maxMatch = this.instanceWisesavedTotalTenureName.match(/Max\s*(\d+)/);
                
                        const min = minMatch ? Number(minMatch[1]) : null;
                        console.log('min: '+min);
                        const max = maxMatch ? Number(maxMatch[1]) : null;
                        console.log('max: '+max);
                
                        if (min !== null && max !== null) {
                            console.log(`Min: ${min}, Max: ${max}`);
                            if (total >= min && total <= max) {
                                console.log('Total is within range');
                                this.savedTotalTenureName = total;
                            } else {
                                console.warn('Total is out of range');
                                this.savedTotalTenureName = '';
                                this.hybridTenure = '';
                                this.hybridTenureId = '';
                                // this.showToast('Error.', 'Total (' + total + ') is out of range (' + min + '/'+max +')', 'error');
                                this.showToast('Total Tenure calculated: '+ total, 'Total tenure exceeds the maximum limit of ' + max +'. Kindly reselect the value for interest tenure.', 'error');
                                return;
                            }
                        } else {
                            console.error('Could not parse Min/Max from totalTenureOptions');
                        }
                    }
                }
            }, 500);
        }
    }

    handleSchemeChange(event) {
        event.stopPropagation();
        console.log('handleSchemeChange event --> '+JSON.stringify(event.detail));
        this.savedSchemeId = event.detail.value;
        const savedScheme = this.schemeOptions.find(option => option.value === this.savedSchemeId);
        this.savedSchemeName = savedScheme ? savedScheme.label : null;
        console.log('Selected Scheme: ', this.savedSchemeName, ', Master Id: ', this.savedSchemeId);
        //if(this.savedSchemeId != null) {
            this.isSchemeSelected = false;
          //  this.fetchFullEMIPicklist();
            // this.savedFullEMIId = '';
            // this.savedFullEMIName = '';
            // this.savedTotalTenureId = '';
            // this.savedTotalTenureName = '';
        //}
    }

    handleHybridTenureChange(event) {
        this.hybridTenureId = Number(event.target.value) || 0;
        this.calculateTotalTenure();
    }

    handleFullEMIChange(event) {
        this.savedFullEMIId = Number(event.target.value) || 0;
        this.calculateTotalTenure();
    }

    calculateTotalTenure() {
        const hybrid = Number(this.hybridTenureId) || 0;
        const fullEMI = Number(this.savedFullEMIId) || 0;

        const sum = hybrid + fullEMI;
        if (sum > 720) {
            this.totalTenure = 720; // Or set to 0 or previous valid value
         this.showToast('Error', 'Total Tenure cannot exceed 720 months.', 'error');
        } else {
            this.totalTenure = sum;
        }
    }


// Commented due to new requirement in AHL by prachi
  /*  handleFullEMIChange(event) {
        this.savedFullEMIId = event.detail.value;
        const savedFullEMI = this.fullEMIOptions.find(option => option.value === this.savedFullEMIId);
        this.savedFullEMIName = savedFullEMI ? savedFullEMI.label : null;
        console.log('Selected Scheme: ', this.savedFullEMIName, ', Master Id: ', this.savedFullEMIId);
        if(this.savedFullEMIId != null) {
            this.fetchTotalTenurePicklist();
            this.instanceWiseFullEMIId = this.savedFullEMIId;
            setTimeout(() => {
                if (this.hybridTenure && this.savedFullEMIName) {
                    const total = Number(this.hybridTenure) + Number(this.savedFullEMIName);
                    console.log('Total:', total);
                    if (this.savedTotalTenureName) {
                        this.instanceWisesavedTotalTenureName = this.savedTotalTenureName;
                        const minMatch = this.savedTotalTenureName.match(/Min\s*(\d+)/);
                        const maxMatch = this.savedTotalTenureName.match(/Max\s*(\d+)/);
                
                        const min = minMatch ? Number(minMatch[1]) : null;
                        const max = maxMatch ? Number(maxMatch[1]) : null;
                
                        if (min !== null && max !== null) {
                            console.log(`Min: ${min}, Max: ${max}`);
                            if (total >= min && total <= max) {
                                console.log('Total is within range');
                                this.savedTotalTenureName = total;
                            } else {
                                console.warn('Total is out of range');
                                this.savedTotalTenureName = '';
                                this.savedFullEMIId = '';
                                this.savedFullEMIName = '';
                                // this.showToast('Error.', 'Total (' + total + ') is out of range (' + min + '/'+max +')', 'error');
                                this.showToast('Total Tenure calculated: '+ total, 'Total tenure exceeds the maximum limit of ' + max +'. Kindly reselect the value for full EMI or Interest Tenure.', 'error');
                                return;
                            }
                        } else {
                            console.error('Could not parse Min/Max from totalTenureOptions');
                        }
                    }
                }
            }, 500);
        }
    }

    handleTotalTenureChange(event) {
        this.savedTotalTenureId = event.detail.value;
        const savedTotalTenure = this.totalTenureOptions.find(option => option.value === this.savedTotalTenureId);
        this.savedTotalTenureName = savedTotalTenure ? savedTotalTenure.label : null;
        console.log('Selected Tenure: ', this.savedTotalTenure, ', Master Id: ', this.savedTotalTenureId);
    }*/

    handleRepaymentFacilityChange(event) {
        event.stopPropagation();
        this.repaymentValue = event.detail.value;
    }

    async saveProduct(event) {
         this.isloading = true;
        event.stopPropagation();
         if(this.isHLUser){
            for(var i=0;i<this.products.length;i++){
                if(this.products[i].prodName=='Flexi Loan' && this.products[i].productType=='Parent'){
                     this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'You cannot add another product with flexi product',
                            variant: 'error',
                        })
                    );
                    event.detail.value=null;
                    this.savedProductName = null;
                    event.target.value=null;
                     this.isloading = false;
                    return;
                    
                }
            }
        }
        console.log('this.savedFullEMIName : ' + this.originalSanctionedAmount);

        if (!this.savedProductName || !this.savedVarient || !this.savedSubProduct ||!this.savedVarientId || !this.savedSchemeName || (!this.hybridTenureId &&  this.savedSubVarient != 'Regular') || !this.savedFullEMIId || !this.requestedLoanAmount || !this.selectedLoanFacility || !this.requestedROI ) {
            this.showToast('Failed to save product.', 'Kindly fill all the details and try again.', 'error');
            return;
        }

        if(!this.hideBtDetails && (!this.originalSanctionedAmount || !this.numberOfInstallmentsPaid || !this.financialInstitutionName || !this.existingLoanStartDate)){
            this.isloading = false;
            this.showToast('Failed to save product.', 'Kindly fill all the bt details and try again.', 'error');
            return;
        }

        if (!this.isHLUser && this.savedProductName === 'Flexi Loan') {
            const otherProductExists = this.products.some(
                product => product.prodName && product.prodName !== 'Flexi Loan'
            );

            if (!otherProductExists) {
                this.isloading = false;
                this.showToast('Cannot add Flexi Loan.', 'Please add another product before adding Flexi Loan.', 'error');
                return;
            }

            const flexiProductExists = this.products.some(
                product => product.prodName && product.prodName == 'Flexi Loan'
            );

            if (flexiProductExists) {
                this.isloading = false;
                this.showToast('Cannot add another Flexi Loan.', 'Flexi Loan cannot be added twice.', 'error');
                return;
            }
        }

        if (this.disableProduct == false) {
            try {
                const duplicateResult = await checkProductDedupe({
                    loanId: this.recordId,
                    product: this.savedProductName,
                    productId: this.savedProductId,
                    subProduct: this.savedSubProduct
                });

                if (duplicateResult !== 'Valid Product') {
                    this.isloading = false;
                    this.showToast('Failed to save product.', duplicateResult, 'error');
                    return;
                }
            } catch (error) {
                this.isloading = false;
                console.error('Error checking product:', error);
                this.showToast('Failed to check product.', 'Kindly contact System Admin.', 'error');
                return;
            }
        }

        const enteredAmount = parseFloat(this.requestedLoanAmount) || 0;
        const totalLimit = parseFloat(this.totalRequestedLoanAmount) || 0;

        let existingAmountTotal = 0;

        // Sum existing product loan amounts
        this.products.forEach(prod => {
            if (prod.loanAmoutReq) {
                existingAmountTotal += parseFloat(prod.loanAmoutReq) || 0;
            }
        });

        // If no existing products, just compare current entry
       /* if (this.products.length === 0) {
            if (enteredAmount > totalLimit) {
                this.showToast('Loan Amount Exceeded', 'Requested loan amount exceeds the Request Amount.', 'error');
                return;
            }
        } else {
            const newTotal = existingAmountTotal + enteredAmount;
            if (newTotal > totalLimit) {
                this.showToast('Loan Amount Exceeded', 'Total of all requested loan amounts exceeds the Request Amount.', 'error');
                return;
            }
        }*/


        const productData = {
            loanId: this.recordId,
            product: { prodId: this.savedProductId, name: this.savedProductName },
            subProduct: { prodId: this.savedSubProductId, name: this.savedSubProduct },
            purposeLoan: {prodId: this.savedLoanPurposeId, name: this.savedLoanPurpose}, // Anish
            variant: { prodId: this.savedVarientId, name: this.savedVarient },
            subVariant: { prodId: this.savedSubVarientId, name: this.savedSubVarient },
            scheme: { prodId: this.savedSchemeId, name: this.savedSchemeName, repaymentFacility: this.repaymentValue },
            fullEMI: { name: this.savedFullEMIId?.toString() || '0' },
            hybridTenure: { name: this.hybridTenureId?.toString() || '0' },
            totalTenure: { name: this.totalTenure?.toString() || '0' },
            transaction: { name: this.transactionTypeId, name: this.transactionType }, // Anish
            propertyType: {prodId: this.savedPropertyTypeId, name: this.savedPropertyType}, // Anish
            isDisabledProduct: this.disableProduct,
            isVasOnly: this.isVASOnlyLoan,
            reqLoanAmount: this.requestedLoanAmount,
            loanFacility: this.selectedLoanFacility,
            loanPurpose: this.loanPurpose,
            transactionType: this.transactionType,
            originalSanctionedAmount: this.originalSanctionedAmount,
            financialInstitutionName: this.financialInstitutionName,
            numberOfInstallmentsPaid: this.numberOfInstallmentsPaid,
            existingLoanStartDate: this.existingLoanStartDate,
            requestedROI: this.requestedROI,
            moratDuration: this.totalDuration
        };
        console.log('productData-999-',productData);
        if(this.isHLUser){
            productData.purposeLoan = {prodId: this.savedLoanPurposeId, name: this.savedLoanPurpose
            };
            productData.transaction = { prodId: this.savedtransactionTypeId, name: this.transactionType };
            productData.propertyType = {prodId: this.savedPropertyTypeId, name: this.savedPropertyType};
        }
        try {
            await saveProductRecord({ productData });

            this.showToast('Success', 'Product updated successfully!', 'success');

            if (this.savedSubProduct === 'HL Builder Purchase' || this.savedSubProduct === 'HL Resale Purchase') {
                const valueSelectedEvent = new CustomEvent('subproductchange', {
                    detail: { subProductName: this.savedSubProduct },
                    bubbles: true,
                    composed: true
                });
                this.dispatchEvent(valueSelectedEvent);
            }

            // Reset fields
            this.showAddNewProduct = false;
            this.savedSchemeId = '';
           // this.savedProductId = '';
            this.savedSubProductId = '';
            this.loanPurpose = '';
            this.transactionType = '';
            this.transactionTypeOptions = [];
            this.transactionTypeId = '';
            this.repaymentValue = '';
            this.savedVarientId = '';
            this.savedSubVarientId = '';
            this.hybridTenure = '';
            this.hybridTenureId = '';
            this.savedFullEMIId = '';
            this.savedTotalTenureId = '';
            this.isVASOnlyLoan = false;
            this.showVASConfirmation = false;
            this.savedTotalTenureName = '';
            this.savedFullEMIName = '';
            this.totalDuration = '';
            this.showDuration = false;
            this.requestedLoanAmount = '';
           // this.selectedLoanFacility = '';
            this.productType = '';
            this.totalTenure = '';
            this.originalSanctionedAmount ='';
            this.financialInstitutionName ='';
            this.numberOfInstallmentsPaid ='';
            this.existingLoanStartDate ='';
            this.hideBtDetails = true;
            this.requestedROI = '';
            this.isloading = false;
            // ✅ JS-Only Change: add short delay to let Apex commit
            await new Promise(resolve => setTimeout(resolve, 300));

            return this.loadProducts();

        } catch (error) {
            this.isloading = false;
            console.error('Error updating product:', error);
            this.showToast('Failed to save product.', 'Kindly contact System Admin.', 'error');
        }
    }


    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    addProduct() {
        this.showAddNewProduct = true;
    }

    cancelAddProduct() {
        this.showAddNewProduct = false;
    }

    handleDelete(event) {
        event.stopPropagation();
        let prodId = event.target.dataset.name;
        console.log('prodId :-- '+ prodId);

        deleteProduct({loanId : this.recordId, prod : prodId})
        .then((result) => {
            let delRes = result;
            console.log('delRes: '+delRes);
            if(delRes =='HL restricted deletion'){
                 this.showToast('Unable to delete product!', 'Cannot delete parent product.', 'error');
            }
            if (delRes == 'BL restricted') {
                this.showToast('Unable to delete product!', 'Business Loan is required as a product.', 'error');
            } else if (delRes == 'Success') {
                this.showToast('Success', 'Product deleted successfully!', 'success');
            } else {
                this.showToast('System Error !', 'Kindly contact system admin.', 'error');
            }
            this.loadProducts();
        }).catch(error => {
            console.error('Error deleting product:', error);
            this.showToast('Error deleting product !!', 'Kindly contact system admin.', 'error');
        });
    }

    goToNext(event){
        event.stopPropagation();
        const valueChangeEvent = new CustomEvent("callloandetails", {
            detail: { value:this.recordId,name:'Application Information',currentAppSeq: '2' }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    handleVASConfirmation(event){
        console.log('event in handleVASConfirmation---',event.target.checked);
        if(this.isVASOnlyLoan){
            this.isVASOnlyLoan = false;
        }else{
            this.isVASOnlyLoan = true;
        }

        saveVASOnly({
            loanId: this.recordId,
            vasValue: this.isVASOnlyLoan
        }).then((result) => {
            if(result){
                this.showToast('Success', 'Product updated successfully!', 'success');
            }else{
                this.showToast('Error', 'Product not updated successfully!', 'error');
            }            
            
        }).catch(error => {
            console.error('Error updating product:', error);
        });

        console.log('this.isVASOnlyLoan---',this.isVASOnlyLoan);
        
    }

    handleEdit(event){
        let prodId = event.target.dataset.name;
        console.log('prodId: '+prodId);
        if(prodId != null || prodId != undefined || prodId != ''){
            getSlectedProductDetails({loanId: this.recordId, productId: prodId})
            .then((result) => {
                this.editProduct = result;
                console.log('this.editProduct: '+JSON.stringify(this.editProduct));
                this.editMode = true;
                this.fetchSubProductEditPicklist();
                this.fetchVariantEditPicklist();
                this.fetchSubVariantEditPicklist();
               // this.fetchHybridTenureEditPicklist()
                this.fetchSchemeEditPicklist();
              //  this.fetchFullEMIEditPicklist();
               // this.fetchTotalTenureEditPicklist();
            }).catch(error => {
                console.error('Error getting selected product details: ', JSON.stringify(error));
            });
        }       
    }

    handleEditProductChange(event) {
        this.editProduct.productMaster = event.target.value;
        this.fetchSubProductEditPicklist();
    }
    
    fetchSubProductEditPicklist() {
        console.log('this.editProduct.productMaster --> '+this.editProduct.productMaster);
        getProductMasterPicklist({ recordTypeName: 'Sub Product', productRecordSelected: this.editProduct.productMaster, subProductRecordSelected: null })
        .then(result => {
            this.subProductOptions = result.picklistOptions;
            console.log('this.subProductOptions --> '+JSON.stringify(this.subProductOptions));
        })
        .catch(error => {
            console.error('Error fetching sub-products:', error);
        });
    }

    handleEditSubProductChange(event) {
        this.editProduct.subProductMaster = event.target.value;
        this.fetchVariantEditPicklist();
        this.editProduct.variantProductMaster = '';
    }

    fetchVariantEditPicklist() {
        console.log('this.editProduct.subProductMaster --> '+this.editProduct.subProductMaster);
        getProductMasterPicklist({ recordTypeName: 'Variant', productRecordSelected: this.editProduct.productMaster, subProductRecordSelected: this.editProduct.subProductMaster, variantRecId: null })
        .then(result => {
            this.variantOptions = result.picklistOptions;
            console.log('this.variantOptions --> '+JSON.stringify(this.variantOptions));
        })
        .catch(error => {
            console.error('Error fetching sub-products:', error);
        });
    }

    handleVariantEditChange(event) {
        this.editProduct.variantProductMaster = event.target.value;
        this.fetchSubVariantEditPicklist();
        this.editProduct.subVariantProductMaster = '';
    }

    fetchSubVariantEditPicklist() {
        console.log('this.editProduct.variantProductMaster :'+this.editProduct.variantProductMaster);
        getProductMasterPicklist({ recordTypeName: 'Sub Variant', productRecordSelected: this.editProduct.productMaster, subProductRecordSelected: null, variantRecId: this.editProduct.variantProductMaster })
        .then(result => {
            this.subVariantOptions = result.picklistOptions;
        })
        .catch(error => {
            console.error('Error fetching sub variant:', error);
        });
    }

    handleSubVariantEditChange(event) {
        this.editProduct.subVariantProductMaster = event.target.value;
        this.fetchHybridTenureEditPicklist();
        this.editProduct.hybridRecProductMaster = '';
    }

    fetchHybridTenureEditPicklist() {
        getProductMasterPicklist({ recordTypeName: 'Hybrid Tenure', productRecordSelected: null, subProductRecordSelected: null, subVariantSelected: this.editProduct.subVariantProductMaster, variantRecId: null })
        .then(result => {
            this.hybridTenureOptions = result.picklistOptions;
        })
        .catch(error => {
            console.error('Error fetching hybrid tenures:', error);
        });
    }

    handleHybridTenureEditChange(event){
        this.editProduct.hybridRecProductMaster = event.target.value;
        this.fetchSchemeEditPicklist();
        // this.editProduct.schemeProductMaster = '';
        const savedHybridTenure = this.hybridTenureOptions.find(option => option.value === this.editProduct.hybridRecProductMaster);
        this.editProduct.hybridRecProductName = savedHybridTenure ? savedHybridTenure.label : null;
        console.log('Selected hybridTenure: ', this.editProduct.hybridRecProductName, ', Master Id: ', this.editProduct.hybridRecProductMaster);
        
        setTimeout(() => {
            if(this.editProduct.hybridRecProductMaster != null) {
                console.log('this.hybridTenure: '+ this.editProduct.hybridRecProductName+ ', this.fullEMIName:' + this.editProduct.fullEMIProductName);
                if (this.editProduct.hybridRecProductName && this.editProduct.fullEMIProductName) {
                    const total = Number(this.editProduct.hybridRecProductName) + Number(this.editProduct.fullEMIProductName);
                    console.log('Total:', total);
                    if (this.totalTenureOptions) {
                        console.log('this.totalTenureName: '+this.totalTenureName);
                        const minMatch = this.totalTenureName.match(/Min\s*(\d+)/);
                        const maxMatch = this.totalTenureName.match(/Max\s*(\d+)/);
                
                        const min = minMatch ? Number(minMatch[1]) : null;
                        const max = maxMatch ? Number(maxMatch[1]) : null;
                
                        if (min !== null && max !== null) {
                            console.log(`Min: ${min}, Max: ${max}`);
                            if (total >= min && total <= max) {
                                console.log('Total is within range');
                                this.editProduct.totalTenureProductName = total;
                            } else {
                                console.warn('Total is out of range');
                                this.editProduct.hybridRecProductMaster = '';
                                this.editProduct.totalTenureProductName = '';
                                // this.fullEMIName = '';
                                this.showToast('Total Tenure calculated: '+ total, 'Total tenure exceeds the maximum limit of ' + max +'. Kindly reselect the value for full EMI or Interest Tenure.', 'error');
                                return;
                            }
                        } else {
                            console.error('Could not parse Min/Max from totalTenureOptions');
                        }
                    }
                }
            }
        }, 300);
    }

    fetchSchemeEditPicklist() {
        getProductMasterPicklist({ recordTypeName: 'Scheme', productRecordSelected: this.editProduct.productMaster, subProductRecordSelected: null, variantRecId: null, subVariantSelected: this.editProduct.subVariantProductMaster})
        .then(result => {
            this.schemeOptions = result.picklistOptions;
        })
        .catch(error => {
            console.error('Error fetching schemes:', error);
        });
    }

    handleSchemeEditChange(event) {
        this.editProduct.schemeProductMaster = event.target.value;
        this.fetchFullEMIEditPicklist();
        this.editProduct.fullEMIProductMaster = '';
    }

    fetchFullEMIEditPicklist() {
        getProductMasterPicklist({ recordTypeName: 'Full EMI', productRecordSelected: null, subProductRecordSelected: this.editProduct.subProductMaster, subVariantSelected: this.editProduct.subVariantProductMaster, variantRecId: null})
        .then(result => {
            this.fullEMIOptions = result.picklistOptions;
            console.log('this.fullEMIOptions --> '+JSON.stringify(this.fullEMIOptions));
        })
        .catch(error => {
            console.error('Error fetching schemes:', error);
        });
    }

    handleFullEMIEditChange(event) {
        this.editProduct.fullEMIProductMaster = event.target.value;
        this.fetchTotalTenureEditPicklist();
        console.log('this.editProduct.fullEMIProductMaster: '+this.editProduct.fullEMIProductMaster);
        console.log('this.editProduct.totalTenureProductName: '+this.editProduct.totalTenureProductName);
        // this.editProduct.totalTenureProductMaster = '';
        const savedFullEMI = this.fullEMIOptions.find(option => option.value === this.editProduct.fullEMIProductMaster);
        this.editProduct.fullEMIProductName = savedFullEMI ? savedFullEMI.label : null;
        console.log('Selected FullEMI: ', this.editProduct.fullEMIProductName, ', Master Id: ', this.editProduct.fullEMIProductMaster);
        setTimeout(() => {
            if(this.editProduct.fullEMIProductMaster != null) {
                console.log('this.hybridTenure: '+ this.editProduct.hybridRecProductName+ ', this.fullEMIName:' + this.editProduct.fullEMIProductName);
                if (this.editProduct.hybridRecProductName && this.editProduct.fullEMIProductName) {
                    const total = Number(this.editProduct.hybridRecProductName) + Number(this.editProduct.fullEMIProductName);
                    console.log('Total:', total);
                    if (this.totalTenureOptions) {
                        console.log('this.totalTenureName: '+this.totalTenureName);
                        const minMatch = this.totalTenureName.match(/Min\s*(\d+)/);
                        const maxMatch = this.totalTenureName.match(/Max\s*(\d+)/);
                
                        const min = minMatch ? Number(minMatch[1]) : null;
                        const max = maxMatch ? Number(maxMatch[1]) : null;
                
                        if (min !== null && max !== null) {
                            console.log(`Min: ${min}, Max: ${max}`);
                            if (total >= min && total <= max) {
                                console.log('Total is within range');
                                console.log('Total: '+total);
                                this.editProduct.totalTenureProductName = total;
                                console.log('this.editProduct.totalTenureProductMaster:'+this.editProduct.totalTenureProductMaster);
                            } else {
                                console.warn('Total is out of range');
                                this.totalTenureName = '';
                                this.editProduct.fullEMIProductMaster = '';
                                this.editProduct.totalTenureProductName = '';
                                // this.fullEMIName = '';
                                this.showToast('Total Tenure calculated: '+ total, 'Total tenure exceeds the maximum limit of ' + max +'. Kindly reselect the value for full EMI or Interest Tenure.', 'error');
                                return;
                            }
                        } else {
                            console.error('Could not parse Min/Max from totalTenureOptions');
                        }
                    }
                }
            }
        }, 300);
    }

    fetchTotalTenureEditPicklist() {
        getProductMasterPicklist({ recordTypeName: 'Total Tenure', productRecordSelected: null, subProductRecordSelected: this.editProduct.subProductMaster, subVariantSelected: this.editProduct.subVariantProductMaster, variantRecId: null })
        .then(result => {
            this.totalTenureOptions = result.picklistOptions;
            if (this.totalTenureOptions && this.totalTenureOptions.length > 0) {
                const firstOption = this.totalTenureOptions[0];
                this.totalTenureId = firstOption.Id;
                this.totalTenureName = firstOption.label;
                // this.editProduct.totalTenureProductMaster = firstOption.value;
            }
        })
        .catch(error => {
            console.error('Error fetching schemes:', error);
        });
    }

    handleTotalTenureEditChange(event) {
        this.editProduct.totalTenureProductMaster = event.target.value;
    }

    cancelUpdate(){
        this.editMode = false
    }

    updateProduct() {
        console.log('this.editProduct --> ' + JSON.stringify(this.editProduct));
        console.log('update this.editProduct.totalTenureProductName: '+this.editProduct.totalTenureProductName);
        const requiredFields = [
            { key: 'productMaster', label: 'Product' },
            { key: 'subProductMaster', label: 'Sub Product' },
            { key: 'variantProductMaster', label: 'Variant' },
            { key: 'subVariantProductMaster', label: 'Sub Variant' },
            { key: 'hybridRecProductMaster', label: 'Interest only tenure' },
            { key: 'schemeProductMaster', label: 'Scheme' },
            { key: 'fullEMIProductMaster', label: 'Full EMI' },
            { key: 'totalTenureProductMaster', label: 'Total Tenure' }
        ];
    
        
        if (this.isPSVStage) {
            console.log('this.editProduct:: '+JSON.stringify(this.editProduct));
            getPSVRelatedProductFlags({ editProduct: this.editProduct, totalTenureValue: this.editProduct.totalTenureProductName,stageName: this.psvStageName,loanId: this.recordId})
            .then(result => {
                console.log('Hybrid/InterestOnly:', result.isToSubVariantHybridOrInterestOnly);
                console.log('VariantDeleteTrigger:', result.isVariantChangeTriggeringDelete);
                this.showConfirmationForSendBack = result.isToSubVariantHybridOrInterestOnly;
                this.showConfirmationForDeletion = result.isVariantChangeTriggeringDelete;
                if (!this.showConfirmationForSendBack && !this.showConfirmationForDeletion) {
                    for (let field of requiredFields) {
                        const value = this.editProduct[field.key];
                        if (!value || value.trim() === '') {
                            this.showToast('Error', `${field.label} is required.`, 'error');
                            return;
                        }
                    }
        
                    updateEditedProduct({
                        editProduct: this.editProduct,
                        totalTenureValue: this.editProduct.totalTenureProductName
                    })
                    .then(result => {
                        this.editMode = false;
                        this.showToast('Success', 'Product updated successfully!', 'success');
                        this.loadProducts();
                    })
                    .catch(error => {
                        if(error.body.message.includes('Approval already in progress')){
                            this.showToast('Error', error.body.message, 'error');
                        }else{
                        this.showToast('Error', 'Product update failed!', 'error');
                        }
                        console.error('Error updating product:', error);
                    });
                }
            })
            .catch(error => {
                this.showToast('Error', 'Product update failed!', 'error');
                console.error('Error updating product:', error);
            });
        }else{
            console.log('this.editProduct before update: '+this.editProduct);
            for (let field of requiredFields) {
                const value = this.editProduct[field.key];
                if (!value || value.trim() === '') {
                    this.showToast('Error', `${field.label} is required.`, 'error');
                    return;
                }
            } 
            
            updateEditedProduct({ editProduct: this.editProduct, totalTenureValue: this.editProduct.totalTenureProductName})
            .then(result => {
                this.editMode = false;
                this.showToast('Success', 'Product updated successfully!', 'success');
                this.loadProducts();
            })
            .catch(error => {
                this.showToast('Error', 'Product update failed!', 'error');
                console.error('Error updating product:', error);
            });
        }
        
    }
    enableResanction(){
        console.log('inside resanction');
        this.isResanction = true;
        const requiredFields = [
            { key: 'productMaster', label: 'Product' },
            { key: 'subProductMaster', label: 'Sub Product' },
            { key: 'variantProductMaster', label: 'Variant' },
            { key: 'subVariantProductMaster', label: 'Sub Variant' },
            { key: 'hybridRecProductMaster', label: 'Interest only tenure' },
            { key: 'schemeProductMaster', label: 'Scheme' },
            { key: 'fullEMIProductMaster', label: 'Full EMI' },
            { key: 'totalTenureProductMaster', label: 'Total Tenure' }
        ];
    
        updateEditedProduct({ editProduct: this.editProduct, totalTenureValue: this.editProduct.totalTenureProductName,stageName: this.psvStageName,loanId: this.recordId,resanction:this.isResanction})
            .then(result => {
                this.editMode = false;
                this.showToast('Success', 'Product updated successfully!', 'success');
                this.showConfirmationForSendBack = false;
                this.loadProducts();
                window.location.reload();
            })
            .catch(error => {
                this.showToast('Error', 'Product update failed!', 'error');
                console.error('Error updating product:', error);
            }); 
    }

    closeResanctionModal(){
        this.showConfirmationForSendBack = false;
        this.editMode = false;
    }

    deleteRecreateTransaction(){
        console.log('inside isTransactionDelete');
        this.isTransactionDelete = true;
        const requiredFields = [
            { key: 'productMaster', label: 'Product' },
            { key: 'subProductMaster', label: 'Sub Product' },
            { key: 'variantProductMaster', label: 'Variant' },
            { key: 'subVariantProductMaster', label: 'Sub Variant' },
            { key: 'hybridRecProductMaster', label: 'Interest only tenure' },
            { key: 'schemeProductMaster', label: 'Scheme' },
            { key: 'fullEMIProductMaster', label: 'Full EMI' },
            { key: 'totalTenureProductMaster', label: 'Total Tenure' }
        ];
    
        updateEditedProduct({ editProduct: this.editProduct, totalTenureValue: this.editProduct.totalTenureProductName,stageName: this.psvStageName,loanId: this.recordId, isTransactionDelete:this.isTransactionDelete})
            .then(result => {
                this.editMode = false;
                this.showConfirmationForDeletion = false;
                this.showToast('Success', 'Product updated successfully!', 'success');
                this.loadProducts();
                window.location.reload();
            })
            .catch(error => {
                this.showToast('Error', 'Product update failed!', 'error');
                console.error('Error updating product:', error);
            });
    }
    closeConfirmationForDeletion(){
        this.showConfirmationForDeletion = false;
        this.editMode = false;
    }

    //HL-Ishi-10/10
    checkIfLoggedInUserIsHLRelated(){
        this.isHLUser = true;
        /*checkIfLoggedInUserIsHLRelated()
        .then(result => {
            this.isHLUser = result.isHLRelated;
            if(this.isHLUser && this.isCrif){
                this.isHLUser =false;
             console.log('  this.isHLUser----'+  this.isHLUser);
            }
            console.log('isHLUser-->',this.isHLUser);
            this.evaluateEditPermission();
        })
        .catch(error => {
            console.log('error-->',error);
        })
        //HL-Ishi-10/10*/
    }

    handleDurationChange(event){
        console.log('event---', event.target.value);
        this.totalDuration= event.target.value;
    }
    fetchProducDetails(){
        var inputMapParam = {
            'oppId': this.recordId
        };

        getProductDetails({inputMap : inputMapParam})
        .then(result =>{
            console.log('result product: '+ JSON.stringify(result));
            if(result.loanProduct=='Flexi Loan'){
                this.isFlexiProd=true;
            }
        })
        .catch(error=>{
            console.error('error in getting product: '+ JSON.stringify(error))
        })
    }
    
}