import { api, LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getLoanApprovalDetails from '@salesforce/apex/HL_LoanApplicationApprovalController.getLoanApprovalDetails';
import performApprovalAction from '@salesforce/apex/HL_LoanApplicationApprovalController.performApprovalAction';
import recommendLoanApproval from '@salesforce/apex/HL_LoanApplicationApprovalController.recommendLoanApproval';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from "lightning/uiRecordApi";
import holdLoanApp from '@salesforce/apex/HL_LoanApplicationApprovalController.holdLoanApp';
import unHoldApplication from "@salesforce/apex/HL_LoanApplicationApprovalController.unHoldApplication";
import getPicklistValues from '@salesforce/apex/ScreenGenerationController.getPicklistValues';
import checkUserAuthorisationForApprove from '@salesforce/apex/HL_LoanApplicationApprovalController.checkUserAuthorisationForApprove';
import { RefreshEvent } from "lightning/refresh";
import checkIfAllDeviationsApproved from '@salesforce/apex/HL_LoanApplicationApprovalController.checkIfAllDeviationsApproved';
import getApprovalLevel from '@salesforce/apex/HL_LoanApplicationApprovalController.getApprovalLevel';
import assignToMe from '@salesforce/apex/HL_LoanApplicationApprovalController.assignToMe';
import checkPolicyLTV from '@salesforce/apex/HL_LoanApplicationApprovalController.checkPolicyLTV';
import getApplicantsByLoanApplication from "@salesforce/apex/AHL_LoanApplicationActionController.getApplicantsByLoanApplication";
import checkDedupeAtExist from "@salesforce/apex/AHL_LoanApplicationActionController.checkDedupeAtExist";


export default class Hl_LoanApprovalProcess extends NavigationMixin(LightningElement) {
    modalVisibility = false;
    @api recordId;
    @api isOneView = false;
    cssContainer = 'slds-modal__container width-70';
    @api approvalType = 'Loan Approval';
    @track approvalData = {};
    isLoading = false;
    @track errorModal = false;
    @track errorLst = [];
    actionToPerform;
    actionMessage;
    ltvBreach = '';
    isRendered = false;
    @track approvalTypeOptions = [];
    @track selectedApprovalType = '';
    selectedApprovalLevel = '';
    approvalLevelOptions = [];
    @track applicantList = [];
    @track currentApplicantIndex;
    toastvariant = {
        SUCCESS: 'success',
        ERROR: 'error'
    }
    toastTitle = {
        SUCCESS: 'Success',
        ERROR: 'Error'
    }

    toastMessages = {
        Loan_Recommended: 'Loan application has been submitted successfully.',
        Loan_Approved: 'Loan application has been approved successfully.',
        Loan_Rejected: 'Loan application has been rejected successfully.',
        SOMETHING_WENT_WRONG: 'Something went wrong.',
        SelectUser: 'Please select assignee user.',
        Loan_SentBack: 'Loan application has been sent back successfully.'
    }


    fetchApprovalTypePicklist() {
        getPicklistValues({ storageObject: 'Opportunity', storageField: 'Approval_Type__c' })
        .then(result => {
            this.approvalTypeOptions = result.map(item => ({
                label: item.label,   // must match Apex key
                value: item.value    // must match Apex key
            }));
            console.log('Approval Type Options:', this.approvalTypeOptions);
        })
        .catch(error => {
            console.error('Error fetching picklist values:', error);
        });
    }

    fetchApprovalLevel() {
        getApprovalLevel({ loanId : this.recordId })
        .then((result) => {
            console.log('result 85: ' + JSON.stringify(result));
            
            if(result){
                for(var key in result) {
                    this.approvalLevelOptions.push({ label: key, value: result[key] });
                }
            }
        })
        .catch((err) => {
            console.error(err);
        });
    }

    @api
    refresh() {
        this.connectedCallback();
    }

    connectedCallback() {
        console.log('record Id in connectedCallback ' + this.recordId);

        this.fetchApprovalTypePicklist();
        this.fetchApprovalLevel();
        this.getLoanApprovalDetails();
    }

    renderedCallback() {
        if(!this.isRendered) {
            // Create and append styles dynamically
            const style = document.createElement('style');
            style.innerText = `
            p, h1, h2, h3, h4, h5, a, .slds-button{
                font-family: Arial;
            }
            .cancel-button{
                text-wrap-mode: nowrap;
            }
            .custom-table .slds-form-element__label, span.slds-file-selector__text.slds-medium-show{
                display: none;
            }
            .custom-table span.slds-file-selector__button.slds-button.slds-button_neutral{
                font-size: 0px;
            }
            .custom-table svg.slds-button__icon.slds-button__icon_left{
                margin: 0px;
            }
            .custom-table lightning-primitive-file-droppable-zone.slds-file-selector__dropzone{
                border: none;
            }
            .custom-div .slds-form-element__control .slds-rich-text-editor{
                min-height: 400px;
            }
            .custom-div .slds-form-element__control .slds-rich-text-editor .slds-grid .slds-grid_vertical .slds-nowrap .slds-rich-text-editor__textarea .slds-grid editor .slds-rich-text-editor__textarea .slds-grid .ql-editor .ql-blank .slds-rich-text-area__content .slds-grow .slds-text-color_weak{
                min-height: 400px;
            }
            .custom-table{
                font-weight: 400;
            }

            /* ----------------- Rich Text Editor Dark Theme -----------------
               lightning-input-rich-text renders its internal Quill markup outside
               the reach of this component's scoped .css file, so the dark theme
               overrides for it must live in this unscoped injected <style> tag
               (same technique already used above for the min-height rule). */
            .custom-div .slds-rich-text-editor{
                background-color: #0e1c30;
                border: 1px solid #33455e;
                border-radius: 6px;
            }
            .custom-div .slds-rich-text-editor__toolbar,
            .custom-div .ql-toolbar.ql-snow{
                background-color: #0e1c30;
                border-bottom: 1px solid #33455e;
            }
            .custom-div .ql-toolbar .ql-picker-label{
                background-color: #16283f;
                color: #ffffff;
                border: 1px solid #33455e;
                border-radius: 4px;
            }
            .custom-div .ql-toolbar .ql-picker-options{
                background-color: #0e1c30;
                border: 1px solid #33455e;
                color: #ffffff;
            }
            .custom-div .ql-toolbar .ql-picker-item{
                color: #ffffff;
            }
            .custom-div .ql-toolbar .ql-picker-label .ql-stroke,
            .custom-div .ql-toolbar button .ql-stroke{
                stroke: #ffffff;
            }
            .custom-div .ql-toolbar .ql-picker-label .ql-fill,
            .custom-div .ql-toolbar button .ql-fill{
                fill: #ffffff;
            }
            .custom-div .ql-toolbar button:hover,
            .custom-div .ql-toolbar button.ql-active,
            .custom-div .ql-toolbar .ql-picker-label:hover{
                background-color: #1467eb;
                border-radius: 4px;
            }
            .custom-div .ql-container.ql-snow,
            .custom-div .ql-editor,
            .custom-div .slds-rich-text-area__content{
                background-color: #16283f;
                color: #ffffff;
                border: none;
            }
            .custom-div .ql-editor.ql-blank::before{
                color: #8a99b3;
            }

            /* ----------------- lightning-combobox dropdown option list -----------------
               The open listbox popover (approvalType / levelType / Udaan Approver
               dropdowns) renders outside the reach of the scoped .css file, so it
               needs the same unscoped injected-style technique used above for the
               Quill rich-text toolbar. Background/border match --dt-input-bg /
               --dt-border, hover/selected highlighted per the established pattern. */
            .slds-dropdown,
            .slds-dropdown__list,
            .slds-listbox_vertical {
                background-color: #16283f !important;
                border: 1px solid #33455e !important;
            }
            .slds-listbox__option,
            .slds-listbox__item {
                background-color: #16283f !important;
                color: #ffffff !important;
            }
            .slds-listbox__option:hover,
            .slds-listbox__option:focus,
            .slds-listbox__option.slds-has-focus,
            .slds-listbox__option[aria-selected="true"] {
                background-color: #1f3550 !important;
                color: #ffffff !important;
            }
            `;

            // Append the styles to the .styleContainer
            this.template.querySelector('.styleContainer')?.appendChild(style);

            // Prevent re-adding styles
            this.isRendered = true;
        }
    }

    getLoanApprovalDetails() {
        getLoanApprovalDetails({ loanId: this.recordId })
        .then((result) => {
            if(result) {
                this.approvalData = result;
                this.selectedApprovalType = result.crApprovalType;

                this.approvalData.products = this.approvalData.products.map((row) => {
                    return { 
                        ...row, 
                        prodComment: row.prodComment ? row.prodComment : ''
                    };
                });

                console.log('this.approvalData: ', JSON.stringify(this.approvalData));
            }
        })
        .catch((error) => {
            console.log('errror---=> in getLoanApprovalDetails', error);
        });
    }

    handleApprovalLevelChange(event){
        this.selectedApprovalLevel = event.target.value;
    }

    handleCommentChange(event) {
        var comment = event.target.value;
        var productId = event.target.dataset.productid;

        console.log('comment: ', comment);
        console.log('184 productId: ', productId);

        this.approvalData.products = this.approvalData.products.map((row) => {
            return { 
                ...row, 
                prodComment: row.productId == productId ? comment : row.prodComment
            };
        });

        // event.stopPropagation();
    }

    saveDraft(event) {
        // event.stopPropagation();
        
        var productId = event.target.dataset.productid;
        console.log('200 productId: ', productId);

        this.saveDraftNotes(productId);
    }

    saveDraftNotes(productId){
        const selectedProduct = this.approvalData.products.filter(row => row.productId == productId);
        console.log('selectedProduct: '+JSON.stringify(selectedProduct));

        if(selectedProduct){
            const fields = {};
            fields['Id'] = selectedProduct[0].productId;
            fields['Draft_PD_Note__c'] = selectedProduct[0].prodComment;
            const recordInput = { fields };
            console.log(`The Update Record: ${JSON.stringify(recordInput)}`)

            updateRecord(recordInput)
            .then(() => {
                this.handletoastEvent('The draft PD notes are saved successfully.', this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
                this.getLoanApprovalDetails();
            })
            .catch(error => {
                console.log('Error updating record --> ' + JSON.stringify(error));
            });
        }
    }

    validatePolicyLTV(){
        checkPolicyLTV({ 
            loanId: this.recordId
        })
        .then((result) => {
            if(result[0] != 'success'){
                var msg = '';
                for(var i=0; i< result.length; i++){
                    msg += result[i] + '     ';
                }

                this.ltvBreach = msg;
            }
        })
        .catch((error) => {
        });
    }

    async handleAction(event) {
        var action = event.target.dataset.name;
        this.actionToPerform = action;
        this.actionMessage = action == 'Hold' ? 'place your application on hold' : 'resume your application';
        var productId = event.target.dataset.productid;

        console.log('action: ', event.target.dataset.name);
        console.log('productId: '+productId);
        console.log('this.approvalType: '+this.approvalType);
        console.log('this.selectedApprovalType: '+this.selectedApprovalType);

        // event.stopPropagation();

        if(this.selectedApprovalType == null || this.selectedApprovalType == undefined || this.selectedApprovalType == ''){
            this.handletoastEvent('Please select approval type before proceeding further.', this.toastTitle.ERROR, this.toastvariant.ERROR);
            return;
        }

        if(action != 'AssignToMe') {
            var isProceed = true;
            this.approvalData.products.map((row) => {
                if(!row.prodComment && ((action === 'saveDraft' && row.productId == productId) || action !== 'saveDraft')){
                    this.handletoastEvent('Please enter remarks for '+ row.productName +'.', this.toastTitle.ERROR, this.toastvariant.ERROR);
                    isProceed = false;
                    return;
                }
            });

            if(isProceed){
                if(action == 'Recommended') {
                    console.log('in Recommended');

                    if(!this.selectedApprovalLevel) {
                        this.handletoastEvent('Please select approver level before submission.', this.toastTitle.ERROR, this.toastvariant.ERROR);
                        return;
                    }
                    else {
                        this.validatePolicyLTV();

                        this.timeoutId = setTimeout(() => {
                            console.log('285 this.ltvBreach: '+this.ltvBreach);

                            if(this.ltvBreach){
                                this.isLoading = false;
                                this.handletoastEvent(this.ltvBreach, this.toastTitle.ERROR, this.toastvariant.ERROR);
                            }
                            else{
                                this.isLoading = true;

                                recommendLoanApproval({ 
                                    loanId: this.recordId,
                                    approvalType: this.approvalType,
                                    selectedApprovalLevel: this.selectedApprovalLevel,
                                    isFinalApproval: this.selectedApprovalType == 'Final Approval'
                                })
                                .then((result) => {
                                    if(result) {
                                        console.log('result in Recommended::::', result);

                                        if(result[0] == 'success') {
                                            this.handletoastEvent(this.toastMessages.Loan_Recommended, this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
                                            
                                            this.getLoanApprovalDetails();
                                            this.selectedApprovalLevel = '';
                                        }
                                        else if(result[0] == 'fail') {
                                            this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                                        }
                                        else if(result.includes('STRING_TOO_LONG')) {
                                            this.handletoastEvent('Please shorten the comment in order to submit the loan.', this.toastTitle.ERROR, this.toastvariant.ERROR);
                                        }
                                        else {
                                            this.errorModal = true;
                                            this.errorLst = result;
                                        }
                                    }

                                    this.isLoading = false;
                                })
                                .catch((error) => {
                                    console.log('errror--- in Recommended', error);
                                    this.isLoading = false;
                                    this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                                });
                            }
                        }, 600);
                    }
                }
                else if(action == 'Approv' || action == 'Reject') {
                    console.log('in Approv/Reject');

                    this.isLoading = true;

                    if(action === 'Approv') {
                        checkIfAllDeviationsApproved({ loanId: this.recordId })
                        .then(() => {
                            return checkUserAuthorisationForApprove({ loanId: this.recordId });
                        })
                        .then((isAuthorized) => {

                            if(isAuthorized === false) {
                                this.isLoading = false;
                                
                                this.handletoastEvent(
                                    'You are not authorised to approve, please send it to higher authority.',
                                    this.toastTitle.ERROR,
                                    this.toastvariant.ERROR
                                );
                                return;
                            }

                            this.validatePolicyLTV();

                            this.timeoutId = setTimeout(() => {
                                console.log('359 this.ltvBreach: '+this.ltvBreach);

                                if(this.ltvBreach){
                                    this.isLoading = false;
                                    this.handletoastEvent(this.ltvBreach, this.toastTitle.ERROR, this.toastvariant.ERROR);
                                }
                                else{
                                    this.callApprovalAction(action);
                                    this.dispatchEvent(new RefreshEvent());
                                }
                            }, 600);
                        })
                        .catch((error) => {
                            console.error('Error in deviation/authorization checks: ', error);
                            this.isLoading = false;

                            this.handletoastEvent(
                                this.toastMessages.SOMETHING_WENT_WRONG,
                                this.toastTitle.ERROR,
                                this.toastvariant.ERROR
                            );
                        });
                    }
                    else {
                        // No special validation
                        this.callApprovalAction(action);
                    }

                    return;
                }
                else if(action === 'saveDraft') {
                    console.log('in savedraft');

                    this.saveDraftNotes(productId);
                }
                else if(action === 'Hold' || action === 'UnHold') {
                    this.modalVisibility = true;
                }
            }
        }
        else{
            console.log('in Assign to me');
            this.isLoading = true;

            assignToMe({ 
                loanId: this.recordId
            })
            .then((result) => {
                console.log('result in AssignToMe::::', result);
                if(result == 'Success'){
                    this.handletoastEvent('LA has been assigned to you.', 'Success', 'success');
                    this.getLoanApprovalDetails();
                }
                else{
                    this.handletoastEvent(result, 'Error', 'error');
                }
                this.isLoading = false;
            })
            .catch((error) => {
                console.log('errror--- in AssignToMe', error);
                this.isLoading = false;
                this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
            });
        }
    }

    async callApprovalAction(action) {
        console.log('calling performApprovalAction');
        console.log('this.selectedApprovalType: '+this.selectedApprovalType);

        const selectedProduct = this.approvalData.products[0];
        console.log('437 selectedProduct: '+JSON.stringify(selectedProduct));

        performApprovalAction({ loanId: this.recordId, action: action, comments: selectedProduct.prodComment, approvalType: this.selectedApprovalType })
        .then((result) => {
            if(result) {
                console.log('result in performApprovalAction::::', JSON.stringify(result));
                if(result[0] == 'success') {
                    this.getLoanApprovalDetails();

                    if(action == 'Approv') {
                        console.log('447 this.approvalType: ', this.approvalType);
                        if(this.selectedApprovalType == 'Final Approval'){
                            this.handleStartDedupe();
                        }

                        this.handletoastEvent(this.toastMessages.Loan_Approved, this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
                        this.dispatchEvent(new RefreshEvent());
                    } else {
                        console.log('at 452--');

                        this.handletoastEvent(this.toastMessages.Loan_Rejected, this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
                    }
                }
                else if(result[0] == 'fail') {
                    this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                }
                else if(result[0] && result[0].includes('long')) {
                    this.handletoastEvent('Please shorten the comment in order to approve the loan.', this.toastTitle.ERROR, this.toastvariant.ERROR);
                }
                else {
                    this.errorModal = true;
                    this.errorLst = result;
                }
            }

            this.isLoading = false;
        })
        .catch((error) => {
            console.log('errror--- in performApprovalAction', error);
            this.isLoading = false;
            this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
        });
    }

    handleStartDedupe() {
        this.applicantList = [];
        this.currentApplicantIndex = 0;

        getApplicantsByLoanApplication({ loanApplicationId: this.recordId })
        .then((response) => {
            console.log('response app188', JSON.stringify(response));
            if(response && response.length > 0) {
                this.applicantList = response;
                this.callDedupeAPISequentially(); // continue with dedupe process
            } else {
                this.handletoastEvent('No applicants found for this Loan Application.','Info',  'info');
            }
        })
        .catch((error) => {
            console.error('Error fetching applicants:', error);
            this.handletoastEvent('Unable to fetch applicants.','Error', 'error');
        });
    }

    async callDedupeAPISequentially() {
        if(this.currentApplicantIndex >= this.applicantList.length) {
            console.log('All applicants processed.');
            this.handletoastEvent( 'All applicants deduped successfully!','Success', 'success');
            return;
        }
        console.log('currentApplicantIndex-------', this.currentApplicantIndex);

        const applicant = this.applicantList[this.currentApplicantIndex];
        console.log('Processing applicant:', applicant.Id);

        try {
            const response = await checkDedupeAtExist({ applicantId: applicant.Id });
            //this.currentApplicantIndex++;

            console.log('Dedupe API Response for applicant:', applicant.Id, response);
        } catch (error) {
            console.error('Error during Dedupe API call for applicant:', applicant.Id, error);
            this.handletoastEvent( `Dedupe failed for applicant ${applicant.Name || applicant.Id}`,'Error', 'error');
        } finally {
            this.currentApplicantIndex++;

            setTimeout(() => {
                this.callDedupeAPISequentially();
            }, 100);
        }
    }

    handletoastEvent(msg, title, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
        }));
    }

    // sales-Ishi
    hideModalBox() {
        this.errorModal = false;
    }

    async handleApprovalTypeChange(event) {
        this.selectedApprovalType = event.detail.value;
        console.log('Selected Approval Type:', this.selectedApprovalType);

        const fields = {};
        fields['Id'] = this.recordId;
        fields['Approval_Type__c'] = this.selectedApprovalType;
        const recordInput = { fields };
        console.log(`The Update Record: ${JSON.stringify(recordInput)}`)

        updateRecord(recordInput)
        .then(() => {
            this.handletoastEvent('Approval Type updated successfully.', this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
        })
        .catch(error => {
            console.log('Error updating record --> ' + JSON.stringify(error));
            this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
        });
    }

    handleYes() {
        if(this.actionToPerform == 'Hold') {
            console.log('in hold');
            holdLoanApp({loanId: this.recordId})
            .then(() => {
                this.handletoastEvent('Loan application has been put on hold.', this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
                this.getLoanApprovalDetails();
                window.location.reload();
            })
            .catch(error => {
                this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                console.log('Error holdLoanApp --> ' + JSON.stringify(error));
            });
        }
        else if(this.actionToPerform == 'UnHold') {
            console.log('In Unhold');

            unHoldApplication({loanId: this.recordId})
            .then(() => {
                this.handletoastEvent('Loan application substage is changed to credit in-progress.', this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
                this.getLoanApprovalDetails();
                window.location.reload();
            }).catch(error => {
                this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                console.log('Error unHoldApplication --> ' + JSON.stringify(error));
            });
        }
    }

    handleNo() {
        this.modalVisibility = false;
    }

    stopPropogation(event) {
        const target = event.target;
        if(
            target &&
            (target.closest('.slds-rich-text-editor__toolbar') ||
                target.getAttribute('role') === 'textbox' ||
                target.tagName === 'BUTTON')
        ) {
            // Allow toolbar actions (Bold, Italic, etc.)
            return;
        }
        // Stop propagation for everything else
        event.stopPropagation();
    }
}