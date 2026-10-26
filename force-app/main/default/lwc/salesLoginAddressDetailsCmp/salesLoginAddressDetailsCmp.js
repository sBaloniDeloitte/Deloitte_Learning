import { LightningElement, track, wire, api } from 'lwc';
import getAddressesByApplicantId from '@salesforce/apex/COMM_SalesAddressDetailsController.getAddressesByApplicantId';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import updateAddress from '@salesforce/apex/COMM_SalesAddressDetailsController.upsertAddress';
import APPLICANT_ADDRESS_OBJECT from '@salesforce/schema/Applicant_Address__c';
import ADDRESS_TYPE_FIELD from '@salesforce/schema/Applicant_Address__c.Address_Type__c';
import ADDRESS_PROOF_FIELD from '@salesforce/schema/Applicant_Address__c.Current_Address_Proof__c';
import ADDRESS_OWNERSHIP_FIELD from '@salesforce/schema/Applicant_Address__c.Address_Ownership__c';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import deleteApplicantAddress from '@salesforce/apex/SalesDocumentCmpController.deleteApplicantAddress';
import getPincodeDetails from '@salesforce/apex/COMM_SalesCollateralDetailsController.getPincodeDetails';
import { NavigationMixin } from 'lightning/navigation';
import getAddressesByBuilder from '@salesforce/apex/COMM_SalesAddressDetailsController.getAddressesByBuilder';
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
import getApplicantValues from '@salesforce/apex/COMM_SalesAddressDetailsController.getApplicantsForOpportunity';
import getApplicantAddressesForOpportunityBuilderSeller from '@salesforce/apex/COMM_SalesAddressDetailsController.getApplicantAddressesForOpportunityBuilderSeller';
//Hl-Ishi-16/09
//HL-Ishi-15/09
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated';
//HL-Ishi-16/09
import checkApplicantAddressType from '@salesforce/apex/Utility_V1.checkApplicantAddressType';
import isCrifDocumentPresent from '@salesforce/apex/SellerAdditionalDetailController.isCrifDocumentPresent';

export default class SalesLoginAddressDetailsCmp extends NavigationMixin(LightningElement) {
    @api applicantId;
    @track appId;
    @api recordId;
    @api fromBuilderSeller;
    @track addresses = [];
    @track editMode = false;
    @track editAddress = {};
    @track isGCStandardUser = false;
    @track filteredPincodeList = [];
    @track showModal = false;
    @track deleteId = null;
    @track hasAddresses = false;
    @api currentAppSeq;
    @api passedScreenName;
    @track addressTypeOptions = [];
    @track addressOwnershipOptions = [];
    @track addressProofOptions = [];
    @track isDisable = false;//Sanwar
    @track addressId = null;//Sanwar
    @track applicantOptions = [];
    @track showAddAddressButton = true;

    _refreshTrigger; // private backing field
    //HL-Ishi-16/9/2025
    isHLUser = false;
    showHLAddressButton = false;
    //HL-Ishi-16/09/2025
    /* @api
     set refreshTrigger(value) {
         this._refreshTrigger = value;
         // Every time parent changes this value, refresh the list
         if (value !== undefined && value !== null) {
             this.loadAddresses();
         }
     }
     get refreshTrigger() {
         return this._refreshTrigger;
     }*/
    _applicantId; // private backing field
    isExistingAddressForApplicant = false;
    addressTypeChanged;
    isHLRelated;
    @track rawProductPicklistOptions = [];

