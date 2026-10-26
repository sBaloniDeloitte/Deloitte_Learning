import {
    LightningElement,
    api,
    track
} from 'lwc';
import {
    NavigationMixin
} from "lightning/navigation";
import {
    deleteRecord,
    updateRecord
} from 'lightning/uiRecordApi';
import getApprovalDetails from '@salesforce/apex/AHL_IncomeSanctionController.getApprovalDetails';
import submitLoanForApproval from '@salesforce/apex/AHL_IncomeSanctionController.submitLoanForApproval';
import performApprovalAction from '@salesforce/apex/AHL_IncomeSanctionController.performApprovalAction';
import creditStageValidations from '@salesforce/apex/AHL_IncomeSanctionController.incomeSanctionValidations';
import getApprovalStatus from '@salesforce/apex/CreditRejectLoanApplicationController.getApprovalStatus';
import recallApprovalAction from '@salesforce/apex/AHL_IncomeSanctionController.recallApprovalAction';
import performRecommendAction from '@salesforce/apex/AHL_IncomeSanctionController.performRecommendAction';
import getSCMAndCM from '@salesforce/apex/Hl_LoanApprovalController.getSCMAndCM';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';

//import setDocument from '@salesforce/apex/GenericInitiateController.setDocument';
//import deleteContent from '@salesforce/apex/GenericInitiateController.deleteContent';
//import uploadFile from '@salesforce/apex/FieldInvestigationController.uploadFile';

