import { LightningElement, api,track,wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, createRecord,updateRecord } from "lightning/uiRecordApi";//sanwar (4/12/2025) add getRecord
import DOCUMENT_CHECKLIST_OBJECT from '@salesforce/schema/Document_Details__c';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import customLoadStyles from '@salesforce/resourceUrl/waiverDoc';
import { loadStyle } from 'lightning/platformResourceLoader';
//import uploadFile from '@salesforce/apex/Utility.uploadFile';
import checkUserHavePsFcuSamplerPermissionSet from '@salesforce/apex/Utility.checkUserHavePsFcuSamplerPermissionSet';
import assigneeList from '@salesforce/apex/Credit_FIVerificationController.assigneeList';
//import getInvestigationRecords from '@salesforce/apex/Credit_FIVerificationController.getInvestigationRecords';
import initateFieldVisitMultiple from '@salesforce/apex/Credit_FIVerificationController.initateFieldVisitMultiple';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getApplicantTable from '@salesforce/apex/Credit_FIVerificationController.getApplicantTable';
import initiateVendorPD from '@salesforce/apex/Credit_FIVerificationController.initiateVendorPD';
import getLoanStage from '@salesforce/apex/Utility.getLoanStage';
import getCurrentUserProfileName from '@salesforce/apex/Utility.getCurrentUserProfileName';
import getApprovalSataus from '@salesforce/apex/Utility.getApprovalSataus';
import createApplicationVerification  from '@salesforce/apex/Credit_FIVerificationController.createApplicationVerification';
import getProductName  from '@salesforce/apex/Credit_FIVerificationController.getProductName';
import getComponentEditability from '@salesforce/apex/Utility.getComponentEditability';
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";//sanwar(4/12/2025)
import canUserEditRecord from '@salesforce/apex/Hl_CovenantsDetailFormController.canUserEditRecord';//sanwar(4/12/2025)
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';//updated Ayushi
const SUCCESS_TITLE     = 'Success'
const SUCCESS_VARIANT   = 'success'
const FI_CREATION_MSG   = 'Successfully initiated a field investigation.'
const FI_CREATION_MSG_HL = 'Field Investigation initiated successfully.';
const PD_CREATION_MSG   = 'PD initiated successfully.'

const ERROR_TITLE           = 'Error'
const ERROR_VARIANT         = 'error'
const VALIDATE_FI_ERROR     = 'Please select the required fields before initiating the Field Investigation.'


export default class CreditFIInitiationCmp extends LightningElement {
    @api recordId;
    @api isVendorPD;
    @api sectionHeader= "Field Investigation Initiation";
    @api disabledCmp = false;
    @track showVendorPD;
    @track verificationType= 'FI';
    initiateFICmp = false;
    @track recordTypeOptions = [];
    @track recordTypeValue = '';
    @track selectedCustomer = '';
    @track assigneeOptions = [];
    @track selectedAssignee = '';
    @track oppSubStage = '';//sanwar(4/12/2025)
    recordTypeMap = new Map();
    @api genericInitiate = false
    showFITable = false
    //@track investigations = []
    @track documents = []
    currentDocId;
    currentIndex;
    @track geoCordinates = '';
    @track latitude = '';
    @track longitude = '';
    @track fiInitiationTable = [];
    @track showBusinessAddress;
    @track businessAddressList=[];
    @track selectedAddressId;
    @track showEnabledButtons=false;
    @track applicantId;
    @track assigneeWrapper;
    @track assigneeWrapperList;
    @track contentDocIWaiver;
    @track showSpinner=false;
    @track ShowLoader=false;
    @track waiverDocUploaded=false;
    @track imageURL;
    @track isMobile=false;
    @track comment;
    @track initialTableData;
    @track applicableVisitTable=[];
    @track remarks;
    @track fiListToBeInitated=[];
    @track userHavePsFcuSamplerPermissionSet = false;
    @track isInterFIToggled = false;
    @track isModalOpen = false;
    @track remarks = '';
    @track uploadedFileIds = [];
    @track isSubmitDisabled = true;
    selectedId;
    selectedType;
    isWaiverSelected = false;
    isInitiationOpen = true; 
    isInvestigationOpen = false; 
    @track reportStatus;
    DisplayVendorPD = true;
    initiateMessage;
    prodCheck = false;
    progressStep = {
        step1 : false,
        step2 : false,
        step3 : false,
        step4 : false,
        step5 : false
    }

    @track selectOption = {
        'label':'',
        'value': ''
    }

