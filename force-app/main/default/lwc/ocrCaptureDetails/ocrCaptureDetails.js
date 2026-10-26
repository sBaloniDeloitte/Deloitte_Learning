import { api, wire, track, LightningElement } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getOcrLoanTransaction from '@salesforce/apex/Hl_OcrDetailsController.getOcrLoanTransaction';
import { RefreshEvent } from "lightning/refresh";
import createOcrCapture from '@salesforce/apex/Hl_OcrDetailsController.createOcrCapture';
import getOcrCaptureTransaction from '@salesforce/apex/Hl_OcrDetailsController.getOcrCaptureTransaction';
import upsertLoanTransaction from '@salesforce/apex/Hl_OcrDetailsController.upsertLoanTransaction';
import deleteLoanTransaction from '@salesforce/apex/Hl_OcrDetailsController.deleteLoanTransaction';
import fetchBusinessDateFromIntDetail from '@salesforce/apex/Utility.fetchBusinessDateFromIntDetail';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import canUserEditRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.canUserEditRecord';
import getOpportunityTeamMembers from '@salesforce/apex/AHL_LoanDetailsController.getOpportunityTeamMembers';
import USERID_FIELD from "@salesforce/user/Id";
import ProfileName from '@salesforce/schema/User.Profile.Name';
import STAGE_FIELD from "@salesforce/schema/Opportunity.StageName";
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";
const FIELDS = ['Opportunity.Name'];

export default class OcrCaptureDetails extends NavigationMixin(LightningElement) {
    @api recordId;
    @track steps = [];
    @track todayDate;
    @track applicationName;
    @track parentOcrId = '';
    @track totalReceivable;
    @track totalOcrPaid=0;
    @track totalBuilderDemand = 0;
    @track isDisable = true;
    oppStage = '';
    oppSubStage = '';
    currentUserOppRole = [];
    userId = USERID_FIELD;
    userProfileName;
    
    _isOcrEditable;
    @api
    get isOcrEditable() 
    {
        return this._isOcrEditable; 
    }
    set isOcrEditable(val) {
        this._isOcrEditable = val;
        console.log(' this._isOcrEditable', this._isOcrEditable);
    }

    

    @track ocrCaptureFields = [
        { label: 'OCR Receivable', fieldName: 'ocrReceivable', fieldValue: this.totalReceivable, type: 'number', disabled: true },
        { label: 'Total Builder Demand Raised', fieldName: 'totalBuilderDemandRaised', fieldValue: this.totalBuilderDemand, type: 'number', disabled: true },
        { label: 'Total OCR Paid', fieldName: 'totalOcrPaid', fieldValue: this.totalOcrPaid, type: 'number', disabled: true }
    ];
    ocrCapture = {
        ocrReceivable: '',
        totalBuilderDemandRaised: this.totalBuilderDemand,
        totalOcrPaid: this.totalOcrPaid
    };

    _totalBuilderDemandRaised;
    @api
    set totalBuilderDemandRaised(value) {
        this._totalBuilderDemandRaised = value;
        this.calculateReceivable();
        this.initializeFields(); // Reinitialize when value changes
    }
    get totalBuilderDemandRaised() {
        return this._totalBuilderDemandRaised;
    }

    _customerPortion;
    @api
    set customerPortion(value) {
        this._customerPortion = value;
        this.calculateReceivable();
        this.initializeFields(); // Reinitialize when value changes
    }

