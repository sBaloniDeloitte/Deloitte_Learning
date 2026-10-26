import { LightningElement, track, api, wire } from 'lwc';
import getChargesRecords from '@salesforce/apex/COMM_CreditChargesTableController.getChargesRecords';
import getPicklistValues from '@salesforce/apex/COMM_CreditChargesTableController.getPicklistValues';
import getVASOnlyOppDetails from '@salesforce/apex/ChargesInsuranceCmpController.getVASOnlyOppDetails';
import updateChargesRecords from '@salesforce/apex/COMM_CreditChargesTableController.updateChargesRecords';
import getMetadataValue from '@salesforce/apex/COMM_PricingApprovalController.getMetadataValue';
import getPicklistValuesScreen from '@salesforce/apex/ScreenGenerationController.getPicklistValues';
import fetchAllProducts from '@salesforce/apex/COMM_Sales_LoginProductDetailsController.fetchAllProducts';
// import getDetailsForDisbursement from '@salesforce/apex/LoanTransactionController.getDetailsForDisbursement';
import getChargesApprovalCriteria from '@salesforce/apex/COMM_PricingApprovalController.getChargesApprovalCriteria';
import getLoanRecords from '@salesforce/apex/COMM_PricingApprovalController.getLoanRecords';
import getLatestLoanRecords from '@salesforce/apex/COMM_PricingApprovalController.getLatestLoanRecords';
import updateNegotiatedValues from '@salesforce/apex/COMM_PricingApprovalController.updateNegotiatedValues';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import RESANCTION from '@salesforce/schema/Opportunity.Resanction__c';
import PRICINGAPPROVAL from '@salesforce/schema/Opportunity.Pricing_Approval_Status__c';
import ELIGIBLE_FOR_RESANCTION from '@salesforce/schema/Opportunity.Eligible_for_Resanction__c';
import IS_PRICING_APPROVAL_REQUIRED from '@salesforce/schema/Opportunity.Is_Pricing_Approval_Required__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendIncomeSanctionEvent from '@salesforce/apex/COMM_IncomeSanctionLetterController.sendIncomeSanctionEvent';
import getExistingSanctionLetter from '@salesforce/apex/COMM_IncomeSanctionLetterController.getExistingSanctionLetter';
import resetResanctionFlag from '@salesforce/apex/COMM_PricingApprovalController.resetResanctionFlag';
import getVariantRecord from '@salesforce/apex/COMM_PricingApprovalController.getVariantRecord';
import getCustomerProfile from '@salesforce/apex/COMM_PricingApprovalController.getCustomerProfile';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';
import getCurrentUserDetails from '@salesforce/apex/COMM_SanctionLetterController.getCurrentUserDetails';
import getUserRole from '@salesforce/apex/Hl_CovenantsDetailFormController.getUserRole';
import STAGE_FIELD from "@salesforce/schema/Opportunity.StageName";
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
import LOAN_HIERARCHY_FIELD from "@salesforce/schema/Opportunity.Loan_Hierarchy__c";
import getTransactionsByProductIds from '@salesforce/apex/HL_StepLoanController.getTransactionsByProductIds';
import getLoanProductRecords from '@salesforce/apex/COMM_PricingApprovalController.getLoanProductRecords';
import salesProfile from '@salesforce/label/c.SalesProfile';

const LOAN_FIELDS = ['Opportunity.StageName','Opportunity.Sub_stage__c'];
export default class CustomerNegotiationScreen extends LightningElement {
    @api recordId;
    @track isOneView = true;
    @track rows = [];
    @track productList = [];
    @track graceProducts = [];
    @track stepProducts = [];
    @track metadataRecords = [];
    @track selectedMetadataRecords = [];
    @track chargesNamesMap = new Map();

    @track loanParameters = [];
    @track loanParametersAHLChild = [];
    @track loanParametersANHL = [];
    @track loanParametersFL = [];
    @track picklistMap = {}; // Store API Name -> Label Mapping
    // @track feeMethodOptions = []; // Picklist options for Fee Method
    @track mainAccordianActiveSection = [];
    @track showOpenAll = true;
    oppSubStage = '';
    oppStage = '';
    loanHierarchy = '';
    isEdit = false
    isSave = true
    ishandleApproval = false
    showResanctionNotes = false
    isEnableApprovalHis = false
    originalData = {};
    originalDataAHLChild = {};
    originalDataANHL = {};
    originalDataFL = {};
    loanData = {
        loanAmount: 0,
        roi: 0,
        tenure: 0,
        roiDiff:0,
        product: '',
        subProduct: '',
        rePaymentFacility: '',
        scheme: '',
        customerProfile: '',
        range1: '',
        range2: '',
        oldSubProduct: '',
        newSubProduct: '',
        loanAmountFL: 0,
        roiFL: 0,
        tenureFL: 0,
        roiDiffFL:0,
        loanAmountANHL: 0,
        roiANHL: 0,
        tenureANHL: 0,
        roiDiffANHL:0,
        loanAmountAHLChild: 0,
        roiAHLChild: 0,
        tenureAHLChild: 0,
        roiDiffAHLChild:0
        //loanAmountDiff: 0,
        //tenureDiff :0
    };

    userProfileName = '';
    showSections = true;
    @track ahlProductName = '';
    @track ahlChildProductName = '';
    @track flProductName = '';
    @track anhlProductName = '';
    @track ahlProductId = '';
    @track ahlChildProductId = '';
    @track flProductId = '';
    @track anhlProductId = '';
    @track displayGenerateSanctionLetter = false; 
    @track infoMessage = ''; // New property to store the approval in progress message   
    @track showMessage = false;  
    label = {
        salesProfile
    };

    @track isEditableUser = true;
    shoGenSanctionLetter = true;
    @wire(getRecord, {
        recordId: "$recordId",
        fields: LOAN_FIELDS,
    })
    gotLoanFields({
        data,
        error
    }) {
        if (data) {
            this.loanStage= data.fields.StageName.value;
        } else if (error) {
            console.error('Error fetching INFO:', error);
        }
    }

    @track showCmp = false;
    @track isLoading = false;
    connectedCallback() {
        this.fetchCurrentUserDetails();
        this.loadProducts(); 
        this.checkExistingSanctionLetter();

        if(this.isEditableUser){
            this.isEdit =  false;
            console.log('this.isEdit:::1'+this.isEdit);
            this.loadPicklistValues();
            this.loadLoanDetails();
            this.loadProductDetails();
                   
            getChargesApprovalCriteria()
            .then(result => {
                this.metadataRecords = result;
            })
            .catch(error => {
                console.error('Error fetching metadata:', error);
            });
        }
        
        getVASOnlyOppDetails({parentLoanAppId : this.recordId})
        .then(result => {
            this.isVASOnlyOpp = result;

        })
        .catch(error => {
            console.error('Error fetching metadata:', error);
        });
    }

