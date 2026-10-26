import { LightningElement,api, track, wire } from 'lwc';
import getDocumentDetailRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.getDocumentDetailRecord';
import upsertDocumentDetails from '@salesforce/apex/Hl_CovenantsDetailFormController.upsertDocumentDetails';
import deletedocumentIds from '@salesforce/apex/Hl_CovenantsDetailFormController.deletedocumentIds';
import getCurrentUserRole from '@salesforce/apex/Hl_CovenantsDetailFormController.getCurrentUserRole';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import deleteDocumentDetailRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.deleteDocumentDetailRecord';
import getCovenantNameValues from '@salesforce/apex/Hl_CovenantsDetailFormController.getCovenantNameValues';//Sanwar
import getCovenantDetails from '@salesforce/apex/Hl_CovenantsDetailFormController.getCovenantDetails';//Sanwar
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";//sanwar(3/12/2025)
import canUserEditRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.canUserEditRecord';//sanwar(3/12/2025)
import { getRecord, updateRecord } from 'lightning/uiRecordApi';//sanwar(3/12/2025)
  
export default class Hl_covenantsDetailForm extends LightningElement {

    @api recordId;
    isLoading = false;
    howNoRecords= false;
    disableDocField= false;
    showSummaryStyle = true;
    showNoRecords = false;
    @track displayList;
    @track detailRecord = [];
    mapArray = [];
    showConfirmation = false;
    showCovenantSection = false;
    typeValue = '';//Sanwar
    descriptionValue = '';//Sanwar
    isDisable = false;
    @track documentCategory = '';
    @track documentType = '';
    confirmMessage = 'Are you sure you want to delete these document(s)?';
    @track isNotOpsAuthor = true;//sanwar(3/12/2025)
    @track oppSubStage = '';//sanwar(3/12/2025)
    // documentDetail ={};
    recordTypeId;
    sanctiondocTodelete;
    docNameOptions=[];
    statusOptions = [
        { label: '-- Select Status --', value: '' },
        {label: 'Pending', value: 'Pending'},
        {label: 'Mandatory', value: 'Mandatory'},
        {label: 'Waiver', value: 'Waiver'}
    ];
    //Sanwar
    approvalStatusOptions = [
        { label: '-- Select Status --', value: '' },
        {label: 'Approved', value: 'Approved'},
        {label: 'Rejected', value: 'Rejected'}
    ];

    approvalLevelOptions = [
        { label: '-- Select Level --', value: '' },
        {label: 'L1', value: 'L1'},
        {label: 'L2', value: 'L2'},
        {label: 'L3', value: 'L3'},
        {label: 'L4', value: 'L4'},
        {label: 'L5', value: 'L5'}
    ];//Sanwar

    typeOptions = [
        { label: '-- Select Type --', value: '' },
        {label: 'Critical', value: 'Critical'},
        {label: 'Non-Critical', value: 'Non-Critical'}
    ];
    //Sanwar
    nodOptions = [
        { label: '-- Select Option --', value: ''},
        {label: 'Original', value: 'Original'},
        {label: 'Photocopy', value: 'Photocopy'},
        {label: 'Certified copy', value: 'Certified copy'},
        {label: 'Others', value: 'Others'}
    ];


    covCategory = [
        { label: '-- Select Category --', value: ''},
        {label: 'LEGXT', value: 'LEGXT'},
        {label: 'CREDIT', value: 'CREDIT'},
        {label: 'OTH', value: 'OTH'}
    ];


    covType = [
        { label: '-- Select Name --', value: ''},
        {label: 'OTC', value: 'OTC'},
        {label: 'PDD', value: 'PDD'},
        {label: 'LOS', value: 'LOS'}
    ];

    today;
    futureDate;
    isRendered = false;

