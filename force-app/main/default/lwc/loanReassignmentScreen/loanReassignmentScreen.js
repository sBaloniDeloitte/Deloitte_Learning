import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from "lightning/navigation";

import getObjectName from '@salesforce/apex/AssignmentScreenController.getObjectName';
import getCurrentAssignee from '@salesforce/apex/AssignmentScreenController.getCurrentAssignee';
import getNewAssignee from '@salesforce/apex/Credit_LoanAssignmentController.getNewAssignee';
import confirmReassignment from "@salesforce/apex/Credit_LoanAssignmentController.confirmReassignment";
import checkAuthorization from "@salesforce/apex/Credit_LoanAssignmentController.checkAuthorization";
import addUserToOpportunityTeam from '@salesforce/apex/Credit_LoanAssignmentController.addUserToOpportunityTeam';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import { CurrentPageReference } from 'lightning/navigation';

export default class LoanReassignmentScreen extends LightningElement {
    @api recordId;
    @api recordIds = []; // Multiple records for List View
    @api isModalOpen;
    @track isMultiMode = false; // Toggle between single and multi-record mode
    @track isLoan;
    @track reportType;
    @track otherSelected;
    @track recordoptions;
    @track selectedRecord;
    @track selectedRecordId;
    @track currentAssignee;
    @track showNewAssignee;
    @track newAssignee;
    @track showConfirmScreen;
    @track objectSelected= false;
    @track assigneeoptions;
    @track objectApiName;
    @track headerTitle= 'Re-Assign Loan';
    @track buttonLabel = 'Reassign';
    showUnauthorisedMessage = false;
    message =  '';
    @track showOPS= false;
    @track showOptions = false;
    @track selectedOPSType;
    @track OPSTypeOptions = [];
     allAssigneeOptions;
    @track showInlineError = false;
    @track inlineErrorMessage = '';


    @api isLoanAssignmentScreen;
    cssContainer = 'slds-modal__container width-90';
    cssContainerAssignModal =  'slds-modal__container width-90';

    OPSTypeOptions = [
        { label: 'OPS Maker', value: 'OPS Maker' },
        { label: 'OPS Author', value: 'OPS Author' },

    ];
    
