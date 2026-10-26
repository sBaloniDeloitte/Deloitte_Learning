import { LightningElement, api } from 'lwc';
import getCustId from '@salesforce/apex/COMM_SalesLoanLoginController.getCustId';

export default class SalesLoanParent360Cmp extends LightningElement {
    @api recordId;
    @api custId;
    @api showInPopup;
    showChildCmp = false;

    connectedCallback() {
        console.log('this.custId-->',this.custId + this.showInPopup);
        if (!this.custId) {
            this.showInPopup = false;
            this.getCustId();
        }
    }

    getCustId() {
        console.log('result--- 15', this.recordId)
        this.showChildCmp = false;
        getCustId({ customerId: this.recordId })
            .then(result => {
                console.log('result--- 19', result)
                this.custId = result;
                this.showChildCmp = true;
            })
            .catch(error => {
                console.log(error);
            })
    }
    modalClose() {
        this.dispatchEvent(new CustomEvent('handleclose', {}));
    }
}