        @track statusOptions = [
        { label: 'Positive', value: 'Positive' },
        { label: 'Negative', value: 'Negative' },
        { label: 'Refer to CM', value: 'Refer to CM' }
    ];

    @track openModal = false;
    openModalPD = false;
    openWaiverModal=false;
    confirmationMessage = 'Are you sure you want to perform this action?'
    activeSection = 'initiation';
    isDisableInitiation = false;
    prodName;
    initiateMessage;
    waivedMessage;
    buttonLabel;
    @track isHLProduct = false;//updated Ayushi

    /* ____GenAI: Generated code starts here - lightning-accordion-section's
       header renders inside its own fully encapsulated shadow root in this
       org: neither SLDS custom-property styling hooks nor external CSS
       overrides ever repainted it (confirmed by deploying twice and
       hard-refreshing, zero visual change both times). The base accordion
       markup is replaced with plain divs (see creditFIInitiationCmp.html)
       driven by the existing `activeSection` state, so handleSectionToggle
       now reads the section name from a data-name attribute on the custom
       header div instead of the base component's own `name` property.____ */
    handleSectionToggle(event){
        const sectionName = event.currentTarget && event.currentTarget.dataset ? event.currentTarget.dataset.name : undefined;
        if(sectionName != undefined && sectionName != '' && sectionName != null){
            this.activeSection = sectionName;
        }
    }

