import { LightningElement ,api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class LeadEditOverride extends NavigationMixin(LightningElement) {
    @api recordId;

     connectedCallback() {
        this.showErrorToast();
           setTimeout(() => {
            this.navigateToListView();
        }, 1500);
    }

    showErrorToast() {
        const evt = new ShowToastEvent({
            title: 'Error',
            message: 'You cannot perform this action from here.Kindly contact your System Administrator',
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
    navigateToListView() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Lead', 
                actionName: 'list'
            }
        });
    }
}