import { LightningElement, api, track, wire } from 'lwc';
import getAllDocument from '@salesforce/apex/SalesDocumentCmpController.getAllDocument';
import getScreenDetails from '@salesforce/apex/ScreenGenerationController.getScreenDetails';
import getPicklistValues from '@salesforce/apex/ScreenGenerationController.getPicklistValues';
import getLoanDetailsFromStorageObject from '@salesforce/apex/ScreenGenerationController.getLoanDetailsFromStorageObject';
import saveAddressSource from '@salesforce/apex/COMM_SalesLoanLoginController.saveAddressSource';
import getOrCreateAddressRecords from '@salesforce/apex/COMM_SalesLoanLoginController.getOrCreateAddressRecords';
import getApplicantValues from '@salesforce/apex/COMM_SalesLoanLoginController.getApplicantValues';
import getRelatedDocAddressType from '@salesforce/apex/COMM_SalesLoanLoginController.getRelatedDocAddressType';
import getAllRelatedAddresses from '@salesforce/apex/COMM_SalesLoanLoginController.getAllRelatedAddresses';
import clonePrimaryAddress from '@salesforce/apex/COMM_SalesLoanLoginController.clonePrimaryAddress';
import clearCoApplicantAddress from '@salesforce/apex/COMM_SalesLoanLoginController.clearCoApplicantAddress';
import splitAddressType from '@salesforce/apex/COMM_SalesLoanLoginController.splitAddressType';
import shrinkAddressTypes from '@salesforce/apex/COMM_SalesLoanLoginController.shrinkAddressTypes';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFieldDependencies from '@salesforce/apex/ScreenGenerationController.getFieldDependencies';
import { getRecord, updateRecord } from "lightning/uiRecordApi";
import checkFieldValues from '@salesforce/apex/OCRProcessingService.checkFieldValues';
import checkExceptionStatus from '@salesforce/apex/COMM_SalesLoanLoginController.checkExceptionStatus';
import checkExistingAddresses from '@salesforce/apex/Utility_V1.checkExistingAddresses';
import checkExistingAddress from '@salesforce/apex/COMM_SalesLoanLoginController.checkExistingAddressWithDocument';
import saveTriangulationData from '@salesforce/apex/Utility.saveTriangulationDataManual';
import { validateDLNumber, validatePassportNumber, validateVoterIdNumber, validateAddress,panNumberValidation, validateNonIndividualPAN, gstNumberValidation } from 'c/utility';
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails'


const ALL_FIELDS = [
    'Application_Applicant__c.Pan_Name__c',
    'Application_Applicant__c.Date_of_Birth__c',
    'Application_Applicant__c.Father_Name__c'
];
export default class documentDetailsUpdateCmp extends LightningElement {
    _formIdentifier;
    @api
    get formIdentifier() {
        return this._formIdentifier;
    }
    set formIdentifier(value) {
        this._formIdentifier = value;
        console.log(' formIdentifier arrived:', value);
        if (value) {
            this.getScreenDetailsFromApex();
            this.getFIDetails();
        }
    }
    @api clearScreen() {
        this.fieldDetails = [];
        this.showfields = false;
    }
    @api applicantType;


    @api recordId;
    @api docCheckId;
    @api appId;
    @track documents = [];
    @track custTypeOptions = [{"label":"Individual","value":"Individual"},{"label":"Non Individual","value":"Non Individual"}];
    @api name;
    @api valid = false;
    @api ckyc = false;
    @api catg;
    @api validated = false;
    @api addressRecordId;
    @track allFieldDetails = [];
    @track fieldDetails = [];
    @track filteredScreenDetails = [];
    @track screenName;
    @track screenObject;
    @track PANPage = false;
    @track fieldsDataMap = {};
    @track fieldsObjectMap = {};
    @track passedScreenName;
    @track currentScreenSequence = 0;
    @track objectName = 'Application_Applicant__c';
    @track resultMap;
    @api editfields = false;
    @api bankId;
    noteditfields = false;;
    isSpinnerLoading = false;
    showfields = false;
    dde = false;
    @track ir = false;
    mfalse = false;
    addressType
    fieldAPIName;
    fieldAPIValue;
    isMultiSelect;
    multiselectValues = [];
    addressTypeValue = [];
    showMultiPicklist = false;
    addressDocType = [];
    selectedValues = [];
    allDocumentType = [];
    selectedConstitution;
    fromConnectedCallBack = true;
    isHLRelated;
    showAddressType = true;
    
    @wire(getRecord, { recordId: '$recordId', fields: ALL_FIELDS })
    wiredApplicant({ data, error }) {
        if (data) {
            console.log('Wired Applicant data:', data);
            this.fieldDetails = this.fieldDetails.map(f => {
                const fld = `Application_Applicant__c.${f.Storage_Field__c}`;
                const live = data.fields[f.Storage_Field__c];
                return {
                    ...f,
                    value: live?.value ?? f.value
                };
            });
            console.log('Updated fieldDetails with live data:', JSON.stringify(this.fieldDetails));
        }
    }
    renderedCallback() {
    }

    connectedCallback() {
        this.fetchProducDetails();
        this.getApplicantValues();
        this.getAllRelatedAddresses();
        this.getRelatedDocAddressType();
        console.log('formIdentifier ' + this.formIdentifier);
        console.log('appId ' + this.appId);
        console.log('name 42 : ' + this.name);
        console.log('valid 42 : ' + this.recordId);
        console.log('docCheckId 15: ' + this.docCheckId);
        console.log('REC++ ' + this.valid);
        console.log('catg++ ' + this.catg);
        console.log('Connected – formIdentifier is', this.formIdentifier);
        if (this.editfields) {
            this.noteditfields = false;
        }
        else {
            this.noteditfields = true;
        }
        
        this.passedScreenName = this.formIdentifier;
        if (this.catg == 'DDE') {
            this.isSpinnerLoading = true;
            this.dde = true;
        }
        
        else {
            this.dde = false;
        }
        if (this.catg == 'Income Related') {
            console.log('bankId ' + this.bankId);
            this.ir = true;
        }
        else {
            this.ir = false;
        }
    }
    checkUserProfile() {
        checkExceptionStatus({ loanId: this.recordId })
            .then(result => {
                console.log('Inside Profile true----', result);

                if (result) {

                    this.fieldDetails = this.fieldDetails.map(field => {
                        if (field.Field_Label__c) {
                            return { ...field, Is_Disabled__c: true };
                        }
                        return field;
                    });
                }
            })
            .catch(error => {
                console.error('Error in checkExceptionStatus:', error);
                const errorMessage = error?.body?.message || error?.message || 'Error checking exception status';
                this.showToastMessage('Error', errorMessage, 'error');
            });
    }
    getApplicantValues() {
        console.log('Error in 117:');
        const inputMap = {

            'applicantId': this.appId
        }
        getApplicantValues({ inputMap: inputMap })
            .then(result => {
                console.log('Error in 117:', JSON.stringify(result));
                this.customerType = result[0].customerType;
                this.selectedConstitution=result[0].sector;
                console.log('  this.customerType', this.customerType);
            })
            .catch(error => {
                console.error('Error in getApplicantValues:', error);
                const errorMessage = error?.body?.message || error?.message || 'Error fetching applicant values';
                this.showToastMessage('Error', errorMessage, 'error');
            });

    }
    getRelatedDocAddressType() {
        getRelatedDocAddressType({
            'docId': this.docCheckId
        })
            .then(result => {
                console.log('Error in 117:', JSON.stringify(result));
                if (result != null && result != undefined && result.length > 0) {
                    for (var i = 0; i < result.length; i++) {
                        if (!this.addressDocType.includes(result[i])) {
                            this.addressDocType.push(result[i]);
                        }

                    }
                }
            })
            .catch(error => {
                console.error('Error in getRelatedDocAddressType:', error);
                const errorMessage = error?.body?.message || error?.message || 'Error fetching document address types';
                this.showToastMessage('Error', errorMessage, 'error');
            });
    }

