import { LightningElement, api, wire, track } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TECH_DETAIL_OBJECT from '@salesforce/schema/Technical_Detail__c';
import PARENT_FIELD from '@salesforce/schema/Technical_Detail__c.Technical_Evaluation__c';

export default class PropertyDimensionDetails extends LightningElement {
    @api recordId;

    @track rows = [];
    isInitialized = false;

    dimensionLabels = [
        'As per document',
        'Actual (As per Measurement in ft)'
    ];

    boundaryLabels = [
        'As per document',
        'Actual (As per Measurement in ft)'
    ];

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Technical_Details__r',
        fields: [
            'Technical_Detail__c.Description_Dimension_of_Property__c',
            'Technical_Detail__c.North__c',
            'Technical_Detail__c.East__c',
            'Technical_Detail__c.West__c',
            'Technical_Detail__c.South__c',
            'Technical_Detail__c.Property_Details_Category__c'
        ]
    })
    wiredDetails({ data, error }) {
        if (error) {
            console.error(error);
            return;
        }
        if (!this.recordId) {
            return;
        }
        const parsedData = JSON.parse(JSON.stringify(data));
        console.log('parsed data:', parsedData);
        console.log('records length:', parsedData.records.length);


        const records = parsedData.records
            .filter(r =>
                r.fields.Property_Details_Category__c?.value != null &&
                r.fields.Description_Dimension_of_Property__c?.value != null
            )
            .map(r => ({
                Id: r.id,
                Property_Details_Category__c: r.fields.Property_Details_Category__c.value,
                Description_Dimension_of_Property__c: r.fields.Description_Dimension_of_Property__c.value,
                North__c: r.fields.North__c?.value,
                East__c: r.fields.East__c?.value,
                West__c: r.fields.West__c?.value,
                South__c: r.fields.South__c?.value
            }));


        this.rows = records;

        if (!this.isInitialized) {
            if (records.length === 0) {
                this.createDefaultRows();
            }
            this.isInitialized = true;
        }
    }

    get dimensionRows() {
        return this.rows.filter(r => r.Property_Details_Category__c === 'Dimension of Property (For Land & Building , Offices & Shops)');
    }

    get boundaryRows() {
        return this.rows.filter(r => r.Property_Details_Category__c === 'Boundaries Details');
    }

    createDefaultRows() {
        const payload = [];

        this.dimensionLabels.forEach(label => {
            payload.push(this.buildCreateRecord('Dimension of Property (For Land & Building , Offices & Shops)', label));
        });

        this.boundaryLabels.forEach(label => {
            payload.push(this.buildCreateRecord('Boundaries Details', label));
        });

        Promise.all(payload.map(p => createRecord(p)))
            .then(() => {
                this.showToast('Success', 'Default rows created', 'success');
            })
            .catch(err => {
                console.error(err);
                this.showToast('Error', 'Failed to create rows', 'error');
            });
    }

    buildCreateRecord(section, label) {
        return {
            apiName: 'Technical_Detail__c',
            fields: {
                Technical_Evaluation__c: this.recordId,
                Property_Details_Category__c: section,
                Description_Dimension_of_Property__c: label,
                Sections__c: 'Dimension of Property (For Land & Building , Offices & Shops)'
            }
        };
    }

    // handleChange(event) {
    //     const rowId = event.target.dataset.id;
    //     const field = event.target.dataset.field;
    //     let value = event.target.value;
    //     console.log('value000>>>',value);
    //     if (!/^\d*$/.test(value)) {
    //         console.log('value111>>>',value);
    //         value = value.replace(/[^\d]/g, '');
    //         event.target.value = value; // update UI as well
    //         console.log('event.target.value111>>>',event.target.value);
    //     }
    //     if (value === '') {
    //         console.log('value222>>>',value);
    //         return;
    //     }

    //     this.rows = this.rows.map(r =>
    //         r.Id === rowId ? { ...r, [field]: value } : r
    //     );
    // }
    handleChange(event) {
        const rowId = event.target.dataset.id;
        const field = event.target.dataset.field;
        let value = event.target.value;

        // Find current row
        const currentRow = this.rows.find(r => r.Id === rowId);

        console.log('value >>>', value);
        console.log('currentRow >>>', currentRow);

        // Apply number-only validation ONLY for Dimension rows
        if (currentRow?.Property_Details_Category__c ===
            'Dimension of Property (For Land & Building , Offices & Shops)') {

            if (!/^\d*$/.test(value)) {
                value = value.replace(/[^\d]/g, '');
                event.target.value = value;
            }
        }

        // For Boundary → allow everything (text + number)

        this.rows = this.rows.map(r =>
            r.Id === rowId ? { ...r, [field]: value } : r
        );
    }

    handleSave() {
        const updates = this.rows.map(row => ({
            fields: {
                Id: row.Id,
                North__c: row.North__c ? row.North__c : null,
                East__c: row.East__c ? row.East__c : null,
                West__c: row.West__c ? row.West__c : null,
                South__c: row.South__c ? row.South__c : null
            }
        }));

        Promise.all(updates.map(u => updateRecord(u)))
            .then(() => {
                this.showToast('Success', 'Records updated successfully', 'success');
            })
            .catch(err => {
                console.error(err);
                this.showToast('Error', 'Save failed', 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}