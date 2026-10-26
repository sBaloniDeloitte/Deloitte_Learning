import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Fields
import ZONE_FIELD from '@salesforce/schema/Technical_Evaluation__c.ZONE_NO__c';
import SUB_REG_FIELD from '@salesforce/schema/Technical_Evaluation__c.SUB_REGISTRAR_OFFICE__c';
import DLC_FIELD from '@salesforce/schema/Technical_Evaluation__c.DLC_RATE__c';
import LOCATION_FIELD from '@salesforce/schema/Technical_Evaluation__c.Location_Name__c';

const FIELDS = [ZONE_FIELD, SUB_REG_FIELD, DLC_FIELD, LOCATION_FIELD];

export default class CustomPropertyDetails extends LightningElement {

    @api recordId;

    zoneNo;
    subRegistrarOffice;
    dlcRate;
    locationName;

    // 🔹 Load data (onload)
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.zoneNo = data.fields.ZONE_NO__c?.value;
            this.subRegistrarOffice = data.fields.SUB_REGISTRAR_OFFICE__c?.value;
            this.dlcRate = data.fields.DLC_RATE__c?.value;
            this.locationName = data.fields.Location_Name__c?.value;
        } else if (error) {
            this.showToast('Error', 'Error loading record', 'error');
        }
    }

    // 🔹 Handle change + auto save
    handleChange(event) {
        const fieldName = event.target.dataset.field;
        const value = event.target.value;

        // Update local variable
        this[fieldNameMap(fieldName)] = value;

        const fields = {};
        fields['Id'] = this.recordId;
        fields[fieldName] = value;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.showToast('Success', 'Field updated', 'success');
            })
            .catch(error => {
                console.log('error>>>>>',error);
                this.showToast('Error', 'Update failed', 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}

// 🔹 Helper function to map API → variable
function fieldNameMap(apiName) {
    switch(apiName) {
        case 'ZONE_NO__c': return 'zoneNo';
        case 'SUB_REGISTRAR_OFFICE__c': return 'subRegistrarOffice';
        case 'DLC_RATE__c': return 'dlcRate';
        case 'Location_Name__c': return 'locationName';
        default: return null;
    }
}