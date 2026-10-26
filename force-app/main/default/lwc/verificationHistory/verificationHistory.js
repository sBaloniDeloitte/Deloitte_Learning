import { LightningElement, api, wire, track } from 'lwc';
import getVerificationHistory from '@salesforce/apex/Credit_FIVerificationController.getVerificationHistory';
import getProductName  from '@salesforce/apex/Credit_FIVerificationController.getProductName';
const columns = [
    { label: 'Application Verification Name', fieldName: 'ParentName' },
    { label: 'Field', fieldName: 'Field' },
    { label: 'Old Value', fieldName: 'OldValue' },
    { label: 'New Value', fieldName: 'NewValue' }
];

export default class VerificationHistory extends LightningElement {
    @api recordId; 
    @track data;
    @track columns = columns;
    @track error;
    productCheck;

    @wire(getVerificationHistory, { loanAppId: '$recordId' , objectApiName:'Application_Verification__c' })
    wiredVerificationHistory({ error, data }) {
        if (data) {
            this.data = data;
            this.error = undefined;
            this.verificationNumber = data.length > 0 ? data[0].VerificationNumber : null;
            console.log('line 23-->>',JSON.stringify(this.data));
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }

    connectedCallback() {
        this.fetchProductName();
    }

    fetchProductName(){
        getProductName({recordId: this.recordId})
        .then(result=>{
           this.prodName = result;
           if(this.prodName == 'Home Loan'){
              this.productCheck = true;
           }
           else {
               this.productCheck = false;
           }
        })
        .catch((error) =>{
              console.error('Error fetching product name '+ error);
        });
    }
}