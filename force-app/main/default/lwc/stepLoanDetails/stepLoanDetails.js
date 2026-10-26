import { api, wire, LightningElement, track } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord } from 'lightning/uiRecordApi';
import SANCTION_LOAN_AMOUNT_FIELD from '@salesforce/schema/Product2.Sanctioned_Loan_Amount__c';
import SANCTION_TENURE_FIELD  from '@salesforce/schema/Product2.Sanctioned_Tenor__c';
import EMI_AMOUNT_REPAY_FIELD from '@salesforce/schema/Opportunity.EMI_Amount_Repayment_Schedule__c';
import EMI_AMOUNT_FIELD from '@salesforce/schema/Product2.EMI_Amount__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import STEP_SPECIFIER_FIELD from '@salesforce/schema/Loan_Transaction__c.Step_Specifier__c';
import LOAN_TRANSACTION_OBJECT from '@salesforce/schema/Loan_Transaction__c';
import createAndUpdateStepLoan from '@salesforce/apex/HL_StepLoanController.createAndUpdateStepLoan';
import getStepLoan from '@salesforce/apex/HL_StepLoanController.getStepLoan';
import deleteAndRecalculateStepLoan from '@salesforce/apex/HL_StepLoanController.deleteAndRecalculateStepLoan';
import getTransactionDetails from '@salesforce/apex/HL_StepLoanController.getTransactionDetails';
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';

export default class StepLoanDetails extends LightningElement {
    @api recordId;
    @api productId;
    @api transactionRecordId;
    @track picklistValues;
    @api currentUserOppRole = [];
    @api oppStage = '';
    @api oppSubStage = '';
    @api allowGraceValue;
    @api allowPaymentInGrace
    @api gracePeriodTerms;
    @track isHLUser;

    repayEMIAmount

    validationMessage = '';
    saveIndex;
    showAddButton = true;
    showDeleteConfirmationPopUp = false;
    toBeDeletedStep;
    @track stepSpecifierPicklistValue = [];
    stepSpecifierPicklistallValues = [];
    @track stepLoanTableDetails = [];
    retrievedLoanDetails = {};
    transactionDetails = {};
    stepLoanRecord = {
        stepNumber: 1,
        stepLoanId: '',
        stepIdentifier: '',
        stepLoanAmount: 0,
        stepLoanTenure: null,
        tenurePercentage: null,
        autoCal : false,
        disabledRow: false,
        showEdit : false,
        showDelete: false,
        disableInput: false
    }

    toastTitle = {
        SUCCESS: "Success",
        ERROR: 'Error'
    }

    toastVariant = {
        SUCCESS: "success",
        ERROR: "error"
    }

    toastMessages = {
        GRACE_AFTER_REPAYMENT_NOT_ALLOWED :'You cannot add a grace record after repayment record.',
        GRACE_TENURE_MORE_THAN_TENURE: 'Your grace tenure sum cannot be greater than grace period.',
        PERCENTAGE_MORE_THAN_100: 'Your sum of tenure percentages cannot be greater than 100.',
        STEP_SAVED_SUCCESSFUL: "Step saved successfully.",
        STEP_DELETED_SUCCESSFUL: "Step deleted Successfully.",
        UPDATE_SUCCESSFUL: "Record updated Successfully.",
        SOMETHING_WENT_WRONG: 'Something went wrong.',
        STEP_LOAN_TENURE_CANT_BE_ZERO: 'Step Loan Tenure cannot be zero.',
        STEP_LOAN_AMOUNT_CANT_BE_GREATER_THAN_SANCTION_LA: 'Step Loan Amount cannot be greater than sanctioned loan amount.',
        TOTAL_STEP_LOAN_AMOUNT_CANT_BE_GREATER_THAN_SANCTION_LA: 'Total step loan amount cannot be greater than sanctioned loan amount.',
        STEP_LOAN_REQUIRED_FIELDS: "Please fill all the Step Loan details.",
        LOAN_TENOR_VALIDATION: "Loan Tenor cannot be greater than Total Tenor",
        LOAN_TENOR_EMPTY: "Loan Tenor cannot be Empty.",
        GRACE_PARAMETERS_TO_BE_FILLED: "Please fill Grace Parameters before filling Step Loan.",
        LOAN_TENOR_CANNOT_BE_GREATER_THAN_GRACE_FREQUENCY: 'Loan Tenor cannot be greater than Grace Frequency.',
        STEP_AMOUNT_CANNOT_BE_GREATER_THAN_LOAN_AMOUNT: 'Step Amount cannot be greater than Loan Amount.',
        CANNOT_DELETE_GRACE: 'Cannot delete Grace step when other steps exist.',
        TOTAL_EMI_AMOUNT_CANT_BE_GREATER_THAN_REPAY_EMI_AMOUNT: 'Please enter a lesser step amount.',
        TOTAL_EMI_AMOUNT_CANT_BE_LESSER_THAN_EMI_AMOUNT: 'Please enter a greater step amount'
    }

