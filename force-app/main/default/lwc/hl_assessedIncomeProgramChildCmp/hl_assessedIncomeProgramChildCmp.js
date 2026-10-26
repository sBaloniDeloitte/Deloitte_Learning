import { LightningElement, api, track } from 'lwc';
import getIncomeAssessmentData from '@salesforce/apex/HL_AssessedIncomeProgramController.getLIPIncomeAssessment';
import { updateRecord } from 'lightning/uiRecordApi';

export default class Hl_assessedIncomeProgramChildCmp extends LightningElement {
    @api loanId;
    @api applicantId;
    @track data = [];
    @track isPrevious;
    @track spinnerRun = false;
    //874
    additionalFoir;
    recordIdIncome;
    //874

    fieldLabels = [
        'LIP PD assessed Net Profit',
        'Average Bank Balance',
        'Is Previous Year Financial Available?',
        'Latest Year PBT',
        'Previous Year PBT',
        'Latest Year Turnover',
        'Turnover as per GST Returns of last 12 months',
        'Primary Income for LIP',
        'Depreciation',
        'Interest on Capital/Loans',
        'Rent paid to borrowers',
        'Other Income (To be capped at 100% PAT)',
        'Total Income'
    ];

    isDarkThemeInjected = false;

    connectedCallback() {
        this.loadData(true);
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

    booleanOptions = [
        { label: 'True', value: true },
        { label: 'False', value: false }
    ];


    loadData(isStart) {
        if(isStart){
            this.spinnerRun = true;
        }
        console.log('yas 3 '+ this.loanId ); console.log('yas 4 '+ this.applicantId );
        getIncomeAssessmentData({ loanId: this.loanId, apDetId: this.applicantId })
            .then(result => {
                const recId = result?.recordId || null;
                this.recordIdIncome=result?.recordId || null;
                this.additionalFoir=result?.additionalFoir||null;
                console.log('record id '+ JSON.stringify(result))
                
                this.data = this.fieldLabels.map(label => {
                    const key = this.mapLabelToWrapperKey(label);
                    const isBoolean = label === 'Is Previous Year Financial Available?'; // ✅ define it here
                    return {
                        label,
                        recordId: recId,
                        value: result ? (result[key] ?? (isBoolean ? false : '')) : (isBoolean ? false : ''),
                        isBoolean: isBoolean,
                        disabled: ['Primary Income for LIP', 'Total Income'].includes(label)
                    };
                });
                this.data.forEach(row => {
                    if (row.isBoolean) {
                        this.isPrevious = row.value; // ✅ store current boolean value
                    }
                });
                console.log('test '+ JSON.stringify(this.data));
            })
            .catch(error => {
                console.error('Error y data', JSON.stringify(error));
                this.data = this.fieldLabels.map(label => ({
                    label,
                    recordId: null,
                    value: label === 'Is Previous Year Financial Available?' ? false : '',
                    isBoolean: label === 'Is Previous Year Financial Available?',
                    disabled: ['Primary Income for LIP', 'Total Income'].includes(label)
                }));
            })
            .finally(() => {
                if(isStart){
                    this.spinnerRun = false;
                }
            });
    }

    mapLabelToWrapperKey(label) {
        const map = {
            'LIP PD assessed Net Profit': 'LIP_PD_assessed_Net_Profit',
            'Average Bank Balance': 'Average_Bank_Balance',
            'Is Previous Year Financial Available?': 'Is_Previous_Year_Financial_Available',
            'Latest Year PBT': 'Latest_Year_PBT',
            'Previous Year PBT': 'Previous_Year_PBT',
            'Latest Year Turnover': 'Latest_Year_Turnover',
            'Turnover as per GST Returns of last 12 months': 'Turnover_as_per_GST_Returns_of_last_12_m',
            'Primary Income for LIP': 'Primary_Income_for_LIP',
            'Depreciation': 'Depreciation',
            'Interest on Capital/Loans': 'Interest_on_Capital_Loans',
            'Rent paid to borrowers': 'Rent_paid_to_borrowers',
            'Other Income (To be capped at 100% PAT)': 'Other_Income_To_be_capped_at_100_PAT',
            'Total Income': 'Total_Income'
        };
        return map[label];
    }

    handleInputChange(event) {
        console.log('handleInputChange');
        const recId = event.target.dataset.id;
        const fieldLabel = event.target.dataset.label;
        let fieldValue = event.target.value;
        console.log('yy ' +event.target.type);

        // Handle checkbox boolean value
        if (fieldLabel == 'Is Previous Year Financial Available?') {
            fieldValue = (event.target.value === 'true');
            this.isPrevious = fieldValue;
        }

        const fieldMapping = {
            'LIP PD assessed Net Profit': 'LIP_PD_assessed_Net_Profit__c',
            'Average Bank Balance': 'Average_Bank_Balance__c',
            'Is Previous Year Financial Available?': 'Is_Previous_Year_Financial_Available__c',
            'Latest Year PBT': 'Latest_Year_PBT__c',
            'Previous Year PBT': 'Previous_Year_PBT__c',
            'Latest Year Turnover': 'Latest_Year_Turnover__c',
            'Turnover as per GST Returns of last 12 months': 'Turnover_as_per_GST_Returns_of_last_12_m__c',
            'Primary Income for LIP': 'Primary_Income_for_LIP__c',
            'Depreciation': 'Depreciation__c',
            'Interest on Capital/Loans': 'Interest_on_Capital_Loans__c',
            'Rent paid to borrowers': 'Rent_paid_to_borrowers__c',
            'Other Income (To be capped at 100% PAT)': 'Other_Income_To_be_capped_at_100_PAT__c',
            'Total Income': 'Total_Income__c'
        };

        const fieldAPI = fieldMapping[fieldLabel];
        if (!fieldAPI || !recId) return;

        // Skip disabled fields
        if (['Primary Income for LIP', 'Total Income'].includes(fieldLabel)) {
            return;
        }

        const fields = { Id: recId };
        fields[fieldAPI] = fieldValue;

        updateRecord({ fields })
            .then(() => {
                this.loadData();
            })
            .catch(error => {
                console.error('Update error:', error);
            });
    }
     handleSustainableValueChange(event){
        const fields = {};
        console.log('this.parentRecId'+this.recordIdIncome);
        fields['Id'] = this.recordIdIncome;
        console.log('event.target.name=:'+event.target.name);
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
}