import { LightningElement,api,track,wire } from 'lwc';
import { updateRecord } from "lightning/uiRecordApi";
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import FORM_FACTOR from '@salesforce/client/formFactor';
import USER_ID from '@salesforce/user/Id'; 
import NAME_FIELD from '@salesforce/schema/User.Name';
import checkShowSubmit from '@salesforce/apex/Credit_FIVerificationController.checkShowSubmit';
import currentLoggedInUserAssignedUser from '@salesforce/apex/Credit_FIVerificationController.currentLoggedInUserAssignedUser';
import showDispositionDropDown from  '@salesforce/apex/Credit_FIVerificationController.showDispositionDropDown';
import updateAssignedUser from '@salesforce/apex/RecordActionButtonController.updateAssignedUser';
import saveRemarksFI from '@salesforce/apex/Credit_FIVerificationController.saveRemarksFI';
import setRecordButtons from '@salesforce/apex/RecordActionButtonController.setRecordButtons';
import sendNotificationFI from '@salesforce/apex/RecordActionButtonController.sendNotificationFI';
import approvalAssignment from '@salesforce/apex/RecordActionButtonController.approvalAssignment';
import getRecordTypeName from '@salesforce/apex/RecordActionButtonController.getRecordTypeName';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName2';
import {unregisterAllListeners, fireEvent, registerListener} from 'c/pubsub';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import updateDocumentDetail from '@salesforce/apex/RecordActionButtonController.updateDocumentDetail';
import getProductName from '@salesforce/apex/Credit_FIVerificationController.getProductNameFromLA';
import getOwnerName from '@salesforce/apex/Credit_FIVerificationController.getOwnerName';
//HL-Ishi-16/09
import isReportPending from '@salesforce/apex/RecordActionButtonController.isReportPending'
import createLegalRecordNew from '@salesforce/apex/Hl_LegalRecordPageController.createLegalRecordNew'
//HL-Ishi-16/09
// --- NEW LEGAL CONTROLLER IMPORTS ---
import checkShowSubmitLegal from '@salesforce/apex/Credit_LegalVerificationController.checkShowSubmit';
import saveRemarksLegal from '@salesforce/apex/Credit_LegalVerificationController.saveRemarksFI';
import getProductNameFromLALegal from '@salesforce/apex/Credit_LegalVerificationController.getProductNameFromLA';
import getOwnerNameLegal from '@salesforce/apex/Credit_LegalVerificationController.getOwnerName';


export default class RecordActionButton extends NavigationMixin(LightningElement) {
    @api recordId

    @track buttonTrackers = []

    fieldAPIName
    previousFieldValue
    objectAPIName
    fieldValue
    buttonMessage = '';
    comment = '';
    @track buttonValue = '';
    @track greenColour=true;
    @track changeColour;
    @track isFCU = false;
    @track isVendorPD = false;
    @track isExecutive = false;
    
    isMobile = false;
    isLoaded = false;
    openRemark = false;
    opendisposition=false;
    isModalOpen = false;
    isReassignModalOpen = false
    showButtons = false;
    @track showQueryModal = false;

    buttonMap = new Map()
    @wire(CurrentPageReference) pageRef;
    // @wire(CurrentPageReference)
    // getPageReferenceParameters(currentPageReference) {
    //     if (currentPageReference) {
    //         console.log('currentpageRef',currentPageReference);
    //         this.pageRef = currentPageReference;
    //         this.recordId = currentPageReference.state?.recordId || currentPageReference.attributes?.recordId;
    //     }
    // }
    assignButtonlabel = '';
    assignHeader = '';
    @track yesNoOptions = [{label: 'Yes', value: 'Yes'}, {label: 'No', value: 'No'}];
    @track openLegalApproveScreen=false;
    @track receiptGenerated;
    @track advocateSigned;
    @track isAreaLegal=false;
    @track selectedDisposition;
    @track showRemarks=false;
    @track showConfirmationMessage=false;
    @track showDisposition;
    isCurrentUserAssignedUser = false;
    @track userName;
    @track stage;//kalpesh
    @track submissionButtonValue = '';//updated-Ayushi
    prodName;
    owner;
    confirmMessage = 'Are you sure you want to continue?';
    dispositionOption = [
        { label: 'Accept', value: 'Approve' },
        { label: 'Reject', value: 'Reject' },
        { label: 'Re-initiate', value: 'Re-initiate' },
    ];

