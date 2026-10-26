import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import fetchApplicants from '@salesforce/apex/HL_fetchApplicantsController.fetchApplicants';
import checkRecordStatus from '@salesforce/apex/HL_fetchApplicantsController.checkRecordStatus';
import insertApplicants from '@salesforce/apex/HL_fetchApplicantsController.insertApplicants';
import deleteApplicants from '@salesforce/apex/HL_fetchApplicantsController.deleteApplicants';
import permanentDeleteOwners from '@salesforce/apex/HL_fetchApplicantsController.permanentDeleteOwners';
import revertOwnerDeletionRequest from '@salesforce/apex/HL_fetchApplicantsController.revertOwnerDeletionRequest';
import isCreditManager from '@salesforce/apex/HL_fetchApplicantsController.isCreditManager';
import fetchCollateralOwners from '@salesforce/apex/HL_fetchApplicantsController.fetchCollateralOwners';
import getRecordTypeName from '@salesforce/apex/HL_fetchApplicantsController.getRecordTypeName';
export default class LegalShowApplicants extends LightningElement {

    @track applicants = [];
    @track preSelectedRows = [];
    @track applicantDetails = [];
    @api recordId;
    @track showManagerNotification = false;
    CurrentUserProfile;
    @track disableCheckboxFor = false;
    @track showTabs = true;

    get isCheckboxDisabled() {
        // Disable the checkbox if the user is NOT a manager
        // OR if there is only one owner
        return this.disableCheckboxFor || this.isSingleOwner;
    }

    connectedCallback() {
        // First fetch all applicants
        console.log('line 24-->>', this.recordId);
        this.fetchRecordType();
        this.fetchApplicants();
        this.checkRecordStatus();
        this.isCreditManager();
        this.fetchCollateralOwners();
    }

    fetchRecordType() {
        getRecordTypeName({ recordId: this.recordId })
            .then(recordTypeName => {
                // Check if the record type is one of the ones to hide
                if (recordTypeName === 'Legal Search Report' || recordTypeName === 'Legal Vetting Report') {
                    this.showTabs = false;
                } else {
                    this.showTabs = true;
                }
            })
            .catch(error => {
                console.error('Error fetching record type:', error);
                // Default to showing the tabs if an error occurs
                this.showTabs = true; 
            });
    }
    
    checkRecordStatus() {
        checkRecordStatus({
            recordId: this.recordId
        }).then(resp => {
            this.showManagerNotification = resp;
        }).catch(error => {

        })
    }
    isCreditManager() {
        isCreditManager({
            recordId: this.recordId
        }).then(resp => {
            this.disableCheckboxFor = !resp;
        }).catch(error => {

        })
    }
    fetchApplicants() {
        fetchApplicants({ recordId: this.recordId })
            .then(result => {
                this.applicantDetails = [...result];
                console.log('Applicants:', JSON.stringify(this.applicants));
                /*for (let i = 0; i < this.applicantDetails.length; i++) {
                    if (this.applicantDetails[i].applicantType == 'Primary Applicant') {
                        this.applicantDetails[i].applicantType = 'Borrower';
                    }
                    else if (this.applicantDetails[i].applicantType == 'Co-Applicant') {
                        this.applicantDetails[i].applicantType = 'Co-Borrower';
                    }
                }*/
            })
            .catch(error => {
                console.error('Error:', error);
            });
    }
    fetchCollateralOwners() {
        fetchCollateralOwners({
            recordId: this.recordId
        }).then(response => {
            console.log('Collateral Owners:', JSON.stringify(response));
            this.applicants = [...response];

            this.isSingleOwner = this.applicants.length === 1; // Check if length is exactly 1
            console.log('Is Single Owner:', this.isSingleOwner);

            for (let i = 0; i < this.applicants.length; i++) {
                if (this.applicants[i].applicantType == 'Primary Applicant') {
                    this.applicants[i].applicantType = 'Borrower';
                }
                else if (this.applicants[i].applicantType == 'Co-Applicant') {
                    this.applicants[i].applicantType = 'Co-Borrower';
                }
            }
        })
            .catch(error => {
                console.error('Error:', error);
            })
    }
    handleCheckboxChange(event) {
        if (event.target.checked) {
            insertApplicants({
                appId: event.target.dataset.id,
                recordId: this.recordId
            }).then(response => {
                //this.fetchApplicants();
                this.fetchCollateralOwners();
                this.checkRecordStatus();
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Owner selected successfu;ly.',
                    variant: 'success',
                }));
            }).catch(error => {

            })
        }
        else {
            deleteApplicants({
                appId: event.target.dataset.id,
                recordId: this.recordId
            }).then(response => {
                //this.fetchApplicants();
                this.fetchCollateralOwners();
                this.checkRecordStatus();
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Owner deselected successfully.',
                    variant: 'success',
                }));
            }).catch(error => {

            })
        }
    }
    handleAccept() {
        permanentDeleteOwners({
            recordId: this.recordId
        }).then(response => {
            // this.fetchApplicants();
            this.fetchCollateralOwners();
            this.checkRecordStatus();
            this.isCreditManager();
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Owner deleted successfully.',
                variant: 'success',
            }));
        }).catch(error => {

        })
    }
    handleReject() {
        revertOwnerDeletionRequest({
            recordId: this.recordId
        }).then(response => {
            //this.fetchApplicants();
            this.fetchCollateralOwners();
            this.checkRecordStatus();
            this.isCreditManager();
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Owner deletion rejected.',
                variant: 'success',
            }));
        }).catch(error => {

        })
    }
}