    getAllRelatedAddresses() {
        getAllRelatedAddresses({
            docheckId: this.docCheckId, appId: this.appId
        })
            .then(response => {
                if (response != null && response != undefined && response.length > 0) {
                    for (var i = 0; i < response.length; i++) {
                        if (!this.multiselectValues.includes(response[i])) {
                            this.multiselectValues.push(response[i]);
                        }

                    }
                }
                console.log('multiselectValues', JSON.stringify(this.multiselectValues));

            }).catch(error => {
                console.error('Error in getAllRelatedAddresses -->', JSON.stringify(error));
                const errorMessage = error?.body?.message || error?.message || 'Error fetching related addresses';
                this.showToastMessage('Error', errorMessage, 'error');
            });
    }

    getAllRelatedDocs() {
        getAllDocument({
            recordId: this.recordId, catg: this.catg, appId: this.appId
        }).then(response => {
            this.documents = response;
            console.log('this.documents -->' + JSON.stringify(this.documents));
        }).catch(error => {
            console.error('Error wiredDocuments file -->', JSON.stringify(error));
            const errorMessage = error?.body?.message || error?.message || 'Error fetching documents';
            this.showToastMessage('Error', errorMessage, 'error');
        });
    }
    showToastMessage(title, message, type) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: type
        });
        this.dispatchEvent(toastEvent);
    }

    openDetailedView(event) {
        console.log(JSON.stringify(event.target.dataset.id));
        this.dispatchEvent(new CustomEvent('handledocumentclick', { detail: { 'docId': event.target.dataset.id } }));

    }
    getScreenDetailsFromApex() {
        console.log('Fetching screen details for ►', this.formIdentifier);
        getScreenDetails({ formIdentifier: this.formIdentifier, loanId: this.recordId })
            .then(result => {
                if (result) {
                    this.allFieldDetails = result;
                    if (this.allFieldDetails.length === 0) {
                        console.log("Array is empty");
                        this.showfields = false;
                        this.isSpinnerLoading = false;
                    }
                    else {
                        this.showfields = true;
                        console.log("Array is not empty");
                        this.isSpinnerLoading = true;
                    }
                    console.log('inside screen seq getScrrefromapex=:' + this.currentScreenSequence);
                    console.log('getScreenDetailsFromApex allFieldDetails=:' + JSON.stringify(this.allFieldDetails));
                    this.getCurrentScreenFieldDetails();
                }
            }).catch(error => {
                console.log('error in getScreenDetailsFromApex: ' + error);
                this.isSpinnerLoading = false;
                const errorMessage = error?.body?.message || error?.message || 'Error fetching screen details';
                this.showToastMessage('Error', errorMessage, 'error');
            });

    }
    getCurrentScreenFieldDetails() {
        console.log('this.allFieldDetails=:' + JSON.stringify(this.allFieldDetails));
        console.log('this.passedScreenName=: 104 ' + this.passedScreenName);
        if (this.passedScreenName) {
            this.filteredScreenDetails = this.allFieldDetails.filter(item => item.Parent_Screen__r.Master_Screen_Name__c == this.passedScreenName);
            console.log('filteredScreenDetails : ', JSON.stringify(this.filteredScreenDetails));
            this.filteredScreenDetails.forEach(item => { this.currentSeq = item.Parent_Screen__r.Screen_Sequence__c; });
            console.log('currentSeq : ', this.currentSeq);
            this.currentScreenSequence = this.currentSeq;
        }
        console.log('this.currentScreenSequence=:' + this.currentScreenSequence);
        this.filteredScreenDetails = this.allFieldDetails.filter(item => item.Parent_Screen__r.Screen_Sequence__c == this.currentScreenSequence);
        this.filteredScreenDetails = this.filteredScreenDetails.filter(item => {
            if (!item.Applicant_Type_Visibility__c) {
                return true;
            }
            const allowedTypes = item.Applicant_Type_Visibility__c.split(';').map(v => v.trim().toLowerCase());
            const currentType = (this.applicantType || '').toLowerCase();
            return allowedTypes.includes(currentType);
        });
        this.filteredScreenDetails.forEach(item => { this.screenName = item.Parent_Screen__r.Master_Screen_Name__c; });
        this.filteredScreenDetails.forEach(item => { this.screenObject = item.Storage_Object__c; });
        this.fieldDetails = this.filteredScreenDetails.map(item => ({ ...item }));
        console.log('104 fieldDetails ' + JSON.stringify(this.fieldDetails));
        this.fieldDetails.forEach(item => {
            item.isPicklist = item.Field_Type__c === 'Picklist';
        });
        
        if (this.isSameAsPrimary) {
            this.fieldDetails = this.fieldDetails.map(field => {
                if (field.Storage_Field__c === 'Same_As_Primary_Applicant__c') {
                    return { ...field, Is_Disabled__c: false };
                }
                return field;
            });
        }
        
        this.fieldDetails.forEach(async item => {
            if(item.Parent_Screen__r.Form_Name__c === 'PAN'){
                item.picklistOptions = [{"label":"Individual","value":"Individual"},{"label":"Non Individual","value":"Non Individual"}];
            }
            else{
            item.picklistOptions = await this.getPicklistOptionsFromApex(item.isPicklist, item.Storage_Object__c, item.Storage_Field__c);
            console.log('item.picklistOptions 174 Kshitiz: ' + JSON.stringify(item.picklistOptions));}
        });
       
        this.fieldDetails.forEach(item => {
            if (item.is_Lookup__c) {
                console.log('inside item.is_Lookup__c --> item.Storage_Field__c --> ' + item.Storage_Field__c);
                if (item.Storage_Field__c.includes('Branch__') && !item.Storage_Field__c.includes('Sub_Branch__')) {
                    item.showBranchLookup = true;
                } else if (item.Storage_Field__c.includes('Pincode__')) {
                } else if (item.Storage_Field__c.includes('Branch_Master__')) {
                    item.showBranchLookup = true
                } else if (item.Storage_Field__c.includes('Lead__r.Channel__c')) {
                    item.showLeadChannelLookup = true
                }
            }
        });
        console.log('Final fieldDetails to show  Kshitiz' + JSON.stringify(this.fieldDetails));
        console.log('this.name 194 Kshitiz: ' + this.name);
        if(this.name == 'PAN'){
             this.fieldDetails = this.fieldDetails.map(field => {
                console.log('field.Field_Label__c----',field.Field_Label__c);
                 if (field.Field_Label__c) {
                        return { ...field, Is_Disabled__c: true };
                }
                        return field;
                    });
        }
        this.passedScreenName = null;
        setTimeout(() => {
            this.getFIDetails();
        }, 500);
    }
    async getPicklistOptionsFromApex(isPicklist, storageObject, storageField) {

        if (isPicklist) {
            let picklistOptions
            if (storageField === 'Address_Type__c') {
                this.showMultiPicklist = false;

                picklistOptions = this.addressDocType.map(item => {
                    if (this.multiselectValues.includes(item)) {
                        this.fieldDetails.forEach(field => {
                            if (field.Field_Type__c == 'Checkbox') {
                                if (!this.multiselectValues.includes(field.Enable_for__c)) {
                                    field.Is_Disabled__c = true;
                                }
                            }
                        });
                    }
                    if (this.multiselectValues.includes(item)) {
                        return {
                            label: item,
                            value: item,
                            checked: true
                        };
                    }
                    else {
                        return {
                            label: item,
                            value: item,
                            checked: false
                        };
                    }

                });

                setTimeout(() => {
                    this.showMultiPicklist = true;
                }, 100);

            }

            else {
                try {
                    const result = await getPicklistValues({ storageObject: storageObject, storageField: storageField });
                    picklistOptions = result.map(option => {
                        return {
                            label: option.label,
                            value: option.value
                        };
                    });
                    console.log('picklistOptions!', JSON.stringify(picklistOptions));
                } catch (error) {
                    console.error('Error in getPicklistOptionsFromApex:', error);
                    const errorMessage = error?.body?.message || error?.message || 'Error fetching picklist values';
                    this.showToastMessage('Error', errorMessage, 'error');
                    picklistOptions = [];
                }
            }

            return picklistOptions;
        }
    }
    getFIDetails() {
        console.log('Fetching existing field values for ', this.formIdentifier);
        console.log('screenName1 ' + this.screenName);
        console.log('screenName2' + this.name);
        let recId;
        if (this.ir) {
            recId = this.bankId;
        }
        else {
            recId = this.appId;
        }
        console.log('apps ' + this.appId);
        console.log('recId ' + recId);
        console.log('formnamee ' + this.name);
        let shouldRerenderPincode = false;
        getLoanDetailsFromStorageObject({
            screenName: this.formIdentifier,
            loanId: this.recordId,
            formIdentifier: this.formIdentifier,
            recordId: recId,
            did: this.docCheckId
        }).then(result => {
            this.showLoader = false;
            var isFetchFromReadObject = true;
            console.log('Apex returned field values:', result);
            if (this.fieldDetails) {
                result.forEach(item => {
                    isFetchFromReadObject = false;
                    console.log(' this.fieldDetails----- 21333' + JSON.stringify(this.fieldDetails));
                    this.fieldDetails.forEach(record => {
                        if(record.Field_Type__c == 'Checkbox'){
                            record.isCheckbox = true;
                        }
                        if (item.fieldApiName == record.Storage_Field__c && record.is_Lookup__c == true) {
                            if (record.Storage_Field__c === 'Document_Master__r.Document_Category__c') {
                                record.savedName = item.fieldValue;
                                record.value = item.fieldValue; 
                            } 
                            else if (record.Storage_Field__c == 'Document_Master__r.Document_Type__c') {
                                record.savedName = item.lookUpfieldValue;
                                record.value = item.fieldValue;
                            } else if (record.Storage_Field__c == 'Pincode__r.Name') {
                                console.log('inside pincode----');
                                console.log('item.fieldValue pincode----', item);

                                record.savedName = item.fieldValue;
                                record.value = item.lookUpfieldValue;
                                record.showPinCodeLookup = true;
                                shouldRerenderPincode = true;
                                console.log(' record.showPinCodeLookup ---', record.showPinCodeLookup);
                            } else {
                                record.savedName = item.fieldValue;
                                record.value = item.lookUpfieldValue;
                            }

                            console.log('record -->' + JSON.stringify(record));
                        } else if (item.fieldApiName == record.Storage_Field__c) {
                            record.value = item.fieldValue;
                            if (record.Storage_Field__c === 'Address_Type__c' && record.Is_Multipicklist__c) {
                                if (item.fieldValue) {
                                    const selectedValues = item.fieldValue
                                        .split(';')
                                        .map(v => v.trim().toLowerCase());

                                    record.picklistOptions = record.picklistOptions.map(opt => ({
                                        ...opt,
                                        checked: selectedValues.includes(opt.value.toLowerCase())
                                    }));

                                    record.value = item.fieldValue;
                                }
                            }
                        }
                        if (item.fieldApiName === 'Same_As_Primary_Applicant__c') {
                            this.isSameAsPrimary = item.fieldValue === true;

                            this.fieldDetails = this.fieldDetails.map(f =>
                                f.Storage_Field__c === 'Same_As_Primary_Applicant__c'
                                    ? { ...f, value: this.isSameAsPrimary }
                                    : f
                            );
                        }
                        if (item.fieldApiName == 'Address_Source__c') {
                            console.log(' this.fieldDetails----- 21333' + item.fieldValue);
                            this.addressSource = item.fieldValue;
                        }
                        if (item.fieldApiName == 'Address_Type__c') {
                            console.log(' this.fieldDetails----- 21333' + item.fieldValue);
                            this.addressType = item.fieldValue;
                        }
                        if (item.fieldApiName === 'Document_Master__r.Document_Category__c') {
                            console.log('Document Category captured:', item.fieldValue);
                            this.documentCategory = item.fieldValue;
                        }
                        this.isSpinnerLoading = false;
                    });
                    console.log('fieldDetails 173' + JSON.stringify(this.fieldDetails));
                });
                this.fieldDetails = [...this.fieldDetails];
                if (shouldRerenderPincode) {
                    this.forcePincodeRerender();
                }

                setTimeout(() => {
                    this.isSpinnerLoading = false;
                    console.log(' this.fieldDetails  436=:' + this.fieldDetails);
                    this.fieldDetails.forEach(record => {
                        let isHandled = false;
                        if (record.Storage_Field__c === 'Document_Master__r.Document_Category__c') {
                            record.hideField = true;
                            isHandled = true;
                        }
                        if (record.Storage_Field__c === 'Same_As_Primary_Applicant__c') {
                            const isPoa = (this.documentCategory || '').toLowerCase() === 'poa';
                            record.hideField = !isPoa;
                            isHandled = true;
                        }
                        try {
                            if (!isHandled) {
                                if (record.Visibility_Controlled_By__c != null && record.Visibility_Controlled_By__c != '' && record.Visibility_Controlled_By__c != undefined) {
                                    console.log('record.Storage_Field__c=:' + record.Storage_Field__c);
                                    const dependentField = this.fieldDetails.find(item => item.Id == record.Visibility_Controlled_By__c);
                                    console.log('dependentField=:' + JSON.stringify(dependentField));
                                    const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                                    console.log('arrDependentControlledValue=:' + JSON.stringify(arrDependentControlledValue));
                                    if (dependentField.value != null && dependentField.value != '' && dependentField.value && dependentField.value != undefined) {
                                        console.log('inside if KD');
                                        if (arrDependentControlledValue.find(element => element == dependentField.value.toLowerCase())) {
                                            record.hideField = false;
                                        }
                                        else {
                                            record.hideField = true;
                                            console.log('inside hide KD');
                                        }
                                    } else {
                                        record.hideField = false;
                                        console.log('inside else KD');
                                    }
                                }
                                else {
                                    record.hideField = false;
                                }
                                if(this.addressType == null || this.addressType == '' || this.addressType == undefined){
                                    if(record.Storage_Field__c == 'Flag_Current_Registred_as_Very_High__c' || record.Storage_Field__c == 'Flag_PO_as_High__c'){
                                        record.hideField = true;
                                    }
                                }
                            }
                        }
                        catch (error) {
                            console.log('record=:' + record.Storage_Field__c);
                            console.log('error=:' + error);
                            console.log('str error=:' + JSON.stringify(error));
                        }
                    });
                    if (this.isSameAsPrimary) {
                        this.fieldDetails = this.fieldDetails.map(field => {
                            if (field.Storage_Field__c === 'Same_As_Primary_Applicant__c') {
                                return { ...field, Is_Disabled__c: false };
                            }
                            return field;
                        });
                    }
                }, 1000);
            }
            else {
                this.isSpinnerLoading = false;
            }

            return ({ isFetchFromReadObject: isFetchFromReadObject });
        }).then(res => {
            if (res.isFetchFromReadObject) {
                this.getLoanDetailsFromReadObject();
            }
        })
            .catch(error => {
                this.isSpinnerLoading = false;
                const errorMessage = error?.body?.message || error?.message || 'Error fetching field details';
                this.showToastMessage('Error', errorMessage, 'error');
            })
    }
    
    forcePincodeRerender() {
        this.fieldDetails = this.fieldDetails.map(f =>
            f.Storage_Field__c === 'Pincode__r.Name'
                ? { ...f, forceRender: false }
                : f
        );

        setTimeout(() => {
            this.fieldDetails = this.fieldDetails.map(f =>
                f.Storage_Field__c === 'Pincode__r.Name'
                    ? { ...f, forceRender: true }
                    : f
            );
        }, 0);
    }
    
    resetAddressTypeUI() {
        this.fieldDetails = this.fieldDetails.map(f => {
            if (f.Storage_Field__c === 'Address_Type__c') {
                return {
                    ...JSON.parse(JSON.stringify(f)), 
                    picklistOptions: f.picklistOptions.map(opt => ({
                        ...opt,
                        checked: false
                    })),
                    value: ''
                };
            }
            return f;
        });

        this.multiselectValues = [];
        this.addressType = '';
        this.showAddressType = false;

        Promise.resolve().then(() => {
            this.multiPicklistKey++;
            this.showAddressType = true;
        });
    }

    handleEditClick(event) {
        const fieldId = event.target.dataset.id;
        for (let item of this.fieldDetails) {
            if (item.Id === fieldId) {
                item.Is_Disabled__c = false;
                break;
            }
        }
        this.fieldDetails = [...this.fieldDetails];
    }

    _isValidPersonName(value) {
    const s = (value ?? '').toString().trim();
    return s.length >= 3 && /^[A-Za-z ]+$/.test(s);
    }

    _normalizeAadhaar(raw) {
    return (raw ?? '').toString().replace(/\D+/g, '');
    }

    _isValidAadhaar(a12) {
    return /^[2-9]\d{11}$/.test(a12);
    }

    _saveAddressFlag(currentId, currentField, recordIdToUpdate) {
        this.fieldAPIName = currentId;
        this.fieldAPIValue = true;
        this.fieldDetails = this.fieldDetails.map(f =>
            f.Storage_Field__c === currentId ? { ...f, value: true } : f
        );
        this.saveAddressType();
        if (this.formIdentifier != null) {
            setTimeout(() => {
                this.setTriangulationData(this.formIdentifier, this.appId, true);
            }, 500);
        }
        const valueChangeEvent = new CustomEvent("updatedapplicants", {
            detail: { value: recordIdToUpdate, valuesChanged: true }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    handleInputChange(event) {
        this.isMultiSelect = false;
        const currentId = event.target.dataset.id;
        const currentField = event.target.dataset.name;
        const isCheckbox = event.target.type === 'checkbox';
        let currentValue = isCheckbox ? event.target.checked : event.target.value;
        this.fieldAPIName = event.target.dataset.id;
        const inputType = (event.target?.type || '').toLowerCase();
        
        if (currentId === 'Same_As_Primary_Applicant__c') {
            const isChecked = event.target.checked;
            this.fieldDetails = this.fieldDetails.map(f =>
                f.Storage_Field__c === currentId ? { ...f, value: isChecked } : f
            );
            if (isChecked) {
                if (this.isCloningInProgress) return;
                this.isCloningInProgress = true;
                clonePrimaryAddress({coApplicantId: this.appId, docDetailId: this.docCheckId, documentName: this.name, category: this.catg})
                .then(() => {
                    this.showToastMessage('Success', 'Address copied from Primary Applicant', 'success');
                    setTimeout(() => {
                        this.getFIDetails();
                    }, 300);
                })
                .catch(err => {
                    console.error('Error cloning primary address:', err);
                    const errorMessage = err?.body?.message || err?.message || 'Error copying address';
                    this.showToastMessage('Error', errorMessage, 'error');
                })
                .finally(() => {
                    console.log('After update:', JSON.stringify(this.addressFields));
                    this.isCloningInProgress = false;
                });
            }
            else {
                this.resetAddressTypeUI();
                clearCoApplicantAddress({ docDetailId: this.docCheckId})
                .then(() => {
                    this.showToastMessage('Success', 'Address cleared. You can enter address manually.', 'success');
                    setTimeout(() => {
                        this.getFIDetails();
                    }, 300);
                })
                .catch(err => {
                    console.error('Error clearing co-applicant address:', err);
                    const errorMessage = err?.body?.message || err?.message || 'Error clearing address';
                    this.showToastMessage('Error', errorMessage, 'error');
                });
            }
            return;
        }
        
        const dateFieldsByApi = [
            'Passport_Date_of_Issue__c',
            'Passport_Date_of_Birth__c',
            'Date_of_Birth__c'
        ];
        const isDateish =
            inputType === 'date' ||
            inputType === 'datetime' ||
            inputType === 'datetime-local' ||
            dateFieldsByApi.includes(currentId);
        console.log('currentId -->', currentId, 'currentValue -->', currentValue);
        if (event.target.value) {
            this.fieldAPIValue = event.target.value;
        }
        if (currentId == 'Flag_Current_Registred_as_Very_High__c' || currentId == 'Flag_PO_as_High__c') {
            this.fieldAPIValue = event.target.checked;
        }
      
        if (['Address_Line_1__c', 'Address_Line_2__c', 'Address_Line_3__c'].includes(currentId)) {
            if (currentValue.length > 50) {
                this.showToastMessage('Invalid Input', `${event.currentTarget.label} cannot exceed 50 characters.`, 'error');
                return;
            }
            if (!validateAddress(currentValue)) {
                this.showToastMessage('Invalid Input', 'Please enter address in correct format.', 'error');
                return;
            }
        }
        if (currentId === 'Drivers_License_Number__c' && !validateDLNumber(currentValue)) {
            this.showToastMessage('Error', 'Please enter driving license in correct format.', 'error');
                return;
            }
        if (currentId === 'Passport_Number__c' && !validatePassportNumber(currentValue)) {
            this.showToastMessage('Error', 'Please enter passport number in correct format.', 'error');
            return;
        }
        if (currentId === 'Voter_ID_Number__c' && !validateVoterIdNumber(currentValue)) {
            this.showToastMessage('Error', 'Please enter voter ID in correct format.', 'error');
                return;
            }

        const addressFields = [
            'Address_Line_1__c',
            'Address_Line_2__c',
            'Address_Line_3__c',
            'Address_Type__c',
            'Address_Ownership__c'
        ];
        const recordIdToUpdate = addressFields.includes(currentId)
            ? this.addressRecordId
            : (currentField == 'Document_Details__c' ? this.docCheckId : this.appId);

        if ((currentId == 'Flag_Current_Registred_as_Very_High__c' || currentId == 'Flag_PO_as_High__c') && event.target.checked == true) {
            checkExistingAddress({ applicantId: this.appId, addressField: currentId, formIdentifier: this.formIdentifier, docId: this.addressRecordId  })
                .then(result => {
                    if (result) {
                        console.log('661--',JSON.stringify(result));
                        this.fieldAPIValue = false;
                        this.showToastMessage('Duplicate Address', 'An address with this priority already exists and is linked with a document.', 'error');
                        this.getRelatedDocAddressType();
                        this.getCurrentScreenFieldDetails();
                        this.saveAddressType();
                        console.log('this.fieldDetails--', this.fieldDetails);
                        this.fieldDetails.forEach(field => {
                            field.hideField = true;
                            console.log('this.fieldDetails 670--',field.hideField);
                            field.value = false;
                            console.log('this.fieldDetails 670--',field.value);
                            setTimeout(() => {
                                field.hideField = false;
                            }, 100);
                        });
                    }
                    else {
                        this._saveAddressFlag(currentId, currentField, recordIdToUpdate);
                    }
                })
                .catch(error => {
                    console.error('Error checking existing address:', error);
                    const errorMessage = error?.body?.message || error?.message || 'Error checking existing address';
                    this.showToastMessage('Error', errorMessage, 'error');
                });
            return;
        }

        console.log('will update', currentId, 'on record', recordIdToUpdate);
        if (!isDateish) {
            this.fieldDetails = this.fieldDetails.map(f =>
                f.Storage_Field__c === currentId ? { ...f, value: currentValue } : f
            );
        }
        const opts = isDateish
            ? { suppressRefresh: true, suppressEvent: true }
            : { suppressRefresh: false, suppressEvent: false };

        if (isDateish && typeof event.target.blur === 'function') {
            try { event.target.blur(); } catch (_) { }
        }

        {
            const id = currentId;
            const val = this.normalizeDocValue
                ? this.normalizeDocValue(currentValue)
                : (currentValue ?? '').toString().trim().toUpperCase();

            if (['PAN_Number__c'].includes(id)) {
                const isIndividual = this.customerType === 'Individual';

                const ok = isIndividual
                    ? panNumberValidation(val)
                    : validateNonIndividualPAN(val, this.selectedConstitution);

                if (!ok) {
                    this.showToastMessage(
                        'Error',
                        isIndividual
                            ? 'Please enter a valid PAN Number.'
                            : `Please enter a valid PAN Number.`,
                        'error'
                    );
                    return;
                }
            }

            if (['GST_Number__c', 'GSTIN__c'].includes(id)) {
                if (!gstNumberValidation(val)) {
                    this.showToastMessage('Error', 'Please enter GST number in correct format.', 'error');
                    return;
                }
            }
        }
        {
            const id  = currentId;
            const raw = currentValue;

            const personNameFields = new Map([
                ['Pan_Name__c','Please enter a valid PAN Name.'],
                ['Pan_Father_s_Name__c', "Please enter a valid PAN Father's Name."],
                ['Voter_ID_First_Name__c', 'Please enter a valid Voter ID First Name.'],
                ['Voter_ID_Last_Name__c',  'Please enter a valid Voter ID Last Name.']
            ]);

            if (personNameFields.has(id)) {
                if (!this._isValidPersonName(raw)) {
                this.showToastMessage('Error', personNameFields.get(id), 'error');
                return;
                }
            }
        }
        {
            const id  = currentId;
            const raw = currentValue;
            let valueForSave= raw; 
            if (id === 'Aadhaar_Number__c') {
                const cleaned = this._normalizeAadhaar(raw);

                if (!cleaned) {
                this.showToastMessage('Error', 'Please Fill Aadhar Number.', 'error');
                return;
                }
                if (!this._isValidAadhaar(cleaned)) {
                this.showToastMessage('Error', 'Please enter Aadhar Number in correct format.', 'error');
                return;
                }
                valueForSave = cleaned;
            }
        }

        if (currentId != 'Address_Type__c' && currentId != 'Address_Line_1__c' && currentId != 'Address_Line_2__c' && currentId != 'Address_Line_3__c' && currentId != 'Flag_Current_Registred_as_Very_High__c' && currentId != 'Flag_PO_as_High__c' && currentId != 'Address_Ownership__c') {
        this.updateRecordField(recordIdToUpdate, currentId, currentValue, opts)
            .then(() => {
                if (isDateish) {
                    window.clearTimeout(this._dateRefreshTimer);
                    this._dateRefreshTimer = window.setTimeout(() => {
                        if (this.isConnected) this.getFIDetails();
                    }, 300);
                }
                console.log('Inside 764 documentsss------');
                const valueChangeEvent2 = new CustomEvent("updatedapplicants", {
                    detail: {
                        value: recordIdToUpdate,
                        valuesChanged: true

                    }
                });
                this.dispatchEvent(valueChangeEvent2);
                console.log('Inside 764 documentsss------');
            })
            .catch(err => {
            console.error('Error saving', currentId, err);
            const messages = this.getLdsErrorMessages(err);
            this.showToastMessage('Error', messages.join('\n'), 'error');
        });
                }
                if (this.formIdentifier != null) {
                    setTimeout(() => {
                        this.saveAddressType();
                        this.setTriangulationData(this.formIdentifier, this.appId, currentValue);
                    }, 500)
                }

    }
    normalizeDocValue(v) {
        return (v ?? '').toString().trim().toUpperCase();
    }

    setTriangulationData(formIndentifier, appId, currentValue) {
        console.log('docName: ' + formIndentifier + ' // this.fieldAPIName: ' + this.fieldAPIName + ' // appId: ' + appId + ' // currentValue: ' + currentValue + ' // loanId: ' + this.recordId);
        saveTriangulationData({ docName: formIndentifier, fieldAPIName: this.fieldAPIName, appId: appId, currentValue: currentValue, loanId: this.recordId })
            .then(result => {
                console.log('Success saveTriangulationData');
            })
            .catch(error => {
                console.error('Error in saveTriangulationData:', JSON.stringify(error));
                const errorMessage = error?.body?.message || error?.message || 'Error saving triangulation data';
                this.showToastMessage('Error', errorMessage, 'error');
            })
    }

    saveAddressType() {
        saveAddressSource({
            applicantId: this.appId,
            fieldAPIName: this.fieldAPIName,
            fieldAPIValue: this.fieldAPIValue,
            multiselectValues: this.multiselectValues,
            formIdentifier: this.formIdentifier,
            docId: this.docCheckId,
            addressTypeValue: this.addressTypeValue
        })
            .then(result => {
                this.resultMap = result;
                this.getFIDetails();
            })
            .catch(error => {
                console.error('Error in saveAddressSource:', error);
                const errorMessage = error?.body?.message || error?.message || 'Error saving address information';
                this.showToastMessage('Error', errorMessage, 'error');
            })

    }

    updateRecordField(recordId, fieldApiName, fieldValue, opts = {}) {
        const { suppressRefresh = false, suppressEvent = false } = opts;

        const fields = { Id: recordId, [fieldApiName]: fieldValue };
        const recordInput = { fields };

        return updateRecord(recordInput)
            .then(() => {
                if (!suppressEvent) {
                    this.dispatchEvent(new CustomEvent('updatedapplicants', {
                        detail: { value: recordId, valuesChanged: true }
                    }));
                }
                if (!suppressRefresh) {
                    return this.getFIDetails();
                }
                return null;
            })
            .catch(error => {
                console.error('Error updating record: ', error);
                throw error;
            });
    }

    hanldefieldCheck() {
        checkFieldValues({
            docName: this.name,
            recordId: this.appId,
        })
            .then(result => {
                this.resultMap = result;
                console.log('OCR Data Processed:', this.resultMap);
            })
            .catch(error => {
                console.error('Error processing OCR data:', error);
                const errorMessage = error?.body?.message || error?.message || 'Error processing OCR data';
                this.showToastMessage('Error', errorMessage, 'error');
            });

    }

    handlepincodelookupselected(event) {
        try {
            console.log('inside search');
            this.fieldDetails.forEach(record => {
                if (record.Read_Field_Name__c.includes('Pincode__') && record.Storage_Field__c.includes('Pincode__')) {
                    record.savedName = event.detail.searchRecord.Name;
                    record.value = event.detail.searchRecord.Id;
                    this.fieldAPIName = 'Pincode__c'
                    this.fieldAPIValue = event.detail.searchRecord.Id;
                }
            });

            if (this.formIdentifier != null) {
                this.saveAddressType();
            }

        } catch (error) {
            console.error('Error in handlepincodelookupselected:', error);
            const errorMessage = error?.body?.message || error?.message || 'Error selecting pincode';
            this.showToastMessage('Error', errorMessage, 'error');
        }

    }

    handlepincodelookupdeselected(event) {
        try {
            setTimeout(() => {
                this.fieldDetails.forEach(record => {
                    if (record.Read_Field_Name__c.includes('Pincode__') && record.Storage_Field__c.includes('Pincode__')) {
                        record.value = '';
                        record.savedName = '';
                    } else if (record.Read_Field_Name__c == 'Town__c' && record.Storage_Field__c == 'Town__c') {
                        record.value = '';
                    } else if (record.Read_Field_Name__c == 'District__c' && record.Storage_Field__c == 'District__c') {
                        record.value = '';
                    } else if (record.Read_Field_Name__c == 'State__c' && record.Storage_Field__c == 'State__c') {
                        record.value = '';
                    } else if (record.Read_Field_Name__c == 'Post_Office__c' && record.Storage_Field__c == 'Post_Office__c') {
                        record.value = '';
                    }
                });

            }, 100)
            this.fieldAPIName = 'Pincode__c'
            this.fieldAPIValue = '';

            if (this.formIdentifier != null) {
                this.saveAddressType();
            }
        } catch (error) {
            console.error('Error in handlepincodelookupdeselected:', error);
            const errorMessage = error?.body?.message || error?.message || 'Error deselecting pincode';
            this.showToastMessage('Error', errorMessage, 'error');
        }
    }

    handleBlur(event) {
        console.log('inside handle blur: ');
        const currentId = event.target.dataset.id;
        const currentField = event.target.dataset.name;
        const currentValue = event.target.value;
        const currentLabel = event.target.label;
        console.log('currentId in handleBlur --> ' + currentId);
        console.log('currentField in handleBlur--> ' + currentField);
        console.log('currentValue in handleBlur--> ' + currentValue);
        console.log('currentLabel in handleBlur--> ' + currentLabel);
        if (currentId == 'Masked_Aadhar_Number__c') {
            console.log('557');
            console.log('Masked_Aadhar_Number__c currentValue in handleBlur--> ' + currentValue);
            const isMasked = /^X{8}\d{4}$/.test(currentValue);
            if (isMasked) {
                console.log('Masked Aadhaar detected, skipping validation.');
            }
            else {
                const isValid = /^\d{12}$/.test(currentValue);
                if (!isValid) {
                    this.showToastMessage('Invalid Input', 'Please enter a valid Aadhaar number.', 'error');
                    event.target.value = '';
                }

            }

        }
    }

   
    handleMultiPicklistSelection(event) {
        let tempSelectedValues = [];
        let picklistOptions;
        console.log('event=:'+event);
        let selectedList = event.detail.selectedList;
        let currentSelectedVal = event.detail.currVal;
        if (selectedList.length > 0) {
            console.log('inside search'+selectedList)
            var listVal=[];
            console.log('selectedList.contains(', ')=:'+selectedList.includes(', '));
            if(selectedList.includes(', ')){
                listVal = selectedList.split(', ');
            }
            else{
                console.log('selectedList=:'+selectedList);
                listVal.push(selectedList)
            }
            console.log('listVal'+listVal)
            console.log('currentSelectedVal=:'+currentSelectedVal);
            if(this.isHLRelated){
                  checkExistingAddresses({ applicantId: this.appId, addressTypes: currentSelectedVal })
                    .then(dup => {
                        if (dup) {

                            this.showToastMessage('Duplicate Address Type',
                                'An address with this type already exists.', 'error');
                            this.filteredScreenDetails = [];
                            this.fieldDetails = [];
                            setTimeout(()=>{
                                this.getCurrentScreenFieldDetails();
                            },100)
                            return;
                        }
                        else{
                            this.isMultiSelect = true
                            for (let i = 0; i < selectedList.length; i++) {
                                if (!this.allDocumentType.includes(selectedList[i]) && (!this.multiselectValues.includes(selectedList[i]))) {
                                    tempSelectedValues.push(selectedList[i]);
                                }
                            }
                            console.log('selectedList',selectedList);
                            this.multiselectValues = selectedList;
                            this.saveAddressType();
                            this.fieldDetails.forEach(field => {
                                console.log('field',JSON.stringify(field));
                                if (field.Enable_for__c) {
                                    console.log('1004', field.value);
                                    if (this.multiselectValues.includes(field.Enable_for__c)) {
                                        field.value = false;
                                        field.hideField = true;
                                        field.Is_Disabled__c = false;
                                        setTimeout(() => {
                                            field.hideField = false;
                                        }, 100);
                                    } else {
                                        field.value = false;
                                        field.hideField = true;
                                        field.Is_Disabled__c = true;
                                        setTimeout(() => {
                                            field.hideField = false;
                                        }, 100);
                                    }
                                }
                            });
                        }
                    })
                    .catch(error => {
                        console.error('Error checking existing addresses:', error);
                        const errorMessage = error?.body?.message || error?.message || 'Error checking existing addresses';
                        this.showToastMessage('Error', errorMessage, 'error');
                    });
            }
            else{
                this.isMultiSelect = true
                for (let i = 0; i < selectedList.length; i++) {
                    if (!this.allDocumentType.includes(selectedList[i]) && (!this.multiselectValues.includes(selectedList[i]))) {
                        tempSelectedValues.push(selectedList[i]);
                    }
                }
                console.log('selectedList',selectedList);
                this.multiselectValues = selectedList;
                this.saveAddressType();
                this.fieldDetails.forEach(field => {
                    console.log('field',JSON.stringify(field));
                    if (field.Enable_for__c) {
                        console.log('1004', field.value);
                        if (this.multiselectValues.includes(field.Enable_for__c)) {
                            field.value = false;
                            field.hideField = true;
                            field.Is_Disabled__c = false;
                            setTimeout(() => {
                                field.hideField = false;
                            }, 100);
                        } else {
                            field.value = false;
                            field.hideField = true;
                            field.Is_Disabled__c = true;
                            setTimeout(() => {
                                field.hideField = false;
                            }, 100);
                        }
                    }
                });
            }
          
        }
        else {
            
            this.multiselectValues = [];
            this.saveAddressType();
            if (this.multiselectValues.length == 0) {
                this.fieldDetails.forEach(record => {
                    if (this.formIdentifier == record.Parent_Screen__r.Form_Name__c && record.Storage_Object__c == 'Applicant_Address__c') {
                        if (record.Field_Type__c == 'Checkbox') {
                            record.hideField = true;
                            if (record.Field_Type__c == 'Checkbox') {
                                record.Is_Disabled__c = true;
                                record.value = false;
                            }
                        }
                    }
                });
                
            }
        }
    }

    @api
    showOCRValidationResults(validationResult) {
        console.log('Showing OCR validation results:', validationResult);

        try {
            this.fieldDetails.forEach(field => {
                const fieldApiName = field.Storage_Field__c;

                if (validationResult.hasOwnProperty(fieldApiName)) {
                    const isValid = validationResult[fieldApiName];

                    if (isValid) {
                        field.ocrStatus = 'valid';
                        field.ocrMessage = 'OCR validation passed';
                        field.ocrClass = 'slds-border_success';
                    } else {
                        field.ocrStatus = 'needs-review';
                        field.ocrMessage = 'Please verify this field';
                        field.ocrClass = 'slds-border_warning';
                    }

                    field.showOCRIndicator = true;
                }
            });

            this.fieldDetails = [...this.fieldDetails];

            this.showToastMessage('Info', 'OCR validation results applied. Green borders indicate validated fields.', 'info');

        } catch (error) {
            console.error('Error showing OCR validation:', error);
            this.showToastMessage('Error', 'Error applying OCR validation results', 'error');
        }

    }
    @api
    populateFieldsFromOCR(ocrMap) {
        console.log('populateFieldsFromOCR called with:', ocrMap);

        if (!ocrMap || !this.fieldDetails.length) {
            console.log('No OCR data or field details');
            return;
        }

        console.log('Step 1: Enabling edit mode');
        this.editfields = true;
        this.noteditfields = false;

        console.log('Step 2: Processing fields');
        let fieldsUpdated = 0;

        this.fieldDetails = this.fieldDetails.map(field => {
            const fieldName = field.Storage_Field__c;
            const updatedField = {
                ...field,
                Is_Disabled__c: false
            };

            if (ocrMap[fieldName]) {
                console.log(`Populating field ${fieldName} with: ${ocrMap[fieldName]}`);
                updatedField.value = ocrMap[fieldName];
                updatedField.ocrPopulated = true;
                updatedField.ocrClass = 'slds-border_success';
                fieldsUpdated++;
            }

            return updatedField;
        });

        console.log(`Updated ${fieldsUpdated} fields, enabled all fields`);
        console.log('Final editfields state:', this.editfields);

        this.fieldDetails = [...this.fieldDetails];

        if (fieldsUpdated > 0) {
            this.showToastMessage('Success', `${fieldsUpdated} fields populated and all fields enabled`, 'success');
        }
    }

    @api
    makeFieldsEditableNow() {
        console.log('Making fields editable NOW');
        console.log('Before - editfields:', this.editfields, 'noteditfields:', this.noteditfields);
        this.editfields = true;
        this.noteditfields = false;
        this.fieldDetails = this.fieldDetails.map(field => {
            console.log(`Field ${field.Storage_Field__c} - Was disabled: ${field.Is_Disabled__c}`);
            return {
                ...field,
                Is_Disabled__c: false
            };
        });

        console.log('After - editfields:', this.editfields, 'noteditfields:', this.noteditfields);
        console.log('Field details updated:', this.fieldDetails.length, 'fields');
        this.fieldDetails = [...this.fieldDetails];
    }

    saveAllOCRValues(ocrMap) {
        const recordId = this.ir ? this.bankId : this.appId;
        const updates = Object.entries(ocrMap).map(([apiName, val]) =>
            updateRecord({ fields: { Id: recordId, [apiName]: val } })
        );
        Promise.all(updates)
            .then(() => {
                console.log('All OCR values saved successfully');
            })
            .catch(err => {
                console.error('Error saving OCR fields', err);
                const errorMessage = err?.body?.message || err?.message || 'Error saving OCR values';
                this.showToastMessage('Error', errorMessage, 'error');
            });
    }

    updateDatabaseWithOCR(ocrMap) {
        const recordId = this.ir ? this.bankId : this.appId;
        let updatesCount = 0;

        Object.keys(ocrMap).forEach(fieldApiName => {
            const fieldValue = ocrMap[fieldApiName];

            if (fieldValue && fieldValue.toString().trim() !== '') {
                console.log(`Updating database field ${fieldApiName} with value: ${fieldValue}`);
                this.updateRecordField(recordId, fieldApiName, fieldValue);
                updatesCount++;
            }
        });

        console.log(`Updated ${updatesCount} database fields from OCR`);
    }
    @api
    refreshDocumentDetails(documentId, documentData) {
        this.docCheckId = documentId;
        this.appId = documentData.applicantId;
        this.addressRecordId = documentData.addressRecordId;

        getOrCreateAddressRecords({
            docDetailId: this.docCheckId,
            applicantId: this.appId
        })
            .then(rows => {
                if (rows && rows.length) {
                    this.addressRecordId = rows[0].Id;
                }
            })
            .catch(error => {
                console.error('Error in getOrCreateAddressRecords:', error);
                const errorMessage = error?.body?.message || error?.message || 'Error creating address records';
                this.showToastMessage('Error', errorMessage, 'error');
            })
            .finally(() => {
                this.getScreenDetailsFromApex();
                this.getFIDetails();
                this.getAllRelatedAddresses();
            });
    }
    getLdsErrorMessages(error) {
        if (!error) return ['Unknown error'];

        const boilerplates = [
            'An error occurred while trying to update the record. Please try again.',
            'An unexpected error occurred.',
            'We can\'t save this record because the ',
            'We can\'t save this record because the ',
            'FIELD_CUSTOM_VALIDATION_EXCEPTION'
        ];
        const isBoilerplate = (msg = '') =>
            !msg || boilerplates.some(bp => msg.includes(bp));

        let msgs = [];

        const out = error?.body?.output;
        if (out) {
            if (Array.isArray(out.errors) && out.errors.length) {
                msgs.push(...out.errors.map(e => e?.message).filter(Boolean));
            }
            if (out.fieldErrors) {
                Object.values(out.fieldErrors).forEach(arr => {
                    if (Array.isArray(arr)) {
                        msgs.push(...arr.map(e => e?.message).filter(Boolean));
                    }
                });
            }
            if (Array.isArray(out.pageErrors) && out.pageErrors.length) {
                msgs.push(...out.pageErrors.map(e => e?.message).filter(Boolean));
            }
        }
        if (msgs.length === 0) {
            const fallback = error?.body?.message || error?.message;
            if (!isBoilerplate(fallback)) msgs.push(fallback);
        }

        msgs = Array.from(new Set(msgs.filter(m => !isBoilerplate(m))));

        return msgs.length ? msgs : ['Validation failed'];
    }

    fetchProducDetails(){
        var inputMapParam = {
            'oppId': this.recordId
        };
        console.log('recordid----'+this.recordId);
        getProductDetails({inputMap : inputMapParam})
        .then(result =>{
            console.log('result product: '+ JSON.stringify(result));
            this.isHLRelated = result.isHLRelated;
            //this.filteredAddressType();
        })
        .catch(error=>{
            console.error('Error in getting product details:', JSON.stringify(error));
            const errorMessage = error?.body?.message || error?.message || 'Error fetching product details';
            this.showToastMessage('Error', errorMessage, 'error');
        })
    }


}