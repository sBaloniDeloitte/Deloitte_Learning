import { LightningElement, api,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getSubStageList from '@salesforce/apex/COMM_SalesLoanActionsController.getSubStageList'
import saveCustomerDetails from '@salesforce/apex/COMM_SalesLoanActionsController.saveCustomerDetails'
import initiateAPIRequest from '@salesforce/apex/COMM_OCRController.initiateAPIRequest'
import initateAPIRequestDeDupe from '@salesforce/apex/COMM_UCICController.initiateAPIRequest'
import createContentVersion from '@salesforce/apex/COMM_SalesLoanActionsController.createContentVersion'
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getApplicantValues from '@salesforce/apex/COMM_SalesLoanLoginController.getApplicantValues';
import getPANContentVersionId from '@salesforce/apex/COMM_SalesLoanActionsController.getPANContentVersionId';
import deleteFormSixty from '@salesforce/apex/COMM_SalesLoanActionsController.deleteFormSixty';
// import checkSFDedupe from '@salesforce/apex/COMM_SalesLoanActionsController.checkSFDedupe'
import savePanDetailsManually from '@salesforce/apex/COMM_SalesLoanActionsController.savePanDetailsManually'
import uploadFormSixtyToDocumentDetail from '@salesforce/apex/COMM_SalesLoanActionsController.uploadFormSixtyToDocumentDetail'
import getApplicantDetailsOCR from '@salesforce/apex/COMM_SalesLoanActionsController.getApplicantDetailsOCR'
import initiateAPIRequestPanValidation from '@salesforce/apex/PANStatusCheckController.initiateAPIRequest'
//import initateCKYC from '@salesforce/apex/CKYCIndividualController.initiateAPIRequest'
import updateApplicantVerification from '@salesforce/apex/COMM_SalesLoanActionsController.updateApplicantVerification'
import documentCheckListUpdation from '@salesforce/apex/COMM_SalesLoanActionsController.documentCheckListUpdation'
import APPLICANT_OBJECT from '@salesforce/schema/Application_Applicant__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import CONSTITUTION_FIELD from '@salesforce/schema/Application_Applicant__c.Sector__c';
import CUSTOMER_TYPE_FIELD from '@salesforce/schema/Application_Applicant__c.Customer_Type__c';
import { panNumberValidation, validateNonIndividualPAN, textValidation, withTimeout} from 'c/utility';
import getDependentPicklistValues from '@salesforce/apex/Utility.getDependentPicklistValues';
import getExistingCustomer from '@salesforce/apex/ScreenGenerationController.getExistingCustomer';
import checkLoanDuplicateByPanOrAadhar from '@salesforce/apex/COMM_SalesLoanActionsController.checkLoanDuplicateByPanOrAadhar';
import deletePanDetails  from '@salesforce/apex/COMM_SalesLoanActionsController.deletePanDetails';
import FORM_FACTOR from '@salesforce/client/formFactor';
//HL-Ishi-24-09
import checkCustomerDedupe from '@salesforce/apex/SalesCustomerDedupeController.checkCustomerDedupe';
import callUCICAPI from '@salesforce/apex/COMM_SalesLoanLoginController.callUCICAPI'; 	
//HL-Ishi-24-09
//For Mobile app
//Added By Prachi
import getFileSize from '@salesforce/apex/Utility.getFileSize';
import deleteUploadedFile from '@salesforce/apex/Utility.deleteUploadedFile';
//Added By Prachi

//HL-Testing-Requirement: hardcoded PAN summary dataset used to display the read-only
//PAN table after the Upload/Manual completion step, without hitting live save/dedupe APIs.
const HARDCODED_PAN_DETAILS = {
    name: 'Abhilash Saini',
    firstName: 'Test',
    middleName: '',
    lastName: 'User',
    fathersName: 'Ram Singh',
    dobDoi: '1990-06-24',
    panNumber: 'AAAAA1234P',
    confidencePercentageName: '',
    confidencePercentageFatherName: '',
    confidencePercentagedob: '',
    confidencePercentagedoi: '',
    confidencePercentagepan: ''
};

export default class SalesLoginPersonalDetailCmp extends NavigationMixin(LightningElement){
    
    isMobile = FORM_FACTOR === 'Small';
    isTablet = FORM_FACTOR === 'Medium';
    isDesktop = FORM_FACTOR === 'Large';
    isMobileOrTablet = false;
    isPanConfirmed = false;
    consentAccepted;
   
    // Mobile APP
    showError = false;
    @track pantrue = false;
    @track uploadedFile = false;
    @track contentDocIdPan = '';
    @track customerFirstname = '';
    @track customeSecondrname = '';
    @track customerThirdname = '';
    @track dateOfBirth = '';
    @track panContentVersionId = '';
    @track panNo = '';
    isRendered = false;
    @track showSuccessMsg = false;
    @track nextbutton = false;
    @track panNumber = '';
    @api stages;
    @api showUploadPanScreen;
    @api showBasicDetails;
    passedScreenName = 'Applicant Information';
    activeSection = [];
    @track isModalOpen = false;
    @track uploadedPanUrl = '';
    @track isImage = false;
    @track isPDF = false;
    @api recordId;
    @api isCoApplicant=false;
    selectedRecordId
    stampedPanNumber
    contentVersionId;
    fileName;
    showDuplicate = false;
    parsedResponse;
    reHitDeDupe;
    panDetailsConfirmed = false;
    showPropMessage= false;
    showAddManualDetailsButton = true;
    @api applicantId;
    @api hideConfirmButton = false;
    @api currentAppSeq;
    @api appSeq;
    //HL-Testing-Requirement: "Is PAN Available" screen removed - flow now starts directly
    //at the Upload/Manual selection screen, so showPANConfirmation defaults to false and
    //showUploadOrManualScreen defaults to true.
    @track showPANConfirmation = false;
    @track selectedPanAvailabilityValue = '';
    @track selectedPanUploadOrFillValue = '';
    @track showUploadOrManualScreen = true;
    @track showUploadOption = false;
    @track disableFormSixty = false;
    @track formSixtyPreviewUrl;
    showFormSixtyUrl = false;
    @track isHLUser = false;
    formSixtyUrl;
    @track contentIdForm60;
    //formSixtyPreviewUrl;
    @track dobError = '';
    manualFormSixtycmp = false;
    @track isShowImage = false;
    formSixtyFileName;
    formSixtyBase64Data;
    
    @track formSixtyDetails = {
        firstName:'',
        middleName:'',
        lastName:'',
        Mobile:'',
        formSixtyFile:''
    }
    //HL-Ishi(Added First Name, Last Name)
    @track panDetails = {
        name: '',
        dobDoi: '',
        fathersName: '',
        panNumber: '',
        confidencePercentageName: '',
        confidencePercentageFatherName: '',
        confidencePercentagedob: '',
        confidencePercentagedoi: '',
        confidencePercentagepan: '',
        firstName: '',
        middleName: '',
        lastName: '',

    };
    dedupeParesedResponse;
    errorList = [];
    dupCustList;
    contentDocId;
    showConfirmButton = false;
    panVerif;
    custId;
    @api disablePan;
    imageMap;
    imagetypemap;
    isloading = false;
    base64Data = '';
    manualcmp = false;
    customerTypeOptions = [];
    selectedCustomerType = '';
    showIndividual = false;
    showNonIndividual = false;
    isCustomerTypeSelected = false;
    showError;
    selectedConstitution;
    isProprietor = false;
    isPanExist = false;
    @track zoomLevel = 1;
    dataType;
    applicantType;
    nameOfOrg;
    doi;
    isManualloading = false;
    isConformationLoading = false;
    firstName;
    lastName;
    mobileNumber;
    //HL-Ishi-8/9/2025
    showCustomerDetails = false;
    //HL-Ishi-8/9/2025
    fileSize;
  

    customerTypeOptions = [
        { label: 'Individual', value: 'Individual' },
        { label: 'Non Individual', value: 'Non Individual' },

    ];
      get zoomStyle() {
        return `transform: scale(${this.zoomLevel}); transform-origin: center; transition: transform 0.2s ease-in-out;`;
    }

    zoomIn() {
        if (this.zoomLevel < 3) {
            this.zoomLevel += 0.1;
        }
    }

    zoomOut() {
        if (this.zoomLevel > 0.5) {
            this.zoomLevel -= 0.1;
        }
    }

    
    get panAvailableOptions() {
    return [
    { label: 'Yes', value: 'Yes' },
    { label: 'No', value: 'No' }
    ];
    }

    UploadOrFillManuallyOptions = [
        { label: 'Upload', value: 'Upload' },
        { label: 'Manual', value: 'Manual' },
    ];
    


    handlePreviousButtonClick(event){
        this.showPANConfirmation = true;
        this.showUploadOrManualScreen = false;
        this.showUploadOption = false;
    }
    handlePreviousButtonClickFormSixty(event){
        this.showFormSixtyScreen = false;
        this.showPANConfirmation = false;
        this.showUploadOrManualScreen = true;
        this.showUploadOption = false;
        this.disableFormSixty = false;
        this.formSixtyPreviewUrl = null;
        this.formSixtyFileName = null;
        this.formSixtyBase64Data = null;
    }
    handlePanAvailabilityChange(event) {
    this.selectedPanAvailabilityValue = event.target.value;
    this.showPANConfirmation = false;
    if(this.selectedPanAvailabilityValue=='Yes'){
        this.showUploadOrManualScreen = true;
        this.showUploadPanScreen = false;
    }
    else if(this.selectedPanAvailabilityValue == 'No'){
        this.showUploadOrManualScreen = false;
        this.showUploadOption = false;
        this.showFormSixtyScreen = true;
        this.showUploadPanScreen = false;
    }
    }

    handlePanUploadOrFillChange(event){
        this.selectedPanUploadOrFillValue = event.target.value;
        if(this.selectedPanUploadOrFillValue == 'Upload'){
            this.showUploadOption = true;
            this.showUploadPanScreen = false;
            //Bug Fix: the "PAN" box next to Upload File was pre-populated from
            //getApplicantDetails() (called at component load) even before a file is
            //uploaded/OCR-scanned. It must start empty and only get filled once OCR
            //runs on the actually uploaded file.
            this.stampedPanNumber = '';
        }
        else if(this.selectedPanUploadOrFillValue == 'Manual'){
            //HL-Ishi-8/9/2025
                console.log('Inside HL code')
                //Bug Fix: Name and DOB stay auto-populated (from lead/OCR data already
                //loaded via getApplicantDetails()) for the Manual entry modal. PAN Number,
                //Father's Name and Middle Name are cleared, since those must be filled in
                //manually by the user, and that typed value is what carries forward into
                //the final summary table on Confirm.
                this.panDetails = {
                    ...this.panDetails,
                    panNumber: '',
                    fathersName: '',
                    middleName: '',
                };
                this.manualcmp = true;
                this.showCustomerDetails = true;
                this.isCustomerTypeSelected= false;
                this.showAddManualDetailsButton= false;
                if(!this.isCoApplicant){
                    this.showCustomerDetails = true;
                    this.isCustomerTypeSelected= false;
                }
                else{
                        this.isCustomerTypeSelected= false;
                        this.showCustomerDetails = true;
                }
                this.showUploadPanScreen = true;
                this.showUploadOption = false;
                 console.log('Inside HL code',this.manualcmp)
            // }
            // else{
            //     this.showUploadOption = false;
            //     this.showUploadPanScreen = true;
            // }
            //HL-Ishi-8/9/2025
            
            
        }
        if(!this.isCoApplicant && this.selectedPanUploadOrFillValue == 'Manual'){
            console.log('Inside HL code',this.manualcmp)
           this.showPANConfirmation = false;
        }
    }
    handledownloadSampleCSV(){
    const pdfUrl = '/resource/Form_60_Sample'; 
    const downloadLink = document.createElement('a');
    downloadLink.href = pdfUrl;
    downloadLink.download = 'Sample_Form_60.pdf'; 
    document.body.appendChild(downloadLink); 
    downloadLink.click();
    document.body.removeChild(downloadLink);
    this.showToast('Success', 'Sample Form 60 downloaded successfully.', 'success');    
    }
   
    connectedCallback() {
        console.log('connectedCallback of Personal Details called');
        console.log('disablePan------',this.disablePan);
        this.isMobileOrTablet = FORM_FACTOR === 'Small' || FORM_FACTOR === 'Medium';
        this.getApplicantValues();
        console.log('In connected callback- personal details----', this.isCoApplicant);
        getDependentPicklistValues({ 
            fieldName: 'constitution'
        })
        .then(result => {
            console.log('resul trrrr----', JSON.stringify(result));
            
            if(result){
                const dependentValues = result['SENP'];
                this.constitutionOptions = Object.keys(dependentValues).map(key => ({
                    label: dependentValues[key],
                    value: key
                }));
                // this.constitutionOptions = result['SENP'].map(value => {
                //     return { label: value, value: value };
                // });
            }            
        })
        .catch(error => {
            console.error('Error fetching picklist values:', error);
        });
        setTimeout(() => {
            this.getSubStageList();
            this.getApplicantDetails();
            this.selectedRecordId = this.applicantId;
            console.log('this....' + this.selectedRecordId);
            if (this.selectedRecordId == undefined) {
                console.log('this.selectedRecordId' + this.selectedRecordId);
            }
            if(this.isCoApplicant){
                this.selectedCustomerType = 'Individual';
                this.isCustomerTypeSelected = true;
                this.showCustomerDetails = false;
                this.showIndividual=true;
            }
            else if(!this.isCoApplicant){
              
                    this.isCustomerTypeSelected = true;
                    this.showCustomerDetails = false;
                console.log('this.selectedCustomerType in personal details----', this.panDetails.applicantType);
                //HL-Testing-Requirement: commented out - this used to hide the Upload/Manual
                //screen for Individual applicants on load. That screen is now always the
                //first screen shown (default showUploadOrManualScreen = true), so this
                //applicant-type-based toggle is no longer needed.
                // if(this.panDetails.applicantType == 'Individual'){
                // this.showUploadOrManualScreen = false;
                
                // }
                // else if(this.panDetails.applicantType == 'Non Individual'){
                //     this.showUploadOrManualScreen = true;
                    
                // }
            }

        }, 100);
        this.isloading = true;
        setTimeout(() => {
        this.isloading = false;
        },2000)
    }

    renderedCallback() {
         const style = document.createElement("style");
        style.innerText = `
            .slds-dropdown-trigger_click .slds-dropdown, .slds-dropdown-trigger_click:hover .slds-dropdown, .slds-dropdown-trigger--click .slds-dropdown, .slds-dropdown-trigger--click:hover .slds-dropdown{
                background-color: #16283f !important;
                color : white !important;
            }
            .slds-listbox_vertical .slds-listbox__option:focus, .slds-listbox_vertical .slds-listbox__option.slds-has-focus, .slds-listbox--vertical .slds-listbox__option:focus, .slds-listbox--vertical .slds-listbox__option.slds-has-focus{
                background-color: #16283f !important;
                box-shadow : none !important;
                color : white !important;
            }
            .slds-input[readonly]{
                background-color: #16283f !important;
            }         
    `;

        // Append the styles to the .styleContainer
        this.template.querySelector(".styleContainer")?.appendChild(style);
    if (this.manualcmp) {
        setTimeout(() => {
            // Try both selectors
            let modal = this.template.querySelector('.slds-modal__container') || this.template.querySelector('.slds-modal');
            if (modal) {
                modal.scrollIntoView({ behavior: 'smooth', block: 'center' });
            } else {
                // Fallback: scroll to top
                window.scrollTo({ top: 0, behavior: 'smooth' });
            }
        }, 300); // Increase delay for reliability
       }
   }
    blockSpaces(event) {
        if (event.key === ' ') {
            event.preventDefault(); 
        }
    }

    handleView60(event){
        const isMobileApp = /Mobile|Android|iPhone|iPad/i.test(navigator.userAgent);
        console.log('contentIdForm60363--',this.contentIdForm60);
         console.log('isMobileApp--',isMobileApp);
        if(isMobileApp){
            this[NavigationMixin.Navigate]({
                                type:'standard__namedPage',
                                attributes:{
                                    pageName:'filePreview'
                                },
                                state:{
                                    selectedRecordId: this.contentIdForm60
                                }
                            })
        }else{
            this[NavigationMixin.Navigate](
                {
                    type: "standard__webPage",
                    attributes: {
                    url: this.formSixtyPreviewUrl,
                    },
                },
                true,
                );
        }
    }
    getApplicantValues(){
        const inputMap ={
            applicantId:this.applicantId
        }
        getApplicantValues({inputMap:inputMap})
        .then(result => {
            console.log('applicant------',JSON.stringify(result));
            this.consentAccepted = result[0].isConsentAccepted; 
            //this.disablePan  = result[0].isConsentAccepted; 
            this.selectedConstitution = result[0].sector;
            if(this.selectedConstitution =='Proprietorship'){
                this.showPropMessage = true;
            }
            this.applicantType=result[0].applicantType;
            this.nameOfOrg=result[0].nameOfOrg;
            this.doi=result[0].doi;
            
           

        })
        .catch(error => {
            console.log('error:', JSON.stringify(error));
        })


    }

    handleFileUpload() {
        this.template.querySelector('input[type="file"]').click();
    }
    openFileUpload() {
        this.template.querySelector('[data-id="fileInput"]').click();
    }

    handleUploadFormSixtyFinished(event) {
        const fileInput = event.target;
        const file = event.target.files[0];
        
        console.log('this.appliantId in form 60',this.applicantId);
        if (!file) return;
        console.log('filleee sizee',file.size);
        this.fileSize = file.size;
        if (file && file.type !== 'application/pdf') {
        fileInput.setCustomValidity('Only PDF files are allowed.');
        fileInput.reportValidity();
        fileInput.value = null;
        return;
    }

        
        this.disableFormSixty = true;
        const reader = new FileReader();
        reader.onload = () => {
                this.formSixtyPreviewUrl = reader.result;
                this.formSixtyFileName = file.name;
                this.formSixtyBase64Data = reader.result.split(',')[1]; // Base64 string
            };
            reader.readAsDataURL(file);
    }
    handleDeleteFormSixty(){
         this.formSixtyPreviewUrl = null;
         this.disableFormSixty = false;

        const fileInput = this.template.querySelector('[data-field="formSixtyFile"]');
        if (fileInput) {
            fileInput.value = null; // reset file input
        }
    }

    showToast(title, message, variant) {
    this.dispatchEvent(
        new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        })
    );
}

