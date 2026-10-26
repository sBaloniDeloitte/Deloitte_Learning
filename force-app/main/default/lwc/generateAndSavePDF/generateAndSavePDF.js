import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateAndSavePDF from '@salesforce/apex/TechnicalEvaluationPDFController.generateAndSavePDF';

export default class GenerateAndSavePDF extends LightningElement {
    @api recordId;
    handleGeneratePDF() {

        generateAndSavePDF({ recordId: this.recordId })
            .then(result => {

                console.log('ContentVersionId:', result.ContentVersionId);
                console.log('ContentDocumentId:', result.ContentDocumentId);

                // this.showToast('Success', 'PDF saved successfully', 'success');
                const url = '/apex/VFGenerateTechnicalReport?id=' + this.recordId;
                window.open(url, '_blank');
                setTimeout(() => {
                    window.location.reload();
                }, 3000); // 3 seconds delay
            })
            .catch(error => {
                console.log('error:', error);
                //  this.showToast('Error', error.body?.message || error.message, 'error');
            });
    }
    @api
    invoke() {
        this.handleGeneratePDF();
    }



}