    get isInitiationSectionOpen() {
        return this.activeSection === 'initiation';
    }
    get isInvestigationSectionOpen() {
        return this.activeSection === 'investigation';
    }
    get initiationSectionIcon() {
        return this.isInitiationSectionOpen ? 'utility:chevrondown' : 'utility:chevronright';
    }
    get investigationSectionIcon() {
        return this.isInvestigationSectionOpen ? 'utility:chevrondown' : 'utility:chevronright';
    }
    /* ____GenAI: Generated code ends here____ */
    handleAccordionChange(event) {
        const sectionName = event.target.name;
        if (sectionName === 'initiation') {
            this.isInitiationOpen = event.target.opened;
            this.isInvestigationOpen = !this.isInitiationOpen; 
        } else if (sectionName === 'investigation') {
            this.isInvestigationOpen = event.target.opened;
            this.isInitiationOpen = !this.isInvestigationOpen; 
        }
    }
    connectedCallback(){
        if(FORM_FACTOR == 'Large') {
            this.isMobile = false;
        } else {
            this.isMobile = true;
        }
        this.fetchProductName();
        if(this.isVendorPD == 'true'){
            this.showVendorPD = true;
            this.verificationType = 'Vendor PD';
        }else if(this.isVendorPD == 'false'){
            this.showVendorPD = false;
        }
        console.log('this.verificationType---in connected callback--', this.verificationType);
        
        this.setInvestigationRecords()
        this.setAssignee()
        this.getUserLocationCordinates();
        // setTimeout(() => {
        //     this.getApplicableAddressDetails();
        // },500)
        this.getApplicableAddressDetails();
        this.fetchLoanStage();
        Promise.all([
            loadStyle(this, customLoadStyles )
        ]).then(() => {
            console.log('Upload success')
        }).catch( (error) => {
            console.error(error);
        })
        this.handleCheckUserHavePsFcuSamplerPermissionSet();
        this.checkCmpEditability();
    }
    //4/12/2025
    @wire(getRecord, {
        recordId: "$recordId",
        fields: [SUBSTAGE_FIELD]
    })
    oppRecord({ data, error }) {
        if (data) {
            console.log('Data',data);
            this.oppSubStage = data.fields.Sub_stage__c.value;
            console.log("Sub Stage:", this.oppSubStage);
            canUserEditRecord({ recordId: this.recordId })
            .then(result => {
                console.log('At 380');
                if(result && this.oppSubStage == 'Ops Author'){
                    console.log('At 382');
                    this.isDisableInitiation = true;
                }
            });
        } else if (error) {
            console.error(error);
        }
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

    fetchProductName(){
        getProductName({recordId: this.recordId})
        .then(result=>{
           this.prodName = result;
           if(this.prodName == 'Home Loan'){
            this.initiateMessage =  'Step 1: Please select appropriate assignee and initiate the field investigation process.';
            this.buttonLabel = 'Enable Internal FI';
           }
           else {
            this.initiateMessage = `Step 1: Please select appropriate assignee and initiate the field investigation process.${this.openModal}`;
            this.buttonLabel = 'Internal FI';
           }
        })
        .catch((error) =>{
              console.error('Error fetching product name '+ error);
        });
    }

    fetchLoanStage() {
        getLoanStage({ loanId: this.recordId })
          .then(result => {
            console.log('Result1', result);
            if (result == 'Credit Underwriting' || result == 'PSV' || result == 'Disbursement') {
                getCurrentUserProfileName()
                .then((res) => {
                    if(res == 'Sales' || res == 'Ops') {
                        this.isDisableInitiation = true;
                        this.DisplayVendorPD = false;
                    }else if(this.isVendorPD && (res == 'Credit Officer' || res == 'Sales')) {
                        this.isDisableInitiation = true;
                        this.DisplayVendorPD = false;
                    }
                })
                .catch((error) => {
                    console.error('Error getCurrentUserProfileName --> '+ error);
                });
            } else {
                getCurrentUserProfileName()
                .then((res) => {
                    if(res == 'Sales' || res == 'Ops') { // || res == 'Credit Manager'
                        this.isDisableInitiation = true;
                    }
                })
                .catch((error) => {
                    console.error('Error getCurrentUserProfileName --> '+ error);
                });
            }
          })
          .catch(error => {
            console.error('Error:', error);
        });
    }

    handleCheckUserHavePsFcuSamplerPermissionSet() {
        checkUserHavePsFcuSamplerPermissionSet()
          .then(result => {
            console.log('Result', result);
            this.userHavePsFcuSamplerPermissionSet = result;
          })
          .catch(error => {
            console.error('Error:', error);
        });
    }
    getApplicableAddressDetails(){
        console.log('this.verificationType----', this.verificationType);
        
        getApplicantTable({
            loanId:this.recordId,
            verificationType: this.verificationType
        }).then(response=>{
            console.log('this.applicableVisitTable ####### :: ',response);
            
            this.applicableVisitTable=response;//[...response];
            let rowClass ;
            //this.applicableVisitTable = response.map(visit => {
                let processedVisits = response.map(visit => {
                // Process creditRemarks
                //let latestComment = "";
                let latestComment = visit.creditRemarks || "";
                if (visit.creditRemarks) {
                    // Split by <br> to get individual remarks
                    if (latestComment.includes('<br>')) {
                        let remarksArray = visit.creditRemarks.split('<br>');
                        
                        if (remarksArray.length > 0) {
                            // Extract the latest remark (first item)
                            let latestRemark = remarksArray[0];
                           
                            // Remove the "CM User - date, time:" part using regex
                            latestComment = latestRemark.replace(/^CM User - [\d/]+, [\d:apm\s]+:\s*/, '');
                            console.log('line 248--->>',latestComment);
                        }
                    }else{
                        latestComment = visit.creditRemarks;
                    }
                }
                if(visit.waiverFlag=='Waived'){
                    rowClass="background-paleBlue"
                }else{
                    rowClass="background-normal"
                }
                return {
                    ...visit,
                    rowClass, 
                    creditRemarks: latestComment
                };

            });
            this.applicableVisitTable = processedVisits.sort((a, b) => {
            let aHasFiStage = a.fiStage ? 1 : 0;
            let bHasFiStage = b.fiStage ? 1 : 0;
            return bHasFiStage - aHasFiStage;  // addresses with fiStage first
            });
            console.log('this.applicableVisitTable=:147'+JSON.stringify(this.applicableVisitTable));
            console.log('ayush142');
            this.genericInitiate=true;
            this.showInitiationTable=true;

        }).catch(error=>{

        })
    }

    setInvestigationRecords(){
        const childComponent = this.template.querySelector('c-show-record-table');
    
        
        if(childComponent) {
            // Call the method in the child component
            childComponent.getRecordDetails();
        }


    }
    
    setAssignee(){
        assigneeList({loanId: this.recordId, verificationType: this.verificationType})
        .then((data) => {
            this.selectOption = {
                'label':'',
                'value': ''
            };
            console.log('data------122'+JSON.stringify(data));
            this.assigneeWrapper = data;
            //this.assigneeOptions = data.assigneeList;  
            this.selectOption.label = this.assigneeWrapper.assigneeName;
            this.selectOption.value = this.assigneeWrapper.assigneeID;
            if(this.assigneeOptions.length > 0){this.selectedAssignee = this.assigneeOptions[0].value}
         
        })
        .catch((error) => {
            console.error(`Error : assigneeList : ${JSON.stringify(error)}`);
        });
    }
    handleRecordTypeChange(event){
        this.recordTypeValue = event.target.value;
        this.progressStep.step1 = true
    }
    get showAssigneeList(){
        if(this.selectedCustomer != null && this.selectedCustomer != '' && this.selectedCustomer != undefined){
            return true;
        }else{
            return false;
        }
    }
    handleAssignee(event){
     
        this.applicableVisitTable.forEach(customerinTable => {
            
            if(customerinTable.applicantId === event.detail.id && customerinTable.addressType === event.detail.name){
                customerinTable.selectedAssignee = event.detail.value;
            }
        });

        this.selectedAssignee = event.detail.value;
        this.progressStep.step3 = true;
        this.isUserSelected = true
        this.progressStep.step4 = true;
    }
    handleInternal(event)
    {

        this.applicableVisitTable.forEach(customerinTable => {
            
            if(customerinTable.applicantId === event.detail.id && customerinTable.addressType === event.detail.name){
                customerinTable.selectedAssignee = event.detail.value;
            }
        });
    }
    handleDirectorAssignee(event){

        this.applicableVisitTable.forEach(customerinTable => {
            
            if(customerinTable.applicantId === event.detail.id && customerinTable.addressType === event.detail.name){
                customerinTable.selectedDirector = event.detail.value;
            }
        });
    }
    closeModal(){
        this.openModal = false;
    }
    closeModalPD(){
        this.openModalPD = false;
    }
    closeWaiverModal(){
        this.openWaiverModal = false;  
        this.isWaiverSelected = false;
        this.ShowLoader=false;
        this.showSpinner=false;
    }
    closeRemarkModal(){
        this.openWaiverModal = true;  
        this.isWaiverSelected = false;
        this.ShowLoader=false;
        this.showSpinner=false;
    }
    sendToastMessage(title,msg,variant){
        this.dispatchEvent(
                new ShowToastEvent({
                title: title,
                message: msg,
                variant: variant
            })
        );
    }
    get showInitiationTable(){
        return this.applicableVisitTable.length > 0;
    }
    handleUpload(event){
        console.log(JSON.stringify(event));
        const file = event.target.files[0];
        console.log('file -->'+file);
        
        if (file) {
            this.spinnerRun = true;
            this.compressImage(file).then(compressedFile => {
                const originalSize = file.size;
                const fileName = file.name;
                const fileType = file.type;
                const compressedReader = new FileReader();
                const compressedSize = compressedFile.size;

                compressedReader.onload = async () => {
                    const compressedUrl = compressedReader.result;
                    const base64Data = compressedUrl.split(',')[1];
                   
                };
                compressedReader.readAsDataURL(compressedFile);
            });
        }
        this.template.querySelector('.hidden-input').value = null;
    }

    compressImage(file) {
        return new Promise((resolve, reject) => {
            const img = document.createElement('img');
            const reader = new FileReader();

            reader.onload = (e) => {
                img.src = e.target.result;
                img.onload = () => {
                    const canvas = document.createElement('canvas');
                    const ctx = canvas.getContext('2d');
                    let newCompressionRatio = (file.size/4000000)
                    this.compressionRatio = newCompressionRatio > 1.5 ? newCompressionRatio : 1.5
                    const scaleFactor = 1 / this.compressionRatio ; // 150% 
                    const width = img.width * scaleFactor;
                    const height = img.height * scaleFactor;
                    canvas.width = width;
                    canvas.height = height;

                    ctx.drawImage(img, 0, 0, width, height);
                    ctx.fillStyle = "#113451";
                    ctx.font = "50px bold Arial";
                    const currentDateTime = new Date().toLocaleString('default', {timeZone: TIME_ZONE});
                    const textToFill = this.geoCordinates + '     ' + currentDateTime;
                    ctx.fillText(textToFill, 60, 100);
                    // PNG issue, can convert to JPEG
                    const outputFormat = file.type === 'image/png' ? 'image/jpeg' : file.type;

                    canvas.toBlob((blob) => {
                        if (blob.size < file.size) {
                            resolve(new File([blob], file.name, { type: outputFormat }));
                        } else {
                            console.log('Compressed image is larger than the original, reducing quality further');
                            canvas.toBlob((blob) => {
                                resolve(new File([blob], file.name, { type: outputFormat }));
                            }, outputFormat, 0.5); 
                        }
                    }, outputFormat, 1); 
                };
            };

            reader.onerror = (e) => reject(e);
            reader.readAsDataURL(file);
        });
    }

    getUserLocationCordinates() {
        //get user's geo-cordinates
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition((position) => {
                var latitude = position.coords.latitude;;
                var longitude = position.coords.longitude;
                var longitude = position.coords.longitude;
                this.latitude = latitude;
                this.longitude = longitude;
                this.geoCordinates = '(' + latitude.toFixed(4) + ',' + longitude.toFixed(4) + ')';

            },
            (e) => {

            },
            {
                enableHighAccuracy: true,
            }
            );
        }
       
    }
    showImage(event){
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
    handleWaiverDocUploadFinish(event){
        this.handleUploadFinished(event);
    }
    handleUploadFinished(event){
        console.log('event.detail.files :' + JSON.stringify(event.detail.files));
        
        const uploadedFiles = event.detail.files;
        this.uploadedFileIds = event.detail.files.map(file => file.documentId);
        let docId = event.target.dataset.id;
   
        this.frontId = uploadedFiles[0].documentId;
        this.contentDocIWaiver= uploadedFiles[0].documentId;
        this.showSpinner = true;
        for (var i = 0; i < this.applicableVisitTable.length; i++) {

            if (this.applicableVisitTable[i].addressId == event.target.dataset.id) {
                this.applicableVisitTable[i].waiverDocId =uploadedFiles[0].documentId;
                this.applicableVisitTable[i].waiverDocName = uploadedFiles[0].name;
                this.applicableVisitTable[i].isDocumentUploaded=true;
                this.imageURL= '/sfc/servlet.shepherd/document/download/'+this.contentDocIWaiver
            }
        }

        if(this.fiListToBeInitated!=null && this.fiListToBeInitated!=undefined && this.fiListToBeInitated.length>0){

            for (var i = 0; i < this.fiListToBeInitated.length; i++) {
                if (this.fiListToBeInitated[i].addressId == event.target.dataset.id) {
                    this.fiListToBeInitated[i].waiverDocId = uploadedFiles[0].documentId;
                    this.fiListToBeInitated[i].waiverDocName = uploadedFiles[0].name;
                    this.fiListToBeInitated[i].isDocumentUploaded=true;
                    this.imageURL= '/sfc/servlet.shepherd/document/download/'+this.contentDocIWaiver
                }
            }
        }
        this.ShowLoader = true;
        this.updateSubmitState();
        this.ShowLoader = false;
        this.showSpinner = false;

    }
    
    updateWaiver(){
        if(this.fiListToBeInitated==null||this.fiListToBeInitated==undefined||this.fiListToBeInitated.length==0){
            this.dispatchEvent(
                new ShowToastEvent({
                title: 'Error',
                message: 'Please select visit to be waived.',
                variant: 'Error'
            })
            )
            return;
        } else if (this.fiListToBeInitated.some(item => item.waiverFlag === 'Waived')){
            this.openWaiverModal = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Visist already waived , please check.',
                    variant: 'Error'
                })
            );
            return;
        }else{
            this.openWaiverModal = false;  
            let selectedId = this.selectedId;
            let selectedType = this.selectedType;
            let isWaiverSelected = this.isWaiverSelected;
            let custTableRow;
            this.applicableVisitTable.forEach(customerinTable => {
                if(customerinTable.addressId === selectedId){
                    custTableRow = customerinTable;
                }
            })
            console.log('this.fiListToBeInitated---'+JSON.stringify(this.fiListToBeInitated));
            console.log('this.fiListToBeInitated.length',this.fiListToBeInitated.length);

            console.log(`The Value is : ${JSON.stringify(custTableRow)}`)
           if(this.fiListToBeInitated!=undefined && this.fiListToBeInitated.length>0){
            console.log( 'filterdVisitList>',this.fiListToBeInitated,' recordId>',this.recordId,' waiverComment>',this.remarks, ' waiverDocumentId>' ,this.contentDocIWaiver, ' selectedAssignee>',this.selectedAssignee );
                initateFieldVisitMultiple({
                    'filterdVisitList':JSON.stringify(this.fiListToBeInitated),
                    'recordId':this.recordId,
                    'waiverComment':this.remarks,
                    'waiverDocumentId':this.contentDocIWaiver,
                    'selectedAssignee':this.selectedAssignee,//this.selectOption.value,
                    'isWaived':true
                })
                .then(result=>{
                    this.fiListToBeInitated=[];
                    this.sendToastMessage(SUCCESS_TITLE,'Waiver initiated successfully.',SUCCESS_VARIANT)
                    if(this.genericInitiate){
                        this.progressStep.step5 = true;
                        this.setInvestigationRecords();
                        this.getApplicableAddressDetails();
                        this.setAssignee();
                    }
                })
                .catch(error=>{
                    console.log('error: ' + error.body?.message || error.message);
                })
            }
        }
    }
    showImage(event){

        this[NavigationMixin.Navigate]({ 
            type:'standard__namedPage',
            attributes:{ 
                pageName:'filePreview'
            },
            state:{ 
                selectedRecordId: event.target.dataset.name
            }
        })
    }
    handleRotate(){
        this.rotationAngle = (this.rotationAngle + 90) % 360;
        this.updateRotation();
    }   
    updateRotation() {
        const image = this.template.querySelector('.rotate-image');
        if (image) {
            image.style.transform = `rotate(${this.rotationAngle}deg)`;
        }
    }
    handleRetake(event){
        this.selecteddocCheckId = event.target.dataset.id;

        this.template.querySelector('.hidden-input').click();
    }
    handleRemark(event){
        console.log('value####' + event.target.value);
        
        this.comment=event.target.value;
    }
    handleRemarksChange(event){
        this.remarks = event.target.value;
        this.updateSubmitState();
        console.log('value ' + event.target.value);

        for(var i=0;i<this.applicableVisitTable.length;i++){
            if(this.applicableVisitTable[i].addressId==event.target.dataset.id){
                this.applicableVisitTable[i].remarks=event.target.value;

            }
        }
    }

    handleReportStatusChange(event) {
        this.reportStatus = event.target.value;
    }

    selectallcheckboxes(event){

            const isChecked = event.target.checked;
            const toggleList = this.template.querySelectorAll('[data-id="toggle"]');

            toggleList.forEach((toggleElement) => {
                toggleElement.checked = isChecked;
            });
            if(event.target.checked){
                for(var i=0;i<this.applicableVisitTable.length;i++){
                    if(!this.applicableVisitTable[i].isVistiInitated)
                    {
                        this.fiListToBeInitated.push(this.applicableVisitTable[i]);

                    }else{
                        this.applicableVisitTable[i].selected=false;
                    }
                }
            }
            else{
                this.fiListToBeInitated=[];

            
            }
        }
        selectIndividualCheckbox(event){


            const isChecked = event.target.checked;
            if(!isChecked){
            const toggleList = this.template.querySelectorAll('[data-id="mainToggle"]');

                toggleList.forEach((toggleElement) => {
                    toggleElement.checked = isChecked;
                
                
                });
                
            }
            for (var i = 0; i < this.applicableVisitTable.length; i++) {
                console.log('this.applicableVisitTable[i].selected :' + JSON.stringify(this.applicableVisitTable));
                if (this.applicableVisitTable[i].addressId == event.target.dataset.name) {
                    if (event.target.checked == true) {
                        this.applicableVisitTable[i].selected = true;
                        this.fiListToBeInitated.push(this.applicableVisitTable[i]);
                        console.log('fiListToBeInitated---' + JSON.stringify(this.fiListToBeInitated));
                        this.setAssignee();
                    } else {

                        this.applicableVisitTable[i].selected = false;

                        this.fiListToBeInitated = this.fiListToBeInitated.filter(item => item.addressId !== event.target.dataset.name);

                    }
                }
            }
            
           
        }
        renderedCallback() {
            const footer = this.template.querySelector('.slds-modal__footer');
            if (footer) {
                footer.style.position = 'sticky';
                footer.style.bottom = '0';
                footer.style.backgroundColor = 'white';
                footer.style.zIndex = '10';
                footer.style.borderTop = '1px solid #d8dde6';
            }
        }
        handleOpenConfModal(){
             getApprovalSataus({ loanId: this.recordId })
                .then((res) => {
                    console.log('res>>>'+res);
                    if(res == 'Soft Rejected 1' || res == 'Soft Rejected 2' ||res =='Hard Rejected') {
                    this.dispatchEvent(
                    new ShowToastEvent({
                    title: 'Error',
                    message: 'Verification cannot be initiated because the loan application status is Rejected',
                    variant: 'Error'
                })
                )
                this.openModal = false;
                return;
                    }
                })
                .catch((error) => {
                    console.error('Error getCurrentUserProfileName --> '+ error);
                });
    
             if(this.fiListToBeInitated==null||this.fiListToBeInitated==undefined||this.fiListToBeInitated.length==0){
                if(this.prodName == 'Home Loan'){
                   this.initiateMessage = 'Please select a visit before initiating the field investigation.';
                }
                else{
                     this.initiateMessage = 'Please select a visit to initiate.';
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                    title: 'Error',
                    message: this.initiateMessage,
                    variant: 'Error'
                })
                )
                

                return;
            }
            console.log('line 727-->>',this.selectedAssignee);
            if(this.prodName == 'Home Loan' && (this.selectedAssignee == null || this.selectedAssignee == undefined || this.selectedAssignee == '')){
                 
                 this.dispatchEvent(
                    new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select an assignee and enter remarks to proceed.',
                    variant: 'Error'
                })
                )

                return;
            }

            this.openModal = true;
        }

        handleOpenConfModalPD(){
            if(this.fiListToBeInitated==null||this.fiListToBeInitated==undefined||this.fiListToBeInitated.length==0){
               this.dispatchEvent(
                   new ShowToastEvent({
                   title: 'Error',
                   message: 'Please select a applicant to initiate PD.',
                   variant: 'Error'
               })
               )
               return;
            }
            var isvalid= true;
            this.fiListToBeInitated.forEach((entry, index) => {
                if (entry.isDirectorReq) {

                    if (  !entry.selectedDirector) {
                        isvalid= false;
                        
                        // return;
                    }
                }
            });
            if(isvalid){
                this.openModalPD = true;
            }else{
                this.dispatchEvent(
                    new ShowToastEvent({
                    title: 'Error',
                    message: 'Please add director for non-individual applicant.',
                    variant: 'Error'
                })
                );
            }
            
       }

        handleInitateAllSelected(){
            if(this.fiListToBeInitated==null||this.fiListToBeInitated==undefined||this.fiListToBeInitated.length==0){
                this.dispatchEvent(
                    new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select a visit to initiate.',
                    variant: 'Error'
                })
                )
                return;
            }
         
            console.log('fiListToBeInitated---'+JSON.stringify(this.fiListToBeInitated));
            console.log('line 796-->>',this.comment);
            initateFieldVisitMultiple({
                'filterdVisitList':JSON.stringify(this.fiListToBeInitated),
                'recordId':this.recordId,
                'waiverComment':this.comment,
                'waiverDocumentId':this.contentDocIWaiver,
                'selectedAssignee':this.selectOption.value,
                'isWaived':false
               
            })
            .then(result=>{
                this.fiListToBeInitated=[];
                if(this.prodName == 'Home Loan'){
                    this.sendToastMessage(SUCCESS_TITLE,FI_CREATION_MSG_HL,SUCCESS_VARIANT)
                }
                else{
                    this.sendToastMessage(SUCCESS_TITLE,FI_CREATION_MSG,SUCCESS_VARIANT)
                }
            if(this.genericInitiate){
                this.progressStep.step5 = true;
                this.setAssignee();
                this.setInvestigationRecords();
                this.getApplicableAddressDetails();
            }
            })
            .catch(error=>{
                    console.log(error);
                })
            this.openModal = false;
        }

        handleInitatePD(){
            if(this.fiListToBeInitated==null||this.fiListToBeInitated==undefined||this.fiListToBeInitated.length==0){
                this.dispatchEvent(
                    new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select a visit to initiate.',
                    variant: 'Error'
                })
                )
                return;
            }
         

            initiateVendorPD({
                'filterdVisitList':JSON.stringify(this.fiListToBeInitated),
                'recordId':this.recordId,
                'selectedAssignee':this.selectOption.value
               
            })
            .then(result=>{
                this.fiListToBeInitated=[];
                this.sendToastMessage(SUCCESS_TITLE,PD_CREATION_MSG,SUCCESS_VARIANT)
                if(this.genericInitiate){
                    this.setAssignee();
                    this.setInvestigationRecords();
                    this.getApplicableAddressDetails();
                }
            })
            .catch(error=>{
                    console.log(error);
            })
            this.openModalPD = false;
        }
        handleConsentWaiverForAll(){
            for(var i=0;i<this.fiListToBeInitated.length;i++){
                if((this.fiListToBeInitated[i].remarks==null||this.fiListToBeInitated[i].remarks==''||this.fiListToBeInitated[i].remarks==undefined)){
                    this.dispatchEvent(
                        new ShowToastEvent({
                        title: 'Error',
                        message: 'Please add remarks',
                        variant: 'error'
                        })
                    )
                    return;
                }
            }
             if(this.fiListToBeInitated==null||this.fiListToBeInitated==undefined||this.fiListToBeInitated.length==0){
               if(this.prodName == 'Home Loan'){
                    this.waivedMessage = 'Please select a visit before waving the field investigation.';
                }
                else{
                    this.waivedMessage = 'Please select a visit to waive.';
            }
                
                this.dispatchEvent(
                    new ShowToastEvent({
                    title: 'Error',
                    message: this.waivedMessage,
                    variant: 'Error'
                })
                )
                return;
            }
            this.isWaiverSelected = true;
            this.openWaiverModal = true;
        }
        previewHandler(event){
            if(event.target.dataset.id == '' || event.target.dataset.id == null || event.target.dataset.id == undefined){
                this.showToastMethod('Error', 'No file uploaded', 'Error');
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
        navigateToRecord(event) {
           window.open(`/${event.currentTarget.dataset.id}`, '_blank');
           /* const pageref = {
            type: 'standard__navItemPage',
            attributes: {
                apiName:'Credit_PD_Form_Page',
                recordId:this.recordId,
                appVerifId :event.target.dataset.id,
                objectApiName: 'Opportunity',
            },
            state:{
                recordId:this.recordId
            }
        };
        this[NavigationMixin.Navigate](pageref);*/
        }
        handleRefresh()
        {
            this.getApplicableAddressDetails();
        }
        handleInterFIToggle(event) {
        this.isInterFIToggled = event.target.checked;

        }
         /*get labelClass() {
        return this.isInterFIToggled ? 'label-true' : 'label-false';
        }*/


        get labelClass() {
          let classes = [];

         
          if (this.prodName === 'Home Loan') {
             classes.push('label-center'); 
           } else {
            classes.push('label-normal'); 
          }

            
          if (this.isInterFIToggled) {
              classes.push('label-true');
            } else {
            classes.push('label-false');
           }

          return classes.join(' ');
        }   

        
        internalFI() {
             getApprovalSataus({ loanId: this.recordId })
                .then((res) => {
                    console.log('res>>>'+res);
                    if(res == 'Soft Rejected 1' || res == 'Soft Rejected 2' ||res =='Hard Rejected') {
                    this.dispatchEvent(
                    new ShowToastEvent({
                    title: 'Error',
                    message: 'Verification cannot be initiated because the loan application status is Rejected',
                    variant: 'Error'
                })
                )
                 this.isModalOpen = false;
                return;
                    }
                })
                .catch((error) => {
                    console.error('Error getCurrentUserProfileName --> '+ error);
                });
            this.isModalOpen = true;
            this.remarks = '';
            this.uploadedFileIds = [];
            this.isSubmitDisabled = true;
        }

        closeModal() {
            this.isModalOpen = false;
        }

        // handleRemarksChange(event) {
        //     this.remarks = event.target.value;
        //     console.log('this.remarks :: ', this.remarks)
        //     this.updateSubmitState();
        // }

        // handleUploadFinished(event) {
        //     this.uploadedFileIds = event.detail.files.map(file => file.documentId);
        //     this.updateSubmitState();
        // }

        updateSubmitState() {
            this.isSubmitDisabled = !(this.remarks && this.uploadedFileIds.length > 0);
        }

        async handleSubmit() {
            if (!this.remarks || this.uploadedFileIds.length === 0) {
            this.showToast('Error', 'Remarks and file upload are required.', 'error');
            return;
            }

            try {
                console.log('filisttoBeInitated---'+JSON.stringify(this.fiListToBeInitated));
                console.log('remarks'+ this.remarks);
                console.log('uploadedFileIds'+this.uploadedFileIds);
                console.log('selectedAssignee'+this.selectedAssignee);
                console.log('this.recordId' + this.recordId);

                this.fiListToBeInitated = this.fiListToBeInitated.map(item => {
                    return {
                            ...item,
                            fiStage: this.reportStatus
                        };
                    });

            console.log('fiListToBeInitated', this.fiListToBeInitated);

            // const loanAppId = await getLoanApplicationId({ addressId: this.selectedRecordId });
            await createApplicationVerification({
                
                // addressId: this.selectedRecordId,
                loanApplicationId: this.recordId,
                fiList: JSON.stringify(this.fiListToBeInitated),
                remarks: this.remarks,
                selectedAssignee:this.selectedAssignee,
                documentIds: this.uploadedFileIds
            });
             console.log('filisttoBeInitated2---'+JSON.stringify(this.fiListToBeInitated));
                console.log('remarks2'+ this.remarks);
                console.log('uploadedFileIds2'+this.uploadedFileIds);
                console.log('selectedAssignee2'+this.selectedAssignee);
                console.log('this.recordId2' + this.recordId);
                

            
            this.showToast('Success', 'Record created!', 'success');
            this.closeModal();

            } catch (error) {
            this.showToast('Error123', error.body?.message || error.message, 'error');
            console.log('error: ' + error.body?.message || error.message);
            
            }
        }

        showToast(title, message, variant) {
            this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
        }

    //updated Ayushi
    async fetchProductContext() {
        try {
            const inputMap = { oppId: this.recordId }; 
            const result = await getProductDetails({ inputMap: inputMap });
            
            this.isHLProduct = result ? result.isHLRelated : false;
        } catch (error) {
            console.error('Error checking product type:', error);
        }
    }
    //end updated    
}