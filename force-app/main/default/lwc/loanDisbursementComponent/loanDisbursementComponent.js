import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from "lightning/navigation";
import getScreenDetails from '@salesforce/apex/AHL_LoanTransactionController.getScreenDetails';
import getDetailsForDisbursement from '@salesforce/apex/AHL_LoanTransactionController.getDetailsForDisbursement';
import getDetailsForPayment from '@salesforce/apex/AHL_LoanTransactionController.getDetailsForPayment';
import getPicklistValues from '@salesforce/apex/AHL_LoanTransactionController.getPicklistValues';
import getNextPaymentSequence from '@salesforce/apex/AHL_LoanTransactionController.getNextPaymentSequence';
import getPaymentTableRecords from '@salesforce/apex/AHL_LoanTransactionController.getPaymentTableRecords';
import getApplicantsForLoan from '@salesforce/apex/AHL_LoanTransactionController.getApplicantsForLoan';
import getBankDetails from '@salesforce/apex/CaptureMandateController.getBankDetails';
import savePaymentTransaction from '@salesforce/apex/AHL_LoanTransactionController.savePaymentTransaction';
//import uploadFile from '@salesforce/apex/CaptureMandateController.uploadInstrumentFile';
import uploadFile from '@salesforce/apex/AHL_LoanTransactionController.uploadFile';
import getDisbursalDetails from '@salesforce/apex/AHL_LoanTransactionController.getDisbursalDetails';
import updateFirstDisbursementAmount from '@salesforce/apex/AHL_LoanTransactionController.updateFirstDisbursementAmount';
import getPaymentRecord from '@salesforce/apex/AHL_LoanTransactionController.getPaymentRecord';
import deletePaymentRecord from '@salesforce/apex/AHL_LoanTransactionController.deletePaymentRecord';
import getUploadedDocument from '@salesforce/apex/AHL_LoanTransactionController.getUploadedDocument';
import getUploadedDocumentPerLT from '@salesforce/apex/AHL_LoanTransactionController.getUploadedDocumentPerLT';
import saveBankDetailRecord from '@salesforce/apex/AHL_LoanTransactionController.saveBankDetailRecord'
import { getRecord, getFieldValue, updateRecord } from "lightning/uiRecordApi";
import USERID_FIELD from "@salesforce/user/Id";
import STAGE_FIELD from "@salesforce/schema/Opportunity.StageName";
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
import SANCTION_LOANAMOUNT_FIELD from "@salesforce/schema/Opportunity.Sanction_Loan_Amount__c";
import getOpportunityTeamMembers from '@salesforce/apex/AHL_LoanDetailsController.getOpportunityTeamMembers';
import getLoanStartDate from '@salesforce/apex/AHL_LoanTransactionController.getLoanStartDate';
import getLoanTransactionDetails from '@salesforce/apex/AHL_LoanDetailsController.getLoanTransactionDetails'
import getDetailsForBank from '@salesforce/apex/AHL_LoanTransactionController.getDetailsForBank';
import getDisburmentPartyRecord from '@salesforce/apex/AHL_LoanTransactionController.getDisburmentPartyRecord';
import getApplicantsForBuilderApf from '@salesforce/apex/AHL_LoanTransactionController.getApplicantsForBuilderApf';
import getBankDetailsForBuilderApf from '@salesforce/apex/AHL_LoanTransactionController.getBankDetailsForBuilderApf';
import getUserRole from '@salesforce/apex/Hl_CovenantsDetailFormController.getUserRole'; //Sanwar
import canUserEditRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.canUserEditRecord';//Sanwar
import getObjectApiNameFromId from '@salesforce/apex/AHL_LoanTransactionController.getObjectApiNameFromId';//sanwar(12/12/2025)


export default class LoanDisbursementComponent extends NavigationMixin(LightningElement) {
    @api recordId; // Loan ID
    @track screenFieldsDisbursement = []; // Fields from Screen_Field__c
    @track fieldDetailsDisbursement = []; // Fields with actual values
    @track screenFieldsPayment = []; // Fields from Screen_Field__c
    @track fieldDetailsPayment = []; // Fields with actual values
    @track fieldDetailsBank =  [];
    @track fieldDetailsBeneficiary = []; // Stores Beneficiary Details Fields
    @track fieldDetailsChequeDD = []; //Stores ChequeDD details
    @track isLoading = true; // To show spinner while loading data
    @track showBankDetail = false;
    @track showPaymentButton = true; //Sanwar
    @track paymentSequence = 1; // Default sequence
    paymentSequenceField = null;
    @track disbursementType = ''; // Track Disbursement Type
    @track showBeneficiaryDetails = false; // Toggle Beneficiary Section
    @track showChequeDDDetails = false; //Toggle Cheque/DD Details
    @track paymentTableData = [];
    @track selectedApplicantId = '';
    @track applicantPicklistOptions = []; // Stores dropdown options for applicants
    @track showBankModal = false; // Modal visibility control
    @track bankDetails = [];
    @track showDetail = true;  //Sanwar
    @track showCreateButton = false; //change
    cssContainer = 'slds-modal__container width-60';
    @track isFavouringUploadRequired = false;  // Flag to track requirement
    @track isFileUploaded = false;  // Flag to track file upload
    @track totalPaymentAmount = 0; // Stores total payment amount
    @track showPaymentForm = false; // Controls form visibility
    @track isEditing = false; // Flag for edit mode
    @track editingRecordId = null; // Holds the payment record ID being edited
    @track selectedBankMasterId = ''; // Stores the selected Bank Master ID
    @track selectedIFSCCode = ''; // Stores the selected IFSC Code
    @track selectedBankName = ''; // Stores the selected Bank Name
    @track selectedBankBranch = ''; // Stores the selected Bank Branch
    @track showPreview = false; // Controls the preview icon visibility
    @track uploadedContentDocumentId; // Stores the uploaded file's ContentDocumentId
    @track selectedCusBankDetailId = '';
    quickDisb;
    qdpStatus = '';
    disbursementParty;
    currentUserOppRole = [];
    oppStage = '';
    oppSubStage = '';
    transactionId;
    disablePaymentBtn = false;
    sanctionLoanAmount = 0;
    showCreateBank = false;
    @track previouseDisType;
    @track previouseDisParty;
    @track valueDate;
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
    @wire(getLoanTransactionDetails, {
        loanId: "$recordId",
    })
    getLoanTxnDetails({
        data,
        error
    }){
        if (data) {
            console.log('getLoanTxnDetails   ', data)
            this.qdpStatus = data.QDP_Status__c ?? 'N/A';   
            this.quickDisb = data.Quick_Disbursement__c ?? false;
            console.log('this.qdpStatus is '+this.qdpStatus+'  and this.quickDisb is '+this.quickDisb)
        } else if(error) {
            this.handleError(error, 'gotLoanFields');
            this.showToast(this.toastTitle.ERROR, this.toastMessages.SOMETHING_WENT_WRONG, this.toastVariant.ERROR);
        }
    }

    connectedCallback() {
        //Sanwar - Start
        canUserEditRecord({recordId: this.recordId})
        .then(result => {
            if(result){
                this.showPaymentButton = true;
            }
        }) //Sanwar - End

        this.fetchScreenFieldsForDisbursementScreen();
        this.fetchScreenFieldsForPaymentScreen();
        this.fetchPaymentTableRecords();

        setTimeout(() => {
            this.setPageEditability();
        }, 3000);
    }

    async setPageEditability(){

        console.log('currentUserOppRole: '+this.currentUserOppRole);
        console.log('oppStage: '+this.oppStage);
        console.log('oppSubStage: '+this.oppSubStage);

        const isQDP = this.quickDisb === true && this.qdpStatus === 'QDP-ONHOLD';
        console.log('isQDP   '+isQDP)

        var disableControls = false;
        if(this.oppSubStage == 'Disbursed' || isQDP){
            //dont allow edit
            disableControls = true;
        }
        else if(this.oppStage == 'Disbursement'){
            if(this.oppSubStage == 'Ops Maker' && (this.currentUserOppRole.includes('OPS Maker') || this.currentUserOppRole.includes('Credit Officer'))){
                //allow edit
                console.log('disable false');
                disableControls = false;
            }
            else {
                //dont allow edit
                console.log('allow edit');
                disableControls = true;
            }
        }
        
        if(disableControls){
            console.log('disable controls--');
            
            this.fieldDetailsDisbursement = this.fieldDetailsDisbursement.map(row => { return { ...row, isDisabled: true }; });
            this.paymentTableData = this.paymentTableData.map(row => { return { ...row, isActionsRequired: false,enableRefresh : false }; });
            this.disablePaymentBtn = true;
        }else{
            this.paymentTableData = this.paymentTableData.map(row => { return { ...row, enableRefresh : false, enableRefresh : row.enableRefresh == true? true: row.enableRefresh}; });
        }

        if((this.oppStage == 'Disbursement' && this.oppSubStage == 'Ops Maker' && (this.currentUserOppRole.includes('OPS Maker') || this.currentUserOppRole.includes('Credit Officer'))) || (this.oppStage == 'PSV' && this.oppSubStage == 'PSV Sales' && this.currentUserOppRole.includes('Sales'))){
            console.log('ops maker');
            this.disablePaymentBtn = false;
            this.fieldDetailsDisbursement = this.fieldDetailsDisbursement.map(row => {
                if (row.id == 'Disbursement_Amount__c') {
                    console.log('ops 3');
                    return { ...row, isDisabled: false }; 
                }
                return row;
            });
        }
        else{
            console.log('inside else part');
            this.disablePaymentBtn = false;
        }

        // try {
        //     const result = await getUserRole({ recordId: this.recordId }); // Sanwar Start
        //     console.log('data is coming');
        //     if (result && this.oppSubStage == 'Ops Maker') {
        //         console.log('ops maker');
        //         this.disablePaymentBtn = false;

        //         this.fieldDetailsDisbursement = this.fieldDetailsDisbursement.map(row => {
        //             if (row.id == 'Disbursement_Amount__c') {
        //                 console.log('ops 3');
        //                 return { ...row, isDisabled: false };
        //             }
        //             return row;
        //         });
        //     }
        // } catch (error) {
        //     console.error('Error in getUserRole:', error);
        // }
        // //Sanwar End
        //Kalpesh Start
         if(this.oppStage == 'Disbursement' || this.oppStage == 'PSV' ){
             const fieldsToHide = ['Disbursement_Amount__c','Other_expenses__c','Total_VAS_Amount__c','Disbursement_Date__c',
                                    'Disbursement_Type__c','Disbursement_Party__c','Number_of_Payments__c'];
             this.fieldDetailsDisbursement = this.fieldDetailsDisbursement.map(row => {
                if (fieldsToHide.includes(row.id)) {
                     return { ...row, isHidden: true };
                    } else {
                      return { ...row, isHidden: false };
                    }
            });
         }
         //Kalpesh End
    }