    showToast(title, msg, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: msg,
                variant: variant,
            }),
        )
    }


    get options() {
        return [{ label: 'Yes', value: 'Yes' }, { label: 'No', value: 'No' }];

    }

    @wire(getRecord, { recordId: '$recordId', fields: [EMI_AMOUNT_REPAY_FIELD] })
    gotLoanFields({ data, error }) {
        if (data) {
            this.retrievedLoanDetails.repayEMIAmount =
                data.fields.EMI_Amount_Repayment_Schedule__c?.value || null;

            console.log('Repay EMI Amount →', this.retrievedLoanDetails.repayEMIAmount);
        } else if (error) {
            console.error('Error fetching Opportunity EMI field:', error);
        }
    }

    // --- Fetch loan-related fields from Product2 ---
    @wire(getRecord, { recordId: '$productId', fields: [SANCTION_LOAN_AMOUNT_FIELD, SANCTION_TENURE_FIELD, EMI_AMOUNT_FIELD] })
    gotProductFields({ data, error }) {
        if (data) {
            this.retrievedLoanDetails = {
                ...this.retrievedLoanDetails,
                sanctionLoanAmount: data.fields.Sanctioned_Loan_Amount__c?.value || null,
                sanctionTenure: data.fields.Sanctioned_Tenor__c?.value || null,
                emiAmount: data.fields.EMI_Amount__c?.value || null
            };

            console.log('Final retrievedLoanDetails →', JSON.stringify(this.retrievedLoanDetails));
        } else if (error) {
            console.error('Error fetching Product2 fields:', error);
        }
    }

    @wire(getObjectInfo, { objectApiName: LOAN_TRANSACTION_OBJECT })
    objectInfo;

    // fetch picklist values dynamically
    @wire(getPicklistValues, {recordTypeId: '$objectInfo.data.defaultRecordTypeId',fieldApiName: STEP_SPECIFIER_FIELD})
    wiredPicklistValues({ data, error }) {
        if (data) {
            this.picklistValues = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
            console.log('Picklist Values:', JSON.stringify(this.picklistValues));
        } else if (error) {
            console.error('Error fetching Step_Specifier__c picklist:', error);
        }
    }

    fetchProducDetails(){
        var inputMapParam = {
            'oppId': this.recordId
        };
        getProductDetails({inputMap : inputMapParam})
        .then(result =>{
            console.log('result product: '+ JSON.stringify(result));
            this.isHLUser = result.isHLRelated;
        })
        .catch(error=>{
            console.error('error in getting product: '+ error)
        })
     }

    fetchTransactionDetailRecords(loanAppId) {
        getTransactionDetails({ loanId: loanAppId, transactionId: this.transactionRecordId}).then(data => {
            this.transactionDetails = data;
            console.log('transactionRecordId 148--',this.transactionRecordId);
             console.log('transactionRecordId 148--',loanAppId);
            console.log('transactionDetails>>'+JSON.stringify(this.transactionDetails));
        }).catch(err => {
            this.showToast(this.toastTitle.ERROR, err?.body?.message, this.toastVariant.ERROR);
        })
    }

    fetchStepLoanRecords(loanAppId) {
        getStepLoan({ loanId: loanAppId, transactionId : this.transactionRecordId})
            .then(response => {
                console.log('resp179=:'+JSON.stringify(response));
                this.stepLoanTableDetails = response;
                console.log('stepLoanTableDetails>>'+JSON.stringify(this.stepLoanTableDetails));
                let percentageSum = 0;
                this.stepLoanTableDetails.forEach(element => {
                    percentageSum += parseFloat(element.tenurePercentage);
                });
                if (percentageSum >= 100) {
                    this.showAddButton = false;
                }
                this.showEditButton();
            }).catch(err => {
                this.showToast(this.toastTitle.ERROR, err?.body?.message, this.toastVariant.ERROR);
            })

    }



    createNewStepLoanRecord() {
        this.stepLoanRecord = {
            stepNumber: this.stepLoanTableDetails.length + 1,
            stepLoanId: '',
            stepIdentifier: '',
            stepLoanAmount: 0,
            stepLoanTenure: null,
            tenurePercentage: null,
            disabledRow: false,
            showEdit : false,
            showDelete: false,
            autoCal : false
        }
    }


    recalculateStepNumbers() {
        for (let i = 0; i < this.stepLoanTableDetails.length; i++) {
            this.stepLoanTableDetails[i].stepNumber = i + 1;
        }
    }

    handleYesDelete() {
     
        deleteAndRecalculateStepLoan({
            toBeDeletedStepLoanId: this.toBeDeletedStep, transactionId : this.transactionRecordId
        }).then(response => {
            try {
                this.showToast(this.toastTitle.SUCCESS, this.toastMessages.STEP_DELETED_SUCCESSFUL, this.toastVariant.SUCCESS);
                this.stepLoanTableDetails = response;
                if(this.stepLoanTableDetails[this.stepLoanTableDetails.length - 1].stepLoanAmount == 0){
                    this.stepLoanTableDetails[this.stepLoanTableDetails.length - 1].showEdit = true;
                    this.stepLoanTableDetails[this.stepLoanTableDetails.length - 1].showDelete = false;
                }
                console.log('stepLoanTableDetails>>'+JSON.stringify(this.stepLoanTableDetails));
                this.showAddButton = true;
                this.showEditButton();
            } catch (error) {
                console.log('step delete error  '+error)
            }
            
        }).catch(err => {
            this.showToast(this.toastTitle.ERROR, err?.body?.message, this.toastVariant.ERROR);
        })
        this.showDeleteConfirmationPopUp = false;

    }

    handleNoDelete() {
        this.showDeleteConfirmationPopUp = false;
    }

    // handleDelete(event) {
    //     this.showDeleteConfirmationPopUp = true;
    //     this.toBeDeletedStep = event.target.dataset.steploanid;
    // }

    handleDelete(event) {
        const index = event.target.dataset.index; 
        const selectedRow = this.stepLoanTableDetails[index];

        console.log('Clicked Row:', selectedRow);

        //Requirement- A grace row cannot be deleted if there are Repayment rows present
        // Check if the specifier is Grace
        if (selectedRow.stepIdentifier === 'Grace') {
           // if (this.stepLoanTableDetails.length > 1) {
                // Grace row has rows after it, Do NOT allow delete
               // console.error('Cannot delete Grace step when other steps exist.');
               // this.showToast(this.toastTitle.ERROR, this.toastMessages.CANNOT_DELETE_GRACE, this.toastVariant.ERROR);
               // return;
            //} else {
                // Grace is the only row, Allow delete 
                this.showDeleteConfirmationPopUp = true;
                this.toBeDeletedStep = selectedRow.stepLoanId;
                return;
           // }
        }

        // For all other steps (non-Grace), allow delete
        this.showDeleteConfirmationPopUp = true;
        this.toBeDeletedStep = selectedRow.stepLoanId;
    }


    handleEdit(event) {
        const index = event.target.dataset.index;
        this.stepLoanTableDetails[index].disabledRow = false;
        this.stepLoanTableDetails[index].disableInput = false;
        this.stepLoanRecord = this.stepLoanTableDetails[index];
    }

    handleAddStep(event) {
        this.createNewStepLoanRecord();
        this.stepLoanTableDetails.push(this.stepLoanRecord);
        console.log('this.stepLoanTableDetails   '+JSON.stringify(this.stepLoanTableDetails))
        // this.enableStepLoanAmountForGrace();
        this.showAddButton = false;
    }

    handleStepLoanChange(event) {
        const index = event.currentTarget.dataset.index;
        const fieldName = event.currentTarget.name;
        const fieldValue = event.currentTarget.value;
        console.log(typeof fieldValue);
        console.log('index  '+index);
        console.log('fieldValue  '+fieldValue);
        if(fieldName == 'autocal'){
            this.stepLoanTableDetails[index].autoCal = event.currentTarget.checked;

        }else{
            if (fieldValue == 0) {
                this.stepLoanTableDetails[index][fieldName] = '';
            } else {
                this.stepLoanTableDetails[index][fieldName] = fieldValue;

                if (fieldName == 'stepLoanTenure') {
                    let percentage = (fieldValue / this.retrievedLoanDetails.sanctionTenure) * 100;
                    console.log('percentage 292>>>'+ percentage);
                    this.stepLoanTableDetails[index].tenurePercentage = (percentage * 100) / 100;
                }

                if (fieldName == 'stepIdentifier' && index == 0 && this.allowGraceValue && fieldValue != 'Grace'){
                }
                this.updateGraceRowsIfComplete();
            }
        }
    }

    calculateTenurePercentage(fieldValue){
        if (this.retrievedLoanDetails && this.retrievedLoanDetails.sanctionTenure) {
            let percentage = (fieldValue / this.retrievedLoanDetails.sanctionTenure) * 100;
            return (percentage * 100) / 100;
        } else{
            console.error('Missing sanctionTenure for calculation.');
            return 0;
        }
    }
 

    handleSaveStep(event) {
        try {
            if (this.checkValidation()) {
            this.saveIndex = event.target.dataset.index;
            this.stepLoanTableDetails[this.saveIndex].showEdit = false;
            this.stepLoanTableDetails[this.saveIndex].showDelete = true;
            this.stepLoanTableDetails[this.saveIndex].disabledRow = true;
            this.stepLoanTableDetails[this.saveIndex].disableInput = true;
            console.log('197>>');
            this.saveAndUpdateStepLoan();
            } else {
                console.log('360')
                this.showToast(this.toastTitle.ERROR, this.validationMessage, this.toastVariant.ERROR);
            }
        } catch (error) {
            console.log('save step error   '+error)
        }
        
    }

    checkValidation() {

        //Add validation for last step row and then enable the below validaition- In progres
       /* if (this.stepLoanRecord.stepIdentifier == 'Repayment'  && this.stepLoanRecord.stepLoanAmount < this.retrievedLoanDetails.emiAmount) {
            this.validationMessage = this.toastMessages.TOTAL_EMI_AMOUNT_CANT_BE_LESSER_THAN_EMI_AMOUNT
            return false;
        }*/
        if(this.isHLUser){
            if (this.stepLoanRecord.stepIdentifier == '' /*|| (this.stepLoanRecord.stepLoanAmount == null && this.stepLoanRecord.stepIdentifier == 'Repayment')*/ || this.stepLoanRecord.stepLoanTenure == null /*|| (this.stepLoanRecord.stepLoanAmount == "" && this.stepLoanRecord.stepIdentifier == 'Repayment')*/ || this.stepLoanRecord.stepLoanTenure == "") {
                this.validationMessage = this.toastMessages.STEP_LOAN_REQUIRED_FIELDS;
                return false;
            }
       }
       else{
            if (this.stepLoanRecord.stepIdentifier == '' || (this.stepLoanRecord.stepLoanAmount == null && this.stepLoanRecord.stepIdentifier == 'Repayment') || this.stepLoanRecord.stepLoanTenure == null || (this.stepLoanRecord.stepLoanAmount == "" && this.stepLoanRecord.stepIdentifier == 'Repayment') || this.stepLoanRecord.stepLoanTenure == "") {
                this.validationMessage = this.toastMessages.STEP_LOAN_REQUIRED_FIELDS;
                return false;
            }
       }
       
        if (this.stepLoanRecord.stepIdentifier == '' /*|| (this.stepLoanRecord.stepLoanAmount == null && this.stepLoanRecord.stepIdentifier == 'Repayment')*/ || this.stepLoanRecord.stepLoanTenure == null /*|| (this.stepLoanRecord.stepLoanAmount == "" && this.stepLoanRecord.stepIdentifier == 'Repayment')*/ || this.stepLoanRecord.stepLoanTenure == "") {
            this.validationMessage = this.toastMessages.STEP_LOAN_REQUIRED_FIELDS;
            return false;
        }
        if (this.stepLoanRecord.stepLoanTenure == 0) {
            this.validationMessage = this.toastMessages.STEP_LOAN_TENURE_CANT_BE_ZERO;
            return false;
        }
        if (this.stepLoanRecord.stepLoanAmount > this.retrievedLoanDetails.sanctionLoanAmount) {
            this.validationMessage = this.toastMessages.STEP_LOAN_AMOUNT_CANT_BE_GREATER_THAN_SANCTION_LA;
            return false;
        }
        if (!this.checkGraceTenure()) {
            this.validationMessage = this.toastMessages.GRACE_TENURE_MORE_THAN_TENURE;
            return false;
        }
        if (!this.checkPercentageSum()) {
            this.validationMessage = this.toastMessages.PERCENTAGE_MORE_THAN_100;
            return false;
        }
        if(this.checkGraceAfterRepayment()){
            this.validationMessage = this.toastMessages.GRACE_AFTER_REPAYMENT_NOT_ALLOWED;
            return false;
        }
        if (!this.checkTotalStepAmount()) {
            this.validationMessage = this.toastMessages.TOTAL_STEP_LOAN_AMOUNT_CANT_BE_GREATER_THAN_SANCTION_LA;
            return false;
        }
       /* if (this.stepLoanRecord.stepLoanAmount > this.retrievedLoanDetails.repayEMIAmount) {
            this.validationMessage = this.toastMessages.TOTAL_EMI_AMOUNT_CANT_BE_GREATER_THAN_REPAY_EMI_AMOUNT;
            return false;
        }*/

        
        return true;
    }



    checkGraceAfterRepayment(){
        if(this.stepLoanTableDetails.length >=2){
       if(this.stepLoanTableDetails[this.stepLoanTableDetails.length-2].stepIdentifier == 'Repayment'
        && this.stepLoanTableDetails[this.stepLoanTableDetails.length-1].stepIdentifier == 'Grace'
       ){
        return true;
       }
    }
       return false;
    }

    checkGraceTenure() {
        let graceTenureTillNow = 0;
        this.stepLoanTableDetails.forEach(data => {
            if (data.stepIdentifier == 'Grace') {
                graceTenureTillNow += parseInt(data.stepLoanTenure);
            }
        })
        // if (graceTenureTillNow > this.transactionDetails.gracePeriod) {
        //     return false;
        // }
        if (graceTenureTillNow > this.gracePeriodTerms) {
            return false;
        }
        return true;

    }

    calculateLastStepTenure(){
        if (this.retrievedLoanDetails || this.retrievedLoanDetails.sanctionTenure) {
            let currentTotalStepTenure = 0
            this.stepLoanTableDetails.forEach(data => {
                currentTotalStepTenure += parseInt(data.stepLoanTenure) || 0;
            })
            return this.retrievedLoanDetails.sanctionTenure - currentTotalStepTenure;
        } else {
            console.error('Missing sanctionTenure.');
            return 0;
        }
        
    }

    calculateLastStepLoanAmount(){
        if (this.retrievedLoanDetails || this.retrievedLoanDetails.sanctionLoanAmount) {
            let currentTotalStepLoanAmount = 0
            this.stepLoanTableDetails.forEach(data => {
                currentTotalStepLoanAmount += parseInt(data.stepLoanAmount) || 0;
            })
            return this.retrievedLoanDetails.sanctionLoanAmount - currentTotalStepLoanAmount;
        } else {
            console.error('Missing sanctionLoanAmount.');
            return 0;
        }
        
    }

    enableStepLoanAmountForGrace() {
        try {
            console.log('1  '+JSON.stringify(this.stepLoanTableDetails));
            this.stepLoanTableDetails.forEach((row, index) => {
                console.log(`Checking row ${index}, identifier: ${row.stepIdentifier}`);
                if (row.stepIdentifier === 'Grace') {
                    const input = this.template.querySelector(`lightning-input[name="stepLoanTenure"][data-index="${index}"]`);
                    if (input) {
                        console.log('Disabling input for index', index);
                        input.disabled = true;
                    } else {
                        console.warn(`Input not found for index ${index}`);
                    }
                }
            });
        } catch (error) {
            console.error('enableStepLoanAmountForGrace error:', error);
        }
    }

    checkPercentageSum() {
       let percentageSum = 0;
        console.log('stepLoanTableDetails 568---', JSON.stringify(this.stepLoanTableDetails));

        this.stepLoanTableDetails.forEach(element => {
            if (element.tenurePercentage != null && element.tenurePercentage != '') {
                 const value = parseFloat(element.tenurePercentage);
                percentageSum += value;
            }
        });

        console.log('percentageSum 465', percentageSum);

        //percentageSum = parseFloat(percentageSum.toFixed(0));
        console.log('percentageSum', percentageSum);

        if (percentageSum > 100) {
            return false;
        }else if (percentageSum == 100) {
            this.stepLoanTableDetails[this.stepLoanTableDetails.length - 1].stepLoanAmount = 0;
            this.saveIndex = this.stepLoanTableDetails.length - 1;
            this.stepLoanRecord = this.stepLoanTableDetails[this.stepLoanTableDetails.length - 1];
            createAndUpdateStepLoan();
            this.showAddButton = false;

        }
        return true;
    }

    checkTotalStepAmount(){
        let stepAmount = 0;
        let currentStepTenure = 0
        let totalStepAmount = 0

        this.stepLoanTableDetails.forEach(element => {
            stepAmount = parseInt(element.stepLoanAmount) || 0;
            currentStepTenure = parseInt(element.stepLoanTenure) || 0;
            totalStepAmount += stepAmount * currentStepTenure;
        });
        
        console.log("totalStepAmount  "+totalStepAmount + "  stepAmount  "+stepAmount + "  currentStepTenure  "+currentStepTenure + 'remaining loan amount  '+(this.retrievedLoanDetails.sanctionLoanAmount - totalStepAmount))
        if ((totalStepAmount > this.retrievedLoanDetails.sanctionLoanAmount)) {
            return false
        } else if ((totalStepAmount == this.retrievedLoanDetails.sanctionLoanAmount)) {
            this.stepLoanTableDetails[this.stepLoanTableDetails.length - 1].stepLoanAmount = 0;
            this.saveIndex = this.stepLoanTableDetails.length - 1;
            this.stepLoanRecord = this.stepLoanTableDetails[this.stepLoanTableDetails.length - 1];
            this.showAddButton = false;
            createAndUpdateStepLoan();
        }
        return true;
    }

    sendStepLoanCount(){
        this.dispatchEvent(
            new CustomEvent("updatecount", {
                detail: {
                    stepLoanCount: this.stepLoanTableDetails.length,
                },
            })
        );
    }
    
    saveAndUpdateStepLoan() {
        console.log('this.stepLoanRecord save n update  '+JSON.stringify(this.stepLoanRecord))
        createAndUpdateStepLoan({
            stepLoanDetails: this.stepLoanRecord,
            loanApplicationId: this.recordId,
            relatedTransactionId: this.transactionRecordId //this.transactionDetails.id
        })
            .then(response => {
                this.showToast(
                    this.toastTitle.SUCCESS,
                    this.toastMessages.STEP_SAVED_SUCCESSFUL,
                    this.toastVariant.SUCCESS);
                this.stepLoanTableDetails[this.saveIndex].stepLoanId = response;
                this.showAddButton = true;
                this.checkPercentageSum();
                this.checkTotalStepAmount();
                this.sendStepLoanCount();
                this.showEditButton();

            }).catch(err => {
                this.showToast(this.toastTitle.ERROR, err?.body?.message, this.toastVariant.ERROR);
            })
    }

    

    showEditButton() {
        try {
            console.log('this.stepLoanTableDetails  '+JSON.stringify(this.stepLoanTableDetails))

            if (!this.stepLoanTableDetails || this.stepLoanTableDetails.length === 0) {
                console.log('No stepLoanTableDetails data found. Exiting.');
                return;
            }

            this.stepLoanTableDetails.forEach(row => {
                row.showEdit = false;
                row.showDelete = true;
            });

            let totalTenure = 0;
            this.stepLoanTableDetails.forEach(row => {
                totalTenure += Number(row.stepLoanTenure);
            });

            const lastIndex = this.stepLoanTableDetails.length - 1;
            const lastRow = this.stepLoanTableDetails[lastIndex];

            console.log('lastRow.stepIdentifier  '+lastRow.stepIdentifier)
            console.log('lastRow.stepLoanAmount  '+lastRow.stepLoanAmount)
            if (lastRow.stepIdentifier === 'Repayment' && lastRow.stepLoanAmount > 0) {
                lastRow.showEdit = true;
            } 
            else if (lastRow.stepLoanAmount == 0) {
                for (let i = lastIndex - 1; i >= 0; i--) {
                    const currentRow = this.stepLoanTableDetails[i];
                    if (currentRow.stepIdentifier === 'Repayment') {
                        currentRow.showEdit = true;
                        break; 
                    }
                }

                console.log('totalTenure  '+totalTenure)
                console.log('this.retrievedLoanDetails.sanctionTenure  '+this.retrievedLoanDetails.sanctionTenure)
                if (totalTenure != this.retrievedLoanDetails.sanctionTenure) {
                    console.log('tenure is not equal to step tenure sum')
                    lastRow.showEdit = true;
                }
            }

            if (this.stepLoanTableDetails.length == 1 && this.stepLoanTableDetails[0].stepIdentifier === 'Grace' && this.stepLoanTableDetails) {
                this.stepLoanTableDetails[0].showEdit = false;
            }
        } catch (error) {
            console.log('error: '+error)
        }
        
    }


    connectedCallback(){
        this.fetchProducDetails();
        this.fetchTransactionDetailRecords(this.recordId);
        this.fetchStepLoanRecords(this.recordId);

        setTimeout(() => {
            console.log('1currentUserOppRole: '+this.currentUserOppRole);
            console.log('1oppStage: '+this.oppStage);
            console.log('1oppSubStage: '+this.oppSubStage);

            var disableControls = false;
            if(this.currentUserOppRole.includes('OPS Maker') || this.currentUserOppRole.includes('OPS Author')){
                disableControls = true;
            }
            
            if(disableControls){
                console.log('disable controls--');
                this.stepLoanTableDetails = this.stepLoanTableDetails.map(row => { return { ...row, showEdit: false, showDelete: false }; });
                this.showAddButton = false;
            }
        }, 3000);
    }

    renderedCallback(){

    }

 updateGraceRowsIfComplete() {
    const graceRows = this.stepLoanTableDetails.filter(row => row.stepIdentifier === 'Grace');
    if (graceRows.length === 0) return;
    const totalGraceTenure = graceRows.reduce((sum, row) => sum + (parseInt(row.stepLoanTenure) || 0), 0);

    if (totalGraceTenure === this.gracePeriodTerms) {
        const lastGraceRow = graceRows[graceRows.length - 1];
        const index = this.stepLoanTableDetails.findIndex(row => row.stepLoanId === lastGraceRow.stepLoanId);

        if (index !== -1) {
        this.stepLoanTableDetails[index].stepLoanAmount = 0;
        }
        this.showAddButton = false;
    } else {
        this.showAddButton = true;

        // Optional: Reset stepLoanAmount for grace rows if needed
        // For example, remove 0 from last grace row if total tenure is no longer equal
        // const lastGraceRow = graceRows[graceRows.length - 1];
        // const index = this.stepLoanTableDetails.findIndex(row => row.stepLoanId === lastGraceRow.stepLoanId);
        // if (index !== -1 && this.stepLoanTableDetails[index].stepLoanAmount === 0) {
        // You may want to reset to a default amount, e.g., 1 or original amount
        // this.stepLoanTableDetails[index].stepLoanAmount = 1;
        // }
    }
    }

}