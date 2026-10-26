import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRepaymentAccountDetails from '@salesforce/apex/CaptureMandateController.getRepaymentAccountDetails';
import upsertMandateRecord from '@salesforce/apex/CaptureMandateController.upsertMandateRecord';
import updateMandateRecord from '@salesforce/apex/CaptureMandateController.updateMandateRecord';
import getExistingMandate from '@salesforce/apex/CaptureMandateController.getExistingMandate';
import getMandateTypeValues from '@salesforce/apex/CaptureMandateController.getMandateTypeValues';
import getMandateModeValues from '@salesforce/apex/CaptureMandateController.getMandateModeValues';
import getPeriodicityValues from '@salesforce/apex/CaptureMandateController.getPeriodicityValues';
import getPennyDropOptions from '@salesforce/apex/CaptureMandateController.getPennyDropOptions';
import getApplicants from '@salesforce/apex/CaptureMandateController.getApplicants';
import getBankDetails from '@salesforce/apex/CaptureMandateController.getBankDetails';
import STAGE_FIELD from "@salesforce/schema/Opportunity.StageName";
import fetchSchedule from "@salesforce/apex/COMM_RepaymentScheduleController.fetchSchedule";
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
import SANCTION_LOAN_AMOUNT_FIELD from "@salesforce/schema/Opportunity.Sanction_Loan_Amount__c";
import FINAL_AMOUNT_FIELD from "@salesforce/schema/Opportunity.Final_Amount__c";
import EMI_AMOUNT_FIELD from "@salesforce/schema/Opportunity.Emi_amount__c";
import EMI_AMOUNT_RPS_FIELD from "@salesforce/schema/Opportunity.EMI_Amount_Repayment_Schedule__c";
import deleteMandateRecord from '@salesforce/apex/CaptureMandateController.deleteMandate';
import getLoanStartDateForLoanApplication from '@salesforce/apex/CaptureMandateController.getLoanStartDateForLoanApplication';
import canUserEditMandate from '@salesforce/apex/CaptureMandateController.canUserEditMandate';
import getCurrentUserRole from '@salesforce/apex/Hl_CovenantsDetailFormController.getCurrentUserRole';
import updateBankDetailRecord from '@salesforce/apex/CaptureMandateController.updateBankDetailRecord';
import {getRecord} from "lightning/uiRecordApi";
import canUserEditRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.canUserEditRecord';
import USERID_FIELD from "@salesforce/user/Id";
import getOpportunityTeamMembers from '@salesforce/apex/AHL_LoanDetailsController.getOpportunityTeamMembers';
import getBranchNameForBank from '@salesforce/apex/CaptureMandateController.getBranchNameForBank';//sanwar
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails'
import reHitEnach from '@salesforce/apex/InstrumentMandateHandler.reHitEnach';

export default class CaptureMandateComponent extends LightningElement {
    @api recordId; // Loan Application ID
    @track repaymentAccounts = [];
    @track selectedBankDetail = {}; // Holds auto-populated bank details
    @track mandate = { mandateType: '', mandatemode:'', maxLimit: '', startDate: '', endDate: '', periodicity: '', status: '', pennyDrop: '' };
    @track mandateId = null; // Store Mandate ID for updates
    @track createdMandate = []; // Stores the created mandate details
    @track mandateCreated = false; // Flag to show mandate table after creation
    @track isEditing = false; // Flag for inline editing mode
    @track mandateTypeOptions = [];
    @track mandateModeOptions = [];
    @track periodicityOptions = [];
    @track branchOptions = []; //sanwar
    @track pennyDropOptions = [];
    @track isSaving = false;
    @track isVisible = true;
    @track error;
    @track isDisable = true;
    @track applicants = []; // List of applicants for dropdown
    @track selectedApplicantId = ''; // Selected applicant ID
    @track selectedApplicantType = ''; // Auto-populated Customer Type
    @track bankDetails = []; // Bank details of the selected applicant
    @track showBankModal = false; // Modal visibility control
    @track loanStartDate;
    @track selectedBranch;//sanwar
    @track selectedIfsc;//sanwar
    @track selectedIfscLabel;
    @track needToRehitEnach = false;
    branchRecordsData;//sanwar
    cleanedBankName = '';//sanwar
    cssContainer = 'slds-modal__container width-60';
    selectedApplicant;
    @track editingRowId = null; 
    @track showBankCreationButton = false;
    @track isEditableUser = true;
        oppSubStage = '';
    oppStage = '';
    currentUserOppRole = [];
    disableDocField= false;//Sanwar
    minMandateStartDate;
    loanTenor = 0;
    minEndDate;
    isHLUser = false;
    oppFinalAmount = '';
    oppSanctionedAmount = '';

    @track openModal = false;
    @track mandateToDeleteId ='';
    filteredIfscList=[];
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
    //Ishi-Mandate
    mandateStatusOption = [
        { label: 'Pending', value: 'Pending' },
        { label: 'Success', value: 'Success' },
        {label: 'Failed', value: 'Failed'}
    ];
    //Ishi-Mandate

    getProductDetails(){
         var inputMapParam = {
            'oppId': this.recordId
        };
        getProductDetails({inputMap : inputMapParam})
        .then(result => {
            this.isHLUser = result.isHLRelated;
            console.log('isHLUser-->',this.isHLUser);
        })
        .catch(error => {
            console.log('error-->',error);
        })
    }

