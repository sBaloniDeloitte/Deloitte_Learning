import { LightningElement,track, api, wire } from 'lwc';
import getScreenDetails from '@salesforce/apex/ScreenGenerationController.getScreenDetails';
import getPicklistValues from '@salesforce/apex/ScreenGenerationController.getPicklistValues';
import checkEditableOrNot from '@salesforce/apex/Hl_CovenantsDetailFormController.checkEditableOrNot';
import getLoanDetailsFromStorageObject from '@salesforce/apex/ScreenGenerationController.getLoanDetailsFromStorageObject';
import getCollateralData from '@salesforce/apex/CaptureMandateController.getCollateralData';
import getNOIRecords from '@salesforce/apex/CaptureMandateController.getNOIRecords';
import upsertNOIRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.upsertNOIRecord';
import createNoiRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.createNoiRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUserRole from '@salesforce/apex/Hl_CovenantsDetailFormController.getUserRole';
import canUserEditRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.canUserEditRecord';

const columns = [
    { label: 'Name', fieldName: 'Name' },
    { label: 'Remark', fieldName: 'Remark__c'},
    { label: 'Status', fieldName: 'Status__c' }
];

export default class Hl_noticeOfIntimation extends LightningElement {
    @track fieldDetails;
    @track mortgagorDetails;
    @track mortgageDetails;
    @track initiate;
    @api formName = 'Notice of Intimation';
    @api recordId;
    @track collateralRecords;
    @track collateralRecordWithFields;
    @track showTable = false;
    @track loanTrscId;
    @track data;
    @track isDisable = true;
    disableDocField= false;
    @track selectedRecord;
    noiDetailUpdate = {};
    columns = columns;

    handleFetchNOI() {
        getNOIRecords({ loanAppId: this.recordId })
            .then(result => {
                if (Array.isArray(result) && result.length > 0) {
                    this.data = [...result];
                    this.showTable = true;
                    console.log('data is coming');
                } else {
                    this.data = [];
                    this.showTable = false;
                    console.log('data not present');
                }
            })
            .catch(error => {
                console.error(error);
            });
    }

    connectedCallback(){
        console.log('Record Id ', this.recordId);
        this.handleFetchNOI();
        this.getScreenDetailsFromApex();
    }

    handleInputChange(event){
        console.log('event.target.value ' + event.target.value);
        // this.noiDetailUpdate = {};
        console.log('event ',event.target.value);
        const apiName = event.currentTarget.dataset.name;
        console.log('api name ',apiName);
        console.log(event.target.dataset.id);
        this.noiDetailUpdate[apiName] = event.target.value;
        this.noiDetailUpdate['Id'] = this.loanTrscId;
        console.log('NOI Details: ',this.noiDetailUpdate);        
        console.log('api name ', apiName);
    }

    createRecord(){
        this.selectedRecord = true;
    }

    handleSave(event){
        console.log('onBlurValue--' + event.target.value);
        console.log('NOI detail ', this.noiDetailUpdate);
        if (JSON.stringify(this.noiDetailUpdate) !== '{}'){
            console.log('this field detail', this.noiDetailUpdate);
            console.log('Loan Id ',this.recordId);
            upsertNOIRecord({NoiDetail : this.noiDetailUpdate, loanId: this.recordId})
            .then(result => {
                console.log('REsult is  ',result);
                if(this.noiDetailUpdate.Id ){
                    this.showToast('Success', 'Record Updated Successfully', 'success');
                }
                else{
                    this.showToast('Success', 'Record Created Successfully', 'success');
                }
                this.noiDetailUpdate = {};
                this.handleFetchNOI();
            })
            .catch(error => {
                console.log('error ::',error);
            });
        }
        else{
            console.log('detail not completed');
        }
    }

    handleOnblur(event){
        // console.log('onBlurValue--' + event.target.value);
        // console.log('NOI detail ', this.noiDetailUpdate);
        // if (JSON.stringify(this.noiDetailUpdate) !== '{}'){
        //     console.log('this field detail', this.noiDetailUpdate);
        //     upsertNOIRecord({NoiDetail : this.noiDetailUpdate})
        //     .then(result => {
        //         this.noiDetailUpdate = {};
        //         this.handleFetchNOI();
        //     })
        //     .catch(error => {
        //         console.log('error ::',error);
        //     });
        // }
        // else{
        //     console.log('detail not completed');
        // }
    }

