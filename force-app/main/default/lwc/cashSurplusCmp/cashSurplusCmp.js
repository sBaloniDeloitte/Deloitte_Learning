import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import getApprovalDetails from '@salesforce/apex/Hl_LoanApprovalController.getApprovalDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import recalcPY1 from '@salesforce/apex/AHL_ApplicantListController.recalcPY1';

//import setDocument from '@salesforce/apex/GenericInitiateController.setDocument';
//import deleteContent from '@salesforce/apex/GenericInitiateController.deleteContent';
//import uploadFile from '@salesforce/apex/FieldInvestigationController.uploadFile';

import ID_FIELD from '@salesforce/schema/Opportunity.Id';
import NOY_FIELD from '@salesforce/schema/Opportunity.No_of_years__c';
import CAGR_FIELD from '@salesforce/schema/Opportunity.CAGR_in_percentage__c';
import PY1_FIELD from '@salesforce/schema/Opportunity.Amount_of_Cash_Surplus_for_PY1_Rs__c';
import PY2_FIELD from '@salesforce/schema/Opportunity.Amount_of_Cash_Surplus_for_PY2_Rs__c';
import PY3_FIELD from '@salesforce/schema/Opportunity.Amount_of_Cash_Surplus_for_PY3_Rs__c';
import PY4_FIELD from '@salesforce/schema/Opportunity.Amount_of_Cash_Surplus_for_PY4_Rs__c';
import PY5_FIELD from '@salesforce/schema/Opportunity.Amount_of_Cash_Surplus_for_PY5_Rs__c';
import TOTAL_FIELD from '@salesforce/schema/Opportunity.Total_Amount_of_Cash_Surplus_Rs__c';
import PERS_EXP_FIELD from '@salesforce/schema/Opportunity.Personal_Expenses_in_percentage__c';
import SURPLUS_FIELD from '@salesforce/schema/Opportunity.Cash_Surplus_Rs__c';

const PERCENT_FIELDS = new Set([
    'CAGR_in_percentage__c',
    'Personal_Expenses_in_percentage__c'
]);

