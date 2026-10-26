import { LightningElement,api,track ,wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import existingLoans from '@salesforce/apex/COMM_SalesLoanActionsController.existingLoans';
import getCustomerDetails from '@salesforce/apex/COMM_GetCustomerController.getCustomerDetails';
import getExistingLoanDetails from '@salesforce/apex/GetExistingLoanDetailsController.getExistingLoanDetails';

export default class SalesExisitingLoanDetails extends LightningElement {
    @api showExistingLoans;
    @api recordId;
    @api processObject;                 //to get the object/process name
    @track existingLoans = [];
    customerDemographicResp
    totalResp;

    connectedCallback(){
        this.getExistingLoans();
    }

    getExistingLoans(){
        existingLoans({ recordId : this.recordId, processObject : this.processObject })
        .then(response=>{
            this.existingLoans = response;
            console.log('response=existingLoans '+JSON.stringify(this.existingLoans));
            if(this.existingLoans.length === 0){
                this.showExistingLoans = false;
            } else {
                this.showExistingLoans = true;
                console.log('this.existingLoans[0].custLMS :--> ' +this.existingLoans[0].custLMS);
                this.selectedId = this.existingLoans[0].custLMS;
                this.getExistingLoanCustomerDetails();
            }
            
            // this.getDuplicateCustomerList();
        })
        .catch(error=>{
            // this.ShowLoader = false;
            console.error('error existingLoans--> '+JSON.stringify(error));
        })
    }

    getExistingLoanCustomerDetails() {
        console.log('this.selectedId-', this.selectedId);

        getCustomerDetails({
            customerId: this.selectedId,
            processName: 'Get Customer'
        }).then(response => {
            var responseData = JSON.parse(response);
            console.log('response getExistingLoanCustomerDetails=:', JSON.stringify(responseData));
            
            if (responseData.customerFinanceDetailList.length > 0) {
                this.showDuplicate = false;
                this.customerDemographicResp = responseData.customerFinanceDetailList;
                this.totalResp = responseData;
                console.log('this.customerDemographicResp --> ' + JSON.stringify(this.customerDemographicResp));
    
                this.existingLoans = this.existingLoans.map(existingLoan => {
                    let matchingLoan = this.customerDemographicResp.find(loan => loan.finReference === existingLoan.loanNo);
    
                    return matchingLoan
                        ? { 
                            ...existingLoan, 
                            loanNo: matchingLoan.finReference,
                            product: matchingLoan.finType,
                            loanAmount: matchingLoan.finAmount
                        }
                        : existingLoan;
                });
    
                this.customerDemographicResp.forEach(newLoan => {
                    if (!this.existingLoans.some(existing => existing.loanNo === newLoan.finReference)) {
                        this.existingLoans.push({
                            loanNo: newLoan.finReference,
                            product: newLoan.finType,
                            loanAmount: newLoan.finAmount
                        });
                    }
                });
    
                console.log('Final merged this.existingLoans --> ', JSON.stringify(this.existingLoans));
                // this.getExistingLoanDet();
                this.existingLoans.forEach(loan => {
                    if (!loan.loanNo.startsWith('LA-')) {
                        console.log(`Calling getExistingLoanDet() for loanNo: ${loan.loanNo}`);
                        this.getExistingLoanDet(loan.loanNo);
                    }
                });
    
            } else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'There are no existing loans for the selected customer.',
                        variant: 'Error',
                    }),
                );
            }
        }).catch(error => {
            this.ShowLoader = false;
            console.log('error -->' + JSON.stringify(error));
        });
    }
    getExistingLoanDet(loanId) {
        getExistingLoanDetails({ loanId: loanId })
        .then(response => {
            console.log(`response getExistingLoanDet for loanId ${loanId}:`, JSON.stringify(response));
            if (response.customersExtLiability) {
                let matchingLoan = response.customersExtLiability.find(loan => loan.liabilitySeq && loan.finType);
                
                if (matchingLoan) {
                    this.existingLoans = this.existingLoans.map(loan =>
                        loan.loanNo === loanId ? { ...loan, status: matchingLoan.finStatus } : loan
                    );
                }
            } else {
                console.log('response.customersExtLiability not found :');
            }

            console.log('Updated existingLoans with status:', JSON.stringify(this.existingLoans));
        })
        .catch(error => {
            console.error(`error getExistingLoanDetails for loanId ${loanId}: `, JSON.stringify(error));
        });
    }
}