    // Other properties and methods...

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef) {
            // Check the state for the recordId parameter.
            this.recordId = pageRef.state.recordId || this.recordId;
            // For debugging:
            console.log('Record Id from URL:', this.recordId);
        }
    }
    

    get reportOptions(){
        return[
            { label: 'Loan Application', value: 'Loan Application' },
            { label: 'Technical', value: 'Technical' },
            { label: 'Legal', value: 'Legal' },
            { label: 'Field Investigation', value: 'Field Investigation' },
        ];
    }    

    connectedCallback() {
        this.isMultiMode = Array.isArray(this.recordIds) && this.recordIds.length > 0;
        if (!this.isMultiMode) {
            this.recordIds = [this.recordId];
        }

        // getLoanStage({loanId: this.recordId})
        // .then((result) => {
        //     console.log('result in getLoanStage----', result);
        //     if(result == 'Disbursement'){
        //         this.showOPS= true;
        //     }
        //     checkAuthorization().then((result) => {
        //         console.log('result----', result);
                
        //         if(result!= 'Success'){
        //             this.showUnauthorisedMessage = true;
        //             this.message =  result;
        //         }else{
        //             this.getObjectName();
                    
        //         }
        //         this.isModalOpen = true;
        //     }).catch(error=>{
        //         console.log('Error>>'+JSON.stringify(error));

        //     })
        // }).catch(error=>{
        //     console.log('Error>>'+JSON.stringify(error));

        // })

        
        getLoanStage({loanId: this.recordId})
    .then((result) => {
        console.log('result in getLoanStage----', result);

        if(result == 'Disbursement'){
            this.showOPS = true;
        }

        this.getObjectName();
        this.isModalOpen = true;

    })
    .catch(error => {
        console.log('Error>>' + JSON.stringify(error));
    });
       
        
    }

    // renderedCallback(){
    //     const style = document.createElement('style');
    //         style.innerText = `.slds-modal__container .empty .closeIcon{
    //                                 display:none;
    //                             }`;
    //         // this.template.querySelector('.slds-modal__container').appendChild(style);
    // }
    _hideQuickActionClose = false;
    renderedCallback() {
    if (!this._hideQuickActionClose) {
        const style = document.createElement('style');

        style.innerText = `
            .slds-modal__close {
                display: none !important;
            }
        `;

        document.head.appendChild(style);
        this._hideQuickActionClose = true;
    }
}

    getObjectName(){
        console.log('inside getObjectName----');
        
        getObjectName({
            recordId : this.recordId
        }).then(response=>{
            console.log('response in getObjectName--', response);
            
            if(response != undefined && response.length>0){
                this.reportType= response[0];
                this.objectApiName= response[1];
                this.getCurrentAssignee();
                console.log('this.reportType--', this.reportType);
                console.log('this.showOPS-----', this.showOPS);
                
                if(this.reportType== 'Loan Application'){
                    if(!this.showOPS){
                        this.getNewAssignee();
                    }                    
                }
            }
        }).catch(error=>{
            console.log(JSON.stringify(error));
            this.showToast(
                'Error',
                error.body.message,
                'error');
            
        })
    }
    

    getCurrentAssignee(){
        var recId;
        if(this.objectSelected){
            recId= this.selectedRecord;
        }else{
            recId= this.recordId;
        }
        
        getCurrentAssignee({
            recordId : recId
        }).then(response=>{
            console.log('response in getCurrentAssignee--', response);
            
            if(response != undefined && response.length>0){
                this.currentAssignee= response;
                if(!this.showOPS){
                    this.getNewAssignee();
                } 
            }
        }).catch(error=>{
            console.error('error in getCurrentAssignee---', error);
            
        })
    }

    openModel() {
        this.isModalOpen = true;
    }

    closeModel() {
        this.isModalOpen = false;
       // this.dispatchEvent(new CustomEvent('closeappraiser', {}));
        this.modalVisibility = false;
        this.dispatchEvent(new CustomEvent('closemodal'));
        // Redirect after 1 second
        setTimeout(() => {
            this.redirectToOpportunity();
        }, 300);
    }

    handleTypechange(event){
        
        this.reportType= event.target.value;
        this.currentAssignee= '';
        this.newAssignee= '';
        this.selectedRecord= '';
        // this.selectedRecordId='';
        console.log('this.reportType------', this.reportType);
        if(this.reportType== 'Loan Application'){
            this.getCurrentAssignee();
        }else{
            this.objectSelected= true;
            //this.getReportRecords();
        }
    }

    handleRecordChange(event){
        this.selectedRecord= event.target.value;
        console.log('this.selectedRecord-- in handleRecordChange--', this.selectedRecord);
        
        // this.selectedRecordId = event.target.options.find(opt => opt.value === event.detail.value).label;
        this.newAssignee= null;
        this.getCurrentAssignee();
    }

    handleAssigneeChange(event){
        this.newAssignee= event.target.value;
        console.log('this.newAssignee:: '+this.newAssignee);
    }

    reassignRecord(){
        if(this.objectSelected){
            if(this.selectedRecord== undefined || this.selectedRecord== '' || this.selectedRecord== null){
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select a  record to reassign',
                    variant: 'error',
                }));
                return;
            }
        }
        
        if(this.newAssignee== undefined || this.newAssignee== '' || this.newAssignee== null){
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please select assignee',
                variant: 'error',
            }));
            return;
        }

        if(this.showOPS && (this.selectedOPSType== null || this.selectedOPSType == ''|| this.selectedOPSType == undefined)){
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please select OPS type',
                variant: 'error',
            }));
            return;
        }
        this.showConfirmScreen = true;
        //this.isModalOpen=false;
    }

    handleNoPerm(){
        this.showConfirmScreen= false;
        //this.isModalOpen=true;
    }

    async handleYesPerm() {
        //let recId = this.objectSelected ? this.selectedRecord : this.recordId;
        //console.log('Opportunity ID:', recId);
        console.log('New Assignee User ID:', this.newAssignee);

        if (!this.recordId || !this.newAssignee) {
            this.showToast('Error', 'Missing Opportunity ID or User ID.', 'error');
            return;
        }

        try {

            //const result = await addUserToOpportunityTeam({ opportunityId: this.recordId, userId: this.newAssignee });
            const result = await confirmReassignment({ loanApplicationRecordId: this.recordId, newAssigneeId: this.newAssignee, selectedOPSType: this.selectedOPSType });

            if (result.includes('User reassigned successfully')) {
                this.showToast('Success', result, 'success');

                // Close the modal
                this.modalVisibility = false;
                this.dispatchEvent(new CustomEvent('closemodal'));

                // Redirect after 1 second
                setTimeout(() => {
                    this.redirectToOpportunity();
                }, 300);
            } else {
                // If response is an error message, manually throw an error
                throw new Error(result);
            }
        } catch (error) {
            console.error('Caught Error:', error);

            let errorMessage = 'An unexpected error occurred.';
            
            if (error.body && error.body.message) {
                errorMessage = error.body.message;
            } else if (error.message) {
                errorMessage = error.message;
            }

            // Ensuring the toast notification is explicitly called outside the async block
            setTimeout(() => {
                this.showToast('Error', errorMessage, 'error');
            }, 100); // Slight delay to ensure UI updates
        }
    
    }

    redirectToOpportunity() {
        const baseUrl = window.location.origin;
        const redirectUrl = `${baseUrl}/lightning/r/Opportunity/${this.recordId}/view`;
        window.location.href = redirectUrl;
    }

    getNewAssignee(){
        var recId;
        if(this.objectSelected){
            recId= this.selectedRecord;
        }else{
            recId= this.recordId;
        }

        console.log('this.selectedRecord in getNewAssignee----', this.recordId);
        console.log('this.newAssigneee---', this.newAssignee);

        
        getNewAssignee({
            recordId : this.recordId,
            selectedOPSType: this.selectedOPSType
        }).then(response=>{
            console.log('response in getNewAssignee--', response);
            let options = [];
            if(response != undefined){
                for (var key in response) {
                    console.log('key --' + key);
                    options.push({ label: response[key], value: key });
                }
                this.assigneeoptions = options;
                this.allAssigneeOptions = options;
                this.showOptions = true;
            }
        }).catch(error=>{
            // if(error.body.message.includes('are not allowed to reassign loan.')){
            //     this.showUnauthorisedMessage = true;
            //     this.message = error.body.message;
            // }else{
                this.showToast('Error',error.body.message,'error');
            // } 
        })
       
        
    }

    // Handle changes to the search field
    handleSearch(event) {
        const searchTerm = event.target.value.toLowerCase();
        console.log('searchTerm--', searchTerm);

        // Filter the full list based on the search term (using the label field)
        this.assigneeoptions = this.allAssigneeOptions.filter(option =>
            option.label.toLowerCase().includes(searchTerm)
        );
        if(searchTerm == ''){
            this.assigneeoptions = this.allAssigneeOptions;
        }
       
        
    }

    showToast(title, message, variant) {
        // Error messages (e.g. "You are not authorized to reassign") are
        // now displayed as a centered themed panel inside the modal
        // instead of a browser toast. Success toasts are unaffected.
        if (variant === 'error') {
            this.inlineErrorMessage = message;
            this.showInlineError = true;
            return;
        }
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    handleOPSTypeChange(event){
        this.selectedOPSType = event.target.value;
        console.log('selectedOPSType-----', this.selectedOPSType);
        if(this.selectedOPSType != null && this.selectedOPSType != '' && this.selectedOPSType != undefined){
            this.getNewAssignee();
        }
        
    }

}