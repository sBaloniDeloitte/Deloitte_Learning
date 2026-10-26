import { LightningElement, api, track } from 'lwc';
import getScreenData from '@salesforce/apex/HL_GrossMarginController.getScreenData';
import updateYearName from '@salesforce/apex/HL_GrossMarginController.updateYearName';
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import calculateGrowth from '@salesforce/apex/HL_GrossMarginController.calculateGrowth';
import getEligibilityConsiderationPicklist from '@salesforce/apex/HL_CashProfitController.getEligibilityConsiderationPicklist';
import updateEligibilityConsideration from '@salesforce/apex/HL_GrossMarginController.updateEligibilityConsideration';

export default class Hl_grossMarginChildCmp extends LightningElement {

    @api loanId;
    @api applicantId;
    @track screenDataResult;
    @track loadTable = false;
    @track parentRecId;
    @track sepMultiplierAverage = 0;
    isAddYearsEnabled = false;
    yearVal;
    spinnerRun = false;
    childRecId;
    @track eligibilityOption = '';
    @track eligibilityOptions = [];
    @track yearCount = 0;
    @track averageValue = 0;
    //874
    turnOverGrowth;
    grossProfit;
    cashProfit;
    additionalGrossMargin;
    additionalFoir;
    //874
    isDarkThemeInjected = false;

    connectedCallback() {
        console.log('loanId=:' + this.loanId);
        console.log('applicantId=:' + this.applicantId);
        getEligibilityConsiderationPicklist()
            .then(result => {
                this.eligibilityOptions = result.map(val => ({ label: val, value: val }));
            })
            .catch(error => {
                this.eligibilityOptions = [];
            });
        this.getScreenData();
    }

    get eligibilityColspan() {
        if (this.screenDataResult && this.screenDataResult.headerValues) {
            // Subtract 1 for the label column
            return this.screenDataResult.headerValues.length - 1;
        }
        return 1;
    }

    get processedParticularsData() {
        if (!this.screenDataResult || !this.screenDataResult.particularsData) return [];

        const averageEntry = this.screenDataResult.particularsData.find(
            row => row.particularName === 'Average'
        );
        this.averageValue = averageEntry?.yearData?.[0]?.averageValue || 0;
        this.yearCount = averageEntry?.yearData?.length || 0;
        return this.screenDataResult.particularsData.map(row => ({
            ...row,
            isEligibility: row.particularName === 'Amount Considered For Eligibility Calculation',
            isAverage: row.particularName === 'Average'
        }));
    }

    getScreenData() {
        getScreenData({
            loanId: this.loanId,
            apDetId: this.applicantId
        }).then(response => {
            console.log('response=:' + JSON.stringify(response));
            this.screenDataResult = response;
            if(response.isTurnOverGrowth){
                 this.turnOverGrowth = response.isTurnOverGrowth;
            }
            if(response.grossProfit){
                this.grossProfit=response.grossProfit;
            }
            if(response.cashProfit){
                this.cashProfit=response.cashProfit;
            }
            if(response.additionalGrossMargin!=null && response.additionalGrossMargin!=undefined &&  response.additionalGrossMargin!=''){
                this.additionalGrossMargin= response.additionalGrossMargin;
            }
            if(response.additionalFoir!=null && response.additionalFoir!=undefined && response.additionalFoir!=''){
                this.additionalFoir=response.additionalFoir;
            }
            // Set eligibilityOption from the backend field if available
            if (response && response.particularsData && response.particularsData.length > 0) {
                // Find the parent record's eligibility value if available
                if (response.eligibilityConsideration) {
                    this.eligibilityOption = response.eligibilityConsideration;
                }
            }
            this.loadTable = true;
        }).catch(error => {
            console.error('Error getScreenData =:' + JSON.stringify(error));
        })
    }

    addyears(event) {
        this.isAddYearsEnabled = true;
    }

    resetYears(event) {
        this.yearVal = null;
        this.isAddYearsEnabled = false;
    }

    inputChanged(event) {
        this.yearVal = event.target.value;
    }

    handleEligibilityChange(event) {
        this.eligibilityOption = event.detail.value;
        console.log('Selected Eligibility Option:', this.eligibilityOption); // Debug line
        // Save the selected value to the backend
        updateEligibilityConsideration({
            loanId: this.loanId,
            apDetId: this.applicantId,
            eligibilityValue: this.eligibilityOption
        })
            .then(() => {
                // Optionally show a toast or handle success
            })
            .catch(error => {
                // Optionally handle error
            });
    }

