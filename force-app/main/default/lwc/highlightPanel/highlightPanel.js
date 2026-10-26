import { LightningElement, api, wire, track } from 'lwc';
import { getRecordUi } from 'lightning/uiRecordApi';
import getObjectFields from '@salesforce/apex/Utility_V1.getObjectFields'
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';//Ayushi - 24/10
import RECORDTYPE_NAME from '@salesforce/schema/Legal__c.RecordType.Name';//Ayushi - 24/10
export default class highlightPanel extends LightningElement {
    @api recordId;
    @api fields=[]; // e.g. ['Account.Name','Account.Industry','Account.Rating']

    @track name;
    @track recordFields = [];
    objectApiName;
    @track stage;
    @track recordTypeName;
    recordTypeLabel = 'Report Type';
    //Ayushi - 24/10
    
    connectedCallback(){
        this.loadApexFields();
    }
    loadApexFields() {
        getObjectFields({ recordId: this.recordId })
            .then(result => {
                console.log('Apex result ---- ' + JSON.stringify(result));

                if (result && result.length > 0) {
                    // ✅ Extract Name
                    const nameField = result.find(f => f.apiName === 'name');
                    if (nameField) {
                        this.name = nameField.value;
                        console.log('Name ---- ' + this.name);
                    }

                    // ✅ Extract Stage__c
                    const stageField = result.find(f => f.apiName === 'stage__c');
                     console.log('stageField---- ' +stageField);
                    if (stageField) {
                        this.stage = {
                            label: stageField.label,
                            value: stageField.value
                        };
                        console.log('this.stage ---- ' + this.stage);
                    }
                }
            })
            .catch(error => {
                console.error('Error fetching fields:', error);
            });
    }
    // Fetch record + field metadata
    @wire(getRecord, { recordId: '$recordId', fields: [RECORDTYPE_NAME] })
    wiredRecordType({ error, data }) {
        if (data) {
            // --- Extract the Name value ---
            this.recordTypeName = getFieldValue(data, RECORDTYPE_NAME); // <-- Get the Name
            console.log('Fetched Record Type Name: ', this.recordTypeName);
        } else if (error) {
            console.error('Error fetching record type name:', error);
        }
    }
    
   
}