import { api, LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningModal from 'lightning/modal';
import quickActionSave from "@salesforce/apex/AHL_LoanApplicationActionController.quickActionSave";
import validateApplicantAddressPriorities from '@salesforce/apex/AHL_LoanApplicationActionController.validateApplicantAddressPriorities';
import quickActionYes from "@salesforce/apex/AHL_LoanApplicationActionController.quickActionYes";
import areAllDocumentsFCUComplete from "@salesforce/apex/FCUController.areAllDocumentsFCUComplete";
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName1';
import creditUnderwritingToPSVValidations from "@salesforce/apex/AHL_LoanApplicationActionController.creditUnderwritingToPSVValidations";
import checkPsvSalesToPsvCreditValidation from '@salesforce/apex/AHL_LoanApplicationActionController.checkPsvSalesToPsvCreditValidation';
import sanctionLetterGeneratedValidation from "@salesforce/apex/AHL_LoanApplicationActionController.sanctionLetterGeneratedValidation";
import fetchBranchUsers from "@salesforce/apex/AHL_LoanApplicationActionController.fetchBranchUsers";
import checkQDEComments from '@salesforce/apex/AHL_LoanApplicationActionController.checkQDEComments';
import getApplicantsByLoanApplication from "@salesforce/apex/AHL_LoanApplicationActionController.getApplicantsByLoanApplication";
import checkDedupeAtExist from "@salesforce/apex/AHL_LoanApplicationActionController.checkDedupeAtExist"
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';
const FIELDS = ['Opportunity.StageName', 'Opportunity.Sub_stage__c', 'Opportunity.Loan_Hierarchy__c'];
import FCU_STATUS_FIELD from '@salesforce/schema/Opportunity.FCU_Status__c';
import checkOPSMakerStageValidation from "@salesforce/apex/AHL_LoanApplicationActionController.checkOPSMakerStageValidation";
import savePDF from "@salesforce/apex/Utility.savePDF";
import validateQuickDisbursementProcess from '@salesforce/apex/AHL_LoanApplicationActionController.validateQuickDisbursementProcess';
import handleQuickDisbursementProcess from '@salesforce/apex/AHL_LoanApplicationActionController.handleQuickDisbursementProcess';
import getLoanTransactionDetails from '@salesforce/apex/AHL_LoanApplicationActionController.getLoanTransactionDetails';
// import updateLoanSanctionTenureField from '@salesforce/apex/Sales_LoginProductDetailsController.updateLoanSanctionTenureField';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import getOpportunityTeamMembers from '@salesforce/apex/AHL_LoanDetailsController.getOpportunityTeamMembers';
import USERID_FIELD from "@salesforce/user/Id";
import { NavigationMixin } from 'lightning/navigation';
import calculateWaiverAmount from '@salesforce/apex/AHL_LoanApplicationActionController.calculateWaiverAmount';
import revertLoanStatus from '@salesforce/apex/AHL_LoanApplicationActionController.revertLoanStatus';
import addUsertoOtm from '@salesforce/apex/AHL_LoanApplicationActionController.addUsertoOtm';

import getUseLmsNewLogic from '@salesforce/apex/PushToLMS.getUseLmsNewLogic';
import getInitialData from '@salesforce/apex/PushToLMS.getInitialData';
import upsertApplicant from '@salesforce/apex/PushToLMS.upsertApplicant';
import handleExistingCIFUpdate from '@salesforce/apex/PushToLMS.handleExistingCIFUpdate';
import processCollateral from '@salesforce/apex/PushToLMS.processCollateral';
import callCreateFinanceAPEX from '@salesforce/apex/PushToLMS.callCreateFinance';
import updateLoanTransactionQDPFields from '@salesforce/apex/PushToLMS.updateLoanTransactionQDPFields';


export default class homeQuickAction extends NavigationMixin(LightningElement) {
    @api recordId;
    @api actionName;
    @track modalVisibility = false;
    @track errorModal = false;
    quickActionAPIName;
    cssContainer = 'slds-modal__container width-70';
    loan;
    @track remarks = '';
    currentUserOppRole = []; //Sanwar
    @track isError = false;
    @track errorLst = [];
    @track applicantList = [];
    @track currentApplicantIndex = 0;
    errorData = [];
    @track spinner = false;
    @track isSampler = false;
    @track userProfile;
    @track showQueryScreen;
    @track query;
    showMovetoCreditError = false;
    @track loanTransactionRec;
    @track isHomeLoan = false;
    applicableUsers = [];
    showReassignPopup = false;
    nextProfileNeeded = '';


    handleRemarksChange(event) {
        this.remarks = event.target.value;
    }


    get showMarkAsCompleteHelpText() {
        return this.quickActionAPIName == 'Mark_As_Complete1';
    }

    @wire(getOpportunityTeamMembers, {
        loanId: "$recordId",
    })
    getOppTeamMembers({
        data,
        error
    }) {
        if (data) {
            console.log('data ', data);
            data.forEach(item => {
                console.log('User Data');
                console.log('user id', item.UserId);
                if (item.UserId == USERID_FIELD) {
                    this.currentUserOppRole.push(item.TeamMemberRole);
                }
            })
            console.log('Current user role ', this.currentUserOppRole);
            /*if (this.currentUserOppRole == '' || this.currentUserOppRole == undefined) {
                this.errorData.push('The current user has No Team Member Role attached to it.')
            }*/
        } else if (error) {
            this.handleError(error, 'gotLoanFields');
            this.showToast(this.toastTitle.ERROR, this.toastMessages.SOMETHING_WENT_WRONG, this.toastVariant.ERROR);
        }
    }

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef) {
            this.recordId = pageRef.state.recordId || this.recordId;
        }

        if (pageRef.type === "standard__quickAction") {
            let quickActionPath = pageRef.attributes.apiName;
            this.quickActionAPIName = quickActionPath.split('.')[1];
            console.log('quick action name>', this.quickActionAPIName);
        }

    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.loan = data;

            // Access field values
            console.log('loan StageName:', this.loan.fields.StageName.value);
            console.log('loan Sub_stage__c:', this.loan.fields.Sub_stage__c.value);
            console.log('loan Loan_Hierarchy__c:', this.loan.fields.Loan_Hierarchy__c.value);
        } else if (error) {
            console.error('Error fetching account:', error);
        }
    }

    userName;

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [USER_NAME_FIELD]
    })
    wiredUser({ error, data }) {
        if (data) {
            this.userName = data.fields.Name.value;
            // this.error = undefined;
            console.log('Current User Name:', this.userName);
        } else if (error) {
            // this.error = error;
            this.userName = undefined;
            console.error('Error fetching user:', error);
        }
    }

    redirectToOpportunity() {
        const baseUrl = window.location.origin;
        const redirectUrl = `${baseUrl}/lightning/r/Opportunity/${this.recordId}/view`;
        window.location.href = redirectUrl;
    }

    handleNo() {
        this.modalVisibility = false;
        this.spinner = false;
        this.dispatchEvent(new CustomEvent('closemodal'));
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleAssigneeChange(event) {
        this.newAssignee = event.target.value;

    }




    async handleProceed() {
        this.spinner = true;
        let finalRemarks = null;
        if (!this.recordId) {
            this.showToast('Error', 'No Opportunity Record ID found.', 'error');
            this.redirectToOpportunity();
            this.handleNo();
            return;
        }

        try {
            if (!this.remarks || this.remarks.trim() === '') {
                this.showToast('Error', 'Remarks are required to proceed.', 'error');
                this.spinner = false;
                return;
            }
            else {
                const now = new Date();
                this.currentDate = now.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
                this.currentTime = now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true });
                finalRemarks = '{ ' + this.currentTime + ' } ' + ' { ' + this.currentDate + ' } ' + ' { ' + this.userName + ' } ' + '{' + this.remarks + ' }';
            }
            const result = await (quickActionSave({ loanApplicationId: this.recordId, quickActionName: this.quickActionAPIName, remarks: finalRemarks, userName: this.userName, stageName: '' })
            );
            console.log('this.quickActionAPIName',this.quickActionAPIName);
            console.log('#####' + result);
            if (
                result.includes(
                    'Loan application cannot be sent back as an approval process is already in progress.'
                ) ||
                result.includes(
                    'Loan application cannot be marked as complete as an approval process is already in progress.'
                ) ||
                result.includes('Last date of CIBIL pull was more than') ||
                result.includes('Opportunity Team member is not present with role')) {
                this.showToast('Error', result, 'error');
            }
            else if (
                result == 'Application sent back successfully' ||
                result == 'Stage changed successfully' ||
                result == 'Sub stage changed from PSV Sales to Credit in-progress' ||
                result == 'Sub stage changed from Credit in-progress to Credit Processing Verification' ||
                result == 'Sub-Stage successfully changed from PSV Sales to PSV Credit') {
                this.showToast('Success', result, 'success');
                this.dispatchEvent(new CustomEvent('closemodal'));
                setTimeout(() => {
                    this.redirectToOpportunity();
                }, 1000);
            } else if (
                result != '' &&
                result !=
                'Loan application can not be sent back as an approval process is already in progress.' &&
                result !=
                'Loan application can not be marked as complete as an approval process is already in progress.' && !(result.includes('Reassign needed for:'))) {
                // call gst for waiver amount
                this.calculateWaiverAmount();
                // call QDP
                getLoanTransactionDetails({ loanId: this.recordId })
                    .then((result) => {
                        if (result) {
                            this.loanTransactionRec = result;
                            if (this.loanTransactionRec.Quick_Disbursement__c == true && this.loanTransactionRec.Loan_Application__r.Sub_stage__c == 'Ops Author') { //check with Gaurav why its Ops Author>> as per debugging its gettting moved to Ops author beforehand
                                this.validateQDPProcess();
                            }
                            else {
                                this.handleNo();
                                //this.showToast('Error', result, 'error');
                            }
                        }
                    })
                    .catch((error) => {
                        console.error('error in getting loantransaction', error);
                        this.spinner = false;
                    });
            } else if (result.includes('Reassign needed for:')) {
                console.log('result>>>' + result);
                console.log('result.split(:)>>>' + result.split(':'));
                this.nextProfileNeeded = result.split(':')[1];
                console.log('nextProfileNeeded>>>' + this.nextProfileNeeded);
                this.modalVisibility = false;
                this.showReassignPopup = true;
                fetchBranchUsers({ role: this.nextProfileNeeded, loanId: this.recordId }).then(data => {
                    console.log('branch users>>>' + JSON.stringify(data));
                    this.applicableUsers = data;
                    let options = [];
                    this.applicableUsers.forEach(res => {
                        options.push({ label: res.userName, value: res.userId });

                    })
                    this.assigneeoptions = options;
                    this.spinner = false;


                }).catch(err => {
                    console.log('Error 239>>' + JSON.stringify(err));
                })
            } else {
                throw new Error(result);
            }
        } catch (error) {
            const regex = /FIELD_CUSTOM_VALIDATION_EXCEPTION,\s*(.*?):\s*\[\]/;
            let errorMessage = 'An unexpected error occurred.';
            if (error.body && error.body.message && error.body.message.match(regex)) {
                const matches = error.body.message.match(regex);
                errorMessage = matches && matches[1] ? matches[1] : error.body.message;
            } else if (error.body && error.body.message) {
                errorMessage = error.body.message;
            } else if (error.message) {
                errorMessage = error.message;
            } else if (error?.body?.pageErrors?.[0]?.message) {
                errorMessage = error.body.pageErrors[0].message;
            }
            this.showToast('Error', errorMessage, 'error');
            this.handleNo();
        }
    }

    reassignRecord() {
        addUsertoOtm({ userId: this.newAssignee, role: this.nextProfileNeeded, loanApplicationId: this.recordId }).then(data => {
            this.showToast('Success', 'User added successfully!', 'success');
            this.showReassignPopup = false;
            this.dispatchEvent(new CustomEvent('closemodal'));
            this.dispatchEvent(new CloseActionScreenEvent());
            this.dispatchEvent(new RefreshEvent());
        }).catch(error => {
            console.log('error 293>>>' + JSON.stringify(error));
            this.showToast('Success', error.body.message, 'success');

        })
    }

    closeModel() {
        this.showReassignPopup = false;
        this.dispatchEvent(new CustomEvent('closemodal'));
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(new RefreshEvent());
    }

    updateSanctionTenure() {
        updateLoanSanctionTenureField({ loanId: this.recordId })
            .then(result => {
                this.showToast('Success', 'Updated sanction tenure successfully!', 'success');
                this.dispatchEvent(new RefreshEvent());
            })
            .catch(error => {
                console.log('Error updating sanction tenure:', error);
            });
    }

    checkQDEComments() {
        this.spinner = true;
        this.modalVisibility = false;
        this.showQueryScreen = false;
        this.errorModal = false;
        this.showMovetoCreditError = false;
        checkQDEComments({ recordId: this.recordId })
            .then(response => {
                console.log('response---', JSON.stringify(response));

                if (response.length > 0) {
                    this.errorLst = response.map((item, index) => ({ index: index + 1, value: item }));
                    this.modalVisibility = false;
                    this.errorModal = true;
                } else {
                    this.modalVisibility = true;
                }
                this.spinner = false;
            })
            .catch(() => this.showToast('Error', 'Error checking validation.', 'error'))
            .finally(() => this.spinner = false);
    }
    //added by oj
    checkForSanctionLetterGenerationValidation() {
        this.spinner = true;
        this.modalVisibility = false;
        this.showQueryScreen = false;
        this.errorModal = false;
        this.showMovetoCreditError = false;
        sanctionLetterGeneratedValidation({ recordId: this.recordId })
            .then(response => {
                if (response.length > 0) {
                    this.errorLst = response.map((item, index) => ({ index: index + 1, value: item }));
                    this.modalVisibility = false;
                    this.errorModal = true;
                } else {
                    this.modalVisibility = true;
                }
                this.spinner = false;
            })
            .catch(() => this.showToast('Error', 'Error checking validation.', 'error'))
            .finally(() => this.spinner = false);
    }


    fetchLoanStage() {
        getLoanStage({ loanId: this.recordId })
            .then((result) => {
                console.log('getLoanStage -- result : ' + result);
                if (result && (result === 'Credit Underwriting' || result === 'PSV')) {
                    this.updateFromProduct = true;
                } else {
                    this.updateFromProduct = false;
                }
            })
            .catch(error => {
                console.error('Error getLoanStage : ', error);
            })
    }

    checkAddressPrioritiesForSalesLogin() {
        this.spinner = true;
        this.modalVisibility = false;
        this.errorModal = false;

        validateApplicantAddressPriorities({ loanApplicationId: this.recordId })
            .then(response => {
                if (response && response.length > 0) {
                    this.errorLst = response.map((item, index) => ({
                        index: index + 1,
                        value: item
                    }));
                    this.errorModal = true;
                } else {
                    this.modalVisibility = true;
                }
                this.spinner = false;
            })
            .catch(error => {
                console.error('Error in address priority validation:', error);
                this.showToast('Error', 'Error checking address priorities.', 'error');
                this.spinner = false;
            });
    }

    connectedCallback() {
        // When this component is embedded directly (e.g. from a custom banner button)
        // rather than invoked as a real platform Quick Action, the CurrentPageReference
        // wire below never sees pageRef.type === "standard__quickAction", so
        // quickActionAPIName would stay unset. Falling back to the @api actionName prop
        // here (only when provided) fixes that without touching the existing
        // quick-action wiring, which still takes priority via the wire callback.
        if (this.actionName && !this.quickActionAPIName) {
            this.quickActionAPIName = this.actionName;
        }
        this.fetchLoanStage();
        getCurrentUserProfileName()
            .then(result => {
                this.userProfile = result;
                console.log('User profile:', this.userProfile);

                if (this.userProfile === 'Sampler') {
                    // Skip modal. Check FCU document completion and update field
                    areAllDocumentsFCUComplete({ loanAppId: this.recordId })
                        .then(allComplete => {
                            console.log('check', allComplete);
                            const fields = {};
                            fields['Id'] = this.recordId;
                            if (allComplete) {
                                fields[FCU_STATUS_FIELD.fieldApiName] = 'FCU Completed';
                            } else {
                                fields[FCU_STATUS_FIELD.fieldApiName] = 'Pending';
                            }
                            const recordInput = { fields };

                            updateRecord(recordInput)
                                .then(() => {
                                    if (allComplete) {
                                        this.showToast('Success', 'FCU Status Updated successfully', 'success');
                                    } else {
                                        this.showToast('Error', 'All Documents are not yet completed', 'error');
                                    }
                                    this.dispatchEvent(new CloseActionScreenEvent());
                                    this.redirectToOpportunity();
                                })
                                .catch(error => {
                                    console.error('Error updating Opportunity:', error);
                                    this.showToast('Error', 'Failed to update Opportunity.', 'error');
                                })
                                .finally(() => {
                                    this.spinner = false;
                                });

                        })
                        .catch(error => {
                            console.error('Error checking FCU docs:', error);
                            this.showToast('Error', 'Error checking FCU document status.', 'error');
                            this.spinner = false;
                            this.dispatchEvent(new CloseActionScreenEvent());
                        });

                }
                else {
                    setTimeout(() => {
                        console.log('this.quickActionAPIName', this.quickActionAPIName);
                        //this.modalVisibility = true;
                        const stage = this.loan.fields.StageName.value;
                        const subStage = this.loan.fields.Sub_stage__c.value;
                        const loanHierarchy = this.loan.fields.Loan_Hierarchy__c.value ? this.loan.fields.Loan_Hierarchy__c.value : '';
                        const roles = this.currentUserOppRole;
                        console.log('stagesubstage', stage, subStage, roles);
                        if ((
                            stage == 'Disbursement' || stage == 'PSV') &&

                            (!(
                                (stage == 'Disbursement' && this.loan.fields.Sub_stage__c.value == 'Ops Maker' ) ||  //&& (roles.includes('OPS Maker') || roles.includes('Credit Officer'))
                                (stage == 'PSV' &&
                                    (subStage == 'PSV Sales')
                                     //&& roles.includes('Sales'))
                                ||
                                (stage == 'PSV' && (subStage == 'PSV Credit') ) || //&& (roles.includes('Credit') || roles.includes('Credit Officer') || roles.includes('OPS Maker'))
                                    
                                (stage == 'Disbursement' && subStage == 'Ops Author' ))))) { //&& roles.includes('OPS Author')
                            this.isError = true;
                            this.modalVisibility = false;
                            let buttonName = this.quickActionAPIName == 'Mark_As_Complete1' ? 'Mark As Complete' : 'Send Back';
                            let errorMessage = 'You don\'t have permission to do ' + buttonName;
                            let obj = { 'Id': 1, 'Message': errorMessage };
                            this.errorData.push(obj);
                            console.log('errorData' + JSON.stringify(this.errorData));
                        }
                        /*else if (stage == 'Disbursement' && subStage == 'Ops Maker' && this.quickActionAPIName == 'Mark_As_Complete1') {
                            this.checkOPSMakerValidation(false);
                        }*/
                        /*else if (stage == 'PSV' && subStage == 'PSV Credit' && this.quickActionAPIName == 'Mark_As_Complete1') {
                            this.checkOPSMakerValidation(true);
                        }*/
                        else if (stage.toLowerCase() == 'sales login' && this.quickActionAPIName == 'Mark_As_Complete1') {
                            this.checkAddressPrioritiesForSalesLogin();
                        }
                        /*else if (stage == 'PSV' && subStage == 'PSV Sales' && this.quickActionAPIName == 'Mark_As_Complete1') {
                            this.checkPsvSalesToPsvCredit(true);
                        }*/
                        else if (stage == 'Credit Underwriting' && subStage == 'QDE in-progress' && this.quickActionAPIName == 'Mark_As_Complete1') {
                            console.log('at 391');

                            this.checkQDEComments();
                        }
                        else if (stage == 'PSV' && subStage == 'PSV Sales' && this.quickActionAPIName == 'Send_Back' && loanHierarchy == 'Parent') {
                            this.isError = true;
                            this.modalVisibility = false;
                            let errorMessage = 'You don\'t have permission to do send back after loan is splitted, please use Submit For Resanction button to proceed';
                            let obj = { 'Id': 1, 'Message': errorMessage };
                            this.errorData.push(obj);
                            console.log('errorData' + JSON.stringify(this.errorData));
                        }
                        // else if(this.loan.fields.StageName.value == 'Disbursement' && this.loan.fields.Sub_stage__c.value == 'Ops Author' && this.quickActionAPIName == 'Mark_As_Complete1') {
                        //     this.checkOpsMakerToOpsAuthorValidation();
                        // } 
                        else {
                            this.modalVisibility = true;
                        }
                    }, 1000);
                }
            })
    }

    savePDF() {
        savePDF({ loanId: this.recordId, docName: 'DisbursmentMemo' })
            .then(response => {
                console.log('response: ', response);
            })
            .catch(error => {
                console.error('Error updating the record: ', error);
            })
    }

    checkPsvSalesToPsvCredit() {
        this.spinner = true;
        this.modalVisibility = false;
        this.showQueryScreen = false;
        this.errorModal = false;
        this.showMovetoCreditError = false;

        checkPsvSalesToPsvCreditValidation({ loanApplicationId: this.recordId })
            .then(response => {
                console.log('checkPsvSalesToPsvCreditValidation: ', JSON.stringify(response));
                if (response[0] === 'Success') {
                    this.modalVisibility = true;
                } else {

                    console.log('this.errorLst : ', this.errorLst);
                    this.errorLst = response.map((item, index) => ({
                        index: index + 1,
                        value: item
                    }));
                    this.errorModal = true;
                }
                this.spinner = false;
            })
            .catch(error => {
                console.error('Error in checkPsvSalesToPsvCreditValidation: ', error);
                this.showToast('Error', 'Unable to process.', 'error');
                this.spinner = false;
            })
            .finally(() => this.spinner = false);
    }

    //added by oj
    checkOPSMakerValidation(isPsvToDisb) {
        this.spinner = true;
        /*this.modalVisibility = false;
        this.showQueryScreen = false;
        this.errorModal = false;
        this.showMovetoCreditError = false;*/

        checkOPSMakerStageValidation({ loanApplicationId: this.recordId, isPsvToDisb })
            .then(response => {
                if (response[0] === 'Success') {
                    this.modalVisibility = true;
                } else {
                    this.errorLst = response.map((item, index) => ({ index: index + 1, value: item })); this.errorModal = true;
                }
                this.spinner = false;
            })
            .catch((error) => {
                console.error('Error checking disb validations: ', error);
                this.showToast('Error', 'Unable to process.', 'error');
                this.spinner = false;
            })
            .finally(() =>
                this.spinner = false);
    }


    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });

        this.dispatchEvent(evt);
    }

    hideModalBox() {
        this.errorModal = false;
        this.dispatchEvent(new CustomEvent('closemodal'));
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    
    handleStartDedupe() {
        this.spinner = true;
        this.modalVisibility = false;
        this.showQueryScreen = false;
        this.errorModal = false;
        this.showMovetoCreditError = false;
        this.applicantList = [];
        this.currentApplicantIndex = 0;

        getApplicantsByLoanApplication({ loanApplicationId: this.recordId })
            .then((response) => {
                console.log('response app188', JSON.stringify(response));
                if (response && response.length > 0) {
                    this.applicantList = response;
                    this.callDedupeAPISequentially(); // continue with dedupe process
                } else {
                    this.showToast('Info', 'No applicants found for this Loan Application.', 'info');
                    this.spinner = false;
                }
            })
            .catch((error) => {
                console.error('Error fetching applicants:', error);
                this.showToast('Error', 'Unable to fetch applicants.', 'error');
                this.spinner = false;
            });
    }

    async callDedupeAPISequentially() {
        if (this.currentApplicantIndex >= this.applicantList.length) {
            this.showToast('Success', 'All applicants deduped successfully!', 'success');
            this.spinner = false;

            if (!this.showMovetoCreditError && this.loan.fields.StageName.value == 'Disbursement' && this.loan.fields.Sub_stage__c.value == 'Ops Maker' && this.quickActionAPIName == 'Mark_As_Complete1') {
                this.checkOPSMakerValidation(false);
                this.savePDF();
            }
            else if (!this.showMovetoCreditError && this.loan.fields.StageName.value == 'PSV' && this.quickActionAPIName == 'Mark_As_Complete1') {
                this.checkForSanctionLetterGenerationValidation();
            }
            else if (!this.showMovetoCreditError && this.loan.fields.StageName.value == 'Credit Underwriting' && this.loan.fields.Sub_stage__c.value == 'QDE in-progress' && this.quickActionAPIName == 'Mark_As_Complete1') {
                this.checkQDEComments();
            }

            if (!this.loan.fields.StageName.value == 'PSV' && !this.loan.fields.StageName.value == 'Disbursement') {
                this.creditUnderwritingToPSVValidations();
            }
            return;
        }

        const applicant = this.applicantList[this.currentApplicantIndex];

        try {
            const response = await checkDedupeAtExist({ applicantId: applicant.Id });
            if (response == true && (this.loan.fields.StageName.value == 'PSV' || (this.loan.fields.StageName.value == 'Disbursement' && (this.loan.fields.Sub_stage__c.value == 'Ops Maker' || this.loan.fields.Sub_stage__c.value == 'Ops Author')))) {
                this.modalVisibility = false;
                this.errorModal = false;
            }

        } catch (error) {
            console.error('Error during Dedupe API call for applicant:', applicant.Id, error);
            this.showToast('Error', `Dedupe failed for applicant ${applicant.Name || applicant.Id}`, 'error');
        } finally {
            this.currentApplicantIndex++;
            setTimeout(() => {
                this.callDedupeAPISequentially();
            }, 100);
        }
    }

    //product check by oj
    creditUnderwritingToPSVValidations() {
        this.spinner = true;
        this.modalVisibility = false;
        this.showQueryScreen = false;
        this.errorModal = false;
        this.showMovetoCreditError = false;
        creditUnderwritingToPSVValidations({ oppId: this.recordId })
            .then((response) => {
                console.log('Validation response:', response);

                if (response && response.length > 0) {
                    this.errorLst = response.map((item, index) => ({
                        index: index + 1,
                        value: item
                    }));
                    console.log(this.errorLst);
                    this.errorModal = true;
                } else {
                    this.modalVisibility = true;
                }
            })
            .catch((error) => {
                console.error('Error during validation:', error);
                this.showToast('Error', 'Something went wrong during validation.', 'error');
            })
            .finally(() => {
                this.spinner = false;
            });
    }


    hideModalCreditSendback() {
        this.showMovetoCreditError = false;
        this.modalVisibility = false;
    }

    //added by oj
    validateQDPProcess() {
        validateQuickDisbursementProcess({ loanApplicationId: this.recordId })
            .then(response => {
                if (response[0] === 'Success') {
                    this.handleQuickDisbursementProcess();
                } else {
                    this.errorLst = response.map((item, index) => ({ index: index + 1, value: item }));
                    this.errorModal = true;
                }
            })
            .catch(error => {
                this.spinner = false;
                this.showToast('Error', 'Something went wrong during validation.', 'error');
                console.error('Error validateQDP', error);
            });
    }

    async handleQuickDisbursementProcess() {
        this.modalVisibility = false;
        this.showQueryScreen = false;
        this.errorModal = false;
        this.showMovetoCreditError = false;

        const isHL = this.showHLRelatedData === true;

        let useNewLogic = false;
        try {
            const flag = await getUseLmsNewLogic();
            useNewLogic = (flag === true);
        } catch (err) {
            console.error('QDP routing - getUseLmsNewLogic failed, falling back to old flow:', err);
            useNewLogic = false;
        }
        console.log('QDP routing -> isHL:', isHL, '| useNewLogic:', useNewLogic);

        if (useNewLogic) {
            await this.handleQDPMultiTransaction();
            return;
        }

        handleQuickDisbursementProcess({ loanApplicationId: this.recordId })
            .then(response => {
                const successResp = response.success;
                const errorResp = response.error;
                if (successResp.length > 0) {
                    this.spinner = false;
                    this.showToast('Success', successResp[0], 'success');
                    this.modalVisibility = false;
                    this.dispatchEvent(new CustomEvent('closemodal'));
                } else if (errorResp.length > 0) {
                    this.spinner = false;
                    this.errorLst = errorResp.map((item, index) => ({ index: index + 1, value: item }));
                    this.errorModal = true;
                }
            })
            .catch(error => {
                this.spinner = false;
                this.showToast('Error', 'Something went wrong during validation.', 'error');
                console.error('Error handleQuickDisbursementProcess', error);

                revertLoanStatus({ loanApplicationId: this.recordId })
                    .then()
                    .catch(error => console.error('Error updating status to ops maker:', error));
            });
    }

    async handleQDPMultiTransaction() {
        try {
            let initialData;
            try {
                initialData = await getInitialData({ loanApplicationId: this.recordId });
            } catch (err) {
                await this._revertQDPSubStage();
                this.spinner = false;
                this.errorLst = [{
                    index: 1,
                    value: this._extractMsg(err, 'Failed to retrieve loan data.')
                }];
                this.errorModal = true;
                return;
            }

            const lmsIdMap = {};
            let primaryCif = '';
            let successCount = 0;
            const errors = [];
            const existingCustMsgs = [];

            const apResultsRaw = await Promise.all(
                initialData.applicants.map(applicant =>
                    upsertApplicant({
                        loanApplicationId: this.recordId,
                        applicantId: applicant.applicantId
                    }).catch(err => ({
                        _isError: true,
                        applicantId: applicant.applicantId,
                        errorMessage: 'Create/Update Customer Error: ' + this._extractMsg(err)
                    }))
                )
            );

            for (const apResult of apResultsRaw) {
                if (apResult._isError) {
                    errors.push(apResult.errorMessage);
                } else if (apResult.existingCustMsg) {
                    existingCustMsgs.push(apResult.existingCustMsg);
                } else if (apResult.success) {
                    successCount++;
                    if (apResult.lmsId) {
                        lmsIdMap[apResult.customerId] = apResult.lmsId;
                    }
                    if (apResult.applicantType === 'Primary Applicant' && apResult.lmsId) {
                        primaryCif = apResult.lmsId;
                    }
                } else {
                    errors.push(apResult.errorMessage || 'Create/Update Customer Error');
                }
            }

            if (existingCustMsgs.length > 0) {
                try {
                    const updated = await handleExistingCIFUpdate({ messages: existingCustMsgs });
                    if (updated) {
                        errors.push(
                            'Some existing Customers were found and updated in the system. ' +
                            'Kindly Push to LMS again.'
                        );
                    }
                } catch (err) {
                    console.error('handleExistingCIFUpdate error:', err);
                    errors.push('Error processing existing customers: ' + this._extractMsg(err));
                }
            }

            if (errors.length > 0) {
                await this._revertQDPSubStage();
                this.spinner = false;
                this.errorLst = errors.map((item, index) => ({ index: index + 1, value: item }));
                this.errorModal = true;
                return;
            }

            if (successCount === initialData.applicants.length) {

                const colRefMap = {};
                let callCf = false;
                const collateralsNeedingAPI = [];

                for (const collateral of initialData.collaterals) {
                    if (collateral.plfId) {
                        colRefMap[collateral.appColId] = collateral.plfId;
                        callCf = true;
                    } else {
                        collateralsNeedingAPI.push(collateral);
                    }
                }

                if (collateralsNeedingAPI.length > 0) {
                    const colResultsRaw = await Promise.all(
                        collateralsNeedingAPI.map(collateral =>
                            processCollateral({
                                loanApplicationId: this.recordId,
                                appColId: collateral.appColId,
                                primaryCif: primaryCif
                            }).catch(err => ({
                                _isError: true,
                                appColId: collateral.appColId,
                                collateralName: collateral.collateralName,
                                errorMessage: this._extractMsg(err)
                            }))
                        )
                    );

                    for (let i = 0; i < colResultsRaw.length; i++) {
                        const collateral = collateralsNeedingAPI[i];
                        const colResult = colResultsRaw[i];

                        if (colResult._isError) {
                            errors.push(
                                'For Collateral ' + collateral.collateralName +
                                ': ' + colResult.errorMessage
                            );
                            colRefMap[collateral.appColId] = '';
                        } else {
                            colRefMap[collateral.appColId] = colResult.colRef || '';
                            if (colResult.success) {
                                callCf = true;
                            } else {
                                errors.push(
                                    'For Collateral ' + collateral.collateralName +
                                    ' ' + colResult.errorMessage
                                );
                            }
                        }
                    }
                }

                if (errors.length > 0) {
                    await this._revertQDPSubStage();
                    this.spinner = false;
                    this.errorLst = errors.map((item, index) => ({ index: index + 1, value: item }));
                    this.errorModal = true;
                    return;
                }

                if (callCf || initialData.childLoan || initialData.collaterals.length === 0) {
                    let finResult;
                    try {
                        finResult = await callCreateFinanceAPEX({
                            loanApplicationId: this.recordId,
                            isQdp: true,
                            colRefMapJSON: JSON.stringify(colRefMap),
                            lmsIdMapJSON: JSON.stringify(lmsIdMap),
                            childLoan: initialData.childLoan
                        });
                    } catch (err) {
                        throw err;
                    }

                    if (finResult && finResult.success) {
                        try {
                            await updateLoanTransactionQDPFields({ loanApplicationId: this.recordId });
                        } catch (qdpErr) {
                            console.error(
                                'updateLoanTransactionQDPFields failed after successful Push To LMS:',
                                qdpErr
                            );
                        }

                        this.spinner = false;
                        this.showToast(
                            'Success',
                            'Loan has been pushed to LMS with the LMS Ref Number: ' +
                            finResult.finReference,
                            'success'
                        );
                        this.modalVisibility = false;
                        this.dispatchEvent(new CustomEvent('closemodal'));
                    } else {
                        this.spinner = false;
                        const finErrMsg = (finResult && finResult.errorMessage)
                            ? finResult.errorMessage
                            : 'Create Finance Error';
                        this.errorLst = [{ index: 1, value: finErrMsg }];
                        this.errorModal = true;
                    }
                }
            }
        } catch (error) {
            this.spinner = false;
            this.showToast('Error', 'Something went wrong during validation.', 'error');
            console.error('Error handleQDPMultiTransaction', error);
            revertLoanStatus({ loanApplicationId: this.recordId })
                .then()
                .catch(err => console.error('Error updating status to ops maker:', err));
        }
    }

    _extractMsg(err, fallback = 'Unknown error') {
        if (!err) return fallback;
        if (err.body && err.body.message) return err.body.message;
        if (err.message) return err.message;
        return String(err);
    }

    async _revertQDPSubStage() {
        try {
            await revertLoanStatus({ loanApplicationId: this.recordId });
        } catch (err) {
            console.error('Error reverting loan status to Ops Maker:', err);
        }
    }

    calculateWaiverAmount() {
        calculateWaiverAmount({ loanId: this.recordId })
            .then((data) => {
                console.log('waiver amount data ==>', data);
                if (data == 'Success: GST calculation completed.') {
                    console.log('GST calculated for waiver amount successfully');
                }
                else if (data == 'Waiver Amount is 0') {
                    console.log('No GST calculation is required as waiver amount is 0');
                }
                else {
                    console.log('Error in GST calculation for the waiver amount');
                }
            })
    }

}