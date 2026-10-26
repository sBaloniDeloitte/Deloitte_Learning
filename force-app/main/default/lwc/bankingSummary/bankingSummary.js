import { LightningElement, wire, api, track } from 'lwc';

//import getBankingDetails from '@salesforce/apex/LoanExposureController.getBankingDetails';



export default class BankingSummary extends LightningElement {
    @api bankingData;
    @api recordId;
    @api totalExposure; 
    @api totalExposureGhfHfc;
    @api totalExposureGflNbfc;
    @api totalExposureGc;

    @track wipLoan = 0;
    @track disburstLoan = 0;
    @api exposureGhfWipLoan;
    @api exposureGhfDisburstLoan;
    @api exposureGfl;
    @api totalWipLoanSalesforce;
    @api totalDisbursedLoanSalesforce;



    // @wire(getBankingDetails, { opportunityId: '$recordId' })

    // wiredData({ data, error }) {

    //     if (data) {

    //         this.bankingData = data;

    //     } else if (error) {

    //         console.error(error);

    //     }

    // }
    connectedCallback() {
        
        console.log('✅ totalExposure:', this.totalExposure);
        console.log('✅ totalExposureGhfHfc:', this.totalExposureGhfHfc);
        console.log('✅ totalExposureGflNbfc:', this.totalExposureGflNbfc);
        console.log('✅ totalExposureGc:', this.totalExposureGc);
        console.log('✅ exposureGfl:', this.exposureGfl);
        console.log('✅ totalWipLoanSalesforce:', this.totalWipLoanSalesforce);
        console.log('✅ totalDisbursedLoanSalesforce:', this.totalDisbursedLoanSalesforce);
        console.log('✅ exposureGhfWipLoan:', this.exposureGhfWipLoan);
        console.log('✅ exposureGhfDisburstLoan:', this.exposureGhfDisburstLoan);
       
    }

}