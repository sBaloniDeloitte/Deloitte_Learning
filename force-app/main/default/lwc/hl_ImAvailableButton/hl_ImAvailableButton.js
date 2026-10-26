import { LightningElement, track,wire,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import markUserAvailable from '@salesforce/apex/HL_AvailabilityController.markUserAvailable';

import Id from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import I_AM_AVAILABLE from '@salesforce/schema/User.I_am_available_today__c';


const FIELDS = [I_AM_AVAILABLE];


export default class ImAvailableButton extends LightningElement {
    @track isLoading = false; // Controls the spinner
    @track isUnavailable = false; // Controls the button/message visibility
    @api recordId;
    userId = Id;
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredUser({ data, error }) {
        if (data) {
            this.isUnavailable = !(data.fields.I_am_available_today__c.value);
            console.log('this.isUnavailable>>>'+this.isUnavailable);
        } else if (error) {
            console.log('Error fetching user availability: '+JSON.stringify(error));
        }
    }



    // Function runs when the button is clicked
    handleAvailableClick() {
        this.isLoading = true;

        // Call the Apex method we created in Part 1
        markUserAvailable({
            currentUserId: this.recordId
        })
            .then(() => {
                // Success!
                this.isUnavailable = true; // This hides the button and shows the success message
                this.isLoading = false;
            })
            .catch(error => {
                // Error!
                this.isLoading = false;
                // Show a popup error message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating status',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
}