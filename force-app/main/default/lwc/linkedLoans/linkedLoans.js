import { LightningElement, wire, api, track } from 'lwc';

//import getBankingDetails from '@salesforce/apex/LoanExposureController.getBankingDetails';



export default class LinkedLoans extends LightningElement {

    @api recordId;
    @api linkedLoansCombined;



    // @wire(getBankingDetails, { opportunityId: '$recordId' })

    // wiredData({ data, error }) {

    //     if (data) {

    //         this.linkedLoans = data.linkedLoans;

    //     } else if (error) {

    //         console.error(error);

    //     }

    // }

    connectedCallback() {
        console.log('✅ Linked Loans Data:', JSON.stringify(this.linkedLoansCombined, null, 2));
    }

}