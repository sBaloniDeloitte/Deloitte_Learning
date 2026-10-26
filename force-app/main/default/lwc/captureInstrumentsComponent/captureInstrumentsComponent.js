import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPurposeValues from '@salesforce/apex/CaptureMandateController.getPurposeValues';
import getApplicants from '@salesforce/apex/CaptureMandateController.getApplicants';
import getBankDetails from '@salesforce/apex/CaptureMandateController.getBankDetails';
import createInstruments from '@salesforce/apex/CaptureMandateController.createInstruments';
import fetchCreatedInstruments from '@salesforce/apex/CaptureMandateController.fetchCreatedInstruments';
import deleteInstrument from '@salesforce/apex/CaptureMandateController.deleteInstrument';
import updateInstrument from '@salesforce/apex/CaptureMandateController.updateInstrument';
import uploadFile from '@salesforce/apex/CaptureMandateController.uploadInstrumentFile';
import reUploadFile from '@salesforce/apex/CaptureMandateController.reUploadInstrumentFile'
import getLoanInfo from '@salesforce/apex/CaptureMandateController.getLoanInfo';
import getRepaymentAccountDetails from '@salesforce/apex/CaptureMandateController.getRepaymentAccountDetails';
import fetchSchedule from "@salesforce/apex/COMM_RepaymentScheduleController.fetchSchedule";
import canUserEditMandate from '@salesforce/apex/CaptureMandateController.canUserEditMandate';
import canUserEditRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.canUserEditRecord';
import {getRecord} from "lightning/uiRecordApi";
import STAGE_FIELD from "@salesforce/schema/Opportunity.StageName";
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
import USERID_FIELD from "@salesforce/user/Id";
import getOpportunityTeamMembers from '@salesforce/apex/AHL_LoanDetailsController.getOpportunityTeamMembers';



export default class CaptureInstrumentsComponent extends LightningElement {
    @api recordId; // Loan Application ID
    cssContainer = 'slds-modal__container width-60';
    @track selectedBankDetail = {}; // Holds auto-populated bank details
    @track purposeOptions = [];
    @track isSaving = false;
    @track isVisible = true;
    @track error;
    @track applicants = []; // List of applicants for dropdown
    @track selectedApplicantId = ''; // Selected applicant ID
    @track selectedApplicantType = ''; // Auto-populated Customer Type
    @track bankDetails = []; // Bank details of the selected applicant
    @track showBankModal = false; // Modal visibility control
    @track instrument = { purpose: '',  startingInstrumentNumber: '', endingInstrumentNumber:'' };
    @track instrumentCreated = false;
    @track createdInstruments = [];
    @track instrumentBeingEdited;
    //@track isEditing= false;
    @track updatedPurpose = {};
    selectedApplicant;
    openBankAccountModal=false;
    @track loanTenure = 0; // Store the loan tenure (months)
    showCreateBankAccBtn = true;
    loanStage = '';
    showEditableInstNo = true;
    @track repaymentAccounts = [];
    showInstrumentScheduleModal = false;
    instrumentSchedule = [];
    @track isEditableUser = true;
    oppSubStage = '';
    oppStage = '';
    currentUserOppRole = [];

    showPreview = false;
    contentDocId = '';
    docDetailId = '';
    fileType = '';
    showPdf = false;
    pdfUrl = null;
    showImage = false;
    imageUrl = null;
    isRetakeCase = false;
    lattitude;                         //to get the lattitude value
    longitude;                         //to get the longitude value

    toastVariant = {
        SUCCESS: 'success',
        ERROR: 'error',
        WARNING : 'warning'
    }
    toastTitle = {
        SUCCESS: 'Success',
        ERROR: 'Error',
        WARNING : 'Warning'
    }

