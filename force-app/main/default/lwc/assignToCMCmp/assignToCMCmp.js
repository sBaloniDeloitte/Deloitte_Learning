import { LightningElement, api,wire, track } from 'lwc';
import validateFIStages from '@salesforce/apex/AHL_AssignToCmController.validateFIStages';
import assignOpportunityToCM from '@salesforce/apex/AHL_AssignToCmController.assignOpportunityToCM';
import assignOpportunityToCM_Ahl from '@salesforce/apex/AHL_AssignToCmController.assignOpportunityToCM_Ahl';
import validateAssignToCM from '@salesforce/apex/AHL_AssignToCmController.validateAssignToCM';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange, updateRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import getLoanSubStage from '@salesforce/apex/Utility.getLoanSubStage';
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails'

export default class AssignToCMCmp extends LightningElement {
    @api recordId;
    isLoading = false;
    isHLRelated = false;
    isHLUser = false;
    showValidation = false;
    //validationMessage = 'All the Field Investigation record should be initiated or Waived.';
    @track validationMessages = [];
    subStage;
    isModalOpen = false;
    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
        if (currentPageReference) {
            console.log(currentPageReference);
            this.recordId = currentPageReference.attributes.recordId;

            this.recordId = currentPageReference.state.recordId || this.recordId;
            console.log('Record Id from URL:' + this.recordId);
        }
    }
    connectedCallback(){
        getLoanSubStage({loanId : this.recordId}).then(result => {
            this.subStage = result;
            console.log('this.subStage>>>>>'+this.subStage);
            this.checkisHLUser();
            }).catch(error => {
            console.error('Error getting subStage:: '+ JSON.stringify(error));
        })

       
    }
      stageMovement(){
        if(this.subStage == 'Credit Processing Verification'){
                console.log('38>>>>');
                    const fields = {
                        Id: this.recordId,
                        Sub_stage__c: 'Credit in-progress',
                };
                const recordInput = { fields };
                    updateRecord(recordInput).then(() => {
                        this.showToast(
                            'Success',
                            'Loan Application assigned to Credit Manager.',
                            'success'
                        );
                        this.closeModal();
                    }).catch(error => {
                        console.error('Error updating record:: '+ JSON.stringify(error));
                        this.showToast('Error', error.body.message, 'error');
                    })
            }
    }
      checkisHLUser() {
        var inputMapParam = {
            'oppId': this.recordId
        };            
        getProductDetails({inputMap : inputMapParam})
        .then(result => {
            this.isHLUser = result.isHLRelated;
            console.log('isHLUser-->',this.isHLUser);
            // If user is HL, call validation for APF Collateral
            //if (this.isHLUser) {
                //  this.stageMovement();
            //}else{
                this.isModalOpen = true;
            //}
        })
        .catch(error => {
            console.log('error-->',error);
        })
    }
    async handleAssign() {
        const oppId = this.recordId;
        if (!oppId) {
            this.showToast('Error', 'No Opportunity Id found in the component', 'error');
            return;
        }
        if (this.isLoading) return;
        this.isLoading = true;
        let methodName = this.isHLUser ? assignOpportunityToCM : assignOpportunityToCM_Ahl;
        this.validationMessages = [];

        const blanks = await validateFIStages({opportunityId: this.recordId});

        if (Array.isArray(blanks) && blanks.length > 0) {
            this.validationMessages.push( 'All the Field Investigation record should be initiated or Waived.');
        }
        const ftrValidation = await validateAssignToCM({opportunityId: this.recordId });
        if (ftrValidation) {
            this.validationMessages.push(ftrValidation);
        }
        if (this.validationMessages.length > 0) {
            this.showValidation = true;
            this.isLoading = false;
            return;
        }

        methodName({ opportunityId: oppId })
            .then(() => {
                getRecordNotifyChange([{ recordId: this.recordId }]);
                try {
                    eval("$A.get('e.force:refreshView').fire();");
                } catch (e) {
                }
                this.showToast(
                    'Success',
                    'Loan Application assigned to Credit Manager.',
                    'success'
                );
                this.closeModal();
            })
            .catch(error => {
                console.error('Apex assignOpportunityToCM error:', JSON.stringify(error));
                let message = 'Unknown error';
                if (error.body) {
                    if (error.body.pageErrors && error.body.pageErrors.length) {
                        message = error.body.pageErrors[0].message;
                    } else if (error.body.message) {
                        message = error.body.message;
                    }
                } else if (error.message) {
                    message = error.message;
                }

                this.showToast('Error', message, 'error');
                this.closeModal();
            })
            .finally(() => {
                this.isLoading = false;
                this.closeModal();
            });
    }
    closeValidationModal() {
    this.showValidation = false;
    this.validationMessages = [];
    getRecordNotifyChange([{ recordId: this.recordId }]);
    try {
      eval("$A.get('e.force:refreshView').fire();");
    } catch (e) {
    }
    this.dispatchEvent(new CloseActionScreenEvent());
    // CloseActionScreenEvent only has an effect inside a real Quick Action panel.
    // Also dispatch a plain bubbling 'close' event so components embedding this one
    // directly (outside a Quick Action context) have a way to know to unmount it.
    this.dispatchEvent(new CustomEvent('close', { bubbles: true, composed: true }));
  }

    handleCancel() {
        this.closeModal();
    }
    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(new CustomEvent('close', { bubbles: true, composed: true }));
    }

    showToast(title, msg, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message: msg, variant })
        );
    }
}