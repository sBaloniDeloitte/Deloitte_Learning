import { LightningElement,api } from 'lwc';

export default class DisbursementMemo extends LightningElement {
        @api recordId;
        pageUrl = '';
    
        connectedCallback() {
            console.log('recordId: '+this.recordId);
            this.pageUrl = `/apex/DisbursmentMemo?id=`+this.recordId;
        }
    }