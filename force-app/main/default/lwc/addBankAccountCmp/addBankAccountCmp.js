import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import LightningConfirm from "lightning/confirm";
import { NavigationMixin } from 'lightning/navigation';
import getCustomerDetails from '@salesforce/apex/COMM_BankAccountController.getCustomerDetails';
import getIFSCDetails from '@salesforce/apex/COMM_BankAccountController.getIFSCDetails';
import getBankDetails from '@salesforce/apex/COMM_BankAccountController.getBankDetails';
import isDupBank from '@salesforce/apex/COMM_BankAccountController.isDupBank';
import uploadFileNonDocument from '@salesforce/apex/COMM_ManualBankingController.uploadFileNonDocument';
import createDocumentDetail from '@salesforce/apex/COMM_ManualBankingController.createDocumentDetail';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import Application_Verification from '@salesforce/schema/Document_Details__c';
import monthField from '@salesforce/schema/Document_Details__c.Month__c';
import createBSArecord from '@salesforce/apex/COMM_ManualBankingController.createBSArecord';
import createDocumentChecklistForSales from '@salesforce/apex/COMM_SalesLoanLoginController.createDocumentChecklistForSales';
import checkExistingBank from '@salesforce/apex/COMM_BankAccountController.checkExistingBank';
import insertFileRecord from '@salesforce/apex/COMM_SalesLoanLoginController.insertFileRecord'
import { isValidMobileNumber } from 'c/utility';
import getFileSize from '@salesforce/apex/Utility.getFileSize';//sanwar(11/12/2025)
import deleteUploadedFile from '@salesforce/apex/Utility.deleteUploadedFile';
import getBranchNameForBank from '@salesforce/apex/CaptureMandateController.getBranchNameForBank';//sanwar
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
import { refreshApex } from '@salesforce/apex';
export default class AddBankAccountCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api trancheId;
    @api isModalOpen;
    @api selectedApplicant;
    @api bsa;
    @api sanctionLimit;
    @api loanFacility;
    customerSelected = false;
    @api isSecurityMandate; //Sanwar
    @api selectedCustOpt = '';
    @track ifscvalue;
    @track selectedCustomer;
    @track custOptions = [];
    @api accHolderName = '';
    @track recId;
    @track isLoanApp;
    @track hideFields;
    @track modalTitle;
    @track secTitle;
    @track disableButton = false;
    @track isBankAdded = false;
    @track contentDocumentId;
    @api accountType;
    @api fromBuilderSeller;
    selecteddocCheckId;
    fromDate;
    toDate;
    bankname;
    ifscV;
    passWord;
    drawingPower;
    sourceType = 'Manual';
    branch;
    fetchedCustomer;
    nonDocList;
    picklistValues = [];
    selectedMonth;
    selectedYear;
    monthDifference = 0;
    monthInputs = [];
    @track inputValues = [];
    maxResults = 10;
    MAX_SIZE = 25 * 1024 * 1024;

    @track spinnerRun = false;
    @api fromSales = false;
    @track today;
    @api isDisable;
    //multipleFile-sales
    uploadedFilesSales = [];
    uploadedFilesList = [];
    salesReturnedDocumentId;
    countOfDocument = 0;
    uploadedFileName = [];
    showDocumentName = false;
    @api loanId;
    @api passedScreenName;
    @api isBsa = false;
    get acceptedFormats() {
        return ['.pdf'];
    }
    @track branchOptions = []; //sanwar
    branchRecordsData;
    selectedBankBranch;
    selectedBranch;
    showHLRelatedData = false;
    product;
    wiredCustomerResult;
    @wire(getCustomerDetails, { loanAppId: '$recordId' })
    getCustomerDetails(result) {
        this.wiredCustomerResult = result;
        this.getCustomerDetail(result);
    }
    getCustomerDetail({ error, data }) {
        if (data) {
            this.wiredCustomerResult = data;
            console.log('data: ' + JSON.stringify(data));
            console.log('record id: ' + this.recordId);
            console.log('object: ' + this.objectApiName);
            if (this.objectApiName == 'Bank_Details__c') {
                this.isModalOpen = true;
                this.recId = this.recordId;
                this.isLoanApp = false;
                //this.hideFields = false;
                this.modalTitle = 'Edit Bank Account';
                this.secTitle = 'Edit Bank Account Details';
            } else if (this.fromSales) {
                this.recId = null;
                this.isLoanApp = false;
                this.hideFields = false;
                this.modalTitle = 'Add bank statements';
                this.secTitle = 'Enter Bank Account Details';
            }
            else if (this.fromBuilderSeller) {
                this.recId = null;
                this.isLoanApp = false;
                this.hideFields = false;
                this.modalTitle = 'New Bank Account';
                this.secTitle = 'Enter Bank Account Details';
            }
            else {
                this.recId = null;
                this.isLoanApp = true;
                this.hideFields = false;
                this.modalTitle = 'New Bank Account';
                this.secTitle = 'Enter Bank Account Details';
            }

            // Keep custOptions logic unchanged for compatibility
            const noneOpt = {
                label: '--None--',
                value: ''
            };
            this.custOptions = [...this.custOptions, noneOpt];
            for (var i = 0; i < data.length; i++) {

                console.log('list:' + JSON.stringify(data[i]));
                var nameAndType;
                var customerId = data[i]['custId'];
                if (customerId == null || customerId == undefined) {
                    if (data[i]['custLastName'] == '' || data[i]['custLastName'] == null || data[i]['custLastName'] == undefined) {
                        nameAndType = data[i]['custFirstName'] + ' (' + data[i]['applicantType'] + ')';
                    }
                    else {
                        nameAndType = data[i]['custFirstName'] + ' ' + data[i]['custLastName'] + ' (' + data[i]['applicantType'] + ')';
                    }
                    customerId = null;
                }
                else {
                    nameAndType = data[i]['custName'] + ' (' + data[i]['applicantType'] + ')';
                }
                const option = {
                    label: nameAndType,
                    value: customerId
                };
                this.custOptions = [...this.custOptions, option];
            }

            // Set fetchedCustomer to only sellers if fromBuilderSeller is true
            console.log('fromBuilderSeller value: ' + this.fromBuilderSeller);
            console.log('passedScreenName value: ' + this.passedScreenName);
            if (this.fromBuilderSeller && this.passedScreenName && this.passedScreenName.toLowerCase() === 'seller details') {
                // Filter only sellers
                let sellers = data.filter(item => item['applicantType'] && item['applicantType'].toLowerCase() === 'seller');
                console.log('Filtered sellers: ' + JSON.stringify(sellers));
                // Map to display format (label, value, customerType)
                this.fetchedCustomer = sellers.map(item => {
                    let label = item['custName'] ? item['custName'] : (item['custFirstName'] + (item['custLastName'] ? (' ' + item['custLastName']) : ''));
                    return {
                        label: label,
                        value: item['custId'],
                        customerType: item['applicantType']
                    };
                });
            } else if (this.fromBuilderSeller && this.passedScreenName && this.passedScreenName.toLowerCase() === 'builder details') {

                // Filter only builders
                let builders = data.filter(item => item['applicantType'] && item['applicantType'].toLowerCase() === 'builder');
                console.log('Filtered builders: ' + JSON.stringify(builders));
                // Map to display format (label, value, customerType)
                this.fetchedCustomer = builders.map(item => {
                    let label = item['custName'] ? item['custName'] : (item['custFirstName'] + (item['custLastName'] ? (' ' + item['custLastName']) : ''));
                    return {
                        label: label,
                        value: item['custId'],
                        customerType: item['applicantType']
                    };
                });
            }

            else {
                // For other cases, keep previous logic or set to all
                this.fetchedCustomer = data.map(item => {
                    let label = item['custName'] ? item['custName'] : (item['custFirstName'] + (item['custLastName'] ? (' ' + item['custLastName']) : ''));
                    return {
                        label: label,
                        value: item['custId'],
                        customerType: item['applicantType']
                    };
                });
            }
        }
        if (error) {
            console.log('error get cust details: ' + JSON.stringify(error));
        }
    }
    @wire(getObjectInfo, { objectApiName: Application_Verification })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: monthField
    })
    wiredPicklist({ error, data }) {
        if (data) {
            this.picklistValues = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
            console.log('picklistValues--', JSON.stringify(this.picklistValues));

        } else if (error) {
            console.error('Error fetching picklist values', error);
        }
    }

    get monthOptions() {
        return this.picklistValues;
    }

    @api refreshComponent(selectedId, selectedName, isManual) {
        console.log('selectedId----', selectedId);
        console.log('selectedName----', selectedName);
        console.log('isManual----', isManual);
        this.recordId = selectedId;
        this.fromSales = isManual;
        this.selectedCustOpt = selectedId;
        this.accHolderName = selectedName;
        this.connectedCallback();

    }
    renderedCallback() {
        if (!this.isRendered) {
            const style = document.createElement('style');
            style.innerText = `
            p, h1, h2, h3, h4, h5, a, .slds-button{
                font-family: Arial;
            }
            .cancel-button{
                text-wrap-mode: nowrap;
            }
            .custom-table .slds-form-element__label, span.slds-file-selector__text.slds-medium-show{
                display: none;
            }
            .form-div span.slds-file-selector__button.slds-button.slds-button_neutral{
                font-size: 0px;
            }
            .custom-table svg.slds-button__icon.slds-button__icon_left{
                margin: 0px;
            }
            .custom-table lightning-primitive-file-droppable-zone.slds-file-selector__dropzone{
                border: none;
            }
            .custom-table .slds-textarea{
                min-height: 200px;
            }
            .custom-table{
                font-weight: 400;
            }
            .slds-listbox__option,
            .slds-listbox__option-text,
            .slds-media__body,
            .slds-listbox__item span {
            color: white !important;
            }
            `;

            // Append the styles to the .styleContainer
            this.template.querySelector('.styleContainer')?.appendChild(style);

            // Prevent re-adding styles
            this.isRendered = true;
        }
    }

    @api changeAccountType(str) {
        this.accountType = str;
        console.log('accountType--in changeMessage----', this.accountType);


    }

    connectedCallback() {
        //multiple files-Ishi
        this.getProductDetails();
        this.countOfDocument = 0;
        console.log('bsa' + this.fromSales);
        console.log('accountType------', this.accountType);

        const currentDate = new Date();
        const year = currentDate.getFullYear();
        const month = String(currentDate.getMonth() + 1).padStart(2, '0');
        const day = String(currentDate.getDate()).padStart(2, '0');
        this.today = `${year}-${month}-${day}`;
        this.isModalOpen = true;
        console.log('selectedApplicant in add bank---', JSON.stringify(this.selectedApplicant));
        this.customerSelected = this.selectedApplicant ? true : false;
        console.log('this.customerSelected---', this.customerSelected);
        if (this.selectedApplicant) {
            this.selectedCustOpt = this.selectedApplicant.value;
            this.accHolderName = this.selectedApplicant.label;
            this.selectedCustomer = this.selectedApplicant.customerType;

            this.fetchedCustomer = this.selectedApplicant.label + ' ( ' + this.selectedApplicant.customerType + ' )';
        }
    }

    handleSubmit(event) {
        console.log('this.selectedId----', this.selectedId);
        console.log('uploadedFilesSales--- 220--' + JSON.stringify(this.uploadedFilesSales))
        console.log('bsa--- 220--' + this.bsa)




        console.log('fromSales--- 220--' + this.fromSales)
        if (this.fromSales == true) {
            event.stopPropagation();
        }
        event.preventDefault();
        if (this.bsa && !this.fromSales && this.fromSales == false) {
            if (this.contentDocumentId == null || this.contentDocumentId == undefined || this.contentDocumentId == '') {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please upload document to proceed further.',
                        variant: 'error'
                    })
                );
                return;
            }
        }
        if (this.fromSales == true) {
            if ((this.toDate == '' || this.toDate == null || this.toDate == undefined) && (this.fromDate != '' || this.fromDate == undefined || this.fromDate == '')) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please select to and from dates',
                        variant: 'error',
                    }),
                );
                return;
            }
            let currentDate = new Date().toJSON().slice(0, 10);
            console.log('todayDate----', new Date());
            if (this.fromDate >= currentDate) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Statement start date cannot be future/current date',
                    variant: 'Error',
                }));
                return;
            }
            if (this.toDate > currentDate) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Statement end date cannot be future date',
                    variant: 'Error',
                }));
                return;
            }
            const from = new Date(this.fromDate);
            const to = new Date(this.toDate);
            const monthDifference = (to.getFullYear() - from.getFullYear()) * 12 + (to.getMonth() - from.getMonth());
            if (monthDifference > 12 || (monthDifference === 12 && to.getDate() > from.getDate())) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Date range cannot exceed 12 months between start and end date.',
                    variant: 'error',
                }));
                return;
            }
            if (this.ifscvalue == '' || this.ifscvalue == null || this.ifscvalue == undefined) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please select ifsc details to proceed forward',
                        variant: 'error',
                    }),
                );
                return;
            }
            if (this.fromDate > this.toDate) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Statement End Date should be after Statement Start Date.',
                        variant: 'error',
                    }),
                );
                return;
            }
            this.loanFacility = 'Saving';
            if (this.loanFacility == null || this.loanFacility == undefined || this.loanFacility == '') {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter loan facility.',
                        variant: 'error',
                    }),
                );
                return;
            }
            if ((this.loanFacility == 'CC' || this.loanFacility == 'OD') && (this.sanctionLimit == '' || this.sanctionLimit == null || this.sanctionLimit == undefined)) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter sanction limit.',
                        variant: 'error',
                    }),
                );
                return;
            }
            if (this.loanFacility == 'CC') {
                let isValid = true;
                this.inputValues = [];
                const inputs = this.template.querySelectorAll('.dynamic-number');
                const validPattern = /^[1-9][0-9]*[1-9]$/;
                var drawingSum = 0;
                inputs.forEach((input, index) => {
                    if (!input.checkValidity()) {
                        input.reportValidity();
                        isValid = false;
                    } else {
                        this.inputValues[index] = input.value;
                        drawingSum += parseFloat(input.value);
                    }
                });

                if (!isValid) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter drawing power for all the selected months.',
                            variant: 'error',
                        }),
                    );
                    return;
                }
                if (drawingSum >= this.sanctionLimit) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Sum of drawing power is more than sanction limit.',
                            variant: 'error',
                        }),
                    );
                    return;
                }
            }
            if (this.uploadedFilesSales == null || this.uploadedFilesSales == undefined || this.uploadedFilesSales.length == 0) {
                console.log('bsa--- 220--' + this.uploadedFilesSales)
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please upload document to proceed further.',
                        variant: 'error'
                    })
                );
                return;
            }
        }

        this.handleSuccessAlertClick();
    }

    @api openModal() {
        console.log('modalopen');
        //this.isModalOpen = true;
        this.connectedCallback();
    }

    getBranchDetails(event) {

        if (this.recId) {
            const rec = event.detail.records?.[this.recId];
            const ifscId = rec?.fields?.Bank_Master__c?.value;
            //var ifscId = event.detail.records[this.recordId].fields.Bank_Master__c.value;
            console.log('IFSC ID', ifscId);
            getIFSCDetails({ ifsc: ifscId, loanId: this.recordId })
                .then(result => {
                    console.log('result--' + result);
                    this.bankname = result.bankname;
                    this.branch = result.branch;
                    this.ifscV = result.ifscVal;
                    console.log('get ifsc detial ', this.ifscv);
                })
                .catch(error => {
                    this.error = error;

                });

            this.accHolderName = event.detail.records[this.recordId].fields.Account_Holder_Name__c.value;
            this.selectedCustOpt = event.detail.records[this.recordId].fields.Application_Applicant__c.value;
        }
    }

    closeModal() {
        this.isModalOpen = false;
        this.selectedCustOpt = '';
        this.accHolderName = '';
        this.closeAction();
    }

    handleOnChangeOpt(event) {
        console.log('fromSales-----' + this.fromSales)
        if (this.fromSales == true) {
            event.stopPropagation();
        }
        this.selectedCustOpt = event.target.value;
        console.log('cust options: ' + JSON.stringify(this.custOptions));
        var custLabel;
        var custLabelArr = [];
        for (var i = 0; i < this.custOptions.length; i++) {
            if (this.custOptions[i]['value'] == this.selectedCustOpt) {
                custLabel = this.custOptions[i]['label'];
                console.log('custLabel: ' + custLabel);


                custLabelArr = custLabel.split('(');
                console.log('custLabelArr:', custLabelArr);
                this.accHolderName = custLabelArr[0];
                console.log('this.accHolderName at 339--', this.accHolderName);

                var appType = custLabelArr[1].split(')');
                if (appType[0] == 'Primary Applicant') {
                    this.selectedCustomer = 'Applicant';
                }
                else {
                    this.selectedCustomer = appType[0];
                }
                if (this.selectedCustOpt == '') {
                    this.accHolderName = '';
                }
                console.log('this.accHolderName at 351--', this.accHolderName);
                console.log('label: ' + JSON.stringify(this.selectedCustomer));
            }
        }
    }

    handleChange(event) {
        if (this.fromSales == true) {
            event.stopPropagation();
        }
        console.log('debug99 ' + this.bsa)
        this.ifscvalue = event.target.value;
        console.log('ifsc value', this.ifscvalue);
        getIFSCDetails({ ifsc: this.ifscvalue, loanId: this.recordId })
            .then(result => {
                console.log('result--' + result);
                this.bankname = result.bankname;
                this.branch = result.branch;
                this.ifscV = result.ifscVal;
                console.log('get ifsc detial agian ', this.ifscv);
            })
            .catch(error => {
                this.error = error;
            });
    }

    handleSuccess(event) {
        if (this.fromSales == true) {
            event.stopPropagation();
        }
        var bankdetail;
        console.log('this.selectedCustOpt- at 318---', this.selectedCustOpt);
        getBankDetails({ applicantId: this.selectedCustOpt })
            .then(result => {
                console.log('result in getBankDetails--' + JSON.stringify(result));


                if (result) {
                    bankdetail = result;
                    console.log('Bank Detail ', result);
                    if (this.bsa == true && !this.fromSales) {
                        console.log('result.Id---', result.Id);
                        console.log('this.selectedCustOpt----', this.selectedCustOpt);
                        var bankId = result.Id;
                        createDocumentDetail({ applicationId: this.selectedCustOpt, bankDetailRecord: bankId, loanAppId: this.recordId, contentDocumentId: this.contentDocumentId })
                            .then(result => {
                                console.log('result--00' + result);
                                createBSArecord({ bdRecordId: bankId })
                                    .then(result => {
                                        console.log("created BSA record ", result);
                                        const valueEvent2 = new CustomEvent('savedbankrecord', { detail: bankId });
                                        this.dispatchEvent(valueEvent2);
                                    })
                                    .catch(error => {
                                        console.log('Error in creating records---', error);
                                    })
                            })
                            .catch(error => {
                                console.log(error)
                                console.log('result--00 failed');
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error in creating document Details',
                                        message: error.body.message,
                                        variant: 'error'
                                    })
                                );
                            });
                    }
                    else {
                        if (this.fromSales == false) {
                            const valueEvent2 = new CustomEvent('savedbankrecord', { detail: bankdetail });
                            this.dispatchEvent(valueEvent2);
                        }
                        else {
                            console.log('414');
                            this.template.querySelectorAll('lightning-input-field').forEach(field => {
                                field.value = null;
                            });
                            if (this.inputValues) {
                                this.drawingPower = this.inputValues.join(',');
                            }
                            const valueEvent2 = new CustomEvent('savedbankrecord', {
                                detail: {
                                    bankdetail: bankdetail,
                                    fromDate: this.fromDate,
                                    toDate: this.toDate,
                                    passWord: this.passWord,
                                    drawingPower: this.drawingPower,
                                    contentDocumentId: this.contentDocumentId
                                }
                            });
                            this.dispatchEvent(valueEvent2);
                            console.log('this.monthInputs-----', this.monthInputs)
                            this.inputValues = '';
                            this.fromDate = '';
                            this.toDate = '';
                            this.passWord = '';
                            this.ifscvalue = '';
                            this.drawingPower = '';
                            this.inputValues = [];
                            this.monthInputs = [];
                            this.inputValues = '';
                            console.log('this.inputValues-----', this.inputValues)
                            const lookupCmp = this.template.querySelector('c-search-lookup');
                            if (lookupCmp) {
                                lookupCmp.handleReset();
                                console.log('this.inputValues-----', this.inputValues)
                            }
                        }
                    }
                    if (this.fromSales == false) {
                        this.isModalOpen = false;
                        console.log('Final--', JSON.stringify(event.detail));
                        this.selectedCustOpt = '';
                        this.accHolderName = '';
                    }
                    this.spinnerRun = false;
                }
            })
            .catch(error => {
                this.error = error;
                console.log('error in getBankDetails', error);

            });
        setTimeout(() => {
            this.closeAction();
        }, 1000);

    }
    openCameraNonDocument(event) {
        this.selecteddocCheckId = event.target.dataset.id;
        console.log('this.selecteddocCheckId -->' + this.selecteddocCheckId);
        this.template.querySelector('.hidden-input-finish').click();
    }
    handleUploadFinished(event) {
        this.countOfDocument = 0;
        const uploadedFiles = event.detail.files;
        this.showDocumentName = false;
        const validNamePattern = /^[a-zA-Z0-9. ]+$/;
        if (this.fromSales) {
            console.log('event.detail.files-----', JSON.stringify(event.detail.files));
            console.log('uploadedFiles', uploadedFiles.length);
            for (var i = 0; i < uploadedFiles.length; i++) {
                console.log('fileName-----', JSON.stringify(event.detail.files[i]))
                const filedet = event.detail.files[i];
                if (!validNamePattern.test(event.detail.files[i].name)) {
                    console.log('fileName- 702----', JSON.stringify(event.detail.files[i]))
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Invalid File Name',
                            message: 'File name contains special characters.',
                            variant: 'error',
                        })
                    );
                    return;
                }
                else if (!event.detail.files[i].mimeType.includes('application/pdf')) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please upload PDF Files only',
                            variant: 'error',
                        })
                    );
                    return;
                }
                else {
                    getFileSize({ contentDocumentId: event.detail.files[i].documentId })
                        .then(size => {
                            if (size > this.MAX_SIZE) {
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: 'File exceeds 25 MB and is not allowed.',
                                        variant: 'error',
                                    })
                                );
                                deleteUploadedFile({ contentDocumentId: event.detail.files[i].documentId })
                                    .then(size => {
                                    })
                                    .catch(error => {
                                    });
                                return;
                            }
                            else {
                                this.uploadedFilesSales.push(filedet);
                                console.log('fileName--770---', JSON.stringify(filedet));
                                this.uploadedFileName.push(filedet.name);
                                this.showDocumentName = true;
                                console.log('this.uploadedFilesSales : ' + JSON.stringify(this.uploadedFilesSales));
                                this.showToastMethod('Success', 'Document uploaded successfully.', 'success');
                            }
                        })
                        .catch(error => {
                            console.log('errpr', error);
                        });
                }
            }
        }
        else {
            console.log('debug77 : ' + uploadedFiles[0].documentId);
            this.contentDocumentId = uploadedFiles[0].documentId;
            this.showToastMethod('Success', 'statement uploaded successfully.', 'success');
        }
    }

    createDocumentChecklistForSales() {
        console.log('selectedCustOpt- 676-----', this.selectedCustOpt);
        const uploadParam = {
            'loanid': this.loanId,
            'docName': 'Work Experience Proof',
            'docRequiredFor': 'Income Bank Statement',
            'docCategory': 'Income Documents and Bank Statements',
            'manualAA': this.manualAA,
            'applicantId': this.selectedCustOpt
        };
        createDocumentChecklistForSales({ uploadParam: uploadParam })
            .then(result => {
                console.log('result0-----', result)
                if (result != null && result != '' && result != undefined) {
                    this.salesReturnedDocumentId = result;
                    this.uploadedFilesSales.forEach(file => {
                        this.uploadedFilesList.push({
                            id: file.documentId,
                            name: file.name,
                            downloadUrl: file.downloadUrl
                        });
                    });
                    for (var i = 0; i < this.uploadedFilesSales.length; i++) {
                        this.countOfDocument = this.countOfDocument + 1;
                        console.log('this.countOfDocument ', this.countOfDocument);
                        this.insertFileRecordToSalesforce(this.uploadedFilesSales[i]);
                    }
                }
            })
            .catch(error => {
                console.error('Error in checkExceptionStatus:', error);
            });
    }
    insertFileRecordToSalesforce(file) {
        insertFileRecord({
            fileName: file.name,
            fileSize: file.size,
            fileContentDocumentId: file.documentId,
            recordId: this.salesReturnedDocumentId
        })
            .then(() => {
                if (this.countOfDocument == this.uploadedFilesSales.length) {
                    if (this.inputValues) {
                        this.drawingPower = this.inputValues.join(',');
                    }
                    console.log('ifscvalue------c/addManualBankDACmp', this.ifscvalue)
                    const valueEvent2 = new CustomEvent('savedbankrecord', {
                        detail: {
                            bankdetail: this.ifscvalue,
                            fromDate: this.fromDate,
                            toDate: this.toDate,
                            passWord: this.passWord,
                            drawingPower: this.drawingPower,
                            documentChecklistId: this.salesReturnedDocumentId,
                            fileName: this.uploadedFileName
                        }
                    });
                    this.dispatchEvent(valueEvent2);


                    this.fromDate = '';
                    this.toDate = '';
                    this.passWord = '';
                    this.ifscvalue = '';
                    this.drawingPower = '';
                    this.uploadedFileName = [];
                    this.uploadedFilesSales = [];
                    this.inputValues = '';
                    this.monthInputs = [];
                    this.inputValues = [];

                    const lookupCmp = this.template.querySelector('c-search-lookup');
                    if (lookupCmp) {
                        lookupCmp.handleReset();
                    }
                }


            })
            .catch((error) => {

            });
    }
    handleUploadFinished1(event) {
        console.log(JSON.stringify(event));
        const file = event.target.files[0];
        console.log('file -->' + file);
        if (file) {
            console.log('file 120 -->' + file);

            this.compressImage(file).then(compressedFile => {

                const originalSize = file.size;
                const fileName = file.name;
                const fileType = file.type;
                const compressedReader = new FileReader();
                const compressedSize = compressedFile.size;
                setTimeout(() => {

                    compressedReader.onload = async () => {
                        const compressedUrl = compressedReader.result;
                        const base64Data = compressedUrl.split(',')[1];
                        console.log('compressedUrl=:' + compressedUrl);
                        // console.log('file 132 -->'+file);
                        await uploadFileNonDocument({
                            base64Data: base64Data,
                            fileName: fileName,
                            fileType: fileType
                        })
                            .then(result => {
                                if (result != '' && result != null && result != undefined) {
                                    if (this.nonDocList == undefined || this.nonDocList == [] || this.nonDocList == null || this.nonDocList == '' || this.nonDocList.length == 0) {
                                        var docWrap = {};
                                        docWrap.documentName = '';
                                        docWrap.reqLevel = '';
                                        docWrap.contactName = '';
                                        docWrap.contentId = result;
                                        docWrap.showPreview = true;
                                        docWrap.sequence = 1;
                                        this.nonDocList.push(docWrap);
                                    }
                                    else {
                                        var docWrap = {};
                                        docWrap.documentName = '';
                                        docWrap.reqLevel = '';
                                        docWrap.contactName = '';
                                        docWrap.contentId = result;
                                        docWrap.showPreview = true;
                                        docWrap.sequence = this.nonDocList.length + 1;
                                        this.nonDocList.push(docWrap);
                                    }
                                    this.shownonDocDetailsTable = true;
                                    this.sendToastMessage('Success', 'File Uploaded Successfully', 'Success');
                                }
                                else {
                                    this.sendToastMessage('Error', 'Please retry', 'error');
                                }
                            })
                            .catch(error => {
                                console.error('Error uploading file:', error);
                            });
                    }
                    compressedReader.readAsDataURL(compressedFile);
                }, 500)
            });
        }
        this.template.querySelector('.hidden-input-finish').value = null;
        event.target.value = "";

    }
    handleError(event) {
        console.log('fromSales- 541----' + this.fromSales)
        if (this.fromSales == true) {
            event.stopPropagation();
            const hasFrom = !!this.fromDate;
            const hasTo = !!this.toDate;
            if (!hasFrom || !hasTo) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please select from and to year for the bank statement that you are trying to upload.',
                        variant: 'error',
                    }),
                );
                return;
            }
            /*if((this.toDate == ''||this.toDate == null||this.toDate == undefined ) && (this.fromDate != ''||this.fromDate == undefined||this.fromDate == '')){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title:'Error',
                        message:'Please select from and to year for the bank statement that you are trying to upload.',
                        variant:'error',
                    }),
                );
            }*/

        }

        console.error('error found adding Bank acc: ' + JSON.stringify(event.detail));
        if (event.detail.detail) {
            this.showToastMethod('Error', event.detail.detail, 'Error');
        }
        else {
            this.showToastMethod('Error', 'Something went wrong, please contact system administrator.', 'Error');
        }
        this.spinnerRun = false;
    }

    closeAction(event) {
        console.log('fromSales---- 580-' + this.fromSales)
        console.log('close action---');
        this.dispatchEvent(new CustomEvent('closemodal', {
            detail: { data: this.isModalOpen }
        }));
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToastMethod(toastTitle, toastMessage, toastVariant) {
        const evt = new ShowToastEvent({
            title: toastTitle,
            message: toastMessage,
            variant: toastVariant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
    async handleConfirmClick() {
        const result = await LightningConfirm.open({
            message: "Bank Account is already added. Do you want to add another.",
            variant: "default", // headerless
            label: "Confirmation Required."
        });
        if (result) {
            this.isModalOpen = true;
        } else {
            this.isModalOpen = false;
            this.disconnectedCallback();
        }
    }
    handleSuccessAlertClick(event) {
        console.log('fromSales--572---' + this.fromSales);
        var isValid = true;
        var ifsc;
        var accNumb;
        var bankName;
        var nameOfAccHolder;
        console.log('accountype in successss-', this.accountType);
        let fields = {};
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        console.log('INput fields', inputFields);
        console.log('fromSales--586---' + inputFields)
        if (inputFields) {
            console.log('fromSales--586---' + inputFields)
            inputFields.forEach(field => {
                console.log('Field: ' + field.fieldName);
                console.log('Field value: ' + field.value);
                //Sanwar Start
                if ((field.fieldName === 'Account_Type__c' || field.fieldName === 'Account_Number__c')) {
                    if (!field.value || !this.bankname) {
                        isValid = false;
                        if (!isValid) {
                            this.showToastMethod('Error', 'Please fill in all required fields.', 'error');
                            event.preventDefault();
                            return;
                        }
                    }
                }
                if (this.selectedCustomer == 'Applicant' && field.fieldName == 'Loan_Application__c') {
                    field.value = this.recordId;
                }
                console.log('FIELD NAME ', field.fieldName);
                if (field.fieldName == 'Bank_Master__c') {
                    console.log('ifsc data is ', field.value);
                    ifsc = field.value;
                }
                if (field.fieldName == 'Account_Number__c') {
                    accNumb = field.value;
                }
                if (field.fieldName == 'Account_Holder_Name__c') {
                    nameOfAccHolder = field.value;
                }
                ifsc = this.ifscV ? this.ifscV : this.ifscvalue;
                console.log('Ifsc value ', ifsc);
                if (this.isLoanApp || this.fromBuilderSeller) {
                    fields[field.fieldName] = field.value;
                }
            });
        }
        if (this.isLoanApp || this.fromBuilderSeller) {
            fields.Bank_Master__c = this.ifscvalue;
            fields.IFSC__c = this.ifscV;//Arman : adding this  25htMarch 2026 to handle the fillinf of IFSC__c on Bank details record
        }
        console.log('isvalid=:' + isValid);
        if (!this.fromSales && this.recId == null && this.trancheId == null) {
            let comboField1 = this.template.querySelector(".combo1");
            if (isValid && comboField1 && comboField1.value == '') {
                console.log('appli');
                this.showToastMethod('Error', 'Please Select Applicant/Co-Applicant', 'Error');
                isValid = false;
                event.preventDefault();
                return;
            }
        }
        console.log('isvalid=:' + isValid);
        if (this.fromSales) {
            if (this.uploadedFilesSales == null || this.uploadedFilesSales == undefined || this.uploadedFilesSales.length == 0) {
                console.log('appli');
                this.showToastMethod('Error', 'Please upload bank statement to proceed further.', 'Error');
                isValid = false;
                event.preventDefault();
                return;
            }
        }
        if (!this.fromSales) {
            var alphas = /^[A-Za-z\s]+$/;
            let accHolderField = this.template.querySelector(".accHolder");
            console.log('isvalid=:' + isValid);
            if (isValid) {
                console.log('at 690 is valid---');
                if (this.fromSales) {
                    console.log('at 693 from sales');
                } else {
                    this.spinnerRun = true;
                    console.log('ifsc ', ifsc);
                    console.log('accNumb ', accNumb);
                    isDupBank({ loanAppId: this.recordId, ifsc: ifsc, acNumber: accNumb })
                        .then(result => {
                            console.log('result--' + result);
                            if (result) {
                                this.showToastMethod('Error', 'This Bank Account is already added. Bank Account No. + IFSC code should be unique.', 'Error');
                                event.preventDefault();
                                this.spinnerRun = false;
                                return;
                            }
                            else {
                                console.log('fields 1213', fields, this.fromBuilderSeller);
                                if (this.isLoanApp || this.fromBuilderSeller) {
                                    this.template.querySelector('lightning-record-edit-form').submit(fields);
                                } else {
                                    this.template.querySelector('lightning-record-edit-form').submit();
                                }
                            }
                        })
                        .catch(error => {
                            this.error = error;
                            console.log('error in isDupBank', error);

                        });
                }
            }
        }
        else {
            this.createDocumentChecklistForSales();
        }

    }
    disconnectedCallback() {
        this.isModalOpen = false;
    }

    handlePreviewClick() {
        console.log('this.contentDocumentId=:' + this.contentDocumentId);
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: this.contentDocumentId
            }
        })
    }

    handleMonthChange(event) {
        console.log('event.target.value=: handleMonthChange' + event.target.value);
        this.selectedMonth = event.target.value;
    }

    handleYearChange(event) {
        console.log('event.target.value=: handleYearChange' + event.target.value);
        this.selectedYear = event.target.value;
    }

    handleStopPropogation(event) {
        console.log('704')
        if (this.fromSales == true) {
            event.stopPropagation();
        }
        const inputField = event.target;
        const fieldName = inputField.dataset.field;
        const value = inputField.value;

        if (fieldName === 'Account_Number__c') {
            if (this.fromSales == true) {
                const accountNumberField = this.template.querySelector('[data-id="accountNumber"]');

                const accountNumberValue = accountNumberField.value;

                console.log('accountNumberValue in submit----', accountNumberValue);

                if (!isValidMobileNumber(accountNumberValue)) {
                    this.template.querySelector('[data-id="accountNumber"]').value = null;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter account number in correct format',
                            variant: 'error',
                        }),
                    );

                    return;

                }
            } else {
                const isValid = /^[a-zA-Z0-9]+$/.test(value);//sanwar(11/12/2025)
                if (!isValid && value) {
                    inputField.value = '';
                    this.showToastMethod('Invalid Input', 'Please enter alphabets or numbers only', 'error');//sanwar(11/12/2025)
                }
            }
        }
    }
    handleDateChange(event) {
        if (event.target.name === 'fromDate') {
            this.fromDate = event.target.value;
        } else if (event.target.name === 'toDate') {
            this.toDate = event.target.value;
        }
        if (this.loanFacility == 'CC') {
            this.calculateMonths();
        }

    }

    calculateMonths() {
        if (this.fromDate && this.toDate && this.toDate > this.fromDate) {
            const start = new Date(this.fromDate);
            const end = new Date(this.toDate);
            // const start = this.fromDate;
            // const end = this.toDate;
            const months = (end.getFullYear() - start.getFullYear()) * 12 + (end.getMonth() - start.getMonth()) + 1;
            this.monthDifference = months;

            this.monthInputs = Array.from({ length: months }, (_, index) => ({
                id: index,
                label: `Month ${index + 1}`
            }));

            this.inputValues = new Array(months).fill('');
        }
    }

    handleDrawingInputChange(event) {
        if (event.target.value < 1 || event.target.value > 9999999999) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter drawing power between 1 and 9999999999',
                    variant: 'error'
                })
            );
            event.target.value = null;
            return;

        } else {
            const index = event.target.dataset.index;
            this.inputValues[index] = event.target.value;
        }

    }

    validateNumber(event) {
        const inputCmp = event.target;
        const value = inputCmp.value;

        // Regex: Only digits, no decimal, last digit 1-9
        const validPattern = /^[1-9][0-9]*[1-9]$/;

        if (!validPattern.test(value)) {
            inputCmp.setCustomValidity("Number must be an integer (no decimals) and should not end in 0");
        } else {
            inputCmp.setCustomValidity("");
        }

        inputCmp.reportValidity();
    }

    handleSelectDocument(event) {
        console.log('event in lookuppp---', JSON.stringify(event));
        this.ifscvalue = event.detail.searchRecord.Id;
        console.log('ifscvalue in lookup----', this.ifscvalue);
        console.log('ifscvalue in lookup----', this.ifscvalue);
        getIFSCDetails({ ifsc: this.ifscvalue, loanId: this.recordId })
            .then(result => {
                console.log('result--' + result);
                this.bankname = result.bankname;
                this.branch = result.branch;
                this.ifscV = result.ifscVal;
                console.log('IFSC value ', this.ifscV);
                console.log('this.bankname= in handle change---', this.bankname);
                console.log('this.branch=in handle change---', this.branch);
                if (this.bankname && this.bankname) {
                    const name = this.bankname ?? '';
                    this.cleanedBankName = name.includes(',')
                        ? name.trim()
                        : name.trim();

                    console.log('Cleaned Name:', this.cleanedBankName);
                    getBranchNameForBank({ bankName: this.cleanedBankName })
                        .then(result => {
                            this.branchRecordsData = result;
                            console.log('At 465', result);
                            this.branchOptions = result?.map(value => ({ label: `${value.Branch_Name__c} - ${value.Branch_Location__c}`, value: value.Id }));
                            this.selectedBranch = this.branchOptions[0]?.Id;
                            console.log('At 467', this.branchOptions);
                        })
                }

            })
            .catch(error => {
                this.error = error;

            });

    }

    handleldeselectDocument() {
        this.ifscvalue = '';
        this.bankname = '';
        this.branch = '';
        this.ifscV = '';
        this.branchOptions = [];
        this.selectedBranch = '';
    }

    handlePasswordChange(event) {
        this.passWord = event.target.value;
    }

    handleInputChange(event) {
        try {
            this.selectedBranch = this.branchRecordsData.find(branch => branch.Id === event.target.value);
            this.selectedBankBranch = event.target.value;
            if (this.selectedBranch) {
                this.ifscvalue = this.selectedBankBranch;
                this.branch = this.selectedBankBranch;
                this.bankname = this.selectedBranch.Bank_Name__c;
            }
        } catch (error) {
            console.log('error', error);
        }
    }
    //HL
    getProductDetails() {
        console.log('1528' + this.recordId);
        const inputMap = {
            'oppId': this.recordId
        }
        console.log('1528' + this.recordId);
        getProductDetails({ inputMap: inputMap })

            .then(response => {
                console.log('response' + response);
                this.showHLRelatedData = response.isHLRelated;
                this.product = response.loanProduct;
                /*console.log('Product Details: '+JSON.stringify(this.product));
                if(this.product == 'Home Loan'||this.product=='Non Home Loan'||this.product=='Flexi Loan'){
                    this.showHLRelatedData = true;
                }*/
            })
            .catch(error => {
                console.log(error);
            });
    }
    fetchCustomerDetails() {
        getCustomerDetails({ loanAppId: this.recordId })
            .then(data => {
                console.log('data refresh', data);
                this.getCustomerDetail({ data: data, error: null });
            })
            .catch(error => {
                this.getCustomerDetail({ data: null, error: error });
            });
    }
    @api refreshData() {
        this.fetchCustomerDetails();
    }

}