    //Hl-Ishi-16/09
    showReportPendingError = false;
    //HL-Ishi-16/09
    openModal() { this.isModalOpen = true }
    closeModal() { this.isModalOpen = false }
    loadComponent() { this.isLoaded = true }
    setFormFactor() { this.isMobile = FORM_FACTOR == 'Large' ? false : true }
    openReassingModal() {
    if (this.objectAPIName == 'Legal__c') {
            this.isReassignModalOpen = true;
            //this.updateRecords();
    } else {
        this.isReassignModalOpen = true;
    }
}
    closeReassingModal() { this.isReassignModalOpen = false }
    openRemarkModal() { this.openRemark = true; this.comment = '' }
    closeRemarkModal() { this.openRemark = false; this.comment = '' }
    openDispositionModal() { this.opendisposition = true; this.comment = '' }
    closeDispositionModal() {
        this.showRemarks = false;
        this.comment = '';
        console.log('line 99-->>', this.prodName);
        if (this.prodName == 'Home Loan') {
            this.selectedDisposition = ''
        }
    }
    closeConfirmationModal() { this.showConfirmationMessage = false; }
    handleRemark(event) {
        this.comment = event.target.value;
        console.log('commenttt---', this.comment);
        
    }
    connectedCallback(){
        this.setFormFactor();
        //this.showDispositionDropDown();
        //this.currentLoggedInUserAssignedUser();
        // alert(this.isMobile);
        this.init();
        //this.checkShowSubmit();
        registerListener("fiCheckSubmit",this.checkShowSubmit, this);
        // registerListener("technicalEnableSubmit",this.checkShowSubmitTechnical, this);
        registerListener('fcuReportValidated', this.handleReportValidation, this);//updated-Ayushi
        console.log('Inside button component>');
    }
    //updated-Ayushi - New method to handle the validation response
    handleReportValidation(payload) {
        console.log('Record Action Button: Received validation response...');
        console.log("payload received ",payload);
        if (payload.isValid) {
            // Validation passed!
            console.log('Validation successful. Proceeding with submit.');
            this.proceedWithSubmit(); // Call the new method that contains the Apex call
        } else {
            // Validation failed.
            console.log('Validation failed. Submission stopped.');
        }
    }

