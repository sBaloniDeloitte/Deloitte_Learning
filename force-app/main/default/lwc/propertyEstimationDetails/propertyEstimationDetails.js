import { LightningElement, api, wire, track } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { createRecord, updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import FLOOR_FIELD from '@salesforce/schema/Technical_Detail__c.Floor__c';
import TECH_DETAIL_OBJECT from '@salesforce/schema/Technical_Detail__c';
import PARENT_FIELD from '@salesforce/schema/Technical_Detail__c.Technical_Evaluation__c';

// ===== Parent Fields =====
import VCR_CUSTOMER from '@salesforce/schema/Technical_Evaluation__c.Vetted_Construction_Rates_Estimation__c';
import VCR_VETTED from '@salesforce/schema/Technical_Evaluation__c.Vetted_Construction_Rates_Vetted_Estimat__c';
import TOTAL_BUA_CUSTOMER from '@salesforce/schema/Technical_Evaluation__c.Total_BUA_Estimation_as_per_Customer__c';
import TOTAL_BUA_VETTED from '@salesforce/schema/Technical_Evaluation__c.Total_BUA_Vetted_Estimation_Permissible__c';
import TOTAL_EST_CUSTOMER from '@salesforce/schema/Technical_Evaluation__c.Total_Vetted_Estimate_Amount__c';
import TOTAL_EST_VETTED from '@salesforce/schema/Technical_Evaluation__c.Total_Vetted_Estimate_Amount_Vatted_Esti__c';

export default class PropertyEstimationDetails extends LightningElement {

    @api recordId;
    @track rows = [];

    // ===== Static Values =====
    @track totalBUACustomer = 0;
    @track totalBUAVetted = 0;
    @track vettedConstructionRateCustomer = 0;
    @track vettedConstructionRateVetted = 0;
    @track totalEstimateCustomer = 0;
    @track totalEstimateVetted = 0;
    parentLoaded = false;
    childLoaded = false;


    // floorOptions = [
    //     { label: 'GF', value: 'GF' },
    //     { label: 'FF', value: 'FF' },
    //     { label: 'SF', value: 'SF' },
    //     { label: '3rd Floor', value: '3rd Floor' }
    // ];
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

    // ===============================
    // LOAD CHILD RECORDS
    // ===============================
    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Technical_Details__r',
        fields: [
            'Technical_Detail__c.Floor__c',
            'Technical_Detail__c.Sections__c',
            'Technical_Detail__c.Estimation_as_per_Customer_sqft__c',
            'Technical_Detail__c.Vetted_Estimation_Permissible_sqft__c'
        ]
    })
    wiredDetails({ data, error }) {

        if (error) {
            console.error('Child load error:', error);
            this.showToast('Error', 'Failed to load floor records', 'error');
            return;
        }

        if (data) {
            console.log('Child records loaded');

            try {
                const parsed = JSON.parse(JSON.stringify(data));

                this.rows = parsed.records
                    .filter(r => r.fields.Sections__c?.value === 'Proposed Estimate of Project')
                    .map(r => ({
                        Id: r.id,
                        Floor__c: r.fields.Floor__c?.value,
                        Estimation_as_per_Customer_sqft__c:
                            r.fields.Estimation_as_per_Customer_sqft__c?.value || 0,
                        Vetted_Estimation_Permissible_sqft__c:
                            r.fields.Vetted_Estimation_Permissible_sqft__c?.value || 0
                    }));
                this.calculateBUA();

                this.childLoaded = true;
                this.tryCalculate();

            } catch (e) {
                console.error('Child parsing error:', e);
            }
        }
    }
    tryCalculate() {

        if (this.parentLoaded && this.childLoaded) {
            this.calculateTotals();
        }
    }
    calculateBUA() {

        this.totalBUACustomer = 0;
        this.totalBUAVetted = 0;

        this.rows.forEach(row => {

            this.totalBUACustomer +=
                Number(row.Estimation_as_per_Customer__c) || 0;

            this.totalBUAVetted +=
                Number(row.Vetted_Estimation_Permissible__c) || 0;
        });

        console.log('BUA Calculated:',
            this.totalBUACustomer,
            this.totalBUAVetted
        );
    }


    // ===============================
    // LOAD PARENT RECORD
    // ===============================
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [
            VCR_CUSTOMER,
            VCR_VETTED,
            TOTAL_BUA_CUSTOMER,
            TOTAL_BUA_VETTED,
            TOTAL_EST_CUSTOMER,
            TOTAL_EST_VETTED
        ]
    })
    wiredParent({ data, error }) {

        if (error) {
            console.error('Parent load error:', error);
            this.showToast('Error', 'Failed to load parent data', 'error');
            return;
        }

        if (data) {
            console.log('Parent record loaded', data);

            try {

                this.vettedConstructionRateCustomer =
                    data.fields.Vetted_Construction_Rates_Estimation__c?.value || 0;

                this.vettedConstructionRateVetted =
                    data.fields.Vetted_Construction_Rates_Vetted_Estimat__c?.value || 0;

                this.totalBUACustomer =
                    data.fields.Total_BUA_Estimation_as_per_Customer__c?.value || 0;

                this.totalBUAVetted =
                    data.fields.Total_BUA_Vetted_Estimation_Permissible__c?.value || 0;

                this.totalEstimateCustomer =
                    data.fields.Total_Vetted_Estimate_Amount__c?.value || 0;

                this.totalEstimateVetted =
                    data.fields.Total_Vetted_Estimate_Amount_Vatted_Esti__c?.value || 0;

                console.log('Parent values assigned', this.totalEstimateVetted);
                this.parentLoaded = true;
                this.tryCalculate();

            } catch (e) {
                console.error('Parent parsing error:', e);
            }
        }
    }

    // ===============================
    // ADD ROW
    // ===============================
    handleAddRow() {

        createRecord({
            apiName: TECH_DETAIL_OBJECT.objectApiName,
            fields: {
                [PARENT_FIELD.fieldApiName]: this.recordId,
                Sections__c: 'Proposed Estimate of Project'
            }
        })
            .then(result => {

                console.log('Row created:', result.id);

                this.rows = [
                    ...this.rows,
                    {
                        Id: result.id,
                        Floor__c: '',
                        Estimation_as_per_Customer_sqft__c: 0,
                        Vetted_Estimation_Permissible_sqft__c: 0
                    }
                ];
            })
            .catch(error => {
                console.error('Add row error:', error);
                this.showToast('Error', 'Failed to add row', 'error');
            });
    }

    // ===============================
    // HANDLE FLOOR CHANGE
    // ===============================
    handleChange(event) {
        let value = event.target.value;
        const id = event.target.dataset.id;
        const field = event.target.dataset.field;
        console.log('value000>>>', value);
        const numericFields = [
            'Estimation_as_per_Customer_sqft__c',
            'Vetted_Estimation_Permissible_sqft__c',
        ];
        if (numericFields.includes(field)) {
            if (!/^\d*$/.test(value)) {
                console.log('value111>>>', value);
                value = value.replace(/[^\d]/g, '');
                event.target.value = value; // update UI as well
                console.log('event.target.value111>>>', event.target.value);
            }
        }
        if (value === '') {
            console.log('value222>>>', value);
            return;
        }
        
        console.log(id, field, value)


        if (numericFields.includes(field)) {
            value = Number(value) || 0;
        }
        this.rows = this.rows.map(row =>
            row.Id === id ? { ...row, [field]: value } : row
        );

        updateRecord({ fields: { Id: id, [field]: value } })
            .catch(error => {
                console.error('Child update error:', error);
                this.showToast('Error', 'Failed to update floor record', 'error');
            });
        this.calculateBUA();
        this.calculateTotals();
    }

    // ===============================
    // HANDLE RATE CHANGE
    // ===============================
    handleRateChange(event) {
        let value = event.target.value;
        console.log('value000>>>', value);
        if (!/^\d*$/.test(value)) {
            console.log('value111>>>', value);
            value = value.replace(/[^\d]/g, '');
            event.target.value = value; // update UI as well
            console.log('event.target.value111>>>', event.target.value);
        }
        if (value === '') {
            console.log('value222>>>', value);
            return;
        }
        const field = event.target.dataset.field;
        //  const value = Number(event.target.value) || 0;

        if (field === 'customer') {
            this.vettedConstructionRateCustomer = value;
        }

        if (field === 'vetted') {
            this.vettedConstructionRateVetted = value;
        }

        this.calculateTotals();
    }

    // ===============================
    // CALCULATIONS
    // ===============================
    calculateTotals() {

        this.totalBUACustomer = this.rows.reduce(
            (sum, row) => sum + (row.Estimation_as_per_Customer_sqft__c || 0), 0
        );

        this.totalBUAVetted = this.rows.reduce(
            (sum, row) => sum + (row.Vetted_Estimation_Permissible_sqft__c || 0), 0
        );

        this.totalEstimateCustomer =
            this.totalBUACustomer * this.vettedConstructionRateCustomer;

        this.totalEstimateVetted =
            this.totalBUAVetted * this.vettedConstructionRateVetted;

        this.updateParent();
    }

    // ===============================
    // UPDATE PARENT
    // ===============================
    updateParent() {

        updateRecord({
            fields: {
                Id: this.recordId,
                Total_BUA_Estimation_as_per_Customer__c: this.totalBUACustomer,
                Total_BUA_Vetted_Estimation_Permissible__c: this.totalBUAVetted,
                Vetted_Construction_Rates_Estimation__c: this.vettedConstructionRateCustomer,
                Vetted_Construction_Rates_Vetted_Estimat__c: this.vettedConstructionRateVetted,
                Total_Vetted_Estimate_Amount__c: this.totalEstimateCustomer,
                Total_Vetted_Estimate_Amount_Vatted_Esti__c: this.totalEstimateVetted
            }
        })
            .catch(error => {
                console.error('Parent update error:', error);
                let errorMessage = 'Failed to update record';

                // ✅ Validation Rule Error
                if (error.body && error.body.output && error.body.output.errors && error.body.output.errors.length > 0) {
                    errorMessage = error.body.output.errors[0].message;
                }
                // ✅ Field Level Error
                else if (error.body && error.body.output && error.body.output.fieldErrors) {
                    const fieldErrors = error.body.output.fieldErrors;
                    const firstField = Object.keys(fieldErrors)[0];
                    errorMessage = fieldErrors[firstField][0].message;
                }
                // ✅ Normal Error
                else if (error.body && error.body.message) {
                    errorMessage = error.body.message;
                }

                // this.showToast('Error', errorMessage, 'error');
            });
    }

    // ===============================
    // DELETE
    // ===============================
    handleDelete(event) {

        const id = event.currentTarget.dataset.id;

        deleteRecord(id)
            .then(() => {
                this.rows = this.rows.filter(r => r.Id !== id);
                this.calculateTotals();
            })
            .catch(error => {
                console.error('Delete error:', error);
                this.showToast('Error', 'Failed to delete row', 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    get isAddDisabled() {
        if (!this.floorOptions || this.floorOptions.length === 0) {
            return true;
        }
        const selectedFloors = this.rows.map(row => row.Floor__c).filter(floor => floor);
        return selectedFloors.length >= this.floorOptions.length;
    }
}