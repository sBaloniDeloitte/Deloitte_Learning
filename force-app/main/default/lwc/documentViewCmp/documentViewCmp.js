import { LightningElement, api, track, wire } from 'lwc';
import getAllDocument from '@salesforce/apex/SalesDocumentCmpController.getAllDocument';
import sendBackDoc from '@salesforce/apex/DocumentViewCmpController.sendBackDoc';
import validateDoc from '@salesforce/apex/DocumentViewCmpController.validateDoc';
import getBase64FromContentId from '@salesforce/apex/SalesDocumentCmpController.getBase64FromContentId';
import unValidateDoc from '@salesforce/apex/DocumentViewCmpController.unValidateDoc';
import checkDataFilledOrNotWrapper from '@salesforce/apex/DocumentViewCmpController.checkDataFilledOrNotWrapper';
import reUploadFile from '@salesforce/apex/COMM_UploadViewDeleteDocumentController.reUploadFile';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import uploadFile from '@salesforce/apex/COMM_UploadViewDeleteDocumentController.uploadFile';
import { updateRecord } from 'lightning/uiRecordApi';
import initiateOCR from '@salesforce/apex/COMM_UploadViewDeleteDocumentController.initiateOCR';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

export default class documentViewCmp extends NavigationMixin(LightningElement) {

    @api recordId;
    @api docCheckId;
    @api docname;
    @api ckyc = false;
    @api salesdocname;
    @api docMasterName;
    @api loginChecklist;
    @api contentDocId;
    @api extension;
    @api fromSales = false;
    @api docVersion;
    @api catg;
    @api showMaskingCheck;
    //@api currentIndex = 0;
    @api isSplitViewMode = false;
    @api singleDocumentData = null;
    @track imageUrl;
    @track isNext = false;
    @track isValidated = false;
    @track isback = false;
    @track currentIndex = 0;
    @track isPdf = false;
    @track pdfUrl = 'about:blank';
    @track isShowModal = false;
    @track remarks = '';
    @track status;
    @track custname;
    @track docCategory;
    //@track doctype; // Add this to track doctype
    @api appId;
    @api isAcknowledged;
    isRetakeCase = false;
    @track noImage = false;
    @track isLoading = false;
    @track zoomLevel = 1;
    @track showimage = false; // Changed default to false
    @api ocrApplicable;
    @track errorList = [];
    @track showError = false;
    @track checked;
    @track userName;
    @track nextorprev = false;
    @track disableMaskingCheck = false;
    @api disabled;
    _baseUrl;

