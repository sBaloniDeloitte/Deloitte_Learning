import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import getAllApplicants from '@salesforce/apex/COMM_SalesLoanLoginController.getAllApplicants';
import callDedupeAPI from '@salesforce/apex/COMM_SalesLoanLoginController.callDedupeAPI';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import quickActionSave from '@salesforce/apex/AHL_LoanApplicationActionController.quickActionSave';
import getNextScreenDetails from '@salesforce/apex/COMM_SalesLoanActionsController.getNextScreenDetails';
import updateStage from '@salesforce/apex/COMM_SalesLoanLoginController.checkSubStageCompletionApplicantInformation';
import isProductAdded from '@salesforce/apex/COMM_SalesLoanLoginController.isProductAdded';
import checkConsent from '@salesforce/apex/COMM_SalesLoanLoginController.checkConsent';
import getScreenDetails from '@salesforce/apex/ScreenGenerationController.getScreenDetails';
import getPicklistValues from '@salesforce/apex/ScreenGenerationController.getPicklistValues';
import savecreateLoanDetails from '@salesforce/apex/ScreenGenerationController.savecreateLoanDetails';
import getFieldDependencies from '@salesforce/apex/ScreenGenerationController.getFieldDependencies';;
import getLoanDetailsFromReadObject from '@salesforce/apex/ScreenGenerationController.getLoanDetailsFromReadObject';
import getLoanDetailsFromStorageObject from '@salesforce/apex/ScreenGenerationController.getLoanDetailsFromStorageObject';
import saveUploadedAddressProof from '@salesforce/apex/ScreenGenerationController.saveUploadedAddressProof';
import customLoadStyles from '@salesforce/resourceUrl/stylingForCurrentAddressProofButton';
import customReLoadStyles from '@salesforce/resourceUrl/reUploadAddressProofButton';
import { loadStyle } from 'lightning/platformResourceLoader';
import createCurrentAddressRecord from '@salesforce/apex/ScreenGenerationController.createCurrentAddressRecord';
import getCustomerType from '@salesforce/apex/ScreenGenerationController.getCustomerType';
import { updateRecord } from "lightning/uiRecordApi";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import USERID_FIELD from "@salesforce/user/Id";//sanwar(01/12/2025)
import STAGE_FIELD from "@salesforce/schema/Opportunity.StageName";//sanwar(01/12/2025)
import SUBSTAGE_FIELD from "@salesforce/schema/Opportunity.Sub_stage__c";//sanwar(01/12/2025)
import DOCVERIFBYCO_FIELD from "@salesforce/schema/Opportunity.Documents_Verified_By_CO__c";
import getOpportunityTeamMembers from '@salesforce/apex/AHL_LoanDetailsController.getOpportunityTeamMembers';//sanwar(01/12/2025)
import getDefaultSubBranch from '@salesforce/apex/ScreenGenerationController.getDefaultSubBranch';
import getIndustry from '@salesforce/apex/AHL_LoanDetailsController.getIndustry';
import getIndustryByApp from '@salesforce/apex/AHL_LoanDetailsController.getIndustryByApp';
import updateFCUInitiationDate from '@salesforce/apex/AHL_LoanApplicationActionController.updateFCUInitiationDate';//Added by Fawaz for SFAH-2170

const FIELDS = ['Application_Applicant__c.DOB__c','Application_Applicant__c.DOI__c','Application_Applicant__c.Business_Commencement_Date__c'];

// ⚠️ Adjust these field imports if your API names differ
import ID_FIELD from '@salesforce/schema/Opportunity.Id';
import LOGIN_COMPLETION_STAGE from '@salesforce/schema/Opportunity.Login_Completion_Stage__c'; // Multi-Select

import { emailValidation, mobileNumberValidation, charLength, panNumberValidation, numberValidation,isValidMobileNumber, gstNumberValidation, textValidation, isNotFutureDate, checkSpecialCharacter, checkalphnumeric, validateNameOfOrganisation,udyamValidation , validateTANNumber} from 'c/utility';
import getApplicantValues from '@salesforce/apex/COMM_SalesLoanLoginController.getApplicantValues';
import checkBranchFromLoan from '@salesforce/apex/COMM_SalesLoanLoginController.checkBranchFromLoan';
import checkNextStageMovement from '@salesforce/apex/COMM_SalesLoanLoginController.checkNextStageMovement';
import sendEmailToUsers from '@salesforce/apex/sendEmailToUsers.sendEmailToUsers';
import getProductLimitations from '@salesforce/apex/COMM_Sales_LoginProductDetailsController.getProductLimitations';
import checkSubBranch from '@salesforce/apex/COMM_SalesLoanLoginController.checkSubBranch';
import createCoAppAddress from '@salesforce/apex/COMM_SalesLoanLoginController.createCoAppAddress';
import checkApplicantProfile from '@salesforce/apex/COMM_SalesLoanLoginController.checkApplicantProfile';
import checkExceptionStatus from '@salesforce/apex/COMM_SalesLoanLoginController.checkExceptionStatus';
import getExistingCustomer from '@salesforce/apex/ScreenGenerationController.getExistingCustomer';
import getPANToGSTNumber from '@salesforce/apex/ScreenGenerationController.getPANToGSTNumber';
//import getCoApplicantRelationFieldValues from '@salesforce/apex/COMM_SalesLoanLoginController.getCoApplicantRelationFieldValues';
import getNumberToWord from '@salesforce/apex/Comm_LeadManagementController.getNumberToWord';
import checkMNRL from '@salesforce/apex/COMM_MNRLController.initiateAPIRequest'; 
import callUCICAPI from '@salesforce/apex/COMM_SalesLoanLoginController.callUCICAPI';
import initiateAPIRequestForAadharConsent from '@salesforce/apex/HL_AadharConsentController.initiateAPIRequest';
import initiateAPIRequestForPanAadharLink from '@salesforce/apex/HL_PANAadharController.initiateAPIRequest';
import getLocationSettings from '@salesforce/apex/HL_AadharConsentController.getLocationSettings';
import validateOVDDocuments from '@salesforce/apex/SalesDocumentValidationChecklist.validateOVDDocuments';
import getBuilderName from '@salesforce/apex/COMM_Sales_LoginProductDetailsController.getBuilderName';
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated';

import getProductDetails from '@salesforce/apex/Utility_V1.getProductDetails';

export default class SalesLoanLoginGenericScreenCmp extends NavigationMixin(LightningElement) {
    //Mobile APP
    // variable that hold formfactor
    formFactor = FORM_FACTOR;
    deviceType;

    // Mobile app
    @api recordId;
    @api fromBuilderSeller;
    allFieldDetails = [];
    @api activeSection = {};
    @api passedScreenName;
    @api loginChecklist= false;
    @api item; // Accepts data dynamically
    @track isDropdownOpen = false;
    @track selectedValue = '';
    @track selectedLabel = 'Select an option';
    @api appId;
    firstLoad
    loadLookUps
    showPermanentAdr
    isDropdownOpen = false;
    @track fieldDetails;
    @track filteredScreenDetails;
    @track allFieldDetails = [];
    // @track screenName = 'Enter PAN Details';
    @track screenName = 'Basic Details';
    @track screenObject;
    @track PANPage = false; // was false before
    @track currentScreenSequence = 0;
    @track showIMDScreen = false;
    @track showAccAg = false;
    @track showUploadDocuments = false;
    @track showLoginConfirm = false;
    @track showbasicCustomerDetails = true;
    @track showCollateralScreen = false;
    @track showConsentScreen = false;
    @track showCaptureApplicantPhotoScreen = false;
    @track showSalesLoginPrimaryApplicantInfoScreen = false;
    @track showProductInfoScreen = false;
    @track showLoginFeeScreen = false;
    @track showDocScreen = false;
    @track isCustomCmp = false;
    @track fromCreateNewLoan = true;
    @track customCmpName;
    currentSeq = 0;
    mobileNumber;
    onePage = false;
    @api selectedRecordId;
    picklistOptionsFromApex;
    saveandnext = "Next";
    cmpNameCheck;
    productAdded;
    consentReceived;
    @track completionVal = 0;
    logoicon
    isRendered = false;
    @track showBankScreen = false;
    @track aadharPage = false;
    @track showProductScreen = false;
    @track showCoApplicantScreen = false;
    @track showGurantorScreen = false;
    @track showBusinessAddressScreen = false;
    @track showBOScreen = false;
    @track showChangeApplicantScreen = false;
    @track showEligibilityScreen = false;
    @track small = false;
    @track pincodeRecordId;
    @track showAccAg = false;
    selectedValue
    openDropdown = null;
    showPincodeCmp = false;
    showEligibilityScreen = false;
    showEligibilityScreenAA = false;
    @api formIdentifier = 'Loan Login Form';
    @track showParentSave = false;
    @track showSpinner = false;
    @track custype;
    @track customerType;
    @track empType;
    @track showPermanentAdr = false;
    showFSA = false;
    applicantIds = [];
    currentIndex = 0;
    modalAPIVisibility = false;
    isSEPApplicant = false;
    currentApplicantType;
    customerProfile;
    gstExempt;
    get picklistOptions() {
        return [{
            label: 'Yes',
            value: 'Yes'
        },
        {
            label: 'No',
            value: 'No'
        }
        ];
    }
    @track mainApplicantId;
    @track applicantDoi;
    @track bussinessComendate;
    @track applicantDob;
    @track dateofIncorporation;
    @track applicantbusinessComenDate;
    @track spinnerClass;
    @track showLoader;
    @track loadLookUps = true;
    @track firstLoad = true;
    isFormSixtyUploaded;
    errorModal=false;
    errorLst=[];

    @track permanentAddressFilled = false;
    stages = [];
    @track aadharPage = false;
    @track ovdPage = false;
    isNewSaved = false;
    //@track businessAddressScreen = false;
    @track showSkipForBusinessAddress = false;
    @track showScreenFieldLoginAppFields = true;
    @track uploadButtonLabel;
    @track isNonIndividual = false;
    @track showITRCmp = false;
    @track showGSTCmp = false;
    @track showComparisonScreen = false;
    @wire(CurrentPageReference) pageRef;
    showIncomeScreen = false;
    showBSAScreen = false;
    showPrimaryApplicantInfoScreen = false;
    @api currentAppSeq;
    @track showcreditEligibilityComponent=false;
    showAddressDetails = false;
    cibilOneView = false;
    showCibilEligibility = false;
    selectedBranchId='';
    selectedBankType='';
    selectedDsaAreaManager ='';
    sunBranchFilter='';
    branchFilter='RecordType.Name=Branch;Branch_Type__c=HUB';
    marktrue = 'true';
    appval=[];
    sector;
    branchAvailable = false;
    subBranchSelected;
    errors=[];
    viewEligibilityBSA= false;
    showLoginButton;
    movetoEligibility;
    hasErrors;
    hasNoErrors = false;
    confirmationMessageLogin ='Congratulations. You have successfully completed the login processs. We are going to proceed with the loan processing'
    subProductLimits = [];
    industryPicklistOptions = [];
    subBranchRequired=false;
    removedFields=[];
    nonWorkingLablesToRemove=[];
    currentExpInYear = 0;
    currentExpInMonths = 0;
    totalExpInYear = 0;
    totalExpInMonths = 0;
    maxResults = 10;
    qualification;
    employerReturnFields = ['Id','Name','Employer_Name__c','Employer_Catagory__c','CreatedDate'];
    // key = field API name (e.g., 'Business_Vintage__c'), value = { valid: boolean, msg: string }
    validationMap = new Map(); //Added by Kshitiz AHL for handling all the validations
    @track ckycAadhaarNum;
    currentUserOppRole = [];//sanwar(01/12/2025)
    oppStage = '';//sanwar(01/12/2025)
    oppSubStage = '';//sanwar(01/12/2025)
    //HL-Ishi_Bre
    checkBREAPI=false;
    dontCheckBREAPI=false
    generateAppform=false;
    defaultSubBranch;
    isHLUser= false;
    //HL-Ishi_Bre
    product;
    showHLRelatedData=false;

    @track industryOptions = [];
    @track industryOptionsAll = [];

    @track cusPro;
    @track cussec;
    @track rmFilter = 'Position_Title__c=RM';
    @track AMFilter = 'Position_Title__c=AM';
    @track DSTFilter = 'Position_Title__c=DST';

    //  Mobile APP
    get getClassByDeviceType(){
        if(this.deviceType=='Mobile'){
            return 'andcontainer slds-text-align_center';
        }
        return 'andcontainer slds-text-align_center';
    }
    get getInputContByDeviceType(){
        if(this.deviceType=='Mobile'){
            return '';
        }
        return 'input-container';
    }
    get getMarginByDeviceType(){
        if(this.deviceType=='Mobile'){
            return 'margin: 8px -10px 1px -10px;';
        }
        return ' margin: 8px 5px 1px 10px;';
    }
    get getPaddingStyleByDeviceType(){
        if(this.deviceType=='Mobile'){
            return 'padding: 10px';
        }
        return '';
    }

