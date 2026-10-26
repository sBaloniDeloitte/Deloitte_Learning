import { LightningElement, api, track } from 'lwc';
import fetchParentLoanDetail from '@salesforce/apex/AHL_LoanApplicationActionController.fetchParentLoanDetail';

export default class AhlShowSplitParentLoanDetail extends LightningElement {
    @api recordId; 
    @track showMessage = false;
    ChildLoanId;
    ChildLoanName;

    connectedCallback(){
        this.fetchParentLoanDetail();
    }
    
    fetchParentLoanDetail(){
                fetchParentLoanDetail({childLoanId : this.recordId})
                .then(result => {
                   this.showMessage = true;
                   this.ChildLoanName = result.ChildLoanName;
                   this.ChildLoanId = result.ChildLoanId;
                })
                .catch(error => {
                    console.error('Error in fetchParentLoanDetail:', error);
                });
        }
}