    handleNameClick(event) {
        const recordId = event.target.dataset.id;
        console.log('Record id ' , recordId);
        this.loanTrscId = recordId;
        const record = this.data.find(item => item.Id === recordId);
        console.log('Data record ',record);

        // Only change if it's a new record click
        if (!this.selectedRecord || this.selectedRecord.Id !== recordId) {
            this.selectedRecord = record;
        }
        this.populateAllAccordions();
    }

    populateAllAccordions() {
        if (!this.selectedRecord) return;
    
        // Example: updating multiple accordion arrays
        this.mortgageDetails = this.mortgageDetails.map(field => ({
            ...field,
            value: this.selectedRecord[field.Storage_Field__c] || ''
        }));
    
        this.mortgagorDetails = this.mortgagorDetails.map(field => ({
            ...field,
            value: this.selectedRecord[field.Storage_Field__c] || ''
        }));
    
        this.initiate = this.initiate.map(field => ({
            ...field,
            value: this.selectedRecord[field.Storage_Field__c] || ''
        }));
    }
    
    renderedCallback() {
        const style = document.createElement("style");
        style.innerText = `
        .slds-dropdown,
        .slds-dropdown_fluid,
        .slds-listbox,
        .slds-listbox_vertical {
        background-color: #16283f !important;
        }
            
        .slds-listbox__option,
        .slds-listbox__item {
        background-color: #16283f !important;
        color: #ffffff !important;
        }
            
        .slds-listbox__option:hover,
        .slds-listbox__item:hover {
        background-color: #1f3550 !important;
        color: #ffffff !important;
        }
            
        .slds-listbox__option-text,
        .slds-listbox__option span,
        .slds-media__body {
        color: #ffffff !important;
        }
            
        .slds-is-selected {
        background-color: #1f3550 !important;
        color: #ffffff !important;
        }
        .slds-accordion__list-item .section-control {
            background: linear-gradient(
                135deg,
                #001a5e 0%,
                #003087 55%,
                #004db3 100%
            ) !important;

            color: #ffffff !important;
            font-weight: 600;

            margin-left: 0;
            margin-right: 0;
            margin-bottom: 0;
        }

        .slds-accordion__summary {
            padding: 10px 0px 10px 0px;

            background: linear-gradient(
                135deg,
                #001a5e 0%,
                #003087 55%,
                #004db3 100%
            ) !important;
        }

        .slds-accordion__summary-content,
        .slds-accordion__summary-heading,
        .slds-accordion__summary-action,
        .slds-accordion__summary-action .slds-truncate {
            color: #ffffff !important;
            font-weight: 600 !important;
        }

        .slds-accordion__summary-action svg,
        .slds-button__icon {
            fill: #ffffff !important;
            color: #ffffff !important;
        }

        .slds-accordion__summary:hover,
        .slds-accordion__summary-action:hover,
        .slds-accordion__list-item .section-control:hover {
            background: linear-gradient(
                135deg,
                #001a5e 0%,
                #003087 55%,
                #004db3 100%
            ) !important;

            color: #ffffff !important;
        }
    `;

        this.template.querySelector(".styleContainer")?.appendChild(style);
    }
    
