import { api, LightningElement, track } from 'lwc';

export default class SalesLoanLoginChecklistCmp extends LightningElement {
    @api recordId;

    @track screenName= 'Login Checklist';

    connectedCallback(){
        console.log('loan id in loginchecklist----', this.recordId);
        
        
    }
}