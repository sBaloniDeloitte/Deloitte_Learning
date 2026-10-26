import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import createContentVersion from '@salesforce/apex/COMM_SalesLoanActionsController.createContentVersion'
import getApplicantDetailsOCR from '@salesforce/apex/COMM_SalesLoanActionsController.getApplicantDetailsOCR'
import getSubStageList from '@salesforce/apex/COMM_SalesLoanActionsController.getSubStageList'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveAadharDetailsManually from '@salesforce/apex/COMM_SalesLoanActionsController.saveAadharDetailsManually'
import getPincodeDetails from '@salesforce/apex/COMM_SalesLoanActionsController.getPincodeDetails';
import initiateAPIRequest from '@salesforce/apex/COMM_OCRController.initiateAPIRequest'
import createDocumentDetailsRecord from '@salesforce/apex/COMM_SalesLoanActionsController.createDocumentDetailsRecord';
// import checkSFDedupe from '@salesforce/apex/COMM_SalesLoanActionsController.checkSFDedupe'
import FORM_FACTOR from '@salesforce/client/formFactor';
//HL-Ishi-15/09
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated';
import APPLICANT_ADDRESS_OBJECT from '@salesforce/schema/Applicant_Address__c';
import ADDRESS_TYPE_FIELD from '@salesforce/schema/Applicant_Address__c.Address_Type__c';
import ADDRESS_PROOF_FIELD from '@salesforce/schema/Applicant_Address__c.Current_Address_Proof__c';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
//HL-Ishi-15/09
//HL-Ishi-24-09
import checkCustomerDedupe from '@salesforce/apex/SalesCustomerDedupeController.checkCustomerDedupe' 	
//HL-Ishi-24-09
//Added By Prachi
import getFileSize from '@salesforce/apex/Utility_V1.getFileSize';
import deleteUploadedFile from '@salesforce/apex/Utility_V1.deleteUploadedFile';
//Added By Prachi
import deleteAadhaarDetails from '@salesforce/apex/COMM_SalesLoanActionsController.deleteAadhaarDetails';
import USER_ID from '@salesforce/user/Id'; 
import NAME_FIELD from '@salesforce/schema/User.Name';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import linkManualDocumentAndUpdate from '@salesforce/apex/COMM_SalesLoanActionsController.linkManualDocumentAndUpdate';//Aadhar Masking Failure_Ayushi
import checkApplicantAddressType from '@salesforce/apex/Utility_V1.checkApplicantAddressType';
import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';
export default class SalesLoginAadharDetailsCmp extends NavigationMixin(LightningElement) {
    isMobile = FORM_FACTOR === 'Small';
    isTablet = FORM_FACTOR === 'Medium';
    isDesktop = FORM_FACTOR === 'Large';
    isMobileOrTablet = false;
    @track zoomLevel = 1;
    @api isAadharDetails = false;
    isAadharDetailsUploads = false;
    showAadharManualTableGrid = true;
    @api applicantId;
    @api recordId;
    @track docType;
    @track selectedAadharUploadOrFillValue = '';
    @track showUploadOrManualScreen = false;
    @track showUploadOption = false;
    @track showAadharUploadOption = false;
    @track showManualAadharFillOption = false;
    @track isAadharFrontModalOpen = false;
    @track isAadharBackModalOpen = false;
    @track ShowConfirmAadharUpload = false;
    stampedAadharNumber;
    parsedResponse;
    passedScreenName = 'Applicant Information';
    @track disableUploadOption = false;
    @track uploadedAadharUrl = '';
    @track dobError = '';
    manualAadharcmp = false;
    @track disableAadhar = false;
    selectedRecordId;
    isloading = false;
    @track isAadhaarBackOCRConfirmed = false;
    @track isAadhaarFrontOCRConfirmed = false;
    @track selectedPinCodeMasterId;
    @track disableFrontUpload = false;
    @track disableBackUpload = false;
    maskedAadharNumber = '';
    lengthAadharNumber = 0;
    originalAadharNumber = '';
    showDeleteAadhaarButton = false;
    //HL-Ishi-8/9/2025
    isHLUser = false;
    hideManualDetailsAddButton = false;
    @track addressTypeOptions = [];
    @track addressProofOptions = [];
    //HL-Ishi-8/9/2025
    @track aadharDetails = {
        firstName: '',
        firstNameConfidence: '',
        middleName: '',
        middleNameConfidence: '',
        lastName: '',
        lastNameConfidence: '',
        dob: '',
        dobConfidence: '',
        aadharNumberMasked: '',
        aadharNumber: '',
        aadharNumberConfidence: '',
        mobileNumber: '',
        mobileNumberConfidence: '',
        aadharFullAddress: '',
        addressConfidence: '',
        pinCodeConfidence: '',
        addType: '',
        aadharAddress: {
            addressLine1: '',
            addressLine2: '',
            addressLine3: '',
            city: '',
            province: '',
            postalCode: '',
            country: '',
            addType: '',
            addressOwnership: null
        },
      
    }
    showcheckBoxMaskingManualFront =false;
    showcheckBoxMaskingManualBack =false;
    @track checkedFront;
    @track checkedBack;
    isAcknowledged =false;
    userName;
    //Hl-Ishi-15/09