    get customerPortion() {
        return this._customerPortion;
    }


    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.applicationName = data.fields.Name.value;
            console.log(this.applicationName);
            console.log(data.fields.Name.value);

        } else if (error) {
            console.error('Error fetching record name:', error);
        }
    }
    @wire(getRecord, { recordId: USERID_FIELD, fields: [ProfileName] })
    userDetails({ error, data }) {
        if (data) {
            if (data.fields.Profile.value != null) {
                this.userProfileName = data.fields.Profile.value.fields.Name.value;
            }
        }
    }

    //Sanwar - Start
    @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD, SUBSTAGE_FIELD] })
    opportunity({ error, data }) {
        if (data) {
            this.oppStage = data.fields.StageName.value;
            this.oppSubStage = data.fields.Sub_stage__c.value;
            console.log('Opp sub stage', this.oppSubStage);
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
            console.log('data ', data);
            data.forEach(item => {
                console.log('User Data');
                console.log('user id', item.UserId);
                if (item.UserId == USERID_FIELD) {
                    this.currentUserOppRole.push(item.TeamMemberRole);
                }
            })
            console.log('Current user role ', this.currentUserOppRole);
        } else if (error) {
            this.handleError(error, 'gotLoanFields');
            this.showToast(this.toastTitle.ERROR, this.toastMessages.SOMETHING_WENT_WRONG, this.toastVariant.ERROR);
        }
    }

    handleVisibility() {
        console.log('Stage', this.oppStage);
        console.log(' Sub stage', this.oppSubStage);
        if ((this.oppStage == 'Disbursement' && this.oppSubStage == 'Ops Maker' && (this.currentUserOppRole.includes('OPS Maker') || this.currentUserOppRole.includes('Credit Officer'))) ||
            (this.oppStage == 'PSV' && this.oppSubStage == 'PSV Sales' && this.currentUserOppRole.includes('Sales'))
            ) { // || this.userProfileName == 'System Administrator'//sanwar(17/12/2025)
            console.log('make is editable');
            this.isDisable = false;
            this.steps = this.steps.map((step, i, arr) => {
                return {
                    ...step,
                    disabled: false,                 
                    disabledAddBtn: i !== arr.length - 1 
                };
            });
        }
        else {
            this.isDisable = true;
            this.steps = this.steps.map(step => {
                return {
                    ...step,
                    disabled: true,
                    disabledAddBtn: true
                };
            });
        }
    }//Sanwar End

    connectedCallback() {
        this.getOcrCapture();
        fetchBusinessDateFromIntDetail({})
        .then(result =>{
            if(result){
                this.todayDate = new Date(result);
            }
        })
        .catch(error => {
            console.error('Error fetch Business date', error);
        });
    }

    calculateReceivable() {
        if (!isNaN(this.totalBuilderDemandRaised) && !isNaN(this.customerPortion) && this.customerPortion !== 0) {
            const calculatedReceivable = (this.customerPortion / 100) * this.totalBuilderDemandRaised;
            this.totalReceivable = parseFloat(calculatedReceivable.toFixed(2)); // Round to 2 decimals

            // Update ocrCapture and UI fields
            this.ocrCapture.ocrReceivable = this.totalReceivable;
            this.ocrCaptureFields = this.ocrCaptureFields.map(f =>
                f.fieldName === 'ocrReceivable' ? { ...f, fieldValue: this.totalReceivable } : f
            );
        }
    }

    createNewStep(index) {
        return {
            index,
            builderDemand: null,
            paidAmount: null,
            receiptDate: null,
            remarks: null,
            files: [],
            disabled: false
        };
    }
    initializeFields() {
        this.ocrCaptureFields = [
            { label: 'OCR Receivable', fieldName: 'ocrReceivable', fieldValue: this.totalReceivable, type: 'number', disabled: true },
            { label: 'Total Builder Demand Raised', fieldName: 'totalBuilderDemandRaised', fieldValue: this.totalBuilderDemand, type: 'number', disabled: true },
            { label: 'Total OCR Paid', fieldName: 'totalOcrPaid', fieldValue: this.totalOcrPaid, type: 'number', disabled: true }
        ];

        this.ocrCapture = {
            ocrReceivable: this.totalReceivable,
            totalBuilderDemandRaised: this.totalBuilderDemand,
            totalOcrPaid: this.totalOcrPaid
        };
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.ocrCapture[field] = value;
        this.ocrCaptureFields = this.ocrCaptureFields.map(f =>
            f.fieldName === field ? { ...f, fieldValue: value } : f
        );
        console.log(this.ocrCapture);
    }

    handleStepChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const field = event.target.dataset.field;
        const value = event.target.value;
        //Added by kalpesh
        this.steps[index][field] = value;

        if (field === 'builderDemand') {
            this.totalBuilderDemand = 0;  // Reset total before summing
            this.steps.forEach(step => {
                const num = parseFloat(step.builderDemand);
                this.totalBuilderDemand += isNaN(num) ? 0 : num;
            });
            this.ocrCaptureFields = this.ocrCaptureFields.map(field => {
                if (field.fieldName === 'totalBuilderDemandRaised') {
                    return { ...field, fieldValue: this.totalBuilderDemand };
                }
                return field;
            });
        }
        if (field === 'paidAmount') {
            this.totalOcrPaid = 0;
            this.steps.forEach(step => {
                const num = parseFloat(step.paidAmount);
                this.totalOcrPaid += isNaN(num) ? 0 : num;
            });
            this.ocrCaptureFields = this.ocrCaptureFields.map(field => {
                if (field.fieldName === 'totalOcrPaid') {
                    return { ...field, fieldValue: this.totalOcrPaid };
                }
                return field;
            });
        }

        if (field === 'receiptDate') {
            const selectedDate = new Date(value);
            const today = new Date();
            today.setHours(0, 0, 0, 0); // Normalize to midnight
            console.log('selected',selectedDate);
            console.log('todatyyy',this.todayDate);
            if (selectedDate > this.todayDate) {
                this.showToast('Invalid Date', 'Receipt date cannot be in the future.', 'error');
                return;
            }
        }
        this.steps[index][field] = value;
    }

    getOcrCapture() {
        getOcrCaptureTransaction({ recordId: this.recordId })
            .then(result => {
                console.log('this.recordId>>>', this.recordId);
                if (result && result.length > 0) {
                    const paid = result[0]['OCR_Definition__r.Total_OCR_Paid__c'];
                    console.log('paid', paid);
                    //  this.totalOcrPaid = !isNaN(paid) && paid !== null && paid !== undefined ? parseFloat(paid) : 0;
                    var totalOcrPaidSum = 0;
                    var totalBuilderDemand = 0;

                    this.initializeFields();
                    result.forEach(record => {
                        totalOcrPaidSum += parseFloat(record.Paid_Amount__c) || 0;
                        totalBuilderDemand += parseFloat(record.Builder_Demand__c) || 0;
                    });
                    this.totalOcrPaid = totalOcrPaidSum;
                    this.totalBuilderDemand = totalBuilderDemand;
                    console.log('total ocr', this.totalOcrPaid);
                    this.calculateReceivable();

                    this.initializeFields();

                    const mappedSteps = result.map(record => ({
                        Id: record.Id,
                        index: record.Step_Sequence__c,
                        builderDemand: record.Builder_Demand__c || '',
                        paidAmount: record.Paid_Amount__c || '',
                        receiptDate: record.Receipt_Date__c || '',
                        remarks: record.Remark__c || '',
                        ocrDefination:record.OCR_Definition__c || null,
                        files: (record.files || []).map(file => ({
                            id: file.Id,
                            name: file.Name,
                            title: file.Title,
                            fileName: file.Title,
                            fileType: file.FileType,
                            size: file.ContentSize,
                            downloadUrl: file.DownloadUrl,
                            contentDocId: file.Content_Document_Id__c
                        })),
                        disabled: true
                    }));
                    this.steps = [...mappedSteps];
                    if(!this._isOcrEditable){
                        this.steps = this.steps.map((step, i, arr) => {
                            return {
                                ...step,
                                disabled: true
                            };
                        });
                    }
                    setTimeout(() => {
                        this.handleVisibility();
                    }, 1000);
                    // canUserEditRecord({recordId: this.recordId})
                    // .then(result => {
                    //     if(result){
                    //         this.isDisable = true;
                    //         this.steps = this.steps.map(step => {
                    //             return { 
                    //                 ...step,
                    //                 disabled: true ,
                    //                 disabledAddBtn: true
                    //             };
                    //         });
                    //     }
                    // })
                }
                else {
                    this.steps = [this.createNewStep(1)];
                    if(!this._isOcrEditable){
                        this.steps = this.steps.map((step, i, arr) => {
                            return {
                                ...step,
                                disabled: true
                            };
                        });
                    }

                    console.log('steps data', JSON.stringify(this.steps));
                    setTimeout(() => {
                        this.handleVisibility();
                    }, 1000);
                    // canUserEditRecord({recordId: this.recordId})
                    // .then(result => {
                    //     if(result){
                    //         this.isDisable = true;
                    //         this.steps = this.steps.map(step => {
                    //             return { 
                    //                 ...step,
                    //                 disabled: true,
                    //                 disabledAddBtn: true
                    //             };
                    //         });
                    //     }
                    // })
                }
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetch OCR transaction', error);
                this.isLoading = false;
                this.showToast('Error', 'Failed to fetch OCR details', 'error');
            });
    }

    handleAddRow(event) {
        const index = parseInt(event.target.dataset.index, 10);
        console.log('steps', JSON.stringify(this.steps));
        if (this.steps[index].builderDemand <= 0 || this.steps[index].builderDemand == null) {
            this.showToast('Action Denied', 'Builder demand should be greater than zero.', 'warning');
            return;
        }
        if (this.steps[index].paidAmount <= 0 || this.steps[index].paidAmount == null) {
            this.showToast('Action Denied', 'OCR Paid should be greater than zero.', 'warning');
            return;
        }
        /*if (this.steps[index].receiptDate == null) {
            this.showToast('Action Denied', 'Receipt Date is mandatory', 'warning');
            return;
        }
        if (this.steps[index].remarks == null) {
            this.showToast('Action Denied', 'Remark is mandatory', 'warning');
            return;
        }*/
        this.steps[index].disabled = true;
        this.steps[index].disabledAddBtn = true;
        const newIndex = this.steps.length + 1;
        this.steps = [...this.steps, this.createNewStep(newIndex)];
        console.log('steps', JSON.stringify(this.steps));
    }

   async handleDeleteRow(event) {
        const index = parseInt(event.target.dataset.index, 10);
        if (this.steps.length === 1) {
            this.showToast('Action Denied', 'At least one step is required.', 'warning');
            return;
        }

        const stepToDelete = this.steps[index];
        console.log('stepToDelete?>>>', JSON.stringify(this.steps));
        console.log('stepToDelete?>>>', stepToDelete.Id);
       const result= await deleteLoanTransaction({ recordId: stepToDelete.Id })
            if(result=='success') {
                this.showToast('Success', `Record has been deleted successfully.`, 'success');
            }
        this.steps.splice(index, 1);
        // Make the previous row editable if it exists and was disabled
        if (index > 0 && this.steps[index - 1].disabled) {
            this.steps[index - 1].disabled = false;
        }
        this.steps = this.steps.map((s, i, arr) => ({
            ...s,
            disabledAddBtn: i !== arr.length - 1
        }));
        // Calculate new totals after deletion
        let totalBuilderDemand = 0;
        let totalOcrPaid = 0;

        this.steps.forEach(step => {
            totalBuilderDemand += parseFloat(step.builderDemand) || 0;
            totalOcrPaid += parseFloat(step.paidAmount) || 0;
        });
        this.ocrCaptureFields = this.ocrCaptureFields.map(field => {
            if (field.fieldName === 'totalBuilderDemandRaised') {
                return { ...field, fieldValue: totalBuilderDemand };
            }
            if (field.fieldName === 'totalOcrPaid') {
                return { ...field, fieldValue: totalOcrPaid };
            }
            return field;
        });

        this.steps = this.steps.map((step, i) => ({ ...step, index: i + 1 }));
        if(stepToDelete.Id){
            console.log('stepToDelete.Id inside>>'+stepToDelete.Id);
            this.updateIndex();
        }
         this.dispatchEvent(
                    new CustomEvent('ocrsaved', {
                        detail: { recordId: stepToDelete.Id }
                    })
                );
        
    }
    handleEditRow(event) {
        const index = parseInt(event.target.dataset.index, 10);
        console.log('steps', JSON.stringify(this.steps));
        this.steps[index].disabled = false;

    }
    async handleSave() {
        try {
            for (let i = 0; i < this.steps.length; i++) {
                const step = this.steps[i];

                if (!step.builderDemand || isNaN(parseFloat(step.builderDemand)) || parseFloat(step.builderDemand) === 0) {
                    this.showToast('Action Denied', `Builder Demand is required and must be a number greater than 0 in row ${i + 1}.`, 'warning');
                    return;
                }

                if (step.paidAmount == null || isNaN(parseFloat(step.paidAmount)) || parseFloat(step.paidAmount) <= 0) {
                    this.showToast('Action Denied', `Paid Amount must be a number greater than 0 in row ${i + 1}.`, 'warning');
                    return;
                }

                if (!step.receiptDate) {
                    this.showToast('Action Denied', `Receipt Date is mandatory in row ${i + 1}.`, 'warning');
                    return;
                }
                if (!step.remarks) {
                    this.showToast('Action Denied', `Remark is mandatory in row ${i + 1}.`, 'warning');
                    return;
                }
            }
            this.initializeFields();
            const parentValues = {
                OCR_Receivable__c: parseFloat(this.ocrCapture.ocrReceivable) || 0,
                Total_Builder_Demand_Raised__c: parseFloat(this.ocrCapture.totalBuilderDemandRaised) || 0,
                Total_OCR_Paid__c: parseFloat(this.ocrCapture.totalOcrPaid) || 0
            };
            console.log('this.recordId>>>>',this.recordId);
            const context = {
                recordId: this.recordId,
                ocrReceivable: this.ocrCapture.ocrReceivable && !isNaN(this.ocrCapture.ocrReceivable) ? parseFloat(this.ocrCapture.ocrReceivable) : null,
                totalBuilderDemandRaised: this.ocrCapture.totalBuilderDemandRaised && !isNaN(this.ocrCapture.totalBuilderDemandRaised) ? parseFloat(this.ocrCapture.totalBuilderDemandRaised) : null,
                totalOcrPaid: this.ocrCapture.totalOcrPaid && !isNaN(this.ocrCapture.totalOcrPaid) ? parseFloat(this.ocrCapture.totalOcrPaid) : null
            };
            console.log(context);

            // upserting the parent transaction
            const result = await upsertLoanTransaction({ fieldValues: parentValues, recordId: this.recordId, recordTypeDevName: 'OCR_Capture_Transaction' });
            if (result) {
                this.parentOcrId = result;
                console.log('Parent OCR ID:', result);
                const stepsPayload = this.steps.map(step => ({
                    Id: step.Id || undefined, //this will include id if present
                    Step_Sequence__c: step.index,
                    receiptDate: step.receiptDate || null,
                    OCR_Definition__c: this.parentOcrId,
                    remarks: step.remarks || null,
                    paidAmount: step.paidAmount && !isNaN(step.paidAmount) ? parseFloat(step.paidAmount) : null,
                    builderDemand: step.builderDemand && !isNaN(step.builderDemand) ? parseFloat(step.builderDemand) : null,
                    files: step.files || []
                }));
                console.log('stepsPayload', JSON.stringify(stepsPayload));

                //Creating the child OCR capture
                const childResult = await createOcrCapture({ steps: stepsPayload, context });
                console.log('result >>>', JSON.stringify(result));
                this.steps = this.steps.map((step, i) => {
                    const saved = childResult[i];
                    return {
                        ...step,
                        Id: saved ? saved.Id : step.Id,
                        index: i + 1
                    };
                });

                this.steps = this.steps.map((s, i, arr) => ({
                    ...s,
                    disabled: true,
                    disabledAddBtn: i !== arr.length - 1 // enable add only for last row
                }));

                console.log('Updated steps with Ids:', JSON.stringify(this.steps));
                this.dispatchEvent(new RefreshEvent()); //refreshingg ui

                //this.steps = [...this.steps, this.createNewStep(this.steps.length + 1)]; //commenting this as need not to crate another step
                this.showToast('Success', 'OCR Captured successfully.', 'success');
                this.dispatchEvent(
                    new CustomEvent('ocrsaved', {
                        detail: { recordId: this.recordId }
                    })
                );
            }
        } catch (error) {
            console.error('Error in handleSave:', error , error.message);
           
            this.showToast('Error', 'Failed to create Loan Transactions.', 'error');
        }
    }


    handleUploadFinished(event) {
        const stepIndex = parseInt(event.target.dataset.id, 10);
        if (isNaN(stepIndex) || stepIndex < 0 || stepIndex >= this.steps.length) {
            console.error('Invalid step index:', stepIndex);
            this.showToast('Error', 'Invalid step index for file upload.', 'error');
            return;
        }

        const uploadedFiles = event.detail.files;
        const step = this.steps[stepIndex];

        if (!step.files) {
            step.files = [];
        }

        uploadedFiles.forEach(file => { //variables to array
            step.files.push({
                fileName: file.name,
                contentDocId: file.documentId,
                contentDocLink: `/lightning/r/ContentDocument/${file.documentId}/view`
            });
        });

        //step.files.push(...uploadedFiles); //array to array
        console.log(`Files for step ${stepIndex}:`, JSON.stringify(step.files));
        this.showToast('Success', 'Document uploaded successfully.', 'success');
    }

    // @track filePreviewUrl ='';
    handlePreview(event) {
        const contentDocId = event.target.dataset.id;
        //this.filePreviewUrl = event.target.dataset.url + '#toolbar=0';
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: contentDocId
            }
        })
    }


    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
     async updateIndex(){
        try{
         const context = {
                recordId: this.recordId,
                ocrReceivable: this.ocrCapture.ocrReceivable && !isNaN(this.ocrCapture.ocrReceivable) ? parseFloat(this.ocrCapture.ocrReceivable) : null,
                totalBuilderDemandRaised: this.ocrCapture.totalBuilderDemandRaised && !isNaN(this.ocrCapture.totalBuilderDemandRaised) ? parseFloat(this.ocrCapture.totalBuilderDemandRaised) : null,
                totalOcrPaid: this.ocrCapture.totalOcrPaid && !isNaN(this.ocrCapture.totalOcrPaid) ? parseFloat(this.ocrCapture.totalOcrPaid) : null
            };
            console.log(context);
             const stepsPayload = this.steps.map(step => ({
                    Id: step.Id || undefined, //this will include id if present
                    Step_Sequence__c: step.index,
                    receiptDate: step.receiptDate || null,
                    OCR_Definition__c: step.ocrDefination,
                    remarks: step.remarks || null,
                    paidAmount: step.paidAmount && !isNaN(step.paidAmount) ? parseFloat(step.paidAmount) : null,
                    builderDemand: step.builderDemand && !isNaN(step.builderDemand) ? parseFloat(step.builderDemand) : null,
                    files: step.files || []
                }));
                console.log('stepsPayload', JSON.stringify(stepsPayload));

                //Creating the child OCR capture
                const childResult = await createOcrCapture({ steps: stepsPayload, context });
        }catch (error) {
        console.error('Error updating step sequence:', error);
    }
    }

    // @wire(getOcrLoanTransaction, { recordId: '$recordId' })
    // wiredData({ error, data }) {
    //     if (data) {
    //         // handle data if needed
    //     } else if (error) {
    //         console.error('Error fetching loan transactions:', JSON.stringify(error));
    //     }
    // }
}