    @api
    set applicantIdForChild(value) {
        this._applicantId = value;
        console.log('applicantId setter called Kshitiz address', this._applicantId);
        if (value !== undefined && value !== null) {
            this.loadAddresses();
            this.fetchApplicantOptions();
        }
        // Load addresses when applicantId is set
    }
    get applicantIdForChild() {
        return this._applicantId;
    }
    //Ishi-Address
    isExistingAddressForApplicant = false;
    addressTypeChanged;
    isHLRelated;
    @track rawProductPicklistOptions = [];
    //Ishi-Address
    connectedCallback() {
        getCurrentUserProfileName()
            .then(profileName => {
                this.isGCStandardUser = (profileName === 'GC Standard User');
            })
            .catch(error => {
                console.error('Error fetching profile:', error);
            });
        this.appId = this.applicantId || this._applicantId;
        this.applicantId = this.appId;
        this._applicantId = this.appId;
        

        this.loadAddresses();
        
        console.log('recordId', this.recordId);
        this.getBuilderAddress();
        //HL-Ishi-8/9/2025
        setTimeout(() => {
            this.fetchProducDetails();
            this.fetchApplicantOptions();
        }, 3000);
        this.checkIfLoggedInUserIsHLRelated();
        this.handleAddNewAddress()
    }

    // ...existing code...

    fetchApplicantOptions() {
        // Only run if getApplicantValues is imported and available
        if (typeof getApplicantValues !== 'function' || !this.recordId) return;
        getApplicantValues({ opportunityId: this.recordId })
            .then(result => {
                let options = [];
                if (this.fromBuilderSeller && this.passedScreenName === 'Builder Details') {
                    for (let i = 0; i < (result || []).length; i++) {
                        let app = result[i];
                        if (app.Applicant_Type__c === 'Builder') {
                            options.push({
                                label: app.Name,
                                value: app.Id
                            });
                        }
                    }
                } else if (this.fromBuilderSeller && this.passedScreenName === 'Seller Details') {
                    for (let i = 0; i < (result || []).length; i++) {
                        let app = result[i];
                        if (app.Applicant_Type__c === 'Seller') {
                            options.push({
                                label: app.Name,
                                value: app.Id
                            });
                        }
                    }
                } else {
                    for (let i = 0; i < (result || []).length; i++) {
                        let app = result[i];
                        options.push({
                            label: app.Name,
                            value: app.Id
                        });
                    }
                }
                this.applicantOptions = options;
            })
            .catch(error => {
                this.applicantOptions = [];
                this.showToast('Error', 'Failed to load applicants', 'error');
            });
    }
    getBuilderAddress() {
        console.log('this.fromBuilderSeller>>>>', this.fromBuilderSeller);
        if (this.fromBuilderSeller) {
            console.log('inside result>>>>');
            getAddressesByBuilder({ recordId: this.recordId })
                .then(result => {
                    console.log('result>>>>', result);
                    if (result != null) {
                        this.editAddress = {};
                        this.editAddress = {
                            pincode: result.Collateral__r?.Builder__r?.Pincode_Master__r?.Name ?? null,
                            addLine1: result.Collateral__r?.Builder__r?.Address_1__c ?? null,
                            addLine2: result.Collateral__r?.Builder__r?.Address_2__c ?? null,
                            addLine3: result.Collateral__r?.Builder__r?.Address_3__c ?? null,
                            city: result.Collateral__r?.Builder__r?.Pincode_Master__r?.City__r?.name ?? null,
                            state: result.Collateral__r?.Builder__r?.Pincode_Master__r?.State__c ?? null,
                            isDisable: true
                        };
                        this.editMode = true;
                        console.log(' this.editAddress>>>>', this.editAddress);
                    }
                })
                .catch(() => {
                    this.showToast('Error', 'Failed to load add', 'error');
                });
        }
    }
    @api
    loadAddresses() {
        console.log('applicantId in loadAddresses Kshitiz address', this._applicantId);

        const appId = this.applicantId || this._applicantId;
        console.log('appId in loadAddresses Kshitiz address', appId);

        let promiseCall;

        if (this.fromBuilderSeller) {
            promiseCall = getApplicantAddressesForOpportunityBuilderSeller({ opportunityId: this.recordId });
        } else {
            // Use existing logic with applicantId
            promiseCall = getAddressesByApplicantId({ applicantId: appId, recordId: this.recordId });
        }

        promiseCall
            .then(result => {
                console.log('result-->');
                console.log('result-->', result);
                console.log('3');
                if (this.addresses.length === 0) {
                   this.addresses = result || [];
                   this.hasAddresses = (this.addresses.length > 0);
}
                this.editMode = false;
                if (this.isHLUser) {
                    for (var i = 0; i < result.length; i++) {
                        if (result[i].source == 'Login Fees') {
                            this.showHLAddressButton = true;
                            break;
                        }
                    }
                }
            })
            .catch(() => {
                this.showToast('Error', 'Failed to load addresses', 'error');
            });

    }

