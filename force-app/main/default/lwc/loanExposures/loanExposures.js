import { LightningElement, wire, api, track } from 'lwc';

//import getBankingDetails from '@salesforce/apex/LoanExposureController.getBankingDetails';



export default class LoanExposures extends LightningElement {

    @api recordId;
    @api existingLoans;



    // @wire(getBankingDetails, { opportunityId: '$recordId' })

    // wiredData({ data, error }) {

    //     if (data) {

    //         this.loanExposures = data.loanExposures;

    //     } else if (error) {

    //         console.error(error);

    //     }

    // }
    connectedCallback() {
      
        console.log('✅ existingLoans:', this.existingLoans);
    }

}