export default class Ahl_incomeApprovalCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    @api isOneView = false;
    @track isDisabled = false;
    @track showInputText = false;
    @track spinner = true;
    @track approvalData = {};
    @track errorModal = false;
    @track errorLst = [];
    @track showRejectModal = false;
    @track options = [];
    
    @track value = '';

    toastvariant = {
        SUCCESS: 'success',
        ERROR: 'error'
    }
    toastTitle = {
        SUCCESS: 'Success',
        ERROR: 'Error'
    }
  

    toastMessages = {
        Pricing_Approval: 'Pricing Approval has been Submitted successfully.',
        Loan_Recommended: 'Loan application has been recommended successfully.',
        Loan_Approved: 'Loan application has been approved successfully.',
        Loan_Rejected: 'Loan application has been rejected successfully.',
        SOMETHING_WENT_WRONG: 'Something went wrong.',
        SelectUser: 'Please select assignee user.',
        Loan_SentBack: 'Loan application has been sent back successfully.',
        Loan_ExceptionApproval: 'Loan exceptions have been submitted for approval successfully.',
        Loan_Exception_Approved: 'Loan exceptions has been approved successfully.',
        Loan_Exception_Rejected: 'Loan exceptions has been rejected successfully.',
    }

    connectedCallback() {
        this.getLoanApprovalDetails();
        this.getApplicantPickList();
    }

     handleChangeApprover(event) {
        this.value = event.detail.value;
    }

    getApplicantPickList() {
    getSCMAndCM({
      recordId: this.recordId,
    })
      .then((response) => {
        console.log("SCMCH" + JSON.stringify(response));
        //this.options = [... this.options,{label:'All',value:'All'}];
        for (let key in response) {
          console.log("customer details=:" + response[key]);
          this.options = [
            ...this.options,
            {
              label: response[key],
              value: key,
            },
          ];
        }
      })
      .catch((error) => {});
  }

    getLoanApprovalDetails() {
        getApprovalDetails({
                recordId: this.recordId
            })
            .then((result) => {
                if (result) {
                    console.log('result in getLoanApprovalDetails::::', result);
                    this.approvalData = result;
                    //this.comment = result.remarks;
                    if(this.approvalData.nextApprover != '') {
                        this.value = this.approvalData.nextApprover;
                    }

                    this.spinner = false;
                    //this.comment = this.approvalData.draftComment;
                    console.log('this.approvalData---', JSON.stringify(this.approvalData));
                } else {
                    console.log('errror--- in getLoanApprovalDetails', error);
                }
            })
            .catch((error) => {
                this.handletoastEvent(error.body.message, this.toastTitle.ERROR, this.toastvariant.ERROR);
                this.spinner = false;
                console.log('errror--- in getLoanApprovalDetails', error);
            });

    }
    stopPropogation(event) {
        event.stopPropagation();
    }
    handleCommentChange(event) {
        console.log('comment in handle change----', event.target.value);
        const value = event.target.value;
        const invalidPattern = /(%%-|&&-)/;
        if (invalidPattern.test(value)) {
            event.target.value = '';
            this.handletoastEvent('Invalid characters %%- and &&-.', this.toastTitle.ERROR, this.toastvariant.ERROR);
            return;
        } else {
            this.comment = event.target.value;
            console.log('this.comment---', this.comment);
        }

        event.stopPropagation();
    }

    handleAction(event) {

        var action = event.target.dataset.name;
        console.log('event.target---', event.target.dataset.name);

        //harcode for testing
        // this.approvalType = 'pricing Approval';
        event.stopPropagation();
        if (this.comment == '' || this.comment == null) {
            this.handletoastEvent('Please enter approval notes.', this.toastTitle.ERROR, this.toastvariant.ERROR);
            return;
        }

         if(action === 'Recommended' || (action === 'submitted For Approval' && this.approvalData.checkForOptionSelected) ) {
            if (this.value == '' || this.value == null) {
                this.handletoastEvent('Please enter approver.', this.toastTitle.ERROR, this.toastvariant.ERROR);
                return;
            }
        }
        if (action == 'submitted For Approval') {
            this.spinner = true;

            console.log('this.comments>>' + this.comment);
            //
            creditStageValidations({
                    recordId: this.recordId
                })
                .then((result) => {
                    if (result.length > 0) {
                        this.errorModal = true;
                            this.errorLst = result;
                            return Promise.resolve(null);
                        
                    } else {
                        submitLoanForApproval({
                    loanId: this.recordId,
                    comment: this.comment,
                    approver : this.value
                })
                .then((result) => {
                    if (result) {
                        console.log('result in submitLoanForApproval::::', result);
                        if (result.includes('No ')) {
                            this.approvalData = {
                                ...this.approvalData,
                                currentStatus: result
                            };

                            this.handletoastEvent(result, this.toastTitle.ERROR, this.toastvariant.ERROR);
                            location.reload();
                        } else {
                            this.getLoanApprovalDetails();
                            this.handletoastEvent('Application submitted successfully!.', this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
                        }
                    } else {
                        console.log('errror--- in submitLoanForApproval');
                    }
                })
                .catch((error) => {

                    this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                });
                    }
                })
                .catch((error) => {

                    this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                })
                .finally(() => {
                    this.spinner = false;
                });

            //
            


        } else if (action == 'Approv') {
            this.spinner = true;
            performApprovalAction({
                    loanId: this.recordId,
                    action: action,
                    comment: this.comment
                })
                .then((result) => {
                    if (result) {
                        console.log('result in performApprovalAction::::', result);
                        if (result[0] == 'success') {
                            this.getLoanApprovalDetails();
                            if (action == 'Approv') {
                                console.log('at 216--');
                                console.log('this.approvalType----at 218--', this.approvalType);


                                this.handletoastEvent(this.toastMessages.Loan_Approved, this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
location.reload();
                            } else {

                                this.handletoastEvent(this.toastMessages.Loan_Rejected, this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
location.reload();
                            }
                        } else if (result[0] == 'fail') {
                            this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                        } else {
                            this.errorModal = true;
                            this.errorLst = result;
                        }

                    } else {
                        console.log('errror--- in performApprovalAction');
                    }
                })
                .catch((error) => {
                    console.log('errror--- in performApprovalAction', error);
                    this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                })
                .finally(() => {
                this.spinner = false;
                });
        }
        else if (action === 'Reject') {
            this.showRejectModal = true;
            return;
        }
         else if (action === 'saveDraft') {
            this.spinner = true;
            const fields = {};
            fields['Id'] = this.recordId;

            fields['Draft_PD_Note__c'] = this.comment;
            const recordInput = {
                fields
            };
            console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
            updateRecord(recordInput)
                .then(() => {
                    this.handletoastEvent('The draft PD notes are saved successfully.', this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
                })
                .catch(error => {
                    console.log('Error updating record --> ' + JSON.stringify(error));
                })
                .finally(() => {
                this.spinner = false;
                });
        }
        else if(action === 'Recall') {
            
            this.spinner = true;
            recallApprovalAction({
                    loanId: this.recordId,
                    action: action,
                    comment: this.comment
                })
                .then((result) => {
                    if (result) {
                        console.log('result in performApprovalAction::::', result);
                        if (result[0] == 'success') {
                            this.getLoanApprovalDetails();
                            this.handletoastEvent('Approval is recalled!.', this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
                            location.reload();
                            
                        } else if (result[0] == 'fail') {
                            this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                        } else {
                            this.errorModal = true;
                            this.errorLst = result;
                        }

                    } else {
                        console.log('errror--- in performApprovalAction');
                    }
                })
                .catch((error) => {
                    console.log('errror--- in performApprovalAction', error);
                    this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                })
                .finally(() => {
                this.spinner = false;
                });
        }

        else if(action === 'Recommended') {
            
            this.spinner = true;
            performRecommendAction({
                    loanId: this.recordId,
                    action: action,
                    comment: this.comment,
                    approverRole: this.value
                })
                .then((result) => {
                    if (result) {
                        console.log('result in performApprovalAction::::', result);
                        if (result[0] == 'success') {
                            this.getLoanApprovalDetails();
                            this.handletoastEvent('Recommended to '+this.value+' successfully!.', this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
                            location.reload();
                            
                        } else if (result[0] == 'fail') {
                            this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                        } else {
                            this.errorModal = true;
                            this.errorLst = result;
                        }

                    } else {
                        console.log('errror--- in performApprovalAction');
                    }
                })
                .catch((error) => {
                    console.log('errror--- in performApprovalAction', error);
                    this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                })
                .finally(() => {
                this.spinner = false;
                });
        }
        else if(action === 'Send Back') {
            this.spinner = true;
            recallApprovalAction({
                    loanId: this.recordId,
                    action: action,
                    comment: this.comment
                })
                .then((result) => {
                    if (result) {
                        console.log('result in performApprovalAction::::', result);
                        if (result[0] == 'success') {
                            this.getLoanApprovalDetails();
                            this.handletoastEvent('Approval is sent back!.', this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
                            location.reload();
                            
                        } else if (result[0] == 'fail') {
                            this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                        } else {
                            this.errorModal = true;
                            this.errorLst = result;
                        }

                    } else {
                        console.log('errror--- in performApprovalAction');
                    }
                })
                .catch((error) => {
                    console.log('errror--- in performApprovalAction', error);
                    this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                })
                .finally(() => {
                this.spinner = false;
                });
        }
    }
    handletoastEvent(msg, title, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
        }));
    }
    hideModalBox() {
        this.errorModal = false;
    }
    handleRejectClose() {
        this.showRejectModal = false;
    }
    handleRejectSuccess(evt) {
  this.showRejectModal = false;

  const statusFromModal = evt?.detail?.status; 
  const reasons = (evt?.detail?.reasons || []).join('; ');
  const composedComment =
    this.comment
      ? `${this.comment} | Reasons: ${reasons}`
      : `Rejected via modal | Reasons: ${reasons}`;

  this.spinner = true;
  performApprovalAction({
    loanId: this.recordId,
    action: 'Reject',
    comment: composedComment
  })
  .then(async (result) => {
    if (result && result[0] === 'success') {
      //  Read back status to confirm Apex didn't overwrite it
      const latestStatus = await getApprovalStatus({ loanId: this.recordId });
      this.getLoanApprovalDetails();
      this.handletoastEvent(
        `Loan application has been ${latestStatus || statusFromModal || 'Rejected'}`,
        this.toastTitle.SUCCESS,
        this.toastvariant.SUCCESS
      );
      // keep your current behavior
      location.reload();
    } else if (result && result[0] === 'fail') {
      this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
    } else {
      // validations list returned from Apex
      this.errorModal = true;
      this.errorLst = result;
    }
  })
  .catch((error) => {
    const msg = (error && (error.body?.message || error.message)) || 'Something went wrong';
    console.error('performApprovalAction(Reject) error:', error);
    this.handletoastEvent(msg, this.toastTitle.ERROR, this.toastvariant.ERROR);
  })
  .finally(() => {
    this.spinner = false;
  });
}
}