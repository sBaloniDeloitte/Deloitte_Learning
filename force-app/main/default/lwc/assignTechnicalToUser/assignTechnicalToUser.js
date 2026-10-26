import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateTechnicalTeamMember from '@salesforce/apex/COMM_TechnicalRecordPageController.updateTechnicalTeamMember';

export default class AssignTechnicalToUser extends LightningElement {
    @api recordId;

    @api invoke(){
        console.log('inside invoke');
        updateTechnicalTeamMember({recordId: this.recordId})
        .then(result => {
            console.log('resultt---', result);
            
            if(result== 'success'){
                this.showToast('Success', 'Technical assigned to you successfully.', 'success');
            }else{
                this.showToast('Error', result, 'error');
            }
            
            this.closeQuickAction();
        })
        .catch(error => {
            this.showToast('Error', 'Failed to assign technical records.', 'error');
            console.log('Error updating record:', error);
        });
        
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    closeQuickAction() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}