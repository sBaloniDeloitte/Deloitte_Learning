import { api, LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord,updateRecord } from "lightning/uiRecordApi";
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import fcusamplingConfirm from '@salesforce/label/c.FCU_sampling_confirm'; 
import ProfileName from '@salesforce/schema/User.Profile.Name';
import Name from '@salesforce/schema/User.Name';
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id'; 
import getApplicantsDetailsListForSampling from '@salesforce/apex/FCUController.getApplicantsDetailsListForSampling';
//import sendNotificationToSamplerAddr from '@salesforce/apex/FCURecordPageController.sendNotificationToSamplerAddr';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName1';

export default class FcuProfileSampling extends LightningElement {
    @api recordId;

    @track modalVisibility = false;
    @track spinnerRun = true;

    @track profileDatas = [];

    @wire(CurrentPageReference) pageRef;

    @track showgenericConfirm = false;

    @track negativelabel = 'No';
    @track positiveLabel = 'Yes';
    @track confirmMessage = fcusamplingConfirm;

    selectedId = '';
    remarks
    isRemarkScreen = false;
    @track currentProfileName;
    @track currentUserName;
    @api fromCredit = false;
    username;
    @wire(getRecord, { recordId: Id, fields: [Name] })
    wiredUser({ data, error }) {
        if (data) {
            this.username = data.fields.Name.value;
            console.log('user id -->',Id);
            console.log('Username-->',this.username);
        } else if (error) {
            console.error('Error fetching user data', error);
        }
    }
    connectedCallback(){
        this.modalVisibility = true;

        this.getData();
        registerListener("inititedFCUrefreshdata",this.getData, this);
    }

    disconnectedCallback() { 
        unregisterAllListeners(this); 
    }

    @wire(getCurrentUserProfileName)
    wiredProfile({ error, data }) {
        if (error) {
            this.error = error;  // Handle error if any
        } else if (data) {
            this.currentProfileName = data;  // Store the profile name returned by Apex
            console.log('profile',this.currentProfileName);
            // Set the profile flags based on the profile name
            if (this.currentProfileName === 'Admin') {
                this.profile.Admin = true;
            } else if (this.currentProfileName === 'Sampler') {
                this.profile.Sampler = true;
            } /*else if (this.currentProfileName === 'FCU Admin') {
                this.profile.FCU_Admin = true;
            } else if (this.currentProfileName === 'FCU Executive') {
                this.profile.FCU_Executive = true;
            }*/
        }
    }
    getData(){
        getApplicantsDetailsListForSampling({
            recordId: this.recordId,
            fromCredit: this.fromCredit
        }).then(response=>{
            this.profileDatas = response;
            this.spinnerRun = false;
            console.log(`The getApplicantsDetailsListForSampling are: ${JSON.stringify(response)}`)
        }).catch(error=>{
            console.error('Error getApplicantsDetailsListForSampling -->' + JSON.stringify(error));
        });
    }

    updateRecordField(recordId, fieldApiName, fieldValue) {
        const fields = {};
        fields['Id'] = recordId;
        fields[fieldApiName] = fieldValue;
        if(this.remarks){
            const now = new Date();
            const formattedDate = now.getFullYear() + '-' +
                      String(now.getMonth() + 1).padStart(2, '0') + '-' +
                      String(now.getDate()).padStart(2, '0') + 'T' +
                      String(now.getHours()).padStart(2, '0') + ':' +
                      String(now.getMinutes()).padStart(2, '0');
            if(this.currentProfileName == 'Sampler'){
                fields['Remarks__c'] = this.remarks+'-'+this.username+'-'+formattedDate;
                fields['Referred_By__c'] =Id;
                fields['Referred_By_Role__c'] = 'Sampler';
                
            }
            else{
                fields['Remarks__c'] = this.remarks+'-'+this.username+'-'+formattedDate;
                fields['Referred_By__c'] = Id;
                fields['Referred_By_Role__c'] = 'Credit';
                
            }
        }
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                this.showToastMessage('Success', 'Status updated successfully!', 'success');
                this.getData();

                fireEvent(this.pageRef, "changescreeningstatus", "changescreeningstatus");
                const valueCloseEvent = new CustomEvent('changescreeningstatus', {});
                this.dispatchEvent(valueCloseEvent);
            })
            .catch(error => {
                console.log('Error updating record --> '+JSON.stringify(error));
            });
    }

    handleselectionChange(event){
        this.selectedId = event.target.dataset.id;
        if(event.target.checked){  
            this.isRemarkScreen = true;
            // this.updateRecordField(this.selectedId, 'Screening_Status__c', 'Added to sampling queue');
        }else{
            this.modalVisibility = false;
            this.showgenericConfirm = true;
        }
    }
    cancelRemark(){
        const checkbox = this.template.querySelector(`lightning-input[data-id="${this.selectedId}"]`);
        if (checkbox) {
            checkbox.checked = false;
        }
        this.isRemarkScreen = false;
    }

    handleRemark(){
        if(this.remarks == undefined || this.remarks == null || this.remarks ==''){
            this.showToastMessage('Error', 'Please fill the remarks in order to proceed.', 'Error');
        }
        else{
            this.isRemarkScreen = false;
            console.log(`The Value is ${this.remarks}`);
            console.log('Selectedid is -->',this.selectedId);
            if(this.currentProfileName == 'Credit Manager' || this.currentProfileName == 'System Administrator'){
                this.updateRecordField(this.selectedId, 'Screening_Status__c', 'Recommended For FCU');
                this.sendNotificationToSamplerAddr();
            }
            else{
                this.updateRecordField(this.selectedId, 'Screening_Status__c', 'Added to sampling queue');
            }
            
        }
    }
    sendNotificationToSamplerAddr(){
        sendNotificationToSamplerAddr({
            loanId:this.recordId,
            addrId:this.selectedId
        }).then(resp=>{

        }).catch(error=>{

        })
    }
    handleRemarkChanges(evt){
        this.remarks = evt.target.value;
    }

    handleNegative(){
        this.modalVisibility = true;
        this.showgenericConfirm = false;
    }

    handlePositive(){
        setTimeout(() => {
            this.updateRecordField(this.selectedId, 'Screening_Status__c', 'Pending');
        }, 800);
        setTimeout(() => {
            this.remarks = null;
            this.updateRecordField(this.selectedId, 'Remarks__c', '');
        }, 400);

        this.handleNegative();
    }

    showToastMessage(title, message, type) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: type
        });
        this.dispatchEvent(toastEvent);
    }
}