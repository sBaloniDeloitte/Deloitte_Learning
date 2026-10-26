import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getTargetIdIfCU from '@salesforce/apex/AHL_AssignToCmController.getTargetIdIfCU';

export default class RedirectToTargetLoanApplication extends NavigationMixin(LightningElement) {
  @api recordId;
  @api objectApiName;

  connectedCallback() {
    if (!this.recordId || !this.objectApiName) return;

    getTargetIdIfCU({ objectApiName: this.objectApiName, recordId: this.recordId })
      .then(targetId => {
        if (targetId) {
          
          this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: targetId, actionName: 'view' }
          
          });
          
          //window.open('/lightning/r/Opportunity/'+targetId+'/view','_self');
        }
        // If null:user stays on Process page
      })
      .catch(() => {/* no-op */});

  }
}