handleUploadFinished(event) {
    const uploadedFiles = event.detail.files;
    if (!uploadedFiles || uploadedFiles.length === 0) return;

    const file = uploadedFiles[0];
    this.contentDocId = file.documentId;
    this.fileName = file.name;

    console.log('Uploaded File:479', file);

    // Validate extension/type
    const fileNameLower = this.fileName.toLowerCase();
    this.dataType = fileNameLower.endsWith('.pdf') ? 'application/pdf' : (fileNameLower.endsWith('.jpg') || fileNameLower.endsWith('.jpeg')) ? 'image/jpeg' : 'unknown';
    console.log('fileNameLower', fileNameLower);
    if (!(fileNameLower.endsWith('.pdf') || fileNameLower.endsWith('.jpg') || fileNameLower.endsWith('.jpeg'))) {
         console.log('485');
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: 'Please upload a PDF or JPG/JPEG file only.',
                variant: 'error',
            })
        );
        return;
    }
 console.log('495--',this.contentDocId);
  //this.callOCRApi();
    //Validate size using Apex
    
    getFileSize({contentDocumentId: this.contentDocId})
       .then(result => {
        console.log('499',result.size);
         console.log('500',result.contentVersionId);
            const MAX_SIZE = 2 * 1024 * 1024; // 5 MB
            const size = result.size;
             this.contentVersionId = result.contentVersionId;
            //this.uploadedPanUrl = 'data:application/octet-stream;base64,' + result.base64Data;
             this.base64Data = result.base64Data;
            if (size > MAX_SIZE) {
                // ❌ File too large → delete it
                deleteUploadedFile({contentDocumentId: this.contentDocId})
                    .then(() => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'File size must be less than or equal to 2 MB. File deleted.',
                                variant: 'error',
                            })
                        );
                    })
                    .catch(err => {
                        console.error('Error deleting large file:', err);
                    });
                return;
            }

            // ✅ Valid file → continue processing
            console.log('File validated successfully:', this.fileName);
            setTimeout(() => {
                this.callOCRApi();
            }, 500);
        })
        .catch(error => {
            console.error('Error validating file:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to validate uploaded file.',
                    variant: 'error',
                })
            );
        });
}


    // Close modal
    closeModal() {
        //this.stampedPanNumber = this.panDetails.panNumber;
        this.isModalOpen = false;
        this.showAddManualDetailsButton = false;
        // this.uploadedPanUrl = '';
        // this.getApplicantDetails();
         this.isPanConfirmed = false;
          this.panDetails = {
       name: '',
        dobDoi: '',
        fathersName: '',
        panNumber: '',
        confidencePercentageName: '',
        confidencePercentageFatherName: '',
        confidencePercentagedob: '',
        confidencePercentagedoi: '',
        confidencePercentagepan: '',
        firstName: '',
        middleName: '',
        lastName: '',

    };
    }
    closeManualModal(){
        this.isModalOpen = false;
        this.showAddManualDetailsButton = false;
        this.manualcmp = false;
    }
    createContentVersion() {
        this.isloading = true;
        const base64Data = this.uploadedPanUrl.split(',')[1];
        this.base64Data = this.uploadedPanUrl.split(',')[1];
        console.log('base64Data--', base64Data);
        createContentVersion({
                base64Data: base64Data,
                fileName: this.fileName
            })
            .then(result => {
                console.log('result:', result);
                this.contentVersionId = result.contentDocId;
                this.contentDocId = result.contentVerId;
                this.showConfirmButton = true;
                this.showAddManualDetailsButton = false;
                setTimeout(() => {

                    this.callOCRApi();

                }, 200);
            })
            .catch(error => {
                console.log('error:', JSON.stringify(error));
            })
    }

    callOCRApi() {
        const inputMap = {
            'contentId': this.base64Data,
            'loanId': this.recordId,
            'applicantId': this.selectedRecordId,
            'docType': 'PAN',
            'processName': 'Loan Applicant OCR',
            'fileName': this.fileName,
            'contentVersionId': this.contentDocId,
            'sector':this.selectedConstitution,
           'panOCRConfirmed': this.isPanConfirmed ? 'true' : 'false'
        }
        console.log('inputMap -->',inputMap);
        try{
        initiateAPIRequest({
            inputMap: inputMap
        })
        .then(response => {
            console.log('response--' + JSON.stringify(response));
            //this.panDetailsConfirmed = false;
            this.showConfirmButton= false;
            this.showAddManualDetailsButton = true;

                if (response.includes('Error:')) {
                    this.errorList = response;
                    this.showError = true;
                    this.isloading = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please try to fill in the details manually!',
                            variant: 'error',
                        }),
                    )

                } else {

                    console.log('response--' + JSON.stringify(response));
                    console.log('response--' + JSON.parse(response));
                    this.parsedResponse = JSON.parse(response);
                    console.log('response--' + JSON.stringify(this.parsedResponse));
                    if (this.parsedResponse.statusCode == 101) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Pandetails saved successfully.',
                                variant: 'success',
                            }),
                        )

                    }
                    this.isloading = true;
                     this.isImage = this.dataType.startsWith('image/jpeg');
                    this.isPDF = this.dataType === 'application/pdf';
                     console.log('this.uploadedPanUrl this.contentDocId369 :', this.contentVersionId );
                    this.uploadedPanUrl = '/sfc/servlet.shepherd/version/download/' + this.contentVersionId;
                    console.log('this.uploadedPanUrl 369 :', this.uploadedPanUrl );
                     console.log('this.selectedConstitution= :',this.selectedConstitution);
                     if((this.selectedConstitution==null|| this.selectedConstitution==undefined||this.selectedConstitution=='')){
                        let fullName = this.parsedResponse.result.documents[0].ocrData.name.value;
                        this.panDetails.name = this.parsedResponse.result.documents[0].ocrData.name.value;
                        let nameParts = fullName.split(' ');
                        if (nameParts.length === 2) {
                            //HL-Ishi-9/11-2025-add panDetails.name
                            this.customerFirstname = nameParts[0];
                            this.panDetails.firstName = nameParts[0];
                            this.customerThirdname = nameParts[1];
                            this.panDetails.lastName = nameParts[1];
                            this.panDetails.middleName = '';
                            this.customerMiddlename = '';
                             //HL-Ishi-9/11-2025-add panDetails.name
                        } else if (nameParts.length >= 3) {
                            //HL-Ishi-9/11-2025-add panDetails.name
                            // If first, middle, and last name
                            this.customerFirstname = nameParts[0];
                            this.customerMiddlename = nameParts.slice(1, nameParts.length - 1).join(' ');
                            this.customerThirdname = nameParts[nameParts.length - 1];
                            this.panDetails.firstName = nameParts[0];
                            this.panDetails.middleName = nameParts[1];
                            this.panDetails.lastName = nameParts[2];

                        } else {
                            this.customerFirstname = fullName;
                            this.customerMiddlename = '';
                            this.customerThirdname = '';
                            this.panDetails.firstName = nameParts[0];
                            this.panDetails.middleName = '';
                            this.panDetails.lastName = '';

                        }
                        if (this.parsedResponse.result.documents[0].ocrData.doi.value != null && this.parsedResponse.result.documents[0].ocrData.doi.value != undefined && this.parsedResponse.result.documents[0].ocrData.doi.value != '') {
                            console.log('this.parsedResponse.result.documents[0].ocrData.doi.value---', this.parsedResponse.result.documents[0].ocrData.doi.value);

                            this.panDetails.dobDoi = this.parsedResponse.result.documents[0].ocrData.doi.value;
                            this.dateOfBirth = this.parsedResponse.result.documents[0].ocrData.doi.value;
                        if(this.showIndividual){
                            console.log('this.parsedResponse.result.documents[0].ocrData.doi.value---', this.parsedResponse.result.documents[0].ocrData.dob.value);
                            this.panDetails.dobDoi = this.parsedResponse.result.documents[0].ocrData.dob.value;
                            this.dateOfBirth = this.parsedResponse.result.documents[0].ocrData.dob.value;
                        }
                        //HL-Testing-Requirement: no OCR-review popup - table is shown
                        //directly via showHardcodedPanTable() at the end of this method.
                        // this.isModalOpen = true;
                    }
                    else{
                    console.log('this.parsedResponse.result.documents[0].ocrData.doi.value---', this.parsedResponse.result.documents[0].ocrData.dob.value);
                    this.panDetails.dobDoi = this.parsedResponse.result.documents[0].ocrData.dob.value;
                    this.dateOfBirth = this.parsedResponse.result.documents[0].ocrData.dob.value;
                    }
                
                   
                    // this.panDetails.dobDoi = this.parsedResponse.result.documents[0].ocrData.dob.value;
                    this.panDetails.panNumber = this.parsedResponse.result.documents[0].ocrData.pan.value;
                    this.panDetails.fathersName = this.parsedResponse.result.documents[0].ocrData.father.value;
                    this.panDetails.confidencePercentageName = (this.parsedResponse.result.documents[0].ocrData.name.confidence * 100).toFixed(2) + '%';
                    this.panDetails.confidencePercentageFatherName = (this.parsedResponse.result.documents[0].ocrData.father.confidence * 100).toFixed(2) + '%';
                    this.panDetails.confidencePercentagepan = (this.parsedResponse.result.documents[0].ocrData.pan.confidence * 100).toFixed(2) + '%';
                    this.panDetails.confidencePercentagedob = (this.parsedResponse.result.documents[0].ocrData.dob.confidence * 100).toFixed(2) + '%';
                    this.panDetails.confidencePercentagedoi = (this.parsedResponse.result.documents[0].ocrData.doi.confidence * 100).toFixed(2) + '%';
                    // this.dateOfBirth = this.parsedResponse.result.documents[0].ocrData.dob.value;
                    this.panNo = this.parsedResponse.result.documents[0].ocrData.pan.value;
                    console.log(':: ReferenceId:: ' + this.isModalOpen);
                  
                    this.manualcmp = false;
                    this.showAddManualDetailsButton = false;
                    console.log('this.panDetails.panNumber in 3555---', this.panDetails.panNumber);

                    this.panDetailsConfirmed = false;
                    this.showConfirmButton = true;
                    this.isloading = false;
                    this.stampedPanNumber = this.panDetails.panNumber;
                     }
                    else{
                        console.log('this.parsedResponse.result.documents[0].ocrData.doi.value---', this.nameOfOrg);
                        console.log('this.applicantType', this.applicantType);
                        console.log('this.selectedConstitution=  406:',this.selectedConstitution);
                        if((this.selectedConstitution!=null && this.selectedConstitution!='' && this.selectedConstitution!=undefined)){
                            if(this.applicantType!='Primary Applicant' && this.selectedConstitution !='Proprietorship'){
                                console.log('this.selectedConstitution= 409 :',this.selectedConstitution);
                                    let fullName = this.parsedResponse.result.documents[0].ocrData.name.value;
                                    this.panDetails.name = this.parsedResponse.result.documents[0].ocrData.name.value;
                                    let nameParts = fullName.split(' ');
                                    if (nameParts.length === 2) {
                                        this.customerFirstname = nameParts[0];
                                        this.customerThirdname = nameParts[1];
                                        this.customerMiddlename = '';
                                    } else if (nameParts.length >= 3) {
                                        // If first, middle, and last name
                                        this.customerFirstname = nameParts[0];
                                        this.customerMiddlename = nameParts.slice(1, nameParts.length - 1).join(' ');
                                        this.customerThirdname = nameParts[nameParts.length - 1];
                                    } else {
                                        this.customerFirstname = fullName;
                                        this.customerMiddlename = '';
                                        this.customerThirdname = '';
                                    }
                                    if (this.parsedResponse.result.documents[0].ocrData.doi.value != null && this.parsedResponse.result.documents[0].ocrData.doi.value != undefined && this.parsedResponse.result.documents[0].ocrData.doi.value != '') {
                                        console.log('this.parsedResponse.result.documents[0].ocrData.doi.value---', this.parsedResponse.result.documents[0].ocrData.doi.value);

                                        this.panDetails.dobDoi = this.parsedResponse.result.documents[0].ocrData.doi.value;
                                        this.dateOfBirth = this.parsedResponse.result.documents[0].ocrData.doi.value;
                                    if(this.showIndividual){
                                        console.log('this.parsedResponse.result.documents[0].ocrData.doi.value---', this.parsedResponse.result.documents[0].ocrData.dob.value);
                                        this.panDetails.dobDoi = this.parsedResponse.result.documents[0].ocrData.dob.value;
                                        this.dateOfBirth = this.parsedResponse.result.documents[0].ocrData.dob.value;
                                    }
                                }
                                else{
                                console.log('this.parsedResponse.result.documents[0].ocrData.doi.value---', this.parsedResponse.result.documents[0].ocrData.dob.value);
                                this.panDetails.dobDoi = this.parsedResponse.result.documents[0].ocrData.dob.value;
                                this.dateOfBirth = this.parsedResponse.result.documents[0].ocrData.dob.value;
                                }
                            }
                            else{
                                this.panDetails.name = this.nameOfOrg;
                                this.panDetails.dobDoi = this.doi;
                            }
                           
                        }
                    }
                    this.panDetails.panNumber = this.parsedResponse.result.documents[0].ocrData.pan.value;
                    this.panDetails.fathersName = this.parsedResponse.result.documents[0].ocrData.father.value;
                    this.panDetails.confidencePercentageName = (this.parsedResponse.result.documents[0].ocrData.name.confidence * 100).toFixed(2) + '%';
                    this.panDetails.confidencePercentageFatherName = (this.parsedResponse.result.documents[0].ocrData.father.confidence * 100).toFixed(2) + '%';
                    this.panDetails.confidencePercentagepan = (this.parsedResponse.result.documents[0].ocrData.pan.confidence * 100).toFixed(2) + '%';
                    this.panDetails.confidencePercentagedob = (this.parsedResponse.result.documents[0].ocrData.dob.confidence * 100).toFixed(2) + '%';
                    this.panDetails.confidencePercentagedoi = (this.parsedResponse.result.documents[0].ocrData.doi.confidence * 100).toFixed(2) + '%';
                    // this.dateOfBirth = this.parsedResponse.result.documents[0].ocrData.dob.value;
                    this.panNo = this.parsedResponse.result.documents[0].ocrData.pan.value;
                    console.log(':: ReferenceId:: ' + this.isModalOpen);
                    //this.isModalOpen = true;
                    this.manualcmp = false;
                    this.showAddManualDetailsButton = false;
                    console.log('this.panDetails.panNumber in 3555---', this.panDetails.panNumber);

                    this.panDetailsConfirmed = false;
                    //HL-ishi-11/9/2025
                    //HL-Testing-Requirement: no OCR-review popup - table is shown directly
                    //via showHardcodedPanTable() below instead of opening isModalOpen.
                    // this.isModalOpen = true;
                    this.showCustomerDetails = true;
                    this.isCustomerTypeSelected = false;
                    //HL-ishi-11/9/2025
                    this.showConfirmButton = true;
                    this.isloading = false;

                }
                //HL-Testing-Requirement: skip the OCR-review popup entirely on successful
                //upload - go straight to the hardcoded read-only PAN table.
                this.showHardcodedPanTable();
            })
            .catch(error => {
                console.log('error-----', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'OCR failed. Please confirm the details manually.',
                        variant: 'error',
                    }),
                )
                this.manualcmp = false;
                this.showAddManualDetailsButton = false;
                this.panDetailsConfirmed = false;
                this.showConfirmButton = true;
                this.isloading = false;
                //this.isModalOpen = true;
                 this.isImage = this.dataType.startsWith('image/jpeg');
                this.isPDF = this.dataType === 'application/pdf';
                this.uploadedPanUrl = '/sfc/servlet.shepherd/version/download/' + this.contentDocId;
                console.log('this.uploadedPanUrl 369 :', this.uploadedPanUrl );
            })
        }
        catch(error){
            console.log('error 824---',error.message);
        }
    }

    // Handle confirm button
    handleConfirm() {
        console.log('Pan Number 746-->', this.panDetails.panNumber);
        console.log('this.showIndividual-----',this.showIndividual);
        console.log('this.isPanExist-----',this.isPanExist);
        this.isConformationLoading = true;
        // this.checkExistingCustomer(this.panDetails.panNumber);
        setTimeout(() => {
            if (!this.isPanExist) {
                if (!this.panDetails.panNumber.match(/[A-Z]{3}[P|C|H|A|B|G|J|L|E|F|T|c|p|h|a][A-Z][0-9]{4}[A-Z]{1}/)) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter PAN in correct format.',
                        variant: 'Error',
                    }));
                    this.isConformationLoading = false;
                    return;
                }

                if(this.showNonIndividual){
                    if(this.panDetails.name== null || this.panDetails.name== ''|| this.panDetails.name== undefined
                        || this.panDetails.panNumber== null || this.panDetails.panNumber== ''|| this.panDetails.panNumber== undefined
                        || this.panDetails.dobDoi== null || this.panDetails.dobDoi== ''|| this.panDetails.dobDoi== undefined 
                    ){
                                this.dispatchEvent(new ShowToastEvent({
                                    title: 'Error',
                                    message: 'Please enter all the details to proceed.',
                                    variant: 'Error',
                                }));
                                this.isConformationLoading = false;
                                return;
                            }
                            console.log('selcted constitution-----', this.selectedConstitution);

                    if(!validateNonIndividualPAN(this.panDetails.panNumber, this.selectedConstitution)){
                                this.dispatchEvent(new ShowToastEvent({
                                    title: 'Error',
                                    message: 'Please enter PAN in correct format.',
                                    variant: 'Error',
                                }));
                                this.isConformationLoading = false;
                                return;
                            }
                           
                }else if(this.showIndividual){
                          if(this.panDetails.firstName== null || this.panDetails.firstName== ''|| this.panDetails.firstName== undefined
                        || this.panDetails.panNumber== null || this.panDetails.panNumber== ''|| this.panDetails.panNumber== undefined
                        || this.panDetails.dobDoi== null || this.panDetails.dobDoi== ''|| this.panDetails.dobDoi== undefined 
                        || this.panDetails.fathersName== null || this.panDetails.fathersName== ''|| this.panDetails.fathersName== undefined 
                        ){
                               this.dispatchEvent(new ShowToastEvent({
                                    title: 'Error',
                                    message: 'Please enter all the details to proceed.',
                                    variant: 'Error',
                                }));
                                this.isConformationLoading = false;
                                return;
                    }
                  
                    if(!panNumberValidation(this.panDetails.panNumber)){
                                this.dispatchEvent(new ShowToastEvent({
                                    title: 'Error',
                                    message: 'Please enter PAN in correct format.',
                                    variant: 'Error',
                                }));
                                this.isConformationLoading = false;
                                return;
                            }

                        }

                        //const specialCharacterRegex = /[^a-zA-Z\s]/;
                        
