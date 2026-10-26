import { LightningElement,track,api,wire } from 'lwc';
import appaddr_obj from "@salesforce/schema/Applicant_Address__c";
import fetchApplicantsAddresses from '@salesforce/apex/SalesDocumentCmpController.fetchApplicantsAddresses';
import addrtype from '@salesforce/schema/Applicant_Address__c.Address_Type__c';
import addrOwner from '@salesforce/schema/Applicant_Address__c.Address_Ownership__c';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CurrentPageReference } from 'lightning/navigation';
import fetchApplicantsAddress from '@salesforce/apex/SalesDocumentCmpController.fetchApplicantsAddress';
import insertApplicantAddress from '@salesforce/apex/SalesDocumentCmpController.insertApplicantAddress';
import deleteApplicantAddress from '@salesforce/apex/SalesDocumentCmpController.deleteApplicantAddress';
import saveAddressRecord from '@salesforce/apex/SalesDocumentCmpController.saveAddressRecord';
import getPincodeDetails from '@salesforce/apex/SalesDocumentCmpController.getPincodeDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAddedAddressTypes from '@salesforce/apex/SalesDocumentCmpController.getAddedAddressTypes';
import checkaddrtype from '@salesforce/apex/SalesDocumentCmpController.checkaddrtype';
import callDedupeAPI from '@salesforce/apex/COMM_SalesLoanLoginController.callDedupeAPI';
import checkExceptionStatus from '@salesforce/apex/COMM_SalesLoanLoginController.checkExceptionStatus';
//HL-Ishi-15/09
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated'
import getLoanStageFromApplicant from '@salesforce/apex/Utility_V1.getLoanStageFromApplicant';
import getCurrentUserProfileName from '@salesforce/apex/Utility_V1.getCurrentUserProfileName';
import fetchAddressDetails from '@salesforce/apex/SalesDocumentCmpController.fetchAddressDetails';
import updateAddressRecord from '@salesforce/apex/SalesDocumentCmpController.updateAddressRecord';
//HL-Ishi-15/09
import { RefreshEvent } from "lightning/refresh"; 
export default class ApplicantAddresses extends LightningElement {