    @wire(getRecord, { recordId: '$selectedRecordId', fields: FIELDS })
    wiredAccount({ data, error }) {
        if (data) {
            if(data.fields.DOB__c.value != '' && data.fields.DOB__c.value != null) {
                this.applicantDob = data.fields.DOB__c.value;
            }
            if(data.fields.DOI__c.value != '' && data.fields.DOI__c.value != null) {
                this.applicantDoi = data.fields.DOI__c.value;
            }
            if(data.fields.Business_Commencement_Date__c.value != '' && data.fields.Business_Commencement_Date__c.value != null) {
                this.applicantbusinessComenDate = data.fields.Business_Commencement_Date__c.value;
            }
            console.log('loan Sub_stage__c:', this.applicantDoi);
        } else if (error) {
            console.error('Error fetching loan record:', error);
        }
    }
    //sanwar(01/12/2025)
    @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD, SUBSTAGE_FIELD] })
    opportunity({ error, data }) {
        if(data) {
            this.oppStage = data.fields.StageName.value;
            this.oppSubStage = data.fields.Sub_stage__c.value;
        }
    }

    @wire(getOpportunityTeamMembers, {
        loanId: "$recordId",
    })
    getOppTeamMembers({
        data,
        error
    }) {
        if (data) {
            data.forEach(item => {
                if(item.UserId == USERID_FIELD){
                    this.currentUserOppRole.push(item.TeamMemberRole);    
                }
            })
        } else if (error) {
            console.log('error fetching Opp Team Members: '+error);
        }
    }

    handleFormFactor() {
        if (this.formFactor === "Large") {
            this.deviceType = "Desktop/Laptop";
        } else if (this.formFactor === "Medium") {
            this.deviceType = "Tablet";
        } else if (this.formFactor === "Small") {
            this.deviceType = "Mobile";
        }
    }

    //End of Mobile app
    //  showBranchMasterLookup = false;
    //  showLeadChannelLookup = false;
    handleNavigationClick(event) {
        const valueSelectedEvent = new CustomEvent('opennavigationmenu', {
            detail: {}
        });
        this.dispatchEvent(valueSelectedEvent);
    }
    getCustomerType() {
        getCustomerType({
            loanId: this.recordId
        }).then(response => {
            console.log('response=: partner' + JSON.stringify(response));
            if(this.passedScreenName == 'Seller Details'){
                this.selectedRecordId = response.applicantId;
                console.log('This Selcted RecodId>>', this.selectedRecordId);
            }
            this.customerType = response.customerType;
            this.empType = response.empType;
            this.mainApplicantId = response.applicantId;
            this.sector = response.sector;
            console.log('this.selectedRecordId: '+this.selectedRecordId);
            const inputMap = {
                'loanId': this.recordId,
                'applicantId': this.selectedRecordId,
            }
            console.log('inputMap -->287 '+JSON.stringify(inputMap));
            getApplicantValues({inputMap: inputMap})
                .then(response => {
                console.log('getApplicantValues response --> '+JSON.stringify(response));
                if(this.passedScreenName == 'Seller Details'){
                    console.log('Response>>>>>>>>> ',response[0].applicantId)
                    this.selectedRecordId = response[0].applicantId;
                    console.log('This Selcted RecodId>>>>', this.selectedRecordId);
                }
                console.log('sector 249--',response.sector);
                    this.appval = response;
                console.log('this.appval: '+this.appval);
                //console.log('appval.consentStatus --> '+this.appval[0].consentStatus);
                }).catch(error => {
                console.error('error in getApplicantValues --> '+JSON.stringify(error));
                })
            this.checkBranch();
            this.isProductAdded();
            this.checkConsent();  
        }).catch(error => {

        })
       
    }

    checkSubBranchRequired(){
        checkSubBranch({loanId: this.recordId})
            .then(response => {
            console.log('checkSubBranch response --> '+response);
                this.subBranchRequired = response;
                if(response){
                    getDefaultSubBranch().then(data=>{
                        this.defaultSubBranch = data;

                        console.log('this.defaultSubBranch>>>' +  JSON.stringify(this.defaultSubBranch));
                    }).catch(error=>{
                        console.log('error fetching default subbranch>>'+JSON.stringify(error));
                    })
                }
            }).catch(error => {
            console.error('error in checkSubBranch --> '+JSON.stringify(error));
            })
    }

    checkIfLoggedInUserIsHLRelated(){
        checkIfLoggedInUserIsHLRelated()
        .then(result => {
            this.isHLUser = result.isHLRelated;
            console.log('isHLUser-->',this.isHLUser);
            if(this.isHLUser){
                this.branchFilter="RecordType.Name=Branch;Branch_Type__c=HUB;Account.Vertical1__c INCLUDES ('HL')";

            }else{
                this.branchFilter="RecordType.Name=Branch;Branch_Type__c=HUB;Account.Vertical1__c INCLUDES ('AHL')";
            }
        })
        .catch(error => {
            console.log('error-->',error);
        })
       
    }

    getIndustryOnLoan() {
        console.log('selectedRecordId12' + this.selectedRecordId);
        getIndustryByApp({ 
            appId: this.selectedRecordId
        })
        .then(result => {
            console.log('IndustyValues' + JSON.stringify(result));
            this.industryOptions = result.map(item => {
                return { label: item, value: item };
            });
            this.industryOptionsAll = result.map(item => {
                return { label: item, value: item };
            });
            this.cusPro = null;
            this.cussec = null;
        })
        .catch(error => {
            console.error('Error fetching industries:', error);
        });
    }

    connectedCallback() {
        this.getProductDetails();
        this.handleFormFactor();
        console.log('SalesLoanLoginGenericScreenCmp:deviceType: ', this.deviceType, this.selectedRecordId);
        console.log('check 1');
        this.checkIfLoggedInUserIsHLRelated();

        try {
            //this.getCompletionPercent();
            //Sanwar Start
            if(this.passedScreenName != 'Seller Details'){
            this.getCustomerType();
            }
            //Sanwar End
            this.allFieldDetails = null;
            // document.addEventListener('click', this.handleClickOutside.bind(this));
            console.log('currentAppSeq=:142' + this.currentAppSeq);
            console.log('connectedCallback');
            this.checkSubBranchRequired();
            // console.log('appId in GenericCMP: '+appId);
            var detail = {};
            detail["isPullToRefreshEnabled"] = false;
            var updateScrollSettingsEvent = new CustomEvent("updateScrollSettings", {
                detail: detail,
                bubbles: true,
                composed: true
            });
            dispatchEvent(updateScrollSettingsEvent);
            console.log('this.recordId -->' + this.recordId);
            console.log('activeSection--157-', JSON.stringify(this.activeSection));
            console.log('passedScreenName--158-', this.passedScreenName)
            if (this.activeSection && this.activeSection.name === 'Login Fees') {
                 this.onePage = false;
        this.showIncomeScreen = false;
        this.showBSAScreen = false;
        this.showSalesLoginPrimaryApplicantInfoScreen = false;
        this.showProductInfoScreen = false;
        this.cibilOneView = false;
        this.showCibilEligibility = false;
        this.showPrimaryApplicantInfoScreen = false;
        this.showAddressDetails = false;
                this.showLoginFeeScreen = true;
            }
            else{
                 setTimeout(() => {
                this.getScreenDetailsFromApex();
                if (this.activeSection && this.activeSection.name === 'Loan Details') {
                    console.log('inside this.activeSection.name === Loan Details');
                    this.checkProductLimitations();
                }
            }, 700)

            }
           
            if (FORM_FACTOR == 'Small') {
                this.small = true;
                this.addEventListeners();
            }
            Promise.all([
                loadStyle(this, customLoadStyles)
            ]).then(() => {}).catch((error) => {})
            Promise.all([
                loadStyle(this, customReLoadStyles)
            ]).then(() => {}).catch((error) => {})
        } catch (Error) {
            console.log('Inside generic cmp 182', Error);
            console.log('Inside generic cmp 183', JSON.stringify(Error));
        }
        this.showSpinner = true;
        setTimeout(() => {
            this.showSpinner = false;
        }, 2000);
        //Sanwar Start
        // if(this.passedScreenName == 'Seller Details'){
        //     setTimeout(() => {
        //         console.log('this.fieldDetails::: ' + JSON.stringify(this.fieldDetails));
        //         if (this.fieldDetails.some(field => field.value !== '')) {
        //             this.fieldDetails = this.fieldDetails.map(field => {
        //                 return {
        //                     ...field,
        //                     Is_Disabled__c: true
        //                 };
        //             });
        //         }
        //     }, 4000);
        // }//Sanwar End
    }
    checkProductLimitations () {
        getProductLimitations ({loanId : this.recordId})
            .then(result => {
                if (result) {
                    this.subProductLimits = result;
                    console.log('Sub Product Limits Array:', JSON.stringify(this.subProductLimits));
                }
            })
            .catch(error => {
                console.error('Error in checkProductLimitations:', error);
                this.showToast('Error', 'Failed to load product limitations.', 'error');
            });
    }
    //Check Current USer Profile if Profile = Sales then all fields are disabled
    isDisabled = false;
    checkUserProfile() {
        checkExceptionStatus({ loanId: this.recordId })
            .then(result => {
                console.log('Inside Profile true----', result);

                if (result) {
                    this.isDisabled = true;
                    this.fieldDetails = this.fieldDetails.map(field => {
                        if (field.Field_Label__c) {
                            return { ...field, Is_Disabled__c: true };
                        }
                        return field;
                    });
                }
            })
            .catch(error => {
                console.error('Error in checkExceptionStatus:', error);
            });
    }

    checkSEPApplicant() {
        checkApplicantProfile({ loanId: this.recordId })
            .then(result => {
                if (result) {
                    this.isSEPApplicant = result;
                    console.log('checkSEPApplicant', result);
                    if (this.isSEPApplicant) {
                        console.log('Inside sep true----');

                        this.fieldDetails = this.fieldDetails.map(field => {
                            if (field.Field_Label__c === "Nature of Business") {
                                return { ...field, Is_Disabled__c: true };
                            }
                            return field;
                        });

                        // // If the field is found, update its Is_Disabled__c property
                        // if (targetField) {
                        //     targetField.Is_Disabled__c = true;
                        // }
                    }
                }
            })
            .catch(error => {
                console.error('Error in checkSEPApplicant:', error);
            });
    }
    createChecklist() {
        executeMapping({
            identifier: 'fromLoan',
            recordId: this.recordId,
            applicantId: this.mainApplicantId,
            applicantType: 'Primary Applicant'

        }).then(response => {
            console.log('response=: partner' + JSON.stringify(response));

        }).catch(error => {

        })
    }
    get picklistOptions() {
        return this.item?.picklistOptions || [];
    }

    disconnectedCallback() {
        // document.removeEventListener('click', this.handleClickOutside.bind(this));
    }
    addEventListeners() {
        window.addEventListener('touchmove', this.preventPullToRefresh, {
            passive: false
        });
        window.addEventListener('touchstart', this.preventPullToRefresh, {
            passive: false
        });
    }

    preventPullToRefresh(event) {
        // Add logic to detect and prevent pull-to-refresh
        if (event.touches.length > 1) {
            // If more than one touch point, prevent default
            event.preventDefault();
        }
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
        window.removeEventListener('touchmove', this.preventPullToRefresh);
        window.removeEventListener('touchstart', this.preventPullToRefresh);
    }

    renderedCallback() {
        if (!this.isRendered) {
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
        }
        .uploadFile slds-form-element__label{
            display: none;
            }
            .uploadFile slds-form-element__control{
                margin-left:20%;
            }
            .info-button svg.slds-button__icon.slds-button__icon_left {
            margin: 0;
        }
        .uploaded-view svg.slds-button__icon {
            color: green;
        }
            .inputSize .slds-form-element__label{
                
            }
            .navClass .slds-progress-bar__value{
                background: skyblue;
            }
                .instruction-box-nav.slds-progress-bar__value{
                background: skyblue;
            }
            /* Line format -- underline only, no box/background, for the
               dynamic fieldDetails-driven inputs (Applicant's Basic
               Information and other generic sections). Colors/theme kept
               identical to the rest of this screen (#33455e border,
               #ffffff text) - only the box shape is removed. */
            .hideInput .slds-input {
                background-color: transparent !important;
                color: #ffffff !important;
                border: none !important;
                border-bottom: 1px solid #33455e !important;
                border-radius: 0 !important;
                padding: 4px 2px !important;
                outline: none;
                box-shadow: none;
                transition: none !important;
            }
            /* Explicitly pin hover to the exact same idle underline color -
               without this, the browser/SLDS default hover state (no rule
               defined here previously) could show through, which is what
               looked like the line "changing color" on hover. */
            .hideInput .slds-input:hover {
                background-color: transparent !important;
                border-bottom: 1px solid #33455e !important;
                box-shadow: none !important;
            }
            .hideInput .slds-input:focus,
            .hideInput .slds-input:active {
                border-bottom: 1px solid #8b5cf6 !important;
                box-shadow: none !important;
            }
            .removeborder .slds-combobox__input {
                box-shadow: none !important;  /* Remove any shadow */
                background-color: transparent !important;
                color: #ffffff !important;
                border: none !important;
                border-bottom: 1px solid #33455e !important;
                border-radius: 0 !important;
                padding: 4px 2px !important;
                transition: none !important;
            }
            .removeborder .slds-combobox__input:hover {
                background-color: transparent !important;
                border-bottom: 1px solid #33455e !important;
                box-shadow: none !important;
            }
            .removeborder .slds-combobox__input:focus,
            .removeborder .slds-combobox__input:active {
                border-bottom: 1px solid #8b5cf6 !important;
                box-shadow: none !important;
            }
            .hideInput .slds-form-element__control,
            .removeborder .slds-form-element__control {
                background-color: transparent !important;
            }
            .removeborder .slds-combobox__form-element,
            .removeborder lightning-base-combobox-formatted-text {
                background-color: transparent !important;
            }
              .removelookup .slds-combobox__input {
                border: none !important;
                box-shadow: none !important;
                border-bottom: 1px solid black !important; /* Add only bottom border */
                padding:5px
            }
           .slds-has-error .slds-input__icon {
                display: none;
            }
            

            /* Force all lightning-input / lightning-combobox field labels
               to render white - these labels have no public CSS custom
               property hook, so they must be styled via this injected
               stylesheet the same way the border rules above are. */
            .slds-form-element__label {
                color: #ffffff !important;
            }
            .slds-accordion__list-item .section-control {
                background: linear-gradient(
                    135deg,
                    #001a5e 0%,
                    #003087 55%,
                    #004db3 100%
                ) !important;

                color: #ffffff !important;
                font-weight: 600;
            }

            .slds-accordion__summary-content,
            .slds-accordion__summary-heading,
            .slds-accordion__summary-action,
            .slds-accordion__summary-action .slds-truncate {
                color: #ffffff !important;
                font-weight: 600 !important;
            }

            .slds-accordion__summary-action svg,
            .slds-button__icon {
                fill: #ffffff !important;
                color: #ffffff !important;
            }

            .slds-accordion__summary:hover,
            .slds-accordion__summary-action:hover {
                background: linear-gradient(
                    135deg,
                    #001a5e 0%,
                    #003087 55%,
                    #004db3 100%
                ) !important;
            }
            `;
            this.template.querySelector('.styleContainer').appendChild(style);
            this.spinnerClass = 'spinner-medium';
        }

        setTimeout(() => {
            if (this.fieldDetails) {
                this.fieldDetails.forEach(item => {
                    if (item.Is_Hidden__c) {
                        if(this.template.querySelector(`[data-rec="${item.Id}"]`)){
                        this.template.querySelector(`[data-rec="${item.Id}"]`).classList.add('slds-hide');
                        }                       
                    }
                });
            }
        }, 1000)

        // if(this.fieldDetails) {
        //     this.fieldDetails.forEach(item => {
        //         if(item.Is_Hidden__c) {
        //             item.hideField = true;
        //             this.template.querySelector(`[data-id="${item.Id}"]`).classList.add('slds-hide');
        //         }
        //         else if(this.firstLoad == true && this.isCustomCmp == false && (this.recordId == null || this.recordId == '' || this.recordId == undefined) && item.Visibility_Controlled_By__c != null && item.Visibility_Controlled_By__c != '' && item.Visibility_Controlled_By__c != undefined){
        //             item.hideField = false;
        //             this.template.querySelector(`[data-id="${item.Id}"]`).classList.add('slds-hide');
        //         }
        //     });
        // }
    }

    get previousVisibility() {
        return this.currentScreenSequence > 1;
    }
    get showSaveVisibility() {
        return this.currentScreenSequence == 15;
    }
    //Added by kalpesh -start
        getBuilderNameFromApex(){
                if(this.passedScreenName == 'Builder Details'){
                getBuilderName({loanId: this.recordId}).then(result => {
                    if (result !='') {
                        this.fieldDetails.forEach(record => {
                if (record.Storage_Field__c == 'Name' && record.Field_Label__c=='Name of the Builder') {
                    console.error('inside builder fields:>>>',record);
                    record.value = result;
                    record.Is_Disabled__c=true;
                }
            })
                    }
                }).catch(error => {
                    //  console.error('error getScreenDetails: ' + error);
                });
                }
        }
        //Added by kalpesh -end
    getScreenDetailsFromApex() {
        console.log('this.formIdentifier ' + this.formIdentifier);
        this.allFieldDetails = [];
        this.fieldDetails = null;
        getScreenDetails({
            formIdentifier: this.formIdentifier,
            loanId: this.recordId
        })
            .then(result => {
                if (result) {
                    console.log('fields from apex 554 ', JSON.stringify(result));
                    this.allFieldDetails = result;
                    this.allFieldDetails.forEach(item => {
    
            });
                    this.getCurrentScreenFieldDetails();
                    this.getBuilderNameFromApex();//Added by kalpesh
                }
            }).catch(error => {
                //  console.error('error getScreenDetails: ' + error);
            });
    }
    getCurrentScreenFieldDetails() {
        try {
            // setTimeout(() => {
            this.screenObject = null;
            this.fieldDetails = null;
            this.screenName = null;
            this.isCustomCmp = false;
            this.showIncomeScreen = false;
            this.showBSAScreen = false;
            this.showSalesLoginPrimaryApplicantInfoScreen = false;
            this.showProductInfoScreen = false;
            this.showLoginFeeScreen = false;
            this.cibilOneView = false;
            this.showPrimaryApplicantInfoScreen = false;
            this.showCibilEligibility = false;
            //this.showGurantorScreen = false;
            console.log('this.allFieldDetails --> ' + this.formName);
            console.log('this.allFieldDetails --> ' + JSON.stringify(this.allFieldDetails));

            console.log('this.passedScreenName 326', JSON.stringify(this.activeSection));
            this.onePage = true;
            if (this.activeSection?.name){
            this.allFieldDetails.forEach(item => {
                console.log('this.passedScreenName 329', item.Parent_Screen__r.Master_Screen_Name__c);
              //  if (item.Parent_Screen__r.Master_Screen_Name__c == this.activeSection.name) 
              if (item?.Parent_Screen__r?.Master_Screen_Name__c === this.activeSection?.name)

                    {
                    console.log('this.passedScreenName 326', this.activeSection.name);
                }
             
            });
        }
            console.log('this filter list in 589',JSON.stringify(this.allFieldDetails));
            console.log('this.activeSection.name=:' + this.activeSection.name);
            console.log('this.customerType=:' + this.customerType);
            if (this.activeSection && this.activeSection.name) {
                this.filteredScreenDetails = this.allFieldDetails.filter(item =>
                    item?.Parent_Screen__r?.Master_Screen_Name__c?.toLowerCase().trim() === this.activeSection?.name?.toLowerCase().trim()
                  
                );
            }
            console.log('this filter list in 596',JSON.stringify(this.filteredScreenDetails));
            if(this.activeSection?.name === 'Applicant\'s Basic Information' && this.customerType){
                console.log('inside activeSection',this.activeSection.name);
                this.filteredScreenDetails = this.filteredScreenDetails.filter(item =>
                    (item.Applicable_For__c === this.customerType) || (item.Applicable_For__c === 'Both') || (item.Applicable_For__c === 'Individual-Both') || (item.Applicable_For__c === 'Individual') || (item.Applicable_For__c === 'Non Individual')
                );
            }
            
            console.log('Filtered Screen Details for Active Section: 604', JSON.stringify(this.filteredScreenDetails));

            // Assign current screen sequence
            this.filteredScreenDetails.forEach(item => {
                this.currentSeq = item.Parent_Screen__r.Screen_Sequence__c;
            });
            this.currentScreenSequence = this.currentSeq;

            console.log('this.currentScreenSequence -->', this.currentScreenSequence);
            this.filteredScreenDetails.forEach(element => {
                this.cmpNameCheck = element.Custom_Component_Name__c
            });
            console.log('this.filteredScreenDetails -->' + JSON.stringify(this.filteredScreenDetails));
            console.log('this.cmpNameCheck -->' + JSON.stringify(this.cmpNameCheck));

            if (this.cmpNameCheck !== undefined) {

                this.onePage = false;

                this.filteredScreenDetails.forEach(item => {
                    this.screenName = item.Parent_Screen__r.Master_Screen_Name__c;
                });
                this.filteredScreenDetails.forEach(item => {
                    this.customCmpName = item.Custom_Component_Name__c
                });
                console.log('customCmpName --> ', JSON.stringify(this.customCmpName));
                console.log('filteredScreenDetails --> ', JSON.stringify(this.filteredScreenDetails));
                const valueSelectedEvent = new CustomEvent('highlightactivescreen', {
                    detail: {
                        screenName: this.passedScreenName
                    }
                });
                this.dispatchEvent(valueSelectedEvent);
                this.showCustomCmp(this.customCmpName);
                this.filteredScreenDetails = null;
            } else {
                //only in case of non-custom component
                this.PANPage = false;
                this.aadharPage = false;
                this.showCoApplicantScreen = false;
                this.showGurantorScreen = false;
                this.showBusinessAddressScreen = false;
                this.showBOScreen = false;
                this.showChangeApplicantScreen = false;
                this.showEligibilityScreen = false;
                this.showEligibilityScreenAA = false;
                this.onePage = true;
                this.filteredScreenDetails.forEach(item => {
                    this.screenName = item.Parent_Screen__r.Master_Screen_Name__c;
                });
                this.filteredScreenDetails.forEach(item => {
                    this.screenObject = item.Storage_Object__c;
                });
                this.fieldDetails = this.filteredScreenDetails;
                const amRow = this.fieldDetails?.find(r => r.Storage_Object__c === 'Opportunity' && (r.Storage_Field__c === 'Dsa_Area_Manager__c' || r.Storage_Field__c === 'Dsa_Area_Manager__r.Name'));
                console.log('[AM][getCurrent] row object =>', amRow);
                if (!this.selectedDsaAreaManager && amRow?.value) {
                    this.selectedDsaAreaManager = String(amRow.value);
                    console.log('[AM][getCurrent] picked from row =>', this.selectedDsaAreaManager);
                }
                if (this.fieldDetails == undefined || this.fieldDetails == null) {
                    this.currentScreenSequence = this.currentScreenSequence + 1;
                    this.getCurrentScreenFieldDetails();
                }
                console.log('this.fieldDetails::: ' + JSON.stringify(this.fieldDetails));
                // const valueSelectedEvent = new CustomEvent('highlightactivescreen', { detail: {screenName: this.passedScreenName} });
                // this.dispatchEvent(valueSelectedEvent);
                this.fieldDetails.forEach(item => {
                    //item.isPicklist = item.Field_Type__c === 'Picklist';
                    item.isCheckBox = item.Field_Type__c === 'Boolean';

                    if (item.is_Lookup__c) {
                        console.log('inside item.is_Lookup__c --> item.Storage_Field__c --> ' + item.Storage_Field__c);
                        if (item.Storage_Field__c.includes('Branch__') && !item.Storage_Field__c.includes('Sub_Branch__')) {
                            item.showBranchLookup = true;
                        }else if (item.Storage_Field__c.includes('Collateral_Area_Pincode__')) {
                            item.showCollateralPinCodeLookup = true;
                        }else if (item.Storage_Field__c.includes('Permanent_Address_Pincode__')) {
                            item.showPermanentPinCodeLookup = true;
                        }
                        else if (item.Storage_Field__c.includes('Pincode__')) {
                            item.showPinCodeLookup = true;
                        } else if (item.Storage_Field__c.includes('Branch_Master__')) {
                            item.showBranchLookup = true
                        } 
                        else if (item.Storage_Field__c.includes('Lead__r.Channel__c')) {
                            item.showLeadChannelLookup = true
                        } 
                        else if (item.Storage_Field__c.includes('Sourcing_Manager__')) {
                            item.showAreaManagerLookup = true;
                            console.log('isnide-------'+item.showAreaManagerLookup);
                        } 
                        else if (item.Storage_Field__c.includes('Dsa_Area_Manager__')) {
                            item.showAreaManagerLookup = true
                        }
                        else if (item.Storage_Field__c.includes('Lead__r.Referred_By_DSA__')) {
                            item.showAreaManagerLookup = true
                        } 
                        else if (item.Storage_Field__c.includes('Reference_Details_Pincode_1__')) {
                            item.showRefDetails1Pincode = true
                        } 
                        else if (item.Storage_Field__c.includes('Reference_Details_Pincode_2__')) {
                            item.showRefDetails2Pincode = true
                        }
                        else if (item.Storage_Field__c.includes('Employer_Pin_Code_')) {
                            item.showEmployerPincode = true
                        }
                        else if(item.Storage_Field__c.startsWith('Employer_Name_')){
                            console.log('item.Storage_Field__c---- Employer Name', item.Storage_Field__c);
                            item.showEmployerMasterLookup = true;
                        }
                        else if (item.Storage_Field__c.includes('HL_Relationship_Manager')) {
                            item.showRMLookup = true
                        }
                        else if (item.Storage_Field__c.includes('HL_Area_Manager')) {
                            item.showAMLookup = true
                        }
                        else if (item.Storage_Field__c.includes('HL_DST')) {
                            item.showDSTLookup = true
                        }
                    }
                    if(item.Storage_Field__c === 'Industry__c'){
                        console.log('item.Storage_Field__c---- inside true', item.Storage_Field__c);
                        item.showBusinessIndustry = true;
                    }

                    // if(item.Parent_Screen__r.Master_Screen_Name__c == `Confirm Applicant's Basic Details`){
                    //     this.ovdPage = false;
                    //     //this.showPermanentAdr = true;
                    //     this.showScreenFieldLoginAppFields = true;
                    // }
                });

                this.fieldDetails.forEach(async item => {
                    if (item.Field_Type__c === 'Picklist') {
                        if(item.Storage_Field__c != 'Industry__c'){
                            item.isPicklist = true;
                            if(item.Picklist_Dependent_On_RecordType__c){
                                console.log('item.Filtered_Picklist_Values__c=:'+JSON.stringify(item.Filtered_Picklist_values__c));
                                item.picklistOptions = await this.getFilteredPicklistValues(item.Filtered_Picklist_values__c);
                            }
                           /* else if(item.Field_Label__c == 'Relationship with primary applicant'){
                                const relationValues = await this.getRelationValues();
                                console.log('relationValues---', relationValues);
                                
                                if (relationValues && relationValues.length > 0) {
                                    item.picklistOptions = relationValues;
                                    if(relationValues.length==1){
                                        console.log('relationValues.length---', relationValues.length);
                                        
                                        item.value= relationValues[0].value;
                                        console.log('item.value--', item.value);
                                        
                                    }
                                } else {
                                    item.picklistOptions = await this.getPicklistOptionsFromApex(item.isPicklist, item.Storage_Object__c, item.Storage_Field__c);
                                }
                            }*/
                            else{
                                console.log('inside else of picklist Hardeek');
                                item.picklistOptions = await this.getPicklistOptionsFromApex(item.isPicklist, item.Storage_Object__c, item.Storage_Field__c);
                                console.log('picklist option Hardeek>>', JSON.stringify(item.picklistOptions));
                            }
                        }else{
                            item.picklistOptions  = await this.getPicklistOptionsFromApex(true, item.Storage_Object__c, item.Storage_Field__c);
                            //  = [picklistValues.values()];
                        }
                        console.log('item.Storage_Field__c----', item.Storage_Field__c);
                        
                    }
                    if(this.isHLUser && item.Storage_Field__c=='Customer_Profile__c'){
                        item.picklistOptions = item.picklistOptions.filter(item => item.value != 'Others');
                    }else if(!this.isHLUser && item.Storage_Field__c=='Customer_Profile__c'){
                        item.picklistOptions = item.picklistOptions.filter(item => item.value != 'Non Working');
                    }
                        console.log('item.picklistOptions----', JSON.stringify(item.picklistOptions));
                });

                if(this.passedScreenName == 'Seller Details'){
                    this.saveandnext='Add Seller';
             this.fieldDetails.forEach(field => {
                console.log('ield.Applicant_Type_Visibility__c', field.Applicant_Type_Visibility__c);
                    const currentValue = 'Individual';
                    console.log('ield.Applicant_Type_Visibility__c', field.Applicable_For__c);
                    if (field.Applicable_For__c == currentValue) {
                        field.hideField = false;
                        setTimeout(() => {
                            if(this.template.querySelector(`[data-id="${field.Id}"]`)){
                            this.template.querySelector(`[data-id="${field.Id}"]`).classList.remove('slds-hide');
                            }                            
                        }, 500)
                    } else if(field.Applicable_For__c != 'Both'){
                        field.Is_Mandatory__c =false;//Kalpesh
                        setTimeout(() => {
                            if(this.template.querySelector(`[data-id="${field.Id}"]`)){
                            this.template.querySelector(`[data-id="${field.Id}"]`).classList.add('slds-hide');
                            }                            
                        }, 500)
                    }
                
                    });
                }
                if (this.isCustomCmp == false && this.recordId != null && this.recordId != '' && this.recordId != undefined /*&& !this.businessAddressScreen*/ ) {
                    console.log('496');
                    this.getLoanDetails();
                }

                console.log('fieldDetails getCurrentScreenFieldDetails --> ', JSON.stringify(this.fieldDetails));
                this.filteredScreenDetails = null;
                if (this.activeSection && this.activeSection.name === 'Loan Details') {
                    console.log('inside this.activeSection.name === Loan Details');
                    this.checkSEPApplicant();
                }
                this.checkUserProfile();
                this.getCurrentApplicantType();
            }

            //this.passedScreenName = null;


            // }, 1000);
        } catch (error) {
            console.log('error 469=:' + error);
        }

    }

    getCurrentApplicantType(){
        console.log('check applicant valuesss----', this.appval);
        if(this.appval.length > 0){
            console.log('Inside trueee--- 688', this.appval[0].customerType);
            console.log('Inside trueee--- 688', this.appval[0].customerType);
            this.currentApplicantType = this.appval[0].applicantType;
            this.customerProfile = this.appval[0].customerProfile;
            this.customerType = this.appval[0].customerType;
            const maritalStatus = this.appval[0].maritalStatus;
            this.qualification = this.appval[0].qualification;
            this.mobileNumber = this.appval[0].mobileNumber;
            this.isFormSixtyUploaded = this.appval[0].isForm60Uploaded;
            console.log('current applicant type----', this.currentApplicantType);

            this.fieldDetails.forEach(field => {
                
                if (field.Field_Label__c != 'Number of Associated Entities' && field.Field_Label__c != 'Total Work Experience (In Months)' && field.Field_Label__c != 'Total Work Experience (In Years)'  ) {
                    if (field.Applicant_Type_Visibility__c) {
                    console.log('Inside app type vis---');
                    console.log('field.Applicant_Type_Visibility__c 14/10', field.Applicant_Type_Visibility__c);
                    console.log('field.Applicable_For__c 14/10', field.Field_Label__c);
                    console.log('this.currentApplicantType 14/10', this.currentApplicantType);
                    if (field.Applicant_Type_Visibility__c == this.currentApplicantType) {
                        console.log('Inside showwww 14/10----');
                        field.hideField = false;
                        setTimeout(() => {
                                if(this.template.querySelector(`[data-id="${field.Id}"]`)){
                                    console.log('Showing field Kshitiz----',field.Field_Label__c);
                            this.template.querySelector(`[data-id="${field.Id}"]`).classList.remove('slds-hide');
                                }                                
                        }, 1000)
                    } else {
                            console.log('Inside hide 14/10----');
                        field.hideField = true;
                        if(field.Field_Label__c == 'Share Holding Percentage'){
                        const labelsToRemove = [
                            'Share Holding Percentage'
                         ];

                        this.fieldDetails = this.fieldDetails.filter(
                            field => !labelsToRemove.includes(field.Field_Label__c)
                        );
                    }
                        field.hideField = false;
                        setTimeout(() => {
                                if(this.template.querySelector(`[data-id="${field.Id}"]`)){
                            this.template.querySelector(`[data-id="${field.Id}"]`).classList.add('slds-hide');
                                }                                
                        }, 1000)
                    }
                }
                } 
                else {
                    var cusTypeList;
                    if (field.Applicable_For__c.includes('-')) {
                        cusTypeList = field.Applicable_For__c.split('-');
                    } else {
                        cusTypeList = field.Applicable_For__c;
                    }
                    if (this.customerProfile == 'SENP' && field.Applicant_Type_Visibility__c == this.currentApplicantType && (this.customerType == cusTypeList[0] || this.customerType == cusTypeList[1] || this.customerType == cusTypeList)) {
                        console.log('Inside hide----');
                        field.hideField = true;
                        setTimeout(() => {
                            if(this.template.querySelector(`[data-id="${field.Id}"]`)){
                            this.template.querySelector(`[data-id="${field.Id}"]`).classList.add('slds-hide');
                            }                            
                        }, 1000)
                        } else {
                        if (field.Applicant_Type_Visibility__c) {
                            console.log('Inside app type vis---');
                            if (field.Applicant_Type_Visibility__c == this.currentApplicantType) {
                                console.log('Inside showwww----');
                                field.hideField = false;
                                setTimeout(() => {
                                    if(this.template.querySelector(`[data-id="${field.Id}"]`)){
                                        this.template.querySelector(`[data-id="${field.Id}"]`).classList.remove('slds-hide');
                                    }                                    
                                }, 1000)
                            } else {
                                console.log('Inside hide for----',field.Field_Label__c);
                                console.log('inside hide for Id----',field.Id);
                                console.log('this.currentApplicantType----',this.template.querySelector(`[data-id="${field.Id}"]`));
                                field.hideField = true;
                                this.showSpinner = true;
                                setTimeout(() => {
                                     console.log('this.currentApplicantType inside settimout----',this.template.querySelector(`[data-id="${field.Id}"]`));
                                    if(this.template.querySelector(`[data-id="${field.Id}"]`)){
                                        console.log('hiding field Kshitiz----',field.Field_Label__c);
                                        this.template.querySelector(`[data-id="${field.Id}"]`).classList.add('slds-hide');
                                        this.showSpinner = false;
                                    }                                    
                                }, 10000)
                            }
                        }
                    }
                }
            });
                if(this.isFormSixtyUploaded == 'Yes'){
                    const labelsToRemove = ['Name As Per PAN'];
                    
                    this.fieldDetails = this.fieldDetails.filter(
                        field => !labelsToRemove.includes(field.Field_Label__c)
                    );
                }
                if(this.customerProfile=='SENP' && this.customerType == 'Individual'){
                    const labelsToRemove = [
                       
                        'Segment',
                      
                        'Specialization',
                        'Registration Number',
                        'Registration Number (CIN)',
                        'Registration Number (LLPIN)',
                        'Udyam Registration Number',
                        'Number of Associated Entities',
                        'Entity 1',
                        'Entity 2'
                    ];

                    this.fieldDetails = this.fieldDetails.filter(
                        field => !labelsToRemove.includes(field.Field_Label__c)
                    );
                    
                }else if(this.customerProfile=='SEP' && this.customerType == 'Individual'){
                    const labelsToRemove = [
                        'Number of Associated Entities',
                        'Entity 1',
                        'Entity 2'
                    ];

                    this.fieldDetails = this.fieldDetails.filter(
                        field => !labelsToRemove.includes(field.Field_Label__c)
                    );
                }
                else if (this.sanitize(this.customerProfile).toLowerCase() === 'salaried indian' && this.customerType === 'Individual') {
                            console.log('Inside Salaried Indian----');
                            var labelsToRemove ;
                            if(!this.showHLRelatedData){
                                labelsToRemove= [
                               
                                    'Segment',
                                
                                    'Specialization',
                                    'Business Industry',
                                    'Registration Number',
                                    'Registration Number (CIN)',
                                    'Registration Number (LLPIN)',
                                    'Udyam Registration Number',
                                    'Number of Associated Entities',
                                    'Entity 1',
                                    'Entity 2',
                                    'Office Ownership',
                                    'Certifcate Issuing Authority',
                                    'Certificate Issue Date',
                                    'Certificate Expiry Date'
                                ];

                            }
                            else{
                                 labelsToRemove= [
                               
                                    'Segment',
                                
                                    'Specialization',
                                    //'Business Industry',
                                    'Registration Number',
                                    'Registration Number (CIN)',
                                    'Registration Number (LLPIN)',
                                    'Udyam Registration Number',
                                    'Number of Associated Entities',
                                    'Entity 1',
                                    'Entity 2',
                                    'Office Ownership',
                                    'Certifcate Issuing Authority',
                                    'Certificate Issue Date',
                                    'Certificate Expiry Date'
                                ];

                            }
                            

                            this.fieldDetails = this.fieldDetails.filter(
                                field => !labelsToRemove.includes(field.Field_Label__c)
                            );
                            console.log('this.fieldDetails after filter----', this.fieldDetails);
                }
                else if (this.sanitize(this.customerProfile).toLowerCase() === 'salaried nri' && this.customerType === 'Individual') {
                            console.log('Inside Salaried Indian----');
                            var labelsToRemove ;
                            if(!this.showHLRelatedData){
                                labelsToRemove = [
                               
                                'Segment',
                              
                                'Specialization',
                                'Business Industry',
                                'Registration Number',
                                'Registration Number (CIN)',
                                'Registration Number (LLPIN)',
                                'Udyam Registration Number',
                                'Number of Associated Entities',
                                'Entity 1',
                                'Entity 2',
                                'Office Ownership',
                                'Certifcate Issuing Authority',
                                'Certificate Issue Date',
                                'Certificate Expiry Date'
                                ];
                            }
                            else{
                               labelsToRemove = [
                               
                                'Segment',
                              
                                'Specialization',
                                //'Business Industry',
                                'Registration Number',
                                'Registration Number (CIN)',
                                'Registration Number (LLPIN)',
                                'Udyam Registration Number',
                                'Number of Associated Entities',
                                'Entity 1',
                                'Entity 2',
                                'Office Ownership',
                                'Certifcate Issuing Authority',
                                'Certificate Issue Date',
                                'Certificate Expiry Date'
                                ]; 
                            }


                            this.fieldDetails = this.fieldDetails.filter(
                                field => !labelsToRemove.includes(field.Field_Label__c)
                            );
                            console.log('this.fieldDetails after filter----', this.fieldDetails);
                }
                else if(this.customerProfile === 'SENP' && this.customerType === 'Non Individual' && ['Proprietorship', 'Partnership', 'Public Limited', 'Private Limited', 'HUF', 'Dentist', 'Chartered Accountant', 'Doctor'].includes(this.sector)){
                    const labelsToRemove = [
                        'Number of Associated Entities',
                        'Entity 1',
                        'Entity 2',
                        'Registration Number (LLPIN)'
                    ];

                    this.fieldDetails = this.fieldDetails.filter(
                        field => !labelsToRemove.includes(field.Field_Label__c)
                    );
                }
                else if(this.customerProfile=='SENP' && this.customerType == 'Non Individual'){
                    const labelsToRemove = [
                        'Number of Associated Entities',
                        'Entity 1',
                        'Entity 2'
                    ];

                    this.fieldDetails = this.fieldDetails.filter(
                        field => !labelsToRemove.includes(field.Field_Label__c)
                    );
                }
                else if((this.customerProfile=='Non Working' || this.customerProfile== 'Others') && this.customerType == 'Individual'){
                    let labelsToRemove;

                    if(this.isHLUser){
                    labelsToRemove = [
                        'Sector',
                        'Sub Employment Type',
                        'CA Membership Number',
                        'Business Vintage',
                        'Office Ownership',
                        'Segment',
                        'Sub segment',
                        'Specialization',
                        'Business Industry',
                        'Registration Number',
                        'Constitution',
                        'Total Work Experience (In Years)',
                        'Total Work Experience (In Months)',
                        'MSME Category',
                        'Registration Number (LLPIN)',
                        'Udyam Registration Number',
                        'Specialization',
                        'Number of Associated Entities',
                        'Entity 1',
                        'Entity 2',
                        'Qualification',
                        'Is Financial applicant?',
                        'Business Commencement Date',
                        'Shareholder/Partner Name',
                        'Share Holding Percentage',
                        'Industry Code',
                        'PSL',
                        'BSR Code',
                        'Other Nature of Business',
                        'Trade Name',
                        'Nature of Business',
                        'Registration Number (CIN)',
                        'Business Entity Name'
                    ];}
                    else{
                        labelsToRemove = [
                        'Sector',
                        'Sub Employment Type',
                        'CA Membership Number',
                        'Business Vintage',
                        'Office Ownership',
                        'Segment',
                        'Sub segment',
                        'Specialization',
                        'Business Industry',
                        'Registration Number',
                        'Constitution',
                        'Total Work Experience (In Years)',
                        'Total Work Experience (In Months)',
                        'MSME Category',
                        'Registration Number (LLPIN)',
                        'Udyam Registration Number',
                        'Specialization',
                        'Number of Associated Entities',
                        'Entity 1',
                        'Entity 2',
                        'Qualification',
                        'Business Commencement Date',
                        'Shareholder/Partner Name',
                        'Share Holding Percentage',
                        'Industry Code',
                        'PSL',
                        'BSR Code',
                        'Other Nature of Business',
                        'Trade Name',
                        'Nature of Business',
                        'Registration Number (CIN)',
                        'Business Entity Name'
                    ];
                    }

                    this.fieldDetails = this.fieldDetails.filter(
                        field => !labelsToRemove.includes(field.Field_Label__c)
                    );
                }
                
               console.log('966----', this.currentApplicantType); 
                if (this.currentApplicantType === 'Primary Applicant') {
                    console.log('Inside Current Applicant type' );
                    const labelsToRemove = [
                        'Relationship with primary applicant'
                    ];

                    this.fieldDetails = this.fieldDetails.filter(
                        field => !labelsToRemove.includes(field.Field_Label__c)
                    );
                }
                console.log('maritalStatus----', maritalStatus);
                if (maritalStatus === 'Single' || maritalStatus === 'Divorced') {
                    console.log('Inside Mariatal status' );
                   /* const labelsToRemove = [
                        'Spouse First Name',
                        'Spouse Middle Name',
                        'Spouse Last Name'
                    ];

                    this.fieldDetails = this.fieldDetails.filter(
                        field => !labelsToRemove.includes(field.Field_Label__c)
                    );*/
                }
                if (this.qualification != 'Others') {
                    console.log('Inside qualification' );
                    const labelsToRemove = [
                        'Other Qualification'
                    ];

                    this.fieldDetails = this.fieldDetails.filter(
                        field => !labelsToRemove.includes(field.Field_Label__c)
                    );
                }

            if (this.appval[0].customerType == 'Non Individual') {
                console.log('Inside trueee--- 6818');

                this.fieldDetails = this.fieldDetails.map(field => {

                    if (field.Field_Label__c === "Sector") {
                        console.log('bhvghjkvgh----');

                        return { ...field, Is_Disabled__c: true };
                    }
                    return field;
                });
            }
        }
    }

    handleamlookupselectedAreaManager(event) {
        this.selectedDsaAreaManager = event.detail.searchRecord.Id;
        this.fieldDetails.forEach(record => {
            if (record.Storage_Field__c == 'Dsa_Area_Manager__r.Name') {
                console.log('Inside lookup Abhiraj');
                record.savedName = event.detail.searchRecord.Name;
                record.value = event.detail.searchRecord.Id;
            }
        })
    }
    handleamlookupdeselectedAreaManager(event) {
        this.selectedDsaAreaManager ='';
        this.fieldDetails.forEach(record => {
            if (record.Storage_Field__c == 'Dsa_Area_Manager__r.Name') {
                console.log('Inside lookup Abhiraj 2');
                record.value = '';
                record.savedName = '';
            }
        })
    }

    async getPicklistOptionsFromApex(isPicklist, storageObject, storageField) {
        if (isPicklist) {
            const result = await getPicklistValues({
                storageObject: storageObject,
                storageField: storageField
            });
            console.log('result from getPicklistValues Hardeek' + JSON.stringify(result));
            let picklistOptions = result.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });
            return picklistOptions;
        }
    }

    async getFilteredPicklistValues(picklistValues){
        console.log('picklistValues=:'+picklistValues);
        var tempVal = picklistValues.split(',');
        console.log('tempVal=:'+tempVal);
        let picklistOptions=[];
        for(var i=0;i<tempVal.length;i++){
            let doc = { label: tempVal[i], value: tempVal[i] };
            picklistOptions.push(doc);
            // var opt = {label: tempVal,value: tempVal};
            // picklistOptions.push(opt);
        }
        console.log('picklistOptions=:'+picklistOptions);
        return picklistOptions;
    }

    async getRelationValues(){
        console.log('Inside getRelationValues', this.selectedRecordId);
        const result = await getCoApplicantRelationFieldValues({
            loanId: this.recordId, 
            applicantId: this.selectedRecordId
        });
        console.log('result=:getRelationValues'+result);
        let picklistOptions=[];
        for(var i=0;i<result.length;i++){
            let doc = { label: result[i], value: result[i] };
            picklistOptions.push(doc);
            // var opt = {label: tempVal,value: tempVal};
            // picklistOptions.push(opt);
        }
        return picklistOptions;
    }

 async validateSaveAndNext(event) {
    console.log('validateSaveAndNext>>>>>>');
    this.getGeolocationAndProceed();
    try {
        // console.log('business address screen:: ' + this.businessAddressScreen);

        if (this.PANPage === true) {
            console.log('inside pan page validateSaveAndNext');
            this.PANPage = false;
            this.onePage = true;
            this.currentScreenSequence = this.currentScreenSequence + 1;
            this.getCurrentScreenFieldDetails();
            return;
        } else {
            console.log('inside else validateSaveAndNext');
            //console.log('this.activeSection.name941---',this.activeSection.name);
            this.showSpinner = true;
            // var isSaveLoanDetails = true;
            var isSaveLoanDetails = true;
            var fieldsAndMandatoryMap = {};

            var objectDataMap = {};
            objectDataMap['Application_Applicant__c'] = {};
            objectDataMap['Opportunity'] = {};
            objectDataMap['Applicant_Address__c'] = {};

            console.log('this.fieldDetails check Kshitiz-->' + JSON.stringify(this.fieldDetails));
            console.log('this.createCurrentAddressSameAsPermanentAddress Kshitiz-->' + this.createCurrentAddressSameAsPermanentAddress);
            if (this.createCurrentAddressSameAsPermanentAddress) {
                this.createCurrentAddress();
            }
            console.log('1384>>>');

            if (this.fieldDetails) {
                console.log('1387>>>>');
                // CHANGED: forEach -> for...of (structural only)
                //Sanwar(1/12/2025)
                if(this.passedScreenName == 'Seller Details' && ((this.oppStage == 'PSV' && this.oppSubStage == 'PSV Sales' && this.currentUserOppRole.includes('Sales')) || (this.oppStage == 'Disbursement' && this.oppSubStage == 'Ops Maker' && (this.currentUserOppRole.includes('OPS Maker') || this.currentUserOppRole.includes('Credit Officer')))) ){//sanwar(01/12/2025)(5/12/2025)(19/12/2025)
                    for (let record of this.fieldDetails) {
                        if (objectDataMap[record.Storage_Object__c]) {
                            objectDataMap[record.Storage_Object__c][record.Storage_Field__c] = record.value;
                        }
                    }
                    console.log('At 1279', JSON.stringify(objectDataMap));
                }
                //Sanwar(1/12/2025)             
                for (const record of this.fieldDetails) {
                    //change by Vedant for SFHL-1564 - start
                    if (record.Storage_Field__c === 'Disability_Percent__c') {
                        const disabilityField = this.fieldDetails.find(item => item.Storage_Field__c === 'Disability__c');
                        const disabilityValue = disabilityField ? disabilityField.value : '';
                        const normalizedValue = disabilityValue ? disabilityValue.trim().toLowerCase() : '';
                        const isRequired = normalizedValue !== 'not applicable';
                        if (!isRequired) {
                            console.log('Skipping Disability Percent validation');
                            record.Is_Mandatory__c = false;
                            record.value = null;
                            objectDataMap.Application_Applicant__c.Disability_Percent__c = '0';
                            continue;
                        }
                        const value = record.value;
                        if (value === null || value === '' || value === undefined) {
                            this.showSpinner = false;
                            this.dispatchEvent(
                                new ShowToastEvent({title: 'Error', message: 'Please enter disability percent.', variant: 'error',})
                            );
                            isSaveLoanDetails = false;
                            break;
                        }
                        const regex = /^(100(\.0{1,2})?|[0-9]{1,2}(\.\d{1,2})?)$/;
                        if (!regex.test(value)) {
                            this.showSpinner = false;
                            this.dispatchEvent(
                                new ShowToastEvent({title: 'Error', message: 'Percentage cannot exceed 100%.', variant: 'error',}) //change by Kunal Bisht for SFHL-1564
                            );
                            isSaveLoanDetails = false;
                            break;
                        }
                    }
                    //change by Vedant for SFHL-1564 - end
                    var tempfieldDataMap = {};

                    if (!record.Is_Formula_Feild__c) {
                        if (record.Is_Mandatory__c) {
                            console.log('All record Kshitiz-->  ' + JSON.stringify(record));
                            console.log('this.customerType=: Kshitiz' + this.customerType);
                            console.log('record.Applicable_For__c=: Kshitiz' + record.Applicable_For__c);
                            console.log('record.Storage_Object__c=: Kshitiz' + record.Storage_Object__c);
                            console.log('record.Storage_Field__c=: Kshitiz' + record.Storage_Field__c );
                            console.log('value Kshitiz>>>' + record.value);
                            console.log('visibilty controlled by Kshitiz>>>' + record.Visibility_Controlled_By__c + 'for field ' + record.Field_Label__c);
                            const nameFields = ['Mother_s_First_Name__c', 'Mother_s_Middle_Name__c', 'Mother_s_Last_Name__c'];
                            if (nameFields.includes(record.Storage_Field__c) && record.value && !checkSpecialCharacter(record.value)) {
                                console.log('Special character validation failed for', record.Storage_Field__c);
                                this.showSpinner = false;

                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: `Please enter ${record.Field_Label__c} in correct format.`,
                                        variant: 'error',
                                    })
                                );

                                isSaveLoanDetails = false;
                                break; 
                            }
                            if (record.Visibility_Controlled_By__c != null && record.Visibility_Controlled_By__c != '' && record.Visibility_Controlled_By__c != undefined) {
                                const dependentField = this.fieldDetails.find(item => item.Id == record.Visibility_Controlled_By__c);
                                //console.log('this.dependent -->' + JSON.stringify(dependentField));
                                if (dependentField) {
                                    console.log('dependent field 1021',JSON.stringify(dependentField));
                                    const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                                     console.log('arrDependentControlledValue Kshitiz 2' + arrDependentControlledValue + 'for field ' + record.Field_Label__c);
                                     console.log('record.value Kshitiz 2' + record.value);
                                     console.log('fieldVal Kshitiz 2' + record.Field_Label__c);
                                   // console.log(' this.empType' + this.empType);
                                    if (dependentField.value) {
                                        const fieldVal = String(dependentField.value);
                                        const fieldSavedName = String(dependentField.savedName);
                                        console.log('field val at 1160---'+fieldVal + 'for field ' + record.Field_Label__c);
                                        console.log('field value'+record.value + 'for field ' + record.Field_Label__c);
                                        if (arrDependentControlledValue.find(element => element == fieldVal.toLowerCase()) && (record.value == null || record.value == '' || record.value == undefined)) {
                                            //console.log('this.arrDependentControlledValue -->');
                                            if (this.customerType != undefined && (this.anyInvalid() || record.Applicable_For__c == 'Both' || record.Applicable_For__c == 'Individual-Both' || record.Applicable_For__c == 'Non Individual-Both' || record.Applicable_For__c == 'Non Individual' ||  record.Applicable_For__c == 'Individual'  || record.Applicable_For__c == (this.customerType + '-' + this.empType))) {
                                                if (record.Field_Label__c != 'Number of Associated Entities' && record.Field_Label__c != 'Total Work Experience (In Months)' && record.Field_Label__c != 'Total Work Experience (In Years)'){
                                                    console.log('tthis.customerType ->' + this.customerType);
                                                    console.log(' record.Applicable_For__c >' + record.Applicable_For__c);
                                                    console.log('record.Storage_Field__c=:' + record.Storage_Field__c);
                                                    console.log('record.Customer_Profile__c 1224 KD1--> ' + record.Customer_Profile__c);
                                                    this.showSpinner = false;
                                                    this.dispatchEvent(
                                                        new ShowToastEvent({
                                                            title: 'Error',
                                                            message: 'Please ensure all details are filled out correctly and in the valid format.',
                                                            variant: 'error',
                                                        })
                                                    );
                                                    // this.showErrorMessage('Please fill all the mandatory fields in order to proceed');
                                                    isSaveLoanDetails = false;
                                                    break; // CHANGED: return -> break
                                                }else{
                                                    var cusTypeList;
                                                    if (record.Applicable_For__c.includes('-')) {
                                                        cusTypeList = record.Applicable_For__c.split('-');
                                                    } else {
                                                        cusTypeList = record.Applicable_For__c;
                                                    }
                                                    if (this.customerProfile == 'SENP' && record.Applicant_Type_Visibility__c == this.currentApplicantType && (this.anyInvalid() || this.customerType == cusTypeList[0] || this.customerType == cusTypeList[1] || this.customerType == cusTypeList)){
                                                        console.log('tthis.customerType ->' + this.customerType);
                                                        console.log(' record.Applicable_For__c >' + record.Applicable_For__c);
                                                        console.log('record.Storage_Field__c=:' + record.Storage_Field__c);
                                                        console.log('record.Customer_Profile__c 1247 --> KD2' + record.Customer_Profile__c);
                                                        this.showSpinner = false;
                                                        this.dispatchEvent(
                                                            new ShowToastEvent({
                                                                title: 'Error',
                                                                message: 'Please ensure all details are filled out correctly and in the valid format.',
                                                                variant: 'error',
                                                            })
                                                        );
                                                        // this.showErrorMessage('Please fill all the mandatory fields in order to proceed');
                                                        isSaveLoanDetails = false;
                                                        break; // CHANGED: return -> break
                                                    }
                                                }

                                                
                                            }
                                        }
                                        else if (arrDependentControlledValue.find(element => element == fieldSavedName.toLowerCase()) && (record.value == null || record.value == '' || record.value == undefined)&& fieldSavedName == 'Others' ) {
                                            if (this.customerType != undefined && (this.anyInvalid() || record.Applicable_For__c == 'Both' || record.Applicable_For__c == 'Individual-Both' || record.Applicable_For__c == 'Individual'  || record.Applicable_For__c == (this.customerType + '-' + this.empType))) {
                                                if (record.Field_Label__c != 'Number of Associated Entities' && record.Field_Label__c != 'Total Work Experience (In Months)' && record.Field_Label__c != 'Total Work Experience (In Years)'){
                                                    console.log('record.Customer_Profile__c 1268 --> KD3' + record.Customer_Profile__c);
                                                    this.showSpinner = false;
                                                    this.dispatchEvent(
                                                        new ShowToastEvent({
                                                            title: 'Error',
                                                            message: 'Please ensure all details are filled out correctly and in the valid format.',
                                                            variant: 'error',
                                                        })
                                                    );
                                                    // this.showErrorMessage('Please fill all the mandatory fields in order to proceed');
                                                    isSaveLoanDetails = false;
                                                    break; // CHANGED: return -> break
                                                }
                                            }
                                        } 
                                        else if (this.customerType != undefined && (record.Applicable_For__c == 'Both' || record.Applicable_For__c == 'Individual-Both' || record.Applicable_For__c == 'Non Individual-Both' || record.Applicable_For__c == 'Non Individual' || record.Applicable_For__c == 'Individual' || record.Applicable_For__c == (this.customerType + '-' + this.empType)) && (arrDependentControlledValue.find(element => element == fieldVal.toLowerCase()) || arrDependentControlledValue.find(element => element == fieldSavedName.toLowerCase())) && (record.value != null || record.value != '' || record.value != undefined)) {
                                            console.log('1045-->' + record.value);
                                            console.log('record.Storage_Field__c=:' + record.Storage_Field__c);
                                            tempfieldDataMap = objectDataMap[record.Storage_Object__c];
                                            console.log('tempfieldDataMap-->' + JSON.stringify(tempfieldDataMap));
                                            tempfieldDataMap[record.Storage_Field__c] = record.value;
                                            console.log('tempfieldDataMap 2-->' + JSON.stringify(tempfieldDataMap));
                                            objectDataMap[record.Storage_Object__c] = tempfieldDataMap;
                                        }
                                    }
                                }

                            } else {
                                console.log('record.value::: 1296 ' + record.value + record.Storage_Field__c);
                                console.log('record.Storage_Field__c=: KD4' + record.Storage_Field__c);
                                console.log('any invalid>'+this.anyInvalid());
                                console.log('val map values>',this.validationMap.values());
                                if (this.anyInvalid() || record.value == null || record.value == '') {
                                    this.showSpinner = false;
                                    this.dispatchEvent(
                                        new ShowToastEvent({
                                            title: 'Error',
                                            message: 'Please ensure all details are filled out correctly and in the valid format.',
                                            variant: 'error',
                                        })
                                    );
                                    // this.showErrorMessage('Please fill all the mandatory fields in order to proceed 2');
                                    isSaveLoanDetails = false;
                                    break; // CHANGED: return -> break
                                } else {
                                    if(record.Storage_Field__c == 'Mobile_Number__c'){
                                                    const isValid = await this.validateMNRL(record.value);
                                                    console.log('isValid--->' + isValid);
                                                    if (!isValid) {
                                                        this.showSpinner = false;
                                                        isSaveLoanDetails = false;
                                                        break; // exit the loop, stop processing further
                                                    }

                                            }
                                    if (this.customerType != undefined && (record.Applicable_For__c == 'Both' || record.Applicable_For__c == 'Individual-Both' || record.Applicable_For__c == 'Non Individual-Both' || record.Applicable_For__c == 'Individual' || record.Applicable_For__c == 'Non Individual' || record.Applicable_For__c == (this.customerType + '-' + this.empType))) {
                                        console.log('record.Storage_Field__c=:' + record.Storage_Field__c);
                                        console.log('record.value=:' + record.value);
                                        tempfieldDataMap = objectDataMap[record.Storage_Object__c];
                                        tempfieldDataMap[record.Storage_Field__c] = record.value;
                                        objectDataMap[record.Storage_Object__c] = tempfieldDataMap;
                                    }
                                }
                                
                            }

                            if (record.Storage_Object__c == 'Opportunity' && record.Storage_Field__c == 'Requested_Amount__c') {
                                console.log('record.value in validate save--> ' + record.value);
                                const minAmount = this.subProductLimits?.minLoanAmount;
                                const maxAmount = this.subProductLimits?.maxLoanAmount;
                                if (minAmount !== undefined && maxAmount !== undefined) {
                                    const numericValue = parseFloat(record.value);
                                    console.log('numericValue: ' + numericValue);
                                    if (numericValue < minAmount || numericValue > maxAmount) {
                                        console.log('inside Error Scenario');
                                        isSaveLoanDetails = false;
                                        this.dispatchEvent(new ShowToastEvent({
                                            title: 'Error',
                                            message: `Requested Amount should be between ${minAmount} and ${maxAmount}`,
                                            variant: 'error',
                                        }));
                                        break; // CHANGED: return -> break
                                    }
                                } else {
                                    console.warn('Product limits not loaded yet.');
                                }
                            }

                            if (record.Storage_Object__c == 'Opportunity' && record.Storage_Field__c == 'Tenor_Months__c') {
                                const minTenure = this.subProductLimits?.minTenure;
                                const maxTenure = this.subProductLimits?.maxTenure;
                                if (minTenure !== undefined && maxTenure !== undefined) {
                                    const numericYearValue = parseFloat(record.value);

                                    if (numericYearValue < minTenure || numericYearValue > maxTenure) {
                                        isSaveLoanDetails = false;
                                        console.log('inside Error Scenario');
                                        this.dispatchEvent(new ShowToastEvent({
                                            title: 'Error',
                                            message: `Requested Tenure should be between ${minTenure} and ${maxTenure}`,
                                            variant: 'error',
                                        }));
                                        break; // CHANGED: return -> break
                                    }
                                } else {
                                    console.warn('Product limits not loaded yet.');
                                }
                            }
                             if (record.Storage_Object__c == 'Opportunity' && record.Storage_Field__c == 'Requested_ROI__c') {
                                const minROI = this.subProductLimits?.minROI;
                                const maxROI = this.subProductLimits?.maxROI;
                                if (minROI !== undefined && maxROI !== undefined) {
                                    const numericYearValue = parseFloat(record.value);

                                    if (numericYearValue < minROI || numericYearValue > maxROI) {
                                        isSaveLoanDetails = false;
                                        console.log('inside Error Scenario');
                                        this.dispatchEvent(new ShowToastEvent({
                                            title: 'Error',
                                            message: `Requested ROI should be between ${minROI} and ${maxROI}`,
                                            variant: 'error',
                                        }));
                                        break; // CHANGED: return -> break
                                    }
                                } else {
                                    console.warn('Product limits not loaded yet.');
                                }     
                             }
                        }
                        /*else if (record.Storage_Field__c === 'Current_Address_Proof__c') {
                            // Find the value of "Is_Current_Address_Same_As_Permanent__c"
                            const isAddressSameField = this.fieldDetails.find(
                                field => field.Storage_Field__c === 'Is_Current_Address_Same_As_Permanent__c'
                            );
                        
                            // Validate only if "Is_Current_Address_Same_As_Permanent__c" is "No" and the current field is empty
                            if (isAddressSameField && isAddressSameField.value === 'No' && (!record.value || record.value.trim() === '')) {
                                console.log('Validation triggered: Documents for Current Address Proof is mandatory.');
                                this.showSpinner = false;
                                this.showErrorMessage('Please upload Documents for Current Address Proof.');
                                isSaveLoanDetails = false;
                                return;
                            }
                        }*/

                        else {
                            console.log('Record Seleted',this.selectedRecordId);
                            tempfieldDataMap = objectDataMap[record.Storage_Object__c];
                            tempfieldDataMap[record.Storage_Field__c] = record.value;
                            console.log('record storage field>',record.Storage_Field__c);
                            console.log('record value>',record.value);
                            console.log('passed screen name>'+this.passedScreenName);
                            if(this.passedScreenName == 'Builder Details' || this.passedScreenName == 'Seller Details'){
                                console.log('Inside if');
                                tempfieldDataMap['Loan_Application__c'] = this.recordId;
                                console.log('Selected Record Id >>>',this.selectedRecordId);
                                if (this.selectedRecordId) {
                                    console.log('AT 1382')
                                    tempfieldDataMap['Id'] = this.selectedRecordId;
                                }
                                tempfieldDataMap['Applicant_Type__c'] = this.passedScreenName == 'Builder Details' ? 'Builder' : 'Seller';
                                if(record.Storage_Field__c == 'Name'){
                                    let lastSpaceIndex = record.value.lastIndexOf(' ');

                                    let firstPart = record.value.substring(0, lastSpaceIndex); // everything before last space
                                    let lastWord = record.value.substring(lastSpaceIndex + 1); // word after last space

                                        console.log('First Part:', firstPart); 
                                        console.log('Last Word:', lastWord); 

                                    tempfieldDataMap['First_Name__c'] = firstPart;
                                    tempfieldDataMap['Last_Name__c'] = lastWord;
                                }

                                if (record.Storage_Field__c == 'CKYC_Aadhar__c') {
                                    console.log('CKYC_Aadhar__c value is  '+record.value)
                                    record.value = this.ckycAadhaarNum;
                                    console.log('CKYC_Aadhar__c value after ckycAadhaarNum is '+record.value)
                                }
                            }
                            objectDataMap[record.Storage_Object__c] = tempfieldDataMap;
                            console.log('tempFieldDataMap 1167-->',JSON.stringify(tempfieldDataMap));
                            console.log('objectDataMap',JSON.stringify(objectDataMap));
                        }

                    }
                    if ( record.Storage_Object__c === 'Opportunity' && (record.Storage_Field__c === 'Dsa_Area_Manager__c' || record.Storage_Field__c === 'Dsa_Area_Manager__r.Name') && record.value) {
                        const f = record.Storage_Field__c;
                        objectDataMap.Opportunity[f] = record.value;
                        console.log('objectDataMap.Opportunity.' + f, '=>', record.value);
                    }


                    // If any blocking error occurred, break already set; respect it.
                    if (!isSaveLoanDetails) break;
                }
            }
            console.log('objectDataMap -->' + JSON.stringify(objectDataMap));
            console.log('showScreenFieldLoginAppFields -->' + this.showScreenFieldLoginAppFields);
            console.log('isSaveLoanDetails -->' + isSaveLoanDetails);
            console.log('formIdentifier ' + this.formIdentifier);
            console.log('this.activeSection.name 631' + this.activeSection.name);
            /*if (this.appval[0] && this.appval[0].consentStatus && this.appval[0].consentStatus == 'Accepted' && this.activeSection.name == 'Applicant\'s Basic Information') {
                isSaveLoanDetails = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Consent Recieved',
                        message: 'Data cannot be changed after consent is received.',
                        variant: 'error',
                    }),
                ); 
                this.getNextScreenDetails();
                 return;
            } */
            if (this.activeSection.name == "Login Fees") {
                if (this.consentReceived == true) {
                    console.log('inside selected Branch Id');
                    isSaveLoanDetails = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Consent',
                            message: 'Kindly receive consent for all the applicants.',
                            variant: 'error',
                        }),
                    );
                     return;
                }
                if (this.productAdded == false) {
                    console.log('inside selected Branch Id');
                    isSaveLoanDetails = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Product Unavailable',
                            message: 'Kindly fill the Product, PMAY details and select key applicant to proceed.',
                            variant: 'error',
                        }),
                    );
                     return;
                }
            }
            if (this.activeSection.name == "Loan Details" || this.activeSection.name == "Login Fees") {
                console.log('this.selectedBranchId: validate ' + this.selectedBranchId);
                console.log('this.selectedBankType: validate' + this.selectedBankType);
                if ((this.selectedBranchId == null || this.selectedBranchId == '') && this.branchAvailable == false) {
                    /*console.log('inside selected Branch Id');
                    isSaveLoanDetails = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Kindly populate the branch details and Relationship Manager / Area Manager details to proceed.',
                            variant: 'error',
                        }),
                    );*/
                }
                 else if(this.selectedBankType == 'HUB' && (this.subBranchSelected == null || this.subBranchSelected == '') && this.branchAvailable == false) {
                            console.log('inside selected Branch Id for HUB');
                            isSaveLoanDetails = false;
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: 'Kindly populate the branch details and Relationship Manager / Area Manager details to proceed.',
                                    variant: 'error',
                                }),
                            );
                }

                else if ((this.selectedDsaAreaManager == null || this.selectedDsaAreaManager =='') && this.branchAvailable == false) {
                    console.log('[999]selectedDsaAreaManager',this.selectedDsaAreaManager);
                    console.log('[AM][final check]',
                        'selected=', this.selectedDsaAreaManager,
                        'row=', (this.fieldDetails?.find(r => r.Storage_Object__c === 'Opportunity' && (r.Storage_Field__c === 'Dsa_Area_Manager__c' || r.Storage_Field__c === 'Dsa_Area_Manager__r.Name'))?.value),
                        'payload=', JSON.stringify(objectDataMap.Opportunity)
                    );
                    isSaveLoanDetails = false;
                    this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Kindly populate the branch details and Relationship Manager / Area Manager details to proceed.',
                        variant: 'error',
                        }),
                    );
                }
                else if(this.activeSection.name == "Login Fees"){
                     this.dispatchEvent(new CustomEvent('navigatetonexttab', {
                        detail: 'Eligibility'
                    }));
                }
                // checkBranchFromLoan({loanId: this.recordId})
                // .then(result => {
                //     this.branchAvailable = result;
                //     isSaveLoanDetails = result;// this.branchAvailable;
                //     if(this.branchAvailable == false) {
                //         console.log('inside branch false');
                //         setTimeout(() => {
                //             this.dispatchEvent(
                //                 new ShowToastEvent({
                //                     title: 'Branch Unavailable',
                //                     message: 'Kindly fill the branch detals to proceed.',
                //                     variant: 'error',
                //                 }),
                //             );
                //         }, 100);
                //         return;
                //     }
                //     console.log('isSaveLoanDetails: '+isSaveLoanDetails);
                // })
                // .catch(error => {
                //     console.log('checkBranchFromLoan error: '+error);
                // }) 
            }
            // if (this.activeSection.name == "Applicant's Basic Information" && this.appval[0]) {
            //     getExistingCustomer({
            //         loanId: this.recordId,
            //         applicantDetId: this.selectedRecordId
            //     }).then(result => {
            //         console.log('resultData', JSON.stringify(result));
            //         result.forEach(resultData => {
            //             if (resultData) {
            //                 console.log('Mobile_Number__c-->', resultData.Mobile_Number__c);
            //                 console.log('objectDataMap-->', objectDataMap.Application_Applicant__c);
            //                 var applicantData = objectDataMap.Application_Applicant__c;
            //                  if (resultData.Mobile_Number__c == applicantData.Mobile_Number__c && applicantData.Applicant_Type__c == 'Co Applicant' && resultData.Applicant_Type__c == 'Primary Applicant'
            //                     && resultData.Customer_Profile__c == 'SENP' && resultData.Customer_Type__c == 'Non Individual' && applicantData.Customer_Type__c == 'Individual' && resultData.Sector__c=='Proprietorship') {
            //                           console.log('applicantData.Mobile_Number__c 1201', applicantData.Mobile_Number__c);
            //                 } else if (resultData.Mobile_Number__c && applicantData.Mobile_Number__c && resultData.Mobile_Number__c == applicantData.Mobile_Number__c) {
            //                     isSaveLoanDetails = false;
            //                     this.dispatchEvent(
            //                         new ShowToastEvent({
            //                             title: 'Mobile Number',
            //                             message: 'This mobile number is already used, Please update mobile number.',
            //                             variant: 'error',
            //                         }),
            //                     );
            //                 }
            //             }
            //         });
            //     }).catch(error => {
            //         console.log('createCoAppAddress error: ' + error);
            //     });
            // }
            if (objectDataMap.Application_Applicant__c.Name_of_Organization__c || objectDataMap.Application_Applicant__c.Pan_Name__c) {
                if (charLength(objectDataMap.Application_Applicant__c.Name_of_Organization__c) != 0 && charLength(objectDataMap.Application_Applicant__c.Name_of_Organization__c) < 2) {
                    isSaveLoanDetails = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Name of Organization can not have less than 2 characters',
                            variant: 'error',
                        }),
                    );
                } if (charLength(objectDataMap.Application_Applicant__c.Pan_Name__c) != 0 && charLength(objectDataMap.Application_Applicant__c.Pan_Name__c) < 2) {
                    isSaveLoanDetails = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Name as per Pan can not have less than 2 characters',
                            variant: 'error',
                        }),
                    );
                }
            }
            if(objectDataMap.Application_Applicant__c.Total_Work_Experience_Months__c && objectDataMap.Application_Applicant__c.Total_Work_Experience_Years__c
                && objectDataMap.Application_Applicant__c.Current_Work_Experience_Months__c && objectDataMap.Application_Applicant__c.Current_Work_Experience_Years__c
            ){
                var totalExp = (parseInt(objectDataMap.Application_Applicant__c.Total_Work_Experience_Years__c) * 12 + parseInt(objectDataMap.Application_Applicant__c.Total_Work_Experience_Months__c));
                var currentExp = (parseInt(objectDataMap.Application_Applicant__c.Current_Work_Experience_Years__c) * 12 + parseInt(objectDataMap.Application_Applicant__c.Current_Work_Experience_Months__c));
                if(totalExp < currentExp){
                isSaveLoanDetails = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Total work experience cannot be less than current work experience',
                            variant: 'error',
                        }),
                    );
                }
            }

            // CHANGED: replace setTimeout(..., 300) with awaited delay
            await new Promise(resolve => setTimeout(resolve, 300));

            if (isSaveLoanDetails) {
                console.log('isSaveLoanDetails');
                if (objectDataMap != {}) {
                    console.log('objectDataMap---> ', JSON.stringify(objectDataMap));
                    console.log('this.selectedRecordId---c/additionalFileUploadComponent 549'+ this.selectedRecordId);
                    console.log('this.recordId in saveLoan ' + this.recordId);
                    console.log('this.formIdentifier ' + this.formIdentifier);
                    
                    // CHANGED: use await instead of then/catch (structure only)
                    try {
                        console.log('at 1787');
                        // const response = await 
                        if(this.passedScreenName == 'Builder Details' || this.passedScreenName == 'Seller Details'){ //Kalpesh
                            if (objectDataMap.Application_Applicant__c && objectDataMap.Application_Applicant__c.Id) {
                                delete objectDataMap.Application_Applicant__c.Id;
                                this.selectedRecordId='';
                            }
                        }
                        console.log('at 17997'+JSON.stringify(objectDataMap));
                        savecreateLoanDetails({
                            fieldsDataMap: JSON.stringify(objectDataMap),
                            loanId: this.recordId,
                            formIdentifier: this.formIdentifier,
                            applicantDetId: this.selectedRecordId
                        }).then(response => {
                        console.log('response1874 --> ', JSON.stringify(response));

                        if (this.recordId != null && this.recordId != '' && this.recordId != undefined) {
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Success',
                                    message: 'Data saved successfully',
                                    variant: 'success',
                                }),
                            );
                            // this.fieldDetails = this.fieldDetails.map(item => {
                            //     return{
                            //         ...item,
                            //         Is_Disabled__c : true
                            //     }
                            // })
                            if(this.passedScreenName == 'Builder Details' || this.passedScreenName == 'Seller Details'){
                                const valueSelectedEvent = new CustomEvent('builderselleradd', {
                                    detail: {
                                        loanId: this.recordId,
                                        screenName: this.activeSection.name,
                                        applicantId: response.loanId
                                    }
                                });
                                this.isNewSaved = true;
                                this.selectedRecordId = response.loanId;
                                this.dispatchEvent(valueSelectedEvent);
                            }
                        } else {
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Success',
                                    message: 'Data saved successfully',
                                    variant: 'success',
                                }),
                            );
                        }
                        if (this.activeSection.name == 'Applicant\'s Basic Information') {
                            console.log('661  this.activeSection.name  ' + this.activeSection.name);
                            console.log('662  selectedRecordId  ' + this.selectedRecordId);
                            this.updateRecordField(this.selectedRecordId, 'Basic_Details_Filled__c', 'true');
                           this.fetchApplicants();
                            this.callUCICAPI();
                        }
                        console.log('754  this.activeSection.name  ' + this.activeSection.name);
                        if (this.activeSection.name == 'Applicant\'s Additional Information') {
                            console.log('661  this.activeSection.name  ' + this.activeSection.name);
                            console.log('662  selectedRecordId  ' + this.selectedRecordId);
                            this.updateRecordField(this.selectedRecordId, 'Additional_Infromation_Filled__c', 'true');
                        }
                        
                        console.log('attt 759---');

                        console.log('at 666---');
                        console.log('response---- at 667', response);

                        // this.recordId = response.loanId;
                        this.mainApplicantId = response.applicantId;

                        //  if(this.showPermanentAdr){
                        //      this.savePermanentAddress();
                        //  }

                        console.log('at 676---');
                        if (this.activeSection.name == "Additional Information") {
                            console.log('this.selectedBranchId: validate ' + this.selectedBranchId);
                            console.log('this.selectedBankType: validate' + this.selectedBankType);
                            this.modalAPIVisibility = true;
                            // this.checkNextStageMovement();
                            // this.getNextScreenDetails();
                        }
                        else {
                            if (!this.showSaveVisibility) {
                                if (this.currentScreenSequence < 20) {
                                    if (this.activeSection.name != 'Applicant\'s Basic Information' && this.activeSection.name != 'Employment Details' && this.activeSectionName!='Loan Details') {
                                        this.currentScreenSequence = this.currentScreenSequence + 1;
                                    }
                                    if(this.activeSection.name=='Loan Details'){
                                         console.log('this.currentScreenSequence=:1815'+this.currentScreenSequence);
                                          this.currentScreenSequence = this.currentScreenSequence + 1;
                                          this.activeSectionName='Login Fee';
                                           console.log('this.currentScreenSequence=:1815'+this.currentScreenSequence);
                                    }
                                    if(this.activeSection.name=='Employment Details'){
                                        const valueSelectedEvent = new CustomEvent('opennextscreen', {
                                            detail: {
                                                loanId: this.recordId,
                                                screenName: 'Cibil'
                                            }
                                        });
                                        this.dispatchEvent(valueSelectedEvent);
                                        //this.currentScreenSequence = this.currentScreenSequence + 1;
                                        //this.activeSectionName='Cibil';
                                        //console.log('this.currentScreenSequence=:1815'+this.currentScreenSequence);
                                    }

                                    console.log('this.currentScreenSequence=:1816'+this.currentScreenSequence);
                                    console.log('at 682----');
                                    // if(this.activeSection.name == 'Loan Details'){
                                    //     this.showCustomCmp('LoginFeeCmp');
                                    //     this.isCustomCmp=true;
                                    // }
                                    // else{
                                    this.getCurrentScreenFieldDetails();
                                    // }

                                    if (this.isCustomCmp == false) {
                                        console.log('inside here customcmp false 2::');
                                        this.getLoanDetails();
                                        this.showSpinner = false;
                                    }
                                } else {
                                    this.currentScreenSequence = this.currentScreenSequence - 1;
                                }
                            }

                            if (this.activeSection.name != 'Applicant\'s Basic Information' && this.activeSection.name != 'Loan Details') {
                                const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
                                    detail: {
                                        loanId: this.recordId,
                                        screenName: this.activeSection.name,
                                        applicantId: this.selectedRecordId
                                    }
                                });

                                this.dispatchEvent(valueSelectedEvent);
                                this.getScreenDetailsFromApex();
                            }
                            console.log('Inside 1846');
                            // if(this.activeSection.name == 'Loan Details'){
                            //     console.log('Inside 1848');
                            //     this.showCustomCmp('LoginFeeCmp');
                            //     this.isCustomCmp=true;
                            // }
                            // else{
                            this.getNextScreenDetails();
                            // }
                           
                            
                            //this.getCompletionPercent();

                        }
                        if(this.passedScreenName != 'Builder Details' && this.passedScreenName != 'Seller Details'){
                        //this.saveCoaappCureentAddress(objectDataMap);
                        }
                        const buttonId = event.currentTarget.dataset.id;
                        if(buttonId === 'save-pmay-button'){
                            this.updateRecordField(
                                this.recordId,
                                'Login_Completion_Stage__c',
                                'Applicant Information;Application Information;'
                            );
                        }
                        if(buttonId === 'save-next-button'){
                            this.updateRecordField(
                                this.recordId,
                                'Login_Completion_Stage__c',
                                'Applicant Information;Application Information;Other Information;Collateral'
                            );
                        }
                        console.log('1400---');
                        }).catch(error => {
                                console.error('Error fetching document:', error);
                            });
                    } catch (error) {
                        console.log('saveLoanDet error: ' + JSON.stringify(error));
                        console.error('saveLoanDet error: ' + JSON.stringify(error));
                        this.showSpinner = false;
                        if (error != undefined && error.body != undefined && error.body.message != undefined) {
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: error.body.message,
                                    variant: 'error',
                                }),
                            );
                        }
                    }
                } else {
                    console.log('inelse');
                    if (this.currentScreenSequence < 20) {
                        this.getCurrentScreenFieldDetails();
                        if (this.activeSection.name != "Applicant's Basic Information") {
                            const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
                                detail: {
                                    loanId: this.recordId,
                                    screenName: this.activeSection.name
                                }
                            });
                            this.dispatchEvent(valueSelectedEvent);

                        }
                        if (this.isCustomCmp == false) {
                            this.getLoanDetails();
                        }
                        this.getNextScreenDetails();
                    } else {
                        this.showSpinner = false;
                        this.currentScreenSequence = this.currentScreenSequence - 1;
                    }
                }
            }
        }
    } finally {

        this.showSpinner = false;
    this.connectedCallback();
       
    }
}

    saveCoaappCureentAddress(objectDataMap) {
        console.log('objectDataMap saveCoaappCureentAddress:', JSON.stringify(objectDataMap));

        let pincodeValue = objectDataMap.Application_Applicant__c["Pincode__r.Name"];
        console.log('Pincode:', pincodeValue);

        createCoAppAddress({
            pincode: pincodeValue,
            loanId: this.recordId,
            applicantDetId: this.selectedRecordId
        })
            .then(result => {
                console.log('createCoAppAddress result:', result);
            })
            .catch(error => {
                console.error('createCoAppAddress error:', error);
            });
    }

    checkBranch() {
        checkBranchFromLoan({ loanId: this.recordId })
            .then(result => {
                this.branchAvailable = result;
                console.log('isSaveLoanDetails: ' + this.branchAvailable);
            })
            .catch(error => {
                console.log('checkBranchFromLoan error: ' + error);
            })
    }

    getNextScreenDetails() {
        console.log('this.formIdentifier>', this.formIdentifier);
        console.log('this.activeSection.name 634 kshitiz 3' + this.activeSection.name);
        console.log('this.currentAppseq--- 635', this.currentAppSeq);
        getNextScreenDetails({
            currentAppSeq: this.currentAppSeq,
            activeSectionName: this.activeSection.name,
            formIdentifier: this.formIdentifier
        })
            .then(result => {
                console.log('result-----635', result);
                if(result == 'PMAY Eligibility' || result == 'Login Fees'){
                    const valueChangeEvent = new CustomEvent("callloandetails", {
                        detail: { value: this.recordId, name: result, currentAppSeq: '2' }
                    });
                    this.dispatchEvent(valueChangeEvent);
                }else{
                const valueSelectedEvent = new CustomEvent('opennextscreen', {
                    detail: {
                        screenName: result
                    }
                });
                this.dispatchEvent(valueSelectedEvent);
                }
            })
            .catch(error => {
                console.log(error);
            })
    }
    previousAction() {
        this.showPermanentAdr = true; //was false before
        this.currentScreenSequence = this.currentScreenSequence - 1;

        this.loadLookUps = false;

        if (this.currentScreenSequence > 0) {
            this.getCurrentScreenFieldDetails();

            if (this.isCustomCmp == false && this.recordId != null && this.recordId != '' && this.recordId != undefined) {
                this.getLoanDetails();
            }
        }
    }

    previousActionFromCustom(event) {
        console.log('event -->' + JSON.stringify(event));
        if (event.detail.recordId != null && event.detail.recordId != '' && event.detail.recordId != undefined) {
            this.recordId = event.detail.recordId;
        }

        this.showPermanentAdr = true; //was false before
        this.currentScreenSequence = this.currentScreenSequence - 1;

        this.loadLookUps = false;

        if (this.currentScreenSequence > 0) {
            this.getCurrentScreenFieldDetails();

            if (this.isCustomCmp == false && this.recordId != null && this.recordId != '' && this.recordId != undefined) {
                this.getLoanDetails();
            }
        }
    }

    getLoanDetails() {
        try {
this.getIndustryOnLoan();
            // if(this.selectedRecordId== null || this.selectedRecordId == '' || this.selectedRecordId == undefined){
            //     this.selectedRecordId= this.recordId;
            // }
            console.log('780 '+this.selectedRecordId);
            console.log('782 ' + this.screenName);
            setTimeout(() => {
                console.log('at 796');

                getLoanDetailsFromStorageObject({
                    screenName: this.screenName,
                    loanId: this.recordId,
                    formIdentifier: this.formIdentifier,
                    recordId: this.selectedRecordId,
                    did: ''
                }).then(result => {
                    console.log('at result 802-----', JSON.stringify(result));

                    this.showSpinner = false;
                    this.loadLookUps = false;
                    console.log('At 806---');
                   // const gstExempt;
                    const gstExempt = result.find(fd => fd.fieldLabel == 'GST Exempt');
                    console.log('gstExempt 808---', JSON.stringify(gstExempt));
                    this.gstExempt = gstExempt?.fieldValue;
                    console.log('this.gstExempt 809---', this.gstExempt);
                    var isFetchFromReadObject = true;
                    console.log('detailsWrapperList from getLoanDetailsFromStorageObject--> Kshitiz 4' + JSON.stringify(result));
                    console.log('fieldDetails-> Kshitiz 4' + JSON.stringify(this.fieldDetails));
                    if (this.fieldDetails) {
                        result.forEach(item => {
                            isFetchFromReadObject = false;
                            if (item.fieldApiName == 'Branch_Master__r.Name' && item.lookUpfieldValue != null && item.lookUpfieldValue != undefined) {
                                this.selectedBranchId = item.lookUpfieldValue;
                                this.sunBranchFilter = '[ParentId = ' + item.lookUpfieldValue + ';RecordType.Name = Branch;Branch_Type__c=REGIONALOFFICE]';
                                console.log('1867--',this.sunBranchFilter)
                            }
                            if (item.fieldApiName === 'HL_Area_Manager__r.Name' || item.fieldApiName === 'Dsa_Area_Manager__c') {
                                const serverId = item.lookUpfieldValue || item.fieldValue;
                                    this.selectedDsaAreaManager = String(serverId);
                                    console.log('[AM][getLoanDetails/outer] selectedDsaAreaManager <=', this.selectedDsaAreaManager);
                            }
                            if (item.fieldApiName == 'Is_Current_Address_Same_As_Permanent__c' && item.fieldValue == 'No') {
                                this.showPermanentAdr = true;
                                this.showUploadCurrentAddressProofDoc = true;
                            }
                            if(this.customerType == 'Individual' ){
                               this.fieldDetails = this.fieldDetails.filter(fd=> fd.Applicable_For__c !== 'Non Individual');
                                const constitution = result.find(fd => fd.fieldLabel == 'Constitution');
                                if(constitution){
                                constitution.fieldLabel = 'Segment';}
                              /*  console.log('gstExempt 808---', JSON.stringify(constitution));
                                this.gstExempt = gstExempt?.fieldValue;
                                console.log('this.gstExempt 809---', this.gstExempt);*/
                            }
                            if(this.customerType == 'Non Individual' ){
                                this.fieldDetails = this.fieldDetails.filter(fd=> fd.Applicable_For__c !== 'Individual');
                            }
                            /*if(item.fieldApiName == 'Permanent_Address_Same_As_Current_Addres__c' && item.fieldValue == 'No'){
                                this.showPermanentAdr = true;
                                this.permanentAddressFilled = true;
                            }*/

                            /*if(item.fieldApiName == 'Is_Permanent_Address_Not_Same_As_Current__c' && item.fieldValue){
                                this.showPermanentAdr = true;
                                this.permanentAddressFilled = true;
                            }*/
                            console.log('item.fieldApiName at 810--- Kshitiz 4', JSON.stringify(this.fieldDetails));
                            this.fieldDetails.forEach(record => {
                                //console.log('item.fieldApiName at 810---', item.fieldApiName);
                                //console.log('item.fieldValue at 180----', item.fieldValue);
                                //console.log('record. id==', record.Id);
                                //console.log('record.Storage_Field__c----', item.Storage_Field__c);

                               // setTimeout(() => {
                                    if (this.fieldDetails) {
                                    
                                    if (record.Is_Hidden__c) {
                                        record.hideField = true;
                                        if(this.template.querySelector(`[data-rec="${record.Id}"]`)){
                                            this.template.querySelector(`[data-rec="${record.Id}"]`).classList.add('slds-hide');
                                     }                       
                                    }
                            
                            }           
                            //}, 1000)
                                if (record.Storage_Field__c == 'Sub_Branch__r.Name' && (item.fieldValue != null && item.fieldValue != '' && item.fieldValue != undefined) && this.subBranchRequired) {
                                    console.log('at true 845--');

                                    record.showSubBranchLookup = true;
                                    if(!(record.savedName && record.value)){
                                        console.log('2157>>>>>>');
                                    record.savedName = this.defaultSubBranch.Name;
                                    record.value = this.defaultSubBranch.Id;
                                    }
                                   
                                }
                                if (item.fieldApiName == record.Storage_Field__c && record.is_Lookup__c) {
                                    record.savedName = item.fieldValue; //item.lookUpfieldValue;
                                    record.value = item.lookUpfieldValue;
                                    console.log('record -->' + JSON.stringify(record));
                                } else if (item.fieldApiName == record.Storage_Field__c && record.Storage_Field__c != 'Industry__c') {
                                    record.value = item.fieldValue;
                                    //change by Vedant for SFHL-1564 - start
                                    if (record.Storage_Field__c === 'Disability__c') {
                                        console.log('Calling disability dependency on reload');
                                        this.handleDisabilityDependency(record.value);
                                    }
                                    //change by Vedant for SFHL-1564 - end
                                }else if (item.fieldApiName == record.Storage_Field__c && record.Storage_Field__c == 'Industry__c') {
                                    if(item.fieldValue!= null && item.fieldValue != '' && item.fieldValue != undefined){
                                        record.value = item.fieldValue;
                                    }else{
                                        record.value = '';
                                    }
                                    console.log('record valueee----', record.value);
                                    
                                }
                                else if (record.Show_in_words__c) {
                                    if (record.value) {
                                        getNumberToWord({ laAmt: record.value })
                                            .then(result => {
                                                this.loanamtinwords = result;
                                            })
                                            .catch(error => {
                                                console.error('Error fetching converted amount', error);
                                            });
                                    } else {
                                        this.loanamtinwords = '';
                                    }
                                }
                                if(item.fieldLabel == 'Name of the Builder' || item.fieldLabel=='Name of the Seller'){
                                    this.isNewSaved = true;
                                    
                                }
                                if(this.gstExempt == 'Yes' && record.Field_Label__c == 'GSTIN'){
                                    record.Is_Mandatory__c = false;
                                }
                                if(this.gstExempt == 'No' && record.Field_Label__c == 'GSTIN'){
                                    record.Is_Mandatory__c = true;
                                }
                                if(this.isNewSaved == false && (item.fieldApiName == record.Storage_Field__c && (record.Storage_Field__c == 'Name' 
                                    || record.Storage_Field__c == 'PAN_Number__c' 
                                    || record.Storage_Field__c == 'Contact_Person_Name__c' || record.Storage_Field__c == 'Contact_Person_Number__c'))){
                                        record.value = '';
                                }
                            });
                        });

                        setTimeout(() => {
                            this.loadLookUps = true;
                            
                            
                            console.log('this.customerType 1781=:' + this.customerType);
                            console.log('this.customerProfile 1782=:' + this.customerProfile);
                            console.log('this.currentApplicantType 1783=: KSHITIZ 5' + JSON.stringify(this.fieldDetails));
                            this.fieldDetails.forEach(record => {
                                console.log('record.Visibility_Controlled_By__c=: Kshtiz 3' + record.Visibility_Controlled_By__c);
                                console.log('record.Storage_Field__c=: Kshitiz 3' + record.Storage_Field__c);

                                try{
                                if (record.Visibility_Controlled_By__c != null && record.Visibility_Controlled_By__c != '' && record.Visibility_Controlled_By__c != undefined) {
                                    const dependentField = this.fieldDetails.find(item => item.Id == record.Visibility_Controlled_By__c);
                                    console.log('dependentField=:' + JSON.stringify(dependentField));
                                    const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                                    console.log('arrDependentControlledValue=: Kshitiz 3' + arrDependentControlledValue);
                                   // console.log('1734 Kshitiz 3',dependentField.value);
                                    console.log('1735 Kshitiz 3',record.Field_Label__c);
                                    if (dependentField.value != null && dependentField.value != '' && dependentField.value && dependentField.value != undefined && record.Field_Label__c != 'Total Work Experience (In Months)' && record.Field_Label__c != 'Total Work Experience (In Years)') {
                                        if (arrDependentControlledValue.find(element => element == dependentField.value.toLowerCase())) {
                                            record.hideField = false;
                                            setTimeout(() => {
                                                if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                                                    this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                                                }                                                
                                            }, 1000)
                                           // arrDependentControlledValue.find(element => element == dependentField.savedName.toLowerCase())
                                        } else if( dependentField.savedName == 'Non Working' || dependentField.savedName== 'Others'){
                                            record.hideField = false;
                                            setTimeout(() => {
                                                if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                                                    this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                                                }                                                
                                            }, 1000)
                                        }
                                         else {
                                            try {
                                            record.hideField = true;
                                            setTimeout(() => {
                                                    console.log('record.Id----', record.Id);
                                                    
                                                    if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                                                        console.log('In if condition');
                                                        
                                                        this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                                                    }
                                                    
                                            }, 1000)
                                            } catch (error) {
                                                console.log('errorrr---', error);
                                                
                                            }
                                            
                                        }
                                    }
                                    else {
                                        record.hideField = true;
                                        setTimeout(() => {
                                            if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                                            this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                                            }
                                            
                                        }, 1000)
                                    }

                                }
                                if (this.customerProfile == 'SEP' && (record.Field_Label__c == 'Total Work Experience (In Months)' || record.Field_Label__c == 'Total Work Experience (In Years)')) {
                                    
                                    if (this.currentApplicantType == 'Primary Applicant' ) {
                                        console.log('Inside hide for applicant loop-----');
                                        record.hideField = false;
                                        setTimeout(() => {
                                            this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                                        }, 1000)
                                    }
                                }
                                if (this.customerProfile == 'SENP' && (record.Field_Label__c == 'Total Work Experience (In Months)' || record.Field_Label__c == 'Total Work Experience (In Years)')) {
                                    var cusTypeList;
                                    if (record.Applicable_For__c.includes('-')) {
                                        cusTypeList = record.Applicable_For__c.split('-');
                                    } else {
                                        cusTypeList = record.Applicable_For__c;
                                    }
                                    if (record.Applicant_Type_Visibility__c == this.currentApplicantType && (this.customerType == cusTypeList[0] || this.customerType == cusTypeList[1] || this.customerType == cusTypeList)) {
                                        console.log('Inside hide for applicant loop-----');record.hideField = true;
                                        setTimeout(() => {
                                            if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                                            this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                                            }                                            
                                        }, 1000)
                                    }
                                }
                                else if((this.customerProfile=='Non Working' || this.customerProfile=='Others' ) && this.customerType == 'Individual'){
                                    if (this.removedFields) {
                                        this.fieldDetails = this.fieldDetails.concat(this.removedFields);
                                    }
                                   let labelsToRemove;
                                    if(this.isHLUser){
                                    const labelsToRemove = [
                                        'Sector',
                                        'CA Membership Number',
                                        'Sub Employment Type',
                                        'Business Vintage',
                                        'Office Ownership',
                                        'Segment',
                                        'Sub segment',
                                        'Specialization',
                                        'Business Industry',
                                        'Registration Number',
                                        'Constitution',
                                        'Total Work Experience (In Years)',
                                        'Total Work Experience (In Months)',
                                        'MSME Category',
                                        'Registration Number (LLPIN)',
                                        'Udyam Registration Number',
                                        'Specialization',
                                        'Number of Associated Entities',
                                        'Entity 1',
                                        'Entity 2',
                                        'Qualification',
                                        'Is Financial applicant?',
                                        'Business Commencement Date',
                                        'Shareholder/Partner Name',
                                        'Share Holding Percentage',
                                        'Industry Code',
                                        'PSL',
                                        'BSR Code',
                                        'Other Nature of Business',
                                        'Trade Name',
                                        'Nature of Business',
                                        'Registration Number (CIN)',
                                        'Business Entity Name'
                                    ];}
                                    {
                                        const labelsToRemove = [
                                        'Sector',
                                        'CA Membership Number',
                                        'Sub Employment Type',
                                        'Business Vintage',
                                        'Office Ownership',
                                        'Segment',
                                        'Sub segment',
                                        'Specialization',
                                        'Business Industry',
                                        'Registration Number',
                                        'Constitution',
                                        'Total Work Experience (In Years)',
                                        'Total Work Experience (In Months)',
                                        'MSME Category',
                                        'Registration Number (LLPIN)',
                                        'Udyam Registration Number',
                                        'Specialization',
                                        'Number of Associated Entities',
                                        'Entity 1',
                                        'Entity 2',
                                        'Qualification',
                                        'Business Commencement Date',
                                        'Shareholder/Partner Name',
                                        'Share Holding Percentage',
                                        'Industry Code',
                                        'PSL',
                                        'BSR Code',
                                        'Other Nature of Business',
                                        'Trade Name',
                                        'Nature of Business',
                                        'Registration Number (CIN)',
                                        'Business Entity Name'
                                    ];
                                    }

                                    this.removedFields = this.fieldDetails.filter(
                                        field => labelsToRemove.includes(field.Field_Label__c)
                                    );
                                    this.fieldDetails = this.fieldDetails.filter(
                                        field => !labelsToRemove.includes(field.Field_Label__c)
                                    );
                                }

                                if (record.Is_Controlling_Picklist__c) {
                                    getFieldDependencies({
                                        objectName: record.Storage_Object__c,
                                        controllingField: record.Storage_Field__c,
                                        dependentField: record.Dependent_Picklist__c
                                    }).then(result => {
                                        console.log('Dependent picklist values: in connected callbackkk---record.Dependent_Picklist__c', record.value, '--', JSON.stringify(result), '= ', record.Dependent_Picklist__c);
                                        const dependentPicklistOptions = result[record.value];
                                        console.log('dependentPicklistOptions----', dependentPicklistOptions);

                                        // const targetField = this.fieldDetails.find(item => item.Storage_Field__c === record.Dependent_Picklist__c);

                                        const targetField = this.fieldDetails.find(item => {
                                            const isStorageFieldMatch = item.Storage_Field__c === record.Dependent_Picklist__c;

                                            console.log('this.customerType----', this.customerType);

                                            if (this.customerType != undefined && (item.Applicable_For__c == 'Both' || item.Applicable_For__c == 'Individual-Both' || item.Applicable_For__c == 'Non Individual-Both' || item.Applicable_For__c == (this.customerType + '-' + this.empType))) {
                                                return isStorageFieldMatch;
                                            }
                                            else if (item.Applicable_For__c == this.customerType) {
                                                return isStorageFieldMatch;
                                            }
                                        });


                                        if (targetField) {
                                            console.log('Inside target field---', targetField.Id);
                                            if(this.isHLUser && targetField.Storage_Field__c=='Customer_Profile__c'){
                                                dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Others');
                                            }else if(!this.isHLUser && targetField.Storage_Field__c=='Customer_Profile__c'){
                                                dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Non Working');
                                            }
                                            if(this.template.querySelector(`[data-id="${targetField.Id}"]`)){
                                            this.template.querySelector(`[data-id="${targetField.Id}"]`).options = dependentPicklistOptions;
                                            }
                                            
                                        }
                                    }).catch(error => {
                                        if (error != undefined && error.body != undefined && error.body.message != undefined) {
                                            this.dispatchEvent(
                                                new ShowToastEvent({
                                                    title: 'Error',
                                                    message: error.body.message,
                                                    variant: 'error',
                                                }),
                                            );
                                        }
                                    });
                                }
this.getIndustryOnLoan();

                                getFieldDependencies({
                                    objectName: 'Application_Applicant__c',
                                    controllingField: 'Sector__c',
                                    dependentField: 'Industry__c'
                                }).then(result => {
                                    console.log('dependent picklist values List=:1' + JSON.stringify(result));
                                    console.log('record.value--sector--', JSON.stringify(record));
                                    if(record.Storage_Field__c == 'Sector__c'){
                                        const dependentPicklistOptions = result[record.value];
                                        console.log('dependent picklist options>',JSON.stringify(dependentPicklistOptions));
                                        // const targetId = this.fieldDetails.find(item => item.Storage_Field__c == currentFieldDetails.Dependent_Picklist__c);
                                        // console.log('target id000000', targetId.Id);
                                        this.industryPicklistOptions = dependentPicklistOptions;
                                        // this.template.querySelector(`[data-id="${targetId.Id}"]`).options = dependentPicklistOptions;
                                        const matchingFields = this.fieldDetails.filter(item =>
                                            item.Storage_Field__c === currentFieldDetails.Dependent_Picklist__c
                                        );

                                        matchingFields.forEach(field => {
                                            console.log('field.Field_Label__c at 2686---', field.Field_Label__c);
                                            console.log('dependentPicklistOptions.length----', dependentPicklistOptions.length);
                                            
                                            
                                            if(field.Field_Label__c === 'Segment'  && dependentPicklistOptions.length === 1){
                                                field.value = dependentPicklistOptions[0].value;
                                                this.fieldDetails.forEach(record => {
                                                    if (record.Visibility_Controlled_By__c == field.Id && record.Id != field.Id) {
                                                        const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                                                        if (arrDependentControlledValue.find(element => element ==  field.value.toLowerCase())) {
                                                            console.log('inside show');
                                                            record.hideField = false;
                                                            console.log('record.Id----', record.Id);
                                    
                                                            setTimeout(() => {
                                                                const element = this.template.querySelector(`[data-id="${record.Id}"]`);
                                                                if (element) {
                                                                    setTimeout(() => {
                                                                        element.classList.remove('slds-hide');
                                                                    }, 1000)
                                    
                                                                } else {
                                                                    console.error(`Element with data-id="${record.Id}" not found`);
                                                                }
                                                            }, 100);
                                                            // this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                                                        } else {
                                                            console.log('inside hide');
                                                            // record.value = '';
                                                            record.hideField = true;
                                                            setTimeout(() => {
                                                                if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                                                                    this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                                                                }
                                                                
                                                            }, 1000)
                                    
                                                        }
                                                    }
                                                });
                                            }

                                            console.log('value in auto populate---', field);
                                            
                                            const targetElement = this.template.querySelector(`[data-id="${field.Id}"]`);
                                            if (targetElement) {
                                                targetElement.options = dependentPicklistOptions;
                                            }
                                            
                                        });
                                    }
                                }).catch(error => {
                                    if (error != undefined && error.body != undefined && error.body.message != undefined) {
                                        this.dispatchEvent(
                                            new ShowToastEvent({
                                                title: 'Error',
                                                message: error.body.message,
                                                variant: 'error',
                                            }),
                                        );
                                    }
                                })
                                if (this.passedScreenName == 'Seller Details' && record.Storage_Field__c == 'CKYC_Aadhar__c') { 
                                    console.log('record.Storage_Field__c  '+record.Storage_Field__c)
                                    console.log('CKYC_Aadhar__c value on load is '+record.value)
                                    if (record.value) {
                                        this.ckycAadhaarNum = record.value
                                        record.value = '*'.repeat(record.value.length);
                                    }
                                    console.log('ckycAadhaarNum  '+this.ckycAadhaarNum)
                                }
                                // else{
                                //     record.hideField = false;
                                //     this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                                // }
}                                catch(error){
                                    console.log('error in visibility---', error);
                                }
                            });
                            //Sanwar Start
                            if(this.selectedRecordId && this.passedScreenName == 'Seller Details'){
                                console.log('At 2104!');
                                this.fieldDetails = this.fieldDetails.map(field => {
                                    return {
                                        ...field,
                                        Is_Disabled__c : false
                                    }
                                })
                            }//Sanwar End

                            

                        }, 1500);
                    }
                    // if (this.customerType != undefined) {
                    //     if (this.customerType == 'Non Individual') {
                    //         setTimeout(() => {
                    //             this.fieldDetails.forEach(item => {
                    //                 if(item.Is_Hidden__c== true){
                    //                     item.hideField = true;
                    //                     // if(this.small== false){
                    //                     setTimeout(() => {
                    //                         this.template.querySelector(`[data-id="${item.Id}"]`).classList.remove('slds-hide');
                    //                     }, 1000)

                    //                 }else{
                    //                     if (item.Applicable_For__c == 'Both' || item.Applicable_For__c == 'Non Individual-Both' || item.Applicable_For__c == undefined || item.Applicable_For__c == (this.customerType + '-' + this.empType)) {
                    //                         item.hideField = false;
                    //                         // if(this.small== false){
                    //                         setTimeout(() => {
                    //                             this.template.querySelector(`[data-id="${item.Id}"]`).classList.remove('slds-hide');
                    //                         }, 1000)

                    //                         // }
                    //                     } else {
                    //                         item.hideField = true;
                    //                         // if(this.small== false){
                    //                         setTimeout(() => {
                    //                             this.template.querySelector(`[data-id="${item.Id}"]`).classList.add('slds-hide');
                    //                         }, 1000)

                    //                         // }
                    //                     }
                    //                 }
                    //             });
                    //         }, 2000);
                    //     } else {
                    //         setTimeout(() => {
                    //             console.log('this.customerType 656=:' + this.customerType);
                    //             console.log('this.fieldDetails---683' + this.fieldDetails);
                    //             this.fieldDetails.forEach(item => {
                    //                 console.log('item.Applicable_For__c=:746' + item.Applicable_For__c);
                    //                 console.log('item.Storage_Field__c=:747' + item.Storage_Field__c);
                    //                 if(item.Is_Hidden__c== true){
                    //                     item.hideField = true;
                    //                     // if(this.small== false){
                    //                     setTimeout(() => {
                    //                         this.template.querySelector(`[data-id="${item.Id}"]`).classList.remove('slds-hide');
                    //                     }, 1000)

                    //                 }else{
                    //                     if (item.Applicable_For__c == 'Both' || item.Applicable_For__c == 'Individual-Both' || item.Applicable_For__c == 'Non Individual-Both' || item.Applicable_For__c == undefined || item.Applicable_For__c == (this.customerType + '-' + this.empType)) {
                    //                         console.log('item.Storage_Field__c=:804' + item.Storage_Field__c);
                    //                         item.hideField = false;

                    //                         // if(this.small== false){
                    //                         setTimeout(() => {
                    //                             this.template.querySelector(`[data-id="${item.Id}"]`).classList.remove('slds-hide');
                    //                         }, 1000)

                    //                         // }
                    //                     } else {
                    //                         item.hideField = true;
                    //                         // if(this.small== false){
                    //                         setTimeout(() => {
                    //                             this.template.querySelector(`[data-id="${item.Id}"]`).classList.remove('slds-hide');
                    //                         }, 1000)
                    //                         // }
                    //                     }
                    //                 }
                    //             });
                    //         }, 2000);
                    //     }
                    // }
                    // this.fieldDetails.forEach(record => {
                    //     if (record.Visibility_Controlled_By__c === currentId && record.Id !== currentId) {
                    //         const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                    //         if (arrDependentControlledValue.includes(currentValue.toLowerCase())) {
                    //             console.log('inside show');
                    //             record.hideField = false;
                    //             setTimeout(() => {
                    //                 this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                    //             }, 1000)
                    //         } else {
                    //             console.log('inside hide');
                    //             record.hideField = true;
                    //             setTimeout(() => {
                    //                 this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                    //             }, 1000)

                    //         }
                    //     }
                    // });
                    // console.log('item.Storage_Field__c=:820' + item.Storage_Field__c);
                    // return ({ isFetchFromReadObject: isFetchFromReadObject });
                    const fieldApiNameToFind = 'Id';
                    const fieldValue = result.find(item => item.fieldApiName === fieldApiNameToFind)?.fieldValue;
                    console.log('field value>',fieldValue);
                    if(this.activeSection.name == 'Builder Details' || this.activeSection.name == 'Seller Details'){
                                    const valueSelectedEvent = new CustomEvent('builderselleradd', {
                                        detail: {
                                            loanId: this.recordId,
                                            screenName: this.activeSection.name,
                                            applicantId: fieldValue
                                        }
                                    });
                                    this.isNewSaved = true;
                                    //this.selectedRecordId = response.loanId;
                                    this.dispatchEvent(valueSelectedEvent);
                                }
                    console.log('Field Value:', fieldValue);

                }).catch(error => {
                    this.showSpinner = false;
                    console.log('Inside error at 982--', error);

                    //     if( error != undefined && error.body != undefined && error.body.message != undefined){
                    //        this.dispatchEvent(
                    //            new ShowToastEvent({
                    //                title: 'Error',
                    //                message: error.body.message,
                    //                variant: 'error',
                    //            }),
                    //        );
                    //    }
                })
            }, 1000);
