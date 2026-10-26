import { LightningElement, api, track } from 'lwc';
import getFinanceDetails from '@salesforce/apex/SalesLoanEntireViewController.getFinanceDetails';
import getLoanDetailsFromCustId from '@salesforce/apex/SalesLoanEntireViewController.getLoanDetailsFromCustId';
import getExistingLoanDetails from '@salesforce/apex/GetExistingLoanDetailsController.getExistingLoanDetails';

export default class SalesLoan360 extends LightningElement {
    @api customerId;
    @api recordId
    @track financeResponse;
    loanNumbers = [];
    isloading = false;
    errorForData;
    isDataExist = false;
    activeLabel = 'Finance Details';

    connectedCallback() {
        console.log('customerId-----', this.customerId);
        this.getLoanDetailsFromCustId();

    }
    getFinanceDetails() {
        console.log('cifId----', this.customerId);
        getFinanceDetails({
            cifId: this.customerId
        }).then(resp => {
            this.isloading = false;
            console.log('resp----', resp.length);
            if (resp.length > 0) {
                console.log('resp----', JSON.stringify(resp));
                this.financeResponse = resp;
                this.isDataExist = true;
            } else {
                this.isDataExist = false;
                this.errorForData = 'Loan details were not found for this customer.';
            }
        }).catch(error => {
            this.isloading = false;
            this.errorForData = 'API is Down.'
        })
    }
    getLoanDetailsFromCustId() {
        this.isloading = true;
        getLoanDetailsFromCustId({
            custId: this.customerId
        }).then(resp => {

            this.loanNumbers = resp
            console.log('loannumnnnnn---', JSON.stringify(this.loanNumbers))
            if (this.loanNumbers != undefined && this.loanNumbers.length > 0) {
                for (let i = 0; i < this.loanNumbers.length; i++) {
                    getExistingLoanDetails({
                        loanId: this.loanNumbers[i]
                    })
                        .then(resp => {
                            console.log('print------', i);
                            console.log('this.loanNumbers.length-1------', this.loanNumbers.length - 1);
                            if (i == this.loanNumbers.length - 1) {
                                console.log('this.loanNumbers.length-1------', this.loanNumbers.length - 1);
                                this.getFinanceDetails();
                                return;
                            }
                        })
                        .catch(error => {
                            this.isloading = false;
                        })
                }
            }
            else {
                this.isloading = false;
                this.isDataExist = false;
                this.errorForData = 'Loan details were not found for this customer.';
            }
        })
            .catch(error => {
                this.isloading = false;
            })
    }
    handleSubTabClick(event) {
        this.activeLabel = event.target.dataset.id;
        if (event.target.dataset.id == 'Finance Details') {
            this.getFinanceDetails();
        }
    }
}