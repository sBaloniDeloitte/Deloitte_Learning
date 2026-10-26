import { LightningElement, api, track, wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { createRecord, updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TECH_DETAIL_OBJECT from '@salesforce/schema/Technical_Detail__c';
import PARENT_FIELD from '@salesforce/schema/Technical_Detail__c.Technical_Evaluation__c';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import FLOOR_FIELD from '@salesforce/schema/Technical_Detail__c.Floor__c';
import { refreshApex } from '@salesforce/apex';
import generateRefreshEvent from '@salesforce/apex/TechnialAdditionalChildController.generateRefreshEvent';




export default class PropertyFloorDetails extends LightningElement {

    @api recordId;
    @track rows = [];
    @track floorOptions = [];

    @wire(getObjectInfo, { objectApiName: TECH_DETAIL_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: FLOOR_FIELD
    })
    wiredPicklist({ data, error }) {
        if (data) {
            this.floorOptions = data.values;
        }
    }


    // ================= WIRE =================
wiredResult;
    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Technical_Details__r',
        fields: [
            'Technical_Detail__c.Floor__c',
            'Technical_Detail__c.Sections__c',
            'Technical_Detail__c.Accommodation_and_Occupancy__c',
            'Technical_Detail__c.As_per_Plan_BUA_SFT__c',
            'Technical_Detail__c.Actual_BUA_SFT__c',
            'Technical_Detail__c.Documented_Area_SFT__c',
            'Technical_Detail__c.Permissible_Area_SFT__c',
            'Technical_Detail__c.Adopted_Area_for_Valuation_SFT__c'
        ]
    })
    wiredDetails(result) {

    this.wiredResult = result;

    const { data, error } = result;

        if (error) {
            console.error(error);
            return;
        }

        if (!data) return;

        const parsedData = JSON.parse(JSON.stringify(data));
        console.log('refresh parsedData.records',parsedData.records);
        this.rows = parsedData.records
            .filter(r =>
                r.fields.Sections__c?.value === 'Property Details'
            )
            .map(r => ({
                Id: r.id,
                Floor__c: r.fields.Floor__c?.value,
                Accommodation_and_Occupancy__c: r.fields.Accommodation_and_Occupancy__c?.value,
                As_per_Plan_BUA_SFT__c: r.fields.As_per_Plan_BUA_SFT__c?.value,
                Actual_BUA_SFT__c: r.fields.Actual_BUA_SFT__c?.value,
                Documented_Area_SFT__c: r.fields.Documented_Area_SFT__c?.value,
                Permissible_Area_SFT__c: r.fields.Permissible_Area_SFT__c?.value,
                Adopted_Area_for_Valuation_SFT__c: r.fields.Adopted_Area_for_Valuation_SFT__c?.value
            }));
        console.log('refresh this.rows',this.rows);
    }

    refreshChild() {
        generateRefreshEvent({ techId: this.recordId }).then(result => {
            console.log('refresh triggered');
        }).catch(error => {
            console.log('error', error);
        });
    }
    get isAddDisabled() {
    if (!this.floorOptions || this.floorOptions.length === 0) {
        return true;
    }
    const selectedFloors = this.rows.map(row => row.Floor__c).filter(floor => floor); 
    return selectedFloors.length >= this.floorOptions.length;
}


    // ================= ADD ROW =================

    handleAddRow() {

        if (!this.recordId) {
            this.toast('Error', 'Parent record missing', 'error');
            return;
        }

        createRecord({
            apiName: TECH_DETAIL_OBJECT.objectApiName,
            fields: {
                [PARENT_FIELD.fieldApiName]: this.recordId,
                Sections__c: 'Property Details'
            }
        })
            .then(result => {
                    console.log('result1111>>>>',result)
                this.rows = [
                    ...this.rows,
                    {
                        Id: result.id,
                        Sections__c:'Property Details',
                        Floor__c: '',
                        Accommodation_and_Occupancy__c: '',
                        As_per_Plan_BUA_SFT__c: null,
                        Actual_BUA_SFT__c: null,
                        Documented_Area_SFT__c: null,
                        Permissible_Area_SFT__c: null,
                        Adopted_Area_for_Valuation_SFT__c: null
                    }
                ];
                this.refreshChild();
                this.toast('Success', 'Row added', 'success');
                console.log('handle row this.rows ',this.rows);
            })
            .catch(error => {
                this.toast('Error', error.body?.message || error.message, 'error');
            });
    }

    // ================= HANDLE CHANGE =================

    handleChange(event) {

        const id = event.target.dataset.id;
        const field = event.target.dataset.field;
        let value = event.target.value;
        const numberFields = [
        'As_per_Plan_BUA_SFT__c',
        'Actual_BUA_SFT__c',
        'Documented_Area_SFT__c',
        'Permissible_Area_SFT__c',
        'Adopted_Area_for_Valuation_SFT__c'
        ];

        if (numberFields.includes(field)) {
            value = value.replace(/[^0-9]/g, ''); 
            event.target.value = value; 
            if (!value) {
                return;
            }
        }
        // 🔹 Duplicate validation only for Floor__c
        if (field === 'Floor__c') {

            const isDuplicate = this.rows.some(row =>
                row.Id !== id && row.Floor__c === value
            );

            if (isDuplicate) {

                event.target.setCustomValidity('This floor is already selected.');
                event.target.reportValidity();
                return;
            } else {
                event.target.setCustomValidity('');
                event.target.reportValidity();
            }
        }

        // 🔹 Update row normally
        this.rows = this.rows.map(row =>
            row.Id === id ? { ...row, [field]: value } : row
        );
         updateRecord({
        fields: {
            Id: id,
            [field]: value
        }
    })
    .then(() => {
        console.log('Record updated successfully');
    })
    .catch(error => {
        this.toast('Error', error.body?.message || error.message, 'error');
    });
        console.log('handle change row this.rows ',this.rows);
    }


    // ================= DELETE =================

    handleDelete(event) {

        const id = event.currentTarget.dataset.id;

        deleteRecord(id)
            .then(() => {
                this.rows = this.rows.filter(row => row.Id !== id);
                this.toast('Success', 'Row deleted', 'success');
                this.refreshChild();
            })
            .catch(error => {
                this.toast('Error', error.body?.message || error.message, 'error');
            });
    }

    // ================= SAVE =================

    saveAll() {

        let isValid = true;
        const floorSet = new Set();

        // 🔹 Validate Floors
        for (let row of this.rows) {

            if (!row.Floor__c) {
                this.showToast('Error', 'Floor is required for all rows', 'error');
                return;
            }

            if (floorSet.has(row.Floor__c)) {
                this.showToast('Error', 'Duplicate floors are not allowed', 'error');
                return;
            }

            floorSet.add(row.Floor__c);
        }

        if (!isValid) {
            this.toast(
                'Error',
                'Each row must have a unique Floor value. Duplicate or empty floors are not allowed.',
                'error'
            );
            return;
        }
        console.log('this.rows save>>>>',this.rows)
        // 🔹 Prepare Updates
        const updates = this.rows.map(row => ({
            fields: {
                Id: row.Id,
                Floor__c: row.Floor__c,
                Accommodation_and_Occupancy__c: row.Accommodation_and_Occupancy__c,
                As_per_Plan_BUA_SFT__c: row.As_per_Plan_BUA_SFT__c,
                Actual_BUA_SFT__c: row.Actual_BUA_SFT__c,
                Documented_Area_SFT__c: row.Documented_Area_SFT__c,
                Permissible_Area_SFT__c: row.Permissible_Area_SFT__c,
                Adopted_Area_for_Valuation_SFT__c: row.Adopted_Area_for_Valuation_SFT__c
            }
        }));

        Promise.all(updates.map(u => updateRecord(u)))
            .then(() => {
                this.toast('Success', 'Technical details updated', 'success');
                this.refreshChild();
              //  return refreshApex(this.wiredResult);
                window.location.reload();
            })
            .catch(error => {
                this.toast('Error', error.body?.message || error.message, 'error');
            });
             console.log('this.rows after save>>>>',this.rows)
    }

    // ================= TOTAL CALCULATIONS =================

    get totalPlanBUA() {
        return this.calculateTotal('As_per_Plan_BUA_SFT__c');
    }

    get totalActualBUA() {
        return this.calculateTotal('Actual_BUA_SFT__c');
    }

    get totalDocumentedArea() {
        return this.calculateTotal('Documented_Area_SFT__c');
    }

    get totalPermissibleArea() {
        return this.calculateTotal('Permissible_Area_SFT__c');
    }

    get totalAdoptedArea() {
        return this.calculateTotal('Adopted_Area_for_Valuation_SFT__c');
    }

    calculateTotal(field) {
        return this.rows
            .reduce((sum, row) => {
                return sum + (Number(row[field]) || 0);
            }, 0)
            .toFixed(2);
    }

    // ================= TOAST =================

    toast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

}