this.getIndustryOnLoan();
        } catch (error) {
            this.showSpinner = false;
            console.log('error=:860generic' + error);
            console.log('error=:860generic' + JSON.stringify(error));
        }

    }

    getLoanDetailsFromReadObject() {
        getLoanDetailsFromReadObject({
            screenName: this.screenName,
            loanId: this.recordId,
            formIdentifier: this.formIdentifier,
            recordId: this.selectedRecordId
        }).then(result => {
            console.log('detailsWrapperList from getLoanDetailsFromReadObject- 848->' + JSON.stringify(result));

            if (this.fieldDetails) {
                result.forEach(item => {
                    isFetchFromReadObject = false;
                    if (this.screenName == `Confirm Applicant's Basic Details`) {
                        if (item.fieldApiName == 'Is_Current_Address_Same_As_Permanent__c' && (item.fieldValue == 'Yes' || item.fieldValue == Yes)) {
                            console.log('Inside----735' + JSON.stringify(result));
                            this.showPermanentAdr = true;
                        }
                    }

                    this.fieldDetails.forEach(record => {
                        if (record.Read_Field_Name__c == 'Branch_Name__c' && item.fieldApiName == record.Storage_Field__c) {
                            record.savedName = item.fieldValue;
                        } else if (item.fieldApiName == record.Storage_Field__c) {
                            record.value = item.fieldValue;
                        }
                    });
                });

                setTimeout(() => {
                    this.fieldDetails.forEach(record => {
                        if (record.Visibility_Controlled_By__c != null && record.Visibility_Controlled_By__c != '' && record.Visibility_Controlled_By__c != undefined) {
                            const dependentField = this.fieldDetails.find(item => item.Id == record.Visibility_Controlled_By__c);
                            const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                            if (arrDependentControlledValue.find(element => element == dependentField.value.toLowerCase())) {
                                record.hideField = false;
                                setTimeout(() => {
                                    this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                                }, 1000)

                            } else {
                                record.hideField = true;
                                setTimeout(() => {
                                    this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                                }, 1000)
                            }
                        }
                    });
                }, 1000);
            }
        }).catch(error => {
            console.log(error);
        })
    }

    handlePreview(event) {
        const documentId = event.target.dataset.id; // Fetch ContentDocumentId
        if (documentId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'filePreview'
                },
                state: {
                    selectedRecordId: documentId
                }
            });
        } else {
            this.showToast('Error', 'No file available for preview.', 'error');
        }
    }

    // async mapPermanentAddressToCurrentAddress() {
    //     const permanentAddressCmp = this.template.querySelector('c-loan-login-permanent-address-cmp');
    //     if (permanentAddressCmp) {
    //         try {
    //             const permanentAddressData = await permanentAddressCmp.fetchPermanentAddress();
    //             console.log('Fetched Permanent Address:', permanentAddressData);

    //             this.loadLookUps = false; // Initially set to false

    //             this.fieldDetails = this.fieldDetails.map(field => {
    //                 const mappedValue = permanentAddressData[field.Storage_Field__c];
    //                 const lookupName = permanentAddressData[field.Storage_Field__c + '_Name']; // Name

    //                 if (field.is_Lookup__c) {
    //                     console.log('Fetched Permanent Address insidepermanentAddressCmp:', JSON.stringify(permanentAddressData));
    //                     return {
    //                         ...field,
    //                         savedName: lookupName || '', // Display Name for the lookup
    //                         value: mappedValue || '', // Actual lookup ID
    //                     };
    //                 } else {
    //                     return {
    //                         ...field,
    //                         value: mappedValue !== undefined ? mappedValue : field.value,
    //                     };
    //                 }
    //             });

    //             console.log('Updated fieldDetails:', JSON.stringify(this.fieldDetails));

    //             // Introduce a 2-second delay before setting loadLookUps to true
    //             await new Promise(resolve => setTimeout(resolve, 2000));
    //             this.loadLookUps = true;

    //         } catch (error) {
    //             //  console.error('Error fetching permanent address:', error);
    //             this.showErrorMessage('Failed to fetch permanent address. Please try again.');
    //         }
    //     } else {
    //         //  console.error('Permanent Address Component not found.');
    //         this.showErrorMessage('Permanent Address Component not found.');
    //     }
    // }


    @track contentDocIdCurrentAddressProof;
    @track isUploaded = false;
    async handleUploadAddressProof(event) {
        try {
            console.log('recordId ' + this.recordId);
            const uploadedFiles = event.detail.files;
            this.contentDocIdCurrentAddressProof = uploadedFiles[0].documentId;

            // Save the uploaded file
            const result = await saveUploadedAddressProof({
                loanId: this.recordId,
                applicantType: 'Primary Applicant',
                contentDocId: this.contentDocIdCurrentAddressProof
            });

            if (result) {
                this.isUploaded = true;
                //this.mapPermanentAddressToCurrentAddress();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Address proof uploaded and saved successfully.',
                        variant: 'success'
                    })
                );
            }
        } catch (error) {
            //  console.error('Error in handleUploadAddressProof:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to save uploaded address proof. Please try again.',
                    variant: 'error'
                })
            );
        }
    }

    clearCurrentAddressFields() {
        // Identify address-related fields dynamically based on their labels, types, or any identifiable properties
        const addressRelatedKeywords = ['Floor', 'Plot', 'Street', 'Town', 'State', 'Pincode', 'Landmark', 'District', 'Post']; // Common keywords in address fields

        if (!this.fieldDetails || this.fieldDetails.length === 0) {
            //  console.error('fieldDetails is empty or undefined.');
            return;
        }

        // Dynamically clear fields that match the keywords
        this.fieldDetails = this.fieldDetails.map(field => {
            console.log('field.label:: ' + field.label);
            const isAddressField = addressRelatedKeywords.some(keyword =>
                field.label?.toLowerCase().includes(keyword.toLowerCase()) || // Check field label
                field.Storage_Field__c?.toLowerCase().includes(keyword.toLowerCase()) // Check API name
            );

            if (isAddressField) {
                console.log(`Clearing field: ${field.Storage_Field__c || field.label}`);
                return {
                    ...field,
                    value: ''
                }; // Clear the value
            }
            return field; // Retain other fields
        });

        console.log('Updated fieldDetails after clearing dynamic address fields:', JSON.stringify(this.fieldDetails));
    }

    @track createCurrentAddressSameAsPermanentAddress = false;
    handleChildValueChange(event) {
        // Capture the values passed from the child component
        this.showUploadCurrentAddressProofDoc = event.detail.showUploadCurrentAddressProofDoc;
        this.showScreenFieldLoginAppFields = event.detail.showScreenFieldLoginAppFields;
        this.uploadButtonLabel = event.detail.uploadButtonLabel;
        this.createCurrentAddressSameAsPermanentAddress = event.detail.createCurrentAddressSameAsPermanentAddress;

        console.log('Updated showUploadCurrentAddressProofDoc:', this.showUploadCurrentAddressProofDoc);
        console.log('Updated showScreenFieldLoginAppFields:', this.showScreenFieldLoginAppFields);
        console.log('Updated createCurrentAddressSameAsPermanentAddress:', this.createCurrentAddressSameAsPermanentAddress);
    }

    createCurrentAddress() {
        createCurrentAddressRecord({
            loanId: this.recordId,
        }).then(result => {
            console.log('createCurrentAddressRecord-->' + JSON.stringify(result));
        }).catch(error => {
            console.log(error);
        })
    }

    @track showUploadCurrentAddressProofDoc = false;

    handleFocus(event) {
        const target = event.target;
        if (!target.firstChild) {
            target.textContent = "";
        }
        console.log('target.textContent 1' + target.textContent);
        this.lastValue = target.textContent; // Store initial value
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        }));
    }


    handleInputChangeCheckbox(event) {
        event.stopPropagation();
        const currentId = event.target.dataset.id;
        const currentField = event.target.dataset.name;
        const isChecked = event.target.checked;
        console.log('currentId --> ' , currentId);
        console.log('currentField --> ' , currentField);
        console.log('isChecked --> ' , isChecked);

        this.fieldDetails.forEach(record => {
            if (record.Id == currentId && record.Storage_Field__c == currentField) {
                record.value = isChecked;
                console.log('handleInputChange -->' + JSON.stringify(record));
            }
            if (record.Visibility_Controlled_By__c == currentId && record.Id != currentId) {
                console.log('currentValue.toLowerCase() ta 2432-- ', isChecked);

                const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                console.log('arrDependentControlledValue----', arrDependentControlledValue);

                if (arrDependentControlledValue.find(element => element == String(isChecked))) {
                    console.log('inside show');
                    record.hideField = false;
                    console.log('record.Id----', record.Id);

                    setTimeout(() => {
                        const element = this.template.querySelector(`[data-id="${record.Id}"]`);
                        if (element) {
                            setTimeout(() => {
                                element.classList.remove('slds-hide');
                            }, 1000)

                        } else {
                            console.error(`Element with data-id="${record.Id}" not found`);
                        }
                    }, 100);
                } else {
                    console.log('inside hide1 1');
                    // record.value = '';
                    record.hideField = true;
                    setTimeout(() => {
                         const element = this.template.querySelector(`[data-id="${record.Id}"]`);
                        if (element) {
                            setTimeout(() => {
                                element.classList.add('slds-hide');
                            }, 1000)

                        } else {
                            console.error(`Element with data-id="${record.Id}" not found`);
                        }
                        // if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                        //     this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                        // }
                        
                    }, 1000)

                }
            }
        });
    }

    handlebranchlookupselected(event) {
        console.log('event -->' + JSON.stringify(event));
        console.log('event.detail.searchRecord.Branch_Code__c---', event.detail.searchRecord.Branch_Code__c);
        console.log('event.detail.searchRecord.Branch_Type__c---', event.detail.searchRecord.Branch_Type__c);
        console.log('event.detail.searchRecord.Branch_Type__c---', event.detail.searchRecord.Name);
        console.log('event.detail.searchRecord.Branch_Type__c---', event.detail.searchRecord.Id);

        this.selectedBranchId = event.detail.searchRecord.Id;
        this.selectedBankType = event.detail.searchRecord.Branch_Type__c;

        console.log('selectedbanktype----', this.selectedBankType);

        this.fieldDetails.forEach(record => {
            if (record.Storage_Field__c == 'Branch_Master__r.Name') {
                record.savedName = event.detail.searchRecord.Name;
                record.value = event.detail.searchRecord.Id;
            }
            if (this.selectedBankType == 'HUB') {
                console.log('at 1231----', this.selectedBankType, '----');

                if (record.Storage_Field__c == 'Sub_Branch__r.Name') {
                    record.showSubBranchLookup = true;
                    this.sunBranchFilter = '[ParentId = ' + this.selectedBranchId + ';RecordType.Name = Branch;Branch_Type__c=REGIONALOFFICE]';
                    console.log('sunBranchFilter----', this.sunBranchFilter);

                }
            } else {
                if (record.Storage_Field__c == 'Sub_Branch__r.Name') {
                    record.showSubBranchLookup = false;
                    record.value = '';
                    record.savedName = '';
                    console.log('sunBranchFilter----', this.sunBranchFilter);

                }
            }
        });

    }

    handlebranchlookupdeselected(event) {
        this.fieldDetails.forEach(record => {
            if (record.Storage_Field__c == 'Branch_Master__r.Name') {
                record.value = '';
                record.savedName = '';
            }
            // if(this.selectedBankType=='HUB'){
            //     console.log('at 1231----',this.selectedBankType, '----');

            //     console.log('record.Storage_Field__c----', record.Storage_Field__c);

            if (record.Storage_Field__c == 'Sub_Branch__r.Name') {
                record.showSubBranchLookup = false;
                record.value = '';
                record.savedName = '';

            }
            // }

        });
        this.selectedBankType = '';
    }

    handlesubbranchlookupselected(event) {
        console.log('event -->' + JSON.stringify(event));
        console.log('event.detail.searchRecord.Branch_Code__c---', event.detail.searchRecord.Branch_Code__c);
        console.log('event.detail.searchRecord.Branch_Type__c---', event.detail.searchRecord.Branch_Type__c);
        console.log('event.detail.searchRecord.Branch_Type__c---', event.detail.searchRecord.Name);
        console.log('event.detail.searchRecord.Branch_Type__c---', event.detail.searchRecord.Id);

        this.subBranchSelected = event.detail.searchRecord.Name;

        this.fieldDetails.forEach(record => {
            if (record.Storage_Field__c == 'Sub_Branch__r.Name') {
                record.savedName = event.detail.searchRecord.Name;
                record.value = event.detail.searchRecord.Id;
            }
        });

    }

    handlesubbranchlookupdeselected(event) {
        this.fieldDetails.forEach(record => {
            if (record.Storage_Field__c == 'Sub_Branch__r.Name') {
                record.value = '';
                record.savedName = '';
            }
        });
    }

    handleDSTselected(event){
        this.fieldDetails.forEach(record => {
            if (record.Storage_Field__c == 'HL_DST__r.Name') {
                record.savedName = event.detail.searchRecord.Name;
                record.value = event.detail.searchRecord.Id;
            }
        });
    }

    handleDSTdeselected(event){
        this.fieldDetails.forEach(record => {
            if (record.Storage_Field__c == 'HL_DST__r.Name') {
                record.savedName = '';
                record.value = '';
            }
        });
    }

    handleAMselected(event){
        this.fieldDetails.forEach(record => {
            if (record.Storage_Field__c == 'HL_Area_Manager__r.Name') {
                record.savedName = event.detail.searchRecord.Name;
                record.value = event.detail.searchRecord.Id;
            }
        });
    }

    handleAMdeselected(event){
        this.fieldDetails.forEach(record => {
            if (record.Storage_Field__c == 'HL_Area_Manager__r.Name') {
                record.savedName = '';
                record.value = '';
            }
        });
    }

    handleRMselected(event){
        this.fieldDetails.forEach(record => {
            if (record.Storage_Field__c == 'HL_Relationship_Manager__r.Name') {
                record.savedName = event.detail.searchRecord.Name;
                record.value = event.detail.searchRecord.Id;
            }
        });
    }

    handleRMdeselected(event){
        this.fieldDetails.forEach(record => {
            if (record.Storage_Field__c == 'HL_Relationship_Manager__r.Name') {
                record.savedName = '';
                record.value = '';
            }
        });
    }

   handleEmployerlookupselected(event) {
  try {
    // Prefer the flexible fields map; fall back to searchRecord
    const fields = event?.detail?.fields || {};
    const srec   = event?.detail?.searchRecord || {};

    // Debug what's actually present
    console.log('[lookupselected] keys(fields):', Object.keys(fields));
    console.log('[lookupselected] keys(searchRecord):', Object.keys(srec));

    // Safe reads
    const employerId   = fields.Id ?? srec.Id ?? '';
    const employerName = fields.Employer_Name__c ?? srec.Employer_Name__c ?? '';
    const employerCat  = fields.Employer_Catagory__c ?? srec.Employer_Catagory__c ?? '';

    console.log('[lookupselected] employerId:', employerId);
    console.log('[lookupselected] employerName:', employerName);
    console.log('[lookupselected] employerCategory:', employerCat);

    // Update rows immutably so UI refreshes
    let controllerFieldId;
    let updated = this.fieldDetails.map(rec => {
      const r = { ...rec };
      if (r?.Read_Field_Name__c?.startsWith('Employer_Name_') &&
          r?.Storage_Field__c?.startsWith('Employer_Name_')) {
        controllerFieldId = r.Id;
        r.savedName = employerName || '';
        r.value     = employerId   || '';
      }
      return r;
    });

    updated = updated.map(rec => {
      const r = { ...rec };
      if (r?.Field_Label__c === 'Employer Category') {
        //r.savedName = employerCat || '';
        r.value     = employerCat || '';
      }
      return r;
    });

    if (controllerFieldId) {
      const nameLower = (employerName || '').toLowerCase();
      updated = updated.map(rec => {
        const r = { ...rec };
        if (r?.Visibility_Controlled_By__c === controllerFieldId && r?.Id !== controllerFieldId) {
          const raw = r?.Visibility_Controlled_By_Value__c || '';
          const allowed = raw.split(',').map(s => s.trim().toLowerCase()).filter(Boolean);
          r.hideField = !(nameLower && allowed.includes(nameLower));
        }
        return r;
      });
    }

    this.fieldDetails = updated;
  } catch (e) {
    console.error('handleEmployerlookupselected failed:', e);
    throw e; // don’t swallow silently
  }
}


    handleEmployerlookupDeselected(event) {
        try {
            console.log('inside search');
            console.log('event.detail=:' + JSON.stringify(event.detail));
            this.fieldDetails.forEach(record => {
                if (record.Read_Field_Name__c.startsWith('Employer_Name_') && record.Storage_Field__c.startsWith('Employer_Name_')) {
                    record.savedName = '';
                    record.value = '';
                    console.log('record.value: ' + record.value);
                }
            });
        } catch (error) {
            // console.log('error catch =:'+JSON.stringify(error))
        }

    }

    handlepincodelookupselected(event) {
        try {
            console.log('inside search');
            console.log('event.detail=:' + JSON.stringify(event.detail));
            this.fieldDetails.forEach(record => {
                if (record.Read_Field_Name__c.includes('Pincode__') && record.Storage_Field__c.includes('Pincode__')) {
                    console.log('event.detail.searchRecord.Name=:' + event.detail.searchRecord.Name);
                    console.log('event.detail.searchRecord.Id=:' + event.detail.searchRecord.Id);
                    record.savedName = event.detail.searchRecord.Name;
                    record.value = event.detail.searchRecord.Id;
                    console.log('record.value: ' + record.value);
                }
                // else if(record.Read_Field_Name__c == 'Town__c' && record.Storage_Field__c == 'Town__c'){
                //     record.value = event.detail.searchRecord.Town__c;
                // }
                // else if(record.Read_Field_Name__c == 'District__c' && record.Storage_Field__c == 'District__c'){
                //     record.value = event.detail.searchRecord.District__c;
                // }
                // else if(record.Read_Field_Name__c == 'State__c' && record.Storage_Field__c == 'State__c'){
                //     record.value = event.detail.searchRecord.State__c;
                // }
                // else if(record.Read_Field_Name__c == 'Post_Office__c' && record.Storage_Field__c == 'Post_Office__c'){
                //     record.value = event.detail.searchRecord.Post_Office__c;
                // }
            });
        } catch (error) {
            // console.log('error catch =:'+JSON.stringify(error))
        }

    }

    handlepincodelookupdeselected(event) {
        try {
            setTimeout(() => {
                this.fieldDetails.forEach(record => {
                    if (record.Read_Field_Name__c.includes('Pincode__') && record.Storage_Field__c.includes('Pincode__')) {
                       // record.value = '';
                       // record.savedName = '';
                    } else if (record.Read_Field_Name__c == 'Town__c' && record.Storage_Field__c == 'Town__c') {
                        record.value = '';
                    } else if (record.Read_Field_Name__c == 'District__c' && record.Storage_Field__c == 'District__c') {
                        record.value = '';
                    } else if (record.Read_Field_Name__c == 'State__c' && record.Storage_Field__c == 'State__c') {
                        record.value = '';
                    } else if (record.Read_Field_Name__c == 'Post_Office__c' && record.Storage_Field__c == 'Post_Office__c') {
                        record.value = '';
                    }
                });
            }, 100)

        } catch (error) {
            // console.log('error catch =:'+JSON.stringify(error))
        }
    }

    handleRef1PincodeSelected(event){
        console.log('inside search');
            console.log('event.detail=:' + JSON.stringify(event.detail));
            this.fieldDetails.forEach(record => {
                if (record.Read_Field_Name__c.includes('Reference_Details_Pincode_1__') && record.Storage_Field__c.includes('Reference_Details_Pincode_1__')) {
                    console.log('event.detail.searchRecord.Name=:' + event.detail.searchRecord.Name);
                    console.log('event.detail.searchRecord.Id=:' + event.detail.searchRecord.Id);
                    record.savedName = event.detail.searchRecord.Name;
                    record.value = event.detail.searchRecord.Id;
                    console.log('record.value: ' + record.value);
                }
            });
    }

    handleRef1PincodeDeSelected(){
        try {
            setTimeout(() => {
                this.fieldDetails.forEach(record => {
                    if (record.Read_Field_Name__c.includes('Reference_Details_Pincode_1__') && record.Storage_Field__c.includes('Reference_Details_Pincode_1__')) {
                        record.value = '';
                        record.savedName = '';
                    } 
                });
            }, 100)

        } catch (error) {
            // console.log('error catch =:'+JSON.stringify(error))
        }
    }
    handleEmployerPincodeSelected(event){
        console.log('inside search');
            console.log('event.detail=:' + JSON.stringify(event.detail));
            this.fieldDetails.forEach(record => {
                if (record.Read_Field_Name__c.includes('Employer_Pin_Code_') && record.Storage_Field__c.includes('Employer_Pin_Code_')) {
                    console.log('event.detail.searchRecord.Name=:' + event.detail.searchRecord.Name);
                    console.log('event.detail.searchRecord.Id=:' + event.detail.searchRecord.Id);
                    record.savedName = event.detail.searchRecord.Name;
                    record.value = event.detail.searchRecord.Id;
                    console.log('record.value: ' + record.value);
                }
            });
    }
    handleEmployerPincodeDeSelected(){
        try {
            setTimeout(() => {
                this.fieldDetails.forEach(record => {
                    if (record.Read_Field_Name__c.includes('Employer_Pin_Code_') && record.Storage_Field__c.includes('Employer_Pin_Code_')) {
                        record.value = '';
                        record.savedName = '';
                    }
                });
            }, 100)

        } catch (error) {
            // console.log('error catch =:'+JSON.stringify(error))
        }
    }

    handleRef2PincodeSelected(event){
        console.log('inside search');
            console.log('event.detail=:' + JSON.stringify(event.detail));
            this.fieldDetails.forEach(record => {
                if (record.Read_Field_Name__c.includes('Reference_Details_Pincode_2__') && record.Storage_Field__c.includes('Reference_Details_Pincode_2__')) {
                    console.log('event.detail.searchRecord.Name=:' + event.detail.searchRecord.Name);
                    console.log('event.detail.searchRecord.Id=:' + event.detail.searchRecord.Id);
                    record.savedName = event.detail.searchRecord.Name;
                    record.value = event.detail.searchRecord.Id;
                    console.log('record.value: ' + record.value);
                }
            });
    }

    handleRef2PincodeDeSelected(){
        try {
            setTimeout(() => {
                this.fieldDetails.forEach(record => {
                    if (record.Read_Field_Name__c.includes('Reference_Details_Pincode_2__') && record.Storage_Field__c.includes('Reference_Details_Pincode_2__')) {
                        record.value = '';
                        record.savedName = '';
                    }
                });
            }, 100)

        } catch (error) {
            // console.log('error catch =:'+JSON.stringify(error))
        }
    }
    
    @track permanentAddressData = {};
    confirmpermanentfilled(event) {
        this.permanentAddressFilled = true;
        console.log('this.permanentAddressData -->' + JSON.stringify(event.detail));
        this.permanentAddressData = event.detail;
        console.log('this.permanentAddressData -->' + JSON.stringify(this.permanentAddressData));
    }

    showErrorMessage(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error',
            })
        );
    }




    skipAction() {
        this.currentScreenSequence = this.currentScreenSequence + 1;
        if (this.currentScreenSequence < 20) {
            this.getCurrentScreenFieldDetails();
            //this.getCompletionPercent();

            const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
                detail: {
                    loanId: this.recordId,
                    screenName: this.activeSection.name
                }
            });
            this.dispatchEvent(valueSelectedEvent);

            this.getScreenDetailsFromApex();
            //this.getCompletionPercent();
        } else {
            this.currentScreenSequence = this.currentScreenSequence - 1;
        }
    }



    saveAndNext(event) {
        this.currentScreenSequence = this.currentScreenSequence + 1;
        if (this.currentScreenSequence < 20) {
            this.getCurrentScreenFieldDetails();
            //this.getCompletionPercent();

            const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
                detail: {
                    loanId: this.recordId,
                    screenName: this.activeSection.name
                }
            });
            this.dispatchEvent(valueSelectedEvent);

            this.getScreenDetailsFromApex();
            //this.getCompletionPercent();
        } else {
            this.currentScreenSequence = this.currentScreenSequence - 1;
        }

    }
    handleAANext() {
        this.showSpinner = true;
        setTimeout(() => {
            this.showSpinner = false;
        }, 10000);
        this.currentScreenSequence = this.currentScreenSequence + 1;
        this.getCurrentScreenFieldDetails();
    }

    handleBlur(event) {
        event.stopPropagation();
        let itemId = event.target.dataset.id;
        //let newValue = event.target.textContent.trim();
        let newValue = event.target.value;

        //new add
        // Safe handling if the value is completely empty or missing
        if (newValue === undefined || newValue === null) {
            return;
        }
        // new add
        // Clean string strings if handling a text node
        if (typeof newValue === 'string') {
            newValue = newValue.trim();
        }

        // Ensure max length is respected
        let maxLength = event.target.dataset.maxlength;
        if (maxLength && newValue.length > maxLength) {
            newValue = newValue.substring(0, maxLength);
            event.target.textContent = newValue;
        }

            const currentItem = this.items.find(item => item.Id === itemId);
        if (currentItem && currentItem.value === newValue) {
            // Exit early if the value is identical. Prevents unnecessary UI re-rendering!
            return; 
        }

        // Update the list with the new value
        this.items = this.items.map(item => {
            if (item.Id === itemId) {
                return {
                    ...item,
                    value: newValue
                };
            }
            return item;
        });
    }


    lastValue = ""; // Store the last entered value

    handleFocus(event) {
        const target = event.target;
        if (!target.textContent.trim()) {
            target.textContent = ""; // Ensure field starts empty to avoid duplication
        }
        console.log('target.textContent 1' + target.textContent);
        this.lastValue = target.textContent; // Store initial value to compare
    }

    handleFocusOut(event) {
        event.stopPropagation();
        const currentId = event.target.dataset.id;
        const currentField = event.target.dataset.name;
        const currentValue = event.target.value;
        const currentLabel = event.target.label;
        console.log('currentId input change--> ' + currentId);
        console.log('currentField --> ' + currentField);
        console.log('currentValue --> ' + currentValue);
        console.log('currentLabel --> ' + currentLabel);
        this.firstLoad = false;
        if (currentField == 'Requested_Amount__c') {
            console.log('inside Req amount change.. ');
            console.log('currentValue: ' + currentValue);
            const minAmount = this.subProductLimits?.minLoanAmount;
            const maxAmount = this.subProductLimits?.maxLoanAmount;
            // setTimeout(() => {
            if (minAmount !== undefined && maxAmount !== undefined) {
                const numericValue = parseFloat(currentValue);

                if (numericValue < minAmount || numericValue > maxAmount) {
                    console.log('inside Error Scenario');
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: `Requested Amount should be between ${minAmount} and ${maxAmount}`,
                        variant: 'error',
                    }));
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                    return;
                } else {
                    this.fieldDetails.forEach(record => {
                        if (record.Id === currentId && record.Storage_Field__c === currentField) {
                            record.value = currentValue;
                        }
                    });
                }
            } else {
                console.warn('Product limits not loaded yet.');
            }
            // }, 3000);
        } else if (currentField == 'Tenor_Months__c') {
            console.log('inside Req amount change.. ');
            console.log('currentValue: ' + currentValue);
            const minTenure = this.subProductLimits?.minTenure;
            const maxTenure = this.subProductLimits?.maxTenure;
            // setTimeout(() => {
            if (minTenure !== undefined && maxTenure !== undefined) {
                const numericValue = parseFloat(currentValue);

                if (numericValue < minTenure || numericValue > maxTenure) {
                    console.log('inside Error Scenario');
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: `Requested Tenure should be between ${minTenure} and ${maxTenure}`,
                        variant: 'error',
                    }));
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                    return;
                } else {
                    this.fieldDetails.forEach(record => {
                        if (record.Id === currentId && record.Storage_Field__c === currentField) {
                            record.value = currentValue;
                        }
                    });
                }
            } else {
                console.warn('Product limits not loaded yet.');
            }
            // }, 3000);
        }else if (currentField == 'Requested_ROI__c') {
            console.log('inside Req amount change.. ');
            console.log('currentValue: ' + currentValue);
            const minROI = this.subProductLimits?.minROI;
            const maxROI = this.subProductLimits?.maxROI;
            // setTimeout(() => {
            if (minROI !== undefined && maxROI !== undefined) {
                const numericValue = parseFloat(currentValue);

                if (numericValue < minROI || numericValue > maxROI) {
                    console.log('inside Error Scenario');
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: `Requested ROI should be between ${minROI} and ${maxROI}`,
                        variant: 'error',
                    }));
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                    return;
                } else {
                    this.fieldDetails.forEach(record => {
                        if (record.Id === currentId && record.Storage_Field__c === currentField) {
                            record.value = currentValue;
                        }
                    });
                }
            } else {
                console.warn('Product limits not loaded yet.');
            }
            // }, 3000);
        }
    }


    handleInputChange(event) {
        event.stopPropagation();
        const currentId = event.target.dataset.id;
        const currentField = event.target.dataset.name;
        const currentValue = event.target.value;
        const currentLabel = event.target.label;
        console.log('currentId input change2502-->' + currentId);
        console.log('currentField --> ' + currentField);
        console.log('currentValue --> ' + currentValue);
        console.log('currentLabel --> ' + currentLabel);
        console.log('passed screen name>',this.passedScreenName)
        this.firstLoad = false;
        if(currentField == 'Customer_Type__c' && this.passedScreenName == 'Seller Details'){
            
             this.fieldDetails.forEach(field => {
                console.log('ield.Applicant_Type_Visibility__c', field.Applicant_Type_Visibility__c);
            
                    console.log('ield.Applicant_Type_Visibility__c', field.Applicable_For__c);
                    if (field.Applicable_For__c == currentValue) {
                        field.hideField = false;
                        setTimeout(() => {
                            if(this.template.querySelector(`[data-id="${field.Id}"]`)){
                            this.template.querySelector(`[data-id="${field.Id}"]`).classList.remove('slds-hide');
                            }                            
                        }, 500)
                    } else if(field.Applicable_For__c != 'Both'){
                        field.Is_Mandatory__c =false;
                        setTimeout(() => {
                            if(this.template.querySelector(`[data-id="${field.Id}"]`)){
                            this.template.querySelector(`[data-id="${field.Id}"]`).classList.add('slds-hide');
                            }                            
                        }, 500)
                    }
                
            });
        }
        //change by Vedant for SFHL-1564 - start
        if (currentField === 'Disability__c') {
            console.log('Disability changed -->', currentValue);
            this.fieldDetails.forEach(record => {
                if (record.Storage_Field__c === 'Disability__c') {
                    record.value = currentValue;
                }

            });
            this.handleDisabilityDependency(currentValue);
        }
        //change by Vedant for SFHL-1564 - end
  if (currentField == 'DOB__c') {
            var regexVar = /^([0-9]{2})\/([0-9]{2})\/([0-9]{4})$/;
            var regexDDMMMYYYY = /^(\d{2})-([A-Za-z]{3})-(\d{4})$/;
            if (currentValue != null) {
                let currentDate = new Date().toJSON().slice(0, 10)
                var userBirthDate = new Date(currentValue.replace(regexVar, "$3-$2-$1"));
                var todayYear = (new Date()).getFullYear(); // Always use FullYear!!
                var cutOff19 = new Date(); // should be a Date
                cutOff19.setFullYear(todayYear - 18); // ...  
                console.log('todayDate----', new Date());
                console.log('this.dateofBirth----', currentValue);
                if (currentValue >= currentDate) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Date of birth cannot be future/current date',
                        variant: 'Error',
                    }));
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
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
                }
                // else if (this.applicantDob && currentValue > this.applicantDob) {
                //          console.log('31873--');
                //         this.dispatchEvent(new ShowToastEvent({
                //             title: 'Error',
                //             message: 'Date of Birth cannot be after Date of Joining.',
                //             variant: 'Error',
                //         }));
                //         this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                //         return;
                // }
                 else {
                    this.fieldDetails.forEach(record => {
                        if (record.Id == currentId && record.Storage_Field__c == currentField) {
                            record.value = currentValue;
                            // console.log('handleInputChange -->'+JSON.stringify(record));
                        }
                    });
                }
            }
            else {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill Date of Birth in the correct format.',
                    variant: 'Error',
                }))
                this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                return;
            }
        }else if (currentField == 'Date_of_Joining__c') {
                var regexVar = /^([0-9]{2})\/([0-9]{2})\/([0-9]{4})$/;
                var regexDDMMMYYYY = /^(\d{2})-([A-Za-z]{3})-(\d{4})$/;
                if (currentValue != null) {
                    let currentDate = new Date().toJSON().slice(0, 10);

                    // Applicant DOI (assuming in same DD/MM/YYYY format)
                    if (currentValue >= currentDate) {
                        console.log('3187--');
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: 'Date of Joining cannot be future/current date',
                            variant: 'Error',
                        }));
                        this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                        return;
                    }

                    // Validate 2: Date of Joining should not be greater than Applicant DOI
                    if (this.applicantDob && currentValue < this.applicantDob) {
                         console.log('31873--');
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: 'Date of Joining cannot be before Date of Birth.',
                            variant: 'Error',
                        }));
                        this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                        return;
                    }

                    // If all validations pass, update record value
                    this.fieldDetails.forEach(record => {
                        if (record.Id == currentId && record.Storage_Field__c == currentField) {
                            record.value = currentValue;
                        }
                    });
                }
                else {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Please fill Date of Joining in the correct format.',
                        variant: 'Error',
                    }));
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                    return;
                }
            }
            else if (currentField == 'Business_Commencement_Date__c') {
                var regexVar = /^([0-9]{2})\/([0-9]{2})\/([0-9]{4})$/;
                var regexDDMMMYYYY = /^(\d{2})-([A-Za-z]{3})-(\d{4})$/;
                if (currentValue != null) {
                    let currentDate = new Date().toJSON().slice(0, 10);
                    const compareDoiDate = this.dateofIncorporation ? this.dateofIncorporation : this.applicantDoi;

                    // Applicant DOI (assuming in same DD/MM/YYYY format)
                    if (currentValue >= currentDate) {
                        console.log('3187--');
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: 'Business Commencement Date cannot be future/current date',
                            variant: 'Error',
                        }));
                        this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                        return;
                    }
                    // Validate 2: Date of Joining should not be greater than Applicant DOI
                    if (compareDoiDate && currentValue < compareDoiDate) {
                         console.log('31873--');
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            message: 'Business Commencement Date cannot be before Date of Incorporation.',
                            variant: 'Error',
                        }));
                        this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                        return;
                    }
                      this.bussinessComendate = currentValue;

                    // If all validations pass, update record value
                    this.fieldDetails.forEach(record => {
                        if (record.Id == currentId && record.Storage_Field__c == currentField) {
                            record.value = currentValue;
                        }
                    });
                }
                else {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Please fill Date of Joining in the correct format.',
                        variant: 'Error',
                    }));
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                    return;
                }
            }


        // else if(currentField == 'PSL__c'){
        //     this.fieldDetails.forEach(field => {
        //         console.log('ield.Applicant_Type_Visibility__c', field.Applicant_Type_Visibility__c);
        //           //  field.value = currentValue;
        //           if (field.Id == currentId && field.Storage_Field__c == currentField) {
        //                     field.value = currentValue;
        //                     // console.log('handleInputChange -->'+JSON.stringify(record));
        //                 }
        //             console.log('ield.Applicant_Type_Visibility__c', field.Applicable_For__c);
        //             if (currentValue == 'No' && (field.Field_Label__c == 'Udyam Registration Number' || field.Field_Label__c == 'MSME Category')) {
        //                 field.hideField = false;
        //                 setTimeout(() => {
        //                     if(this.template.querySelector(`[data-id="${field.Id}"]`)){
        //                     this.template.querySelector(`[data-id="${field.Id}"]`).classList.add('slds-hide');
        //                     }                            
        //                 }, 500)
        //             } else if(currentValue == 'Yes' && (field.Field_Label__c == 'Udyam Registration Number' || field.Field_Label__c == 'MSME Category')){
        //                 setTimeout(() => {
        //                     if(this.template.querySelector(`[data-id="${field.Id}"]`)){
        //                     this.template.querySelector(`[data-id="${field.Id}"]`).classList.remove('slds-hide');
        //                     }                            
        //                 }, 500)
        //             }
                
        //     });
        // }
        else if (currentField == 'Certificate_Issue_Date__c') {
            var regexVar = /^([0-9]{2})\/([0-9]{2})\/([0-9]{4})$/;
            var regexDDMMMYYYY = /^(\d{2})-([A-Za-z]{3})-(\d{4})$/;
            if (currentValue != null) {
                let currentDate = new Date().toJSON().slice(0, 10)
                var userBirthDate = new Date(currentValue.replace(regexVar, "$3-$2-$1"));
                var todayYear = (new Date()).getFullYear(); // Always use FullYear!!
                var cutOff19 = new Date(); // should be a Date
                cutOff19.setFullYear(todayYear - 18); // ...  
                if (currentValue >= currentDate) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Certificate Issue Date cannot be future/current date',
                        variant: 'Error',
                    }));
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                    return;
                } else {
                    this.fieldDetails.forEach(record => {
                        if (record.Id == currentId && record.Storage_Field__c == currentField) {
                            record.value = currentValue;
                            this.certIssueDate = currentValue;
                            // console.log('handleInputChange -->'+JSON.stringify(record));
                        }
                    });
                }
            }
            else {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill Certificate Issue Date in the correct format.',
                    variant: 'Error',
                }))
                this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                return;
            }
        }
            else if (currentField === 'Certificate_Expiry_Date__c') {
            if (this.certIssueDate == '' || this.certIssueDate == null || this.certIssueDate == undefined) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill Certificate Issue Date before.',
                    variant: 'error', // lowercase 'error'
                }));
                // Clear the invalid input field
                const inputElement = this.template.querySelector(`[data-id="${currentId}"]`);
                if (inputElement) {
                    inputElement.value = '';
                }
                return;
            }
            if (this.certIssueDate && currentValue <= this.certIssueDate) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Expiry Date must be after Certificate Issue Date.',
                    variant: 'error', // lowercase 'error'
                }));
                // Clear the invalid input field
                const inputElement = this.template.querySelector(`[data-id="${currentId}"]`);
                if (inputElement) {
                    inputElement.value = '';
                }
                return;
            }
            else {
                this.fieldDetails.forEach(record => {
                        if (record.Id == currentId && record.Storage_Field__c == currentField) {
                            record.value = currentValue;
                            // console.log('handleInputChange -->'+JSON.stringify(record));
                        }
                    });
                }
            }
            else if (currentField === 'Employee_ID__c') {
                     const val = (currentValue || '').trim();
                    const ok = /^[A-Za-z0-9]+$/.test(val);

                    if (val && !ok) {
                        event.target.setCustomValidity('Employee ID can contain only letters and numbers.');
                        event.target.reportValidity();
                        return;
                    }

                    event.target.setCustomValidity('');
                    this.fieldDetails.forEach(r => {
                        if (r.Id === currentId && r.Storage_Field__c === currentField) {
                        r.value = val;
                        }
                    });
                    return;
                }
                else if (currentField === 'BSR_Code__c') {
                    console.log('text validation output--',numberValidation(currentValue));
                     if(numberValidation(currentValue)){ 
                         console.log('Inside BSR code--',currentValue);
                         this.dispatchEvent(
                             new ShowToastEvent({
                                 title: 'Error',
                                message: 'Please enter BSR code in correct format',
                                 variant: 'error',
                             }),
                         );
                         if (this.template.querySelector(`[data-id="${currentId}"]`).value != undefined) {
                             this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                        }
                        else {
                             this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                        }
                        
                        return;
                    }
                    this.fieldDetails.forEach(record => {
                        if (record.Id == currentId && record.Storage_Field__c == currentField) {
                            record.value = currentValue;
                            // console.log('handleInputChange -->'+JSON.stringify(record));
                        }
                    });
            }
            else if (currentField === 'Industry_Code__c') {
                     const val = (currentValue || '').trim();
                    const ok = /^[A-Za-z0-9]+$/.test(val);

                    if (val && !ok) {
                        event.target.setCustomValidity('Industry Code can contain only letters and numbers.');
                    event.target.reportValidity();
                    return;
                }

                event.target.setCustomValidity('');
                this.fieldDetails.forEach(r => {
                    if (r.Id === currentId && r.Storage_Field__c === currentField) {
                    r.value = val;
                    }
                    });
                    return;
                }
            else if(currentField === 'Monthly_Salary__c' && currentValue == 0 ){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Monthly Salary cannot be 0.Please enter an amount greater than 0',
                        variant: 'error',
                    }),
                );
                this.fieldDetails.forEach(record => {
                    if ( record.Storage_Field__c == currentField) {
                        console.log('inside monthly salary 0 value Kshitiz--');
                        record.value = '';
                        // console.log('handleInputChange -->'+JSON.stringify(record));
                    }
                });
                 this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                }
            else if (currentField === 'Share_Holding_Percentage__c') {
            const raw = (currentValue ?? '').trim();

            if (raw === '') {
                event.target.setCustomValidity('');
                this.fieldDetails.forEach(r => {
                if (r.Id === currentId && r.Storage_Field__c === currentField) r.value = raw;
                });
                return;
            }

            const num = Number(raw);

            if (Number.isNaN(num) || !isFinite(num)) {
                event.target.setCustomValidity('Enter a number between 0 and 100.');
                event.target.reportValidity();
                return;
            }

            if (num < 0 || num > 100) {
                event.target.setCustomValidity('Must be between 0 and 100.');
                event.target.reportValidity();
                return;
            }

            event.target.setCustomValidity('');
            this.fieldDetails.forEach(r => {
                if (r.Id === currentId && r.Storage_Field__c === currentField) r.value = raw;
                });
                return;
            }
            
          else if (currentField == 'Reference_Name_1__c' || currentField == 'Reference_Last_Name_1__c' || currentField == 'Reference_Name_2__c' || currentField == 'Reference_Last_Name_2__c') {
            if (!textValidation(currentValue)) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter ' + currentLabel + ' in correct format',
                        variant: 'error',
                    }),
                );
                if (this.template.querySelector(`[data-id="${currentId}"]`).value != undefined) {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                }
                else {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                }
                return;
            } else {
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
            }
        } else if (currentField == 'Total_Work_Experience_Years__c' || currentField == 'Current_Work_Experience_Years__c') {
            console.log('Inside mobile number--', currentValue);
            const decimalRegex = /^\d*\.?\d*$/;
            if (!decimalRegex.test(currentValue)) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter ' + currentLabel + ' in correct format',
                        variant: 'error',
                    }),
                );
                if (this.template.querySelector(`[data-id="${currentId}"]`).value != undefined) {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                }
                else {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                }
                return;
            } else {
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
            }
            
        } else if (currentField == 'Floor_Number__c') {
            console.log('Inside mobile number--', currentValue);
            if (textValidation(currentValue)) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter floor number in correct format',
                        variant: 'error',
                    }),
                );
                if (this.template.querySelector(`[data-id="${currentId}"]`).value != undefined) {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                }
                else {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                }
                return;
            } else if (!isValidMobileNumber(currentValue)) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter floor number in correct format',
                        variant: 'error',
                    }),
                );
                if (this.template.querySelector(`[data-id="${currentId}"]`).value != undefined) {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                }
                else {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                }
                return;
            } else {
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
            }
            
        } 
        else if (currentField == 'GST_Exempt__c') {
            console.log('Inside GST_Exempt__c--', currentValue);
            this.fieldDetails.forEach(field => {
                if (field.Field_Label__c == 'GSTIN') {
                    if (currentValue == 'No') {
                        console.log('Inside No Kshitiz--');
                        field.Is_Mandatory__c = true;
                        
                    } else if (currentValue == 'Yes') {
                        console.log('Inside Yes Kshitiz--');
                        field.Is_Mandatory__c = false;
                        
                    }
                }
                if (field.Id == currentId && field.Storage_Field__c == currentField) {
                            field.value = currentValue;
                            console.log('GST Exempt value>'+field.value);
                }
            });
        } 
        else if (currentField == 'Mobile_Number__c' || currentField == 'Reference_Phone_1__c' || currentField == 'Reference_Phone_2__c' || currentField == 'Employer_Phone_Number__c') {
            console.log('Inside mobile number--', currentValue);
            if (textValidation(currentValue)) {
                console.log('Inside textValidation Kshitiz val 1--');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter mobile number in correct format',
                        variant: 'error',
                    }),
                );
                if (this.template.querySelector(`[data-id="${currentId}"]`).value != undefined) {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                }
                else {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                }
                return;
            }
            
            else if (!isValidMobileNumber(currentValue)) {
                  console.log('Inside textValidation Kshitiz val 2--');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter mobile number in correct format',
                        variant: 'error',
                    }),
                );
                if (this.template.querySelector(`[data-id="${currentId}"]`).value != undefined) {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                }
                else {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                }
                return;
            }
            if (currentValue.length == 10 && !mobileNumberValidation(currentValue)) {
                  console.log('Inside textValidation Kshitiz val 3--');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter mobile number in correct format',
                        variant: 'error',
                    }),
                );
                return;
            }
            if (currentValue.length > 10) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Mobile number should not be more than 10 digits',
                        variant: 'error',
                    }),
                );
                return;
            }
            if(this.mobileNumber == currentValue && currentField == 'Employer_Phone_Number__c'){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'Employer Phone Number cannot be same as Applicant Mobile Number',
                                variant: 'error',
                            }),
                        );
                        this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                        return;
                    }
            else {
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
            }
        }
        else if(currentField == 'Shareholder_Partner_Name__c') {
            console.log('Inside Shareholder/Partner Name--', currentValue);
            console.log('before Shareholder/Partner --',  numberValidation(currentValue));
            if ( !numberValidation(currentValue)) {
                console.log('Inside textValidation Kshitiz dadhich val 1--');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter Shareholder/Partner Name in correct format',
                        variant: 'error',
                    }),
                );
                if (this.template.querySelector(`[data-id="${currentId}"]`).value != undefined) {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                }
                else {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                }
                return;
            }
        }
        else if (currentField == 'Salutation__c') {
            let genderField = this.fieldDetails.find(record => record.Storage_Field__c == 'Gender__c');

            if (genderField != undefined && genderField != null && genderField != '') {
                let genderValue = genderField.value;
                console.log('Selected Salutation:', currentValue);
                console.log('Detected Gender:', genderValue);

                if (genderValue != undefined && genderValue != null && genderValue != '' && genderValue != 'Transgender') {
                    const validCombinations = {
                        'Mr.': 'Male',
                        'Ms.': 'Female',
                        'Mrs.': 'Female',
                        // 'Dr.': ['Male', 'Female'], 
                        'Miss': 'Female',
                        // 'CA': ['Male', 'Female'],
                    };

                    if (validCombinations[currentValue] && !validCombinations[currentValue].includes(genderValue)) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: `Invalid combination: ${currentValue} cannot be used for ${genderValue}.`,
                                variant: 'error',
                            })
                        );
                        this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                        return;
                    }
                    else {
                        this.fieldDetails.forEach(record => {
                            if (record.Id == currentId && record.Storage_Field__c == currentField) {
                                record.value = currentValue;
                                console.log('handleInputChange -->' + JSON.stringify(record));
                            }
                        });
                    }
                }
                else {
                    this.fieldDetails.forEach(record => {
                        if (record.Id == currentId && record.Storage_Field__c == currentField) {
                            record.value = currentValue;
                            console.log('handleInputChange -->' + JSON.stringify(record));
                        }
                    });
                }

            } else {
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
            }
        } else if (currentField == 'Gender__c') {
            let salutationField = this.fieldDetails.find(record => record.Storage_Field__c == 'Salutation__c');

            if (salutationField != undefined && salutationField != null && salutationField != '') {
                let salutationValue = salutationField.value;
                console.log('Selected Salutation:', currentValue);
                console.log('Detected Gender:', salutationValue);

                if (salutationValue != null && salutationValue != undefined && salutationValue != '' && currentValue != 'Transgender') {
                    const validCombinations = {
                        'Mr.': 'Male',
                        'Ms.': 'Female',
                        'Mrs.': 'Female',
                        // 'Dr.': ['Male', 'Female'],
                        'Miss': 'Female',
                        // 'CA': ['Male', 'Female'],
                    };

                    if (validCombinations[salutationValue] && validCombinations[salutationValue] !== currentValue) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: `Invalid combination: ${currentValue} cannot be used for ${salutationValue}.`,
                                variant: 'error',
                            })
                        );
                        this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                        return;
                    }
                    else {
                        this.fieldDetails.forEach(record => {
                            if (record.Id == currentId && record.Storage_Field__c == currentField) {
                                record.value = currentValue;
                                console.log('handleInputChange -->' + JSON.stringify(record));
                            }
                        });
                    }
                }
                else {
                    this.fieldDetails.forEach(record => {
                        if (record.Id == currentId && record.Storage_Field__c == currentField) {
                            record.value = currentValue;
                            console.log('handleInputChange -->' + JSON.stringify(record));
                        }
                    });
                }

            } else {
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
            }
        }

        // else if (currentField == 'Email__c' || currentField== 'Alternate_Email__c') {
        //     console.log('Inside Alternate_Email__c--', currentValue);
        //     if(!emailValidation(currentValue)){
        //         this.dispatchEvent(
        //             new ShowToastEvent({
        //                 title: 'Error',
        //                 message: 'Please enter email in correct format',
        //                 variant: 'error',
        //             }),
        //         );
        //         // if(this.template.querySelector(`[data-id="${currentId}"]`).value != undefined){
        //         //     this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
        //         // }
        //         // else{
        //         //     this.template.querySelector(`[data-id="${currentId}"]`).value='';
        //         // }
        //         return;
        //     }
        //     else {
        //         this.fieldDetails.forEach(record => {
        //             if (record.Id == currentId && record.Storage_Field__c == currentField) {
        //                 record.value = currentValue;
        //                 console.log('handleInputChange -->' + JSON.stringify(record));
        //             }
        //         });
        //     }
        // }else if (currentField == 'Name_of_Organization__c' || currentField == 'Father_s_First_Name__c' || currentField == 'Father_s_Middle_Name__c'
        //     || currentField == 'Father_s_Last_Name__c' || currentField == 'Mother_s_First_Name__c' || currentField == 'Mother_s_Middle_Name__c'
        //     || currentField == 'Mother_s_Last_Name__c' || currentField == 'Spouse_First_Name__c' || currentField == 'Spouse_Middle_Name__c'
        //     || currentField == 'Spouse_Last_Name__c' || currentField == 'First_Name__c' || currentField == 'Last_Name__c' || currentField == 'Middle_Name__c'
        //     || currentField == 'Registration_Number__c' || currentField == 'Udhyam_Registration_No__c' 
        // ) {
        //     console.log('Inside Name_of_Organization__c--', currentValue);
        //     if(charLength(currentValue) < 2){
        //         this.dispatchEvent(
        //             new ShowToastEvent({
        //                 title: 'Error',
        //                 message: currentLabel+ ' can not have less than 2 characters',
        //                 variant: 'error',
        //             }),
        //         );
        //         return;
        //     }
        //     else {
        //         this.fieldDetails.forEach(record => {
        //             if (record.Id == currentId && record.Storage_Field__c == currentField) {
        //                 record.value = currentValue;
        //                 console.log('handleInputChange -->' + JSON.stringify(record));
        //             }
        //         });
        //     }
        // }else if (currentField == 'GSTIN__c' ) {
        //     console.log('Inside GSTIN__c-', currentValue);
        //     if(!gstNumberValidation(currentValue)){
        //         this.dispatchEvent(
        //             new ShowToastEvent({
        //                 title: 'Error',
        //                 message: 'Please enter GST number in correct format',
        //                 variant: 'error',
        //             }),
        //         );
        //         return;
        //     }
        //     else {
        //         this.fieldDetails.forEach(record => {
        //             if (record.Id == currentId && record.Storage_Field__c == currentField) {
        //                 record.value = currentValue;
        //                 console.log('handleInputChange -->' + JSON.stringify(record));
        //             }
        //         });
        //     }
        // }
        else if (currentField == 'DOI__c') {
            var regexVar = /^([0-9]{2})\/([0-9]{2})\/([0-9]{4})$/;

            let currentDate = new Date().toJSON().slice(0, 10);
            console.log('todayDate----', new Date());
            console.log('this.dateofBirth----', currentValue);
            const compareDate = this.bussinessComendate ? this.bussinessComendate : this.applicantbusinessComenDate;

            if (currentValue >= currentDate) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Date of incorporation cannot be future/current date',
                    variant: 'Error',
                }));
                this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                return;
            }else if (compareDate && currentValue > compareDate) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Date of incorporation cannot be after Business Commencement Date',
                    variant: 'Error',
                }));
                this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                return;
            } else {
                 this.dateofIncorporation = currentValue;
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        // console.log('handleInputChange -->'+JSON.stringify(record));
                    }
                });
            }
            // } else if (currentField == 'Requested_Amount__c'){
            //     console.log('inside Req amount change.. ');
            //     console.log('currentValue: '+currentValue);
            //     const minAmount = this.subProductLimits?.minLoanAmount;
            //     const maxAmount = this.subProductLimits?.maxLoanAmount;
            //     setTimeout(() => {
            //         if (minAmount !== undefined && maxAmount !== undefined) {
            //             const numericValue = parseFloat(currentValue);

            //             if (numericValue < minAmount || numericValue > maxAmount) {
            //                 console.log('inside Error Scenario');
            //                 this.dispatchEvent(new ShowToastEvent({
            //                     title: 'Error',
            //                     message: `Requested Amount should be between ${minAmount} and ${maxAmount}`,
            //                     variant: 'error',
            //                 }));
            //                 this.template.querySelector(`[data-id="${currentId}"]`).value = '';
            //                 return;
            //             } else {
            //                 this.fieldDetails.forEach(record => {
            //                     if (record.Id === currentId && record.Storage_Field__c === currentField) {
            //                         record.value = currentValue;
            //                     }
            //                 });
            //             }      
            //         } else {
            //             console.warn('Product limits not loaded yet.');
            //         }
            //     }, 3000);
            // } else if (currentField == 'Tenor_Months__c'){
            //     console.log('inside Req amount change.. ');
            //     console.log('currentValue: '+currentValue);
            //     const minTenure = this.subProductLimits?.minTenure;
            //     const maxTenure = this.subProductLimits?.maxTenure;
            //     setTimeout(() => {
            //         if (minTenure !== undefined && maxTenure !== undefined) {
            //             const numericValue = parseFloat(currentValue);

            //             if (numericValue < minTenure || numericValue > maxTenure) {
            //                 console.log('inside Error Scenario');
            //                 this.dispatchEvent(new ShowToastEvent({
            //                     title: 'Error',
            //                     message: `Requested Tenure should be between ${minTenure} and ${maxTenure}`,
            //                     variant: 'error',
            //                 }));
            //                 this.template.querySelector(`[data-id="${currentId}"]`).value = '';
            //                 return;
            //             } else {
            //                 this.fieldDetails.forEach(record => {
            //                     if (record.Id === currentId && record.Storage_Field__c === currentField) {
            //                         record.value = currentValue;
            //                     }
            //                 });
            //             }      
            //         } else {
            //             console.warn('Product limits not loaded yet.');
            //         }
            //     }, 3000);
        } else if (currentField == 'Sector__c') {
            console.log('this.appval', JSON.stringify(this.appval));
            this.currentApplicantType = this.appval[0].applicantType;
            this.customerType = this.appval[0].customerType;
            if(this.customerType == 'Non Individual'){
                console.log('3033',JSON.stringify(this.fieldDetails));
                /* this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                }); */
                this.fieldDetails.forEach(record => {
                    if (record.Visibility_Controlled_By__c == currentId && record.Id != currentId) {
                        console.log('currentValue.toLowerCase() ta 2432-- ', currentValue.toLowerCase());
    
                        const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                        console.log('arrDependentControlledValue----', arrDependentControlledValue);
    
                        if (arrDependentControlledValue.find(element => element == currentValue.toLowerCase())) {
                            console.log('inside show');
                            record.hideField = false;
                            console.log('record.Id----', record.Id);
    
                            setTimeout(() => {
                                const element = this.template.querySelector(`[data-id="${record.Id}"]`);
                                if (element) {
                                    setTimeout(() => {
                                        element.classList.remove('slds-hide');
                                    }, 1000)
    
                                } else {
                                    console.error(`Element with data-id="${record.Id}" not found`);
                                }
                            }, 100);
                            // this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                        } else {
                            console.log('inside hide1');
                            // record.value = '';
                            record.hideField = true;
                            setTimeout(() => {
                                if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                                    this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                                }
                                
                            }, 1000)
    
                        }
                    }
                    if (record.Is_Controlling_Picklist__c) {
                        getFieldDependencies({
                            objectName: record.Storage_Object__c,
                            controllingField: record.Storage_Field__c,
                            dependentField: record.Dependent_Picklist__c
                        }).then(result => {
                            console.log('Dependent picklist values: in connected callbackkk---record.Dependent_Picklist__c KD0', record.value, '--', JSON.stringify(result), '= ', record.Dependent_Picklist__c);
                            const dependentPicklistOptions = result[record.value];
                            console.log('dependentPicklistOptions----', dependentPicklistOptions);

                            // const targetField = this.fieldDetails.find(item => item.Storage_Field__c === record.Dependent_Picklist__c);

                            const targetField = this.fieldDetails.find(item => {
                                const isStorageFieldMatch = item.Storage_Field__c === record.Dependent_Picklist__c;

                                console.log('this.customerType----', this.customerType);

                                if (this.customerType != undefined && (item.Applicable_For__c == 'Both' || item.Applicable_For__c == 'Individual-Both' || item.Applicable_For__c == 'Non Individual-Both' || item.Applicable_For__c == (this.customerType + '-' + this.empType))) {
                                    return isStorageFieldMatch;
                                }
                                else if (item.Applicable_For__c == this.customerType) {
                                    return isStorageFieldMatch;
                                }
                            });


                            if (targetField) {
                                console.log('Inside target field---', targetField.Id);
                                if(this.isHLUser && targetField.Storage_Field__c=='Customer_Profile__c'){
                                    dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Others');
                                }else if(!this.isHLUser && targetField.Storage_Field__c=='Customer_Profile__c'){
                                    dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Non Working');
                                }
                                this.template.querySelector(`[data-id="${targetField.Id}"]`).options = dependentPicklistOptions;
                            }
                        }).catch(error => {
                            if (error != undefined && error.body != undefined && error.body.message != undefined) {
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: error.body.message,
                                        variant: 'error',
                                    }),
                                );
                            }
                        });
                    }
                });
              /*  if(currentValue=='HUF'){ 
                    const labelsToRemove = [
                    'PSL',
                    'Registration Number(CIN)',
                    'Segment',
                    'Sub segment'
                ];
                  this.removedFields = this.fieldDetails.filter(
                    field => labelsToRemove.includes(field.Field_Label__c)
                );

                this.fieldDetails = this.fieldDetails.filter(
                    field => !labelsToRemove.includes(field.Field_Label__c)
                );
                }
                if(currentValue == 'Private Limited'){
                    const labelsToRemove = [
                    'Segment',
                    'Sub segment'
                ]
                  this.removedFields = this.fieldDetails.filter(
                    field => labelsToRemove.includes(field.Field_Label__c)
                );

                this.fieldDetails = this.fieldDetails.filter(
                    field => !labelsToRemove.includes(field.Field_Label__c)
                );
                }
                if(currentValue == 'LLP'){
                    const labelsToRemove = [
                    'PSL',
                    'Registration Number(CIN)',
                    'Segment',
                    'Sub segment'
                ]
                  this.removedFields = this.fieldDetails.filter(
                    field => labelsToRemove.includes(field.Field_Label__c)
                );

                this.fieldDetails = this.fieldDetails.filter(
                    field => !labelsToRemove.includes(field.Field_Label__c)
                );
                }
                 if(currentValue == 'Partnership'){
                    const labelsToRemove = [
                    'PSL',
                    'Registration Number(CIN)',
                    'Segment',
                    'Sub segment'
                ]
                  this.removedFields = this.fieldDetails.filter(
                    field => labelsToRemove.includes(field.Field_Label__c)
                );

                this.fieldDetails = this.fieldDetails.filter(
                    field => !labelsToRemove.includes(field.Field_Label__c)
                );
                }
                 if(currentValue == 'Proprietorship'){
                    const labelsToRemove = [
                    'PSL',
                    'Registration Number(CIN)',
                    'Segment',
                    'Sub segment'
                ]
                  this.removedFields = this.fieldDetails.filter(
                    field => labelsToRemove.includes(field.Field_Label__c)
                );

                this.fieldDetails = this.fieldDetails.filter(
                    field => !labelsToRemove.includes(field.Field_Label__c)
                );
                } */

              



            }





            this.fieldDetails.forEach(field => {
                console.log('ield.Applicant_Type_Visibility__c', field.Applicant_Type_Visibility__c);
                if (field.Applicant_Type_Visibility__c) {
                    console.log('ield.Applicant_Type_Visibility__c', field.Applicant_Type_Visibility__c);
                    if (field.Applicant_Type_Visibility__c == this.currentApplicantType && field.Applicable_For__c == this.customerType) {
                        field.hideField = false;
                        setTimeout(() => {
                            if(this.template.querySelector(`[data-id="${field.Id}"]`)){
                            this.template.querySelector(`[data-id="${field.Id}"]`).classList.remove('slds-hide');
                            }                            
                        }, 500)
                    } else {
                        setTimeout(() => {
                            if(this.template.querySelector(`[data-id="${field.Id}"]`)){
                            this.template.querySelector(`[data-id="${field.Id}"]`).classList.add('slds-hide');
                            }                            
                        }, 500)
                    }
                }
            });
            this.fieldDetails.forEach(record => {
                if (record.Id == currentId && record.Storage_Field__c == currentField) {
                    record.value = currentValue;
                    console.log('handleInputChange -->' + JSON.stringify(record));
                }
            });
            const currentFieldDetails = this.fieldDetails.find(item => item.Storage_Field__c == currentField);
            if (currentFieldDetails.Is_Controlling_Picklist__c) {
                console.log('currentFieldDetails.Storage_Object__c 1827---', currentFieldDetails.Storage_Object__c);
                console.log('currentFieldDetails.Storage_Field__c 1828---', currentFieldDetails.Storage_Field__c);
                console.log('currentFieldDetails.Dependent_Picklist__c 1829---', currentFieldDetails.Dependent_Picklist__c);
                getFieldDependencies({
                    objectName: currentFieldDetails.Storage_Object__c,
                    controllingField: currentFieldDetails.Storage_Field__c,
                    dependentField: currentFieldDetails.Dependent_Picklist__c
                }).then(result => {
                    console.log('dependent picklist values List=:' + JSON.stringify(result));
                    const dependentPicklistOptions = result[currentValue];
                    // const targetId = this.fieldDetails.find(item => item.Storage_Field__c == currentFieldDetails.Dependent_Picklist__c);
                    // console.log('target id000000', targetId.Id);

                    // this.template.querySelector(`[data-id="${targetId.Id}"]`).options = dependentPicklistOptions;
                    const matchingFields = this.fieldDetails.filter(item =>
                        item.Storage_Field__c === currentFieldDetails.Dependent_Picklist__c
                    );

                    matchingFields.forEach(field => {
                        console.log('field.Field_Label__c at 2686---', field.Field_Label__c);
                        console.log('dependentPicklistOptions.length----', dependentPicklistOptions.length);
                        
                        
                        if(field.Field_Label__c === 'Segment'  && dependentPicklistOptions.length === 1){
                            field.value = dependentPicklistOptions[0].value;
                            this.fieldDetails.forEach(record => {
                                if (record.Visibility_Controlled_By__c == field.Id && record.Id != field.Id) {
                                    const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                                    if (arrDependentControlledValue.find(element => element ==  field.value.toLowerCase())) {
                                        console.log('inside show');
                                        record.hideField = false;
                                        console.log('record.Id----', record.Id);
                
                                        setTimeout(() => {
                                            const element = this.template.querySelector(`[data-id="${record.Id}"]`);
                                            if (element) {
                                                setTimeout(() => {
                                                    element.classList.remove('slds-hide');
                                                }, 1000)
                
                                            } else {
                                                console.error(`Element with data-id="${record.Id}" not found`);
                                            }
                                        }, 100);
                                        // this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                                    } else {
                                        console.log('inside hide');
                                        // record.value = '';
                                        record.hideField = true;
                                        setTimeout(() => {
                                            if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                                                this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                                            }
                                            
                                        }, 1000)
                
                                    }
                                }
                            });
                        }

                        console.log('value in auto populate---', field);
                        
                        const targetElement = this.template.querySelector(`[data-id="${field.Id}"]`);
                        if (targetElement) {
                            if(this.isHLUser && targetElement.Storage_Field__c=='Customer_Profile__c'){
                                dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Others');
                            }else if(!this.isHLUser && targetElement.Storage_Field__c=='Customer_Profile__c'){
                                dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Non Working');
                            }
                            targetElement.options = dependentPicklistOptions;
                        }
                        
                    });
                    
                }).catch(error => {
                    if (error != undefined && error.body != undefined && error.body.message != undefined) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: error.body.message,
                                variant: 'error',
                            }),
                        );
                    }
                })
            }
            if(currentFieldDetails.Is_Controlling_Picklist__c && currentFieldDetails.Storage_Field__c == 'Sector__c'){
                console.log('currentFieldDetails.Storage_Object__c 1827---', currentFieldDetails.Storage_Object__c);
                console.log('currentFieldDetails.Storage_Field__c 1828---', currentFieldDetails.Storage_Field__c);
                console.log('currentFieldDetails.Dependent_Picklist__c 1829---', currentFieldDetails.Dependent_Picklist__c);
                console.log('Hello Kshtiz Prod.');
                getFieldDependencies({
                    objectName: currentFieldDetails.Storage_Object__c,
                    controllingField: currentFieldDetails.Storage_Field__c,
                    dependentField: 'Industry__c'
                }).then(result => {
                    console.log('dependent picklist values List=:1' + JSON.stringify(result));
                    const dependentPicklistOptions = result[currentValue];
                    console.log('dependent picklist options>',JSON.stringify(dependentPicklistOptions));
                    // const targetId = this.fieldDetails.find(item => item.Storage_Field__c == currentFieldDetails.Dependent_Picklist__c);
                    // console.log('target id000000', targetId.Id);
                    this.industryPicklistOptions = dependentPicklistOptions;

                    // this.template.querySelector(`[data-id="${targetId.Id}"]`).options = dependentPicklistOptions;
                    const matchingFields = this.fieldDetails.filter(item =>
                        item.Storage_Field__c === currentFieldDetails.Dependent_Picklist__c
                    );
                    
                    this.fieldDetails.forEach(item => {
                        if(item.Storage_Field__c === 'Industry__c'){
                        console.log('item.Storage_Field__c---- inside true', item.Storage_Field__c);
                        item.showBusinessIndustry = true;
                    }
                    })
                    matchingFields.forEach(field => {
                        console.log('field.Field_Label__c at 2686---', field.Field_Label__c);
                        console.log('dependentPicklistOptions.length----', dependentPicklistOptions.length);
                        
                        
                        if(field.Field_Label__c === 'Segment'  && dependentPicklistOptions.length === 1){
                            field.value = dependentPicklistOptions[0].value;
                            this.fieldDetails.forEach(record => {
                                if (record.Visibility_Controlled_By__c == field.Id && record.Id != field.Id) {
                                    const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                                    if (arrDependentControlledValue.find(element => element ==  field.value.toLowerCase())) {
                                        console.log('inside show');
                                        record.hideField = false;
                                        console.log('record.Id----', record.Id);
                
                                        setTimeout(() => {
                                            const element = this.template.querySelector(`[data-id="${record.Id}"]`);
                                            if (element) {
                                                setTimeout(() => {
                                                    element.classList.remove('slds-hide');
                                                }, 1000)
                
                                            } else {
                                                console.error(`Element with data-id="${record.Id}" not found`);
                                            }
                                        }, 100);
                                        // this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                                    } else {
                                        console.log('inside hide');
                                        // record.value = '';
                                        record.hideField = true;
                                        setTimeout(() => {
                                            if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                                                this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                                            }
                                            
                                        }, 1000)
                
                                    }
                                }
                            });
                        }

                        console.log('value in auto populate---', field);
                        
                       /* const targetElement = this.template.querySelector(`[data-id="${field.Id}"]`);
                        if (targetElement) {
                            targetElement.options = dependentPicklistOptions;
                        }*/
                        
                    });
                    
                }).catch(error => {
                    if (error != undefined && error.body != undefined && error.body.message != undefined) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: error.body.message,
                                variant: 'error',
                            }),
                        );
                    }
                })
            }
        } else if (currentField == 'Customer_Profile__c') {
            console.log('current field 3395',currentField);
            console.log('curentValue',currentValue);
            console.log('custumer Type 3396',this.customerType);
            this.customerType = this.appval[0].customerType;
            console.log('customer Type 3399',this.customerType);
            this.fieldDetails.forEach(record => {
                if ( (record.Storage_Field__c == 'Sector__c' || record.Storage_Field__c == 'Sub_Employment_Type_Non_Individual__c')) {
                    record.value = '';
                }
            })
            // if(currentValue == 'SENP'){
                 this.fieldDetails.forEach(item => {
                         if(item.Storage_Field__c == 'Industry__c'){
                        console.log('item.Storage_Field__c---- inside true Kshitiz', item.Storage_Field__c);
                        item.showBusinessIndustry = true;
                    }
                    })
            // }
            if(this.sanitize(currentValue) === 'salaried indian' && this.sanitize(this.customerType) === 'individual'){
                console.log('in Salaried Indian==>3618');
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
                this.fieldDetails.forEach(record => {
                    if (record.Visibility_Controlled_By__c == currentId && record.Id != currentId) {
                        console.log('currentValue.toLowerCase() ta 2432-- ', currentValue.toLowerCase());
    
                        const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                        console.log('arrDependentControlledValue----', arrDependentControlledValue);
    
                        if (arrDependentControlledValue.find(element => element == currentValue.toLowerCase())) {
                            console.log('inside show');
                            record.hideField = false;
                            console.log('record.Id----', record.Id);
    
                            setTimeout(() => {
                                const element = this.template.querySelector(`[data-id="${record.Id}"]`);
                                if (element) {
                                    setTimeout(() => {
                                        element.classList.remove('slds-hide');
                                    }, 1000)
    
                                } else {
                                    console.error(`Element with data-id="${record.Id}" not found`);
                                }
                            }, 100);
                            // this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                        } else {
                            console.log('inside hide1 3');
                            // record.value = '';
                            record.hideField = true;
                            setTimeout(() => {
                                if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                                    this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                                }
                                
                            }, 1000)
    
                        }
                    }
                    if (record.Is_Controlling_Picklist__c) {
                        getFieldDependencies({
                            objectName: record.Storage_Object__c,
                            controllingField: record.Storage_Field__c,
                            dependentField: record.Dependent_Picklist__c
                        }).then(result => {
                            console.log('Dependent picklist values: in connected callbackkk---record.Dependent_Picklist__c KD1', record.value, '--', JSON.stringify(result), '= ', record.Dependent_Picklist__c);
                            const dependentPicklistOptions = result[record.value];
                            console.log('dependentPicklistOptions----', dependentPicklistOptions);

                            // const targetField = this.fieldDetails.find(item => item.Storage_Field__c === record.Dependent_Picklist__c);

                            const targetField = this.fieldDetails.find(item => {
                                const isStorageFieldMatch = item.Storage_Field__c === record.Dependent_Picklist__c;

                                console.log('this.customerType----', this.customerType);

                                if (this.customerType != undefined && (item.Applicable_For__c == 'Both' || item.Applicable_For__c == 'Individual-Both' || item.Applicable_For__c == 'Non Individual-Both' || item.Applicable_For__c == (this.customerType + '-' + this.empType))) {
                                    return isStorageFieldMatch;
                                }
                                else if (item.Applicable_For__c == this.customerType) {
                                    return isStorageFieldMatch;
                                }
                            });


                            if (targetField) {
                                console.log('Inside target field---', targetField.Id);
                                if(this.isHLUser && targetField.Storage_Field__c=='Customer_Profile__c'){
                                    dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Others');
                                }else if(!this.isHLUser && targetField.Storage_Field__c=='Customer_Profile__c'){
                                    dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Non Working');
                                }
                                this.template.querySelector(`[data-id="${targetField.Id}"]`).options = dependentPicklistOptions;
                            }
                        }).catch(error => {
                            if (error != undefined && error.body != undefined && error.body.message != undefined) {
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: error.body.message,
                                        variant: 'error',
                                    }),
                                );
                            }
                        });
                    }
                });
                
                const labelsToRemove = [
                    
                    'Segment',
                    'Sub segment',
                    'Specialization',
                    'Business Industry',
                    'Registration Number',
                    'Registration Number (CIN)',
                    'Registration Number (LLPIN)',
                    'Udyam Registration Number',
                    'Number of Associated Entities',
                    'Entity 1',
                    'Entity 2',
                    'Office Ownership'
                ];

                this.removedFields = this.fieldDetails.filter(
                    field => labelsToRemove.includes(field.Field_Label__c)
                );

                this.fieldDetails = this.fieldDetails.filter(
                    field => !labelsToRemove.includes(field.Field_Label__c)
                );
            }
            else if(currentValue=='SENP' && this.customerType == 'Individual'){
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
                this.fieldDetails.forEach(record => {
                    if (record.Visibility_Controlled_By__c == currentId && record.Id != currentId) {
                        console.log('currentValue.toLowerCase() ta 2432-- ', currentValue.toLowerCase());
    
                        const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                        console.log('arrDependentControlledValue----', arrDependentControlledValue);
    
                        if (arrDependentControlledValue.find(element => element == currentValue.toLowerCase())) {
                            console.log('inside show');
                            record.hideField = false;
                            console.log('record.Id----', record.Id);
    
                            setTimeout(() => {
                                const element = this.template.querySelector(`[data-id="${record.Id}"]`);
                                if (element) {
                                    setTimeout(() => {
                                        element.classList.remove('slds-hide');
                                    }, 1000)
    
                                } else {
                                    console.error(`Element with data-id="${record.Id}" not found`);
                                }
                            }, 100);
                            // this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                        } else {
                            console.log('inside hide1 4');
                            // record.value = '';
                            record.hideField = true;
                            setTimeout(() => {
                                if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                                    this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                                }
                                
                            }, 1000)
    
                        }
                    }
                    if (record.Is_Controlling_Picklist__c) {
                        getFieldDependencies({
                            objectName: record.Storage_Object__c,
                            controllingField: record.Storage_Field__c,
                            dependentField: record.Dependent_Picklist__c
                        }).then(result => {
                            console.log('Dependent picklist values: in connected callbackkk---record.Dependent_Picklist__c KD2', record.value, '--', JSON.stringify(result), '= ', record.Dependent_Picklist__c);
                            const dependentPicklistOptions = result[record.value];
                            console.log('dependentPicklistOptions----', dependentPicklistOptions);

                            // const targetField = this.fieldDetails.find(item => item.Storage_Field__c === record.Dependent_Picklist__c);

                            const targetField = this.fieldDetails.find(item => {
                                const isStorageFieldMatch = item.Storage_Field__c === record.Dependent_Picklist__c;

                                console.log('this.customerType----', this.customerType);

                                if (this.customerType != undefined && (item.Applicable_For__c == 'Both' || item.Applicable_For__c == 'Individual-Both' || item.Applicable_For__c == 'Non Individual-Both' || item.Applicable_For__c == (this.customerType + '-' + this.empType))) {
                                    return isStorageFieldMatch;
                                }
                                else if (item.Applicable_For__c == this.customerType) {
                                    return isStorageFieldMatch;
                                }
                            });


                            if (targetField) {
                                console.log('Inside target field---', targetField.Id);
                                if(this.isHLUser && targetField.Storage_Field__c=='Customer_Profile__c'){
                                    dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Others');
                                }else if(!this.isHLUser && targetField.Storage_Field__c=='Customer_Profile__c'){
                                    dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Non Working');
                                }
                                this.template.querySelector(`[data-id="${targetField.Id}"]`).options = dependentPicklistOptions;
                            }
                        }).catch(error => {
                            if (error != undefined && error.body != undefined && error.body.message != undefined) {
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: error.body.message,
                                        variant: 'error',
                                    }),
                                );
                            }
                        });
                    }
                });
                
                const labelsToRemove = [
                   
                    'Segment',
                    'Sub segment',
                    'Specialization',
                   
                    'Registration Number',
                    'Registration Number (CIN)',
                    'Registration Number (LLPIN)',
                    'Udyam Registration Number',
                    'Number of Associated Entities',
                    'Entity 1',
                    'Entity 2',
                    'Office Ownership'
                ];

                this.removedFields = this.fieldDetails.filter(
                    field => labelsToRemove.includes(field.Field_Label__c)
                );

                this.fieldDetails = this.fieldDetails.filter(
                    field => !labelsToRemove.includes(field.Field_Label__c)
                );
            }else if((currentValue=='SEP' || currentValue=='Non Working' || currentValue=='Others') && this.customerType == 'Individual'){
            this.fieldDetails.forEach(record => {
                if (record.Id == currentId && record.Storage_Field__c == currentField) {
                    record.value = currentValue;
                    console.log('handleInputChange -->' + JSON.stringify(record));
                }
            });

                if(this.removedFields){
                    this.fieldDetails = this.fieldDetails.concat(this.removedFields);
                }

                const labelsToRemove = [
                    'Number of Associated Entities',
                    'Entity 1',
                    'Entity 2'
                ];

                let nonWorkingLablesToRemove;
                if(this.isHLUser){
                nonWorkingLablesToRemove = [
                    'Sector',
                        'Sub Employment Type',
                        'Business Vintage',
                        'CA Membership Number',
                        'Office Ownership',
                        'Segment',
                        'Sub segment',
                        'Specialization',
                        'Business Industry',
                        'Registration Number',
                        'Constitution',
                        'Total Work Experience (In Years)',
                        'Total Work Experience (In Months)',
                        'MSME Category',
                        'Registration Number (LLPIN)',
                        'Udyam Registration Number',
                        'Specialization',
                        'Number of Associated Entities',
                        'Entity 1',
                        'Entity 2',
                        'Qualification',
                        'Is Financial applicant?',
                        'Business Commencement Date',
                        'Shareholder/Partner Name',
                        'Share Holding Percentage',
                        'Industry Code',
                        'PSL',
                        'BSR Code',
                        'Other Nature of Business',
                        'Trade Name',
                        'Nature of Business',
                        'Registration Number (CIN)',
                        'Business Entity Name'
                ];}
                else{
                    nonWorkingLablesToRemove = [
                    'Sector',
                        'Sub Employment Type',
                        'Business Vintage',
                        'CA Membership Number',
                        'Office Ownership',
                        'Segment',
                        'Sub segment',
                        'Specialization',
                        'Business Industry',
                        'Registration Number',
                        'Constitution',
                        'Total Work Experience (In Years)',
                        'Total Work Experience (In Months)',
                        'MSME Category',
                        'Registration Number (LLPIN)',
                        'Udyam Registration Number',
                        'Specialization',
                        'Number of Associated Entities',
                        'Entity 1',
                        'Entity 2',
                        'Qualification',
                        'Business Commencement Date',
                        'Shareholder/Partner Name',
                        'Share Holding Percentage',
                        'Industry Code',
                        'PSL',
                        'BSR Code',
                        'Other Nature of Business',
                        'Trade Name',
                        'Nature of Business',
                        'Registration Number (CIN)',
                        'Business Entity Name'
                ];
                }

                if (currentValue == 'SEP') {
                    this.removedFields = this.fieldDetails.filter(
                        field => labelsToRemove.includes(field.Field_Label__c)
                    );

                    this.fieldDetails = this.fieldDetails.filter(
                        field => !labelsToRemove.includes(field.Field_Label__c)
                    );
                } else if (currentValue == 'Non Working' || currentValue== 'Others') {
                    this.nonWorkingLablesToRemove = this.fieldDetails.filter(
                        field => nonWorkingLablesToRemove.includes(field.Field_Label__c)
                    );

                    this.fieldDetails = this.fieldDetails.filter(
                        field => !nonWorkingLablesToRemove.includes(field.Field_Label__c)
                    );
                }

                this.fieldDetails.forEach(record => {
                    if (record.Visibility_Controlled_By__c == currentId && record.Id != currentId) {
                        console.log('currentValue.toLowerCase() ta 2432-- ', currentValue.toLowerCase());
    
                        const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                        console.log('arrDependentControlledValue----', arrDependentControlledValue);
    
                        if (arrDependentControlledValue.find(element => element == currentValue.toLowerCase())) {
                            console.log('inside show');
                            record.hideField = false;
                            console.log('record.Id----', record.Id);
    
                            setTimeout(() => {
                                const element = this.template.querySelector(`[data-id="${record.Id}"]`);
                                if (element) {
                                    setTimeout(() => {
                                        element.classList.remove('slds-hide');
                                    }, 1000)
            
        } else {
                                    console.error(`Element with data-id="${record.Id}" not found`);
                                }
                            }, 100);
                            // this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                        } else {
                            console.log('inside hide1 5');
                            // record.value = '';
                            record.hideField = true;
                            setTimeout(() => {
                                if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                                    this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                                }                                
                            }, 1000)
    
                        }
                    }
                    if (record.Is_Controlling_Picklist__c) {
                        getFieldDependencies({
                            objectName: record.Storage_Object__c,
                            controllingField: record.Storage_Field__c,
                            dependentField: record.Dependent_Picklist__c
                        }).then(result => {
                            console.log('Dependent picklist values: in connected callbackkk---record.Dependent_Picklist__c KD3', record.value, '--', JSON.stringify(result), '= ', record.Dependent_Picklist__c);
                            const dependentPicklistOptions = result[record.value];
                            console.log('dependentPicklistOptions----', dependentPicklistOptions);

                            // const targetField = this.fieldDetails.find(item => item.Storage_Field__c === record.Dependent_Picklist__c);

                            const targetField = this.fieldDetails.find(item => {
                                const isStorageFieldMatch = item.Storage_Field__c === record.Dependent_Picklist__c;

                                console.log('this.customerType----', this.customerType);

                                if (this.customerType != undefined && (item.Applicable_For__c == 'Both' || item.Applicable_For__c == 'Individual-Both' || item.Applicable_For__c == 'Non Individual-Both' || item.Applicable_For__c == (this.customerType + '-' + this.empType))) {
                                    return isStorageFieldMatch;
                                }
                                else if (item.Applicable_For__c == this.customerType) {
                                    return isStorageFieldMatch;
                                }
                            });


                            if (targetField) {
                                console.log('Inside target field---', targetField.Id);
                                if(this.isHLUser && targetField.Storage_Field__c=='Customer_Profile__c'){
                                    dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Others');
                                }else if(!this.isHLUser && targetField.Storage_Field__c=='Customer_Profile__c'){
                                    dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Non Working');
                                }
                                this.template.querySelector(`[data-id="${targetField.Id}"]`).options = dependentPicklistOptions;
                            }
                        }).catch(error => {
                            if (error != undefined && error.body != undefined && error.body.message != undefined) {
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: error.body.message,
                                        variant: 'error',
                                    }),
                                );
                            }
                        });
                    }
                });
            }
            
            else if(currentValue=='Salaried NRI' && this.customerType == 'Individual'){
            this.fieldDetails.forEach(record => {
                if (record.Id == currentId && record.Storage_Field__c == currentField) {
                    record.value = currentValue;
                    console.log('handleInputChange -->' + JSON.stringify(record));
                }
            });

                if(this.removedFields){
                    this.fieldDetails = this.fieldDetails.concat(this.removedFields);
                }

                const labelsToRemove = [
                    'Number of Associated Entities',
                    'Entity 1',
                    'Entity 2',
                    'Office Ownership'
                ];

                this.removedFields = this.fieldDetails.filter(
                    field => labelsToRemove.includes(field.Field_Label__c)
                );

                this.fieldDetails = this.fieldDetails.filter(
                    field => !labelsToRemove.includes(field.Field_Label__c)
                );

                this.fieldDetails.forEach(record => {
                    if (record.Visibility_Controlled_By__c == currentId && record.Id != currentId) {
                        console.log('currentValue.toLowerCase() ta 2432-- ', currentValue.toLowerCase());
    
                        const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                        console.log('arrDependentControlledValue----', arrDependentControlledValue);
    
                        if (arrDependentControlledValue.find(element => element == currentValue.toLowerCase())) {
                            console.log('inside show');
                            record.hideField = false;
                            console.log('record.Id----', record.Id);
    
                            setTimeout(() => {
                                const element = this.template.querySelector(`[data-id="${record.Id}"]`);
                                if (element) {
                                    setTimeout(() => {
                                        element.classList.remove('slds-hide');
                                    }, 1000)
            
        } else {
                                    console.error(`Element with data-id="${record.Id}" not found`);
                                }
                            }, 100);
                            // this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                        } else {
                            console.log('inside hide1 6');
                            // record.value = '';
                            record.hideField = true;
                            setTimeout(() => {
                                if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                                    this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                                }                                
                            }, 1000)
    
                        }
                    }
                    if (record.Is_Controlling_Picklist__c) {
                        getFieldDependencies({
                            objectName: record.Storage_Object__c,
                            controllingField: record.Storage_Field__c,
                            dependentField: record.Dependent_Picklist__c
                        }).then(result => {
                            console.log('Dependent picklist values: in connected callbackkk---record.Dependent_Picklist__c KD4', record.value, '--', JSON.stringify(result), '= ', record.Dependent_Picklist__c);
                            const dependentPicklistOptions = result[record.value];
                            console.log('dependentPicklistOptions----', dependentPicklistOptions);

                            // const targetField = this.fieldDetails.find(item => item.Storage_Field__c === record.Dependent_Picklist__c);

                            const targetField = this.fieldDetails.find(item => {
                                const isStorageFieldMatch = item.Storage_Field__c === record.Dependent_Picklist__c;

                                console.log('this.customerType----', this.customerType);

                                if (this.customerType != undefined && (item.Applicable_For__c == 'Both' || item.Applicable_For__c == 'Individual-Both' || item.Applicable_For__c == 'Non Individual-Both' || item.Applicable_For__c == (this.customerType + '-' + this.empType))) {
                                    return isStorageFieldMatch;
                                }
                                else if (item.Applicable_For__c == this.customerType) {
                                    return isStorageFieldMatch;
                                }
                            });


                            if (targetField) {
                                console.log('Inside target field---', targetField.Id);
                                if(this.isHLUser && targetField.Storage_Field__c=='Customer_Profile__c'){
                                    dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Others');
                                }else if(!this.isHLUser && targetField.Storage_Field__c=='Customer_Profile__c'){
                                    dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Non Working');
                                }
                                this.template.querySelector(`[data-id="${targetField.Id}"]`).options = dependentPicklistOptions;
                            }
                        }).catch(error => {
                            if (error != undefined && error.body != undefined && error.body.message != undefined) {
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: error.body.message,
                                        variant: 'error',
                                    }),
                                );
                            }
                        });
                    }
                });
            }
            else if((currentValue=='Non Working' || currentValue=='Others') && this.customerType == 'Individual'){
            this.fieldDetails.forEach(record => {
                if (record.Id == currentId && record.Storage_Field__c == currentField) {
                    record.value = currentValue;
                    console.log('handleInputChange -->' + JSON.stringify(record));
                }
            });

                if(this.removedFields){
                    this.fieldDetails = this.fieldDetails.concat(this.removedFields);
                }

                const labelsToRemove = [
                    'Sub Segment',
                    'Specialization',
                ];

                this.removedFields = this.fieldDetails.filter(
                    field => labelsToRemove.includes(field.Field_Label__c)
                );

                this.fieldDetails = this.fieldDetails.filter(
                    field => !labelsToRemove.includes(field.Field_Label__c)
                );

                this.fieldDetails.forEach(record => {
                    if (record.Visibility_Controlled_By__c == currentId && record.Id != currentId) {
                        console.log('currentValue.toLowerCase() ta 2432-- ', currentValue.toLowerCase());
    
                        const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                        console.log('arrDependentControlledValue----', arrDependentControlledValue);
    
                        if (arrDependentControlledValue.find(element => element == currentValue.toLowerCase())) {
                            console.log('inside show');
                            record.hideField = false;
                            console.log('record.Id----', record.Id);
    
                            setTimeout(() => {
                                const element = this.template.querySelector(`[data-id="${record.Id}"]`);
                                if (element) {
                                    setTimeout(() => {
                                        element.classList.remove('slds-hide');
                                    }, 1000)
            
        } else {
                                    console.error(`Element with data-id="${record.Id}" not found`);
                                }
                            }, 100);
                            // this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                        } else {
                            console.log('inside hide1 7');
                            // record.value = '';
                            record.hideField = true;
                            setTimeout(() => {
                                if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                                    this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                                }                                
                            }, 1000)
    
                        }
                    }
                    if (record.Is_Controlling_Picklist__c) {
                        getFieldDependencies({
                            objectName: record.Storage_Object__c,
                            controllingField: record.Storage_Field__c,
                            dependentField: record.Dependent_Picklist__c
                        }).then(result => {
                            console.log('Dependent picklist values: in connected callbackkk---record.Dependent_Picklist__c KD4', record.value, '--', JSON.stringify(result), '= ', record.Dependent_Picklist__c);
                            const dependentPicklistOptions = result[record.value];
                            console.log('dependentPicklistOptions----', dependentPicklistOptions);

                            // const targetField = this.fieldDetails.find(item => item.Storage_Field__c === record.Dependent_Picklist__c);

                            const targetField = this.fieldDetails.find(item => {
                                const isStorageFieldMatch = item.Storage_Field__c === record.Dependent_Picklist__c;

                                console.log('this.customerType----', this.customerType);

                                if (this.customerType != undefined && (item.Applicable_For__c == 'Both' || item.Applicable_For__c == 'Individual-Both' || item.Applicable_For__c == 'Non Individual-Both' || item.Applicable_For__c == (this.customerType + '-' + this.empType))) {
                                    return isStorageFieldMatch;
                                }
                                else if (item.Applicable_For__c == this.customerType) {
                                    return isStorageFieldMatch;
                                }
                            });


                            if (targetField) {
                                console.log('Inside target field---', targetField.Id);
                                if(this.isHLUser && targetField.Storage_Field__c=='Customer_Profile__c'){
                                    dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Others');
                                }else if(!this.isHLUser && targetField.Storage_Field__c=='Customer_Profile__c'){
                                    dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Non Working');
                                }
                                this.template.querySelector(`[data-id="${targetField.Id}"]`).options = dependentPicklistOptions;
                            }
                        }).catch(error => {
                            if (error != undefined && error.body != undefined && error.body.message != undefined) {
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: error.body.message,
                                        variant: 'error',
                                    }),
                                );
                            }
                        });
                    }
                });
            }
            
            
        } else if (currentLabel == 'Loan Amount') {
            if (currentValue) {
                getNumberToWord({ laAmt: currentValue })
                    .then(result => {
                        this.loanamtinwords = result;
                    })
                    .catch(error => {
                        console.error('Error fetching converted amount', error);
                    });
            } else {
                this.loanamtinwords = '';
            }
        } 
        else {
            if (this.screenName == `Confirm Applicant's Basic Details`) {
                if (currentField == 'Is_Current_Address_Same_As_Permanent__c' && (currentValue == 'No')) {
                    console.log('Inside----735');
                    this.showPermanentAdr = true;
                    this.permanentAddressFilled = true;
                    this.showUploadCurrentAddressProofDoc = true;
                } else {
                    this.showPermanentAdr = false;
                    this.permanentAddressFilled = false;
                    this.showUploadCurrentAddressProofDoc = false;
                }
            }


            //var textreg = /^[A-Za-z]*$/;
                // Updated regex to allow spaces
                var textreg = /^[A-Za-z ]*$/;
            var numregex = '^[0-9]*$';
            if (event.target.name == 'Text' && this.screenName != 'Confirm Address Information' && this.screenName != 'Reference Details') {
                // Sanitize input to remove invisible Unicode characters
                let sanitizedValue = currentValue.replace(/[\u200B-\u200D\uFEFF]/g, '');
                if ( /*currentId == 'CIN__c' || */ currentField == 'Reference_Phone_1__c' || currentField == 'Reference_Phone_2__c' || currentField == 'Mobile_Number__c' || currentField == 'Floor_Number__c') {
                    if (isNaN(Number(event.target.value))) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'Please enter in correct format.',
                                variant: 'error',
                            }),
                        );
                        // this.fieldsDataMap[currentId] ='';
                        // str.replace(/.$/, '')
                        if (this.template.querySelector(`[data-id="${currentId}"]`).value != undefined) {
                            this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                        } else {
                            this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                        }
                        // this.template.querySelector(`[data-id="${currentId}"]`).value=lastval;
                        return;
                    }
                } else {
                    console.log('currentValue', sanitizedValue);
                    console.log('!sanitizedValue.match(textreg)', !sanitizedValue.match(textreg));
                    if (!sanitizedValue.match(textreg)) {
                        if (currentField != 'Floor_Number__c' && currentField != 'Registration_Number__c' && currentField != 'Udhyam_Registration_No__c' &&
                            currentField != 'Landmark__c' && currentField != 'Reference_Address_1__c' && currentField != 'Plot_Number__c' && currentField != 'Company__c' &&
                            currentField != 'Reference_Address_2__c' && currentField != 'CIN_LLPIN_number__c' && currentField != 'GSTIN__c' && currentField != 'Legal_Entity_Number__c') {
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: 'Please enter in correct format.',
                                    variant: 'error',
                                }),
                            );
                            if (this.template.querySelector(`[data-id="${currentId}"]`).value != undefined) {
                                this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                            } else {
                                this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                            }
                            // this.template.querySelector(`[data-id="${currentId}"]`).value=lastval;
                            return;
                        }
                    }
                }

            } else if (event.target.name == 'Number' && this.screenName != 'Confirm Address Information' && this.screenName != 'Reference Details') {
                console.log('inside number');
                if (isNaN(Number(currentValue)) || event.target.value == '') {
                    console.log('pattern mismatch');
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter in correct format.',
                            variant: 'error',
                        }),
                    );
                    this.fieldsDataMap[currentId] = '';
                    if (this.template.querySelector(`[data-id="${currentId}"]`).value != undefined) {
                        this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                    } else {
                        this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                    }
                    return;
                }
            }
            // console.log('currentField -->'+currentField);

            const currentFieldDetails = this.fieldDetails.find(item => item.Storage_Field__c == currentField);
            // console.log('currentFieldDetails -->'+JSON.stringify(currentFieldDetails));

            this.fieldDetails.forEach(record => {
                if (record.Id == currentId && record.Storage_Field__c == currentField) {
                    record.value = currentValue;
                    console.log('handleInputChange test Kshitiz-->' + JSON.stringify(record));
                }
            });

            //For handling visibility for dependent item
            this.fieldDetails.forEach(record => {
                console.log('record.Visibility_Controlled_By__c 1826 test Kshitiz---', record.Visibility_Controlled_By__c, ' for field label ', record.Field_Label__c);
                console.log('currentId 1826 test Kshitiz---', currentId);
                console.log('record.Id 1826test Kshitiz---', record.Id ,'for field label ', record.Field_Label__c);
                console.log('record.Visibility_Controlled_By_Value__c 1826 test Kshitiz---', record.Visibility_Controlled_By_Value__c, ' for field label ', record.Field_Label__c);
                console.log('currentValue.toLowerCase() 1826 test Kshitiz---', currentValue.toLowerCase());
                if (record.Visibility_Controlled_By__c == currentId && record.Id != currentId) {
                    console.log('currentValue.toLowerCase() ta 2432 test Kshitiz--- ', currentValue.toLowerCase());
                    const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                    if (arrDependentControlledValue.find(element => element == currentValue.toLowerCase())) {
                        console.log('inside show');
                        record.hideField = false;
                        console.log('record.Id----', record.Id);

                        setTimeout(() => {
                            const element = this.template.querySelector(`[data-id="${record.Id}"]`);
                            if (element) {
                                setTimeout(() => {
                                    element.classList.remove('slds-hide');
                                }, 1000)

                            } else {
                                console.error(`Element with data-id="${record.Id}" not found`);
                            }
                        }, 100);
                        // this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                    } else {
                        console.log('inside hide');
                        // record.value = '';
                        record.hideField = true;
                        setTimeout(() => {
                            if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                            this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                            }                            
                        }, 1000)

                    }
                }
            });

            console.log('currentFieldDetails.Is_Controlling_Picklist__c 1827---', currentFieldDetails.Is_Controlling_Picklist__c);
            //For handling controlling and dependent picklist values
            if (currentFieldDetails.Is_Controlling_Picklist__c) {
                console.log('currentFieldDetails.Storage_Object__c 1827---', currentFieldDetails.Storage_Object__c);
                console.log('currentFieldDetails.Storage_Field__c 1828---', currentFieldDetails.Storage_Field__c);
                console.log('currentFieldDetails.Dependent_Picklist__c 1829---', currentFieldDetails.Dependent_Picklist__c);
                getFieldDependencies({
                    objectName: currentFieldDetails.Storage_Object__c,
                    controllingField: currentFieldDetails.Storage_Field__c,
                    dependentField: currentFieldDetails.Dependent_Picklist__c
                }).then(result => {
                    console.log('dependent picklist values List=:2' + JSON.stringify(result));
                    const dependentPicklistOptions = result[currentValue];
                    // const targetId = this.fieldDetails.find(item => item.Storage_Field__c == currentFieldDetails.Dependent_Picklist__c);
                    // console.log('target id000000', targetId.Id);

                    // this.template.querySelector(`[data-id="${targetId.Id}"]`).options = dependentPicklistOptions;
                    const matchingFields = this.fieldDetails.filter(item =>
                        item.Storage_Field__c === currentFieldDetails.Dependent_Picklist__c
                    );

                    matchingFields.forEach(field => {
                        const targetElement = this.template.querySelector(`[data-id="${field.Id}"]`);
                        if(this.isHLUser && targetElement.Storage_Field__c=='Customer_Profile__c'){
                            dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Others');
                        }else if(!this.isHLUser && targetElement.Storage_Field__c=='Customer_Profile__c'){
                            dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Non Working');
                        }
                        if (targetElement) {
                            targetElement.options = dependentPicklistOptions;
                        }
                    });
                }).catch(error => {
                    if (error != undefined && error.body != undefined && error.body.message != undefined) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: error.body.message,
                                variant: 'error',
                            }),
                        );
                    }
                })
            }
        }

        if((currentField == 'Customer_Profile__c' || currentField == 'Sector__c') ) {
            
             this.fieldDetails.forEach(record => {
                    if (/*record.Id == currentId &&*/ record.Storage_Field__c == 'Customer_Profile__c') {
                        this.cusPro = record.value;
                        
                        console.log('cus==Pro -->' + JSON.stringify(this.cusPro));
                    }
                     if (/*record.Id == currentId &&*/ record.Storage_Field__c == 'Sector__c') {
                        this.cussec = record.value;
                        
                        console.log('cus==sec -->' + JSON.stringify(this.cussec));
                    }
                }); 
                console.log('cus==Pro -->' + this.cusPro);
                console.log('cus==sec -->' + this.cussec);
                if (this.cusPro?.trim() && this.cussec?.trim()) {
                     console.log('cus==sec -->' + this.cusPro + this.cussec);
                    this.handleFetchIndustry(this.cusPro,this.cussec);
                }
        }
    }

    
    handleFetchIndustry(cusPro,cussec) {
        getIndustry({ 
            customerType: cusPro, 
            sector: cussec 
        })
        .then(result => {
            console.log('result -->' + JSON.stringify(result));
            this.industryOptions = result.map(item => {
                return { label: item, value: item };
            });
            this.industryOptionsAll = result.map(item => {
                return { label: item, value: item };
            });
            this.cusPro = null;
            this.cussec = null;
        })
        .catch(error => {
            console.error('Error fetching industries:', error);
        });
    }

    handleDropdownClick(event) {
        event.stopPropagation(); // Prevents dropdown from closing immediately
        let recordId = event.currentTarget.dataset.id;

        this.records = this.records.map(record => ({
            ...record,
            isDropdownOpen: record.Id === recordId ? !record.isDropdownOpen : false
        }));

        // Close dropdown when clicking outside
        document.addEventListener("click", this.closeDropdown);
    }

    handleSelection(event) {
        let recordId = event.currentTarget.dataset.id;
        let fieldName = event.currentTarget.dataset.name;
        let fieldValue = event.currentTarget.dataset.value;

        // Update the selected value and close the dropdown
        this.records = this.records.map(record => {
            if (record.Id === recordId) {
                return {
                    ...record,
                    [fieldName]: fieldValue,
                    isDropdownOpen: false
                };
            }
            return record;
        });

        // Save only the modified field
        this.saveFieldUpdate(recordId, fieldName, fieldValue);

        // Remove event listener after selection
        document.removeEventListener("click", this.closeDropdown);
    }

    closeDropdown = (event) => {
        if (!event.target.closest(".editable-field")) {
            this.records = this.records.map(record => ({
                ...record,
                isDropdownOpen: false
            }));
            document.removeEventListener("click", this.closeDropdown);
        }
    };

    saveFieldUpdate(recordId, fieldName, fieldValue) {
        console.log(`Saving ${fieldName} for ${recordId} with value: ${fieldValue}`);
        // Call Apex method to save field
    }

    toggleDropdown() {
        this.isDropdownOpen = !this.isDropdownOpen;
    }

    handleSelect(event) {
        this.selectedValue = event.currentTarget.dataset.value;
        this.selectedLabel = this.options.find(opt => opt.value === this.selectedValue).label;
        this.isDropdownOpen = false; // Close dropdown after selection
    }

    handleClickOutside(event) {
        // if (!this.template.contains(event.target)) {
        //     this.isDropdownOpen = false;
        // }
    }
    toggleDropdown(event) {
        console.log('Inside 1590---', event.target.dataset.id)

        // this.isDropdownOpen = !this.isDropdownOpen;
        this.fieldDetails.forEach(record => {
            console.log('Inside 1594---', record.Id)
            console.log('Inside 1595---', event.currentTarget.dataset.id)
            if (record.Id === event.currentTarget.dataset.id) {
                record.isDropdownOpen = !record.isDropdownOpen;
                console.log('Inside 1595---', event.currentTarget.dataset.id)
            } else {
                record.isDropdownOpen = false;
            }
        });
    }

    handleSelect(event) {
        console.log('handleSelect triggered');

        // Retrieve selected values from dataset
        const currentId = event.target.dataset.id;
        const currentField = event.target.dataset.name;
        const currentValue = event.target.dataset.value;

        console.log('currentId --> ' + currentId);
        console.log('currentField --> ' + currentField);
        console.log('currentValue --> ' + currentValue);

        // Ensure fieldDetails exist
        if (!this.fieldDetails || this.fieldDetails.length === 0) {
            // console.error('fieldDetails is empty or undefined');
            return;
        }

        // Find the selected field details
        const currentFieldDetails = this.fieldDetails.find(item => item.Storage_Field__c === currentField);
        if (!currentFieldDetails) {
            // console.error('No matching field found for:', currentField);
            return;
        }

        // Update the field's value
        this.fieldDetails = this.fieldDetails.map(record => {
            if (record.Id === currentId && record.Storage_Field__c === currentField) {
                return {
                    ...record,
                    value: currentValue
                };

            }
            return record;
        });
        this.fieldDetails.forEach(record => {
            record.isDropdownOpen = false;
        });
        console.log('Dropdown closed');


        console.log('Updated fieldDetails:', JSON.stringify(this.fieldDetails));

        // Handling dependent fields (show/hide logic)
        this.fieldDetails.forEach(record => {
            if (record.Visibility_Controlled_By__c === currentId && record.Id !== currentId) {
                const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                if (arrDependentControlledValue.includes(currentValue.toLowerCase())) {
                    console.log('inside show');
                    record.hideField = false;
                    setTimeout(() => {
                        if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                        this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                        }                        
                    }, 1000)
                } else {
                    console.log('inside hide');
                    record.hideField = true;
                    setTimeout(() => {
                        if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                        this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                        }                        
                    }, 1000)

                }
            }
        });

        // Handle controlling & dependent picklists
        if (currentFieldDetails.Is_Controlling_Picklist__c) {
            getFieldDependencies({
                objectName: currentFieldDetails.Storage_Object__c,
                controllingField: currentFieldDetails.Storage_Field__c,
                dependentField: currentFieldDetails.Dependent_Picklist__c
            }).then(result => {
                console.log('Dependent picklist values:', JSON.stringify(result));
                const dependentPicklistOptions = result[currentValue];
                const targetField = this.fieldDetails.find(item => item.Storage_Field__c === currentFieldDetails.Dependent_Picklist__c);

                if (targetField) {
                    if(this.isHLUser && targetField.Storage_Field__c=='Customer_Profile__c'){
                        dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Others');
                    }else if(!this.isHLUser && targetField.Storage_Field__c=='Customer_Profile__c'){
                        dependentPicklistOptions = dependentPicklistOptions.filter(item => item.value != 'Non Working');
                    }
                    this.template.querySelector(`[data-id="${targetField.Id}"]`).options = dependentPicklistOptions;
                }
            }).catch(error => {
                if (error != undefined && error.body != undefined && error.body.message != undefined) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: error.body.message,
                            variant: 'error',
                        }),
                    );
                }
            });
        }

        // Update UI for selected value

    }

    handleFocusOut(event) {
        setTimeout(() => {
            this.fieldDetails.forEach(record => {
                record.isDropdownOpen = false;
            });
        }, 100);

    }
    handleBlur(event) {
        const currentId = event.target.dataset.id;
        const currentField = event.target.dataset.name;
        const currentValue = event.target.value;
        const currentLabel = event.target.label;
        console.log('event required',event.target.required);
        const required = event.target.required;
        console.log('currentId in handleBlur --> ' + currentId);
        console.log('currentField in handleBlur--> ' + currentField);
        console.log('currentValue in handleBlur--> ' + currentValue);
        console.log('currentLabel in handleBlur--> ' + currentLabel);
        if (currentField == 'Requested_ROI__c') {
    console.log('inside Req ROI change.. ');
    console.log('currentValue: ' + currentValue);

    // Set the value to 2 decimal places
    const roundedValue = parseFloat(currentValue).toFixed(2);
     console.log('roundedValue: ' + roundedValue);
            const minROI = this.subProductLimits?.minROI;
            const maxROI = this.subProductLimits?.maxROI;
            // setTimeout(() => {
            if (minROI !== undefined && maxROI !== undefined) {
                const numericValue = parseFloat(roundedValue);

                if (numericValue < minROI || numericValue > maxROI) {
                    console.log('inside Error Scenario');
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: `Requested ROI should be between ${minROI} and ${maxROI}`,
                        variant: 'error',
                    }));
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                    return;
                } else {
                    this.fieldDetails.forEach(record => {
                        if (record.Id === currentId && record.Storage_Field__c === currentField) {
                            record.value = roundedValue;
                            console.log(' record.value: ' +  record.value);
                        }
                    });
                }
            } else {
                console.warn('Product limits not loaded yet.');
            }
            // }, 3000);
        
}else if (currentField == 'DOB__c') {
            var regexVar = /^([0-9]{2})\/([0-9]{2})\/([0-9]{4})$/;
            var regexDDMMMYYYY = /^(\d{2})-([A-Za-z]{3})-(\d{4})$/;
            if (currentValue != null) {
                let currentDate = new Date().toJSON().slice(0, 10)
                var userBirthDate = new Date(currentValue.replace(regexVar, "$3-$2-$1"));
                var todayYear = (new Date()).getFullYear(); // Always use FullYear!!
                var cutOff19 = new Date(); // should be a Date
                cutOff19.setFullYear(todayYear - 18); // ...  
                console.log('todayDate----', new Date());
                console.log('this.dateofBirth----', currentValue);
                if (currentValue >= currentDate) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Date of birth cannot be future/current date',
                        variant: 'Error',
                    }));
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
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
                } else {
                    this.fieldDetails.forEach(record => {
                        if (record.Id == currentId && record.Storage_Field__c == currentField) {
                            record.value = currentValue;
                            // console.log('handleInputChange -->'+JSON.stringify(record));
                        }
                    });
                }
            }
            else {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill Date of Birth in the correct format.',
                    variant: 'Error',
                }))
                this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                return;
            }
        } else if (currentField == 'Floor_Number__c') {
            console.log('Inside mobile number--', currentValue);
            if (textValidation(currentValue)) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter floor number in correct format',
                        variant: 'error',
                    }),
                );
                if (this.template.querySelector(`[data-id="${currentId}"]`).value != undefined) {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                }
                else {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                }
                return;
            } else if (!isValidMobileNumber(currentValue)) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter floor number in correct format',
                        variant: 'error',
                    }),
                );
                if (this.template.querySelector(`[data-id="${currentId}"]`).value != undefined) {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                }
                else {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                }
                return;
            } else {
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
            }
        }
         else if (currentField == 'GST_Exempt__c') {
            console.log('Inside GST_Exempt__c--', currentValue);
            this.fieldDetails.forEach(field => {
                if (field.Field_Label__c == 'GSTIN') {
                    if (currentValue == 'No') {
                        console.log('Inside No Kshitiz--');
                        field.Is_Mandatory__c = true;
                        
                    } else if (currentValue == 'Yes') {
                        console.log('Inside Yes Kshitiz--');
                        field.Is_Mandatory__c = false;
                        
                    }

                }
                if (field.Id == currentId && field.Storage_Field__c == currentField) {
                            field.value = currentValue;
                            console.log('GST Exempt value>'+field.value);
                }
            });
        } 
        else if (currentField == 'Mobile_Number__c' || currentField == 'Reference_Phone_1__c' || currentField == 'Reference_Phone_2__c') {
            console.log('Inside mobile number--', currentValue);
              console.log('Inside textValidation Kshitiz val 4--');
            if (textValidation(currentValue)) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter mobile number in correct format',
                        variant: 'error',
                    }),
                );
                if (this.template.querySelector(`[data-id="${currentId}"]`).value != undefined) {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                }
                else {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                }
                return;
            } else if (!isValidMobileNumber(currentValue)) {
                  console.log('Inside textValidation Kshitiz val 5--');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter mobile number in correct format',
                        variant: 'error',
                    }),
                );
                if (this.template.querySelector(`[data-id="${currentId}"]`).value != undefined) {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                }
                else {
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                }
                return;
            } if (currentValue.length == 10 && !mobileNumberValidation(currentValue)) {
                  console.log('Inside textValidation Kshitiz val 6--');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter mobile number in correct format',
                        variant: 'error',
                    }),
                );
                return;
            }
            if (currentValue.length > 10) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Mobile number should not be more than 10 digits',
                        variant: 'error',
                    }),
                );
                return;
            }
            else {
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
            }
        } else if (currentField == 'Email__c' || currentField == 'Alternate_Email__c') {
            console.log('Inside Alternate_Email__c--', currentValue);
            if (!emailValidation(currentValue)) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter email in correct format',
                        variant: 'error',
                    }),
                );
                // if(this.template.querySelector(`[data-id="${currentId}"]`).value != undefined){
                //     this.template.querySelector(`[data-id="${currentId}"]`).value = this.template.querySelector(`[data-id="${currentId}"]`).value.replace(/.$/, '');
                // }
                // else{
                //     this.template.querySelector(`[data-id="${currentId}"]`).value='';
                // }
                return;
            }
            else {
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
            }
        } else if (currentField == 'Salutation__c') {
            let genderField = this.fieldDetails.find(record => record.Storage_Field__c == 'Gender__c');

            if (genderField != undefined && genderField != null && genderField != '') {
                let genderValue = genderField.value;
                console.log('Selected Salutation:', currentValue);
                console.log('Detected Gender:', genderValue);

                if (genderValue != null && genderValue != undefined && genderValue != '' && genderValue != 'Transgender') {
                    const validCombinations = {
                        'Mr.': 'Male',
                        'Ms.': 'Female',
                        'Mrs.': 'Female',
                        // 'Dr.': ['Male', 'Female'], 
                        'Miss': 'Female',
                        // 'CA': ['Male', 'Female'],
                    };

                    if (validCombinations[currentValue] && !validCombinations[currentValue].includes(genderValue)) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: `Invalid combination: ${currentValue} cannot be used for ${genderValue}.`,
                                variant: 'error',
                            })
                        );
                        this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                        return;
                    }
                    else {
                        this.fieldDetails.forEach(record => {
                            if (record.Id == currentId && record.Storage_Field__c == currentField) {
                                record.value = currentValue;
                                console.log('handleInputChange -->' + JSON.stringify(record));
                            }
                        });
                    }
                }
                else {
                    this.fieldDetails.forEach(record => {
                        if (record.Id == currentId && record.Storage_Field__c == currentField) {
                            record.value = currentValue;
                            console.log('handleInputChange -->' + JSON.stringify(record));
                        }
                    });
                }

            } else {
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
            }
        } else if (currentField == 'Gender__c') {
            let salutationField = this.fieldDetails.find(record => record.Storage_Field__c == 'Salutation__c');

            if (salutationField != undefined && salutationField != null && salutationField != '') {
                let salutationValue = salutationField.value;
                console.log('Selected Salutation:', currentValue);
                console.log('Detected Gender:', salutationValue);

                if (salutationValue != null && salutationValue != undefined && salutationValue != '' && currentValue != 'Transgender') {
                    const validCombinations = {
                        'Mr.': 'Male',
                        'Ms.': 'Female',
                        'Mrs.': 'Female',
                        // 'Dr.': ['Male', 'Female'],
                        'Miss': 'Female',
                        // 'CA': ['Male', 'Female'],
                    };

                    if (validCombinations[salutationValue] && validCombinations[salutationValue] !== currentValue) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: `Invalid combination: ${currentValue} cannot be used for ${salutationValue}.`,
                                variant: 'error',
                            })
                        );
                        this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                        return;
                    }
                    else {
                        this.fieldDetails.forEach(record => {
                            if (record.Id == currentId && record.Storage_Field__c == currentField) {
                                record.value = currentValue;
                                console.log('handleInputChange -->' + JSON.stringify(record));
                            }
                        });
                    }
                }
                else {
                    this.fieldDetails.forEach(record => {
                        if (record.Id == currentId && record.Storage_Field__c == currentField) {
                            record.value = currentValue;
                            console.log('handleInputChange -->' + JSON.stringify(record));
                        }
                    });
                }

            } else {
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
            }
        } else if (currentField == 'Name_of_Organization__c' || currentField == 'Father_s_First_Name__c' || currentField == 'Father_s_Middle_Name__c'
            || currentField == 'Father_s_Last_Name__c' || currentField == 'Mother_s_First_Name__c'
            || currentField == 'Mother_s_Last_Name__c' || currentField == 'Spouse_First_Name__c' || currentField == 'Spouse_Middle_Name__c'
            || currentField == 'Spouse_Last_Name__c' || currentField == 'First_Name__c' || currentField == 'Last_Name__c' 
            || (currentField == 'Registration_Number__c' && currentLabel != 'Registration Number (LLPIN)' && currentLabel != 'Registration Number (CIN)') || currentField == 'Pan_Name__c'
        ) {
            console.log('Inside Name_of_Organization__c--', currentValue);
            if (charLength(currentValue) < 2 && currentField != 'Name_of_Organization__c' && currentField != 'Pan_Name__c'&& currentField != 'Father_s_Middle_Name__c') {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: currentLabel + ' can not have less than/ equal to 2 characters',
                        variant: 'error',
                    }),
                );

                return;
            } else {
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
            }
            if (currentField == 'Name_of_Organization__c' || currentField == 'Pan_Name__c') {
                if (charLength(currentValue) < 2) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: currentLabel + ' can not have less than 2 characters',
                            variant: 'error',
                        }),
                    );
                    return;
                } else if (!validateNameOfOrganisation(currentValue)) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter ' + currentLabel + ' in correct format.',
                            // message: currentLabel + ' can not have special characters',
                            variant: 'error',
                        }),
                    );
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                    return;
                } else {
                    if(currentField =='Pan_Name__c' && currentValue != this.appval[0].leadName && this.currentApplicantType === 'Primary Applicant' ){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Warning',
                                message: 'Please note that the name is different from lead.',
                                // message: currentLabel + ' can not have special characters',
                                variant: 'warning',
                            }),
                        );
                    }
                    this.fieldDetails.forEach(record => {
                        if (record.Id == currentId && record.Storage_Field__c == currentField) {
                            record.value = currentValue;
                            console.log('handleInputChange -->' + JSON.stringify(record));
                        }
                    });
                }
            }
            if (currentField == 'Father_s_First_Name__c' || currentField == 'Father_s_Middle_Name__c'
                || currentField == 'Father_s_Last_Name__c' || currentField == 'Mother_s_First_Name__c' || currentField == 'Mother_s_Middle_Name__c'
                || currentField == 'Mother_s_Last_Name__c' || currentField == 'Spouse_First_Name__c' || currentField == 'Spouse_Middle_Name__c'
                || currentField == 'Spouse_Last_Name__c' || currentField == 'First_Name__c' || currentField == 'Last_Name__c' || currentField == 'Middle_Name__c' || currentField == 'Pan_Name__c'
            ) {
                console.log('Inside Name_of_Organization__c--', currentValue);
                if (!checkSpecialCharacter(currentValue)) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter ' + currentLabel + ' in correct format.',
                            // message: currentLabel + ' can not have special characters',
                            variant: 'error',
                        }),
                    );
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                    return;
                } else {
                    this.fieldDetails.forEach(record => {
                        if (record.Id == currentId && record.Storage_Field__c == currentField) {
                            record.value = currentValue;
                            console.log('handleInputChange -->' + JSON.stringify(record));
                        }
                    });
                }
            }

            if (currentField == 'Registration_Number__c') {
                if (!checkalphnumeric(currentValue)) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: currentLabel + ' can not have special characters',
                            variant: 'error',
                        }),
                    );
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                    return;
                } else {
                    this.fieldDetails.forEach(record => {
                        if (record.Id == currentId && record.Storage_Field__c == currentField) {
                            record.value = currentValue;
                            console.log('handleInputChange -->' + JSON.stringify(record));
                        }
                    });
                }
            }
        } else if (currentField == 'GSTIN__c') {
            console.log('Inside GSTIN__c-', currentValue);
            if (!gstNumberValidation(currentValue)) {
                this.setValidity(currentField, false, 'Please enter GST number in correct format'); //Added by Kshitiz AHL 25/09/2025 for field validations
               // this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                if(!required){
                    this.clearValidity(currentField); //Added by Kshitiz AHL 9/10/2025 for field validations
                }
                return;
            } else if (gstNumberValidation(currentValue)) {
                
                let pan = currentValue.toString().slice(2,12);
                console.log('pan number from GST-->',pan);
                console.log('pan number-->',this.appval[0].panNumber);
                if (pan != this.appval[0].panNumber) {
                    this.setValidity(currentField, false, 'Kindly enter GSTIN number as per PAN.'); //Added by Kshitiz AHL 25/09/2025 for field validations
                    return;
                } else {
                    console.log('SELECTED Record-->', this.selectedRecordId);
                getPANToGSTNumber({
                    'loanId': this.recordId,
                        'applicantId': this.selectedRecordId,
                    'panNumber': this.appval[0].panNumber,
                    'gstIn': currentValue
                }).then(data => {
                    console.log('data-->', data);
                    if (data == 'NotFound') {
                        this.setValidity(currentField, false, 'GST number entered is incorrect based on the PAN provided.'); //Added by Kshitiz AHL 25/09/2025 for field validations
                       // this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                        return;
                        } if (data == 'APINotFound') {
                           this.clearValidity(currentField); //Added by Kshitiz AHL 25/09/2025 for field validations
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Warning',
                                    message: 'Currently unable to validate GSTIN Number, please proceed further.',
                                variant: 'Warning',
                            }),
                        );
                    }
                });
                }
            } else {
                //this. = false;
                this.clearValidity(currentField); //Added by Kshitiz AHL 25/09/2025 for field validations
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
            }
        }
       else if (currentField == 'Business_Vintage__c') {  
            if(currentValue == 0){
                this.setValidity(currentField, false, 'Please enter Business Vintage greater than 0'); //Added by Kshitiz AHL 25/09/2025 for field validations
                return;
            }
            else{
                this.clearValidity(currentField);
            }
        }
        else if(currentField == 'Mother_s_Middle_Name__c'){
            if(currentValue != null && currentValue != undefined && currentValue != '' && charLength(currentValue) < 2){
                this.setValidity(currentField, false, currentLabel +' can not have less than 2 characters'); //Added by Kshitiz AHL 25/09/2025 for field validations
                return;
            }
            else{
                this.clearValidity(currentField);
            }
        }
         else if (currentField == 'DOI__c') {
            var regexVar = /^([0-9]{2})\/([0-9]{2})\/([0-9]{4})$/;

            let currentDate = new Date().toJSON().slice(0, 10);
            console.log('this.dateofBirth----', currentValue);

            if (currentValue >= currentDate) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Date of incorporation cannot be future/current date',
                    variant: 'Error',
                }));
                this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                return;
            } else {
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        // console.log('handleInputChange -->'+JSON.stringify(record));
                    }
                });
            }
        } else if (currentField == 'Requested_Amount__c') {
            console.log('inside Req amount change.. ');
            console.log('currentValue: ' + currentValue);
            const minAmount = this.subProductLimits?.minLoanAmount;
            const maxAmount = this.subProductLimits?.maxLoanAmount;
            // setTimeout(() => {
            if (minAmount !== undefined && maxAmount !== undefined) {
                const numericValue = parseFloat(currentValue);

                if (numericValue < minAmount || numericValue > maxAmount) {
                    console.log('inside Error Scenario');
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: `Requested Amount should be between ${minAmount} and ${maxAmount}`,
                        variant: 'error',
                    }));
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                    return;
                } else {
                    this.fieldDetails.forEach(record => {
                        if (record.Id === currentId && record.Storage_Field__c === currentField) {
                            record.value = currentValue;
                        }
                    });
                }
            } else {
                console.warn('Product limits not loaded yet.');
            }
            // }, 3000);
        } else if (currentField == 'Tenor_Months__c') {
            console.log('inside Req amount chang4193e.. ');
            console.log('currentValue: ' + currentValue);
            const minTenure = this.subProductLimits?.minTenure;
            const maxTenure = this.subProductLimits?.maxTenure;
            // setTimeout(() => {
            if (minTenure !== undefined && maxTenure !== undefined) {
                const numericValue = parseFloat(currentValue);

                if (numericValue < minTenure || numericValue > maxTenure) {
                    console.log('inside Error Scenario');
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: `Requested Tenure should be between ${minTenure} and ${maxTenure}`,
                        variant: 'error',
                    }));
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                    return;
                } else {
                    this.fieldDetails.forEach(record => {
                        if (record.Id === currentId && record.Storage_Field__c === currentField) {
                            record.value = currentValue;
                        }
                    });
                }
            } else {
                console.warn('Product limits not loaded yet.');
            }
            // }, 3000);
        } else if(currentLabel == 'Registration Number (LLPIN)'){
            
            // const pattern = /^[A-Z]{3}-\[0-9]{4}$/;
            if (!currentValue.match(/[A-Z]{3}-[0-9]{4}$/)) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter ' + currentLabel + ' in correct format',
                        variant: 'error',
                    }),
                );
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                
                return;
            } else {
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
            }
        } else if(currentLabel == 'Registration Number (CIN)'){
            const pattern = /^[LU][0-9]{5}[A-Z]{2}[0-9]{4}[A-Z]{3}[0-9]{6}$/;
            if (!pattern.test(currentValue)) {
               this.setValidity(currentField, false, 'Please enter ' + currentLabel + ' in correct format'); //Added by Kshitiz AHL 25/09/2025 for field validations     
                return;
            } else {
                //this. = false;
                this.clearValidity(currentField); //Added by Kshitiz AHL 25/09/2025 for field validations
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
            }
        } else if (currentField == 'Udhyam_Registration_No__c' ){
            console.log('Inside udyam validation'+currentValue);
            if (!udyamValidation(currentValue)) {
                this.setValidity(currentField, false, 'Please enter Udyam registration number in correct format'); //Added by Kshitiz AHL 25/09/2025 for field validations
                if(!required){
                    this.clearValidity(currentField); //Added by Kshitiz AHL 25/09/2025 for field validations
                }
                return;
            }
            else {
                //this. = false;
                this.clearValidity(currentField); //Added by Kshitiz AHL 25/09/2025 for field validations
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
            }
        } else if(currentLabel == 'TAN Number'){
            if (!validateTANNumber(currentValue)) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter ' + currentLabel + ' in correct format',
                        variant: 'error',
                    }),
                );
                this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                return;
            } else {
                this.fieldDetails.forEach(record => {
                    if (record.Id == currentId && record.Storage_Field__c == currentField) {
                        record.value = currentValue;
                        console.log('handleInputChange -->' + JSON.stringify(record));
                    }
                });
            }
        } else if (currentLabel == 'Current Work Experience (In Years)') {
            this.currentExpInYear = currentValue;
            if (parseInt(this.totalExpInYear) != 0 || parseInt(this.totalExpInMonths) != 0) {
                var totalExp = (parseInt(this.totalExpInYear) * 12 + parseInt(this.totalExpInMonths));
                var currentExp = (parseInt(this.currentExpInYear) * 12 + parseInt(this.currentExpInMonths));
                if (totalExp < currentExp) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Total work experience cannot be less than current work experience',
                            variant: 'error',
                        }),
                    );
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                    this.currentExpInYear = 0;
                    return;
                }
            }
        } else if (currentLabel == 'Current Work Experience (In Months)') {
            this.currentExpInMonths = currentValue;
            if (parseInt(this.totalExpInYear) != 0 || parseInt(this.totalExpInMonths) != 0) {
                var totalExp = (parseInt(this.totalExpInYear) * 12 + parseInt(this.totalExpInMonths));
                var currentExp = (parseInt(this.currentExpInYear) * 12 + parseInt(this.currentExpInMonths));
                if (totalExp < currentExp) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Total work experience cannot be less than current work experience',
                            variant: 'error',
                        }),
                    );
                    this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                    this.currentExpInMonths = 0;
                    return;
                }
            }
        } else if (currentLabel == 'Total Work Experience (In Years)') {
            this.totalExpInYear = currentValue;
            var totalExp = (parseInt(this.totalExpInYear)*12 + parseInt(this.totalExpInMonths));
            var currentExp = (parseInt(this.currentExpInYear)*12 + parseInt(this.currentExpInMonths));
            if(totalExp < currentExp){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Total work experience cannot be less than current work experience',
                        variant: 'error',
                    }),
                );
                this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                this.totalExpInYear = 0;
                return;
            }
        } else if (currentLabel == 'Total Work Experience (In Months)') {
            this.totalExpInMonths = currentValue;
            var totalExp = (parseInt(this.totalExpInYear)*12 + parseInt(this.totalExpInMonths));
            console.log('totalExp-->',totalExp);
            var currentExp = (parseInt(this.currentExpInYear)*12 + parseInt(this.currentExpInMonths));
            console.log('currentExp-->',currentExp);
            if(totalExp < currentExp){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Total work experience cannot be less than current work experience',
                        variant: 'error',
                    }),
                );
                this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                this.totalExpInMonths = 0;
                return;
            }
        }else if (currentField == 'Date of Joining') {
            var regexVar = /^([0-9]{2})\/([0-9]{2})\/([0-9]{4})$/;

            let currentDate = new Date().toJSON().slice(0, 10);

            // Convert current DOJ to Date object
            var userJoinDate = new Date(currentValue.replace(regexVar, "$3-$2-$1"));

            if (currentValue >= currentDate) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Date of Joining cannot be future/current date',
                    variant: 'Error',
                }));
                this.template.querySelector(`[data-id="${currentId}"]`).value = '';
                return;
            } else {
            this.fieldDetails.forEach(record => {
                if (record.Id == currentId && record.Storage_Field__c == currentField) {
                    record.value = currentValue;
                }
            });
            }
        } else if(currentField == 'CKYC_Aadhar__c' && this.passedScreenName == 'Seller Details'){
            console.log('CKYC_Aadhar__c masking '+ this.passedScreenName)
            try {
                let actualValue = currentValue;
                const maskedValue = '*'.repeat(currentValue.length);
                event.target.value = maskedValue;
                console.log('CKYC_Aadhar__c currentValue '+ currentValue)
                console.log('CKYC_Aadhar__c actualValue '+ actualValue)
            } catch (error) {
                console.log('error masking  '+JSON.stringify(error))
            }
        }


        setTimeout(() => {
            this.fieldDetails.forEach(record => {
                record.isDropdownOpen = false;
            });
        }, 100);
    }


    showCustomCmp(cmpName) {
        this.onePage = false;
        this.showIncomeScreen = false;
        this.showBSAScreen = false;
        this.showSalesLoginPrimaryApplicantInfoScreen = false;
        this.showProductInfoScreen = false;
        this.showLoginFeeScreen = false;
        this.cibilOneView = false;
        this.showCibilEligibility = false;
        this.showPrimaryApplicantInfoScreen = false;
        this.showAddressDetails = false;
        console.log('cmpName:::: ' + cmpName);
        switch (cmpName) {

            case 'SalesIncomeEligibilityCmp':
                this.showIncomeScreen = true;

                break;
            case 'SalesLoginBSAScreenCmp':
                this.showBSAScreen = true;
                break;
            case 'SalesLoanLoginAddressDetails':
                this.showAddressDetails = true;
                break;
            case 'CibilOneViewCmp':
                this.cibilOneView = true;
                break;
            case 'CibilEligibility':
                this.showCibilEligibility = true;
                break;
            case 'SalesLoginPrimaryApplicantInfoCmp':
                this.showSalesLoginPrimaryApplicantInfoScreen = true;
                break;
            case 'salesLoginProductDetailsCmp':
                console.log('this.showProductInfoScreen');
                this.showProductInfoScreen = true;
                console.log('this.showProductInfoScreen 2969');
                break;
            case 'LoginFeeCmp':
                console.log('this.showLoginFeeScreen');
                this.showLoginFeeScreen = true;
                console.log('this.showLoginFeeScreen 4483');
                break;
            case 'fsaCmp':
                this.showFSA = true;
                break;
            case 'SalesLoginEligibilityCmp':
                this.viewEligibilityBSA = true;
                console.log('viewEligibilityBSA:::: ' + this.viewEligibilityBSA);
                break;
            case 'creditEligibilityComponent':
                this.showcreditEligibilityComponent = true;
                console.log('showcreditEligibilityComponent:::: ' + this.showcreditEligibilityComponent);
                break;
            default:


        }
    }
    handleFocus(event) {
        event.stopPropagation();
    }
    handleKeepAccordionOpen(event) {
        console.log('this.showBSAScreen=:' + this.showBSAScreen);
        this.dispatchEvent(new CustomEvent('keepaccordionopen', {
            bubbles: true,
            composed: true
        }));
        this.showBSAScreen = true;
    }


    navToLoanDetails(event) {
        console.log('navToLoanDetails recordId--> ' + event.detail.value);
        console.log('navToLoanDetails name--> ' + event.detail.name);
        console.log('navToLoanDetails currentAppSeq--> ' + event.detail.currentAppSeq);
        const valueChangeEvent = new CustomEvent("callloandetails", {
            detail: { value: this.recordId, name: 'Loan Details', currentAppSeq: '2' }
        });
        this.dispatchEvent(valueChangeEvent);
    }
    goPrevious(event) {
        console.log('2526');
        console.log('this.currentAppSeq--- 635 ' + this.currentAppSeq);
        console.log(' this.activeSection.name ' + this.activeSection.name);
        console.log('this.formIdentifier ' + this.formIdentifier);
        if (this.activeSection.name == 'Loan Details') {
            // this.showCustomCmp('salesLoginProductDetailsCmp');
            console.log('previous loan Details');
            const previousEvent = new CustomEvent('openpreviousscreen', {
                detail: {
                    screenName: 'Product Details'
                }
            });
            this.dispatchEvent(previousEvent);
        }else if (this.activeSection.name == 'PMAY Eligibility') {
            // this.showCustomCmp('salesLoginProductDetailsCmp');
            console.log('previous PMAY');
            const previousEvent = new CustomEvent('openpreviousscreen', {
                detail: {
                    screenName: 'Loan Details'
                }
            });
            this.dispatchEvent(previousEvent);
        }
        else {
            const valueSelectedEvent = new CustomEvent('opennextscreen', {
                detail: {
                    screenName: 'Dedupe'
                }
            });
            this.dispatchEvent(valueSelectedEvent);
        }
    }

    updateRecordField(recordId, fieldApiName, fieldValue) {
        const fields = {};
        fields['Id'] = recordId;
        fields[fieldApiName] = fieldValue;
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                console.log('Record updated successfully 2815', JSON.stringify(recordInput));
            })
            .catch(error => {
                console.error('Error updating record: ', error);
                console.log('Error updating record --> ' + JSON.stringify(error));
            })
    }
    checkNextStageMovement() {
        console.log('result-----2838-Generic Screen');
        console.log('this.activeSection.name-----2839-Generic Screen kshitiz 1', this.activeSection.name);
        const valueSelectedEventfinal = new CustomEvent('refreshmenucmpfinal', {
            detail: {
                loanId: this.recordId,
                screenName: this.activeSection.name,
                applicantId: this.selectedRecordId
            }
        });
        this.dispatchEvent(valueSelectedEventfinal);
        setTimeout(() => {
            checkNextStageMovement({
                recordId: this.recordId
            })
            .then(result => {
                console.log('result-----2842-Generic Screen', JSON.stringify(result));
                console.log('this.activeSection.name-----2843-Generic Screen kshitiz 2', this.activeSection.name);
                if (result) {
                    // Store the errors from the result
                    this.errors = result.errors || [];
                    this.showLoginButton = true; //result.showLogin;
                    this.movetoEligibility = result.moveToEligibility;
                    if (this.movetoEligibility == false) {
                        if (this.errors.length > 0) {
                            this.hasErrors = true;
                        }
                        else {
                            this.hasErrors = false;
                        }
                    }
                    else {
                        const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
                            detail: {
                                loanId: this.recordId,
                                screenName: this.activeSection.name,
                                applicantId: this.selectedRecordId
                            }
                        });
                        this.dispatchEvent(valueSelectedEvent);
                        this.getScreenDetailsFromApex();
                    }
                }

            })
            .catch(error => {
            })
        }, 1000);
        
    }
    handleCloseConfirm() {
        this.hasErrors = false;
    }
    handleLoginLoan() {
        console.log('recordId----', this.recordId)

        this.loginToNextStage();
        console.log('result-----3202-Generic Screen');
        
        this.updateFCUDate();//Added by Fawaz for SFAH-2170

    }
   
    //Added by Fawaz for SFAH-2170
    updateFCUDate(){
        
        updateFCUInitiationDate({ loanApplicationId: this.recordId })
        .then(() => {
                console.log('FCU Initiation Date updated successfully')
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
    
    loginToNextStage() {
        console.log('result-----3208-Generic Screen');
        quickActionSave({
            loanApplicationId: this.recordId,
            quickActionName: 'Mark as complete',

        })
            .then(result => {
                this.fetchApplicants();
                console.log('result-----2842-Generic Screen', JSON.stringify(result));
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Loan Logged in Successfully',
                    variant: 'Success',
                }));

                sendEmailToUsers({ loanId: this.recordId })
                    .then(result => {
                        console.log('Email sent Successfully', JSON.stringify(result));

                        console.log('result-----3225-Generic Screen');
                        this.generateAppform=true;


                    })
                    .catch(error => {
                        console.log('Email Error', JSON.stringify(error));

                        console.log('result-----3233-Generic Screen');
                    })

                if (window.location.origin.includes('my.site.com')) {
                    window.location.href = '/losportal/s/';

                }
                else {
                    location.reload();
                }
            })
            .catch(error => {
                console.log('Error', JSON.stringify(error));
            })

    }
     validateOVDDocuments(){
        this.checkBREAPI=false;
        validateOVDDocuments({
            recordId: this.recordId
        })
        .then(result => {
            console.log('result-----6200-Generic Screen', JSON.stringify(result));
            if (result.length > 0) {
                    this.errorModal = true;
                    this.errorLst = result;
            }
            else{
                if(this.showHLRelatedData){
                    this.checkBREAPI=true;
                }
                else{
                    this.checkNextStageMovement();
                }
                
                console.log('result-----6206-Generic Screen', this.checkBREAPI);
                
            }
        })
        .catch(error => {
                console.log('Error', JSON.stringify(error));
        })


    }
    handleCloseBRE(){
        this.checkBREAPI=false;
    }
    handleProceedBRE(){
        this.checkBREAPI=false;
        this.checkNextStageMovement();
    }
    hideModalBoxError(){
        this.errorModal=false;
    }
    initiateAPIRequestForAadharConsent(latitude, longitude){
        console.log('input :: AadharConsent:'+ latitude + ' :: ' + longitude +' :: ' + this.selectedRecordId);
        let applicantId = this.selectedRecordId;
        const inputMap = {
                            'loanId': this.recordId,
                            'applicantId': this.selectedRecordId,
                            'processName': 'Aadhar Consent',
                            'latitude':latitude,
                            'longitude':longitude,
                        }
        console.log('Input for =: AadharConsent' + JSON.stringify(inputMap));
        initiateAPIRequestForAadharConsent({ inputMap: inputMap })
            .then(result => {
                console.log('response=: AadharConsent:: ' + result);
                if(!result.includes('Error: No Aadhaar Number found for applicant')){
                    console.log('response=: AadharConsent :: In IF :::' + JSON.stringify(result));
                    console.log('response=: AadharConsent :: In IF :::' + applicantId);
                    let parsedData = JSON.parse(result);
                    console.log('response=: AadharConsent :: In IF :::' + parsedData.requestId);
                    console.log('response=: AadharConsent :: In IF :::' + parsedData.result.accessKey);
                
                    const palinputmap = {
                        'loanId': this.recordId,
                        'applicantId': applicantId,
                        'processName': 'Pan Aadhar Link',
                        'accessKey': parsedData.requestId
                    }
                    console.log('input map for=: PAN Aadhar link  ::' + JSON.stringify(palinputmap));
                    initiateAPIRequestForPanAadharLink({ inputMap: palinputmap })
                        .then(result => {
                            console.log('response=: PanAadharLink' + result);
                                 let parsedData = JSON.parse(result);
                                 console.log('response=: PanAadharLink :: In IF :::' + parsedData.result.message);
                                 if(parsedData.result.message == null)	{
                                    this.showToast('Info', 'PAN and Aadhaar is not linked.', 'info');
                                 }
                                 else{
                                    this.showToast('Info', parsedData.result.message, 'info');
                                 }
                        })
                        .catch(error => {
                            console.error('Error in Pan Aadhar Link::'+ JSON.stringify(error));
                        })    

                }
                    
            })
            .catch(error => {
                console.error('Error in AadharConsent::'+ JSON.stringify(error));
            })
    }
    updateFieldDetails(id, field, value) {
        let recordIndex = this.fieldDetails.findIndex(record => record.Id === id && record.Storage_Field__c === field);
        if (recordIndex !== -1) {
            if (this.fieldDetails[recordIndex].value !== value) {
                this.fieldDetails[recordIndex] = {
                    ...this.fieldDetails[recordIndex],
                    value
                };
                // this.fieldDetails = [...this.fieldDetails]; // Ensure LWC reactivity
            }
        }
    }
    handleCloseConfirmLogin() {
        this.showLoginButton = false;
    }
    isProductAdded() {
        isProductAdded({
            recordId: this.recordId
        })
            .then(result => {
                console.log('result 2911---', result);
                if (result) {
                    this.productAdded = true;
                }
                else {
                    this.productAdded = false;
                }
            })
            .catch(error => {
            })
    }
    checkConsent(){
        console.log('checkConsent');
        checkConsent({
            recordId: this.recordId
        })
        .then(result => {
            console.log('result 2911---', result);
            if (result) {
                this.consentReceived = true;
            }
            else {
                this.consentReceived = false;
            }
        })
        .catch(error => {
        })
    }

    fetchApplicants() {
        console.log('All dedupe calls completed 3282.');
        getAllApplicants({ loanId: this.recordId })
            .then(result => {
                // this.applicantIds = result.map(item => item.applicantId);

this.applicantIds = [...result.map(item => item.applicantId)];

                this.callDedupeSequentially();
            })
            .catch(error => {
                console.error('Error fetching applicants:', error);
            });
    }

    callDedupeSequentially() {
        console.log('All dedupe calls completed.');
        if (this.currentIndex >= this.applicantIds.length) {
            console.log('All dedupe calls completed.');
            return;
        }
        callDedupeAPI({ applicantId: applicantId, loanId: this.recordId })
            .then(response => {
                console.log('Dedupe success for applicant:', applicantId, response);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Deupe api is successfull',
                    variant: 'Success',

                }));
                this.currentIndex++;
                this.callDedupeSequentially();
            })
            .catch(error => {
                console.error('Error in deduping applicant:', applicantId, error);
                this.currentIndex++;
                this.callDedupeSequentially();
            });
    }

    async navToNextFromApi(event) {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[STAGE_FIELD.fieldApiName] = 'Credit Underwriting';
        fields[SUBSTAGE_FIELD.fieldApiName] = 'Credit Processing Verification';
        fields[DOCVERIFBYCO_FIELD.fieldApiName] = true;
        await updateRecord({ fields });
        
        /*await this.updateRecordField(this.recordId, 'Documents_Verified_By_CO__c', 'true');
        this.updateRecordField(this.recordId, 'StageName', 'Credit Underwriting');
        this.updateRecordField(this.recordId, 'Sub_stage__c', 'Credit Processing Verification');*/
        window.location.reload();

        /*this.modalAPIVisibility = false;
        if(this.activeSection.name == 'Additional Information'){
             await this.updateStage();
        }
        this.validateOVDDocuments();
       
        
        this.getNextScreenDetails();*/
        
    }
   @wire(getRecord, { recordId: '$recordId', fields: [LOGIN_COMPLETION_STAGE] })
        opp;

        // Call this instead of Apex
        async updateStage() {
        try {
        // Current multi-select value as a semicolon string (or '')
        const currentStage = getFieldValue(this.opp.data, LOGIN_COMPLETION_STAGE) || '';
            console.log('currentStage--->',currentStage);
        // Turn into a Set to avoid duplicates, add our value, then back to the required ';' string
        const stageSet = new Set(currentStage ? currentStage.split(';') : []);
        stageSet.add('Other Information'); // the option must exactly match your picklist value
        const updatedStage = Array.from(stageSet).join(';');
            console.log('updatedStage--->',updatedStage);
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[LOGIN_COMPLETION_STAGE.fieldApiName] = updatedStage;
       // fields[OPP_CODE.fieldApiName] = this.newOpportunityCode; // set your code here

        await updateRecord({ fields });

        // optional: toast/log
        console.log('Stage updated via LDS');
        // this.showToast('Success', 'Stage updated', 'success');

        // If other UI depends on this record, notify LDS to refresh elsewhere:
        // await getRecordNotifyChange([{recordId: this.recordId}]);
        } catch (error) {
        console.error('Error updating stage via LDS:', error);
        // this.showToast('Error', reduceErrors(error).join(', '), 'error');
        }
        }

    handleCloseAPI(event) {
        this.modalAPIVisibility = false;
    }

    refreshaction(event) {
        console.log('insdeiii---');
        
        const valueChangeEvent = new CustomEvent("refreshactions", {
            detail: { value: this.recordId, name: event.detail.name, currentAppSeq: '2' }
        });
        this.dispatchEvent(valueChangeEvent);
    }

    handlebIndustryChange(event){
        const val = event.detail.value;
        //const currentId = event.target.dataset.id;
        const currentId = event.currentTarget.dataset.id;
        //const currentField = event.target.dataset.name;
        const currentValue = event.target.value;
        const currentLabel = event.target.label;
        const currentField = 'Industry__c';
        //For handling visibility for dependent item
            this.fieldDetails.forEach(async record => {
                if (record.Field_Type__c === 'Picklist') {
                        if(record.Storage_Field__c == 'Industry__c'){
                            if ((!this.industryPicklistOptions || !this.industryPicklistOptions.length) && record.picklistOptions && record.picklistOptions.length) {
                                this.industryPicklistOptions = [...record.picklistOptions];
                                console.log('Initialized industryPicklistOptions from record>>', JSON.stringify(this.industryPicklistOptions)
                                );
                            }
                            console.log('Inside Industry__c picklist option Kshitiz>>', JSON.stringify(record.picklistOptions));
                            record.picklistOptions  = this.industryPicklistOptions ;//await this.getPicklistOptionsFromApex(true,  record.Storage_Object__c,  record.Storage_Field__c);
                            console.log('Industry__c picklist option>>', JSON.stringify(record.picklistOptions));
                            //  = [picklistValues.values()];
                        }
                        console.log('item.Storage_Field__c----',  record.Storage_Field__c);
                        
                        

                        console.log('item.picklistOptions----', JSON.stringify( record.picklistOptions));
                        
                    }
                console.log('record.Visibility_Controlled_By__c 1826 test Kshitiz industry---', record.Visibility_Controlled_By__c, ' for field label ', record.Field_Label__c);
                console.log('currentId 1826 test Kshitiz industry---', currentId);
                console.log('record.Id 1826test Kshitiz industry---', record.Id ,'for field label ', record.Field_Label__c);
                console.log('record.Visibility_Controlled_By_Value__c 1826 test Kshitiz industry---', record.Visibility_Controlled_By_Value__c, ' for field label ', record.Field_Label__c);
                console.log('currentValue.toLowerCase() 1826 test Kshitiz industry---', currentValue.toLowerCase());
                if (record.Storage_Field__c == currentField) {
                    record.value = val;
                    console.log('handlebIndustryChange Kshitiz industry-->' + JSON.stringify(record));
                }
                if (record.Visibility_Controlled_By__c == currentId && record.Id != currentId) {
                    console.log('currentValue.toLowerCase() ta 2432 test Kshitiz industry--- ', currentValue.toLowerCase());
                    const arrDependentControlledValue = record.Visibility_Controlled_By_Value__c.trim().toLowerCase().split(',');
                    if (arrDependentControlledValue.find(element => element == currentValue.toLowerCase())) {
                        console.log('inside show Kshitiz industry');
                        record.hideField = false;
                        console.log('record.Id Kshitiz industry----', record.Id);

                        setTimeout(() => {
                            const element = this.template.querySelector(`[data-id="${record.Id}"]`);
                            if (element) {
                                setTimeout(() => {
                                    element.classList.remove('slds-hide');
                                }, 1000)

                            } else {
                                console.error(`Element with data-id="${record.Id}" not found`);
                            }
                        }, 100);
                        // this.template.querySelector(`[data-id="${record.Id}"]`).classList.remove('slds-hide');
                    } else {
                        console.log('inside hide Kshitiz industry');
                        // record.value = '';
                        record.hideField = true;
                        setTimeout(() => {
                            if(this.template.querySelector(`[data-id="${record.Id}"]`)){
                            this.template.querySelector(`[data-id="${record.Id}"]`).classList.add('slds-hide');
                            }                            
                        }, 1000)

                    }
                }
            });
    }
    handlebIndustryBlur(event){
        this.fieldDetails.forEach(async record => {
                if (record.Field_Type__c === 'Picklist') {
                        if(record.Storage_Field__c == 'Industry__c'){
                            record.picklistOptions  = [] ;//await this.getPicklistOptionsFromApex(true,  record.Storage_Object__c,  record.Storage_Field__c);
                            console.log('Industry__c picklist option>>', JSON.stringify(record.picklistOptions));
                            //  = [picklistValues.values()];
                        }
                        console.log('item.Storage_Field__c----',  record.Storage_Field__c);
                        
                        

                        console.log('item.picklistOptions----', JSON.stringify( record.picklistOptions));
                        
                    }
                });
    }
    handleNavigateNext(){
        console.log('5632');
        this.dispatchEvent(new CustomEvent('navigatetonexttab', {
                detail: 'Document Details'
            }));
    }

    navigateNext(event){
        this.validateSaveAndNext();
    }

    sanitize(str) {
    return str?.replace(/[\u200B-\u200D\uFEFF]/g, '').trim().toLowerCase();
    }

    async validateMNRL(mobile) {

    try {
        this.isLoading = true;
        const mnrlResult = await checkMNRL({
            inputMap: { mobNumber: mobile, processName: 'MNRL Check',
                applicantId: this.selectedRecordId
             }
        });

        console.log('MNRL Result:', mnrlResult);

        if (mnrlResult && mnrlResult.isBlacklisted) {
            // ❌ Blacklisted
            this.showToast('Error', mnrlResult.message || 'Mobile number failed MNRL validation.', 'error');
            return false;
        }

        // ✅ Not blacklisted
        return true;
    } catch (error) {
        console.error('Error in MNRL check: ', JSON.stringify(error));
        this.showToast('Error', 'Failed to validate mobile number. Please try again.', 'error');
        return false;
    } finally {
        this.isLoading = false;
    }
}
    // Added by Kshitiz AHL 25/09/2025 for field Validations
    setValidity(key, isValid, msg = '') {
        this.validationMap.set(key, { valid: isValid, msg });
        if (!isValid) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: msg,
                variant: 'error'
            })
            );
        }
    }
    clearValidity(key) {
        this.setValidity(key, true, '');
    }
    anyInvalid() {
        for (const { valid } of this.validationMap.values()) {
            if (!valid) 
                return true;
            }
            return false;
    }
    //Kshitiz 25/09/2025 AHL code for field validations ends here
     //HL-Ishi
     callUCICAPI() {
        console.log('Inside ucic-------');
        callUCICAPI({
            loanId: this.recordId,
            applicantId: this.selectedRecordId
        })
            .then(response => {
            })
            .catch(error => {


            });

    }
     handleRefreshCmp(event) {
        console.log('inside handleRefreshCmp event.detail.loanId=: in main');
        
        // this.recordId = event.detail.loanId;
        // this.template.querySelector('c-sales-login-action-flow-cmp').changeMessage(event);
        console.log('event.detail.screenName---handleRefreshCmp', event.detail.screenName);
        const valueSelectedEvent = new CustomEvent('refreshmenucmp', {
            detail: {
                loanId: event.detail.loanId, 
                screenName: event.detail.screenName
            }
        });
        this.dispatchEvent(valueSelectedEvent);
    }
    //HL-Ishi
    getGeolocationAndProceed(){
        getLocationSettings()
            .then(result => {
                console.log('response=: get Location Settings:' + JSON.stringify(result));	
                if(!result.Location_Required__c){
                    this.initiateAPIRequestForAadharConsent(result.Latitude__c, result.Longitude__c);
                } else {
                    if (navigator.geolocation) {
                        console.log('result-----2838-1 - geolocation');
                            navigator.geolocation.getCurrentPosition(position => {
                                const latitude = position.coords.latitude;
                                const longitude = position.coords.longitude;
                                console.log('Geolocation getting location:' + latitude + '::' + longitude);
                                this.initiateAPIRequestForAadharConsent(latitude, longitude);
                            }, error => {
                                console.error('Error getting location:');
                                console.error('Code:', error.code);
                                console.error('Message:', error.message);
                            });
                        } else {
                            console.error('Geolocation is not supported by this browser.');
                        }
                }
            })
            .catch(error => {
                console.error('Error fetching custom location settings:',  JSON.stringify(error));
            })
    }
    //Ajay
    //HL-Ishi-10-10
    
    handleamlookupselected(event) {
        this.fieldDetails.forEach(record => {
            if (record.Storage_Field__c == 'Sourcing_Manager__r.Name') {
                record.savedName = event.detail.searchRecord.Name;
                record.value = event.detail.searchRecord.Id;
            }
        })
    }
    handleamlookupdeselected(event) {
        this.fieldDetails.forEach(record => {
            if (record.Storage_Field__c == 'Sourcing_Manager__r.Name') {
                record.value = '';
                record.savedName = '';
            }
        })
    }
    //HL-Ishi-10-10
     getProductDetails(){
        console.log('1528'+this.loanId);
          console.log('1528'+this.recordId);
        const inputMap = {
            'oppId': this.recordId
        }
        console.log('1528'+this.loanId);
        getProductDetails({inputMap: inputMap})
        
        .then(response => {
             console.log('response'+response);
            this.product = response.loanProduct;
            console.log('Product Details: '+JSON.stringify(this.product));
            if(this.product == 'Home Loan'||this.product=='Non Home Loan'||this.product=='Flexi Loan' ||this.product=='Affordable Home Loan'){
                this.showHLRelatedData = true;
            }
        })
        .catch(error => {
            console.log(error);
        });
    }
    //  _formIdentifier;

    //     @api
    //     get formIdentifier() {
    //         return this._formIdentifier;
    //     }
    //     set formIdentifier(value) {
    //     this._formIdentifier = value ? value : 'Loan Login Form';
    //     console.log('Final formIdentifier:', this._formIdentifier);
    //             this.getScreenDetailsFromApex();
    //     }

    //change by Vedant for SFHL-1564 - start
    handleDisabilityDependency(disabilityValue) {
        console.log('Inside disability dependency');

        const disabilityPercentField = this.fieldDetails.find(item => item.Storage_Field__c === 'Disability_Percent__c');
        if (!disabilityPercentField) {
            console.log('Disability Percent field not found');
            return;
        }
        const normalizedValue = disabilityValue ? disabilityValue.trim().toLowerCase(): '';
        const isRequired = normalizedValue && normalizedValue !== 'not applicable';
        console.log('isRequired -->', isRequired);
        disabilityPercentField.Is_Mandatory__c = isRequired;
        disabilityPercentField.hideField = !isRequired;
        if (!isRequired) {
            disabilityPercentField.value = null;
            setTimeout(() => {
                const inputCmp = this.template.querySelector(
                    `[data-name="Disability_Percent__c"]`
                );
                if (inputCmp) {
                    inputCmp.value = null;
                    inputCmp.required = false;
                    inputCmp.setCustomValidity('');
                    inputCmp.reportValidity();
                }
            }, 0);
        }
    }
    //change by Vedant for SFHL-1564 - end
}