    // This new method holds your original Apex call
    proceedWithApprovalAssignment() {
        // We use 'this.submissionButtonValue' which we saved
        approvalAssignment({
            recordId: this.recordId,
            buttonvalue: this.submissionButtonValue
        }).then(response => {
            console.log('assigned to id  ', response);
            if (response.includes('Error')) {
                this.sendToastMessage('Error', 'Error:Verification status missing', 'Error');
            }
            else {
                this.sendToastMessage('Success', `The FCU record is updated .`, 'Success');
                location.reload();
            }
        }).catch(error => {
            console.error('error in getCurrentAssignee---', error);
        });
    }
    //end updated
    @wire(getRecord, { recordId: USER_ID, fields: [NAME_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.userName = data.fields.Name.value;
        } else if (error) {
            console.error('Error fetching user data:', error);
        }
    }
    currentLoggedInUserAssignedUser(){
        currentLoggedInUserAssignedUser({
            recordId:this.recordId
        }).then(response=>{
            this.isCurrentUserAssignedUser=response;
        })
    }
    fetchProductName() {
        console.log('FetcchProductname record id' + this.recordId);
        getProductName({ recordId: this.recordId })
            .then(result => {
                this.prodName = result;
            })
            .catch((error) => {
                console.error('Error fetching product name ' + JSON.stringify(error));//updated
            });
    }
    handleChangeDisposition(event){
        this.selectedDisposition=event.target.value;
        console.log('event--'+event.target.value);
        this.showRemarks=true;
        this.showConfirmationMessage=false;
        // if(event.target.value=='Waive'){
            // this.showRemarks=true;
            // this.showConfirmationMessage=false;
        // }
        // if(event.target.value=='Approve'){
        //     this.showConfirmationMessage=true;
        //     this.showRemarks=false;
        // }
    }
    showDispositionDropDown(){
        showDispositionDropDown({
            recordId:this.recordId
        }).then(response=>{
            console.log('showDispositionDropDown response---', response);
            
            this.showDisposition=response;
        })
        
    }
    getRecordTypename(){
        
        getRecordTypeName({
            recordId :  this.recordId
        }).then(response=>{
            console.log('recortypename  ', response);
            if(response === 'FCU') {
                this.isFCU = true;
            }else if(response == 'Personal Discussion AHL'){
                this.isVendorPD = true;
            }
            
        }).catch(error=>{
            console.error('error in getCurrentAssignee---', error);
            
        })
    }
    getCurrentUserProfileName(){
        console.log('stage--->',this.stage);
        getCurrentUserProfileName({
            stage :  this.stage
        }).then(response=>{
            console.log('user-->  ', response);
            if(response === 'FCU Executive') {
                this.isExecutive = true;
            }
            
        }).catch(error=>{
            console.error('error in getCurrentAssignee---', error);
            
        })
    }

    init(){
      
        console.log('before init the record id---',this.recordId);
        setRecordButtons({recordId : this.recordId}).then(response=>{
            console.log('response ',JSON.stringify(response));
            this.stage=response.fieldValue;//kalpesh
            this.setResponse(response);
            //updated
            if (this.objectAPIName !== 'Legal__c') {
                this.currentLoggedInUserAssignedUser();
                this.showDispositionDropDown();
            }
            this.checkShowSubmit();
            this.isReportPending();
            this.loadContextualData();
            //end updated
            this.loadComponent();
            this.getRecordTypename();
            this.getCurrentUserProfileName();
        }).catch(error=>{
            console.error(`The Error in setRecordButtons method is : ${JSON.stringify(error)}`);
            this.isLoaded = false;
        })
    }
    //updated
    loadContextualData() {
        if (!this.objectAPIName) return; // Exit if object name isn't set

        const isLegal = this.objectAPIName === 'Legal__c';

        // --- 1. checkShowSubmit ---
        const checkSubmitMethod = isLegal ? checkShowSubmitLegal : checkShowSubmit;
        checkSubmitMethod({
            recId: this.recordId,
            objectAPIName: this.objectAPIName
        }).then(response => {
            this.showButtons = response;
            console.log('90------'+this.showButtons);
        }).catch(error=>{
            console.log(`The Error in checkShowSubmit method is : ${JSON.stringify(error)}`);
        });

        // --- 2. isReportPending (This seems generic, so we leave it) ---
        this.isReportPending();

        // --- 3. fetchProductName ---
        const productNameMethod = isLegal ? getProductNameFromLALegal : getProductName;
        productNameMethod({ recordId: this.recordId })
            .then(result => {
                this.prodName = result;
                console.log('Product Name: ' + this.prodName);
            })
            .catch((error) => {
                console.error('Error fetching product name ' + JSON.stringify(error));
            });

        // --- 4. getOwnerName ---
        const ownerNameMethod = isLegal ? getOwnerNameLegal : getOwnerName;
        ownerNameMethod({
            recordId: this.recordId,
        }).then(response => {
            this.owner = response;
            console.log('Owner name: ', this.owner);
        }).catch(error => {
            console.error('error in getOwnerName---', error);
        });
    }
    //end updated

    checkShowSubmit() {
        // console.log('line 236-->>' + this.recordId);
        // console.log('objectAPIName-->' + this.objectAPIName);
        console.log('re-running checkShowSubmit');//updated Ayushi
        const isLegal = this.objectAPIName === 'Legal__c';//updated Ayushi
        const checkSubmitMethod = isLegal ? checkShowSubmitLegal : checkShowSubmit;//updated Ayushi
        // checkShowSubmit({
            checkSubmitMethod({//updated Ayushi
             recId: this.recordId,
             objectAPIName: this.objectAPIName
         }).then(response => {

             this.showButtons = response;
             console.log('90------' + this.showButtons);
         }).catch(error => {
            console.log(`The Error in checkShowSubmit method is : ${JSON.stringify(error)}`);
         }) 
    }
    isReportPending() {
        console.log('line 236-->>');
        isReportPending({
            recordId: this.recordId
        }).then(response => {
            console.log('260----' + response);
            this.showReportPendingError = response;
            console.log('90------' + this.showButtons);
        }).catch(error => {
            console.log(`The Error in checkShowSubmit method is : ${JSON.stringify(error)}`);
        })
    }
    
    setResponse(response) {
        this.buttonTrackers = response.buttons.map(button => {
            let buttonClass = 'button-green'; // Default green button
    
            // Set class based on the button name
            if (button.name === 'Send Back') {
                buttonClass = 'button-red';
            } else if (button.name === 'Assign') {
                buttonClass = 'button-green';}
            //     else if(button.name = 'Cancel'){
            //             buttonClass = 'button-red';
            // }
            else if (button.name === 'Approve') {
                buttonClass = 'button-green';
            }
            else if (button.name === 'Reassign') {
                buttonClass = 'button-green';
            }
            else if(button.name=='Underwriters Disposition'){
                buttonClass='button-green';
            }
    
            return {
                ...button,
                buttonClass, // Assign dynamic class
            };
        });
    
        console.log('Processed buttonTrackers:', JSON.stringify(this.buttonTrackers));
    
    
      
        if(this.buttonTrackers.length>0){
            if(this.buttonTrackers[0].name == 'Assign'){
                this.assignButtonlabel = 'Assign';
                this.assignHeader = 'Assign Report';
                this.greenColour=true;
                console.log('button----'+   this.greenColour);
            }else if(this.buttonTrackers[0].name == 'Send Back'){
                console.log('button----'+   this.greenColour);
                 this.greenColour=false;
            }else{
                this.assignButtonlabel = 'Re-assign';
                this.assignHeader = 'Re-assign Report';
                this.greenColour=true;
            }
        }
      
       
        
        this.fieldAPIName = response.fieldAPIName;
        this.objectAPIName = response.objectAPIName;
        this.fieldValue = response.fieldValue;
        this.previousFieldValue = response.previousFieldValue;
        this.buttonMessage = `Currently Stage is in ${this.fieldValue}`;
    }

    get buttonClass() {
        return this.greenColour ? 'button-green' : 'button-red';
    }

    updateRecordStatus(evt){
        this.buttonValue = evt.target.value;
        this.checkShowSubmit();
        this.isReportPending();
        this.submissionButtonValue = this.buttonValue;
        setTimeout(()=>{
            console.log('this.objectAPIName::'+this.objectAPIName);
            console.log('this.buttonValue'+this.buttonValue);
            console.log('this.showButtons'+this.showButtons);
            console.log('this.buttonValue -->'+this.buttonValue);
            console.log('this.recordif-->',this.recordId);
            console.log('this.buttonname-->',evt.target.dataset.id);
            if((this.isFCU && this.isExecutive) || (this.isFCU && this.buttonValue == 'Not Accepted By Admin')|| (this.isFCU && this.buttonValue == 'Approved')||(this.isFCU && this.buttonValue == 'Accepted')||(this.isFCU && this.buttonValue == 'Initiated')||(this.isFCU && this.buttonValue == 'Cancelled')){
                console.log('are we in here');
                if(this.isFCU && this.buttonValue == 'Cancelled'){
                    this.openRemarkModal();
                    return;
                }
                 //kalpesh
                 if(this.buttonValue=='Accepted' && this.objectAPIName == 'Application_Verification__c'){
                    updateDocumentDetail({recordId:this.recordId})
                    .then(result=>{

                    })
                    .catch(error => {
                        console.log('Error updating record --> '+JSON.stringify(error));
                    });
                }
                approvalAssignment({
                    recordId :  this.recordId,
                    buttonvalue : this.buttonValue
                }).then(response=>{
                    console.log('assigned to id  ', response);
                    if (response.includes('Error')) {
                        this.sendToastMessage('Error', 'Error:Verification status missing', 'Error');
                    } 
                    else{
                    this.sendToastMessage('Success', `The FCU record is updated .`, 'Success');
                    location.reload();
                    }
        
                }).catch(error=>{
                    console.error('error in getCurrentAssignee---', error);
                    
                })
                return
            }

            // updated-Ayushi*** THIS IS THE MODIFIED IF BLOCK ***
            if ((this.isFCU && this.isExecutive) || (this.isFCU && this.buttonValue == 'Not Accepted By Admin') || (this.isFCU && this.buttonValue == 'Approved') || (this.isFCU && this.buttonValue == 'Accepted') || (this.isFCU && this.buttonValue == 'Initiated') || (this.isFCU && this.buttonValue == 'Cancelled')) {
                console.log('are we in here');

                // Handle 'Cancelled' first, as it needs no validation
                if (this.isFCU && this.buttonValue == 'Cancelled') {
                    this.openRemarkModal();
                    return;
                }

                // *** NEW VALIDATION CHECK ***
                // If it's the Executive, trigger client-side validation and wait.
                if (this.isFCU && this.isExecutive) {
                    console.log('FCU Executive submit. Firing validateFCUReport event...');
                    fireEvent(this.pageRef, 'validateFCUReport', null);

                    // STOP here. 'handleReportValidation' will call 'proceedWithApprovalAssignment' if valid.
                return;
            }

                // *** EXISTING LOGIC ***
                // If it's NOT the executive (e.g., Admin, Sampler), submit immediately.
                console.log('Not an Executive submit. Proceeding directly.');
                this.proceedWithApprovalAssignment(); // Call the new function that holds the Apex call
                return;
            }//end updated
            if (this.objectAPIName == 'Legal__c' && (this.buttonValue == 'Submitted by Executive' || this.buttonValue == 'Submitted by Admin') && !this.showButtons) {
                console.log('305----');
                this.sendToastMessage('Error', 'Please fill all the mandatory fields in order to submit the report.', 'error');
                return;
            }
            if (this.objectAPIName == 'Legal__c' && this.showReportPendingError && (this.buttonValue == 'Submitted by Executive' || this.buttonValue == 'Submitted by Admin')) {
                console.log('305----');
                this.sendToastMessage('Error', 'Please upload the report in order to submit the report.', 'error');
                return;
            }
            if (this.objectAPIName == 'Application_Verification__c' && this.buttonValue == 'Sent for Approval' && !this.showButtons) {
                console.log('305----');
                this.sendToastMessage('Error', 'Please fill all the mandatory fields in order to submit the report.', 'error');
                return;
            }
            if (this.objectAPIName == 'Application_Verification__c' && this.buttonValue == 'Sent for Approval by FI Admin' && !this.showButtons) {
                console.log('163----');
                this.sendToastMessage('Error','Please fill all the mandatory fields in order to submit the report.','error');
                return;
            }
            if(this.objectAPIName == 'Application_Verification__c'  && this.buttonValue == 'Sent for Approval by PD Admin' && !this.showButtons){
                console.log('163----');
                this.sendToastMessage('Error','Please fill all the mandatory fields in order to submit the PD.','error');
                return;
            }




            console.log('Inside---485' + this.buttonValue);
            switch (this.buttonValue.trim()) {

                case 'Assigned to Admin':
                    console.log('Inside---485');
                    this.openRemarkModal();
                    break
                case 'Sent Back By Area Manager':
                    console.log('Sent Back By Area Manager ------');
                    this.openRemarkModal()
                    break
                case 'Draft':
                    this.openReassingModal()
                    break
                case 'Re-Assigned':
                    this.openReassingModal()
                    break
                case 'Reassign':
                    this.openReassingModal()
                    break
                case 'In progress':
                    this.openReassingModal()
                    break
                case 'Not Accepted By Admin':
                    this.openRemarkModal()
                    break
                case 'Waived':
                    this.openRemarkModal()
                    break
                case 'Waiver Rejected':
                    this.openRemarkModal()
                    break
                case 'Sent Back By Admin':
                    this.openRemarkModal()
                    break
                case 'Sent Back By Credit':
                    this.openRemarkModal()
                    break
                case 'Sent Back By Credit To External Legal':
                    this.openRemarkModal()
                    break
                case 'Sent Back By Credit To Area Legal Manager':
                    this.openRemarkModal()
                    break
                case 'Sent Back By Credit To Operations':
                    this.openRemarkModal()
                    break
                case 'Sent Back By Operations':
                    this.openRemarkModal()
                    break
                case 'Sent Back By Area Legal Manager':
                    this.openRemarkModal()
                    break
                case 'Rejected':
                    this.openRemarkModal()
                    break
                case 'Assigned To Agent':
                    this.openReassingModal()
                    break
                case 'Re Assigned to Admin':
                    this.openReassingModal()
                    break
                case 'Sent Back By Credit':
                        this.openRemarkModal()
                        break
                //case 'Approved 2':
                case 'Approved by CM':
                    this.updateRecords();
                    break
                case 'Assigned To Executive':
                    this.openReassingModal()
                    break
                case 'Underwriters Decisioning':
                    this.openDispositionModal();
                    break;
                case 'Sent for Approval' :
                    this.openRemarkModal();
                    break; 
                case 'Sent for Approval by FI Admin':
                    this.openRemarkModal();
                    break; 
                case 'Sent for Approval by PD Admin':
                    this.openRemarkModal();
                    break;     
                case 'Assign':
                    this.openReassingModal();
                    break;
                case 'Query raised':
                    this.openqueryModal();
                    break;
                case 'Hold':
                    this.openRemarkModal();
                    break;
                case 'Re Initate':
                    this.createLegalRecordNew();
                    break;
                default:
                    this.updateRecords()
            }
        },1000)
    }
    // updated-Ayushi New method to run the Apex call *after* validation succeeds
    proceedWithSubmit() {
        // This code was moved from updateRecordStatus
        // We use 'this.submissionButtonValue' which we saved
        approvalAssignment({
            recordId: this.recordId,
            buttonvalue: this.submissionButtonValue
        }).then(response => {
            console.log('assigned to id  ', response);
            if (response.includes('Error')) {
                this.sendToastMessage('Error', 'Error:Verification status missing', 'Error');
            }
            else {
                this.sendToastMessage('Success', `The FCU record is updated .`, 'Success');
                location.reload();
            }

        }).catch(error => {
            console.error('error in getCurrentAssignee---', error);
        });
    }//end updated
    
    openqueryModal() {
        this.showQueryModal = true;
        console.log('line 442-->>', this.showQueryModal);
    }

    handleCloseModal() {
        this.showQueryModal = false;
    }
    updateRecords(){
        const fields = {};
        fields['Id'] = this.recordId;
        fields[this.fieldAPIName] = this.buttonValue === 'Un-Hold' ? this.previousFieldValue : this.buttonValue;
        console.log('field api -->',this.fieldAPIName);
        if(this.buttonValue === 'Hold' && this.objectAPIName == 'Application_Verification__c'){
            fields['Previous_Stage__c'] = this.fieldValue;
        }
        if(this.buttonValue=='Sent Back By Credit' && this.objectAPIName == 'Application_Verification__c'){
            updateAssignedUser({recordId:this.recordId})
            .then(result=>{

            })
            .catch(error => {
                console.log('Error updating record --> '+JSON.stringify(error));
            });
        }
        if ((this.buttonValue == 'Submitted by Admin' || this.buttonValue == 'Submitted by Executive') && this.objectAPIName == 'Legal__c') {
            this.sendNotificationFI();
        }
       

        const recordInput = { fields };
        console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
        updateRecord(recordInput)
        .then(() => {
            console.log('before perform action in updateRecords method :');
            this.performAction();
            // this.updateButtons()
            this.init();
            this.sendToastMessage('Success','Record status has been updated successfully.','success');
            fireEvent(this.pageRef, "handleRecordrefresh", "handleRecordrefresh");
            location.reload();
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });
    }

    
    updateApproval() {
        if ((this.comment == '' || this.comment == null || this.comment == undefined) && !((this.buttonValue == 'Approved 1' || this.buttonValue == 'Approved 2' || this.buttonvalue == 'Approved by CO/CM') && this.objectAPIName == 'Legal__c')) {
            this.sendToastMessage('Error', 'Please add a remark to proceed further.', 'error');
            return;
        }
        if (this.comment.length > 32768) {
            this.sendToastMessage('Error', 'Comment exceeds the maximum allowed length of 32,768 characters.', 'error');
            return;
        }
        if(this.isFCU && this.buttonValue == 'Cancelled') {
            const fields = {};
            fields['Id'] = this.recordId;
            fields['Cancellation_Remarks__c'] = this.comment;
            const recordInput = { fields };
            updateRecord(recordInput)
            .then(() => {
            approvalAssignment({
                recordId :  this.recordId,
                buttonvalue : this.buttonValue
            }).then(response=>{
                console.log('assigned to id  ', response);
                this.sendToastMessage('Success', `The FCU is assigned .`, 'Success');
                location.reload();
       
            }).catch(error=>{
                console.error('error in getCurrentAssignee---', error);
                
            });
        }).catch(error => {
            console.error('Error in updating record:', error);
            this.sendToastMessage('Error', 'Error saving remark. Please try again.', 'error');
        });
            return
        }
        const fields = {};
        fields['Id'] = this.recordId;
        console.log('this.legal00000', this.fieldValue);
        if (this.objectAPIName == 'Legal__c' && this.buttonValue === 'Hold' /*&& this.objectAPIName == 'Application_Verification__c'*/) {
            fields['Previous_Stage__c'] = this.fieldValue;
        }
        fields[this.fieldAPIName] = this.buttonValue === 'Un-Hold' ? this.previousFieldValue : this.buttonValue;
        if((this.buttonValue === 'Waived' || this.buttonValue === 'Waiver Rejected') && this.objectAPIName == 'Application_Verification__c'){
            fields['Waiver_Remark__c'] = this.comment;
        }
        const recordInput = { fields };
        console.log(`The Update Record : ${JSON.stringify(recordInput)}`);
        updateRecord(recordInput)
        .then(() => {
            console.log('before perform action in updateApproval method :');
            this.performAction();
            // this.updateButtons()
            console.log('this.objectAPIName -->'+this.objectAPIName);
            console.log('this.buttonValue -->'+this.buttonValue);
           
            // updateStatus({recordId : this.recordId,
            //     approvalId : this.recordId,
            //     order : 1,
            //     remark : this.comment,
            //     status : this.buttonValue
            // })
            // .then(response=>{
            //     console.log(`Got Response : ${JSON.stringify(response)}`);
                    
            //     // this.showToastMessage('Success', `Loan has been ${this.statusToUpdate}.`, 'success');

            //     this.comment = '';
            // }).catch(error=>{
            //     console.error(`The error in updateStatus method is : ${JSON.stringify(error)}`)
            // });

            // this.init();
            if(this.buttonValue=='Sent for Approval by FI Admin' && this.objectAPIName == 'Application_Verification__c'){
                this.sendToastMessage('Success','Successfully sent the verification application to Credit Manager.','success');
            }else if(this.buttonValue=='Sent for Approval by PD Admin' && this.objectAPIName == 'Application_Verification__c'){
                this.sendToastMessage('Success','Successfully sent the PD report to Credit Manager.','success');
            }else{
                this.sendToastMessage('Success','Record status has been updated successfully.','success');
            }
            // Introduce a delay before reloading the page
            setTimeout(() => {
                location.reload(); // Reloads the page after a delay
            }, 2000);
        })
        .catch(error => {
            console.log('Error updating record --> '+JSON.stringify(error));
        });
    }
    updateDisposition(){
        if(this.selectedDisposition==''||this.selectedDisposition==null||this.selectedDisposition==undefined){
            this.sendToastMessage('Error','Please select a disposition to proceed further.','error');
            return;
        }
        if(this.selectedDisposition=='Waive' && (this.comment == '' || this.comment == null || this.comment == undefined) && !((this.buttonValue=='Approved 1'||this.buttonValue=='Approved 2'||this.buttonValue=='Approved by CM') && this.objectAPIName=='Legal__c')){
            this.sendToastMessage('Error','Please add a remark to proceed further.','error');
            return;
        }
        const fields = {};
        fields['Id'] = this.recordId;
        // if(this.selectedDisposition=='Waive'){
        //     fields['Stage__c'] = 'Waived';
        //     fields['Waiver_Remark__c']=this.comment;
        // }else if(this.selectedDisposition=='Approve'){
        //     fields['Stage__c'] = 'Approved 2';
        // }
        const currentDateTime = new Date().toISOString();
        fields['Credit_Managers_Disposition__c'] = this.selectedDisposition; 
        if (this.prodName == 'Home Loan') {
            fields['Assigned_To_User__c'] = this.owner;
        }
        if (this.selectedDisposition == 'Approve' && this.isVendorPD) {
            fields['Stage__c'] = 'Approved';
            fields['Completion_Date__c'] = currentDateTime;
        }
        else if(this.selectedDisposition=='Approve'){
           // fields['Stage__c'] = 'Approved 2';
           fields['Stage__c'] = 'Approved by CM';
            fields['Completion_Date__c'] = currentDateTime;
        }
        else if(this.selectedDisposition=='Reject'){
            fields['Stage__c'] = 'Rejected';
            fields['Completion_Date__c'] = currentDateTime;
        }
        else{
             fields['Stage__c'] = 'Re Initiate';
            fields['Completion_Date__c'] = currentDateTime;
        }
        const currentDateTime1 = new Date();
        const year = currentDateTime1.getFullYear();
        const month = String(currentDateTime1.getMonth() + 1).padStart(2, '0');
        const day = String(currentDateTime1.getDate()).padStart(2, '0');
        const hours = String(currentDateTime1.getHours()).padStart(2, '0');
        const minutes = String(currentDateTime1.getMinutes()).padStart(2, '0');
        const seconds = String(currentDateTime1.getSeconds()).padStart(2, '0');
        const formattedDateTime = `${year}-${month}-${day}, ${hours}:${minutes}:${seconds}`;
        // fields['Credit_Manager_s_Remarks__c'] = this.comment +' - '+ formattedDateTime +': '+ this.userName;
        const recordInput = { fields };
        console.log(`The Update Record : ${JSON.stringify(recordInput)}`);
        console.log('comment before UpdateRecord:: '+this.comment);
        
        updateRecord(recordInput)
        .then(() => {
            this.performAction();
            this.sendToastMessage('Success','Record updated successfully.','success');
            location.reload();
            this.openDispositionModal=false;
        })

    }

    performAction(){
        console.log(`The Value is : ${this.buttonValue}  ${this.objectAPIName}`)
        if((this.buttonValue === 'Sent Back By Admin'||this.buttonValue==='Approved 1'/*||this.buttonValue==='Approved 2'*/||this.buttonValue=='Sent for Approval'||this.buttonValue==='Sent Back By Credit'||this.buttonValue==='Re Assigned to Admin'||this.buttonValue==='Sent for Approval by FI Admin'||this.buttonValue==='Sent for Approval by PD Admin') && this.objectAPIName == 'Application_Verification__c'){
            console.log(`The Value is : ${this.buttonValue}  ${this.objectAPIName}`)
            this.sendNotificationFI()
        }
        if((this.buttonValue=='Sent Back By Credit'&& this.objectAPIName == 'Application_Verification__c')){
            this.saveRemarksFI(this.buttonValue);
        }
        if((this.buttonValue=='Sent Back By Admin'&& this.objectAPIName == 'Application_Verification__c')){
            this.saveRemarksFI(this.buttonValue);
        }
        if(this.selectedDisposition=='Waive'&& this.objectAPIName == 'Application_Verification__c'){
            this.saveRemarksFI(this.selectedDisposition);
        }
        if(this.buttonValue=='Sent for Approval' && this.objectAPIName == 'Application_Verification__c'){
            this.saveRemarksFI(this.buttonValue);
        }
        if(this.buttonValue=='Sent for Approval by FI Admin' && this.objectAPIName == 'Application_Verification__c'){
            this.saveRemarksFI(this.buttonValue);
        }  
        if(this.buttonValue=='Sent for Approval by PD Admin' && this.objectAPIName == 'Application_Verification__c'){
            this.saveRemarksFI(this.buttonValue);
        }
        if(this.selectedDisposition=='Approve' && this.objectAPIName == 'Application_Verification__c'){
           this.saveRemarksFI(this.selectedDisposition);
        }  
        if(this.selectedDisposition=='Reject' && this.objectAPIName == 'Application_Verification__c'){
           this.saveRemarksFI(this.selectedDisposition);
        }  
        if(this.selectedDisposition=='Re-initiate' && this.objectAPIName == 'Application_Verification__c'){
           this.saveRemarksFI(this.selectedDisposition);
        }     
        //HL-Ishi-17/09
        if ((this.buttonValue.trim() == 'Assigned to Admin' && this.objectAPIName == 'Legal__c')) {
            console.log('this.buttonValue 74900' + this.buttonValue);
            this.sendNotificationFI();
            this.saveRemarksFI(this.buttonValue);

        }
        if ((this.buttonValue.trim() == 'Hold' && this.objectAPIName == 'Legal__c')) {
            console.log('this.buttonValue 74900' + this.buttonValue);
            this.saveRemarksFI(this.buttonValue);
            this.sendNotificationFI();
        }
        // updated-Ayushi legal Unhold notification
        if (this.buttonValue.trim() === 'Un-Hold' && this.objectAPIName == 'Legal__c') {
            console.log('Un-Hold action, calling sendNotificationFI');
            this.sendNotificationFI();
        }
        // end updated
        //HL-Ishi-17/09   
        else if (this.buttonValue === 'Re-Assigned') {
            this.openReassingModal();
        }
        
    }
    /*saveRemarksFI(Remarks){
        console.log('Remarks:: '+Remarks);
        console.log('comment:: '+this.comment);
        saveRemarksFI({recordId:this.recordId,status:Remarks,comment:this.comment})
        .then(response=>{
            console.log('response:: '+JSON.stringify(response));
        })
        .catch(error=>{
            console.error(`The Error is : ${JSON.stringify(error)}`)
        })
    }*/
    saveRemarksFI(Remarks) {
        console.log('Remarks:: ' + Remarks);
        console.log('comment:: ' + this.comment);

        const isLegal = this.objectAPIName === 'Legal__c';
        // Use the correct imported method based on context
        const saveRemarksMethod = isLegal ? saveRemarksLegal : saveRemarksFI;

        saveRemarksMethod({ recordId: this.recordId, status: Remarks, comment: this.comment })
            .then(response => {
                console.log('response:: ' + JSON.stringify(response));
            })
            .catch(error => {
            console.error(`The Error is : ${JSON.stringify(error)}`)
        })
    }
    

    sendNotificationFI(){
        sendNotificationFI({recordId : this.recordId,status:this.buttonValue, comment:this.comment}).then(response=>{

        }).catch(error=>{
            console.error(`The Error is : ${JSON.stringify(error)}`)
        })
    }

    sendToastMessage(title,message,variant){
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        }));
    }

}