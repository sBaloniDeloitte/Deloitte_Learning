/*
 * @description : Static "Disposition" card - lets a sales agent set the
 *                 lead follow-up status (UI-only save, no Apex/DB write).
 *                 Themed to match the dark/purple leadManagementV2 (LMV2)
 *                 design used by leadPriorityCmp / leadScoreCmp.
 * @author       : ChangeMeIn@UserSettingsUnder.SFDoc
 */
import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const NONE_VALUE = '--None--';

export default class LeadDispositionCmp extends LightningElement {
    selectedDisposition = NONE_VALUE;
    _labelStyleInjected = false;

    renderedCallback() {
        if (!this._labelStyleInjected) {
            // The "Disposition" label renders inside lightning-combobox's
            // own internals, which scoped component CSS (and the
            // --slds-c-combobox-label-color token, tried previously)
            // cannot reach/override in this org. Injecting a real global
            // <style> tag is the only way to recolor it. Only the label
            // text color changes - no options, values, or click handlers
            // are touched.
            const style = document.createElement('style');
            style.innerText = `
                .ld-combobox .slds-form-element__label {
                    color: #ffffff !important;
                }
            `;
            this.template.querySelector('.ld-container')?.appendChild(style);
            this._labelStyleInjected = true;
        }
    }

    /* ____GenAI: option list matches the reference screenshot's dropdown,
       with one additional "Converted" option appended per explicit
       request____ */
    dispositionOptions = [
        { label: '--None--', value: NONE_VALUE },
        { label: 'Follow-up Required', value: 'Follow-up Required' },
        { label: 'Application in Progress', value: 'Application in Progress' },
        { label: 'Documents Pending', value: 'Documents Pending' },
        { label: 'Not Interested', value: 'Not Interested' },
        { label: 'Not Eligible', value: 'Not Eligible' },
        { label: 'Wrong Number', value: 'Wrong Number' },
        { label: 'Not Reachable', value: 'Not Reachable' },
        { label: 'Converted', value: 'Converted' }
    ];

    handleDispositionChange(event) {
        this.selectedDisposition = event.detail.value;
    }

    handleSave() {
        // UI-only save - shows the success toast per the reference screenshot,
        // selected value stays reflected in the combobox (no Apex/DB write)
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Disposition updated successfully.',
                variant: 'success'
            })
        );
        this.dispatchEvent(new CustomEvent('dispositionsaved', { detail: { disposition: this.selectedDisposition } }));
    }
}