import { LightningElement, api, track,wire } from 'lwc';
import submitforResanction from '@salesforce/apex/COMM_PricingApprovalController.submitforResanction';
import getMetadataValue from '@salesforce/apex/COMM_PricingApprovalController.getMetadataValue';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class SubmitForResanction extends LightningElement {

    @api recordId;
    @api headerTitle = 'Confirm Resanction';
    @track modalVisibility = false;
    @track confirmationText = 'Are you sure you want to send back to Credit?'; // fallback default
    @track remarks = '';

    cssContainer = 'slds-modal__container width-70';

    // This is invoked from standard action button
    /*@api invoke() {
        this.modalVisibility = true;
    }*/
   @wire(CurrentPageReference)
       getPageReference(pageRef) {
           if (pageRef) {
               this.recordId = pageRef.state.recordId || this.recordId;
               console.log('Record Id from URL:', this.recordId);
           }
       }
   connectedCallback(){
    this.modalVisibility = true;
    getMetadataValue({ metadataName: 'Resanction_Confirmation_Text' })
        .then(result => {
            if (result) {
                this.confirmationText = result;
            }
        })
        .catch(error => {
            console.error('Error fetching metadata value:', error);
        });
   }

    handleRemarksChange(event) {
        this.remarks = event.target.value;
    }

    handleNegative() {
        this.modalVisibility = false;
        this.dispatchEvent(new CustomEvent('closemodal'));
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handlePositive() {
        if (!this.remarks || this.remarks.trim() === '') {
            this.showToast('Error', 'Remarks are required to proceed.', 'error');
            return;
        }

        this.modalVisibility = false;
        console.log('Confirmed: Submitting for Resanction for Id: ' + this.recordId);
        this.dispatchEvent(new CustomEvent('closemodal'));
        submitforResanction({ loanId: this.recordId, remarks: this.remarks})
            .then(result => {
                if (result === 'success') {
                    this.showToast('Success', 'Re-Sanction initiated successfully!', 'success');
                    //this.refreshPage();
                    // Redirect after 1 second
                    setTimeout(() => {
                        this.redirectToOpportunity();
                    }, 1000);
                } else {
                    this.showToast('Info', result, 'info');
                }
            })
            .catch(error => {
                this.showToast('Error', 'Something went wrong. Please contact your system administrator.', 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable'
            })
        );
    }

    refreshPage() {
        location.reload();
    }

    redirectToOpportunity() {
        const baseUrl = window.location.origin;
        const redirectUrl = `${baseUrl}/lightning/r/Opportunity/${this.recordId}/view`;
        window.location.href = redirectUrl;
    }

    renderedCallback(){
        const style = document.createElement('style');
            style.innerText = `.slds-modal__container .empty .closeIcon{
                                    display:none;
                                }`;
            this.template.querySelector('.slds-modal__container').appendChild(style);
    }
}