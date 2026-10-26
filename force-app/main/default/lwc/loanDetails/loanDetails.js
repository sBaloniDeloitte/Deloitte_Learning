import { LightningElement, wire, track, api } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import USERID_FIELD from "@salesforce/user/Id";
import STAGE_FIELD from "@salesforce/schema/Opportunity.StageName";
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
import SANCTION_TENURE from "@salesforce/schema/Opportunity.Sanction_Tenure__c";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import createLoanTransaction from '@salesforce/apex/LoanDetailsController.createLoanTransaction';
import deleteUpdateStepLoan from '@salesforce/apex/LoanDetailsController.deleteUpdateStepLoan';
import getStepLoan from '@salesforce/apex/LoanDetailsController.getStepLoan';
import StepLoanActivationHandler from '@salesforce/apex/LoanDetailsController.StepLoanActivationHandler';
import resetFieldValues from '@salesforce/apex/LoanDetailsController.resetFieldValues';
import getScreenFields from '@salesforce/apex/LoanDetailsController.getScreenFields';
import getPicklistValues from '@salesforce/apex/ScreenGenerationController.getPicklistValues';
import getOpportunityTeamMembers from '@salesforce/apex/LoanDetailsController.getOpportunityTeamMembers';
import ID_FIELD from "@salesforce/schema/Loan_Transaction__c.Id";
import deleteAllStepLoans from '@salesforce/apex/LoanDetailsController.deleteAllStepLoans';
import getSubProduct from '@salesforce/apex/LoanDetailsController.getSubProduct';
import getProductData from '@salesforce/apex/LoanDetailsController.getProductData';
import getIntegrationDetail from '@salesforce/apex/LoanDetailsController.getIntegrationDetail';
import chargesInsuranceDetails from '@salesforce/apex/LoanDetailsController.chargesInsuranceDetails';
import constantsMetadata from '@salesforce/apex/LoanDetailsController.constantsMetadata';
//import FLEXI_FUNDS_BPI_DISABLED_FIELDS from '@salesforce/label/c.Flexi_Funds_BPI_Disabled_Fields';
import getLoanDetailsFromReadObject from '@salesforce/apex/ScreenGenerationController.getLoanDetailsFromReadObject';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import invokeBPIFlow from '@salesforce/apex/LoanDetailsController.invokeBPIFlow';
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';
export default class LoanDetails extends LightningElement {
    productData;
    @api recordId;
    @track activeSections = [];
    @track basicDetailFields = [];
    @track transactionDetailsFields = [];
    @track keyDetails = [];
    @track stepLoan = [];
    @track graceParameters = [];
    @track emiHolidayParams = [];
    @track principalHolidayParams = [];
    @track stepLoanDetails = [];
    @track purePaymentDetails = [];
    @track dropPaymentDetails = [];
    interestDueDatePicklistOptions = []
    copiedStepLoanDetails = [];
    copiedGraceParameters = [];
    @track penaltyDetails = [];
    modalVisibility = false;
    @track isStepLoanActive = false;
    @track allowPaymentInGracePeriod = false;
    @track allowGraceValue = false;
    stepLoanUncheckModal = false;

    currentUserOppRole = [];
    oppStage = '';
    oppSubStage = '';

    stepSpecifierIndex;

    graceParametersFieldNames = [];
    emiHolidayParamsFieldNames = [];
    principalHolidayParamsFieldNames = [];
    controllingFields = [];

    plannedEMIHolidayValue;
    principalHolidayValue;
    allowPlannedEMIHolidayInGraceIndex;
    stepLoanCheckboxIndex;
    totalFee =0;
    totalLoanTenor = 0;
    schemeName = '';

    firstTimeLoaded = true;
    showGraceParameters = false;
    graceFrequencyValue;
    enteredGraceTenure = 0;
    showStepLoanSection = false;
    showEmiHolidayparams = false;
    showPrincipalHolidayparams = false;
    showPurePaymentDetails = false;
    showDropPaymentDetails = false;

    screenFieldRecords;
    numberOfStepsFieldIndex = 0;
    stepNumberIndex = 0;
    loanTransactionRecord;

    stepIndexForDeletion;
    recIdForDeletion;
    isLoading = false;
    sanctionloanTenor = 0;
    loanType;
    plrValue;
    plrCode;
    productRecordType;

    selectedLoanStartDate;
    integrationDetailRec;

    processedStages = [];

    basicDetailsFilled = true;
    keyDetailsFilled = true;
    transactionalDetailsFilled = true;
    graceParametersFilled = true;
    emiHolidayParamsFilled = true;
    principalHolidayParamsFilled = true;
    penaltyDetailsFilled = true;
    loanAmount;
    picklistValues = [
        { label: 'Grace', value: 'Grace' },
        { label: 'Repayment', value: 'Repayment' }
    ];
    picklistValuesToBeShown = [];
    isDisableEdit;
    //directSalesAgentName;
    //directSalesAgentCode;
    //salesRepName;
    //sourcingOfficerName;


    toastTitle = {
        SUCCESS: "Success",
        ERROR: 'Error'
    }
    toastVariant = {
        SUCCESS: "success",
        ERROR: "error"
    }
    toastMessages = {
        UPDATE_SUCCESSFUL: "Record updated Successfully.",
        SOMETHING_WENT_WRONG: 'Something went wrong.',
        STEP_LOAN_REQUIRED_FIELDS: "Please fill all the Step Loan details.",
        LOAN_TENOR_VALIDATION: "Loan Tenor cannot be greater than Total Tenor",
        LOAN_TENOR_EMPTY: "Loan Tenor cannot be Empty.",
        GRACE_PARAMETERS_TO_BE_FILLED: "Please fill Grace Parameters before filling Step Loan.",
        LOAN_TENOR_CANNOT_BE_GREATER_THAN_GRACE_FREQUENCY: 'Loan Tenor cannot be greater than Grace Frequency.',
        STEP_AMOUNT_CANNOT_BE_GREATER_THAN_LOAN_AMOUNT: 'Step Amount cannot be greater than Loan Amount.'
    }

