import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from "lightning/navigation";

import getObjectName from '@salesforce/apex/AssignmentScreenController.getObjectName';
import getCurrentAssignee from '@salesforce/apex/AssignmentScreenController.getCurrentAssignee';
import getNewAssignee from '@salesforce/apex/AssignmentScreenController.getNewAssignee';

import reAssignRecord from '@salesforce/apex/AssignmentScreenController.reAssignRecord';

export default class AssignmentScreen extends LightningElement {
    @api recordId;
    @api isModalOpen;

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
    @api headerTitle= 'Reassign Report';
    @api buttonLabel = 'Reassign';

    @api isLoanAssignmentScreen;
    

    get reportOptions(){
        return[
            { label: 'Loan Application', value: 'Loan Application' },
            { label: 'Technical', value: 'Technical' },
            { label: 'Legal', value: 'Legal' },
            { label: 'Field Investigation', value: 'Field Investigation' },
        ];
    }

    // Full list of options example
    allAssigneeOptions = [
        { label: 'Alice', value: 'alice' },
        { label: 'Bob', value: 'bob' },
        { label: 'Charlie', value: 'charlie' },
        
    ];

    connectedCallback() {
        this.isModalOpen = true;
        console.log('Record Id:', this.recordId);
        console.log('isLoan:', this.isLoan);
        console.log('isLoanAssignmentScreen:', this.isLoanAssignmentScreen);
        this.getObjectName();
        
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
                if(this.reportType== 'Loan Application' && !this.isLoanAssignmentScreen){
                    this.isLoan= true;
                    this.getNewAssignee();
                } else if(this.reportType== 'Loan Application' && this.isLoanAssignmentScreen){
                    this.isLoan= false;
                    this.getNewAssignee();
                }

            }
        }).catch(error=>{
            console.error('error in getObjectName---', error);
            
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
                this.getNewAssignee();
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
        this.dispatchEvent(new CustomEvent('closeappraiser', {}));
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

    // getReportRecords(){
    //     getReportRecords({
    //         loanId : this.recordId,
    //         selectedType: this.reportType
    //     }).then(response=>{
    //         console.log('response in getReportRecords--', response);
            
    //         if(response != undefined){
    //             let options = [];
    //             this.otherSelected= true;
    //             console.log('this.otherSelected---', this.otherSelected);
                
    //             for (var key in response) {
    //                 console.log('key --' + key);
    //                 options.push({ label: response[key], value: key });
    //             }
    //             this.recordoptions = options;
    //         }
    //     }).catch(error=>{
    //         console.error('error in getReportRecords---', error);
            
    //     })
    // }
    
    handleRecordChange(event){
        this.selectedRecord= event.target.value;
        console.log('this.selectedRecord-- in handleRecordChange--', this.selectedRecord);
        
        // this.selectedRecordId = event.target.options.find(opt => opt.value === event.detail.value).label;
        this.newAssignee= null;
        this.getCurrentAssignee();
    }

    handleAssigneeChange(event){
        this.newAssignee= event.target.value;
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
        this.showConfirmScreen = true;
        //this.isModalOpen=false;
    }

    handleNoPerm(){
        this.showConfirmScreen= false;
        //this.isModalOpen=true;
    }

    handleYesPerm(){
        var recId;
        if(this.objectSelected){
            recId= this.selectedRecord;
        }else{
            recId= this.recordId;
        }
        console.log('this.currentAssignee---'+this.currentAssignee);
        console.log('this.newOwner---'+this.newAssignee);
        reAssignRecord({
            recordId: recId,
            newOwner: this.newAssignee
        }).then(response=>{
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Owner changed successfully.',
                variant: 'Success',
            }));
            this.getObjectName();
            // if(this.objectApiName != 'Fraud_Control_Unit__c'){
            //     this[NavigationMixin.Navigate]({
            //         type: 'standard__recordPage',
            //         attributes: {
            //             recordId: this.recordId,
            //             objectApiName: this.objectApiName,
            //             actionName: 'view'
            //         }
            //     })
            // }
            // else{
                location.reload();
            // }
        }).catch(error=>{
            console.error('error in reAssignRecord---', error);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error,
                variant: 'error',
            }));            
            
        })
    }

    getNewAssignee(){
        var recId;
        if(this.objectSelected){
            recId= this.selectedRecord;
        }else{
            recId= this.recordId;
        }
        console.log('line 254-->>', recId);
        console.log('this.selectedRecord in getNewAssignee----', this.selectedRecord);
        console.log('this.newAssigneee---', this.newAssignee);

        if(this.reportType== 'Loan Application' && this.isLoanAssignmentScreen){
            this.assigneeoptions = [...this.allAssigneeOptions];
            console.log('this.assigneeoptions---', this.assigneeoptions);
        }
        else{
            getNewAssignee({
                recordId : recId
            }).then(response=>{
                console.log('response in getNewAssignee--', response);
                let options = [];
                if(response != undefined){
                    for (var key in response) {
                        console.log('key --' + key);
                        options.push({ label: response[key], value: key });
                    }
                    this.assigneeoptions = options;
                }
            }).catch(error=>{
                console.error('error in getNewAssignee---', error);
                
            })
        }
        
    }

    // Handle changes to the search field
    handleSearch(event) {
        const searchTerm = event.target.value.toLowerCase();

        // Filter the full list based on the search term (using the label field)
        this.assigneeoptions = this.allAssigneeOptions.filter(option =>
            option.label.toLowerCase().includes(searchTerm)
        );
    }

}