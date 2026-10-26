import { LightningElement,api,wire,track } from 'lwc';
import getQueryDetails from '@salesforce/apex/QueryModuleDetailsController.getQueryDetails'
import uploadFile from '@salesforce/apex/QueryModuleDetailsController.uploadFile'
import uploadFileNonDocument from  '@salesforce/apex/QueryModuleDetailsController.uploadFileNonDocument';
import uploadFileNonDocumentNew from  '@salesforce/apex/QueryModuleDetailsController.uploadFileNonDocumentNew';

import { NavigationMixin } from "lightning/navigation";
import setRecordButtons from '@salesforce/apex/QueryModuleController.setRecordButtons';
import setDocRecordButtons from '@salesforce/apex/QueryModuleController.setDocRecordButtons';
import sendResponse from '@salesforce/apex/QueryModuleController.sendResponse';
import deleteNonDocumentChecklist from '@salesforce/apex/QueryModuleController.deleteNonDocumentChecklist';
import sendDocResponse from '@salesforce/apex/QueryModuleController.sendDocResponse';
import sendRecordBack from '@salesforce/apex/QueryModuleController.sendRecordBack';
import acceptRecord from '@salesforce/apex/QueryModuleController.acceptRecord';
import closedRevertRecord from '@salesforce/apex/QueryModuleController.closedRevertRecord';
import getRequestedFromUsers from '@salesforce/apex/QueryModuleController.getRequestedFromUsers';
import reassignRecord from '@salesforce/apex/QueryModuleController.reassignRecord';
import getLoanId  from '@salesforce/apex/QueryModuleController.getLoanId';
import checkRecordEditability from '@salesforce/apex/QueryModuleDetailsController.checkRecordEditability';
import getRequirementLevels from '@salesforce/apex/QueryModuleDetailsController.getRequirementLevels';
import getCustomers from '@salesforce/apex/QueryModuleDetailsController.getCustomers';
import checktypeofDoc from '@salesforce/apex/QueryModuleController.checktypeofDoc';
import updateDocumentChecklist from '@salesforce/apex/QueryModuleDetailsController.updateDocumentChecklist';
// This Code was generated using GenAI tool : Codify, Please check for accuracy
import getAssignedQueriesForLoan from '@salesforce/apex/QueryModuleListController.getAssignedQueriesForLoan';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import FORM_FACTOR from '@salesforce/client/formFactor';
import USER_ID from '@salesforce/user/Id';
//import communityBasePath from '@salesforce/community/basePath';
export default class QueryModuleAssignedQueriesCmp extends NavigationMixin (LightningElement) {
    userId = USER_ID;
    headerTitle= 'Assigned Query';
    @api recordId;
    queryType;
    queryCategory;
    requestor;
    requestedFromUser;
    docList=[]
    showDocTable =false;
    isRendered=false;
    status;
    remarks;
    selecteddocCheckId
    buttonValue
    buttonTrackers = []
    showCategory =false;
    openReassignmentModal = false;
    recordEditable = false;
    uploadEditable = false;
    showUploadDoc = false;
    //isRendered=false;
    showDocDetailsTable =false;
    contentDocIds;
     addedDocList = []; 
     requirementOptions = [];
    customerOptions = [];
    selectedQueue
    disableCustomerName = false;
    @track nonDocList=[];
    isLoading = false;
    inputValuesMap = {};
    allQueryIds;
    showremarks = false;
    childId;
    requestorId;//Added by kalpesh
    @track isActionAllowed = true;
    // This Code was generated using GenAI tool : Codify, Please check for accuracy
    @track queryList = [];
    showQueryList = false;
    showBackButton = false;
    loanApplicationRecordId;
    get noQueriesFound() {
        return !this.queryList || this.queryList.length === 0;
    }
    // GenAI: Generated code ends here
    openReassignModal()             {this.openReassignmentModal = true
        this.getLoanId();
    }
    headerTitle = 'Assigned Query';
    requestedFromUsers =[];
    assingedUsers=[];
    newDoc = { 
        label: '', 
        requirementLevel: '', 
        customerId: '' ,
        value: '' 
    };
    showPreview=false;
    filePreviewUrl;
    contentDocLink;

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        console.log('pageReference state', pageRef);
        if (pageRef.state.recordId || pageRef.attributes.recordId) {
            console.log('pageReference state', pageRef.attributes.recordId);
            // Check the state for the recordId parameter.
            this.recordId = pageRef.state.recordId || this.recordId || pageRef.attributes.recordId;
            console.log('RecordId', this.recordId);
            // For debugging:
            console.log('Record Id from URL:', this.recordId);
        }
    }
     get acceptedFormats() {
        return ['.pdf', '.png', '.jpg'];
    }



    connectedCallback(){
        console.log('recordId Query', this.recordId);
        // This Code was generated using GenAI tool : Codify, Please check for accuracy
        this.loanApplicationRecordId = this.recordId;
        this.loadQueryList();
        // GenAI: Generated code ends here
    }
    // This Code was generated using GenAI tool : Codify, Please check for accuracy
    loadQueryList(){
        this.isLoading = true;
        getAssignedQueriesForLoan({ loanApplicationId: this.loanApplicationRecordId })
        .then(result => {
            this.queryList = result;
            this.showQueryList = true;
            this.showBackButton = false;
            this.isLoading = false;
        })
        .catch(error => {
            console.error('Error fetching assigned queries for loan:', error);
            this.queryList = [];
            this.showQueryList = true;
            this.isLoading = false;
        });
    }
    handleSelectQuery(event){
        const selectedQueryId = event.target.dataset.id;
        this.recordId = selectedQueryId;
        this.showQueryList = false;
        this.showBackButton = true;
        this.loadQueryDetail();
    }
    handleBackToList(){
        this.recordId = this.loanApplicationRecordId;
        this.showBackButton = false;
        this.loadQueryList();
    }
    loadQueryDetail(){
        this.getQueryDetails();
        this.init();
        this.checkRecordEditability();
        this.getLoanId();
    }
    // GenAI: Generated code ends here
    getLoanId(){
        getLoanId({
            recordValue:this.recordId
        })
        .then(result => {
            this.loanId = result;
            this.fetchRequestedFromUsers();
            this.fetchRequirementLevels();
            this.fetchCustomers();
        })
        .catch(error => {
        })

    }
    fetchRequestedFromUsers() {
        getRequestedFromUsers({
            recordValue:this.loanId
        })
        .then(result => {
            this.requestedFromUsers = result.map(item => ({
                label: item.userName,
                value: item.userId
            }));
           
            console.log('requestedFromUsers----'+JSON.stringify(this.requestedFromUsers));
            
        })
        .catch(error => {
            console.error('Error fetching query types:', error);
        });
    }
    getQueryDetails(){
        getQueryDetails({recordId:this.recordId})
        .then(response=>{
            console.log('107 '+JSON.stringify(response));
            this.queryType=response.queryType;
            this.isActionAllowed = response.isActionAllowed;
            if(this.userId == response.requestorId) {
                this.isActionAllowed = true;
            }
            if(this.queryType == 'Non Document'){
                this.showUploadDoc  =true;
            }
            else{
                this.showUploadDoc  =false;
            }
            if(response.queryCategory!='' && response.queryCategory!=null  && response.queryCategory!=undefined){
            this.queryCategory=response.queryCategory;
            this.showCategory =true;
            }
            else{
                this.showCategory =false;
            }
            this.requestor=response.requestorName;
            this.requestorId=response.requestorId;//Added by kalpesh
            this.requestedFromUser=response.requestByUsersName;
            console.log('this.docList '+this.docList);
            console.log('querytype',this.queryType);
            if(this.queryType == 'Document'){ //COndition was if(!this.queryType == 'Document') Armani :  which wasnt working so changed it directky tio docuemnt
            console.log('130');
            this.docList=response.docWrapp;
            }
            let queryIds = this.docList ? this.docList.map(doc => doc.queryId) : [];
            this.allQueryIds = queryIds
            console.log('this.allQueryIds  '+this.allQueryIds);
            this.docList.forEach(doc => {
                console.log('Buttons for Document:', doc.documentName, JSON.stringify(doc.buttonWrapp));
            });
            // Call setResponse to handle button mapping
            this.setnewResponse(response);
            this.status=response.status;
            this.selectedQueue =response.selectedQueueName;
            this.remarks = response.remark;
            console.log('this.docList.length '+this.docList.length);
            if(this.docList.length>0){
                if(this.queryType == 'Document'){
                this.showDocTable =true;
            }
            else{
                console.log('153');
                this.shownonDocDetailsTable = true;
                this.nonDocList = this.docList;
            }
            }
            console.log('response',response)

        }).catch(error=>{
        })
    }
    setnewResponse(response) {
        this.docList = response.docWrapp.map(doc => {
            let buttons = doc.buttonWrapp.map(button => {
                let buttonClass = 'button-green';
    
                if (button.name === 'Send Response') {
                    buttonClass = 'button-green';
                } else if (button.name === 'Re-assign Query' || button.name === 'Close' || button.name === 'Reassign') {
                    buttonClass = 'button-red';
                }
    
                return {
                    ...button,
                    buttonClass
                };
            });
    
            return {
                ...doc,
                buttonWrapp: buttons, // Attach buttons to each document
                // This Code was generated using GenAI tool : Codify, Please check for accuracy
                // Per-row Remarks value. Previously bound to a non-existent
                // `docremarks` property (always undefined); seed from any
                // value already captured for this document, otherwise blank.
                remarks: this.inputValuesMap[doc.queryId] || ''
                // GenAI: Generated code ends here
            };
        });
    
        console.log('Updated Documents:', JSON.stringify(this.docList));
    }
    
    renderedCallback(){
        console.log('IN CHILD RENDER CALL BACK');
        if(!this.isRendered){
            console.log('Inside if condition');
            this.isRendered = true;
            const style = document.createElement('style');
            style.innerText = `
            .uploadFile .slds-file-selector__text.slds-medium-show {
              display: none;
            }
            .uploadFile .slds-file-selector__button.slds-button.slds-button_neutral{
                font-size: 0!important;
            }
            .uploadFile svg.slds-button__icon.slds-button__icon_left {
                margin: 0;
            }
            .uploadFile lightning-primitive-file-droppable-zone.slds-file-selector__dropzone {
                border: none;
                padding: 0;
            }
            .uploadFile slds-form-element__label{
                display: none;
            }
            .info-button svg.slds-button__icon.slds-button__icon_left {
                margin: 0;
            }
            .class-file-upload .slds-form-element__label:empty {
                margin: 0;
                display: none;
            }
            .uploaded-view svg.slds-button__icon.slds-button__icon_left {
                color: green;
            }
            .uploaded-view svg.slds-button__icon.slds-button__icon_left {
                margin-top: 2%;
            }
            .uploaded-view svg.slds-button__icon {
                color: green;
            }
                .uploaded-view-disabled svg.slds-button__icon.slds-button__icon_left {
                color: grey;
            }
            .uploaded-view-disabled svg.slds-button__icon {
                color: grey;
            }
            .file-preview-buttons.slds-align--absolute-center {
                display: none;
            }
            `;
            this.template.querySelector('.styleContainer').appendChild(style);
        }
    }
      handlePreview(event){
        const contentDocumentId = event.target.dataset.id;
        console.log('File Preview::' , event.target.dataset.id);
        if(event.target.dataset.id == '' || event.target.dataset.id == null || event.target.dataset.id == undefined){
            this.showToastMethod('Error', 'No file uploaded', 'Error');
            return;
        }
         const isCommunity = window.location.href.includes('/s/');

    if (isCommunity) {
          this.showPreview = true;
        // For Experience Cloud users
       // const baseUrl = window.location.origin + '/losportal/sfc/servlet.shepherd/document/download/' + contentDocumentId;
        console.log('Community Preview URL:', this.showPreview);
        console.log('event.target.dataset.id URL:',event.target.dataset);
      //  window.open(baseUrl); // Open in a new tab
      console.log('Community event.target.data URL:', event.target.dataset.id);
       // this.showTable = false;
        this.contentDocLink =event.target.dataset.id;
       const urlToPreview= '/losportal/sfc/servlet.shepherd/document/download/' + contentDocumentId;
        this.filePreviewUrl = urlToPreview + '#toolbar=0';
          console.log('Community this.contentDocLink URL:',  this.contentDocLink);
           console.log('Community this.contentDocLink URL:',  this.filePreviewUrl);
    
    }
         else{
                
                this[NavigationMixin.Navigate]({
                    type:'standard__namedPage',
                    attributes:{
                        pageName:'filePreview'
                    },
                    state:{
                        selectedRecordId: event.target.dataset.id
                    }
                })
            }
        }
        handleClosePreview(event){
              this.showPreview = false;
        }

        

