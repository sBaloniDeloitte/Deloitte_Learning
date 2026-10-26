import { LightningElement, api, wire } from 'lwc';
import generatePDF from '@salesforce/apex/DigitalSignatureController.generatePDF';
import checkSigned from '@salesforce/apex/DigitalSignatureController.checkSigned';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class DigitalSignatureAction extends LightningElement {

    @api
    set recordId(value) {
        this._recordId = value;
        if (value) {
            console.log('Record Id received:', value);
            this.loadStatus();
        }
    }

    get recordId() {
        return this._recordId;
    }
    isSigned = false;
    imageUrl = '';

    connectedCallback() {
        console.log('recordId>>>', this.recordId);
        //  this.loadStatus();
    }

    loadStatus() {
        checkSigned({ recordId: this.recordId })
            .then(res => {
                console.log('res>>>>', res);
                this.isSigned = res;
            });
    }

    handleSign() {
        generatePDF({ recordId: this.recordId })
            .then(result => {
                console.log('result>>>>', result);
                //this.imageUrl = result;
                if (result === 'success') {
                    this.showToast('Success', 'Signature saved successfully', 'success');
                   // const url = '/apex/VFGenerateTechnicalReport?id=' + this.recordId;
                   // window.open(url, '_blank');
                    this.dispatchEvent(new CloseActionScreenEvent());
                }
            })
            .catch(err => {
                console.log('err>>>', err);
                this.showToast('Error', err.body.message, 'error');
            });
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}