    @wire(getObjectInfo, { objectApiName: APPLICANT_ADDRESS_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: ADDRESS_TYPE_FIELD })
    wiredAddressType({ error, data }) {
        if (data) {
            this.addressTypeOptions = data.values.map(opt => ({ label: opt.label, value: opt.value }));
            const allowedAddressTypes = ['Permanent','Current'];
            this.addressTypeOptions = this.addressTypeOptions.filter(item => allowedAddressTypes.includes(item.label));
        } else if (error) {
            this.showToast('Error', 'Failed to load Address Type picklist', 'error');
        }
    }
    @wire(getRecord, { recordId: USER_ID, fields: [NAME_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.userName = data.fields.Name.value;
        } else if (error) {
            console.error('Error fetching user data:', error);
        }
    }

    //Hl-Ishi-15/09

    aadharUploadOrFillManuallyOptions = [
        { label: 'Upload', value: 'Upload' },
        { label: 'Manual', value: 'Manual' },
    ];

    addressOwnershipOptions = [
        { label: 'Self Owned', value: 'Self Owned' },
        { label: 'Rented', value: 'Rented' }
    ];
    get showAadharModal() {
        return this.isAadharFrontModalOpen || this.isAadharBackModalOpen;
    }
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
    //Ishi-Address
    isExistingAddressForApplicant=false;
    addressTypeChanged;
    isHLRelated;

    connectedCallback() {
        this.fetchProducDetails();
        this.isMobileOrTablet = FORM_FACTOR === 'Small' || FORM_FACTOR === 'Medium';
        console.log('isAadharDetails==>>', this.isAadharDetails);
        this.getApplicantDetails();
        this.getSubStageList();
        this.selectedRecordId = this.applicantId;
        console.log('this.selectedRecordId=>', this.selectedRecordId);
        //HL-Ishi-8/9/2025
        this.checkIfLoggedInUserIsHLRelated();
        //HL-Ishi-8/9/2025

    }

    /* ____GenAI: Generated code starts here - one-time dark-theme style
       injection for lightning-card's internal header/body/footer, which
       live inside the base component's own shadow DOM and cannot be reached
       by this component's compiled :host CSS. This mirrors the same
       technique already used successfully in salesLoanLoginMainCmp for the
       lightning-accordion header. Visual-only, no functional change.____ */
    isCardStyleInjected = false;
    injectCardTheme() {
        if (this.isCardStyleInjected) {
            return;
        }
        const anchor = this.template.querySelector('.styleContainer');
        if (!anchor) {
            return;
        }
        this.isCardStyleInjected = true;
        const style = document.createElement('style');
        style.innerText = `
            .slds-card {
                background-color: #0e1c30 !important;
                border: 1px solid #1d2f45 !important;
                border-radius: 10px !important;
                box-shadow: 0 4px 14px rgba(0, 0, 0, 0.35) !important;
                padding: 20px;
            }
            .slds-card__header {
                background-color: #0e1c30 !important;
            }
            .slds-card__header-title,
            .slds-card__header-title a,
            .slds-card__header-title .slds-truncate {
                color: #ffffff !important;
                font-weight: 700 !important;
            }
            .slds-card__body {
                background-color: transparent !important;
                color: #ffffff !important;
            }
            .slds-card__footer {
                background-color: #0e1c30 !important;
            }
            .slds-radio__label,
            .slds-radio__label .slds-form-element__label,
            .slds-checkbox__label .slds-form-element__label {
                color: #ffffff !important;
                opacity: 1 !important;
            }
            .slds-radio_faux,
            .slds-checkbox_faux {
                background-color: #16283f !important;
                border-color: #8a99b3 !important;
            }
            .slds-radio input:checked + .slds-radio__label .slds-radio_faux,
            .slds-radio input:checked ~ .slds-radio__label .slds-radio_faux {
                background-color: #2563eb !important;
                border-color: #2563eb !important;
            }
            .slds-modal__content table.slds-table thead th,
            .slds-modal__content table.slds-table tbody td,
            .slds-modal__content table.slds-table tbody td span {
                color: #ffffff !important;
            }
        `;
        anchor.appendChild(style);
    }
    /* ____GenAI: Generated code ends here____ */

    renderedCallback() {
        this.injectCardTheme();
        if (this.manualAadharcmp) {
            setTimeout(() => {
                // Try to find the modal container
                const modal = this.template.querySelector('.slds-modal__container');
                if (modal) {
                    modal.scrollIntoView({ behavior: 'smooth', block: 'center' });
                } else {
                    // Fallback: scroll to top
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                }
            }, 300); // Slight delay for DOM render
        }
    }
    checkIfLoggedInUserIsHLRelated() {
        checkIfLoggedInUserIsHLRelated()
            .then(result => {
                this.isHLUser = result.isHLRelated;
                console.log('isHLUser-->', this.isHLUser);
            })
            .catch(error => {
                console.log('error-->', error);
            })
    }

    blockSpaces(event) {
        if (event.key === ' ') {
            event.preventDefault();
        }
    }
    openAadharManualCmp() {
        this.manualAadharcmp = true;
        this.isModalOpen = false;
        /* const scrollOptions = {
                 left: 0,
                 top: 2,
                 behavior: 'smooth'
             }
             window.scrollTo(scrollOptions);*/
    }
    handleConfirm() {
        this.isConformationLoading = true;

        const requiredFields = [];
        if (!this.aadharDetails.firstName) requiredFields.push('First Name');
        if (!this.aadharDetails.lastName) requiredFields.push('Last Name');

        if (this.isAadharBackModalOpen) {
            if (!this.aadharDetails.aadharFullAddress) requiredFields.push('aadharFullAddress');
            if (!this.aadharDetails.aadharAddress?.postalCode) requiredFields.push('Pincode');
            if (!this.aadharDetails.addType) {
                requiredFields.push('Address Type');
            }
            if (!this.aadharDetails.aadharAddress?.addressOwnership) {
                requiredFields.push('Address Ownership');
            }
        }

        if (this.isAadharFrontModalOpen) {
            if (!this.aadharDetails.dob) requiredFields.push('DOB');
            if (!this.aadharDetails.aadharNumber) requiredFields.push('Aadhaar Number');
        }

        if (requiredFields.length > 0) {
            this.showToast('Missing Required Fields', `Please fill: ${requiredFields.join(', ')}`, 'error');
            this.isConformationLoading = false;
            return;
        }

        const inputMap = {
            aadharFirstName: this.aadharDetails.firstName,
            aadharMiddleName: this.aadharDetails.middleName,
            aadharLastName: this.aadharDetails.lastName,
            dob: this.aadharDetails.dob,
            aadharNumber: this.aadharDetails.aadharNumber,
            mobileNumber: this.aadharDetails.mobileNumber,
            applicantId: this.selectedRecordId,
            loanId: this.recordId,
            aadharPinCode: this.aadharDetails.postalCode,
            aadharFullAddress: this.aadharDetails.aadharFullAddress,
            frontConfirmed: this.isAadharFrontModalOpen ? 'true' : 'false',
            backConfirmed: this.isAadharBackModalOpen ? 'true' : 'false',
            addressType: this.aadharDetails.addType,
            addressOwnership: this.aadharDetails.aadharAddress?.addressOwnership
        };
       
       // Keep track of which modal is open before the save call
    const wasFrontModalOpen = this.isAadharFrontModalOpen;
        saveAadharDetailsManually({ inputMap })
            .then(async result => {
                console.log('Aadhaar Save Result:', result);
                this.showToast('Success', 'Aadhaar details saved successfully.', 'success');
                // Now, explicitly manage the UI state based on which modal was confirmed.
            if (wasFrontModalOpen) {
                // If we just confirmed the FRONT, enable the BACK upload.
                this.isAadharFrontModalOpen = false;
                this.disableFrontUpload = true;
                this.disableBackUpload = false; // Enable back upload
                this.ShowConfirmAadharUpload = false;
                if (!this.isHLUser) {
                    this.showDeleteAadhaarButton = true; // Show the delete button
                }

            }else  {
                // If we just confirmed the BACK, disable everything and show the final table.
                this.isAadharBackModalOpen = false;
                this.disableUploadOption = true;
                this.checkCustomerDedupe(); // Trigger dedupe check after final confirmation
                
            }
            
                this.getApplicantDetails();
                if (this.aadharDetails.postalCode == null || this.aadharDetails.postalCode == undefined || this.aadharDetails.postalCode == '') {
                    this.isAadharDetails = true;
                    this.disableUploadOption = false;

                }
                //this.checkSFDedupe();

                if (this.aadharDetails.postalCode != null && this.aadharDetails.postalCode != undefined && this.aadharDetails.postalCode != '') {
                    this.getApplicantDetails();
                    this.isAadharDetails = true;
                    this.disableUploadOption = true;
                    this.disableBackUpload = true;
                    try {
                         //this.checkSFDedupe();
                        //HL-Ishi-24/09
                        this.checkCustomerDedupe();
                        //HL-Ishi-24/09
                    } catch (err) {
                        console.error('Error in checkSFDedupe:', err);
                        this.showToast('Error', 'Error during deduplication check.' + err, 'error');
                    }
                }

            })
            .catch(error => {
                const message = error?.body?.message || error?.message || 'Failed to save Aadhaar details.';
                console.error('Aadhaar Save Error:', error);
                this.showToast('Error', message, 'error');
            })
            .finally(() => {
                this.isConformationLoading = false;
            });
    }
    disConnectedCallback() {
        this.isAadharFrontModalOpen = false;
        this.getApplicantDetails();
    }
    closeModal() {
        this.isAadharFrontModalOpen = false;
        this.isAadharBackModalOpen = false;
    }

    async getApplicantDetails() {
        console.log('applicantid 343', this.applicantId)
        await getApplicantDetailsOCR({
            applicantId: this.applicantId
        })
            .then(result => {
                console.log('reuslt in aadhar details cmp', JSON.stringify(result));
                if (result.isAadharDetails == true) {
                    this.isAadharDetails = true;
                }
                console.log('result in getApplicantDetails', JSON.stringify(result));
                console.log('result.aadhar==>', result.aadharNumberUnmasked);

                this.aadharDetails.aadharNumber = result.aadharNumberUnmasked;
                this.aadharDetails.aadharNumberMasked = result.aadharNumber;
                this.aadharDetails.firstName = result.aadharFirstName;
                this.aadharDetails.middleName = result.aadharMiddleName;
                this.aadharDetails.lastName = result.aadharLastName;
                this.aadharDetails.dob = result.aadharDob;
                this.aadharDetails.mobileNumber = result.mobileNumber;
                this.aadharDetails.aadharAddress.postalCode = result.aadharPinCode;
                this.stampedAadharNumber = result.aadharNumber;
                this.aadharName = result.aadharName;
                this.aadharDob = result.aadharDob;
                this.aadharFullAddress = result.aadharAddress;
                this.isAadhaarBackOCRConfirmed = result.isAadhaarBackOCRConfirmed;
                this.isAadhaarFrontOCRConfirmed = result.isAadhaarFrontOCRConfirmed;
                this.aadharDetails.aadharAddress.addressLine1 = result.addressLine1;
                this.aadharDetails.aadharAddress.addressLine2 = result.addressLine2;
                this.aadharDetails.aadharAddress.addressLine3 = result.addressLine3;
                this.aadharDetails.aadharAddress.city = result.city;
                this.aadharDetails.aadharAddress.province = result.state;
                this.aadharDetails.aadharAddress.country = result.country;
                this.aadharDetails.aadharAddress.addressOwnership = result.addressOwnership;
                this.aadharDetails.addType = result.addressType;
                if (
                    !result.isAadhaarFrontOCRConfirmed &&
                    !result.isAadhaarBackOCRConfirmed &&
                    result.applicantType === 'Primary Applicant' &&
                    result.customerType === 'Individual'
                ) {
                    if (this.aadharDetails.firstName == null || this.aadharDetails.firstName == undefined || this.aadharDetails.firstName == '') {
                        this.aadharDetails.firstName = result.firstName;
                    }
                    if (this.aadharDetails.middleName == null || this.aadharDetails.middleName == undefined || this.aadharDetails.middleName == '') {
                        this.aadharDetails.middleName = result.middleName;
                    }
                    if (this.aadharDetails.lastName == null || this.aadharDetails.lastName == undefined || this.aadharDetails.lastName == '') {
                        this.aadharDetails.lastName = result.lastName;
                    }
                    if (this.aadharDetails.dob == null || this.aadharDetails.dob == undefined || this.aadharDetails.dob == '') {
                        this.aadharDetails.dob = result.dobORDoi;
                    }
                    if (this.aadharDetails.mobileNumber == null || this.aadharDetails.mobileNumber == undefined || this.aadharDetails.mobileNumber == '') {
                        this.aadharDetails.mobileNumber = result.mobileNumber;
                    }
                }

                if (!this.isAadhaarFrontOCRConfirmed) {
                    this.disableBackUpload = true;
                }
                if (result.aadharNumber != null && result.aadharNumber != '' && result.aadharNumber != undefined) {
                    this.disableFrontUpload = true;
                }
                if (result.aadharNumber != null && result.aadharNumber != '' && result.aadharNumber != undefined && result.aadharPincode == null) {
                    this.disableBackUpload = false;
                    this.disableFrontUpload = true;
                }
                if (result.aadharPinCode != null) {
                    //this.disableBackUpload = true;
                    this.disableUploadOption = true;
                }
                console.log('result.aadharNumber-->', result.aadharNumber);
                if (result.aadharNumber != null && result.aadharNumber.trim() !== '') {
                    //Hl-Ishi
                    if (!this.isHLUser) {
                        this.showDeleteAadhaarButton = true;
                    }

                }
            })
            .catch(error => {
                console.log('error:', JSON.stringify(error));
            })
    }

    getSubStageList() {
        getSubStageList({
            loanId: this.loanId,
            applicableStage: this.passedScreenName
        })
            .then(response => {
                this.getApplicantDetails();
                this.rerenderCmp = true;
                this.stages = response;
                this.activeSection = this.stages[0];
            })
            .catch(error => {
                console.log('Error getting sub stage list:', JSON.stringify(error));
            });
    }
    handleConfirmAadharUpload() {
        console.log('docType->', this.docType);
        if (this.docType && this.docType.toLowerCase().includes('front')) {
            this.isAadharFrontModalOpen = true;
            this.isAadharBackModalOpen = false;
        }
        else if (this.docType && this.docType.toLowerCase().includes('back')) {
            this.isAadharFrontModalOpen = false;
            this.isAadharBackModalOpen = true;
        }
        const scrollOptions = {
            left: 0,
            top: 2,
            behavior: 'smooth'
        }
        window.scrollTo(scrollOptions);
        console.log('handleConfirmAadharUpload called', this.docType);

    }

    handleAadharFrontUpload(event) {
        const file = event.target.files[0];
        this.readFileAsBase64(file, 'front');
        this.disableFrontUpload = true;
    }
    handleAadharBackUpload(event) {
        const file = event.target.files[0];
        this.readFileAsBase64(file, 'back');
        this.disableBackUpload = true;
    }
    readFileAsBase64(file, side) {
        if (file) {
            const reader = new FileReader();
            reader.onload = () => {
                const base64 = reader.result.split(',')[1];
                if (side === 'front') {
                    this.frontBase64 = base64;
                } else {
                    this.backBase64 = base64;
                }
            };
            reader.readAsDataURL(file);
        }
    }

    /*handleUploadAadharFinished(event) {
        const file = event.target.files[0];
        this.docType = '';
        this.docType = event.target.dataset.type;
        //Aadhar masking failure_Ayushi
        this.oldContentVersionIdForManualFlow = this.contentDocId; 
        this.isloading = true;
        if (!file) return;
        console.log('docType==>', this.docType);
        console.log('fileType==>', file.type);
        console.log('file=:' + JSON.stringify(file));
        if (file.type == 'application/pdf' || file.type.startsWith('image')) {
            const reader = new FileReader();

            reader.onload = () => {
                this.fileName = file.name;
                this.uploadedAadharUrl = reader.result; // Base64 string
                // this.contentDocId = this.uploadedAadharUrl.split(',')[1];
                setTimeout(() => {
                    this.createContentVersion();
                }, 500);

                console.log('this.uploadedAadharUrl:', this.uploadedAadharUrl);
                console.log('file.type:', file.type);

                // this.isImage = file.type.startsWith('image');
                // this.isPDF = file.type === 'application/pdf';
                this.dataType = file.type;
            };

            reader.readAsDataURL(file);
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please upload file in correct format',
                    variant: 'error',
                }),
            );
        }

    }*/
      
    handleUploadAadharFinished11(event) {
        const uploadedFiles = event.detail.files;
        if (!uploadedFiles || uploadedFiles.length === 0) return;

        const file = uploadedFiles[0];
        this.contentDocId = file.documentId;
        this.fileName = file.name;
        this.docType = event.target.dataset.type;
        this.isloading = true;

        console.log('Uploaded Aadhaar File:', file);

        // ✅ Determine data type based on extension
        const fileNameLower = this.fileName.toLowerCase();
        this.dataType = fileNameLower.endsWith('.pdf')
            ? 'application/pdf'
            : (fileNameLower.endsWith('.jpg') || fileNameLower.endsWith('.jpeg'))
            ? 'image/jpeg'
            : 'unknown';

        console.log('fileNameLower:', fileNameLower);

        // ❌ Validate file type
        if (!(fileNameLower.endsWith('.pdf') || fileNameLower.endsWith('.jpg') || fileNameLower.endsWith('.jpeg'))) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please upload a PDF or JPG/JPEG file only.',
                    variant: 'error',
                })
            );
            this.isloading = false;
            return;
        }

        // ✅ Validate file size via Apex
        getFileSize({ contentDocumentId: this.contentDocId })
            .then(result => {
                console.log('File Size Result:', result);
                const MAX_SIZE = 2 * 1024 * 1024; // 2 MB
                const size = result.size;
                this.contentVersionId = result.contentVersionId;
               // this.uploadedAadharUrl = 'data:application/octet-stream;base64,' + result.base64Data;
                this.base64Data = result.base64Data;

                if (size > MAX_SIZE) {
                    deleteUploadedFile({ contentDocumentId: this.contentDocId })
                        .then(() => {
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: 'File size must be less than or equal to 2 MB. File deleted.',
                                    variant: 'error',
                                })
                            );
                            this.isloading = false;
                        })
                        .catch(err => {
                            console.error('Error deleting large file:', err);
                            this.isloading = false;
                        });
                    return;
                }

                // ✅ File validated successfully → Call OCR
                console.log('Aadhaar file validated successfully:', this.fileName);
                setTimeout(() => {
                    this.createDocumentDetailsRecord();
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
                this.isloading = false;
            });
    }

    handleUploadAadharFinished(){
        this.showToast('Success', 'Aadhar details saved successfully.', 'success');
        
        this.applicantId = 'a05dN00000Ddua3QAB';
        //this.getApplicantDetails();
        this.aadharDetails = false;
        this.disableUploadOption = true;
        this.isAadharDetailsUploads = true;
        // ____GenAI: Generated code starts here____
        // Reset upload/manual UI flags so only the hardcoded Aadhar Details
        // table (isAadharDetailsUploads) is visible once the upload finishes.
        this.showAadharUploadOption = false;
        this.showManualAadharFillOption = false;
        // __________________________GenAI: Generated code ends here______________________________
    }

    /* ____GenAI: Generated code starts here____ */
    get showAadharDetailsSection() {
        return this.isAadharDetails && !this.isAadharDetailsUploads;
    }
    /* __________________________GenAI: Generated code ends here______________________________ */
    createContentVersion() {
        this.ShowLoader = true;
        const base64Data = this.uploadedAadharUrl.split(',')[1];
        this.base64Data = this.uploadedAadharUrl.split(',')[1];
        console.log('base64Data--', base64Data);
        createContentVersion({
            base64Data: base64Data,
            fileName: this.fileName
        })
            .then(result => {
                console.log('result: 470', result);
                this.contentVersionId = result.contentDocId;
                this.contentDocId = result.contentVerId;
                //this.showConfirmButton = true;
                this.showAddManualDetailsButton = false;
                setTimeout(() => {

                    this.createDocumentDetailsRecord();

                }, 200);
            })
            .catch(error => {
                console.log('error:', JSON.stringify(error));
            })
    }
    createDocumentDetailsRecord() {
        const inputMap = {
            'loanId': this.recordId,
            'applicantId': this.selectedRecordId,
            'docType': this.docType,
        }
           console.log('result: 505', inputMap);
        createDocumentDetailsRecord({
            inputMap: inputMap
        })
            .then(response => {
                console.log('response in createDocumentDetails', response.documentDetailsRecordId);
                const docRecordId = response.documentDetailsRecordId;
                this.documentId = docRecordId;
                let isManualMaskedUpload = false;
        if (this.docType.toLowerCase().includes('front')) {
            isManualMaskedUpload = this.checkedFront;
        } else if (this.docType.toLowerCase().includes('back')) {
            isManualMaskedUpload = this.checkedBack;
        }

        /*if (isManualMaskedUpload) {
            // BYPASS OCR: User has checked the box for manual upload.
            // BYPASS OCR: User has checked the box for manual upload.
    this.isloading = true; // Keep the spinner active

    // 1. Prepare the record update
    const fields = {};
    fields['Id'] = this.documentId;
    fields['Content_Document_Id__c'] = this.contentVersionId; // The ID of the manually uploaded file
    fields['Status__c'] = 'Uploaded'; // Set status to match the successful flow
    fields['Aadhar_Masked_Source__c'] = 'Manual'; // Mark as manually handled

    const recordInput = { fields };

    // 2. Call updateRecord to link the new file
    updateRecord(recordInput)
        .then(() => {
            // 3. Now that the record is updated, proceed to the confirmation screen
            this.showToast('Success', 'Manually masked document saved.', 'success');

            this.uploadedAadharUrl = '/sfc/servlet.shepherd/version/download/' + this.contentDocId;
            this.isImage = this.dataType.startsWith('image');
            this.isPDF = this.dataType === 'application/pdf';

            this.isloading = false;
            this.ShowLoader = false;
            
            this.handleConfirmAadharUpload(); // Open confirmation modal AFTER saving
        })
        .catch(error => {
            this.isloading = false;
            this.ShowLoader = false;
            this.showToast('Error', 'Failed to save the manually uploaded document. ' + error.body.message, 'error');
            console.error('Error on manual masked update:', error);
        });*/
        //Aadhar Masking failure-Ayushi
        if (isManualMaskedUpload) {
    this.isloading = true; // Keep spinner active

    // Call the new Apex method to handle the manual file link and cleanup
    linkManualDocumentAndUpdate({
        docDetailId: this.documentId,
        newContentVersionId: this.contentDocId, // ID of the new manually uploaded file
        oldContentVersionId: this.oldContentVersionIdForManualFlow // ID of the old failed file
    })
    .then(() => {
        // Now that the file is correctly linked and cleaned up, proceed to confirmation
        this.showToast('Success', 'Manually masked document saved successfully.', 'success');
        if(window.location.origin.includes('my.site.com')){
             this.uploadedAadharUrl =  `${window.location.origin}/losportal/sfc/servlet.shepherd/document/download/${this.contentDocId}`;
        }
        else{
             this.uploadedAadharUrl = '/sfc/servlet.shepherd/version/download/' + this.contentDocId;
        }
       
        this.isImage = this.dataType.startsWith('image');
        this.isPDF = this.dataType === 'application/pdf';

        this.isloading = false;
        this.ShowLoader = false;

        this.handleConfirmAadharUpload(); // Open confirmation modal
    })
    .catch(error => {
        this.isloading = false;
        this.ShowLoader = false;
        this.showToast('Error', 'Failed to save the manually uploaded document.', 'error');
        console.error('Error in linkManualDocumentAndUpdate:', error);
    });

        } else {
                setTimeout(() => {

                    this.callOCRApi();

                }, 200);
              }   
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
            'docType': this.docType,
            'processName': 'Loan Applicant OCR',
            'uploadedFileName': this.fileName,
            'contentVersionId': this.contentDocId,
            'sector': this.selectedConstitution,
            'documentId': this.documentId
        }
        console.log('inputMap -->' + JSON.stringify(inputMap));
        initiateAPIRequest({
            inputMap: inputMap
        })
            .then(response => {
                console.log('response--' + JSON.stringify(response));
                this.ShowLoader = false;
                //this.panDetailsConfirmed = false;
                this.showConfirmButton = false;
                this.showAddManualDetailsButton = true;

                if (response.includes('Error:')) {
                    this.errorList = response;
                    this.showError = true;
                    this.showToast('Error', response, 'error');
                    this.ShowLoader = false;
                    this.isloading = false;
                    
                    if (response.includes('Error: Aadhar has not been masked properly.')) {
                    if (this.docType === 'Aadhaar Front') {
                        this.showcheckBoxMaskingManualFront = true;
                        this.checkedFront = false;
                    } else if (this.docType === 'Aadhaar Back') {
                        this.showcheckBoxMaskingManualBack = true;
                        this.checkedBack = false;
                    }
                }
            
            

                } else {
                    console.log('response-->', response);
                    const contentVersionIndex = response.indexOf('ContentVersion:');
                    const ocrJsonString = response.substring(0, contentVersionIndex).trim();
                    const cvString = response.substring(contentVersionIndex).trim();
                    console.log('ocrJsonString--' + JSON.stringify(ocrJsonString));
                    console.log('cvString--' + cvString);
                    var paresedCVString = cvString.split('ContentDocumentId=')[1].split(',')[0];
                    console.log('cvString--' +paresedCVString);
                    this.parsedResponse = JSON.parse(ocrJsonString);
                    console.log('response--' + JSON.stringify(this.parsedResponse));
                    if (this.parsedResponse.statusCode == 101) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'OCR Successfull!',
                                variant: 'success',
                            }),
                        )
                        if (
                            !this.parsedResponse ||
                            !this.parsedResponse.result ||
                            !Array.isArray(this.parsedResponse.result.documents) ||
                            this.parsedResponse.result.documents.length === 0
                        ) {
                            this.showToast('Error', 'No OCR Document found', 'error');
                            return;
                        }
                        const confidencePercent = (conf) => typeof conf === 'number' && !isNaN(conf) ? (conf * 100).toFixed(2) + '%' : '';
                        const documents = this.parsedResponse.result.documents;
                        documents.forEach(doc => {
                            const ocr = doc.ocrData || {};
                            const subtype = doc.subType?.toLowerCase() || '';

                            // Handle front side (name, dob, aadhar number, etc.)
                            if (subtype.includes('front')) {
                                console.log('Front side OCR data:', ocr);
                                this.ShowConfirmAadharUpload = true;
                                this.docType = 'front';
                                const fullName = ocr.name?.value?.trim() || '';
                                const nameParts = fullName.split(' ').filter(n => n);

                                this.aadharDetails.firstName = nameParts[0] || '';
                                this.aadharDetails.middleName = nameParts.length === 3 ? nameParts[1] : '';
                                this.aadharDetails.lastName = nameParts.length >= 2 ? nameParts[nameParts.length - 1] : '';

                                console.log('name confidence', confidencePercent(ocr.name?.confidence));
                                this.aadharDetails.firstNameConfidence = confidencePercent(ocr.name?.confidence);
                                this.aadharDetails.middleNameConfidence = confidencePercent(ocr.name?.confidence);
                                this.aadharDetails.lastNameConfidence = confidencePercent(ocr.name?.confidence);
                                console.log('confidence score->', this.aadharDetails.firstNameConfidence);
                                console.log('confidenc2 ->', this.aadharDetails.middleNameConfidence);

                                if (ocr.dob?.value) {
                                    const input = ocr.dob.value.replace(/[^\x00-\x7F]/g, '').trim(); // remove hidden unicode chars
                                    const parts = input.split('/').map(p => p.trim());

                                    if (parts.length === 3) {
                                        const [dd, mm, yyyy] = parts;
                                        // validate lengths to avoid errors
                                        if (dd.length === 2 && mm.length === 2 && yyyy.length === 4) {
                                            // set in ISO format for lightning-input
                                            this.aadharDetails.dob = `${yyyy}-${mm}-${dd}`;
                                        } else {
                                            this.aadharDetails.dob = '';
                                        }
                                    } else {
                                        this.aadharDetails.dob = '';
                                    }
                                } else {
                                    this.aadharDetails.dob = '';
                                }
                                this.aadharDetails.dobConfidence = confidencePercent(ocr.dob?.confidence);
                                console.log('dob:', this.aadharDetails.dob);
                                console.log('dob confidence:', this.aadharDetails.dobConfidence);

                                this.aadharDetails.aadharNumber = ocr.aadhaar?.value || '';
                                this.aadharDetails.aadharNumberConfidence = confidencePercent(ocr.aadhaar?.confidence);

                                this.aadharDetails.mobileNumber = ocr.mobile?.value || '';
                                this.aadharDetails.mobileNumberConfidence = confidencePercent(ocr.mobile?.confidence);
                                this.isAadharFrontModalOpen = true;
                                console.log('998--->', this.isAadharFrontModalOpen);
                                this.isAadharBackModalOpen = false;

                                setTimeout(() => {
                                    const redirecttoaadharevent = new CustomEvent("callaadhardetails", {
                                        detail: {
                                            value: this.recordId,
                                            name: 'Aadhar Details',
                                            currentAppSeq: this.currentAppSeq,
                                            appDetId: this.selectedRecordId
                                        }
                                    });
                                    this.dispatchEvent(redirecttoaadharevent);

                                }, 200);
                            }

                            // Handle back side (address)
                            if (subtype.includes('back')) {
                                console.log('Back side OCR data:', ocr);
                                this.ShowConfirmAadharUpload = true;
                                this.docType = 'back';
                                this.aadharDetails.aadharFullAddress = ocr.address?.value || '';

                                this.aadharDetails.aadharAddress = {
                                    addressLine1: ocr.addressLine1?.value || '',
                                    addressLine2: ocr.addressLine2?.value || '',
                                    addressLine3: ocr.addressLine3?.value || '',
                                    city: ocr.city?.value || '',
                                    province: ocr.province?.value || '',
                                    postalCode: ocr.pin?.value || '',
                                    country: ocr.country?.value || ''
                                };
                                console.log('aadhar address confidence:', confidencePercent(ocr.address?.confidence));
                                this.aadharDetails.addressConfidence = confidencePercent(ocr.address?.confidence);
                                this.aadharDetails.pinCodeConfidence = confidencePercent(ocr.pin?.confidence);
                                this.isAadharBackModalOpen = true;
                                this.isAadharFrontModalOpen = false;
                            }
                        });
                    }
                    this.isImage = this.dataType.startsWith('image');
                    this.isPDF = this.dataType === 'application/pdf';
                    const contentVersionIdMatch = cvString.match(/Id=(\w{15,18})/);
                    if (contentVersionIdMatch && contentVersionIdMatch[1]) {
                        const contentVersionId = contentVersionIdMatch[1];
                        console.log('contentVersionId: 814', this.contentVersionId);
                        //this.contentDocId = contentVersionId;')
                        if(window.location.origin.includes('my.site.com')){
                             this.uploadedAadharUrl = `${window.location.origin}/losportal/sfc/servlet.shepherd/document/download/${paresedCVString}`
                            
                        }
                        else{
                             this.uploadedAadharUrl = '/sfc/servlet.shepherd/version/download/' + contentVersionId; //+ this.contentDocId;
                        }
                       
                    }
                    console.log('this.uploadedAadharUrl 369 :', this.uploadedAadharUrl);
                    this.isloading = false;
                    //this.refreshRecordPage();

                }
            })
            .catch(error => {
                console.log('error-----', error);
                this.showToast('Error', 'OCR failed. Please confirm the details manually.', 'error');
                this.manualcmp = false;
                this.showAddManualDetailsButton = false;
                this.panDetailsConfirmed = false;
                this.showConfirmButton = true;
                this.ShowLoader = false;
                this.isloading = false;
                this.isModalOpen = true;
                this.isImage = this.dataType.startsWith('image');
                this.isPDF = this.dataType === 'application/pdf';
                if(window.location.origin.includes('my.site.com')){
                    this.uploadedAadharUrl = `${window.location.origin}/losportal/sfc/servlet.shepherd/document/download/${this.contentVersionId}`
                }
                else{
                   this.uploadedAadharUrl = '/sfc/servlet.shepherd/version/download/' + this.contentDocId;
                }
                    
              
                console.log('this.uploadedAadharUrl 369 :', this.uploadedAadharUrl);
            })
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
        console.log('Record page refreshed');
        window.scrollTo({ block: 'center', behavior: 'smooth' });
    }

    refreshRecordPageNew() {
        return new Promise((resolve) => {
            // perform navigation (fire-and-forget)
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'Opportunity',
                    actionName: 'view'
                }
            }, true);

            // resolve when page becomes visible again (if it changes),
            // otherwise resolve after a short fallback timeout.
            const onVisibility = () => {
                if (document.visibilityState === 'visible') {
                    document.removeEventListener('visibilitychange', onVisibility);
                    window.scrollTo({ block: 'center', behavior: 'smooth' });
                    resolve();
                }
            };

            document.addEventListener('visibilitychange', onVisibility);

            // fallback: resolve after 700ms if visibilitychange doesn't fire
            setTimeout(() => {
                document.removeEventListener('visibilitychange', onVisibility);
                window.scrollTo({ block: 'center', behavior: 'smooth' });
                resolve();
            }, 700);
        });
    }

    handleInputBlurDate(event) {
        const currentId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;
        if (field == 'dob') {
            let currentDate = new Date().toJSON().slice(0, 10);
            console.log('todayDate----', new Date());
            console.log('this.dateofBirth----', value);
            if (value >= currentDate) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Date of birth Cannot be future/current date',
                    variant: 'Error',
                }));
                this.template.querySelector(`[data-field="${field}"]`).value = '';
                return;
            } else {
                this.aadharDetails = {
                    ...this.aadharDetails,
                    [field]: event.target.value
                };
            }
        }
    }
    handleInputAadharChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;
        console.log('fieldName', field);
        console.log('value below field ', value.length);

        if (field === 'addressLine1') {
            this.aadharDetails.aadharAddress.addressLine1 = value;
        }
        else if (field === 'addressLine2') {
            this.aadharDetails.aadharAddress.addressLine2 = value;
        }
        else if (field === 'addressLine3') {
            this.aadharDetails.aadharAddress.addressLine3 = value;
        }
         else if (field === 'addressOwnership') {
            this.aadharDetails.aadharAddress.addressOwnership = value;
        }
        else if (field === 'addressType') {
            this.aadharDetails.addType = value;
            this.aadharDetails.aadharAddress.addType = value;
        }
        else if (field === 'postalCode' && value) {
            this.aadharDetails.aadharAddress.postalCode = value;
            console.log('value length:', value.length);
            if (value && value.length === 6) {
                console.log('value:', value);
                console.log(
                    'this.aadharDetails.aadharAddress.postalCode:', this.aadharDetails.aadharAddress.postalCode);
                getPincodeDetails({ pinCode: this.aadharDetails.aadharAddress.postalCode })
                    .then(result => {
                        if (result) {
                            console.log('getPincodeDetails result:', result);
                            this.selectedPinCodeMasterId = result.Id;
                            this.aadharDetails.aadharAddress.city = result.City__r.Name;
                            this.aadharDetails.aadharAddress.province = result.City__r.State__c;
                            this.aadharDetails.aadharAddress.country = result.City__r.Country__c;
                        } else {
                            // Optional: Clear fields or show error
                            this.clearAddressFields();
                            this.showToast('Invalid Pincode', 'Entered pincode does not exist in the Database. Contact system admin for assistance.', 'error');
                        }
                    })
                    .catch(error => {
                        console.error(error);
                        this.showToast('Error', 'Failed to fetch address details.', 'error');
                    });
            }
        }
        else if (field == 'aadharNumber') {
            if (this.isHLUser) {
                const inputValue = event.target.value;
                const lastCharacter = inputValue.charAt(inputValue.length - 1);
                console.log('inputValue -->' + inputValue);
                console.log('lastCharacter -->' + lastCharacter);

                if (isNaN(lastCharacter) && (inputValue.length > this.lengthAadharNumber)) {
                    if (this.maskedAadharNumber != undefined) {
                        event.target.value = this.maskedAadharNumber;
                    }
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter valid aadhar number',
                            variant: 'error',
                        }),
                    );
                    return;
                }
                else {
                    if (inputValue.length > this.lengthAadharNumber) {
                        console.log('Inc..');
                        this.originalAadharNumber = this.originalAadharNumber + lastCharacter;
                        console.log('this.originalAadharNumber -->' + this.originalAadharNumber);
                    } else {
                        console.log('Desc..');
                        this.originalAadharNumber = this.originalAadharNumber.slice(0, -1);
                        if (inputValue.length == 0) {
                            this.originalAadharNumber = '';
                        }
                        console.log('this.originalAadharNumber -->' + this.originalAadharNumber);
                    }
                    console.log('inputValue.length -->' + inputValue.length);
                    console.log('lengthAadharNumber -->' + this.lengthAadharNumber);

                    this.lengthAadharNumber = inputValue.length;
                    console.log('inputValue.length -->' + inputValue.length);
                    console.log('lengthMobileNumber -->' + this.lengthAadharNumber);

                    this.maskedAadharNumber = event.target.value;
                    console.log('MobileNumber -->' + isNaN(event.target.value));
                    console.log('MobileNumber -->' + this.maskedAadharNumber);
                    this.aadharDetails = {
                        ...this.aadharDetails,
                        [field]: this.maskedAadharNumber
                    };

                    if (this.maskedAadharNumber.length <= 8) {
                        console.log('X'.repeat(this.maskedAadharNumber.length));
                        event.target.value = 'X'.repeat(this.maskedAadharNumber.length);
                        this.maskedAadharNumber = 'X'.repeat(this.maskedAadharNumber.length);
                        this.aadharDetails = {
                            ...this.aadharDetails,
                            [field]: this.maskedAadharNumber
                        };

                    } else {
                        console.log('XXXXXX' + this.maskedAadharNumber.slice(8));
                        event.target.value = 'XXXXXXXX' + this.maskedAadharNumber.slice(8);
                        this.maskedAadharNumber = 'XXXXXXXX' + this.maskedAadharNumber.slice(8);
                        this.aadharDetails = {
                            ...this.aadharDetails,
                            [field]: this.maskedAadharNumber
                        };
                    }
                }
            }
            else {
                this.aadharDetails = {
                    ...this.aadharDetails,
                    [field]: value
                };
            }
        }
        else {
            this.aadharDetails = {
                ...this.aadharDetails,
                [field]: value
            };
        }
    }

    clearAddressFields() {
        this.selectedPinCodeMasterId = '';
        this.aadharDetails.aadharAddress.city = '';
        this.aadharDetails.aadharAddress.province = '';
        this.aadharDetails.aadharAddress.country = '';
    }

    handleAadharUploadOrFillChange(event) {
        this.selectedAadharUploadOrFillValue = event.target.value;
        console.log('handle AadharUpload called', this.selectedAadharUploadOrFillValue);
        if (this.selectedAadharUploadOrFillValue == 'Upload') {
            this.showAadharUploadOption = true;
            this.showManualAadharFillOption = false;
            this.manualAadharcmp = false;
        }
        else if (this.selectedAadharUploadOrFillValue == 'Manual') {
            //HL-Ishi-11/9/2025
            this.showAadharUploadOption = false;
            this.showManualAadharFillOption = true;
            this.manualAadharcmp = true;
            console.log('828------');
            this.isModalOpen = false;
        }
        this.getApplicantDetails();
    }

    handleAddAadharDetailsManually(event) {
        this.isManualloading = true;

        if (!this.aadharDetails.firstName || this.aadharDetails.firstName.trim() === '') {
            this.showToast('Validation Error', 'Please Fill the First Name.', 'error');
            this.isManualloading = false;
            return;
        }

        if (!this.aadharDetails.lastName || this.aadharDetails.lastName.trim() === '') {
            this.showToast('Validation Error', 'Please Fill the Last Name.', 'error');
            this.isManualloading = false;
            return;
        }
        if (!this.aadharDetails.dob || this.aadharDetails.dob.trim() === '') {
            this.showToast('Validation Error', 'Please Fill Date of Birth.', 'error');
            this.isManualloading = false;
            return;
        }

        if (!this.aadharDetails.aadharNumber || this.aadharDetails.aadharNumber.trim() === '') {
            this.showToast('Validation Error', 'Please Fill Aadhar Number.', 'error');
            this.isManualloading = false;
            return;
        }

        if (!this.isHLUser && !this.aadharDetails.aadharNumber.match(/^[2-9][0-9]{11}$/)) {
            this.showToast('Validation Error', 'Please enter Aadhar Number in correct format.', 'error');
            this.isManualloading = false;
            return;
        }
        if (this.isHLUser && this.aadharDetails.aadharNumber.length != 12) {
            this.showToast('Validation Error', 'Please enter Aadhar Number in correct format.', 'error');
            this.isManualloading = false;
            return;
        }

        if (!this.aadharDetails.mobileNumber || this.aadharDetails.mobileNumber.trim() === '') {
            this.showToast('Validation Error', 'Please Fill Mobile Number.', 'error');
            this.isManualloading = false;
            return;
        }

        this.dobError = this.validateDob(this.aadharDetails.dob);
        if (this.dobError !== '') {
            this.showToast('Validation Error', this.dobError, 'error');
            this.isManualloading = false;
            return;
        }

        if (!this.aadharDetails.mobileNumber.match(/^[6-9]\d{9}$/)) {
            this.showToast('Validation Error', 'Please enter Mobile Number in correct format.', 'error');
            this.isManualloading = false;
            return;
        }
        if (!this.aadharDetails.aadharAddress.addressLine1 || this.aadharDetails.aadharAddress.addressLine1.trim() === '') {
            this.showToast('Validation Error', 'Please Fill the Address. Line 1', 'error');
            this.isManualloading = false;
            return;
        }
        if (!this.aadharDetails.aadharAddress.addressLine2 || this.aadharDetails.aadharAddress.addressLine2.trim() === '') {
            this.showToast('Validation Error', 'Please Fill the Address. Line 2', 'error');
            this.isManualloading = false;
            return;
        }
        if (!this.aadharDetails.aadharAddress.postalCode || this.aadharDetails.aadharAddress.postalCode.trim() === '' || this.selectedPinCodeMasterId == '') {
            this.showToast('Validation Error', 'Please Fill the PinCode', 'error');
            this.isManualloading = false;
            return;
        }
        if (!this.aadharDetails.aadharAddress.addressOwnership) {
            this.showToast('Validation Error', 'Please select Address Ownership.', 'error');
            this.isManualloading = false;
            return;
        }

        const inputMap = {
            'aadharFirstName': this.aadharDetails.firstName,
            'aadharLastName': this.aadharDetails.lastName,
            'aadharMiddleName': this.aadharDetails.middleName,
            'applicantId': this.selectedRecordId,
            'loanId': this.recordId,
            'dob': this.aadharDetails.dob,
            'aadharNumber': this.aadharDetails.aadharNumber,
            'mobileNumber': this.aadharDetails.mobileNumber,
            'addressLine1': this.aadharDetails.aadharAddress.addressLine1,
            'addressLine2': this.aadharDetails.aadharAddress.addressLine2,
            'addressLine3': this.aadharDetails.aadharAddress.addressLine3,
            'aadharCity': this.aadharDetails.aadharAddress.city,
            'aadharState': this.aadharDetails.aadharAddress.province,
            'pinCodeMasterRecordId': this.selectedPinCodeMasterId,
            'addressType': this.aadharDetails.addType,
            'addressOwnership': this.aadharDetails.aadharAddress.addressOwnership
        };
        console.log('input map values before saving ==>', JSON.stringify(inputMap));
        saveAadharDetailsManually({ inputMap })
            .then(async result => {
                if (result) {
                    this.isManualloading = false;
                    console.log('result in saveAadharDetailsManually:', JSON.stringify(result));

                    this.selectedRecordId = Object.keys(result)[0];
                    this.applicantId = Object.keys(result)[0];
                    this.manualAadharcmp = false;
                    this.isModalOpen = false;
                    
                    this.showToast('Success', 'Aadhar details saved successfully.', 'success');

                    await this.getApplicantDetails();
                    this.isAadharDetails = true;
                    this.disableUploadOption = true;
                        
                    this.showManualAadharFillOption = false;
                    const middleSection = this.template.querySelector('[data-id="middleSection"]');
                    if (middleSection) {
                        middleSection.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    }
                    //this.refreshRecordPage();
                    // this.scrollToMiddle();
                    /*    const scrollOptions = {
                       left: 0,
                       top: document.body.scrollHeight / 2, // Calculate the middle of the page
                       behavior: 'smooth'
                   };
                   window.scrollTo(scrollOptions);*/
                    try {
                        //await this.checkSFDedupe();
                        //HL-Ishi-24/09
                        this.checkCustomerDedupe();
                        //HL-Ishi-24/09
                    } catch (err) {
                        console.error('Error in checkSFDedupe:', err);
                        this.showToast('Error', 'Error during deduplication check.' + err, 'error');
                    }

                }
            })
            .catch(error => {
                const errorMessage = error?.body?.message || 'An unexpected error occurred'; //error.body.message.split("FIELD_CUSTOM_VALIDATION_EXCEPTION,")[1]?.split(":")[0]?.trim();
                this.showToast('Error', errorMessage, 'error');
                this.isManualloading = false;
            })
            .finally(() => {
                this.isManualloading = false;
            });
    }


    validateDob(dateStr) {
        if (!dateStr) {
            return 'Please select a valid date';
        }
        const selected = new Date(dateStr);
        const today = new Date();

        // Remove time components
        selected.setHours(0, 0, 0, 0);
        today.setHours(0, 0, 0, 0);
        console.log('selected ', selected);
        console.log('today', today);
        if (selected >= today) {
            console.log('selected==>', selected);
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

    closeAadharModalManual() {
        this.manualAadharcmp = false;
    }

    // checkSFDedupe() {
    //     this.isloading = true;
    //     checkSFDedupe({
    //         applicantId: this.selectedRecordId,
    //         loanId: this.recordId,
    //     })
    //         .then(result => {
    //             this.isloading = false;
    //             console.log('result checkSFDedupe:', JSON.stringify(result));
    //             this.custId = result.custId;


    //             if (this.custId == null || this.custId == '' || this.custId == null) {
    //                 this.showDuplicate = false;
    //                 const valueChangeEvent2 = new CustomEvent("refreshapplicantlist", {
    //                     detail: {
    //                         value: this.recordId,
    //                         name: 'Applicant\'s Basic Information',
    //                         currentAppSeq: this.currentAppSeq,
    //                         appDetId: this.selectedRecordId
    //                     }
    //                 });
    //                 this.dispatchEvent(valueChangeEvent2);
    //                 setTimeout(() => {
    //                     const valueChangeEvent = new CustomEvent("callbasicinformation", {
    //                         detail: {
    //                             value: this.recordId,
    //                             name: 'Applicant\'s Basic Information',
    //                             currentAppSeq: this.currentAppSeq,
    //                             appDetId: this.selectedRecordId
    //                         }
    //                     });
    //                     this.dispatchEvent(valueChangeEvent);

    //                 }, 200);

    //             }
    //             else {
    //                 this.showDuplicate = true;
    //                 console.log('436this.showDuplicate', this.showDuplicate);
    //                 const valueChangeEvent2 = new CustomEvent("refreshapplicantlist", {
    //                     detail: {
    //                         value: this.recordId,
    //                         name: 'Dedupe',
    //                         currentAppSeq: this.currentAppSeq,
    //                         appDetId: this.selectedRecordId
    //                     }
    //                 });
    //                 this.dispatchEvent(valueChangeEvent2);
    //                 setTimeout(() => {
    //                     console.log('447this.showDuplicate', this.showDuplicate);
    //                     const valueChangeEvent = new CustomEvent("recallapplicantmethod", {
    //                         detail: {
    //                             value: this.recordId,
    //                             name: 'Dedupe',
    //                             custId: this.custId,
    //                             currentAppSeq: this.currentAppSeq,
    //                             appDetId: this.selectedRecordId
    //                         }
    //                     });
    //                     this.dispatchEvent(valueChangeEvent);
    //                 }, 200);

    //             }
    //             //this.callCkyc();
    //             //this.getApplicantDetails();


    //         })
    //         .catch(error => {
    //             this.isloading = false;
    //             console.log('error checkSFDedupe:', error);
    //             this.showDuplicate = false;
    //             console.log('showDuplicate:::', this.showDuplicate)
    //             console.log('showDuplicate:::', this.showDuplicate)
    //             this.showDuplicate = false;
    //             const valueChangeEvent2 = new CustomEvent("refreshapplicantlist", {
    //                 detail: {
    //                     value: this.recordId,
    //                     name: 'Applicant\'s Basic Information',
    //                     currentAppSeq: this.currentAppSeq,
    //                     appDetId: this.selectedRecordId
    //                 }
    //             });
    //             this.dispatchEvent(valueChangeEvent2);
    //             setTimeout(() => {
    //                 const valueChangeEvent = new CustomEvent("callbasicinformation", {
    //                     detail: {
    //                         value: this.recordId,
    //                         name: 'Applicant\'s Basic Information',
    //                         currentAppSeq: this.currentAppSeq,
    //                         appDetId: this.selectedRecordId
    //                     }
    //                 });
    //                 this.dispatchEvent(valueChangeEvent);

    //             }, 200);
    //             this.isloading = false;
    //             this.getApplicantDetails();

    //         })

    // }

     checkCustomerDedupe(){
        this.isloading = true;
        let wrapperObj = {
            appId: this.selectedRecordId,  // example Applicant Id
            loanId: this.recordId,      // example Loan Id
        };
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
                    // this.dispatchEvent(valueChangeEvent);
                    
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
             //this.callCkyc();
             //this.getApplicantDetails();
            

            })
        .catch(error => {
            this.isloading = false;
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

    // make sure this method is declared async (you already had that)
    async handleDeleteAadhaarDetailsClick() {
        this.isloading = true;
        const inputMap = {
            applicantId: this.selectedRecordId,
            loanId: this.recordId
        };
        console.log('input map values before deleting ==>', JSON.stringify(inputMap));

        try {
            const result = await deleteAadhaarDetails({ inputMap });
            this.isloading = false;
            console.log('result deleteAadhaarDetails:', JSON.stringify(result));

            if (result) {
                this.showToast('Success', 'Aadhaar details deleted successfully.', 'success');

                // update local state
                this.isAadharDetails = false;
                this.disableUploadOption = false;
                this.manaadharDetails = {
                    firstName: '',
                    middleName: '',
                    lastName: '',
                    aadharNumber: ''
                };
                this.showDeleteAadhaarButton = false;
                this.disableUploadOption = false;
                this.isAadharDetails = true;
                this.disableFrontUpload = false;
                this.disableBackUpload = true;
                this.stampedAadharNumber = '';

                // wait for refreshRecordPageNew to finish (must return a Promise)
                //await this.refreshRecordPageNew();

                // now dispatch event
                this.dispatchEvent(new CustomEvent('callaadhardetails', {
                    detail: {
                        value: this.recordId,
                        name: 'Aadhar Details',
                        currentAppSeq: this.currentAppSeq,
                        appDetId: this.selectedRecordId
                    }
                }));
            }
        } catch (error) {
            this.isloading = false;
            console.error('error deleteAadhaarDetails:', error);
            this.showToast('Error', 'Error in deleting Aadhaar details. Please try again.', 'error');
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
    scrollToMiddle() {
        const scroller =
            document.querySelector('div[role="main"]') || // Lightning main area
            document.scrollingElement || // fallback
            document.documentElement;

        const top = (scroller.scrollHeight - scroller.clientHeight) / 2;
        scroller.scrollTo({ top, behavior: 'smooth' });
    }
    //HL-Ishi-11/9/2025
    handleEdit() {
        this.showAadharUploadOption = false;
        this.showManualAadharFillOption = true;
        this.hideManualDetailsAddButton = true;
        this.manualAadharcmp = true;
        console.log('828------');
        this.isModalOpen = false;
        this.getApplicantDetails();
    }
    handleDelete() {
        this.isloading = true;
        const inputMap = {
            applicantId: this.selectedRecordId,
            loanId: this.recordId
        };
        console.log('input map values before deleting ==>', JSON.stringify(inputMap));

        try {
            const result = deleteAadhaarDetails({ inputMap });
            this.isloading = false;
            console.log('result deleteAadhaarDetails:', JSON.stringify(result));

            if (result) {
                this.showToast('Success', 'Aadhaar details deleted successfully.', 'success');

                // update local state
                this.isAadharDetails = false;
                this.disableUploadOption = false;
                this.aadharDetails = {
                    firstName: '',
                    middleName: '',
                    lastName: '',
                    aadharNumber: ''
                };
                this.showDeleteAadhaarButton = false;
                this.disableUploadOption = false;
                this.isAadharDetails = true;
                this.disableFrontUpload = false;
                this.disableBackUpload = true;
                this.stampedAadharNumber = '';
                this.showAadharUploadOption = false;
                this.showManualAadharFillOption = false;
                this.manualAadharcmp = false;
                setTimeout(() => {
                    this.refreshRecordPage();
                }, 0);


                // wait for refreshRecordPageNew to finish (must return a Promise)
                //await this.refreshRecordPageNew();

                // now dispatch event
                // this.dispatchEvent(new CustomEvent('callaadhardetails', {
                //     detail: {
                //         value: this.recordId,
                //         name: 'Aadhar Details',
                //         currentAppSeq: this.currentAppSeq,
                //         appDetId: this.selectedRecordId
                //     }
                // }));
            }
        } catch (error) {
            this.isloading = false;
            console.error('error deleteAadhaarDetails:', error);
            this.showToast('Error', 'Error in deleting Aadhaar details. Please try again.', 'error');
        }

    }
    refreshRecordPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Opportunity', // change if your object is different
                actionName: 'view'
            }
        }, true);
    }

    handleAddressTypeChange(event) {
        if(this.isHLRelated){
            this.addressTypeChanged = event.detail.value;
            this.checkApplicantAddressType();
        }
        else{
            this.aadharDetails.addType = event.detail.value;
            if (this.aadharDetails.addType !== 'Current') {
                this.aadharDetails.addProof = '';
            }
        }
       
       
    }

   
    handleAckowledgeChangeChange(event){
        const fields = {};
        const side = event.target.dataset.side;
         const isChecked = event.target.checked;

    if (side === 'front') {
        this.checkedFront = isChecked;
    } else if (side === 'back') {
        this.checkedBack = isChecked;
    }
        
        if(isChecked){
            fields['Id'] = this.documentId;
            fields['Is_manual_masking_confirmed__c'] = true;
            fields['Manual_masking_confirmation_user__c'] = this.userName;
        }else{
            fields['Id'] = this.documentId ;
            fields['Is_manual_masking_confirmed__c'] = false;
            fields['Manual_masking_confirmation_user__c'] = '';
        }
        const recordInput = { fields };
        console.log('recordInput----'+JSON.stringify(recordInput));
        
        updateRecord(recordInput)
        .then(() => {
            console.log('before perform action in updateRecords method :');
            //this.template.querySelector('.hidden-input-all').value = null;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Manual masking confirmation changed successfully.',
                    variant: 'success',
                }),
            );
        })
        .catch(error => {
            console.log('Error updating document record --> '+JSON.stringify(error));
        });
    }
    //HL-Ish-11/9/2025
    checkApplicantAddressType(){
        const inputMap ={
            appId : this.applicantId,
            selectedAdd : this.addressTypeChanged
        }
        checkApplicantAddressType({
            inputMap: inputMap
        })
        .then(response => {
            console.log('response in checkApplicantAddressType', response);
            this.isExistingAddressForApplicant=response;
            if(response){
                 this.aadharDetails.addType = null;
                 this.addressTypeChanged=null;
                 this.showToast('Error', 'Address type already exists for this applicant.', 'error');
            }
            else{
                this.aadharDetails.addType = this.addressTypeChanged;
                if (this.aadharDetails.addType !== 'Current') {
                    this.aadharDetails.addProof = '';
                }
            }
        })
        .catch(error => {
            console.log('Error updating document record --> '+JSON.stringify(error));
        });
    }
      fetchProducDetails(){
        var inputMapParam = {
            'oppId': this.recordId
        };
        console.log('recordid----'+this.recordId);
        getProductDetails({inputMap : inputMapParam})
        .then(result =>{
            console.log('result product: '+ JSON.stringify(result));
            this.isHLRelated = result.isHLRelated;
        })
        .catch(error=>{
            console.error('error in getting product: '+ JSON.stringify(error))
        })
    }




}