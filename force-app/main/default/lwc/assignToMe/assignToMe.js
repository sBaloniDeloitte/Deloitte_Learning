import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import assignToMe from '@salesforce/apex/FCUController.assignToMe';
import { FlowNavigationFinishEvent } from "lightning/flowSupport";

export default class AssignToMe extends LightningElement {
    @api idsFromFlow;
    reloadFlag = false;

    connectedCallback() {
        this.handleAssignToMe();
    }

    handleAssignToMe() {

        if (!this.idsFromFlow || this.idsFromFlow.length === 0) {
            this.showErrorToast('No Records selected.');
            return;
        }

        /*assignToMe({ loanids: this.idsFromFlow })
            .then(() => {
                console.log('are we in then?');
                this.showSuccessToast('Owner updated successfully!');
                this.handleFinish();
            })
            .catch((error) => {
                console.error("Error assigning owner: ", error);
                this.showErrorToast('Error assigning owner: ' + (error.body ? error.body.message : error.message));
            });*/
    }

    handleFinish() {
     const nextEvent = new FlowNavigationFinishEvent();
     this.dispatchEvent(nextEvent);
  }

    showSuccessToast(message) {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

    showErrorToast(message) {
        const evt = new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }
}