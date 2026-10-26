import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

// Object
import TECH_OBJECT from '@salesforce/schema/Technical_Evaluation__c';

// Fields
import DISTENCE_FIELD from '@salesforce/schema/Technical_Evaluation__c.Distance_from_Godrej_Branch_Base_Branc__c';
import NEAREST_RAILWAY_FIELD from '@salesforce/schema/Technical_Evaluation__c.Nearest_Railway_Station__c';
import NEARESTBUS_FIELD from '@salesforce/schema/Technical_Evaluation__c.Nearest_Bus_Stand__c';
import NEARESTHOSPITAL_FIELD from '@salesforce/schema/Technical_Evaluation__c.Nearest_Hospital__c';

const FIELDS = [
    DISTENCE_FIELD,
    NEAREST_RAILWAY_FIELD,
    NEARESTBUS_FIELD,
    NEARESTHOSPITAL_FIELD
];

export default class CustomNearestLocation extends LightningElement {

    @api recordId;

    // Values
    distenceFromGC;
    railwayStation;
    busStand;
    hospital;

    // Picklist options
    distOptions = [];
    railwayOptions = [];
    busOptions = [];
    hospitalOptions = [];

    recordTypeId;

    // 🔹 Get Object Info
    @wire(getObjectInfo, { objectApiName: TECH_OBJECT })
    objectInfo({ data }) {
        if (data) {
            this.recordTypeId = data.defaultRecordTypeId;
        }
    }

    // 🔹 Get Record Data
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.distenceFromGC = data.fields.Distance_from_Godrej_Branch_Base_Branc__c?.value;
            this.railwayStation = data.fields.Nearest_Railway_Station__c?.value;
            this.busStand = data.fields.Nearest_Bus_Stand__c?.value;
            this.hospital = data.fields.Nearest_Hospital__c?.value;
        } else if (error) {
            this.showToast('Error', 'Error loading record', 'error');
        }
    }

    // 🔹 Picklist Values

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: DISTENCE_FIELD
    })
    wiredDistance({ data }) {
        if (data) this.distOptions = data.values;
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: NEAREST_RAILWAY_FIELD
    })
    wiredRailway({ data }) {
        if (data) this.railwayOptions = data.values;
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: NEARESTBUS_FIELD
    })
    wiredBus({ data }) {
        if (data) this.busOptions = data.values;
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: NEARESTHOSPITAL_FIELD
    })
    wiredHospital({ data }) {
        if (data) this.hospitalOptions = data.values;
    }

    // 🔹 Handle Change + Auto Save
    handleChange(event) {
        const fieldName = event.target.dataset.field;
        const value = event.detail.value;

        // Update local variable
        const mappedField = fieldNameMap(fieldName);
        if (mappedField) {
            this[mappedField] = value;
        }

        const fields = {
            Id: this.recordId,
            [fieldName]: value
        };

        updateRecord({ fields })
            .then(() => {
                this.showToast('Success', 'Field updated', 'success');
            })
            .catch(error => {
                console.error(error);
                this.showToast('Error', 'Update failed', 'error');
            });
    }

    // 🔹 Toast
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}

// 🔹 Helper mapping
function fieldNameMap(apiName) {
    switch (apiName) {
        case 'Distance_from_Godrej_Branch_Base_Branc__c': return 'distenceFromGC';
        case 'Nearest_Railway_Station__c': return 'railwayStation';
        case 'Nearest_Bus_Stand__c': return 'busStand';
        case 'Nearest_Hospital__c': return 'hospital';
        default: return null;
    }
}