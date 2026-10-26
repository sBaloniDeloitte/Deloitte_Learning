import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkForMandatoryDoc from '@salesforce/apex/TechnialAdditionalChildController.checkForMandatoryDoc';
import generateAndSavePDF from '@salesforce/apex/TechnicalEvaluationPDFController.generateAndSavePDF';
import { getRecord } from "lightning/uiRecordApi";
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';


export default class CallTechnialReportCmp extends NavigationMixin(LightningElement) {
    hasError = false;
    @track errors = [];

    _recordId;

    @api
    set recordId(value) {
        this._recordId = value;
        if (value) {
            console.log('Record Id received:', value);
            this.handleRecordLoad();
        }
    }

    get recordId() {
        return this._recordId;
    }

    handleRecordLoad() {
        checkForMandatoryDoc({ techId: this._recordId }).then(result => {
            console.log('comresultplition', result.length);
            if (result.length > 0) {
                this.errors = result;
                this.hasError = true;
            } else {
                generateAndSavePDF({ recordId: this.recordId })
                    .then(res => {
                        console.log('ContentVersionId:', res.ContentVersionId);
                        console.log('ContentDocumentId:', res.ContentDocumentId);
                        const url = '/apex/VFGenerateTechnicalReport?id=' + this.recordId;
                        window.open(url, '_blank');
                        this.dispatchEvent(new CloseActionScreenEvent());
                        setTimeout(() => {
                            window.location.reload();
                        }, 2000); // 3 seconds delay
                    })
                    .catch(error => {
                        console.log('error:', error);
                        //  this.showToast('Error', error.body?.message || error.message, 'error');
                    });
            }
        }).catch(error => {
            console.log('error', error);
        });
    }


    /*
        connectedCallback() {
            console.log('tech id', this.recordId);
            checkForMandatoryDoc({ techId: this.recordId }).then(result => {
                console.log('comresultplition', JSON.stringify(this.result));
                if(result.length > 0) {
                    this.errors = result;
                    this.hasError = true;
                }else { 
                    
                    this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: '/apex/VFGenerateTechnicalReport?id=' + this.recordId
                    }
                   });
                }
                
                
            }).catch(error => {
                console.log('error', error);
            });
        }*/

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}