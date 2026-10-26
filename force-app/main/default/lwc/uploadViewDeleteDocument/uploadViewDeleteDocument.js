import { LightningElement, api, wire , track } from 'lwc';
import deleteDocumentByDocDetailId from '@salesforce/apex/UploadViewDeleteDocumentController.deleteDocumentByDocDetailId';
import getDocumentChecklistRecords from '@salesforce/apex/DocumentDetailsScreenController.getDocumentChecklistRecords';
import uploadFile from '@salesforce/apex/UploadViewDeleteDocumentController.uploadFile'
import getFiStatus from '@salesforce/apex/Credit_FIVerificationController.getFiStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { fireEvent } from 'c/pubsub';
import checkdocRequired from '@salesforce/apex/UploadViewDeleteDocumentController.checkdocRequired';
import reUploadFile from '@salesforce/apex/UploadViewDeleteDocumentController.reUploadFile'
import initiateAPIRequest from '@salesforce/apex/DMSFetchController.initiateAPIRequest'
import getCompressedDocument from '@salesforce/apex/DocGenerationAPICallout.getCompressedDocument';
import getFcuStatusAndUpdateLoan from '@salesforce/apex/FCUController.getFcuStatusAndUpdateLoan';
import checkLoanDisbursed from '@salesforce/apex/UploadViewDeleteDocumentController.checkLoanDisbursed';
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';


export default class UploadViewDeleteDocument extends LightningElement {
    
    @api docDetailId;
    @api contentDocId;
    @api showUpload = false;                //to show upload button
    @api documentProcessingTheme = false;   //compact upload icon for documentProcessingScreen
    @api showView = false;                  //to show view button
    @api showDelete = false;                //to show delete button
    @api hidePreviewOnUpload = false;       //to hide the file preview after upload
    @api stopDeleteOnRetake = false;        //to retain the old document during retake process
    @api showInsidePreview = false;         //to show preview in this component instead of popup
    @api showAddBtn = false;                //to show add new document button
    @api docRequiredFor = '';               //to get the process for which new document will be created
    @api docCategory = '';                  //to get the document category for which new document will be created
    @api docLinkRecodId = '';               //to link the new document record with parent record Id
    @api showAddBigBtn = false;             //to show add new document big button
    @api showWidgetStyle = false;           //to show file preview in widget style
    @api showRetake = false;                //to show retake button
    @api showLocation = false;              //to show google location button
    @api disableActionHover = false;        //static document-table action icons
    @api lattitude;                         //to get the lattitude value
    @api longitude;                         //to get the longitude value
    @api fileType;
    @api docName;
    @api processObject;   
    @api recordId;
    @api queryRecordId;                 
    @wire(CurrentPageReference) pageRef;
    docAddedFromAdd = false;
    @api contentVersionId;
    @api addButtonDisplay;
    @api reuploadIfnotUploaded = false;
    @api esignContent;
    @api name;
    @api docUri;
    pdfUrl;
    imageUrl;
    fileUrl;
    showExcel = false;
    showMSG = false;
    showPreview = false;
    isRetakeCase = false;
    isLoading = false;
    showImage = false;
    showPdf = false;
    showConfirmation = false;
    confirmMessage = 'Are you sure you want to delete this document?';
    showAddDocument = false;
    newDocName = '';
    otherDocName = '';
    isAddDocCase = false;
    mapMarkers = [];
    showGeoLocation = false;
    isMobileDevice = false;

