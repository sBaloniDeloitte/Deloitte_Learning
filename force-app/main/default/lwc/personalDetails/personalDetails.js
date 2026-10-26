import { LightningElement, api, wire } from 'lwc';
import getApplicants from '@salesforce/apex/ApplicantController.getApplicants';

export default class personalDetails extends LightningElement {
    @api recordId; // Opportunity Id
    applicants;
    error = false;
    @api hideIdStatusColumns = false;

    @wire(getApplicants, { loanApplicantionId: '$recordId' })
    wiredApplicants({ error, data }) {
        if (data) {
            const mapped = (data || []).map(a => ({
                ...a,
                businessTypeDisplay:
                    a.Business_Type__c && String(a.Business_Type__c).trim().length
                        ? a.Business_Type__c
                        : '-'
            }));
            this.applicants = mapped;
            this.error = mapped.length === 0;
        } else if (error) {
            this.error = true;
            this.applicants = undefined;
        }
    }
}