    handleSaveYearData() {
        if (this.yearVal == null || this.yearVal == undefined) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter current year.',
                    variant: 'error',
                }),
            );
        }
        else {
            this.spinnerRun = true;
            updateYearName({
                loanId: this.loanId,
                apDetId: this.applicantId,
                yearVal: this.yearVal
            }).then(response => {
                this.spinnerRun = false;
                this.yearVal = null;
                this.isAddYearsEnabled = false;
                this.getScreenData();
            }).catch(error => {
                this.spinnerRun = false;
            })
        }
    }

    handleInputValueChange(event) {
        console.log('event.target.dataset.id=:' + event.target.dataset.id);
        console.log('event.target.value=:' + event.target.value);
        console.log('event.target.dataset.parent=:' + event.target.dataset.parent);
        this.childRecId = event.target.dataset.id;
        this.parentRecId = event.target.dataset.parent;
        const fields = {};
        fields['Id'] = event.target.dataset.id;
        fields['Yearly_Amount__c'] = event.target.value;
        const recordInput = { fields };
        updateRecord(recordInput)
            .then((response) => {
                console.log('updateRecord -->' + JSON.stringify(response));
                this.calculateGrowth();
            })
            .catch(error => {
                console.error('Error updateRecord -->' + JSON.stringify(error));
            });
    }

    calculateGrowth() {
        calculateGrowth({
            recId: this.parentRecId,
            loanId: this.loanId,
            apDetId: this.applicantId
        }).then(response => {
            console.log('calculateGrowth -->' + JSON.stringify(response));
            this.getScreenData();
        }).catch(error => {
            console.error('Error calculateGrowth -->' + JSON.stringify(error));
        })
    }
     //874
    handleSustainableValueChange(event){
        const fields = {};
        console.log('this.parentRecId'+this.screenDataResult.recordId);
        fields['Id'] = this.screenDataResult.recordId;
        console.log('event.target.name=:'+event.target.name);
        console.log('event.target.value=:'+event.target.checked);
         if(event.target.name=='additionalGrossMargin'){
            this.additionalGrossMargin =event.target.value;
            fields['Additional_Gross_Margin__c'] =  this.additionalGrossMargin;
        }
        if(event.target.name=='additionalFOIR'){
            this.additionalFoir =event.target.value;
            fields['HL_Additional_FOIR__c'] =  this.additionalFoir;
        }
        if(event.target.name=='turnOverGrowthSustainable'){
            this.turnOverGrowth =event.target.checked;
            fields['Is_Turnover_Growth_Sustainable__c'] =  this.turnOverGrowth;
        }
        if(event.target.name=='grossProfitSustainable'){
            this.grossProfit =event.target.checked;
            fields['Is_Gross_Profit_Sustainable__c'] =  this.grossProfit;
        }
        if(event.target.name=='cashProfitSustainable'){
            this.cashProfit =event.target.checked;
            fields['Is_Cash_Profit_Sustainable__c'] =  this.cashProfit;
        }
        const recordInput = { fields };
        updateRecord(recordInput)
        .then((response) => {
            console.log('update response: '+JSON.stringify(response));
            this.getScreenData();
        })
        .catch(error => {
            console.log('Error updateRecord -->'+ JSON.stringify(error));
        });
    }
    //874

    renderedCallback() {
        if (!this.isDarkThemeInjected) {
            this.isDarkThemeInjected = true;
            this.injectDarkThemeStyles();
        }
    }

    injectDarkThemeStyles() {
        const style = document.createElement('style');
        style.innerText = `
            .slds-dropdown,
            .slds-dropdown__list,
            .slds-listbox_vertical {
                background-color: #16283f !important;
                border-color: #33455e !important;
            }
            .slds-listbox__option,
            .slds-listbox__item {
                background-color: #16283f !important;
                color: #ffffff !important;
            }
            .slds-listbox__option:hover,
            .slds-listbox__option:focus,
            .slds-listbox__option.slds-has-focus,
            .slds-listbox__option[aria-selected="true"] {
                background-color: #1589ee !important;
                color: #ffffff !important;
            }
            .slds-select,
            .slds-combobox__input {
                background-color: #16283f !important;
                border: 1px solid #33455e !important;
                color: #ffffff !important;
                height: 2.25rem !important;
            }
        `;
        this.template.querySelector('.styleContainer')?.appendChild(style);
    }

}