    @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD, SUBSTAGE_FIELD, LOAN_HIERARCHY_FIELD] })
    opportunity({ error, data }) {
        if(data) {
            this.oppStage = data.fields.StageName.value;
            this.oppSubStage = data.fields.Sub_stage__c.value;
            if(this.oppSubStage == 'Credit in-progress'){
                this.shoGenSanctionLetter = false;
            }else{
                this.shoGenSanctionLetter = true;
            }
            this.loanHierarchy = data.fields.Loan_Hierarchy__c.value
            console.log('Opp sub stage' , this.oppSubStage);
            setTimeout(() => {
                this.handleVisibility();
                
                //for parent loan
                if(this.loanHierarchy == 'Parent'){
                    this.isEditableUser = false;
                    this.loanParameters = this.loanParameters.map(field => {
                        return{
                            ...field,
                            isdisabled : true
                        }
                    })
                }

            }, 1000);
        }
    }

    handleProductUpdated() {
        console.log('Product updated â€” reloading accordions...');
        this.loadProducts(); 
    }

    loadProducts() {
        fetchAllProducts({ loanId: this.recordId })
            .then(result => {
                this.productList = (result || []).map(prod => ({
                    ...prod,
                    labelName: prod.subProdName ? `${prod.prodName} / ${prod.subProdName}`: prod.prodName
                }));

                // Collect all product Ids
                const productIds = this.productList.map(p => p.Id);
                // Fetch related Loan Transaction records
                if (productIds.length > 0) {
                    getTransactionsByProductIds({productIds :productIds,loanApplicationId :this.recordId})
                        .then(transactionMap => {
                            // Merge transaction data into productList
                            this.productList = this.productList.map(prod => {
                                const txn = transactionMap[prod.Id] || {};
                                return {
                                    ...prod,
                                    transactionId: txn.Id || null,
                                    allowGrace: txn.Allow_Grace__c || false,
                                    allowGracePeriod: txn.Allow_Payment_in_Grace_Period__c || false
                                };
                            });

                            // Filter products after merging
                            this.graceProducts = this.productList.filter(
                                prod => prod.subvariantName === 'PEMI' || prod.subvariantName === 'Morat'
                            );

                            this.stepProducts = this.productList.filter(
                                prod => prod.subvariantName === 'DEMI'
                            );
                        })
                        .catch(error => {
                            console.error('Error fetching transaction details:', error);
                        });
                }
            })
            .catch(error => {
                console.error('Error loading products:', error);
            });
    }
    // Conditional display
    get showGraceDetails() {
        return this.graceProducts.length > 0;
    }

    get showStepDetails() {
        return this.stepProducts.length > 0;
    }

    handleVisibility(){
        console.log('Stage', this.oppStage);
        console.log(' Sub stage At 238', this.oppSubStage);
        getUserRole({ recordId: this.recordId })
        .then(result => {
            if(result && this.oppStage == 'Disbursement' && this.oppSubStage == 'Ops Maker'){
                this.isEditableUser = true;

                this.loanParameters = this.loanParameters.map(field => {
                    return{
                        ...field,
                        isdisabled : false
                    }
                })
            }
        })
    }

    fetchCurrentUserDetails(){
        getCurrentUserDetails({ })
        .then(result => {
            this.userProfileName = result[0];

            if(result[0] === 'GC Tele Sales User'){
                this.showSections = false;
            }
            if(result[0] === 'System Administrator' || result[0] === this.label.salesProfile || result[0] === 'Credit Manager'){
                this.isOneView= false;
            }
            if(this.userProfileName == 'Sales' && this.oppSubStage == 'Credit in-progress'){
                this.isEditableUser = false;
            }
        })
        .catch(error => {
            console.error('Error fetching profile name: ', error);
        });
    }

    @wire(getRecord, { recordId: '$recordId', fields: [RESANCTION, PRICINGAPPROVAL, ELIGIBLE_FOR_RESANCTION,IS_PRICING_APPROVAL_REQUIRED] })
    wiredOpportunity({ error, data }) {
        if (data) {
                console.log('getRecord@@'+JSON.stringify(data));
            this.opportunity = data;
            this.updateIsEdit(); // Call method after getting data
        } else if (error) {
            console.error('Error fetching record@@', error);
        }
    }

    @wire(CurrentPageReference)
    pageRef;

    get reSanction() {
        return this.opportunity?.fields?.Resanction__c?.value ?? false;
    }

    get pricing_Approval_Status() {

        return this.opportunity?.fields?.Pricing_Approval_Status__c?.value ?? '';
    }
    get eligibleForResanction() {

        return this.opportunity?.fields?.Eligible_for_Resanction__c?.value ?? '';
    }

     get isPricingApproval_Required() {

        return this.opportunity?.fields?.Is_Pricing_Approval_Required__c?.value ?? '';
    }

    updateIsEdit() {

        console.log('this.reSanction##', this.reSanction);
        console.log('this.pricing_Approval_Status##', this.pricing_Approval_Status);
        console.log('this.isPricingApproval_Required##', this.isPricingApproval_Required);

        if (this.eligibleForResanction == true) {
            this.showResanctionNotes = true
            this.isEdit = false

        }else if(this.reSanction === true) {
            this.isSave = true
            this.isEdit = true

             if(this.pricing_Approval_Status !== '' || this.isPricingApproval_Required == true){
                this.isEnableApprovalHis = true

            }
        }else if(this.isPricingApproval_Required == true){

            this.isEnableApprovalHis = true;
           

        }
        if(this.pricing_Approval_Status == 'Approved'){
             this.isEdit = false;
        }
        
    }

    // Fetch Picklist Values for Charge Name (Charges_Fee_Type__c)
    loadPicklistValues() {
        getPicklistValues()
            .then((data) => {
                this.picklistMap = data;
                this.loadChargesRecords(); // Load charges after picklist values
            })
            .catch((error) => {
                console.error('Error fetching picklist values:', JSON.stringify(error));
            });
    }

    @track resanctionNotes = '';

    @wire(getMetadataValue, { metadataName: 'Loan_Details_Credit_Notes' })
    wiredMetadata({ error, data }) {
        if (data) {
            this.resanctionNotes = data;
            console.log('Fetched Metadata Value:', this.resanctionNotes);
        } else if (error) {
            console.error('Error fetching metadata:', error);
        }
    }

    loadLoanDetails() {
        
            getLoanRecords({ opportunityId: this.recordId })
            .then((data) => {
            if (data && data.length > 0) {
            let record = data[0];
            console.log('record.Is_Pricing_Approval_Required__c>>'+record.Is_Pricing_Approval_Required__c);
            console.log('PricingApprovalStatus>.'+record.Pricing_Approval_Status__c);
            if(record.Is_Pricing_Approval_Required__c || (!record.Is_Pricing_Approval_Required__c && (record.Pricing_Approval_Status__c =='Approved'|| record.Pricing_Approval_Status__c =='Rejected'))){
                
                this.isEnableApprovalHis = true;
            }else if(record.Is_Pricing_Approval_Required__c == false){
                this.isEnableApprovalHis = false;
            }
            if(record.Pricing_Approval_Status__c == 'Submitted For Approval'){
                this.isEdit = true;
                this.isSave = true;
            }
            this.loanData.rePaymentFacility = record.Repayment_Facility__c;
            this.loanData.roiDiff = record.Sanction_Rate_Of_Interest__c - record.Negotiated_Rate_Of_Interest__c; 
            console.log('this.loanData.roiDiff:: '+this.loanData.roiDiff);
            console.log('record.Sanction_Rate_Of_Interest__c:: '+JSON.stringify(record.Sanction_Rate_Of_Interest__c));
            console.log('Negotiated_Rate_Of_Interest__c:: '+JSON.stringify(record.Negotiated_Rate_Of_Interest__c));
            //this.loanData.customerProfile = record.Customer_Profile__c;
            this.loanData.product = record.Product__c;
            /*for(let product2 of record.Products__r){
                this.loanData.product =  product2.RecordType.DeveloperName == 'Product' ? product2.Name : this.loanData.product;
                this.loanData.subProduct =  product2.RecordType.DeveloperName == 'Sub_Product' ? product2.Name : this.loanData.subProduct;
                this.loanData.scheme =  product2.RecordType.DeveloperName == 'Scheme' ? product2.Name : this.loanData.scheme;
            }*/
            getVariantRecord({ productPicklistValue: record.Product__c, opportunityId:this.recordId })
            .then(variantRecord => {
                if (variantRecord) {
                    this.loanData.subProduct = variantRecord.Name;
                }
                console.log('this.loanData.subProduct:: '+this.loanData.subProduct);
            })
            .catch(error => {
                console.error('Error fetching variant record', error);
            });
            getCustomerProfile({opportunityId:this.recordId})
            .then(custProfile => {
                if(custProfile){
                    this.loanData.customerProfile = custProfile.Customer_Profile__c;
                }
                console.log('custProfile.Customer_Profile__c:: '+custProfile.Customer_Profile__c);
            })
            .catch(error => {
                console.error('Error fetching variant record', error);
            });
            console.log('record.finalamount:: '+record.Final_Amount__c);
            }
        })
        .catch((error) => {
            console.error('Error fetching records:', JSON.stringify(error));
        });
    }

    loadProductDetails() {
            getLoanProductRecords({ opportunityId: this.recordId })
            .then((data) => {
            if (data && data.length > 0) {
                console.log('data---401',data);
                //get the affordable home loan details    
                let ahlRecordList = data.filter(record => record.Product__r.Product_Master__r.Name == 'Home Loan' && record.Product__r.Product_Type__c == 'Parent');
                if(ahlRecordList.length > 0){
                    this.ahlProductId = ahlRecordList[0].Id;
                    this.ahlProductName = ahlRecordList[0].Product__r.Product_Master__r.Name;
                    this.originalData = {
                        Id: ahlRecordList[0].Id,
                        Negotiated_Tenure__c: ahlRecordList[0].Negotiated_Tenure__c,
                        Negotiated_Loan_Amount__c: ahlRecordList[0].Negotiated_Loan_Amount__c,
                        Negotiated_ROI__c: ahlRecordList[0].Negotiated_ROI__c
                    };

                    this.loanParameters = [
                        { 
                            id: 1, Parameter: 'Loan Amount (INR)', field: 'Negotiated_Loan_Amount__c', 
                            sanctionedValue: this.formatDisplayValue(ahlRecordList[0].Sanctioned_Loan_Amount__c,false), 
                            negotiatedValue: this.formatDisplayValue(ahlRecordList[0].Negotiated_Loan_Amount__c,false),
                            finalValue: this.formatDisplayValue(ahlRecordList[0].Final_Loan_Amount__c,false), 
                            isdisabled: true,productName: this.ahlProductName,
                            step: '1' 
                        },
                        { 
                            id: 2, Parameter: 'ROI (In %)', field: 'Negotiated_ROI__c', 
                            sanctionedValue: this.formatDisplayValue(ahlRecordList[0].Sanctioned_ROI__c,true), 
                            negotiatedValue: this.formatDisplayValue(ahlRecordList[0].Negotiated_ROI__c,true),
                            finalValue: this.formatDisplayValue(ahlRecordList[0].Final_ROI__c,true), 
                            isdisabled: true,productName: this.ahlProductName,
                            step: '0.01' 
                        },
                        { 
                            id: 3, Parameter: 'Tenure (In Month)', field: 'Negotiated_Tenure__c', 
                            sanctionedValue: this.formatDisplayValue(ahlRecordList[0].Sanctioned_Tenor__c,false), 
                            negotiatedValue: this.formatDisplayValue(ahlRecordList[0].Negotiated_Tenure__c,false),
                            finalValue: this.formatDisplayValue(ahlRecordList[0].Final_Tenure__c,false), 
                            isdisabled: true,productName: this.ahlProductName,
                            step: '1' 
                        } 
                    ];
                }

            
                //get the affordable home loan child details    
                let ahlChildRecordList = data.filter(record => record.Product__r.Product_Master__r.Name == 'Home Loan' && record.Product__r.Product_Type__c == 'Child');
                if(ahlChildRecordList.length > 0){
                    this.ahlChildProductId = ahlChildRecordList[0].Id;
                    this.ahlChildProductName = ahlChildRecordList[0].Product__r.Product_Master__r.Name;
                    this.originalDataAHLChild = {
                        Id: ahlChildRecordList[0].Id,
                        Negotiated_Tenure__c: ahlChildRecordList[0].Negotiated_Tenure__c,
                        Negotiated_Loan_Amount__c: ahlChildRecordList[0].Negotiated_Loan_Amount__c,
                        Negotiated_ROI__c: ahlChildRecordList[0].Negotiated_ROI__c
                    };

                    this.loanParametersAHLChild = [
                        { 
                            id: 1, Parameter: 'Loan Amount (INR)', field: 'Negotiated_Loan_Amount__c', 
                            sanctionedValue: this.formatDisplayValue(ahlChildRecordList[0].Sanctioned_Loan_Amount__c,false), 
                            negotiatedValueAHLChild: this.formatDisplayValue(ahlChildRecordList[0].Negotiated_Loan_Amount__c,false),
                            finalValue: this.formatDisplayValue(ahlChildRecordList[0].Final_Loan_Amount__c,false), 
                            isdisabled: true,productName: this.ahlChildProductName,
                            step: '1' 
                        },
                        { 
                            id: 2, Parameter: 'ROI (In %)', field: 'Negotiated_ROI__c', 
                            sanctionedValue: this.formatDisplayValue(ahlChildRecordList[0].Sanctioned_ROI__c,true), 
                            negotiatedValueAHLChild: this.formatDisplayValue(ahlChildRecordList[0].Negotiated_ROI__c,true),
                            finalValue: this.formatDisplayValue(ahlChildRecordList[0].Final_ROI__c,true), 
                            isdisabled: true,productName: this.ahlChildProductName,
                            step: '0.01' 
                        },
                        { 
                            id: 3, Parameter: 'Tenure (In Month)', field: 'Negotiated_Tenure__c', 
                            sanctionedValue: this.formatDisplayValue(ahlChildRecordList[0].Sanctioned_Tenor__c,false), 
                            negotiatedValueAHLChild: this.formatDisplayValue(ahlChildRecordList[0].Negotiated_Tenure__c,false),
                            finalValue: this.formatDisplayValue(ahlChildRecordList[0].Final_Tenure__c,false), 
                            isdisabled: true,productName: this.ahlChildProductName,
                            step: '1' 
                        } 
                    ];
                }

                //get the non-home loan details
                let anhlRecordList = data.filter(record => record.Product__r.Product_Master__r.Name == 'Non Home Loan');
                if(anhlRecordList.length > 0){
                   this.anhlProductId = anhlRecordList[0].Id;
                   this.anhlProductName = anhlRecordList[0].Product__r.Product_Master__r.Name;
                   this.originalDataANHL = {
                        Id: anhlRecordList[0].Id,
                        Negotiated_Tenure__c: anhlRecordList[0].Negotiated_Tenure__c,
                        Negotiated_Loan_Amount__c: anhlRecordList[0].Negotiated_Loan_Amount__c,
                        Negotiated_ROI__c: anhlRecordList[0].Negotiated_ROI__c
                    };

                    this.loanParametersANHL = [
                        { 
                            id: 1, Parameter: 'Loan Amount (INR)', field: 'Negotiated_Loan_Amount__c', 
                            sanctionedValue: this.formatDisplayValue(anhlRecordList[0].Sanctioned_Loan_Amount__c,false), 
                            negotiatedValueANHL: this.formatDisplayValue(anhlRecordList[0].Negotiated_Loan_Amount__c,false),
                            finalValue: this.formatDisplayValue(anhlRecordList[0].Final_Loan_Amount__c,false), 
                            isdisabled: true, productName: this.anhlProductName,
                            step: '1' 
                        },
                        { 
                            id: 2, Parameter: 'ROI (In %)', field: 'Negotiated_ROI__c', 
                            sanctionedValue: this.formatDisplayValue(anhlRecordList[0].Sanctioned_ROI__c,true), 
                            negotiatedValueANHL: this.formatDisplayValue(anhlRecordList[0].Negotiated_ROI__c,true),
                            finalValue: this.formatDisplayValue(anhlRecordList[0].Final_ROI__c,true), 
                            isdisabled: true, productName: this.anhlProductName,
                            step: '0.01' 
                        },
                        { 
                            id: 3, Parameter: 'Tenure (In Month)', field: 'Negotiated_Tenure__c', 
                            sanctionedValue: this.formatDisplayValue(anhlRecordList[0].Sanctioned_Tenor__c,false), 
                            negotiatedValueANHL: this.formatDisplayValue(anhlRecordList[0].Negotiated_Tenure__c,false),
                            finalValue: this.formatDisplayValue(anhlRecordList[0].Final_Tenure__c,false), 
                            isdisabled: true, productName: this.anhlProductName,
                            step: '1' 
                        } 
                    ];
                }


                //get the flexi loan details
                let flRecordList = data.filter(record => record.Product__r.Product_Master__r.Name == 'Flexi Loan');
                if(flRecordList.length > 0){
                   this.flProductId = flRecordList[0].Id;
                   this.flProductName = flRecordList[0].Product__r.Product_Master__r.Name;
                   this.originalDataFL = {
                        Id: flRecordList[0].Id,
                        Negotiated_Tenure__c: flRecordList[0].Negotiated_Tenure__c,
                        Negotiated_Loan_Amount__c: flRecordList[0].Negotiated_Loan_Amount__c,
                        Negotiated_ROI__c: flRecordList[0].Negotiated_ROI__c
                    };

                    this.loanParametersFL = [
                        { 
                            id: 1, Parameter: 'Loan Amount (INR)', field: 'Negotiated_Loan_Amount__c', 
                            sanctionedValue: this.formatDisplayValue(flRecordList[0].Sanctioned_Loan_Amount__c,false), 
                            negotiatedValueFL: this.formatDisplayValue(flRecordList[0].Negotiated_Loan_Amount__c,false),
                            finalValue: this.formatDisplayValue(flRecordList[0].Final_Loan_Amount__c,false), 
                            isdisabled: true, productName: this.flProductName,
                            step: '1' 
                        },
                        { 
                            id: 2, Parameter: 'ROI (In %)', field: 'Negotiated_ROI__c', 
                            sanctionedValue: this.formatDisplayValue(flRecordList[0].Sanctioned_ROI__c,true), 
                            negotiatedValueFL: this.formatDisplayValue(flRecordList[0].Negotiated_ROI__c,true),
                            finalValue: this.formatDisplayValue(flRecordList[0].Final_ROI__c,true), 
                            isdisabled: true, productName: this.flProductName,
                            step: '0.01' 
                        },
                        { 
                            id: 3, Parameter: 'Tenure (In Month)', field: 'Negotiated_Tenure__c', 
                            sanctionedValue: this.formatDisplayValue(flRecordList[0].Sanctioned_Tenor__c,false), 
                            negotiatedValueFL: this.formatDisplayValue(flRecordList[0].Negotiated_Tenure__c,false),
                            finalValue: this.formatDisplayValue(flRecordList[0].Final_Tenure__c,false), 
                            isdisabled: true, productName: this.flProductName,
                            step: '1' 
                        } 
                    ];
                }
            
            }
        })
        .catch((error) => {
            console.error('Error fetching records:', JSON.stringify(error));
        });
    }
    formatDisplayValue(val, forceTwoDecimal) {
        // Handle null, undefined, empty string
        if (val === null || val === undefined || val === '') {
            return '';
        }
    
        // Convert to number safely
        let num = Number(val);
        if (isNaN(num)) {
            return val; // Return as-is if it's not a number
        }
    
        // ROI: always show 2 decimal points
        if (forceTwoDecimal) {
            return num.toFixed(2);
        }
    
        // Other values: show no decimal if .00, else keep .2
        return (num % 1 === 0) ? num.toFixed(0) : num.toFixed(2);
    }
    

    insuranceNegotiatePercent = 0.0
    premiumInsuranceNegotiatePercent = 0.0


    loadChargesRecords() {
        this.premiumInsuranceNegotiatePercent = 0.0;
        this.insuranceNegotiatePercent = 0.0;
        getChargesRecords({ opportunityId: this.recordId })
            .then((data) => {
                    this.rows = data.map((record) => {
                        console.log('test-->'+record.Fee_Method__c +'--'+ record.Category__c +'--' + record.Negotiated_Percentage__c  + '--'+this.premiumInsuranceNegotiatePercent);
                            if(record.Fee_Method__c == 'POSP' && (record.Category__c == 'LOS' || record.Category__c == 'Insurance')){
                            if(record.Negotiated_Percentage__c > 0)
                                this.premiumInsuranceNegotiatePercent = this.premiumInsuranceNegotiatePercent + record.Negotiated_Percentage__c;
                    }

                    if (record.RecordType.Name == 'Insurance') {
                        if (record.Negotiated_Percentage__c > 0) {
                            this.insuranceNegotiatePercent = this.insuranceNegotiatePercent + record.Negotiated_Percentage__c;
                            console.log('Charge Negotiated_Percentage__c', record.Negotiated_Percentage__c);
                        }
                    }
                      if(record.Name === 'PROCFEE'){
                        this.chargesNamesMap.set('Processing Fee', record.Negotiated_Percentage__c);
                      }

                
                    });
            }) 
            .catch((error) => {
                console.error('Error fetching records:', JSON.stringify(error));
            });
    }


    handlePassAllSections() {
        // Collect all active section names from fieldDetails
        this.mainAccordianActiveSection = ['Product Details', 'LoandDetails', 'SanctionLetter','StepDetails','GraceDetails'];
        // Hide the "Open All" button if needed
        this.showOpenAll = false;
    }

    handleCloseAllSections() {
        this.showOpenAll = true;
        this.mainAccordianActiveSection = [];
    }

    handleloanDetailChange(event) {
        
        const rowId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.loanParameters = this.loanParameters.map((row) => {
            if (row.id == rowId) {
                row[field] = value;
            }
            return row;
        });

    }

    handleloanDetailChangeAHLChild(event) {
        
        const rowId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.loanParametersAHLChild = this.loanParametersAHLChild.map((row) => {
            if (row.id == rowId) {
                row[field] = value;
            }
            return row;
        });

    }

    handleloanDetailChangeANHL(event) {
        
        const rowId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.loanParametersANHL = this.loanParametersANHL.map((row) => {
            if (row.id == rowId) {
                row[field] = value;
            }
            return row;
        });

    }

    handleloanDetailChangeFL(event) {
        
        const rowId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.loanParametersFL = this.loanParametersFL.map((row) => {
            if (row.id == rowId) {
                row[field] = value;
            }
            return row;
        });

    }

    @track isLoading = false;
    @track errorMessage = '';
    @track pdfUrl = '';  // Stores the Blob URL for PDF


    handleRegenerateSanctionLetter(event) {
        // Get product details from clicked tab/button
        const prodId = event.target.dataset.id;
        const prodName = event.target.dataset.prodName;

        console.log('Re-generating sanction letter for:', prodId, prodName);

        this.isLoading = true;
        this.errorMessage = '';

        sendIncomeSanctionEvent({
            loanId: this.recordId,
            productId: prodId,
        })
        .then(result => {
            this.isLoading = false;
            this.checkExistingSanctionLetter();

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: `Event has been fired for Sanction Letter Generation - ${prodName}`,
                    variant: 'success'
                })
            );
        })
        .catch(error => {
            console.error('Apex Exception:', error);
            this.isLoading = false;

            this.errorMessage = 'Error firing event for Sanction Letter Generation.';

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.errorMessage,
                    variant: 'error'
                })
            );
        });
    }
    
    renderPDF(base64String) {
        try {
            let byteCharacters = atob(base64String);
            let byteNumbers = new Array(byteCharacters.length);
            for (let i = 0; i < byteCharacters.length; i++) {
                byteNumbers[i] = byteCharacters.charCodeAt(i);
            }
            let byteArray = new Uint8Array(byteNumbers);
            let file = new Blob([byteArray], { type: 'application/pdf' });

            this.pdfUrl = URL.createObjectURL(file);  // Create a Blob URL for PDF
        } catch (error) {
            console.error('Error rendering PDF:', error);
            this.errorMessage = 'Error rendering PDF.';
        }
    }  

    checkExistingSanctionLetter() {
        this.isLoading = true;
        getExistingSanctionLetter({ loanId: this.recordId })
            .then((response) => {
                console.log('Sanction Letter Response:', response);
                console.log('productList787', JSON.stringify(this.productList));

                if (response && response.length > 0 && this.productList.length > 0) {
                    this.productList = this.productList.map((prod) => {
                        const match = response.find(
                            (rec) => rec.Product__c === prod.Id
                        );
                        return {
                            ...prod,
                            communicationStatus: match ? match.Communication_Status__c : 'Not Generated'
                        };
                    });
                } else {
                    this.productList = this.productList.map((prod) => ({
                        ...prod,
                        communicationStatus: 'Not Generated'
                    }));
                }

                this.isLoading = false;
            })
            .catch((error) => {
                console.error('Error checking existing sanction letter:', error);
                this.errorMessage = 'Error checking existing sanction letter.';
                this.isLoading = false;
            });
    }

    handleEdit() {
        this.showResanctionNotes = false
        this.isEnableApprovalHis = false
        this.loanParameters = this.loanParameters.map(row => {
            if (row.Parameter == 'EMI Amount (INR)' || (this.isVASOnlyOpp && this.loanStage==='PSV' && row.Parameter == 'Loan Amount (INR)')) {
                return { ...row, isdisabled: true };
            }else{
                return { ...row, isdisabled: false };
            }
           // return row;
        });

        this.loanParametersAHLChild = this.loanParametersAHLChild.map(row => {
            if (row.Parameter == 'EMI Amount (INR)' || (this.isVASOnlyOpp && this.loanStage==='PSV' && row.Parameter == 'Loan Amount (INR)')) {
                return { ...row, isdisabled: true };
            }else{
                return { ...row, isdisabled: false };
            }
           // return row;
        });

        this.loanParametersANHL = this.loanParametersANHL.map(row => {
            if (row.Parameter == 'EMI Amount (INR)' || (this.isVASOnlyOpp && this.loanStage==='PSV' && row.Parameter == 'Loan Amount (INR)')) {
                return { ...row, isdisabled: true };
            }else{
                return { ...row, isdisabled: false };
            }
           // return row;
        });

        this.loanParametersFL = this.loanParametersFL.map(row => {
            if (row.Parameter == 'EMI Amount (INR)' || (this.isVASOnlyOpp && this.loanStage==='PSV' && row.Parameter == 'Loan Amount (INR)')) {
                return { ...row, isdisabled: true };
            }else{
                return { ...row, isdisabled: false };
            }
           // return row;
        });

        this.isSave = false
        this.isEdit = true

    }
    isLoaded = true

    //async handleSave() { //July 7, setTimeout
    handleSave() {

        this.isLoaded = false
        this.loadPicklistValues();

        setTimeout(() => {
            console.log('776>>>');
                    this.isLoaded = true
        this.selectedMetadataRecords = [];

        this.isSave = true
        this.isEdit = false

        if (this.reSanction === true || this.pricing_Approval_Status !== '') {
        this.isSave = true
        this.isEdit = true
        }
        console.log('this.loanParameters@@', JSON.stringify(this.loanParameters));
        this.loanParameters = this.loanParameters.map(row => {
        if (row.Parameter != 'EMI Amount (INR)') {
            return { ...row, isdisabled: true };
        }
        return row;
        });

        console.log('this.loanParametersAHLChild@@', JSON.stringify(this.loanParametersAHLChild));
        this.loanParametersAHLChild = this.loanParametersAHLChild.map(row => {
        if (row.Parameter != 'EMI Amount (INR)') {
            return { ...row, isdisabled: true };
        }
        return row;
        });

        console.log('this.loanParametersANHL@@', JSON.stringify(this.loanParametersANHL));
        this.loanParametersANHL = this.loanParametersANHL.map(row => {
        if (row.Parameter != 'EMI Amount (INR)') {
            return { ...row, isdisabled: true };
        }
        return row;
        });

        console.log('this.loanParametersFL@@', JSON.stringify(this.loanParametersFL));
        this.loanParametersFL = this.loanParametersFL.map(row => {
        if (row.Parameter != 'EMI Amount (INR)') {
            return { ...row, isdisabled: true };
        }
        return row;
        });

        let updatedValues = {};
        let updatedValuesAHLChild = {};
        let updatedValuesANHL = {};
        let updatedValuesFL = {};


        this.loanParameters.map((row) => {
            console.log('row>>>'+row);
        if (row.Parameter != 'EMI Amount (INR)' && this.originalData[row.field] != row.negotiatedValue) {
            updatedValues[row.field] = row.negotiatedValue;
        }
        if (row.Parameter === 'Loan Amount (INR)') {
            this.loanData.loanAmount = row.negotiatedValue - row.sanctionedValue;
            //this.loanData.loanAmountDiff = row.negotiatedValue - row.sanctionedValue;
        }
        if (row.Parameter === 'ROI (In %)') {
            this.loanData.roi = (row.negotiatedValue || 0);
            this.loanData.roiDiff = row.sanctionedValue - row.negotiatedValue;
            //console.log('this.loanData.roiDiff::: '+this.loanData.roiDiff);
        }
        if (row.Parameter === 'Tenure (In Month)') {
            this.loanData.tenure = (row.negotiatedValue || 0) - (row.sanctionedValue || 0);
            //this.loanData.tenureDiff = (row.negotiatedValue || 0) - (row.sanctionedValue || 0);
        }
        });
        console.log('this.loanParameters>>>'+JSON.stringify(this.loanParameters));


        this.loanParametersAHLChild.map((row) => {
        if (row.Parameter != 'EMI Amount (INR)' && this.originalDataAHLChild[row.field] != row.negotiatedValueAHLChild) {
            updatedValuesAHLChild[row.field] = row.negotiatedValueAHLChild;
        }
        if (row.Parameter === 'Loan Amount (INR)') {
            this.loanData.loanAmountAHLChild = row.negotiatedValueAHLChild - row.sanctionedValue;
        }
        if (row.Parameter === 'ROI (In %)') {
            this.loanData.roiAHLChild = (row.negotiatedValueAHLChild || 0);
            this.loanData.roiDiffAHLChild = row.sanctionedValue - row.negotiatedValueAHLChild;
        }
        if (row.Parameter === 'Tenure (In Month)') {
            this.loanData.tenureAHLChild = (row.negotiatedValueAHLChild || 0) - (row.sanctionedValue || 0);
        }
        });

        console.log('this.loanParametersAHLChild>>>'+JSON.stringify(this.loanParametersAHLChild));

        this.loanParametersANHL.map((row) => {
        if (row.Parameter != 'EMI Amount (INR)' && this.originalDataANHL[row.field] != row.negotiatedValueANHL) {
            updatedValuesANHL[row.field] = row.negotiatedValueANHL;
        }
        if (row.Parameter === 'Loan Amount (INR)') {
            this.loanData.loanAmountANHL = row.negotiatedValueANHL - row.sanctionedValue;
        }
        if (row.Parameter === 'ROI (In %)') {
            this.loanData.roiANHL = (row.negotiatedValueANHL || 0);
            this.loanData.roiDiffANHL = row.sanctionedValue - row.negotiatedValueANHL;
        }
        if (row.Parameter === 'Tenure (In Month)') {
            this.loanData.tenureANHL = (row.negotiatedValueANHL || 0) - (row.sanctionedValue || 0);
        }
        });

        console.log('this.loanParametersANHL>>>'+JSON.stringify(this.loanParametersANHL));

        this.loanParametersFL.map((row) => {
        if (row.Parameter != 'EMI Amount (INR)' && this.originalDataFL[row.field] != row.negotiatedValueFL) {
            updatedValuesFL[row.field] = row.negotiatedValueFL;
        }
        if (row.Parameter === 'Loan Amount (INR)') {
            this.loanData.loanAmountFL = row.negotiatedValueFL - row.sanctionedValue;
        }
        if (row.Parameter === 'ROI (In %)') {
            this.loanData.roiFL = (row.negotiatedValueFL || 0);
            this.loanData.roiDiffFL = row.sanctionedValue - row.negotiatedValueFL;
        }
        if (row.Parameter === 'Tenure (In Month)') {
            this.loanData.tenureFL = (row.negotiatedValueFL || 0) - (row.sanctionedValue || 0);
        }
        });

        console.log('this.loanParametersFL>>>'+JSON.stringify(this.loanParametersFL));

        console.log('updatedValues--', updatedValues);
        console.log('updatedValuesAHLChild--', updatedValuesAHLChild);
        console.log('updatedValuesANHL--', updatedValuesANHL);
        console.log('updatedValuesFL--', updatedValuesFL);
        if (Object.keys(updatedValues).length === 0 && Object.keys(updatedValuesAHLChild).length === 0 && Object.keys(updatedValuesFL).length === 0 && Object.keys(updatedValuesANHL).length === 0) {
            this.showToast('No Changes', 'No modifications detected', 'info');
            return;
        }

        if (Object.keys(updatedValues).length > 0) {
            if (updatedValues.hasOwnProperty('Negotiated_Tenure__c')){
                if(updatedValues['Negotiated_Tenure__c'] == ''){
                    this.showToast('Error', 'Please enter the Negotiated Tenure', 'error');
                    return;
                }
            }
            if (updatedValues.hasOwnProperty('Negotiated_Loan_Amount__c')){
                if(updatedValues['Negotiated_Loan_Amount__c'] == ''){
                    this.showToast('Error', 'Please enter the Negotiated Loan Amount', 'error');
                    return;
                }
            }
            if (updatedValues.hasOwnProperty('Negotiated_ROI__c')){
                if(updatedValues['Negotiated_ROI__c'] == ''){
                    this.showToast('Error', 'Please enter the Negotiated ROI', 'error');
                    return;
                }
            }

        }

        if (Object.keys(updatedValuesAHLChild).length > 0) {
            if (updatedValuesAHLChild.hasOwnProperty('Negotiated_Tenure__c')){
                if(updatedValuesAHLChild['Negotiated_Tenure__c'] == ''){
                    this.showToast('Error', 'Please enter the Negotiated Tenure', 'error');
                    return;
                }
            }
            if (updatedValuesAHLChild.hasOwnProperty('Negotiated_Loan_Amount__c')){
                if(updatedValuesAHLChild['Negotiated_Loan_Amount__c'] == ''){
                    this.showToast('Error', 'Please enter the Negotiated Loan Amount', 'error');
                    return;
                }
            }
            if (updatedValuesAHLChild.hasOwnProperty('Negotiated_ROI__c')){
                if(updatedValuesAHLChild['Negotiated_ROI__c'] == ''){
                    this.showToast('Error', 'Please enter the Negotiated ROI', 'error');
                    return;
                }
            }
  
        }

        if (Object.keys(updatedValuesANHL).length > 0) {
            if (updatedValuesANHL.hasOwnProperty('Negotiated_Tenure__c')){
                if(updatedValuesANHL['Negotiated_Tenure__c'] == ''){
                    this.showToast('Error', 'Please enter the Negotiated Tenure', 'error');
                    return;
                }
            }
            if (updatedValuesANHL.hasOwnProperty('Negotiated_Loan_Amount__c')){
                if(updatedValuesANHL['Negotiated_Loan_Amount__c'] == ''){
                    this.showToast('Error', 'Please enter the Negotiated Loan Amount', 'error');
                    return;
                }
            }
            if (updatedValuesANHL.hasOwnProperty('Negotiated_ROI__c')){
                if(updatedValuesANHL['Negotiated_ROI__c'] == ''){
                    this.showToast('Error', 'Please enter the Negotiated ROI', 'error');
                    return;
                }
            }
  
        }

        if (Object.keys(updatedValuesFL).length > 0) {
            if (updatedValuesFL.hasOwnProperty('Negotiated_Tenure__c')){
                if(updatedValuesFL['Negotiated_Tenure__c'] == ''){
                    this.showToast('Error', 'Please enter the Negotiated Tenure', 'error');
                    return;
                }
            }
            if (updatedValuesFL.hasOwnProperty('Negotiated_Loan_Amount__c')){
                if(updatedValuesFL['Negotiated_Loan_Amount__c'] == ''){
                    this.showToast('Error', 'Please enter the Negotiated Loan Amount', 'error');
                    return;
                }
            }
            if (updatedValuesFL.hasOwnProperty('Negotiated_ROI__c')){
                if(updatedValuesFL['Negotiated_ROI__c'] == ''){
                    this.showToast('Error', 'Please enter the Negotiated ROI', 'error');
                    return;
                }
            }
  
        }

        if (Object.keys(updatedValues).length > 0) {
            console.log('897>>>>>');
            //try catch block
            // const data = await updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValues }) //July 7, setTimeout
            updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValues, productName : this.ahlProductId })
            .then(() => {
                /*this.loanParameters.forEach(data=>{
                    console.log('data 899>>>>'+JSON.stringify(data));
                    console.log('data.field>>'+data.field);
        
                    if(data.field != 'Negotiated_ROI__c'){
                        if(updatedValues[data.field] <= data.sanctionedValue){
                            data.finalValue = updatedValues[data.field];
                        }

                    }else if(data.field == 'Negotiated_ROI__c'){
                    if(updatedValues[data.field] >= data.sanctionedValue){
                        data.finalValue = updatedValues[data.field];
                    }
                    }
                    })*/
                this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                console.log('this.loanParameters>>>>'+JSON.stringify(this.loanParameters));
                 this.loadLoanDetails(); // Reload data after save
            })
            .catch((error) => {
                console.error('Error updating records:', JSON.stringify(error));
                this.showToast('Error', 'Failed to update values AHL', 'error');
            });

            console.log('this.originalData##', JSON.stringify(this.originalData));
            console.log('call process criteria AHL')
            //this.processApprovalCriteria();
        }

        if (Object.keys(updatedValuesAHLChild).length > 0) {
            updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesAHLChild, productName : this.ahlChildProductId })
            .then(() => {
                /*this.loanParametersAHLChild.forEach(data=>{
        
                    if(data.field != 'Negotiated_ROI__c'){
                        if(updatedValuesAHLChild[data.field] <= data.sanctionedValue){
                            data.finalValue = updatedValuesAHLChild[data.field];
                        }

                    }else if(data.field == 'Negotiated_ROI__c'){
                    if(updatedValuesAHLChild[data.field] >= data.sanctionedValue){
                        data.finalValue = updatedValuesAHLChild[data.field];
                    }
                    }
                    }) */  
                this.showToast('Success', 'Negotiated values updated successfully!', 'success');
            })
            .catch((error) => {
                console.error('Error updating records:', JSON.stringify(error));
                this.showToast('Error', 'Failed to update values AHL Child', 'error');
            });

            console.log('this.originalDataAHLChild##', JSON.stringify(this.originalDataAHLChild));

            //check the criteria for AHL Child only when AHL doesn't meet resanction or approval
            if(this.showResanctionNotes == false && this.isEnableApprovalHis == false){
                console.log('call process criteria AHL Child');
                //this.processApprovalCriteriaForAHLChild();
            }
        }

        if (Object.keys(updatedValuesANHL).length > 0) {
            updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesANHL, productName : this.anhlProductId })
            .then(() => {
                /*this.loanParametersANHL.forEach(data=>{
        
                    if(data.field != 'Negotiated_ROI__c'){
                        if(updatedValuesANHL[data.field] <= data.sanctionedValue){
                            data.finalValue = updatedValuesANHL[data.field];
                        }

                    }else if(data.field == 'Negotiated_ROI__c'){
                    if(updatedValuesANHL[data.field] >= data.sanctionedValue){
                        data.finalValue = updatedValuesANHL[data.field];
                    }
                    }
                    })   */
                this.showToast('Success', 'Negotiated values updated successfully!', 'success');
            })
            .catch((error) => {
                console.error('Error updating records:', JSON.stringify(error));
                this.showToast('Error', 'Failed to update values ANHL', 'error');
            });

            console.log('this.originalData##', JSON.stringify(this.originalDataANHL));

            //check the criteria for FL only when AHL doesn't meet resanction or approval
            if(this.showResanctionNotes == false && this.isEnableApprovalHis == false){
                console.log('call process criteria ANHL');
               // this.processApprovalCriteriaForANHL();
            }
        }

        if (Object.keys(updatedValuesFL).length > 0) {
            updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesFL, productName : this.flProductId })
            .then(() => {
                /*this.loanParametersFL.forEach(data=>{
        
                    if(data.field != 'Negotiated_ROI__c'){
                        if(updatedValuesFL[data.field] <= data.sanctionedValue){
                            data.finalValue = updatedValuesFL[data.field];
                        }

                    }else if(data.field == 'Negotiated_ROI__c'){
                    if(updatedValuesFL[data.field] >= data.sanctionedValue){
                        data.finalValue = updatedValuesFL[data.field];
                    }
                    }
                    }) */  
                this.showToast('Success', 'Negotiated values updated successfully!', 'success');
            })
            .catch((error) => {
                console.error('Error updating records:', JSON.stringify(error));
                this.showToast('Error', 'Failed to update values FL', 'error');
            });

            console.log('this.originalData##', JSON.stringify(this.originalDataFL));

            //check the criteria for FL only when AHL doesn't meet resanction or approval
            if(this.showResanctionNotes == false && this.isEnableApprovalHis == false){
                console.log('call process criteria FL');
                //this.processApprovalCriteriaForFL();
            }
        }

        if(Object.keys(updatedValues).length > 0 || Object.keys(updatedValuesFL).length > 0 || Object.keys(updatedValuesANHL).length > 0 || Object.keys(updatedValuesAHLChild).length > 0){
            console.log('this.showResanctionNotes after criteria', this.showResanctionNotes)
            const fields = {
            Id: this.recordId,
            Eligible_for_Resanction__c: this.showResanctionNotes,
            Is_Pricing_Approval_Required__c: this.isEnableApprovalHis,
            };
            const recordInput = { fields };
            updateRecord(recordInput)
            .then(() => {
                if (this.showResanctionNotes) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'This loan application requires to be re-sactioned. Kindly click on the re-sanction button to initiate the process.',
                            variant: 'success'
                        })

                    );
                }
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Failed to update Eligible for Resanction',
                        variant: 'error'
                    })
                );
                console.error('Update Error:', error);
            });
        }
        }, 5000);
        // console.log('this.selectedMetadataRecords', JSON.stringify(this.selectedMetadataRecords));
    }

    processApprovalCriteria() {

        console.log('row this.loanData', JSON.stringify(this.loanData));
        console.log('this.metadataRecords:: '+JSON.stringify(this.metadataRecords));
        console.log('this.record.Final_Amount__c'+this.loanFinalAmount);
        for (const row of this.metadataRecords) {
            let isMatch = false;
            let isRoiResanctionMatch = false;
            let isRoiPricingApprovalMatch = false;
            console.log('row this.loanData.loanAmount', this.loanData.loanAmount);

            // if (row.Type__c == 'Loan Amount' && this.loanData.loanAmount < 0 && row.Decreased_by__c > 0 && Math.abs(this.loanData.loanAmount) >= row.Decreased_by__c ) {
            //     isMatch = true;
            //     console.log('row 459##', JSON.stringify(row));

            // } else 
            if (row.Type__c == 'Loan Amount' && this.loanData.loanAmount > 0 && row.Increased_By__c > 0 && Math.abs(this.loanData.loanAmount) >= row.Increased_By__c) {
                isMatch = true;
            }

            // for loan amount new implementation
            // if (row.Type__c == 'Loan Amount' && this.loanData.loanAmountDiff > 0 && row.Range1__c != null && row.Range2__c != null && this.loanData.loanAmount > row.Range1__c && this.loanData.loanAmount <= row.Range2__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c && this.loanData.customerProfile.replace(/[\u200B-\u200D\uFEFF]/g, '') == row.Customer_Profile__c.replace(/[\u200B-\u200D\uFEFF]/g, '')) {
            //     isMatch = true;
            //     console.log('upto 50L loan amount--', JSON.stringify(row))
            // }
            // else if (row.Type__c == 'Loan Amount' && this.loanData.loanAmountDiff > 0 && row.Range1__c != null && row.Range2__c == null && this.loanData.loanAmount >= row.Range1__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c && this.loanData.customerProfile.replace(/[\u200B-\u200D\uFEFF]/g, '') == row.Customer_Profile__c.replace(/[\u200B-\u200D\uFEFF]/g, '')) {
            //     isMatch = true;
            //     console.log('above 50L loan amount--', JSON.stringify(row));
            // }

            // for tenure
            if (row.Type__c == 'Tenure' && this.loanData.tenure < 0 && row.Decreased_by__c != null && row.Decreased_by__c > 0 && Math.abs(this.loanData.tenure) >= row.Decreased_by__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c) {
                isMatch = true;
                console.log('dec--', this.loanData.tenure)
            } else if (row.Type__c == 'Tenure' && this.loanData.tenure > 0 && row.Increased_By__c != null && row.Increased_By__c > 0 && Math.abs(this.loanData.tenure) >= row.Increased_By__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c) {
                isMatch = true;
                console.log('Inc--', this.loanData.tenure)
            }
            
            // for tenure new implementation
            // if (row.Type__c == 'Tenure' && this.loanData.tenureDiff > 0 && row.Range1__c != null && row.Range2__c != null && this.loanData.tenure > row.Range1__c && this.loanData.tenure <= row.Range2__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c && this.loanData.customerProfile.replace(/[\u200B-\u200D\uFEFF]/g, '') == row.Customer_Profile__c.replace(/[\u200B-\u200D\uFEFF]/g, '')) {
            //     isMatch = true;
            //     console.log('upto 48M tenure--', JSON.stringify(row))
            // }
            // else if (row.Type__c == 'Tenure' && this.loanData.tenureDiff > 0 && row.Range1__c != null && row.Range2__c == null && this.loanData.tenure >= row.Range1__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c && this.loanData.customerProfile.replace(/[\u200B-\u200D\uFEFF]/g, '') == row.Customer_Profile__c.replace(/[\u200B-\u200D\uFEFF]/g, '')) {
            //     isMatch = true;
            //     console.log('above 48M tenure--', JSON.stringify(row));
            // }

            console.log('inside:: '+row.Type__c + this.loanData.roi + this.loanData.roi + this.loanData.product + row.Product__c + this.loanData.subProduct + row.Sub_Product__c + this.loanData.customerProfile + row.Customer_Profile__c);
            //for Roi
            // if (row.Type__c == 'ROI' && this.loanData.roiDiff != 0 && this.loanData.roiDiff > 0 && this.loanData.roi != null && this.loanData.roi == row.Value__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c && this.loanData.customerProfile.replace(/[\u200B-\u200D\uFEFF]/g, '') == row.Customer_Profile__c.replace(/[\u200B-\u200D\uFEFF]/g, '')) {
            //     console.log('inside roi match');
            //     isMatch = true;
            // }

            console.log('metadata row>>'+JSON.stringify(row));
            console.log('this.loanData>>'+JSON.stringify(this.loanData));


            //new roi implemetation
            if (row.Type__c == 'ROI' && 
                this.loanData.roiDiff != 0 && 
                this.loanData.roiDiff > 0 && 
                this.loanData.roi != null && 
                row.Range1__c != null && 
                row.Range2__c != null && 
                this.loanData.roi >= row.Range1__c && 
                this.loanData.roi <= row.Range2__c && 
                this.loanData.product == row.Product__c && 
                this.loanData.subProduct == row.Sub_Product__c && 
                this.loanData.customerProfile.replace(/[\u200B-\u200D\uFEFF]/g, '') == row.Customer_Profile__c.replace(/[\u200B-\u200D\uFEFF]/g, '')) {
                console.log('inside roi match');
                isRoiPricingApprovalMatch = true;
            }

            if(row.Type__c == 'ROI' && this.loanData.roiDiff < 0){
                isRoiResanctionMatch = true;
            }

            /*  for Processign fees
            if (row.Type__c == 'Processing Fee' && this.chargesNamesMap.has(row.Type__c) && this.chargesNamesMap.get(row.Type__c) != null && this.chargesNamesMap.get(row.Type__c) == row.Value__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c && this.loanData.customerProfile == row.Customer_Profile__c) {
                isMatch = true;
            }

            // for insurance
            if (row.Type__c == 'Insurance' && this.insuranceNegotiatePercent != 0 && this.insuranceNegotiatePercent == row.Value__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c &&  this.loanData.customerProfile == row.Customer_Profile__c) {
                isMatch = true;
            }*/

            // for Premium insurance
            //&& this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c && this.loanData.rePaymentFacility == row.Re_Payment_Facility__c && this.loanData.scheme == row.Scheme__c && this.loanData.customerProfile == row.Customer_Profile__c
           
            /*if (row.Type__c == 'PremiumInsurance' && this.premiumInsuranceNegotiatePercent > 0 && this.premiumInsuranceNegotiatePercent > row.Value__c) {
                isMatch = true;
            }*/

            if (isMatch) {
                
                if (row.Resanction__c == false && row.Level__c != null && row.Designation__c != null) {
                    this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = false;
                    this.isEnableApprovalHis = true;
                }

                if (row.Resanction__c == true) {
                    this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = true;
                    this.isEnableApprovalHis = false;
                    break;
                }
            }
            if(isRoiPricingApprovalMatch){
                 if (row.Level__c != null && row.Designation__c != null) {
                    this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = false;
                    this.isEnableApprovalHis = true;
                }

            }
            if(isRoiResanctionMatch){
                this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = true;
                    this.isEnableApprovalHis = false;
                    break;
            }
        }

        console.log('Selected Metadata Records:', JSON.stringify(this.selectedMetadataRecords));
    }

    processApprovalCriteriaForAHLChild() {
        console.log('row this.loanData', JSON.stringify(this.loanData));
        console.log('this.metadataRecords:: '+JSON.stringify(this.metadataRecords));
        for (const row of this.metadataRecords) {
            let isMatch = false;
            let isRoiResanctionMatch = false;
            let isRoiPricingApprovalMatch = false;
            console.log('row this.loanData.loanAmountAHLChild', this.loanData.loanAmountAHLChild);

            if (row.Type__c == 'Loan Amount' && this.loanData.loanAmountAHLChild > 0 && row.Increased_By__c > 0 && Math.abs(this.loanData.loanAmountAHLChild) >= row.Increased_By__c) {
                isMatch = true;
                console.log('inside ahl child amount match');
            }

            if (row.Type__c == 'Tenure' && this.loanData.tenureAHLChild > 0 && row.Increased_By__c != null && row.Increased_By__c > 0 && Math.abs(this.loanData.tenureAHLChild) >= row.Increased_By__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c) {
                isMatch = true;
                console.log('inside ahl child tenure match');
            }else if (row.Type__c == 'Tenure' && this.loanData.tenureAHLChild < 0 && row.Decreased_by__c != null && row.Decreased_by__c > 0 && Math.abs(this.loanData.tenureAHLChild) >= row.Decreased_by__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c ) {
                isMatch = true;
                console.log('dec--', this.loanData.tenure)
            }

            if (row.Type__c == 'ROI' && this.loanData.roiDiffAHLChild != 0 && this.loanData.roiDiffAHLChild > 0 && this.loanData.roiAHLChild != null && row.Range1__c != null && row.Range2__c != null && this.loanData.roiAHLChild >= row.Range1__c && this.loanData.roiAHLChild <= row.Range2__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c && this.loanData.customerProfile.replace(/[\u200B-\u200D\uFEFF]/g, '') == row.Customer_Profile__c.replace(/[\u200B-\u200D\uFEFF]/g, '')) {
                console.log('inside ahl child roi match');
                //isMatch = true;
                isRoiPricingApprovalMatch = true;
            }
            if(row.Type__c == 'ROI' && this.loanData.roiDiffAHLChild < 0){
                isRoiResanctionMatch = true;
            }


            if (isMatch) {
                if (row.Resanction__c == false && row.Level__c != null && row.Designation__c != null) {
                    this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = false;
                    this.isEnableApprovalHis = true;
                }
                if (row.Resanction__c == true) {
                    this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = true;
                    this.isEnableApprovalHis = false;
                    break;
                }
            }
            if(isRoiPricingApprovalMatch){
                 if (row.Level__c != null && row.Designation__c != null) {
                    this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = false;
                    this.isEnableApprovalHis = true;
                }

            }
            if(isRoiResanctionMatch){
                this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = true;
                    this.isEnableApprovalHis = false;
                    break;
            }
        }

        console.log('Selected Metadata Records:', JSON.stringify(this.selectedMetadataRecords));
    }

    processApprovalCriteriaForANHL() {
        console.log('row this.loanData', JSON.stringify(this.loanData));
        console.log('this.metadataRecords:: '+JSON.stringify(this.metadataRecords));
        for (const row of this.metadataRecords) {
            let isMatch = false;
            let isRoiResanctionMatch = false;
            let isRoiPricingApprovalMatch = false;
            console.log('row this.loanData.loanAmountANHL', this.loanData.loanAmountANHL);

            if (row.Type__c == 'Loan Amount' && this.loanData.loanAmountANHL > 0 && row.Increased_By__c > 0 && Math.abs(this.loanData.loanAmountANHL) >= row.Increased_By__c) {
                isMatch = true;
                console.log('inside anhl amount match');
            }

            if (row.Type__c == 'Tenure' && this.loanData.tenureANHL > 0 && row.Increased_By__c != null && row.Increased_By__c > 0 && Math.abs(this.loanData.tenureANHL) >= row.Increased_By__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c) {
                isMatch = true;
                console.log('inside anhl tenure match');
            }else if (row.Type__c == 'Tenure' && this.loanData.tenureANHL < 0 && row.Decreased_by__c != null && row.Decreased_by__c > 0 && Math.abs(this.loanData.tenureANHL) >= row.Decreased_by__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c) {
                isMatch = true;
                console.log('dec--', this.loanData.tenureANHL)
            }

            if (row.Type__c == 'ROI' && this.loanData.roiDiffANHL != 0 && this.loanData.roiDiffANHL > 0 && this.loanData.roiANHL != null && row.Range1__c != null && row.Range2__c != null && this.loanData.roiANHL >= row.Range1__c && this.loanData.roiANHL <= row.Range2__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c && this.loanData.customerProfile.replace(/[\u200B-\u200D\uFEFF]/g, '') == row.Customer_Profile__c.replace(/[\u200B-\u200D\uFEFF]/g, '')) {
                console.log('inside anhl roi match');
                //isMatch = true;
                isRoiPricingApprovalMatch = true;
            }
            if(row.Type__c == 'ROI' && this.loanData.roiDiffANHL < 0){
                isRoiResanctionMatch = true;
            }


            if (isMatch) {
                if (row.Resanction__c == false && row.Level__c != null && row.Designation__c != null) {
                    this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = false;
                    this.isEnableApprovalHis = true;
                }
                if (row.Resanction__c == true) {
                    this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = true;
                    this.isEnableApprovalHis = false;
                    break;
                }
            }
            if(isRoiPricingApprovalMatch){
                 if (row.Level__c != null && row.Designation__c != null) {
                    this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = false;
                    this.isEnableApprovalHis = true;
                }

            }
            if(isRoiResanctionMatch){
                this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = true;
                    this.isEnableApprovalHis = false;
                    break;
            }
        }

        console.log('Selected Metadata Records:', JSON.stringify(this.selectedMetadataRecords));
    }

    processApprovalCriteriaForFL() {
        console.log('row this.loanData', JSON.stringify(this.loanData));
        console.log('this.metadataRecords:: '+JSON.stringify(this.metadataRecords));
        for (const row of this.metadataRecords) {
            let isMatch = false;
            let isRoiResanctionMatch = false;
            let isRoiPricingApprovalMatch = false;
            console.log('row this.loanData.loanAmountFL', this.loanData.loanAmountFL);

            if (row.Type__c == 'Loan Amount' && this.loanData.loanAmountFL > 0 && row.Increased_By__c > 0 && Math.abs(this.loanData.loanAmountFL) >= row.Increased_By__c) {
                isMatch = true;
                console.log('inside fl amount match');
            }

            if (row.Type__c == 'Tenure' && this.loanData.tenureFL > 0 && row.Increased_By__c != null && row.Increased_By__c > 0 && Math.abs(this.loanData.tenureFL) >= row.Increased_By__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c) {
                isMatch = true;
                console.log('inside fl tenure match');
            }else if (row.Type__c == 'Tenure' && this.loanData.tenureFL < 0 && row.Decreased_by__c != null && row.Decreased_by__c > 0 && Math.abs(this.loanData.tenureFL) >= row.Decreased_by__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c ) {
                isMatch = true;
                console.log('dec--', this.loanData.tenure)
            }

            if (row.Type__c == 'ROI' && this.loanData.roiDiffFL != 0 && this.loanData.roiDiffFL > 0 && this.loanData.roiFL != null && row.Range1__c != null && row.Range2__c != null && this.loanData.roiFL >= row.Range1__c && this.loanData.roiFL <= row.Range2__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c && this.loanData.customerProfile.replace(/[\u200B-\u200D\uFEFF]/g, '') == row.Customer_Profile__c.replace(/[\u200B-\u200D\uFEFF]/g, '')) {
                console.log('inside fl roi match');
                //isMatch = true;
                isRoiPricingApprovalMatch = true;
            }
            if(row.Type__c == 'ROI' && this.loanData.roiDiffFL < 0){
                isRoiResanctionMatch = true;
            }


            if (isMatch) {
                if (row.Resanction__c == false && row.Level__c != null && row.Designation__c != null) {
                    this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = false;
                    this.isEnableApprovalHis = true;
                }
                if (row.Resanction__c == true) {
                    this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = true;
                    this.isEnableApprovalHis = false;
                    break;
                }
            }
            if(isRoiPricingApprovalMatch){
                 if (row.Level__c != null && row.Designation__c != null) {
                    this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = false;
                    this.isEnableApprovalHis = true;
                }

            }
            if(isRoiResanctionMatch){
                this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = true;
                    this.isEnableApprovalHis = false;
                    break;
            }
        }

        console.log('Selected Metadata Records:', JSON.stringify(this.selectedMetadataRecords));
    }

    handleSendForApproval() {

        submitLoanForApproval({ loanId: this.recordId, approvalType: 'Test' })
            .then(result => {
                console.log('result--' + result);

                if (result === 'success') {

                    this.showToast('Success', 'Approval initiated successfully!', 'success');

                    this.refreshPage();
                } else {

                    this.showToast('Info', result, 'info');

                }
            })
            .catch(error => {
                this.showToast('Error', 'Something went wrong. Please contact your system administrator.', 'error');
            });

    }

    // Update a single Charge Record in Salesforce
    updateSingleChargeRecord(row) {
        const updatedRecord = {
            Id: row.id,
            Charges_Fee_Type__c: row.picklistApiValue, // Send API Name (not label) to Salesforce
            Requested_Amount_INR__c: row.requestedAmount,
            Tax_INR__c: row.tax,
            Final_Amount_INR__c: row.finalAmount,
            Fee_Method__c: row.feeMethod
        };

        updateChargesRecords({ updatedRecords: [updatedRecord] })
            .then(() => {
                this.showToast('Success', 'Record updated successfully', 'success');
            })
            .catch((error) => {
                this.showToast('Error', 'Failed to update record', 'error');
                console.error('Error updating record:', error);
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    hasRendered = false; 
    renderedCallback() {
        console.log('I am inside rendered callback');
        registerListener('refreshPricingApproval', this.handlePricingRefresh, this);
        registerListener('triggerResanctionCheck', this.handleChildUpdateForResanction, this);
        //if (this.hasRendered) return;
        //this.hasRendered = true;
        // Listen for focus (when tab becomes active)
        //window.addEventListener("focus", this.handleTabFocus.bind(this));
        const style = document.createElement("style");
        style.innerText = `
            .slds-accordion__summary {
                padding: 10px 0px 10px 0px;
            }
            .slds-accordion__list-item {
                margin-bottom: 10px;
                border-radius: 10px;
                overflow: hidden;
                border: 1px solid #33455e;
            }
            .slds-accordion__summary-action {
                background: linear-gradient(135deg, #001a5e 0%, #003087 55%, #004db3 100%) !important;
                border-radius: 10px !important;
                padding: 14px 16px !important;
                margin: 0px;
                font-weight: 500;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.35);
            }
            .slds-accordion__summary-action,
            .slds-accordion__summary-action * {
                color: #ffffff !important;
            }
            .slds-accordion__summary-action-icon,
            .slds-accordion__summary-action-icon svg {
                fill: #ffffff !important;
                color: #ffffff !important;
            }
            .slds-accordion__section {
                background-color: #0e1c30 !important;
                border-color: #33455e !important;
            }
        `;

        // Append the styles to the .styleContainer
        this.template.querySelector(".styleContainer")?.appendChild(style);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
       // window.removeEventListener("focus", this.handleTabFocus);
    }

    handlePricingRefresh() {
        console.log('Pubsub Event received: refreshing PricingApproval');
        //this.spinner = true;
        fireEvent(this.pageRef, 'refreshCharges', {});
        Promise.all([
            this.loadPicklistValues(),
            this.loadLoanDetails(),
            this.checkExistingSanctionLetter()
        ])
        .then(() => {
            this.mainAccordianActiveSection = ['Charges', 'LoandDetails', 'ApprovalHistory', 'SanctionLetter'];
            this.showOpenAll = false;
            
        })
        .finally(() => {
            //this.spinner = false;
        });
    }

    @track loanFinalAmount=0;
    //async handleChildUpdateForResanction(payload) {
    handleChildUpdateForResanction(payload) {
        console.log('Resanction check triggered from child with data:', payload);
        //this.resetResanctionFlagOnOpp();
        if (payload?.isUpdateDone) {
            // Delay for DB commit
            setTimeout(() => {
                console.log('Waiting done, fetching updated loan details...');
    
                // const data = await getLatestLoanRecords({ opportunityId: this.recordId }) //July 7, setTimeout
                getLatestLoanRecords({ opportunityId: this.recordId })
                    .then((data) => {
                        if (data && data.length > 0) {
                            let record = data[0];
                            this.originalData = {
                                Id: record.Id,
                                Sanction_Tenure__c: record.Sanction_Tenure__c,
                                Sanction_Rate_Of_Interest__c: record.Sanction_Rate_Of_Interest__c,
                                Sanction_Loan_Amount__c: record.Sanction_Loan_Amount__c,
                                Negotiated_Tenure__c: record.Negotiated_Tenure__c,
                                Negotiated_Loan_Amount__c: record.Negotiated_Loan_Amount__c,
                                Negotiated_Rate_Of_Interest__c: record.Negotiated_Rate_Of_Interest__c,
                                Emi_amount__c: record.Emi_amount__c,
                                Product__c: record.Product__c,
                                Repayment_Facility__c: record.Repayment_Facility__c,
                                Final_Amount__c: record.Final_Amount__c
                            };
    
                            this.loanData.product = record.Product__c;
                            this.loanData.subProduct = record.Sub_Product__c;
                            this.loanData.rePaymentFacility = record.Repayment_Facility__c;
                            this.loanData.scheme = record.Scheme__c;
                            this.loanData.customerProfile = record.Customer_Profile__c;
                            this.loanParameters = [
                                { id: 1, Parameter: 'Loan Amount (INR)', field: 'Negotiated_Loan_Amount__c', sanctionedValue: record.Sanction_Loan_Amount__c, negotiatedValue: record.Negotiated_Loan_Amount__c,finalValue: record.Final_Amount__c, isdisabled: true },
                                { id: 2, Parameter: 'ROI (In %)', field: 'Negotiated_Rate_Of_Interest__c', sanctionedValue: record.Sanction_Rate_Of_Interest__c, negotiatedValue: record.Negotiated_Rate_Of_Interest__c,finalValue: record.Final_Rate_Of_Interest__c, isdisabled: true },
                                { id: 3, Parameter: 'Tenure (In Month)', field: 'Negotiated_Tenure__c', sanctionedValue: record.Sanction_Tenure__c, negotiatedValue: record.Negotiated_Tenure__c,finalValue: record.Final_Tenure__c, isdisabled: true }
                                //{ id: 4, Parameter: 'EMI Amount (INR)', sanctionedValue: record.Emi_amount__c, negotiatedValue: record.Emi_amount__c,finalValue: record.Emi_amount__c, isdisabled: true }
                            ];
    
                            console.log('Fetched updated final amount:', record.Final_Amount__c);
                            this.loanFinalAmount = record.Final_Amount__c;
                            this.spinner = false;
                            // Now continue the rest of the flow
                            getChargesApprovalCriteria()
                            .then(result => {
                                this.metadataRecords = result;

                            })
                            .catch(error => {
                                console.error('Error fetching metadata:', error);
                            });
                            //this.getChargesApprovalCriteria();
                            this.loadPicklistValues();
                            this.loadChargesRecords();
                            if(payload?.method == 'POSP' || payload?.method == 'Insurance'){
                                this.isEdit = true;
                                this.showResanctionNotes = false;
                                this.isEnableApprovalHis = false;
                                this.handleSave();
                            }else{
                                this.isEdit = true;
                                this.updateIsEdit();
                                this.showResanctionNotes = false;
                                this.isEnableApprovalHis = false;
                                this.handleSave();
                            }
                            
                        }
                    })
                    .catch(error => {
                        console.error('Error fetching loan details:', error);
                    });
    
            }, 5000); // Wait for DB commit
        } else {
            console.log('Resanction triggered without backend update');
        }
    }

    resetResanctionFlagOnOpp() {
        resetResanctionFlag({ opportunityId: this.recordId })
            .then(() => {
                console.log('Resanction__c successfully reset to false');
            })
            .catch(error => {
                console.error('Error resetting Resanction__c flag:', error);
                this.showToast('Error', 'Failed to reset Resanction flag', 'error');
            });
    }

    async getPicklistOptionsFromApex(isPicklist, storageObject, storageField) {
        if (isPicklist) {
            const result = await getPicklistValuesScreen({
                storageObject: storageObject,
                storageField: storageField
            });
            let picklistOptions = result.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });
            return picklistOptions;
        }
    }

}