    getScreenDetailsFromApex() {
        console.log('this.formIdentifier ' + this.formName);
        this.fieldDetails = [];
        
        const forms = [
            'Notice of Intimation',
            'Initiate NOI',
            'Mortgage Details NOI',
            'Mortgagor Details NOI',
        ];
    
        Promise.all(forms.map(f => getScreenDetails({
            formIdentifier: f,
            loanId: this.recordId
        })))
        .then(async results => {
            // Flatten all results into one array
            const allResults = results.flat();
            // Grouping based on Form_Name__c
            this.mortgagorDetails = allResults.filter(item => item.Form_Name__c === 'Mortgagor Details');
            this.fieldDetails     = allResults.filter(item => item.Form_Name__c === 'Loan Summary');
            this.mortgageDetails  = allResults.filter(item => item.Form_Name__c === 'Mortgage Details');
            this.initiate         = allResults.filter(item => item.Form_Name__c === 'Initiate');
    
            // Add picklist options
            const allDetails = [
                ...this.mortgagorDetails,
                ...this.fieldDetails,
                ...this.mortgageDetails,
                ...this.initiate
            ];
    
            for (const item of allDetails) {
                if (item.Field_Type__c === 'Picklist') {
                    item.picklistOptions = await this.getPicklistOptionsFromApex(true, item.Storage_Object__c, item.Storage_Field__c);
                    console.log('Picklist option ',item.picklistOptions);
                    item.isPicklist = false;
                }
            }
    
            this.getLoanDetails();
            checkEditableOrNot({ recordId: this.recordId }).then(data => {
                this.disableDocField = data;
                this.isDisable = !data;
                getUserRole({recordId: this.recordId})
                .then(result => {
                    if(result){
                        this.disableDocField = false;
                        this.isDisable = true;
                    }
                })

                //Sanwar
                canUserEditRecord({recordId: this.recordId})
                .then(result => {
                    if(result){
                        this.disableDocField = true;
                        this.isDisable = false;
                    }
                })
                console.log("Disable",this.isDisable);
            });
    
            console.log('Loan Summary ,', this.fieldDetails);
            console.log('Initiate Detail ,', this.initiate);
            console.log('Mortgage Detail ,', this.mortgageDetails);
            console.log('Mortgagor Detail ,', this.mortgagorDetails);
        })
        .catch(error => {
            console.error('error getScreenDetails: ' + error);
        });
    }
    
    async getPicklistOptionsFromApex(isPicklist, storageObject, storageField) {
        if (isPicklist) {
            const result = await getPicklistValues({
                storageObject: storageObject,
                storageField: storageField
            });
            let picklistOptions = result.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });
            return picklistOptions;
        }
    }


    getLoanDetails() {
        try {
            console.log('782 ' + this.screenName);
            console.log('Record Id ', this.recordId);
            setTimeout(() => {
                console.log('at 796');
                console.log('form name ',this.formName);
                console.log('Record Id ', this.recordId);
                getLoanDetailsFromStorageObject({
                    screenName: this.formName,
                    loanId: this.recordId,
                    formIdentifier: this.formName,
                    technicalEvaluationId: this.recordId, //change 
                    recordId: this.recordId,
                    did: ''
                }).then(result => {
                    console.log(result[0].fieldId);
                    console.log('detailsWrapperList from getLoanDetailsFromStorageObject--> ' + JSON.stringify(result));
                    console.log('fieldDetails-> ' + this.fieldDetails);
                    if (this.fieldDetails) {
                        
                        result.forEach(item => {
                            this.fieldDetails.forEach(record => {
                                console.log('item.fieldApiName at 810---', item.fieldApiName);
                                console.log('item.fieldValue at 180----', item.fieldValue);
                                console.log('record. id==', record.Id);
                                console.log('record.Storage_Field__c----', item.Storage_Field__c);
                                console.log('item id' ,item.fieldId);
                                record.Id = item.fieldId;

                                if (item.fieldApiName == record.Storage_Field__c && record.is_Lookup__c) {
                                    record.savedName = item.fieldValue; //item.lookUpfieldValue;
                                    record.value = item.lookUpfieldValue;
                                    console.log('record -->' + JSON.stringify(record));
                                } else if (item.fieldApiName == record.Storage_Field__c) {
                                    record.value = item.fieldValue;
                                }
                                if (record.Field_Type__c === 'Picklist') {
                                    record.isPicklist = true;
                                }
                            });
                        });

                        console.log('this.fieldDetails at 108---', JSON.stringify(this.fieldDetails));
                    }
                }).catch(error => {
                    console.log('error ',error);
                })
            }, 1000);
        } catch (error) {
            console.log('error=:860generic' + error);
            console.log('error=:860generic' + JSON.stringify(error));
        }
    
    } 
    showToast(title, msg, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message: msg, variant })
        );
    }
}