    @wire(getObjectInfo, { objectApiName: APPLICANT_ADDRESS_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: ADDRESS_TYPE_FIELD })
    wiredAddressType({ error, data }) {
        if (data) {
            this.rawProductPicklistOptions = data.values;
            //  this.addressTypeOptions ;
            //   this.addressTypeOptions = this.rawProductPicklistOptions.filter(option => /*option.value !== 'Flexi Loan' && */option.value !== 'Office' && option.value !== 'Other' && option.value !=='Regional Office' && option.value !=='Project Site' && option.value !=='Godown' && option.value !=='Central Office' && option.value !=='Factory Outlet' && option.value !=='Business' && option.value !=='Local' && option.value !=='BSA' && option.value !=='Employee Address' && option.value !=='Clinic' && option.value !=='Owned' && option.value !=='Collateral' && option.value !=='Business Operational');
            // setTimeout(()=>{
            //   this.filteredAddressType();
            // },100)



        } else if (error) {
            this.showToast('Error', 'Failed to load Address Type picklist', 'error');
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: ADDRESS_OWNERSHIP_FIELD })
    wiredAddressOwnership({ error, data }) {
        if (data) {
            this.addressOwnershipOptions = data.values.map(opt => ({ label: opt.label, value: opt.value }));
        } else if (error) {
            this.showToast('Error', 'Failed to load Address Type picklist', 'error');
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: ADDRESS_PROOF_FIELD })
    wiredAddressProof({ error, data }) {
        if (data) {
            this.addressProofOptions = data.values.map(opt => ({ label: opt.label, value: opt.value }));
        } else if (error) {
            this.showToast('Error', 'Failed to load Address Proof picklist', 'error');
        }
    }

    handleEdit(event) {
        const addrId = event.currentTarget.dataset.id;
        this.addressId = addrId;
        const applicantId = event.currentTarget.dataset.applicantid;
        this.applicantId = applicantId;
        console.log('addrId', addrId);
        console.log('applicantId', applicantId);
        const found = this.addresses.find(addr => addr.Id === addrId);
        if (found) {
            this.editAddress = JSON.parse(JSON.stringify(found)); // Deep copy
            this.editMode = true;
            this.hasAddresses = false;
            this.isDisable = true;
        }
    }
    filteredAddressType() {
        console.log('this.rawProductPicklistOptions=:' + JSON.stringify(this.rawProductPicklistOptions));
        if (!this.isHLRelated) {
            this.addressTypeOptions = this.rawProductPicklistOptions;//data.values.map(opt => ({ label: opt.label, value: opt.value }));
        }
        else {
            console.log('Insideeeee-------');
            this.addressTypeOptions = this.rawProductPicklistOptions.filter(option => /*option.value !== 'Flexi Loan' && */option.value !== 'Office' && option.value !== 'Other' && option.value !== 'Regional Office' && option.value !== 'Project Site' && option.value !== 'Godown' && option.value !== 'Central Office' && option.value !== 'Factory Outlet' && option.value !== 'Business' && option.value !== 'Local' && option.value !== 'BSA' && option.value !== 'Employee Address' && option.value !== 'Clinic' && option.value !== 'Owned' && option.value !== 'Collateral' && option.value !== 'Business Operational');
            console.log('Insideeeee-------' + JSON.stringify(this.addressTypeOptions));

        }

    }

