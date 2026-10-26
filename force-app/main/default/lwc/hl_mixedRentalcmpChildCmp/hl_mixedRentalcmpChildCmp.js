import { LightningElement, api, track } from 'lwc';
import getScreenData from '@salesforce/apex/HL_MixedRentalController.getScreenData';
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getEligibilityConsiderationPicklist from '@salesforce/apex/HL_CashProfitController.getEligibilityConsiderationPicklist';
import updateEligibilityConsideration from '@salesforce/apex/HL_MixedRentalController.updateEligibilityConsideration';
import addPropertyIncomeAssessment from '@salesforce/apex/HL_MixedRentalController.addPropertyIncomeAssessment';
import updateMonthNames from '@salesforce/apex/HL_MixedRentalController.updateMonthNames';
import calculateTotalAndAverage from '@salesforce/apex/HL_MixedRentalController.calculateTotalAndAverage';


export default class Hl_mixedRentalcmpChildCmp extends LightningElement {

    @api loanId;
    @api applicantId;
    @track screenDataResult;
    @track loadTable = false;
    @track parentRecId;
    @track isAvgCalculate = false;
    @track spinnerRun = false;
    @track startMonthName = '';
    @track eligibilityOption = '';
    @track eligibilityOptions = [];
    @track tableData = [];
    //874
    @track additionalFoir;
    //874
    @track isDarkThemeInjected = false;

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
            return this.screenDataResult.headerValues.length - 1;
        }
        return 1;
    }

    get processedParticularsData() {
        if (!this.screenDataResult || !this.screenDataResult.leaseData) return [];

        const monthMap = new Map();
        this.screenDataResult.leaseData.forEach((lease) => {
            if (lease.monthData && lease.monthData.length) {
                lease.monthData.forEach((m, i) => {
                    const label = m.monthName ? m.monthName.trim() : '';
                    if (label === null || label === undefined) return;
                    if (monthMap.has(label)) {
                        const existing = monthMap.get(label);
                        existing.childRecordIds.push(m.recordId);
                        monthMap.set(label, existing);
                    } else {
                        monthMap.set(label, {
                            label,
                            field: '',
                            isInput: true,
                            isDisabled: i !== 0,
                            childRecordIds: [m.recordId]
                        });
                    }
                });
            }
        });
        const monthRows = Array.from(monthMap.values());

        const particulars = [
            { label: 'LESSOR', field: 'lessor', nameapi: 'HL_Lessor__c' },
            { label: 'LESSEE', field: 'lessee', nameapi: 'HL_Lessee__c' },
            { label: 'PROPERTY ADDRESS', field: 'propertyAddress', nameapi: 'HL_Property_Address__c' },
            { label: 'AGREEMENT REGISTERED DATE', field: 'agreementRegisteredDate', nameapi: 'HL_Agreement_Registered_Date__c' },
            { label: 'LEASE COMMENCEMENT DATE', field: 'leaseCommencementDate', nameapi: 'HL_Lease_Commencement_Date__c' },
            { label: 'Tenure (in months)', field: 'tenureInMonths', nameapi: 'HL_Tenure_In_Months__c' },
            { label: 'LOCKING PERIOD (in months)', field: 'lockingPeriodInMonths', nameapi: 'HL_Locking_Period_In_Months__c' },
            { label: 'SECURITY DEPOSIT', field: 'securityDeposit', nameapi: 'HL_Security_Deposit__c' },
            { label: 'ESCALATION %', field: 'escalationPercent', nameapi: 'HL_Escalation__c' },
            { label: 'Gross Rent', field: 'grossRent', nameapi: 'HL_Gross_Rent__c' },
            { label: 'TDS', field: 'tds', nameapi: 'HL_TDS__c' },
            { label: 'GST', field: 'gst', nameapi: 'HL_GST__c' },
            { label: 'Net Rental', field: 'netRental', nameapi: 'HL_Net_Rental__c' },
            { label: 'Amount Without GST', field: 'amountWithoutGST', nameapi: 'HL_Net_Rental__c' },
            { label: 'Bank Details', field: 'bankDetails', nameapi: 'HL_Bank_Details__c' },
        ];

        const particularsTotals = [
            { label: 'Total', field: 'totalAmount', nameapi: '' },
            { label: 'Average', field: 'average', nameapi: '' },
            { label: 'Amount Considered For Eligibility', field: '', nameapi: '' }
        ];

        const allParticulars = [...particulars, ...monthRows, ...particularsTotals];
        console.log(' processedParticularsData allParticulars =:' + JSON.stringify(allParticulars));

        this.tableData = allParticulars.map((part) => {
            const row = { 
                label: part.label, 
                nameapi: part.nameapi, 
                recordId: '', 
                values: [], 
                isEligibility: part.label == 'Amount Considered For Eligibility',
                isDisabled: (part.label == 'Net Rental' || part.label == 'Amount Without GST' || part.label == 'Total' || part.label == 'Average'),
                isHeaderDisabled: part.isDisabled,
                isInput: part.isInput,
            }

            this.screenDataResult.leaseData.forEach((property, index) => {
                let cellValue = '';
                if (part.field && property[part.field] !== undefined) {
                    cellValue = property[part.field];
                } 
                else if (property.monthData && property.monthData.length > 0) {
                    const matchedMonth = property.monthData.find(
                        (m) => m.monthName === part.label
                    );
                    if (matchedMonth) {
                        cellValue = matchedMonth.monthValue;
                    }
                }
                const valueObj = {
                    val: cellValue || '',
                    recordId: property.recordId || '',
                    childId: Array.isArray(part.childRecordIds) ? part.childRecordIds[index] || '' : ''
                };

                row.values.push(valueObj);
                row.recordId = property.recordId;
            });

            return row;
        });
        console.log(' processedParticularsData Table Data =:' + JSON.stringify(this.tableData));

        return this.tableData;
    }

    getScreenData() {
        getScreenData({
            loanId: this.loanId,
            apDetId: this.applicantId
        }).then(response => {
            console.log('getScreenData response=:' + JSON.stringify(response));
            this.screenDataResult = response;
            this.loadTable = true;
            this.eligibilityOption = this.screenDataResult.eligibilityConsideration;
            let firstMonthName = "";
            if(response.additionalFoir){
                this.additionalFoir = response.additionalFoir;
            }
            if (this.screenDataResult && this.screenDataResult.leaseData &&
                 this.screenDataResult.leaseData.length > 0) {
                for (const lease of this.screenDataResult.leaseData) {
                    if (lease?.monthData?.length > 0) {
                        const foundMonth = lease.monthData.find(
                            m => m?.monthName && m.monthName.trim() !== ""
                        );
                        if (foundMonth) {
                            firstMonthName = foundMonth.monthName;
                            break; 
                        }
                    }
                }
                this.startMonthName = firstMonthName;
            }
            console.log('getScreenData : first entered month name' + firstMonthName + ' ::: ' + this.startMonthName);
        }).catch(error => {
            console.error('Error getScreenData =:' + JSON.stringify(error));
        })
    }

    handleEligibilityChange(event) {
        this.eligibilityOption = event.detail.value;
        console.log('Selected Eligibility Option:', this.eligibilityOption);
        updateEligibilityConsideration({
            loanId: this.loanId,
            apDetId: this.applicantId,
            eligibilityValue: this.eligibilityOption
        })
            .then((response) => {
                console.log('handleEligibilityChange response=:' + JSON.stringify(response));
            })
            .catch(error => {
                 console.error('Error handleEligibilityChange =:' + JSON.stringify(error));
            });
    }

    handleInputValueChange(event) {
        console.log('event.target.dataset.id=:' + event.target.dataset.id);
        console.log('event.target.value=:' + event.target.value);
        console.log('event.target.name=:' + event.target.name);
        console.log('event.target.Child=:' + event.target.dataset.child);
        this.parentRecId = event.target.dataset.id;
        const fields = {};
        if(event.target.dataset.child){
            fields['Id'] = event.target.dataset.child;
            fields['HL_Month_Value__c'] = event.target.value;
            this.isAvgCalculate = true;
        }else{
            fields['Id'] = event.target.dataset.id;
            fields[event.target.name] = event.target.value;
            this.isAvgCalculate = false;
        }
        const recordInput = { fields };
        updateRecord(recordInput)
            .then((response) => {
                console.log('updateRecord -->' + JSON.stringify(response));
                if(this.isAvgCalculate){
                    this.calculateTotalAndAverage();
                } else{
                    this.getScreenData();
                }
            })
            .catch(error => {
                let message = error.body.message;
                if (message && message.startsWith('Invalid date format:')) {
                    message = message + ' Correct format is YYYY-MM-DD';
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!',
                        message: message,
                        variant: 'error',
                        mode: 'dismissable'
                    })
                );
                console.error('Error updateRecord -->' + JSON.stringify(error));
            });
    }

    updateMonthNames(event) {
        console.log('updateMonthNames :::event.target.value=:' + event.target.value);
        this.updateMonthNamesBack(event.target.value);
    }

    updateMonthNamesBack(startMonth) {
        console.log('updateMonthNames Backend:::=:' + startMonth);
        updateMonthNames({
            loanId: this.loanId,
            apDetId: this.applicantId,
            startMonthYear: startMonth
        }).then(response => {
            console.log('updateMonthNames response=:' + JSON.stringify(response));
            this.getScreenData();
        }).catch(error => {
            this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!',
                        message: error.body.message,
                        variant: 'error',
                        mode: 'dismissable'
                    })
                );
            console.error('Error updateMonthNames =:' + JSON.stringify(error));
        })
    }

    calculateTotalAndAverage() {
        console.log('CalculateTotalAndAverage :::=:' + this.parentRecId);
        calculateTotalAndAverage({
            recordId: this.parentRecId
        }).then(response => {
            console.log('CalculateTotalAndAverage response=:' + JSON.stringify(response));
            this.getScreenData();
        }).catch(error => {
            console.error('Error CalculateTotalAndAverage =:' + JSON.stringify(error));
        })
    }

    addPropertyIncomeAssessment(event) {
        console.log('addPropertyIncomeAssessment new : ');
        addPropertyIncomeAssessment({
            loanId: this.loanId,
            apDetId: this.applicantId
        })
        .then(result => {
            console.log('addPropertyIncomeAssessment result : ', JSON.stringify(result));
            this.getScreenData();
            setTimeout(() => {
                console.log('addPropertyIncomeAssessment : first entered month name::: ' + this.startMonthName);
                this.updateMonthNamesBack(this.startMonthName);
            }, 1000);
        })
    }

     handleSustainableValueChange(event){
        const fields = {};
        console.log('this.parentRecId'+this.screenDataResult.recordId);
        fields['Id'] = this.screenDataResult.recordId;
        console.log('event.target.name=:'+event.target.name);
        console.log('event.target.value=:'+event.target.checked);
        if(event.target.name=='additionalFOIR'){
            this.additionalFoir =event.target.value;
            fields['HL_Additional_FOIR__c'] =  this.additionalFoir;
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