    @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD, SUBSTAGE_FIELD, SANCTION_LOANAMOUNT_FIELD] })
    opportunity({ error, data }) {
        if(data) {
            this.oppStage = data.fields.StageName.value;
            this.oppSubStage = data.fields.Sub_stage__c.value;
            this.sanctionLoanAmount = data.fields.Sanction_Loan_Amount__c.value;
        }
    }

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

    renderedCallback() {
        const style = document.createElement("style");
        style.innerText = `
            .slds-accordion__list-item .section-control {
                background: #003087;
                color: #ffffff;
                margin-left: 0px;
                margin-bottom: 0px;
                margin-right: 0px;
                font-weight: 500;
            }
            .slds-accordion__summary {
                padding: 10px 0px 10px 0px;
            }
            .slds-accordion__summary-heading {
                color: #ffffff;
            }
            .slds-accordion__summary-action-icon {
                fill: #ffffff;
            }
        `;

        this.template.querySelector(".styleContainer")?.appendChild(style);
    }

    @track firstDisbursementAmount = 0;
    @track totalDisbursedAmount = 0;

    fetchScreenFieldsForDisbursementScreen() {
        this.isLoading = true;
        getScreenDetails({ formIdentifier: 'Disbursement Details Accordian', loanId: this.recordId })
            .then(data => {
                console.log('Screen Fields Data:', JSON.stringify(data));
                if (data) {
                    this.screenFieldsDisbursement = data;
                    this.fetchDisbursementDetails();
                }
            })
            .catch(error => {
                console.error('Error fetching screen fields:', error);
                this.isLoading = false;
            });
    }

    handleError(error, context) {
        console.error(`Error in ${context}:`, error);
    }

    fetchDisbursementDetails() {
        getDetailsForDisbursement({ screenName: 'Disbursement Details', loanId: this.recordId, formIdentifier: 'Disbursement Details Accordian' })
            .then(result => {
                console.log('Loan Details:', JSON.stringify(result));

                this.fieldDetailsDisbursement = result.map(item => {
                    const screenField = this.screenFieldsDisbursement.find(sf => sf.Storage_Field__c === item.fieldApiName);
                    return {
                        id: item.fieldApiName,
                        label: item.fieldLabel,
                        value: item.fieldValue,
                        isDisabled: screenField ? screenField.Is_Disabled__c : true,
                        isPicklist: item.fieldType === 'Picklist',
                        isDate: item.fieldType === 'Date',
                        isNumber: item.fieldType === 'Number',
                        isCheckBox : item.fieldType === 'Boolean'
                    };
                });

                console.log('this.fieldDetailsDisbursement   '+this.fieldDetailsDisbursement);

                // Fetch Disbursal Details (Total Fee, Total Loan Amount, Total Disbursal Amount)
                return getDisbursalDetails({ loanId: this.recordId });
            })
            .then(disbursalData => {
                console.log('Disbursal Data:', disbursalData);
                this.firstDisbursementAmount = disbursalData.First_Disbursement_Amount__c || 0;
                this.totalDisbursedAmount = disbursalData.Total_Disbursed_Amount__c || 0;

                // Update relevant fields in the UI
                this.fieldDetailsDisbursement = this.fieldDetailsDisbursement.map(field => {
                    if (field.id === 'Total_Fee__c') {
                        return { ...field, value: disbursalData.Total_Fee__c };
                    }
                    else if (field.id === 'Total_Loan_Amount__c') {
                        return { ...field, value: disbursalData.Total_Loan_Amount__c };
                    }
                    else if (field.id === 'Total_Disbursal_Amount__c') {
                        return { ...field, value: disbursalData.Total_Disbursal_Amount__c };
                    }
                    else if (field.id === 'Insurance_Amount__c') {
                        return { ...field, value: disbursalData.Insurance_Amount__c };
                    }
                    else if (field.id === 'Total_Disbursed_Amount__c') {
                        return { ...field, value: disbursalData.Total_Disbursed_Amount__c };
                    }
                    return field;
                });

                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching disbursement details:', error);
                this.isLoading = false;
            });
    }


    fetchPaymentSequence() {
        return getNextPaymentSequence({ loanId: this.recordId })
            .then(sequence => {
                console.log(`Next Payment Sequence: ${sequence}`);

                // Store Payment Sequence Field
                this.paymentSequenceField = {
                    id: 'Payment_Sequence__c',
                    label: 'Payment Sequence',
                    value: sequence,
                    isDisabled: true,
                    isPaymentSequence: true
                };
                this.fieldDetailsPayment = [this.paymentSequenceField, ...this.fieldDetailsPayment];
            })
            .catch(error => {
                console.error('Error fetching payment sequence:', error);
                this.paymentSequenceField = {
                    id: 'Payment_Sequence__c',
                    label: 'Payment Sequence',
                    value: 1, // Default to 1 if error occurs
                    isDisabled: true,
                    isPaymentSequence: true
                };
                this.fieldDetailsPayment = [this.paymentSequenceField, ...this.fieldDetailsPayment];
            });

    }

    fetchScreenFieldsForPaymentScreen() {
        this.isLoading = true;

        // First fetch Payment Sequence, then fetch fields
        this.fetchPaymentSequence()
            .then(() => {
                return getScreenDetails({ formIdentifier: 'Payment Details Accordian', loanId: this.recordId });
            })
            .then(data => {
                console.log('Screen Fields Data:', JSON.stringify(data));

                if (data) {
                    this.screenFieldsPayment = data;
                    this.fetchPaymentDetails();
                }
            })
            .catch(error => {
                console.error('Error fetching screen fields:', error);
                this.isLoading = false;
            });
    }

    fetchPaymentDetails() {
        this.isLoading = true;

        getDetailsForPayment({ screenName: 'Payment Details', loanId: this.recordId, formIdentifier: 'Payment Details Accordian' })
            .then(async result => {
                console.log('Apex Response:', JSON.stringify(result));

                let updatedFields = await Promise.all(result.map(async item => {
                    console.log(`Processing Field: ${item.fieldApiName}, Type: ${item.fieldType}`);

                    let fieldData = {
                        id: item.fieldApiName,
                        label: item.fieldLabel,
                        value: '', // Initially empty
                        isDisabled: item.isDisabled,
                        isPicklist: item.fieldType === 'Picklist',
                        isDate: item.fieldType === 'Date',
                        isNumber: item.fieldType === 'Number',
                        isTextarea: item.fieldType === 'Textarea',
                        isPaymentSequence: false,
                        isLookup: item.isLookup,
                        picklistOptions: [],
                        isMandatory: item.isMandatory
                    };

                    if (fieldData.isPicklist) {
                        fieldData.picklistOptions = await this.getPicklistOptionsFromApex(true, item.storageObject, item.fieldApiName);
                    }

                    return fieldData;
                }));

                var scheduleDate = '';
                getLoanStartDate({ loanId: this.recordId })
                .then(result => {
                    scheduleDate = result;
                    console.log('result dae: '+result);

                    // Get Disbursal Details to fetch Total Fee
                    return getDisbursalDetails({ loanId: this.recordId }).then(disbursalData => {
                        console.log('Fetched Disbursal Data:', JSON.stringify(disbursalData));

                        let totalFee = disbursalData.Total_Fee__c || 0;
                        console.log('this.paymentSequence:: ' + this.paymentSequence);

                        // **Ensure Total Fee is 0 if Payment Sequence > 1**
                        updatedFields = updatedFields.map(field => {
                            if (field.id === 'Total_Fee__c') {
                                return { ...field, value: (this.paymentSequence === 1 ? totalFee : 0) };
                            }
                            else if (field.id === 'Scheduled_Disbursement_Date__c') {
                                return { ...field, value: scheduleDate };
                            }
                            return field;
                        });

                        // Clear existing fields before adding new ones
                        this.fieldDetailsPayment = [];
                        this.fieldDetailsPayment.push(this.paymentSequenceField);
                        this.fieldDetailsPayment = [...this.fieldDetailsPayment, ...updatedFields];

                        this.isLoading = false;
                        console.log('Final fieldDetailsPayment:', JSON.stringify(this.fieldDetailsPayment));
                    });
                })
                .catch(error => {
                    console.error('Error fetching schedule date: ', error);
                });
            })
            .catch(error => {
                console.error('Error fetching payment details:', error);
                this.isLoading = false;
            });
    }

    // get checkCreatePayment() {
    //     console.log('create Pay: ' + this.totalAmountWithOutVas + '  ==  ' + this.totalDisbursedAmount);
    //     return this.disableCreatePayment;
    // }

    // set checkCreatePayment(value) {
    //     if(!this.disablePaymentBtn){
    //         this.disableCreatePayment = this.totalAmountWithOutVas >= this.totalDisbursedAmount;
    //     }
    //     else{
    //         this.disableCreatePayment = this.disablePaymentBtn;
    //     }
    // }

    @track showPaymentForm = false;
    createPayment() {
        if (this.totalAmountWithOutVas >= this.totalDisbursedAmount) {
            this.showToast('Error', 'Total disbursed amount has been reached. Cannot create more payments.', 'error');
            return;
        }
        this.showPaymentForm = true;

        // Fetch Payment Sequence first
        this.fetchPaymentSequence()
            .then(() => {
                console.log('Updated Payment Sequence:', this.paymentSequenceField.value);
                this.paymentSequence = this.paymentSequenceField.value; // Ensure it's updated
                this.showBeneficiaryDetails = false;
                this.showChequeDDDetails = false;
                // Now fetch screen fields after sequence is properly updated
                return this.fetchScreenFieldsForPaymentScreen();
            })
            .then(() => {
                console.log('this.paymentSequence:', this.paymentSequence);

                // Ensure Total Fee is 0 for second payment onwards
                this.fieldDetailsPayment = this.fieldDetailsPayment.map(field => {
                    console.log('field: '+JSON.stringify(field));
                    if (field.id === 'Total_Fee__c' && this.paymentSequence > 1) {
                        return { ...field, value: 0 };
                    }
                    return field;
                });

                console.log('Total Fee set to 0 for new payments after the first one.');
            })
            .catch(error => {
                console.error('Error during createPayment:', error);
            });
    }

    async getPicklistOptionsFromApex(isPicklist, storageObject, storageField) {
        if (isPicklist) {
            console.log(`Fetching Picklist for Object: ${storageObject}, Field: ${storageField}`);

            try {
                const result = await getPicklistValues({ storageObject: storageObject, storageField: storageField });
                console.log('Picklist Values from Apex:', JSON.stringify(result));

                result.map(option => ({
                    label: option.label,
                    value: option.value
                }));

                if (this.oppStage == 'Disbursement') {
                    const filterList = result.filter(
                        (elem) => elem.label != 'VAS'
                    );

                    return filterList;
                }

                return result;
            } catch (error) {
                console.error('Error fetching picklist values:', error);
                return [];
            }
        }
        return [];
    }

    // Function to fetch applicants for the loan and return as picklist options
    async fetchApplicants() {
        try {
            if(this.disbursementParty === 'Customer'){
                console.log('Dis party ',this.disbursementParty);
                this.disbursementParty = ['Primary Applicant', 'Co Applicant'];
            }
            console.log('selected party ', this.disbursementParty);
            //Sanwar - Start
            if(this.disbursementParty === 'Builder-APF'){
                const builderData = await getApplicantsForBuilderApf({loanId: this.recordId});
                if (!builderData || builderData.length === 0) {
                    console.warn('No applicants found for this loan.');
                    this.applicantPicklistOptions = [];
                    return;
                }
    
                // Convert applicants to dropdown options
                this.applicantPicklistOptions = builderData.map(applicant => ({
                    label: applicant.Collateral__r.Builder__r.Name, // Applicant's Name
                    value: applicant.Id,   // Applicant's Salesforce ID
                    applicantType: 'Builder-APF'
                }));
            }
            //Sanwar - End
            else{   // Sanwar
                const result = await getApplicantsForLoan({ loanId: this.recordId, applicantType : this.disbursementParty});
                console.log('Fetched Applicants:', JSON.stringify(result));

                // Check if data is received
                if (!result || result.length === 0) {
                    console.warn('No applicants found for this loan.');
                    this.applicantPicklistOptions = [];
                    return;
                }

                // Convert applicants to dropdown options
                this.applicantPicklistOptions = result.map(applicant => ({
                    label: applicant.Name, // Applicant's Name
                    value: applicant.Id,   // Applicant's Salesforce ID
                    applicantType: applicant.Applicant_Type__c
                }));
            } //Sanwar
            console.log('Updated Applicant Picklist:', JSON.stringify(this.applicantPicklistOptions));

            // Update the fieldDetailsBeneficiary to use the picklist options
            this.fieldDetailsBeneficiary = this.fieldDetailsBeneficiary.map(field => {
                if (field.id === 'Application_Applicant__c') {
                    return { ...field, picklistOptions: this.applicantPicklistOptions };
                }
                return field;
            });

        } catch (error) {
            console.error('Error fetching applicants:', error);
            this.applicantPicklistOptions = [];
        }
    }

    // Function to check if Disbursement Party is "Customer" & Type is "RTGS/NEFT/IMPS"
    isCustomerRTGSNEFTIMPS() {
        return this.fieldDetailsPayment.some(
            field => field.id === 'Disbursement_Party__c' && (field.value === 'Customer' || field.value === 'Seller' || field.value === 'Builder' || field.value === 'Builder-APF')
        ) &&
            this.fieldDetailsPayment.some(
                field => field.id === 'Disbursement_Type__c' && ['RTGS', 'NEFT', 'IMPS','IFT'].includes(field.value)
            );
    }

    // Function to check if Disbursement Party is "Third Party" & Type is "IMPS"

    isThirdPartyWithIMPS() {
        return this.fieldDetailsPayment.some(field => field.id === 'Disbursement_Party__c' && field.value === 'Third party') &&
            this.fieldDetailsPayment.some(field => field.id === 'Disbursement_Type__c' && field.value == 'IMPS');
    }
    //Sanwar
    isVendorWithIMPS() {
        return this.fieldDetailsPayment.some(field => field.id === 'Disbursement_Party__c' && field.value === 'Vendor') &&
            this.fieldDetailsPayment.some(field => field.id === 'Disbursement_Type__c' && field.value == 'IMPS');
    }

    isThirdPartyRTGSNEFTIMPS() {
        console.log('Checking isThirdPartyRTGSNEFTIMPS...');
        console.log('Current fieldDetailsPayment:', JSON.stringify(this.fieldDetailsPayment));

        let partyField = this.fieldDetailsPayment.find(field => field.id === 'Disbursement_Party__c');
        let typeField = this.fieldDetailsPayment.find(field => field.id === 'Disbursement_Type__c');

        console.log('Disbursement Party:', partyField ? partyField.value : 'Not Found');
        console.log('Disbursement Type:', typeField ? typeField.value : 'Not Found');

        let result = partyField?.value === 'Third party' &&
            ['RTGS', 'NEFT', 'IMPS','IFT'].includes(typeField?.value);

        console.log('Returning:', result);
        return result;
    }

    //Sanwar Start
    isVendorRTGSNEFTIMPS() {
        console.log('Current fieldDetailsPayment:', JSON.stringify(this.fieldDetailsPayment));

        let partyField = this.fieldDetailsPayment.find(field => field.id === 'Disbursement_Party__c');
        let typeField = this.fieldDetailsPayment.find(field => field.id === 'Disbursement_Type__c');

        console.log('Disbursement Party:', partyField ? partyField.value : 'Not Found');
        console.log('Disbursement Type:', typeField ? typeField.value : 'Not Found');

        let result = partyField?.value === 'Vendor' &&
            ['RTGS', 'NEFT', 'IMPS','IFT'].includes(typeField?.value);

        console.log('Returning:', result);
        return result;
    }//Sanwar End

    //Function to check if Disbursement Party is "Customer" & Type is "Cheque/DD"
    isCustomerChequeDD() {
        return this.fieldDetailsPayment.some(
            field => field.id === 'Disbursement_Party__c' && (field.value === 'Customer' || field.value === 'Seller' || field.value === 'Builder' || field.value === 'Builder-APF')  //Sanwar
        ) &&
            this.fieldDetailsPayment.some(
                field => field.id === 'Disbursement_Type__c' && ['CHEQUE', 'DD - DEMAND DRAFT'].includes(field.value)
            );
    }

    isThirdPartyChequeDD() {
        return this.fieldDetailsPayment.some(
            field => field.id === 'Disbursement_Party__c' && field.value === 'Third party'
        ) &&
            this.fieldDetailsPayment.some(
                field => field.id === 'Disbursement_Type__c' && ['CHEQUE', 'DD - DEMAND DRAFT'].includes(field.value)
            );
    }
    //Sanwar
    isVendorChequeDD() {
        return this.fieldDetailsPayment.some(
            field => field.id === 'Disbursement_Party__c' && field.value === 'Vendor'
        ) &&
            this.fieldDetailsPayment.some(
                field => field.id === 'Disbursement_Type__c' && ['CHEQUE', 'DD - DEMAND DRAFT'].includes(field.value)
            );
    }

    // Utility function to fetch field values from fieldDetailsPayment
    getFieldValue(fieldId) {
        let field = this.fieldDetailsPayment.find(f => f.id === fieldId);
        return field ? field.value : null;
    }

    handleOnBlur(event) {
        console.log('inside handleOnBlur::');

        const fieldId = event.target.dataset.id;
        if (!fieldId) {
            console.error('No field ID found in event target!');
            return;
        }

        // Extract Value: Use event.detail.value for picklists, event.target.value for other fields
        const selectedValue = event.detail ? event.detail.value : event.target.value;

        // **Handle First Disbursement Amount Change**
        if (fieldId === 'First_Disbursement_Amount__c' && this.firstDisbursementAmount != selectedValue) {

            /*if (selectedValue % 1 !== 0) {
                this.showToast('Error', 'First Disbursement Amount cannot be a decimal value.', 'error');
                event.target.value = this.firstDisbursementAmount;
                return;
            }*/
            if(selectedValue > this.sanctionLoanAmount){
                this.showToast('Error', 'First disbursement amount can not be more then the sanctioned amount.', 'error');
                event.target.value = this.firstDisbursementAmount;
                return;
            }

            var totalAmountWithOutVas =0;
            this.paymentTableData.forEach(field => {
                if(field.disbursementParty != 'VAS' && field.qdpStatus != 'Rejected'){
                    totalAmountWithOutVas += field.amount;
                }
            });

            if(totalAmountWithOutVas > selectedValue){
                this.showToast('Error', 'First disbursement amount can not be less then the already paid amount.', 'error');
                event.target.value = this.firstDisbursementAmount;
                return;
            }

            this.updateTotalDisbursedAmount(selectedValue);
            
            // Save to Salesforce
            updateFirstDisbursementAmount({ loanId: this.recordId, newAmount: selectedValue, totalDisbAmount: this.totalDisbursedAmount })
            .then(response => {
                if(response && response.startsWith('SUCCESS')) {
                    this.firstDisbursementAmount = selectedValue;
                    console.log('First Disbursement Amount successfully updated in Salesforce');
                    this.transactionId = response.split(':')[1]; 
                } else {
                   console.error('Error saving First Disbursement Amount:', response);
                   this.showToast('Error', response, 'error');
                }
            })
            .catch(error => {
                console.error('Error updating First Disbursement Amount:', error);
            });
        }
        console.log('this.transactionId;',this.transactionId);
        
        if (fieldId === 'Value_Date__c' /*&& this.valueDate != selectedValue*/) {
            /*if (!selectedValue) { mandatory check removed as of now
                this.showToast('Error', 'Value Date cannot be empty.', 'error');
                event.target.value = this.valueDate;
                return;
            }*/
            const today = new Date();
            const selectedDate = new Date(selectedValue);

            if (selectedDate > today) {
                this.showToast('Error', 'Value Date cannot be a future date.', 'error');
                event.target.value = this.valueDate;
                return;
            }

            const fields = {};
            fields['Id'] = this.transactionId;
            fields['Value_Date__c'] = selectedValue;
            const recordInput = { fields };
            updateRecord(recordInput)
            .then(() => {
                this.valueDate = selectedValue;
                this.showToast('Success','Value Date updated successfully.','success');
            })
            .catch(error => {
                console.error('Error updating Value Date:', error);
                this.showToast('Error','Something went wrong while updating Value Date.','error');
            });


        }

    }

    handleInputChange(event) {
        console.log('inside handleinput::');

        // Extract Field ID
        const fieldId = event.target.dataset.id;
        console.log('field id ', fieldId);
        if (!fieldId) {
            console.error('No field ID found in event target!');
            return;
        }

        //Sanwar(22/12/2025)
        // Extract Value: Use event.detail.value for picklists, event.target.value for other fields
        let selectedValue = event.detail ? event.detail.value : event.target.value;
        //sanwar start 31/12/2025
        if(fieldId == 'Account_Number__c'){
            const regex = /^[a-zA-Z0-9]+$/        ///[^a-zA-Z0-9]|x/i;
            console.log('At 832');
            if (!regex.test(selectedValue)) {
                console.log('At 834');
                selectedValue = selectedValue.slice(0, -1);
                event.target.value = selectedValue;

                this.showToast(
                    'Warning',
                    'The account number contains special characters or invalid values.',
                    'warning'
                );
            }
            event.target.reportValidity();
            this.fieldDetailsBeneficiary = this.fieldDetailsBeneficiary.map(field => {
                if (field.id === fieldId) {
                    field.value = selectedValue;
                }
                return field;
            });

            return; 
        }//sanwar end 31/12/1202

        console.log('At 828',selectedValue);
        if (fieldId === 'Favoring_Name__c') {
            const regex = /^[A-Za-z0-9. ]*$/;
            console.log('831');
            if (!regex.test(selectedValue)) {
                console.log('832');
                selectedValue = selectedValue.slice(0, -1);
                console.log('833');
                event.target.value = selectedValue;
                console.log('834');
                this.showToast('Warning', 'Invalid Character', 'warning');
            }
        
            event.target.reportValidity();
            this.fieldDetailsChequeDD = this.fieldDetailsChequeDD.map(field => {
                if (field.id === fieldId) {
                    field.value = selectedValue;
                }
                return field;
            });
        
        }//Sanwar(22/12/2025)
        
        //sanwar(12/12/2025)
        console.log('At 829');
        if(fieldId === 'Application_Applicant__c'){
            getObjectApiNameFromId({ recordId: selectedValue })
            .then(objectApiName => {
                console.log('Object Name:', objectApiName);
                if (objectApiName === 'Application_Collateral__c') {
            this.selectedApplicantId = selectedValue;
            getBankDetailsForBuilderApf({ applicantCollateralId: this.selectedApplicantId })
            .then(result => {
                console.log('below is detail data');
                console.log('get bank detail ',result);
                if (result && result.length > 0) {
                    //prachi's changes start
                                                        this.bankDetails = result.map(bank => {
                                        // Check if account number is masked (all Xs, asterisks, or contains X/*)
                                        let accNum = bank.Account_Number__c || '';
                                        const isMasked = /^[Xx*]+$/.test(accNum) || accNum.includes('X') || accNum.includes('*') || accNum.includes('x');
                                        return {
                                            id: bank.Id,
                                            bankName: bank.Name || '',  // Extracting Bank Name
                                            customerName: bank.Account_Holder_Name__c || '',  // Extracting Account Holder Name
                                            branchName: bank.Bank_Master__r?.Branch_Name__c || '',  // Extracting Branch Name
                                            branchLocation: bank.Bank_Master__r?.Branch_Location__c || '',  // Extracting Branch Location,
                                            ifsc: bank.Bank_Master__r?.IFSC__c || '',
                                            isRepayment: bank.Is_Repayment_Account__c || '',
                        accountNumber: bank.Account_Number__c || '',
                                            micr: bank.Bank_Master__r?.MICR__c || '',
                                            accountType: bank.Account_Type__c || '',
                                            mobileNumber: bank.Application_Applicant__r?.Mobile_Number__c || ''
                                        };
                                    });
console.log('this.bankDetails:: ' + JSON.stringify(this.bankDetails));
                    this.showBankModal = true;
                    this.showBankDetail = false;
                    //prachi's changes end
                    this.showCreateBank = false;
                } else {
                                //sanwar 31/12/2025
                                // if(['Seller', 'Builder', 'Builder-APF'].includes(this.disbursementParty)){
                                //     this.showBankModal = true;
                                //     this.showCreateBank = true;
                                //     this.showBankDetail = false;
                                // }
                                //  else {
                        this.showBankModal = false;
                        this.showCreateBank = false;
                        this.showBankDetail = false;
                        this.bankDetails = []; // Clear previous data if no bank details found


                        this.fieldDetailsBeneficiary = this.fieldDetailsBeneficiary.map(field => {
                            if (field.id === 'IFSC__c') {
                                return { ...field, value: '', isDisabled: true };
                            } else if (field.id === 'Bank__c') {
                                return { ...field, value: '', isDisabled: true };
                            } else if (field.id === 'Bank_Branch__c') {
                                return { ...field, value: '', isDisabled: true };
                            } else if (field.id === 'Account_Number__c') {
                                return { ...field, value: '', isDisabled: true };
                            } else if (field.id === 'Account_Holder_Name__c') {
                                return { ...field, value: '', isDisabled: true };
                            } else if (field.id === 'Bank_Details__c') {
                                return { ...field, value: '', isDisabled: true };
                            }
                            return field;
                        });

                        // **Ensure UI reactivity**
                        this.fieldDetailsBeneficiary = [...this.fieldDetailsBeneficiary];

                        console.log('------ ' + JSON.stringify(this.fieldDetailsBeneficiary));
                                    this.showToast('Warning', `No bank details found for selected  ${this.disbursementParty}`, 'warning');//sanwar 31/12/2025
                                // }
                    
                }
            })
            .catch(error => {
                console.error('Error fetching bank details:', error);
            });
        }

            })
            .catch(error => {
                console.error(error);
            });
        }

        console.log(`Field Changed: ${fieldId}, New Value: ${selectedValue}`);
        //Sanwar - Start
        if(fieldId == 'Disbursement_Party__c' && (selectedValue == 'Builder' || selectedValue == 'Seller' || selectedValue == 'Builder-APF')){
            getDisburmentPartyRecord({disParty : selectedValue, loanId : this.recordId})
            .then(result => {
                if(result != true){
                    this.showToast('Error', 'No matching records exist for this Disbursement Party.', 'error');
                    this.showBeneficiaryDetails = false;
                    this.showChequeDDDetails = false;
                    this.showDetail = false;
                    return;
                }
                else{
                    this.showDetail = true;
                }
            })
            } 
        else if(fieldId == 'Disbursement_Party__c' && (selectedValue != 'Builder' && selectedValue != 'Seller' && selectedValue != 'Builder-APF')){
            this.showDetail = true;
            // this.showBeneficiaryDetails = true;
            // this.showChequeDDDetails = true;
        }

        if(fieldId == 'Disbursement_Type__c'){
            if(!this.showDetail){
                this.showBeneficiaryDetails = false;
                this.showChequeDDDetails = false;
                this.showToast('Error', 'No matching records exist for this Disbursement Party.', 'error');
                return;
            }
        }
        //Sanwar - End
        // **Update Payment Fields**
        this.fieldDetailsPayment = this.fieldDetailsPayment.map(field => {
            if (field.id === fieldId) {
                return { ...field, value: selectedValue };
            }
            return field;
        });

        this.fieldDetailsBank = this.fieldDetailsBank.map(field => {
            console.log('field id ', field.id);
                console.log('field idd', fieldId);
            if (field.id === fieldId) {
                console.log('field id ', field.id);
                console.log('field idd', fieldId);
                return { ...field, value: selectedValue };
            }
            return field;
        });

        console.log('bank field details in input change ',this.fieldDetailsBank);

        // **Update Beneficiary Fields**
        this.fieldDetailsBeneficiary = this.fieldDetailsBeneficiary.map(field => {
            if (field.id === fieldId) {
                return { ...field, value: selectedValue };
            }
            if(field.id === "Bank_Master__c" && fieldId === 'IFSC__c'){
                console.log('field id ', field.id);
                console.log('field idd', fieldId);
                return { ...field, value: selectedValue };

            }
            
            return field;
        });

        // **Update Cheque/DD Fields**
        this.fieldDetailsChequeDD = this.fieldDetailsChequeDD.map(field => {
            if (field.id === fieldId) {
                return { ...field, value: selectedValue };
            }
            return field;
        });

        // Update values of the disbursement type and party
        if (fieldId === 'Disbursement_Type__c') {
            this.disbursementType = selectedValue;
        } else if (fieldId === 'Disbursement_Party__c') {
            this.disbursementParty = selectedValue;
        }

        console.log(`Updated Disbursement Party: ${this.disbursementParty}`);
        if(this.disbursementParty === 'Customer'){
            this.showCreateButton = false;
        }
        else{
            this.showCreateButton = true;
        }
        console.log(`Updated Disbursement Type: ${this.disbursementType}`);

        console.log("Updated Payment Fields:", JSON.stringify(this.fieldDetailsPayment));

        

        // **Special Handling for Applicant Selection**
        if (fieldId === 'Application_Applicant__c') {
            this.selectedApplicantId = selectedValue;

            let selectedApplicant = this.applicantPicklistOptions.find(app => app.value === selectedValue);
            console.log(`Selected Applicant ID: ${selectedValue}`);

            if (selectedApplicant) {
                console.log(`Auto-filling Customer Type: ${selectedApplicant.applicantType}`);

                // Check if Customer_Type__c exists
                let customerTypeFieldExists = this.fieldDetailsBeneficiary.some(field => field.id === 'Customer_Type__c');
                console.log(`Customer_Type__c field exists? ${customerTypeFieldExists}`);

                // Ensure the field gets updated
                this.fieldDetailsBeneficiary = this.fieldDetailsBeneficiary.map(field => {
                    if (field.id === 'Customer_Type__c') {
                        console.log(`Updating Customer_Type__c to: ${selectedApplicant.applicantType}`);
                        return {
                            ...field,
                            value: selectedApplicant.applicantType,
                            isDisabled: true
                        };
                    }
                    return field;
                });

                // Ensure LWC Reactivity
                this.fieldDetailsBeneficiary = [...this.fieldDetailsBeneficiary];

                console.log('Updated fieldDetailsBeneficiary:', JSON.stringify(this.fieldDetailsBeneficiary));
            }

            const disbursementType = this.getFieldValue('Disbursement_Type__c');
            console.log(`Current Disbursement Type: ${disbursementType}`);

            if (!['CHEQUE', 'DD - DEMAND DRAFT'].includes(disbursementType)) {
                this.fetchBankDetails();
            } else {
                console.log("Skipping fetchBankDetails() because Disbursement Type is Cheque/DD.");
            }
        }

        if (fieldId === 'Disbursement_Party__c') {
            this.isFavouringUploadRequired = (selectedValue === 'Third party');
            console.log(`Favouring Upload Required? ${this.isFavouringUploadRequired}`);
        }

        // **Handle Disbursement Type Change**
        if ((fieldId === 'Disbursement_Party__c' || fieldId === 'Disbursement_Type__c' ) && this.disbursementType && this.disbursementParty) {//Sanwar
            console.log(`Updating Disbursement Fields: ${fieldId} = ${selectedValue}`);

            // Update payment fields first
            this.fieldDetailsPayment = this.fieldDetailsPayment.map(field => {
                if (field.id === fieldId) {
                    return { ...field, value: selectedValue };
                }
                return field;
            });

            // Ensure reactivity
            this.fieldDetailsPayment = [...this.fieldDetailsPayment];

            console.log('Updated fieldDetailsPayment:', JSON.stringify(this.fieldDetailsPayment));

            // Call handleDisbursementTypeChange AFTER ensuring the values are updated
            this.handleDisbursementTypeChange(selectedValue);


        }


        // **Ensure Total Fee is 0 if Payment Sequence > 1**
        if (this.paymentSequence > 1 && fieldId === 'Total_Fee__c') {
            this.fieldDetailsPayment = this.fieldDetailsPayment.map(field => {
                if (field.id === 'Total_Fee__c') {
                    return { ...field, value: 0 };
                }
                return field;
            });

            console.log('Total Fee set to 0 for sequence > 1.');
        }

        // **Update Net Amount dynamically when Disbursement Amount changes**
        if (fieldId === 'Disbursement_Amount__c') {
            /*if (selectedValue % 1 !== 0) {
                this.showToast('Error', 'Disbursement Amount cannot be a decimal value.', 'error');
                this.updateField(fieldId, ''); // Clear it if decimal
                return;
            }*/
            this.updateNetAmount(selectedValue);
        }
    }
    //new method
    updateField(fieldId, newValue) {
        this.fieldDetailsPayment = this.fieldDetailsPayment.map(field => {
            if (field.id === fieldId) {
                return { ...field, value: newValue };
            }
            return field;
        });
    }
    

    // **Function to update Net Amount dynamically**
    updateNetAmount(disbursementAmount) {
        const totalFeeField = this.fieldDetailsPayment.find(f => f.id === 'Total_Fee__c');
        const totalFee = totalFeeField ? parseFloat(totalFeeField.value) || 0 : 0;

        this.fieldDetailsPayment = this.fieldDetailsPayment.map(field => {
            if (field.id === 'Net_Amount__c') {
                return { ...field, value: disbursementAmount };
            }// Sanwar - removed  totalFee subtracting condition
            return field;
        });

        console.log('Updated Net Amount:', disbursementAmount - totalFee);
    }

    updateTotalDisbursedAmount(firstDisbursementAmount) {
        const totalFeeField = this.fieldDetailsDisbursement.find(f => f.id === 'Total_Fee__c');
        const totalFee = totalFeeField ? parseFloat(totalFeeField.value) || 0 : 0;

        this.fieldDetailsDisbursement = this.fieldDetailsDisbursement.map(field => {
            if (field.id === 'Total_Disbursed_Amount__c') {
                this.totalDisbursedAmount = firstDisbursementAmount - totalFee;
                return { ...field, value: firstDisbursementAmount - totalFee };
            }
            return field;
        });

        console.log('Updated Total Disbursed Amount:', firstDisbursementAmount - totalFee);
    }

    handleIFSCLookupSelected(event) {
        console.log('Selected Bank Master:', JSON.stringify(event.detail));

        // Extract the correct record from searchRecord
        const selectedRecord = event.detail.searchRecord || {}; // Ensure it exists
        console.log('data',selectedRecord);
        console.log('data',selectedRecord.Id);
        console.log('data',selectedRecord.IFSC__c);
        console.log('data',selectedRecord.Branch_Name__c);
        // Assign values safely
        this.selectedBankMasterId = selectedRecord.Id || ''; // Bank Master ID
        this.selectedIFSCCode = selectedRecord.IFSC__c || ''; // IFSC Code
        this.selectedBankName = selectedRecord.Bank_Name__c || ''; // Bank Name
        this.selectedBankBranch = selectedRecord.Branch_Name__c || ''; // Branch Name

        // Update fieldDetailsBeneficiary with new values
        this.fieldDetailsBeneficiary = this.fieldDetailsBeneficiary.map(field => {
            if (field.id === 'IFSC__c') {
                console.log('field id ',field.id);
                return { ...field, value: this.selectedIFSCCode };
            } else if (field.id === 'Bank__c') {
                return { ...field, value: this.selectedBankName, isDisabled: true };
            } else if (field.id === 'Bank_Branch__c') {
                return { ...field, value: this.selectedBankBranch, isDisabled: true };
            } else if (field.id === 'Bank_Master__c') {
                return { ...field, value: this.selectedBankMasterId }; // Store Bank Master ID
            }
            return field;
        });


        this.fieldDetailsBank = this.fieldDetailsBank.map(field => {
            if (field.id === 'IFSC__c') {
                console.log('field id ',field.id);
                return { ...field, value: this.selectedIFSCCode };
            } else if (field.id === 'Bank__c') {
                return { ...field, value: this.selectedBankName, isDisabled: true };
            } else if (field.id === 'Bank_Branch__c') {
                return { ...field, value: this.selectedBankBranch, isDisabled: true };
            } else if (field.id === 'Bank_Master__c') {
                return { ...field, value: this.selectedBankMasterId }; // Store Bank Master ID
            }
            return field;
        });

        console.log('Updated fieldDetailsBeneficiary:', JSON.stringify(this.fieldDetailsBank));
    }


    handleIFSCLookupDeselected(event) {
        console.log('Deselected IFSC Code');

        this.selectedBankMasterId = '';
        this.selectedIFSCCode = '';
        this.selectedBankName = '';
        this.selectedBankBranch = '';

        this.fieldDetailsBeneficiary = this.fieldDetailsBeneficiary.map(field => {
            if (field.id === 'IFSC__c' || field.id === 'Bank__c' || field.id === 'Bank_Branch__c' || field.id === 'Bank_Master__c') {
                return { ...field, value: '', isDisabled: false };
            }
            return field;
        });

        console.log('Cleared IFSC-related fields.');
    }

    // Handle Disbursement Type Change
    handleDisbursementTypeChange(selectedValue) {
        console.log(`Disbursement Type Selected: ${selectedValue}`);

        // Reset `showBeneficiaryDetails` before checking condition
        this.showBeneficiaryDetails = false;

        // If no value, clear and exit
        if (!selectedValue || selectedValue.trim() === '') {
            console.log('Disbursement Type is empty, hiding Beneficiary Details.');
            this.fieldDetailsBeneficiary = [];
            return;
        }

        // Show the Beneficiary Details section only for RTGS, NEFT, IMPS
        if (['RTGS', 'NEFT', 'IMPS','IFT'].includes(this.disbursementType)) {
            this.showBeneficiaryDetails = true;
            this.showChequeDDDetails = false;
            console.log(`Previous Disbursement Type Id: ${this.previouseDisType}`);
            //Sanwar - Start
            if(this.previouseDisType && this.previouseDisParty && this.disbursementType == this.previouseDisType && this.disbursementParty == this.previouseDisParty){
                this.fetchBeneficiaryDetailsforEdit();
            }
            else{
                this.fetchBeneficiaryDetails();
            }
            //Sanwar - End
        } else if (['CHEQUE', 'DD - DEMAND DRAFT'].includes(this.disbursementType)) {
            this.showChequeDDDetails = true;
            this.showBeneficiaryDetails = false;
            //Sanwar - Start
            if(this.previouseDisType && this.previouseDisParty && this.disbursementType == this.previouseDisType && this.disbursementParty == this.previouseDisParty){
                this.fetchChequeDDDetailsforEdit();
            }
            else{
                this.fetchChequeDDDetails();
            }
            //Sanwar - End
            
        }/*else {
            this.fieldDetailsBeneficiary = []; // Clear beneficiary details
            this.fieldDetailsChequeDD = [];
            this.showBeneficiaryDetails = false; // Explicitly hide
            this.showChequeDDDetails = false;
        }*/

        console.log(`Beneficiary Details Visibility: ${this.showBeneficiaryDetails}`);
        console.log(`ChequeDD Details Visibility: ${this.showChequeDDDetails}`);
    }

    // Fetch Beneficiary Details Fields from Apex on creation
    fetchBeneficiaryDetails() {
        console.log('AAAAAAAAAAAAAAA');
        this.fieldDetailsBeneficiary = []; // Clear previous values
        getDetailsForPayment({ screenName: 'Payment-Beneficiary Details', loanId: this.recordId, formIdentifier: 'Payment Details Accordian' })
            .then(async data => {
                console.log('Fetched Beneficiary Fields:', JSON.stringify(data));

                let newFields = await Promise.all(data.map(async item => {
                    let fieldData = {
                        id: item.fieldApiName,
                        label: item.fieldLabel,
                        value: item.fieldValue, // Default value
                        isDisabled: item.isDisabled,
                        isPicklist: item.fieldType === 'Picklist',
                        isDate: item.fieldType === 'Date',
                        isNumber: item.fieldType === 'Number',
                        isTextarea: item.fieldType === 'Textarea',
                        isLookup: item.isLookup,
                        isText: item.fieldType === 'Text',
                        isApplicationApplicant: false, // Default false
                        isCustomerNameText: false, // Default false
                        isCustomerType: item.fieldApiName === 'Customer_Type__c',
                        isAutoFilledBankDetail: ['IFSC__c', 'Bank__c', 'Bank_Branch__c', 'Account_Number__c', 'Account_Holder_Name__c', 'Bank_Details__c'].includes(item.fieldApiName),
                        isVisible: true,  // NEW: Ensures no field gaps,
                        isMandatory: item.isMandatory,
                        isIFSCSearchable: false, // Default is false
                        picklistOptions: []
                    };

                    // Hide `Customer_Name__c` when Disbursement Party = Customer & Type = RTGS/NEFT/IMPS
                    if (this.isCustomerRTGSNEFTIMPS() && fieldData.id === 'Customer_Name__c') {
                        fieldData.isVisible = false; // Hide it instead of rendering
                    }
                    // required Mobile Number when Disbursement Party = Third party & Type = IMPS 

                    if (this.isThirdPartyWithIMPS() && fieldData.id === 'Mobile_Number__c') {
                        fieldData.isMandatory = true;
                    }
                    //Sanwar
                    if (this.isVendorWithIMPS() && fieldData.id === 'Mobile_Number__c') {
                        fieldData.isMandatory = true;
                    }
                    // Hide `Application_Applicant__c` when Disbursement Party = Third party & Type = RTGS/NEFT/IMPS
                    if (this.isThirdPartyRTGSNEFTIMPS() &&(fieldData.id === 'Application_Applicant__c' || fieldData.id === 'Vendor_Name__c')) {//Sanwar
                        fieldData.isVisible = false; // Hide it instead of rendering
                    }
                    //Sanwar Start
                    if (this.isVendorRTGSNEFTIMPS() &&(fieldData.id === 'Application_Applicant__c' || fieldData.id === 'Customer_Name__c')) {
                        fieldData.isVisible = false; // Hide it instead of rendering
                    }//Sanwar End

                    if (this.isCustomerRTGSNEFTIMPS() && fieldData.id === 'Account_Type__c') {
                        fieldData.isVisible = false; // Hide it instead of rendering
                    }
                    //Sanwar
                    if (this.isCustomerRTGSNEFTIMPS() && fieldData.id === 'Vendor_Name__c') {
                        fieldData.isVisible = false; // Hide it instead of rendering
                    }
                    
                    // Convert `Application_Applicant__c` to Dropdown when Customer + RTGS/NEFT/IMPS
                    if (fieldData.id === 'Application_Applicant__c' && this.isCustomerRTGSNEFTIMPS()) {
                        fieldData.isApplicationApplicant = true;
                        fieldData.isCustomerNameText = false;
                        await this.fetchApplicants(); // Fetch applicant picklist values
                    }
                    console.log('this.isThirdPartyRTGSNEFTIMPS()::' + this.isThirdPartyRTGSNEFTIMPS());

                    if (fieldData.id === 'Bank_Master__c' && fieldData.isLookup &&(this.isThirdPartyRTGSNEFTIMPS() || this.isVendorRTGSNEFTIMPS())) {//Sanwar
                        fieldData.isVisible = true;  // Show the lookup field
                        fieldData.isIFSCSearchable = true;
                    }
                    /*if (fieldData.id === 'IFSC__c' && this.isVendorRTGSNEFTIMPS()) {//Sanwar COMMENTING this as vendor will aslo have IFSC
                        fieldData.isVisible = false;  // Keep only the text field
                    }*/



                    // Convert `Customer_Name__c` to Open Text when Third party + RTGS/NEFT/IMPS
                    if (fieldData.id === 'Customer_Name__c' && (this.isThirdPartyRTGSNEFTIMPS() || this.isVendorRTGSNEFTIMPS())) {//Sanwar
                        fieldData.isCustomerNameText = true;
                        fieldData.isApplicationApplicant = false;

                    }

                    if ((this.isThirdPartyRTGSNEFTIMPS() || this.isVendorRTGSNEFTIMPS()) && fieldData.id === 'Customer_Type__c') {//Sanwar
                        fieldData.value = 'NA'; // Hide it from rendering
                    }

                    if (fieldData.fieldApiName === 'Customer_Type__c') {
                        console.log('Customer_Type__c found in API response.');
                    }
                    // **EXPLICITLY HIDE `Bank_Details__c` FROM UI**
                    if (item.fieldApiName === 'Bank_Details__c') {
                        fieldData.isVisible = false; // Hide it from rendering
                    }

                    if (this.isThirdPartyRTGSNEFTIMPS() || this.isVendorRTGSNEFTIMPS() ){
                        if (fieldData.id === 'Bank__c' || fieldData.id === 'Bank_Branch__c') {
                            fieldData.isMandatory = false; 
                            fieldData.isDisabled = true; 
                        }
                        if (fieldData.id === 'IFSC__c') {
                            fieldData.isMandatory = true; 
                        }
                    }

                    if (fieldData.isPicklist) {
                        fieldData.picklistOptions = await this.getPicklistOptionsFromApex(true, item.storageObject, item.fieldApiName);
                    }
                    console.log('fieldData:: ' + JSON.stringify(fieldData));
                    return fieldData;

                }));


                // **Final Filtering to Remove Non-Visible Fields (Ensuring Correct Layout)**
                this.fieldDetailsBeneficiary = newFields.filter(f => f.isVisible);//Sanwar(18/12/2025)
                // this.fieldDetailsBeneficiary = [...newFields];//Sanwar(18/12/2025)


                console.log('Final Beneficiary Fields:', JSON.stringify(this.fieldDetailsBeneficiary));
            })
            .catch(error => {
                console.error('Error fetching Beneficiary Details:', error);
            });
    }

    // Fetch ChequeDD Details Fields from Apex
    fetchChequeDDDetails() {
        getDetailsForPayment({ screenName: 'Payment-Cheque/DD Details', loanId: this.recordId, formIdentifier: 'Payment Details Accordian' })
            .then(async data => {
                console.log('Fetched ChequeDD Fields:', JSON.stringify(data));

                let newFields = await Promise.all(data.map(async item => {
                    let fieldData = {
                        id: item.fieldApiName,
                        label: item.fieldLabel,
                        value: item.fieldValue, // Default value
                        isDisabled: item.isDisabled,
                        isPicklist: item.fieldType === 'Picklist',
                        isDate: item.fieldType === 'Date',
                        isNumber: item.fieldType === 'Number',
                        isTextarea: item.fieldType === 'Textarea',
                        isLookup: item.isLookup,
                        isApplicationApplicant: false, // Default false
                        isFavouringNameText: false, // Default false
                        isVisible: true,  // NEW: Ensures no field gaps
                        isMandatory: item.isMandatory,
                        picklistOptions: []
                    };
                    //sanwar(11/12/2025)
                    // Hide `Favoring_Name__c` when Disbursement Party = Customer & Type = Cheque/DD
                    // if (this.isCustomerChequeDD() && fieldData.id === 'Favoring_Name__c') {
                    //     fieldData.isVisible = false; // Hide it instead of rendering
                    // }

                    // Hide `Application_Applicant__c` when Disbursement Party = Third party & Type = Cheque/DD
                    if ((this.isThirdPartyChequeDD() || this.isCustomerChequeDD()) && fieldData.id === 'Application_Applicant__c') {//sanwar(11/12/2025)
                        fieldData.isVisible = false; // Hide it instead of rendering
                    }
                    //Sanwar
                    if ((this.isVendorChequeDD()) && fieldData.id === 'Application_Applicant__c') {
                        fieldData.isVisible = false; // Hide it instead of rendering
                    }

                    // Convert `Application_Applicant__c` to Dropdown when Customer + Cheque/DD//sanwar(11/12/2025)
                    // if (fieldData.id === 'Application_Applicant__c' && this.isCustomerChequeDD()) {
                    //     fieldData.isApplicationApplicant = true;
                    //     fieldData.isFavouringNameText = false;
                    //     await this.fetchApplicants();
                    // }

                    // Convert `Favoring_Name__c` to Open Text when Third party + Cheque/DD
                    if (fieldData.id === 'Customer_Name__c' && this.isThirdPartyChequeDD()) {
                        fieldData.isCustomerNameText = true;
                        fieldData.isApplicationApplicant = false;
                    }
                    //Sanwar
                    if (fieldData.id === 'Customer_Name__c' && this.isVendorChequeDD()) {
                        fieldData.isCustomerNameText = true;
                        fieldData.isApplicationApplicant = false;
                    }

                    if (fieldData.isPicklist) {
                        fieldData.picklistOptions = await this.getPicklistOptionsFromApex(true, item.storageObject, item.fieldApiName);
                    }

                    return fieldData;
                }));

                // **Final Filtering to Remove Non-Visible Fields (Ensuring Correct Layout)**
                this.fieldDetailsChequeDD = newFields.filter(f => f.isVisible);
                //this.fieldDetailsChequeDD = [...newFields]; // Clone to trigger reactivity
                console.log('Updated Cheque Fields:', JSON.stringify(this.fieldDetailsChequeDD));
            })
            .catch(error => {
                console.error('Error fetching Cheque Details:', error);
            });
    }

    totalAmountWithOutVas = 0;
    fetchPaymentTableRecords() {
        getPaymentTableRecords({ loanId: this.recordId })
            .then(result => {
                console.log('Fetched Payment Table Data:', JSON.stringify(result));

                this.paymentTableData = [];

                // Add Insurance Record separately (DO NOT include in payment calculation)
                if (result.insuranceRecord) {
                    this.paymentTableData.push(result.insuranceRecord);
                }

                // Add Loan Transaction Payment Records
                if (result.paymentRecords) {
                    this.paymentTableData = [...this.paymentTableData, ...result.paymentRecords];
                    this.transactionId = this.paymentTableData[0].transactionId;

                    //formatting input date date when enableRefresh is true because of the format issue in the input tag date in HTML
                    this.paymentTableData = this.paymentTableData.map(row => ({
                        ...row, 
                        disbursementDateForDisplay: !row.enableRefresh ? this.formatDateForDisplay(row.disbursementDate) : this.formatDateForDisplay(row.disbursementDate)}));

                    console.log('this.paymentTableData after the date format  '+JSON.stringify(this.paymentTableData))
                    
                    // Calculate total amount for payment records ONLY (ignore insurance)
                    //this.totalPaymentAmount = result.paymentRecords.reduce((sum, record) => sum + (parseFloat(record.amount) || 0), 0);
                    //console.log('Total Payment Amount (excluding insurance):', this.totalPaymentAmount);
                }

                this.totalPaymentAmount =0;
                this.totalAmountWithOutVas =0;
                this.paymentTableData.forEach(field => {
                    if(field.disbursementParty != 'VAS' && field.qdpStatus != 'Rejected'){
                        this.totalAmountWithOutVas += field.amount;
                        console.log('Total ---> ',this.totalAmountWithOutVas);
                        this.totalPaymentAmount += field.amount;
                    }

                });
                console.log('paymentTableData>>'+JSON.stringify(this.paymentTableData));

                console.log('Total Payment Amount (excluding insurance):', this.totalPaymentAmount);
            })
            .catch(error => {
                console.error('Error fetching Payment Table Records:', error);
            });
    }

    fetchBankDetails() {
        console.log('fetch detail');
        getBankDetails({ applicantId: this.selectedApplicantId, disbursementParty: this.disbursementParty })
            .then(result => {
                console.log('below is detail data');
                console.log('get bank detail ',result);
                if (result && result.length > 0) {
//prachi's changes start
                    console.log('inside the result console');
                    let accNum = result[0].Account_Number__c || '';
                     const isMasked = /^[Xx*]+$/.test(accNum) || accNum.includes('X') || accNum.includes('*') || accNum.includes('x');
                    this.bankDetails = result.map(bank => ({
                        id: bank.Id,
                        bankName: bank.Name || '',  // Extracting Bank Name
                        customerName: bank.Account_Holder_Name__c || '',  // Extracting Account Holder Name
                        branchName: bank.Bank_Master__r?.Branch_Name__c || '',  // Extracting Branch Name
                        branchLocation: bank.Bank_Master__r?.Branch_Location__c || '',  // Extracting Branch Location,
                        ifsc: bank.Bank_Master__r?.IFSC__c || '',
                        isRepayment: bank.Is_Repayment_Account__c || '',
                        accountNumber: bank.Account_Number__c || '',
                        micr: bank.Bank_Master__r?.MICR__c || '',
                        accountType: bank.Account_Type__c || '',
                        mobileNumber: bank.Application_Applicant__r?.Mobile_Number__c || ''
                    }));
                    console.log('this.bankDetails:: ' + JSON.stringify(this.bankDetails));
                    this.showBankModal = true;
                    this.showBankDetail = false;
                    this.showCreateBank = false;
                    //prachi's changes end
                } else {
                    //sanwar 31/12/2025
                    // if(['Seller', 'Builder', 'Builder-APF'].includes(this.disbursementParty)){
                    //     this.showBankModal = true;
                    //     this.showCreateBank = true;
                    //     this.showBankDetail = false;
                    // } else {
                        this.showBankModal = false;
                        this.showCreateBank = false;
                        this.showBankDetail = false;
                        this.bankDetails = []; // Clear previous data if no bank details found


                        this.fieldDetailsBeneficiary = this.fieldDetailsBeneficiary.map(field => {
                            if (field.id === 'IFSC__c') {
                                return { ...field, value: '', isDisabled: true };
                            } else if (field.id === 'Bank__c') {
                                return { ...field, value: '', isDisabled: true };
                            } else if (field.id === 'Bank_Branch__c') {
                                return { ...field, value: '', isDisabled: true };
                            } else if (field.id === 'Account_Number__c') {
                                return { ...field, value: '', isDisabled: true };
                            } else if (field.id === 'Account_Holder_Name__c') {
                                return { ...field, value: '', isDisabled: true };
                            } else if (field.id === 'Bank_Details__c') {
                                return { ...field, value: '', isDisabled: true };
                            }
                            return field;
                        });

                        // **Ensure UI reactivity**
                        this.fieldDetailsBeneficiary = [...this.fieldDetailsBeneficiary];

                        console.log('------ ' + JSON.stringify(this.fieldDetailsBeneficiary));
                        this.showToast('Warning', `No bank details found for selected ${this.disbursementParty}`, 'warning');//sanwar 31/12/2025
                    // }
                    
                }
            })
            .catch(error => {
                console.error('Error fetching bank details:', error.body.message);
            });
    }

    // Close Modal
    closeBankModal() {
        this.showBankModal = false;
        this.showCreateBank = false;
        this.showBankDetail = false;
    }

    handleBankSelection(event) {
        const selectedBankId = event.target.value;
        console.log(`Selected Bank ID: ${selectedBankId}`);
        this.selectedCusBankDetailId = selectedBankId;

        // Find the selected bank details
        const selectedBank = this.bankDetails.find(bank => bank.id === selectedBankId);
        console.log('Selected Bank Details:', JSON.stringify(selectedBank));
        console.log('Field detail beneficiaryy ', this.fieldDetailsBeneficiary);
        if (selectedBank) {
            // Update Beneficiary Details Fields
            this.fieldDetailsBeneficiary = this.fieldDetailsBeneficiary.map(field => {
                if (field.id === 'IFSC__c') {
                    return { ...field, value: selectedBank.ifsc, isDisabled: true };
                } else if (field.id === 'Bank__c') {
                    return { ...field, value: selectedBank.bankName, isDisabled: true };
                } else if (field.id === 'Bank_Branch__c') {
                    return { ...field, value: selectedBank.branchName, isDisabled: true };
                } else if (field.id === 'Account_Number__c') {
                    return { ...field, value: selectedBank.accountNumber, isDisabled: true };//31/12/2025
                } else if (field.id === 'Account_Holder_Name__c') {
                    return { ...field, value: selectedBank.customerName, isDisabled: true };
                } else if (field.id === 'Bank_Details__c') {
                    return { ...field, value: selectedBank.id, isDisabled: true };
                } else if (field.id === 'Mobile_Number__c') {
                    return { ...field, value: selectedBank.mobileNumber, isDisabled: true };
                }
                return field;
            });

            // **Ensure UI reactivity**
            this.fieldDetailsBeneficiary = [...this.fieldDetailsBeneficiary];
            this.showBankModal = false;
            console.log('Updated fieldDetailsBeneficiary:', JSON.stringify(this.fieldDetailsBeneficiary));
        }
    }

    savePayment() {
        let paymentRecordData = {};
        let beneficiaryData = {};
        let chequeDDData = {};
        let missingFields = [];

        console.log('recordID:: ', this.recordId);

        if (this.isFavouringUploadRequired && !this.showPreview) {
            this.showToast('Error', 'Upload Favouring document is required for Third party disbursement.', 'error');
            return;
        }

        // Add record ID if updating
        if (this.isEditing) {
            paymentRecordData.Id = this.editingRecordId;
        }

        this.totalAmountWithOutVas = 0;
        this.paymentTableData.forEach(field => {
            if(field.id != this.editingRecordId && field.disbursementParty != 'VAS' && field.qdpStatus != 'Rejected'){
                this.totalAmountWithOutVas += field.amount;
            }
        });

        // Collect fields from Payment Section
        this.fieldDetailsPayment.forEach(field => {
            //console.log('field: '+JSON.stringify(field));
            paymentRecordData[field.id] = field.value;
            
            // **Check Required Fields**
            if (field.isMandatory && !field.value) {
                missingFields.push(field.label);
            }

            if (field.id == 'Net_Amount__c') {
                this.totalAmountWithOutVas += parseInt(field.value);
            }
        });

        console.log('this.totalAmountWithOutVas: '+this.totalAmountWithOutVas);
        console.log('this.totalDisbursedAmount: '+this.totalDisbursedAmount);

        if(this.totalAmountWithOutVas > this.totalDisbursedAmount){
            this.showToast('Error', 'Disbursement Amount should be less than Total Disbursed Amount.', 'error');
            return;
        }

        // Collect fields from Beneficiary Section
        let isIMPSError = false;
        if (this.showBeneficiaryDetails) {
            this.fieldDetailsBeneficiary.forEach(field => {
                console.log('FIeld id ',field.id);
                console.log('fieldid ',field.Id);
                if(field.id != 'Application_Applicant__c'){
                    beneficiaryData[field.id] = field.value || ''; // Store all values, even blank
                }
                //sanwar(12/12/2025)
                else if(field.id == 'Application_Applicant__c'){
                    getObjectApiNameFromId({ recordId: this.selectedApplicantId })
                    .then(objectApiName => {
                        console.log('Object Name:', objectApiName);

                        if (objectApiName != 'Application_Collateral__c') {
                    beneficiaryData[field.id] = field.value || '';
                }
                    })
                    .catch(error => {
                        console.error(error);
                    });
                }
                
                if (this.disbursementType == 'IMPS' && field.id == 'Mobile_Number__c' && (field.value === null || field.value.trim() === '')) {
                    isIMPSError = true;
                }

                // **Check Required Fields**
                if (field.isMandatory && (field.value === null || field.value.trim() === '')) {
                    missingFields.push(field.label);
                }
            });
        }

        if(isIMPSError == true){
            this.showToast('Error', 'Mobile number is required for IMPS.', 'error');
            return;
        }
        if(this.showChequeDDDetails) {
            console.log('4');
            console.log('4>>',this.fieldDetailsChequeDD);
            this.fieldDetailsChequeDD = this.fieldDetailsChequeDD.filter(f => f.isVisible);//Sanwar(19/12/2025)
            console.log('At 1698',this.fieldDetailsChequeDD);
            this.fieldDetailsChequeDD.forEach(field => {
                chequeDDData[field.id] = field.value || '';
                // **Check Required Fields**
                const value = field.value ? String(field.value).trim() : '';//sanwar(19/12/2025)

                if (field.isMandatory && value === '') {//sanwar(19/12/2025)
                    missingFields.push(field.label);
                }
            });
        }

        console.log('missing fields:: ' + JSON.stringify(missingFields));
        // if (missingFields.length > 0) {
        //     this.showToast('Error', 'Please fill the required fields', 'error');
        //     return; // Stop execution
        // }

        // Debug Final Payload
        console.log("Final Payload Before Sending:", JSON.stringify({
            paymentRecordData,
            beneficiaryData,
            chequeDDData,
            loanId: this.recordId
        }));

        // Call Apex Method Correctly
        setTimeout(() => {//sanwar(17/112/2025)
        savePaymentTransaction({
            paymentRecordData: paymentRecordData,
            beneficiaryData: beneficiaryData,
            chequeDDData: chequeDDData,
                loanId: this.recordId,
                selectedCusBankDetailId : this.selectedCusBankDetailId
        })
            .then(result => {
                if (result === 'SUCCESS') {
                    this.showToast('Success', 'Payment Record Saved Successfully', 'success');

                    // Refresh Data (if required)
                    this.fetchPaymentTableRecords();
                    // **RESET THE FORM** (Clearing all fields)
                    this.isEditing = false;
                    this.editingRecordId = '';
                    this.fieldDetailsPayment = [];
                    this.fieldDetailsBeneficiary = [];
                    this.fieldDetailsChequeDD = [];
                        this.disbursementParty = '';//Sanwar(18/12/2025)
                        this.disbursementType = '';//Sanwar(18/12/2025)
                        this.previouseDisType = '';//Sanwar(18/12/2025)
                        this.previouseDisParty = '';//Sanwar(18/12/2025)
                    // **Re-fetch Fresh Fields**
                    this.fetchScreenFieldsForDisbursementScreen();
                    this.fetchScreenFieldsForPaymentScreen();
                    // Close Payment Form after Save
                    this.showPaymentForm = false;
                    this.isFileUploaded = false;

                } else {
                    this.showToast('Error', result, 'error');
                }
            })
            .catch(error => {
                console.error("Error Saving Payment Record:", error);
                this.showToast('Error', 'Failed to save payment record', 'error');
            });
        }, 1000);
    }

    // Show Toast Message
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    @track selectedDocumentId;
    uploadFavouring(event) {
        // this.selectedDocumentId = event.target.dataset.id;
        this.selectedDocumentId = this.editingRecordId;
        console.log('Selected Document ID:', this.selectedDocumentId);
        console.log('this.editingRecordId  '+this.editingRecordId)
        this.template.querySelector('.hidden-input').click();
    }

    createBankDetail(event){
         getDetailsForBank({loanId: this.recordId, formIdentifier: 'Bank Detail' })
         .then(async result => {
            console.log('Apex Response:', JSON.stringify(result));

            let updatedFields = await Promise.all(result.map(async item => {
                console.log(`Processing Field: ${item.fieldApiName}, Type: ${item.fieldType}`);

                let fieldData = {
                    id: item.fieldApiName,
                    label: item.fieldLabel,
                    value: '', // Initially empty
                    isDisabled: item.isDisabled,
                    isPicklist: item.fieldType === 'Picklist',
                    isDate: item.fieldType === 'Date',
                    isNumber: item.fieldType === 'Number',
                    isTextarea: item.fieldType === 'Textarea',
                    isCheckBox: item.fieldType === 'Checkbox',
                    isIFSCSearchable: item.fieldApiName === 'Bank_Master__c',
                    isPaymentSequence: false,
                    isLookup: item.isLookup,
                    picklistOptions: [],
                    isMandatory: item.isMandatory
                };

                if (fieldData.isPicklist) {
                    fieldData.picklistOptions = await this.getPicklistOptionsFromApex(true, item.storageObject, item.fieldApiName);
                }

                return fieldData;
            }));


            this.fieldDetailsBank = [];
            this.fieldDetailsBank = [...this.fieldDetailsBank, ...updatedFields];
            console.log('bank detail ',this.fieldDetailsBank);
            this.showBankDetail = true;
         })
    }


    handleFileSelection(event) {
        const file = event.target.files[0];
        if (!file) return;

        this.isLoading = true;
        console.log('Selected Document ID:', this.selectedDocumentId);

        this.readFile(file)
            .then(({ base64Data, fileName, fileType }) => {
                return this.uploadToApex(base64Data, fileName, fileType, this.recordId, this.selectedDocumentId);
            })
            .then((contentId) => {
                console.log('Received Content ID:', contentId);
                if (contentId) {
                    return this.fetchUploadedFileDetails(contentId); // Pass contentId to fetch details
                }
            })
            .catch(error => {
                console.error('File Upload Error:', error);
                this.showToast('Error', 'File upload failed. Please retry.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
                const fileInput = this.template.querySelector('.hidden-input');
                if (fileInput) {
                    fileInput.value = null; // Reset input field to allow re-selection
                }
            });
    }

    async uploadToApex(base64Data, fileName, fileType, recordId, documentId) {
        try {
            console.log('Uploading file to Apex...');
            const contentId = await uploadFile({ base64Data, fileName, fileType, recordId, selecteddocCheckId: documentId });
            if (contentId) {
                this.uploadedContentDocumentId = contentId;
                this.showPreview = true;
                this.showToast('Success', 'File uploaded successfully!', 'success');
                return contentId;
            } else {
                throw new Error('File upload failed');
            }
        } catch (error) {
            console.error('Upload Failed:', error);
            throw error;
        }
    }

    async fetchUploadedFileDetails(contentId) {
        try {
            console.log('Fetching uploaded document details for:', contentId);
            const docData = await getUploadedDocument({ contentId });
            if (docData && docData.Content_Document_Id__c) {
                this.uploadedContentDocumentId = docData.Content_Document_Id__c;
                this.showPreview = true;
                console.log('Document ID:', this.uploadedContentDocumentId);
            }
        } catch (error) {
            console.error('Error fetching document:', error);
        }
    }

    handlePreview() {
        getUploadedDocumentPerLT({ loanTxnId: this.editingRecordId })
            .then(result => {
                if (!result) {
                    this.showToast('Error', 'No file available for preview', 'error');
                    return;
                }

                this.uploadedContentDocumentId = result; 

                this[NavigationMixin.Navigate]({
                    type: 'standard__namedPage',
                    attributes: {
                        pageName: 'filePreview'
                    },
                    state: {
                        selectedRecordId: result
                    }
                });
            })
            .catch(error => {
                console.error('Error fetching document:', error);
                this.showToast('Error', 'Failed to fetch document', 'error');
            });
    }


    readFile(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();

            reader.onload = () => {
                resolve({
                    base64Data: reader.result.split(',')[1],
                    fileName: file.name,
                    fileType: file.type
                });
            };

            reader.onerror = (error) => {
                console.error('FileReader Error:', error);
                reject(error);
            };

            try {
                reader.readAsDataURL(file);
            } catch (error) {
                console.error('File Read Error:', error);
                reject(error);
            }
        });
    }

    handleSave(event){
        console.log('handle Save',event);
        console.log('bank field details ',this.fieldDetailsBank);
        console.log('field detail beneficiary ', this.fieldDetailsBeneficiary);
        console.log('applicant id',this.selectedApplicantId);
        let bankRecordData = {};
        let missingFields = [];

        this.fieldDetailsBank.forEach(field => {
            //console.log('field: '+JSON.stringify(field));
            bankRecordData[field.id] = field.value;
            
            // **Check Required Fields**
            if (field.isMandatory && !field.value) {
                missingFields.push(field.label);
                console.log('Missing Field , ',field.label);
            }
        });
        if (missingFields.length > 0) {
            this.showToast('Error', 'Please fill the required fields', 'error');
            return; // Stop execution
        }

        console.log('final data');
        console.log('final data before save',bankRecordData);

        saveBankDetailRecord({bankRecords : bankRecordData , applicantId : this.selectedApplicantId})
        .then(bankRecId => {
                console.log('Data created');
                //sanwar(12/12/2025)
                getObjectApiNameFromId({ recordId: this.selectedApplicantId })
                    .then(objectApiName => {
                        console.log('Object Name:', objectApiName);
                        if(objectApiName === 'Application_Collateral__c'){
                    getBankDetailsForBuilderApf({ applicantCollateralId: this.selectedApplicantId })
                    .then(result => {
                        console.log('inside getBankdetail');
                     if (result && result.length > 0) {
                        this.bankDetails = result.map(bank => ({
                            id: bank.Id,
                            bankName: bank.Name || '',  // Extracting Bank Name
                            customerName: bank.Account_Holder_Name__c || '',  // Extracting Account Holder Name
                            branchName: bank.Bank_Master__r?.Branch_Name__c || '',  // Extracting Branch Name
                            branchLocation: bank.Bank_Master__r?.Branch_Location__c || '',  // Extracting Branch Location,
                            ifsc: bank.Bank_Master__r?.IFSC__c || '',
                            isRepayment: bank.Is_Repayment_Account__c || '',
                            accountNumber: bank.Account_Number__c || '',
                            micr: bank.Bank_Master__r?.MICR__c || '',
                            accountType: bank.Account_Type__c || '',
                            mobileNumber: bank.Application_Applicant__r?.Mobile_Number__c || ''
                        }));
                        const selectedBank = this.bankDetails.find(bank => bank.id === bankRecId);
                        console.log('Selected Bank Details:', JSON.stringify(selectedBank));
                        console.log('Field detail beneficiaryy ', this.fieldDetailsBeneficiary);
                        if (selectedBank) {
                            // Update Beneficiary Details Fields
                            this.fieldDetailsBeneficiary = this.fieldDetailsBeneficiary.map(field => {
                                if (field.id === 'IFSC__c') {
                                    return { ...field, value: selectedBank.ifsc, isDisabled: true };
                                } else if (field.id === 'Bank__c') {
                                    return { ...field, value: selectedBank.bankName, isDisabled: true };
                                } else if (field.id === 'Bank_Branch__c') {
                                    return { ...field, value: selectedBank.branchName, isDisabled: true };
                                } else if (field.id === 'Account_Number__c') {
                                    return { ...field, value: selectedBank.accountNumber, isDisabled: true };
                                } else if (field.id === 'Account_Holder_Name__c') {
                                    return { ...field, value: selectedBank.customerName, isDisabled: true };
                                } else if (field.id === 'Bank_Details__c') {
                                    return { ...field, value: selectedBank.id, isDisabled: true };
                                } else if (field.id === 'Mobile_Number__c') {
                                    return { ...field, value: selectedBank.mobileNumber, isDisabled: true };
                                }
                                return field;
                            });

                        // **Ensure UI reactivity**
                        this.fieldDetailsBeneficiary = [...this.fieldDetailsBeneficiary];
                        this.showBankModal = false;
                        this.showToast('Success', 'Bank Record Saved Successfully', 'success');
                        this.isEditing = false;
                        this.editingRecordId = '';
                        this.fieldDetailsBank = [];
                        this.isFileUploaded = false;
                        console.log('Updated fieldDetailsBeneficiary:', JSON.stringify(this.fieldDetailsBeneficiary));
                    }
                     }
                     });
                }
                else if (bankRecId) {
                    getBankDetails({ applicantId: this.selectedApplicantId })
                    .then(result => {
                        console.log('inside getBankdetail');
                     if (result && result.length > 0) {
                        this.bankDetails = result.map(bank => ({
                            id: bank.Id,
                            bankName: bank.Name || '',  // Extracting Bank Name
                            customerName: bank.Account_Holder_Name__c || '',  // Extracting Account Holder Name
                            branchName: bank.Bank_Master__r?.Branch_Name__c || '',  // Extracting Branch Name
                            branchLocation: bank.Bank_Master__r?.Branch_Location__c || '',  // Extracting Branch Location,
                            ifsc: bank.Bank_Master__r?.IFSC__c || '',
                            isRepayment: bank.Is_Repayment_Account__c || '',
                            accountNumber: bank.Account_Number__c || '',
                            micr: bank.Bank_Master__r?.MICR__c || '',
                            accountType: bank.Account_Type__c || '',
                            mobileNumber: bank.Application_Applicant__r?.Mobile_Number__c || ''
                        }));
                        const selectedBank = this.bankDetails.find(bank => bank.id === bankRecId);
                        console.log('Selected Bank Details:', JSON.stringify(selectedBank));
                        console.log('Field detail beneficiaryy ', this.fieldDetailsBeneficiary);
                        if (selectedBank) {
                            // Update Beneficiary Details Fields
                            this.fieldDetailsBeneficiary = this.fieldDetailsBeneficiary.map(field => {
                                if (field.id === 'IFSC__c') {
                                    return { ...field, value: selectedBank.ifsc, isDisabled: true };
                                } else if (field.id === 'Bank__c') {
                                    return { ...field, value: selectedBank.bankName, isDisabled: true };
                                } else if (field.id === 'Bank_Branch__c') {
                                    return { ...field, value: selectedBank.branchName, isDisabled: true };
                                } else if (field.id === 'Account_Number__c') {
                                    return { ...field, value: selectedBank.accountNumber, isDisabled: true };
                                } else if (field.id === 'Account_Holder_Name__c') {
                                    return { ...field, value: selectedBank.customerName, isDisabled: true };
                                } else if (field.id === 'Bank_Details__c') {
                                    return { ...field, value: selectedBank.id, isDisabled: true };
                                } else if (field.id === 'Mobile_Number__c') {
                                    return { ...field, value: selectedBank.mobileNumber, isDisabled: true };
                                }
                                return field;
                            });

                        // **Ensure UI reactivity**
                        this.fieldDetailsBeneficiary = [...this.fieldDetailsBeneficiary];
                        this.showBankModal = false;
                        this.showToast('Success', 'Bank Record Saved Successfully', 'success');
                        this.isEditing = false;
                        this.editingRecordId = '';
                        this.fieldDetailsBank = [];
                        this.isFileUploaded = false;
                        console.log('Updated fieldDetailsBeneficiary:', JSON.stringify(this.fieldDetailsBeneficiary));
                    }
                     }
                     });
                    

                } else {
                    this.showToast('Error', result, 'error');
                }
            })
        .catch(error => {
                        console.error(error);
                    });
            })
        .catch(error => {
            console.error("Error Saving Payment Record:", error);
            this.showToast('Error', 'Failed to save payment record', 'error');
        });


    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }


    handleEdit(event) {
        this.isLoading = true;
        this.isEditing = true;
        this.editingRecordId = event.target.dataset.id;

        console.log('Result ',event.target);
        console.log(`Editing Payment Record ID: ${this.editingRecordId}`);

        // First, fetch Payment Details
        getPaymentRecord({
            screenName: 'Payment Details',
            loanId: this.recordId,
            formIdentifier: 'Payment Details Accordian',
            paymentRecordId: this.editingRecordId
        })
        .then(async result => {
            console.log('Apex Response (Payment Details):', JSON.stringify(result));
            this.showPaymentForm = true;

            let updatedFields = await Promise.all(result.map(async item => {
                console.log(`Processing Field: ${item.fieldApiName}, Type: ${item.fieldType}`);
                //Sanwar - Start
                if(item.fieldApiName == 'Disbursement_Type__c'){
                    this.previouseDisType = item.fieldValue;
                    console.log(`Previous Disbursement : ${this.previouseDisType}`);
                }
                else if(item.fieldApiName == 'Disbursement_Party__c'){
                    this.previouseDisParty = item.fieldValue;
                    console.log(`Previous Disbursement : ${this.previouseDisParty}`);
                } //Sanwar - End
                let fieldData = {
                    id: item.fieldApiName,
                    label: item.fieldLabel,
                    value: item.fieldValue,  // Value coming from Apex
                    isDisabled: item.isDisabled,
                    isPicklist: item.fieldType === 'Picklist',
                    isDate: item.fieldType === 'Date',
                    isNumber: item.fieldType === 'Number',
                    isTextarea: item.fieldType === 'Textarea',
                    isPaymentSequence: false,
                    isLookup: item.isLookup,
                    picklistOptions: [],
                    isMandatory: item.isMandatory
                };

                if (fieldData.isPicklist) {
                    fieldData.picklistOptions = await this.getPicklistOptionsFromApex(true, item.storageObject, item.fieldApiName);
                }

                return fieldData;
            }));

            // Fetch Disbursal Details (Total Fee, Loan Amount)
            return getDisbursalDetails({ loanId: this.recordId }).then(disbursalData => {
                console.log('Fetched Disbursal Data 1392:', JSON.stringify(disbursalData));

                // Update payment details in UI
                this.fieldDetailsPayment = [];
                //var sequence = this.paymentSequence;

                if (this.isEditing) {
                    const existingRec = this.paymentTableData.filter(
                        (elem) => elem.id == this.editingRecordId
                    );

                    //sequence = existingRec[0].paymentSequence;

                    var exisSeq = {
                        id: 'Payment_Sequence__c',
                        label: 'Payment Sequence',
                        value: existingRec[0].paymentSequence,
                        isDisabled: true,
                        isPaymentSequence: true
                    };

                    this.fieldDetailsPayment.push(exisSeq);
                }
                else {
                    this.fieldDetailsPayment.push(this.paymentSequenceField);
                }

                //let totalFee = disbursalData.Total_Fee__c || 0;
                //console.log('totalFee: '+totalFee);
                //console.log('paymentSequence:: ' + sequence);

                // // Ensure Total Fee is 0 if Payment Sequence > 1
                // updatedFields = updatedFields.map(field => {
                //     console.log('1458 field '+JSON.stringify(field));
                //     if (field.id === 'Total_Fee__c') {
                //         return { ...field, value: (sequence === 1 ? totalFee : 0) };
                //     }
                //     return field;
                // });

                //console.log('updatedFields: '+JSON.stringify(updatedFields));

                this.fieldDetailsPayment = [...this.fieldDetailsPayment, ...updatedFields];

                // Extract `Disbursement_Party__c` and `Disbursement_Type__c`
                this.disbursementParty = this.getFieldValue('Disbursement_Party__c');
                this.disbursementType = this.getFieldValue('Disbursement_Type__c');

                console.log(`Disbursement Party: ${this.disbursementParty}`);
                console.log(`Disbursement Type: ${this.disbursementType}`);

                // Determine which additional details to fetch
                if (['RTGS', 'NEFT', 'IMPS','IFT'].includes(this.disbursementType)) {
                    this.showChequeDDDetails = false;
                    this.showBeneficiaryDetails = true;
                    return this.fetchBeneficiaryDetailsforEdit();
                } else if (['CHEQUE', 'DD - DEMAND DRAFT'].includes(this.disbursementType)) {
                    this.showChequeDDDetails = true;
                    this.showBeneficiaryDetails = false;
                    return this.fetchChequeDDDetailsforEdit();
                }
            });
        })
        .catch(error => {
            console.error('Error fetching payment details:', error);
            this.isLoading = false;
        });
    }

    // Fetch Beneficiary Details for Edit
    fetchBeneficiaryDetailsforEdit() {
        getPaymentRecord({
            screenName: 'Payment-Beneficiary Details',
            loanId: this.recordId,
            formIdentifier: 'Payment Details Accordian',
            paymentRecordId: this.editingRecordId
        })
            .then(async data => {
                console.log('Fetched Beneficiary Fields From Edit:', JSON.stringify(data));

                let newFields = await Promise.all(data.map(async item => {
                    let fieldData = {
                        id: item.fieldApiName,
                        label: item.fieldLabel,
                        value: item.fieldValue,
                        isDisabled: item.isDisabled,
                        isPicklist: item.fieldType === 'Picklist',
                        isDate: item.fieldType === 'Date',
                        isNumber: item.fieldType === 'Number',
                        isTextarea: item.fieldType === 'Textarea',
                        isLookup: item.isLookup,
                        isMandatory: item.isMandatory,
                        isVisible: true, // Ensure all fields are visible
                        picklistOptions: [],
                        isApplicationApplicant: false, // Default false
                        isCustomerNameText: false, // Default false
                        isCustomerType: item.fieldApiName === 'Customer_Type__c',
                        isAutoFilledBankDetail: ['IFSC__c', 'Bank__c', 'Bank_Branch__c', 'Account_Number__c', 'Account_Holder_Name__c', 'Bank_Details__c'].includes(item.fieldApiName),
                    };
                    //sanwar 31/12/2025
                    if (item.fieldApiName === 'Bank_Details__c' && item.fieldValue) {
                        this.selectedCusBankDetailId = item.fieldValue;
                        console.log('Selected Bank Detail Id (Edit Mode): ', this.selectedCusBankDetailId);
                    }

                    // **Handle Customer RTGS/NEFT/IMPS Case**
                    if (this.isCustomerRTGSNEFTIMPS()) {
                        if (fieldData.id === 'Customer_Name__c' || fieldData.id === 'Account_Type__c') {
                            fieldData.isVisible = false; // Hide these fields
                        }
                        if (fieldData.id === 'IFSC__c' || fieldData.id === 'Bank__c' || fieldData.id === 'Bank_Branch__c' || fieldData.id === 'Account_Holder_Name__c') {
                            fieldData.isDisabled = true;
                        }//sanwar 31/12/2025
                        if(fieldData.id === 'Account_Number__c'){
                            fieldData.isDisabled = true;
                        }//sanwar 31/12/2025
                        if (fieldData.id === 'Application_Applicant__c') {
                            fieldData.isApplicationApplicant = true; // Show as picklist
                            fieldData.isCustomerNameText = false; // Ensure it's not text
                            await this.fetchApplicants(); // Populate dropdown values
                        }
                    }

                    // **Handle Third party RTGS/NEFT/IMPS Case**
                    if (this.isThirdPartyRTGSNEFTIMPS() || this.isVendorRTGSNEFTIMPS()) {//Sanwar
                        if (fieldData.id === 'Application_Applicant__c') {
                            fieldData.isVisible = false; // Hide the dropdown
                        }
                        if (fieldData.id === 'Customer_Name__c') {
                            fieldData.isCustomerNameText = true; // Show as an input text field
                            fieldData.isApplicationApplicant = false;
                        }
                    }

                    // **EXPLICITLY HIDE `Bank_Details__c` FROM UI**
                    if (item.fieldApiName === 'Bank_Details__c') {
                        fieldData.isVisible = false; // Hide it from rendering
                    }
                    if (this.isThirdPartyRTGSNEFTIMPS() || this.isVendorRTGSNEFTIMPS()){
                        if (fieldData.id === 'Bank__c' || fieldData.id === 'Bank_Branch__c') {
                            fieldData.isMandatory = false; 
                            fieldData.isDisabled = true; 
                        }
                        if (fieldData.id === 'IFSC__c') {
                            fieldData.isMandatory = true; 
                        }
                    }

                    if (fieldData.isPicklist) {
                        fieldData.picklistOptions = await this.getPicklistOptionsFromApex(true, item.storageObject, item.fieldApiName);
                    }

                    return fieldData;
                }));
                this.fieldDetailsBeneficiary = newFields.filter(f => f.isVisible);//Sanwar(18/12/2025)
                // this.fieldDetailsBeneficiary = [...newFields];//Sanwar(18/12/2025)
                this.showBeneficiaryDetails = true;
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching Beneficiary Details:', error);
                this.isLoading = false;
            });
    }

    // Fetch Cheque/DD Details for Edit
    fetchChequeDDDetailsforEdit() {
        getPaymentRecord({
            screenName: 'Payment-Cheque/DD Details',
            loanId: this.recordId,
            formIdentifier: 'Payment Details Accordian',
            paymentRecordId: this.editingRecordId
        })
            .then(async data => {
                console.log('Fetched Cheque/DD Fields:', JSON.stringify(data));

                let newFields = await Promise.all(data.map(async item => {
                    let fieldData = {
                        id: item.fieldApiName,
                        label: item.fieldLabel,
                        value: item.fieldValue,
                        isDisabled: item.isDisabled,
                        isPicklist: item.fieldType === 'Picklist',
                        isDate: item.fieldType === 'Date',
                        isNumber: item.fieldType === 'Number',
                        isTextarea: item.fieldType === 'Textarea',
                        isLookup: item.isLookup,
                        isMandatory: item.isMandatory,
                        isVisible: true,
                        picklistOptions: [],
                        isApplicationApplicant: false, // Default false
                        isFavouringNameText: false // Default false
                    };
                    //sanwar(11/12/2025)
                    // **Hide Favoring Name when Disbursement Party = Customer + Cheque/DD**
                    // if (this.isCustomerChequeDD() && fieldData.id === 'Favoring_Name__c') {
                    //     fieldData.isVisible = false; // Hide it instead of rendering
                    // }

                    // **Hide Application Applicant when Disbursement Party = Third party + Cheque/DD**
                    if ((this.isThirdPartyChequeDD() ||  this.isCustomerChequeDD())&& fieldData.id === 'Application_Applicant__c') {//sanwar(19/12/2025)
                        fieldData.isVisible = false; // Hide it
                    }
                    //Sanwar
                    if (this.isVendorChequeDD() && fieldData.id === 'Application_Applicant__c') {
                        fieldData.isVisible = false; // Hide it
                    }
                    //sanwar(19/12/2025) comment below code
                    // **Convert Application_Applicant__c to Dropdown when Customer + Cheque/DD**
                    // if (fieldData.id === 'Application_Applicant__c' && this.isCustomerChequeDD()) {
                    //     fieldData.isApplicationApplicant = true;
                    //     fieldData.isFavouringNameText = false;
                    //     await this.fetchApplicants(); // Fetch applicant picklist values

                    //     // **Pre-fill existing applicant selection**
                    //     if (this.applicantPicklistOptions.length > 0) {
                    //         let selectedApplicant = this.applicantPicklistOptions.find(app => app.value === fieldData.value);
                    //         if (selectedApplicant) {
                    //             fieldData.value = selectedApplicant.value; // Set pre-selected applicant
                    //         }
                    //     }
                    // }

                    // **Convert Favoring Name to Open Text when Third party + Cheque/DD**
                    if (fieldData.id === 'Customer_Name__c' && this.isThirdPartyChequeDD()) {
                        fieldData.isCustomerNameText = true;
                        fieldData.isApplicationApplicant = false;
                    }
                    //Sanwar
                    if (fieldData.id === 'Customer_Name__c' && this.isVendorChequeDD()) {
                        fieldData.isCustomerNameText = true;
                        fieldData.isApplicationApplicant = false;
                    }

                    if (fieldData.isPicklist) {
                        fieldData.picklistOptions = await this.getPicklistOptionsFromApex(true, item.storageObject, item.fieldApiName);
                    }

                    return fieldData;
                }));

                this.fieldDetailsChequeDD = [...newFields];
                this.showChequeDDDetails = true;
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching Cheque/DD Details:', error);
                this.isLoading = false;
            });
    }

    handleDelete(event) {
        this.isLoading = true;
        const recordId = event.target.dataset.id;
        console.log(`Deleting Payment Record ID: ${recordId}`);

        // Remove from UI
        this.paymentTableData = this.paymentTableData.filter(record => record.id !== recordId);

        // Recalculate total payment amount excluding insurance
        // this.totalPaymentAmount = this.paymentTableData.reduce((sum, record) => {
        //     return sum + (parseFloat(record.amount) || 0);
        // }, 0);

        this.totalPaymentAmount =0;
        this.totalAmountWithOutVas =0;
        this.paymentTableData.forEach(field => {
            if(field.disbursementParty != 'VAS' && field.qdpStatus != 'Rejected'){
                this.totalAmountWithOutVas += field.amount;
                console.log('Total ---> ',this.totalAmountWithOutVas);
                this.totalPaymentAmount += field.amount;
            }

        });

        console.log('Updated Total Payment Amount:', this.totalPaymentAmount);

        // Call Apex method to delete record from Salesforce
        deletePaymentRecord({ paymentRecordId: recordId })
            .then(response => {
                if (response === 'SUCCESS') {
                    console.log('inside::');
                    this.showToast('Success', 'Payment Record Deleted Successfully', 'success');
                    // Refresh the payment table after deletion
                    this.fetchPaymentTableRecords();

                    this.showPaymentForm = false;
                    this.isEditing = false;
                    this.editingRecordId = '';
                    this.fieldDetailsPayment = [];
                    this.fieldDetailsBeneficiary = [];
                    this.fieldDetailsChequeDD = [];
                } else {
                    this.showToast('Error', response, 'error');
                }
            })
            .catch(error => {
                console.error('Error Deleting Payment Record:', error);
                this.showToast('Error', 'Failed to delete payment record', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });

        // // Check Create Payment Button Validation
        // if (this.totalAmountWithOutVas < this.totalDisbursedAmount) {
        //     this.checkCreatePayment = false; // Allow payment creation
        // } else {
        //     this.checkCreatePayment = true; // Prevent payment creation
        // }
    }

   

    updateOnFocusOut(event){
        //event.preventDefault(); 
        const recordId = event.target.dataset.recordid;
        console.log('recordId>>'+recordId);
        const fieldApiName = 'Scheduled_Disbursement_Date__c';
        const fields = {};
        fields.Id = recordId;
        fields[fieldApiName] = event.target.value;
        const recordInput = {
            fields
        };
        console.log('recordInput>>' + JSON.stringify(recordInput));
        updateRecord(recordInput).then(() => {
            this.showToast('Success','Scheduled Date updated successfully!','success');
        }).catch(error => {
            console.log('err>'+JSON.stringify(error));
        })


    }


    formatDateForDisplay(dateStr) {
        if (!dateStr) {
            return '';
        }

        // Expecting yyyy-MM-dd
        const [year, month, day] = dateStr.split('-');
        return `${day}-${month}-${year}`;
    }

}