    @api recordId;
    showDedupeSpinner = false;
    @track addressTypeOptions = [
        // { label: 'Regional Office', value: 'Regional Office' },
        // { label: 'Permanent', value: 'Permanent' }
    ];
    @track availableaddressTypeOptions = [];
    @api appId;
    @api loginChecklist;
    @track addressTable = [];
    @track edit = false;
    @track isEditing = false;
    pincodeDisabled = false;
    addressTypeval;
    @track pinno;
    @track pincodename;
    @track ad1;
    @track ad2;
    @track ad3;
    @track town;
    @track state;
    pincodeDisabled = false;
    @track showPin = true;
    isRendered = false;
    savedAddressType = [];
    presentAddrTypes;
    @api objectApiName;
    isNextVisible = true;
    showLoanDetails = false;
    showApplicantName = false;
    @wire(getObjectInfo, { objectApiName: appaddr_obj })
    objectInfo;
    error;
    viewEdit = false;
    setFalse = false;
    setTrue = true;
    showEditAddressRec = false;
    addressOwnerOptions = [];
    editAddressDetails;
    @wire(CurrentPageReference) pageRef;
    //HL-Ishi-8/9/2025
    isHLUser= false;
    //HL-Ishi-26/09

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: addrtype })
    byHandF8ieldInfo({ data, error }) {
        if (data) {
            this.addressTypeOptions = JSON.parse(JSON.stringify(data.values));
            console.log('24 ' + JSON.stringify(this.addressTypeOptions));
            // this.filterAddressTypeOptions();
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: addrOwner })
    byHandPickListInfo({ data, error }) {
        if (data) {
            this.addressOwnerOptions = JSON.parse(JSON.stringify(data.values));
            console.log('addressOwnerOptions :  ' + JSON.stringify(this.addressOwnerOptions));
            // this.filterAddressTypeOptions();
        }
    }
    connectedCallback() {
        console.log('recordId ' + this.recordId);
        console.log('ApplicantAddresses:deviceType ' + this.deviceType);
        this.showPin = true;
        this.checkIfLoggedInUserIsHLRelated();
        getLoanStageFromApplicant({ appId: this.appId})
        .then(result => {
            console.log('Result Loan Stage : ', result);
            if (result == 'Credit Underwriting') {
                getCurrentUserProfileName()
                .then((res) =>{
                    console.log('getCurrentUserProfileName -- res : '+res);
                    if (res && res === 'Credit Manager') {
                        console.log('getCurrentUserProfileName -- Inside If');
                        this.viewEdit = true;
                    } else {
                        console.log('getCurrentUserProfileName -- Inside else');
                        this.viewEdit = false;
                    }
                }).catch ((err) => {
                    console.error('getCurrentUserProfileName error '+ err);
                    this.viewEdit = false;
                })
            } else {
                this.viewEdit = false;
            }
        })
        .catch(error => {
            console.error('Error Loan Stage :', error);
        });
        this.ApplicantAddress();
        this.savedAddressTypes();
        this.checkUserProfile();
    }

    isFieldDisable = false;
    checkUserProfile() {
        checkExceptionStatus({ loanId: this.recordId })
            .then(result => {
                console.log('Inside Profile true----', result);

                if (result) {
                    this.isFieldDisable = true;
                }
            })
            .catch(error => {
                console.error('Error in checkExceptionStatus:', error);
            });

    }
    renderedCallback() {
        if (!this.isRendered) {
            this.isRendered = true;
            const style = document.createElement('style');
            style.innerText = `
    .removeborder .slds-combobox__input {
        border: none !important;  /* Remove border */
        box-shadow: none !important;  /* Remove any shadow */
        background-color: transparent;  /* Ensure no background color */
         border-bottom: 1px solid black !important; /* Add only bottom border */
         border-radius: 0 !important; /* Remove curved edges */
         padding:5px`;
            this.template.querySelector('.styleContainer').appendChild(style);
            this.spinnerClass = 'spinner-medium';

        }
    }
    ApplicantAddress() {
        if(this.objectApiName == 'Opportunity'){
            this.isNextVisible = true;
            this.recordId = this.recordId;
            this.appId = this.appId;
        }else if(this.objectApiName == 'Application_Applicant__c'){
            this.isNextVisible = false;
            this.appId = this.recordId;
            this.recordId = '';
        }
        else if(this.objectApiName =='Account'){
            this.showLoanDetails= true;
        }
        fetchApplicantsAddresses({
            recordId: this.recordId,
            appId: this.appId,
        })
            .then((response) => {
                console.log("stage response: " + response);
                console.log("stage response: JSON" + JSON.stringify(response));
                if (response.length > 0) {
                    this.addressTable = response;
                    this.error = false;
                    this.presentAddrTypes = response.map(addr => addr.addressType);
                    console.log('presentAddrTypes '+JSON.stringify(this.presentAddrTypes));
                    setTimeout(() => {
                        this.filterAddressTypeOptions();
                    }, 2000);
                }else{
                    this.error = true;
                }
            })
    }
    savedAddressTypes(){
        getAddedAddressTypes({
            recordId: this.recordId,
            appId: this.appId,
        })
            .then((response) => {
                console.log("stage response: " + response);
                console.log("stage response: JSON" + JSON.stringify(response));
                this.savedAddressType = response;
            })
    }
    //  handleEdit(event) {
    //     const instrumentId = event.target.dataset.id;
    //     console.log('Instrument Id:', instrumentId);

    //     this.addressTable = this.addressTable.map(instrument => {
    //         if (instrument.Id.toString() === instrumentId) { // Ensure it's a string comparison
    //             return {
    //                 ...instrument,
    //                 isEditing: !instrument.isEditing // Toggle edit mode
    //             };
    //         }
    //         return instrument;
    //     });

    //     console.log('Updated Address Table:', JSON.stringify(this.addressTable));
    // }

    handleEdit(event) {
        this.selectedAddressRec = event.target.dataset.id;
        console.log('this.selectedAddressRec : '+this.selectedAddressRec);
        console.log('this.appId : '+this.recordId);
        fetchAddressDetails({addressId :this.selectedAddressRec, appId: this.recordId})
        .then((response) => {
            this.editAddressDetails = response[0];
            console.log('this.editAddressDetails : '+JSON.stringify(this.editAddressDetails));
            setTimeout(() => {
               this.showEditAddressRec = true; 
            }, 200);
            
        })
        .catch(error => {
            console.error('Error in fetchAddressDetails:', JSON.stringify(error));
        });

    }

    cancelUpdate(event) {
        this.selectedAddressRec = '';
        this.showEditAddressRec = false;
       
        this.editAddressDetails = {};
       
    }

    filterAddressTypeOptions() {
        console.log('this.addressTypeOptions----', JSON.stringify(this.addressTypeOptions));
        console.log('this.presentAddrTypes----', JSON.stringify(this.presentAddrTypes));


        if (this.addressTypeOptions.length > 0 && this.presentAddrTypes.length > 0) {
            this.availableaddressTypeOptions = this.addressTypeOptions.filter(option => !this.presentAddrTypes.includes(option.value));
            console.log('Filtered addressTypeOptions: ' + JSON.stringify(this.addressTypeOptions));
        }
        else{
            this.availableaddressTypeOptions = this.addressTypeOptions;
        }
    }
    handleSelecttype(event){
        this.addressTypeval = event.target.value;
    }
    addrCHange1(event){
        const input = event.target.value;
        const regex = /^[a-zA-Z0-9\s]*$/; // allows letters, numbers, and spaces only

        if (regex.test(input)) {
            this.ad1 = input;
        } else {
            this.ad1 = '';
            event.target.value = ''; // clear the input field in UI
            this.showToast('Error', 'Address can not have special characters.', 'error');
        }
        // this.ad1 = event.target.value;
    }
    addrCHange2(event){
        const input = event.target.value;
        const regex = /^[a-zA-Z0-9\s]*$/; // allows letters, numbers, and spaces only

        if (regex.test(input)) {
            this.ad2 = input;
        } else {
            this.ad2 = '';
            event.target.value = ''; // clear the input field in UI
            this.showToast('Error', 'Address can not have special characters.', 'error');
        }
        // this.ad2 = event.target.value;
    }
    addrCHange3(event){
        const input = event.target.value;
        const regex = /^[a-zA-Z0-9\s]*$/; // allows letters, numbers, and spaces only

        if (regex.test(input)) {
            this.ad3 = input;
        } else {
            this.ad3 = '';
            event.target.value = ''; // clear the input field in UI
            this.showToast('Error', 'Address can not have special characters.', 'error');
        }
        // this.ad3 = event.target.value;
    }
    handleSelectedRow(event) {
        const recordId = event.detail.searchRecord.Id;
        console.log('recordId '+recordId);
    }
    handleselectedPin(event){
        this.pinno = event.detail.searchRecord.Id;
        this.pincodename = event.detail.searchRecord.Name;
        console.log('pinno : '+this.pinno);
        console.log('pincodename : '+this.pincodename);
        getPincodeDetails({
            pinId: this.pinno
        })
            .then((response) => {
                console.log("stage response: " + response);
                console.log("stage response: JSON" + JSON.stringify(response));
                this.town = response.Town__c;
                this.state = response.State__c;
            })
    }
    handleselectedPinEdit(event){
        this.pinno = event.detail.searchRecord.Id;
        this.pincodename = event.detail.searchRecord.Name;
        console.log('pinno : '+this.pinno);
        console.log('pincodename : '+this.pincodename);
        getPincodeDetails({ pinId: this.pinno })
        .then((response) => {
            console.log("Pincode response: " + JSON.stringify(response));
            this.editAddressDetails = {
                ...this.editAddressDetails,
                city: response?.City__r?.Name,
                state: response?.State__c,
                pincodename: this.pincodename,
                pincode: this.pinno
            };
        })
        .catch((error) => {
            console.error('Error fetching pincode details:', JSON.stringify(error));
        });
    }
    addLnOneChange(event) {
        const value = event.target.value;
        if (!value || value.length > 50) {
            this.showToast('Error', 'Address Line 1 must be 1–50 characters long.', 'error');
            return;
        }
        this.editAddressDetails = {
            ...this.editAddressDetails,
            addressLine1: value
        };
    }
    addLnTwoChange(event) {
        const value = event.target.value;
        if (!value || value.length > 50) {
            this.showToast('Error', 'Address Line 2 must be 1–50 characters long.', 'error');
            return;
        }
        this.editAddressDetails = {
            ...this.editAddressDetails,
            addressLine2: value
        };
    }
    addLnThreeChange(event) {
        const value = event.target.value;
        if (!value || value.length > 50) {
            this.showToast('Error', 'Address Line 3 must be 1–50 characters long.', 'error');
            return;
        }
        this.editAddressDetails = {
            ...this.editAddressDetails,
            addressLine3: value
        };
    }
    stateChange(event){
        this.editAddressDetails = {
            ...this.editAddressDetails,
            state: event.detail.value
        };
    }
    cityChange(event){
        this.editAddressDetails = {
            ...this.editAddressDetails,
            city: event.detail.value
        };
    }
    changeAddressTypeee(event){
        this.editAddressDetails = {
            ...this.editAddressDetails,
            addressType: event.detail.value
        };
    }
    changeOwnershipTypeee(event){
        this.editAddressDetails = {
            ...this.editAddressDetails,
            ownerShip: event.detail.value
        };
    }

    updateProduct() {
        if (!this.editAddressDetails || !this.editAddressDetails.Id) {
            console.error('Missing editAddressDetails or Id');
            return;
        }
        console.log('Updating address with:', JSON.stringify(this.editAddressDetails));
        updateAddressRecord({ addressData: this.editAddressDetails })
        .then(() => {
            this.selectedAddressRec = '';
            this.showEditAddressRec = false;
            this.editAddressDetails = '';
            this.showToast('Success', 'Address updated successfully', 'success');
            console.log('appId : '+this.appId);
            this.recordId = this.appId;
            setTimeout(() => {
                this.ApplicantAddress();
            }, 300);
        })
        .catch(error => {
            console.error('Error updating address:', JSON.stringify(error));
            this.showToast('Error', 'Failed to update address', 'error');
        });
    }
    handlepincodelookupdeselected(event){
        this.pinno = null;
    }
    handleSelectsameas(event){
        this.sameas = event.target.value;
        console.log('sameas '+this.sameas);
        this.showPin = false;
        fetchApplicantsAddress({
            recordId: this.recordId,
            appId: this.appId,
            adrType : this.sameas
        })
            .then((response) => {
                console.log("stage response: " + response);
                console.log("stage response: JSON" + JSON.stringify(response));
                this.ad1 = response.addressLine1;
                this.ad2 = response.addressLine2;
                this.ad3 = response.addressLine3;
                this.pincodename = response.pincodename;
            console.log('pincodename '+this.pincodename);
                this.pinno = response.pincode;
            console.log('pinno '+this.pinno);
                this.state = response.state;
                this.town = response.town;
                this.showPin = true;
            })
    }
    SaveAddress(event){
        console.log('Save Address');
        console.log('addressTypeval '+this.addressTypeval);
        console.log('ad1 '+this.ad1);
        console.log('pincode '+this.pinno);
        if(!this.addressTypeval || !this.ad1 || !this.pinno){
            this.showToast('Error', 'Please fill all the required fields', 'error');
            return;
        }
        else{
            insertApplicantAddress({
                recordId: this.recordId,
            appId : this.appId,
                adrType: this.addressTypeval,
            pincode : this.pinno,
            addressLine1 : this.ad1,
            addressLine2 : this.ad2,
            addressLine3 : this.ad2,
            })
                .then((response) => {
                    console.log("stage response: " + response);
            if(response){
                        this.addressTypeval = null;
                        this.pinno = null;
                        this.ad1 = null;
                        this.ad2 = null;
                        this.ad3 = null;
                        this.pincodename = null;
                        this.addressTypesameval = null;
                        this.addressTypeval = null;
                        this.showPin = false;
                        this.town = null;
                        this.state = null;
                        this.showToast('Success', 'Address record created succesfully', 'success');
                        console.log('Inside save add');
                        this.callDedupeAPI();
                        this.connectedCallback();

                    }
                })
        }
    }
    handleDelete(event){
        console.log('Delete Address');
        const instrumentId = event.target.dataset.id;
        console.log('Delete Address : '+instrumentId);
        deleteApplicantAddress({
            adrId : instrumentId
        })
            .then((response) => {
                this.connectedCallback();
            })

    }
    handleSave(event) {
        const recordId = event.currentTarget.dataset.id; // Get the row's ID
        let updatedRecord;
        let addressTypeval, ad1, ad2, ad3;
        // Find the record in addressTable that matches the ID
        this.addressTable = this.addressTable.map((record) => {
            if (record.Id === recordId) {
                updatedRecord = {
                    ...record,
                    isEditing: false // Disable editing mode
                };
                if(addressTypeval || !ad1 || !pinno)

                    // Store values in local variables
                    addressTypeval = updatedRecord.addressType;
                ad1 = updatedRecord.addressLine1;
                ad2 = updatedRecord.addressLine2;
                ad3 = updatedRecord.addressLine3;
            }
            return record.Id === recordId ? updatedRecord : record;
        });

        // Call Apex method to save the record
        if (updatedRecord) {
            saveAddressRecord({
                addrId: recordId,
                adrType: addressTypeval,
                addressLine1: ad1,
                addressLine2: ad2,
                addressLine3: ad3,
            })
                .then(() => {
                    this.showToast('Success', 'Record updated successfully', 'success');
                    console.log('Inside save add');
                    this.callDedupeAPI();
                    console.log('Inside save add 315');
                    this.connectedCallback();

                })
                .catch((error) => {
                    console.error('Error updating record:', error);
                    this.showToast('Error', 'Failed to update record', 'error');
                });
        }
    }


    // Utility function to show toast messages
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    changeAddressType(event) {
        const recordId = event.target.dataset.id;
        const newValue = event.target.value;
        const oldValue = event.target.dataset.oldValue;
        checkaddrtype({
            adrtype : newValue,
            recordId : recordId
        })
            .then((response) => {
            console.log('response '+response);
            if(response){
                    this.addressTable = this.addressTable.map(doc => {
                        if (doc.Id.toString() === recordId) {
                            return { ...doc, addressType: newValue };
                        }
                        return doc;
                    });
                }
            else{
                    this.showToast('error', 'The Address Type is already assigned to one Address', 'error');
                    this.addressTable = this.addressTable.map(doc => {
                        if (doc.Id.toString() === recordId) {
                            return { ...doc, addressType: oldValue };
                        }
                        const combobox = this.template.querySelector(`lightning-combobox[data-id="${recordId}"]`);
                        if (combobox) {
                            combobox.value = oldValue;
                        }
                        return doc;
                    });
                }
            })
            .catch((error) => {
                console.error('Error in checking:', error);
            });
    }

    changeAddressline1(event) {
        const recordId = event.target.dataset.id;
        const newValue = event.target.value;

        this.addressTable = this.addressTable.map(doc => {
            if (doc.Id.toString() === recordId) {
                return { ...doc, addressLine1: newValue };
            }
            return doc;
        });
    }

    changeAddressline2(event) {
        const recordId = event.target.dataset.id;
        const newValue = event.target.value;

        this.addressTable = this.addressTable.map(doc => {
            if (doc.Id.toString() === recordId) {
                return { ...doc, addressLine2: newValue };
            }
            return doc;
        });
    }

    changeAddressline3(event) {
        const recordId = event.target.dataset.id;
        const newValue = event.target.value;

        this.addressTable = this.addressTable.map(doc => {
            if (doc.Id.toString() === recordId) {
                return { ...doc, addressLine3: newValue };
            }
            return doc;
        });
    }
    checkaddressTypeAdded(addrtype,adrId){
        console.log('addrtype '+addrtype);
        console.log('adrId '+adrId);
        checkaddrtype({
            adrtype : addrtype,
            recordId : adrId
        })
            .then((response) => {
            console.log('response '+response);
                return response;
            })
            .catch((error) => {
                console.error('Error in checking:', error);
            });
    }

    navigateToNext(){
        console.log('Inside navigate to next-----');
        const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
            detail: {
                loanId: this.recordId,
                screenName: 'Applicant\'s Address Information',
                applicantId: this.appId
            }
        });
        this.dispatchEvent(valueSelectedEvent);
    }



    callDedupeAPI(){
        console.log('451-------------')
        this.showDedupeSpinner =true;
        console.log('451-------------')
        callDedupeAPI({ applicantId: this.appId ,loanId:this.recordId})
            .then(result => {
                console.log('result-------------')
                this.showToast('Success', 'Dedupe api has been successfull initated', 'success');
            this.showDedupeSpinner =false;
            })
            .catch(error => {

                this.showDedupeSpinner =false;
            });
    }
     //HL-Ishi-15/09
    checkIfLoggedInUserIsHLRelated(){
        checkIfLoggedInUserIsHLRelated()
        .then(result => {
            this.isHLUser = result.isHLRelated;
            if(this.isHLUser && this.isCrif){
                this.isHLUser =false;
             console.log('  this.isHLUser----'+  this.isHLUser);
            }
            console.log('isHLUser-->',this.isHLUser);
        })
        .catch(error => {
            console.log('error-->',error);
        })
    }
    //Hl-Ishi-15/09

}