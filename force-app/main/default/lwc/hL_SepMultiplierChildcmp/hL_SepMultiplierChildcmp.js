import { LightningElement, api, track } from 'lwc';
import getScreenData from '@salesforce/apex/HL_sepMultiplier.getScreenData';
import updateYearName from '@salesforce/apex/HL_sepMultiplier.updateYearName';
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import calculateGrowth from '@salesforce/apex/HL_sepMultiplier.calculateGrowth';
import upsertRentalIncome from '@salesforce/apex/HL_sepMultiplier.upsertRentalIncome';
import getRentalDetails from '@salesforce/apex/HL_sepMultiplier.getRentalDetails';
import getEligibilityConsiderationPicklist from '@salesforce/apex/HL_CashProfitController.getEligibilityConsiderationPicklist';
import updateEligibilityConsideration from '@salesforce/apex/HL_sepMultiplier.updateEligibilityConsideration';
import upsertAdditionalMultiplier from '@salesforce/apex/HL_sepMultiplier.upsertAdditionalMultiplier'

export default class HL_SepMultiplierChildcmp extends LightningElement {

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
    @track averageValue=0;
    rentalIncome = 0;
    rentalRecId = '';
    //874
    growthSustainable;
    additionalMultiplier;
    additionalFoir;
    //874
    isDarkThemeInjected = false;

    connectedCallback() {
        getEligibilityConsiderationPicklist()
            .then(result => {
                this.eligibilityOptions = result.map(val => ({ label: val, value: val }));
            })
            .catch(error => {
                this.eligibilityOptions = [];
            });
        this.getScreenData();
        this.getRentalData();
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
        //this.averageValue = averageEntry?.yearData?.[0]?.averageValue;
        this.yearCount = averageEntry?.yearData?.length || 0;
        return this.screenDataResult.particularsData.map(row => ({
            ...row,
            isEligibility: row.particularName === 'Eligibility Consideration',
            isAverage: row.particularName === 'Average'
        }));
    }
    getScreenData() {
        getScreenData({
            loanId: this.loanId,
            apDetId: this.applicantId
        }).then(response => {
            this.screenDataResult = response;
            // Set eligibilityOption from the backend field if available
            if (response && response.particularsData && response.particularsData.length > 0) {
                // Find the parent record's eligibility value if available
                if (response.eligibilityConsideration) {
                    this.eligibilityOption = response.eligibilityConsideration;
                }
                if(response.growthSustainable){
                    this.growthSustainable = response.growthSustainable;
                }
                if(response.additionalFoir){
                    this.additionalFoir = response.additionalFoir;
                }
                
            }
            if (this.screenDataResult && this.screenDataResult.particularsData) {
                this.screenDataResult.particularsData.forEach(row => {
                    row.isAverageRow = row.particularName === 'Average';
                });
            }
            this.loadTable = true;
            this.calculateAndUpdateAverage();
            // this.parentRecId = response.recordId;
        }).catch(error => {

        })
    }
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
        this.childRecId = event.target.dataset.id;
        this.parentRecId = event.target.dataset.parent;
        const fields = {};
        fields['Id'] = event.target.dataset.id;
        fields['Yearly_Amount__c'] = event.target.value;
        const recordInput = { fields };
        updateRecord(recordInput)
            .then((response) => {
                this.calculateGrowth();
                this.calculateAndUpdateAverage();
            })
            .catch(error => {
            });
    }

    handleRentalIncomeChange(event) {
        this.rentalIncome = event.target.value;

        upsertRentalIncome({
            'loanId' : this.loanId,
            'applicantId' : this.applicantId,
            'rentalIncome' : this.rentalIncome,
            'recId' : this.rentalRecId
        })
        .then((response) => {
            if(response != 'Success'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: response,
                        variant: 'error',
                    }),
                );
            }
        })
        .catch(error => {
        });
    }
    

    getRentalData() {

        getRentalDetails({
            'loanId' : this.loanId,
            'applicantId' : this.applicantId
        })
        .then((response) => {
            if(response){
                this.rentalRecId = response[0];
                this.rentalIncome = response[1];
            }
        })
        .catch(error => {
        });
    }

    calculateGrowth() {
        calculateGrowth({
            recId: this.parentRecId,
            loanId: this.loanId,
            apDetId: this.applicantId
        }).then(response => {
            this.getScreenData();
        }).catch(error => {

        })
    }
    calculateAndUpdateAverage() {
        // Find Sep Multiplier row
        let sepMultiplierRow = this.screenDataResult.particularsData.find(
            row => row.particularName === 'Sep Multiplier'
        );
        // Find Average row
        let averageRow = this.screenDataResult.particularsData.find(
            row => row.particularName === 'Average'
        );
        if (!sepMultiplierRow || !averageRow) return;

        let sum = 0, count = 0;
        sepMultiplierRow.yearData.forEach(yearObj => {
            let val = yearObj.yearValue;
            if (val !== null && val !== undefined && !isNaN(val)) {
                sum += Number(val);
                count++;
            }
        });
        let sepMultiplierAvg = count > 0 ? (sum / count) : 0;

        this.averageValue=sepMultiplierAvg;
        // Update all yearData cells in Average row with the calculated average
        averageRow.yearData.forEach(yearObj => {
            yearObj.yearValue = sepMultiplierAvg;
            this.updateAverageInApex(yearObj.recordId, sepMultiplierAvg);
        });

        this.sepMultiplierAverage = sepMultiplierAvg;
        this.screenDataResult = { ...this.screenDataResult }; // trigger UI update
    }
    updateAverageInApex(recordId, avgValue) {
        const fields = {};
        fields['Id'] = recordId;
        fields['Average_Amount__c'] = avgValue;
        const recordInput = { fields };
        updateRecord(recordInput);
    }
    //874
    handleSustainableValueChange(event){
        const fields = {};
        fields['Id'] = this.screenDataResult.recordId;
        if(event.target.name=='growthSustainable'){
            this.growthSustainable =event.target.checked;
            fields['Is_Growth_Sustainable__c'] =  this.growthSustainable;
        }
        if(event.target.name=='additionalFOIR'){
            this.additionalFoir =event.target.value;
            fields['HL_Additional_FOIR__c'] =  this.additionalFoir;
        }
        const recordInput = { fields };
        updateRecord(recordInput)
        .then((response) => {
            this.calculateGrowth();
            this.calculateAndUpdateAverage();
            this.getScreenData();
        })
        .catch(error => {
        });
    }

    handleAdditionalMultiplier(event){
        this.additionalMultiplier=event.target.value;
          upsertAdditionalMultiplier({
            'loanId' : this.loanId,
            'applicantId' : this.applicantId,
            'additonalMultiplier' : this.additionalMultiplier,
            'recId' : this.rentalRecId
        })
        .then((response) => {
            if(response != 'Success'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: response,
                        variant: 'error',
                    }),
                );
            }
        })
        .catch(error => {
        });
    }
    //874

}