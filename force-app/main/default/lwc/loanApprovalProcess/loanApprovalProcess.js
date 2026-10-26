import { api, LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getLoanApprovalDetails from '@salesforce/apex/LoanApplicationApprovalController.getLoanApprovalDetails';
import performApprovalAction from '@salesforce/apex/LoanApplicationApprovalController.performApprovalAction';
import recommendLoanApproval from '@salesforce/apex/LoanApplicationApprovalController.recommendLoanApproval';
import submitLoanForApproval from '@salesforce/apex/LoanApplicationApprovalController.submitLoanForApproval';
import getNewAssignee from '@salesforce/apex/Credit_LoanAssignmentController.getNewAssignee';
import getOriginator from '@salesforce/apex/LoanApplicationApprovalController.getOriginator';
import sendBackLoan from '@salesforce/apex/LoanApplicationApprovalController.sendBackLoan';
import submitLoanForExceptionApproval from '@salesforce/apex/LoanApplicationApprovalController.submitLoanForExceptionApproval';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkNextStageMovement from '@salesforce/apex/COMM_SalesLoanLoginController.checkNextStageMovement';
import sendEmailToUsers from '@salesforce/apex/sendEmailToUsers.sendEmailToUsers';
import { updateRecord } from "lightning/uiRecordApi";
import quickActionSave from '@salesforce/apex/AHL_LoanApplicationActionController.quickActionSave';
import getAllApplicants from  '@salesforce/apex/COMM_SalesLoanLoginController.getAllApplicants';
import callDedupeAPI from  '@salesforce/apex/COMM_SalesLoanLoginController.callDedupeAPI';


export default class LoanApprovalProcess extends NavigationMixin(LightningElement) {

    @api recordId;
    @api approvalType = 'Loan Approval';
    @track approvalData={};
    @track isSubmitting = false;
    @api showApproval = false;//sanwar
    isExceptionApproval=false;
    comment;
    showSendBackFields= false;
    showSendBack=false;
    selectedUserId;
    selectedUserName;
    selectedOption;
    showSendBackData;
    assigneeoptions;
    showSearch=false;
    newAssignee;
    selectedUserNameSendBack;
    selectedReasons=[];
    contentDocumentId;
    showPreview=false;
    errors=[];
    showLoginButton;
    movetoEligibility;
    hasErrors;
    applicantIds = [];
    currentIndex = 0;
    isLoanApproval=false;
    @track errorModal = false;
    @track errorLst = [];
    confirmationMessageLogin ='Congratulations. You have successfully completed the login processs. We are going to proceed with the loan processing'

    filterOptionsSendBack = [
        { label: 'Originator', value: 'Originator'},
        { label: 'Search and send', value: 'Search'},
    ];

    

    connectedCallback(){
        console.log('record Id in connectedCallback '+this.recordId);

         console.log('this.approvalType--'+this.approvalType);
        if(this.approvalType=='Exception Approval'){
            this.isExceptionApproval= true;
        }else if(this.approvalType=='Loan Approval'){
            this.isLoanApproval= true;
        }
        this.getLoanApprovalDetails();
        console.log('this.isLoanApproval-----', this.isLoanApproval);
        console.log('this.approvalType--after-'+this.approvalType);
    }

    renderedCallback() {
        if (!this.isRendered) {
            // Create and append styles dynamically
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
            .custom-table span.slds-file-selector__button.slds-button.slds-button_neutral{
                font-size: 0px;
            }
            .custom-table svg.slds-button__icon.slds-button__icon_left{
                margin: 0px;
            }
            .custom-table lightning-primitive-file-droppable-zone.slds-file-selector__dropzone{
                border: none;
            }
            .custom-div .slds-textarea{
                min-height: 200px;
            }
            .custom-table{
                font-weight: 400;
            }
    
    
            `;
    
            // Append the styles to the .styleContainer
            this.template.querySelector('.styleContainer')?.appendChild(style);
    
            // Prevent re-adding styles
            this.isRendered = true;
        }
    }

    toastvariant = {
        SUCCESS : 'success',
        ERROR : 'error'
    }
    toastTitle = {
        SUCCESS : 'Success',
        ERROR : 'Error'
    }

    toastMessages = {
         Pricing_Approval : 'Pricing Approval has been Submitted successfully.',
        Loan_Recommended : 'Loan application has been recommended successfully.',
        Loan_Approved : 'Loan application has been approved successfully.',
        Loan_Rejected : 'Loan application has been rejected successfully.',
        SOMETHING_WENT_WRONG : 'Something went wrong.',
        SelectUser : 'Please select assignee user.',
        Loan_SentBack : 'Loan application has been sent back successfully.',
        Loan_ExceptionApproval : 'Loan exceptions have been submitted for approval successfully.',
        Loan_Exception_Approved : 'Loan exceptions has been approved successfully.',
        Loan_Exception_Rejected : 'Loan exceptions has been rejected successfully.',
    }

    getLoanApprovalDetails(){
        console.log('this.approvalType:: '+this.approvalType);
        getLoanApprovalDetails({loanId: this.recordId, approvalType : this.approvalType})
        .then((result) =>{
            if(result){
                console.log('result in getLoanApprovalDetails::::', result);
                this.approvalData= result;
                this.comment = result.remarks;

                if(this.approvalData && this.approvalData.contentId){
                    this.contentDocumentId= this.approvalData.contentId;
                }
                if(this.approvalType=='Exception Approval'){
                    if(this.approvalData && this.approvalData.exceptions){
                        this.approvalData.exceptions.forEach(field => {
                            this.selectedReasons.push(field.name);
                        });
                    }
                }
                this.comment = this.approvalData.draftComment;
                console.log('this.approvalData---', JSON.stringify(this.approvalData));
                console.log('this.approvalData---', JSON.stringify(this.approvalData.commentLenth));
            }else{
                console.log('errror--- in getLoanApprovalDetails', error);
            }
        })
        .catch((error) => {
            console.log('errror--- in getLoanApprovalDetails', error);
        });

    }

    handleCommentChange(event){
        console.log('comment in handle change----', event.target.value);
        const value = event.target.value;
        const invalidPattern = /(%%-|&&-)/;
        if (invalidPattern.test(value)) {
            event.target.value = '';
            this.handletoastEvent('Invalid characters %%- and &&-.',this.toastTitle.ERROR,this.toastvariant.ERROR);
            return;            
        }else{
            this.comment = event.target.value;
            console.log('this.comment---', this.comment);
        }
        
        event.stopPropagation();
    }

    handleAction(event){
        
        var action=event.target.dataset.name;
        console.log('this.approvalType--after clcik-'+this.approvalType);
        console.log('Action clicked',this.approvalType);
        console.log('event.target---', event.target.dataset.name);
       
        //harcode for testing
        // this.approvalType = 'pricing Approval';
        event.stopPropagation();
        if(this.comment == '' || this.comment == null) {
            this.handletoastEvent('Please enter remarks',this.toastTitle.ERROR,this.toastvariant.ERROR);
            return;
        }
if(action == 'submitted For Approval'){

    // Guard: prevent double-submit while a request is already in flight
    if(this.isSubmitting){
        console.log('Submit already in progress, ignoring click.');
        return;
    }
    this.isSubmitting = true;

    if(this.approvalType=='Exception Approval'){

        console.log('content id in submit for approval--', this.contentDocumentId);
        console.log('Selected reasons---', JSON.stringify(this.selectedReasons));

        submitLoanForExceptionApproval({loanId: this.recordId, exceptReasons: this.selectedReasons, documentContentId: this.contentDocumentId, comments: this.comment})
        .then((result) =>{
            if(result=='success'){
                console.log('result in submitLoanForExceptionApproval::::', result);
                this.getLoanApprovalDetails();
                this.handletoastEvent(this.toastMessages.Loan_ExceptionApproval,this.toastTitle.SUCCESS,this.toastvariant.SUCCESS);
                if(this.approvalType == 'pricing Approval'){
                    this.dispatchEvent(new CustomEvent('loadloandata'));
                }//sanwar
            }else{
                this.handletoastEvent(result,this.toastTitle.ERROR,this.toastvariant.ERROR);
            }
        })
        .catch((error) => {
            this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG,this.toastTitle.ERROR,this.toastvariant.ERROR);
        })
        .finally(() => {
            // Always release the guard so the user can retry on error / "No approver" cases
            this.isSubmitting = false;
        });

    } else {
        console.log('this.approvalType:: '+this.approvalType);
        console.log('this.comments>>'+this.comment);
        submitLoanForApproval({loanId: this.recordId, approvalType : this.approvalType, comment: this.comment})
        .then((result) =>{
            if(result){
                console.log('result in submitLoanForApproval::::', result);
                if(result.includes('No approver')){
                    this.approvalData = {...this.approvalData,
                        currentStatus: result
                    };
                    this.handletoastEvent(result,this.toastTitle.ERROR,this.toastvariant.ERROR);
                    // Release guard so user can fix and retry — reload does NOT happen here
                    this.isSubmitting = false;
                } else {
                    this.getLoanApprovalDetails();
                    this.handletoastEvent(this.toastMessages.Loan_Recommended,this.toastTitle.SUCCESS,this.toastvariant.SUCCESS);
                    // Do NOT release guard — page is about to reload, keep button disabled meanwhile
                    window.location.reload();
                }
            } else {
                console.log('errror--- in submitLoanForApproval');
                this.isSubmitting = false;
            }
        })
        .catch((error) => {
            this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG,this.toastTitle.ERROR,this.toastvariant.ERROR);
            this.isSubmitting = false;
        });
    }
}
        if(action == 'Recommended'){
            recommendLoanApproval({loanId: this.recordId, comments: this.comment, approvalType : this.approvalType})
            .then((result) =>{
                if(result){
                    console.log('result in Recommended::::', result);
                    if(result[0]=='success'){
                        this.getLoanApprovalDetails();
                        this.handletoastEvent(this.toastMessages.Loan_Recommended,this.toastTitle.SUCCESS,this.toastvariant.SUCCESS);
                    }else if(result[0]=='fail'){
                        this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG,this.toastTitle.ERROR,this.toastvariant.ERROR);
                    }else{
                        this.errorModal = true;
                        this.errorLst = result;
                    }                        
                }else{
                    console.log('errror--- in Recommended');
                }
            })
            .catch((error) => {
                console.log('errror--- in Recommended', error);
                this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG,this.toastTitle.ERROR,this.toastvariant.ERROR);
            });
        }else if(action == 'Approv' ||  action =='Reject'){
            performApprovalAction({loanId: this.recordId, action: action ,comments: this.comment, approvalType : this.approvalType})
            .then((result) =>{
                if(result){
                    console.log('result in performApprovalAction::::', result);
                    if(result[0]=='success'){
                        this.getLoanApprovalDetails();
                        if(action == 'Approv'){
                            console.log('at 216--');
                            console.log('this.approvalType----at 218--', this.approvalType);
                            
                            if(this.approvalType == 'Exception Approval'){
                                this.handletoastEvent(this.toastMessages.Loan_Exception_Approved,this.toastTitle.SUCCESS,this.toastvariant.SUCCESS);
                            }else{
                                this.handletoastEvent(this.toastMessages.Loan_Approved,this.toastTitle.SUCCESS,this.toastvariant.SUCCESS);
                            }
                        }else{
                            console.log('at 224--');
                            if(this.approvalType == 'Exception Approval'){
                                this.handletoastEvent(this.toastMessages.Loan_Exception_Rejected,this.toastTitle.SUCCESS,this.toastvariant.SUCCESS);
                            }else{
                                this.handletoastEvent(this.toastMessages.Loan_Rejected,this.toastTitle.SUCCESS,this.toastvariant.SUCCESS);
                            }
                        }
                    }else if(result[0]=='fail'){
                        this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG,this.toastTitle.ERROR,this.toastvariant.ERROR);
                    }else{
                        this.errorModal = true;
                        this.errorLst = result;
                    }                    
                    
                }else{
                    console.log('errror--- in performApprovalAction');
                }
                setTimeout(()=>{
                     window.location.reload();
                },1000)
              
                
            })
            .catch((error) => {
                console.log('errror--- in performApprovalAction', error);
                this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG,this.toastTitle.ERROR,this.toastvariant.ERROR);
            });
        }else if(action == 'Send Back' ){
            this.showSendBackFields= true;
        }else if(action === 'saveDraft'){
            const fields = {};
            fields['Id'] = this.recordId;

            fields['Draft_PD_Note__c'] = this.comment;
            const recordInput = { fields };
            console.log(`The Update Record : ${JSON.stringify(recordInput)}`)
            updateRecord(recordInput)
            .then(() => {
                this.handletoastEvent('The draft PD notes are saved successfully.',this.toastTitle.SUCCESS,this.toastvariant.SUCCESS);
            })
            .catch(error => {
                console.log('Error updating record --> ' + JSON.stringify(error));
            });
        }
    }

    handletoastEvent(msg,title,variant){
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
        }));
    }

    sendBack(event){
        event.stopPropagation();
        console.log('Inside send backk-----');
        sendBackLoan({
            loanId : this.recordId,
            comments: this.comment,
            sendBackType: this.selectedOption,
            selectedUserId: this.selectedUserId,
            approvalType : this.approvalType
        }).then(response=>{
            console.log('response in sendBackLoan--', response);
            if(response){
                this.showSendBackData= false;
                this.selectedUserName = '';
                this.selectedUserId = '';
                this.getLoanApprovalDetails();
                this.handletoastEvent(this.toastMessages.Loan_SentBack,this.toastTitle.SUCCESS,this.toastvariant.SUCCESS);
            }
        }).catch(error=>{
            console.error('error in sendBackLoan---', error);
            this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG,this.toastTitle.ERROR,this.toastvariant.ERROR);
        })
    }

    handleSave(event){
        event.stopPropagation();
        console.log('Inside handleSave-----');
        if(this.selectedOption== 'Search' && (this.selectedUserId== null || this.selectedUserId == '' || this.selectedUserId == undefined)){
            this.handletoastEvent(this.toastMessages.SelectUser,this.toastTitle.ERROR,this.toastvariant.ERROR);
        }else{
            this.showSendBackFields= false;
            
            this.showSendBackData= true;
            if(this.selectedOption== 'Originator'){
                this.selectedUserNameSendBack = this.selectedUserName + ' - '+ this.selectedOption;
            }else{
                this.selectedUserNameSendBack = this.selectedUserName ;
            }
            
        }
    }

    handleCancel(event){
        event.stopPropagation();
        this.showSendBackFields = false;
    }

    handleSelection(event){
        event.stopPropagation();
        console.log('event.target.value----',event.target.value);
        this.selectedOption= event.target.value;
        if(this.selectedOption== 'Search'){
            this.getNewAssignee();
        }else if(this.selectedOption== 'Originator'){
            this.getOriginator();
        }
        
    }

    getOriginator(){
        getOriginator({
            loanId : this.recordId
        }).then(response=>{
            console.log('response in getOriginator--', response);
            if(response != undefined){
                for (var key in response) {
                    this.selectedUserId = key;
                    this.selectedUserName = response[key];
                    break;
                }
            }
        }).catch(error=>{
            console.error('error in getOriginator---', error);
            
        })
    }

    getNewAssignee(){
    
        console.log('this.selectedRecord in getNewAssignee----', this.recordId);

        getNewAssignee({
            recordId : this.recordId
        }).then(response=>{
            console.log('response in getNewAssignee--', response);
            let options = [];
            if(response != undefined){
                for (var key in response) {
                    console.log('key --' + key);
                    options.push({ label: response[key], value: key });
                }
                this.assigneeoptions = options;
                this.showSearch= true;
            }
        }).catch(error=>{
            console.error('error in getNewAssignee---', error);
            
        })
        
    }

    handleAssigneeChange(event){
        event.stopPropagation();
        console.log('event.target.value in handleAssignee---', event.target.value);
        console.log('event.target.label in handleAssignee---', event.target.label);
        
        this.selectedUserName= event.target.label;
        this.selectedUserId= event.target.value;

        this.assigneeoptions.map(user => {
            if (this.selectedUserId && this.selectedUserId== user.value) {
                this.selectedUserName=  user.label;
            }
        });
        console.log('this.selectedUserName----', this.selectedUserName);
        
    }

    @api
    refresh() {
        console.log('Api refres');
        this.connectedCallback();
    }

    handleUploadFinished(event) {
        event.stopPropagation();
        const uploadedFiles = event.detail.files;
        if(!uploadedFiles) return;

        const file= uploadedFiles[0];

        if(file.mimeType == 'application/pdf' || file.mimeType.includes('image')){
            console.log('debug77 : ' + uploadedFiles[0].documentId);

            this.contentDocumentId = uploadedFiles[0].documentId;
            if(this.contentDocumentId!= null && this.contentDocumentId!= undefined && this.contentDocumentId!= ''){
                this.showPreview = true;
            }
        }else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please upload file in correct format',
                    variant: 'error',
                }),
            );
        }
        

    }

    stopPropogation(event){
        event.stopPropagation();
    }
    viewImage(event){
        event.stopPropagation();
        console.log('this.contentDocumentId=:'+this.contentDocumentId);
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state : {
                selectedRecordId:this.contentDocumentId
             }
           })
    }

    selectIndividualCheckbox(event){
        console.log('event.target.dataset.name');
        var selectedReason= event.target.dataset.name;
        event.stopPropagation();
        console.log('Inside selectIndividualCheckbox');
        console.log('event.target.dataset.id : '+ event.target.dataset.id);
        
        for (var i = 0; i < this.approvalData.exceptions.length; i++) {
            console.log('selectedReason.selected :' + JSON.stringify(this.approvalData.exceptions));
            if (this.approvalData.exceptions[i].name == selectedReason) {
                if (event.target.checked == true) {
                    this.approvalData.exceptions[i].selected = true;
                    this.selectedReasons.push(selectedReason);
                    console.log('selectedReasons---' + JSON.stringify(this.selectedReasons));
                } else {
                    console.log('event.target.dataset.id: ' + event.target.dataset.id);
                    console.log('selectedReason');
                    console.log('selectedReason.selected :' + JSON.stringify(this.selectedReasons));
                    this.approvalData.exceptions[i].selected = false;
                    console.log('selectedReason :' + selectedReason);
                    this.selectedReasons = this.selectedReasons.filter(item => item !== selectedReason);
                    console.log('selectedReasons---' + JSON.stringify(this.selectedReasons));
                }
            }
        }  
    }

    handleNextClick(){
        console.log('Inside handleNextClick');
        const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
            detail: {
                loanId: this.recordId,
                screenName: 'Exception Approval'
            }
        });
        this.dispatchEvent(valueSelectedEvent);
    }
    // sales-Ishi
    handleLoanLogin(){
        this.checkNextStageMovement();

    }
    checkNextStageMovement(){
        console.log('result-----2838-Generic Screen');
        checkNextStageMovement({
            recordId: this.recordId
        })
        .then(result => {
            console.log('result-----2842-Generic Screen', JSON.stringify(result));
            if (result) {
                // Store the errors from the result
                this.errors = result.errors || [];
                this.showLoginButton = result.showLogin;
                this.movetoEligibility = result.moveToEligibility;
                if(this.errors.length>0)
                    {
                        this.hasErrors = true;
                    }
                    else{
                        this.hasErrors = false;
                    }
            }

        })
        .catch(error => {
        })
    }
    handleCloseConfirm(){
        this.hasErrors = false;
    }
    handleCloseConfirmLogin(){
        this.showLoginButton = false;
    }
    // handleLoginLoan(){
    //     console.log('recordId----',this.recordId)
    //     this.updateRecordField(this.recordId,'StageName','Pre Credit');
    //     this.dispatchEvent(new ShowToastEvent({
    //         title: 'Success',
    //         message: 'Loan Logged in Successfully',
    //         variant: 'Success',
    //     }));
    // }
    handleLoginLoan(){
        console.log('recordId----',this.recordId)
         this.loginToNextStage();
       
       
    }
    loginToNextStage(){
        quickActionSave({
            loanApplicationId: this.recordId,
            quickActionName: 'Mark as complete',
           
        })
        .then(result => {
            this.showLoginButton = false;
            console.log('result-----2842-Generic Screen', JSON.stringify(result));
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Loan Logged in Successfully',
                variant: 'Success',
     
            }));
            sendEmailToUsers({ loanId: this.recordId })
            .then(result => {
                this.fetchApplicants();
                console.log('Email sent Successfully', JSON.stringify(result));
            })
            .catch(error => {
                this.fetchApplicants();
                console.log('Email Error', JSON.stringify(error));
            })
            if(window.location.origin.includes('my.site.com')){
                window.location.href = '/losportal/s/';

            }
            else{
                location.reload();
            }
           
        })
        .catch(error=> {
        })
    }

    updateRecordField(recordId, fieldApiName, fieldValue) {
        const fields = {};
        fields['Id'] = recordId;
        fields[fieldApiName] = fieldValue;
        const recordInput = { fields };
        updateRecord(recordInput)
        .then(() => {
            console.log('Record updated successfully 2815',JSON.stringify(recordInput));
        })
        .catch(error => {
            console.error('Error updating record: ', error);
            console.log('Error updating record --> '+JSON.stringify(error));
        })
    }

    fetchApplicants() {
        getAllApplicants({ loanId: this.recordId })
            .then(result => {
                this.applicantIds = result.map(item => item.applicantId);
                this.callDedupeSequentially(); 
            })
            .catch(error => {
                console.error('Error fetching applicants:', error);
            });
    }

    callDedupeSequentially() {
        if (this.currentIndex >= this.applicantIds.length) {
            console.log('All dedupe calls completed.');
            return;
        }
        callDedupeAPI({ applicantId:applicantId ,loanId:this.recordId})
            .then(response => {
                console.log('Dedupe success for applicant:', applicantId, response);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Deupe api is successfully',
                    variant: 'Success',
         
                }));
                this.currentIndex++;
                this.callDedupeSequentially(); 
            })
            .catch(error => {
                console.error('Error in deduping applicant:', applicantId, error);
                this.currentIndex++;
                this.callDedupeSequentially();
            });
    }

    // sales-Ishi
    hideModalBox(){
        this.errorModal = false;
    }
}