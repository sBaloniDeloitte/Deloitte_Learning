import { LightningElement, track, api, wire } from 'lwc';
import getChargesRecords from '@salesforce/apex/COMM_CreditChargesTableController.getChargesRecords';
import getPicklistValues from '@salesforce/apex/COMM_CreditChargesTableController.getPicklistValues';
import getVASOnlyOppDetails from '@salesforce/apex/ChargesInsuranceCmpController.getVASOnlyOppDetails';
import updateChargesRecords from '@salesforce/apex/COMM_CreditChargesTableController.updateChargesRecords';
import getMetadataValue from '@salesforce/apex/COMM_PricingApprovalController.getMetadataValue';
import getScreenDetails from '@salesforce/apex/ScreenGenerationController.getScreenDetails';
import getPicklistValuesScreen from '@salesforce/apex/ScreenGenerationController.getPicklistValues';
// import getDetailsForDisbursement from '@salesforce/apex/LoanTransactionController.getDetailsForDisbursement';
import getLoanDetailsFromStorageObject from '@salesforce/apex/ScreenGenerationController.getLoanDetailsFromStorageObject';
import getChargesApprovalCriteria from '@salesforce/apex/COMM_PricingApprovalController.getChargesApprovalCriteria';
import getLoanRecords from '@salesforce/apex/COMM_PricingApprovalController.getLoanRecords';
import getLatestLoanRecords from '@salesforce/apex/COMM_PricingApprovalController.getLatestLoanRecords';
import updateNegotiatedValues from '@salesforce/apex/COMM_PricingApprovalController.updateNegotiatedValues';
import updateFinalValues from '@salesforce/apex/COMM_PricingApprovalController.updateFinalValues';
import { getRecord, updateRecord, getFieldValue } from 'lightning/uiRecordApi';
import RESANCTION from '@salesforce/schema/Opportunity.Resanction__c';
import PRICINGAPPROVAL from '@salesforce/schema/Opportunity.Pricing_Approval_Status__c';
import ELIGIBLE_FOR_RESANCTION from '@salesforce/schema/Opportunity.Eligible_for_Resanction__c';
import IS_PRICING_APPROVAL_REQUIRED from '@salesforce/schema/Opportunity.Is_Pricing_Approval_Required__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import initiateAPIRequest from '@salesforce/apex/COMM_SanctionLetterController.initiateAPIRequest';
import initiateAPRAPIRequest from '@salesforce/apex/COMM_APRController.initiateAPRAPIRequest';
import getExistingSanctionLetter from '@salesforce/apex/COMM_SanctionLetterController.getExistingSanctionLetter';
import resetResanctionFlag from '@salesforce/apex/COMM_PricingApprovalController.resetResanctionFlag';
import resetPricingFlag from '@salesforce/apex/COMM_PricingApprovalController.resetPricingFlag';
import canUserEditChargesPricing from '@salesforce/apex/COMM_CreditChargesTableController.canUserEditChargesPricing';
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
import getLoanProductRecords from '@salesforce/apex/COMM_PricingApprovalController.getLoanProductRecords';
import canUserEditRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.canUserEditRecord';//Kalpesh
//updated
import SAVED_ROI_FIELD from '@salesforce/schema/Opportunity.HL_Saved_Offer_ROI_Impact_Percent__c';
import IS_OFFER_APPLIED_FIELD from '@salesforce/schema/Opportunity.HL_Is_Offer_Applied__c';
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
//import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
// import OFFER_APPLY_CHANNEL from '@salesforce/messageChannel/OfferApplyMessageChannel__c';
import checkeSignStatus from '@salesforce/apex/Utility_V1.checkeSignStatus';
//end updated
const LOAN_FIELDS = ['Opportunity.StageName'];
import checkChildLoan from '@salesforce/apex/COMM_PricingApprovalController.checkChildLoan';
import getUserRoleSales from '@salesforce/apex/Hl_CovenantsDetailFormController.getUserRoleSales';
import updateEligibleforResanction from '@salesforce/apex/Utility_V1.updateEligibleforResanction';
import NEGOTIATED_DSA_IMPACT__FIELD from "@salesforce/schema/Opportunity.Negotiated_DSA_Impact__c";
import FINAL_DSA_IMPACT__FIELD from "@salesforce/schema/Opportunity.Final_DSA_Impact__c";


export default class PricingApproval extends LightningElement {
    hideApprovalHistory = false;
    @api recordId;
    @track rows = [];
    @track metadataRecords = [];
    @track selectedMetadataRecords = [];
    @track chargesNamesMap = new Map();