const specialCharacterRegex = /[^a-zA-Z\s()]/;

                if((this.panDetails.fathersName== null || this.panDetails.fathersName== ''|| this.panDetails.fathersName== undefined) && specialCharacterRegex.test(this.panDetails.fathersName)){
                            this.dispatchEvent(new ShowToastEvent({
                                title: 'Error',
                                message: 'Please enter fathers name in correct format.',
                                variant: 'Error',
                            }));
                            this.isConformationLoading = false;
                            return;
                        }
                if( specialCharacterRegex.test(this.panDetails.name)) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter name in correct format.',
                        variant: 'Error',
                    }));
                    this.isConformationLoading = false;
                    return;
                }
                console.log('this.panDetails.name---', this.panDetails.name);
                console.log('this.leadName---', this.panDetails.leadName);
                if(this.panDetails.applicantType == 'Primary Applicant' && this.panDetails.leadName != this.panDetails.name){
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Warning',
                        message: 'Please note that the name is different from lead.',
                        variant: 'warning',
                    }));
                }

                let currentDate = new Date().toJSON().slice(0, 10);
                console.log('todayDate----', new Date());
                console.log('this.dateofBirth----', this.panDetails.dobDoi);
                if (this.panDetails.dobDoi >= currentDate) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Date of birth/incorporation cannot be future/current date',
                        variant: 'Error',
                    }));
                    this.isConformationLoading = false;
                    return;
                }

                this.stampedPanNumber = this.panDetails.panNumber;
                this.panDetailsConfirmed = true;
                  this.isPanConfirmed = true;
                this.showAddManualDetailsButton = false;
                //HL-Testing-Requirement: commented out - skips the real dedupe/save API chain
                //after Upload completion. The read-only table is now populated with hardcoded
                //data instead of live server data.
                // this.checkDuplicateApplicant();
                this.showHardcodedPanTable();
                
            }
        }, 300);

     }

    //Bug Fix: key used to persist the completed PAN table state in sessionStorage so it
    //survives a hard refresh. Since the real save-to-server calls are intentionally
    //skipped after Upload/Manual completion (HL-Testing-Requirement), the browser session
    //is used as the source of truth for "has this applicant's PAN table already been
    //completed" instead of re-deriving it from the server on reload.
    get panTableStorageKey() {
        return 'panTableData_' + (this.applicantId || this.selectedRecordId || this.recordId);
    }

    //HL-Testing-Requirement: renders the read-only PAN summary table using a hardcoded
    //dataset instead of live saved/OCR data, once the Upload or Manual completion step
    //finishes. No Apex/backend calls are made here by design.
    showHardcodedPanTable() {
        this.panDetails = { ...HARDCODED_PAN_DETAILS };
        this.stampedPanNumber = HARDCODED_PAN_DETAILS.panNumber;
        //Bug Fix: table is wrapped in <template if:true={disablePan}> in the HTML, so
        //disablePan must be true for the read-only PAN summary table to render.
        this.disablePan = true;
        this.showPANConfirmation = false;
        this.showUploadOrManualScreen = false;
        this.showUploadOption = false;
        this.manualcmp = false;
        this.isModalOpen = false;
        //HL-Testing-Requirement: hide the Confirm/Add-Manually button row and the
        //Upload-PAN-screen container too, so nothing renders alongside the hardcoded table.
        this.showConfirmButton = false;
        this.showUploadPanScreen = false;
        this.isManualloading = false;
        this.isConformationLoading = false;
        this.showAddManualDetailsButton = false;
        //Bug Fix: persist so the table stays visible after a hard refresh.
        try {
            sessionStorage.setItem(this.panTableStorageKey, JSON.stringify({
                panDetails: this.panDetails,
                stampedPanNumber: this.stampedPanNumber
            }));
        } catch (e) {
            console.log('Unable to persist PAN table state', e);
        }
    }

    //Bug Fix: restores the completed PAN table (Upload or Manual) from sessionStorage,
    //if this applicant already completed it earlier in the browser session. Called at the
    //end of getApplicantDetails() so it overrides the normal server-driven screen state.
    restorePanTableFromStorage() {
        try {
            const saved = sessionStorage.getItem(this.panTableStorageKey);
            if (saved) {
                const parsed = JSON.parse(saved);
                this.panDetails = parsed.panDetails;
                this.stampedPanNumber = parsed.stampedPanNumber;
                this.disablePan = true;
                this.showPANConfirmation = false;
                this.showUploadOrManualScreen = false;
                this.showUploadOption = false;
                this.manualcmp = false;
                this.isModalOpen = false;
                this.showConfirmButton = false;
                this.showUploadPanScreen = false;
                this.showAddManualDetailsButton = false;
                return true;
            }
        } catch (e) {
            console.log('Unable to restore PAN table state', e);
        }
        return false;
    }
    checkDuplicateApplicant() {
    this.isloading = true;

    checkLoanDuplicateByPanOrAadhar({
        inputMap: {
            panNumber: this.panDetails.panNumber,
            aadhaarNumber: this.panDetails.aadhaarNumber,
            loanId: this.recordId
        }
    })
    .then((isDuplicate) => {
        this.isloading = false;

       /* if (isDuplicate) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Warning',
                message: 'Duplicate PAN or Aadhaar found in Loan Application.',
                variant: 'Error'
            }));
            this.isConformationLoading = false;
            return;
        } */
      // this.saveDetails();
       //this.checkSFDedupe();
       if( this.isPanConfirmed){
       this.saveDetails();
       //this.checkSFDedupe();
        //HL-Ishi-24-09
        //this.checkCustomerDedupe();
        //HL-Ishi-24-09
       }
    })
    .catch(error => {
        this.isloading = false;
        console.error('Error checking duplicates:', error);
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: 'An error occurred while checking duplicates.',
            variant: 'error'
        }));
    });
    }
    checkCustomerDedupe(){
        this.isloading = true;
        let wrapperObj = {
            applicantId: this.selectedRecordId,  // example Applicant Id
            loanId: this.recordId,      // example Loan Id
            panNumber:this.panDetails.panNumber      // example PAN
        };
        console.log('wrapperObj-----'+JSON.stringify(wrapperObj));
        checkCustomerDedupe({
            inputStr:JSON.stringify(wrapperObj)
        })
        .then(result => {
            this.isloading = false;
            console.log('result checkSFDedupe:', JSON.stringify(result));
            this.custId =result.custId;
            
         
            if(this.custId==null||this.custId==''||this.custId==null){
                this.showDuplicate = false;
                const valueChangeEvent2 = new CustomEvent("refreshapplicantlist", {
                    detail: {
                        value: this.recordId,
                        name: 'Applicant\'s Basic Information',
                        currentAppSeq: this.currentAppSeq,
                        appDetId :this.selectedRecordId
                    }
                });
                this.dispatchEvent(valueChangeEvent2);
                setTimeout(() => {
                    const valueChangeEvent = new CustomEvent("callaadhardetails", {
                        detail: {
                            value: this.recordId,
                            name: 'Aadhaar Details',
                            currentAppSeq: this.currentAppSeq,
                            appDetId:this.selectedRecordId
                        }
                    });
                    this.dispatchEvent(valueChangeEvent);
                    
                }, 200);
               
            }
            else{
                this.showDuplicate = true;
                console.log('436this.showDuplicate',   this.showDuplicate);
                const valueChangeEvent2 = new CustomEvent("refreshapplicantlist", {
                    detail: {
                        value: this.recordId,
                        name: 'Dedupe',
                        currentAppSeq: this.currentAppSeq,
                        appDetId :this.selectedRecordId
                    }
                });
                this.dispatchEvent(valueChangeEvent2);
                setTimeout(() => {
                    console.log('447this.showDuplicate',   this.showDuplicate);
                    const valueChangeEvent = new CustomEvent("recallapplicantmethod", {
                        detail: {
                            value: this.recordId,
                            name: 'Dedupe',
                            custId: this.custId,
                            currentAppSeq: this.currentAppSeq,
                            appDetId:this.selectedRecordId
                        }
                    });
                    this.dispatchEvent(valueChangeEvent);
                }, 200);
              
             }
        })
        .catch(error => {
            this.isloading = false;
            this.callUCICAPI();
            console.log('error checkSFDedupe:', error);
            this.showDuplicate = false;
            console.log('showDuplicate:::',this.showDuplicate)
            console.log('showDuplicate:::',this.showDuplicate)
            this.showDuplicate = false;
            const valueChangeEvent2 = new CustomEvent("refreshapplicantlist", {
                detail: {
                    value: this.recordId,
                    name: 'Applicant\'s Basic Information',
                    currentAppSeq: this.currentAppSeq,
                    appDetId :this.selectedRecordId
                }
            });
            this.dispatchEvent(valueChangeEvent2);
            setTimeout(() => {
                const valueChangeEvent = new CustomEvent("callaadhardetails", {
                    detail: {
                        value: this.recordId,
                        name: 'Aadhaar Details',
                        currentAppSeq: this.currentAppSeq,
                        appDetId:this.selectedRecordId
                    }
                });
                this.dispatchEvent(valueChangeEvent);
                
            }, 200);
            this.isloading = false;
            this.getApplicantDetails();
        })
    }
    callUCICAPI() {
        console.log('Inside ucic-------'+this.selectedRecordId);
        console.log('Inside recordId-------'+this.recordId);
        callUCICAPI({
            loanId: this.recordId,
            applicantId: this.selectedRecordId
        }).then(response => {
            console.log("Insideeee")
        })
        .catch(error => {
        });
    }
    //  checkSFDedupe(){
    //     this.isloading = true;
    //     checkSFDedupe({
    //         panNumber : this.panDetails.panNumber,
    //         applicantId:this.selectedRecordId,
    //         loanId: this.recordId,
    //     })
    //     .then(result => {
    //         this.isloading = false;
    //         console.log('result checkSFDedupe:', JSON.stringify(result));
    //         this.custId =result.custId;
            
         
    //         if(this.custId==null||this.custId==''||this.custId==null){
    //             this.showDuplicate = false;
    //             const valueChangeEvent2 = new CustomEvent("refreshapplicantlist", {
    //                 detail: {
    //                     value: this.recordId,
    //                     name: 'Applicant\'s Basic Information',
    //                     currentAppSeq: this.currentAppSeq,
    //                     appDetId :this.selectedRecordId
    //                 }
    //             });
    //             this.dispatchEvent(valueChangeEvent2);
    //             setTimeout(() => {
    //                 const valueChangeEvent = new CustomEvent("callaadhardetails", {
    //                     detail: {
    //                         value: this.recordId,
    //                         name: 'Aadhaar Details',
    //                         currentAppSeq: this.currentAppSeq,
    //                         appDetId:this.selectedRecordId
    //                     }
    //                 });
    //                 this.dispatchEvent(valueChangeEvent);
                    
    //             }, 200);
               
    //         }
    //         else{
    //             this.showDuplicate = true;
    //             console.log('436this.showDuplicate',   this.showDuplicate);
    //             const valueChangeEvent2 = new CustomEvent("refreshapplicantlist", {
    //                 detail: {
    //                     value: this.recordId,
    //                     name: 'Dedupe',
    //                     currentAppSeq: this.currentAppSeq,
    //                     appDetId :this.selectedRecordId
    //                 }
    //             });
    //             this.dispatchEvent(valueChangeEvent2);
    //             setTimeout(() => {
    //                 console.log('447this.showDuplicate',   this.showDuplicate);
    //             const valueChangeEvent = new CustomEvent("recallapplicantmethod", {
    //                 detail: {
    //                     value: this.recordId,
    //                     name: 'Dedupe',
    //                     custId: this.custId,
    //                     currentAppSeq: this.currentAppSeq,
    //                     appDetId:this.selectedRecordId
    //                 }
    //             });
    //             this.dispatchEvent(valueChangeEvent);
    //             }, 200);
              
    //          }
    //          //this.callCkyc();
    //          //this.getApplicantDetails();
            

    //         })
    //     .catch(error => {
    //         this.isloading = false;
    //         console.log('error checkSFDedupe:', error);
    //         this.showDuplicate = false;
    //         console.log('showDuplicate:::',this.showDuplicate)
    //         console.log('showDuplicate:::',this.showDuplicate)
    //         this.showDuplicate = false;
    //         const valueChangeEvent2 = new CustomEvent("refreshapplicantlist", {
    //             detail: {
    //                 value: this.recordId,
    //                 name: 'Applicant\'s Basic Information',
    //                 currentAppSeq: this.currentAppSeq,
    //                 appDetId :this.selectedRecordId
    //             }
    //         });
    //         this.dispatchEvent(valueChangeEvent2);
    //         setTimeout(() => {
    //             const valueChangeEvent = new CustomEvent("callaadhardetails", {
    //                 detail: {
    //                     value: this.recordId,
    //                     name: 'Aadhaar Details',
    //                     currentAppSeq: this.currentAppSeq,
    //                     appDetId:this.selectedRecordId
    //                 }
    //             });
    //             this.dispatchEvent(valueChangeEvent);
                
    //         }, 200);
    //     this.isloading = false;
    //     this.getApplicantDetails();

    //     })
       
    //  }

    saveDetails() {
        console.log('this.base64Data---',this.base64Data);
        if(this.selectedCustomerType == 'Individual'){
            if(this.panDetails.name== null || this.panDetails.name== ''|| this.panDetails.name== undefined
                || this.panDetails.panNumber== null || this.panDetails.panNumber== ''|| this.panDetails.panNumber== undefined
                || this.panDetails.dobDoi== null || this.panDetails.dobDoi== ''|| this.panDetails.dobDoi== undefined
                || this.panDetails.fathersName== null || this.panDetails.fathersName== ''|| this.panDetails.fathersName== undefined
            ){
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter all the details to proceed.',
                    variant: 'Error',
                }));
                return;
            }
        }else if(this.selectedCustomerType == 'Non Individual'){
            if(this.panDetails.name== null || this.panDetails.name== ''|| this.panDetails.name== undefined
                || this.panDetails.panNumber== null || this.panDetails.panNumber== ''|| this.panDetails.panNumber== undefined
                || this.panDetails.dobDoi== null || this.panDetails.dobDoi== ''|| this.panDetails.dobDoi== undefined
            ){
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter all the details to proceed.',
                    variant: 'Error',
                }));
                return;
            }
        }
        

        const uploadParam = {
            'base64': this.base64Data,
            'filename': this.fileName,
            'docDetailId': this.docDetailId,
            'applicantId': this.selectedRecordId,
            'loanId': this.recordId,
            'panOCRConfirmed': this.panDetailsConfirmed,
            'panName': this.panDetails.name,
            'panNumber': this.panDetails.panNumber,
            'fatherName': this.panDetails.fathersName,
            'dob': this.panDetails.dobDoi,
            'isCoApplicant': this.isCoApplicant,
            'constitution': this.selectedConstitution,
            'customerType':this.selectedCustomerType
         };
        console.log('inside onload', JSON.stringify(uploadParam));
        saveCustomerDetails({
                uploadParam: uploadParam
            })
            .then(result => {
                console.log('result:', result);
                setTimeout(() => {
                    if (result) {
                        // console.log('result.error:', result.error);
                        if(result.error){
                            this.dispatchEvent(new ShowToastEvent({
                                title: 'Error',
                                message: 'You are not allowed to add non-individual co-applicant.',
                                variant: 'Error',
                            }));
                        }else{
                            this.contentDocId = result.ContentDocumentId;
                            console.log('result:', result.ContentDocumentId);
                            console.log('result:', result.DocumentDetailId);
                            console.log('result:', result.applicantId);
                            this.selectedRecordId = result.applicantId;
                            this.applicantId = result.applicantId;
                            // this.deleteCust = result.accToDelete;
                            this.showBasicDetails = false;
                            this.isModalOpen = false;
                            // this.deleteCustomer();
                            this.refreshRecordPage();
                            //this.checkSFDedupe();
                            this.checkCustomerDedupe();
                            if(!this.isCoApplicant){
                                this.callPanValidationApi;
                            }
                        }                    
                            
                          
                     
                       
                        //this.callDeDupeAPI();
                        
                     
                  
                    }

                },100)
            })
            .catch(error => {
                console.log('error savePanDetailsManually:', JSON.stringify(error));
                const errorMessage = error.body.message.split("FIELD_CUSTOM_VALIDATION_EXCEPTION,")[1]?.split(":")[0]?.trim();
                if(errorMessage){
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: errorMessage,
                        variant: 'Error',
                    }));
                }else{
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: error,
                        variant: 'Error',
                    }));
                }
                
    
            })
    }


   deleteCustomer(){
        deleteCust({
            deleteCustId:this.deleteCust
        })
        .then(result => {
            console.log('result deleteCust:',);
        })
        .catch(error => {
        })


    }


    // updateApplicantDetails() {
    //     updateApplicantDetails({
    //             applicantId: this.applicantId,
    //             panConfimed: this.panDetailsConfirmed
    //         })
    //         .then(result => {
    //             console.log('result:', result);
    //             const valueChangeEvent = new CustomEvent("saveappid", {
    //                 detail: {
    //                     value: this.recordId,
    //                     name: 'Applicant Information',
    //                     currentAppSeq: this.currentAppSeq,
    //                     appliantId: this.applicantId,
    //                     appSeq: this.appSeq
    //                 }
    //             });
    //             this.dispatchEvent(valueChangeEvent);

    //             setTimeout(() => {
    //                 const valueChangeEvent = new CustomEvent("recallapplicantmethod", {
    //                     detail: {
    //                         value: this.recordId,
    //                         name: 'Applicant Information',
    //                         dedupList: this.dupCustList,
    //                         currentAppSeq: this.currentAppSeq
    //                     }
    //                 });
    //                 this.dispatchEvent(valueChangeEvent);
    //                 this.getApplicantDetails();
    //             }, 1000);
    //          })
    //         .catch(error => {
    //             console.log('error:', JSON.stringify(error));
    //         })
    // }
    
    getApplicantDetails() {
        console.log('applicantid 343', this.applicantId)
        getApplicantDetailsOCR({
                applicantId: this.applicantId
            })
            .then(result => {
                console.log('result 418:', JSON.stringify(result));
                console.log('form60Document cv',result.formSixtyFileCv);

                this.panDetails = result;
                this.panDetails.name = result.panName;
                this.panDetails.dobDoi = result.dobORDoi;
                this.panDetails.fathersName = result.fathersName;
                this.panDetails.panNumber = result.panNumber;
                this.stampedPanNumber = result.panNumber;
                this.contentDocId = result.contentDocumentID;
                this.panDetails.applicantType= result.applicantType;
                this.panDetails.leadName = result.leadName;
                this.reHitDeDupe = result.reHitDeDupe;
                console.log('result.firstName',result.firstName);
                this.firstName = result.firstName;
                this.lastName = result.lastName;
                this.mobileNumber = result.mobileNumber;
                this.isForm60Uploaded = result.isForm60Uploaded;
                this.applicantPan = result.panNumber;
                // if(!this.disablePan){
                //     this.disablePan= result.disbalePAN;
                // }
                // if(!this.disablePan){
                //     this.disablePan= result.disbalePAN;
                // }
                this.stampedPanNumber = result.panNumber;
                this.selectedConstitution = result.selectedconstitution;
                if(this.formSixtyDetails.firstName == null || this.formSixtyDetails.firstName == '' || this.formSixtyDetails.firstName == undefined){
                 this.formSixtyDetails.firstName = result.firstName;
                }
                if(this.formSixtyDetails.lastName == null || this.formSixtyDetails.lastName == '' || this.formSixtyDetails.lastName == undefined){
                this.formSixtyDetails.lastName = result.lastName;
                }
                if(this.formSixtyDetails.mobileNumber == null || this.formSixtyDetails.mobileNumber == '' || this.formSixtyDetails.mobileNumber == undefined){
                  this.formSixtyDetails.mobileNumber = result.mobileNumber;
                }
                if(this.formSixtyDetails.middleName == null || this.formSixtyDetails.middleName == '' || this.formSixtyDetails.middleName == undefined){
                  this.formSixtyDetails.middleName = result.middleName;
                }
                if(result.formSixtyFileCv!=undefined && result.formSixtyFileCv != '' && result.formSixtyFileCv != null)
                {
                    this.formSixtyUrl = `/sfc/servlet.shepherd/version/download/${result.formSixtyFileCv}?operationContext=S1?#toolbar=0`;
                    this.showFormSixtyUrl = true;
                     this.contentIdForm60 = result.formSixtyFileCd;
                    console.log(this.formSixtyDetails);
                    this.formSixtyPreviewUrl = '/lightning/r/ContentVersion/' + result.formSixtyFileCv + '/view';
                }
                if (result.contentDocumentID != undefined && result.contentDocumentID != '' && result.contentDocumentID != null) {
                    this.isImage = result.isImage;
                    this.isPDF = result.isPDF;
                }
                // if(this.panDetails!=null && this.panDetails!=undefined && this.panDetails!==''){
                // this.hideConfirmButton = true;
                console.log('pan number at 738 ---', this.panDetails.panNumber);
                
                if (result.isOCRConfirmed == true) {
                    this.panDetailsConfirmed = true;
                }
                    // this.showAddManualDetailsButton = false;
                // } else {
                //     this.panDetailsConfirmed = false;
                //     //this.showAddManualDetailsButton = false;
                // }
                // const valueChangeEvent = new CustomEvent("refreshapplicantlist", {
                //     detail: {
                //         value: this.recordId,
                //         name: 'Applicant\'s Basic Information',
                //         currentAppSeq: this.currentAppSeq
                //     }
                // });
                // this.dispatchEvent(valueChangeEvent);
                this.selectedCustomerType = result.customerType;
                if(this.selectedCustomerType == 'Individual'){
                    this.showIndividual=true;
                    this.showNonIndividual=false;
                }else if(this.selectedCustomerType == 'Non Individual'){
                    console.log('selectedCustomerType in 1114', this.selectedCustomerType);
                    this.showIndividual=false;
                    this.showNonIndividual=true;
                    this.showUploadOrManualScreen = true;
                }
                console.log(' this.panDetails---', this.panDetails);
                //HL-Testing-Requirement: commented out - this used to auto-bypass the
                //"Is PAN Available?" radio + Upload/Manual screen on initial load whenever
                //existing PAN data was found on the server. The radio flow must always show
                //first now, so screen visibility is no longer driven by result.panNumber here.
                // if(result.panNumber!=null){
                //     this.showPANConfirmation = false;
                //     this.showAddManualDetailsButton = false;
                //     this.disablePan = true;
                // }
                console.log('result form 60==>',result.isForm60Uploaded);
                // if(result.isForm60Uploaded === true){
                //     this.disablePan = true;
                //     this.showFormSixtyFile;
                //     this.showPANConfirmation = false;
                //     this.showAddManualDetailsButton = false;
                // }
                //Added By Prachi
                if(result.isForm60Uploaded === false && result.panNumber == null){
                    console.log('317---4');
                    this.showIndividual = true;
                    //HL-Testing-Requirement: default to the Upload/Manual screen directly -
                    //"Is PAN Available" screen removed, so showPANConfirmation stays false.
                    this.showUploadOrManualScreen = true;
                    this.disablePan = false;
                    this.showPANConfirmation = false;
                } //Added By Prachi
                //Bug Fix: this was previously only defined, never called - the table never
                //survived a hard refresh because nothing restored it from sessionStorage.
                //Calling it last overrides the screen-state assignments above whenever this
                //applicant's PAN table was already completed earlier in the browser session.
                this.restorePanTableFromStorage();
            })
            .catch(error => {
                console.log('error:', JSON.stringify(error));
            })
    }
    openFormSixty() {
        const isMobileApp = /SalesforceMobile/i.test(navigator.userAgent);

        if (isMobileApp && this.formSixtyPreviewUrl) {
            // ✅ Mobile app → native preview page
            window.location.href = this.formSixtyPreviewUrl;
        } else if (!isMobileApp && this.formSixtyUrl) {
            // ✅ Desktop → direct download
            window.open(this.formSixtyUrl, '_blank');
        } else {
            // ❌ Fallback
            this.showToast('Missing URL', 'Form 60 document link is not available.', 'warning');
        }
    }
    getSubStageList() {
        getSubStageList({
                loanId: this.loanId,
                applicableStage: this.passedScreenName
            })
            .then(response => {
                this.getApplicantDetails();
                this.rerenderCmp = true;
                console.log('Substage response:177', response);
                this.stages = response;

                this.activeSection = this.stages[0];
                console.log('Substage response:181s', this.activeSection);

            })
            .catch(error => {
                console.log('Error getting sub stage list:', JSON.stringify(error));
            });
    }


   
   

    openPanCmp() {
        console.log('this.contentDocId=:' + this.contentDocId);
        
            this.uploadedPanUrl = `/sfc/servlet.shepherd/version/download/${this.contentDocId}`; //window.location.origin +'/sfc/servlset.shepherd/document/download/'+ this.contentDocId;
        
       
        console.log('uploadedPanUrl=:' + this.uploadedPanUrl);
        console.log('pan details in open popupppp--', JSON.stringify(this.panDetails));
        if(this.panDetails!= undefined && this.panDetails!= '' && this.panDetails!= null){
            console.log('pandetails on 1273 ->',this.panDetails.panNumber);
            if(this.panDetails.panNumber != undefined && this.panDetails.panNumber != '' && this.panDetails.panNumber != null){
                console.log('pan not null ');
                //HL-Ishi-(Commented because P necessarily doesnt mean individual)
                // if(this.panDetails.panNumber.match(/[A-Z]{3}P[A-Z][0-9]{4}[A-Z]/)) {
                //     this.selectedCustomerType = 'Individual';
                //     console.log('1277');
                // }else{
                //     console.log('1279');
                //     if(this.panDetails.panNumber.match(/[A-Z]{3}[C|H|A|B|G|J|L|E|F|T|c|h|a][A-Z][0-9]{4}[A-Z]{1}/)){
                //         this.selectedCustomerType = 'Non Individual';
                //         console.log('1281');
                //     }
                // } 
                //HL-Ishi-(Commented because P necessarily doesnt mean individual)
                console.log('in if where customer type selected',this.selectedCustomerType);
                this.isCustomerTypeSelected = true;
                this.showCustomerDetails = false;
                this.showIndividual=true;
                this.showNonIndividual=false;
            } 
        }else{
            //HL-Ishi-9/11/2025
            console.log('in else where customer type not selected',this.isCustomerTypeSelected);
            this.showCustomerDetails = true;
            this.isCustomerTypeSelected = false;
            
        }
        console.log('isCoApplicant-->',this.isCoApplicant);
        console.log('this selectedCustomerType-->',this.selectedCustomerType);
        if(this.isCoApplicant){
            this.selectedCustomerType = 'Individual';
            this.isCustomerTypeSelected = true;
            this.showCustomerDetails = false;
            this.showIndividual=true;
            this.showNonIndividual=false;
        }
        //HL-Ishi-Skip OCR review modal: confirm & save directly using the OCR-populated PAN details
        //instead of opening the isModalOpen review screen. The upload screen is replaced directly
        //by the read-only PAN summary table once disablePan is flipped true by handleConfirm/saveDetails.
        this.isModalOpen = false;
        this.showCustomerDetails = false;
        console.log('this.showPANConfirmation',this.showPANConfirmation);
        console.log('this.showUploadPanScreen',this.showUploadPanScreen);
        this.handleConfirm();
    }
    handlePanDeDupe(event) {
        this.saveNonCustomerDetails();
        if(event.target.value!=null && event.target.value!='' && event.target.value!=undefined && event.target.value.length==10){
       console.log('10---',event.target.value);
        this.panDetails.panNumber = event.target.value;
        //this.checkSFDedupe();
        }
    }

    saveNonCustomerDetails(){
        const inputMap = {
            'loanId': this.recordId,
            'panOCRConfirmed': true,
          
            'panNumber': this.panDetails.panNumber
         }
         saveNonCustomerDetails({
            inputMap: inputMap
        })
        .then(response => {
            console.log('result:', result.ContentDocumentId);
            console.log('result:', result.DocumentDetailId);
            console.log('result:', result.applicantId);
            this.selectedRecordId = result.applicantId;
            this.applicantId = result.applicantId;
            this.showBasicDetails = false;
            this.isModalOpen= false;
           
            setTimeout(() => {
                this.getApplicantDetails();
                //this.checkSFDedupe();
                this.checkCustomerDedupe();
                this.callCkyc();
              
            }, 500);
        })
        .catch(error => {
            console.log('error:', JSON.stringify(error));
        })

    }
 

   
    handleNext() {
        const valueChangeEvent = new CustomEvent("callbasicinformation", {
            detail: {
                value: this.recordId,
                name: 'Applicant Information',
                currentAppSeq: this.currentAppSeq,
                appDetId :this.selectedRecordId
            }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    callPanValidationApi() {
        console.log('548');
        const inputMap = {
            'loanId': this.recordId,
            'applicantId': this.applicantId, // this.selectedRecordId,
            'processName': 'Loan Applicant PAN Validation',
            'panNum': this.panNo, // 'BTQPP1549D',
            'dob': this.dateOfBirth // '1977-03-22'
        }
        console.log('inputMap initiateAPIRequestPanValidation-->' + JSON.stringify(inputMap));
        initiateAPIRequestPanValidation({
                inputMap: inputMap
            })
            .then(response => {
                console.log('response initiateAPIRequestPanValidation-- ' + JSON.parse(response));
                if (response.includes('Error:')) {
                    console.log('response--', response.split(':')[1]);
                    var temp = response.split(':')[1];
                    console.log('temp--' + temp);
                    this.errorList = temp.split(',');
                    console.log('errorList--' + this.errorList);
                } else {
                    console.log('in else');
                    this.panVerif = JSON.parse(response);
                    console.log('errorList- 569-' + JSON.stringify(this.panVerif));
                    // let parsedResponse = JSON.parse(response);
                    let dobMatch = this.panVerif.result.dobMatch;
                    let nameMatch = this.panVerif.result.nameMatch;
                    let statusActive = this.panVerif.result.status;
                    let duplicateCheck = this.panVerif.result.duplicate;

                    this.updateApplicantRecord(dobMatch, nameMatch, statusActive, duplicateCheck);

                    this.callCkyc();
                }

            })
            .catch(error => {
                console.error('error initiateAPIRequestPanValidation --> ' + JSON.stringify(error));
            })
    }

    updateApplicantRecord(dobMatch, nameMatch, statusActive, duplicateCheck) {
        updateApplicantVerification({
                applicantId: this.applicantId,
                dobMatch: dobMatch,
                nameMatch: nameMatch,
                statusActive: statusActive,
                duplicateCheck: duplicateCheck
            })
            .then(() => {
                console.log('Application_Applicant__c record updated successfully.');
            })
            .catch(error => {
                console.error('Error updating Application_Applicant__c --> ', JSON.stringify(error));
            });
    }

   /* callCkyc() {
        const inputMap = {
            'loanId': this.recordId,
            'applicantId': this.applicantId, // this.selectedRecordId,
            'processName': 'Loan Applicant CKYC',
            'panNum': this.panNo, // 'BTQPP1549D',
            'dob': this.dateOfBirth // '1999-03-22'
        }
        console.log('inputMap -->' + JSON.stringify(inputMap));
        initateCKYC({
                inputMap: inputMap
            })
            .then(response => {
                console.log('initateCKYC response -->' + response);
                this.ckycResp = JSON.parse(response);
                if (this.ckycResp) {
                    console.log('initateCKYC success');
                    const images = this.ckycResp?.PID_DATA?.IMAGE_DETAILS?.IMAGE;
                    this.imageMap = images.reduce((acc, image) => {
                        if (!acc[image.IMAGE_CODE]) {
                            acc[image.IMAGE_CODE] = []; // Initialize array if not present
                        }
                        acc[image.IMAGE_CODE].push(image.IMAGE_DATA); // Push image data into array
                        return acc;
                    }, {});
                    this.imagetypemap = this.ckycResp?.PID_DATA?.IMAGE_DETAILS?.IMAGE?.reduce((acc, image) => {
                        acc[image.IMAGE_CODE] = image.IMAGE_TYPE;
                        return acc;
                    }, {});
                    console.log('Extracted imageMap -->', this.imageMap);
                    console.log('Extracted imageMap -->', JSON.stringify(this.imageMap));
                    console.log('Extracted imagetypemap -->', this.imagetypemap);
                    console.log('Extracted imagetypemap -->', JSON.stringify(this.imagetypemap));
                    this.updateDocumentChecklist();
                } else {
                    console.log('else initateCKYC error');
                }
            })
            .catch(error => {
                console.error('initateCKYC error -->' + JSON.stringify(error));
            })
    }*/

    updateDocumentChecklist() {
        if (this.imageMap != null) {
            documentCheckListUpdation({
                    documentMap: this.imageMap,
                    imagetypeMap : this.imagetypemap,
                    loanId: this.recordId,
                    applicantId: this.appId,
                    documentType: 'CKYC'
                })
                .then(res => {
                    console.log('updateDocumentChecklist success -->' + JSON.stringify(res));
                })
                .catch(error => {
                    console.error('updateDocumentChecklist error -->' + JSON.stringify(error));
                });
        } else {
            console.log('No imageMap found');
            this.fetchagain = false;
        }
    }
    handleInputFormSixtyChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;
        const targetvalue = event.target.value;
        console.log('value-->',value);
        console.log('target value-->',targetvalue);
        console.log('field-->', field);
        this.formSixtyDetails = {
            ...this.formSixtyDetails,
            [field]: event.target.value
        };
    }

    handleInputChange(event) {
        console.log('inside handleInput----');
        const field = event.target.dataset.field;
        console.log('field-->', field);
        this.panDetails = {
            ...this.panDetails,
            [field]: event.target.value
        };
    }
    handlePanChange(event) {
        let value = event.target.value.toUpperCase();
        if (value.length > 10) {
            value = value.substring(0, 10);
        }
        this.panDetails = {
            ...this.panDetails,
            panNumber: value
        };
    }
    openManualCmp(){
        this.showCustomerDetails =true;
        this.isCustomerTypeSelected  =false;
        this.manualcmp = true;
        this.isModalOpen = false;
        const scrollOptions = {
            left: 0,
            top: 2,
            behavior: 'smooth'
        }
        window.scrollTo(scrollOptions);
    }
    openFormSixtyManualCmp(){
        this.manualFormSixtycmp = true;
        this.isModalOpen = false;
        const scrollOptions = {
            left: 0,
            top: 2,
            behavior: 'smooth'
        }
        window.scrollTo(scrollOptions);
    }
    handleAddFormSixtyDetails(event){
        console.log('firstName==>',this.formSixtyDetails.firstName +'lastName',this.formSixtyDetails.lastName + 'loanId=',this.recordId);
        this.isManualloading = true;
        
          if(!this.formSixtyDetails.firstName || this.formSixtyDetails.firstName.trim() === ''){
            this.showToast('Error','Please Fill the First Name','Error');
            this.isManualloading = false;
            return;
        }
        if(!this.formSixtyDetails.lastName || this.formSixtyDetails.lastName.trim() === ''){
            this.showToast('Error','Please Fill the Last Name','Error');
            this.isManualloading = false;
            return;
        }
        if(!this.formSixtyDetails.mobileNumber || this.formSixtyDetails.mobileNumber.trim() === ''){
           this.showToast('Error','Please Fill Mobile Number.','Error');
           this.isManualloading = false;
           return;
        }
        if(!this.formSixtyDetails.mobileNumber.match(/^[6-9]\d{9}$/)){
            this.showToast('Error','Please Enter Mobile Number in Correct Format','Error');
            this.isManualloading = false;
            return;
        }
        if(!this.formSixtyBase64Data || this.formSixtyBase64Data.trim() === ''){
           this.showToast('Error','Please Uploade the Form-60 File','Error');
           this.isManualloading = false;
           return;
        }
        if(this.fileSize > 3000000){
           this.showToast('Error','Please Uploade the Form-60 File Less than 3 mb','Error');
           this.isManualloading = false;
           return;
        }
                const inputMap = {
                firstName: this.formSixtyDetails.firstName,
                middleName: this.formSixtyDetails.middleName,
                lastName: this.formSixtyDetails.lastName,
                applicantId: this.selectedRecordId,
                loanId: this.recordId,
                mobileNumber: this.formSixtyDetails.mobileNumber,
                formSixtyFileName: this.formSixtyFileName,              
                formSixtyBase64Data: this.formSixtyBase64Data
                };
                console.log('inputMap==>',inputMap);
               uploadFormSixtyToDocumentDetail({ inputMap})
                    .then(result => {
                        console.log('result uploadFormSixtyToDocumentDetail:', JSON.stringify(result));
                        setTimeout(() => {
                        if (result) {
                                this.selectedRecordId = result.applicantId;
                                this.applicantId = result.applicantId;
                                this.manualFormSixtycmp = false;
                               this.isModalOpen = false;
                                this.showBasicDetails = false;
                                this.manualcmp = false;                            
                                if(result.applicantId != null || result.applicantId != ''){
                                    this.showToast('Success','FormSixty has been Uploaded Successfully','Success');
                                    setTimeout(() => {
                                    //this.checkSFDedupe();
                                    //HL-Ishi-24-09
                                    this.checkCustomerDedupe();
                                     //HL-Ishi-24-09
                                 //  this.refreshRecordPage(); // call the above method
                                }, 1000);
                                } 
                            }

            },100)
                    })
                    .catch(error => {
                        console.log('error savePanDetailsManually:', JSON.stringify(error));
                        const errorMessage = error.body.message.split("FIELD_CUSTOM_VALIDATION_EXCEPTION,")[1]?.split(":")[0]?.trim();
                        if(errorMessage){
                            this.dispatchEvent(new ShowToastEvent({
                                title: 'Error',
                                message: errorMessage,
                                variant: 'Error',
                            }));
                        }else{
                            this.dispatchEvent(new ShowToastEvent({
                                title: 'Error',
                                message: error,
                                variant: 'Error',
                            }));
                        }
                        this.isManualloading = false;

                    })
           
        
    }

    handleDeleteForm60() {
            deleteFormSixty({ applicantId: this.selectedRecordId })
                .then(() => {
                    // Clear local UI state
                    this.showFormSixtyUrl = false;
                    this.showPANConfirmation =
                    this.formSixtyDetails = null;

                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Form 60 deleted successfully.',
                            variant: 'success'
                        })
                    );
                    this.refreshRecordPage();
                })
                .catch(error => {
                    console.error('Error deleting Form 60:', error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: error?.body?.message || 'Failed to delete Form 60.',
                            variant: 'error'
                        })
                    );
                });
    }  

        validateDob(dateStr) {
            console.log('validate dob called or not',dateStr);
        if (!dateStr) {
        return 'Please select a valid date';
        }
        const selected = new Date(dateStr);
        const today = new Date();

        // Remove time components
        selected.setHours(0,0,0,0);
        today.setHours(0,0,0,0);
        console.log('selected ',selected);
        console.log('today',today);
        if (selected >= today) {
            console.log('selected==>',selected);
            this.aadharDetails.dob = '';
        return 'Date must be before today';
        }

        const eighteenYearsAgo = new Date();
        eighteenYearsAgo.setFullYear(eighteenYearsAgo.getFullYear() - 18);

        if (selected > eighteenYearsAgo) {
            this.aadharDetails.dob = '';
        return 'You must be at least 18 years old';
        }

        return ''; // All good
        }
        
        handleAddDetailsManually() {
            this.isManualloading = true;
            console.log('inside handleAddDetailsManually',this.showNonIndividual);
            console.log('inside handleAddDetailsManually',this.panDetails.panNumber);
            console.log('inside handleAddDetailsManually',this.isPanExist);
            // this.checkExistingCustomer(this.panDetails.panNumber);
            setTimeout(() => {
                 console.log('inside handleAddDetailsManually',JSON.stringify(this.panDetails));
                if(this.panDetails.panNumber == null || this.panDetails.panNumber == '' || this.panDetails.panNumber == undefined){
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter PAN to proceed.',
                        variant: 'Error',
                    }));
                    this.isManualloading = false;
                    return;
                }
                if (!this.isPanExist) {
                    if (!this.panDetails.panNumber.match(/[A-Z]{3}[P|C|H|A|B|G|J|L|E|F|T|c|p|h|a][A-Z][0-9]{4}[A-Z]{1}/)) {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter PAN in correct format.',
                            variant: 'Error',
                        }));
                        this.isManualloading = false;
                        return;
                    }
        if(this.showNonIndividual){
            if(this.panDetails.name== null || this.panDetails.name== ''|| this.panDetails.name== undefined
                || this.panDetails.panNumber== null || this.panDetails.panNumber== ''|| this.panDetails.panNumber== undefined
                || this.panDetails.dobDoi== null || this.panDetails.dobDoi== ''|| this.panDetails.dobDoi== undefined
            ){
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter all the details to proceed.',
                            variant: 'Error',
                        }));
                        this.isManualloading = false;
                        return;
                    }
                
            if(!validateNonIndividualPAN(this.panDetails.panNumber, this.selectedConstitution)){
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter PAN in correct format.',
                            variant: 'Error',
                        }));
                        this.isManualloading = false;
                        return;
                    }
                   
        }else if(this.showIndividual){
             console.log('inside handleAddDetailsManually 1723',JSON.stringify(this.panDetails));
              
            if(this.panDetails.firstName== null || this.panDetails.firstName== ''|| this.panDetails.firstName== undefined
                || this.panDetails.panNumber== null || this.panDetails.panNumber== ''|| this.panDetails.panNumber== undefined
                || this.panDetails.dobDoi== null || this.panDetails.dobDoi== ''|| this.panDetails.dobDoi== undefined
                || this.panDetails.fathersName== null || this.panDetails.fathersName== ''|| this.panDetails.fathersName== undefined
            ){
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter all the details to proceed.',
                            variant: 'Error',
                        }));
                        this.isManualloading = false;
                        return;
                    }

            if(!panNumberValidation(this.panDetails.panNumber)){
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter PAN in correct format.',
                            variant: 'Error',
                        }));
                        this.isManualloading = false;
                        return;
                    }

                }
        console.log('inside handleAddDetailsManually 1763',JSON.stringify(this.panDetails));
                //const specialCharacterRegex = /[^a-zA-Z\s]/;
                