    get actionIconClass() {
        return this.disableActionHover ? 'upload-icon-static' : 'upload-icon-css';
    }
    isLeadObject=false;
    isFIObject =false;
    @api disableUpload = false;
    //showSaveButton = true;
    @track addDocCase = false;
    @api currentUserOppRole = [];
    @api oppStage = '';
    @api oppSubStage = '';
   @track checkDisbursed = true;
   @api fromCredit = false;
    @track thresholdFileSize = 1;
    @api calledFrom;
    isDisableEdit;
    connectedCallback(){
      
            const pathArray = window.location.pathname.split('/');
            console.log('Path Array:', pathArray);
            if (pathArray.length > 4) {
                this.recordId = pathArray[4]; // Adjust if needed
                console.log('Extracted Record Id:', this.recordId);
                this.checkCmpEditability();
            }
        
        if(this.processObject=='Lead'){
            this.isLeadObject=true;
        }
        if(this.processObject =='Application Verification'){
            console.log('result-102-ggggsss--');
            this.isFIObject =true;
            this.getFiStatus();
        }
        
        this.setFileUrl();

        if(this.showWidgetStyle){
            this.viewFile();
        }
        if(this.addButtonDisplay =='button') {

            this.showAddDocAsButton = true;

        } else {

            this.showAddDocAsButton = false;

        }

        console.log('currentUserOppRole: '+this.currentUserOppRole);
        console.log('oppStage: '+this.oppStage);
        console.log('oppSubStage: '+this.oppSubStage);

        var disableControls = false;
        if(this.currentUserOppRole.includes('OPS Maker') || this.currentUserOppRole.includes('OPS Author')){
            disableControls = true;
        }
        
        if(disableControls){
            console.log('disable controls--');
            this.showRetake = false;
            this.showUpload = false;
            this.showDelete = false;
        }
        this.getUserLocationCordinates(); 
         this.checkLoanDisbursed();
    }

    checkLoanDisbursed(){
        checkLoanDisbursed({loanId : this.recordId})
            .then(data => {
            this.checkDisbursed = data;
            // console.log('data', data);
        })
    }
    checkCmpEditability() {
        getComponentEditability({ loanId: this.recordId, component: 'uploadViewDeleteDocument' })
            .then(result => {
                this.isDisableEdit = result;
            })
            .catch(error => {
                console.error('Error getComponentEditability : ', error);
                this.isDisableEdit = true;
            });
    }
    get disabledEdit()
    {
        return this.isDisableEdit;
    }
    checkCmpEditability() {
        getComponentEditability({ loanId: this.recordId, component: 'uploadViewDeleteDocument' })
            .then(result => {
                this.isDisableEdit = result;
            })
            .catch(error => {
                console.error('Error getComponentEditability : ', error);
                this.isDisableEdit = true;
            });
    }
    get disabledEdit()
    {
        return this.isDisableEdit;
    }
    
