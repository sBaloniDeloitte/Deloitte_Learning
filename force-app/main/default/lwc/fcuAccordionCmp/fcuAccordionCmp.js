/*_______________This Code was generated using GenAI tool : Codify, Please check for accuracy_______________*/
import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOverallStatus from '@salesforce/apex/FCUAccordionController.getOverallStatus';
import getFCUVerifications from '@salesforce/apex/FCUAccordionController.getFCUVerifications';

/**
 * @description Dark-themed replacement for the standard "Overall Status" field
 *              section + "Application Verifications" related list that used to sit
 *              inside the FCU accordion section, so its background matches the
 *              Field Investigation accordion (creditFIInitiationCmp dark theme).
 */
export default class FcuAccordionCmp extends LightningElement {
    @api recordId;

    overallStatusResult;
    verificationsResult;
    verifications = [];

    @wire(getOverallStatus, { recordId: '$recordId' })
    wiredOverallStatus(result) {
        this.overallStatusResult = result;
    }

    @wire(getFCUVerifications, { recordId: '$recordId' })
    wiredVerifications(result) {
        this.verificationsResult = result;
        if (result.data) {
            this.verifications = result.data.map((rec) => ({
                Id: rec.Id,
                name: rec.Name,
                applicantName: rec.Applicant__r ? rec.Applicant__r.Name : '',
                stage: rec.Stage__c
            }));
        } else if (result.error) {
            this.verifications = [];
        }
    }

    get hasVerifications() {
        return this.verifications && this.verifications.length > 0;
    }

    handleFieldsSaveSuccess() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Overall Status updated successfully.',
                variant: 'success'
            })
        );
        refreshApex(this.overallStatusResult);
    }

    handleFieldsSaveError(event) {
        const message = event?.detail?.detail || event?.detail?.message || 'Unable to save Overall Status.';
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message,
                variant: 'error'
            })
        );
    }
}
/*__________________________GenAI: Generated code ends here______________________________*/