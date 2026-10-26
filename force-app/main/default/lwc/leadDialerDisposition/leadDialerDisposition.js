import { LightningElement, wire, api, track } from 'lwc';
import disposition from '@salesforce/schema/Lead.Dialer_Disposition__c';
import subDisposition from '@salesforce/schema/Lead.Dialer_Sub_Disposition__c';
import Lead_OBJECT from "@salesforce/schema/Lead";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import updateDialerHistory from '@salesforce/apex/LeadService.updateDialerHistory';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkpastDate from '@salesforce/apex/Comm_LeadManagementController.checkpastDate';

export default class LeadDialerDisposition extends LightningElement {
    @api recordId;
    @api count;

    dispositionOptions;
    selectedDisposition;
    selectSubdisposition;
    isLoading = false;
    remarks;
    showtime = false;
    today;
    dateOfFollowUp;
    timeOfFollowUp;
    timechanged;
    datechanged;
    selectedDateTime;
    subdispositionOptionsAll;

    @wire(getObjectInfo, { objectApiName: Lead_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: disposition })
    getDispositionValues({ data, error }) {
        if(data) {
            this.dispositionOptions = data.values;
            console.log('dispositionOptions:  '+this.dispositionOptions);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: subDisposition })
    getSubDispositionValues({ data, error }) {
        if(data) {
            this.subdispositionOptionsAll = data;
            console.log('subdispositionOptionsAll:  '+this.subdispositionOptionsAll);
        }
    }

    handleDispositionChange(event){
        console.log('selected disposition '+event.target.value);
        let key = this.subdispositionOptionsAll.controllerValues[event.target.value];
        this.subdispositionOptions = this.subdispositionOptionsAll.values.filter(opt => opt.validFor.includes(key));
        this.selectedDisposition = event.target.value;
        this.showtime = false;
    }

    handlesubDispositionChange(event){
        console.log('selected subdisposition: '+event.target.value);
        this.selectSubdisposition = event.target.value;
        
        if(this.selectSubdisposition != 'Follow up'){
            this.showtime = false;
        }
        else{
            this.showtime = true;
        }
    }

    handleRemarksChange(event){
        console.log('31 event '+event.target.value);
        this.remarks = event.target.value;
    }

    @api handleSave(){
        console.log('Selected Disposition:', this.selectedDisposition);
        console.log('Record ID:', this.recordId);
        console.log('Count:', this.count);

        this.isLoading = true;
        
        if(this.selectedDisposition == null) {
            this.showToast('error', 'Disposition is required', 'error');
            this.isLoading = false;
            return;
        }

        if(this.selectSubdisposition == null) {
            this.showToast('error', 'Sub Disposition is required', 'error');
            this.isLoading = false;
            return;
        }

        if(this.remarks == null) {
            this.showToast('error', 'Remarks is required', 'error');
            this.isLoading = false;
            return;
        }

        var dateTimeValue = null;
        if(this.selectSubdisposition == 'Follow up'){
            if(this.dateOfFollowUp && this.timeOfFollowUp){
                dateTimeValue = `${this.dateOfFollowUp}T${this.timeOfFollowUp}Z`;
            }

            if(dateTimeValue == null) {
                this.showToast('error', 'Follow up Date and Time is required', 'error');
                this.isLoading = false;
                return;
            }
        }

        updateDialerHistory({ leadId: this.recordId, count: this.count, disposition: this.selectedDisposition, subDisposition: this.selectSubdisposition, remarks: this.remarks, followUpDateTime: dateTimeValue })
        .then(result => {
            console.log('Update result:', result);
            
            this.isLoading = false;
            this.showToast('success', 'Disposition updated successfully', 'success');
            this.selectedDisposition = null;

            const valueCloseEvent = new CustomEvent('modalclose', {});
            this.dispatchEvent(valueCloseEvent);
        })
        .catch(error => {
            console.error('Error updating dialer history:', error);
            this.showToast('error', 'Failed to update Disposition', 'error');
            this.isLoading = false;
        });
    }

    handleFollowDateChange(event){
        this.datasaved = false;
        this.dateOfFollowUp = event.target.value;

        checkpastDate({ followUpDate: this.dateOfFollowUp})
        .then(result => {
            if(result){
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select a future date.',
                    variant: 'error'
                }));
                this.dateOfFollowUp = '';
            }

            if(this.dateOfFollowUp){
                this.datechanged = true;

                if(this.timeOfFollowUp && this.isFollowUpSaved){
                    this.timechanged = true;
                }
            }
            else{
                this.datechanged = false;
            }
        })
        .catch(error => {
            console.error('Error in validating Date: ', JSON.stringify(error));
            this.ShowLoader=false;
        });
    }

    handleFollowTimeChange(event){
        this.timeOfFollowUp = event.target.value;
        var todaysDate = new Date();
        let year = todaysDate.getFullYear();
        let month = String(todaysDate.getMonth() + 1).padStart(2, '0'); // January is 0!
        let day = String(todaysDate.getDate()).padStart(2, '0');

        var currentDate = `${year}-${month}-${day}`;
        
        var currentTime = todaysDate.getHours()+':'+todaysDate.getMinutes()+":"+ todaysDate.getSeconds();
        let parts = currentTime.split(':');

        // Ensure hours, minutes, and seconds are two digits with leading zeros if necessary
        let hours = ('0' + parts[0]).slice(-2);    
        let minutes = ('0' + parts[1]).slice(-2);  
        let seconds = ('0' + parts[2]).slice(-2);

        // Concatenate the padded values into the desired format
        let formattedTime = hours + ':' + minutes + ':' + seconds;

        if(this.dateOfFollowUp){
            if((this.dateOfFollowUp == currentDate)){
                if(this.timeOfFollowUp <= formattedTime){
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Please select a future time.',
                        variant: 'error'
                    }));

                    this.timeOfFollowUp = undefined;
                    this.timechanged = false;
                    return;
                }
            }
        }
        
        if(this.timeOfFollowUp){
            this.timechanged = true;

            if(this.dateOfFollowUp && this.isFollowUpSaved){
                this.datechanged = true;
            }
        }
        else{
            this.timechanged = false;
        }
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }
}