import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// import DISPOSITION_FIELD from '@salesforce/schema/Lead.Disposition__c';
// import EVENT_DATETIME_FIELD from '@salesforce/schema/Lead.Event_Date_Time__c';

const FOLLOW_UP_VALUE = 'Follow-up Required';

const FIELDS = [
    DISPOSITION_FIELD,
    EVENT_DATETIME_FIELD
];

export default class Disposition extends LightningElement {

    @api recordId;

    dispositionValue = '';
    savedEventDateTime;

    followUpDate;
    followUpTime;

    isSaved = false;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: FIELDS
    })
    wiredRecord({ data, error }) {

        if (data) {

            // this.dispositionValue =
            //     getFieldValue(data, DISPOSITION_FIELD) || '';

            // this.savedEventDateTime =
            //     getFieldValue(data, EVENT_DATETIME_FIELD);

            if (this.savedEventDateTime) {

                const dt = new Date(this.savedEventDateTime);

                this.followUpDate =
                    dt.toISOString().split('T')[0];

                this.followUpTime =
                    dt.toLocaleTimeString('en-GB', {
                        hour: '2-digit',
                        minute: '2-digit',
                        hour12: false
                    }).substring(0, 5);
            }

        } else if (error) {
            console.error(error);
        }
    }

    handleDispositionChange(event) {

        this.dispositionValue = event.detail.value;

        this.isSaved = false;
    }

    handleDateChange(event) {
        this.followUpDate = event.target.value;
    }

    handleTimeChange(event) {
        this.followUpTime = event.target.value.substring(0, 5);
    }

    handleSubmit(event) {

        event.preventDefault();

        const fields = event.detail.fields;

        if (this.dispositionValue === FOLLOW_UP_VALUE) {

            if (!this.followUpDate || !this.followUpTime) {

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please select date and time.',
                        variant: 'error'
                    })
                );

                return;
            }

            const selectedDate =
                new Date(
                    `${this.followUpDate}T${this.followUpTime}:00`
                );

            if (selectedDate <= new Date()) {

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Only future follow up allowed.',
                        variant: 'error'
                    })
                );

                return;
            }

            fields.Event_Date_Time__c =
                selectedDate.toISOString();
        }

        this.template
            .querySelector('lightning-record-edit-form')
            .submit(fields);
    }

    handleSuccess() {

        if (
            this.followUpDate &&
            this.followUpTime
        ) {

            this.savedEventDateTime =
                new Date(
                    `${this.followUpDate}T${this.followUpTime}:00`
                ).toISOString();
        }

        this.isSaved = true;

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Disposition updated successfully.',
                variant: 'success'
            })
        );
    }

    handleError(event) {

        console.error(event);

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message:
                    event?.detail?.message ||
                    'Unable to save record.',
                variant: 'error'
            })
        );
    }

    handleEditClick() {
        this.isSaved = false;
    }

    get showEventDateTime() {

        return (
            this.dispositionValue === FOLLOW_UP_VALUE &&
            !this.isSaved
        );
    }

    get showSavedConfirmation() {

        return (
            this.dispositionValue === FOLLOW_UP_VALUE &&
            this.isSaved &&
            this.savedEventDateTime
        );
    }

    get showSaveButton() {

        return !this.isSaved;
    }
}