    handleAddNewAddress() {
    const hardcodedAddress = {
        Id: 'TEMP_' + Date.now(),
        sellerName: 'John Doe',
        addType: 'Current',
        addOwnership: 'Self Owned',
        addLine1: '123 Test Street',
        addLine2: 'Near City Mall',
        addLine3: 'Sector 62',
        pincode: '201309',
        state: 'Uttar Pradesh',
        city: 'Noida',
        source: 'Manual',
        addressSourceDoc: 'Hardcoded',
        applicantId: this.appId,
        disableEdit: false,
        deleteAddressDisable: false
    };

    this.addresses = [...this.addresses, hardcodedAddress];
    this.hasAddresses = true;

    // Hide Add Address button
    
}

    handleAddressTypeChange(event) {
        if (this.isHLRelated) {
            this.addressTypeChanged = event.detail.value;
            this.checkApplicantAddressType();
        }
        else {
            this.editAddress.addType = event.detail.value;
            if (this.editAddress.addType !== 'Current') {
                this.editAddress.addProof = '';
            }
        }


    }
    handleAddressOwnershipChange(event) {
        this.editAddress.addOwnership = event.detail.value;
    }
    handlePincodeChange(event) {
        const searchKey = event.detail.value;
        this.editAddress.pincode = searchKey;

        if (searchKey.length >= 3) {
            getPincodeDetails({ pinCodeFragment: searchKey })
                .then(result => {
                    this.filteredPincodeList = result || [];
                })
                .catch(error => {
                    console.error('Pincode search error', error);
                    this.filteredPincodeList = [];
                });
        } else {
            this.filteredPincodeList = [];
        }
    }

    handlePincodeSelect(event) {
        const selectedId = event.target.dataset.id;
        const selectedPincode = this.filteredPincodeList.find(pin => pin.Id === selectedId);

        if (selectedPincode) {
            this.editAddress.city = selectedPincode.City__r?.Name || '';
            this.editAddress.state = selectedPincode.City__r?.State_Name__c || '';
            this.editAddress.country = selectedPincode.City__r?.Country__c || '';
            this.editAddress.addPincode = selectedPincode.Id;
            this.editAddress.pincode = selectedPincode.Name;
            this.filteredPincodeList = [];
        }
    }

