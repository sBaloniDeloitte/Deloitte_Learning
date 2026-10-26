import { LightningElement, track, wire, api } from 'lwc';
import getVASMasterRecords from '@salesforce/apex/ChargesInsuranceCmpController.getVASMasterRecords';
import getVASOnlyOppDetails from '@salesforce/apex/ChargesInsuranceCmpController.getVASOnlyOppDetails';
import checkIfVASExists from '@salesforce/apex/ChargesInsuranceCmpController.checkIfVASExists';
import getChargeInsuranceRecords from '@salesforce/apex/ChargesInsuranceCmpController.getChargeInsuranceRecords';
import deleteChargeInsurance from '@salesforce/apex/ChargesInsuranceCmpController.deleteChargeInsurance';
import getApplicantDetails from '@salesforce/apex/ChargesInsuranceCmpController.getApplicantDetails';
import fetchConstants from '@salesforce/apex/ChargesInsuranceCmpController.fetchConstants';
import createDocumentDetail from '@salesforce/apex/ChargesInsuranceCmpController.createDocumentDetail'
import deleteDocumentDetail from '@salesforce/apex/ChargesInsuranceCmpController.deleteDocumentDetail'
import updateDocDetails from '@salesforce/apex/ChargesInsuranceCmpController.updateDocDetails';
import getIntegrationDetails from '@salesforce/apex/ChargesInsuranceCmpController.getIntegrationDetails';
import canUserEditVAS from '@salesforce/apex/ChargesInsuranceCmpController.canUserEditVAS';
import updateEligibleForResanction from '@salesforce/apex/ChargesInsuranceCmpController.updateEligibleForResanction';
import {getRecord, deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex'; 
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CHARGES_INSURANCE_API_NAME from "@salesforce/schema/Charges_Insurance__c";
import VAS_CODE_FIELD from "@salesforce/schema/Charges_Insurance_Master__c.VAS_Code__c";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import requiredFieldMsg from "@salesforce/label/c.VAS_Required_Fields_Msg";
import noIndividualApplicantMsg from "@salesforce/label/c.No_Individual_Applicant_Msg";
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';
import { fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
const LOAN_FIELDS = ['Opportunity.Sanction_Loan_Amount__c','Opportunity.Sanction_Tenure__c','Opportunity.StageName'];
import LightningConfirm from 'lightning/confirm';

export default class ChargesInsuranceCmp extends LightningElement {

    @api recordId;
    @track errorMessages = []; // Store errors for each field 
    vasRecords = [];
    @track groupedFieldList = [];
    @track existingVasRecords;
    @track existingApplicants;
    @track applicants = [];
    applicantsMap = new Map();
    customerId;
    fields;
    @track prefilledFields = {};
    copiedPrefilledFields = {};
    showTable;
    isEdit = false;
    loanStage;
    isLoanInPSVStage;
    isSelfFundedActive =false;
    vasId;
    selectedVasRecordId;
    selectedVasCode;
    disableUpload = false;

    tabName;

    label = {
        requiredFieldMsg,
        noIndividualApplicantMsg
    }

    //for editing a record
    vasRecordId;
    isSelfFunded;
    isMinor;
    //for editing a record

    confirmDeletePopup = false;
    isLoading = false;

    wiredExistingRecords;
    recordTypeId;
    chargeInsuranceApiName = CHARGES_INSURANCE_API_NAME;
    recordTypeName = 'Insurance';

    sectionFieldMap = new Map();
    applicantVasCodeMap= new Map();
    copiedapplicantVasCodeMap = new Map();
    vasPercentage;
    allowedFilesFormats;

    conditionalSections = ['Appointee Details','Self Funded Detail'];
    disabledFields = ['Applicant_Type__c','Date_of_Birth__c','Self_Funded_Amount__c','Gender_Bank_Insurance_Details__c','Loan_Amount__c','Loan_tenure__c'];

    selfFundedAmountTabIndex;
    selfFundedAmountfieldIndex;

    errorMessage;
    isError = false;
    disableFeeMethod = false;
    disableSelfDeducted = false;

    DocDetailId;
    excelCalculatorDocId;
    isDocUploadStarted = false;
    isDocUploadStartedExcel = false;
    showNoIndividualApplicantMsg = true;

    showView=true;
    showViewExcel = true;
    showUpload=true;
    showUploadExcel = true;
    showRetake=true;
    showRetakeExcel = true;
    showDelete=false;
    showDeleteExcel = false
    showLocation = false;
    showLocationExcel = false;
    contentId;
    contentIdExcel;
    docUri;
    docUriExcel;
    fileType;
    fileTypeExcel;
    toDeletedVasCode;
    firstTimeLoaded=true;
    policyTenureMinValue = 0;
    policyTenureMaxValue =0;
    sanctionLoanTenure = 0;
     insurancePremiumDefaultValue = 0;
    toastvariant = {
        SUCCESS: 'success',
        ERROR: 'error',
        WARNING : 'warning'
    }
    toastTitle = {
        SUCCESS: 'Success',
        ERROR: 'Error',
        WARNING : 'Warning'
    }

    toastmessages = {
        RECORD_CREATION_SUCCESS_MSG: 'Record has been created Successfully.',
        RECORD_UPDATED_SUCCESSFULLY : 'Record updated Successfully',
        SOMETHING_WENT_WRONG_MSG: 'Something went wrong.',
        ERROR_OCCURED_WHILE_SAVING: 'Error occured while saving the Record. Please enter valid input and try again.',
        VAS_RECORD_DELETED_SUCCESSFULLY : 'VAS Record Deleted Successfully.',
        RECORD_IN_EDIT_MODE_CANNOT_BE_DELETED : 'Please save the VAS changes before deleting the record.',
        VAS_RECORD_IS_ALREADY_CREATED : 'VAS Record is already created for the selected Customer.',
        INSURANCE_PREMIUM_VALIDATION : 'Insurance Premium is more than 5% of Loan Amount.',
        ONLY_ONE_VASRECORD : 'VAS Only Loan Opportunity can have only ONE VAS',
    }

    validationMessages = {
        //Self_Funded_Amount__c : 'Self Funded Amount should not be greater than Insurance Premium.',
        self_funded_should_be_greater_than_zero : 'Self Funded Amount should be greater than zero',
        Loan_Amount__c : 'Loan Amount is mandatory and should be greater than zero.',
        Insurance_Premium__c : 'VAS Fee/ VAS Premium is mandatory and should be greater than zero.',
        Loan_tenure__c : 'Loan Tenure is mandatory.',
        Policy_Tenure__c : 'Policy Tenure is mandatory.',
        Value_Date__c : 'Value Date is mandatory.',
        Application_Applicant__c : 'Customer Name is Mandatory.',
        Fee_Method__c : 'Fee Method is mandatory',
        Mode_of_Payment_Self_Funded_Detail__c : 'Mode of payment is mandatory',
        Insurer_Details__c : 'Insurer Details is mandatory',
        Policy_Details__c : 'Policy Details is mandatory',
        //Self_Funded_Amount__c : 'Self Funded Amount is mandatory',

    }

    //for lightning record picker
    filter = {
        criteria: [{
                fieldPath: 'VAS_Code__c',
                operator: 'ne',
                value: '',
            },
            {
                fieldPath: 'Sequence__c',
                operator: 'eq',
                value: 1,
            },
            {
                fieldPath: 'Is_Active__c',
                operator: 'eq',
                value: true,
            },
        ],
        filterLogic: '1 AND 2 AND 3',
    };

    displayInfo = {
        primaryField: 'VAS_Code__c',
    }

    matchingInfo = {
        primaryField: {
            fieldPath: 'VAS_Code__c'
        },
        additionalFields: [{
            fieldPath: 'VAS_Code__c'
        }],
    }
    @track isEditableUser = true;
    @track isPreviewMode = false;
    @track isResanctionReq = false;
    connectedCallback() {
        // Call Apex to determine if user can edit
        canUserEditVAS({ opportunityId: this.recordId })
            .then(result => {
                this.isEditableUser = result;
                this.disableUpload = !result;
                console.log('Is editable user:', this.isEditableUser);
                if(this.isEditableUser == true)
                {
                    this.checkCmpEditability();
                }
            })
            .catch(error => {
                console.error('Error checking user access for VAS:', error);
                this.isEditableUser = false; // Default to read-only if error
            });
    }
    checkCmpEditability() {
        getComponentEditability({ loanId: this.recordId, component: 'chargesInsuranceCmp' })
            .then(result => {
               this.disableUpload = result; 
                this.isEditableUser = !result;
            })
            .catch(error => {
                console.error('Error getComponentEditability : ', error);
            });
    }

    handlePreview(event) {
        this.isPreviewMode = true;
        this.selectedVasRecordId = event.target.dataset.vascode;
        this.vasRecordId = event.target.dataset.vasid;
        this.prefilledFields = {};

        this.customerId = event.target.dataset.vascustomerid;
        console.log('this.customerId:: '+this.customerId);
        this.applicantVasCodeMap =  new Map(JSON.parse(JSON.stringify(Array.from(this.copiedapplicantVasCodeMap))));
        let tempVasCodeList = this.applicantVasCodeMap.get(this.customerId);
        tempVasCodeList.splice(tempVasCodeList.indexOf(this.selectedVasRecordId), 1);
        this.applicantVasCodeMap.set(this.customerId,tempVasCodeList);

        this.totalVasAmount = event.target.dataset.vasinsurancepremium;
        this.isSelfFunded = event.target.dataset.vasselffunded;
        this.isMinor = event.target.dataset.vasnomineedob;
        
        this.DocDetailId = event.target.dataset.vasdocdetailid;
        this.excelCalculatorDocId = event.target.dataset.vasdocdetailidexcel;
        this.contentId = event.target.dataset.vascontentid;
        this.contentIdExcel = event.target.dataset.vascontentidexcel;
        this.docUri = `/sfc/servlet.shepherd/version/download/${this.contentId}`;
        this.fileType = event.target.dataset.vasfiletype;
        this.fileTypeExcel = event.target.dataset.vasfiletypeexcel;
       
        this.docUriExcel = `/sfc/servlet.shepherd/version/download/${this.contentIdExcel}`;
         

        


      
        this.disableFeeMethod = true;
        this.disableSelfDeducted = true;
    
        // Also load edit-related info if needed
        this.isEdit = false;
    
        // Force load VAS UI in preview mode
        this.getVasRecords();
        this.changeSectionVisibility('Self Funded Detail',this.isSelfFunded === 'true');
        this.changeSectionVisibility('Appointee Details',this.isAgeLessThan18(this.isMinor, new Date()) );
        setTimeout(() => {
            this.assignBankInsuranceValue();
        }, 300);
        this.prefilledFields = {...this.copiedPrefilledFields};
        this.scrollToTop();
    }
    

    get currentDate(){
        return new Date().toISOString().slice(0,10);
    }

    //for lightning record picker
    @wire(getRecord, {
        recordId: "$recordId",
        fields: LOAN_FIELDS,
    })
    gotLoanFields({
        data,
        error
    }) {
        if (data) {
            let stage = data.fields.StageName.value;
            this.sanctionLoanAmount = data.fields?.Sanction_Loan_Amount__c?.value;
            this.prefilledFields.sumInsured = data.fields?.Sanction_Loan_Amount__c?.value;
            this.prefilledFields.tenureInYears = parseInt(data.fields?.Sanction_Tenure__c?.value);
            this.sanctionLoanTenure = parseInt(data.fields?.Sanction_Tenure__c?.value);
            this.loanStage= stage;
            this.isLoanInPSVStage = stage === 'PSV';
            this.copiedPrefilledFields = {...this.prefilledFields};
        } else if (error) {
            this.handleError(error);
            this.showToast(this.toastTitle.ERROR, this.toastmessages.SOMETHING_WENT_WRONG_MSG, this.toastvariant.ERROR);
        }
    }

     @wire(fetchConstants)  
    getVasConstants({ data, error }){
        if (data) {             
            this.vasPercentage = parseInt(data[0]);
            this.allowedFilesFormats = data[1].split(",");
        } else if ( error ) {
            this.handleError(error);
            this.showToast(this.toastTitle.ERROR, this.toastmessages.SOMETHING_WENT_WRONG_MSG, this.toastvariant.ERROR);

        }

    }  

    @wire(getChargeInsuranceRecords, {
        loanId: '$recordId'
    })
    getExistingRecords(result) {
        this.wiredExistingRecords = result;
        if (result.data) {
            console.log('result.data ',JSON.stringify(result.data));
            this.existingVasRecords = result.data;
            this.applicantVasCodeMap = new Map();
            result.data.forEach(item =>{
                this.updateApplicantVasCodeMap(item.chargeInsurance.Application_Applicant__c, item.chargeInsurance.Charges_Insurance_Master__c);
            })
            this.copiedapplicantVasCodeMap =  new Map(JSON.parse(JSON.stringify(Array.from(this.applicantVasCodeMap))));
            this.showTable = result.data.length;
        } else if (result.error) {
            this.handleError(result.error);
            this.showToast(this.toastTitle.ERROR, this.toastmessages.SOMETHING_WENT_WRONG_MSG, this.toastvariant.ERROR);
        }
    }

    updateApplicantVasCodeMap(customerId, VasCode){
        
        if(this.applicantVasCodeMap.has(customerId)){
            this.applicantVasCodeMap.get(customerId).push(VasCode);
        }else{
            let tempList = [];
            tempList.push(VasCode);
            this.applicantVasCodeMap.set(customerId,tempList);
        }
    }

    @wire(getApplicantDetails, {
        loanId: '$recordId'
    })
    getExistingApplicants({data,error}) {
        if (data) {
            this.existingApplicants = data;
            data.forEach(item => {
                if(item.Customer_Type__c == 'Individual'){
                    this.showNoIndividualApplicantMsg = false;
                
                this.applicants.push({
                    label : item.Name,
                    value : item.Id, 
                })
                this.applicantsMap.set(item.Id,item);
            }
            });
            if (this.isPreviewMode && this.customerId) {
                this.assignBankInsuranceValue(); 
            }
        } else if (error) {
            this.handleError(error);
            this.showToast(this.toastTitle.ERROR, this.toastmessages.SOMETHING_WENT_WRONG_MSG, this.toastvariant.ERROR);
        }
    }


    @wire(getObjectInfo, {
        objectApiName: '$chargeInsuranceApiName'
    })
    chargeInsuranceRecordType({
        error,
        data
    }) {
        if (data) {
            const recordTypes = data.recordTypeInfos;
            const recordTypeInfo = Object.values(recordTypes).find(rt => rt.name === this.recordTypeName);
            if (recordTypeInfo) {
                this.recordTypeId = recordTypeInfo.recordTypeId;
            }
        } else if (error) {
            this.handleError(error);
            this.showToast(this.toastTitle.ERROR, this.toastmessages.SOMETHING_WENT_WRONG_MSG, this.toastvariant.ERROR);
        }
    }

    @wire(getRecord, {
        recordId: "$selectedVasRecordId",
        fields: [VAS_CODE_FIELD],
    })
    getVasMasterRecord({
        data,
        error
    }) {
        if (data) {
            this.selectedVasCode = data.fields.VAS_Code__c.value;
        } else if (error) {
            this.handleError(error);
            this.showToast(this.toastTitle.ERROR, this.toastmessages.SOMETHING_WENT_WRONG_MSG, this.toastvariant.ERROR);
        }
    }

    @wire(CurrentPageReference) pageRef;

    @wire(getVASOnlyOppDetails, {
        parentLoanAppId : '$recordId'
    })
    gotVASDetails({data , error}){
        if(data){
            this.isVASOnlyOpp = data;
        }else if(error){
            this.handleError(error);
            this.showToast(this.toastTitle.ERROR, this.toastmessages.SOMETHING_WENT_WRONG_MSG, this.toastvariant.ERROR);
        }
    }

    @wire(getIntegrationDetails, {
    })
    plfDate;
    


    async handleVASCode(event) {

        this.vasExists = await checkIfVASExists({parentLoanAppId : this.recordId});
        if(event.detail.recordId && this.isVASOnlyOpp && this.loanStage=='PSV' && this.vasExists){
            this.showToast(this.toastTitle.ERROR, this.toastmessages.ONLY_ONE_VASRECORD, this.toastvariant.ERROR);
            return;
        }else{
            this.isLoading = true;
            this.selectedVasRecordId = event.detail.recordId;
            this.customerId ='';
            this.vasRecordId = '';
            this.errorMessages = {};
            this.totalVasAmount = '';
            this.prefilledFields = {...this.copiedPrefilledFields};

            //for file upload
            this.DocDetailId = '';
            this.excelCalculatorDocId = '';
            this.contentId = '';
            this.contentIdExcel = '';
            this.docUri = '';
            this.fileType = '';
            this.fileTypeExcel = '';
            
            if (this.selectedVasRecordId) {
                try {
                    if(this.isVASOnlyOpp && this.loanStage==='PSV'){
                        this.assignVASOnlyDetails();
                    }
                    this.getVasRecords();
                    createDocumentDetail({ names: ['Insurance Related Document', 'Excel Calculator'] })
                        .then(result => {
                            if (result) {
                                console.log('Document IDs:', JSON.stringify(result));
                                this.DocDetailId = result['Insurance Related Document'];
                                this.checkdocid = this.DocDetailId;
                                this.excelCalculatorDocId = result['Excel Calculator'];
                                this.checkdoccal = this.excelCalculatorDocId;
                                console.log('DocDetailIds:', this.DocDetailId);
                                console.log('excelCalculatorDocId:', this.excelCalculatorDocId);
                            } else {
                                this.showToast(this.toastTitle.ERROR, 'Document Detail records not created', this.toastvariant.ERROR);
                            }
                        })
                        .catch(error => {
                        console.error('Error creating document details:', error);
                            this.showToast(this.toastTitle.ERROR, error.body.message, this.toastvariant.ERROR);
                    });

                    // this.DocDetailId = await createDocumentDetail({name : 'Insurance Related Document'});
                    // console.log('this.DocDetailId>>'+JSON.stringify( this.DocDetailId));
                    // this.excelCalculatorDocId = await createDocumentDetail({name : 'Excel Calculator'});
                    // console.log('this.excelCalculatorDocId>>'+JSON.stringify(this.excelCalculatorDocId));
                    
                } catch (error) {
                    this.isLoading = false;
                    this.handleError(error);
                    this.showToast(this.toastTitle.ERROR, this.toastmessages.SOMETHING_WENT_WRONG_MSG, this.toastvariant.ERROR);
                }
            }
        }   
    }

    handleFileUpload(){
        this.isDocUploadStarted = true;
    }

    handleFileUploadExcel(){
        console.log('handleFileUploadExcel>>');
        this.isDocUploadStartedExcel = true;
    }

    async getVasRecords() {
        this.vasRecords = [];
        this.groupedFieldList = [];
        
        this.vasRecords = await getVASMasterRecords({
            selectedVASRecordId: this.selectedVasRecordId
        });
        console.log('vasRecords : 499 :'+JSON.stringify(this.vasRecords));
        this.vasRecords.forEach((item, index) => {
            let splittedFields = item.vasMasterRecord.Section_Fields__c.split(',');
            this.tabName = item.vasMasterRecord.Tab_Name__c;
            if(item.vasMasterRecord.Section_Name__c == 'Customer Details'){
                   this.policyTenureMinValue = item.vasMasterRecord.Min_Value__c;
                   this.policyTenureMaxValue = item.vasMasterRecord.Max_Value__c;
                   this.insurancePremiumDefaultValue = item.vasMasterRecord.Default_Text_Value__c;
            console.log('this.policyTenureMinValue>>'+this.policyTenureMinValue);
            console.log('this.policyTenureMaxValue>>'+this.policyTenureMaxValue);
            }
             
            let tempList = [];
            this.prefilledFields.description = item.vasMasterRecord.VAS_Description__c;
            
            splittedFields.forEach((splittedField, fieldIndex) =>{
                let value = splittedField == 'Loan_Amount__c' ? this.prefilledFields?.sumInsured : 
                            splittedField == 'Loan_tenure__c' ? this.prefilledFields.tenureInYears :
                            splittedField == 'Self_Funded_Amount__c' ? this.totalVasAmount : '';
                
                let isPrefilled_Disabled;

                 if(splittedField == 'Insurance_Premium__c'){
       
                    value = this.insurancePremiumDefaultValue;
                    
                }

                if(splittedField == 'Policy_Tenure__c' && this.policyTenureMinValue == 0 && this.policyTenureMaxValue == 0){
                    value = this.sanctionLoanTenure;
                }
                
                if(this.isVASOnlyOpp && this.loanStage === 'PSV' && splittedField == 'Insurance_Premium__c'){
                    value = this.sanctionLoanAmount;
                    isPrefilled_Disabled = true;
                }
                else if(this.loanStage === 'Disbursement' && splittedField == 'Insurance_Premium__c'){
                    value = this.totalVasAmount;
                    isPrefilled_Disabled = true;
                }
                else{   
                    isPrefilled_Disabled = this.disabledFields.includes(splittedField);
                }
                this.selfFundedAmountTabIndex = splittedField == 'Self_Funded_Amount__c' ? index : this.selfFundedAmountTabIndex;
                this.selfFundedAmountfieldIndex = splittedField == 'Self_Funded_Amount__c' ? fieldIndex : this.selfFundedAmountfieldIndex;
                var existingRecordValue = {};
                this.existingVasRecords.forEach(data=>{


                    if(data.chargeInsurance.Id == this.vasRecordId){
                        existingRecordValue = data.chargeInsurance;
                     
                    }
                })
                         
                tempList.push({
                    fieldName : splittedField,

                    fieldValue : value !='' ? value : existingRecordValue[splittedField],
                    isDisabled : isPrefilled_Disabled,
                    isPrefilled : isPrefilled_Disabled,
                    fieldErrorMessage : '',
                    isCustomerName : splittedField == 'Application_Applicant__c' ? true : false,
                    customClass : item.picklistFieldList.includes(splittedField) ? 'removeborder' : 'hideInput',
                    // isRequired : splittedField == 'Policy_Issued_Date__c' || 
                    //              splittedField == 'Policy_Issued_Month__c' ||
                    //              splittedField == 'Policy_Status__c' ||
                    //              splittedField == 'Remarks__c' ||
                    //              splittedField == 'Amount_in_Nominee_Account__c'||
                    //              splittedField == 'UTR_details_for_Nominee__c' ||
                    //              splittedField == 'Claim_Amount__c' ||
                    //              splittedField == 'UTR_details_to_Godrej__c' ||
                    //              splittedField == 'Status_Remarks__c' ||
                    //              splittedField == 'Insurance_Type__c' ||
                    //              splittedField == 'Claim__c' ||
                    //              splittedField == 'Reason__c' ? false : true
                     isRequired : item.nestedMap[item.vasMasterRecord.Section_Name__c][splittedField] || false
                })
            })
            this.groupedFieldList.push({
                tabIndex: index,
                sectionName: item.vasMasterRecord.Section_Name__c,
                isVisible : !this.conditionalSections.includes(item.vasMasterRecord.Section_Name__c),
                fieldList: tempList,
                isFieldData : true,
            });

            this.isLoading = false;
            
        })
        this.groupedFieldList.push({
                tabIndex: this.vasRecords.length,
                sectionName: 'Please Upload Insurance Proposal Form',
                isVisible : true,
                acceptedFormats : this.allowedFilesFormats,
                isFieldData : false,
                isExcelUploadSection : false
            });
        this.groupedFieldList.push({
                tabIndex: this.vasRecords.length +1,
                sectionName: 'Please Upload Excel Calculator',
                isVisible : true,
                acceptedFormats : this.allowedFilesFormats,
                isFieldData : false,
                isExcelUploadSection : true
            });
        console.log('this.groupedFieldList>>'+JSON.stringify(this.groupedFieldList));
    }

    handleUploadFinished(event){

    }

    async saveRecord(event) {
        event.preventDefault();
        const submittedFields = event.detail.fields;
        if (this.isResanctionReq) {
            const result = await LightningConfirm.open({
                message: 'Insurance Percentage is geater than equal to 5% of sanction amount. Are you sure you want to Re-sanction this record?',
                label: 'Confirmation Screen',
                className: "custom-confirm-header"
            });
            if (!result) {
                return;
            }
        }
        console.log('recordTypeId ',this.recordTypeId);

        if(this.isDocUploadStarted){
            this.showUpload=true;
            return;
        }

        if(this.isDocUploadStartedExcel){
            this.showUploadExcel = true;
            return;
        }


        if(Number.isInteger(parseInt(event.target.value)) && parseInt(event.target.value) < 0){
            this.showToast(this.toastTitle.ERROR, 'Value Cannot be Zero.', this.toastvariant.ERROR);
            return;
        }
        if(this.applicantVasCodeMap.get(this.customerId)?.includes(this.selectedVasRecordId)){
            this.showToast(this.toastTitle.ERROR, this.toastmessages.VAS_RECORD_IS_ALREADY_CREATED, this.toastvariant.ERROR);
            return;
        }

        this.isLoading = true;
        this.isError = false;
        this.fields = submittedFields;
        this.fields.Loan_Application__c = this.recordId;
        this.fields.VAS_Code__c = this.selectedVasCode;
        this.fields.Name = this.selectedVasCode;
        this.fields.RecordTypeId = this.recordTypeId;
        this.fields.Charges_Insurance_Master__c = this.selectedVasRecordId;
        this.fields.Application_Applicant__c = this.customerId;
        this.fields.Total_VAS_Amount__c = event.detail.fields.Insurance_Premium__c != null ? event.detail.fields.Insurance_Premium__c : '';
        this.fields.Value_Date__c  = this.plfDate.data;
        this.fields.Fee_Accural_Date__c  = this.plfDate.data;  
        this.fields.Category__c = 'Insurance'; //this is populated so that the VAS record is visible under the charges table as for charges records are being segregated using the Category__c field
        this.fields.Policy_Tenure_Max_Value__c = this.policyTenureMaxValue;
        this.fields.Policy_Tenure_Min_Value__c = this.policyTenureMinValue;


        Array.from(this.template.querySelectorAll('lightning-input-field, lightning-combobox')).forEach(item => {
            const groupedIndex = item.dataset.groupedindex ? item.dataset.groupedindex : '';
            const tabIndex = item.dataset.tabindex ? item.dataset.tabindex : '';
            const fieldName = item.fieldName ? item.fieldName : item.name;
            this.handleErrorMessage(fieldName, this.fields[fieldName], groupedIndex, tabIndex);
        });

        try {
            if (!this.isError) {
                console.log('fields ',JSON.stringify(this.fields));
                this.template.querySelector('lightning-record-edit-form').submit(this.fields);
            } else {
                this.isLoading = false;
                this.showToast(this.toastTitle.ERROR, this.toastmessages.ERROR_OCCURED_WHILE_SAVING, this.toastvariant.ERROR);
            }
        } catch (error) {
            this.isLoading = false;
            this.handleError(error);
            this.showToast(this.toastTitle.ERROR, this.toastmessages.SOMETHING_WENT_WRONG_MSG, this.toastvariant.ERROR);
        }

    }

    handleChange(event) {

        if(event.target.fieldName == 'Nominee_DOB__c'){
            let isValid = this.isAgeLessThan18(event.target.value, new Date());
            this.changeSectionVisibility('Appointee Details',isValid );
        }else if(event.target.fieldName == 'Fee_Method__c'){
            if(event.target.value == 'Self funded'){
                this.changeSectionVisibility('Self Funded Detail',true);
            }else{
                this.changeSectionVisibility('Self Funded Detail',false);
            }
        }
        // else if(event.target.fieldName == 'Self_Funded__c'){
        //     this.changeSectionVisibility('Self Funded Detail',event.target.value);
        // }

        if(event.target.fieldName == 'Insurance_Premium__c'){
            if(event.target.value >= (this.prefilledFields?.sumInsured*(this.vasPercentage/100))){
                this.isResanctionReq = true;
                this.showToast(this.toastTitle.WARNING, this.toastmessages.INSURANCE_PREMIUM_VALIDATION, this.toastvariant.WARNING);
            } else {
                this.isResanctionReq = false;
            }
            this.groupedFieldList[this.selfFundedAmountTabIndex].fieldList[this.selfFundedAmountfieldIndex].fieldValue = event.target.value;
        }
        
        this.totalVasAmount = event.target.fieldName == 'Insurance_Premium__c' ? event.target.value : this.totalVasAmount;

        // if(event.target.fieldName == 'Self_Funded__c'){
        //     console.log('self funded value',event.target.value);
        //     this.disableFeeMethod = event.target.value;
        //     this.prefilledFields.feeMethod = '--None--';

        // }

        const fieldName = event.target.fieldName;
        const fieldValue = event.target.value;
        const groupedIndex = event.target.dataset.groupedindex ? event.target.dataset.groupedindex : '';
        const tabIndex = event.target.dataset.tabindex ? event.target.dataset.tabindex : '';
        this.handleErrorMessage(fieldName, fieldValue, groupedIndex, tabIndex);
    }

    handleCustomerChange(event){
        if(this.applicantVasCodeMap.get(event.target.value)?.includes(this.selectedVasRecordId)){
            this.showToast(this.toastTitle.WARNING, this.toastmessages.VAS_RECORD_IS_ALREADY_CREATED, this.toastvariant.WARNING);
        }
        this.customerId = event.target.value;
        const groupedIndex = event.target.dataset.groupedindex ? event.target.dataset.groupedindex : '';
        const tabIndex = event.target.dataset.tabindex ? event.target.dataset.tabindex : '';
        this.assignBankInsuranceValue();
        this.logError('',groupedIndex,tabIndex,'')
    }

    handleCustomerFcsOut(event){
        if(!event.target.value){
            const groupedIndex = event.target.dataset.groupedindex ? event.target.dataset.groupedindex : '';
            const tabIndex = event.target.dataset.tabindex ? event.target.dataset.tabindex : '';
            this.logError(this.validationMessages.Application_Applicant__c,groupedIndex,tabIndex,'');
        }
    }

    assignBankInsuranceValue(){
        if(this.customerId){
            Array.from(this.template.querySelectorAll('lightning-input-field')).forEach(item => {
                //ternary operator is not used as it is effecting other field values
                if(item.fieldName == 'Applicant_Type__c'){
                    item.value = this.applicantsMap?.get(this.customerId)?.Applicant_Type__c;
                }else if(item.fieldName == 'Date_of_Birth__c'){
                    item.value = this.applicantsMap?.get(this.customerId)?.DOB__c;
                }else if(item.fieldName == 'Gender_Bank_Insurance_Details__c'){
                    item.value = this.applicantsMap?.get(this.customerId)?.Gender__c;
                }
            });
        }else{
             Array.from(this.template.querySelectorAll('lightning-input-field')).forEach(item => {
                item.value = item.fieldName == 'Applicant_Type__c' || item.fieldName == 'Date_of_Birth__c' || item.fieldName == 'Gender_Bank_Insurance_Details__c' ? '' : item.value;
                if(item.fieldName == 'Applicant_Type__c'){
                    item.value = '';
                }else if(item.fieldName == 'Date_of_Birth__c'){
                    item.value = '';
                }else if(item.fieldName == 'Gender_Bank_Insurance_Details__c'){
                    item.value = '';
                }
            });
        }
        
        
    }

    handleFocusOut(event) {
        const fieldName = event.target.fieldName;
        const groupedIndex = event.target.dataset.groupedindex ? event.target.dataset.groupedindex : '';
        const tabIndex = event.target.dataset.tabindex ? event.target.dataset.tabindex : '';
      
    let errorMsg = '';            
                if(fieldName === 'Value_Date__c' && event.target.value < this.currentDate){
                    errorMsg = 'Value Date cannot be a past date.';

                }
                if(errorMsg!= ''){
                this.logError(errorMsg,groupedIndex,tabIndex,fieldName);
                }
   
    }

    async handleSuccess(event) {
        // if(this.VASExists){
        //     return;
        // }
        if(this.isDocUploadStarted){
            this.isDocUploadStarted = false;
            return;
        }
        if(this.isDocUploadStartedExcel){
            this.isDocUploadStartedExcel = false;
            return;
        }
        if(this.applicantVasCodeMap.get(this.customerId)?.includes(this.selectedVasRecordId)){
            return;
        }
        if(this.DocDetailId){
            await updateDocDetails({LoanId : this.recordId, customerId : this.customerId, docDetailId : this.DocDetailId, vasCode : this.selectedVasCode});
        }
        if(this.excelCalculatorDocId){
            await updateDocDetails({LoanId : this.recordId, customerId : this.customerId, docDetailId : this.excelCalculatorDocId, vasCode : this.selectedVasCode});
        }
        this.selectedVasRecordId = '';
        this.tabName = '';
        this.groupedFieldList = [];
        this.vasRecordId = '';
        this.template.querySelector('lightning-record-picker').clearSelection();

        let toastMessage = this.isEdit ? this.toastmessages.RECORD_UPDATED_SUCCESSFULLY : this.toastmessages.RECORD_CREATION_SUCCESS_MSG;
        this.isEdit = false;
        this.showToast(this.toastTitle.SUCCESS, toastMessage, this.toastvariant.SUCCESS);
        if(!this.isResanctionReq) {
            fireEvent(this.pageRef, 'refreshPricingApproval', {});
            fireEvent(this.pageRef, 'triggerResanctionCheck', {
                method: 'Insurance',
                isUpdateDone: true
            });
        } else {
            await this.sendForReSanction();
        }
        await refreshApex(this.wiredExistingRecords);
        this.isLoading = false;
    }

    async sendForReSanction() {
        try {
            await updateEligibleForResanction({ opportunityId: this.recordId });
            this.isResanctionReq = false;
            fireEvent(this.pageRef, 'refreshPricingApproval', {});
            fireEvent(this.pageRef, 'triggerResanctionCheck', {
                method: 'Insurance',
                isUpdateDone: true
            });
        } catch (error) {
            console.error('Resanction update failed', error);
        }
    }

    async handleEdit(event){
        
        this.isEdit = true;
        this.selectedVasRecordId = event.target.dataset.vascode;
        this.vasRecordId = event.target.dataset.vasid;
        this.prefilledFields = {};

        this.customerId = event.target.dataset.vascustomerid;

        this.applicantVasCodeMap =  new Map(JSON.parse(JSON.stringify(Array.from(this.copiedapplicantVasCodeMap))));
        let tempVasCodeList = this.applicantVasCodeMap.get(this.customerId);
        tempVasCodeList.splice(tempVasCodeList.indexOf(this.selectedVasRecordId), 1);
        this.applicantVasCodeMap.set(this.customerId,tempVasCodeList);

        this.totalVasAmount = event.target.dataset.vasinsurancepremium;
        this.isSelfFunded = event.target.dataset.vasselffunded;
        this.isMinor = event.target.dataset.vasnomineedob;
        
        this.DocDetailId = event.target.dataset.vasdocdetailid;
        this.excelCalculatorDocId = event.target.dataset.vasdocdetailidexcel;
        this.contentId = event.target.dataset.vascontentid;
        this.contentIdExcel = event.target.dataset.vascontentidexcel;
        this.docUri = `/sfc/servlet.shepherd/version/download/${this.contentId}`;
        this.fileType = event.target.dataset.vasfiletype;
        this.fileTypeExcel = event.target.dataset.vasfiletypeexcel;
        this.docUriExcel = `/sfc/servlet.shepherd/version/download/${this.contentIdExcel}`;
        
        

        try{
            if(this.isVASOnlyOpp && this.loanStage==='PSV'){
                this.assignVASOnlyDetails();
            }
            else if(this.loanStage =='Disbursement'){
                this.disableFeeMethod = true;
                this.disableSelfDeducted = true;
            }

            await this.getVasRecords();
            this.changeSectionVisibility('Self Funded Detail',this.isSelfFunded === 'true');
            this.changeSectionVisibility('Appointee Details',this.isAgeLessThan18(this.isMinor, new Date()) );
            this.assignBankInsuranceValue();
            this.prefilledFields = {...this.copiedPrefilledFields};
            this.scrollToTop();
        }catch(error){
            this.handleError(error);
            this.showToast(this.toastTitle.ERROR, this.toastmessages.SOMETHING_WENT_WRONG_MSG, this.toastvariant.ERROR);
        }
        
    }
    assignVASOnlyDetails(){
        this.prefilledFields.feeMethod = 'DISB';
        this.disableFeeMethod = true;
        this.prefilledFields.selfDeducted = false;
        this.disableSelfDeducted = true;
    }

    handleDelete(event){
        this.confirmDeletePopup = true;
        this.vasId= event.target.dataset.vasid;
        this.customerId = event.target.dataset.vascustomerid;
        this.toDeletedVasCode = event.target.dataset.vascode;
    }

    async confirmVasDelete(){
        try{
            this.isLoading = true;
            this.confirmDeletePopup = false;
            if(this.vasRecordId == this.vasId){
                this.showToast(this.toastTitle.ERROR, this.toastmessages.RECORD_IN_EDIT_MODE_CANNOT_BE_DELETED, this.toastvariant.ERROR);
                this.isLoading = false;
                return;
            }
            this.showToast(this.toastTitle.SUCCESS, this.toastmessages.VAS_RECORD_DELETED_SUCCESSFULLY, this.toastvariant.SUCCESS);
            await deleteChargeInsurance({ vasId: this.vasId});
            await this.refreshTable();

            fireEvent(this.pageRef, 'refreshPricingApproval', {});
            fireEvent(this.pageRef, 'triggerResanctionCheck', {
                method: 'Insurance',
                isUpdateDone: true
            });
        }catch(error){
            this.handleError(error);
            this.showToast(this.toastTitle.ERROR, this.toastmessages.SOMETHING_WENT_WRONG_MSG, this.toastvariant.ERROR);
        }
    }

     handleErrorMessage(fieldName, fieldValue, groupedIndex, tabIndex) {
        let errorMsg = '';
        let onlyMandatoryCheckRequired = false;
        let mandatoryAndValidationRequired;
        
        if(this.loanStage==='PSV'){
            onlyMandatoryCheckRequired =  fieldName === 'Application_Applicant__c';
        }else{
            onlyMandatoryCheckRequired = fieldName === 'Loan_tenure__c' ||
                                                 fieldName === 'Value_Date__c' || fieldName === 'Application_Applicant__c' ||
                                                 fieldName === 'Applicant_Type__c' || fieldName === 'Date_of_Birth__c' ||
                                                 fieldName === 'Gender_Bank_Insurance_Details__c' || fieldName === 'Nominee_Relationship__c' ||
                                                 fieldName === 'Nominee_DOB__c' || fieldName === 'Nominee_Name__c';
        }
        if(this.isSelfFundedActive){
            onlyMandatoryCheckRequired = onlyMandatoryCheckRequired || fieldName == 'Mode_of_Payment_Self_Funded_Detail__c' || fieldName == 'Insurer_Details__c' || 
                                         fieldName == 'Policy_Details__c' /*|| fieldName == 'Self_Funded_Amount__c'*/ ;
        }
        if(this.loanStage==='PSV'){
        mandatoryAndValidationRequired = fieldName === 'Insurance_Premium__c';
        }else{
        mandatoryAndValidationRequired = fieldName === 'Loan_Amount__c' || fieldName === 'Insurance_Premium__c';
        }
        // Validate input and set error messages
        if (mandatoryAndValidationRequired && (parseInt(fieldValue) <= 0 || !fieldValue)) {
            errorMsg = this.validationMessages[fieldName];
        } else if (onlyMandatoryCheckRequired && !fieldValue) {
            errorMsg = this.validationMessages[fieldName];
        }
        /*else if (fieldName === 'Self_Funded_Amount__c') {
            const totalVasAmount = parseInt(this.totalVasAmount || 0);
            if (parseInt(fieldValue) > totalVasAmount) {
                errorMsg =this.validationMessages[fieldName];
            }else if(parseInt(fieldValue) <= 0 || !fieldValue){
                errorMsg =this.validationMessages.self_funded_should_be_greater_than_zero;
            }
        } */
       
        if(fieldName == 'Value_Date__c' && fieldValue<this.currentDate){
            errorMsg = 'Value Date cannot be a past date.';
        }
        else if(fieldName == 'Fee_Accural_Date__c' && fieldValue<this.currentDate){
            errorMsg = 'Fee Accural Date cannot be a past date.';
        }
        else if(fieldName == 'Sum_Insured_Customer_Details__c'){
            if( fieldValue != '' && fieldValue == 0){
                errorMsg = 'Sum Insured cannot be 0.';
            }/*else if(fieldValue > this.prefilledFields.sumInsured){
                errorMsg = 'Sum Insured cannot be more than Loan Amount.';
            }*/else if(fieldValue > (this.prefilledFields.sumInsured * 1.25)){
                errorMsg = 'Sum Insured cannot be more than 125% of the Loan Amount.';
            }
        }
        else if(fieldName == 'Insurance_Premium__c'){
            if(fieldValue > this.prefilledFields.sumInsured){
                errorMsg = 'Insurance Premium Amount cannot be more than Loan Amount.'
            }
        }
        else if(fieldName == 'Policy_Tenure__c'){
            if(fieldValue != '' && fieldValue == 0){
                errorMsg = 'Policy Tenure should be greater than 0.';
            }
            if(fieldValue > this.prefilledFields.tenureInYears){
                errorMsg = 'Policy Tenure cannot be more than Loan Tenure.';
            }
            if(this.policyTenureMinValue != 0 && this.policyTenureMaxValue == 0  && fieldValue < this.policyTenureMinValue){
                errorMsg = 'Policy tenure should be greater than '+ this.policyTenureMinValue; 
            }
            else if(this.policyTenureMinValue == 0 && this.policyTenureMaxValue != 0 && fieldValue > this.policyTenureMaxValue){
                errorMsg = 'Policy tenure should be less than '+this.policyTenureMaxValue;
            }else if(this.policyTenureMinValue != 0 && this.policyTenureMaxValue != 0 && (fieldValue < this.policyTenureMinValue || fieldValue > this.policyTenureMaxValue)){
                errorMsg = 'Policy tenure should be between '+ this.policyTenureMinValue +' and '+this.policyTenureMaxValue;
            }

        }
        else if(fieldName == 'Nominee_DOB__c'){
            if(fieldValue > this.currentDate){
                errorMsg = 'Nominee DOB cannot be a future date.';
            }

        }else if (fieldName == 'Appointee_DOB__c') {
            const ageInMilliseconds = new Date() - new Date(fieldValue);
            const ageInYears = ageInMilliseconds / (1000 * 60 * 60 * 24 * 365.25); 
            if (ageInYears < 18) {
                errorMsg = 'Appointee must be at least 18 years old.';
            }
        }
        if ((fieldName === 'Sum_Insured_Customer_Details__c' || fieldName === 'Insurance_Premium__c') 
            && fieldValue && fieldValue.toString().includes('.')) {
            errorMsg = fieldName === 'Sum_Insured_Customer_Details__c'
                ? 'Decimal values are not allowed for Sum Insured.'
                : 'Decimal values are not allowed for Insurance Premium.';
        }

       

        // Update error messages object
        this.logError(errorMsg,groupedIndex,tabIndex,fieldName);
    }


    logError(errorMsg,groupedIndex,tabIndex,fieldName){
        if (errorMsg) {
            this.isError = true;
            if (groupedIndex && tabIndex) {
                this.groupedFieldList[groupedIndex].fieldList[tabIndex].fieldErrorMessage = errorMsg;
            } else {
                this.errorMessages = {
                    ...this.errorMessages,
                    [fieldName]: errorMsg
                };
            }
        }else {
            if (groupedIndex && tabIndex) {
                this.groupedFieldList[groupedIndex].fieldList[tabIndex].fieldErrorMessage = errorMsg;
            } else {
                delete this.errorMessages[fieldName]; // Remove error if input is valid
                this.errorMessages = {
                    ...this.errorMessages
                };
            }

        }
    }

    async updateDocDetails(loanId, custId, docId, vasCode){
        setTimeout(async () => {
            updateDocDetails({LoanId : loanId, customerId : custId, docDetailId : docId, vasCode : vasCode});
        }, 500)
    }

    async refreshTable() {
        setTimeout(async () => {
            await refreshApex(this.wiredExistingRecords);
            this.isLoading = false;
        }, 1000)
    }

    changeSectionVisibility(sectionName, isVisible){
        this.groupedFieldList.forEach(item =>{
            if(item.sectionName == sectionName){
                item.isVisible = isVisible;
            } 
        })
    }

    closeVasDeleteModal(){
        this.confirmDeletePopup = false;
    }

    isAgeLessThan18(startDate, endDate) {
        const start = new Date(startDate);
        const end = new Date(endDate);
        let age = end.getFullYear() - start.getFullYear();
        const monthDiff = end.getMonth() - start.getMonth();
        if (monthDiff < 0 || (monthDiff === 0 && end.getDate() < start.getDate())) {
            age--;
        }
        return age < 18;
    }

    scrollToTop() {
        this.template.querySelector('.tobeScrolled').scrollIntoView(false,{ behavior: 'smooth', block: 'start' }); // Smooth scrolling to the top of the div
    }

    showToast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    handleFormError(event){
        const error = event.detail;
        console.error('Error message:', error.message);
        console.error('Error body:', error.body);
        console.log(JSON.stringify(error));
    }

    handleError(error) {
        this.errorMessage = "Error Occured : " + (error.message ? error.message : error.body.message);
        console.error(error);
    }
    
    renderedCallback() {
        const style = document.createElement("style");
        style.innerText = `
        /* Hide border and apply bottom border only */
            .hideInput .slds-input {
                border: none !important; /* Remove all default borders */
                border-bottom: 1px solid black !important; /* Add only bottom border */
                background-color: #16283f !important;
                outline: none;
                box-shadow: none;
                border-radius: 0 !important; /* Remove curved edges */
                padding: 4px; /* Adjust padding if necessary */
            }
            .removeborder .slds-combobox__input {
                border: none !important;  /* Remove border */
                box-shadow: none !important;  /* Remove any shadow */
                background-color: #16283f !important;
                 border-bottom: 1px solid black !important; /* Add only bottom border */
                 border-radius: 0 !important; /* Remove curved edges */
                 padding:5px

            }
            .slds-textarea{
                background-color: #16283f !important;
            }
            .slds-dropdown-trigger_click .slds-dropdown, .slds-dropdown-trigger_click:hover .slds-dropdown, .slds-dropdown-trigger--click .slds-dropdown, .slds-dropdown-trigger--click:hover .slds-dropdown{
                background-color: #16283f !important;
                color : white !important;
            }
            .slds-listbox_vertical .slds-listbox__option:focus, .slds-listbox_vertical .slds-listbox__option.slds-has-focus, .slds-listbox--vertical .slds-listbox__option:focus, .slds-listbox--vertical .slds-listbox__option.slds-has-focus{
                background-color: #16283f !important;
                box-shadow : none !important;
                color : white !important;
            }
            .slds-input[readonly]{
                background-color: #16283f !important;
            }
                .slds-tabs_card, .slds-tabs_card.slds-tabs_card
            {
                background-color: #16283f !important;
            }
                .slds-tabs_default__link, .slds-tabs--default__link{
                color : white !important;
                }
                .slds-dropdown__item > a {
                color : white !important;
                }
                 .slds-dropdown__item > a:focus {
                color : white !important;
                background-color: #16283f !important;
                box-shadow : none !important;
                }

    `;

        // Append the styles to the .styleContainer
        this.template.querySelector(".styleContainer")?.appendChild(style);
    }
}