    @wire(getRecord, { recordId: USER_ID, fields: [NAME_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.userName = data.fields.Name.value;
        } else if (error) {
            console.error('Error fetching user data:', error);
        }
    }

     get isAndroid() {
        try { return /Android/i.test(navigator.userAgent || ''); }
        catch (e) { return false; }
    }

     get showAndroidPdfButton() {
        return this.isPdf && this.isAndroid && !!this.contentDocId;
    }

    handleOpenPdfExternally() {
        if (!this.pdfUrl && this.contentDocId) {
            this.setupPdfUrl();
        }
        if (!this.pdfUrl) {
            this.showToastMessage('Warning', 'Could not build PDF URL', 'warning');
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: this.pdfUrl
            }
        });
    }

    handleZoomIn() {
        this.zoomLevel = Math.min(this.zoomLevel + 0.1, 2);
        this.updateZoom();
    }

    handleZoomOut() {
        if (this.zoomLevel > 0.5) {
            this.zoomLevel -= 0.1;
            this.updateZoom();
        }
    }

    updateZoom() {
        let docViewer = this.template.querySelector('[data-id="documentViewer"]');
        let imgViewer = this.template.querySelector('[data-id="documentImage"]');

        if (docViewer) {
            docViewer.style.transform = `scale(${this.zoomLevel})`;
            docViewer.style.transformOrigin = "center";
        }

        if (imgViewer) {
            imgViewer.style.transform = `scale(${this.zoomLevel})`;
            imgViewer.style.transformOrigin = "center";
        }
    }

    renderedCallback() {
        if (!this.isRendered) {
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
        .form-div span.slds-file-selector__button.slds-button.slds-button_neutral{
            font-size: 0px;
        }
        .custom-table svg.slds-button__icon.slds-button__icon_left{
            margin: 0px;
        }
        .custom-table lightning-primitive-file-droppable-zone.slds-file-selector__dropzone{
            border: none;
        }
        .custom-table .slds-textarea{
            min-height: 200px;
        }
        .custom-table{
            font-weight: 400;
        }`
                ;
            this.template.querySelector('.styleContainer')?.appendChild(style);
            this.isRendered = true;
        }
    }

    connectedCallback() {
        console.log('documentViewCmp connectedCallback');
        console.log('docname 37' + this.docname);
        console.log('appId 37' + this.appId);
        console.log('recordId  40' + this.recordId);
        console.log('docCheckId  40' + this.docCheckId);
        console.log('docname  40' + this.docname);
        console.log('contentdocid 78', this.contentDocId);
        console.log('isSplitViewMode:', this.isSplitViewMode);
        console.log('singleDocumentData:', this.singleDocumentData);

        this._baseUrl = window.location.origin;
        console.log('_baseUrl 79', this._baseUrl);

        if (this.isSplitViewMode && this.singleDocumentData) {
            console.log('Handling Split View mode');
            this.handleSplitViewMode();
        } else if (this.fromSales) {
            console.log('Handling Sales mode');
            this.handleSalesMode();
        } else {
            console.log('Handling Normal mode - loading documents array');
            this.getAllRelatedDocs();
        }

        this.addEventListener('documentuploaded', this.handleDocumentUploaded.bind(this));
        this.addEventListener('ocrcompleted', this.handleOCRCompleted.bind(this));
    }

    handleDocumentUploaded(event) {
        console.log('Document uploaded event received:', event.detail);
        const { documentData, ocrData } = event.detail;
        this.refreshAfterUpload(documentData, ocrData);
    }

    handleOCRCompleted(event) {
        console.log('OCR completed event received:', event.detail);
        this.dispatchEvent(new CustomEvent('ocrready', {
            detail: event.detail,
            bubbles: true,
            composed: true
        }));
    }

    handleSplitViewMode() {
        try {
            console.log('Processing Split View mode');
            console.log('singleDocumentData:', JSON.stringify(this.singleDocumentData));
            this.status = this.singleDocumentData.Status || '';
            this.custname = this.singleDocumentData.custName || this.singleDocumentData.appName || '';
            this.docCategory = this.singleDocumentData.docCategory || '';
            this.doctype = this.singleDocumentData.docType || this.singleDocumentData.docCategory || ''; // Add this line
            this.checked = this.isAcknowledged;

            if (this.checked) {
                this.disableMaskingCheck = true;
            }
            this.displaySingleDocument();

            console.log('Split View mode setup complete');
            console.log('status:', this.status);
            console.log('custname:', this.custname);
            console.log('doctype:', this.doctype);
            console.log('showimage:', this.showimage);
            console.log('isPdf:', this.isPdf);
            console.log('noImage:', this.noImage);

        } catch (error) {
            console.error('Error in handleSplitViewMode:', error);
            this.showToastMessage('Error', 'Failed to load document in Split View', 'error');
        }
    }

    displaySingleDocument() {
        console.log('displaySingleDocument called');
        console.log('contentDocId:', this.contentDocId);
        console.log('extension:', this.extension);

        if (!this.contentDocId) {
            console.log('No content document ID - showing no image');
            this.noImage = true;
            this.isPdf = false;
            this.showimage = false;
            this.imageUrl = this.pdfUrl = null;
            return;
        }

        const ext = this.extension || this.singleDocumentData?.fileType || this.singleDocumentData?.docExtention;
        console.log('Displaying document with extension:', ext);

        if (ext === 'pdf') {
            console.log('Setting up PDF display');
            this.isPdf = true;
            this.showimage = false;
            this.setupPdfUrl();
            this.imageUrl = null;
            this.noImage = false;
        } else if (ext) {
            console.log('Setting up Image display');
            this.isPdf = false;
            this.showimage = true;
            this.setupImageUrl();
            this.pdfUrl = null;
            this.noImage = false;
        } else {
            console.log('No valid extension found');
            this.noImage = true;
            this.isPdf = false;
            this.showimage = false;
            this.imageUrl = this.pdfUrl = null;
        }

        console.log('Final display state:', {
            isPdf: this.isPdf,
            showimage: this.showimage,
            noImage: this.noImage,
            imageUrl: this.imageUrl,
            pdfUrl: this.pdfUrl
        });
    }

    setupPdfUrl() {
    const cid = this.contentDocId;
    if (!cid) {
        this.noImage = true;
        return;
    }
    const base = window.location.origin.includes('my.site.com')
        ? `${window.location.origin}/losportal/sfc/servlet.shepherd/document/download/`
        : `${window.location.origin}/sfc/servlet.shepherd/document/download/`;
    this.pdfUrl = `${base}${cid}?t=${Date.now()}#navpanes=0&toolbar=1&scrollbar=0&zoom=page-width`;
    }


    setupImageUrl() {
        const cid = this.contentDocId;
        if (!cid) {
            this.noImage = true;
            return;
        }
        const base = window.location.origin.includes('my.site.com')
            ? `${window.location.origin}/losportal/sfc/servlet.shepherd/document/download/`
            : `${window.location.origin}/sfc/servlet.shepherd/document/download/`;
        this.imageUrl = `${base}${cid}?t=${Date.now()}`;
        console.log('Image URL set:', this.imageUrl);
    }

    handleSalesMode() {
        console.log('Processing Sales mode');
        this.showimage = true;

        if (this.extension === 'pdf') {
            this.isPdf = true;
            if (window.location.origin.includes('my.site.com')) {
                this.pdfUrl = window.location.origin + '/losportal/sfc/servlet.shepherd/document/download/' + this.contentDocId + '#toolbar=0';
            } else {
                this.pdfUrl = `${this._baseUrl}/sfc/servlet.shepherd/document/download/${this.contentDocId}#toolbar=0`;
            }
            console.log('pdfUrl ' + this.pdfUrl);
            this.imageUrl = null;
            this.noImage = false;
        } else if (this.extension != null && this.extension != undefined && this.extension != '') {
            this.isPdf = false;
            if (window.location.origin.includes('my.site.com')) {
                this.imageUrl = window.location.origin + '/losportal/sfc/servlet.shepherd/document/download/' + this.contentDocId;
                console.log(' this.imageUrl---' + this.imageUrl);
            } else {
                this.imageUrl = `/sfc/servlet.shepherd/document/download/${this.contentDocId}`;
            }
            this.pdfUrl = null;
            this.noImage = false;
        } else {
            this.noImage = true;
            this.isPdf = false;
            this.imageUrl = null;
            this.pdfUrl = null;
        }

        this.checked = this.isAcknowledged;
        if (this.checked) {
            this.disableMaskingCheck = true;
        }
        console.log('Sales mode setup complete');
    }

    getAllRelatedDocs() {
        console.log('appId ' + this.appId);
        console.log('recordId ' + this.recordId);
        console.log('catg ' + this.catg);
        getAllDocument({
            recordId: this.recordId, catg: this.catg, appId: this.appId
        }).then(response => {
            this.documents = response;
            console.log('this.documents.length ' + this.documents.length);
            console.log('documents 49' + this.documents);
            console.log('this.docCheckId ' + this.docCheckId);
            console.log('this.docname ' + this.docname);
            if (this.docCheckId != null || this.docCheckId != '') {
                if (this.documents[0].docChecklistId != this.docCheckId) {
                    for (let i = 0; i < this.documents.length; i++) {
                        console.log('this.documents[i].docName ' + this.documents[i].docName);
                        console.log('this.docname ' + this.docname);
                        if (this.documents[i].docMasterName == this.docname) {
                            console.log('57 ');
                            this.currentIndex = i;
                            console.log('currentIndex ' + this.currentIndex);
                            break;
                        }
                    }
                }
            }

            console.log('62 this.documents -->' + JSON.stringify(this.documents));
            this.status = this.documents[this.currentIndex].Status;
            this.custname = this.documents[this.currentIndex].appName;
            console.log('status ' + this.documents[this.currentIndex].Status);
            console.log('custname ' + this.documents[this.currentIndex].appName);
            this.firstImage();
        }).catch(error => {
            console.error('Error wiredDocuments file -->', JSON.stringify(error));
        });
    }
    get documentName() {
        return this.documents?.length > 0 ? this.documents[this.currentIndex].docName : null;
    }

    get isVerified() {
        return this.documents?.length > 0 ? this.documents[this.currentIndex].isVerified : null;
    }

    get disableNext() {
        return this.currentIndex === (this.documents?.length - 1);
    }

    get previous() {
        return this.currentIndex > 0;
    }

    get doctype() {
        if (this.isSplitViewMode) {
            return this.doctype || this.singleDocumentData?.docType || this.singleDocumentData?.docCategory || '';
        }
        return this.documents?.length > 0 ? this.documents[this.currentIndex].docType : null;
    }

    // Rest of your methods remain the same...
    async handleNext() {
        if (this.currentIndex < this.documents.length - 1) {
            this.currentIndex++;
        }
        this.nextorprev = true;
        await this.firstImage();
    }

    async handlePrevious() {
        if (this.currentIndex > 0) {
            this.currentIndex--;
        }
        this.nextorprev = true;
        await this.firstImage();
    }

    async firstImage() {
        if (this.documents.length > 0) {
            const currentDoc = this.documents[this.currentIndex];
            console.log('currentDoc.docExtention  ' + currentDoc.docExtention);
            if (currentDoc.docExtention === 'pdf') {
                this.isPdf = true;
                this.pdfUrl = this.downloadPdf(currentDoc.docVerionData);
                this.imageUrl = null;
                this.noImage = false;
            } else if (currentDoc.docExtention != null && currentDoc.docExtention != undefined && currentDoc.docExtention != '') {
                this.isPdf = false;
                this.imageUrl = `/sfc/servlet.shepherd/document/download/${currentDoc.docContentId}`;
                this.pdfUrl = null;
                this.noImage = false;
            } else {
                this.noImage = true;
                this.isPdf = false;
                this.imageUrl = null;
                this.pdfUrl = null;
            }
            if (!this.fromSales && !this.loginChecklist) {
                this.openDetailedView();
            }
        }
    }

    downloadPdf(contentId) {
        if (!contentId) {
            console.error('No content available for PDF');
            return null;
        }
        getBase64FromContentId({ contentDocumentId: contentId })
            .then(response => {
                const base64fContent = response;
                console.log('base64fContent : ' + base64fContent);
                if (!base64fContent) {
                    console.error('No base64 content available for PDF');
                    return null;
                }

                try {
                    const byteCharacters = atob(base64fContent);
                    const byteNumbers = new Array(byteCharacters.length);

                    for (let i = 0; i < byteCharacters.length; i++) {
                        byteNumbers[i] = byteCharacters.charCodeAt(i);
                    }

                    const byteArray = new Uint8Array(byteNumbers);
                    const blob = new Blob([byteArray], { type: 'application/pdf' });
                    const url = URL.createObjectURL(blob);

                    this.pdfUrl = url;
                    console.log('PDF URL:', url);

                } catch (error) {
                    console.error('Error loading PDF:', error);
                }
            })
            .catch(error => {
                console.error('Error fetching base64 content:', error);
            });
    }

    sendBack() {
        if (this.remarks == '' || this.remarks == null) {
            this.showToastMessage('Error', 'Please fill the remarks in order to proceed.', 'Error');
            return;
        }
        const currentDoc = this.documents[this.currentIndex];
        sendBackDoc({
            docDetailId: currentDoc.docChecklistId,
            remarks: this.remarks
        }).then(response => {
            console.log('response', JSON.stringify(response));
            if (response == 'success') {
                this.showToastMessage('Success', 'Document is sent back to sales.', 'success');
                this.documents[this.currentIndex].isVerified = false;
                this.hideModalBox();
                this.remarks = null;
            } else {
                this.showToastMessage('Error', 'Something went wrong.', 'Error');
                this.hideModalBox();
                this.remarks = null;
                return;
            }
        }).catch(error => {
            this.showToastMessage('Error', JSON.stringify(error), 'Error');
            console.error('Error wiredDocuments file -->', JSON.stringify(error));
        });
    }

    showModalBox() {
        this.isShowModal = true;
    }

    hideModalBox() {
        this.isShowModal = false;
    }

    showToastMessage(title, message, type) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: type
        });
        this.dispatchEvent(toastEvent);
    }

    validateDoc() {
        const currentDoc = this.documents[this.currentIndex];
        const currentDocName = this.documents[this.currentIndex].docMasterName;
        let recId;
        if (this.catg == 'Income Related') {
            recId = this.documents[this.currentIndex].bankrecordId;
        } else {
            recId = this.appId;
        }
        checkDataFilledOrNotWrapper({ formName: currentDocName, applicantId: recId })
            .then(result => {
                if (result) {
                    validateDoc({
                        docDetailId: currentDoc.docChecklistId,
                    }).then(response => {
                        if (response == 'success') {
                            this.showToastMessage('Success', 'Document is Verified.', 'success');
                            this.documents[this.currentIndex].isVerified = true;
                            this.nextorprev = true;
                            this.getAllRelatedDocs();
                        } else {
                            this.showToastMessage('Error', 'Something went wrong.', 'Error');
                            return;
                        }
                    }).catch(error => {
                        this.showToastMessage('Error', JSON.stringify(error), 'Error');
                        console.error('Error wiredDocuments file -->', JSON.stringify(error));
                    });
                } else {
                    this.showToastMessage('Error', 'Please fill all the mandatory fields to mark it as validated.', 'Error');
                }
            })
    }

    unValidateDoc() {
        const currentDoc = this.documents[this.currentIndex];
        unValidateDoc({
            docDetailId: currentDoc.docChecklistId,
        }).then(response => {
            if (response == 'success') {
                this.documents[this.currentIndex].isVerified = false;
                this.getAllRelatedDocs();
            } else {
                this.showToastMessage('Error', 'Something went wrong.', 'Error');
                return;
            }
        }).catch(error => {
            this.showToastMessage('Error', JSON.stringify(error), 'Error');
            console.error('Error wiredDocuments file -->', JSON.stringify(error));
        });
    }

    handleFormInputChange(event) {
        this.remarks = event.target.value;
    }

    docMenu() {
        this.dispatchEvent(new CustomEvent('docmenu'));
    }

    openDetailedView() {
        try {
            console.log('rec.docName -> ' + this.documents[this.currentIndex].docName);
            console.log('rec.appid -> ' + this.documents[this.currentIndex].appId);
            console.log('rec.acDocName -> ' + this.documents[this.currentIndex].acDocName);
            console.log('rec.valid -> ' + this.documents[this.currentIndex].isVerified);
            this.status = this.documents[this.currentIndex].Status;
            this.dispatchEvent(
                new CustomEvent('hanlenextpreviousorsave', {
                    detail: {
                        docId: this.documents[this.currentIndex].docChecklistId,
                        docName: this.documents[this.currentIndex].docMasterName,
                        appId: this.documents[this.currentIndex].appId,
                        name: this.documents[this.currentIndex].docMasterName,
                        valid: this.documents[this.currentIndex].isVerified,
                        bankid: this.documents[this.currentIndex].bankrecordId,
                    }
                })
            );
        } catch (e) {
            console.log(e.message);
        }
    }

    dispatchUploadCompletedEvent(uploadResult) {
        console.log('Dispatching upload completed event');
        const documentData = {
            contentDocumentId: uploadResult.ContentDocumentId,
            ContentDocumentId: uploadResult.ContentDocumentId,
            fileType: uploadResult.FileType,
            FileType: uploadResult.FileType,
            docName: uploadResult.docName,
            docDetailId: uploadResult.docDetailId,
            docChecklistId: uploadResult.docDetailId,
            contentVersionId: uploadResult.ContentVersionId
        };

        this.dispatchEvent(new CustomEvent('documentuploaded', {
            detail: { documentData, ocrData: {} },
            bubbles: true,
            composed: true
        }));
    }

    handleAckowledgeChangeChange(event) {
        const fields = {};

        if (event.target.checked) {
            fields['Id'] = this.docCheckId;
            fields['Is_manual_masking_confirmed__c'] = true;
            fields['Manual_masking_confirmation_user__c'] = this.userName;
        } else {
            fields['Id'] = this.docCheckId;
            fields['Is_manual_masking_confirmed__c'] = false;
            fields['Manual_masking_confirmation_user__c'] = '';
        }
        const recordInput = { fields };
        console.log('recordInput----' + JSON.stringify(recordInput));

        updateRecord(recordInput)
            .then(() => {
                console.log('before perform action in updateRecords method :');
                this.template.querySelector('.hidden-input-all').value = null;
                this.disableMaskingCheck = true;
                this.dispatchEvent(new CustomEvent('fileuploaded'));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Manual masking confirmation changed successfully.',
                        variant: 'success',
                    }),
                );
            })
            .catch(error => {
                console.log('Error updating document record --> ' + JSON.stringify(error));
            });
    }

    @api
    refreshAfterUpload(documentData, ocrData) {
        console.log('Refreshing document after upload:', documentData);

        this.singleDocumentData = documentData;
        this.contentDocId = documentData.contentId || documentData.ContentVersionId || documentData.ContentDocumentId;
        this.extension = (documentData.fileType || documentData.FileType || '').toLowerCase();

        this.displaySingleDocument();

        if (ocrData && Object.keys(ocrData).length > 0) {
            setTimeout(() => {
                this.dispatchEvent(new CustomEvent('ocrready', {
                    detail: { ocrMap: ocrData, docDetailId: this.docCheckId },
                    bubbles: true,
                    composed: true
                }));
            }, 500);
        }
    }
    @api
    refreshPreview(newVersionId, newExtension) {
        this.contentDocId = newVersionId;
        this.extension = newExtension.toLowerCase();
        this.displaySingleDocument();
    }

}