    @track fieldDetails;
    @track loanParameters = [];
    @track loanParametersAHLChild = [];
    @track loanParametersANHL = [];
    @track loanParametersANHLChild = [];
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
    @track isEnableApprovalHis = false
    showApprovalButton = false;
    originalData = {};
    originalDataAHLChild = {};
    originalDataANHL = {};
    originalDataANHLChild = {};
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
        roiDiffAHLChild:0,
        loanAmountANHLChild: 0,
        roiANHLChild: 0,
        tenureANHLChild: 0,
        roiDiffANHLChild:0
        //loanAmountDiff: 0,
        //tenureDiff :0
    };

    userProfileName = '';
    showSections = true;
    @track ahlProductName = '';
    @track ahlChildProductName = '';
    @track flProductName = '';
    @track anhlProductName = '';
    @track anhlChildProductName = '';
    @track ahlProductId = '';
    @track ahlChildProductId = '';
    @track flProductId = '';
    @track anhlProductId = '';
    @track anhlChildProductId = '';
    @track showEligibilitySection=false;//Added by kalpesh

    @track isEditableUser = true;
    @track isEditHidden = false; //Sanwar
    //updated
    savedRoiImpact = null;
    isOfferApplied = false;
    @track isHlRelated=false;
    @track esignStatus;
    @track showConfirmation= false;
    @track confirmation= false;
    //end updated

    // Anish - 26/03 - LAP
    isLapRelated = false;
    accordianLabel = 'Home Loan Details';

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
    //updated
   /* @wire(MessageContext)
    messageContext;
    subscription = null;
    //end updated*/

    @track showCmp = false;
    @track isLoading = false;
    @track isChildLoan=false;
    @track isDSAdisabled = true;
    @track dsaOriginalValue = 0;
    @track dsaNegotiatedValue = 0;
    @track dsaFinalValue = 0;

    connectedCallback() {
        this.getProductDetails();
        this.fetchCurrentUserDetails();
        this.getScreenDetailsFromApex(); //by arman 11july2025
        //this.subscribeToMessageChannel();//updated
        canUserEditChargesPricing({ opportunityId: this.recordId })
        .then(result => {
            console.log('res 151>>>>'+result);
            this.isEditableUser = result;
            if(this.isEditableUser){
                this.isEdit =  false;
            }

            console.log('Is editable user:', this.isEditableUser);
        })
        .catch(error => {
            console.error('Error checking user access for VAS:', error);
            this.isEditableUser = false; // Default to read-only if error
        });

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

        this.checkChildLoan();
    }

    checkChildLoan(){
        checkChildLoan({recordId: this.recordId})
        .then(response => {
            console.log('response in checkChildLoan'+response);
            this.isChildLoan= response;
        })
        .catch(error => {
            console.log(error);
        });
    }

    getProductDetails(){
        console.log('1528'+this.recordId);
        const inputMap = {
            'oppId': this.recordId
        }
        console.log('1528'+this.recordId);
        getProductDetails({inputMap: inputMap})
        .then(response => {
            console.log('response'+response);
            if(response.loanProduct == 'Home Loan'||response.loanProduct=='Non Home Loan'||response.loanProduct=='Flexi Loan'){
                this.isHlRelated = true;
                this.accordianLabel = response.loanProduct + ' Details';
                checkeSignStatus({loanId : this.recordId})
                .then(res =>{
                    console.log('result product: '+ res);
                    this.esignStatus = res;
                })
                .catch(error=>{
                    console.error('error in getting product: '+ error)
                })
            }
        })
        .catch(error => {
            console.log(error);
        });
    }

        @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD, SUBSTAGE_FIELD, LOAN_HIERARCHY_FIELD, NEGOTIATED_DSA_IMPACT__FIELD,FINAL_DSA_IMPACT__FIELD] })
    opportunity({ error, data }) {
        if(data) {
            this.oppStage = data.fields.StageName.value;
            this.oppSubStage = data.fields.Sub_stage__c.value;
            this.loanHierarchy = data.fields.Loan_Hierarchy__c.value
            console.log('Opp sub stage' , this.oppSubStage);
            this.dsaOriginalValue = data.fields.Negotiated_DSA_Impact__c.value;
            this.dsaNegotiatedValue = data.fields.Negotiated_DSA_Impact__c.value;
            this.dsaFinalValue = data.fields.Final_DSA_Impact__c.value;
            setTimeout(() => {
                this.handleVisibility();
                
                //for parent loan
                // if(this.loanHierarchy == 'Parent'){
                //    this.isEditableUser = false;
                //     this.loanParameters = this.loanParameters.map(field => {
                //         return{
                //             ...field,
                //             isdisabled : true
                //         }
                //     })
                // }
            }, 1000);
        }
    }

    handleVisibility(){
        console.log('Stage', this.oppStage);
        console.log(' Sub stage At 238', this.oppSubStage);
        //added by kalpesh-start
        if(this.oppStage == 'Disbursement' && !this.isHlRelated){
            this.showEligibilitySection=false;
            this.isEditableUser = false;
        }
        if( this.oppSubStage=='PSV Sales'){
            this.showEligibilitySection=false;
        //  this.isEditableUser = true;
            this.isEdit=false;
        }
        if( this.oppSubStage=='PSV Credit'){
            this.showEligibilitySection=false;
            this.isEditableUser = true;
            this.isEdit=false;
        }
          //added by kalpesh-end
        getUserRole({ recordId: this.recordId })
        .then(result => {
            if(result && !this.isHlRelated && this.oppStage == 'Disbursement' && this.oppSubStage == 'Ops Maker'){
                this.isEditableUser = false;

                this.loanParameters = this.loanParameters.map(field => {
                    return{
                        ...field,
                        isdisabled : true
                    }
                })
            }
            getUserRoleSales({recordId: this.recordId})
            .then(result => {
                if(result && this.isHlRelated && ((this.oppStage == 'Disbursement' && this.oppSubStage == 'Ops Maker')||this.oppStage == 'PSV') ){
                    this.isEditableUser= true;
                }//commenting the else part because in AHL cases this is overwriting the isEditableUser flag to false without checking any condition
                // else{
                //     this.isEditableUser= false;
                // }
            })
            if(!this.isHlRelated){
                canUserEditRecord({ recordId: this.recordId })
                .then(result => {
                    if(result){
                        console.log('inside edit>>>',result);
                        this.isEditableUser = false;

                        this.loanParameters = this.loanParameters.map(field => {
                            return{
                                ...field,
                                isdisabled : true
                            }
                        })
                    }
                })
                console.log(' Sub stage At 359', this.isEditableUser);
            }
        })
        //kalpesh start
        
        

        //kalpesh end
    }

    fetchCurrentUserDetails(){
        getCurrentUserDetails({ })
        .then(result => {
            this.userProfileName = result[0];

            if(result[0] === 'GC Tele Sales User'){
                this.showSections = false;
            }
        })
        .catch(error => {
            console.error('Error fetching profile name: ', error);
        });
    }
    //updated
    @wire(getRecord, { recordId: '$recordId', fields: [RESANCTION, PRICINGAPPROVAL, ELIGIBLE_FOR_RESANCTION,IS_PRICING_APPROVAL_REQUIRED,SAVED_ROI_FIELD, IS_OFFER_APPLIED_FIELD] })
    wiredOpportunity({ error, data }) {
        if (data) {
                console.log('getRecord@@'+JSON.stringify(data));
            this.opportunity = data;
            this.updateIsEdit(); // Call method after getting data
            // updated
            // 1. Store the values from the record
            //this.isOfferApplied = getFieldValue(data, IS_OFFER_APPLIED_FIELD);
            //this.savedRoiImpact = getFieldValue(data, SAVED_ROI_FIELD);

            // 2. If the table data is already loaded, apply the calculation now.
            //    This fixes the "refresh" bug.
            if (this.loanParameters.length > 0) {
                //this.applySavedOfferOnLoad();
            }
            // end updated
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

    handleLoadingChange(event) {
        console.log('inside handleloadingchange');
        this.isLoading = event.detail.isLoading;
        console.log('this.isLoading:: '+this.isLoading);
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
                this.isEnableApprovalHis = true;
                this.showApprovalButton = true;

            }
        }else if(this.isPricingApproval_Required == true){

            this.isEnableApprovalHis = true;
            this.showApprovalButton = true;
           

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
            if(record.Is_Pricing_Approval_Required__c || (!record.Is_Pricing_Approval_Required__c && (record.Pricing_Approval_Status__c =='Approved'|| record.Pricing_Approval_Status__c =='Rejected' ||record.Pricing_Approval_Status__c == 'Submitted For Approval'))){//Sanwar
                //change by Kunal Bisht for SFHL-1404 - start
                if(this.isHlRelated){
                    this.showApprovalButton = true; 
                }
                //change by Kunal Bisht for SFHL-1404 - end
                this.isEnableApprovalHis = true;
            }else if(record.Is_Pricing_Approval_Required__c == false){
                this.isEnableApprovalHis = false;
            }
            if(record.Pricing_Approval_Status__c == 'Submitted For Approval'){
                this.isEdit = true;
                this.isSave = true;
                this.isEditHidden = true;//sanwar
            }
            if(record.Pricing_Approval_Status__c =='Approved'){//Sanwar
                this.isEdit = false;
                this.isEditHidden = false;
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
                //get the affordable home loan details    
                let ahlRecordList = data.filter(record => (record.Product__r.Product_Master__r.Name === 'Affordable Home Loan' || record.Product__r.Product_Master__r.Name === 'Home Loan' || record.Product__r.Product_Master__r.Name === 'Non Home Loan') && record.Product__r.Product_Type__c == 'Parent');
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
                let ahlChildRecordList = data.filter(record => (record.Product__r.Product_Master__r.Name === 'Affordable Home Loan' ||
                    record.Product__r.Product_Master__r.Name === 'Home Loan') && record.Product__r.Product_Type__c == 'Child');
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
                let anhlRecordList = data.filter(record => (record.Product__r.Product_Master__r.Name == 'Affordable Non-Home Loan' || record.Product__r.Product_Master__r.Name === 'Non-Home Loan') && record.Product__r.Product_Type__c == 'Parent');
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


                //get the affordable non-home loan child details    
                let anhlChildRecordList = data.filter(record => (record.Product__r.Product_Master__r.Name === 'Affordable Non-Home Loan' ||
                    record.Product__r.Product_Master__r.Name === 'Non-Home Loan') && record.Product__r.Product_Type__c == 'Child');
                if(anhlChildRecordList.length > 0){
                    this.anhlChildProductId = anhlChildRecordList[0].Id;
                    this.anhlChildProductName = anhlChildRecordList[0].Product__r.Product_Master__r.Name;
                    this.originalDataANHLChild = {
                        Id: anhlChildRecordList[0].Id,
                        Negotiated_Tenure__c: anhlChildRecordList[0].Negotiated_Tenure__c,
                        Negotiated_Loan_Amount__c: anhlChildRecordList[0].Negotiated_Loan_Amount__c,
                        Negotiated_ROI__c: anhlChildRecordList[0].Negotiated_ROI__c
                    };

                    this.loanParametersANHLChild = [
                        { 
                            id: 1, Parameter: 'Loan Amount (INR)', field: 'Negotiated_Loan_Amount__c', 
                            sanctionedValue: this.formatDisplayValue(anhlChildRecordList[0].Sanctioned_Loan_Amount__c,false), 
                            negotiatedValueANHLChild: this.formatDisplayValue(anhlChildRecordList[0].Negotiated_Loan_Amount__c,false),
                            finalValue: this.formatDisplayValue(anhlChildRecordList[0].Final_Loan_Amount__c,false), 
                            isdisabled: true,productName: this.anhlChildProductName,
                            step: '1' 
                        },
                        { 
                            id: 2, Parameter: 'ROI (In %)', field: 'Negotiated_ROI__c', 
                            sanctionedValue: this.formatDisplayValue(anhlChildRecordList[0].Sanctioned_ROI__c,true), 
                            negotiatedValueANHLChild: this.formatDisplayValue(anhlChildRecordList[0].Negotiated_ROI__c,true),
                            finalValue: this.formatDisplayValue(anhlChildRecordList[0].Final_ROI__c,true), 
                            isdisabled: true,productName: this.anhlChildProductName,
                            step: '0.01' 
                        },
                        { 
                            id: 3, Parameter: 'Tenure (In Month)', field: 'Negotiated_Tenure__c', 
                            sanctionedValue: this.formatDisplayValue(anhlChildRecordList[0].Sanctioned_Tenor__c,false), 
                            negotiatedValueANHLChild: this.formatDisplayValue(anhlChildRecordList[0].Negotiated_Tenure__c,false),
                            finalValue: this.formatDisplayValue(anhlChildRecordList[0].Final_Tenure__c,false), 
                            isdisabled: true,productName: this.anhlChildProductName,
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
            //updated
            //this.applySavedOfferOnLoad();
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

    getFieldFavorability(rows, negotiatedField) {
        let roiFavorable = false;
        let amountFavorable = false;
        rows.forEach(row => {
            const newVal = parseFloat(row[negotiatedField]);
            const finalVal = parseFloat(row.finalValue);
            if (isNaN(newVal) || isNaN(finalVal)) {
                return;
            }
            if (row.Parameter === 'ROI (In %)' && newVal > finalVal) {
                roiFavorable = true;
            }
            if (row.Parameter === 'Loan Amount (INR)' && newVal < finalVal) {
                amountFavorable = true;
            }
        });
        return { roiFavorable: roiFavorable, amountFavorable: amountFavorable };
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
        this.mainAccordianActiveSection = ['Charges', 'LoandDetails', 'ApprovalHistory', 'SanctionLetter'];
        // Hide the "Open All" button if needed
        this.showOpenAll = false;
    }

    handleCloseAllSections() {
        this.showOpenAll = true;
        this.mainAccordianActiveSection = [];
    }

    handleDSAOnChange(event) {
       this.dsaNegotiatedValue = event.target.value?event.target.value : 0;
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

    handleloanDetailChangeANHLChild(event) {
        
        const rowId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.loanParametersANHLChild = this.loanParametersANHLChild.map((row) => {
            if (row.id == rowId) {
                row[field] = value;
            }
            return row;
        });

    }
    //Sanwar
    handleEnableApproval(event) {
        this.isEnableApprovalHis = event.detail.isChargesWaived;
        this.showApprovalButton = event.detail.isChargesWaived;
        console.log('Approval history enabled:', this.isEnableApprovalHis);
    }
    //Sanwar
    handleEditButton(){
        this.isEditHidden = true;
    }

    //sanwar
    loanLoanData(){
        this.template.querySelector('c-credit-charges-table').runCheckMethod();
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

    handleGensancLett() {
        this.isLoading = true;
        this.errorMessage = '';
        this.pdfUrl = '';
    
        let params = {
            loanId: this.recordId,
            processName: 'Loan APR Calculation'
        };

        // const resp = await initiateAPRAPIRequest({ inputMap: params })
        initiateAPRAPIRequest({ inputMap: params })
        .then(resp => {
            try {
                console.log('APR response:: '+resp);

                if(resp === 'Success'){
                    params = {
                        loanId: this.recordId,
                        processName: 'Sanction Letter Generation'
                    };
                
                    initiateAPIRequest({ inputMap: params })
                    .then(response => {
                        setTimeout(() => {
                            try {
                                console.log('response:: '+JSON.stringify(response));
                                let parsed = JSON.parse(response);
                
                                // Case 1: Proper Success
                                if (
                                    parsed?.response?.status === true &&
                                    parsed?.response?.base64StringForPDF
                                ) {
                                    this.displayGenerateSanctionLetter = false;
                                    this.showMessage = false;
                                    this.renderPDF(parsed.response.base64StringForPDF);
                                } 
                                // Case 2: API returned error with message
                                else if (parsed?.message) {
                                    this.errorMessage = parsed.message;
                                    console.error('API Error Message:', parsed.message);
                                } 
                                // Case 3: Generic fallback
                                else {
                                    this.errorMessage = 'Unexpected response from API.';
                                    console.error('Unknown API response:', parsed);
                                }
                                this.isLoading = false;
                            } catch (e) {
                                this.errorMessage = 'Error parsing API response.';
                                console.error('Parsing Exception:', e);
                                this.isLoading = false;
                            }
                        }, 30000);
                        
                    })
                    .catch(error => {
                        console.error('JS/Network error:', error);
                        this.errorMessage = 'Sanction letter generation failed.';
                        this.isLoading = false;
                    });
                }
                else{
                    this.errorMessage = resp;
                    this.isLoading = false;
                }
            } 
            catch (e) {
                this.errorMessage = 'Error APR API response.';
                console.error('Parsing Exception:', e);
                this.isLoading = false;
            } 
        })
        .catch(error => {
            console.error('JS/Network error:', error);
            this.errorMessage = 'Sanction letter generation failed.';
            this.isLoading = false;
        });
    }

    handleRegenerateSanctionLetter() {
        this.isLoading = true;
        this.errorMessage = '';
        this.pdfUrl = '';
    
        let params = {
            loanId: this.recordId,
            processName: 'Sanction Letter Generation',
            isRegenerate: true
        };
    
        initiateAPIRequest({ inputMap: params })
        .then(response => {
            try {
                console.log('response:: '+JSON.stringify(response));
                let parsed = JSON.parse(response);

                // Case 1: Proper Success
                if (
                    parsed?.response?.status === true &&
                    parsed?.response?.base64StringForPDF
                ) {
                    this.displayGenerateSanctionLetter = false;
                    this.showMessage = false;
                    this.renderPDF(parsed.response.base64StringForPDF);
                } 
                // Case 2: API returned error with message
                else if (parsed?.message) {
                    this.errorMessage = parsed.message;
                    console.error('API Error Message:', parsed.message);
                } 
                // Case 3: Generic fallback
                else {
                    this.errorMessage = 'Unexpected response from API.';
                    console.error('Unknown API response:', parsed);
                }
                this.isLoading = false;
            } catch (e) {
                this.errorMessage = 'Error parsing API response.';
                console.error('Parsing Exception:', e);
                this.isLoading = false;
            }
        })
        .catch(error => {
            console.error('JS/Network error:', error);
            this.errorMessage = 'Sanction letter generation failed.';
            this.isLoading = false;
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

    /*handleTabFocus() {
        console.log('Tab focused - refreshing component');
        //this.spinner = true;// Show spinner
        setTimeout(() => {
            Promise.all([
                this.loadPicklistValues(),
                this.loadLoanDetails(),
                this.checkExistingSanctionLetter()
            ])
            .then(() => {
                //this.spinner = false;
                console.log('Reload completed');
            })
            .catch(error => {
                //this.spinner = false;
                console.error('Error during reload:', error);
            })
            .finally(() => {
                //this.spinner = false; 
            });
        
            // Collect all active section names from fieldDetails
            this.mainAccordianActiveSection = ['Charges', 'LoandDetails', 'ApprovalHistory', 'SanctionLetter'];
            // Hide the "Open All" button if needed
            this.showOpenAll = false;
        }, 2000); // Delay of 500ms
    }*/



    @track displayGenerateSanctionLetter = false; 
    @track infoMessage = ''; // New property to store the approval in progress message   
    @track showMessage = false;    

    checkExistingSanctionLetter() {
        this.isLoading = true;
        this.errorMessage = '';
        this.infoMessage = '';
        
        getExistingSanctionLetter({ loanId: this.recordId })
            .then(response => {
                // Handle the Map response
                if (response.existingDocument) {
                    // If there's an existing document, render it
                    this.renderPDF(response.existingDocument);
                } else if (response.shouldHitAPI) {
                    // If API call is needed, you can trigger it here
                    //this.handleGensancLett(); // Auto-generate if API is needed
                    this.displayGenerateSanctionLetter = true;
                }
                if (response.message) {
                    this.infoMessage = response.message;
                    this.showMessage = true;
                }
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error checking existing sanction letter:', error);
                this.errorMessage = 'Error checking existing sanction letter.';
                this.isLoading = false;
            });
    }
    isEditDisabled = false;
    isApprove = true;
    handleEdit() {
        this.isEditDisabled = false;
        this.showResanctionNotes = false
        // this.isEnableApprovalHis = false //Sanwar
        if(this.isHlRelated && this.isChildLoan){
            this.loanParameters = this.loanParameters.map(row => {
                console.log('OUTPUT : 1135', row.Parameter);
                if (row.Parameter == 'EMI Amount (INR)' || (this.isVASOnlyOpp && this.loanStage==='PSV' && row.Parameter == 'Loan Amount (INR)')) {
                    return { ...row, isdisabled: true };
                }else if(row.Parameter == 'Loan Amount (INR)' || row.Parameter == 'Tenure (In Month)'){
                    return { ...row, isdisabled: true };
                }else{
                    return { ...row, isdisabled: false };
                }
            // return row;
            });
        }else{
            this.isDSAdisabled = false;
            this.loanParameters = this.loanParameters.map(row => {
                console.log('OUTPUT : 1147', row.Parameter);
                if (row.Parameter == 'EMI Amount (INR)' || (this.isVASOnlyOpp && this.loanStage==='PSV' && row.Parameter == 'Loan Amount (INR)')) {
                    return { ...row, isdisabled: true };
                }else{
                    return { ...row, isdisabled: false };
                }
            // return row;
            });
        }
        console.log('OUTPUT : this.loanParametersFL 1154', this.loanParameters);

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

        this.loanParametersANHLChild = this.loanParametersANHLChild.map(row => {
            if (row.Parameter == 'EMI Amount (INR)' || (this.isVASOnlyOpp && this.loanStage==='PSV' && row.Parameter == 'Loan Amount (INR)')) {
                return { ...row, isdisabled: true };
            }else{
                return { ...row, isdisabled: false };
            }
           // return row;
        });

        console.log('OUTPUT : this.isHlRelated 1188',this.isHlRelated );
        console.log('OUTPUT : this.isChildLoan', this.isChildLoan);
        if(this.isHlRelated && this.isChildLoan){
            
            this.loanParametersFL = this.loanParametersFL.map(row => {
                console.log('OUTPUT : 1188', row.Parameter);
                if (row.Parameter == 'EMI Amount (INR)' || (this.isVASOnlyOpp && this.loanStage==='PSV' && row.Parameter == 'Loan Amount (INR)')) {
                    return { ...row, isdisabled: true };
                }else if(row.Parameter == 'Loan Amount (INR)' || row.Parameter == 'Tenure (In Month)'){
                    return { ...row, isdisabled: true };
                }else{
                    return { ...row, isdisabled: false };
                }
            // return row;
            });
            console.log('OUTPUT : this.loanParametersFL 1181', this.loanParametersFL);
        }else{
            this.loanParametersFL = this.loanParametersFL.map(row => {
                console.log('OUTPUT : 1201', row.Parameter);
                if (row.Parameter == 'EMI Amount (INR)' || (this.isVASOnlyOpp && this.loanStage==='PSV' && row.Parameter == 'Loan Amount (INR)')) {
                    return { ...row, isdisabled: true };
                }else{
                    return { ...row, isdisabled: false };
                }
            // return row;
            });
        }
        

        this.isSave = false;
        this.isEdit = true;
        this.isApprove = true;

    }
    isLoaded = true

    handleRefreshDetails(){
        console.log('handleRefreshDetails>>>');
        this.connectedCallback();
    }

    handleyes(event){
        this.confirmation= true;
        this.handleSave();
        this.showConfirmation=false;
    }

    handleClose(event){
        this.showConfirmation= false;
    }
    //async handleSave() { //July 7, setTimeout
    /*handleSave() {
        
        if(this.isHlRelated && this.esignStatus== 'Esign Completed' && this.confirmation ){
            console.log('1244---------');
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

            console.log('this.loanParametersANHLChild@@', JSON.stringify(this.loanParametersANHLChild));
            this.loanParametersANHLChild = this.loanParametersANHLChild.map(row => {
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
            let updatedValuesANHLChild = {};
            let updatedValuesFL = {};


            this.loanParameters.map((row) => {
                console.log('row>>>'+row);
            if (row.Parameter != 'EMI Amount (INR)' && this.originalData[row.field] != row.negotiatedValue) {
                updatedValues[row.field] = row.negotiatedValue;
            }
            if (row.Parameter === 'Loan Amount (INR)') {
                this.loanData.loanAmount = row.negotiatedValue - row.sanctionedValue;
            }
            if (row.Parameter === 'ROI (In %)') {
                this.loanData.roi = (row.negotiatedValue || 0);
                this.loanData.roiDiff = row.sanctionedValue - row.negotiatedValue;
            }
            if (row.Parameter === 'Tenure (In Month)') {
                this.loanData.tenure = (row.negotiatedValue || 0) - (row.sanctionedValue || 0);
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


            this.loanParametersANHLChild.map((row) => {
            if (row.Parameter != 'EMI Amount (INR)' && this.originalDataANHLChild[row.field] != row.negotiatedValueANHLChild) {
                updatedValuesANHLChild[row.field] = row.negotiatedValueANHLChild;
            }
            if (row.Parameter === 'Loan Amount (INR)') {
                this.loanData.loanAmountANHLChild = row.negotiatedValueANHLChild - row.sanctionedValue;
            }
            if (row.Parameter === 'ROI (In %)') {
                this.loanData.roiANHLChild = (row.negotiatedValueANHLChild || 0);
                this.loanData.roiDiffANHLChild = row.sanctionedValue - row.negotiatedValueANHLChild;
            }
            if (row.Parameter === 'Tenure (In Month)') {
                this.loanData.tenureANHLChild = (row.negotiatedValueANHLChild || 0) - (row.sanctionedValue || 0);
            }
            });

            console.log('this.loanParametersANHLChild>>>'+JSON.stringify(this.loanParametersANHLChild));


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
            console.log('updatedValuesANHLChild--', updatedValuesANHLChild);
            console.log('updatedValuesFL--', updatedValuesFL);
            if (Object.keys(updatedValues).length === 0 && Object.keys(updatedValuesAHLChild).length === 0 && Object.keys(updatedValuesFL).length === 0 && Object.keys(updatedValuesANHL).length === 0 && Object.keys(updatedValuesANHLChild).length === 0) {
                this.showToast('No Changes', 'No modifications detected', 'info');
                return;
            }

            const favAHL = this.getFieldFavorability(this.loanParameters, 'negotiatedValue');
            const favAHLChild = this.getFieldFavorability(this.loanParametersAHLChild, 'negotiatedValueAHLChild');
            const favANHL = this.getFieldFavorability(this.loanParametersANHL, 'negotiatedValueANHL');
            const favANHLChild = this.getFieldFavorability(this.loanParametersANHLChild, 'negotiatedValueANHLChild');
            const favFL = this.getFieldFavorability(this.loanParametersFL, 'negotiatedValueFL');
            console.log('favAHL--', JSON.stringify(favAHL));
            console.log('favAHLChild--', JSON.stringify(favAHLChild));
            console.log('favANHL--', JSON.stringify(favANHL));
            console.log('favANHLChild--', JSON.stringify(favANHLChild));
            console.log('favFL--', JSON.stringify(favFL));

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

            if (Object.keys(updatedValuesANHLChild).length > 0) {
                if (updatedValuesANHLChild.hasOwnProperty('Negotiated_Tenure__c')){
                    if(updatedValuesANHLChild['Negotiated_Tenure__c'] == ''){
                        this.showToast('Error', 'Please enter the Negotiated Tenure', 'error');
                        return;
                    }
                }
                if (updatedValuesANHLChild.hasOwnProperty('Negotiated_Loan_Amount__c')){
                    if(updatedValuesANHLChild['Negotiated_Loan_Amount__c'] == ''){
                        this.showToast('Error', 'Please enter the Negotiated Loan Amount', 'error');
                        return;
                    }
                }
                if (updatedValuesANHLChild.hasOwnProperty('Negotiated_ROI__c')){
                    if(updatedValuesANHLChild['Negotiated_ROI__c'] == ''){
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

            let promises = [];

            if (Object.keys(updatedValues).length > 0) {
                console.log('updatedValues 1220>>>'+updatedValues);
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValues, productName : this.ahlProductId })
                .then(() => {
                    this.loanParameters.forEach(data=>{
                        if(updatedValues[data.field] !== undefined){
                            data.negotiatedValue = updatedValues[data.field];
                            data.finalValue = updatedValues[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                    this.loadLoanDetails();
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values AHL', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesAHLChild).length > 0) {
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesAHLChild, productName : this.ahlChildProductId })
                .then(() => {
                    this.loanParametersAHLChild.forEach(data=>{
                        if(updatedValuesAHLChild[data.field] !== undefined){
                            data.negotiatedValueAHLChild = updatedValuesAHLChild[data.field];
                            data.finalValue = updatedValuesAHLChild[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values AHL Child', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesANHL).length > 0) {
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesANHL, productName : this.anhlProductId })
                .then(() => {
                    this.loanParametersANHL.forEach(data=>{
                        if(updatedValuesANHL[data.field] !== undefined){
                            data.negotiatedValueANHL = updatedValuesANHL[data.field];
                            data.finalValue = updatedValuesANHL[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values ANHL', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesANHLChild).length > 0) {
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesANHLChild, productName : this.anhlChildProductId })
                .then(() => {
                    this.loanParametersANHLChild.forEach(data=>{
                        if(updatedValuesANHLChild[data.field] !== undefined){
                            data.negotiatedValueANHLChild = updatedValuesANHLChild[data.field];
                            data.finalValue = updatedValuesANHLChild[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values ANHL Child', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesFL).length > 0) {
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesFL, productName : this.flProductId })
                .then(() => {
                    this.loanParametersFL.forEach(data=>{
                        if(updatedValuesFL[data.field] !== undefined){
                            data.negotiatedValueFL = updatedValuesFL[data.field];
                            data.finalValue = updatedValuesFL[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                    if(this.isHlRelated){
                        this.loadLoanDetails(); // Aditya A hotfix/roiFlagTrigger
                    }
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values FL', 'error');
                });
                promises.push(p);
            }

            Promise.all(promises).then(() => {
                if (Object.keys(updatedValues).length > 0) {
                    console.log('call process criteria AHL');
                    this.processApprovalCriteria(favAHL);
                }
                if (Object.keys(updatedValuesAHLChild).length > 0 && this.showResanctionNotes == false && this.isEnableApprovalHis == false) {
                    console.log('call process criteria AHL Child');
                    this.processApprovalCriteriaForAHLChild(favAHLChild);
                }
                if (Object.keys(updatedValuesANHL).length > 0 && this.showResanctionNotes == false && this.isEnableApprovalHis == false) {
                    console.log('call process criteria ANHL');
                    this.processApprovalCriteriaForANHL(favANHL);
                }
                if (Object.keys(updatedValuesANHLChild).length > 0 && this.showResanctionNotes == false && this.isEnableApprovalHis == false) {
                    console.log('call process criteria ANHL Child');
                    this.processApprovalCriteriaForANHLChild(favANHLChild);
                }
                if (Object.keys(updatedValuesFL).length > 0 && this.showResanctionNotes == false && this.isEnableApprovalHis == false) {
                    console.log('call process criteria FL');
                    this.processApprovalCriteriaForFL(favFL);
                }

                console.log('this.showResanctionNotes after criteria', this.showResanctionNotes);
                console.log('this.isEnableApprovalHis after criteria', this.isEnableApprovalHis);

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
                    const inputMap = {
                        'loanId': this.recordId,
                        'eligible': this.showResanctionNotes,
                        'pricingApproval': this.isEnableApprovalHis
                    }
                    console.log('1528'+this.recordId);
                    updateEligibleforResanction({inputMap: inputMap})
                    .then(response => {
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
                        console.log(error);
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'Failed to update Eligible for Resanction',
                                variant: 'error'
                            })
                        );
                    });
                    console.log('Update Error:', error);
                });

                if(this.isEnableApprovalHis){
                    console.log('refreshing approval process');
                    this.template.querySelector('c-loan-approval-process').refresh();
                }
            });

            }, 5000);
        }
        else if(this.isHlRelated && this.esignStatus== 'Esign Completed' && !this.confirmation){
            this.showConfirmation= true;
        }else if(!this.isHlRelated || this.esignStatus!= 'Esign Completed'){
            this.isLoaded = false
            this.loadPicklistValues();

            setTimeout(() => {
                console.log('776>>>');
                console.log('776>>> 1044', this.reSanction);
            console.log('776>>> 1044' ,this.pricing_Approval_Status);
                        this.isLoaded = true
            this.selectedMetadataRecords = [];

            this.isSave = true
            this.isEdit = false

            if (this.reSanction === true || this.pricing_Approval_Status != '' || this.pricing_Approval_Status != 'Approved') {
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

            console.log('this.loanParametersANHLChild@@', JSON.stringify(this.loanParametersANHLChild));
            this.loanParametersANHLChild = this.loanParametersANHLChild.map(row => {
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
            let updatedValuesANHLChild = {};
            let updatedValuesFL = {};

            //DSA Impact logic
            this.isDSAdisabled = true;
            const dsaValueDiff = Math.abs(parseFloat(this.dsaOriginalValue?this.dsaOriginalValue:0) - parseFloat(this.dsaNegotiatedValue?this.dsaNegotiatedValue:0));
            if (this.dsaNegotiatedValue != null && dsaValueDiff > 0 && this.dsaNegotiatedValue != this.dsaOriginalValue) { 
                this.showResanctionNotes = false;
                this.isEnableApprovalHis = true;
                this.showApprovalButton = true;
                const fields = {
                    Id: this.recordId,
                    Negotiated_DSA_Impact__c: this.dsaNegotiatedValue
                };
                const recordInput = { fields };
                updateRecord(recordInput)
                .then(() => {
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                })
                .catch(error => {
                        console.log('Error while saving DSA Imapct::' + JSON.stringify(error));
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'Failed to update Negotiated DSA Impact',
                                variant: 'error'
                            })
                        );
                });
            }

            this.loanParameters.map((row) => {
                console.log('row>>>'+row);
            if (row.Parameter != 'EMI Amount (INR)' && this.originalData[row.field] != row.negotiatedValue) {
                updatedValues[row.field] = row.negotiatedValue;
            }
            if (row.Parameter === 'Loan Amount (INR)') {
                this.loanData.loanAmount = row.negotiatedValue - row.sanctionedValue;
            }
            if (row.Parameter === 'ROI (In %)') {
                this.loanData.roi = (row.negotiatedValue || 0);
                this.loanData.roiDiff = row.sanctionedValue - row.negotiatedValue;
            }
            if (row.Parameter === 'Tenure (In Month)') {
                this.loanData.tenure = (row.negotiatedValue || 0) - (row.sanctionedValue || 0);
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


            this.loanParametersANHLChild.map((row) => {
            if (row.Parameter != 'EMI Amount (INR)' && this.originalDataANHLChild[row.field] != row.negotiatedValueANHLChild) {
                updatedValuesANHLChild[row.field] = row.negotiatedValueANHLChild;
            }
            if (row.Parameter === 'Loan Amount (INR)') {
                this.loanData.loanAmountANHLChild = row.negotiatedValueANHLChild - row.sanctionedValue;
            }
            if (row.Parameter === 'ROI (In %)') {
                this.loanData.roiANHLChild = (row.negotiatedValueANHLChild || 0);
                this.loanData.roiDiffANHLChild = row.sanctionedValue - row.negotiatedValueANHLChild;
            }
            if (row.Parameter === 'Tenure (In Month)') {
                this.loanData.tenureANHLChild = (row.negotiatedValueANHLChild || 0) - (row.sanctionedValue || 0);
            }
            });

            console.log('this.loanParametersANHLChild>>>'+JSON.stringify(this.loanParametersANHLChild));


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

            console.log('this.loanParametersFL>>>1'+JSON.stringify(this.loanParametersFL));

            console.log('updatedValues--', updatedValues);
            console.log('updatedValuesAHLChild--', updatedValuesAHLChild);
            console.log('updatedValuesANHL--', updatedValuesANHL);
            console.log('updatedValuesANHLChild--', updatedValuesANHLChild);
            console.log('updatedValuesFL--', updatedValuesFL);
            if (Object.keys(updatedValues).length === 0 && Object.keys(updatedValuesAHLChild).length === 0 && Object.keys(updatedValuesFL).length === 0 && Object.keys(updatedValuesANHL).length === 0 && Object.keys(updatedValuesANHLChild).length === 0 && this.dsaNegotiatedValue == this.dsaOriginalValue) {
                this.showToast('No Changes', 'No modifications detected', 'info');
                return;
            }

            const favAHL = this.getFieldFavorability(this.loanParameters, 'negotiatedValue');
            const favAHLChild = this.getFieldFavorability(this.loanParametersAHLChild, 'negotiatedValueAHLChild');
            const favANHL = this.getFieldFavorability(this.loanParametersANHL, 'negotiatedValueANHL');
            const favANHLChild = this.getFieldFavorability(this.loanParametersANHLChild, 'negotiatedValueANHLChild');
            const favFL = this.getFieldFavorability(this.loanParametersFL, 'negotiatedValueFL');
            console.log('favAHL--', JSON.stringify(favAHL));
            console.log('favAHLChild--', JSON.stringify(favAHLChild));
            console.log('favANHL--', JSON.stringify(favANHL));
            console.log('favANHLChild--', JSON.stringify(favANHLChild));
            console.log('favFL--', JSON.stringify(favFL));

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

            if (Object.keys(updatedValuesANHLChild).length > 0) {
                if (updatedValuesANHLChild.hasOwnProperty('Negotiated_Tenure__c')){
                    if(updatedValuesANHLChild['Negotiated_Tenure__c'] == ''){
                        this.showToast('Error', 'Please enter the Negotiated Tenure', 'error');
                        return;
                    }
                }
                if (updatedValuesANHLChild.hasOwnProperty('Negotiated_Loan_Amount__c')){
                    if(updatedValuesANHLChild['Negotiated_Loan_Amount__c'] == ''){
                        this.showToast('Error', 'Please enter the Negotiated Loan Amount', 'error');
                        return;
                    }
                }
                if (updatedValuesANHLChild.hasOwnProperty('Negotiated_ROI__c')){
                    if(updatedValuesANHLChild['Negotiated_ROI__c'] == ''){
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

            let promises = [];

            if (Object.keys(updatedValues).length > 0) {
                console.log('updatedValues 1220>>>'+updatedValues);
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValues, productName : this.ahlProductId })
                .then(() => {
                    this.loanParameters.forEach(data=>{
                        if(updatedValues[data.field] !== undefined){
                            data.negotiatedValue = updatedValues[data.field];
                            data.finalValue = updatedValues[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                    this.loadLoanDetails();
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values AHL', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesAHLChild).length > 0) {
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesAHLChild, productName : this.ahlChildProductId })
                .then(() => {
                    this.loanParametersAHLChild.forEach(data=>{
                        if(updatedValuesAHLChild[data.field] !== undefined){
                            data.negotiatedValueAHLChild = updatedValuesAHLChild[data.field];
                            data.finalValue = updatedValuesAHLChild[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values AHL Child', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesANHL).length > 0) {
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesANHL, productName : this.anhlProductId })
                .then(() => {
                    this.loanParametersANHL.forEach(data=>{
                        if(updatedValuesANHL[data.field] !== undefined){
                            data.negotiatedValueANHL = updatedValuesANHL[data.field];
                            data.finalValue = updatedValuesANHL[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values ANHL', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesANHLChild).length > 0) {
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesANHLChild, productName : this.anhlChildProductId })
                .then(() => {
                    this.loanParametersANHLChild.forEach(data=>{
                        if(updatedValuesANHLChild[data.field] !== undefined){
                            data.negotiatedValueANHLChild = updatedValuesANHLChild[data.field];
                            data.finalValue = updatedValuesANHLChild[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values ANHL Child', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesFL).length > 0) {
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesFL, productName : this.flProductId })
                .then(() => {
                    this.loanParametersFL.forEach(data=>{
                        if(updatedValuesFL[data.field] !== undefined){
                            data.negotiatedValueFL = updatedValuesFL[data.field];
                            data.finalValue = updatedValuesFL[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                    if(this.isHlRelated){
                        this.loadLoanDetails(); // Aditya A hotfix/roiFlagTrigger
                    }
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values FL', 'error');
                });
                promises.push(p);
            }

            Promise.all(promises).then(() => {
                if (Object.keys(updatedValues).length > 0) {
                    console.log('call process criteria AHL');
                    this.processApprovalCriteria(favAHL);
                }
                if (Object.keys(updatedValuesAHLChild).length > 0 && this.showResanctionNotes == false && this.isEnableApprovalHis == false) {
                    console.log('call process criteria AHL Child');
                    this.processApprovalCriteriaForAHLChild(favAHLChild);
                }
                if (Object.keys(updatedValuesANHL).length > 0 && this.showResanctionNotes == false && this.isEnableApprovalHis == false) {
                    console.log('call process criteria ANHL');
                    this.processApprovalCriteriaForANHL(favANHL);
                }
                if (Object.keys(updatedValuesANHLChild).length > 0 && this.showResanctionNotes == false && this.isEnableApprovalHis == false) {
                    console.log('call process criteria ANHL Child');
                    this.processApprovalCriteriaForANHLChild(favANHLChild);
                }
                if (Object.keys(updatedValuesFL).length > 0 && this.showResanctionNotes == false && this.isEnableApprovalHis == false) {
                    console.log('call process criteria FL');
                    this.processApprovalCriteriaForFL(favFL);
                }

                console.log('this.showResanctionNotes after criteria', this.showResanctionNotes);
                console.log('this.isEnableApprovalHis after criteria', this.isEnableApprovalHis);

                if(Object.keys(updatedValues).length > 0 || Object.keys(updatedValuesFL).length > 0 || Object.keys(updatedValuesANHL).length > 0 || Object.keys(updatedValuesAHLChild).length > 0 || Object.keys(updatedValuesANHLChild).length > 0 || (this.dsaNegotiatedValue != null && dsaValueDiff > 0 && this.dsaNegotiatedValue != this.dsaOriginalValue)){
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
                        const inputMap = {
                            'loanId': this.recordId,
                            'eligible': this.showResanctionNotes,
                            'pricingApproval': this.isEnableApprovalHis
                        }
                        console.log('1528'+this.recordId);
                        updateEligibleforResanction({inputMap: inputMap})
                        .then(response => {
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
                            console.log(error);
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: 'Failed to update Eligible for Resanction',
                                    variant: 'error'
                                })
                            );
                        });
                        console.log('Update Error:', error);
                    });
                }

                if(this.isEnableApprovalHis){
                    console.log('refreshing approval process');
                    this.template.querySelector('c-loan-approval-process').refresh();
                }
            });

            }, 5000);
        }
        if(this.isHlRelated){
            const fields = {
                Id: this.recordId,
                DocGen_Status__c: 'DocGen Not-Initiated'
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
        }
    }*/
    
    handleSave() {
        if(this.isHlRelated && this.esignStatus== 'Esign Completed' && this.confirmation ){
            console.log('1244---------');
            this.isLoaded = false
            this.loadPicklistValues();

            setTimeout(() => {
                console.log('776>>>');
                        this.isLoaded = true
            this.selectedMetadataRecords = [];

            this.isSave = true;
            this.isEdit = false;
            this.isApprove = false;
            /*if (this.reSanction === true || this.pricing_Approval_Status !== '') {
            this.isSave = true
            this.isEdit = true
            }*/
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

            console.log('this.loanParametersANHLChild@@', JSON.stringify(this.loanParametersANHLChild));
            this.loanParametersANHLChild = this.loanParametersANHLChild.map(row => {
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
            let updatedValuesANHLChild = {};
            let updatedValuesFL = {};


            this.loanParameters.map((row) => {
                console.log('row>>>'+row);
            if (row.Parameter != 'EMI Amount (INR)' && this.originalData[row.field] != row.negotiatedValue) {
                updatedValues[row.field] = row.negotiatedValue;
            }
            if (row.Parameter === 'Loan Amount (INR)') {
                this.loanData.loanAmount = row.negotiatedValue - row.sanctionedValue;
            }
            if (row.Parameter === 'ROI (In %)') {
                this.loanData.roi = (row.negotiatedValue || 0);
                this.loanData.roiDiff = row.sanctionedValue - row.negotiatedValue;
            }
            if (row.Parameter === 'Tenure (In Month)') {
                this.loanData.tenure = (row.negotiatedValue || 0) - (row.sanctionedValue || 0);
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


            this.loanParametersANHLChild.map((row) => {
            if (row.Parameter != 'EMI Amount (INR)' && this.originalDataANHLChild[row.field] != row.negotiatedValueANHLChild) {
                updatedValuesANHLChild[row.field] = row.negotiatedValueANHLChild;
            }
            if (row.Parameter === 'Loan Amount (INR)') {
                this.loanData.loanAmountANHLChild = row.negotiatedValueANHLChild - row.sanctionedValue;
            }
            if (row.Parameter === 'ROI (In %)') {
                this.loanData.roiANHLChild = (row.negotiatedValueANHLChild || 0);
                this.loanData.roiDiffANHLChild = row.sanctionedValue - row.negotiatedValueANHLChild;
            }
            if (row.Parameter === 'Tenure (In Month)') {
                this.loanData.tenureANHLChild = (row.negotiatedValueANHLChild || 0) - (row.sanctionedValue || 0);
            }
            });

            console.log('this.loanParametersANHLChild>>>'+JSON.stringify(this.loanParametersANHLChild));


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
            console.log('updatedValuesANHLChild--', updatedValuesANHLChild);
            console.log('updatedValuesFL--', updatedValuesFL);
            if (Object.keys(updatedValues).length === 0 && Object.keys(updatedValuesAHLChild).length === 0 && Object.keys(updatedValuesFL).length === 0 && Object.keys(updatedValuesANHL).length === 0 && Object.keys(updatedValuesANHLChild).length === 0) {
                this.showToast('No Changes', 'No modifications detected', 'info');
                return;
            }

            const favAHL = this.getFieldFavorability(this.loanParameters, 'negotiatedValue');
            const favAHLChild = this.getFieldFavorability(this.loanParametersAHLChild, 'negotiatedValueAHLChild');
            const favANHL = this.getFieldFavorability(this.loanParametersANHL, 'negotiatedValueANHL');
            const favANHLChild = this.getFieldFavorability(this.loanParametersANHLChild, 'negotiatedValueANHLChild');
            const favFL = this.getFieldFavorability(this.loanParametersFL, 'negotiatedValueFL');
            console.log('favAHL--', JSON.stringify(favAHL));
            console.log('favAHLChild--', JSON.stringify(favAHLChild));
            console.log('favANHL--', JSON.stringify(favANHL));
            console.log('favANHLChild--', JSON.stringify(favANHLChild));
            console.log('favFL--', JSON.stringify(favFL));

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

            if (Object.keys(updatedValuesANHLChild).length > 0) {
                if (updatedValuesANHLChild.hasOwnProperty('Negotiated_Tenure__c')){
                    if(updatedValuesANHLChild['Negotiated_Tenure__c'] == ''){
                        this.showToast('Error', 'Please enter the Negotiated Tenure', 'error');
                        return;
                    }
                }
                if (updatedValuesANHLChild.hasOwnProperty('Negotiated_Loan_Amount__c')){
                    if(updatedValuesANHLChild['Negotiated_Loan_Amount__c'] == ''){
                        this.showToast('Error', 'Please enter the Negotiated Loan Amount', 'error');
                        return;
                    }
                }
                if (updatedValuesANHLChild.hasOwnProperty('Negotiated_ROI__c')){
                    if(updatedValuesANHLChild['Negotiated_ROI__c'] == ''){
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

            let promises = [];

            if (Object.keys(updatedValues).length > 0) {
                console.log('updatedValues 1220>>>'+updatedValues);
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValues, productName : this.ahlProductId })
                .then(() => {
                    this.loanParameters.forEach(data=>{
                        if(updatedValues[data.field] !== undefined){
                            data.negotiatedValue = updatedValues[data.field];
                            data.finalValue = updatedValues[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                    this.loadLoanDetails();
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values AHL', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesAHLChild).length > 0) {
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesAHLChild, productName : this.ahlChildProductId })
                .then(() => {
                    this.loanParametersAHLChild.forEach(data=>{
                        if(updatedValuesAHLChild[data.field] !== undefined){
                            data.negotiatedValueAHLChild = updatedValuesAHLChild[data.field];
                            //data.finalValue = updatedValuesAHLChild[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values AHL Child', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesANHL).length > 0) {
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesANHL, productName : this.anhlProductId })
                .then(() => {
                    this.loanParametersANHL.forEach(data=>{
                        if(updatedValuesANHL[data.field] !== undefined){
                            data.negotiatedValueANHL = updatedValuesANHL[data.field];
                            data.finalValue = updatedValuesANHL[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values ANHL', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesANHLChild).length > 0) {
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesANHLChild, productName : this.anhlChildProductId })
                .then(() => {
                    this.loanParametersANHLChild.forEach(data=>{
                        if(updatedValuesANHLChild[data.field] !== undefined){
                            data.negotiatedValueANHLChild = updatedValuesANHLChild[data.field];
                            data.finalValue = updatedValuesANHLChild[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values ANHL Child', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesFL).length > 0) {
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesFL, productName : this.flProductId })
                .then(() => {
                    this.loanParametersFL.forEach(data=>{
                        if(updatedValuesFL[data.field] !== undefined){
                            data.negotiatedValueFL = updatedValuesFL[data.field];
                            data.finalValue = updatedValuesFL[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                    if(this.isHlRelated){
                        this.loadLoanDetails(); // Aditya A hotfix/roiFlagTrigger
                    }
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values FL', 'error');
                });
                promises.push(p);
            }

            }, 5000);
        }
        else if(this.isHlRelated && this.esignStatus== 'Esign Completed' && !this.confirmation){
            this.showConfirmation= true;
        }else if(!this.isHlRelated || this.esignStatus!= 'Esign Completed'){
            this.isLoaded = false
            this.loadPicklistValues();

            setTimeout(() => {
                console.log('776>>>');
                console.log('776>>> 1044', this.reSanction);
            console.log('776>>> 1044' ,this.pricing_Approval_Status);
                        this.isLoaded = true
            this.selectedMetadataRecords = [];

            this.isSave = true;
            this.isEdit = false;
            this.isApprove = false;

            /*if (this.reSanction === true || this.pricing_Approval_Status != '' || this.pricing_Approval_Status != 'Approved') {
            this.isSave = true
            this.isEdit = true
            }*/
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

            console.log('this.loanParametersANHLChild@@', JSON.stringify(this.loanParametersANHLChild));
            this.loanParametersANHLChild = this.loanParametersANHLChild.map(row => {
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
            let updatedValuesANHLChild = {};
            let updatedValuesFL = {};

            //DSA Impact logic
            this.isDSAdisabled = true;
            const dsaValueDiff = Math.abs(parseFloat(this.dsaOriginalValue?this.dsaOriginalValue:0) - parseFloat(this.dsaNegotiatedValue?this.dsaNegotiatedValue:0));
            if (this.dsaNegotiatedValue != null && dsaValueDiff > 0 && this.dsaNegotiatedValue != this.dsaOriginalValue) { 
                this.showResanctionNotes = false;
                this.isEnableApprovalHis = true;
                this.showApprovalButton = true;
                const fields = {
                    Id: this.recordId,
                    Negotiated_DSA_Impact__c: this.dsaNegotiatedValue
                };
                const recordInput = { fields };
                updateRecord(recordInput)
                .then(() => {
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                })
                .catch(error => {
                        console.log('Error while saving DSA Imapct::' + JSON.stringify(error));
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'Failed to update Negotiated DSA Impact',
                                variant: 'error'
                            })
                        );
                });
            }

            this.loanParameters.map((row) => {
                console.log('row>>>'+row);
            if (row.Parameter != 'EMI Amount (INR)' && this.originalData[row.field] != row.negotiatedValue) {
                updatedValues[row.field] = row.negotiatedValue;
            }
            if (row.Parameter === 'Loan Amount (INR)') {
                this.loanData.loanAmount = row.negotiatedValue - row.sanctionedValue;
            }
            if (row.Parameter === 'ROI (In %)') {
                this.loanData.roi = (row.negotiatedValue || 0);
                this.loanData.roiDiff = row.sanctionedValue - row.negotiatedValue;
            }
            if (row.Parameter === 'Tenure (In Month)') {
                this.loanData.tenure = (row.negotiatedValue || 0) - (row.sanctionedValue || 0);
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


            this.loanParametersANHLChild.map((row) => {
            if (row.Parameter != 'EMI Amount (INR)' && this.originalDataANHLChild[row.field] != row.negotiatedValueANHLChild) {
                updatedValuesANHLChild[row.field] = row.negotiatedValueANHLChild;
            }
            if (row.Parameter === 'Loan Amount (INR)') {
                this.loanData.loanAmountANHLChild = row.negotiatedValueANHLChild - row.sanctionedValue;
            }
            if (row.Parameter === 'ROI (In %)') {
                this.loanData.roiANHLChild = (row.negotiatedValueANHLChild || 0);
                this.loanData.roiDiffANHLChild = row.sanctionedValue - row.negotiatedValueANHLChild;
            }
            if (row.Parameter === 'Tenure (In Month)') {
                this.loanData.tenureANHLChild = (row.negotiatedValueANHLChild || 0) - (row.sanctionedValue || 0);
            }
            });

            console.log('this.loanParametersANHLChild>>>'+JSON.stringify(this.loanParametersANHLChild));


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

            console.log('this.loanParametersFL>>>1'+JSON.stringify(this.loanParametersFL));

            console.log('updatedValues--', updatedValues);
            console.log('updatedValuesAHLChild--', updatedValuesAHLChild);
            console.log('updatedValuesANHL--', updatedValuesANHL);
            console.log('updatedValuesANHLChild--', updatedValuesANHLChild);
            console.log('updatedValuesFL--', updatedValuesFL);
            if (Object.keys(updatedValues).length === 0 && Object.keys(updatedValuesAHLChild).length === 0 && Object.keys(updatedValuesFL).length === 0 && Object.keys(updatedValuesANHL).length === 0 && Object.keys(updatedValuesANHLChild).length === 0 && this.dsaNegotiatedValue == this.dsaOriginalValue) {
                this.showToast('No Changes', 'No modifications detected', 'info');
                return;
            }

            const favAHL = this.getFieldFavorability(this.loanParameters, 'negotiatedValue');
            const favAHLChild = this.getFieldFavorability(this.loanParametersAHLChild, 'negotiatedValueAHLChild');
            const favANHL = this.getFieldFavorability(this.loanParametersANHL, 'negotiatedValueANHL');
            const favANHLChild = this.getFieldFavorability(this.loanParametersANHLChild, 'negotiatedValueANHLChild');
            const favFL = this.getFieldFavorability(this.loanParametersFL, 'negotiatedValueFL');
            console.log('favAHL--', JSON.stringify(favAHL));
            console.log('favAHLChild--', JSON.stringify(favAHLChild));
            console.log('favANHL--', JSON.stringify(favANHL));
            console.log('favANHLChild--', JSON.stringify(favANHLChild));
            console.log('favFL--', JSON.stringify(favFL));

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

            if (Object.keys(updatedValuesANHLChild).length > 0) {
                if (updatedValuesANHLChild.hasOwnProperty('Negotiated_Tenure__c')){
                    if(updatedValuesANHLChild['Negotiated_Tenure__c'] == ''){
                        this.showToast('Error', 'Please enter the Negotiated Tenure', 'error');
                        return;
                    }
                }
                if (updatedValuesANHLChild.hasOwnProperty('Negotiated_Loan_Amount__c')){
                    if(updatedValuesANHLChild['Negotiated_Loan_Amount__c'] == ''){
                        this.showToast('Error', 'Please enter the Negotiated Loan Amount', 'error');
                        return;
                    }
                }
                if (updatedValuesANHLChild.hasOwnProperty('Negotiated_ROI__c')){
                    if(updatedValuesANHLChild['Negotiated_ROI__c'] == ''){
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

            let promises = [];

            if (Object.keys(updatedValues).length > 0) {
                console.log('updatedValues 1220>>>'+updatedValues);
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValues, productName : this.ahlProductId })
                .then(() => {
                    this.loanParameters.forEach(data=>{
                        if(updatedValues[data.field] !== undefined){
                            data.negotiatedValue = updatedValues[data.field];
                            data.finalValue = updatedValues[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                    this.loadLoanDetails();
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values AHL', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesAHLChild).length > 0) {
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesAHLChild, productName : this.ahlChildProductId })
                .then(() => {
                    this.loanParametersAHLChild.forEach(data=>{
                        if(updatedValuesAHLChild[data.field] !== undefined){
                            data.negotiatedValueAHLChild = updatedValuesAHLChild[data.field];
                            //data.finalValue = updatedValuesAHLChild[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values AHL Child', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesANHL).length > 0) {
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesANHL, productName : this.anhlProductId })
                .then(() => {
                    this.loanParametersANHL.forEach(data=>{
                        if(updatedValuesANHL[data.field] !== undefined){
                            data.negotiatedValueANHL = updatedValuesANHL[data.field];
                            data.finalValue = updatedValuesANHL[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values ANHL', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesANHLChild).length > 0) {
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesANHLChild, productName : this.anhlChildProductId })
                .then(() => {
                    this.loanParametersANHLChild.forEach(data=>{
                        if(updatedValuesANHLChild[data.field] !== undefined){
                            data.negotiatedValueANHLChild = updatedValuesANHLChild[data.field];
                            data.finalValue = updatedValuesANHLChild[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values ANHL Child', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesFL).length > 0) {
                let p = updateNegotiatedValues({ opportunityId: this.recordId, updatedFields: updatedValuesFL, productName : this.flProductId })
                .then(() => {
                    this.loanParametersFL.forEach(data=>{
                        if(updatedValuesFL[data.field] !== undefined){
                            data.negotiatedValueFL = updatedValuesFL[data.field];
                            data.finalValue = updatedValuesFL[data.field];
                        }
                    });
                    this.showToast('Success', 'Negotiated values updated successfully!', 'success');
                    if(this.isHlRelated){
                        this.loadLoanDetails(); // Aditya A hotfix/roiFlagTrigger
                    }
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values FL', 'error');
                });
                promises.push(p);
            }
            /*
            Promise.all(promises).then(() => {
                if (Object.keys(updatedValues).length > 0) {
                    console.log('call process criteria AHL');
                    this.processApprovalCriteria(favAHL);
                }
                if (Object.keys(updatedValuesAHLChild).length > 0 && this.showResanctionNotes == false && this.isEnableApprovalHis == false) {
                    console.log('call process criteria AHL Child');
                    this.processApprovalCriteriaForAHLChild(favAHLChild);
                }
                if (Object.keys(updatedValuesANHL).length > 0 && this.showResanctionNotes == false && this.isEnableApprovalHis == false) {
                    console.log('call process criteria ANHL');
                    this.processApprovalCriteriaForANHL(favANHL);
                }
                if (Object.keys(updatedValuesANHLChild).length > 0 && this.showResanctionNotes == false && this.isEnableApprovalHis == false) {
                    console.log('call process criteria ANHL Child');
                    this.processApprovalCriteriaForANHLChild(favANHLChild);
                }
                if (Object.keys(updatedValuesFL).length > 0 && this.showResanctionNotes == false && this.isEnableApprovalHis == false) {
                    console.log('call process criteria FL');
                    this.processApprovalCriteriaForFL(favFL);
                }

                console.log('this.showResanctionNotes after criteria', this.showResanctionNotes);
                console.log('this.isEnableApprovalHis after criteria', this.isEnableApprovalHis);
                /*
                if(Object.keys(updatedValues).length > 0 || Object.keys(updatedValuesFL).length > 0 || Object.keys(updatedValuesANHL).length > 0 || Object.keys(updatedValuesAHLChild).length > 0 || Object.keys(updatedValuesANHLChild).length > 0 || (this.dsaNegotiatedValue != null && dsaValueDiff > 0 && this.dsaNegotiatedValue != this.dsaOriginalValue)){
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
                        const inputMap = {
                            'loanId': this.recordId,
                            'eligible': this.showResanctionNotes,
                            'pricingApproval': this.isEnableApprovalHis
                        }
                        console.log('1528'+this.recordId);
                        updateEligibleforResanction({inputMap: inputMap})
                        .then(response => {
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
                            console.log(error);
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: 'Failed to update Eligible for Resanction',
                                    variant: 'error'
                                })
                            );
                        });
                        console.log('Update Error:', error);
                    });
                }

                if(this.isEnableApprovalHis){
                    console.log('refreshing approval process');
                    this.template.querySelector('c-loan-approval-process').refresh();
                }
            });*/

            }, 5000);
        }
        /*
        if(this.isHlRelated){
            const fields = {
                Id: this.recordId,
                DocGen_Status__c: 'DocGen Not-Initiated'
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
        }*/
    }

    handleApprove() {
        if(this.isHlRelated && this.esignStatus== 'Esign Completed' && this.confirmation ){
            console.log('1244---------');
            this.isLoaded = false
            this.loadPicklistValues();

            setTimeout(() => {
                console.log('776>>>');
                        this.isLoaded = true
            this.selectedMetadataRecords = [];

            this.isSave = true;
            this.isEdit = false;
            this.isApprove = false;
            /*if (this.reSanction === true || this.pricing_Approval_Status !== '') {
            this.isSave = true
            this.isEdit = true
            }*/
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

            console.log('this.loanParametersANHLChild@@', JSON.stringify(this.loanParametersANHLChild));
            this.loanParametersANHLChild = this.loanParametersANHLChild.map(row => {
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
            let updatedValuesANHLChild = {};
            let updatedValuesFL = {};


            this.loanParameters.map((row) => {
                console.log('row>>>'+row);
            if (row.Parameter != 'EMI Amount (INR)' && this.originalData[row.field] != row.negotiatedValue) {
                updatedValues[row.field] = row.negotiatedValue;
            }
            if (row.Parameter === 'Loan Amount (INR)') {
                this.loanData.loanAmount = row.negotiatedValue - row.sanctionedValue;
            }
            if (row.Parameter === 'ROI (In %)') {
                this.loanData.roi = (row.negotiatedValue || 0);
                this.loanData.roiDiff = row.sanctionedValue - row.negotiatedValue;
            }
            if (row.Parameter === 'Tenure (In Month)') {
                this.loanData.tenure = (row.negotiatedValue || 0) - (row.sanctionedValue || 0);
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


            this.loanParametersANHLChild.map((row) => {
            if (row.Parameter != 'EMI Amount (INR)' && this.originalDataANHLChild[row.field] != row.negotiatedValueANHLChild) {
                updatedValuesANHLChild[row.field] = row.negotiatedValueANHLChild;
            }
            if (row.Parameter === 'Loan Amount (INR)') {
                this.loanData.loanAmountANHLChild = row.negotiatedValueANHLChild - row.sanctionedValue;
            }
            if (row.Parameter === 'ROI (In %)') {
                this.loanData.roiANHLChild = (row.negotiatedValueANHLChild || 0);
                this.loanData.roiDiffANHLChild = row.sanctionedValue - row.negotiatedValueANHLChild;
            }
            if (row.Parameter === 'Tenure (In Month)') {
                this.loanData.tenureANHLChild = (row.negotiatedValueANHLChild || 0) - (row.sanctionedValue || 0);
            }
            });

            console.log('this.loanParametersANHLChild>>>'+JSON.stringify(this.loanParametersANHLChild));


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

            const favAHL = this.getFieldFavorability(this.loanParameters, 'negotiatedValue');
            const favAHLChild = this.getFieldFavorability(this.loanParametersAHLChild, 'negotiatedValueAHLChild');
            const favANHL = this.getFieldFavorability(this.loanParametersANHL, 'negotiatedValueANHL');
            const favANHLChild = this.getFieldFavorability(this.loanParametersANHLChild, 'negotiatedValueANHLChild');
            const favFL = this.getFieldFavorability(this.loanParametersFL, 'negotiatedValueFL');

            let promises = [];

            if (Object.keys(updatedValues).length > 0) {
                console.log('updatedValues 1220>>>'+updatedValues);
                let p = updateFinalValues({ opportunityId: this.recordId, updatedFields: updatedValues, productName : this.ahlProductId })
                .then(() => {
                    this.loanParameters.forEach(data=>{
                        if(updatedValues[data.field] !== undefined){
                            data.negotiatedValue = updatedValues[data.field];
                            data.finalValue = updatedValues[data.field];
                        }
                    });
                    this.showToast('Success', 'Final values updated successfully!', 'success');
                    this.isApprove = true;
                    this.loadLoanDetails();
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values AHL', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesAHLChild).length > 0) {
                let p = updateFinalValues({ opportunityId: this.recordId, updatedFields: updatedValuesAHLChild, productName : this.ahlChildProductId })
                .then(() => {
                    this.loanParametersAHLChild.forEach(data=>{
                        if(updatedValuesAHLChild[data.field] !== undefined){
                            data.negotiatedValueAHLChild = updatedValuesAHLChild[data.field];
                            data.finalValue = updatedValuesAHLChild[data.field];
                        }
                    });
                    this.showToast('Success', 'Final values updated successfully!', 'success');
                    this.isApprove = true;
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values AHL Child', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesANHL).length > 0) {
                let p = updateFinalValues({ opportunityId: this.recordId, updatedFields: updatedValuesANHL, productName : this.anhlProductId })
                .then(() => {
                    this.loanParametersANHL.forEach(data=>{
                        if(updatedValuesANHL[data.field] !== undefined){
                            data.negotiatedValueANHL = updatedValuesANHL[data.field];
                            data.finalValue = updatedValuesANHL[data.field];
                        }
                    });
                    this.showToast('Success', 'Final values updated successfully!', 'success');
                    this.isApprove = true;
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values ANHL', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesANHLChild).length > 0) {
                let p = updateFinalValues({ opportunityId: this.recordId, updatedFields: updatedValuesANHLChild, productName : this.anhlChildProductId })
                .then(() => {
                    this.loanParametersANHLChild.forEach(data=>{
                        if(updatedValuesANHLChild[data.field] !== undefined){
                            data.negotiatedValueANHLChild = updatedValuesANHLChild[data.field];
                            data.finalValue = updatedValuesANHLChild[data.field];
                        }
                    });
                    this.showToast('Success', 'Final values updated successfully!', 'success');
                    this.isApprove = true;
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values ANHL Child', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesFL).length > 0) {
                let p = updateFinalValues({ opportunityId: this.recordId, updatedFields: updatedValuesFL, productName : this.flProductId })
                .then(() => {
                    this.loanParametersFL.forEach(data=>{
                        if(updatedValuesFL[data.field] !== undefined){
                            data.negotiatedValueFL = updatedValuesFL[data.field];
                            data.finalValue = updatedValuesFL[data.field];
                        }
                    });
                    this.showToast('Success', 'Final values updated successfully!', 'success');
                    this.isApprove = true;
                    if(this.isHlRelated){
                        this.loadLoanDetails(); // Aditya A hotfix/roiFlagTrigger
                    }
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values FL', 'error');
                });
                promises.push(p);
            }

            }, 5000);
        }
        else if(this.isHlRelated && this.esignStatus== 'Esign Completed' && !this.confirmation){
            this.showConfirmation= true;
        }else if(!this.isHlRelated || this.esignStatus!= 'Esign Completed'){
            this.isLoaded = false
            this.loadPicklistValues();

            setTimeout(() => {
                console.log('776>>>');
                console.log('776>>> 1044', this.reSanction);
            console.log('776>>> 1044' ,this.pricing_Approval_Status);
                        this.isLoaded = true
            this.selectedMetadataRecords = [];

            this.isSave = true;
            this.isEdit = false;
            this.isApprove = false;

            /*if (this.reSanction === true || this.pricing_Approval_Status != '' || this.pricing_Approval_Status != 'Approved') {
            this.isSave = true
            this.isEdit = true
            }*/
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

            console.log('this.loanParametersANHLChild@@', JSON.stringify(this.loanParametersANHLChild));
            this.loanParametersANHLChild = this.loanParametersANHLChild.map(row => {
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
            let updatedValuesANHLChild = {};
            let updatedValuesFL = {};

            //DSA Impact logic
            this.isDSAdisabled = true;
            const dsaValueDiff = Math.abs(parseFloat(this.dsaOriginalValue?this.dsaOriginalValue:0) - parseFloat(this.dsaNegotiatedValue?this.dsaNegotiatedValue:0));
            if (this.dsaNegotiatedValue != null && dsaValueDiff > 0 && this.dsaNegotiatedValue != this.dsaOriginalValue) { 
                this.showResanctionNotes = false;
                this.isEnableApprovalHis = true;
                this.showApprovalButton = true;
                const fields = {
                    Id: this.recordId,
                    Negotiated_DSA_Impact__c: this.dsaNegotiatedValue
                };
                const recordInput = { fields };
                updateRecord(recordInput)
                .then(() => {
                    this.showToast('Success', 'Final values updated successfully!', 'success');
                    this.isApprove = true;
                })
                .catch(error => {
                        console.log('Error while saving DSA Imapct::' + JSON.stringify(error));
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'Failed to update Negotiated DSA Impact',
                                variant: 'error'
                            })
                        );
                });
            }

            this.loanParameters.map((row) => {
                console.log('row>>>'+row);
            if (row.Parameter != 'EMI Amount (INR)' && this.originalData[row.field] != row.negotiatedValue) {
                updatedValues[row.field] = row.negotiatedValue;
            }
            if (row.Parameter === 'Loan Amount (INR)') {
                this.loanData.loanAmount = row.negotiatedValue - row.sanctionedValue;
            }
            if (row.Parameter === 'ROI (In %)') {
                this.loanData.roi = (row.negotiatedValue || 0);
                this.loanData.roiDiff = row.sanctionedValue - row.negotiatedValue;
            }
            if (row.Parameter === 'Tenure (In Month)') {
                this.loanData.tenure = (row.negotiatedValue || 0) - (row.sanctionedValue || 0);
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


            this.loanParametersANHLChild.map((row) => {
            if (row.Parameter != 'EMI Amount (INR)' && this.originalDataANHLChild[row.field] != row.negotiatedValueANHLChild) {
                updatedValuesANHLChild[row.field] = row.negotiatedValueANHLChild;
            }
            if (row.Parameter === 'Loan Amount (INR)') {
                this.loanData.loanAmountANHLChild = row.negotiatedValueANHLChild - row.sanctionedValue;
            }
            if (row.Parameter === 'ROI (In %)') {
                this.loanData.roiANHLChild = (row.negotiatedValueANHLChild || 0);
                this.loanData.roiDiffANHLChild = row.sanctionedValue - row.negotiatedValueANHLChild;
            }
            if (row.Parameter === 'Tenure (In Month)') {
                this.loanData.tenureANHLChild = (row.negotiatedValueANHLChild || 0) - (row.sanctionedValue || 0);
            }
            });

            console.log('this.loanParametersANHLChild>>>'+JSON.stringify(this.loanParametersANHLChild));


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

            const favAHL = this.getFieldFavorability(this.loanParameters, 'negotiatedValue');
            const favAHLChild = this.getFieldFavorability(this.loanParametersAHLChild, 'negotiatedValueAHLChild');
            const favANHL = this.getFieldFavorability(this.loanParametersANHL, 'negotiatedValueANHL');
            const favANHLChild = this.getFieldFavorability(this.loanParametersANHLChild, 'negotiatedValueANHLChild');
            const favFL = this.getFieldFavorability(this.loanParametersFL, 'negotiatedValueFL');

            let promises = [];

            if (Object.keys(updatedValues).length > 0) {
                console.log('updatedValues 1220>>>'+updatedValues);
                let p = updateFinalValues({ opportunityId: this.recordId, updatedFields: updatedValues, productName : this.ahlProductId })
                .then(() => {
                    this.loanParameters.forEach(data=>{
                        if(updatedValues[data.field] !== undefined){
                            data.negotiatedValue = updatedValues[data.field];
                            data.finalValue = updatedValues[data.field];
                        }
                    });
                    this.showToast('Success', 'Final values updated successfully!', 'success');
                    this.isApprove = true;
                    this.loadLoanDetails();
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values AHL', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesAHLChild).length > 0) {
                let p = updateFinalValues({ opportunityId: this.recordId, updatedFields: updatedValuesAHLChild, productName : this.ahlChildProductId })
                .then(() => {
                    this.loanParametersAHLChild.forEach(data=>{
                        if(updatedValuesAHLChild[data.field] !== undefined){
                            data.negotiatedValueAHLChild = updatedValuesAHLChild[data.field];
                            data.finalValue = updatedValuesAHLChild[data.field];
                        }
                    });
                    this.showToast('Success', 'Final values updated successfully!', 'success');
                    this.isApprove = true;
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values AHL Child', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesANHL).length > 0) {
                let p = updateFinalValues({ opportunityId: this.recordId, updatedFields: updatedValuesANHL, productName : this.anhlProductId })
                .then(() => {
                    this.loanParametersANHL.forEach(data=>{
                        if(updatedValuesANHL[data.field] !== undefined){
                            data.negotiatedValueANHL = updatedValuesANHL[data.field];
                            data.finalValue = updatedValuesANHL[data.field];
                        }
                    });
                    this.showToast('Success', 'Final values updated successfully!', 'success');
                    this.isApprove = true;
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values ANHL', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesANHLChild).length > 0) {
                let p = updateFinalValues({ opportunityId: this.recordId, updatedFields: updatedValuesANHLChild, productName : this.anhlChildProductId })
                .then(() => {
                    this.loanParametersANHLChild.forEach(data=>{
                        if(updatedValuesANHLChild[data.field] !== undefined){
                            data.negotiatedValueANHLChild = updatedValuesANHLChild[data.field];
                            data.finalValue = updatedValuesANHLChild[data.field];
                        }
                    });
                    this.showToast('Success', 'Final values updated successfully!', 'success');
                    this.isApprove = true;
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values ANHL Child', 'error');
                });
                promises.push(p);
            }

            if (Object.keys(updatedValuesFL).length > 0) {
                let p = updateFinalValues({ opportunityId: this.recordId, updatedFields: updatedValuesFL, productName : this.flProductId })
                .then(() => {
                    this.loanParametersFL.forEach(data=>{
                        if(updatedValuesFL[data.field] !== undefined){
                            data.negotiatedValueFL = updatedValuesFL[data.field];
                            data.finalValue = updatedValuesFL[data.field];
                        }
                    });
                    this.showToast('Success', 'Final values updated successfully!', 'success');
                    this.isApprove = true;
                    if(this.isHlRelated){
                        this.loadLoanDetails(); // Aditya A hotfix/roiFlagTrigger
                    }
                })
                .catch((error) => {
                    console.error('Error updating records:', JSON.stringify(error));
                    this.showToast('Error', 'Failed to update values FL', 'error');
                });
                promises.push(p);
            }

            }, 5000);
        }
    }

    processApprovalCriteria(fav) {
        const roiFav = fav ? fav.roiFavorable === true : false;
        const amountFav = fav ? fav.amountFavorable === true : false;
        for (const row of this.metadataRecords) {
            let isMatch = false;
            let isRoiResanctionMatch = false;
            let isRoiPricingApprovalMatch = false;
           
            if (row.Type__c == 'Loan Amount' && !amountFav && this.loanData.loanAmount > 0 && row.Increased_By__c > 0 && Math.abs(this.loanData.loanAmount) >= row.Increased_By__c) {
                isMatch = true;
            }

       
            if (row.Type__c == 'Tenure' && this.loanData.tenure < 0 && row.Decreased_by__c != null && row.Decreased_by__c > 0 && Math.abs(this.loanData.tenure) >= row.Decreased_by__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c) {
                isMatch = true;
                console.log('dec--', this.loanData.tenure)
            } else if (row.Type__c == 'Tenure' && this.loanData.tenure > 0 && row.Increased_By__c != null && row.Increased_By__c > 0 && Math.abs(this.loanData.tenure) >= row.Increased_By__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c) {
                isMatch = true;
                console.log('Inc--', this.loanData.tenure)
            }
        

            console.log('metadata row>>'+JSON.stringify(row));
            console.log('this.loanData>>'+JSON.stringify(this.loanData));
            
          


            
            if (row.Type__c == 'ROI' && !roiFav && 
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
                console.log('ro1407>>>'+JSON.stringify(row));
                isRoiPricingApprovalMatch = true;
            }

            if(row.Type__c == 'ROI' && !roiFav && this.loanData.roiDiff < 0){
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
                    this.showApprovalButton = true;
                }

                if (row.Resanction__c == true) {
                    this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = true;
                    this.isEnableApprovalHis = false;
                    this.showApprovalButton = true;
                    break;
                }
            }
            if(isRoiPricingApprovalMatch){
                console.log('1466>>> matched'); 

                 if (row.Level__c != null && row.Designation__c != null) {
                    this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = false;
                    this.isEnableApprovalHis = true;
                    this.showApprovalButton = true;
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

    processApprovalCriteriaForAHLChild(fav) {
        const roiFav = fav ? fav.roiFavorable === true : false;
        const amountFav = fav ? fav.amountFavorable === true : false;
        console.log('row this.loanData', JSON.stringify(this.loanData));
        console.log('this.metadataRecords:: '+JSON.stringify(this.metadataRecords));
        for (const row of this.metadataRecords) {
            let isMatch = false;
            let isRoiResanctionMatch = false;
            let isRoiPricingApprovalMatch = false;
            console.log('row this.loanData.loanAmountAHLChild', this.loanData.loanAmountAHLChild);

            if (row.Type__c == 'Loan Amount' && !amountFav && this.loanData.loanAmountAHLChild > 0 && row.Increased_By__c > 0 && Math.abs(this.loanData.loanAmountAHLChild) >= row.Increased_By__c) {
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

            if (row.Type__c == 'ROI' && !roiFav && this.loanData.roiDiffAHLChild != 0 && this.loanData.roiDiffAHLChild > 0 && this.loanData.roiAHLChild != null && row.Range1__c != null && row.Range2__c != null && this.loanData.roiAHLChild >= row.Range1__c && this.loanData.roiAHLChild <= row.Range2__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c && this.loanData.customerProfile.replace(/[\u200B-\u200D\uFEFF]/g, '') == row.Customer_Profile__c.replace(/[\u200B-\u200D\uFEFF]/g, '')) {
                console.log('inside ahl child roi match');
                //isMatch = true;
                isRoiPricingApprovalMatch = true;
            }
            if(row.Type__c == 'ROI' && !roiFav && this.loanData.roiDiffAHLChild < 0){
                isRoiResanctionMatch = true;
            }


            if (isMatch) {
                if (row.Resanction__c == false && row.Level__c != null && row.Designation__c != null) {
                    this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = false;
                    this.isEnableApprovalHis = true;
                    this.showApprovalButton = true;
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
                    this.showApprovalButton = true;
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

    processApprovalCriteriaForANHL(fav) {
        const roiFav = fav ? fav.roiFavorable === true : false;
        const amountFav = fav ? fav.amountFavorable === true : false;
        console.log('row this.loanData', JSON.stringify(this.loanData));
        console.log('this.metadataRecords:: '+JSON.stringify(this.metadataRecords));
        for (const row of this.metadataRecords) {
            let isMatch = false;
            let isRoiResanctionMatch = false;
            let isRoiPricingApprovalMatch = false;
            console.log('row this.loanData.loanAmountANHL', this.loanData.loanAmountANHL);

            if (row.Type__c == 'Loan Amount' && !amountFav && this.loanData.loanAmountANHL > 0 && row.Increased_By__c > 0 && Math.abs(this.loanData.loanAmountANHL) >= row.Increased_By__c) {
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

            if (row.Type__c == 'ROI' && !roiFav && this.loanData.roiDiffANHL != 0 && this.loanData.roiDiffANHL > 0 && this.loanData.roiANHL != null && row.Range1__c != null && row.Range2__c != null && this.loanData.roiANHL >= row.Range1__c && this.loanData.roiANHL <= row.Range2__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c && this.loanData.customerProfile.replace(/[\u200B-\u200D\uFEFF]/g, '') == row.Customer_Profile__c.replace(/[\u200B-\u200D\uFEFF]/g, '')) {
                console.log('inside anhl roi match');
                //isMatch = true;
                isRoiPricingApprovalMatch = true;
            }
            if(row.Type__c == 'ROI' && !roiFav && this.loanData.roiDiffANHL < 0){
                isRoiResanctionMatch = true;
            }


            if (isMatch) {
                if (row.Resanction__c == false && row.Level__c != null && row.Designation__c != null) {
                    this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = false;
                    this.isEnableApprovalHis = true;
                    this.showApprovalButton = true;
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
                    this.showApprovalButton = true;
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

    processApprovalCriteriaForANHLChild(fav) {
        const roiFav = fav ? fav.roiFavorable === true : false;
        const amountFav = fav ? fav.amountFavorable === true : false;
        console.log('row this.loanData', JSON.stringify(this.loanData));
        console.log('this.metadataRecords:: '+JSON.stringify(this.metadataRecords));
        for (const row of this.metadataRecords) {
            let isMatch = false;
            let isRoiResanctionMatch = false;
            let isRoiPricingApprovalMatch = false;
            console.log('row this.loanData.loanAmountANHLChild', this.loanData.loanAmountANHLChild);

            if (row.Type__c == 'Loan Amount' && !amountFav && this.loanData.loanAmountANHLChild > 0 && row.Increased_By__c > 0 && Math.abs(this.loanData.loanAmountANHLChild) >= row.Increased_By__c) {
                isMatch = true;
                console.log('inside anhl child amount match');
            }

            if (row.Type__c == 'Tenure' && this.loanData.tenureANHLChild > 0 && row.Increased_By__c != null && row.Increased_By__c > 0 && Math.abs(this.loanData.tenureANHLChild) >= row.Increased_By__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c) {
                isMatch = true;
                console.log('inside anhl child tenure match');
            }else if (row.Type__c == 'Tenure' && this.loanData.tenureANHLChild < 0 && row.Decreased_by__c != null && row.Decreased_by__c > 0 && Math.abs(this.loanData.tenureANHLChild) >= row.Decreased_by__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c ) {
                isMatch = true;
                console.log('dec--', this.loanData.tenure)
            }

            if (row.Type__c == 'ROI' && !roiFav && this.loanData.roiDiffANHLChild != 0 && this.loanData.roiDiffANHLChild > 0 && this.loanData.roiANHLChild != null && row.Range1__c != null && row.Range2__c != null && this.loanData.roiANHLChild >= row.Range1__c && this.loanData.roiANHLChild <= row.Range2__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c && this.loanData.customerProfile.replace(/[\u200B-\u200D\uFEFF]/g, '') == row.Customer_Profile__c.replace(/[\u200B-\u200D\uFEFF]/g, '')) {
                console.log('inside anhl child roi match');
                //isMatch = true;
                isRoiPricingApprovalMatch = true;
            }
            if(row.Type__c == 'ROI' && !roiFav && this.loanData.roiDiffANHLChild < 0){
                isRoiResanctionMatch = true;
            }


            if (isMatch) {
                if (row.Resanction__c == false && row.Level__c != null && row.Designation__c != null) {
                    this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = false;
                    this.isEnableApprovalHis = true;
                    this.showApprovalButton = true;
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
                    this.showApprovalButton = true;
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

    processApprovalCriteriaForFL(fav) {
        const roiFav = fav ? fav.roiFavorable === true : false;
        const amountFav = fav ? fav.amountFavorable === true : false;
        console.log('row this.loanData', JSON.stringify(this.loanData));
        console.log('this.metadataRecords:: '+JSON.stringify(this.metadataRecords));
        for (const row of this.metadataRecords) {
            let isMatch = false;
            let isRoiResanctionMatch = false;
            let isRoiPricingApprovalMatch = false;
            console.log('row this.loanData.loanAmountFL', this.loanData.loanAmountFL);

            if (row.Type__c == 'Loan Amount' && !amountFav && this.loanData.loanAmountFL > 0 && row.Increased_By__c > 0 && Math.abs(this.loanData.loanAmountFL) >= row.Increased_By__c) {
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

            if (row.Type__c == 'ROI' && !roiFav && this.loanData.roiDiffFL != 0 && this.loanData.roiDiffFL > 0 && this.loanData.roiFL != null && row.Range1__c != null && row.Range2__c != null && this.loanData.roiFL >= row.Range1__c && this.loanData.roiFL <= row.Range2__c && this.loanData.product == row.Product__c && this.loanData.subProduct == row.Sub_Product__c && this.loanData.customerProfile.replace(/[\u200B-\u200D\uFEFF]/g, '') == row.Customer_Profile__c.replace(/[\u200B-\u200D\uFEFF]/g, '')) {
                console.log('inside fl roi match');
                //isMatch = true;
                isRoiPricingApprovalMatch = true;
            }
            if(row.Type__c == 'ROI' && !roiFav && this.loanData.roiDiffFL < 0){
                isRoiResanctionMatch = true;
            }


            if (isMatch) {
                if (row.Resanction__c == false && row.Level__c != null && row.Designation__c != null) {
                    this.selectedMetadataRecords.push(row);
                    this.showResanctionNotes = false;
                    this.isEnableApprovalHis = true;
                    this.showApprovalButton = true;
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
                    this.showApprovalButton = true;
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
        // const style = document.createElement("style");
        // style.innerText = `
        //     .slds-accordion__list-item .section-control{
        //         background: #c5c5c5;
        //         color: black;
        //         margin-left: 0px;
        //         margin-bottom: 0px;
        //         margin-right: 0px;
        //         font-weight: 500;
        //     }
        //     .slds-accordion__summary {
        //         padding: 10px 0px 10px 0px;
        //     }
        // `;

        // Append the styles to the .styleContainer
        //this.template.querySelector(".styleContainer")?.appendChild(style);
    if (!this.hasRendered) {
        const style = document.createElement("style");

        style.innerText = `
    /* Header background */
    .slds-accordion__summary {
        background: linear-gradient(
            135deg,
            #001a5e 0%,
            #003087 55%,
            #004db3 100%
        ) !important;

        color: #ffffff !important;
        font-weight: 600;

        /* prevent hover color changes */
        transition: none !important;
    }

    /* Keep same gradient on hover/focus/open */
    .slds-accordion__summary:hover,
    .slds-accordion__summary:focus,
    .slds-accordion__summary-action:hover,
    .slds-accordion__summary-action:focus,
    .slds-is-open .slds-accordion__summary {
        background: linear-gradient(
            135deg,
            #001a5e 0%,
            #003087 55%,
            #004db3 100%
        ) !important;
    }

    /* Accordion title text */
    .slds-accordion__summary-content,
    .slds-accordion__summary-heading,
    .slds-accordion__summary-action,
    .slds-accordion__summary-action .slds-truncate {
        color: #ffffff !important;
        font-weight: 600 !important;
    }

    /* Accordion arrow */
    .slds-accordion__summary-action svg,
    .slds-accordion__summary-action lightning-primitive-icon,
    .slds-button__icon {
        fill: #ffffff !important;
        color: #ffffff !important;
    }
`;

this.template.querySelector(".styleContainer")?.appendChild(style);

        this.hasRendered = true;
    }

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

    resetPricingApprovalFlag(){
        resetPricingFlag({ opportunityId: this.recordId, productName : this.flProductId })
         .then( ()=> {
                this.isEnableApprovalHis = true;
                console.log('Pricing Tag Updated--' + this.isEnableApprovalHis);
          })
    }

    getScreenDetailsFromApex() {
        //console.log('this.formIdentifier ' + this.formName);
        this.fieldDetails = [];
        getScreenDetails({
            formIdentifier: 'Charges and Pricing',
            loanId: this.recordId
        })
        .then(result => {
            if (result) {
                //this.fieldDetails = result;
                this.fieldDetails = result.map(item => ({...item,
                    isNumber: item.Field_Type__c === 'Number',
                    isCheckBox: item.Field_Type__c === 'Checkbox',
                    isDate: item.Field_Type__c === 'Date',
                    isPicklist: item.Field_Type__c === 'Picklist',
                    picklistOptions: []
                }));

                this.fieldDetails.forEach(async item => {
                    if (item.Field_Type__c === 'Picklist') {
                        item.picklistOptions  = await this.getPicklistOptionsFromApex(true, item.Storage_Object__c, item.Storage_Field__c);
                        item.isPicklist = false;
                        
                    }
                });
                this.getLoanDetails();
            }
        }).catch(error => {
            //  console.error('error getScreenDetails: ' + error);
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

    getLoanDetails() {
        try {
            console.log('782 ' + this.screenName);
            setTimeout(() => {
                console.log('at 796');

                getLoanDetailsFromStorageObject({
                    screenName: 'Charges and Pricing',
                    loanId: this.recordId,
                    formIdentifier: 'Charges and Pricing',
                    recordId: this.recordId,
                    did: ''
                }).then(result => {

                    console.log('detailsWrapperList from getLoanDetailsFromStorageObject--> ' + JSON.stringify(result));
                    console.log('fieldDetails-> ' + this.fieldDetails);
                    if (this.fieldDetails) {
                        result.forEach(item => {
                            this.fieldDetails.forEach(record => {
                                console.log('item.fieldApiName at 810---', item.fieldApiName);
                                console.log('item.fieldValue at 180----', item.fieldValue);
                                console.log('record. id==', record.Id);
                                console.log('record.Storage_Field__c----', item.Storage_Field__c);

                                if (item.fieldApiName == record.Storage_Field__c && record.is_Lookup__c) {
                                    record.savedName = item.fieldValue; //item.lookUpfieldValue;
                                    record.value = item.lookUpfieldValue;
                                    console.log('record -->' + JSON.stringify(record));
                                } else if (item.fieldApiName == record.Storage_Field__c) {
                                    record.value = item.fieldValue;
                                }
                                if (record.Field_Type__c === 'Picklist') {
                                    record.isPicklist = true;
                                }
                            });
                        });
                        console.log('this.fieldDetails at 108---', JSON.stringify(this.fieldDetails));
                    }
                }).catch(error => {
                })
            }, 1000);
        } catch (error) {
            console.log('error=:860generic' + error);
            console.log('error=:860generic' + JSON.stringify(error));
        }

    }

    // updated

    /**
     * Subscribes to the LMS channel to listen for applied offers.
     */
    subscribeToMessageChannel() {
        // Make sure we don't subscribe twice
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                (message) => this.handleOfferApplied(message)
                // OFFER_APPLY_CHANNEL
            );
        }
    }

    applyOfferCalculation(roiImpactPercent, feeImpact) {
        
        // Helper function to update any ROI row
        const updateRoi = (row, negotiatedField) => {
            // Find the correct parameter row
            if (row.Parameter === 'ROI (In %)') {
                let newRow = { ...row }; 
                
                let negotiatedVal = parseFloat(newRow[negotiatedField]);
                let sanctionedVal = parseFloat(newRow.sanctionedValue);

                let baseValue;
                // 1. Prioritize Negotiated Value.
                //    We check if it's a valid number (not NaN from null, undefined, or empty).
                if (!isNaN(negotiatedVal)) {
                    baseValue = negotiatedVal;
                } 
                // 2. Fallback to Sanctioned Value.
                else if (!isNaN(sanctionedVal)) {
                    baseValue = sanctionedVal;
                } 
                // 3. If neither is a number, we can't calculate.
                else {
                    console.warn('pricingApproval: Could not find base value for ROI calculation.');
                    return newRow;
                }
                // Now, perform the calculation based on the selected 'baseValue'
                if (roiImpactPercent != null) {
                    // **Apply Offer:**
                    // 1. Calculate reduction based on the 'baseValue'
                    let reduction = baseValue * (parseFloat(roiImpactPercent) / 100.0);
                    
                    // 2. Apply reduction to the base value
                    newRow.finalValue = (baseValue - reduction).toFixed(2);
                
                } else {
                    // **Remove Offer:** Revert Final Value back to the Negotiated Value.
                    // If negotiated value is invalid, clear the final value.
                    newRow.finalValue = !isNaN(negotiatedVal) ? negotiatedVal.toFixed(2) : '';
                }
                return newRow;
            }
            // Return all other rows unchanged
            return row;
        };

        // Apply the update to all 4 product lists 
        this.loanParameters = this.loanParameters.map(row => updateRoi(row, 'negotiatedValue'));
        this.loanParametersAHLChild = this.loanParametersAHLChild.map(row => updateRoi(row, 'negotiatedValueAHLChild'));
        this.loanParametersANHL = this.loanParametersANHL.map(row => updateRoi(row, 'negotiatedValueANHL'));
        this.loanParametersFL = this.loanParametersFL.map(row => updateRoi(row, 'negotiatedValueFL'));

        // (Optional) Handle fee impact here
        if (feeImpact) {
            console.log(`pricingApproval: Fee impact of ${feeImpact} received.`);
        }
    }
    
    /**
     * This function is called by the LMS subscriber.
     */
    handleOfferApplied(message) {
        console.log('pricingApproval: Message Received!', message);
        if (!message) return;
        
        // This calls the calculation function you already have
        this.applyOfferCalculation(message.roiImpact, message.feeImpact);
    }
    
    /**
     * This helper function fixes the "refresh" bug.
     * It runs on load and applies any saved offer.
     */
    /*applySavedOfferOnLoad() {
        // Only run if:
        // 1. An offer is marked as applied on the record
        // 2. The table data (loanParameters) has been loaded
        if (this.isOfferApplied && this.loanParameters.length > 0) {
            console.log('pricingApproval: Applying saved offer on load.');
            // Pass the saved ROI (which could be null if it was removed)
            this.applyOfferCalculation(this.savedRoiImpact, 0); // or use this.savedFeeImpact
        }
    }*/
    //end updated
}