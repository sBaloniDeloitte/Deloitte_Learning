import { LightningElement,api,track,wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import QUICK_SANCTION_RESPONSE from '@salesforce/schema/Opportunity.Quick_Sanction_Response__c';
export default class Hl_QuickSanctionIndicator extends LightningElement {
    @api recordId;
    quickRespSanction;
    @wire(getRecord, { recordId: '$recordId', fields: [QUICK_SANCTION_RESPONSE] })
    wiredOpportunity({ error, data }) {
        if (data) {
            this.quickRespSanction = getFieldValue(data, QUICK_SANCTION_RESPONSE);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.quickRespSanction = undefined;
        }
    }
}