    connectedCallback() {
        const tomorrowDate = new Date();
        tomorrowDate.setDate(tomorrowDate.getDate() + 1);
        this.today = tomorrowDate.toISOString().split('T')[0];
        const daysLaterDate = new Date();
        daysLaterDate.setDate(daysLaterDate.getDate() + 30);
        this.futureDate = daysLaterDate.toISOString().split('T')[0];
        console.log('dataaa');
        console.log('Status Option ', this.statusOptions);
        this.getCovenantDetails();
        this.docNameOptions.push({label: 'Select Options', value: ''});//Sanwar

    }

    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;
            this.injectCustomStyles();
        }
    }

    injectCustomStyles() {
        const style = document.createElement('style');
        style.innerText = `
            .hl-covenant-dark-theme lightning-select .slds-select,
            .hl-covenant-dark-theme lightning-combobox .slds-combobox__input {
                background-color: #16283f !important;
                border-color: #33455e !important;
                color: #ffffff !important;
                height: 2.25rem !important;
            }
            .hl-covenant-dark-theme lightning-textarea .slds-textarea {
                background-color: #16283f !important;
                border-color: #33455e !important;
                color: #ffffff !important;
            }
            .hl-covenant-dark-theme lightning-input .slds-input[disabled] {
                background-color: #0e1c30 !important;
                color: #8a99b3 !important;
            }
            .hl-covenant-dark-theme lightning-select .slds-form-element__label,
            .hl-covenant-dark-theme lightning-textarea .slds-form-element__label,
            .hl-covenant-dark-theme lightning-input .slds-form-element__label {
                color: #cfd8e6 !important;
            }
        `;
        this.template.querySelector('.styleContainer')?.appendChild(style);
    }

      //sanwar(3/12/2025)
    @wire(getRecord, {
        recordId: "$recordId",
        fields: [SUBSTAGE_FIELD]
    })
    oppRecord({ data, error }) {
        if (data) {
            console.log('Data',data);
            this.oppSubStage = data.fields.Sub_stage__c.value;
            console.log("Sub Stage:", this.oppSubStage);
            canUserEditRecord({ recordId: this.recordId })
            .then(result => {
                console.log('At 380');
                if(result && this.oppSubStage == 'Ops Author'){
                    console.log('At 382');
                    this.isNotOpsAuthor = false;
                }
            });
        } else if (error) {
            console.error(error);
        }
    }
    

    handleCovenantSection(){
        console.log('at 97');
        this.showCovenantSection = true
        this.isDisable = true;
    }
    
    getCovenantDetails() {
        getCurrentUserRole({recordId : this.recordId}).then(data => {
            this.disableDocField = data;
        });
        getDocumentDetailRecord({documentMasterId : null, recordId: this.recordId})
        .then(result => {
            this.detailRecord = result;
            console.log('result ::',result, this.recordId);
            this.detailRecord.forEach(parent => {
                parent.documentList.forEach(row => {
                    row.optionsList = [{ label: 'Select Options', value: '' }];
                     if (row.isCovenantId) {
                        this.fetchDocNameOptions(row);
                    }
                });
            });
        })
        .catch(error => {
            console.log('error ::',error);
        });
    }

    fetchDocNameOptions(row) {

        getCovenantNameValues({
            documentCategory: row.covenantCategory,
            documentType: row.covenantType
        })
        .then(result => {

            row.optionsList = [
                { label: 'Select Options', value: '' },
                ...result.map(item => ({
                    label: `${item.code__c}: ${item.description__c}`,
                    value: item.Id
                }))
            ];
            this.detailRecord = [...this.detailRecord]; //sanwar      
            console.log('this.detailRecord   '+this.detailRecord);
             
        })
        .catch(error => {
            console.error('error fetching options:', error);
            console.error('error fetching options:', error);
        });
    }




    handleshowgenericConfirm(event){
        this.sanctiondocTodelete = event.target.dataset.id;
        this.eventName = event.target.dataset.name;
        this.newsanctionId = event.target.dataset.sanctionid;
        this.modalVisibility = false;
        this.showConfirmation = true;
    }
    docDetail = {};
    handleChangeRecord(event){
        console.log('event at 152',event.detail.value);
        console.log('event at 154',event.target.value);
        console.log('>>>>>>>>>>>',event.target.name);
        let fieldApiName = event.target.name;
        let value = event.target.value;
        if(fieldApiName != 'Document_Category__c' && fieldApiName != 'Document_Type__c' && fieldApiName != 'Document_Name__c' ){
            this.docDetail[fieldApiName] = value;
        }
        console.log('this.docDetail',this.docDetail);
        //Sanwar
        if(fieldApiName == 'Document_Category__c'){
            this.documentCategory = event.target.value;
        }
        if(fieldApiName == 'Document_Name__c'){
            console.log('At 230'+ value);
            console.log('At 265'+ this.documentCategory);
            getCovenantNameValues({documentCategory : this.documentCategory, documentType : this.documentType})
            .then(result => {
                const record = result.find(item => item.Id === value);
                console.log('record',record);
                console.log('At 243');
                if (record) {
                    console.log('245');
                    this.typeValue = record.covenanttype__c;
                    this.descriptionValue = record.description__c;
                    this.docDetail['Name'] = record.code__c;
                    this.docDetail['Document_Type__c'] = this.typeValue;
                    this.docDetail['Covenant_Id__c'] = record.Name;
                    this.docDetail['Covenant_Doc_Type__c'] = record.doctype__c;
                    console.log('At 247',value);
                    this.docDetail['Covenant_Master__c'] = value;
                    console.log('this.docDetail>>>',this.docDetail);
                }
            });
        }
        if(fieldApiName == 'Document_Type__c'){
            this.documentType = event.target.value;
            getCovenantNameValues({documentCategory : this.documentCategory, documentType : event.target.value})
            .then(result => {
                    this.docNameOptions = [
                    { label: 'Select Options', value: '' },
                    ...result.map(item => ({
                        label: item.code__c+': '+item.description__c,
                        value: item.Id
                    }))
                ];
            })
            .catch(error => {
                console.log('error ::',error);
            });
        }
    }
    
    handleNo(){
        this.sanctiondocTodelete = '';
        if(this.eventName != 'Main Table'){
            this.modalVisibility = true;
        }
        this.eventName = '';
        this.showConfirmation = false;
        this.sanctionIdtoDelete = '';
        this.showConfirmationSanctionDelete = false;
    }
    handleDocDelete () {
        console.log('this.sanctiondocTodelete',this.sanctiondocTodelete);
        deletedocumentIds({recordId: this.sanctiondocTodelete})
        .then((result) => {
            this.getCovenantDetails();
            this.showToastMessage('Success', 'Document deleted succesfully.', 'success');
            this.showConfirmation = false;
        })
        .catch((error) => {
            console.error('Error deleteDocIds --> ', JSON.stringify(error));
        });
    }

    async handleSave(event){

        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        console.log('isInputsCorrect  '+isInputsCorrect);
        
        if (!isInputsCorrect) {
         //perform success logic
            this.showToast('Validation Error', 'Target date cannot be a past date.', 'error');
            return; 
        }

        let duplicateFound = this.checkDuplicateCovenantDoc(this.docDetail)

        if(isInputsCorrect && !duplicateFound){
        if (this.docDetail){
            this.isLoading = true;
            this.docDetail['Requirement_At__c'] = 'Collateral Level';
            this.docDetail['RecordType.Name'] = 'Covenant Details';
            upsertDocumentDetails({documentDetails : this.docDetail , recordId: this.recordId})
            .then(result => {
                this.docDetail = {};
                this.isLoading = false;
                this.showToastMessage('Success', 'Document saved succesfully.', 'success');
                this.getCovenantDetails();
                this.showCovenantSection = false;
                this.docNameOptions =[{label: 'Select Options', value: '' }];
                this.documentType = '';
                this.documentCategory = '';
                this.descriptionValue = '';
                this.isDisable = false;
                this.showSummaryStyle = true;
            })
            .catch(error => {
                this.isLoading = false;
                console.log('error ::',error);
                let message = 'Unknown error';
                if (error.body && error.body.fieldErrors) {
                    const fieldErr = error.body.fieldErrors.Name;
                    if (fieldErr && fieldErr[0]) {
                        message = fieldErr[0].message;
                    }
                } else if (error.body && error.body.message) {
                    message = error.body.message;
                }
                this.showToast('Error', message, 'error');
            });
            }
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    handleClose(){
        this.showCovenantSection = false;
        this.documentDetail = {};
        this.showSummaryStyle = true;
        this.isDisable = false;
    }

    showToastMessage(title, message, type) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: type
        });
        this.dispatchEvent(toastEvent);
    }

    handleDeleteRecord(event){
        console.log('At 226',event);   
        this.isLoading = true;
        console.log('At 229',event.target.dataset.docid);
        deleteDocumentDetailRecord({docDetailId : event.target.dataset.docid})
        .then(result => {
            this.getCovenantDetails();
            this.isLoading = false;
            this.showToastMessage('Success', 'Document deleted succesfully.', 'success');
        })
        .catch(error => {
            console.log('error ::',error);
            this.showToastMessage('Error', 'Document not deleted.', 'error');
            this.isLoading = false;
        });
    }

    handleChange (event) {
        this.documentDetail = {};
        const field = event.target.name;
        console.log(event.target.dataset.id);
        console.log(event.target.dataset.docid);
        console.log('Field ',field);
        console.log('ids ', event.target.dataset.docid);
        // if(this.documentDetail['Document_Master__c'] == null){
            // this.documentDetail['Document_Master__c'] = event.target.dataset.id;
            if(event.target.dataset.docid){
                this.documentDetail['Id'] = event.target.dataset.docid;
            }
        // }
        this.documentDetail[field] = event.target.value;
        if(field == 'Covenant_Master__c'){
            getCovenantDetails({covenantId : event.target.value})
            .then(result => {
                console.log('result',result);;
                if (result && result.length > 0) {
                    const record = result[0];
                    console.log('326');
                    this.typeValue = record.covenanttype__c;
                    this.descriptionValue = record.description__c;
                    this.documentDetail['Name'] = record.code__c;
                    this.documentDetail['Document_Type__c'] = record.covenanttype__c;
                    this.documentDetail['Covenant_Id__c'] = record.Name;
                    this.documentDetail['Covenant_Doc_Type__c'] = record.doctype__c;
                    // this.documentDetail['Covenant_Master__c'] = event.target.value;
                    console.log('this.documentDetail>>>',this.documentDetail);
                }
            });
        }
        console.log('documentDetail handleChange  ', this.documentDetail);
    }
    
    handleOnBlur () {
        try{
            console.log('documentDetail handleOnBlur  ', this.documentDetail);
            const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
                .reduce((validSoFar, inputField) => {
                    inputField.reportValidity();
                    return validSoFar && inputField.checkValidity();
                }, true);
            console.log('isInputsCorrect  '+isInputsCorrect);
            if (!isInputsCorrect) {
                this.showToast('Validation Error', 'Target date cannot be a past date.', 'error');
                return; 
            }

            let duplicateFound = this.checkDuplicateCovenantDoc(this.documentDetail);
            if (this.documentDetail && isInputsCorrect && !duplicateFound){
                this.isLoading = true;
                upsertDocumentDetails({documentDetails : this.documentDetail , recordId: this.recordId})
                .then(result => {
                    this.getCovenantDetails();
                    this.documentDetail = {};
                    this.isLoading = false;
                })
                .catch(error => {
                    this.isLoading = false;
                    console.log('error ::',error);
                });
            }
        }
        catch{
            this.isLoading = false;
        }
    }

    updateDocumentDetails (event) {
        console.log('eventdocId',event?.detail?.docId);
        if (event?.detail?.docId) {
            this.documentDetail = {};
            this.documentDetail['Id'] = event?.detail?.docId;
            const today = new Date();
            this.documentDetail['Document_Date_of_Receipt__c'] = today.toISOString().slice(0, 10);         
            this.handleOnBlur();
        }
        
    }

    checkDuplicateCovenantDoc(docDetail){
        const newName = docDetail?.Name?.trim().toLowerCase();
        const newCovMasterId = docDetail?.Covenant_Master__c;//Sanwar(17/12/2025)

        let duplicateFound = false; 
        //Sanwar(17/12/2025)
        if (newCovMasterId && Array.isArray(this.detailRecord)) {
            for (const group of this.detailRecord) {
                if (Array.isArray(group.documentList)) {
                    for (const doc of group.documentList) {
                        const existCovMasterId = doc?.covenantMaster;
                        if (existCovMasterId === newCovMasterId) {
                            duplicateFound = true;
                            break;
                        }
                    }
                }
                if (duplicateFound) break;
            }
        }

        if (duplicateFound) {
            this.showToast(
                'Duplicate Document',
                `A document with the same Covenant Name already exists.`,
                'error'
            );
            return duplicateFound; 
        }
        return duplicateFound;
    }

}