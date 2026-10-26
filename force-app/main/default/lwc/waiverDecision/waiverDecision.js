import { LightningElement, api, track, wire } from 'lwc';
import handleDecision from '@salesforce/apex/WaiverController.handleWaiverAction';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getUserHierarchy from '@salesforce/apex/WaiverController.getUserHierarchy';
import getLoggedInUser from '@salesforce/apex/WaiverController.getLoggedInUser';
// import saveWaiver from '@salesforce/apex/WaiverController.saveWaiver';

export default class WaiverDecision extends LightningElement {
    @api waivers = [];
    @track activeTab = 'approve';
    @track remarks = '';
    @track selectedWaiverStatus = '';
    selectedWaiverRequestedBy;
    selectedWaiverRequestedFrom;
    // selectedWaiverRequestedFromReassign;
    @api recordId;

    waiverFrom;
    waiverFromOptions;

    connectedCallback() {
        this.loadUserDetails();
    }

    async loadUserDetails() {
        try {
            const user = await getLoggedInUser();
            this.loggedinUserFullName = user.Name;
            const hierarchyUsers = await getUserHierarchy({ requestedBy: this.loggedinUserFullName, loanAppId: this.recordId });
            this.waiverFromOptions = hierarchyUsers.map(u => ({ label: u, value: u }));
            
        } catch (error) {
            console.error('Error loading user hierarchy:', error);
        }
    }

    handleView(event) {
        const waiverId = event.target.dataset.id;
        const selectedWaiver = this.waivers.find(w => w.Id === waiverId);
        this.selectedWaiverStatus = selectedWaiver?.Status__c || '';

        this.selectedWaiverRequestedBy = selectedWaiver?.Waiver_Requested_By__c;
        this.selectedWaiverRequestedFrom = selectedWaiver?.Waiver_Requested_From__c;

        this.waivers = this.waivers.map(w => ({
            ...w,
            isSelected: w.Id === waiverId ? !w.isSelected : false,
            detailKey: `${w.Id}_details`
        }));
    }

    handleTabClick(event) {
        this.activeTab = event.target.dataset.tab;
    }

    handleRemarksChange(event) {
        this.remarks = event.target.value;
    }

    async handleApprove() {
        const waiver = this.waivers.find(w => w.isSelected);
        if (waiver) await this.updateWaiver(waiver.Id, 'approve', this.remarks);
    }

    async handleReject() {
        const waiver = this.waivers.find(w => w.isSelected);
        if (waiver) await this.updateWaiver(waiver.Id, 'reject', this.remarks);
    }

    async handleChange(event) {
        const field = event.target.name;
        this[field] = event.target.value;
        console.log('OUTPUT : ',event.target.name,event.target.value);
    }

    async handleSubmit() {
        const waiver = this.waivers.find(w => w.isSelected);
        if (waiver) await this.updateWaiver(waiver.Id, 'submit', this.waiverFrom);
    }

    async updateWaiver(waiverId, action, remarks) {
        try {
            await handleDecision({ waiverId, actionType: action, remarks });
            this.showToast('Success', `Waiver ${action}ed successfully`, 'success');

            this.waivers = this.waivers.map(w =>
                w.Id === waiverId
                    ? { ...w, Waiver_Requested_From__c : action == 'submit' ? this.waiverFrom : w.Waiver_Requested_From__c, Status__c: this.getStatusLabel(action), isSelected: false }
                    : w
            );
        } catch (error) {
            this.showToast('Error', error.body?.message || 'An error occurred', 'error');
        }
    }

    getStatusLabel(action) {
        switch (action) {
            case 'approve': return 'Approved';
            case 'reject': return 'Rejected';
            case 'submit': return 'Submit for Approval';
            default: return '';
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

    get approveTabClass() {
        return this.activeTab === 'approve' ? 'tab active' : 'tab';
    }
    get rejectTabClass() {
        return this.activeTab === 'reject' ? 'tab active' : 'tab';
    }
    get submitTabClass() {
        return this.activeTab === 'submit' ? 'tab active' : 'tab';
    }

    get isApproveTab() {
        return this.activeTab === 'approve';
    }
    get isRejectTab() {
        return this.activeTab === 'reject';
    }
    get isSubmitTab() {
        return this.activeTab === 'submit';
    }

    // get showSubmitTab() {
    //    return this.selectedWaiverStatus === 'Submitted';
    // }

    get showSubmitTab() {
       return this.selectedWaiverRequestedFrom !== this.loggedinUserFullName || (this.selectedWaiverRequestedFrom == this.loggedinUserFullName && (
        this.selectedWaiverStatus !== 'Submitted' &&
        this.selectedWaiverStatus !== 'Submit For Approval'
        ));
    }

    get showApproveRejectTabs() {
        return this.selectedWaiverStatus === 'Submit For Approval';
    }


    get isSubmitDisabled() {
        return this.selectedWaiverRequestedFrom !== this.loggedinUserFullName || (this.selectedWaiverRequestedFrom == this.loggedinUserFullName && !this.isReadyToSubmitReassign);
    }

    get isReadyToSubmitReassign(){
        return (this.selectedWaiverStatus === 'Submitted' || this.selectedWaiverStatus === 'Submit For Approval') && this.waiverFrom;
    }

    get isAbleToReassign() {
        return this.selectedWaiverRequestedFrom === this.loggedinUserFullName && (this.selectedWaiverStatus === 'Submitted' || this.selectedWaiverStatus === 'Submit For Approval');
    }
}