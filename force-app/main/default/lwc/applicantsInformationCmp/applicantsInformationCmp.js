import { LightningElement, api, wire } from 'lwc';
import getLoanTransactionDetails from '@salesforce/apex/AHL_LoanDetailsController.getLoanTransactionDetails'

export default class ApplicantsInformationCmp extends LightningElement {
    @api recordId;
    quickDisb;
    qdpStatus = '';
    stage = ''
    isEditable = true;

    @wire(getLoanTransactionDetails, {
        loanId: "$recordId",
    })
    getLoanTxnDetails({
        data,
        error
    }){
        if (data) {
            console.log('getLoanTxnDetails   ', data)
            this.qdpStatus = data.QDP_Status__c ?? 'N/A';   
            this.quickDisb = data.Quick_Disbursement__c ?? false;
            this.stage = data.Loan_Application__r.StageName ?? 'N/A';
            console.log('this.qdpStatus is '+this.qdpStatus+'  and this.quickDisb is '+this.quickDisb)
            const isQDP = this.quickDisb === true && this.qdpStatus === 'QDP-ONHOLD' && this.stage === 'PSV';
            if (isQDP) {
                this.isEditable = false;
            } 
        } else if(error) {
            console.log('error is '+error)
        }
    }
}