    refreshRecordPage() {
        if (!this.fromBuilderSeller) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'Opportunity',
                    actionName: 'view'
                }
            })
        }
        this.loadAddresses();
    }

    handleNext() {
        console.log('this.selectedCustIds-----', this.selectedCustIds);
        const valueChangeEvent = new CustomEvent("callnextaccordian", {
            detail: { value: this.recordId, name: 'Applicant Information', currentAppSeq: this.currentAppSeq, section: 'PAN validation' }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    handleDelete(event) {
        console.log('Delete Address');
        deleteApplicantAddress({
            adrId: this.deleteId
        })
            .then((response) => {
                this.showModal = false;
                this.deleteId = null;
                this.loadAddresses();
            })
            .catch(error => {
                console.error('Delete failed: ', error);
                this.showModal = false;
            });

    }

    handleOpenDeletePopup(event) {
        console.log('138');
        this.deleteId = event.target.dataset.id;
        this.showModal = true;
    }

    handleCancel() {
        this.showModal = false;
        this.deleteId = null;
    }

    clearAddressFields() {
        this.editAddress.city = '';
        this.editAddress.state = '';
        this.editAddress.country = '';
        this.editAddress.addPincode = '';
    }

    handleAddLine1Change(event) {
        this.editAddress.addLine1 = event.target.value;
    }

    handleAddLine2Change(event) {
        this.editAddress.addLine2 = event.target.value;
    }

    handleAddLine3Change(event) {
        this.editAddress.addLine3 = event.target.value;
    }

    handleAddressProofChange(event) {
        this.editAddress.addProof = event.detail.value;
    }


    updateAddress() {

        if (!this.editAddress.addType || !this.editAddress.addLine1 || !this.editAddress.addPincode || !this.editAddress.addOwnership) {
            this.showToast('Error', 'Please fill all required fields before saving.', 'error');
            return;
        }
        const inputMap = {
            Id: this.editAddress.Id,
            addType: this.editAddress.addType,
            addOwnership: this.editAddress.addOwnership,
            addProof: this.editAddress.addProof,
            addLine1: this.editAddress.addLine1,
            addLine2: this.editAddress.addLine2,
            addLine3: this.editAddress.addLine3,
            addPincode: this.editAddress.addPincode,
            applicantId: this.appId,
            loanId: this.recordId
        };

        console.log('input map---', (JSON.stringify(inputMap)));

        updateAddress({ inputMap })
            .then(result => {
                if (result.status === 'success') {
                    this.showToast('Success', 'Address updated successfully', 'success');
                    this.editMode = false;
                    this.loadAddresses();
                    this.isDisable = false;
                }
            })
            .catch(error => {
                this.showToast('Error', error.body ? error.body.message : 'Unknown error', 'error');
            });

    }


    cancelEdit() {
        // this.editMode = false;
        // this.editAddress = {};
        this.editAddress = {};
        if (this.addressId) {
            this.editAddress.Id = this.addressId;
        }
        this.editMode = true;
        this.isDisable = true;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant,
            mode: 'dismissable'
        }));
    }

    get showAddressProof() {
        return this.editAddress.addType === 'Current';
    }

    get getProductByDeviceType() {
        return 'slds-grid slds-wrap slds-gutters';
    }

    get getProductByDeviceTypeCol() {
        return 'slds-col slds-size_1-of-4';
    }
    //HL-Ishi-16-09/2025
    checkIfLoggedInUserIsHLRelated() {
        checkIfLoggedInUserIsHLRelated()
            .then(result => {
                this.isHLUser = result.isHLRelated;
                console.log('isHLUser-->', this.isHLUser);
            })
            .catch(error => {
                console.log('error-->', error);
            })
    }
    //HL-Ishi-16-09-2025

    checkApplicantAddressType() {
        console.log('addressTypeChanged', this.addressTypeChanged);
        const inputMap = {
            appId: this.applicantId,
            selectedAdd: this.addressTypeChanged
        }
        checkApplicantAddressType({
            inputMap: inputMap
        })
            .then(response => {
                console.log('response in checkApplicantAddressType', response);
                this.isExistingAddressForApplicant = response;
                if (response) {
                    this.editAddress = {
                        ...this.editAddress,
                        addType: ''
                    };
                    this.template.querySelector(`[data-id="Address_Type__c"]`).value = null;
                    this.addressTypeChanged = null;
                    this.addressTypeChanged = null;
                    this.showToast('Error', 'Address type already exists for this applicant.', 'error');
                }
                else {
                    this.editAddress.addType = this.addressTypeChanged;
                    if (this.editAddress.addType !== 'Current') {
                        this.editAddress.addProof = '';
                    }
                }
            })
            .catch(error => {
                console.log('Error updating document record --> ' + JSON.stringify(error));
            });
    }
    fetchProducDetails() {
        var inputMapParam = {
            'oppId': this.recordId
        };
        console.log('recordid----' + this.recordId);
        getProductDetails({ inputMap: inputMapParam })
            .then(result => {
                console.log('result product: ' + JSON.stringify(result));
                this.isHLRelated = result.isHLRelated;
                this.filteredAddressType();
            })
            .catch(error => {
                console.error('error in getting product: ' + JSON.stringify(error))
            })
    }
    handleCloseScreen() {
        this.hasAddresses = true;
        this.editMode = false;
    }
    isDocPresent = false;
    @wire(isCrifDocumentPresent, {
        recordId: '$recordId',
        applicantId: '$applicantId'
    })
    wiredCrifDoc({ data, error }) {
        if (data !== undefined) {
            console.log('result doc present>>>', data);
            this.isDocPresent = data === true;
        }
        else if (error) {
            console.error('Error checking document', error);
        }
        console.log('result doc present>>>', this.daisDocPresentta);
    }

    handleApplicantChange(event) {
        const selectedId = event.detail.value;
        this.editAddress.applicantId = selectedId;
        this.applicantId = selectedId;
        this.appId = selectedId;
    }
    @api refreshData() {
        console.log('Address component called');
        this.fetchApplicantOptions();
    }

}