    getFiStatus(){
        console.log('result-102-gggg- 76-',this.recordId);
        getFiStatus({recordId:this.recordId})
        .then(result => {
            console.log('result-102-gggg- 77-'+result);
            if(result!=null && result==true){
               
                        this.disableUpload=true;
                
                
            }
        })
        .catch(error => {
        })
    }
    getFcuStatusAndUpdateLoan()
    {
        console.log('inside fcu check',this.recordId);
        getFcuStatusAndUpdateLoan({loanId:this.recordId})
        .then(result => {
            console.log('check the fcu result -->'+result)
        })
    }
    renderedCallback(){

        if(FORM_FACTOR === "Large") { }
        else { 
            this.isMobileDevice = true;

            if(this.showPdf){
                this.showView = false;
                this.pdfUrl = null;
                this.showPdf = false;
            }
        }

        this.template.querySelector('.hidden-input').addEventListener('cancel', (evt) => {
            if(this.isRetakeCase){
                this.showPreview = true;
                this.isRetakeCase = false;
            }
            else if(this.newDocName){
                this.showAddBtn = true;
                this.showUpload = false;
            }
        });

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
            }
    
    
            `;
    
            // Append the styles to the .styleContainer
            this.template.querySelector('.styleContainer')?.appendChild(style);
    
            // Prevent re-adding styles
            this.isRendered = true;
        }
    }


    setFileUrl() {
        console.log('window.location.origin--'+window.location.origin);
        if(window.location.origin.includes('my.site.com')){
            this.fileUrl = window.location.origin +'/losportal/sfc/servlet.shepherd/document/download/'+ this.contentDocId;
        }
        else{
            console.log('contentVersionId--',this.contentVersionId)
            console.log('contentVersionId--',this.contentDocId)
            this.fileUrl = window.location.origin +'/sfc/servlet.shepherd/document/download/'+ this.contentDocId;
        }

        console.log('this.fileUrl: '+ this.fileUrl);
    }

    handleAddDoc(){
        console.log('this.fileUrl: 138 ');
        this.docDetailId = '';
        this.contentDocId = '';
        this.newDocName = '';
        this.otherDocName = '';
        this.showAddDocument = true;
        this.docAddedFromAdd = true;
        this.isAddDocCase = true;
        console.log('this.fileUrl: 138 ',this.docAddedFromAdd );

    }

    saveAddDoc(event){
        this.showAddDocument = false;
        this.newDocName = event.detail.fileName;
        this.otherDocName = event.detail.otherFileName;
        // this.isAddDocCase = true;
        console.log('this.fileUrl: 154 ',this.docAddedFromAdd );
        // this.isAddDocCase = false;
        this.addDocCase = true;
        // this.openCamera(event);
    }

    handleView(event){
        //event.stopPropagation();
        console.log('docURI: '+this.docUri);
        if(this.docUri != null && this.docUri != '' && this.docUri != undefined){
            console.log('inside docURI --> ');
            console.log('this.recordId: doc view --> '+this.recordId);
            let inputMap = {
                loanId: this.recordId,
                processName: 'Doc Fetch',
                docId: this.docUri
            };
            initiateAPIRequest({ inputMap }) 
            .then(response => {
                console.log('API Response doc view:', response);
                let base64Content = this.extractBase64(response);
                if (base64Content) {
                    let pdfUrl = this.downloadPdf(base64Content);
                    if(pdfUrl){
                        console.log('pdfUrl : '+pdfUrl);
                        this.fileType = 'PDF';
                        this.fileUrl = pdfUrl;
                        //this.showSaveButton = false;
                        setTimeout(() => {
                            this.viewFile();
                            this.showPreview = true;
                            this.showRetake = false;
                        }, 400);
                    }
                } else {
                    console.error('No Base64 content found in response.');
                }
            })
            .catch(error => {
                console.error('Error in API call doc view:', error);
            });
        } else {
            this.viewFile();
            this.showPreview = true;
            // this.showRetake = true;

            var disableControls = false;
            if(this.currentUserOppRole.includes('OPS Maker') || this.currentUserOppRole.includes('OPS Author')){
                disableControls = true;
            }
            
            if(disableControls){
                console.log('disable controls 255--');
                this.showRetake = false;
            }
            
            //this.showSaveButton = true;
        }
        
        // this.showPreview = true;
        // this.showRetake = false;
    }

    extractBase64(xmlString) {
        let match = xmlString.match(/<docContent>(.*?)<\/docContent>/);
        return match ? match[1] : null;
    }

    downloadPdf(base64fContent) {
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
            return url;
        } catch (error) {
            console.error('Error loading PDF:', error);
            return null;
        }
    }

    viewFile(event){
        //event.stopPropagation();
        console.log('this.fileType: '+this.fileType);
        console.log('this.fileUrl: '+this.fileUrl);
        this.showPdf = false;
        this.pdfUrl = null;
        this.showImage = false;
        this.showExcel = false;
        this.showMSG =  false;
        this.imageUrl = null;

        switch(this.fileType) {
            case 'PNG':
            case 'JPG':
            case 'JPEG':
            case 'SVG':
            case 'BMP':
            case 'WEBP':
            case 'GIF':
                this.imageUrl = this.fileUrl;
                this.showImage = true;
                break;
            case 'EXCEL_X':
                this.showExcel = true;
                console.log('showExcel>>'+this.showExcel);
                break;

            case 'PDF':
                console.log('casePDF...');
                if(this.isMobileDevice){ 
                    this.showView = false;
                }
                else{
                    console.log('inside not mobile');
                    this.pdfUrl = this.fileUrl;
                    this.showPdf = true;
                }
                break;
            case 'MSG':
                console.log('caseMSG...');
                this.showMSG = true;
                console.log('caseMSG this.showMSG >> '+this.showMSG);
                break;
        }

        if (this.docName && this.docName.includes('CIBIL')) {
            console.log('inside cibil condition');
            this.pdfUrl = this.pdfUrl + '#toolbar=0';
            console.log('this.fileUrl: ',this.pdfUrl);
        }
    }

    handleLocation(event){
        
        const lat = event.target.dataset.lattitude;
        const lng = event.target.dataset.longitude;
        
        this.showGeoLocation = true;
        this.mapMarkers = [
            {
                location: {
                    Latitude: lat,
                    Longitude: lng,
                },
                title: 'Google map',
                description: 'Coordinate'
            }
        ];
    }

    deleteDocument(){
        console.log('docDetailId: '+this.docAddedFromAdd);

        if(this.docDetailId){
            this.isLoading = true;


            deleteDocumentByDocDetailId({docDetailId: this.docDetailId})
            .then(result => {
                //console.log('result: '+result);
                
                if(result){
                    if(!this.isRetakeCase){
                        let title = `${this.docName} document is deleted successfully.`;
                        this.showToastMethod('Success', title, 'success');
        
                        this.showUpload = true;
                        this.showView = false;
                        this.showDelete = false;
                        this.showLocation = false;

                        this.showImage = false;
                        this.showPdf = false;
                        
                        this.handleClose();
                        this.isLoading = false;
                        fireEvent(this.pageRef, "handleRefreshDocument", "Breed-Labrador");
                        const valueSelectedEvent = new CustomEvent('deletedoc',{ docId: this.docDetailId});
                        this.dispatchEvent(valueSelectedEvent);
                    }
                }
                else {
                    this.isLoading = false;
                    this.showToastMethod('Error', 'Unable to delete file.', 'error');
                }

                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                //this.showToastMethod('Error', 'Unable to delete file.', 'error');

                console.error('Error in deleting file: ', JSON.stringify(error));
            });
        }
    }
    
    handleDelete(event) {
        console.log('event.target.dataset.id---',event.target.dataset.name);
        this.docDetailId = event.target.dataset.id;
        this.confirmMessage = 'Are you sure you want to delete this '+ event.target.dataset.name +' document?';
        if(this.isMobileDevice){
            const scrollOptions = {
                left: 0,
                top: 0,
                behavior: 'smooth'
            }
            window.scrollTo(scrollOptions);
        }

        setTimeout(() => {
           
            this.showConfirmation = true;
            
        }, 1000);
     
    }

    reUploadFile(event){
        this.showPreview = false;
        this.isRetakeCase = true;
        if(this.isMobileDevice){
            const scrollOptions = {
                left: 0,
                top: 0,
                behavior: 'smooth'
            }
            window.scrollTo(scrollOptions);
        }
        this.openCamera(event);
    }

    openCamera(event){
        if(this.isRetakeCase){

            this.template.querySelector('.hidden-input-all').click();

            this.getUserLocationCordinates();

        }

        else{
            this.template.querySelector('.hidden-input').click();
            this.getUserLocationCordinates();
            
        }
    }

    getUserLocationCordinates() {
       console.log('287---------upload')
        if(navigator.geolocation) {
            navigator.geolocation.getCurrentPosition((position) => {
                this.lattitude = position.coords.latitude;;
                this.longitude = position.coords.longitude;
            },
            (e) => {},
            { enableHighAccuracy: true }
            );
        }
    }

    handleUpload(event) {
        this.getUserLocationCordinates();
        this.isLoading = true;
        // console.log('file data: '+ JSON.stringify(event));
       

        if(this.isRetakeCase){
            this.showImage = false;
            this.showPdf = false;
            this.imageUrl = null;
            this.pdfUrl = null;
        }

        // const file = event.target.files[0];
        const file = event.detail.files[0];
        console.log('file 523 : '+JSON.stringify(file));
        this.contentDocId = file.documentId;

        if(this.isRetakeCase){
            this.showImage = false;
            this.showPdf = false;
            this.imageUrl = null;
            this.pdfUrl = null;
        }

        console.log('file 523 : '+JSON.stringify(file));
        this.contentDocId = file.documentId;
        console.log('inside oqqqnload',this.isFIObject );
        if(this.isFIObject == true  ){
            console.log('inside oqqqnload');
            const validTypes = ['image/jpeg', 'image/png', 'image/gif'];
            
                if (!validTypes.includes(file.mimeType)) {
                    console.log('inside onlssssoad');
                    this.showToastMethod('Error', 'Invalid file type! Please upload an image.', 'error');
                    this.isLoading = false;
                   
                    return;
                }
               
        }
        else if(this.name == 'Sales add document'){
            const validTypes = ['image/jpeg', 'image/png', 'image/gif'];
            if (!validTypes.includes(file.mimeType)) {
                this.showToastMethod('Error', 'Please upload file in correct format.', 'error');
                    this.isLoading = false;
                   
                    return;
            }
        }
        console.log('docDetailId: '+this.docDetailId);
        console.log('file: '+this.newDocName)
        // var reader = new FileReader();
        // reader.onload = () => {
            console.log('inside onload');
            const uploadParam = {
                // 'base64': reader.result.split(',')[1],
                'filename': file.name,
                'docDetailId': this.docDetailId,
                'docName': this.newDocName,
                'otherDocName':this.otherDocName,
                'docRequiredFor': this.docRequiredFor,
                'docCategory': this.docCategory,
                'docLinkRecodId': this.docLinkRecodId,
                'stopDeleteOnRetake': this.stopDeleteOnRetake,
                'contentDocId': this.contentDocId,
                'latitude': this.lattitude,
                'longitude': this.longitude,
                'queryRecordId' : this.queryRecordId
            };
                       

            
            
            const fileSizeInMB = (file.size / (1024 * 1024)).toFixed(2);
            const fileType = file.type;
            const fileTypemimeType = file.mimeType;
            console.log('fileType at 551----', fileType);
            console.log('file.size ----', file.size );
            console.log('fileType at 552----', fileTypemimeType);
            

            console.log('fileSizeInMB: '+typeof(fileSizeInMB));

            if ((fileTypemimeType === 'application/pdf' || fileTypemimeType === 'pdf' || fileTypemimeType === 'PDF') && this.name == 'E-sign') {
                // const base64String = reader.result.split(',')[1];
                // parameters for the compress API Apex method
                const compressApiParams = {
                    fileName: file.name,
                    loanId: this.recordId,
                    contentDocId: this.contentDocId,
                    docDetailId: this.docDetailId
                };
                console.log('compressApiParams  '+JSON.stringify(compressApiParams));
                    console.log('calling getCompressedDocument');
                    getCompressedDocument(compressApiParams)
                    .then(result => {
                        // console.log('getCompressedDocument result   '+JSON.stringify(result));
                        console.log('getCompressedDocument result   '+JSON.stringify(result.status));
                        if (result!=null) {
                            uploadParam.contentDocId = result;
                            console.log('uploadParam base64   ',uploadParam);
                            setTimeout(()=>{
                                this.handleUploadFile(uploadParam);
                                },500);
                        } else {
                            this.showToastMethod('Error', 'Error in uploading file', 'error');
                        }
                    })
                    .catch(error => {
                        this.showToastMethod('Error', 'Error in uploading file' , 'error');
                        console.log('getCompressedDocument error   '+JSON.stringify(error));
                        console.log('getCompressedDocument error   '+error);
                    })
                    
                
            } else {
                console.log('not a pdf');
                setTimeout(()=>{
                    this.handleUploadFile(uploadParam);
                },500);
            }
         
            // setTimeout(()=>{
                
            // },500);
        // }

        // reader.readAsDataURL(file);

        // Reset the input value
        // this.template.querySelector('.hidden-input').value = null;
    }

    handleUploadFile(uploadParam){
        console.log('344',uploadParam);
                uploadFile({ uploadParam: uploadParam })
                .then(result => {
                   
                      console.log('347');
                      this.addDocCase = false;
                    setTimeout(()=>{
                        if(result) {
                            console.log('350',result);
                            this.contentDocId = result.ContentDocumentId;
                            this.contentVersionId = result.ContentVersionId;
                            this.fileType = result.FileType;
                            console.log('354---',this.isAddDocCase);
                            // this.handleCompressApiCall(compressApiParams);
                            if(this.isAddDocCase){
                                this.docName = result.docName;
                                this.docDetailId = result.docDetailId;
                                this.showLocation = true;
                                this.showUpload = false;
                                // this.showDelete = true;
                                console.log('350---',this.pageRef);
                                //fire the event to refresh the document details screen comp
                                // setTimeout(()=>{
                                //     fireEvent(this.pageRef, "handleRefreshDocumentAddDoc", "Breed-Labrador");
                                // },1000)
                                fireEvent(this.pageRef, "handleRefreshDocument", "Breed-Labrador");

                                this.showLocation = true;

                                // this.showDelete = true;
                                if(!this.showInsidePreview){
                                    this.showView = true;
                                }
                            }
                            else{
                                this.docName = result.docName;
                                this.docDetailId = result.docDetailId;
                                this.showLocation = true;
                                this.showUpload = false;
                                // this.showDelete = true;
                                //setTimeout(()=>{
                                    fireEvent(this.pageRef, "handleRefreshDocument", "Breed-Labrador");
                                // },1000)
                                // if(!this.showInsidePreview){
                                //     this.showView = true;
                                // }
                            }
    
                            this.setFileUrl();
                            console.log('372');
                            this.showPreview = true;
                            //show preview after upload file
                            if(!this.hidePreviewOnUpload){
                                this.viewFile();
                                 console.log('376');
                                this.showPreview = true;
                                //this.showInsidePreview = false;
                            }
                            else{
                                let title = `${this.docName} document uploaded successfully!!`;
                                this.showToastMethod('Success', title, 'success');
                            }
                            if(this.isMobileDevice){
                                const scrollOptions = {
                                    left: 0,
                                    top: 0,
                                    behavior: 'smooth'
                                }
                                window.scrollTo(scrollOptions);
                            }
                            this.isLoading = false;
                        }
                        else {
                            if(this.isAddDocCase){
                                this.showAddBtn = true;
                            }
                            else {
                                this.showUpload = true;
                                this.showView = false;
                                this.showDelete = false;
                                this.showLocation = false;
                            }
    
                            this.showToastMethod('Error', 'Unable to upload file.', 'error');
                            this.isLoading = false;
                        }
                        this.isAddDocCase = false;
                        this.isLoading = false;
                        this.getUserLocationCordinates();
                        if (this.calledFrom != 'Vendor Invoice') {
                            this.getFcuStatusAndUpdateLoan();
                        }
                    },1000);
                })
                .catch(error => {
                    console.log('412');
                    this.isLoading = false;

                    if(this.isAddDocCase){
                        this.showAddBtn = true;
                    }
                    else {
                        this.showUpload = true;
                        this.showView = false;
                        this.showDelete = false;
                        this.showLocation = false;
                    }

                    this.showToastMethod('Error', 'Unable to upload file', 'error');

                   
                });
    }
    

    handleClose(){
        this.showPreview = false;
        this.isRetakeCase = false;
        this.isLoading = false;
        this.showAddDocument = false;
        this.isAddDocCase = false;
        this.showGeoLocation = false;
        this.mapMarkers;
        this.isAddDocCase = false;
       
            const valueSelectedEvent = new CustomEvent('recallmethod', {  });
            this.dispatchEvent(valueSelectedEvent);
        
        this.confirmMessage = 'Are you sure you want to delete this document?';
        this.template.querySelector('.hidden-input').value = null;
        
    }

    handleNo(event){
        this.showConfirmation = false;
    }

    handleYes(event){
        this.showConfirmation = false;
        this.deleteDocument();
    }

    showToastMethod(toastTitle, toastMessage, toastVariant){
        const evt = new ShowToastEvent({
            title: toastTitle,
            message: toastMessage,
            variant: toastVariant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    getCurrentDateTime() {

        const now = new Date();

        return now.getDate().toString().padStart(2, '0') + '-' +

               (now.getMonth() + 1).toString().padStart(2, '0') + '-' +

               now.getFullYear() + ' ' +

               now.getHours().toString().padStart(2, '0') + ':' +

               now.getMinutes().toString().padStart(2, '0') + ':' +

               now.getSeconds().toString().padStart(2, '0');

    }
    handleReUpload(event){
        this.isLoading = true;
        this.showPreview = false;
        this.isRetakeCase = true;
        this.getUserLocationCordinates();
        if(this.isRetakeCase){
            this.showImage = false;
            this.showPdf = false;
            this.imageUrl = null;
            this.pdfUrl = null;
        }
        // const file = event.target.files[0];
        const file = event.detail.files[0];
        this.contentDocId = file.documentId;
        // var reader = new FileReader();
        // reader.onload = () => {
            console.log('inside onload');
            const uploadParam = {
                // 'base64': reader.result.split(',')[1],
                'filename': file.name,
                'docDetailId': this.reuploadIfnotUploaded ? this.esignContent : this.docDetailId,
                'docName': this.newDocName,
                'otherDocName':this.otherDocName,
                'docRequiredFor': this.docRequiredFor,
                'docCategory': this.docCategory,
                'docLinkRecodId' : this.docLinkRecodId,
                'stopDeleteOnRetake': this.stopDeleteOnRetake,
                'contentDocId': this.contentDocId,
                'latitude': this.lattitude,
                'longitude': this.longitude,
                'deleteDoc' : 'true'
            };
                reUploadFile({ uploadParam: uploadParam })
                .then(result => {
                    // alert('file upload: '+ JSON.stringify(result));
                    setTimeout(()=>{
                        if(result) {
                            this.contentDocId = result.ContentDocumentId;
                            this.fileType = result.FileType;
                            if(this.isAddDocCase){
                                this.docName = result.docName;
                                this.docDetailId = result.docDetailId;
                                //fire the event to refresh the document details screen comp
                                console.log('docName '+this.docName+'494 '+this.docDetailId);
                                fireEvent(this.pageRef, "handleRefreshDocument", "Breed-Labrador");
                            }
                            else{
                                this.showLocation = false;
                                this.showUpload = false;
                                if(!this.showInsidePreview){
                                    this.showView = true;
                                }
                            }
                            this.setFileUrl();
                            if(this.reuploadIfnotUploaded){
                                this.dispatchEvent(new CustomEvent('reload'));
                            }
                            //show preview after upload file
                            if(!this.hidePreviewOnUpload){
                                this.viewFile();
                                this.showPreview = true;
                            }
                            else{
                                let title = `${this.docName} document uploaded successfully!!`;
                                this.showToastMethod('Success', title, 'success');
                            }
                            if(this.isMobileDevice){
                                const scrollOptions = {
                                    left: 0,
                                    top: 0,
                                    behavior: 'smooth'
                                }
                                window.scrollTo(scrollOptions);
                            }
                        }
                        else {
                            if(this.isAddDocCase){
                                this.showAddBtn = true;
                            }
                            else {
                                this.showUpload = true;
                                this.showView = false;
                            }
                            this.showToastMethod('Error', 'Unable to upload file.', 'error');
                        }
                        this.isLoading = false;
                    },1000);
                })
                .catch(error => {
                    this.isLoading = false;

                    if(this.isAddDocCase){
                        this.showAddBtn = true;
                    }
                    else {
                        this.showUpload = true;
                        this.showView = false;
                    }
                    this.showToastMethod('Error', 'Unable to upload file!!', 'error');
                });
        // }
        // reader.readAsDataURL(file);
        // this.template.querySelector('.hidden-input').value = null;
    }
    closeModal() {
        this.addDocCase = false;
    }

}