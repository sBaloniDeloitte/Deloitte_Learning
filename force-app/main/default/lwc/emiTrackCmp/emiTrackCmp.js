import { LightningElement, wire, track,api } from 'lwc';
//import getTransposedData from '@salesforce/apex/EmiTrackingCmpController.getTransposedData';
import getFilteredTransposedData from '@salesforce/apex/EmiTrackingCmpController.getFilteredTransposedData';
import getEligibleBankIds from '@salesforce/apex/EmiTrackingCmpController.getEligibleBankIds';
export default class TransposeAmount extends LightningElement {
    @track processedData = [];
    @track columns = [];
    @track accountOptions = [];
    @api recordId;
    @track selectedBank = '';
    spinner = false;
    @track showBankDetails = false;
    showFilter = false;
  /*  @wire(getTransposedData)
    wiredData({ error, data }) {
        if (data) {
            console.log('Raw Data from Apex:', JSON.stringify(data));
            this.processData(data);
        } else if (error) {
            console.error('Error fetching data:', error);
        }
    } */

    connectedCallback() {
        this.getEligibleBanks();
    }

    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;
            this.injectCustomStyles();
        }
    }

    /* ____GenAI: Generated code starts here - unscoped <style> injection for
       the open lightning-combobox dropdown listbox. The .slds-c-combobox-*
       CSS custom-property hooks and plain CSS-file selectors don't reliably
       reach the listbox on every base-component version (it can render
       outside the normal shadow-DOM styling path), so the working pattern
       from covenantsDetailForm_hl.js / salesLoginCollateralDetailCmp.js is
       reused here: inject the rules directly and append to .styleContainer.____ */
    injectCustomStyles() {
        const style = document.createElement('style');
        style.innerText = `
            .emi-dark-theme lightning-combobox .slds-combobox__input,
            .emi-dark-theme .slds-select {
                background-color: #16283f !important;
                border: 1px solid #33455e !important;
                color: #ffffff !important;
                height: 2.25rem !important;
            }
            .emi-dark-theme lightning-combobox .slds-dropdown,
            .emi-dark-theme lightning-combobox .slds-dropdown__list,
            .emi-dark-theme lightning-combobox .slds-listbox_vertical {
                background-color: #16283f !important;
                border: 1px solid #33455e !important;
            }
            .emi-dark-theme lightning-combobox .slds-listbox__option,
            .emi-dark-theme lightning-combobox .slds-listbox__item {
                background-color: #16283f !important;
                color: #ffffff !important;
            }
            .emi-dark-theme lightning-combobox .slds-listbox__option:hover,
            .emi-dark-theme lightning-combobox .slds-listbox__option:focus,
            .emi-dark-theme lightning-combobox .slds-listbox__option.slds-has-focus,
            .emi-dark-theme lightning-combobox .slds-listbox__option[aria-selected="true"] {
                background-color: #1589ee !important;
                color: #ffffff !important;
            }
        `;
        this.template.querySelector('.styleContainer')?.appendChild(style);
    }
    /* ____GenAI: Generated code ends here____ */

    getEligibleBanks() {
        this.spinner = true;
        getEligibleBankIds({ recordId: this.recordId })
            .then((response) => {
                if (response && response.length > 0) {
                    this.accountOptions = response.map(bank => ({ 
                        label: bank.Name, 
                        value: bank.Id,
                        customerName :bank.Account_Holder_Name__c,
                        accountNumber : bank.Account_Number__c
                     }));
                this.selectedBank = this.accountOptions[0].value; // Set the first bank's value
                this.selectedCustomerName = this.accountOptions[0].customerName; // Set the first bank's customer name
                this.selectedAccountNumber = this.accountOptions[0].accountNumber; // Set the first bank's account number
                this.selectedBankName = this.accountOptions[0].label; // Set the first bank's label
                this.showBankDetails = true; 
                this.getFilteredTransposedData(this.selectedBank);
                    console.log('accountOption==>',this.accountOptions);
                } else {
                    this.showBankDetails = false; 
                    //this.showToastMessage('Error', 'No eligible banks found', 'error');
                }
            })
            .catch((error) => {
                this.spinner = false;
                console.error('Error fetching bank details:', error);
                this.showToastMessage('Error', 'An error occurred while fetching banks.', 'error');
            })
            .finally(() => {
                this.spinner = false;
            });
    }

    processData(data) {
        let allColumns = new Set();
        let transformedData = [];
    
        // Extract all unique date columns and ensure 'Amount' is just before 'Category'
        data.forEach(row => {
            Object.keys(row).forEach(key => {
                if (key !== 'Amount' && key !== 'Category') {
                    allColumns.add(key);
                }
            });
        });
    
        // Convert Set to Array and sort the date columns
        this.columns = ['S.No.', 'Amount', 'Category', ...Array.from(allColumns).sort((a, b) => {
            // Convert month-year strings to Date objects for proper sorting
            const [monthA, yearA] = a.split('-');
            const [monthB, yearB] = b.split('-');
            const dateA = new Date(`${yearA}-${monthA}-01`); // Create a date object
            const dateB = new Date(`${yearB}-${monthB}-01`); // Create a date object
            return dateA - dateB; // Sort in ascending order
        })];
    
        console.log('Extracted Columns:', this.columns);
    
        // Transform data to fit LWC structure
        data.forEach((row, index) => {
            let newRow = {
                id: `row-${index}`,
                serialNumber: index + 1, // Add serial number
                amount: row.Amount,
                category: row.Category,
                values: []
            };
    
            // Map column values
            this.columns.forEach((col, colIndex) => {
                if (col === 'S.No.') {
                    newRow.values.push({
                        id: `cell-${index}-${colIndex}`,
                        value: newRow.serialNumber // Use the serial number for this column
                    });
                } else {
                    newRow.values.push({
                        id: `cell-${index}-${colIndex}`,
                        value: row[col] !== undefined ? row[col] : ''
                    });
                }
            });
    
            transformedData.push(newRow);
        });
    
        console.log('Processed Data:', JSON.stringify(transformedData));
        this.processedData = transformedData;
        if(this.processedData.length>0){
            this.showFilter=true;
        } else {
            this.showFilter=false;
        }
    }

    handleBankSelection(event) {
        this.selectedBank = event.detail.value;
        this.selectedBankName = event.detail.name;

    const selectedBankDetails = this.accountOptions.find(bank => bank.value === this.selectedBank);
    if (selectedBankDetails) {
        this.selectedCustomerName = selectedBankDetails.customerName;
        this.selectedAccountNumber = selectedBankDetails.accountNumber;
        this.selectedBankName = selectedBankDetails.label;
        console.log('Selected Bank Details:', selectedBankDetails);
    }
        if (this.selectedBank) {
            this.showBankDetails = true;
            this.getFilteredTransposedData(this.selectedBank);
        }
    }
    
    getFilteredTransposedData(selectedBank) {
        console.log('select bank record Id in ',this.selectedBank);
        this.spinner = true;
        getFilteredTransposedData({ bankRecordId: this.selectedBank })
            .then((response) => {
                if (response && response.length > 0) {
                    this.spinner =false;
                    console.log('Raw Data from Apex:', JSON.stringify(response));
                    this.processData(response);
                } else {
                    console.log('in else in getfiltered');
                    //this.showToastMessage('Error', 'No eligible banks found', 'error');
                }
            })
            .catch((error) => {
                this.spinner = false;
                console.error('Error fetching bank details:', error);
                this.showToastMessage('Error', 'An error occurred while fetching banks.', 'error');
            })
            .finally(() => {
                this.spinner = false;
            });
    }
}