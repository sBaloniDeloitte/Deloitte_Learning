import { LightningElement, wire, api, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import STAGE_FIELD from "@salesforce/schema/Technical_Evaluation__c.HL_Stage__c";
import CHOOSE_REPORT from "@salesforce/schema/Technical_Evaluation__c.Choose_Report_Option__c";
import REPORT_UPLOADED from "@salesforce/schema/Technical_Evaluation__c.Is_Report_Uploaded__c";
import USER_ID from '@salesforce/user/Id';
import USERTYPE_FIELD from '@salesforce/schema/User.User_Type__c';
import submitLoanForApproval from '@salesforce/apex/COMM_TechnicalRecordPageController.submitLoanForApproval';
import performApprovalAction from '@salesforce/apex/COMM_TechnicalRecordPageController.performApprovalAction';
import createDocDetailForTechnical from '@salesforce/apex/COMM_TechnicalRecordPageController.createDocDetailForTechnical';
import getDocs from '@salesforce/apex/COMM_TechnicalRecordPageController.getDocs';
import getApprovalHistory from '@salesforce/apex/COMM_TechnicalRecordPageController.getApprovalHistory';
import { updateRecord } from 'lightning/uiRecordApi';
import checkSigned from '@salesforce/apex/DigitalSignatureController.checkSigned';

export default class InternalTechnicalApprovalProcess extends LightningElement {
    userId = USER_ID;
    showApproveButton = false;
    showSubmitApprovalButton = false;
    showSendBackButton = false;
    showRejectButton = false;
    technicalStage = '';
    chooseReport = '';
    reportUploaded=false;
    @api recordId;
    showRemarksModal = false;
    remarks = '';
    selectedAction = '';
    showRejectButtonToTech = false;
    @track approvalData = {};
    showEditModal = false;
    showEditButton = false;


    isUploadModalOpen = false;
    newDocName = '';

    isLoadingDocs = false;
    docRows = [];
    acceptedFormats = ['.pdf', '.jpg', '.jpeg', '.png'];

    get hasDocs() {
        return Array.isArray(this.docRows) && this.docRows.length > 0;
    }

    toastvariant = {
        SUCCESS: 'success',
        ERROR: 'error'
    }
    toastTitle = {
        SUCCESS: 'Success',
        ERROR: 'Error'
    }

    toastMessages = {
        Loan_Approved: 'Technical has been approved successfully.',
        Loan_Rejected: 'Technical has been rejected successfully.',
        SOMETHING_WENT_WRONG: 'Something went wrong.',
        SelectUser: 'Please select assignee user.',
        Loan_SentBack: 'Technical has been sent back successfully.',
        Technical_Stage_Change: 'Technical stage has been updated successfully.',

    }

    @wire(getRecord, { recordId: '$userId', fields: [USERTYPE_FIELD] })
    userRecord;

    get userType() {
        return this.userRecord?.data?.fields?.User_Type__c?.value;
    }

    @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD, CHOOSE_REPORT,REPORT_UPLOADED] })
    opportunity({ error, data }) {
        if (data) {
            console.log('data :::', JSON.stringify(data));
            this.technicalStage = data.fields.HL_Stage__c.value;
            this.chooseReport = data.fields.Choose_Report_Option__c.value;
            this.reportUploaded= data.fields.Is_Report_Uploaded__c.value;
            if (this.technicalStage == 'Assigned to Technical Manager') {
                this.showRejectButtonToTech = true;
            }
            if (this.technicalStage == 'Assigned to Admin' ||  this.technicalStage == 'Submitted by Admin' || this.technicalStage == 'Assigned to Technical Manager' || (this.technicalStage == 'Sent Back' && this.userType == 'Internal')) {
                this.showSubmitApprovalButton = true;
            }
             if ((this.technicalStage == 'Assigned to Technical Manager' || this.technicalStage == 'Submitted') && this.userType == 'Internal') {
                this.showApproveButton = true;
                this.showSendBackButton = true;
                this.showRejectButton = true;
            }
            if (this.technicalStage == 'Accepted by Technical Manager') {
                this.showEditButton = true;
            }
        }
        else if (error) {
            console.error('Error fetching INFO:', JSON.stringify(error));
        }
    }

    connectedCallback() {
        this.getApprovalHistory();
        const res =  checkSigned({ recordId: this.recordId });
        this.digitalSignature = res;
    }

    handletoastEvent(msg, title, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
        }));
    }
    handleRemarksChange(event) {
        console.log('Event object HK:', event);
        console.log('Event target HK:', event.target);
        console.log('Entered value HK:', event.target.value);
        this.remarks = event.target.value;
    }
    closeModal() {
        this.showRemarksModal = false;
        this.remarks = '';
    }
    handleAction(event) {
        console.log('HK IN');
        event.stopPropagation();
        this.selectedAction = event.target.dataset.name;
        console.log('event.target---HK', this.selectedAction);
        this.showRemarksModal = true;   // open popup
    }



    digitalSignature=false;
    handleConfirmAction(event) {
        // var action=event.target.dataset.name;
        console.log('event.target---', event.target.dataset.name);
        console.log('this.recordId>>>', this.recordId);
        if (!this.remarks) {
            this.handletoastEvent('Please enter remarks', this.toastTitle.ERROR, this.toastvariant.ERROR);
            return;
        }
        console.log('digitalSignature>>>', this.digitalSignature);
        if ((this.digitalSignature == false && this.chooseReport == 'Generate report in SFDC')) {
            this.handletoastEvent('Please generate the report and ensure it is digitally signed prior to submitting it for approval.', this.toastTitle.ERROR, this.toastvariant.ERROR);
            return;
        }
        event.stopPropagation();
        console.log('Selected Action Value: HK', this.selectedAction);
        console.log('Type of Selected Action: HK', typeof this.selectedAction);
        if (this.selectedAction == 'submitted For Approval') {

            submitLoanForApproval({ technicalId: this.recordId, remarks: this.remarks })
                .then((result) => {
                    if (result) {
                        console.log('result in submitLoanForApproval::::', result);
                        if (result.includes('No approver')) {
                            this.handletoastEvent(result, this.toastTitle.ERROR, this.toastvariant.ERROR);
                        } else {
                            this.handletoastEvent(this.toastMessages.result, this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
                            window.location.reload();
                        }
                    } else {
                        console.log('errror--- in submitLoanForApproval');
                    }
                })
                .catch((error) => {
                    this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                });
        } else if (this.selectedAction == 'Approv' || this.selectedAction == 'Reject' || this.selectedAction == 'Send Back') {
            console.log('HK technicalID-', this.recordId);
            console.log('HK remarks-', this.remarks);
            console.log('HK selectedAction-', this.selectedAction);
            performApprovalAction({ technicalId: this.recordId, action: this.selectedAction, remarks: this.remarks })
                .then((result) => {
                    console.log('HK Apex result:', JSON.stringify(result));
                    if (result) {
                        console.log('result in performApprovalAction::::', result);
                        if (result[0] == 'success') {
                            if (this.selectedAction == 'Approv') {
                                console.log('at 216--');
                                this.handletoastEvent(this.toastMessages.Loan_Approved, this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
                            } else if (this.selectedAction == 'Reject') {
                                console.log('at 224--');
                                this.handletoastEvent(this.toastMessages.Loan_Rejected, this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
                            }
                            else {
                                console.log('at 228--');
                                this.handletoastEvent(this.toastMessages.Loan_SentBack, this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
                            }
                            window.location.reload();
                        }
                        else if (result[0] == 'fail') {
                            this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                        }
                        else {
                            console.error('Error performing action:', JSON.stringify(result));
                        }

                    } else {
                        console.log('errror--- in performApprovalAction');
                    }
                })
                .catch((error) => {
                    console.log('errror--- in performApprovalAction', error);
                    this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                    this.showRemarksModal = false;
                });
        } else if (this.selectedAction == 'IniReject') {
            const fields = {};
            fields['Id'] = this.recordId;
            fields['HL_Stage__c'] = 'Rejected';
            fields['HL_Remarks__c'] = this.remarkss;

            const recordInput = { fields };
            console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
            updateRecord(recordInput)
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Record rejected!',
                            variant: 'success'
                        })
                    );
                    window.location.reload();
                })
                .catch(error => {
                    console.log('Error updating record --> ' + JSON.stringify(error));
                });
        }
        this.showRemarksModal = false;
    }

    handleOpenUploadModal() {
        this.isUploadModalOpen = true;
        this.fetchDocs();
    }

    handleCloseUploadModal() {
        this.isUploadModalOpen = false;
    }


    handleNewDocNameChange(e) {
        this.newDocName = e.target.value?.trim();
    }

    handleAddDocument() {
        if (!this.newDocName) return;
        createDocDetailForTechnical({
            techId: this.recordId,
            docName: this.newDocName,
            isRequired: false
        })
            .then(() => {
                this.newDocName = '';
                this.fetchDocs();
                this.showToast('Success', 'Document added.', 'success');
            })
            .catch(err => this.showError('Could not add document', err));
    }

    fetchDocs() {
        this.isLoadingDocs = true;

        getDocs({ techId: this.recordId })
            .then(rows => {
                this.docRows = (rows || []).map(r => {
                    /*
                    const requiredClass = r.required ? 'slds-badge slds-theme_success' : 'slds-badge';
                    const requiredLabel = r.required ? 'Required' : 'Optional';
                    const statusClass =
                    r.status === 'Uploaded' ? 'slds-badge slds-theme_success' :
                    r.status === 'Pending'  ? 'slds-badge' :
                                                'slds-badge slds-theme_warning';
                                                */
                    const hasFile = !!r.contentDocumentId;

                    return {
                        ...r,
                        showUpload: !hasFile,
                        showView: hasFile,
                        showDelete: false,
                        showRetake: hasFile,
                        requiredClass: r.required ? 'slds-badge slds-theme_success' : 'slds-badge',
                        requiredLabel: r.required ? 'Required' : 'Optional',
                        statusClass:
                            r.status === 'Uploaded' ? 'slds-badge slds-theme_success' :
                                r.status === 'Pending' ? 'slds-badge' : 'slds-badge slds-theme_warning',
                        showPreview: hasFile,
                        docDetailId: r.docDetailId,
                        documentName: r.documentName,
                        contentDocumentId: r.contentDocumentId,
                        fileType: (r.fileType || '').toUpperCase()
                    };
                });
            })
            .catch(err => this.showError('Error loading documents', err))
            .finally(() => { this.isLoadingDocs = false; });
    }


    handleUploadSuccess() {
        this.fetchDocs();
    }

    get documentList() {
        // Map server rows into widget props expected by your child
        return (this.docRows || []).map(r => ({
            id: r.docDetailId,
            name: r.documentName,
            docName: r.documentName,
            isRequired: !!r.required,
            titleClass: r.required ? 'doc-title required' : 'doc-title',
            contentId: r.contentDocumentId || null,
            showUpload: r.showUpload,
            showView: r.showView,
            showDelete: r.showDelete,
            showRetake: r.showRetake,
            showLatLong: false,
            lattitude: r.lattitude,
            longitude: r.longitude,
            fileType: r.fileType
        }));
    }

    getApprovalHistory() {
        getApprovalHistory({ technicalId: this.recordId })
            .then((result) => {
                if (result) {
                    console.log('result in getLoanApprovalDetails::::', result);
                    this.approvalData = result;
                    console.log('this.approvalData---', JSON.stringify(this.approvalData));
                } else {
                    console.log('errror--- in getApprovalHistory', error);
                }
            })
            .catch((error) => {
                console.log('errror--- in getApprovalHistory', error);
            });

    }

    handleEditAction() {
        this.showEditModal = true;
    }

    handleNo() {
        this.showEditModal = false;
    }

    handleProceed() {
        const fields = {};
        fields['Id'] = this.recordId;
        fields[STAGE_FIELD.fieldApiName] = 'Assigned to Technical Manager';
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                this.handletoastEvent(this.toastMessages.Technical_Stage_Change, this.toastTitle.SUCCESS, this.toastvariant.SUCCESS);
                this.showEditModal = false;
                window.location.reload();
            })
            .catch(error => {
                this.showEditModal = false;
                console.error('Error updating Stage :', error);
                this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
            })
    }
}