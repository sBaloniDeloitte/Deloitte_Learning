import { api, LightningElement, track } from 'lwc';
import fetchQDEReasons from '@salesforce/apex/AHL_LoanApplicationActionController.fetchQDEReasons';

export default class Hl_qdeBannerCmp extends LightningElement {
    @api recordId;
    @track reasons= [];

    connectedCallback(){
        this.getQDEReasons();
    }

    getQDEReasons(){
        const inputMap ={
            'recordId':this.recordId
        }
        fetchQDEReasons({
            inputMap: inputMap
        })
        .then((result) => {
            console.log('result in fetchQDEReasons---', JSON.stringify(result));
            this.reasons = result;
            console.log('applicant Data in fetchQDEReasons---', JSON.stringify(this.reasons));
            console.log('applicant Data length in fetchQDEReasons---', this.reasons.length);
        }).catch(error=>{
            console.log('Error in fetchQDEReasons--'+JSON.stringify(error));
        })
    }
}