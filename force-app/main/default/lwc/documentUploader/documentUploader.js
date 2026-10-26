import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getCamCalcDetail from '@salesforce/apex/AHL_DocumentUploaderController.getCamCalcDetail';
import createDocumentDetail from '@salesforce/apex/AHL_DocumentUploaderController.createDocumentDetail';
import getFileMeta from '@salesforce/apex/AHL_DocumentUploaderController.getFileMeta';

export default class DocumentUploader extends LightningElement {
    @api recordId;
    @api enableDisabled =false;
    @api disabledCmp = false;

    acceptedFormats = ['.pdf', '.jpg', '.jpeg', '.png', '.xlsx', '.xls'];
    detail;
    _wiredDetailResult;

    // modal state
    isModalOpen = false;
    previewUrl;
    modalTitle = 'CAM Calculation';
    isImage = false;

    @wire(getCamCalcDetail, { parentId: '$recordId' })
    wiredDetail(result) {
        this._wiredDetailResult = result;
        if (result.data) this.detail = result.data;
    }

    get hasFile() {
        return !!(this.detail && this.detail.Content_Document_Id__c);
    }

    async handleUploadFinished(event) {
        const file = (event.detail.files && event.detail.files[0]) || null;
        if (!file) return;
        try {
            await createDocumentDetail({ contentDocumentId: file.documentId, parentId: this.recordId });
            this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'CAM Calculation uploaded.', variant: 'success' }));
            await refreshApex(this._wiredDetailResult);
            this.detail = await getCamCalcDetail({ parentId: this.recordId });
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Upload failed', message: e?.body?.message || 'Unexpected error', variant: 'error' }));
        }
    }

    async openPreview() {
        const docId = this.detail?.Content_Document_Id__c;
        if (!docId) return;

        const meta = await getFileMeta({ contentDocumentId: docId });
        const type = (meta?.fileType || '').toLowerCase();
        this.modalTitle = meta?.title || 'CAM Calculation';

        this.isImage = ['jpg','jpeg','png','gif','bmp','webp'].includes(type);
        if (this.isImage) {
            this.previewUrl = `${window.location.origin}/sfc/servlet.shepherd/version/download/${meta.versionId}`;
        } else {
            this.previewUrl = `${window.location.origin}/sfc/servlet.shepherd/document/download/${docId}#toolbar=0`;
        }

        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
        this.previewUrl = null;
        this.isImage = false;
    }
}