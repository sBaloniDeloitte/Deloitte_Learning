import {
    LightningElement,
    api,
    track
} from 'lwc';
import {
    NavigationMixin
} from "lightning/navigation";
import {
    deleteRecord,
    updateRecord
} from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import createDeviation from '@salesforce/apex/HL_DeviationRecordPageController.createDeviationRecord';
import checkDupDeviationRecord from '@salesforce/apex/HL_DeviationRecordPageController.checkDupDeviationRecord';

import getDeviationRecords from '@salesforce/apex/HL_DeviationRecordPageController.getAllDeviations';
import deleteDeviation from '@salesforce/apex/HL_DeviationRecordPageController.deleteDeviation';
import updateRemarksOnDeviation from '@salesforce/apex/HL_DeviationRecordPageController.updateRemarksOnDeviation';
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';
//

//import setDocument from '@salesforce/apex/GenericInitiateController.setDocument';
//import deleteContent from '@salesforce/apex/GenericInitiateController.deleteContent';
//import uploadFile from '@salesforce/apex/FieldInvestigationController.uploadFile';

export default class Hl_ParentDeviationCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    @track hasPsvOrDisbursalStage = false;
    @track isDisabled = false;
    @track showAdditionScreen = false;
    @track showInputText = false;
    @track selectedDeviationId;
    @track selectedDeviationType;
    @track selected;
    isDataPresent = true;
    @track deviationTable={};

    @track maxResult = 10;

    toastvariant = {
        SUCCESS : 'success',
        ERROR : 'error'
    }
    toastTitle = {
        SUCCESS : 'Success',
        ERROR : 'Error'
    }

    toastMessages = {
        DELETE_DEVIATION_SUCESS_MESSAGE : 'Deviation deleted Successfully.',
        DELETE_DEVIATION_FAILURE_MESSAGE : 'Unable to delete the Deviation.',
        DEVIATION_ADDED_SUCCESSFULLY : 'Deviation added Successfully.',
        SOMETHING_WENT_WRONG : 'Something went wrong.',
        Already_Added : 'There is an existing deviation record created with this condition. Please select another deviation condition.',
        Everything_Added : 'Please add the necessary mitigants and the applicable deviation target to proceed.',
        NoMitigants : 'Please select the necessary  mitigant or mitigants in order to proceed.',
        AddMitigants : 'Please add atleast one mitigant.',
        MITIGANTS_UPDATED : 'Mitigant updated.',
    }

    @track disabledCmp = false;
    connectedCallback() {
        this.isDataPresent = true;
        this.fetchLoanStage();
        this.getDevationsDetails();
        this.checkCmpEditability();
    }

     checkCmpEditability() {
    getComponentEditability({ loanId : this.recordId, component : '' })
    .then(result => {
        if(result){
            this.disabledCmp = result;
            console.log('this.hideButton>>>>'+this.hideButton);
        }
    })
    .catch(error => {
        console.log('Error getComponentEditability:  '+error);
    });
  }
    fetchLoanStage() {
        getLoanStage({
            loanId: this.recordId
        })
            .then(result => {
                console.log('Result1', result);
                if (result == 'PSV' || result == 'Disbursement') {
                    this.hasPsvOrDisbursalStage = true;
                } else if (result == 'Credit Underwriting') {

                }
            })
            .catch(error => {
                console.error('Error:', error);
            });
    }

    handleAddDeviationRecord() {
        this.showAdditionScreen = true;
    }

    handleRefresh() {

    }
    @track filterCriteria = '';
    @track showmitigantsList = false;
    @track filterCriteriaCate = '[RecordType.Name = Deviation;Product_Name__c!=Home Loan;Is_Active__c=true]';
    @track mitigantsVal = '';
    handleDeviationSelctiontype(event) {
        //this.selectedDeviationId = event.detail.searchRecord.Id;
        this.selectedDeviationType = event.detail.searchRecord.Deviation_Category__c;
        this.selected = true;
        this.filterCriteria = '[RecordType.Name = Deviation;Deviation_Category__c = ' + this.selectedDeviationType + ';Product_Name__c!=Home Loan;Is_Active__c=true]';
        console.log('Selected deviation ID: ' + this.selectedDeviationId);
        console.log('Selected selectedDeviationtype ' + this.selectedDeviationType);
    }

    handleDeviationDeselctiontype(event) {
        console.log('delesect');
        //this.selectedDeviationId = '';
        this.selectedDeviationType = '';
        this.selected = false;
        this.filterCriteria = '[RecordType.Name = Deviation;Is_Active__c=true]';
        this.selectedDeviationId = '';
        this.showmitigantsList = false;
        this.mitigantsVal = '';
        //this.createdDevIds=[];
    }
    handleDeviationSelction(event) {
        this.selectedDeviationId = event.detail.searchRecord.Id;
        this.showmitigantsList = true;
        //this.selectedDeviationType = event.detail.searchRecord.Description__c;
        
        console.log('Selected deviation ID: ' + event.detail.searchRecord.Id);
        console.log('Selected selectedDeviationtype ' + event.detail.searchRecord.Description__c);
    }

    handleDeviationDeselction(event) {
        this.selectedDeviationId = '';
        this.showmitigantsList = false;
        this.mitigantsVal = '';
        //this.createdDevIds=[];
    }
    handleMitigants(event) {
        this.mitigantsVal = event.target.value;
    }
    handleSaveManualDeviation(event){
        
        if(this.mitigantsVal=='' || this.mitigantsVal == undefined || this.mitigantsVal == null){
            this.handletoastEvent(this.toastMessages.AddMitigants,this.toastTitle.ERROR,this.toastvariant.ERROR);
        }else {
            checkDupDeviationRecord({
                recordId: this.recordId,
                devMaster: this.selectedDeviationId
            })
                .then(result => {
                    console.log('Result1', result);
                    if (result) {
                        this.handletoastEvent(this.toastMessages.Already_Added,this.toastTitle.ERROR,this.toastvariant.ERROR);
                        this.reset(event);
                    } else {
                        this.saveDeviation();
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                });


            
        }
    }

    saveDeviation() {
        
        createDeviation({
            recordId: this.recordId,
            devMaster: this.selectedDeviationId,
            mitigants: this.mitigantsVal
        })
            .then(result => {
                console.log('Result1', result);
                if (result == 'success') {
                    this.handletoastEvent(this.toastMessages.DEVIATION_ADDED_SUCCESSFULLY,this.toastTitle.SUCCESS,this.toastvariant.SUCCESS);
                    this.getDevationsDetails();
                    this.reset();
                } else {

                }
            })
            .catch(error => {
                console.error('Error:', error);
            });
    }
    handletoastEvent(msg,title,variant){
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
        }));
    }

    getDevationsDetails() {
        getDeviationRecords({ recordId: this.recordId })
            .then(response => {
                console.log('response',response);
                if (response.length > 0) {
                    // Convert mitigants string into an array for each item
                    this.deviationTable = response.map(item => ({
                        ...item,
                        mitigantsArray: item.mitigants ? item.mitigants.split(',').map(m => m.trim()) : [],
                       
                    }));
                    this.isDataPresent = false;
                } else {
                    this.isDataPresent = true;
                }
            })
            .catch(error => {
                this.handletoastEvent(this.toastMessages.SOMETHING_WENT_WRONG, this.toastTitle.ERROR, this.toastvariant.ERROR);
            });
    }

    handleSaveRowValue(event){
        console.log('Inside handleSaveRowValue');
        console.log('Inside handleSaveRowValue event---', event.target.dataset.id);
        console.log('Inside handleSaveRowValue event field---', event.target.name);
        console.log('Inside handleSaveRowValue event value---', event.target.value);
        updateRemarksOnDeviation({ recordId: event.target.dataset.id , remarks: event.target.value, field: event.target.name})
        .then(response => {
            // console.log('response '+response);
            this.handletoastEvent(this.toastMessages.MITIGANTS_UPDATED,this.toastTitle.SUCCESS,this.toastvariant.SUCCESS);
            this.getDevationsDetails();
        })
        .catch(error => {
            console.log('error in updateRemarksOnDeviation '+error);
        })

    }

    deleteDeviation(event){
        deleteDeviation({
            devId:event.target.dataset.id
        }).then(response=>{
            this.getDevationsDetails();
            this.handletoastEvent(this.toastMessages.DELETE_DEVIATION_SUCESS_MESSAGE,this.toastTitle.SUCCESS,this.toastvariant.SUCCESS);
        }).catch(error=>{
            this.handletoastEvent(this.toastMessages.DELETE_DEVIATION_FAILURE_MESSAGE,this.toastTitle.ERROR,this.toastvariant.ERROR);
        })
    }
    handleClose(){
        this.showAdditionScreen = false;
        this.selectedDeviationType = '';
        this.selected = false;
        this.filterCriteria = '[RecordType.Name = Deviation;Is_Active__c=true]';
        this.selectedDeviationId = '';
        this.showmitigantsList = false;
        this.mitigantsVal = '';
        this.selectedDeviationId = '';
        this.showmitigantsList = false;
        this.mitigantsVal = '';
    }

    reset(event) {
        
        
        this.selectedDeviationType = '';
                    this.selected = false;
                    this.filterCriteria = '[RecordType.Name = Deviation;Is_Active__c=true]';
                    this.selectedDeviationId = '';
                    this.showmitigantsList = false;
                    this.mitigantsVal = '';
                    this.selectedDeviationId = '';
                    this.showmitigantsList = false;
                    this.mitigantsVal = '';
                    
                    
                    this.handleDeviationDeselctiontype(event);
                    this.showAdditionScreen = false;
                    this.showInputText = true;
                    this.showAdditionScreen = true;
                    setTimeout(() => {
                        this.showInputText = false;
                    }, 500);
                    


                   
    }
}