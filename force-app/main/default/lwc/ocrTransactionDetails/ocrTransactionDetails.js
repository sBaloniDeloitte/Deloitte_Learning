import { api, wire, LightningElement } from 'lwc';
import getOcrCaptureTransaction from '@salesforce/apex/Hl_OcrDetailsController.getOcrCaptureTransaction';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OcrTransactionDetails extends LightningElement {
    @api recordId;
    @api refreshData() {
        this.getOcrCapture();
    }
    
    loanTransactionData = [];
    connectedCallback() {
        this.getOcrCapture();
    }
 

    getOcrCapture() {
        getOcrCaptureTransaction({ recordId: this.recordId })
            .then(result => {
                console.log('ocrresult', result);
                if (result && result.length > 0) {
                    const mappedSteps = result.map(record => ({
                        id: record.Id,
                        index: record.Step_Sequence__c,
                        builderDemand: record.Builder_Demand__c || '',
                        paidAmount: record.Paid_Amount__c || '',
                        receiptDate: record.Receipt_Date__c || '',
                        remarks: record.Remark__c || '',
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
                    this.loanTransactionData = [...mappedSteps];
                }
                // this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetch OCR transaction', error);
                // this.isLoading = false;
                this.showToast('Error', 'Failed to fetch OCR details', 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}