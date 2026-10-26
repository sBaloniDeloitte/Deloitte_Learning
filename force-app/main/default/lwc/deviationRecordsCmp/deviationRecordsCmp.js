import { LightningElement,track,api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from "lightning/navigation";
import FORM_FACTOR from '@salesforce/client/formFactor';
import getDevationsDetails from "@salesforce/apex/DeviationRecordPageController.getDevationsDetails"
import deleteDeviation from '@salesforce/apex/DeviationRecordPageController.deleteDeviation';
import removeMitigants from '@salesforce/apex/DeviationRecordPageController.removeMitigants';
import updateRemarksOnDeviation from '@salesforce/apex/DeviationRecordPageController.updateRemarksOnDeviation';
import changeApprovalStatus from '@salesforce/apex/DeviationRecordPageController.changeApprovalStatus';
import STAGENAME_FIELD from "@salesforce/schema/Opportunity.StageName";
import OWNERID_FIELD from "@salesforce/schema/Opportunity.OwnerId";
import USER_ID from "@salesforce/user/Id";
import ProfileName from '@salesforce/schema/User.Profile.Name';
import { getRecord } from "lightning/uiRecordApi";
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
import PROFILE_LEVEL_DISABLITY from '@salesforce/label/c.Profile_Level_Disablity'; // for disabling label wise
import SUB_STAGE_LEVEL_DISABLITY from '@salesforce/label/c.Sub_Stage_Level_Disability'; // for disabling label wise

export default class DeviationRecordsCmp extends NavigationMixin(LightningElement){
    @track deviationTable={};
    @api recordId;
    @track small = false;
    @track showTable;
    @api fromMainScreen = false;
    @track deletemitigantId;
    selectedMitigants = [];
    userProfile;
    oppSubStage;
    hideAction = false;

    @api hasPsvOrDisbursalStage = false;
    
    @api changeMessage(str) {
        this.getDevationsDetails();
    }

    toastvariant = {
        SUCCESS : 'success',
        ERROR : 'error'
    }
    toastTitle = {
        SUCCESS : 'Success',
        ERROR : 'Error'
    }

    toastMessages = {
        DELETE_DEVIATION_SUCESS_MESSAGE : 'Deviation deleted Successfully.',
        DELETE_DEVIATION_FAILURE_MESSAGE : 'Unable to delete the Deviation.',
        DEVIATION_ADDED_SUCCESSFULLY : 'Deviation added Successfully.',
        SOMETHING_WENT_WRONG : 'Something went wrong.',
        NoMitigants : 'Please select atleast one mitigant.',
    }

    hideButton = false;
    userProfile = '';

    checkCmpEditability() {
    getComponentEditability({ loanId : this.recordId, component : 'bsaSelectBankCmp' })
    .then(result => {
        if(result){
            //this.isNotEditable = result;
            this.hideButton = result;
            this.hideDeleteButton = result;
             this.isDisableEdit = result;
           // this.editability = result;
        }
    })
    .catch(error => {
        console.log('Error getComponentEditability:  '+error);
    });
  }

    @wire(getRecord, { recordId: USER_ID, fields: [ProfileName] })
    userDetails({ error, data }) {
        if(data) {
            this.userProfile = data.fields.Profile.value.fields.Name.value;
        }
    }

    @wire(getRecord, { recordId: "$recordId", fields: [SUBSTAGE_FIELD,STAGENAME_FIELD,OWNERID_FIELD]})
    opportunity({ error, data }) {
        if(data) {
            this.oppSubStage = data.fields.Sub_stage__c.value;
            var StageName = data.fields.StageName.value;
            var OwnerId = data.fields.OwnerId.value;

            if(StageName === 'Credit Underwriting'){
                console.log('this.userProfile: '+this.userProfile);
                if(this.userProfile != 'System Administrator' && OwnerId != USER_ID){
                    this.hideButton = true;
                    this.hasPsvOrDisbursalStage = true;
                }
            }
            if(!this.hideButton){
              this.setEditability();
            }
        }
    }

    connectedCallback(){
        this.checkCmpEditability();
        this.getDevationsDetails();
        if(FORM_FACTOR == 'Small'){
            this.small = true;
        }
    }
    setEditability() {
        const disabledProfiles = PROFILE_LEVEL_DISABLITY.split(';').map(p => p.trim());
        const disabledSubStage = SUB_STAGE_LEVEL_DISABLITY.split(';').map(s => s.trim());
        if (disabledProfiles.includes(this.userProfile) || disabledSubStage.includes(this.oppSubStage)) {
            this.hideAction = true;
        }
    }


        getDevationsDetails() {
            getDevationsDetails({ recordId: this.recordId })
                .then(response => {
                    if (response) {
                        console.log('getDevationsDetails response : '+JSON.stringify(response));
                        
                        // Convert mitigants string into an array for each item
                        this.deviationTable = response.map(item => ({
                            ...item,
                            mitigantsArray: item.mitigants ? item.mitigants.split(',').map(m => m.trim()) : [],
                            showRemarks: false,
                            showMitigants:false
                        }));
                        this.showTable = true;
                    } else {
                        this.showTable = false;
                    }
                })
                .catch(error => {
                    console.error('getDevationsDetails error : '+JSON.stringify(error));
                    this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
                });
        }
        get createdRecordsVisibility(){
            return this.deviationTable.length>0;
        }
        
    deleteDeviation(event){
        deleteDeviation({
            devId:event.target.dataset.id
        }).then(response=>{
            this.getDevationsDetails();
            this.handletoastEvent(this.toastMessages.DELETE_DEVIATION_SUCESS_MESSAGE,this.toastTitle.SUCCESS,this.toastvariant.SUCCESS);
        }).catch(error=>{
            this.handletoastEvent(this.toastMessages.DELETE_DEVIATION_FAILURE_MESSAGE,this.toastTitle.ERROR,this.toastvariant.ERROR);
        })
    }

    handleOpenDeviations(event){
        window.open('/'+event.target.dataset.id);
    }

    handletoastEvent(msg,title,variant){
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
        }));
    }
    handleCheckboxChange(event) {
        const mitigantName = event.target.dataset.name; // Get the mitigant name
        console.log('mitigantName '+mitigantName);
        // this.deletemitigantId = event.target.dataset.id;
        const isChecked = event.target.checked; // Check if it's selected or not
        if (!isChecked) {
            // Add the mitigant to the array if it's selected
            if (!this.selectedMitigants.includes(mitigantName)) {
                this.selectedMitigants.push(mitigantName);
                console.log(`Mitigant Selected: ${mitigantName}`);
                //this.handletoastEvent(`Selected: ${mitigantName}`, 'Success', 'success');
                // this.deleteMitigants();
            }
        } else {
            // Remove the mitigant from the array if it's unselected
            const index = this.selectedMitigants.indexOf(mitigantName);
            if (index > -1) {
                this.selectedMitigants.splice(index, 1);
                console.log(`Mitigant Unselected: ${mitigantName}`);
                //this.handletoastEvent(`Unselected: ${mitigantName}`, 'Warning', 'warning');
            }
        }
        // Log the current list of selected mitigants
        console.log('Selected Mitigants:', this.selectedMitigants);
    }
    deleteMitigants(event){
        if (this.selectedMitigants.length === 0) {
            console.log("No mitigants selected");
            this.handletoastEvent(this.toastMessages.NoMitigants,this.toastTitle.ERROR,this.toastvariant.ERROR);
            // You can display a message or perform other actions if no mitigants are selected
        } else {
            console.log("Selected mitigants:", this.selectedMitigants);
            console.log('Id '+Id);
            removeMitigants({ recordId: this.deletemitigantId , mitigantsToRemove:this.selectedMitigants})
            .then(response => {
                console.log('response '+response);
                this.connectedCallback();
            })
            // Handle the case where there are selected mitigants
        }
    }

    handleEditClick(event){
        console.log('Inside handleEditClick');
        console.log('Inside handleEditClick event---', event.target.dataset.id);
        console.log('Inside handleEditClick event name---', event.target.name);
        const fieldName= event.target.name;
        var recordValue = this.deviationTable;
        recordValue.forEach(record => {
            console.log('item.id---', record.id);
            
            if(record.id == event.target.dataset.id){
                console.log('record -->'+JSON.stringify(record));
                if(fieldName== 'remarks'){
                    record.showRemarks = true;
                }else if(fieldName== 'mitigants'){
                    record.showMitigants = true;
                }
            }
        });
    }

    handleSaveRowValue(event){
        console.log('Inside handleSaveRowValue');
        console.log('Inside handleSaveRowValue event---', event.target.dataset.id);
        console.log('Inside handleSaveRowValue event field---', event.target.name);
        console.log('Inside handleSaveRowValue event value---', event.target.value);
        if (!event.target.value || !event.target.value.trim()) {
            this.handletoastEvent(
                'Mitigants is required',
                'Error',
                'error'
            );
            return;
        }
        updateRemarksOnDeviation({ recordId: event.target.dataset.id , remarks: event.target.value, field: event.target.name})
        .then(response => {
            // console.log('response '+response);
            this.connectedCallback();
        })
        .catch(error => {
            console.log('error in updateRemarksOnDeviation '+error);
        })

    }
    approveDeviation(event){
        console.log('Inside approveDeviation');
        this.selectedDeviationId = event.target.dataset.id;
        console.log('this.selectedDeviationId: '+this.selectedDeviationId);
        changeApprovalStatus({ recordId: this.recordId , approvalStatus: 'Approved', deviationId: this.selectedDeviationId})
        .then(response => {
            const approvalUpdationStatus = response;
            console.log('response approveDeviation: '+approvalUpdationStatus);
            if(approvalUpdationStatus == 'Success') {
                this.getDevationsDetails();
                this.handletoastEvent('Deviation approved successfully', 'Approved !', 'success');
            } else {
                this.handletoastEvent(approvalUpdationStatus, 'Invalid Input !', 'error');
            }
        })
        .catch(error => {
            console.log('error in approveDeviation: '+error);
        })
    }
    rejectDeviation(event){
        console.log('Inside rejectDeviation');
        this.selectedDeviationId = event.target.dataset.id;
        console.log('this.selectedDeviationId: '+this.selectedDeviationId);
        /* changeApprovalStatus({ recordId: this.recordId, approvalStatus: 'Rejected', deviationId: this.selectedDeviationId})
        .then(response => {
            console.log('response rejectDeviation: '+response);
            this.getDevationsDetails();
            this.handletoastEvent('Deviation rejected successfully', 'Rejected !', 'success');
        })
        .catch(error => {
            console.log('error in rejectDeviation: '+error);
        }) */
        changeApprovalStatus({ recordId: this.recordId , approvalStatus: 'Rejected', deviationId: this.selectedDeviationId})
        .then(response => {
            const approvalUpdationStatus = response;
            console.log('response approveDeviation: '+approvalUpdationStatus);
            if(approvalUpdationStatus == 'Success') {
                this.getDevationsDetails();
                this.handletoastEvent('Deviation rejected successfully', 'Approved !', 'success');
            } else {
                this.handletoastEvent(approvalUpdationStatus, 'Invalid Input !', 'error');
            }
        })
        .catch(error => {
            console.log('error in approveDeviation: '+error);
        })
    }
    @api handleValueChange() {
        this.getDevationsDetails();
      }
}