    refreshReq = false;
    fromSales = false;
    hasLoanStagePsvOrDisbursement = false;
    @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD, SUBSTAGE_FIELD,SANCTION_TENURE] })
    opportunity({ error, data }) {
        if(data) {
            this.oppStage = data.fields.StageName.value;
            this.oppSubStage = data.fields.Sub_stage__c.value;
            this.sanctionloanTenor = data.fields.Sanction_Tenure__c.value;
        }
    }

    @wire(getIntegrationDetail, {
    })
    integrationDetailRecord({data,error}){
        if(data){
            this.integrationDetailRec = data;
            this.selectedLoanStartDate = data.Business_Date__c;
     
            console.log('this.selectedLoanStartDate 151>>'+this.selectedLoanStartDate);
        }
    }

    @wire(constantsMetadata, {
    })
    constantsMetadataRecords;

    @wire(getOpportunityTeamMembers, {
        loanId: "$recordId",
    })
    getOppTeamMembers({
        data,
        error
    }) {
        if (data) {
            data.forEach(item => {
                //this.directSalesAgentName = item.TeamMemberRole == 'DSA Executive' ? item.Name : '';
                //this.directSalesAgentCode = item.TeamMemberRole == 'DSA Executive' ? item.User.EmployeeNumber : '';
                //this.salesRepName = item.TeamMemberRole == 'Sales Rep' ? item.Name : '';
                //this.sourcingOfficerName = '';

                if(item.UserId == USERID_FIELD){
                    this.currentUserOppRole.push(item.TeamMemberRole);    
                }
            })
        } else if (error) {
            this.handleError(error, 'gotLoanFields');
            this.showToast(this.toastTitle.ERROR, this.toastMessages.SOMETHING_WENT_WRONG, this.toastVariant.ERROR);
        }
    }


    connectedCallback() {
        this.checkCmpEditability(); 
        this.fetchLoanStage();
        console.log('in CB of loandetails')
        getIntegrationDetail().then(data=>{
            this.selectedLoanStartDate = data.Business_Date__c;
            console.log('this.selectedLoanStartDate 187>>>'+this.selectedLoanStartDate);
            // this.getScreenFieldsFromApex();

        }).catch(error=>{
            console.log('Error>>'+JSON.stringify(error));
        })
        console.log('calling getscreenfields');
        this.getScreenFieldsFromApex();
        

        setTimeout(() => {
            this.setPageEditability();
        }, 3000);
    }
    checkCmpEditability() {
        getComponentEditability({ loanId: this.recordId, component: 'loanDetails' })
            .then(result => {
                this.isDisableEdit = result;
            })
            .catch(error => {
                console.error('Error getComponentEditability : ', error);
                this.isDisableEdit = true;
            });
    }

    fetchLoanStage() {
        getLoanStage({ loanId: this.recordId })
          .then(result => {
            console.log('Result1', result);
            if(result == 'PSV' || result == 'Disbursement') {
                this.fromSales = true;
                this.hasLoanStagePsvOrDisbursement = true;
            }
          })
          .catch(error => {
            console.error('Error:', error);
        });
    }

    setPageEditability(){

        console.log('currentUserOppRole: '+this.currentUserOppRole);
        console.log('oppStage: '+this.oppStage);
        console.log('oppSubStage: '+this.oppSubStage);

        var disableControls = false;
        if(this.oppSubStage == 'Disbursed'){
            //dont allow edit
            disableControls = true;
        }
        else if(this.oppStage == 'Disbursement'){
            if(this.oppSubStage == 'Ops Maker' && this.currentUserOppRole.includes('OPS Maker')){
                //allow edit
            disableControls = false;
            }
            else {
                //dont allow edit
                disableControls = true;
            }
        }
        
        if(disableControls){
            console.log('disable controls--');

            this.basicDetailFields = this.basicDetailFields.map(row => { return { ...row, Is_Disabled__c: true }; });
            this.keyDetails = this.keyDetails.map(row => { return { ...row, Is_Disabled__c: true }; });
            this.keyDetails = this.keyDetails.map(row => { return { ...row, Is_Disabled__c: true }; });
            this.transactionDetailsFields = this.transactionDetailsFields.map(row => { return { ...row, Is_Disabled__c: true }; });
            this.graceParameters = this.graceParameters.map(row => { return { ...row, Is_Disabled__c: true }; });
            this.purePaymentDetails = this.purePaymentDetails.map(row => { return { ...row, Is_Disabled__c: true }; });
            this.dropPaymentDetails = this.dropPaymentDetails.map(row => { return { ...row, Is_Disabled__c: true }; });
            this.emiHolidayParams = this.emiHolidayParams.map(row => { return { ...row, Is_Disabled__c: true }; });
            this.principalHolidayParams = this.principalHolidayParams.map(row => { return { ...row, Is_Disabled__c: true }; });
            this.penaltyDetails = this.penaltyDetails.map(row => { return { ...row, Is_Disabled__c: true }; });
        }
    }

    disableAllFields() {
        const disableAll = arr => arr.map(row => ({ ...row, Is_Disabled__c: true }));
        this.basicDetailFields = disableAll(this.basicDetailFields);
        this.keyDetails = disableAll(this.keyDetails);
        this.transactionDetailsFields = disableAll(this.transactionDetailsFields);
        this.graceParameters = disableAll(this.graceParameters);
        this.purePaymentDetails = disableAll(this.purePaymentDetails);
        this.dropPaymentDetails = disableAll(this.dropPaymentDetails);
        this.emiHolidayParams = disableAll(this.emiHolidayParams);
        this.principalHolidayParams = disableAll(this.principalHolidayParams);
        this.penaltyDetails = disableAll(this.penaltyDetails);
    }

    renderedCallback() {
        if (this.firstTimeLoaded) {
            this.refs.btnTag.innerText = 'Open All';
            this.firstTimeLoaded = false;

            const style = document.createElement("style");
            style.innerText = `
            .slds-show {
                background-color: #09172b;
            }
            .slds-accordion__list-item .section-control {
                background: linear-gradient(
                    135deg,
                    #001a5e 0%,
                    #003087 55%,
                    #004db3 100%
                ) !important;

                color: #ffffff !important;

                margin-left: 0px;
                margin-bottom: 0px;
                margin-right: 0px;

                font-weight: 600;
            }
            .slds-accordion__summary-content,
            .slds-accordion__summary-heading,
            .slds-accordion__summary-action,
            .slds-accordion__summary-action .slds-truncate {
                color: #ffffff !important;
                font-weight: 600 !important;
            }
            .slds-accordion__summary-action svg,
            .slds-button__icon {
                fill: #ffffff !important;
                color: #ffffff !important;
            }
            .slds-accordion__summary {
                padding: 10px 0px 10px 0px;

                background: linear-gradient(
                    135deg,
                    #001a5e 0%,
                    #003087 55%,
                    #004db3 100%
                ) !important;
            }
            .slds-accordion__list-item .section-control:hover,
            .slds-accordion__summary:hover,
            .slds-accordion__summary-action:hover {
                background: linear-gradient(
                    135deg,
                    #001a5e 0%,
                    #003087 55%,
                    #004db3 100%
                ) !important;

                color: #ffffff !important;
            }
            
            .slds-form-element__label,
            .slds-form-element__label span {
                color: #ffffff !important;
            }
            .slds-form-element__control {
                color: #ffffff !important;
            }
            .slds-input,
            .slds-input_faux,
            .slds-form-element__static {
                color: #ffffff !important;
            }
            .hideInput .slds-input {
                color: #ffffff !important;
            }
            .slds-form-element__static {
                color: #ffffff !important;
            }
            .slds-accordion__content {
                color: #09172b;
            }

            /* Hide border and apply bottom border only */
            .hideInput .slds-input {
                background-color: #16283f !important;
                color: #ffffff !important;

                border: 1px solid #33455e !important;

                border-radius: 6px !important;

                outline: none;
                box-shadow: none;

                padding: 8px !important;
            }

            .removeborder .slds-combobox__input {
                background-color: #16283f !important;
                color: #ffffff !important;

                border: 1px solid #33455e !important;

                border-radius: 6px !important;

                box-shadow: none !important;

                padding: 8px !important;
            }
            .slds-datepicker {
                color: #ffffff !important;
            }

            .slds-datepicker th,
            .slds-datepicker td,
            .slds-day,
            .slds-day_adjacent-month {
                color: #ffffff !important;
            }

            .slds-datepicker__month thead th {
                color: #8fa7c4 !important;
            }

            .slds-datepicker button {
                color: #ffffff !important;
            }
            .slds-datepicker select,
            .slds-datepicker .slds-select {
                background-color: #16283f !important;
                color: #ffffff !important;
                border: 1px solid #33455e !important;
            }
            .slds-datepicker option {
                background-color: #16283f !important;
                color: #ffffff !important;
            }
            `;

            this.template.querySelector(".styleContainer")?.appendChild(style);
        }
    }

    async getScreenFieldsFromApex() {
        try {
            console.log('in getScreenFieldsFromApex');
            // this.isLoading = true;
            // const prodData = await getSubProduct({loanId : this.recordId});
            // console.log('273>>');

            // const schemeData = await getScheme({loanId :this.recordId});

            console.log('in getScreenFieldsFromApex- calling product data');
            /*
            const productDetails = await getProductData({loanId :this.recordId});
            console.log('product details are '+productDetails);
            this.productData = productDetails;
            this.loanType = this.productData.variant.Name;
            this.plrValue = this.productData.variant.PLR_Value__c;
            this.plrCode = this.productData.variant.PLR_Code__c;
            console.log('this.productData>>'+JSON.stringify(this.productData));
                
          

            const chargesInsuranceData = await chargesInsuranceDetails({loanId :this.recordId});
            console.log('chargesInsuranceData>>'+JSON.stringify(chargesInsuranceData));
            
                this.totalFee = chargesInsuranceData;
            
            console.log(' this.totalFee>>'+ this.totalFee);
            */
        
       

        
            // this.selectedLoanStartDate = this.integrationDetailRecord.Business_Date__c;
            // console.log('this.selectedLoanStartDate 263>>'+this.selectedLoanStartDate);
            // let productType;
            // for (let product2 of prodData) {
            //     if(product2.RecordType.DeveloperName == 'Sub_Product'){
            //         this.productRecordType = 'Sub_Product';
            //         this.loanType = product2.Name;
                    
                 
            //         this.plrValue = product2.PLR_Value__c;
            //     }else if(product2.RecordType.DeveloperName == 'Product'){
            //         productType = product2.Name;
            //     }
            //     //If Subproduct is Term loan, i.e. Subproduct recordType in
            //     // Product2 is Term Loan, Then First Disbursement Amount should be default to 
            //     // total loan amount (Editable).  
                
            // }
            
            
            let tempBasicDetails = [];
            let tempTransactionalDetails = [];
            let tempKeyDetails = [];
            let tempGraceParameters = [];
            let tempStepLoan = [];
            let tempEmiHolidayParams = [];
            let tempPrincipalHolidayParams = [];
            let tempPurePaymentDetails = [];
            let tempDropPaymentDetails = [];
            let tempPenaltyDetails = [];

            const basicDetailsMock = new Map([
                ['Loan Division', 'Retail'],
                ['Sourcing Branch','Mumbai'],
                ['Loan Branch','Mumbai'],
                ['Sub Branch','Mumbai HO'],
                ['Channel Category','DSA'],
                ['Direct Sales Agent', 'ALL ASTUTE MUMBAI'],
                ['DSA Code','DIRECT'],
                ['Relationship Manager','VISHAL TRIBHUVAN'],
                ['Area Manager','VISHAL TRIBHUVAN'],
                ['Sanction Loan Amount',3000000],
                ['Base Rate Code','GFLPLRBL'],
                ['Requested Tenor',48],
                ['DSA Type','VELVETEEN'],
                ['DST','MHR10485'],
                ['AM Code','NA'],
                ['Aarohi flag', 'NO'],
                ['Language Preference','English']
                
            ]);

            const keyDetailsMock = new Map([
                ['Sanctioned Amount', 3000000],
                ['Sanctioned Tenor',48],
                ['Total Finance Amount',2500000],
                ['Sanctioned Rate of Interest',15],
                ['Total Fee',10000],
                ['EMI Amount (as per Repayment Schedule)', 200000],
                ['Loan Purpose','Business Expansion'],
                ['Program Type','H']
            ]);

            const transDetailsMock = new Map([
                ['Loan Start Date', '2049-04-15'],
                ['Payment Method','NACH'],
                ['Allow BPI','TRUE'],
                ['Allow Grace','TRUE'],
                ['Quick Disbursement','TRUE'],
                ['Allow OCR','TRUE'],
                ['BPI Treatment','E'],
                ['Schedule Method','EQUAL'],
                ['Interest Due date', 26],
                ['Interest Frequency','M'],
                ['Elastic Credit Line Type','H'],
                ['Dropline Calculated On','S'],
                ['PLR',18.31],
                ['Margin','-18.31'],
                ['Final Rate of Interest',0],
                ['First Disbursement Amount',0],
                ['Rate Type','R'],
                ['Emi due frequency','6th of the month'],
                ['Pure Tenure',24],
                ['Pure End Date','2051-4-15'],
                ['Dropline Tenure',24],
                ['Dropline End Date','2053-4-15']
            ]);
            console.log('calling getScreenFields '+this.loanType);
            getScreenFields({
                formIdentifier: 'Loan Details',
                loanType: 'Home Loan',
                subVariant : 'Freedom ' 
            }).then(result =>{
                console.log('loan details data is ',result);
                // this.screenFieldRecords = result;
                result.forEach(item => {
                    // console.log('item is ',item);
                if (item.Section_Name__c == 'Basic Details') {
                    item.value = basicDetailsMock.get(item.Field_Label__c);

                    //item.value = item.Field_Label__c == 'Base Rate Code' ? this.plrCode : item.value;
                    tempBasicDetails.push(item);
                } else if (item.Section_Name__c == 'Key Details') {
                   // item.value = item.Field_Label__c == 'Product' ? productType : item.value;
                   console.log('366>>');
                    // console.log('item.Field_Label__c>>>'+item.Field_Label__c);
                    if(item.Field_Label__c == 'Scheme'){
                        item.value = this.schemeName;
                        console.log('322 value>>'+item.value);
                    }
                    if(item.Field_Label__c == 'Total Fee'){
                        item.value = this.totalFee;
                    }

                    item.value = keyDetailsMock.get(item.Field_Label__c);
                    //item.value = item.Field_Label__c == 'Scheme'? 'abc': '';
                    //console.log('item.value>>'+item.value);
                    tempKeyDetails.push(item);
                } else if (item.Section_Name__c == 'Transactional Details') {
                    item.Is_Disabled__c = item.Visibility_Controlled_By__c || item.Is_Disabled__c ? true : false;
                    item.value = item.Field_Label__c == 'PLR' ? this.plrValue : item.value;
                    this.marginIndex = item.Field_Label__c == 'Margin' ? tempTransactionalDetails.length : this.marginIndex;
                    this.finalRateIndex = item.Field_Label__c == 'Final Rate of Interest' ? tempTransactionalDetails.length : this.finalRateIndex;
                    if (item.Storage_Field__c == 'Number_of_Steps__c') {
                        item.value = 0;
                        this.numberOfStepsFieldIndex = tempTransactionalDetails.length;
                    }
                    this.allowPlannedEMIHolidayInGraceIndex = item.Storage_Field__c == 'Allow_Planned_EMI_holiday_in_Grace__c' ? tempTransactionalDetails.length : this.allowPlannedEMIHolidayInGraceIndex;
                    this.stepLoanCheckboxIndex = item.Storage_Field__c == 'Step_Loan__c' ? tempTransactionalDetails.length : this.stepLoanCheckboxIndex;
                     item.value = transDetailsMock.get(item.Field_Label__c);
                    tempTransactionalDetails.push(item);
                }

                });
                console.log('all are tempBasicDetails ', tempBasicDetails);
                console.log('all are tempKeyDetails ', tempKeyDetails);
                console.log('all are tempTransactionalDetails ', tempTransactionalDetails);
                
            this.basicDetailFields = [...tempBasicDetails];
            this.keyDetails = [...tempKeyDetails];
            this.transactionDetailsFields = [...tempTransactionalDetails];
 
            })
            console.log('screenFieldRecords are : '+screenFieldRecords);

            

            let fieldName = ['Loan_Application__r.Tenor_Months__c'];
            this.screenFieldRecords.forEach(item => {
                

                if (item.Storage_Object__c == 'Loan_Transaction__c') {
                    fieldName.push(item.Storage_Field__c);
                }

                if (item?.Visibility_Controlled_By__r?.Storage_Field__c && item?.Visibility_Controlled_By__r?.Storage_Field__c != 'Step_Loan__c') {
                    this.controllingFields.push(item.Visibility_Controlled_By__r.Storage_Field__c);
                }

                if (item.Section_Name__c == 'Basic Details') {
                    //item.value = item.Field_Label__c == 'Direct Sales Agent' ? this.directSalesAgentName : item.value;
                    //item.value = item.Field_Label__c == 'DSA Code' ? this.directSalesAgentCode : item.value;
                    //item.value = item.Field_Label__c == 'Employee Name' ? this.salesRepName : item.value;
                    //item.value = item.Field_Label__c == 'Sourcing officer' ? this.sourcingOfficerName : item.value;
                    //item.value = item.Field_Label__c == 'Base Rate Code' ? this.plrCode : item.value;
                    tempBasicDetails.push(item);
                } else if (item.Section_Name__c == 'Key Details') {
                   // item.value = item.Field_Label__c == 'Product' ? productType : item.value;
                   console.log('366>>');
                 
                   item.value = item.Field_Label__c == 'Product' ? this.productData.productName.Name: item.value;
                   item.value = item.Field_Label__c == 'Sub Product' ? this.productData.subProductName.Name: item.value;
                   item.value = item.Field_Label__c == 'Variant' ? this.productData.variant.Name : item.value;
                   item.value = item.Field_Label__c == 'Sub Variant' ? this.productData.subVariant.Name : item.value;
                   item.value = item.Field_Label__c == 'Hybrid Tenure' ? this.productData.hybridTenure.Name : item.value;
                   item.value = item.Field_Label__c == 'Full EMI' ? this.productData.fullEmi.Name : item.value;
                   item.value = item.Field_Label__c == 'Total Tenure' ? this.productData.totalTenure.Name : item.value;
                    console.log('item.Field_Label__c>>>'+item.Field_Label__c);
                    if(item.Field_Label__c == 'Scheme'){
                        item.value = this.schemeName;
                        console.log('322 value>>'+item.value);
                    }
                    if(item.Field_Label__c == 'Total Fee'){
                        item.value = this.totalFee;
                    }
                    //item.value = item.Field_Label__c == 'Scheme'? 'abc': '';
                    //console.log('item.value>>'+item.value);
                    tempKeyDetails.push(item);
                } else if (item.Section_Name__c == 'Transactional Details') {
                    item.Is_Disabled__c = item.Visibility_Controlled_By__c || item.Is_Disabled__c ? true : false;
                    item.value = item.Field_Label__c == 'PLR' ? this.plrValue : item.value;
                    this.marginIndex = item.Field_Label__c == 'Margin' ? tempTransactionalDetails.length : this.marginIndex;
                    this.finalRateIndex = item.Field_Label__c == 'Final Rate of Interest' ? tempTransactionalDetails.length : this.finalRateIndex;
                    if (item.Storage_Field__c == 'Number_of_Steps__c') {
                        item.value = 0;
                        this.numberOfStepsFieldIndex = tempTransactionalDetails.length;
                    }
                    this.allowPlannedEMIHolidayInGraceIndex = item.Storage_Field__c == 'Allow_Planned_EMI_holiday_in_Grace__c' ? tempTransactionalDetails.length : this.allowPlannedEMIHolidayInGraceIndex;
                    this.stepLoanCheckboxIndex = item.Storage_Field__c == 'Step_Loan__c' ? tempTransactionalDetails.length : this.stepLoanCheckboxIndex;
                    tempTransactionalDetails.push(item);
                } /*else if (item.Section_Name__c == 'Grace Parameters') {
                this.graceParametersFieldNames.push(item.Storage_Field__c);
                tempGraceParameters.push(item);
            }*/
                else if (item.Section_Name__c == 'Grace Parameters') {


                    if (item.Is_Mandatory__c) {
                        this.graceParametersFieldNames.push(item.Storage_Field__c); // only mandatory fields

                    }
                    tempGraceParameters.push(item);
                    //tempGraceParameters.push(item); // push all for UI
                } /*else if (item.Section_Name__c == 'Step Loan') {
                if (item.Storage_Field__c == 'Step_Number__c') {
                    item.value = 1;
                    this.stepNumberIndex = tempStepLoan.length;
                }
                this.stepSpecifierIndex = item.Storage_Field__c == 'Step_Specifier__c' ? tempStepLoan.length : this.stepSpecifierIndex;
                tempStepLoan.push(item);
            }*/ else if (item.Section_Name__c == 'EMI Holiday Parameters') {
                    this.emiHolidayParamsFieldNames.push(item.Storage_Field__c);
                    tempEmiHolidayParams.push(item);
                } else if (item.Section_Name__c == 'Principal Holiday Parameters') {
                    this.principalHolidayParamsFieldNames.push(item.Storage_Field__c);
                    tempPrincipalHolidayParams.push(item);
                } else if (item.Section_Name__c == 'Pure Payment Details') {
                    tempPurePaymentDetails.push(item);
                } else if (item.Section_Name__c == 'Drop Payment Details') {
                    tempDropPaymentDetails.push(item);
                } else if (item.Section_Name__c == 'Penalty Details') {
                    tempPenaltyDetails.push(item);
                }
            })

            const newFieldNameSet = [...new Set(fieldName)];
            this.loanTransactionRecord = await createLoanTransaction({
                loanId: this.recordId,
                fieldList: newFieldNameSet,
                loanType: this.loanType
            });

            if (this.loanType == 'Term Loan') {
                this.isStepLoanActive = this.loanTransactionRecord?.Step_Loan__c;
                this.allowGraceValue = this.loanTransactionRecord?.Allow_Grace__c;
                this.updatePicklistValues();
            }


            //this.basicDetailFields = [...tempBasicDetails];
            //this.keyDetails = [...tempKeyDetails];
            //this.transactionDetailsFields = [...tempTransactionalDetails];
            this.graceParameters = [...tempGraceParameters];
            this.emiHolidayParams = [...tempEmiHolidayParams];
            this.principalHolidayParams = [...tempPrincipalHolidayParams];
            this.penaltyDetails = [...tempPenaltyDetails];
            this.purePaymentDetails = tempPurePaymentDetails;
            this.dropPaymentDetails = tempDropPaymentDetails;

            this.getPicklistValues(this.keyDetails);
            this.getPicklistValues(this.transactionDetailsFields);
            this.getPicklistValues(this.graceParameters);
            this.getPicklistValues(this.emiHolidayParams);
            this.getPicklistValues(this.principalHolidayParams);
            this.getPicklistValues(this.purePaymentDetails);
            this.getPicklistValues(this.dropPaymentDetails);
            this.getPicklistValues(this.penaltyDetails);

            console.log('this.loanTransactionRecord>>'+JSON.stringify(this.loanTransactionRecord));
            /*this.transactionDetailsFields.forEach(data=>{
                console.log('data>>'+ JSON.stringify(data));
                if(data.Storage_Field__c == 'Loan_Start_Date__c'){
                    console.log('loan start date data.value>>'+data.value);
                    data.value = this.selectedLoanStartDate;
                    this.updateRecordonFocusOut(this.loanTransactionRecord.Id,'Loan_Start_Date__c',this.selectedLoanStartDate);

                }
            })
            console.log('this.transactionDetailsFields>>>'+JSON.stringify(this.transactionDetailsFields));*/
            console.log('this.productData.subVariant.Name<<'+this.productData.subVariant.Name);
            const details = await getLoanDetailsFromReadObject({ screenName: 'Loan Details', loanId: this.recordId, formIdentifier: this.loanType, recordId: this.loanTransactionRecord['Id'], subVariant : this.productData.subVariant.Name });
            console.log('details>>'+JSON.stringify(details));
            console.log('details.length>>'+details.length);
            if(details && details.length > 0){

            for (let i = 0; i < details.length; i++) {
                
                if (i < this.basicDetailFields.length) {
                    
                    let arrIndex = i;

                    this.basicDetailFields[arrIndex].value = this.basicDetailFields[arrIndex].Field_Label__c == details[arrIndex].fieldLabel && details[arrIndex].fieldValue ? this.basicDetailFields[arrIndex].is_Lookup__c ? details[arrIndex].lookUpfieldValue : details[arrIndex].fieldValue : this.basicDetailFields[arrIndex].value;
                    this.basicDetailFields[arrIndex].value = this.basicDetailFields[arrIndex].Field_Type__c == 'Checkbox' ? this.basicDetailFields[arrIndex].value == '' ?  false : true : this.basicDetailFields[arrIndex].value;
                    this.basicDetailFields[arrIndex].value = this.basicDetailFields[arrIndex].Field_Type__c == 'Number' && !this.basicDetailFields[arrIndex].value ? 0 : this.basicDetailFields[arrIndex].value;
                } else if (i < this.basicDetailFields.length + this.keyDetails.length) {
                    let arrIndex = i - this.basicDetailFields.length;
                    if (arrIndex >= 0) {
                        this.keyDetails[arrIndex].value = this.keyDetails[arrIndex].Field_Label__c == details[i].fieldLabel && details[i].fieldValue ? this.keyDetails[arrIndex].is_Lookup__c ? details[i].lookUpfieldValue : details[i].fieldValue : this.keyDetails[arrIndex].value;
                        this.keyDetails[arrIndex].value = this.keyDetails[arrIndex].Field_Type__c == 'Checkbox' ? this.keyDetails[arrIndex].value == '' ? false : true : this.keyDetails[arrIndex].value;
                        this.keyDetails[arrIndex].value = this.keyDetails[arrIndex].Field_Type__c == 'Number' && !this.keyDetails[arrIndex].value ? 0 : this.keyDetails[arrIndex].value;
                    }
                } else if (i < this.basicDetailFields.length + this.keyDetails.length + this.transactionDetailsFields.length) {
                    let arrIndex = i - (this.basicDetailFields.length + this.keyDetails.length);
                    console.log('this.transactionDetailsFields[arrIndex].Field_Label__c>>'+this.transactionDetailsFields[arrIndex].Field_Label__c);
                    console.log('details[arrIndex].fieldLabel>>'+details[i].fieldLabel);
                    console.log('this.transactionDetailsFields[arrIndex].value>>'+details[i].fieldValue);
                    if (arrIndex >= 0) {

                        this.transactionDetailsFields[arrIndex].value = this.transactionDetailsFields[arrIndex].Field_Label__c == details[i].fieldLabel && details[i].fieldValue ? this.transactionDetailsFields[arrIndex].is_Lookup__c ? details[i].lookUpfieldValue : details[i].fieldValue : this.transactionDetailsFields[arrIndex].value;
                        this.transactionDetailsFields[arrIndex].value = this.transactionDetailsFields[arrIndex].Field_Type__c == 'Checkbox' ? this.transactionDetailsFields[arrIndex].value == undefined || this.transactionDetailsFields[arrIndex].value == ''? false : true : this.transactionDetailsFields[arrIndex].value;
                        this.transactionDetailsFields[arrIndex].value = this.transactionDetailsFields[arrIndex].Field_Type__c == 'Number' && !this.transactionDetailsFields[arrIndex].value ? 0 : this.transactionDetailsFields[arrIndex].value;
                        this.selectedLoanStartDate = this.transactionDetailsFields[arrIndex].Storage_Field__c == 'Loan_Start_Date__c' ?this.transactionDetailsFields[arrIndex].value : this.selectedLoanStartDate;
                    }
                } else if (i < this.basicDetailFields.length + this.keyDetails.length + this.transactionDetailsFields.length + this.graceParameters.length) {
                    let arrIndex = i - (this.basicDetailFields.length + this.keyDetails.length + this.transactionDetailsFields.length);
                    if (arrIndex >= 0) {
                        this.graceParameters[arrIndex].value = this.graceParameters[arrIndex].Field_Label__c == details[i].fieldLabel && details[i].fieldValue ? this.graceParameters[arrIndex].is_Lookup__c ? details[i].lookUpfieldValue : details[i].fieldValue : this.graceParameters[arrIndex].value;
                        this.graceParameters[arrIndex].value = this.graceParameters[arrIndex].Field_Type__c == 'Checkbox' ? this.graceParameters[arrIndex].value == '' ? false : true : this.graceParameters[arrIndex].value;
                        this.graceParameters[arrIndex].value = this.graceParameters[arrIndex].Field_Type__c == 'Number' && !this.graceParameters[arrIndex].value ? 0 : this.graceParameters[arrIndex].value;
                    }

                } else if (i < this.basicDetailFields.length + this.keyDetails.length + this.transactionDetailsFields.length + this.graceParameters.length + this.emiHolidayParams.length) {
                    let arrIndex = i - (this.basicDetailFields.length + this.keyDetails.length + this.transactionDetailsFields.length + this.graceParameters.length);
                    if (arrIndex >= 0) {
                        this.emiHolidayParams[arrIndex].value = this.emiHolidayParams[arrIndex].Field_Label__c == details[i].fieldLabel && details[i].fieldValue ? this.emiHolidayParams[arrIndex].is_Lookup__c ? details[i].lookUpfieldValue : details[i].fieldValue : this.emiHolidayParams[arrIndex].value;
                        this.emiHolidayParams[arrIndex].value = this.emiHolidayParams[arrIndex].Field_Type__c == 'Checkbox' ? this.emiHolidayParams[arrIndex].value == '' ? false : true : this.emiHolidayParams[arrIndex].value;
                        this.emiHolidayParams[arrIndex].value = this.emiHolidayParams[arrIndex].Field_Type__c == 'Number' && !this.emiHolidayParams[arrIndex].value ? 0 : this.emiHolidayParams[arrIndex].value;
                    }
                } else if (i < this.basicDetailFields.length + this.keyDetails.length + this.transactionDetailsFields.length + this.graceParameters.length + this.emiHolidayParams.length + this.principalHolidayParams.length) {
                    let arrIndex = i - (this.basicDetailFields.length + this.keyDetails.length + this.transactionDetailsFields.length + this.graceParameters.length + this.emiHolidayParams.length);
                    if (arrIndex >= 0) {
                        this.principalHolidayParams[arrIndex].value = this.principalHolidayParams[arrIndex].Field_Label__c == details[i].fieldLabel && details[i].fieldValue ? this.principalHolidayParams[arrIndex].is_Lookup__c ? details[i].lookUpfieldValue : details[i].fieldValue : this.principalHolidayParams[arrIndex].value;
                        this.principalHolidayParams[arrIndex].value = this.principalHolidayParams[arrIndex].Field_Type__c == 'Checkbox' ? this.principalHolidayParams[arrIndex].value == '' ? false : true : this.principalHolidayParams[arrIndex].value;
                        this.principalHolidayParams[arrIndex].value = this.principalHolidayParams[arrIndex].Field_Type__c == 'Number' && !this.principalHolidayParams[arrIndex].value ? 0 : this.principalHolidayParams[arrIndex].value;
                    }
                } else if (i < this.basicDetailFields.length + this.keyDetails.length + this.transactionDetailsFields.length + this.purePaymentDetails.length) {
                    let arrIndex = i - (this.basicDetailFields.length + this.keyDetails.length + this.transactionDetailsFields.length);
                    if (arrIndex >= 0) {
                        this.purePaymentDetails[arrIndex].value = this.purePaymentDetails[arrIndex].Field_Label__c == details[i].fieldLabel && details[i].fieldValue ? this.purePaymentDetails[arrIndex].is_Lookup__c ? details[i].lookUpfieldValue : details[i].fieldValue : this.purePaymentDetails[arrIndex].value;
                        this.purePaymentDetails[arrIndex].value = this.purePaymentDetails[arrIndex].Field_Type__c == 'Checkbox' ? this.purePaymentDetails[arrIndex].value == '' ? false : true : this.purePaymentDetails[arrIndex].value;
                        this.purePaymentDetails[arrIndex].value = this.purePaymentDetails[arrIndex].Field_Type__c == 'Number' && !this.purePaymentDetails[arrIndex].value ? 0 : this.purePaymentDetails[arrIndex].value;
                    }
                } else if (i < this.basicDetailFields.length + this.keyDetails.length + this.transactionDetailsFields.length + this.purePaymentDetails.length + this.dropPaymentDetails.length) {
                    let arrIndex = i - (this.basicDetailFields.length + this.keyDetails.length + this.transactionDetailsFields.length + this.purePaymentDetails.length);
                    if (arrIndex >= 0) {
                        this.dropPaymentDetails[arrIndex].value = this.dropPaymentDetails[arrIndex].Field_Label__c == details[i].fieldLabel && details[i].fieldValue ? this.dropPaymentDetails[arrIndex].is_Lookup__c ? details[i].lookUpfieldValue : details[i].fieldValue : this.dropPaymentDetails[arrIndex].value;
                        this.dropPaymentDetails[arrIndex].value = this.dropPaymentDetails[arrIndex].Field_Type__c == 'Checkbox' ? this.dropPaymentDetails[arrIndex].value == '' ? false : true : this.dropPaymentDetails[arrIndex].value;
                        this.dropPaymentDetails[arrIndex].value = this.dropPaymentDetails[arrIndex].Field_Type__c == 'Number' && !this.dropPaymentDetails[arrIndex].value ? 0 : this.dropPaymentDetails[arrIndex].value;
                    }
                } else if (i < this.basicDetailFields.length + this.keyDetails.length + this.transactionDetailsFields.length + this.purePaymentDetails.length + this.dropPaymentDetails.length + this.graceParameters.length + this.emiHolidayParams.length + this.principalHolidayParams.length + this.penaltyDetails.length) {
                    let arrIndex = i - (this.basicDetailFields.length + this.keyDetails.length + this.transactionDetailsFields.length + this.purePaymentDetails.length + this.dropPaymentDetails.length + this.graceParameters.length + this.emiHolidayParams.length + this.principalHolidayParams.length);
                    if (arrIndex >= 0) {
                        this.penaltyDetails[arrIndex].value = this.penaltyDetails[arrIndex].Field_Label__c == details[i].fieldLabel && details[i].fieldValue ? this.penaltyDetails[arrIndex].is_Lookup__c ? details[i].lookUpfieldValue : details[i].fieldValue : this.penaltyDetails[arrIndex].value;
                        this.penaltyDetails[arrIndex].value = this.penaltyDetails[arrIndex].Field_Type__c == 'Checkbox' ? this.penaltyDetails[arrIndex].value == '' ? false : true : this.penaltyDetails[arrIndex].value;
                        this.penaltyDetails[arrIndex].value = this.penaltyDetails[arrIndex].Field_Type__c == 'Number' && !this.penaltyDetails[arrIndex].value ? 0 : this.penaltyDetails[arrIndex].value;
                    }
                }
            }
        }
             this.keyDetails.forEach(data=>{
                if(data.Storage_Field__c == 'Sanction_Loan_Amount__c'){
                    this.loanAmount = data.value;
                }
                if(data.Storage_Field__c == 'Sanction_Tenure__c'){
                    //this.sanctionloanTenor = data.value;
                     console.log('sanctionloanTenor>>'+this.sanctionloanTenor);
                }
            }

            )
            this.transactionDetailsFields[this.marginIndex].value = (Number(this.transactionDetailsFields[this.finalRateIndex].value) - Number(this.plrValue)).toFixed(2);;
            let tempProcessedStages = [];
            tempProcessedStages.push({
                name: 'Basic Details',
                showLine: true,
                isCompleted: this.basicDetailsFilled,
            });
            tempProcessedStages.push({
                name: 'Key Details',
                showLine: true,
                isCompleted: this.keyDetailsFilled,
            });
            tempProcessedStages.push({
                name: 'Transactional Details',
                showLine: true,
                isCompleted: this.transactionalDetailsFilled,
            })
            tempProcessedStages.push({
                name: 'Penalty Details',
                showLine: true,
                isCompleted: this.penaltyDetailsFilled,
            })

            this.processedStages = tempProcessedStages;

            //populates fields and checks for dependencies
            this.handleDependecy(this.transactionDetailsFields);
            this.handleDependecy(this.graceParameters);
            this.handleDependecy(this.emiHolidayParams);
            this.handleDependecy(this.principalHolidayParams);
            this.handleDependecy(this.purePaymentDetails);
            this.handleDependecy(this.dropPaymentDetails);
            this.handleDependecy(this.penaltyDetails);

            const stepLoanRecs = await getStepLoan({
                loanId: this.recordId
            });
            console.log('stepLoanRecs>>'+JSON.stringify(stepLoanRecs));
            this.transactionDetailsFields.forEach(data=>{
                if(data.Storage_Field__c == 'Number_of_Steps__c'){
                    data.value = stepLoanRecs.length;
                }else if(data.Storage_Field__c == 'Elastic_Credit_Line_Type__c'){
                    if(this.productData.subVariant.Name == 'Dropline'){
                        data.value = 'D';
                    }else{
                        data.value = 'H';
                    }
                    
                    this.updateRecordonFocusOut(this.loanTransactionRecord.Id,'Elastic_Credit_Line_Type__c',data.value);
                    this.fetchDropPureValues(data.value);
                }else if(data.Storage_Field__c == 'First_Disbursement_Amount__c'){
                    console.log('this.loanType>>>'+this.loanType);
                   
                        data.value = this.loanAmount;
                        this.updateRecordonFocusOut(this.loanTransactionRecord.Id,'First_Disbursement_Amount__c',this.loanAmount);
                    
                   
                }else if(data.Storage_Field__c == 'Interest_Due_date__c'){
                    this.interestDueDatePicklistOptions = data.picklistOptions;
                    console.log('data>>'+JSON.stringify(data.picklistOptions));
                   
                    if (this.loanType == 'Term Loan') {
                        data.picklistOptions = this.interestDueDatePicklistOptions.filter(item => item.value !== "26");
                    } else {
                        data.picklistOptions = [...this.interestDueDatePicklistOptions];
                    }


                    if(this.loanType == 'Over Draft'){
                        data.value = '26';
                        this.updateRecordonFocusOut(this.loanTransactionRecord.Id,'First_Disbursement_Amount__c','26');
                    }
                }else if(data.Storage_Field__c == 'Schedule_Method__c'){
                    const picklistOptionScheduledMethod = data.picklistOptions;
                    if(this.loanType == 'Flexi Funds'){
                        data.picklistOptions = picklistOptionScheduledMethod.filter(item => item.value !== "PRI" && item.value != 'PFT');
                    }else{
                       data.picklistOptions = [...picklistOptionScheduledMethod]; 
                    }
                }else if(data.Storage_Field__c == 'Interest_Frequency__c'){
                    const interestFrequencyPicklistOptions = data.picklistOptions;
                    if(this.loanType == 'Flexi Funds'){
                        data.picklistOptions = interestFrequencyPicklistOptions.filter(item => item.value !== "H");
                    }else{
                        data.picklistOptions = [...interestFrequencyPicklistOptions]; 
                    }
                }

                // Disable BPI fields for Flexi Funds
                /*if (this.loanType == 'Flexi Funds') {
                    const bpiDisabledFields = FLEXI_FUNDS_BPI_DISABLED_FIELDS.split(',');
                    if (bpiDisabledFields.includes(data.Storage_Field__c)) {
                        data.Is_Disabled__c = true;
                    }
                }*/c/addBankAccountCmp
            })

            //this.sortStepLoanRecords(stepLoanRecs);
            if (this.isDisableEdit) {
                this.disableAllFields();
            }
            this.isLoading = false;
        } catch (error) {
            this.isLoading = false;
            this.handleError(error, 'screenFieldFromApex');
        
            //this.showToast(this.toastTitle.ERROR, this.toastMessages.SOMETHING_WENT_WRONG, this.toastVariant.ERROR);
        }



    }

    handleStepLoanCount(event){
       
        this.transactionDetailsFields.forEach(data=>{
            if(data.Storage_Field__c == 'Number_of_Steps__c'){
                data.value = event.detail.stepLoanCount;
            }
        })

    }

    updatePicklistValues() {
        console.log('this.allowGrace>>'+this.allowGraceValue);

        console.log('this.allowPaymentInGracePeriod>>'+this.allowPaymentInGracePeriod);
        // if (!this.allowGraceValue || (this.allowGraceValue && !this.allowPaymentInGracePeriod)) {
        //     this.picklistValuesToBeShown = this.picklistValues.filter(element => element.value !== 'Grace');
        // }else{
        //     this.picklistValuesToBeShown = this.picklistValues;
        // }
        if (this.allowGraceValue && this.allowPaymentInGracePeriod) {
            this.picklistValuesToBeShown = this.picklistValues;
        } else {
            this.picklistValuesToBeShown = this.picklistValues.filter(element => element.value !== 'Grace');
        }
    }


    getPicklistValues(fieldArr) {
        fieldArr.forEach(async itm => {
            if (itm.Field_Type__c == 'Picklist' && itm.Storage_Object__c && itm.Storage_Field__c) {
                itm.isPicklist = true;
                itm.picklistOptions = await this.getPicklistOptionsFromApex(itm.Storage_Object__c, itm.Storage_Field__c);
            }
        })
    }

    handleDependecy(fieldArr) {
        fieldArr.forEach(itm => {
            this.sectionVisibility(itm.Storage_Field__c, itm.value);
            if (this.controllingFields.includes(itm.Storage_Field__c)) {
                this.handleEnableDependentField(itm.Storage_Field__c, fieldArr, itm.value);
            }
        })
    }


    handleAccordionBtn() {
        this.refs.btnTag.classList.toggle('save-button')
        this.refs.btnTag.classList.toggle('close-button');
        if (this.refs.btnTag.innerText == 'Open All') {
            let accordionNameList = [];
            Array.from(this.template.querySelectorAll('lightning-accordion-section')).forEach(item => {
                accordionNameList.push(item.name);
            });
            this.activeSections = [...accordionNameList];
            this.refs.btnTag.innerText = 'Close All';
            const button = this.template.querySelector('.openAccordionBtn');
            if (button) {
                button.style.setProperty('background-color', '#16283f');
                button.style.setProperty('border', '1px solid #7c3aed');
            }   
        } else {
            this.activeSections = [];
            this.refs.btnTag.innerText = 'Open All';
            const button = this.template.querySelector('.openAccordionBtn');
            if (button) {
                button.style.setProperty('background-color', '#1467EB');
            } 
        }

    }

    handleStepLoanDeletion(event) {
        this.stepIndexForDeletion = event.target.dataset.stepindex;
        this.recIdForDeletion = event.target.dataset.recid;
        this.transactionDetailsFields[this.numberOfStepsFieldIndex].value -= 1;
        this.modalVisibility = true;
    }

    confirmDelete() {
        console.log('confirmDelete>>');
        this.modalVisibility = false;
        this.deleteStepLoan(this.recIdForDeletion);
    }

    confirmAllDelete() {
        this.stepLoanUncheckModal = false;
        this.sectionVisibility('Step_Loan__c', false);
        this.stepLoanDetails = [];
        this.copiedStepLoanDetails = [];
        this.deleteAllStepLoan();
    }

    closeStepLoanAllDeleteModal(event) {
        this.stepLoanUncheckModal = false;
        this.sectionVisibility('Step_Loan__c', true);
        this.transactionDetailsFields[this.stepLoanCheckboxIndex].value = true;
        this.stepLoanDetails = [...this.copiedStepLoanDetails];
    }

    async deleteAllStepLoan() {
        try {
            await deleteAllStepLoans({ loanId: this.recordId });
        } catch (error) {
            this.handleError(error, 'deleteAllStepLoan');
            this.showToast(this.toastTitle.ERROR, this.toastMessages.SOMETHING_WENT_WRONG, this.toastVariant.ERROR);
        }
    }

    async deleteStepLoan(recId) {
        this.totalLoanTenor -= this.stepLoanDetails[this.stepIndexForDeletion].Loan_Tenor__c;
        try {
            const updatedStepLoanRecs = await deleteUpdateStepLoan({
                stepLoanId: recId,
                loanId: this.recordId
            });
            this.sortStepLoanRecords(updatedStepLoanRecs);
        } catch (error) {
            this.handleError(error, 'deleteStepLoan');
            this.showToast(this.toastTitle.ERROR, this.toastMessages.SOMETHING_WENT_WRONG, this.toastVariant.ERROR);
        }
    }

    sortStepLoanRecords(recordList) {
        let copiedScreenFieldsArr = JSON.parse(JSON.stringify(this.stepLoan));
        let tempStepLoan = [];
        recordList.forEach(rec => {
            let tempStepLoanObj = {};
            for (let i = 0; i < copiedScreenFieldsArr.length; i++) {
                tempStepLoanObj.Id = rec.Id;
                let fieldValue = rec[copiedScreenFieldsArr[i].Storage_Field__c];
                tempStepLoanObj[copiedScreenFieldsArr[i].Storage_Field__c] = fieldValue;
                copiedScreenFieldsArr[i].value = copiedScreenFieldsArr[i].Storage_Field__c == 'Step_Number__c' ? recordList.length + 1 : copiedScreenFieldsArr[i].value;
                this.totalLoanTenor = copiedScreenFieldsArr[i].Storage_Field__c == 'Loan_Tenor__c' ? this.totalLoanTenor + fieldValue : this.totalLoanTenor;
            }
            tempStepLoan.push(tempStepLoanObj);

        });
        this.stepLoan = [...copiedScreenFieldsArr];
        this.stepLoanDetails = [...tempStepLoan];
        this.copiedStepLoanDetails = [...tempStepLoan];
        if (this.isStepLoanActive) {
            this.transactionDetailsFields[this.numberOfStepsFieldIndex].value = this.stepLoanDetails.length;
            this.stepLoan[this.stepNumberIndex].value = recordList.length > 0 ? this.stepLoan[this.stepNumberIndex].value : 1;
        }

    }



    populateEndDates(){
        let pureEndDate = new Date(this.selectedLoanStartDate);
        pureEndDate.setMonth(pureEndDate.getMonth() + parseInt(fieldValue))
        this.updateRecordonFocusOut(this.loanTransactionRecord.Id, '', this.convertToSalesforceDate(pureEndDate));
    }

    fetchDropPureValues(fieldValue){
        console.log('fieldValue 820>>'+fieldValue);
        let dropTenure = 0;
        let pureTenure = 0;
        console.log('this.sanctionloanTenor>>'+this.sanctionloanTenor);

         if(fieldValue == 'D'){
            this.showPurePaymentDetails = false;
            this.showDropPaymentDetails = true;
            console.log(' this.dropPaymentDetails>>'+JSON.stringify(this.dropPaymentDetails));
            this.dropPaymentDetails.forEach(data => {
                if (data.Storage_Field__c == 'Dropline_Tenure__c') {
                    data.value = this.sanctionloanTenor;
                    dropTenure = this.sanctionloanTenor;
                }
                data.Is_Disabled__c = true;
            });
            this.purePaymentDetails.forEach(data => {
                if (data.Storage_Field__c == 'Pure_Tenure__c') {
                    data.value = 0;
                    pureTenure = 0;
                }
                
            });



        }else if(fieldValue == 'H'){
            this.showPurePaymentDetails = true;
            this.showDropPaymentDetails = true;
            this.purePaymentDetails.forEach(data => {
                if (data.Storage_Field__c == 'Pure_Tenure__c') {  
                    data.value = parseInt(this.productData.hybridTenure.Name);
                    pureTenure = parseInt(this.productData.hybridTenure.Name);
                }
                data.Is_Disabled__c = true;
            });
            this.dropPaymentDetails.forEach(data => {
                if (data.Storage_Field__c == 'Dropline_Tenure__c') {
                    data.value = this.sanctionloanTenor - parseInt(this.productData.hybridTenure.Name);
                    dropTenure = this.sanctionloanTenor - parseInt(this.productData.hybridTenure.Name);
                }
                data.Is_Disabled__c = true;
            });


        }

        console.log('pureTenure>>'+pureTenure);
        console.log('dropTenure>>'+dropTenure);

        this.updateRecordonFocusOut(this.loanTransactionRecord.Id, 'Pure_Tenure__c', pureTenure);
        this.updateRecordonFocusOut(this.loanTransactionRecord.Id, 'Dropline_Tenure__c', dropTenure);
        let pureENdDate = new Date(this.selectedLoanStartDate);
        pureENdDate.setMonth(pureENdDate.getMonth() + parseInt(pureTenure))
        this.purePaymentDetails.forEach(data => {
            if (data.Storage_Field__c == 'Pure_End_Date__c') {  
                
                data.value = this.convertToSalesforceDate(pureENdDate);
                this.updateRecordonFocusOut(this.loanTransactionRecord.Id, 'Pure_End_Date__c', this.convertToSalesforceDate(pureENdDate));
                data.Is_Disabled__c = true;
            }
            
        });

        // let pureENdDate = new Date(this.selectedLoanStartDate);
        // pureENdDate.setMonth(pureENdDate.getMonth() + parseInt(pureTenure))
        // this.updateRecordonFocusOut(this.loanTransactionRecord.Id, 'Pure_End_Date__c', this.convertToSalesforceDate(pureENdDate));
       
        console.log('pureENdDate<<'+pureENdDate);
        let dropLineENdDate = new Date(pureENdDate);
        dropLineENdDate.setMonth(dropLineENdDate.getMonth() + parseInt(dropTenure))
        //this.updateRecordonFocusOut(this.loanTransactionRecord.Id, 'Dropline_End_Date__c', this.convertToSalesforceDate(dropLineENdDate));

        this.dropPaymentDetails.forEach(data => {
            if (data.Storage_Field__c == 'Dropline_End_Date__c') {  
                
                data.value = this.convertToSalesforceDate(dropLineENdDate);
                this.updateRecordonFocusOut(this.loanTransactionRecord.Id, 'Dropline_End_Date__c', this.convertToSalesforceDate(dropLineENdDate));
                data.Is_Disabled__c = true;
            }
            
        });
       
        
    }

    async handleInputChange(event) {
        const index = event.target.dataset.index;
        const accordionName = event.currentTarget.dataset.accordion;
        let fieldValue = this.getFieldValue(event);
        
        if (accordionName == 'Transactional Details') {
            const storageField = this.transactionDetailsFields[index].Storage_Field__c;
            console.log('handleInputChange - storageField:', storageField, 'fieldValue:', fieldValue);

            // Handle Interest Due Date change FIRST (before any return statements)
            if (storageField === 'Interest_Due_date__c') {
                console.log('Interest Due Date changed to: ' + fieldValue);
                this.transactionDetailsFields[index].value = fieldValue;
                this.calculateBPIOnInterestDueDateChange(fieldValue);
                return;
            }

            let isToastRequired = true;
            let isValid = await this.isFieldValueInvalid(storageField, fieldValue, isToastRequired);
            if(storageField == 'Allow_BPI__c' && !fieldValue){
                this.transactionDetailsFields.forEach(data=>{
                    if(data.Storage_Field__c == 'BPI_Treatment__c'){
                        data.value = '';
                        this.updateRecordonFocusOut(this.loanTransactionRecord.Id,'BPI_Treatment__c' , '');
                    }
                })

            }

            if (isValid) {
               
                
                if(storageField == 'Allow_Grace__c'){
                    event.target.checked = true;
                    this.showGraceParameters = true;
                }
                return;
            }else{
                this.showGraceParameters = false;
                }
            this.selectedLoanStartDate = storageField == 'Loan_Start_Date__c' ? fieldValue : this.selectedLoanStartDate;
            this.transactionDetailsFields[index].value = fieldValue; //updating the value
            this.sectionVisibility(storageField, fieldValue);
            if(!this.showDropPaymentDetails){
            this.dropPaymentDetails.forEach(ele=>{

                    ele.value = '';

                })
            }
        if(!this.showPurePaymentDetails){
            this.purePaymentDetails.forEach(ele=>{
                    ele.value = '';
                })

            }

            if (this.controllingFields.includes(storageField)) {
                this.handleEnableDependentField(storageField, this.transactionDetailsFields, fieldValue); //disbales and enables the dependent field using controlling field API Name
            }
            
            //this is to handle the dependency of Allow Planned EMI Holiday in Grace field -- this dependency we are handling in JS instead of screen fields.
            if (storageField == 'Allow_Grace__c' || storageField == 'Allow_Planned_EMI_Holiday__c') {
                this.allowGraceValue = this.transactionDetailsFields[index].Storage_Field__c == 'Allow_Grace__c' ? fieldValue : this.allowGraceValue;
                this.showGraceParameters = this.allowGraceValue;
                this.updatePicklistValues();
                this.plannedEMIHolidayValue = this.transactionDetailsFields[index].Storage_Field__c == 'Allow_Planned_EMI_Holiday__c' ? fieldValue : this.plannedEMIHolidayValue;
                let tobeUpdatedValue = !(this.allowGraceValue && this.plannedEMIHolidayValue);
                this.transactionDetailsFields[this.allowPlannedEMIHolidayInGraceIndex].Is_Disabled__c = tobeUpdatedValue;

                if (tobeUpdatedValue) {
                    this.transactionDetailsFields[this.allowPlannedEMIHolidayInGraceIndex].value = false;
                    this.updateRecordonFocusOut(this.loanTransactionRecord.Id, this.transactionDetailsFields[this.allowPlannedEMIHolidayInGraceIndex].Storage_Field__c, !tobeUpdatedValue);
                }

                if (storageField == 'Allow_Grace__c') {
                    if (!fieldValue) {
                        this.graceParameters.forEach(itm => {
                            itm.value = itm.Field_Type__c == 'Checkbox' ? false : '';
                        })
                    }
                    this.resetFieldValues(this.graceParametersFieldNames);
                } else if (storageField == 'Allow_Planned_EMI_Holiday__c') {
                    if (!fieldValue) {
                        this.emiHolidayParams.forEach(itm => {
                            itm.value = itm.Field_Type__c == 'Checkbox' ? false : '';
                        })
                    }
                    this.resetFieldValues(this.emiHolidayParamsFieldNames);
                }

            }else if (storageField == 'Step_Loan__c') {
                if (fieldValue) {
                    this.isStepLoanActive = fieldValue;
                    
                    this.stepLoanDetails = [...this.copiedStepLoanDetails];
                    this.transactionDetailsFields[this.numberOfStepsFieldIndex].value = this.stepLoanDetails.length;
                    this.stepLoan[this.stepNumberIndex].value = this.stepLoanDetails.length + 1;
                } else {
                    this.stepLoanUncheckModal = true;
                    this.isStepLoanActive = !fieldValue;
                    this.copiedStepLoanDetails = [...this.stepLoanDetails];
                    this.stepLoanDetails = [];
                    this.transactionDetailsFields[this.numberOfStepsFieldIndex].value = 0;
                    this.stepLoan.forEach(field => {
                        if (field.Storage_Field__c != 'Step_Number__c') {
                            field.value = '';
                        }
                    })
                }
                if (this.copiedStepLoanDetails.length) {
                    await StepLoanActivationHandler({
                        loanId: this.recordId,
                        changedValue: fieldValue
                    })
                }
            } else if (storageField == 'Allow_Planned_Principal_Holiday__c') {
                if (!fieldValue) {
                    this.principalHolidayParams.forEach(itm => {
                        itm.value = itm.Field_Type__c == 'Checkbox' ? false : '';
                    })
                }
                this.resetFieldValues(this.principalHolidayParamsFieldNames);
            }else if(storageField == 'Elastic_Credit_Line_Type__c'){
                console.log('fieldValue>>'+fieldValue);
                this.fetchDropPureValues(fieldValue);

            }

        } else if (accordionName == 'Grace Parameters') {
            this.graceParameters[index].value = fieldValue;
            this.allowGraceValue = this.graceParameters[index].Storage_Field__c =='Allow_Grace__c' ? fieldValue : this.allowGraceValue;
            this.updatePicklistValues();
            this.graceFrequencyValue = this.graceParameters[index].Storage_Field__c == 'Grace_Period_Frequency__c' ? parseInt(fieldValue) : this.graceFrequencyValue;
            let storageField = this.graceParameters[index].Storage_Field__c;
            
            if(storageField == 'Allow_Payment_in_Grace_Period__c'){

                this.allowPaymentInGracePeriod = fieldValue;
                this.updatePicklistValues();

            }

        } else if (accordionName == 'Step Loan') {
            this.stepLoan[index].value = fieldValue;
        } else if (accordionName == 'Penalty Details') {
            this.penaltyDetails[index].value = fieldValue;
        } else if (accordionName == 'EMI Holiday Parameters') {
            this.emiHolidayParams[index].value = fieldValue;
        } else if (accordionName == 'Principal Holiday Parameters') {
            this.principalHolidayParams[index].value = fieldValue;
        } else if (accordionName == 'Pure Payment Details') {
            let storageField = this.purePaymentDetails[index].Storage_Field__c;
            console.log('storageField>>'+storageField);
            //if (storageField == 'Pure_Tenure__c') {
                if (fieldValue > this.sanctionloanTenor) {
                    console.log('815>>');
                    this.showToast('Error','Pure Tenure cannot be more than sanction loan tenure.','error');
                    event.target.value = 0;
                    this.dropPaymentDetails[index].value = this.sanctionloanTenor;
                    this.updateRecordonFocusOut(this.loanTransactionRecord.Id, 'Dropline_Tenure__c', this.dropPaymentDetails[index].value);
                    return;

                } 
                else {
                    this.purePaymentDetails[index].value = parseInt(this.productData.hybridTenure.Name);
                    console.log('1152>>');
                    this.dropPaymentDetails[index].value = this.sanctionloanTenor - parseInt(this.productData.hybridTenure.Name);
                    console.log('1154>>');
                    this.dropPaymentDetails[index].Is_Disabled__c = true;  
                    this.updateRecordonFocusOut(this.loanTransactionRecord.Id, 'Pure_Tenure__c', this.purePaymentDetails[index].value);         
                    this.updateRecordonFocusOut(this.loanTransactionRecord.Id, 'Dropline_Tenure__c', this.dropPaymentDetails[index].value);
                    console.log('1159>>');
                   
                    if (isNaN(fieldValue)) {
                        this.purePaymentDetails.forEach(itm => {
                            itm.value = '';
                        })
                        this.updateRecordonFocusOut(this.loanTransactionRecord.Id, 'Pure_End_Date__c', '');
                        return;
                    }
                }
            //}
            console.log('1171');
                let pureEndDateS;
                this.purePaymentDetails.forEach(itm => {
                    if (itm.Storage_Field__c == 'Pure_End_Date__c') {
                        itm.Is_Disabled__c = true;
                        let pureEndDate = new Date(this.selectedLoanStartDate);
                        pureEndDate.setMonth(pureEndDate.getMonth() + parseInt(fieldValue))
                        console.log('pureEndDate>>'+pureEndDate);
                        itm.value = this.convertToSalesforceDate(pureEndDate);
                        pureEndDateS = pureEndDate
                        this.updateRecordonFocusOut(this.loanTransactionRecord.Id, itm.Storage_Field__c, this.convertToSalesforceDate(pureEndDate));
                    }
                })
                    //Below line will populate the pure payment end date
                    this.purePaymentDetails = JSON.parse(JSON.stringify(this.purePaymentDetails));
                    this.dropPaymentDetails.forEach(itm => {
                        if (itm.Storage_Field__c == 'Dropline_End_Date__c') {
                            itm.Is_Disabled__c = true;
                            console.log('pureEndDateS>>'+pureEndDateS);
                            let dropLineENdDate = new Date(pureEndDateS);
                            dropLineENdDate.setMonth(dropLineENdDate.getMonth() + parseInt(this.dropPaymentDetails[index].value))
                            itm.value = this.convertToSalesforceDate(dropLineENdDate);
                            this.updateRecordonFocusOut(this.loanTransactionRecord.Id, itm.Storage_Field__c, this.convertToSalesforceDate(dropLineENdDate));
                        }
                    })
                    this.dropPaymentDetails = JSON.parse(JSON.stringify(this.dropPaymentDetails));

                
            //}

        } else if (accordionName == 'Drop Payment Details') {
            
            
            if (this.purePaymentDetails[index].value == '') {
                this.purePaymentDetails[index].value = 0;
            }
            // let sum = parseFloat(fieldValue) + parseFloat(this.purePaymentDetails[index].value);
            // console.log('sum>>' + sum);
            if (fieldValue > this.sanctionloanTenor) {
                this.showToast('Error', 'Drop Line Tenure cannot be greater than the loan tenor.', 'error');
                event.target.value = 0;
                fieldValue =0;
                return;
            } else {
                this.dropPaymentDetails[index].value = fieldValue;
                let storageField = this.dropPaymentDetails[index].Storage_Field__c;
                if (storageField == 'Dropline_Tenure__c') {
                    if (this.isFieldValueInvalid(storageField, this.selectedLoanStartDate, true)) {
                        return;
                    }
                    if (isNaN(fieldValue)) {
                        this.dropPaymentDetails.forEach(itm => {
                            itm.value = '';
                        })
                        this.updateRecordonFocusOut(this.loanTransactionRecord.Id, 'Dropline_End_Date__c', '');
                        return;
                    }
                    this.dropPaymentDetails.forEach(itm => {
                        if (itm.Storage_Field__c == 'Dropline_End_Date__c') {
                            let dropLineENdDate = new Date(this.selectedLoanStartDate);
                            dropLineENdDate.setMonth(dropLineENdDate.getMonth() + parseInt(fieldValue))
                            itm.value = dropLineENdDate;
                            this.updateRecordonFocusOut(this.loanTransactionRecord.Id, itm.Storage_Field__c, this.convertToSalesforceDate(dropLineENdDate));
                        }
                    })

                    this.dropPaymentDetails = JSON.parse(JSON.stringify(this.dropPaymentDetails));
                }

            }
        }

    }

    handleEnableDependentField(storageField, fieldsArr, fieldValue) {
        for (let field of fieldsArr) {
            if (storageField == field?.Visibility_Controlled_By__r?.Storage_Field__c) {
                if (field?.Visibility_Controlled_By__r?.Field_Type__c == 'Checkbox') {
                    field.Is_Disabled__c = !(field?.Visibility_Controlled_By_Value__c && fieldValue);
                } else {
                    let controlledByValue = field?.Visibility_Controlled_By_Value__c.split(';');
                    field.Is_Disabled__c = true;
                    for (let val of controlledByValue) {
                        if (val == fieldValue) {
                            field.Is_Disabled__c = false;
                            //break;
                        }
                        // field.Is_Disabled__c = !(val == fieldValue);

                    }

                    if (field.Is_Disabled__c) {
                        field.value = '';
                        this.updateRecordonFocusOut(this.loanTransactionRecord.Id, field.Storage_Field__c, '');
                    }
                    //break;
                }
            }
        }
    }

    async resetFieldValues(fieldNamesArr) {
        await resetFieldValues({
            loanTransactionId: this.loanTransactionRecord.Id,
            fieldNames: fieldNamesArr
        });
    }

    handleStepLoanChange(event) {
        const fieldApiName = event.target.dataset.apiname;
        const index = event.target.dataset.stepindex;
        let fieldValue = this.getFieldValue(event);

        if (!fieldValue) {
            this.showToast(this.toastTitle.ERROR, this.toastMessages.LOAN_TENOR_EMPTY, this.toastVariant.ERROR);
            return;
        }

        if (fieldValue && fieldApiName == 'Loan_Tenor__c') {
            let enteredTenor = this.totalLoanTenor + parseInt(fieldValue);
            if (enteredTenor > this.loanTransactionRecord?.Loan_Application__r?.Tenor_Months__c) {
                this.showToast(this.toastTitle.ERROR, this.toastMessages.LOAN_TENOR_VALIDATION + `(${this.loanTransactionRecord.Loan_Application__r.Tenor_Months__c})`, this.toastVariant.ERROR);
                return;
            }
        }
        this.stepLoanDetails[parseInt(index)][fieldApiName] = fieldValue;
    }

    updateStepLoan(event) {
        const apiName = event.target.dataset.apiname;
        this.updateRecordonFocusOut(event.target.dataset.recid, apiName, event.target.value);
    }

    updateRecords(event) {
        console.log('FOCUS OUT');
        // event.stopPropagation();
        const index = event.target.dataset.index;
        const accordionName = event.target.dataset.accordion;
        let storageField = '';

        let fieldValue = this.getFieldValue(event);

        if (accordionName == 'Transactional Details') {
            storageField = this.transactionDetailsFields[index].Storage_Field__c;
            if (storageField === 'Interest_Due_date__c') {
                return;
            }
            if (this.isFieldValueInvalid(storageField, fieldValue, false)) {
                return;
            }
        } else if (accordionName == 'Grace Parameters') {
            storageField = this.graceParameters[index].Storage_Field__c;

        } else if (accordionName == 'EMI Holiday Parameters') {
            storageField = this.emiHolidayParams[index].Storage_Field__c;
        } else if (accordionName == 'Principal Holiday Parameters') {
            storageField = this.principalHolidayParams[index].Storage_Field__c;
        } else if (accordionName == 'Penalty Details') {
            storageField = this.penaltyDetails[index].Storage_Field__c;
        } else if (accordionName == 'Pure Payment Details') {
            let validateFieldValue = storageField == 'Pure_Tenure__c' ? this.selectedLoanStartDate : fieldValue;
            if (this.isFieldValueInvalid(storageField, validateFieldValue, false)) {
                return;
            }
            storageField = this.purePaymentDetails[index].Storage_Field__c;
        } else if (accordionName == 'Drop Payment Details') {
            let validateFieldValue = storageField == 'Dropline_Tenure__c' ? this.selectedLoanStartDate : fieldValue;
            if (this.isFieldValueInvalid(storageField, validateFieldValue, false)) {
                return;
            }
            storageField = this.dropPaymentDetails[index].Storage_Field__c;
        }


        if (storageField) {
            this.refreshReq = true;
            this.updateRecordonFocusOut(this.loanTransactionRecord.Id, storageField, fieldValue);
        }
    }

    isFieldValueInvalid(storageField, fieldValue, isToastRequired) {
        let isFieldValueInvalid = false;
        if (storageField == 'Loan_Start_Date__c') {

            let beforeDate = new Date(this.integrationDetailRec.Business_Date__c);
            let afterDate = new Date(this.integrationDetailRec.Business_Date__c);
            let selectedDate = new Date(fieldValue);
            beforeDate.setDate(new Date(this.integrationDetailRec.Business_Date__c).getDate() - parseInt(this.constantsMetadataRecords.data.Loan_Start_Date_Min_Days.Value__c));
            afterDate.setDate(new Date(this.integrationDetailRec.Business_Date__c).getDate() + parseInt(this.constantsMetadataRecords.data.Loan_Start_Date_Max_Days.Value__c));
            beforeDate.setHours(0, 0, 0, 0);
            afterDate.setHours(0, 0, 0, 0);
            selectedDate.setHours(0, 0, 0, 0);
            if (selectedDate > afterDate || selectedDate < beforeDate) {
                if (isToastRequired) {
                    this.showToast(this.toastTitle.ERROR, this.constantsMetadataRecords.data.Selected_Loan_Start_Date_Not_Valid.Value__c, this.toastVariant.ERROR);
                }
                return !isFieldValueInvalid;
            }

        } else if (storageField == 'Pure_Tenure__c' && !fieldValue) {
            if (isToastRequired) {
                this.showToast(this.toastTitle.ERROR, this.constantsMetadataRecords.data.Loan_Start_Date_Is_Empty.Value__c, this.toastVariant.ERROR);
            }
            return !isFieldValueInvalid;
        } else if (storageField == 'Dropline_Tenure__c' && !fieldValue) {
            if (isToastRequired) {
                this.showToast(this.toastTitle.ERROR, this.constantsMetadataRecords.data.Loan_Start_Date_Is_Empty.Value__c, this.toastVariant.ERROR);
            }
                return !isFieldValueInvalid;   
            }

        return isFieldValueInvalid;
    }

    async updateRecordonFocusOut(recordId, fieldApiName, fieldValue) {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = recordId;
        fields[fieldApiName] = fieldValue;
        const recordInput = {
            fields
        };
        console.log('recordInput>>' + JSON.stringify(recordInput));
        await updateRecord(recordInput);

    }

    async refreshData() {
        console.log('in refreshdata method')

        if (this.refreshReq) {
            this.getScreenFieldsFromApex();
            this.refreshReq = false;
        }
    }

    async getPicklistOptionsFromApex(storageObject, storageField) {
        const result = await getPicklistValues({
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

    sectionVisibility(storageField, fieldValue) {
        if (storageField == 'Step_Loan__c') {
            this.showStepLoanSection = fieldValue;
        } else if (storageField == 'Allow_Grace__c') {
            this.showGraceParameters = fieldValue;

        } else if (storageField == 'Allow_Planned_EMI_Holiday__c') {
            this.showEmiHolidayparams = fieldValue;
        } else if (storageField == 'Allow_Planned_Principal_Holiday__c') {
            this.showPrincipalHolidayparams = fieldValue;
        } else if (storageField == 'Elastic_Credit_Line_Type__c') {
            this.showPurePaymentDetails = fieldValue == 'P' || fieldValue == 'H';
            this.showDropPaymentDetails = fieldValue == 'D' || fieldValue == 'H';
           
        }
    }

    showToast(title, msg, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: msg,
                variant: variant,
            }),
        )
    }

    getFieldValue(event) {
        return event.target.type == 'checkbox' ? event.target.checked : event.target.value;
    }

    closeModal(event) {
        this.modalVisibility = false;
    }

    convertToSalesforceDate(jsDate) {
        return jsDate.getFullYear().toString() + '-' + (jsDate.getMonth() + 1) + '-' + jsDate.getDate()
    }



    handleError(error, eventName) {
        //console.error('error in: '+ eventName +' ---> '+error);
    }

    handleRefreshBPI() {
        this.isLoading = true;

        // Invoke the Autolaunched Flow silently via Apex
        invokeBPIFlow({ loanId: this.recordId })
            .then(result => {
                console.log('BPI Flow Result:', JSON.stringify(result));
                if (result) {
                    // Create a new array to force LWC reactivity
                    let updatedFields = [];
                    this.transactionDetailsFields.forEach(field => {
                        let updatedField = { ...field };
                        if (field.Storage_Field__c === 'Interest_Due_date__c') {
                            updatedField.value = result.Interest_Due_date__c;
                        } else if (field.Storage_Field__c === 'Allow_BPI__c') {
                            updatedField.value = result.Allow_BPI__c;
                        } else if (field.Storage_Field__c === 'BPI_Treatment__c') {
                            updatedField.value = result.BPI_Treatment__c;
                        }
                        updatedFields.push(updatedField);
                    });

                    // Force reactivity by assigning a new array
                    this.transactionDetailsFields = [...updatedFields];
                    console.log('Updated transactionDetailsFields:', JSON.stringify(this.transactionDetailsFields));

                    // Show success toast
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'BPI fields refreshed successfully!',
                            variant: 'success'
                        })
                    );
                } else {
                    console.log('No result returned from BPI Flow');
                }
            })
            .catch(error => {
                console.error('Error invoking BPI Flow:', error);
                let errorMessage = 'An error occurred while refreshing BPI fields.';
                if (error && error.body && error.body.message) {
                    errorMessage = error.body.message;
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: errorMessage,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    calculateBPIOnInterestDueDateChange(interestDueDateValue) {

        this.isLoading = true;

        this.updateRecordonFocusOut(this.loanTransactionRecord.Id, 'Interest_Due_date__c', interestDueDateValue)
            .then(() => {
                return this.handleRefreshBPI();
            })
            .catch(error => {
                let errorMessage = 'An error occurred while calculating BPI fields.';
                if (error && error.body && error.body.message) {
                    errorMessage = error.body.message;
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: errorMessage,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
                console.log('=== calculateBPIOnInterestDueDateChange END ===');
            });
    }

}