    toastMessages = {
        RECORD_CREATION_SUCCESS_MSG: 'Record has been created Successfully.',
        RECORD_UPDATED_SUCCESSFULLY : 'Record updated Successfully',
        SOMETHING_WENT_WRONG: 'Something went wrong.',
        ERROR_OCCURED_WHILE_SAVING: 'Error occured while saving the Record. Please enter valid input and try again.',
        VAS_RECORD_DELETED_SUCCESSFULLY : 'VAS Record Deleted Successfully.',
        RECORD_IN_EDIT_MODE_CANNOT_BE_DELETED : 'Please save the VAS changes before deleting the record.',
        VAS_RECORD_IS_ALREADY_CREATED : 'VAS Record is already created for the selected Customer.',
        INSURANCE_PREMIUM_VALIDATION : 'Insurance Premium is more than 5% of Loan Amount.',
        ONLY_ONE_VASRECORD : 'VAS Only Loan Opportunity can have only ONE VAS',
    }

    
    connectedCallback() {
        canUserEditMandate({ opportunityId: this.recordId })
        .then(result => {
            this.isEditableUser = true;
            console.log('Is editable user:', this.isEditableUser);
        })
        .catch(error => {
            console.error('Error checking user access for VAS:', error);
            this.isEditableUser = false; // Default to read-only if error
        });

        // //Sanwar
        // canUserEditRecord({recordId: this.recordId})
        // .then(result => {
        //     if(result){
        //         this.isVisible = false;
        //     }
        // })

        this.fetchRepaymentAccounts();
        this.fetchPurposeOptions();
        this.fetchApplicants();
        this.loadCreatedInstruments();
        this.fetchLoanTenure(); // Fetch loan tenure from backend
    }

    //Sanwar Start
    @wire(getOpportunityTeamMembers, {
        loanId: "$recordId",
    })
    getOppTeamMembers({
        data,
        error
    }) {
        if (data) {
            console.log('data ',data);
            data.forEach(item => {
                console.log('User Data');
                console.log('user id',item.UserId);
                if(item.UserId == USERID_FIELD){
                    this.currentUserOppRole.push(item.TeamMemberRole);    
                }
            })
            console.log('Current user role ',this.currentUserOppRole);
        } else if (error) {
            this.showToast(this.toastTitle.ERROR, this.toastMessages.SOMETHING_WENT_WRONG, this.toastVariant.ERROR);
        }
    }

