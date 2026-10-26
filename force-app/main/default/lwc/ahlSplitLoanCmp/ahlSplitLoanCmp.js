import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveSplitLoans from '@salesforce/apex/AHL_LoanApplicationActionController.saveSplitLoans';
import fetchChildLoanDetails from '@salesforce/apex/AHL_LoanApplicationActionController.fetchChildLoanDetails';

export default class AhlSplitLoanCmp extends LightningElement {
    @api recordId; 
    @track isLoading = false;
    @track displayButton = true;
    isValidations=false;
    isSplitSuccess = false;
    ChildLoanId;
    ChildLoanName;
    @track resultWrapper = [];
    @track validationMessages=[];

    handleButtonValidation(){
            this.isLoading = true;  
            saveSplitLoans({parentLoanId : this.recordId})
            .then(result => {
                this.isLoading = false; 
                if (result.length > 0) {
                    this.validationMessages = result;
                    this.isValidations = true;
                }
                else{
                    this.showToastMessage('Success', 'Loan splitted successfully!', 'Success');
                    this.isSplitSuccess = true;
                    this.getChildLoanDetails();

                    //location.reload();
                    
                }
            })
            .catch(error => {
                this.isLoading = false; 
                console.error('Error in saveSplitLoans:', error);
            });
    }

    getChildLoanDetails(){
            fetchChildLoanDetails({parentLoanId : this.recordId})
            .then(result => {
                this.resultWrapper = result;
            //    this.ChildLoanName = result.ChildLoanName;
            //    this.ChildLoanId = result.ChildLoanId;
            })
            .catch(error => {
                this.isLoading = false; 
                console.error('Error in getChildLoanDetails:', error);
            });
    }

    closeModal(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleCloseValidation(){
        this.isValidations=false;
        this.closeModal();
    }

    handleCloseSplitSuccess(){
        this.isSplitSuccess=false;
        this.closeModal();
    }

    showToastMessage(title, message, variant){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            })
        );
    }
}