export default class CashSurplusCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    @api disabledCmp = false;

    @track isRendered = false;
    _wiredOpp;

    @track form = {
        CAGR_in_percentage__c: null,
        Amount_of_Cash_Surplus_for_PY1_Rs__c: null,
        Amount_of_Cash_Surplus_for_PY2_Rs__c: null,
        Amount_of_Cash_Surplus_for_PY3_Rs__c: null,
        Amount_of_Cash_Surplus_for_PY4_Rs__c: null,
        Amount_of_Cash_Surplus_for_PY5_Rs__c: null,
        Total_Amount_of_Cash_Surplus_Rs__c: null,
        Personal_Expenses_in_percentage__c: null,
        Cash_Surplus_Rs__c: null,
        No_of_years__c: null
    };

    get surplusYearOptions() {
        return [
            { label: '1', value: '1' },
            { label: '2', value: '2' },
            { label: '3', value: '3' },
            { label: '4', value: '4' },
            { label: '5', value: '5' }
        ];
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [CAGR_FIELD, PY1_FIELD, PY2_FIELD, PY3_FIELD, PY4_FIELD, PY5_FIELD, TOTAL_FIELD, PERS_EXP_FIELD, SURPLUS_FIELD, NOY_FIELD]
    })
    wiredRecord(result) {
        this._wiredOpp = result;
        const { data, error } = result;
        if (data) {
            this.form = {
                CAGR_in_percentage__c: getFieldValue(data, CAGR_FIELD),
                Amount_of_Cash_Surplus_for_PY1_Rs__c: getFieldValue(data, PY1_FIELD),
                Amount_of_Cash_Surplus_for_PY2_Rs__c: getFieldValue(data, PY2_FIELD),
                Amount_of_Cash_Surplus_for_PY3_Rs__c: getFieldValue(data, PY3_FIELD),
                Amount_of_Cash_Surplus_for_PY4_Rs__c: getFieldValue(data, PY4_FIELD),
                Amount_of_Cash_Surplus_for_PY5_Rs__c: getFieldValue(data, PY5_FIELD),
                Total_Amount_of_Cash_Surplus_Rs__c: getFieldValue(data, TOTAL_FIELD),
                Personal_Expenses_in_percentage__c: getFieldValue(data, PERS_EXP_FIELD),
                Cash_Surplus_Rs__c: getFieldValue(data, SURPLUS_FIELD),
                No_of_years__c: getFieldValue(data, NOY_FIELD)
            };
        }
    }

    connectedCallback() {
        // compute PY1 once when component loads
        this.refreshPY1();
    }

    async refreshPY1() {
        try {
            const sum = await recalcPY1({ opportunityId: this.recordId });
            const py1 = this.round(sum);
            this.form = { ...this.form, Amount_of_Cash_Surplus_for_PY1_Rs__c: py1 };
            const personal = Number(this.form.Personal_Expenses_in_percentage__c) || 0;
            const cash = this.computeCashSurplus(total, personal);

            const years = parseInt(this.form.No_of_years__c, 10) || 0;
            if (years > 0) {
                const cagrDec = Number(this.form.CAGR_in_percentage__c) || 0;
                const { py2, py3, py4, py5, total } = this.computeSeries(py1, years, cagrDec);
                const formPatch = {
                    Amount_of_Cash_Surplus_for_PY2_Rs__c: py2,
                    Amount_of_Cash_Surplus_for_PY3_Rs__c: py3,
                    Amount_of_Cash_Surplus_for_PY4_Rs__c: py4,
                    Amount_of_Cash_Surplus_for_PY5_Rs__c: py5,
                    Total_Amount_of_Cash_Surplus_Rs__c: total,
                    Cash_Surplus_Rs__c: cash
                };
                this.form = { ...this.form, ...formPatch };

                const fields = {
                    [ID_FIELD.fieldApiName]: this.recordId,
                    [PY2_FIELD.fieldApiName]: py2,
                    [PY3_FIELD.fieldApiName]: py3,
                    [PY4_FIELD.fieldApiName]: py4,
                    [PY5_FIELD.fieldApiName]: py5,
                    [TOTAL_FIELD.fieldApiName]: total,
                    [SURPLUS_FIELD.fieldApiName]: cash
                };
                await this.saveFieldsAndRefresh(fields);
            } else {
                if (this._wiredOpp) await refreshApex(this._wiredOpp);
            }
        } catch {

        }
    }


    async saveFieldsAndRefresh(fields, formPatch = null) {
        try {
            await updateRecord({ fields });
            if (formPatch) this.form = { ...this.form, ...formPatch };
            if (this._wiredOpp) await refreshApex(this._wiredOpp);
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error updating',
                message: e?.body?.message || 'Update failed',
                variant: 'error'
            }));
        }
    }

    round(n) { return (n == null || isNaN(n)) ? 0 : Math.round(Number(n)); }

    computeSeries(py1, years, cagrDec) {
        // cagrDec is decimal (e.g., 0.5 for 50%)
        const growth = 1 + (Number(cagrDec) || 0);
        const safeGrowth = (growth > 0) ? growth : 1;

        let py2 = 0, py3 = 0, py4 = 0, py5 = 0;
        if (years >= 2) py2 = this.round(py1 / safeGrowth);
        if (years >= 3) py3 = this.round(py2 / safeGrowth);
        if (years >= 4) py4 = this.round(py3 / safeGrowth);
        if (years >= 5) py5 = this.round(py4 / safeGrowth);

        const total =
            (years >= 1 ? py1 : 0) +
            (years >= 2 ? py2 : 0) +
            (years >= 3 ? py3 : 0) +
            (years >= 4 ? py4 : 0) +
            (years >= 5 ? py5 : 0);

        return { py2, py3, py4, py5, total: this.round(total) };
    }

    computeCashSurplus(total, personalDec) {
        const t = this.round(total);
        const p = Number(personalDec) || 0;
        return this.round(t * (1 - p));
    }

    async handleBlur(event) {
        const fieldApi = event.target.dataset.field;
        if (!fieldApi) return;

        let raw = event.target.value;
        let val = (raw === '' || raw === null || raw === undefined) ? null : Number(raw);

        if (val !== null && PERCENT_FIELDS.has(fieldApi) && Math.abs(val) > 1) {
            val = val / 100;
        }

        const prev = this.form[fieldApi];
        const changed = (prev == null) ? (val != null) : (val == null || Math.abs(Number(prev) - val) > 1e-7);
        if (!changed) return;

        if (fieldApi === 'CAGR_in_percentage__c') {
            this.form = { ...this.form, CAGR_in_percentage__c: val };

            const newCagr = val || 0;
            const py1 = this.round(this.form.Amount_of_Cash_Surplus_for_PY1_Rs__c);
            const years = parseInt(this.form.No_of_years__c, 10) || 0;

            if (years <= 0) {
                // Only save CAGR; skip derived fields until years is chosen
                await this.saveFieldsAndRefresh({
                    [ID_FIELD.fieldApiName]: this.recordId,
                    [CAGR_FIELD.fieldApiName]: newCagr
                }, { CAGR_in_percentage__c: newCagr });
                return;
            }

            const { py2, py3, py4, py5, total } = this.computeSeries(py1, years, newCagr);
            const personal = Number(this.form.Personal_Expenses_in_percentage__c) || 0;
            const cash = this.computeCashSurplus(total, personal);

            const formPatch = {
                CAGR_in_percentage__c: newCagr,
                Amount_of_Cash_Surplus_for_PY2_Rs__c: py2,
                Amount_of_Cash_Surplus_for_PY3_Rs__c: py3,
                Amount_of_Cash_Surplus_for_PY4_Rs__c: py4,
                Amount_of_Cash_Surplus_for_PY5_Rs__c: py5,
                Total_Amount_of_Cash_Surplus_Rs__c: total,
                Cash_Surplus_Rs__c: cash
                
            };
            this.form = { ...this.form, ...formPatch };

            const fields = {
                [ID_FIELD.fieldApiName]: this.recordId,
                [CAGR_FIELD.fieldApiName]: newCagr,
                [PY2_FIELD.fieldApiName]: py2,
                [PY3_FIELD.fieldApiName]: py3,
                [PY4_FIELD.fieldApiName]: py4,
                [PY5_FIELD.fieldApiName]: py5,
                [TOTAL_FIELD.fieldApiName]: total,
                [SURPLUS_FIELD.fieldApiName]: cash
            };
            await this.saveFieldsAndRefresh(fields);
            return;
        }

        if (fieldApi === PERS_EXP_FIELD.fieldApiName) {
            const personal = val || 0;
            const total = this.round(this.form.Total_Amount_of_Cash_Surplus_Rs__c) || 0;
            const cash = this.computeCashSurplus(total, personal);

            const formPatch = {
                Personal_Expenses_in_percentage__c: personal,
                Cash_Surplus_Rs__c: cash
            };
            this.form = { ...this.form, ...formPatch };

            const fields = {
                [ID_FIELD.fieldApiName]: this.recordId,
                [PERS_EXP_FIELD.fieldApiName]: personal,
                [SURPLUS_FIELD.fieldApiName]: cash
            };
            await this.saveFieldsAndRefresh(fields);
            return;
        }

        try {
            await updateRecord({ fields: { [ID_FIELD.fieldApiName]: this.recordId, [fieldApi]: val } });
            this.form[fieldApi] = val;
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error updating',
                message: e?.body?.message || 'Update failed',
                variant: 'error'
            }));
        }
    }


    renderedCallback() {
        if (!this.isRendered) {
            // Create and append styles dynamically
            const style = document.createElement("style");
            style.innerText = `
            lightning-record-edit-form-edit .slds-form-element .slds-form-element__static{
                border: 1px solid;
                border-radius: 3px;
                padding: 6px 10px;
            }
        `;
            // Append the styles to the .styleContainer
            this.template.querySelector(".styleContainer")?.appendChild(style);
            // Prevent re-adding styles
            this.isRendered = true;
        }
    }
    async handlePicklistChange(event) {
        const fieldApi = event.target.dataset.field;
        const val = event.detail.value;
        if (this.form[fieldApi] === val) return;
        
        const years = parseInt(val, 10) || 0;
        const py1 = this.round(this.form.Amount_of_Cash_Surplus_for_PY1_Rs__c);
        const cagrDec = Number(this.form.CAGR_in_percentage__c) || 0;

        const { py2, py3, py4, py5, total } = this.computeSeries(py1, years, cagrDec);
        const personal = Number(this.form.Personal_Expenses_in_percentage__c) || 0;
        const cash = this.computeCashSurplus(total, personal);

        const formPatch = {
            [fieldApi]: val,
            Amount_of_Cash_Surplus_for_PY2_Rs__c: py2,
            Amount_of_Cash_Surplus_for_PY3_Rs__c: py3,
            Amount_of_Cash_Surplus_for_PY4_Rs__c: py4,
            Amount_of_Cash_Surplus_for_PY5_Rs__c: py5,
            Total_Amount_of_Cash_Surplus_Rs__c: total,
            Cash_Surplus_Rs__c: cash
        };
        this.form = { ...this.form, ...formPatch };

        const fields = {
            [ID_FIELD.fieldApiName]: this.recordId,
            [NOY_FIELD.fieldApiName]: val,
            [PY2_FIELD.fieldApiName]: py2,
            [PY3_FIELD.fieldApiName]: py3,
            [PY4_FIELD.fieldApiName]: py4,
            [PY5_FIELD.fieldApiName]: py5,
            [TOTAL_FIELD.fieldApiName]: total,
            [SURPLUS_FIELD.fieldApiName]: cash
        };
        await this.saveFieldsAndRefresh(fields);
    }


}