// handleDownloadButton(event) {
//     console.log('handleDownloadButton>>>');
//      var fileUrl = event.currentTarget.dataset.url;
//      console.log('event.target.dataset.id>>>'+event.target.dataset.id);
     
//      fileUrl = '/sfc/servlet.shepherd/document/filePreview/'+ event.target.dataset.id;
//      console.log('fileUrl>>>'+fileUrl);

//         if (fileUrl) {
//             const link = document.createElement('a');
//             link.href = fileUrl;
//             link.download = 'downloadedFile.pdf'; 
//             link.click();
//         }
    
    
// }


handleDownloadButton(event) {
    const contentDocumentId = event.currentTarget.dataset.id;
     console.log('contentDocumentId',contentDocumentId);
        if (contentDocumentId) {
            // Construct the download URL using the ContentDocumentId
            const downloadUrl = `/sfc/servlet.shepherd/document/download/${contentDocumentId}`;
            console.log('downloadUrl',downloadUrl);
            // Open the URL in a new window/tab to trigger the download
            window.open(downloadUrl, '_blank');
        }

  
}




  

        handleDownload(event) {
        const fileUrl = event.currentTarget.dataset.url;
        if (fileUrl) {
            const link = document.createElement('a');
            link.href = fileUrl;
            // Optionally, specify a filename to download as:
            link.download = 'downloadedFile.pdf';  // you can set dynamically if you want
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
    }
        handleRemarks(event){
            console.log('event.target.value',event.target.value);
            this.remarks  = event.target.value;
        }
        // This Code was generated using GenAI tool : Codify, Please check for accuracy
        openCamera(event){
            this.selecteddocCheckId = event.currentTarget.dataset.id;
            console.log('this.selecteddocCheckId -->' + this.selecteddocCheckId);
            const uploadInput = this.template.querySelector('.hidden-input');
            if (uploadInput) {
                // Reset the value first so selecting the same file twice in a
                // row still fires the change event and re-triggers the upload.
                uploadInput.value = null;
                uploadInput.click();
            }
        }
        openCameraNonDocument (event){
            this.selecteddocCheckId = event.currentTarget.dataset.id;
            console.log('this.selecteddocCheckId -->' + this.selecteddocCheckId);
            const uploadInputFinish = this.template.querySelector('.hidden-input-finish');
            if (uploadInputFinish) {
                uploadInputFinish.value = null;
                uploadInputFinish.click();
            }
        }
        // GenAI: Generated code ends here
        shownonDocDetailsTable = false;
       handleUploadFinished(event) {
    console.log(JSON.stringify(event));
    const file = event.target.files[0];
    console.log('file finish -->', file);

    if (!file) return;

    const fileType = file.type.toLowerCase();
    const isImage = fileType.startsWith('image/'); // Check if it's an image

    if (isImage) {
        // Compress image before uploading
        this.compressImage(file)
            .then((compressedFile) => {
                this.uploadNonDocFile(compressedFile);
            })
            .catch((error) => {
                console.error('Error compressing image:', error);
                this.uploadNonDocFile(file); // fallback to original
            });
    } else {
        // Directly upload non-image file
        this.uploadNonDocFile(file);
    }

    // Reset file input
    this.template.querySelector('.hidden-input-finish').value = null;
}

// ✅ Reusable method to upload any file
uploadNonDocFile(file) {
    const reader = new FileReader();
    const fileName = file.name;
    const fileType = file.type;

    reader.onload = async () => {
        const base64Data = reader.result.split(',')[1];

        try {
            const result = await uploadFileNonDocument({
                base64Data: base64Data,
                fileName: fileName,
                fileType: fileType,
                requestorId:this.requestorId
            });

            if (result) {
                console.log('result>>>>',result);
                const docWrap = {
                    documentName: '',
                    documentId: '',
                    reqLevel: '',
                    contactName: '',
                    contentId: result,
                    contentDocumentId:result,
                    showPreview: true,
                    editnotdisabled: true,
                    sequence: this.nonDocList?.length ? this.nonDocList.length + 1 : 1
                };

                if (!this.nonDocList || this.nonDocList.length === 0) {
                    this.nonDocList = [docWrap];
                } else {
                    this.nonDocList.push(docWrap);
                }

                this.shownonDocDetailsTable = true;
                this.checkRecordEditability();
                this.sendToastMessage('Success', 'File Uploaded Successfully', 'Success');
            } else {
                this.sendToastMessage('Error', 'Please retry', 'error');
                this.shownonDocDetailsTable = false;
                this.checkRecordEditability();
            }
        } catch (error) {
            console.error('Error uploading file:', error);
            this.sendToastMessage('Error', 'File upload failed', 'error');
        }
    };

    reader.onerror = (e) => {
        console.error('FileReader error:', e);
        this.sendToastMessage('Error', 'Failed to read file', 'error');
    };

    reader.readAsDataURL(file);
}

        handleDeleteNonDoc(event){
            var opt = [];
            for(var i=0;i<this.nonDocList.length;i++){
                if(this.nonDocList[i].sequence != event.target.dataset.id){
                    opt.push(this.nonDocList[i]);
                }
                if(this.nonDocList[i].sequence == event.target.dataset.id){
                    console.log('this.nonDocList[i].documentId : '+this.nonDocList[i].documentId);
                    if(this.nonDocList[i].documentId!=undefined && this.nonDocList[i].documentId!='' && this.nonDocList[i].documentId!=null){
                        this.deleteDocument(this.nonDocList[i].documentId);
                    }
                }
            }
            this.nonDocList = opt;
        }
        handleInputChange(event) {
            let queryId = event.target.dataset.name;
            console.log('queryId '+queryId);
            let inputValue = event.target.value;
            console.log('queryId:', queryId, 'Input Value:', inputValue);
            this.remarks=inputValue;
            // Store the input value against the docId
            this.inputValuesMap[queryId] = inputValue;
            // This Code was generated using GenAI tool : Codify, Please check for accuracy
            // Keep the corresponding docList row's `remarks` in sync so the
            // Remarks column reflects what was typed (the textarea binds to
            // iter.remarks, not a top-level property).
            let docId = event.target.dataset.id;
            this.docList = this.docList.map(doc => {
                if (doc.documentId === docId) {
                    return { ...doc, remarks: inputValue };
                }
                return doc;
            });
            // GenAI: Generated code ends here
            console.log('Updated inputValuesMap:', JSON.stringify(this.inputValuesMap));
        }
      handleUpload(event) {
    const file = event.target.files[0];
    if (!file) return;

    const fileType = file.type.toLowerCase();

    // Check if the file is an image
    const isImage = fileType.startsWith('image/');

    if (isImage) {
        // Compress image
        this.compressImage(file).then(compressedFile => {
            this.uploadFileToServer(compressedFile);
        }).catch(error => {
            console.error('Image compression failed:', error);
        });
    } else {
        // Upload non-image file as-is
        this.uploadFileToServer(file);
    }

    // Clear input
    this.template.querySelector('.hidden-input').value = null;
}

// Separate function to handle uploading any file
uploadFileToServer(file) {
    const reader = new FileReader();
    const fileName = file.name;
    const fileType = file.type;

    reader.onload = async () => {
        const base64Data = reader.result.split(',')[1];
        try {
            await uploadFile({ 
                base64Data: base64Data, 
                fileName: fileName, 
                fileType: fileType, 
                recordId: this.recordId,
                selecteddocCheckId: this.selecteddocCheckId,
                requestorId:this.requestorId
            });
            this.getQueryDetails();
            this.sendToastMessage('Success', 'File Uploaded Successfully', 'Success');
        } catch (error) {
            console.error('Error uploading file:', error);
            this.sendToastMessage('Error', 'File upload failed', 'Error');
        }
    };

    reader.onerror = (e) => {
        console.error('FileReader error:', e);
    };

    reader.readAsDataURL(file);
}

        compressImage(file) {
            return new Promise((resolve, reject) => {
                const img = document.createElement('img');
                const reader = new FileReader();
                console.log('file>>>>')
    
                reader.onload = (e) => {
                    img.src = e.target.result;
                    img.onload = () => {
                        const canvas = document.createElement('canvas');
                        const ctx = canvas.getContext('2d');
                        let newCompressionRatio = (file.size/(this.isMobile ? 3000000 : 4000000))
                        this.compressionRatio = newCompressionRatio > 1.5 ? newCompressionRatio : 1.5
                        const scaleFactor = 1 / this.compressionRatio ; // 150% 
                        const width = img.width * scaleFactor;
                        const height = img.height * scaleFactor;
                        canvas.width = width;
                        canvas.height = height;
    
                        ctx.drawImage(img, 0, 0, width, height);
                        ctx.fillStyle = "#113451";
                        ctx.font = "50px bold Arial";
                        // const currentDateTime = new Date().toLocaleString('default', {timeZone: TIME_ZONE});
                        // const textToFill = this.geoCordinates + '     ' + currentDateTime;
                        // ctx.fillText(textToFill, 60, 100);
                        // PNG issue, can convert to JPEG
                        const outputFormat = file.type === 'image/png' ? 'image/jpeg' : file.type;
    
                        canvas.toBlob((blob) => {
                            if (blob.size < file.size) {
                                resolve(new File([blob], file.name, { type: outputFormat }));
                            } else {
                                console.log('Compressed image is larger than the original, reducing quality further');
                                canvas.toBlob((blob) => {
                                    resolve(new File([blob], file.name, { type: outputFormat }));
                                }, outputFormat, 0.3); 
                            }
                        }, outputFormat, 1); 
                    };
                };
    
                reader.onerror = (e) => reject(e);
                reader.readAsDataURL(file);
            });
        }
        init(){
            console.log('before init the record id---',this.recordId);
            checktypeofDoc({recordId : this.recordId})
            .then(result=>{
                if(result){
                    // setDocRecordButtons({recordId : this.recordId}).then(response=>{
                    //     console.log('response ',JSON.stringify(response));
                    //     this.setResponse(response);
                    // }).catch(error=>{
                    //     console.error(`The Error in setRecordButtons method is : ${JSON.stringify(error)}`);
                    //     this.isLoaded = false;
                    // })
                }
                else{
                    setRecordButtons({recordId : this.recordId}).then(response=>{
                        console.log('response ',JSON.stringify(response));
                        this.setResponse(response);
                    }).catch(error=>{
                        console.error(`The Error in setRecordButtons method is : ${JSON.stringify(error)}`);
                        this.isLoaded = false;
                    })
        }
    })
}
    

        setResponse(response) {
            this.buttonTrackers = response.buttons.map(button => {
                let buttonClass = 'button-green'; 
                if (button.name === 'Send Response') {
                    buttonClass = 'button-green';
                }  
                if (button.name === 'Re-assign Query') {
                    buttonClass = 'button-red';
                }
                if(button.name === 'Close'){
                    console.log('button----'+   this.greenColour);
                    buttonClass = 'button-red';
                }
                 if(button.name === 'Reassign'){
                    buttonClass = 'button-red';
                }
                // }else if (button.name === 'Approve') {
                //     buttonClass = 'button-green';
                // }
                // else if (button.name === 'Reassign') {
                //     buttonClass = 'button-green';
                // }
                // else if(button.name=='Underwriters Disposition'){
                //     buttonClass='button-green';
                // }
        
                return {
                    ...button,
                    buttonClass,
                };
            });
            if(this.buttonTrackers.length>0){
                if(this.buttonTrackers[0].name == 'Send Response'){
                    this.assignButtonlabel = 'Send Response';
                    this.assignHeader = 'Send Response';
                    this.greenColour=true;
                    console.log('button----'+   this.greenColour);
                }
            }
          
           
            
            this.fieldAPIName = response.fieldAPIName;
            this.objectAPIName = response.objectAPIName;
            this.fieldValue = response.fieldValue;
            this.previousFieldValue = response.previousFieldValue;
           
        }
    
        get buttonClass() {
            return this.greenColour ? 'button-green' : 'button-red';
        }
        
        updateDocRecordStatus(event) {
            this.buttonValue = event.target.value;
            let docId = event.target.dataset.docid;
            let btnId = event.target.dataset.btnid;
            let childId = event.target.dataset.name;
            this.remarks = this.inputValuesMap[childId] || ''; 
            console.log('Remarks for childId:', this.remarks);
            console.log(`Button clicked for Document: ${docId}, Button ID: ${btnId}, Child ID: ${childId}`);
            console.log('this.buttonValue ----', this.buttonValue);
            if(this.remarks){
            switch (this.buttonValue) {
                case 'Re-assigned':
                    this.childId = childId;
                    this.openReassignModal();
                    break;
                case 'Response Sent':
                    console.log('this.buttonValue ----', this.remarks);
                    if(this.remarks){
                    this.isLoading = true;
                    console.log('this.buttonValue --325--', JSON.stringify(this.nonDocList));
                    sendResponse({
                        parentId : this.recordId,
                        recordId: childId,
                        buttonValue: this.buttonValue,
                        remarks: this.remarks,
                        docWrap: JSON.stringify(this.nonDocList)
                    })
                    .then(response => {
                        this.isLoading = false;
                        if (response) {
                            console.log('response response sent===>', JSON.stringify(response));
                           // this.resetAfterAction('Response sent successfully.');
                        }
                    })
                    .catch(error => {
                        this.isLoading = false;
                        console.error('Error in sendResponse:', error);
                    });
                }
                else{
                    this.sendToastMessage('Error','Please ensure remarks is filled','error');
                }
                    break;
        
                case 'Accepted':
                    this.isLoading = true;
                    console.log('this.buttonValue ----572', this.buttonValue);
                    console.log('this.childId  ', childId);
                    acceptRecord({
                        recordId: childId,
                        buttonValue: this.buttonValue
                    })
                    .then(response => {
                        this.isLoading = false;
                        if (response === 'Success') {
                            console.log('response===>', JSON.stringify(response));
                            this.resetAfterAction('Record accepted successfully.');
                        }
                    })
                    .catch(error => {
                        this.isLoading = false;
                        console.error('Error in acceptRecord:', error);
                    });
                    break;
        
                case 'Sent Back':
                    if(this.remarks){
                    this.isLoading = true;
                    sendRecordBack({
                        parentId : this.recordId,
                        recordId: childId,
                        buttonValue: this.buttonValue,
                        remarks: this.remarks
                    })
                    .then(response => {
                        this.isLoading = false;
                        if (response === 'Success') {
                            this.resetAfterAction('Record sent back successfully.');
                        }
                    })
                    .catch(error => {
                        this.isLoading = false;
                        console.error('Error in sendRecordBack:', error);
                    });
                }
                else{
                    this.sendToastMessage('Error','Please fill remarks','error');
                }
                    break;
                case 'Closed':
                    if(this.remarks){
                    this.isLoading = true;
                    console.log('this.buttonValue ----', this.remarks);
                    closedRevertRecord({
                        parentId : this.recordId,
                        recordId: childId,
                        buttonValue: this.buttonValue,
                        remarks: this.remarks
                    })
                    .then(response => {
                        this.isLoading = false;
                        if (response === 'Success') {
                            this.resetAfterAction('Record closed successfully.');
                        }
                    })
                    .catch(error => {
                        this.isLoading = false;
                        console.error('Error in closedRevertRecord:', error);
                    });
                }
                else{
                    this.sendToastMessage('Error','Please fill remarks','error');
                }
                    break;
            }
        }
        else{
            this.sendToastMessage('Error','Please fill remarks','error');
            }
        }
        
        /**
         * Common function to reset state after successful actions.
         */
        resetAfterAction(successMessage) {
            this.buttonValue = '';
            this.remarks = '';
            this.shownonDocDetailsTable = false;
            this.getQueryDetails();
            this.init();
            this.checkRecordEditability();
            this.sendToastMessage('Success', successMessage, 'success');
        }
        
    
        updateRecordStatus(event){
        this.buttonValue = event.target.value;
        switch (this.buttonValue) {
            case 'Re-assigned':
                this.openReassignModal()
           
        }
        console.log('this.buttonValue ----',this.buttonValue );
        if(this.buttonValue == 'Response Sent'){
            console.log('this.buttonValue ----',this.remarks );
            checktypeofDoc({recordId : this.recordId})
            .then(result=>{
                if(!result){
            if(this.remarks == null || this.remarks =='' || this.remarks ==undefined){
                console.log('this.buttonValue 319----',this.buttonValue );
                this.sendToastMessage('Error','Please fill the remarks.','error');
                console.log('this.buttonValue  321----',this.buttonValue );
            }
            else
            {
                this.isLoading = true;
                console.log('this.buttonValue --325--',JSON.stringify(this.nonDocList));
                console.log('this,recordId>>>>',this.recordId);
                sendResponse({
                    recordId: this.recordId,
                    buttonValue: this.buttonValue,
                    remarks:this.remarks,
                    docWrap: JSON.stringify(this.nonDocList)
                })
                .then(response => {
                    this.isLoading = false;
                    if(response == true){
                        console.log('response===>'+JSON.stringify(response));
                    //this.performAction();
                   
                   // this.shownonDocDetailsTable  = false;
                    /*this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: this.recordId,
                            objectApiName: 'Query__c',
                            actionName: 'view'
                        }
                    });*/
                    this.sendToastMessage('Success','Response sent successfully.','success');
                    this.buttonValue='';
                    this.getQueryDetails();
                    this.init();
                    this.checkRecordEditability();
                    this.remarks ='';
                    this.getQueryDetails();
                    this.shownonDocDetailsTable();
                   // location.reload();
                    
                    }
        
                    console.log('response===>'+JSON.stringify(response));
                })
                .catch(error => {
                    console.log('error>>>',error);
                    this.isLoading = false;
                })
            }
        }
    else{
        console.log('All Query IDs:', this.allQueryIds);
        console.log('Current inputValuesMap:', JSON.stringify(this.inputValuesMap));
        // Ensure every query ID has a corresponding filled remark
        let allFilled =  this.allQueryIds.every(queryId => 
            this.inputValuesMap[queryId] && this.inputValuesMap[queryId].trim() !== ''
        );
        if (!allFilled) {
            console.log('Validation failed: Some queries do not have remarks.');
        }
        else{
        console.log('Validation successful: All queries have remarks.');
        sendDocResponse({
            parentId : this.recordId,
            queryIds : this.allQueryIds,
            buttonValue : this.buttonValue,
            remarksMap : this.inputValuesMap
        })
        .then(response => {
            this.isLoading = false;
            if(response == true){
                console.log('response===>'+JSON.stringify(response));
            //this.performAction();
           
            this.shownonDocDetailsTable  = false;
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'Query__c',
                    actionName: 'view'
                }
            });
            this.sendToastMessage('Success','Response sent successfully.','success');
            this.buttonValue='';
            this.getQueryDetails();
            this.init();
            this.checkRecordEditability();
            this.remarks ='';
            this.getQueryDetails();
            this.shownonDocDetailsTable();
            location.reload();
            
            }

            console.log('response===>'+JSON.stringify(response));
        })
        .catch(error => {
            this.isLoading = false;
        })
        }
    }})
        }
        if(this.buttonValue == 'Accepted'){
            this.isLoading = true;
            console.log('this.buttonValue ----572',this.buttonValue );
            acceptRecord({
                recordId: this.recordId,
                buttonValue:this.buttonValue
            })
            .then(response => {
                this.isLoading = false;
                if(response == 'Success'){
                console.log('response===>'+JSON.stringify(response));
              
                this.checkRecordEditability();
               
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: 'Query__c',
                        actionName: 'view'
                    }
                });
                this.sendToastMessage('Success','Record accepted successfully.','success');
                this.buttonValue='';
                this.getQueryDetails();
                this.init()
                this.remarks ='';
                location.reload();
                }
            })
            .catch(error => {
                this.isLoading = false;
            })
        }
        if(this.buttonValue == 'Sent Back'){
            this.isLoading = true;
            console.log('this.buttonValue ----',this.remarks );
            if(this.remarks == null || this.remarks =='' || this.remarks ==undefined){
                this.sendToastMessage('Error','Please fill the remarks.','error');
                this.isLoading = false;
            }
            else{
                this.isLoading = true;
                sendRecordBack({
                    recordId: this.recordId,
                    buttonValue:this.buttonValue,
                    remarks:this.remarks,
                })
                .then(response => {
                    this.isLoading = false;
                    if(response == 'Success'){
                        this.buttonValue='';
                        this.getQueryDetails();
                        this.init();
                        this.remarks ='';
                        this.checkRecordEditability();
                        this.sendToastMessage('Success','Record sent back successfully.','success');
                        location.reload();
                        
                    }
                })
                .catch(error => {
                    this.isLoading = false;
                })

            }
        }
        if(this.buttonValue == 'Closed'){
            this.isLoading = true;
            console.log('this.buttonValue ----',this.remarks );
            if(this.remarks == null || this.remarks =='' || this.remarks ==undefined){
                this.sendToastMessage('Error','Please fill the remarks.','error');
                this.isLoading = false;
            }
            else{

                closedRevertRecord({
                    recordId: this.recordId,
                    buttonValue:this.buttonValue,
                    remarks:this.remarks,
                })
                .then(response => {
                    this.isLoading = false;
                    if(response == 'Success'){
                        this.buttonValue='';
                        this.getQueryDetails();
                        this.init();
                        this.checkRecordEditability();
                        this.remarks ='';
                        location.reload();
                    }
                })
                .catch(error => {
                    this.isLoading = false;
                })
            }
        }
        
    }
        
        performAction(){
            console.log(`The Value is : ${this.buttonValue}  ${this.objectAPIName}`)
            if(this.buttonValue==='Assigned'){
                console.log(`The Value is : ${this.buttonValue}  ${this.objectAPIName}`)
                //this.sendNotification(this.assingedUsers);
            }
        }
        sendNotification(assignedUsers){
            sendNotification({recordId : this.recordId,status:this.buttonValue,assignedUserIds:assignedUsers}).then(response=>{
            }).catch(error=>{
                console.error(`The Error is : ${JSON.stringify(error)}`)
            })
        }
    
        sendToastMessage(title,message,variant){
            this.dispatchEvent(new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            }));
        }

        handleRequestFromUsers(event){
            console.log('event.detail=:'+JSON.stringify(event.detail));
            var userList = event.detail.selectedList;
            console.log('event.detail=:'+userList);
           if(userList.length>0){
                for(var i=0;i<userList.length;i++){
                    this.assingedUsers.push(userList[i]);
                    console.log('event. this.assingedUsers=:'+ this.assingedUsers);
                }
            }
        }

        closeReassignmentModal(){
            this.openReassignmentModal = false;
        }
        updateRecords(){
            console.log('this.buttonValue ----',this.remarks );
            console.log('this.childId ----',this.childId);
            console.log('this.assingedUsers ----',this.assingedUsers);
            if(this.remarks && this.assingedUsers && this.assingedUsers.length > 0){
            checktypeofDoc({recordId : this.recordId})
            .then(result=>{
                console.log('result===>'+(result));
              if(result){
                reassignRecord({
                    recordId : this.childId,
                    buttonValue : 'Re-assigned',
                    remarks : this.remarks,
                    requestedFromUsers : this.assingedUsers
                }).then(response => {
                    if(response == 'Success'){
                        this.buttonValue='';
                        this.childId = null;
                        this.getQueryDetails();
                        this.init();
                        this.checkRecordEditability();
                        this.openReassignmentModal = false;
                        this.sendToastMessage('Success','Record reassigned successfully.','success');
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: this.recordId,
                                objectApiName: 'Query__c',
                                actionName: 'view'
                            }
                        });
    
                    }
                
                })
                .catch(error => {
                    console.error(`The Error is : ${JSON.stringify(error)}`)
                })
              }
              else{
                reassignRecord({
                    recordId : this.recordId,
                    buttonValue : 'Re-assigned',
                    remarks : this.remarks,
                    requestedFromUsers : this.assingedUsers
                }).then(response => {
                    if(response == 'Success'){
                        this.buttonValue='';
                        this.getQueryDetails();
                        this.init();
                        this.checkRecordEditability();
                        this.openReassignmentModal = false;
                        this.sendToastMessage('Success','Record reassigned successfully.','success');
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: this.recordId,
                                objectApiName: 'Query__c',
                                actionName: 'view'
                            }
                        });
    
                    }
                
                })
                .catch(error => {
                    console.error(`The Error is : ${JSON.stringify(error)}`)
                })
              }
            })
        }
        else{
            this.sendToastMessage('Error','Please select the users and fill the remarks before proceeding.','error');
        }

        }
        checkRecordEditability(){
            checkRecordEditability({recordId : this.recordId})
            .then(response => {
                this.recordEditable = response.recordEditable;
                this.uploadEditable = response.uploadEditable;
                console.log('recordEditable '+this.recordEditable);
                console.log('uploadEditable '+this.uploadEditable);
            })
            .catch(error => {
                console.error(`The Error is : ${JSON.stringify(error)}`)
            })

        }

        renderedCallback(){
            console.log('IN CHILD RENDER CALL BACK');
            if(!this.isRendered){
                console.log('Inside if condition');
                this.isRendered = true;
                const style = document.createElement('style');
                style.innerText = `
                .uploadFile .slds-file-selector__text.slds-medium-show {
                  display: none;
                }
                .uploadFile .slds-file-selector__button.slds-button.slds-button_neutral{
                    font-size: 0!important;
                }
                .uploadFile svg.slds-button__icon.slds-button__icon_left {
                    margin: 0;
                }
                .uploadFile lightning-primitive-file-droppable-zone.slds-file-selector__dropzone {
                    border: none;
                    padding: 0;
                }
                .uploadFile slds-form-element__label{
                    display: none;
                }
                .info-button svg.slds-button__icon.slds-button__icon_left {
                    margin: 0;
                }
                .class-file-upload .slds-form-element__label:empty {
                    margin: 0;
                    display: none;
                }
                .uploaded-view svg.slds-button__icon.slds-button__icon_left {
                    color: green;
                }
                .uploaded-view svg.slds-button__icon {
                    color: green;
                }
                .file-preview-buttons.slds-align--absolute-center {
                    display: none;
                }
                `;
                this.template.querySelector('.styleContainer').appendChild(style);
            }
        }
      
    handleEdit(event) {
        let docId = event.currentTarget.dataset.id;
        this.addedDocList = this.addedDocList.map(doc => {
            if (doc.value === docId) {
                return { ...doc, isEditing: true };
            }
            return doc;
        });
    }

    handleFieldChangeName(event) {
        const field = event.target.dataset.field;
        const docId = event.target.dataset.id; 
        const value = event.target.value;
        for (let i = 0; i < this.nonDocList.length; i++) {
            if (String(this.nonDocList[i].sequence) === docId) { 
                this.nonDocList[i].documentName = value; 
                break; 
            }
        }
    
        console.log('Updated nonDocList:', JSON.stringify(this.nonDocList));
    }

    handleFieldChangeNameRequirement(event) {
        const field = event.target.dataset.field;
        const docId = event.target.dataset.id; 
        const value = event.target.value;
        if( event.target.value === 'Loan Application') {
            this.disableCustomerName = true;
        }
        else{
            this.disableCustomerName = false;
        }
        for (let i = 0; i < this.nonDocList.length; i++) {
            if (String(this.nonDocList[i].sequence) === docId) { 
                this.nonDocList[i].reqLevel = value;
                break; 
            }
        }
    
        console.log('Updated nonDocList:', JSON.stringify(this.nonDocList));
    }

    handleContactNameChange(event) {
        const field = event.target.dataset.field;
        const docId = event.target.dataset.id; // Capturing sequence ID
        const value = event.target.value;
    
        // Loop through nonDocList to find the matching sequence and update the field
        for (let i = 0; i < this.nonDocList.length; i++) {
            if (String(this.nonDocList[i].sequence) === docId) { // Ensuring proper ID comparison
                this.nonDocList[i].contactName = value; // Update the field
               
                break; // Exit loop once found
            }
        }
    
        console.log('Updated nonDocList:', JSON.stringify(this.nonDocList));
    }

    
    

    saveDocumentChanges(docId) {
        let updatedDoc = this.addedDocList.find(doc => doc.value === docId);
        updateDocumentChecklist({
            contendDocId: this.contentDocIds,
            loanId:this.loanId,
            recordId:this.recordId,
            name: updatedDoc.label,
            requirementLevel: updatedDoc.requirementLevel,
            customerId: updatedDoc.customerId
        }).then(() => {
            this.showToast("Success", "Document updated successfully", "success");
        }).catch(error => {
            console.error("Error updating document", error);
            this.showToast("Error", "Failed to update document", "error");
        });
    }


        fetchRequirementLevels() {
            getRequirementLevels().then(data => {
                this.requirementOptions = data.map(item => ({ label: item, value: item }));
            }).catch(error => {
                console.error("Error fetching requirement levels", error);
            });
        }
    
        fetchCustomers() {
            getCustomers({ loanId: this.loanId }).then(data => {
                this.customerOptions = data.map(item => ({ label: item.Applicant_Name__c, value: item.Id }));
            }).catch(error => {
                console.error("Error fetching customers", error);
            })
        }
        get hasRecords() {
            return this.addedDocList && this.addedDocList.length > 0;
        }
        handleView(event){
            let childId = event.target.dataset.name;
            if(childId!=null){
                this.childId = childId;
                console.log('childId '+this.childId);
                this.showremarks = true;
            }
        }
        handleRemarksClose(event){
            this.childId = null;
            this.showremarks = false;
        }
        deleteDocument(dodId){
            deleteNonDocumentChecklist({
                recordId:dodId,
            }).then(() => {
                this.sendToastMessage("Success", "Document deleted successfully", "success");
            }).catch(error => {
            })
        }
            
          

}