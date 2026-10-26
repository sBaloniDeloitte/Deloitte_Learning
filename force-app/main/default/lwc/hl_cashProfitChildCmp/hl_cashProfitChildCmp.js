import { LightningElement, api, track } from 'lwc';
import getScreenData from '@salesforce/apex/HL_CashProfitController.getScreenData';
import getEligibilityConsiderationPicklist from '@salesforce/apex/HL_CashProfitController.getEligibilityConsiderationPicklist';
import updateEligibilityConsideration from '@salesforce/apex/HL_CashProfitController.updateEligibilityConsideration';
import updateYearName from '@salesforce/apex/HL_CashProfitController.updateYearName';
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import calculateGrowth from '@salesforce/apex/HL_CashProfitController.calculateGrowth';
export default class HL_CashProfitChildCmp extends LightningElement {
    @track eligibilityOption = '';
    @track eligibilityOptions = [];
    @api loanId;
    @api applicantId;
    @track screenDataResult;
    @track loadTable = false;
    @track parentRecId;
    isAddYearsEnabled = false;
    yearVal;
    spinnerRun = false;
    childRecId;
    @track yearCount;
    @track averageValue=0;
    remarks ='';
    //874
    turnOverGrowth;
    grossProfit;
    cashProfit;
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

     // Dynamically calculate colspan for eligibility row (total columns minus label column)
    get eligibilityColspan() {
    if (this.screenDataResult && this.screenDataResult.headerValues) {
        // Subtract 1 for the label column
        return this.screenDataResult.headerValues.length - 1;
    }
    return 1;
   }

    get processedParticularsData() {
        if (!this.screenDataResult || !this.screenDataResult.particularsData) return [];
        // this.screenDataResult.particularsData = this.screenDataResult.particularsData.map(particular => {
        //     const newYearData = [...particular.yearData];
        //     const elementToMove = newYearData.splice(3, 1)[0];
        //     console.log('Element removed processedParticularsData:' + JSON.stringify(elementToMove));
        //     if (elementToMove !== undefined) {
        //         newYearData.splice(2, 0, elementToMove);
        //     }
        //     return {
        //         ...particular,
        //         yearData: newYearData
        //     };
        // });
        // console.log('response=processedParticularsData : After:::'+JSON.stringify(this.screenDataResult.particularsData));

        // const averageEntry = this.screenDataResult.particularsData.find(
        //     row => row.particularName === 'Average'
        // );
        // this.averageValue = averageEntry?.yearData?.[0]?.averageValue || 0;
        // this.yearCount = averageEntry?.yearData?.length || 0;

        return this.screenDataResult.particularsData.map(row => ({
            ...row,
            isEligibility: row.particularName === 'Eligibility Consideration',
            isAverage: row.particularName === 'Average'
        }));
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
            console.error('Error updating eligibility consideration:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to update eligibility consideration.',
                    variant: 'error',
                }),
            );
        });
    }
    
    getScreenData(){
        getScreenData({
            loanId: this.loanId,
            apDetId: this.applicantId
        }).then(response=>{
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
            if(response.additionalFoir){
                this.additionalFoir = response.additionalFoir;
            }
            this.loadTable = true;
            this.remarks = response.remarks;
            // Set eligibilityOption from the backend field if available
            if (response && response.particularsData && response.particularsData.length > 0) {
                // Find the parent record's eligibility value if available
                if (response.eligibilityConsideration) {
                    this.eligibilityOption = response.eligibilityConsideration;
                }
            }
            const baseYearText = this.screenDataResult.headerValues[1]?.headerValue;
            const baseYear = parseInt(baseYearText, 10);
            if (!isNaN(baseYear)) {
                this.screenDataResult.headerValues.forEach(header => {
                    if (header.headerValue === 'Current Growth%') {
                        header.headerValue = `%Growth ${baseYear} - ${baseYear - 1}`;
                    } 
                    // else if (header.headerValue === 'Previous Growth%') {
                    // header.headerValue = `%Growth ${baseYear - 1} - ${baseYear - 2}`;
                    // }
                });
            } else {
                console.warn('baseYear is not a valid number:', baseYearText);
            }

            // let elementToMove = this.screenDataResult.headerValues.splice(3, 1)[0];
            // console.log('Element removed:' + JSON.stringify(elementToMove));
            // this.screenDataResult.headerValues.splice(2, 0, elementToMove);
            // this.screenDataResult.headerValues = [...this.screenDataResult.headerValues];
            // console.log('response=headerValues : Final:::'+JSON.stringify(this.screenDataResult.headerValues));
        }).catch(error=>{
            console.error('Error fetching screen data:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to load screen data.',
                    variant: 'error',
                }),
            );
        })
    }
    addyears(event){
        this.isAddYearsEnabled = true;
    }
    resetYears(event){
        this.yearVal = null;
        this.isAddYearsEnabled = false;
    }
    inputChanged(event){
        if(isNaN(Number(event.target.value )) || event.target.value ==''){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter year in correct format.',
                    variant: 'error',
                }),
            );
        }
        else{
            this.yearVal = event.target.value;
        }
    }
    handleSaveYearData(){
        if(this.yearVal == null || this.yearVal == undefined){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter current year.',
                    variant: 'error',
                }),
            );
        }
        else{
            this.spinnerRun = true;
            updateYearName({
                loanId: this.loanId,
                apDetId: this.applicantId,
                yearVal: this.yearVal
            }).then(response=>{
                this.spinnerRun = false;
                this.yearVal = null;
                this.isAddYearsEnabled = false;
                this.getScreenData();
            }).catch(error=>{
                this.spinnerRun = false;
            })
        }
    }

    handleInputValueChange(event){
        this.childRecId = event.target.dataset.id;
        this.parentRecId = event.target.dataset.parent;
        const fields = {};
        fields['Id'] = event.target.dataset.id;
        fields['Yearly_Amount__c'] = event.target.value;
        fields['Average_Amount__c'] = event.target.value;
        const recordInput = { fields };
        updateRecord(recordInput)
        .then((response) => {
            this.calculateGrowth();
        })
        .catch(error => {
        });
    }

    handleRemarksChange(event){
        this.remarks = event.target.value;

        const fields = {};
        fields['Id'] = this.screenDataResult.recordId;
        fields['Remarks__c'] = event.target.value;
        const recordInput = { fields };
        updateRecord(recordInput)
        .then((response) => {
        })
        .catch(error => {
        });
    }

    calculateGrowth(){
        calculateGrowth({
            recId: this.parentRecId,
            loanId: this.loanId,
            apDetId: this.applicantId
        }).then(response=>{
            this.getScreenData();
        }).catch(error=>{
            console.error('Error calculating growth:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to calculate growth.',
                    variant: 'error',
                }),
            );
        })
    }
    //874
    handleSustainableValueChange(event){
        const fields = {};
        fields['Id'] = this.screenDataResult.recordId;
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
            this.calculateGrowth();
        })
        .catch(error => {
        });
    }
    //874
}