    connectedCallback() {
        //Sanwar - Start
        getCurrentUserRole({recordId : this.recordId}).then(data => {
            this.disableDocField = data;
        });
        //Sanwar - End
        canUserEditMandate({ opportunityId: this.recordId })
        .then(result => {
            this.isEditableUser = true;
            console.log('Is editable user:', this.isEditableUser);
        })
        .catch(error => {
            console.error('Error checking user access for VAS:', error);
            this.isEditableUser = false; // Default to read-only if error
        });

        this.mandate.mandateType = 'Repayment Mandate';
        this.isSecurityMandate = false;
        this.getProductDetails();
        this.fetchRepaymentAccounts();
        this.fetchMandateTypeOptions();
        this.fetchMandateModeOptions();
        this.fetchPeriodicityOptions();
        this.fetchPennyDropOptions();
        this.fetchExistingMandate();
        this.fetchLoanStartDate();
        this.loadSchedules();
        const simulatedEvent = {
            target: {
                value: 'Repayment Mandate'
            }
        };
        this.handleMandateTypeChange(simulatedEvent);

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
                this.handleError(error, 'gotLoanFields');
                this.showToast(this.toastTitle.ERROR, this.toastMessages.SOMETHING_WENT_WRONG, this.toastVariant.ERROR);
            }
        }

    @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD, SUBSTAGE_FIELD, SANCTION_LOAN_AMOUNT_FIELD,FINAL_AMOUNT_FIELD,EMI_AMOUNT_FIELD, EMI_AMOUNT_RPS_FIELD] })
    opportunity({ error, data }) {
        if(data) {
            this.oppStage = data.fields.StageName.value;
            this.oppSubStage = data.fields.Sub_stage__c.value;
            this.oppFinalAmount = data.fields.Final_Amount__c.value;
            this.oppSanctionedAmount = data.fields.Sanction_Loan_Amount__c.value;
            //this.mandate.maxLimit = this.oppFinalAmount ? this.oppFinalAmount : this.oppSanctionedAmount;
            //this.mandate.maxLimit = data.fields.Emi_amount__c.value ? data.fields.Emi_amount__c.value * 2 : 0;
            this.mandate.maxLimit = data.fields.EMI_Amount_Repayment_Schedule__c.value ? data.fields.EMI_Amount_Repayment_Schedule__c.value * 2 : 0; //Arman did this. On 5th Dec
            console.log('Opp sub stage' , this.oppSubStage);
            console.log('this.oppFinalAmount:',this.oppFinalAmount);
            console.log('this.oppSanctionedAmount:',this.oppSanctionedAmount);
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
            console.log('at 149');
        }
        if(this.oppSubStage == 'PSV Sales'){
            console.log('at 159');
            this.isSecurityMandate=false;
            this.showBankCreationButton=false;
            this.isDisable=true;
        }
    }//Sanwar End

    loadSchedules() {
        console.log('RPS last date>');
        fetchSchedule({ recordId: this.recordId })
        .then(result => {
            if(result && this.isHLUser){
                const schedules = result.filter(item => !!item.schDate).map(item => ({
                ...item, schDateObj: new Date(item.schDate)})).sort((a, b) => a.schDateObj - b.schDateObj); //Armann

                /*this.instrumentSchedule = schedules.map(item => ({
                    ...item, schDateFormatted: this.formatDate(item.schDate)
                }));
                I took this from capture insteuments but it is not needed hereee*/

                const lastItem = schedules[schedules.length - 1];
                const lastSchDate = lastItem.schDate;
                //this.lastSchDateFormatted = this.formatDate(lastSchDate); //it is now not being used -- >>Arman
                console.log('RPS last date>',lastSchDate);
                let d = new Date(lastSchDate);
                d.setFullYear(d.getFullYear() + 1);
                this.mandate.endDate = this.getFormattedDate(d);
                console.log(' this.mandate.endDate RPS>', this.mandate.endDate);
            }
            else{
                if(this.mandate.startDate){
                    var date = new Date(this.mandate.startDate);
                    date.setMonth(date.getMonth() + 360);
                    this.mandate.endDate = this.getFormattedDate(date);
                    console.log(' this.mandate.endDate NONRPS>', this.mandate.endDate);
                }
            }
        })
        .catch(error => {
            console.error('Error fetching schedules:', error);
        });
    }

    fetchLoanAmount() {
        getLoanAmount({ loanApplicationId: this.recordId })
            .then(result => {
                this.loanAmount = result.loanAmount;
                this.emiAmount = result.emiAmount;  // Store EMI Amount for Validation
                console.log('Loan Amount Fetched:', this.loanAmount + this.emiAmount);
            })
            .catch(error => {
                console.error('Error fetching loan amount:', error);
            });
    }

    fetchLoanStartDate() {
        getLoanStartDateForLoanApplication({ loanAppId: this.recordId })
            .then(result => {
                this.mandate.startDate = result.Loan_Start_Date__c;
                this.minMandateStartDate = result.Loan_Start_Date__c;
                console.log('Loan Start Date:', result.Loan_Start_Date__c);

                // if(result.Loan_Start_Date__c){
                //     this.loanTenor = result.Loan_Application__r.Tenor_Months__c;
                //     var date = new Date(result.Loan_Start_Date__c);
                //     date.setMonth(date.getMonth() + (this.loanTenor + 3));
                //     console.log('date1: '+date);
    
                //     this.mandate.endDate = this.getFormattedDate(date);
                // }

                
                if(result.Loan_Start_Date__c){
                    if(result.Loan_Application__r && result.Loan_Application__r.Sanction_Tenure__c){
                        this.loanTenor = result.Loan_Application__r.Sanction_Tenure__c;
                    }else{
                        this.loanTenor = 0;
                    }
                    // this.loanTenor = result.Loan_Application__r.Sanction_Tenure__c;
                    if(!this.isHLUser){
                        var date = new Date(result.Loan_Start_Date__c);
                        //date.setMonth(date.getMonth() + (this.loanTenor + 3));Arman : 25-11 commenting this since as per new logic>> Mandate end date is 30 years > start date
                        date.setMonth(date.getMonth() + 360);
                        console.log('date1: '+date);
        
                        this.mandate.endDate = this.getFormattedDate(date);

                        var minDate = new Date(result.Loan_Start_Date__c);
                        minDate.setMonth(minDate.getMonth() + Math.round(this.loanTenor * 1.5));
                        this.minEndDate = this.getFormattedDate(minDate);
                        console.log('this.minEndDate 220: '+this.minEndDate);
                    }
                }
            })
            .catch(error => {
                this.error = error;
                console.error('Error fetching Loan Start Date:', error);
            });
    }

    getFormattedDate(date){
        var yyyy = date.getFullYear().toString();
        var mm = date.getMonth()+1;
        mm = mm < 10 ? '0'+ mm.toString() : mm.toString();
        var dd = date.getDate().toString();
        return yyyy +'-'+ mm +'-'+ dd;
    }


    // Fetch repayment account details and auto-populate first record
    fetchRepaymentAccounts() {
        if (!this.recordId) {
            console.error('Loan Application ID is required.');
            return;
        }

        getRepaymentAccountDetails({ loanApplicationId: this.recordId })
            .then(result => {
                console.log('Result tt',result);
                if(result.length != 0){
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
                    branchName: row.Bank_Master__r ? row.Bank_Master__r.Branch_Name__c : '',
                    umrn:'',
                    txnDet:''
                }));
                    if (this.repaymentAccounts.length > 0) {
                        this.selectedBankDetail = this.repaymentAccounts[0]; // Auto-select first record
                        console.log('selectedBankDetail'+JSON.stringify(this.repaymentAccounts[0]));
                        //Sanwar
                        if (this.selectedBankDetail && this.selectedBankDetail.bankName){
                            const name = this.selectedBankDetail?.bankName ?? '';
                            this.cleanedBankName = name.includes(',')
                                ? name.trim()
                                : name.trim();
                
                            console.log('Cleaned Name:', this.cleanedBankName);
                            console.log('this.selectedBankDetail----', JSON.stringify(this.selectedBankDetail));
                            
                            getBranchNameForBank({bankName : this.cleanedBankName})
                            .then(result => {
                                this.branchRecordsData = result;
                                this.branchOptions = result?.map(value => ({ label: `${value.IFSC__c}`, value: value.Id }));//Sanwar (27/11/2025)
                                
                                const matchedOption = this.branchOptions.find( //done by Arman to prepopulate IFSC.. if I was selectingthis.branchRecordsData[0].Id; any random master was getting picked
                                    opt => opt.label === this.selectedBankDetail.ifsc
                                );
                                if (matchedOption) {
                                    this.selectedIfsc = matchedOption.value; // Id
                                    this.selectedIfscLabel=matchedOption.label;
                                    this.selectedBranch = this.branchRecordsData.find(
                                        rec => rec.Id === this.selectedIfsc
                                    ) || null;
                                } else {
                                    this.selectedIfsc = null;
                                    this.selectedBranch = null;
                                }
                                console.log('this.selectedIfscLabel>>>',this.selectedIfscLabel);
                                //this.selectedBranch = this.branchRecordsData[0];//sanwar (27/11/2025)
                                //this.selectedIfsc = this.branchRecordsData[0].Id;
                            })
                        }
                        this.fetchExistingMandate();
                    }
                    else{
                        console.log('Is Disable ',this.isDisable);
                        this.isDisable = false;
                    }
                    console.log('Auto-populated bank details:', JSON.stringify(this.selectedBankDetail));
                    this.error = undefined;
                }  
                //start
                else{        
                    this.isDisable = false;
                }
                //end
                
            })
            .catch(error => {
                this.error = error;
                this.repaymentAccounts = [];
                console.error('Error fetching repayment account details:', error);
            });
    }

    // Fetch Mandate Type options for dropdown
    fetchMandateTypeOptions() {
        getMandateTypeValues()
            .then(result => {
                this.mandateTypeOptions = result.map(value => ({ label: value, value: value }));
            })
            .catch(error => {
                console.error('Error fetching Mandate Type values:', error);
            });
    }

    // Fetch Mandate Type options for dropdown
    fetchMandateModeOptions() {
        getMandateModeValues()
            .then(result => {
                this.mandateModeOptions = result.map(value => ({ label: value, value: value }));
            })
            .catch(error => {
                console.error('Error fetching Mandate Mode values:', error);
            });
    }

    // Fetch Periodicity options for dropdown
    fetchPeriodicityOptions() {
        getPeriodicityValues()
            .then(result => {
                this.periodicityOptions = result?.map(value => ({ label: value, value: value }));
            })
            .catch(error => {
                console.error('Error fetching Periodicity values:', error);
            });
    }

    fetchPennyDropOptions(){
        getPennyDropOptions()
        .then(result => {
            this.pennyDropOptions = result?.map(value => ({ label: value, value: value }));
        })
        .catch(error => {
            console.error('Error fetching PennyDrop values:', error);
        });
    }

    @track isSecurityMandate = false;
   // Fetch applicants when the Mandate Type is changed
    handleMandateTypeChange(event) {
        //this.mandate.mandateType = event.target.value;
        this.mandate.mandateType = event?.target?.value || 'Repayment Mandate';
        if (this.mandate.mandateType === 'Security Mandate') {
            this.showBankCreationButton = true;
            this.isSecurityMandate = true;
            this.mandate.customerName = '';
            this.selectedApplicantId = '';
            this.selectedApplicantType = '';
            this.mandate.customerType = '';
            this.mandate.mandateMode = '';
            this.mandate.maxLimit = '';
            this.selectedBankDetail = {
                accountHolderName: '',
                accountHolderId:'',
                bankName: '',
                branchName: '',
                accountNumber: '',
                accountType: '',
                branchLocation: '',
                ifsc: '',
                micr: ''
            };
            this.mandate.startDate = '';
            this.mandate.endDate = '';
            this.mandate.periodicity = '';
            this.mandate.pennyDrop = '';
            this.mandate.status = '';
            this.minEndDate;
            this.fetchApplicants();
        }else if(this.mandate.mandateType === 'Repayment Mandate'){
            this.showBankCreationButton = true;
            this.isSecurityMandate = false;
            this.fetchRepaymentAccounts();
            this.mandate.mandateMode = '';
            this.selectedApplicantId = '';
            this.selectedApplicantType = '';
            this.mandate.customerType = '';
            this.mandate.startDate = '';
            this.mandate.endDate = '';
            this.mandate.periodicity = '';
            this.mandate.pennyDrop = '';
            this.mandate.status = '';
            this.mandate.maxLimit = '';
            this.selectedBankDetail = {
                accountHolderName: '',
                accountHolderId:'',
                bankName: '',
                branchName: '',
                accountNumber: '',
                accountType: '',
                branchLocation: '',
                ifsc: '',
                micr: ''
            };
            this.minEndDate;
            this.fetchApplicants();
            
        }

        this.fetchLoanStartDate();
    }

    // Fetch Applicants for Dropdown
    fetchApplicants() {
        getApplicants({ loanApplicationId: this.recordId })
            .then(result => {
                console.log('Applicant ',result);
                this.applicants = result.map(applicant => ({
                    label: applicant.Name,
                    value: applicant.Id,
                    customerType: applicant.Applicant_Type__c
                }));

                console.log('Show Applicant ',this.applicant);
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
                        branchName:  bank.Bank_Master__r?.Branch_Name__c || '',  // Extracting Branch Name
                        branchLocation: bank.Bank_Master__r?.Branch_Location__c || '',  // Extracting Branch Location,
                        ifsc: bank.Bank_Master__r?.IFSC__c || '',
                        isRepayment: bank.Is_Repayment_Account__c || '',
                        accountNumber: bank.Account_Number__c || '',
                        micr: bank.Bank_Master__r?.MICR__c || '',
                        accountType: bank.Account_Type__c || '',
                        applicanttype : bank.Application_Applicant__r?.Applicant_Type__c || ''
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
        this.selectedBankDetail = this.bankDetails.find(bank => String(bank.id) === String(selectedBankId));
        
        console.log('Selected Bank:', JSON.stringify(this.selectedBankDetail));
        console.log('Selected Bank Id ', this.selectedBankDetail.id);
        //this.selectedIfsc = null;//sanwar(27/11/2025)
        
        this.showBankModal = false; // Close the modal after selection
        //Sanwar
        console.log('At 463>>>',this.selectedBankDetail);
        if (this.selectedBankDetail && this.selectedBankDetail.bankName){
            const name = this.selectedBankDetail?.bankName ?? '';
            this.cleanedBankName = name.includes(',')
                ? name.trim()
                : name.trim();

            console.log('Cleaned Name:', this.cleanedBankName);
            getBranchNameForBank({bankName : this.cleanedBankName})
            .then(result => {
                this.branchRecordsData = result;
                console.log('At 465', result);
                this.branchOptions = result?.map(value => ({ label: `${value.IFSC__c}`, value: value.Id }));//Sanwar(27/11/2025)
                console.log('this.branchOptions: '+JSON.stringify(this.branchOptions));
                const matchedOption = this.branchOptions.find(
                    option => option.label === this.selectedBankDetail.ifsc
                );
                console.log('matchedOption: '+matchedOption);
                if (matchedOption) {
                    this.selectedIfsc = matchedOption.value; 
                    this.selectedIfscLabel=matchedOption.label; 
                    console.log('At 502', this.selectedIfsc);
                }
                this.selectedBranch = this.branchRecordsData.find(
                    rec => rec.Id === this.selectedIfsc
                );//sanwar (27/11/2025)
                console.log('At 467', this.branchOptions);
                
            })
        }
    }

    // Close Modal
    closeBankModal() {
        this.showBankModal = false;
    }
    
    get toggleIcon() {
        return this.isEditing ? 'utility:save' : 'utility:edit';
    }
                    
    
            
    fetchExistingMandate() {
        console.log('this.selectedBankDetail.id:: ' + this.selectedBankDetail.id);
    
        if (!this.recordId && !this.selectedBankDetail.id) {
            return;
        }
    
        getExistingMandate({ loanApplicationId: this.recordId, bankDetailId: this.selectedBankDetail.id })
            .then(result => {
                console.log('Fetched Mandates:==>', JSON.parse(JSON.stringify(result)));
    
                if (result && result.length > 0) {
                    let showRehit = false;
                    // Store multiple mandates instead of one
                    this.createdMandate = result.map(mandate => {
                        const status = mandate.ENACH_Status__c;
                        if (status && !['Success', 'Pending','Initiated'].includes(status)) {
                            showRehit = true;
                        }
                        return {
                                id: mandate.Id,
                                mandateType: mandate.Mandate_Type__c,
                                mandateMode: mandate.Mandate_Mode__c,
                                maxLimit: mandate.Max_Limit__c,
                                startDate: mandate.Start_Date__c ? new Date(mandate.Start_Date__c).toISOString().split('T')[0] : null,
                                endDate: mandate.End_Date__c ? new Date(mandate.End_Date__c).toISOString().split('T')[0] : null,
                                periodicity: mandate.Periodicity__c,
                                pennyDrop: mandate.Penny_Drop_Result__c,
                                status: mandate.ENACH_Status__c,
                                bankAccountNumber:mandate.Bank_Details__r?.Account_Number__c,
                                bankName:mandate.Bank_Details__r?.Bank_Master__r?.Bank_Name__c,
                                isEditing: false,
                                iconName: 'utility:edit',
                                showRehit: status && !['Success','Pending', 'Initiated'].includes(status)
                            };
                        });

                    this.needToRehitEnach = showRehit;
                    console.log('this.createdMandates:: ' + JSON.stringify(this.createdMandate));
                    this.mandateCreated = true; // Show the table with mandates
                    console.log('Mandate ', this.mandateCreated);
                    console.log('date 1',this.mandate.startDate);
                } else {
                    this.createdMandate = []; // No mandates found, ensure empty array
                    this.mandateCreated = false; // Hide the table if no mandates
                    this.needToRehitEnach = false;
                    console.log('mandate value ', this.mandateCreated);
                }
            })
            .catch(error => {
                console.error('Error fetching existing mandates:', error);
            });
    }

    
    handleRehitEnach(event) {
        console.log('event',event);
        const mandateId = event.currentTarget.dataset.id;
        if (!mandateId) {
            this.showToast('Error', 'Mandate Id missing', 'error');
            return;
        }
        this.isSaving = true;

        reHitEnach({ mandateId: mandateId })
            .then(result => {
                this.showToast('Success', 'Re-hit e-NACH triggered successfully!', 'success');
                // ✅ Refresh mandates
                this.fetchExistingMandate();
            })
            .catch(error => {
                console.error('Error re-hitting ENACH:', error);
                this.showToast('Error', error.body?.message || 'Re-hit failed', 'error');
            })
            .finally(() => {
                this.isSaving = false;
            });
    }    

    // Handle Input Changes
    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value; 
        console.log('Select Date ',value);

        if(field === 'startDate'){
            if(this.minMandateStartDate && this.minMandateStartDate > value){
                this.mandate[field] = this.minMandateStartDate;
                event.target.value = this.minMandateStartDate;
                this.showToast('Error', 'Start Date should not be before '+ this.minMandateStartDate +'!', 'error');
                return;
            }
            
            if(value){
                if(!this.isHLUser){
                    var date = new Date(value);
                    //date.setMonth(date.getMonth() + (this.loanTenor + 3)); commenting this as per new logic end date > start date +30 years
                    date.setMonth(date.getMonth() + 360);
                    console.log('date1: '+date);
                    this.mandate.endDate = this.getFormattedDate(date);
                }
            

                var minDate = new Date(value);
                minDate.setMonth(minDate.getMonth() + Math.round(this.loanTenor * 1.5));
                this.minEndDate = this.getFormattedDate(minDate);
                console.log('this.minEndDate 220: '+this.minEndDate);
            }
        }
            //sanwar(27/11/2025)
        if(field === 'ifscCode'){
            // this.selectedBranch = this.branchRecordsData.find(branch => branch.Id === value);

            // if (this.selectedBranch) {
            //     this.selectedBankDetail.branchName = this.selectedBranch.Branch_Name__c;//Sanwar(27/11/2025)
            //     this.selectedBankDetail.micr = this.selectedBranch.MICR__c;
            //     this.selectedBankDetail.branchLocation = this.selectedBranch.Branch_Location__c;
            //     this.selectedBankDetail.ifsc = this.selectedBranch.IFSC__c;//Sanwar(27/11/2025)
            // }
            // IFSC SEARCH LOGIC
    // Filter list dynamically while typing
            if (value) {
                console.log('this. this.branchRecordsData 220: ', this.branchRecordsData);
               this.filteredIfscList = this.branchRecordsData
                            .filter(branch =>
                            branch.IFSC__c.toLowerCase().includes(value.toLowerCase()) ||
                            branch.Branch_Name__c.toLowerCase().includes(value.toLowerCase())
                            )
                            .map(branch => {
                            return {
                            Id: branch.Id,
                            label: branch.IFSC__c + ' - ' + branch.Branch_Name__c,
                            value: branch.IFSC__c
                            };
                        });

                     console.log('this.filteredIfscList ', this.filteredIfscList);
                } else {
                this.filteredIfscList = [];
                this.selectedBankDetail = {
                    branchName: '',
                    micr: '',
                    branchLocation: '',
                    ifsc: ''
                };
                }

                this.mandate[field] = value;

                
                return; // stop further execution
        }
        
        this.mandate[field] = value;


        // Ensure Max Limit is Positive
        /*if (field === 'maxLimit' && (parseFloat(value) <= 0 || isNaN(value))) {
            this.showToast('Error', 'Max Limit must be a positive number!', 'error');
            return;
        }*/
        if (field === 'maxLimit') {
            if (parseFloat(value) <= 0 || isNaN(value)) {
                this.showToast('Error', 'Max Limit must be a positive number!', 'error');
                return;
            }
            if (value.includes('.') || value % 1 !== 0) {
                this.showToast('Error', 'Decimal values are not allowed for Max Limit!', 'error');
                return;
            }
        }

        console.log('this.mandate >> '+JSON.stringify(this.mandate));

    }
    
    handleIfscSelect(event) {
    const selectedId = event.currentTarget.dataset.id;
    console.log('this.branchRecordsData ',this.branchRecordsData);
    this.selectedBranch = this.branchRecordsData.find(
        branch => branch.Id === selectedId
    );
    console.log('selectedId ',selectedId);
    console.log('selectedBranch ',this.selectedBranch);
    if (this.selectedBranch) {
        this.selectedIfscLabel= this.selectedBranch.IFSC__c;
        this.selectedIfsc = this.selectedBranch.IFSC__c; // show in input
        this.mandate.ifscCode = this.selectedBranch.IFSC__c;
        this.selectedBankDetail.branchName = this.selectedBranch.Branch_Name__c;
        this.selectedBankDetail.micr = this.selectedBranch.MICR__c;
        this.selectedBankDetail.branchLocation = this.selectedBranch.Branch_Location__c;
        this.selectedBankDetail.ifsc = this.selectedBranch.IFSC__c;
        this.filteredIfscList = [];
    }
    }


//Sanwar - Start
    handleEditMandate(event){
        const mandateId = event.target.dataset.id;
        var oldMandateId = this.editingMandateId;

        this.createdMandate = this.createdMandate.map(mandate => {
            if(mandate.id === mandateId) {  
                return {
                            ...mandate,
                            isEditing: !mandate.isEditing,
                            _originalData: { ...mandate }  //Sanwar
                        };
            }
            else if(mandate.id === oldMandateId){  
                return {
                    ...mandate,
                    isEditing: false
                };
            }
            return mandate;
        });
        this.editingMandateId = mandateId;
    }
    //Sanwar - End

    // Create Mandate on Button Click
    async createMandate() {
        try {
            
        
        if (!this.recordId) {
            console.error('Missing Loan Application or Bank Details');
            return;
        }
        // VALIDATION — Account Number: no special chars + no X masked values
        const accountNumber = this.selectedBankDetail.accountNumber || '';
        const invalidAccountRegex = /[^0-9]|x/i;
        if (invalidAccountRegex.test(accountNumber)) {
            this.showToast(
                'Error',
                'The account number field contains specials characters. Kindly contact the Credit manager to update the account number. You do not have to send back this loan application to perform this action.',
                'error'
            );
            return;
        }

        console.log('this.selectedApplicantId:: '+this.selectedApplicantId +'this.applicants.value:: '+this.applicants.value+' accountHolderId:: '+this.selectedBankDetail.accountHolderId);

        console.log('this.selectedBankDetail:: '+JSON.stringify(this.selectedBankDetail));
        //console.log('At 743',this.selectedBranch, 'AND ID',this.selectedBranch.Id);

        // **Ensure Bank Detail ID is selected**
        if (!this.selectedBankDetail || !this.selectedBankDetail.id) {
            this.showToast('Error', 'Kindly select Bank Account Details for the applicant to create mandate!', 'error');
            return; 
        }

        // Validation for Empty Fields
        if (!this.mandate.mandateType || !this.mandate.mandateMode || !this.mandate.maxLimit || 
            !this.mandate.startDate || !this.mandate.endDate || !this.mandate.periodicity ) {
            this.showToast('Error', 'Kindly fill all required fields to create mandate !', 'error');
            return;
        }

        // Validation: Start Date Should Be Before End Date
        if (!this.isHLUser && new Date(this.mandate.startDate) > new Date(this.mandate.endDate)) {
            this.showToast('Error', 'Start Date cannot be later than End Date!', 'error');
            return;
        }

        // Validation: Max Limit Should be Greater than 0
        if (parseFloat(this.mandate.maxLimit) <= 0) {
            this.showToast('Error', 'Max Limit must be greater than zero!', 'error');
            return;
        }

        // **Validation: Max Limit cannot be greater than Loan Amount**
        if (parseFloat(this.mandate.maxLimit) > parseFloat(this.loanAmount)) {
            this.showToast('Error', 'Max Limit cannot be greater than the Loan Amount!', 'error');
            return;
        }
        if (this.mandate.maxLimit.toString().includes('.') || this.mandate.maxLimit % 1 !== 0) {
            console.log('inside (this.mandate.maxLimit'+this.mandate.maxLimit);
            this.showToast('Error', 'Decimal values are not allowed for Max Limit!', 'error');
            return;
        }
        if (new Date(this.minEndDate) > new Date(this.mandate.endDate)) {
            this.showToast('Error', 'End date can not be less then '+ this.minEndDate, 'error');
            return;
        }

        // Determine the correct customerId
        let customerId = this.selectedBankDetail.accountHolderId 
        ? this.selectedBankDetail.accountHolderId 
        : this.selectedApplicantId;

        if (!customerId) { // If still null or undefined, show an error
            this.showToast('Error', 'No valid Applicant ID found!', 'error');
            return;
        }
        // await updateBankDetailRecord({recordId : this.selectedBankDetail.id, bankMasterId:this.selectedBranch.Id, MandateType : this.mandate.mandateType, loanId: this.recordId})
        // .then(result => {
        //     console.log('Result '+result);
        //     if(result == 'Success'){
        //         this.selectedBankDetail.isRepayment = true;
        //         console.log('Selected Bank:', JSON.stringify(this.selectedBankDetail));                
        //     }
        // });

        console.log('Mandate Start date ',this.mandate.startDate);
        await upsertMandateRecord({
            loanApplicationId: this.recordId,
            bankDetailId: this.selectedBankDetail.id,
            mandateType: this.mandate.mandateType,
            mandateMode: this.mandate.mandateMode,
            maxLimit: parseFloat(this.mandate.maxLimit),
            startDate: this.mandate.startDate,
            endDate: this.mandate.endDate,
            periodicity: this.mandate.periodicity,
            pennyDrop: this.mandate.pennyDrop,
            customerId: customerId
        })
        .then(result => {
            console.log('Test for new record====>',JSON.parse(JSON.stringify(result)));
            let returnData = JSON.parse(JSON.stringify(result));
            // Create a new mandate object
            const newMandate = {
                id: returnData.Id, // The newly created mandate ID
                mandateType: this.mandate.mandateType,
                mandateMode: this.mandate.mandateMode,
                maxLimit: this.mandate.maxLimit,
                startDate: this.mandate.startDate,
                endDate: this.mandate.endDate,
                periodicity: this.mandate.periodicity,
                pennyDrop: this.mandate.pennyDrop,
                status: returnData.ENACH_Status__c,
                bankAccountNumber: returnData.Bank_Details__r?.Account_Number__c || '',
                bankName: returnData.Bank_Details__r?.Bank_Master__r?.Bank_Name__c || ''
            };
            // Add the new mandate to the list
            this.createdMandate = [...this.createdMandate, newMandate];
            console.log('Test for Test=====>',this.createdMandate);
            //Sanwar - Start
            // updateBankDetailRecord({recordId : this.selectedBankDetail.id, bankMasterId:this.selectedBranch.Id, MandateType : this.mandate.mandateType, loanId: this.recordId})
            // .then(result => {
            //     console.log('Result '+result);
            //     if(result == 'Success'){
            //         this.selectedBankDetail.isRepayment = true;
            //         console.log('Selected Bank:', JSON.stringify(this.selectedBankDetail));
            //         this.fetchRepaymentAccounts();
            //     }
            // })
            //Sanwar - End
            this.mandateCreated = true;
            this.resetForm();
            this.showToast('Success', 'Mandate Created Successfully!', 'success');
        })
        .catch(error => {
            console.error('Error upserting mandate:', error);
            let errorMessage = 'Mandate Creation Failed!';
            
            if (error.body && error.body.message.includes('A repayment mandate already exists')) {
                errorMessage = 'A repayment mandate already exists for this loan application.';
            }
            //added by kalpesh
             if (error.body && error.body.message.includes('A security mandate already exists')) {
                errorMessage = 'A security mandate already exists for this loan application.';
            }
            if (error.body && error.body.message.includes('Mandate Max Limit amount')) {
                errorMessage = 'Mandate Max Limit amount cannot be lower than 2X of EMI amount!';
            }
            if (error.body && error.body.message.includes('Mandate Max Limit cannot be lower than Loan Amount')) {
                errorMessage = 'Mandate Max Limit cannot be lower than Loan Amount!';
            }
            if (error.body && error.body.message.includes('Mandate Max Limit cannot be lower than ₹1 Cr for loans above ₹1 Cr')) {
                errorMessage = 'Mandate Max Limit cannot be lower than ₹1 Cr for loans above ₹1 Cr!';
            }
            this.showToast('Error', errorMessage, 'error');
            return;
        });
        }
        catch (error) {
                console.error('Error upserting mandate:', error);
                this.showToast('Error', 'Mandate Creation Failed!', 'error');
                return;
        }
    }
    
    // Toggle Inline Edit Mode
    toggleEdit(event) {
        console.log('i am inside');
        const rowId = event.target.dataset.id;
        console.log('i am inside' +rowId);
        this.createdMandate = this.createdMandate.map(mandate => {
            if (mandate.id === rowId) {
                return {
                    ...mandate,
                    isEditing: !mandate.isEditing,
                    iconName: mandate.isEditing ? 'utility:edit' : 'utility:save' // Toggle icon
                };
            }
            return { ...mandate, isEditing: false, iconName: 'utility:edit' }; // Reset other rows
        });
        console.log('i am inside' +JSON.stringify(this.createdMandate));
    }
    
    

    // Handle Inline Edit Changes
    handleEditChange(event) {
        const rowId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;
        console.log('rowId:: ' + rowId);
        console.log('field:: ' + field);
        console.log('value:: ' + value);
        console.log('this.createdMandate:', JSON.stringify(this.createdMandate));
    
        // Clone createdMandate to ensure reactivity
        let updatedMandateList = [...this.createdMandate];
    
        let mandateToUpdate = updatedMandateList.find(mandate => mandate.id === rowId);
        if (!mandateToUpdate) return;
    
        // Validations
        /*if (field === 'maxLimit') {
            if (parseFloat(value) <= 0 || isNaN(value)) {
                this.showToast('Error', 'Max Limit must be a positive number!', 'error');
                return; // **Prevent the update**
            }
        }*/
        if (field === 'maxLimit') {
            if (parseFloat(value) <= 0 || isNaN(value)) {
                this.showToast('Error', 'Max Limit must be a positive number!', 'error');
                return;
            }
            if (value.includes('.') || value % 1 !== 0) {
                this.showToast('Error', 'Decimal values are not allowed for Max Limit!', 'error');
                return;
            }
        }
            
    
        // If validation passes, update the value
        mandateToUpdate[field] = value;
    
        // Ensure reactivity
        this.createdMandate = updatedMandateList;
        console.log('this.createdMandate:920', JSON.stringify(this.createdMandate));
    }
    

    // Save Updated Mandate from Inline Edit
    saveUpdatedMandate(event) {
            const rowId = event.target.dataset.id;
            console.log('rowId:: ' + rowId);
            console.log('this.createdMandate:', JSON.stringify(this.createdMandate));
        
            let mandateToUpdate = this.createdMandate.find(mandate => mandate.id === rowId);
            if (!mandateToUpdate) {
                this.showToast('Error', 'Mandate not found!', 'error');
                return;
            }
        
            console.log('mandateToUpdate:: ' + JSON.stringify(mandateToUpdate));
        
            // **Fetch latest values from the input fields**
            const startDateInput = this.template.querySelector(`[data-id="${rowId}"][data-field="startDate"]`);
            const endDateInput = this.template.querySelector(`[data-id="${rowId}"][data-field="endDate"]`);
            
            // **Ensure inputs exist before updating**
            if (startDateInput) {
                mandateToUpdate.startDate = startDateInput.value;
            }
            if (endDateInput) {
                mandateToUpdate.endDate = endDateInput.value;
            }
        
            console.log('Updated Start Date:', mandateToUpdate.startDate);
            console.log('Updated End Date:', mandateToUpdate.endDate);
        
            // **Convert to Date Objects & Extract YYYY-MM-DD**
            let startDate;
            let endDate
            if(mandateToUpdate.startDate){
                 startDate = new Date(mandateToUpdate.startDate).toISOString().split('T')[0];
            }
            if(mandateToUpdate.endDate){
                 endDate = new Date(mandateToUpdate.endDate).toISOString().split('T')[0];
            }
            
            console.log('Formatted Start Date:', startDate);
            console.log('Formatted End Date:', endDate);
        
            // **Validation: End Date cannot be earlier than Start Date**
            if(endDate && startDate){
                if (endDate < startDate) {
                    this.showToast('Error', 'End Date cannot be earlier than Start Date!', 'error');
                    return;
                }
            }
            
        
            // **Validate Max Limit ≤ Loan Amount**
            if (parseFloat(mandateToUpdate.maxLimit) > parseFloat(this.loanAmount)) {
                this.showToast('Error', 'Max Limit cannot be greater than the Loan Amount!', 'error');
                return;
            }
            console.log('bank id ', this.selectedBankDetail.id);
             //Sanwar - Start
            if (mandateToUpdate._originalData) {
                const original = mandateToUpdate._originalData;
        
                const unchanged = (
                    original.startDate === mandateToUpdate.startDate &&
                    original.endDate === mandateToUpdate.endDate &&
                    parseFloat(original.maxLimit) === parseFloat(mandateToUpdate.maxLimit) &&
                    original.mandateType === mandateToUpdate.mandateType &&
                    original.mandateMode === mandateToUpdate.mandateMode &&
                    original.periodicity === mandateToUpdate.periodicity &&
                    original.pennyDrop === mandateToUpdate.pennyDrop &&
                    original.mandateStatus === mandateToUpdate.mandateStatus

                );
        
                if (unchanged) {
                    this.createdMandate = this.createdMandate.map(mandate => {
                        if (mandate.id === rowId) {
                            return {
                                ...mandate,
                                isEditing: false,
                                iconName: 'utility:edit'
                            };
                        }
                        return mandate;
                    });
                    return; // stop here, no Apex call
                }
            }
            //Sanwar - End
            
            // **Proceed with saving the mandate**
            updateMandateRecord({
                mandateId: rowId,
                loanApplicationId: this.recordId,
                bankDetailId: this.selectedBankDetail.id,
                mandateType: mandateToUpdate.mandateType,
                mandateMode: mandateToUpdate.mandateMode,
                maxLimit: parseFloat(mandateToUpdate.maxLimit),
                startDate: startDate, // Use normalized format
                endDate: endDate, // Use normalized format
                periodicity: mandateToUpdate.periodicity,
                status:mandateToUpdate.mandateStatus
            })
            .then(() => {
                // Update UI after successful save
                this.createdMandate = this.createdMandate.map(mandate => {
                    if (mandate.id === rowId) {
                        return {
                            ...mandate,
                            isEditing: false, // Exit edit mode
                            status:mandateToUpdate.mandateStatus,
                            iconName: 'utility:edit' // Reset icon
                        };
                    }
                    return mandate;
                });
        
                console.log('Updated Mandate:', JSON.stringify(mandateToUpdate));
                console.log('this.createdMandate1040', JSON.stringify(this.createdMandate));
                this.showToast('Success', 'Mandate Updated Successfully!', 'success');
            })
            .catch(error => {
                console.error('Error updating mandate:', error);
                let errorMessage = 'Mandate Updation Failed!'; //Sanwar

                this.showToast('Error', 'Mandate Update Failed!', 'error.body.message');
                if (error.body && error.body.message.includes('Mandate Max Limit amount')) {
                    errorMessage = 'Mandate Max Limit amount cannot be lower than 2X of EMI amount!';
                }
                if (error.body && error.body.message.includes('Mandate Max Limit cannot be lower than Loan Amount')) {
                    errorMessage = 'Mandate Max Limit cannot be lower than Loan Amount!';
                }
                if (error.body && error.body.message.includes('Mandate Max Limit cannot be lower than ₹1 Cr for loans above ₹1 Cr')) {
                    errorMessage = 'Mandate Max Limit cannot be lower than ₹1 Cr for loans above ₹1 Cr!';
                }
                if(error.body && error.body.message.includes('Mandate Start Date must be the same as Loan Created Date!'));{
                    errorMessage = 'Mandate Start Date must be the same as Loan Created Date';
                }
                this.showToast('Error', errorMessage, 'error'); //Sanwar
            }); 
        }
        
    closeModal(){
        this.openModal = false;
    }

    handleDeleteSelection(){
        this.handleDeleteMandate();
    }

    openModalConfirmation(event){
        // const mandateId = event.target.dataset.id;
        this.mandateToDeleteId = event.target.dataset.id;
        this.openModal = true;
    }

    handleDeleteMandate(){
        const mandateId = this.mandateToDeleteId;

        deleteMandateRecord({ mandateId })
            .then(() => {
                this.closeModal();//Sanwar - to close modal
                this.showToast('Success', 'Mandate deleted successfully!', 'success');

                // Remove from UI
                this.createdMandate = this.createdMandate.filter(mand => mand.id !== mandateId);
                // Check if there are no mandates left, then hide the table
                if (this.createdMandate.length === 0) {
                    this.mandateCreated = false;
                }
            })
            .catch(error => {
                this.closeModal();//Sanwar - to close modal
                console.error('Error deleting mandate:', error);
                this.showToast('Error', 'Failed to delete mandate!', 'error');
            });
    }

    handleError(error, context) {
        console.error(`Error in ${context}:`, error);
    }  

    // Reset Form After Mandate Creation
    resetForm() {
        this.mandate = { mandateType: 'Repayment Mandate', mandateMode:'',customerName:'', maxLimit: '', startDate: '', endDate: '', periodicity: '', pennyDrop: '', status: '' };
        this.fetchLoanStartDate();
    }

    // Show Toast Message
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    @track openBankAccountModal = false;
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
            this.selectedBankDetail.branchLocation = bankDet.Bank_Master__c ? (bankDet.Bank_Master__r.Branch_Location__c ? bankDet.Bank_Master__r.Branch_Location__c	: '') : '';
            this.selectedBankDetail.accountNumber = bankDet.Account_Number__c ? bankDet.Account_Number__c : '';
            this.selectedBankDetail.accountType = bankDet.Account_Type__c ? bankDet.Account_Type__c : '';
            this.selectedBankDetail.branchLocation = '';
            this.selectedBankDetail.ifsc = bankDet.Bank_Master__c ? (bankDet.Bank_Master__r.IFSC__c ? bankDet.Bank_Master__r.IFSC__c	: '') : '';
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
}