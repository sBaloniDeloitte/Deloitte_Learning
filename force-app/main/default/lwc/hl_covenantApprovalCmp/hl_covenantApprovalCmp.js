import { LightningElement, api, track } from 'lwc';
import getCreditATMs from '@salesforce/apex/HL_CovenantApprovalController.getCreditATMs';
import sendForApproval from '@salesforce/apex/HL_CovenantApprovalController.sendForApproval';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Hl_covenantApprovalCmp extends LightningElement {
    @api recordId;
    isLoading = false;
    @track showOptions = false;
    @track isConfirm = false;
    @track approverOptions;
    @api isModalOpen = false;
    @api documentDetailsRecords = [];
    @api fromDocument = false;
    @api fromSanction = false;
    @track approver;
    @track docIds;
    
    connectedCallback(){
        this.isModalOpen = true;
        console.log(' in connectedCallback----', this.recordId + ' ::::: ' + [...this.documentDetailsRecords] + ' ::::: ' + this.fromDocument + ' ::::: ' + this.fromSanction);
        console.log(' in connectedCallback--isModalOpen--', this.isModalOpen);
        this.docIds = Array.isArray(this.documentDetailsRecords)
                        ? this.documentDetailsRecords
                        : Array.from(this.documentDetailsRecords || []);
        this.getCreditApprovers();
    }

    getCreditApprovers(){
        console.log(' in getCreditApprovers----', this.recordId);
        console.log('in getCreditApprovers ::: this.approver---', this.approver);
        getCreditATMs({
            opportunityId : this.recordId
        }).then(response=>{
            console.log('response in getCreditApprovers--', response);
            let options = [];
            if(response != undefined){
                for (var key in response) {
                    console.log('key --' + key);
                    options.push({ label: response[key], value: key });
                }
                this.approverOptions = options;
                this.showOptions = true;

            }
        }).catch(error=>{
                console.log('Error in getCreditApprovers----' +  JSON.stringify(error));
                this.showToast('Error', error.body.message, 'error');
        })
    }

    handleApproverChange(event){
        this.approver = event.target.value;
        console.log('handleApproverChange :: this.approver:: ' + this.approver);
    }

    handleNext(){
        console.log('In handleNext:: this.approver is:: '+ this.approver);
        this.isConfirm = (this.approver && this.approver.trim() !== '');
        this.showOptions = false;
        console.log('IN handleNext:: this.isConfirm:: '+ this.isConfirm);
        console.log('IN handleNext:: this.showOptions:: '+ this.showOptions);
        
    }

    handleApprovalYes() {
        console.log('recordId in handleApprovalYes ---' + this.docIds + ' :: ' + this.approver);
        console.log('recordId in handleApprovalYes ---' + this.fromDocument + ' ::::: ' + this.fromSanction);
        console.log('Sending to Apex -> Approver:', this.approver, 'Docs:', JSON.stringify(this.docIds));
        if(this.approver == '' || this.approver == undefined){
            this.showToast('Error', 'Please select the approver first.' , 'error');
            return;
        }

        //if (this.isLoading) return;
        this.isLoading = true;

        sendForApproval({ approver: this.approver, opportunityId: this.recordId, documentDetailsRecords: this.docIds, fromDocument: this.fromDocument, fromSanction: this.fromSanction})
            .then(() => {
                this.showToast(
                    'Success',
                    'Covenant Send for approval to Credit Manager.',
                    'success'
                );
                this.closeModal();
            })
            .catch(error => {
                console.error('error while sending Approval:', JSON.stringify(error));
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

    handleCancel() {
        this.closeModal();
    }

    closeModal() {
        this.isModalOpen = false;
        this.dispatchEvent(new CustomEvent('close'));
    }

    showToast(title, msg, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message: msg, variant })
        );
    }
}