const specialCharacterRegex = /[^a-zA-Z\s()]/;


        if((this.panDetails.name== null || this.panDetails.name== ''|| this.panDetails.name== undefined) && specialCharacterRegex.test(this.panDetails.fathersName)){
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter fathers name in correct format.',
                        variant: 'Error',
                    }));
                    this.isManualloading = false;
                    return;
                }
        if(specialCharacterRegex.test(this.panDetails.fathersName) || specialCharacterRegex.test(this.panDetails.name)) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter name in correct format.',
                        variant: 'Error',
                    }));
                    this.isManualloading = false;
                    return;
                }
            console.log('this.panDetails.name Kshitiz---', this.panDetails.name);
                console.log('this.leadName Kshitiz---', this.panDetails.leadName);    
        /*if(this.panDetails.applicantType == 'Primary Applicant' && this.panDetails.leadName != this.panDetails.name){
            this.dispatchEvent(new ShowToastEvent({
                title: 'Warning',
                message: 'Please note that the name is different from lead.',
                variant: 'warning',
            }));
        }*/
          console.log('inside handleAddDetailsManually 1790',JSON.stringify(this.panDetails));
                     console.log('inside handleAddDetailsManually 1790',JSON.stringify(this.panDetails));
                    var fullName = '';
                    console.log('inside handleAddDetailsManually 180o',JSON.stringify(this.panDetails));
                        if (this.panDetails.firstName != null) {
                            fullName += this.panDetails.firstName;
                        }
                        if (this.panDetails.middleName != null) {
                            if (fullName != '') fullName += ' ';
                            fullName += this.panDetails.middleName;
                        }
                        if (this.panDetails.lastName != null) {
                            if (fullName != '') fullName += ' ';
                            fullName += this.panDetails.lastName;
                        }
                          console.log('fullName0',fullName);
                    if(this.showIndividual){
                          console.log('fullName1813',fullName);
                        this.panDetails.name =fullName;
                    }
              //  } //Commented By Prachi
                const inputMap = {
                    'customerType':this.selectedCustomerType,
                    'panNumber': this.panDetails.panNumber,
                    'applicantId': this.selectedRecordId,
                    'loanId': this.recordId,
                    'dob': this.panDetails.dobDoi,
                    'panName': this.panDetails.name,
                    'fatherName': this.panDetails.fathersName,
                    'panOCRConfirmed':true,
                    'constitution': this.selectedConstitution
                }
               
                
               
                console.log('inside handleAddDetailsinputMap',inputMap);
                //HL-Testing-Requirement: commented out - skips the real savePanDetailsManually
                //Apex save + dedupe/aadhaar-notification chain after Manual completion. The
                //read-only table is now populated with hardcoded data instead of a live save.
                // savePanDetailsManually({
                //     inputMap: inputMap
                // })
                //     .then(result => {
                //         console.log('result savePanDetailsManually:', JSON.stringify(result));
                //         setTimeout(() => {
                //             if (result) {
                //                 this.selectedRecordId = result.applicantId;
                //                 this.applicantId = result.applicantId;
                //                 this.showBasicDetails = false;
                //                 this.manualcmp = false;
                //                 this.isModalOpen = false;
                //                 this.selectedConstitution = '';
                //                 if(result.createApp == 'true'){
                //                     this.checkCustomerDedupe();
                //                 }
                //                 else{
                //                     if(result.freshCust == 'true'){
                //                         this.showDuplicate = false;
                //                         const valueChangeEvent2 = new CustomEvent("refreshapplicantlist", {
                //                             detail: {
                //                                 value: this.recordId,
                //                                 name: 'Applicant\'s Basic Information',
                //                                 currentAppSeq: this.currentAppSeq,
                //                                 appDetId :this.selectedRecordId
                //                             }
                //                         });
                //                         this.dispatchEvent(valueChangeEvent2);
                //                         setTimeout(() => {
                //                             const valueChangeEvent = new CustomEvent("callaadhardetails", {
                //                                 detail: {
                //                                     value: this.recordId,
                //                                     name: 'Aadhaar Details',
                //                                     currentAppSeq: this.currentAppSeq,
                //                                     appDetId:this.selectedRecordId
                //                                 }
                //                             });
                //                             this.dispatchEvent(valueChangeEvent);
                                            
                //                         }, 200);
                //                     }
                //                     else{
                //                         this.showDuplicate = true;
                //                         console.log('436this.showDuplicate',   this.showDuplicate);
                //                         const valueChangeEvent2 = new CustomEvent("refreshapplicantlist", {
                //                             detail: {
                //                                 value: this.recordId,
                //                                 name: 'Dedupe',
                //                                 currentAppSeq: this.currentAppSeq,
                //                                 appDetId :this.selectedRecordId
                //                             }
                //                         });
                //                         this.dispatchEvent(valueChangeEvent2);
                //                         setTimeout(() => {
                //                             console.log('447this.showDuplicate',   this.showDuplicate);
                //                             const valueChangeEvent = new CustomEvent("recallapplicantmethod", {
                //                                 detail: {
                //                                     value: this.recordId,
                //                                     name: 'Dedupe',
                //                                     custId: this.custId,
                //                                     currentAppSeq: this.currentAppSeq,
                //                                     appDetId:this.selectedRecordId
                //                                 }
                //                             });
                //                             this.dispatchEvent(valueChangeEvent);
                //                         }, 200);
                //                     }
                //                 }
                //             }

                //     },100)
                //         })
                //         .catch(error => {
                //             console.log('error savePanDetailsManually:', JSON.stringify(error));
                //             const errorMessage = error.body.message.split("FIELD_CUSTOM_VALIDATION_EXCEPTION,")[1]?.split(":")[0]?.trim();
                //     if(errorMessage){
                //                     this.dispatchEvent(new ShowToastEvent({
                //                         title: 'Error',
                //                         message: errorMessage,
                //                         variant: 'Error',
                //                     }));
                //     }else{
                //                     this.dispatchEvent(new ShowToastEvent({
                //                         title: 'Error',
                //                         message: error,
                //                         variant: 'Error',
                //                     }));
                //                 }
                //                 this.isManualloading = false;

                //             })
                this.showHardcodedPanTable();
            }
        }, 300);
    }

    checkExistingCustomer(panNumber){
        this.isPanExist = false;
        console.log('this.recordId-->',this.recordId);
        console.log('this.applicantId-->',this.selectedRecordId);
        getExistingCustomer({
            loanId: this.recordId,
            applicantDetId: this.selectedRecordId
        })
        .then(result => {
            result.forEach(resultData => {
                console.log('panNumber--->',panNumber);
                console.log('resultData--->',resultData);
                if(resultData.PAN_Number__c == panNumber && resultData.Applicant_Type__c == 'Primary Applicant' && resultData.Customer_Type__c == 'Non Individual'){
                    this.isPanExist = false;
                }else if(resultData.PAN_Number__c == panNumber){
                    this.isPanExist = true;
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Duplicate customer detected. This customer already exists.',
                        variant: 'Error',
                    }));
                    this.isConformationLoading = false;
                    this.isManualloading = false;
                }
            })
        })
    }
    handleCustomerTypeChange(event) {
        this.selectedCustomerType = null;
     
        this.selectedCustomerType = event.target.value;
     
        if(this.selectedCustomerType === 'Individual'){
            this.showIndividual = true;
            this.showNonIndividual = false;
            this.selectedConstitution='';
            this.isCustomerTypeSelected = true;
            this.showCustomerDetails = false;
        }
        else{
            this.showNonIndividual = true;
            this.showIndividual = false;
            if(this.panDetails!= null && this.panDetails!= '' && this.panDetails!= undefined){
                if(this.panDetails.panNumber!= null && this.panDetails.panNumber!= '' && this.panDetails.panNumber!= undefined){
                    if(panNumberValidation(this.panDetails.panNumber)){
                        this.selectedConstitution = 'Proprietorship';
                        this.isProprietor = true;
                    }
                }
            }
           
        }
        
    }

    handleConstitutionChange(event){
        this.selectedConstitution = event.target.value;
        console.log('this.selectedConstitution----', this.selectedConstitution);
         console.log('this.parsedResponse.result.documents[0].ocrData.doi.value---', this.nameOfOrg);
        this.isCustomerTypeSelected = true;
        this.showCustomerDetails = false;
        //Name/DOB auto-populate from lead data (nameOfOrg/doi) for Proprietorship -
        //this stays active for both Upload and Manual flows per requirement.
        if(this.applicantType == 'Primary Applicant' && this.selectedConstitution == 'Proprietorship'){
            this.panDetails.name = this.nameOfOrg;
            this.panDetails.dobDoi= this.doi;
            this.showPropMessage = true;
           
        }
        // this.isCustomerTypeSelected = true;
    }

    goPrevious(){
        this.isCustomerTypeSelected = false;
     
    }
    handleInputBlurDate(event){
        const currentId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;
        if(this.showNonIndividual){
            if(field== 'dobDoi'){
                let currentDate = new Date().toJSON().slice(0, 10);
                console.log('todayDate----', new Date());
                console.log('this.dateofBirth----', value);
                if (value >= currentDate) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Date of incorporation cannot be future/current date',
                        variant: 'Error',
                    }));
                    this.template.querySelector(`[data-field="${field}"]`).value = '';
                    return;
                }else {
                    this.panDetails = {
                        ...this.panDetails,
                        [field]: event.target.value
                    };
                }
            }
        }else if(this.showIndividual){
            if(field== 'dobDoi'){
                var regexVar = /^([0-9]{2})\/([0-9]{2})\/([0-9]{4})$/;
                let currentDate = new Date().toJSON().slice(0, 10);
                var userBirthDate = new Date(value.replace(regexVar, "$3-$2-$1"));
                var todayYear = (new Date()).getFullYear(); // Always use FullYear!!
                var cutOff19 = new Date(); // should be a Date
                cutOff19.setFullYear(todayYear - 21); // ...  
                console.log('todayDate----', new Date());
                console.log('this.dateofBirth----', value);
                if (value >= currentDate) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Date of birth cannot be future/current date',
                        variant: 'Error',
                    }));
                    this.template.querySelector(`[data-field="${field}"]`).value = '';
                    return;
                } else if (userBirthDate > cutOff19) {
                    console.log('age----', 18 * 365);
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Age should not be less than 18 years',
                        variant: 'Error',
                    }));
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                    return;
                }else {
                    this.panDetails = {
                        ...this.panDetails,
                        [field]: event.target.value
                    };
                }
            }
        }
    }

    handleInputBlur(event){
        console.log('inside handleBlur----');
        //const fourthChar = this.panDetails.panNumber.charAt(3).toUpperCase();

        const field = event.target.dataset.field;
        const value = event.target.value;
        console.log('showNonIndividual', this.showNonIndividual);
        console.log('showIndividual', this.showIndividual);
        console.log('value', value);
        console.log('field.length-----', field.length);
        console.log('field-->',field);
        if (value != null && value != '' && value != undefined) {
            if (this.showNonIndividual) {
                
                
                if (field == 'panNumber') {
                    if (field.length == 10 && !validateNonIndividualPAN(this.panDetails.panNumber, this.selectedConstitution)) {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter PAN in correct format. 1563',
                            variant: 'Error',
                        }));
                        this.template.querySelector(`[data-field="${field}"]`).value = '';
                        return;
                    }
                    else if(field.length> 10){
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter PAN in correct format. 1572',
                            variant: 'Error',
                        }));
                        this.template.querySelector(`[data-field="${field}"]`).value = '';
                        return;
                    }else{
                        this.panDetails = {
                            ...this.panDetails,
                            [field]: event.target.value
                        };
                    }
                }
                if (field == 'name') {
                    console.log('inside name validation----');
                    // const specialCharacterRegex = /[^a-zA-Z\s]/; // Regex to check for special characters
                   
const specialCharacterRegex = /[^a-zA-Z\s()]/;


                    if (specialCharacterRegex.test(value)) {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter name in correct format.',
                            variant: 'Error',
                        }));
                        this.template.querySelector(`[data-field="${field}"]`).value = '';
                        return;
                    } else {
                        if(field == 'name'){
                            if(this.panDetails.applicantType == 'Primary Applicant' && this.panDetails.leadName != event.target.value){
                                this.dispatchEvent(new ShowToastEvent({
                                    title: 'Warning',
                                    message: 'Please note that the name is different from lead.',
                                    variant: 'warning',
                                }));
                            }
                        }
                        this.panDetails = {
                            ...this.panDetails,
                            [field]: event.target.value
                        };
                    }
                }
            } else if (this.showIndividual) {
                if (field == 'panNumber') {
                    if (value.length == 10 && !panNumberValidation(value)) {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter PAN in correct format.',
                            variant: 'Error',
                        }));
                        this.template.querySelector(`[data-field="${field}"]`).value = '';
                        return;
                    }else if(value.length> 10){
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter PAN in correct format.',
                            variant: 'Error',
                        }));
                        this.template.querySelector(`[data-field="${field}"]`).value = '';
                        return;
                    } else {
                        this.panDetails = {
                            ...this.panDetails,
                            [field]: event.target.value
                        };
                    }
                }
                if (field == 'name') {
                    console.log('inside name validation----');
                    //const specialCharacterRegex = /[^a-zA-Z\s]/; // Regex to check for special characters
                    
const specialCharacterRegex = /[^a-zA-Z\s()]/;

                    if (specialCharacterRegex.test(value)) {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter name in correct format.',
                            variant: 'Error',
                        }));
                        this.template.querySelector(`[data-field="${field}"]`).value = '';
                        return;
                    } else {
                        if(field == 'name'){
                            if(this.panDetails.applicantType == 'Primary Applicant' && this.panDetails.leadName != event.target.value){
                                this.dispatchEvent(new ShowToastEvent({
                                    title: 'Warning',
                                    message: 'Please note that the name is different from lead.',
                                    variant: 'warning',
                                }));
                            }
                        }
                        this.panDetails = {
                            ...this.panDetails,
                            [field]: event.target.value
                        };
                    }
                }
            } else {
                if (field == 'panNumber') {
                    if (value.length == 10 && value.match(/[A-Z]{3}[P|C|H|A|B|G|J|L|E|F|T|c|p|h|a][A-Z][0-9]{4}[A-Z]{1}/)) {
                        console.log('Inside correct panNumberValidation');
                        this.panDetails = {
                            ...this.panDetails,
                            [field]: event.target.value
                        };

                    } else if(value.length> 10){
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter PAN in correct format.',
                            variant: 'Error',
                        }));
                        this.template.querySelector(`[data-field="${field}"]`).value = '';
                        return;
                    }
                   
                }
                if (field == 'name' || field == 'fathersName') {
                    console.log('inside name validation----');
                    //const specialCharacterRegex = /[^a-zA-Z\s]/; // Regex to check for special characters
                    
const specialCharacterRegex = /[^a-zA-Z\s()]/;

                    if (specialCharacterRegex.test(value)) {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter name in correct format.',
                            variant: 'Error',
                        }));
                        this.template.querySelector(`[data-field="${field}"]`).value = '';
                        return;
                    } else {
                        if(field == 'name'){
                            if(this.panDetails.applicantType == 'Primary Applicant' && this.panDetails.leadName != event.target.value){
                                this.dispatchEvent(new ShowToastEvent({
                                    title: 'Warning',
                                    message: 'Please note that the name is different from lead.',
                                    variant: 'warning',
                                }));
                            }
                        }
                        this.panDetails = {
                            ...this.panDetails,
                            [field]: event.target.value
                        };
                    }
                }
            }
        }



    }
    closeModalManual(){
        this.manualcmp = false;
    }
    closeFormSixtyManual(){
        this.manualFormSixtycmp = false;
    }
    handleInputBlurDate(event){
        console.log('---')
    }
    handleNextPan(){
        if(this.selectedCustomerType== null || this.selectedCustomerType == ''|| this.selectedCustomerType== undefined){
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please selected customer type to move next',
                variant: 'Error',
            }));
            return;
        }
        if(this.selectedCustomerType == 'Non Individual' && (this.selectedConstitution== null || this.selectedConstitution == ''|| this.selectedConstitution == undefined)){
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please selected constitution to move next',
                variant: 'Error',
            }));
            return;
        }
        console.log('selectedtype---',this.selectedCustomerType);
        if(this.selectedCustomerType === 'Individual' ){
            this.showIndividual = true;
            this.showNonIndividual = false;
        }
        else {
            this.showIndividual = false;
            this.showNonIndividual = true;
        }
        this.isCustomerTypeSelected = true;
        this.showCustomerDetails = false;
    }
    refreshRecordPage() {
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: this.recordId,
            objectApiName: 'Opportunity', // change if your object is different
            actionName: 'view'
        }
    }, true); // true replaces history, avoids extra back step
    }
    handleDelete(){
        console.log('this.panContentVersionId---',this.panContentVersionId);
        const inputMap = {
            applicantId:this.applicantId,contentVersionId :  this.panContentVersionId
        }
        deletePanDetails({
            inputMap: inputMap
        })
        .then(result => {
            console.log('result deletePanDetails:',result);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'PAN details deleted successfully.',
                variant: 'success',
            }));
            this.refreshRecordPage();
           
        })
        .catch(error => {
            console.log('error-->',error);
        })
    }
    isShowPDF = false;
    handleEdit() {
        this.manualcmp = true;

        // ✅ Only call Apex if HL user is false AND PAN number exists
        if (this.panDetails?.panNumber) {
             this.panContentVersionId = '';
            getPANContentVersionId({ applicantId: this.applicantId })
                .then(contentVersionId => {
                    if (contentVersionId) {
                        this.panImageUrl = '/sfc/servlet.shepherd/version/download/' + contentVersionId.split(' ')[0];
                         this.panContentVersionId = contentVersionId;
                         console.log('this.panContentVersionId',this.panContentVersionId);
                         if(contentVersionId.split(' ')[2] == 'pdf'){
                            this.isShowPDF = true;
                            this.isShowImage = false;
                         }
                         else{
                            this.isShowPDF = false;
                            this.isShowImage = true;
                         }
                    } else {
                        this.isShowImage = false;
                        this.panImageUrl = null;
                    }

                    // After PAN fetch → continue UI flow
                    this.processCustomerDetails();
                })
                .catch(error => {
                    console.error('Error fetching PAN image:', error);
                    this.isShowImage = false;
                    this.panImageUrl = null;

                    // Continue UI flow even on error
                    this.processCustomerDetails();
                });
        } else {
            // Skip PAN fetch → directly continue UI flow
            this.processCustomerDetails();
        }
    }

    processCustomerDetails() {
        if (this.isCoApplicant) {
            this.selectedCustomerType = 'Individual';
            this.isCustomerTypeSelected = true;
            this.showCustomerDetails = true;
            this.showIndividual = false;
        } else {
            this.showCustomerDetails = true;
            this.isCustomerTypeSelected = false;

            console.log(
                'this.selectedCustomerType in personal details----',
                this.panDetails.applicantType
            );

            if (this.panDetails.applicantType === 'Individual') {
                this.showUploadOrManualScreen = false;
            } else if (this.panDetails.applicantType === 'Non Individual') {
                this.showUploadOrManualScreen = true;
            }
        }
    }
    //Added By prachi

    goPrevious() {
        this.showCustomerDetails = true;
        this.isCustomerTypeSelected = false;

    }
        
    //HL-Ishi-8/9
}