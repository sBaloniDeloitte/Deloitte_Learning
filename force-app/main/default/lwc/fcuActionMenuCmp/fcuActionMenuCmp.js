import { api,LightningElement,track,wire} from 'lwc';
import { updateRecord } from "lightning/uiRecordApi";
import { CurrentPageReference } from 'lightning/navigation';
import {unregisterAllListeners,fireEvent } from 'c/pubsub';
import checkIfReportButtonVisible from '@salesforce/apex/FCUController.checkIfReportButtonVisible';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class fcuActionMenuCmp extends LightningElement {
    @api recordId;
    @track isMobile = false;
    @track disableReport = false;

    connectedCallback(){
        if(FORM_FACTOR == 'Large') {
            this.isMobile = false;
        } else {
            this.isMobile = true;
        }

        checkIfReportButtonVisible({recordId : this.recordId})
        .then(response=>{
            console.log('Recordid--',this.recordId);
            console.log(`checkVerificationStatusDisability : ${JSON.stringify(response)}`);
            this.disableReport = response;
        }).catch(error=>{
            console.error('The Error is '+JSON.stringify(error))
        });
    }

    generateReport(){
        window.open(`/apex/FCUReport?id=${this.recordId}&pdfReport=pdf`, '_blank');
    }
    generateForm(){
        window.open(`/apex/FCULoanApplicationForm?id=${this.recordId}&pdfReport=pdf`, '_blank');
    }
    
    
}