    @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD, SUBSTAGE_FIELD] })
    opportunity({ error, data }) {
        if(data) {
            this.oppStage = data.fields.StageName.value;
            this.oppSubStage = data.fields.Sub_stage__c.value;
            console.log('Opp sub stage' , this.oppSubStage);
            setTimeout(() => {
                this.handleVisibility();
            }, 1000);
        }
    }

    handleVisibility(){
        console.log('Stage', this.oppStage);
        console.log(' Sub stage', this.oppSubStage);
        if((this.oppStage == 'Disbursement' && this.oppSubStage == 'Ops Maker' && (this.currentUserOppRole.includes('OPS Maker') || this.currentUserOppRole.includes('Credit Officer'))) || 
            (this.oppStage == 'PSV' && this.oppSubStage == 'PSV Sales' && this.currentUserOppRole.includes('Sales'))){
            this.isVisible = true;
        }
        if((this.oppStage == 'PSV' && this.oppSubStage == 'PSV Sales') || (this.oppStage == 'PSV' && this.oppSubStage == 'PSV Credit')){
            this.showCreateBankAccBtn=false;
        }
    }//Sanwar End

    fetchLoanTenure() {
        getLoanInfo({ loanApplicationId: this.recordId })
            .then(result => {
                this.loanTenure = result.Sanction_Tenure__c ? result.Sanction_Tenure__c : 0;
                console.log('Loan Tenure:', this.loanTenure);

                this.loanStage = result.StageName;

                if(this.loanStage == 'Disbursement'){
                    this.showCreateBankAccBtn = false;
                    this.showEditableInstNo = false;
                }
            })
            .catch(error => {
                console.error('Error fetching loan tenure:', error);
                this.loanTenure = 0; // Default to 0 if there's an error
            });
    }
    
    // Fetch repayment account details and auto-populate first record
    fetchRepaymentAccounts() {
        if (!this.recordId) {
            console.error('Loan Application ID is required.');
            return;
        }

        getRepaymentAccountDetails({ loanApplicationId: this.recordId })
            .then(result => {
                this.repaymentAccounts = result.map(row => ({
                    id: row.Id,
                    accountHolderName: row.Account_Holder_Name__c,
                    accountHolderId: row.Application_Applicant__c,
                    bankName: row.Name, 
                    accountNumber: row.Account_Number__c,
                    accountType: row.Account_Type__c,
                    applicanttype: row.Application_Applicant__r.Applicant_Type__c,
                    ifsc: row.Bank_Master__r?.IFSC__c || '',
                    micr: row.Bank_Master__r?.MICR__c || '',
                    branchLocation: row.Bank_Master__r ? row.Bank_Master__r.Branch_Location__c : '',
                    branchName: row.Bank_Master__r ? row.Bank_Master__r.Branch_Name__c : ''
                }));
                if (this.repaymentAccounts.length > 0) {
                    this.selectedBankDetail = this.repaymentAccounts[0]; // Auto-select first record
                    this.selectedApplicantId = this.repaymentAccounts[0].accountHolderId;
                    this.selectedApplicantType = this.repaymentAccounts[0].applicanttype;
                }
                
                console.log('Auto-populated bank details:', JSON.stringify(this.selectedBankDetail));
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.repaymentAccounts = [];
                console.error('Error fetching repayment account details:', error);
            });
    }

    // Fetch Mandate Type options for dropdown
    fetchPurposeOptions() {
        getPurposeValues()
            .then(result => {
                this.purposeOptions = result.map(value => ({ label: value, value: value }));
            })
            .catch(error => {
                console.error('Error fetching Mandate Type values:', error);
            });
    }

    // Fetch Applicants for Dropdown
    fetchApplicants() {
        console.log('this.recordId:: '+this.recordId);
        getApplicants({ loanApplicationId: this.recordId })
            .then(result => {
                console.log('this.result:: '+JSON.stringify(result));
                this.applicants = result.map(applicant => ({
                    label: applicant.Name,
                    value: applicant.Id,
                    customerType: applicant.Applicant_Type__c
                }));
            })
            .catch(error => {
                console.error('Error fetching applicants:', error);
            });
    }

    // Handle Applicant Selection
    handleApplicantChange(event) {
        this.selectedApplicantId = event.target.value;

        // Find the selected applicant from the dropdown data
        let selectedApplicant = this.applicants.find(app => app.value === this.selectedApplicantId);

        // Ensure customerType is properly populated
        this.selectedApplicantType = selectedApplicant ? selectedApplicant.customerType : '';
        this.selectedApplicant = selectedApplicant ? selectedApplicant : {};
        console.log('Selected Applicant:', JSON.stringify(selectedApplicant));
        console.log('Customer Type:', this.selectedApplicantType);

        // Fetch Bank Details for Selected Applicant
        this.fetchBankDetails();
    }

    // Fetch Bank Details for the Selected Applicant
    fetchBankDetails() {
        getBankDetails({ applicantId: this.selectedApplicantId })
            .then(result => {
                if (result && result.length > 0) {
                    this.bankDetails = result.map(bank => ({
                        id: bank.Id,
                        bankName: bank.Name || '',  // Extracting Bank Name
                        customerName: bank.Account_Holder_Name__c || '',  // Extracting Account Holder Name
                        branchName:  '',
                        ifsc: bank.Bank_Master__r?.IFSC__c || '',
                        isRepayment: bank.Is_Repayment_Account__c || '',
                        accountNumber: bank.Account_Number__c || '',
                        micr: bank.Bank_Master__r?.MICR__c || '',
                        accountType: bank.Account_Type__c || '',
                        branchName:  bank.Bank_Master__r?.Branch_Name__c || '',  // Extracting Branch Name
                        branchLocation: bank.Bank_Master__r?.Branch_Location__c || ''  // Extracting Branch Location,
                    }));
                    console.log('this.bankDetails:: '+JSON.stringify(this.bankDetails));
                    this.showBankModal = true; 
                } else {
                    this.bankDetails = []; // Clear previous data if no bank details found
                    this.showToast('Warning', 'No bank details found for selected customer', 'warning');
                }
            })
            .catch(error => {
                console.error('Error fetching bank details:', error);
            });
    }

    handleBankSelection(event) {
        const selectedBankId = event.target.value;
        console.log('selectedBankId:: '+selectedBankId);
        this.selectedBankDetail = this.bankDetails.find(bank => bank.id === selectedBankId);
        
        console.log('Selected Bank:', JSON.stringify(this.selectedBankDetail));
    
        this.showBankModal = false; // Close the modal after selection
    }

    handleScheduleSelection(event) {
        const selectedScheduleId = event.target.dataset.id;
        const selectedScheduleAmount = event.target.value;
        console.log('selectedScheduleId:: '+selectedScheduleId);

        this.createdInstruments = this.createdInstruments.map(instrument => {
            if(instrument.id === this.editingInstrumentId) {
                return {
                    ...instrument,
                    instrumentdate: selectedScheduleId,
                    instrumentamount: selectedScheduleAmount
                };
            }
            return instrument;
        });
        
        //console.log('Selected Schedule:', JSON.stringify(this.createdInstruments));
    
        this.showInstrumentScheduleModal = false; // Close the modal after selection
    }

    // Close Modal
    closeBankModal() {
        this.showBankModal = false;
    }

    closeInstrumentScheduleModal() {
        this.showInstrumentScheduleModal = false;
    }

    // Handle Input Changes
    handleInputChange(event) {
        const field = event.target.dataset.field;
        let value = event.target.value;
        console.log('At 265',value);
        console.log('At 264', field);
        const regex = /^[0-9]*$/;

        if ((field === 'startingInstrumentNumber' || field === 'endingInstrumentNumber')) {
            if (value && !regex.test(value)) {
                event.target.value = '';
                this.showToast('Invalid Input', 'Only Numeric digits are allowed', 'error');
                return;
            }
            if (value && value.length > 6) {
                event.target.value = '';
                this.showToast('Invalid Input', 'Only 6 digits are allowed', 'error');
                return;
            }
        }

        this.instrument[field] = event.target.value;
    }

    // Show Toast Message
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    createInstrument() {
        console.log('this.instrument.purpose:: ' + this.instrument.purpose);
        console.log('this.instrument.startingInstrumentNumber:: ' + this.instrument.startingInstrumentNumber);
        console.log('this.instrument.endingInstrumentNumber:: ' + this.instrument.endingInstrumentNumber);
    
        // Ensure Bank Detail ID is selected
        if (!this.selectedBankDetail || !this.selectedBankDetail.id) {
            this.showToast('Error', 'Kindly select Bank Account Details for the applicant to create mandate!', 'error');
            return;
        }
        if (!this.instrument.purpose || !this.instrument.startingInstrumentNumber || !this.instrument.endingInstrumentNumber) {
            this.showToast('Error', 'All fields are required!', 'error');
            return;
        }
    
        const startNumber = parseInt(this.instrument.startingInstrumentNumber, 10);
        const endNumber = parseInt(this.instrument.endingInstrumentNumber, 10);
    
        if (isNaN(startNumber) || isNaN(endNumber)) {
            this.showToast('Error', 'Instrument numbers must be numeric.', 'error');
            return;
        }
    
        // Allow a single instrument case: startNumber == endNumber
        if (startNumber > endNumber) {
            this.showToast('Error', 'Starting instrument number cannot be greater than the ending number.', 'error');
            return;
        }

        const range = endNumber - startNumber + 1;
        console.log('OUTPUT : range',range);
        console.log('this.loanTenure : this.loanTenure',this.loanTenure);
        if (range > this.loanTenure) {
            this.showToast('Error', 'Instrument range cannot exceed loan tenure months!', 'error');
            return;
        }
        if(this.createdInstruments.length +range > this.loanTenure){
            this.showToast('Error', 'Instrument record cannot exceed loan tenure months!', 'error');
            return;
        }
        createInstruments({
            loanApplicationId: this.recordId,
            bankDetailId: this.selectedBankDetail.id,
            purpose: this.instrument.purpose,
            startNumber: startNumber,
            endNumber: endNumber,
            customerId: this.selectedApplicantId
        })
        .then(result => {

            if(result == 'Instruments created successfully'){
                this.instrumentCreated = true;
                this.loadCreatedInstruments();
                // Reset form fields
                this.instrument = { purpose: '', startingInstrumentNumber: '', endingInstrumentNumber: '' };
                //this.selectedBankDetail = {};
                //this.selectedApplicantId = '';
                //this.selectedApplicantType = '';
                this.showToast('Success', result, 'success');
            }
            else{
                this.showToast('Error', result, 'error');
            }
        })
        .catch(error => {
            console.error('Error creating instruments: ', JSON.stringify(error));
            this.showToast('Error', error, 'error');
        });
    }
        
    loadCreatedInstruments() {
        console.log('i am inside');
        
        fetchCreatedInstruments({ loanApplicationId: this.recordId })
        .then(result => {
            if(result && result.length>0){
                this.createdInstruments = result.map((row) => {
                    return { 
                        ...row, 
                        isInstrumentAmountThere : !row.instrumentAmount ,
                        instrumentamount: row.instrumentamount ? row.instrumentamount : '-',
                        instrumentdate: row.instrumentdate ? this.formatDateFetch(row.instrumentdate) : '-'
                    };
                });

                this.instrumentCreated = true;
                console.log('this.createdInstruments:: '+JSON.stringify(this.createdInstruments));
            }
        })
        .catch(error => {
            console.error('Error fetching created instruments:', error);
        });
    }

    handleInstrumentDateChange(event) {
        const newValue = event.target.value;
        console.log('new: '+newValue);
    
        this.loadSchedules();
        this.showInstrumentScheduleModal = true;
    }

    loadSchedules() {
        fetchSchedule({ recordId: this.recordId })
        .then(result => {
            this.instrumentSchedule = result.map(item => {
                return {
                    ...item,
                    schDateFormatted: this.formatDate(item.schDate)
                };
            });
        })
        .catch(error => {
            console.error('Error fetching schedules:', error);
        });
    }

    formatDate(dateStr) {
        if(dateStr){
            console.log('dateStr: '+dateStr);
            const dateObj = new Date(dateStr);
            const day = String(dateObj.getDate()).padStart(2, '0');
            const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
            const month = monthNames[dateObj.getMonth()];
            const year = dateObj.getFullYear();
            return `${day}-${month}-${year}`;
        }
        
        return dateStr;
    }

    formatDateFetch(dateStr) {
        if(dateStr){
            console.log('dateStr: '+dateStr);
            var tmpDate = dateStr.split('-');
            const dateObj = new Date(tmpDate[0] +'-'+ tmpDate[1] +'-'+ tmpDate[2]);
            const day = String(dateObj.getDate()).padStart(2, '0');
            const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
            const month = monthNames[dateObj.getMonth()];
            const year = dateObj.getFullYear();
            return `${day}-${month}-${year}`;
        }
        
        return dateStr;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    
    // Handle Delete Instrument
    handleDeleteInstrument(event) {
        const instrumentId = event.target.dataset.id;

        deleteInstrument({ instrumentId : instrumentId, loanId : this.recordId })
            .then(result => {

                if(result.includes('Error deleting instrument: ')){
                   // this.showToast('Error', 'First or Last Instrument in the sequence can be deleted', 'error');
                }
                else{
                    this.showToast('Success', 'Instrument deleted successfully!', 'success');

                    // Remove from UI
                    this.createdInstruments = this.createdInstruments.filter(inst => inst.id !== instrumentId);
                    // Check if there are no mandates left, then hide the table
                    if (this.createdInstruments.length === 0) {
                        this.instrumentCreated = false;
                    }
                }
                
            })
            .catch(error => {
                console.error('Error deleting instrument:', error);
                this.showToast('Error', 'Failed to delete instrument!', 'error');
            });
    }

    // Handle Edit Instrument Click
    handleEditInstrument(event) {
        const instrumentId = event.target.dataset.id;
        var oldInstrumentId = this.editingInstrumentId;

        this.createdInstruments = this.createdInstruments.map(instrument => {
            if(instrument.id === instrumentId) {  
                this.updatedPurpose[instrumentId] = instrument.purpose;

                if(instrument.purpose === 'Security'){
                    return {
                        ...instrument,
                        isEditing: !instrument.isEditing, // Toggle editing mode
                        isDateEditing: false,
                        isPurposeEditing: !instrument.isPurposeEditing
                    };
                }
                else if(instrument.purpose === 'Installment'){
                    return {
                        ...instrument,
                        isEditing: !instrument.isEditing, // Toggle editing mode
                        isDateEditing: true,
                        isPurposeEditing: !instrument.isPurposeEditing
                    };
                }
                else if(instrument.purpose === 'Pre EMI'){
                    return {
                        ...instrument,
                        isEditing: !instrument.isEditing, // Toggle editing mode
                        isDateEditing: true,
                        isPurposeEditing: !instrument.isPurposeEditing
                    };
                }
            }
            else if(instrument.id === oldInstrumentId){  
                return {
                    ...instrument,
                    isEditing: false,
                    isPurposeEditing: false,
                    isDateEditing: false
                };
            }

            return instrument;
        });

        this.editingInstrumentId = instrumentId;
    }

    // Handle Purpose Change
    handlePurposeChange(event) {
        const instrumentId = event.target.dataset.id;
        this.updatedPurpose[instrumentId] = event.target.value;
        //this.handleSaveInstrument(event);
        console.log('purpose new: '+event.target.value);

        this.createdInstruments = this.createdInstruments.map(instrument => {
            if(instrument.id === instrumentId) {  
                if(event.target.value === 'Security'){
                    return {
                        ...instrument,
                        isDateEditing: false,
                        instrumentdate: null,
                        instrumentamount: null
                    };
                }
                else if(event.target.value === 'Installment'){
                    return {
                        ...instrument,
                        isDateEditing: true
                    };
                }
                else if(event.target.value === 'Pre EMI'){
                    return {
                        ...instrument,
                        isDateEditing: true
                    };
                }
            }
            return instrument;
        });
    }

    handleInstrumentNumberChange(event) {
        const instrumentId = event.target.dataset.id;
        const newValue = event.target.value;
    
        this.createdInstruments = this.createdInstruments.map(instrument => {
            if (instrument.id === instrumentId) {
                return { ...instrument, instrumentnumber: newValue };
            }
            return instrument;
        });
    }
    

    // Handle Save Click
    handleSaveInstrument(event) {
        const instrumentId = event.target.dataset.id;
        const newPurpose = this.updatedPurpose[instrumentId];
        const instrument = this.createdInstruments.find(inst => inst.id === instrumentId);
        const newInstrumentNumber = instrument.instrumentnumber;
        const instDate = instrument.instrumentdate;
        console.log('instrument.instrumentamount>>'+instrument.instrumentamount);
        const instAmount = instrument.instrumentamount != '-' ? instrument.instrumentamount : 0;

        if(newPurpose === 'Installment' && !instDate){
            this.showToast('Error', 'Required fields are missing!', 'error');
            return;
        }
        if(newPurpose === 'Pre EMI' && !instDate){
            this.showToast('Error', 'Required fields are missing!', 'error');
            return;
        }
        console.log('instAmount', instAmount, instrument.instrumentamount != '-' ? instrument.instrumentamount : 0);

        updateInstrument({ loanId: this.recordId, instrumentId: instrumentId, newPurpose: newPurpose, newInstrumentNumber: newInstrumentNumber, instrumentDate: instDate, instrumentAmount: instAmount })
        .then(response => {

            if(response === 'Success'){
                this.showToast('Success', 'Instrument updated successfully!', 'success');

                // Update UI
                this.createdInstruments = this.createdInstruments.map(instrument => {
                    if (instrument.id === instrumentId) {
                        return {
                            ...instrument,
                            purpose: newPurpose,
                            nstrumentnumber: newInstrumentNumber,
                            isEditing: false, // Exit edit mode
                            isPurposeEditing: false,
                            isDateEditing: false
                        };
                    }
                    return instrument;
                });
    
                this.editingInstrumentId = null;
            }
            else{
                this.showToast('Error', response, 'error');
            }
        })
        .catch(error => {
            console.error('Error updating instrument:', error);
            this.showToast('Error', 'Failed to update instrument!', 'error');
        });
    }

    selectedInstrumentId;
    openCamera(event){
        if(this.isRetakeCase){
            this.template.querySelector('.hidden-input-all').click();
            this.getUserLocationCordinates();
        }
        else{
            this.selectedInstrumentId = event.target.dataset.id;
            this.template.querySelector('.hidden-input').click();
            this.getUserLocationCordinates();
        }
    }

    getUserLocationCordinates() {
        //get user's geo-cordinates
        if(navigator.geolocation) {
            navigator.geolocation.getCurrentPosition((position) => {
                this.lattitude = position.coords.latitude;;
                this.longitude = position.coords.longitude;
            },
            (e) => {},
            { enableHighAccuracy: true }
            );
        }
    }

    handleUpload(event) {
        this.isLoading = true;
        //console.log('this.selectedInstrumentId: '+this.selectedInstrumentId);

        const file = event.target.files[0];
        var reader = new FileReader();
        reader.onload = () => {

            const uploadParam = {
                'base64': reader.result.split(',')[1],
                'filename': file.name,
                'loanId': this.recordId,
                'latitude': this.lattitude,
                'longitude': this.longitude,
                'selectedInstrumentId': this.selectedInstrumentId
            };
        
            uploadFile({ uploadParam: uploadParam, docDetail: null })
            .then(result => {
                if(result) {
                    console.log('result: '+JSON.stringify(result));
                    this.contentDocId = result[0];
                    this.fileType = result[1];
                    this.docDetailId = result[2];

                    this.viewFile();
                    this.showPreview = true;

                    this.loadCreatedInstruments();
                }
                else {
                    this.showToast('Error', 'Unable to upload file.', 'error');
                }

                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', 'Unable to upload file!!', 'error');

            });
        }

        reader.readAsDataURL(file);

        // Reset the input value
        this.template.querySelector('.hidden-input').value = null;
    }

    reUploadFile(event){
        this.showPreview = false;
        this.isRetakeCase = true;
        this.openCamera(event);
    }

    handleReUpload(event){
        this.isLoading = true;
        //console.log('this.selectedInstrumentId: '+this.selectedInstrumentId);

        const file = event.target.files[0];
        var reader = new FileReader();
        reader.onload = () => {

            const uploadParam = {
                'base64': reader.result.split(',')[1],
                'filename': file.name,
                'loanId': this.recordId,
                'latitude': this.lattitude,
                'longitude': this.longitude,
                'selectedInstrumentId': this.selectedInstrumentId,
                'docDetailId': this.docDetailId,
                'isReUpload': true
            };
        
            reUploadFile({ uploadParam: uploadParam })
            .then(result => {
                if(result) {
                    console.log('result: '+JSON.stringify(result));
                    this.contentDocId = result[0];
                    this.fileType = result[1];
                    this.docDetailId = result[2];

                    this.viewFile();
                    this.showPreview = true;

                    this.loadCreatedInstruments();
                }
                else {
                    this.showToast('Error', 'Unable to upload file.', 'error');
                }

                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', 'Unable to upload file!!', 'error');

            });
        }

        reader.readAsDataURL(file);

        // Reset the input value
        this.template.querySelector('.hidden-input-all').value = null;
    }

    viewInstrument(event) {
        this.selectedInstrumentId = event.target.dataset.id;
        this.fileType = event.target.dataset.filetype;
        this.contentDocId = event.target.dataset.contentdocid;
        this.docDetailId = event.target.dataset.docdetailid;
        this.showPreview = true;
        this.viewFile();
    }
    
    viewFile(event){
        //event.stopPropagation();
        console.log('this.fileType: '+this.fileType);
        //console.log('this.fileUrl: '+this.fileUrl);

        var fileUrl = window.location.origin +'/sfc/servlet.shepherd/document/download/'+ this.contentDocId;
        this.showPdf = false;
        this.pdfUrl = null;
        this.showImage = false;
        this.imageUrl = null;

        switch(this.fileType) {
            case 'PNG':
            case 'JPG':
            case 'JPEG':
            case 'SVG':
            case 'BMP':
            case 'WEBP':
            case 'GIF':
                this.imageUrl = fileUrl;
                this.showImage = true;
                break;
            case 'PDF':
                this.pdfUrl = fileUrl;
                this.showPdf = true;
                break;
        }
    }

    createBankaccnt(){
        this.openBankAccountModal = true;
    }

    closeBankAccount(){
        this.openBankAccountModal = false;
    }

    populateBankDet(event){
        console.log('event.detail in populateBankDet---', event.detail);

        const bankDet = event.detail;
        if(bankDet){
            this.selectedBankDetail.bankName = bankDet.Bank_Master__c ? (bankDet.Bank_Master__r.Bank_Name__c ? bankDet.Bank_Master__r.Bank_Name__c	: '') : '';
            this.selectedBankDetail.branchName = bankDet.Bank_Master__c ? (bankDet.Bank_Master__r.Branch_Name__c ? bankDet.Bank_Master__r.Branch_Name__c	: '') : '';
            this.selectedBankDetail.accountNumber = bankDet.Account_Number__c ? bankDet.Account_Number__c : '';
            this.selectedBankDetail.accountType = bankDet.Account_Type__c ? bankDet.Account_Type__c : '';
            this.selectedBankDetail.branchLocation = '';
            this.selectedBankDetail.ifsc = bankDet.Bank_Master__c ? (bankDet.Bank_Master__r.Name ? bankDet.Bank_Master__r.Name	: '') : '';
            this.selectedBankDetail.micr = bankDet.Bank_Master__c ? (bankDet.Bank_Master__r.MICR__c ? bankDet.Bank_Master__r.MICR__c	: '') : '';
            this.selectedBankDetail.id =  bankDet.Id;
        }
        console.log('selectedBankDetail--- in populateee---', JSON.stringify(this.selectedBankDetail));
        
        
    }

    renderedCallback() {
        const style = document.createElement("style");
        style.innerText = `
        /* Hide border and apply bottom border only */
            .hideInput .slds-input {
                border: none !important; /* Remove all default borders */
                border-bottom: 1px solid black !important; /* Add only bottom border */
                background-color: transparent;
                outline: none;
                box-shadow: none;
                border-radius: 0 !important; /* Remove curved edges */
                padding: 4px; /* Adjust padding if necessary */
            }
            .removeborder .slds-combobox__input {
                border: none !important;  /* Remove border */
                box-shadow: none !important;  /* Remove any shadow */
                background-color: transparent;  /* Ensure no background color */
                 border-bottom: 1px solid black !important; /* Add only bottom border */
                 border-radius: 0 !important; /* Remove curved edges */
                 padding:5px

            }
    `;

        // Append the styles to the .styleContainer
        this.template.querySelector(".styleContainer")?.appendChild(style);
    }

    handleClose(){
        this.showPreview = false;
        this.isLoading = false;
        this.isRetakeCase = false;
        this.selectedInstrumentId = '';
        this.showPdf = false;
        this.pdfUrl = null;
        this.showImage = false;
        this.imageUrl = null;
        this.contentDocId = '';
        this.docDetailId = '';
        this.fileType = '';
    }
}