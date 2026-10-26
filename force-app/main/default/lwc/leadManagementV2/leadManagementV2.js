import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from "lightning/uiRecordApi";
import Customer_Type from '@salesforce/schema/Lead.Customer_Type__c';
import Customer_PROFILFE from '@salesforce/schema/Lead.Employment_Type__c';
// import bindustry from '@salesforce/schema/Lead.Industry';
import btype from '@salesforce/schema/Lead.Business_Type__c';
import Channel from '@salesforce/schema/Lead.Channel__c';
import Lead_OBJECT from "@salesforce/schema/Lead";
import PRODUCTMASTER_OBJECT from "@salesforce/schema/Product_Master__c";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import FORM_FACTOR from '@salesforce/client/formFactor';
import createLead from '@salesforce/apex/Comm_LeadManagementController.createLead';
import getExistingLoanDetails from '@salesforce/apex/GetExistingLoanDetailsController.getExistingLoanDetails';
import checkLoanApplicationInSFDC from '@salesforce/apex/COMM_SalesLoanLoginTopUpFlowController.checkLoanApplicationInSFDC';
// import Product from '@salesforce/schema/Lead.Product__c';
import Product_Name from '@salesforce/schema/Product_Master__c.Product_Name__c';
import getreferenceLead from '@salesforce/apex/Comm_LeadUtility.getreferenceLead';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getNumberToWord from '@salesforce/apex/Comm_LeadManagementController.getNumberToWord';
import getreferenceLeadforPan from '@salesforce/apex/Comm_LeadUtility.getreferenceLeadforPan';
import getreferenceLeadname from '@salesforce/apex/Comm_LeadManagementController.getLeadNumber';
import { NavigationMixin } from 'lightning/navigation';
import fetchleaddetails from '@salesforce/apex/Comm_LeadManagementController.fetchLeadDetails';
import fetchDSAContact from '@salesforce/apex/Comm_LeadManagementController.fetchDSAContact';
import fetchUserProfile from '@salesforce/apex/Utility.getCurrentUserProfileName';
import gender from '@salesforce/schema/Lead.GenderIdentity';
// import busiVintage from '@salesforce/schema/Lead.Business_Vintage__c';
import turnoveryearly from '@salesforce/schema/Lead.Turnover_Yearly__c';
import purposeOfLoan from '@salesforce/schema/Lead.COMM_Purpose_of_Loan__c';
import campaignCode from '@salesforce/schema/Lead.COMM_Campaign_Code__c';
import offowner from '@salesforce/schema/Lead.Office_Ownership__c';
import checkImageUploaded from '@salesforce/apex/Comm_LeadManagementController.checkImageUploaded';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
// import callDedupeApi  from '@salesforce/apex/Utility.callDedupeApi'; 
import closeLead from '@salesforce/apex/Comm_LeadManagementController.closeLead';
import { fireEvent } from 'c/pubsub';
import evaluateLeadConditions from '@salesforce/apex/Comm_LeadUtility.evaluateLeadConditions';
import createLoanFromLead from '@salesforce/apex/Comm_LeadToLoanConversionController.createLoanFromLead';
import getConstants from '@salesforce/apex/Comm_LeadManagementController.getConstants';
import checkSFDedupe from '@salesforce/apex/COMM_SalesLoanActionsController.checkSFDedupe';
import createLoanAndAppDet from '@salesforce/apex/COMM_SalesLoanActionsController.createLoanAndAppDet';
import checkMNRL from '@salesforce/apex/COMM_MNRLController.initiateAPIRequest';
import maybeStampDSAAM from '@salesforce/apex/Comm_LeadManagementController.maybeStampDSAAM';
import getCustomPermissionsByUserId from '@salesforce/apex/Comm_LeadManagementController.getCustomPermissionsByUserId';
// import getProductMasterPicklist from '@salesforce/apex/Sales_LoginProductDetailsController.getProductMasterPicklist';
import { panNumberValidation, validateNonIndividualPAN, textValidation } from 'c/utility';
import createLoanFromLeadFL from '@salesforce/apex/Comm_LeadToLoanConversionController.createLoanFromLeadFL';
import createRelatedRecords from '@salesforce/apex/COMM_SalesLoanLoginTopUpFlowController.createRelatedRecords'
import cloneLoanApplicationFL from '@salesforce/apex/Comm_LeadToLoanConversionController.cloneLoanApplicationFL';
import checkIfLoggedInUserIsHLRelated from '@salesforce/apex/Utility_V1.checkIfLoggedInUserIsHLRelated';
import submitForApproval from '@salesforce/apex/Comm_LeadManagementController.submitForApproval';
import USER_ID from '@salesforce/user/Id';


export default class LeadManagementV2 extends NavigationMixin(LightningElement) {

    headerTitle = 'Enter Lead Information​';
    @api recordId;
    @track leadRecordTypeId;
    permissions = [];
    disableNameAndCode = false;
    contactName;
    fillfirstinformation = true;
    fillsecondinformation = false;
    fillthirdinformation = false;
    /* ____GenAI: default landing screen for the Basic Information step - shows
       the AI Sales Insight child card in place of the Collect Basic Information
       fields/buttons until the user explicitly clicks the "Basic Information"
       step in the left progress stepper. Does not touch any existing
       fillfirstinformation/fillsecondinformation/etc. flow logic____ */
    showAiInsight = true;
    isMobile = false;
    inputValue = null;
    inputValue2 = null;
    no;
    showdob = true;
    leadNameIfAny;
    leadname;
    visibilerecord = false;
    pincodecheck = false;
    pinandmobileId;
    newLeadId;
    isShownewModal = false;
    isShowModal;
    showBox = false;
    assignedRo;
    showmob = false;
    buttonval = 'Continue';
    customerTypeOptions;
    customerType;

    @track custProfileOptions = [];
    @track custProfileOptionsActual = [];
    @track custProfileOptionsController = [];
    custProfile;
    @track rawProductPicklistOptions = [];
    @track Product_TypelistOptions = [];
    selectedProductType;
    BL = false;
    shownewbox = false;
    dateOfBirth;
    dateofInc;
    panno;
    showfields = true;
    selectedTehsil;
    selectedTown;
    isLoading = false;
    checklAmt = false;
    shownext = false;
    showprev = false;
    bindustryvalues;
    dispositionlost = false;
    showindi = false;
    shownonindi = false;
    middlename;
    profile;
    closed = false;
    pinno;
    showverif = true;
    pinLength;
    entityname;
    pinval;
    postOffice;
    district;
    showLead = false;
    loanamtinwords;
    leadinwords;
    createdleadName;
    bindustval = '';
    bvintage;
    otptrue = true;
    showelig = true;
    isDesktop = false;
    isMobile = false;
    showRefreshed = false;
    uprofile;
    @track _selectedchannelTypeValue;
    @track disableChannel = false;
    get selectedchannelTypeValue() {
        return this._selectedchannelTypeValue;
    }
    set selectedchannelTypeValue(val) {
        this._selectedchannelTypeValue = val;
        if ((val || '').trim().toLowerCase() === 'csc' || (val || '').trim().toLowerCase() === 'online') {
            this.disableChannel = true;
        } else {
            this.disableChannel = false;
        }
    }
    channelDisabled = false;
    Channel_typeListOptions;
    genderOptions;
    fromChannelChange;
    leadGender;
    offowneroptions;
    businessTypeOptions;
    emailno;
    offownerval;
    reqimagesUploaded = false;
    fillfourthinformation = false;
    loantypeClosed = false;
    CustProfileDisabled = false;
    disablefirstName = false;
    disablepincode = false;
    productDisabled = false;
    disableExternalFields = false;
    isOnlineDisable = false;
    disableLeadType = false;
    hideNameAndCode = false;
    showCampaignCode = false;
    disableEmail = false;
    loanamtClosed = false;
    showLoanAmtMessage = false;
    loanamt;
    btypeval;
    stage;
    leadId;
    hideNextButton = false;
    canClose = true;
    mobVerified = false;
    nameValue;
    codeValue;
    campValue;
    @track currPage = 1;
    servicable = true;
    customerName;
    dedupemob;
    dedupepan;
    showConsent = false;
    softdedupe = false;
    dedupeId;
    showpincode = false;
    pincodeDisabled = false;
    isOnlineLead = false;
    disableMiddleName = false;
    disableLastName = false;
    disableMobile = false;
    actCust;
    datedisabled = false;
    telesales = false;
    @track salesexecutive = false;
    @track systemAdmin = false
    dsa = false;
    btpevalue;
    checkEligibilityButton = 'Continue';
    pincodeFilled = false;
    pincodename;
    @track channelvaluesRo = [];
    responsive = true;
    qualdis = false;
    isHotWarm = false;
    qualified = false;
    showSource = false;
    leadSource;
    ntbScreen = false;
    disablePurposeOfLoan = false;
    disableGeneratorNTB = false;
    bvintagevalues;
    turnoverValues;
    purposeOfLoanValue;
    purposeOfLoan;
    campaignCodeValues;
    disableChannel = false;
    @track showdsaName = false;
    @track showConnectorName = false;
    @track dsaname;
    showareaManager = true;
    _overflowPatched = false;
    arm;
    armtrue = true;
    branchfalse = false;
    channelValuesGroup1;
    channelValuesGroup2
    armName;
    @track dsaId;
    converted = false;
    others = false;
    constants;
    showCustProfile = false;
    siteUser = false;
    fillseventhInformations = false;
    closedReason;
    @track showConfirmationPopup = false;
    confirmationMessage;
    newLoanId;
    newState;
    showBusinessType = false;
    statusNotAccepted = true;
    leadNotAssigned = true;
    showPan = false;
    inputLabel = 'Constitution';
    originalBranchId = null;
    currentBranchId = null;
    hasHLPermission = false;
    //HL-Ishi-31/10
    callTopUpCmp = false
    dobordoi;
    selectedCustId;
    referenceNumber;
    loanSource;
    @track customerFinanceDetailList = [];
    parentLoanNumberFL;
    sourceSystemFL;
    pageRef;
    isExternalLeadsPage = false;
    subProduct;
    alternateMobile;
    cityValue;
    stateValue;
    //HL-Ishi-31/10
    //returnHome = returnHome;
    //close = 'previous'
    //vfdone;
    //isSaveButtonDisabled;
    // showverify = false;
    // optverif = false;
    //verif;
    //showOtherfields = false;
    //@track isShowcode = false;
    //objectInfo;
    //otpTimeout = 60000;
    //showLoginButton = false;
    //customerInterest;
    //@track countdown;
    //@track shownonresend = true;
    //resend = false;
    //showimage = false;
    //@track countdown;
    //@track showTimer = false;
    //timer;
    //showbuttons = true;
    //@track timerValue = '00';
    // get interestOptions() {
    //     return [
    //         { label: 'Yes', value: 'Yes' },
    //         { label: 'No', value: 'No' }
    //     ];
    // }
    //reset = 'Resend Link';
    //addDocuments = false;
    //showConfirmation = false;
    //deleteDocId;
    //confirmMessage = 'Are you sure you want to delete this document?'
    //imageSrc;
    //dontEditLeadGen = false;
    //tempEmpId;
    //empname;
    //leadGeneratorUserId;
    //leadGeneratorEmpId;
    // filter=" and Profile.Name = 'FCU Agent'"
    @track customerTypeOptions = [];
    @track picklistOptions = [
        { label: 'Option 1', value: 'option1' },
        { label: 'Option 2', value: 'option2' },
        { label: 'Option 3', value: 'option3' },
        { label: 'Option 4', value: 'option4' },
        { label: 'Option 5', value: 'option5' },
        { label: 'Option 6', value: 'option6' },
        { label: 'Option 7', value: 'option7' },
        { label: 'Option 8', value: 'option8' },
        { label: 'Option 9', value: 'option9' },
        { label: 'Option 10', value: 'option10' },
    ];
    @track productList = [
        { label: 'Home Loan', value: 'Home Loan' },
        { label: 'Flexi Loan', value: 'Flexi Loan' },
    ]
    // @track custProfileOptions = [];
    selectedCustomerType;
    dependentOptions = [];
    isHLUser = false;
    isApprovalPending = false;
    //LAP
    hasLAPPermissions = false;
    //LAP

    isDirectLike(channel) {
        return channel === 'Direct' || channel === 'Default';
    }
    @wire(CurrentPageReference)
    wiredCurrentPageReference(value) {
        this.pageRef = value;
        this.setExternalLeadsPageContext();
    }

    get showExternalOnlineFields() {
        return this.isExternalLeadsPage || (this.selectedchannelTypeValue || '').trim().toLowerCase() === 'online';
    }

    get showBusinessVintage() {
        const emp = (this.custProfile || '').trim().toUpperCase();
        return emp === 'SENP' || emp === 'SEP';
    }

    // Disable new external fields only when assigned AND the field already has a value
    get disableSubProductField() { return this.disableExternalFields && (!this.isOnlineDisable || !!this.subProduct); }
    get disableAlternateMobileField() { return this.disableExternalFields && (!this.isOnlineDisable || !!this.alternateMobile); }
    get disablePanField() { return this.disableExternalFields && (!this.isOnlineDisable || !!this.panno); }
    get disableCityField() { return this.disableExternalFields && (!this.isOnlineDisable || !!this.cityValue); }
    get disableStateField() { return this.disableExternalFields && (!this.isOnlineDisable || !!this.stateValue); }
    get disableBvintageField() { return this.disableExternalFields && (!this.isOnlineDisable || !!this.bvintage); }
    get disableGenderField() { return this.disableExternalFields && (!this.isOnlineDisable || !!this.leadGender); }
    get disableOffOwnerField() { return this.disableExternalFields && (!this.isOnlineDisable || !!this.offownerval); }
    get disableTurnoverField() { return this.disableExternalFields && (!this.isOnlineDisable || !!this.turnover); }

    // Existing fields: for Online only disable if field has value; otherwise use raw flag
    get disableProductField() { return this.productDisabled && (!this.isOnlineDisable || !!this.selectedProductType); }
    get disableCustomerTypeField() { return this.loantypeClosed && (!this.isOnlineDisable || !!this.customerType); }
    get disableCustProfileField() { return this.CustProfileDisabled && (!this.isOnlineDisable || !!this.custProfile); }
    get disableFirstNameField() { return this.disablefirstName && (!this.isOnlineDisable || !!this.inputValue); }
    get disableMiddleNameField() { return this.disableMiddleName && (!this.isOnlineDisable || !!this.middlename); }
    get disableLastNameField() { return this.disableLastName && (!this.isOnlineDisable || !!this.inputValue2); }
    get disableEntityNameField() { return this.disablefirstName && (!this.isOnlineDisable || !!this.entityname); }
    get disableContactNameField() { return this.disablefirstName && (!this.isOnlineDisable || !!this.contactName); }
    get disableDobField() { return this.datedisabled && (!this.isOnlineDisable || !!this.dateOfBirth); }
    get disableDoiField() { return this.datedisabled && (!this.isOnlineDisable || !!this.dateofInc); }
    get disableLoanAmtField() { return this.loanamtClosed && (!this.isOnlineDisable || !!this.loanamt); }
    get disablePincodeField() { return this.pincodeDisabled && (!this.isOnlineDisable || !!this.pinno); }
    get disableEmailField() { return this.disableEmail && (!this.isOnlineDisable || !!this.emailno); }
    get disableBusinessTypeField() { return this.showmob && (!this.isOnlineDisable || !!this.btpevalue); }
    get disablePurposeOfLoanField() { return this.showmob && (!this.isOnlineDisable || !!this.purposeOfLoan); }
    get disableChannelField() { return this.disableChannel && (!this.isOnlineDisable || !!this.selectedchannelTypeValue); }
    get disableCampaignCodeField() { return this.showmob && (!this.isOnlineDisable || !!this.campValue); }
    get disableDsaField() { return this.disableGeneratorNTB && (!this.isOnlineDisable || !!this.dsaId); }
    get disableNameField() { return this.disableNameAndCode && (!this.isOnlineDisable || !!this.nameValue); }
    get disableCodeField() { return this.disableNameAndCode && (!this.isOnlineDisable || !!this.codeValue); }
    get disableLeadTypeField() { return this.disableLeadType; }

    @track nameCodeLabelMap = {
        'Connector': {
            nameLabel: 'Connector Name​',
            codeLabel: 'Connector Code​'
        },
        'Employee Referral': {
            nameLabel: 'Employee Name​',
            codeLabel: 'Employee ID'
        },
        'Customer Referral': {
            nameLabel: 'Customer Name​',
            codeLabel: 'Cust ID​​'
        },
        'Campaign': {
            nameLabel: 'Campaign Name',
            codeLabel: 'Campaign Code'
        },
        'DSA': {
            nameLabel: 'DSA Name ​',
            codeLabel: 'DSA Code​'
        },
        'Corporate DSA': {
            nameLabel: 'Corporate DSA Name ​',
            codeLabel: 'Corporate DSA Code​'
        },
        'Default': {
            nameLabel: 'Connector Name ​',
            codeLabel: 'Connector Code​'
        },

    }

    @wire(getObjectInfo, { objectApiName: Lead_OBJECT })
    objectInfo;

    @wire(getObjectInfo, { objectApiName: PRODUCTMASTER_OBJECT })
    productMasterObjectInfo;

    @wire(getRecord, { recordId: '$leadId', fields: ['Lead.RecordTypeId'] })
    wiredLead({ data, error }) {
        console.log('wiredLead data:', JSON.stringify(data));
        if (data) {
            let recordTypeId = null;
            if (data.fields && data.fields.RecordTypeId && data.fields.RecordTypeId.value) {
                recordTypeId = data.fields.RecordTypeId.value;
            } else if (data.recordTypeId) {
                recordTypeId = data.recordTypeId;
                console.log('Falling back to data.recordTypeId:', recordTypeId);
            }
            this.leadRecordTypeId = recordTypeId;
            console.log('leadRecordTypeId>>', this.leadRecordTypeId);
            console.log('leadId>>', this.leadId);
        } else {
            this.leadRecordTypeId = null;
            console.log('RecordTypeId not found or is null in wire result. Full data:', JSON.stringify(data));
        }
        if (error) {
            console.log('wiredLead error:', error);
        }
    }
    @wire(getCustomPermissionsByUserId, {})
    wiredPermissions({ error, data }) {
        if (data) {
            this.permissions = data;
            console.log('this.permissions', this.permissions);
            console.log('this.selectedProductType', this.selectedProductType);
            const hasHLPermission = this.permissions.some(permission => permission.includes('HL'));
            const hasLAPPermission = this.permissions.some(permission => permission.includes('LAP'));
            this.hasHLPermission = hasHLPermission;
            this.hasLAPPermissions = hasLAPPermission;
            console.log('hasHLPermission', hasHLPermission);
            if (this.hasHLPermission) {
                console.log('this.selectedProductType', this.selectedProductType);
                if (this.selectedProductType == undefined || this.selectedProductType == null || this.selectedProductType == '') {
                    this.selectedProductType = 'Home Loan';
                    console.log('this.selectedProductType', this.selectedProductType);
                }
            }
            else if (this.hasLAPPermissions) {
                console.log('this.selectedProductType', this.selectedProductType);
                if (this.selectedProductType == undefined || this.selectedProductType == null || this.selectedProductType == '') {
                    this.selectedProductType = 'Non Home Loan';
                    console.log('this.selectedProductType', this.selectedProductType);
                }
            }
            else {
                if (this.selectedProductType == undefined || this.selectedProductType == null || this.selectedProductType == '') {
                    this.selectedProductType = 'Home Loan';
                }
            }
        } else if (error) {
            console.error('Error fetching permissions:', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: Customer_Type })
    byHandF8ieldInfo({ data, error }) {
        if (data) {
            console.log('Full data object: ', JSON.stringify(data));
            this.customerTypeOptions = data.values;
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: Customer_PROFILFE })
    byHandF878ieldInfo({ data, error }) {

        if (data) {
            console.log('Full data object: ', JSON.stringify(data));
            console.log('inside data custProfile');
            console.log('custProfile>>', this.custProfile);
            console.log('cust profile>>' + sessionStorage.getItem('custProfile'));
            console.log('data.values=:' + JSON.stringify(data.values));
            this.custProfileOptionsActual = data.values;
            this.custProfileOptionsController = data.controllerValues;
            console.log('custProfileOptionsActual  ' + this.custProfileOptionsActual);

        } else {
            console.error('Error fetching picklist values:', JSON.stringify(error));
            console.log('custProfileOptionsActual Error --> ' + error);
        }


    }



    @wire(getPicklistValues, { recordTypeId: '$productMasterObjectInfo.data.defaultRecordTypeId', fieldApiName: Product_Name })
    getProductValues({ data, error }) {
        if (data) {
            console.log('data.values412' + JSON.stringify(data.values));
            this.rawProductPicklistOptions = data.values;
            this.Product_TypelistOptions = this.rawProductPicklistOptions;
            console.log('this.hasHLPermission', this.hasHLPermission);
            console.log('1205 rawProductPicklistOptions  ' + JSON.stringify(this.rawProductPicklistOptions));
            if (this.permissions.length > 0) {
                this.filterProductOptions();

            }
        }
        if (error) {
            console.log('error-->', error);
        }
    }

    /*  @wire(getPicklistValues, { recordTypeId:'$objectInfo.data.defaultRecordTypeId', fieldApiName: bindustry })
      getBusinessIndustryValues({ data, error }) {
          if(data) {
             
              this.bindustryvalues = data.values;
          }
      }
  
      @wire(getPicklistValues, {recordTypeId:'$objectInfo.data.defaultRecordTypeId', fieldApiName: gender})
      byHand20FieldInfo({ data, error }) {
          if(data) {
              this.genderOptions = data.values;
          }
      }
  
      @wire(getPicklistValues, {recordTypeId:'$objectInfo.data.defaultRecordTypeId', fieldApiName: offowner})
      byHand21FieldInfo({ data, error }) {
          if(data) {
              this.offowneroptions = data.values;
          }
      }*/

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: btype })
    byHand22FieldInfo({ data, error }) {
        if (data) {
            console.log('Inside wire btype>>', JSON.stringify(data));
            console.log('cust profile>>' + sessionStorage.getItem('custProfile'));
            this.btypeval = data.values;
            this.controllerValues = data.controllerValues;
            const key = this.controllerValues[sessionStorage.getItem('custProfile')];
            console.log('key##', key);
            const filteredOptions = this.btypeval.filter(opt => opt.validFor.includes(key))
                .map(opt => ({ label: opt.label, value: opt.value }));
            this.businessTypeOptions = [...filteredOptions];
            //this
            console.log('this.businessTypeOptions##', JSON.stringify(this.businessTypeOptions));
            this.btypevalue = undefined;
            console.log('Business Type values>>', this.btypeval);
            console.log('controllerValues>>', this.controllerValues);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: campaignCode })
    byHand29FieldInfo({ data, error }) {
        if (data) {
            this.campaignCodeValues = data.values;
            //this.purposeOfLoanValue = data.values;
            console.log('Campaign values>>', this.campaignCodeValues);
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$leadRecordTypeId', fieldApiName: purposeOfLoan })
    byHand30FieldInfo({ data, error }) {
        if (data) {
            //this.campaignCodeValues = data.values;
            this.purposeOfLoanValue = data.values;
            console.log('purposeOfLoanValue>>', this.purposeOfLoanValue);
            console.log('recordtype>>', this.objectInfo.data.defaultRecordTypeId);
        }
    }

    get showDsaConnectorSection() {
        return this.salesexecutive || this.systemAdmin;
    }

    get showChannelInputs() {
        return !this.dsa && !['DSA', 'Corporate DSA', 'Connector', 'CSC', 'Online'].includes(this.selectedchannelTypeValue) && !this.isDirectLike(this.selectedchannelTypeValue);
    }
    get showCreateLoanButton() {
        console.log('statusNotAccepted', this.statusNotAccepted);
        console.log('this.leadNotAssigned', this.leadNotAssigned);
        console.log('this.statusNotAccepted || this.isLeadAssigned', this.statusNotAccepted && this.leadNotAssigned);
        console.log('salesexecutive', this.salesexecutive && this.statusNotAccepted);
        console.log('converted', this.converted);
        console.log('salesexecutive>', this.salesexecutive);
        console.log('status not accepted>', this.statusNotAccepted);
        if (this.salesexecutive) {
            return this.salesexecutive && (this.statusNotAccepted || this.converted || this.leadNotAssigned);
        } else {
            console.log('status not accepted>', this.statusNotAccepted);
            console.log('lead not assigned>', this.leadNotAssigned);
            console.log('converted>', this.converted);
            return this.statusNotAccepted || this.leadNotAssigned || this.converted;
        }
    }
    get showHot() {
        return !this.qualified && this.responsive;
    }

    /* ____GenAI: distinguishes the Lead record page (where this component is
       auto-navigated to with a "standard__recordPage" page reference) from
       the Lightning Tab placement (page reference type "standard__navItemPage").
       The AI Sales Insight default-landing behavior below only applies on the
       record page - on the Tab it is not used, so the Tab keeps rendering the
       Collect Basic Information form exactly as it always has____ */
    get isRecordPageContext() {
        return this.pageRef?.type === 'standard__recordPage';
    }

    /* ____GenAI: default landing view when this component is hosted on the Lead
       record page - shows regardless of which internal step flag
       (fillfirstinformation/fillsecondinformation/fillthirdinformation/etc.)
       is currently active, so it also covers EXISTING leads that resume on a
       later step. On the Lightning Tab placement this stays false so the
       Tab's flow is completely unaffected. True only until the user clicks
       the "Basic Information" step in the left progress stepper. Used purely
       to swap the display between the AI Sales Insight child card and the
       existing header/lead-stage-path/step content - does not alter
       fillfirstinformation or any other flow flag____ */
    get showAiInsightScreen() {
        return this.isRecordPageContext && this.showAiInsight;
    }

    /* ____GenAI: adds a modifier class to the outer lead-main-panel container
       only while the AI Sales Insight card is the active view, so its outer
       purple border/glow can be removed for that view alone via CSS. Every
       other screen (Basic Detail form, Additional Details, etc.) keeps the
       exact same base classes/styling as before - no existing styling or
       markup for those screens is altered____ */
    get leadMainPanelClass() {
        return 'form-container border-field lead-main-panel' + (this.showAiInsightScreen ? ' lmv2-ai-insight-active' : '');
    }

    /* ____GenAI: click handler for the left progress stepper items - clicking
       any step (Basic Information / Additional Information / Lead To Loan
       Conversion) now always navigates directly to that step's section,
       regardless of which step is currently active. Also dismisses the AI
       Sales Insight card if it is showing. No existing save/continue/
       previous button logic is touched - this only changes which section
       flag is toggled on stepper click____ */
    handleStepClick(event) {
        const stepNumber = parseInt(event.currentTarget.dataset.step, 10);
        if (this.showAiInsight) {
            this.showAiInsight = false;
        }
        if (stepNumber === 1) {
            this.fillfirstinformation = true;
            this.fillsecondinformation = false;
            this.fillthirdinformation = false;
            this.fillfourthinformation = false;
            this.fillseventhInformations = false;
        } else if (stepNumber === 2) {
            this.fillfirstinformation = false;
            this.fillsecondinformation = true;
            this.fillthirdinformation = false;
            this.fillfourthinformation = false;
            this.fillseventhInformations = false;
        } else if (stepNumber === 3) {
            this.fillfirstinformation = false;
            this.fillsecondinformation = false;
            this.fillthirdinformation = true;
            this.fillfourthinformation = false;
            this.fillseventhInformations = false;
        }
    }

    /* ____GenAI: added for vertical progress stepper UI - does not affect existing logic____ */
    get progressSteps() {
        const steps = [
            { number: 1, title: 'Basic Information', description: 'Capture essential customer and application details.', isActive: this.fillfirstinformation },
            { number: 2, title: 'Additional Information', description: 'Collect additional details required for assessment and processing.', isActive: this.fillsecondinformation },
            // { number: 3, title: 'Assessment Outcome', description: 'Review eligibility and determine the assessment outcome.', isActive: this.fillthirdinformation },
            // { number: 4, title: 'Customer Consent Request', description: 'Send the consent request and track customer consent completion.', isActive: this.fillfourthinformation },
            { number: 3, title: 'Lead To Loan Conversion', description: 'Complete the final process to convert the lead into a loan.', isActive: this.fillthirdinformation }
        ];
        let currentIndex = steps.findIndex((s) => s.isActive);
        if (currentIndex === -1) {
            currentIndex = 0;
        }
        return steps.map((s, idx) => {
            let state = 'pending';
            if (idx < currentIndex) {
                state = 'completed';
            } else if (idx === currentIndex) {
                state = 'active';
            }
            return {
                key: 'lmv2step' + s.number,
                number: s.number,
                title: s.title,
                description: s.description,
                circleClass: 'lmv2-step-circle lmv2-step-circle_' + state,
                titleClass: 'lmv2-step-title lmv2-step-title_' + state,
                connectorClass: idx < steps.length - 1 ? 'lmv2-step-connector lmv2-step-connector_' + (idx < currentIndex ? 'completed' : 'pending') : 'lmv2-step-connector lmv2-step-connector_hidden'
            };
        });
    }
    /* ____GenAI: end added block____ */

    checkIfLoggedInUserIsHLRelated() {
        checkIfLoggedInUserIsHLRelated()
            .then(result => {
                this.isHLUser = result.isHLRelated;
                console.log(' this.isHLUser>>>' + this.isHLUser);
            })
            .catch(error => {
                console.log('error-->', error);
            })
    }

    async connectedCallback() {
        this.checkIfLoggedInUserIsHLRelated();
        this.setExternalLeadsPageContext();
        if (this.selectedProductType === null || this.selectedProductType === undefined || this.selectedProductType === '') {
            this.initializeComponent();
        }
        if (this.permissions.length > 0 && this.rawProductPicklistOptions.length > 0) {
            this.filterProductOptions();
        }
        if (window.location.origin.includes('my.site.com')) {
            console.log('350');
            const pathParts = window.location.pathname.split('/');
            const maybeId = pathParts.find(part => part.startsWith('00Q')); // Assuming you're dealing with Leads
            if (maybeId) {
                this.recordId = maybeId;
                console.log('Parsed Record Id:', this.recordId);
            }
        }
        var detail = {};
        detail["isPullToRefreshEnabled"] = false;
        var updateScrollSettingsEvent = new CustomEvent("updateScrollSettings", {
            detail: detail,
            bubbles: true,
            composed: true
        });

        dispatchEvent(updateScrollSettingsEvent);
        this.template.addEventListener('focus', this.disableManualEntry.bind(this), true);
        console.log('The device form factor is: ' + FORM_FACTOR);
        if (FORM_FACTOR === "Large") {
            this.isDesktop = true;
        }
        else {
            this.isMobile = true;
        }

        if (this.selectedProductType == 'Business Loan') {
            this.BL = true;
        }
        else {
            this.BL = false;
        }

        await this.getConstantsData();
        if (window.location.origin.includes('my.site.com')) {
            this.siteUser = true;
        }
        else {
            this.siteUser = false;
        }

        if (this.recordId) {
            console.log('209');
            this.visibilerecord = true;
            this.shownext = true;
            this.hideNextButton = true;
            this.leaddetails();
            this.leadId = this.recordId;
            this.ntbScreen = true;
        }
        else {
            this.showpincode = true;
            console.log('215');
            this.visibilerecord = false;
            this.leadId = this.newLeadId;

            // Auto populate mobile number for new lead
            this.no = '9877654890';
}

        registerListener("closeLead", this.updateleaddetails, this);
        registerListener("handleRefreshDocument", this.getDoccheckImageUploadedstatus, this);
        registerListener('leadAssignmentStatus', this.handleAssignmentStatus, this);

        fetchUserProfile({})
            .then(result => {
                this.uprofile = result;
                console.log('User Profile: ', this.uprofile);
                console.log('Constants: ', this.constants);
                console.log('standard user profile>' + this.constants.Standard_User_Profile);
                if (this.uprofile == 'System Administrator') {
                    this.systemAdmin = true
                }
                switch (this.uprofile) {
                    case this.constants.Tele_Sales_User_Profile: //CASE 1>>
                    case this.constants.Tele_Sales_Manager_Profile: //CASE 1b>>
                        this.telesales = true;
                        this.salesexecutive = false;
                        this.dsa = false;
                        console.log('this.visibilerecord', this.visibilerecord);
                        if (this.visibilerecord) {
                            this.leaddetails();
                        }
                        else {
                            console.log('this.selectedchannelTypeValue', this.selectedchannelTypeValue);
                            if (this.selectedchannelTypeValue == 'DSA' || this.selectedchannelTypeValue == 'Corporate DSA') {
                                this.getDSADetails();
                                this.showdsaName = true;
                            }
                            this.hideNameAndCode = true;
                        }
                        break;
                    case this.constants.Standard_User_Profile: //CASE 2
                        console.log('348');
                        this.telesales = false;
                        this.salesexecutive = true;
                        this.dsa = false;
                        this.disableChannel = false;
                        const allowedLabelsRm = ['Default', 'Direct', 'DSA', 'Corporate DSA', 'Connector', 'Employee Referral', 'Customer Referral', 'Campaign'];
                        this.channelvaluesRo = this.salesexecutive ? this.channelvaluesRo.filter(item => allowedLabelsRm.includes(item.label)) : this.channelvaluesRo;
                        if (this.selectedchannelTypeValue == 'DSA' || this.selectedchannelTypeValue == 'Corporate DSA') {
                            this.getDSADetails();
                            this.showdsaName = true;
                        }
                        if (this.visibilerecord) {
                            console.log('354');
                            this.salesexecutive = true;
                            this.telesales = false;
                            this.dsa = false;
                            this.leaddetails();
                        }
                        else if (!this.visibilerecord) {
                            console.log('this.selectedchannelTypeValue', this.selectedchannelTypeValue);
                            this.hideNameAndCode = this.isDirectLike(this.selectedchannelTypeValue);
                        }
                        break;
                    case this.constants.Partner_Community_User_Profile: //CASE 3
                        this.telesales = false;
                        this.salesexecutive = false;
                        console.log('before DSA cond.>>');
                        this.dsa = true;
                        console.log('after dsa cond>' + this.dsa);
                        //  this.selectedchannelTypeValue = 'DSA';
                        this.hideNameAndCode = false;
                        const allowedLabels = ['DSA', 'Corporate DSA'];
                        this.channelvaluesRo = this.dsa ? this.channelvaluesRo.filter(item => allowedLabels.includes(item.label)) : this.channelvaluesRo;
                        this.disableNameAndCode = true;
                        this.getDSADetails();
                        break;
                    default:
                        console.log('this.selectedchannelTypeValue inside default', this.selectedchannelTypeValue);
                        if (this.selectedchannelTypeValue == '' && this.selectedchannelTypeValue == null && this.selectedchannelTypeValue == undefined) {
                            // this.selectedchannelTypeValue = 'Direct';
                            this.hideNameAndCode = true;
                        }
                        this.others = true;
                        if (this.systemAdmin) {
                            this.salesexecutive = true;
                            if (this.selectedchannelTypeValue === 'DSA' || this.selectedchannelTypeValue === 'Corporate DSA') {
                                this.showdsaName = true;
                            } else if (this.selectedchannelTypeValue === 'Connector') {
                                this.showConnectorName = true;
                            }
                            if (this.visibilerecord) {
                                this.leaddetails();
                            }
                        }
                }
            })
            .catch(error => {
                console.error('Error fetching user profile:', error);
            });
        // this.fetchProductPicklist();
    }

    setExternalLeadsPageContext() {
        try {
            const apiName = (this.pageRef?.attributes?.apiName || '').toLowerCase();
            const path = (window.location.pathname || '').toLowerCase();
            const hash = (window.location.hash || '').toLowerCase();
            this.isExternalLeadsPage = apiName.includes('external_leads_page') || path.includes('external_leads_page') || hash.includes('external_leads_page');
        } catch (e) {
            this.isExternalLeadsPage = false;
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: gender })
    byHandGenderFieldInfo({ data, error }) {
        if (data) {
            this.genderOptions = data.values;
        }
        if (error) {
            console.log('Error fetching gender picklist', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: offowner })
    byHandOwnershipFieldInfo({ data, error }) {
        if (data) {
            this.offowneroptions = data.values;
        }
        if (error) {
            console.log('Error fetching office ownership picklist', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: turnoveryearly })
    byHandTurnoverFieldInfo({ data, error }) {
        if (data) {
            this.turnoverValues = data.values;
        }
        if (error) {
            console.log('Error fetching turnover picklist', error);
        }
    }
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: Channel })
    byHandF899ieldInfo({ data, error }) {
        console.log('Inside wire>>', JSON.stringify(data));
        if (data) {
            // Assign the entire picklist values to channelvaluesRo
            console.log('values>>' + JSON.stringify(data.values));
            console.log('dsa>>', this.dsa);

            const allowedLabels = ['DSA', 'Corporate DSA'];
            let filteredValues = this.dsa ? data.values.filter(item => allowedLabels.includes(item.label)) : data.values;

            // If not Integration User, filter out CSC and Online
            if (this.uprofile !== 'Integration User') {
                filteredValues = filteredValues.filter(item => item.label !== 'CSC' && item.label !== 'Online');
            }
            this.channelvaluesRo = filteredValues;
            console.log('channel values>>' + JSON.stringify(this.channelvaluesRo));
            this.showRefreshed = this.dsa ? true : false;

            if (this.salesexecutive && !this.visibilerecord && !this.selectedchannelTypeValue) { //handling the default assignment of channel
                this.selectedchannelTypeValue = 'Direct';
                this.hideNameAndCode = true;
            }

            // Separate values into two categories based on exclusion
            console.log('showrefreshed>' + this.showRefreshed);
            this.channelValuesGroup1 = [];
            this.channelValuesGroup2 = [];

            // Iterate through the picklist values and filter accordingly
            data.values.forEach(value => {
                // Exclude 'Call Centre', 'Website', 'Digital DSA' from Group 1
                if (value.label !== 'Call Centre' && value.label !== 'Website' && value.label !== 'DSA') {
                    this.channelValuesGroup1.push(value);
                }
                // Exclude 'Call Centre', 'Website', 'Direct' from Group 2
                if (value.label !== 'Call Centre' && value.label !== 'Website' && value.label !== 'Direct') {
                    this.channelValuesGroup2.push(value);
                }
            });
            console.log('Group 1:', this.channelValuesGroup1); // Excludes Call Centre, Website, Digital DSA
            console.log('Group 2:', this.channelValuesGroup2); // Excludes Call Centre, Website, Direct
        }
    }

    initializeComponent() {
        getCustomPermissionsByUserId()
            .then((data) => {
                if (data) {
                    this.permissions = data;
                    console.log('this.permissions', this.permissions);
                    const hasHLPermission = this.permissions.some(permission => permission.includes('HL'));
                    this.hasLAPPermissions = this.permissions.some(permission => permission.includes('LAP'));
                    this.hasHLPermission = hasHLPermission;
                    console.log('this.hasHLPermission', this.hasHLPermission);
                    if (this.rawProductPicklistOptions.length > 0) {
                        this.filterProductOptions();
                    }

                } else if (error) {
                    console.error('Error fetching permissions:', error);
                }
            })
    }
    //fetchProductPicklist() {
    //getProductMasterPicklist({ recordTypeName: 'Product', productRecordSelected: null, subProductRecordSelected: null })
    //.then(result => {
    //this.Product_TypelistOptions = result.picklistOptions;
    //console.log('the product list is'+filterProductOptions);
    //})
    //.catch(error => {
    //console.error('Error fetching products:', error);
    //});
    //}


    disableManualEntry(event) {
        const inputElement = event.target;
        if (inputElement.type === 'date') {
            event.preventDefault();
        }
    }


    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    get pincodeLabel() {
        return this.hasHLPermission ? 'Residence Pincode' : 'Residence/Business Pincode';
    }

    async getConstantsData() {
        await getConstants({})
            .then(result => {
                this.constants = result;
                console.log('constants: ', this.constants);
            })
    }

    filterProductOptions() {
        console.log('Filtering product options based on HL permission', this.hasHLPermission);
        // For Tele Sales profiles viewing an existing lead, product is disabled/auto-populated — show all options as-is
        const telesalesProfiles = ['GC Tele Sales Manager', 'GC Tele Sales User'];
        if (this.visibilerecord && telesalesProfiles.includes(this.uprofile)) {
            this.Product_TypelistOptions = this.rawProductPicklistOptions;
            return;
        }
        // Treat these profiles as HL — they can see Home Loan, Non Home Loan, Flexi Loan
        const hlProfiles = ['GC Tele Sales Manager', 'GC Tele Sales User', 'System Administrator'];
        const isHLProfile = hlProfiles.includes(this.uprofile) || this.hasHLPermission;
        if (isHLProfile) {
            console.log('Inside 746');
            console.log('On line number 822 ' + JSON.stringify(this.Product_TypelistOptions));
            this.Product_TypelistOptions = this.rawProductPicklistOptions.filter(option => /*option.value !== 'Flexi Loan' && */option.value !== 'Affordable Home Loan' && option.value !== 'Affordable Non-Home Loan');
            console.log('Inside 748' + JSON.stringify(this.Product_TypelistOptions));
            console.log('Inside 749' + this.selectedProductType);
            if (this.selectedProductType === null || this.selectedProductType === undefined || this.selectedProductType === '') {
                this.selectedProductType = 'Home Loan';
                console.log('Inside 746' + this.selectedProductType);
            }
        }
        else if (this.hasLAPPermissions) {
            console.log('Inside 746');
            console.log('On line number 822 ' + JSON.stringify(this.Product_TypelistOptions));
            this.Product_TypelistOptions = this.rawProductPicklistOptions.filter(option => /*option.value !== 'Flexi Loan' && */option.value !== 'Affordable Home Loan' && option.value !== 'Affordable Non-Home Loan' && option.value !== 'Flexi Loan' && option.value !== 'Home Loan');
            console.log('Inside 748' + JSON.stringify(this.Product_TypelistOptions));
            console.log('Inside 749' + this.selectedProductType);
            if (this.selectedProductType === null || this.selectedProductType === undefined || this.selectedProductType === '') {
                this.selectedProductType = 'Non Home Loan';
                console.log('Inside 746' + this.selectedProductType);
            }
        }

        else {
            this.Product_TypelistOptions = this.rawProductPicklistOptions.filter(option => option.value !== 'Flexi Loan' && option.value !== 'Home Loan' && option.value !== 'Non Housing Home Loan');
            if (this.selectedProductType === null || this.selectedProductType === undefined || this.selectedProductType === '') {
                this.selectedProductType = 'Affordable Home Loan';
            }
        }
    }

    updateleaddetails(dogDtl) {
        console.log('when Closed');
        if (this.visibilerecord) {
            var childCompVar = this.template.querySelector('c-lead-stage-path');
            if (this.visibilerecord) {
                var sendParam = { 'recordId': this.recordId };
                childCompVar.refreshChild(sendParam);
            }
            this.canClose = false;
            this.leaddetails();
        }
        else {
            if (this.isDesktop) {
                if (this.visibilerecord) {
                    var childCompVar = this.template.querySelector('c-lead-stage-path');
                    if (this.visibilerecord) {
                        var sendParam = { 'recordId': this.recordId };
                        childCompVar.refreshChild(sendParam);
                    }
                }
                else {
                    const closevent = new CustomEvent('closelead');
                    this.dispatchEvent(closevent);
                }
            }
        }
    }

    handleInputChange1(event) {


        let firstName = event.target.value;

        event.target.value = firstName.replace(/\s+/g, '');
        this.inputValue = event.target.value;

        if (this.inputValue == '' || this.inputValue == null) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill the first name in the correct format. ',
                    variant: 'error',
                }),
            );
            return;
        }
        var checkValidity = /^[a-zA-Z\s]*$/;
        if (checkValidity.test(this.inputValue) && this.inputValue.length <= 50) {
            console.log('inputValue ' + this.inputValue);
            this.fnameval = false;
            if (this.visibilerecord) {
                if (event.target.value != undefined || event.target.value != null || event.target.value.length > 0) {
                    this.updateRecordField(this.recordId, 'FirstName', this.inputValue);
                }
            }
            else {
                if (this.newLeadId != null && this.newLeadId != '' && this.newLeadId != undefined) {
                    console.log('258 ' + this.newLeadId);
                    this.updateRecordField(this.newLeadId, 'FirstName', this.inputValue);
                }
            }
        }
        else {
            if (this.inputValue.length > 50) {
                this.inputValue = this.inputValue.slice(0, 50) + this.inputValue.slice(51); // Remove 41st character
                event.target.value = this.inputValue;
            }

            var lastIndex = this.inputValue.length - 1;
            //var thisIndex = lastIndex;
            const secondLastChar = this.inputValue[lastIndex - 1];
            console.log('Captured Second Last Character: ' + secondLastChar);
            console.log('lastIndex ' + lastIndex);
            if (lastIndex >= 0) {
                // Remove the last character from the string
                console.log('387');
                this.inputValue = this.inputValue.replace(/[^a-zA-Z\s]/g, '');
                event.target.value = this.inputValue;
                //this.inputValue = this.inputValue+secondLastChar;
            }
            console.log('this.inputValue=:' + this.inputValue);
            this.fnameval = true;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill the first name in the correct format. ',
                    variant: 'error',
                }),
            );
        }
    }

    handleInputChange2(event) {

        let lastName = event.target.value;
        event.target.value = lastName.replace(/\s+/g, '');
        this.inputValue2 = event.target.value;

        this.inputValue2 = event.target.value;
        if (this.inputValue2 == '' || this.inputValue2 == null) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill the Last name in the correct format.',
                    variant: 'error',
                }),
            );
            return;
        }

        var checkValidity = /^[a-zA-Z\s]*$/;
        if (checkValidity.test(this.inputValue2) && this.inputValue2.length <= 50) {
            this.lnameval = false;
            console.log('inputValue ' + this.inputValue2);
            if (this.visibilerecord) {
                if (event.target.value != undefined || event.target.value != null || event.target.value.length > 0) {
                    this.updateRecordField(this.recordId, 'LastName', this.inputValue2);
                }
            }
            else {
                if (this.newLeadId != null && this.newLeadId != '' && this.newLeadId != undefined) {
                    this.updateRecordField(this.newLeadId, 'LastName', this.inputValue2);
                }
            }
        }

        else {

            if (this.inputValue2.length > 50) {
                this.inputValue2 = this.inputValue2.slice(0, 50) + this.inputValue2.slice(51); // Remove 41st character
                event.target.value = this.inputValue2;
            }
            var lastIndex = this.inputValue2.length - 1;
            //var thisIndex = lastIndex;
            const secondLastChar = this.inputValue2[lastIndex - 1];
            console.log('Captured Second Last Character: ' + secondLastChar);
            if (lastIndex >= 0) {
                // Remove the last character from the string
                console.log('430');
                this.inputValue2 = this.inputValue2.replace(/[^a-zA-Z\s]/g, '');
                event.target.value = this.inputValue2;
                //this.inputValue = this.inputValue+secondLastChar;
            }
            console.log('this.inputValue2=:' + this.inputValue2);
            this.lnameval = true;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill the last name in the correct format. ',
                    variant: 'error',
                }),
            );
        }
    }
    handleCodeNameInputChange(event) {
        const inputValue = event.target.value;
        const fieldApiName = event.target.dataset.name;
        const label = event.target.label.trim();
        const regex = /[^a-zA-Z]/g;
        // Restrict special characters for Connector Code
        console.log('inputValue-->', inputValue);
        console.log('label-->', label);
        console.log('regex.test(inputValue)-->', !regex.test(inputValue));
        if (label.includes('Connector Code')) {
            // Remove all non-alphabet characters
            // const cleanedValue = inputValue.replace(/[^a-zA-Z]/g, '');
            const cleanedValue = inputValue.replace(/[^a-zA-Z0-9]/g, '');
            if (inputValue !== cleanedValue) {
                event.target.value = cleanedValue;
                this.showToast('Error', 'Please enter valid Connector Code.', 'error');
            }
            // Optionally, update your tracked property if needed
            event.target.value = cleanedValue;
            console.log('event.target.value-->', event.target.value);
        }
        var checkValidity = /\d/;
        if (fieldApiName.includes("Name") && checkValidity.test(event.target.value)) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please enter value in correct format.',
                variant: 'error'
            }));
            const correctValue = event.target.value.replace(checkValidity, ''); // Remove invalid characters
            event.target.value = correctValue;
        }
        else if (this.visibilerecord) {

            if (event.target.value != undefined || event.target.value != null || event.target.value.length > 0) {

                this.updateRecordField(this.recordId, fieldApiName, event.target.value);
                if (fieldApiName.includes("Name")) {
                    this.nameValue = event.target.value;
                } else {
                    this.codeValue = event.target.value;
                }
            }
        }
        else if (this.newLeadId) {
            if (this.newLeadId != null && this.newLeadId != '' && this.newLeadId != undefined) {
                this.updateRecordField(this.newLeadId, fieldApiName, event.target.value);
                if (fieldApiName.includes("Name")) {
                    this.nameValue = event.target.value;
                } else {
                    this.codeValue = event.target.value;
                }
            }
        }
    }
    updateRecordField(recordId, fieldApiName, fieldValue) {
        const fields = {};
        fields['Id'] = recordId;
        fields[fieldApiName] = fieldValue;

        const recordInput = { fields };
        if (this.isHLUser && this.isApprovalPending) {
            this.showToast('Error', 'You are not allowed to update data as approval is pending.', 'error');
            var childCompVar = this.template.querySelector('c-lead-stage-path');
            if (this.visibilerecord) {
                var sendParam = { 'recordId': this.recordId };
                childCompVar.refreshChild(sendParam);
            }
            else {
                var sendParam = { 'recordId': this.newLeadId };
                childCompVar.refreshChild(sendParam);
            }
            return Promise.resolve();
        }
        return updateRecord(recordInput)
            .then(() => {
                console.log('Record updated successfully');
                var childCompVar = this.template.querySelector('c-lead-stage-path');
                if (this.visibilerecord) {
                    var sendParam = { 'recordId': this.recordId };
                    childCompVar.refreshChild(sendParam);
                }
                else {
                    var sendParam = { 'recordId': this.newLeadId };
                    childCompVar.refreshChild(sendParam);
                }
            })
            .catch(error => {
                console.error('Error updating record: ', error);
                console.log('Error updating record --> ' + JSON.stringify(error));
            })
    }

    handlebtypeval(event) {
        this.btpevalue = event.detail.value;
        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'Business_Type__c', this.btpevalue);
        }
        else {
            this.updateRecordField(this.newLeadId, 'Business_Type__c', this.btpevalue);
        }
    }

    opencodebox(event) {
        var phoneno = '8766634560'; // Updated regex to ensure first digit is 6 or above
        var checkValidity = /^[0-9]*$/; // Regex to check if the input contains only digits
        // Get the entered mobile number
        this.no = event.target.value;
        // Check if the input contains only digits
        if (!this.no.match(checkValidity) && this.no.length > 0) {
            this.showBox = false;
            // If input contains non-numeric characters, remove them and display an error
            this.no = this.no.replace(/[^0-9]/g, '');
            event.target.value = this.no;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Mobile number should contain only digits.',
                variant: 'error'
            }));
            return;
        }

        // Check if the input has exactly 10 digits and starts with 6 or above
        if (this.no.length === 10 && !this.no.match(phoneno)) {
            // If mobile number is invalid, display an error
            this.showBox = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please enter a valid mobile number. It should contain 10 digits and start with 6 or above.',
                variant: 'error'
            }));
        }

    }
    handleDedupe() {
        if ((this.no === null || this.no === undefined || this.no === '') ||
            (this.customerType == 'Individual' && ((this.inputValue === null || this.inputValue === undefined || this.inputValue === '')
                || (this.inputValue2 === null || this.inputValue2 === undefined || this.inputValue2 === ''))) ||
            (this.customerType == 'Non Individual' && ((this.entityname === null || this.entityname === undefined || this.entityname === '')
                || (this.contactName === null || this.contactName === undefined || this.contactName === ''))) || (this.custProfile === null || this.custProfile === undefined || this.custProfile === '')) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please enter the required information.',
                variant: 'error'
            }));
            return;
        }
        if (this.customerType === 'Individual' && (this.inputValue.length < 1)) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'First name should be at least 1 characters.',
                    variant: 'error',
                }),
            );
            this.inputValue = '';
            this.updateRecordField(this.recordId, 'FirstName', this.inputValue);
            return;
        }
        var phoneno = /^[6-9][0-9]{9}$/; // Updated regex to ensure first digit is 6 or above
        if (this.no.length === 10 && this.no.match(phoneno)) {
            // If mobile number is invalid, display an error
            this.duplicateLead();
        }
        //  this.colormethod();
    }
    duplicateLead() {
        getreferenceLead({ phoneNumber: this.no, leadId: this.leadId, cusType: this.customerType })
            .then(result => {
                this.leadNameIfAny = result;
                console.log('leadNameIfAny ' + this.leadNameIfAny);

                if (this.leadNameIfAny != null) {
                    this.leadname = this.leadNameIfAny;
                    this.isShownewModal = true;
                    this.showfields = false;
                    this.isLoading = false;
                    return true;
                } else {
                    if (this.no.length === 10) {
                        this.isLoading = true;
                        // ✅ Call MNRL check first
                        // checkMNRL({ 
                        //     inputMap: { mobNumber: this.no, processName: 'MNRL Check' } 
                        // })
                        // .then(mnrlResult => {
                        //     console.log('MNRL Result:', mnrlResult);

                        //     if (mnrlResult && mnrlResult.isBlacklisted) {
                        //         // ✅ Stop further execution if blacklisted
                        //         this.showToast('Error', mnrlResult.message, 'error');
                        //         //this.isLoading = false;
                        //         return;
                        //     }

                        // ✅ Continue only if NOT blacklisted
                        if (!this.visibilerecord) {
                            if (!this.newLeadId) {
                                console.log('inputValue ' + this.inputValue);
                                console.log('inputValue2 ' + this.inputValue2);
                                console.log('this.assignedRo reflead --> ' + this.assignedRo);
                                console.log('selected Product type>' + this.selectedProductType);
                                console.log('salesexecutive>' + this.salesexecutive);

                                if (((this.customerType == 'Individual' && ((this.inputValue2 && this.inputValue2.length >= 2) && (this.inputValue && this.inputValue.length >= 2))) ||
                                    (this.customerType != 'Individual' && ((this.entityname && this.entityname.length >= 2) && (this.contactName && this.contactName.length >= 2)))) &&
                                    this.selectedProductType != null && this.customerType != null) {

                                    createLead({
                                        firstName: this.inputValue,
                                        middleName: this.middlename,
                                        lastName: this.inputValue2,
                                        mobileNumber: this.no,
                                        company: this.entityname,
                                        contactPersonName: this.contactName,
                                        custType: this.customerType,
                                        channel: this.selectedchannelTypeValue,
                                        employementType: this.custProfile,
                                        productType: this.selectedProductType,
                                        pan: this.panno,
                                        salesExecutive: this.salesexecutive
                                    })
                                        .then(newLead => {

                                            if (this.selectedProductType == 'Flexi Loan' && this.hasHLPermission) {
                                                // this.purposeOfLoanValue = this.purposeOfLoanValue.filter(option => option.value == 'Flexi Loan Personal Expenses' || option.value == 'Flexi Loan Others' || option.value == 'Flexi Loan Family Expenses' || option.value == 'Flexi Loan Consumer Durable' );
                                                //HL_Ishi
                                                if (this.selectedCustId != null && this.selectedCustId != '' && this.selectedCustId != null) {
                                                    console.log('Inside 1110------' + this.selectedCustId);
                                                    this.updateRecordField(newLead, 'HL_Customer_LMS_ID__c', this.selectedCustId);
                                                }
                                                console.log(',this.dobordoi----' + this.dobordoi);
                                                if (this.customerType == 'Individual') {
                                                    this.updateRecordField(newLead, 'Date_of_Birth__c', this.dobordoi);
                                                }
                                                else {
                                                    this.updateRecordField(newLead, 'Date_of_Incorporation__c', this.dobordoi);
                                                }
                                                console.log(',refff numberr---' + this.referenceNumber);
                                                this.updateRecordField(newLead, 'FL_Source__c', this.loanSource);
                                                this.updateRecordField(newLead, 'Parent_Loan_Number__c', this.referenceNumber);

                                            }

                                            console.log('newLead ' + newLead);
                                            // this.newLeadId = newLead;
                                            // this.leadId = this.newLeadId;
                                            // this.ntbScreen = true;
                                            // this.updateRecordField(this.newLeadId, 'Current_Page__c', 2);
                                            // console.log('newLeadId ' + this.newLeadId);
                                            // this.showToast('Success', 'Lead record has been created successfully.', 'success');
                                            // this.isLoading = false;
                                            // this.oldno = this.no;

                                            // var childCompVar = this.template.querySelector('c-lead-stage-path');
                                            // var sendParam = { 'recordId': newLead };
                                            // childCompVar.refreshChild(sendParam);
                                            // this.newLeadId = newLead;
                                            // this.leadId = this.newLeadId;
                                            // this.recordId = this.newLeadId;
                                            // this.ntbScreen = true;

                                            // console.log('newLeadId ' + this.newLeadId);

                                            // // IMPORTANT:
                                            // // Stay on the current Lead Creation tab
                                            // // and move from Basic Information to Additional Details.
                                            // this.navigateToSecondPage();
                                            this.newLeadId = newLead;
                                            this.leadId = this.newLeadId;
                                            this.recordId = this.newLeadId;

                                            console.log('newLeadId ' + this.newLeadId);

                                            // Navigate to the newly created Lead record
                                            this[NavigationMixin.Navigate]({
                                                type: 'standard__recordPage',
                                                attributes: {
                                                    recordId: this.newLeadId,
                                                    objectApiName: 'Lead',
                                                    actionName: 'view'
                                                }
                                            });

                                            this.showToast(
                                                'Success',
                                                'Lead record has been created successfully.',
                                                'success'
                                            );

                                            this.isLoading = false;

                                            this.oldno = this.no;

                                            // Refresh stage path
                                            var childCompVar = this.template.querySelector(
                                                'c-lead-stage-path'
                                            );

                                            if (childCompVar) {
                                                var sendParam = {
                                                    recordId: newLead
                                                };

                                                childCompVar.refreshChild(sendParam);
                                            }

                                            if (newLead != null) {
                                                this.showBox = true;

                                                getreferenceLeadname({ recordId: this.newLeadId })
                                                    .then(name => {
                                                        this.showLead = true;
                                                        this.createdleadName = name;
                                                        this.leadinwords = 'Lead ' + this.createdleadName + ' is created.';
                                                        const allowedLabels = [
                                                            'DSA',
                                                            'Corporate DSA'
                                                        ];

                                                        this.channelvaluesRo = this.dsa
                                                            ? this.channelvaluesRo.filter(
                                                                item => allowedLabels.includes(item.label)
                                                            )
                                                            : this.channelvaluesRo.values;

                                                        // if (this.telesales || this.others || this.dsa || this.salesexecutive) {
                                                        //     const allowedLabels = ['DSA', 'Corporate DSA'];
                                                        //     this.channelvaluesRo = this.dsa ? this.channelvaluesRo.filter(item => allowedLabels.includes(item.label)) : this.channelvaluesRo.values;
                                                        //     console.log('this.dsa',this.dsa);
                                                        //     this[NavigationMixin.Navigate]({
                                                        //         type: 'standard__recordPage',
                                                        //         attributes: {
                                                        //             recordId: this.newLeadId,
                                                        //             objectApiName: 'Lead',
                                                        //             actionName: 'view'
                                                        //         }
                                                        //     });
                                                        // } else if (this.salesexecutive && this.isMobile) {
                                                        //     this[NavigationMixin.Navigate]({
                                                        //         type: 'standard__recordPage',
                                                        //         attributes: {
                                                        //             recordId: this.newLeadId,
                                                        //             objectApiName: 'Lead',
                                                        //             actionName: 'view'
                                                        //         }
                                                        //     });
                                                        // }

                                                        //this.productDisabled = true;
                                                    })
                                            }
                                        })
                                        .catch(error => {
                                            console.error('Error creating Lead: ', JSON.stringify(error));
                                        });
                                } else {
                                    // Validation messages remain unchanged
                                    if (this.customerType == 'Individual' && (!this.inputValue || !this.inputValue2)) {
                                        this.showToast('Error', 'Kindly add first name and last name first before you enter the mobile number', 'error');
                                    } else if (this.customerType == 'Individual' && (!this.inputValue || this.inputValue.length < 2)) {
                                        this.showToast('Error', 'First name should have at least 2 characters. Please enter a valid first name.', 'error');
                                    } else if (this.customerType == 'Individual' && (!this.inputValue2 || this.inputValue2.length < 2)) {
                                        this.showToast('Error', 'Last name should have at least 2 characters. Please enter a valid first name.', 'error');
                                    } else if (this.customerType == 'Non Individual' && (!this.entityname || this.entityname.length < 2)) {
                                        this.showToast('Error', 'Please enter an Entity Name with at least 2 characters and a maximum of 50 characters.', 'error');
                                    } else if (this.customerType == 'Non Individual' && (!this.contactName || this.contactName.length < 2)) {
                                        this.showToast('Error', 'Please enter a Contact Person Name with at least 2 characters and a maximum of 50 characters.', 'error');
                                    }
                                    this.isLoading = false;
                                }
                            } else {
                                this.updateRecordField(this.recordId, 'MobilePhone', this.no);
                            }
                        }
                        // })
                        // .catch(error => {
                        //     console.error('Error in MNRL check: ', JSON.stringify(error));
                        //     this.showToast('Error', 'Failed to validate mobile number. Please try again.', 'error');
                        // });
                    }
                }
            })
            .catch(error => {
                console.error('Error ' + JSON.stringify(error));
                console.error('Error Message:', error.message);
                console.error('Stack Trace:', error.stack);
            });
    }
    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }

    handleSaverecord() {
        this.isLoading = true;
        this.headerTitle = 'Enter Lead Information';
        // Delay logic execution by 2 seconds
        if (this.fillfirstinformation && !this.fillsecondinformation && !this.fillthirdinformation) {
            console.log('inside 862');
            this.handleFirstInformation();
        }
        else if (this.fillsecondinformation && !this.fillfirstinformation && !this.fillthirdinformation) {
            console.log('inside 866');
            this.handlecheckMNRL();
            this.handleSecondInformation();
        }
        else if (this.fillthirdinformation && !this.fillsecondinformation && !this.fillfirstinformation) {
            this.handleconversion();

        }
        else if (this.fillfourthinformation) {
            console.log('inside 880');
            this.handleconversion();
        }
        else {
            console.log('inside 884');
            this.isLoading = false; // Stop loader in case no condition matches
        }
        // alert('alert it will work');
        this.colormethod();
    }

    // Handle First Information Section
    handleFirstInformation() {
        // Call the Apex method to get the reference lead by phone number
        if (this.visibilerecord) {
            this.leadId = this.recordId;
        }
        else {
            this.leadId = this.newLeadId;
        }

        getreferenceLead({ phoneNumber: this.no, leadId: this.leadId, cusType: this.customerType })
            .then(result => {
                this.leadNameIfAny = result;
                console.log('leadNameIfAny: ' + this.leadNameIfAny);

                if (this.leadNameIfAny != null) {
                    // If a lead exists, update the lead name and show the modal
                    this.leadname = this.leadNameIfAny;
                    this.isShownewModal = true;
                    this.showfields = false;
                    this.isLoading = false;
                    return true;
                }
                else {
                    // If no lead exists, prepare input parameters for the Dedupe API call
                    const inputParams = {
                        isKYCSelected: 'false',
                        isCustIdPresent: 'false',
                        isMobScreen: 'true',
                        dob: null,
                        mobileNum: this.no,
                        kycNum: null,
                        custId: null,
                        selectedKYC: null,
                        objectName: this.objectName,
                        product: this.selectedProductType,
                        customerType: this.customerType
                    };

                    // Call the Dedupe API with the prepared parameters
                    // callDedupeApi({ inputParams })
                    // .then(response => {
                    //     // Check if the customer is new or an existing one
                    //     if (response.freshCustomer) {
                    console.log('Customer is fresh.', this.middlename);
                    console.log('this.this.pinno--', this.pinno);
                    console.log('selectedchannelTypeValue>>', this.selectedchannelTypeValue);
                    console.log('telesales>>', this.telesales);
                    console.log('selectedProductType>>', this.selectedProductType);
                    console.log('maskedPhoneNumber>>', this.maskedPhoneNumber);
                    console.log('middlename>>', this.middlename);
                    console.log('canClose>>', this.canClose);
                    console.log('entityname>>', this.entityname);
                    console.log('custProfile>>', this.custProfile);
                    if (((this.selectedchannelTypeValue == 'DSA' && this.arm != null) || this.selectedchannelTypeValue != 'DSA') && ((this.telesales && this.arm != null) || !this.telesales) && this.selectedProductType && this.pinno && (this.maskedPhoneNumber != null && this.maskedPhoneNumber.length == 10) && (this.custProfile != null && this.custProfile != '') &&
                        (this.customerType == 'Non Individual' && (this.entityname != null && this.entityname != '' && this.entityname >= 2)) && (this.customerType == 'Non Individual' && (this.contactName != null && this.contactName != '' && this.contactName >= 2)) && ((this.middlename == null || this.middlename == undefined || this.middlename == '' || this.middlename.length > 2)) || (!this.canClose)) {
                        console.log('inside navigation');
                        var mobile;
                        if (this.no && this.no.length === 10) {
                            mobile = 'XXXXXX' + this.no.slice(-4);
                        }
                        console.log('mobile', mobile);
                        this.updateRecordField(this.recordId, 'MobilePhone', this.no)
                            .then(() => {
                                this.updateRecordField(this.recordId, 'Mobile_Number_Masked__c', mobile);
                                this.navigateToSecondPage(); // Navigate only after MobilePhone is committed
                            })
                            .catch(() => {
                                this.showToast('Error', 'Failed to save mobile number. Please try again.', 'error');
                                this.isLoading = false;
                            });
                    }
                    else {
                        /*if (this.arm == null) {
                            this.showToast('Error', 'Please select the area manager. ', 'error');
                        }*/
                        /*if(this.pinno == null){
                       this.showToast('Error', 'Please select the valid pin code to proceed. ', 'error');

                        }*/
                        if (this.customerType == 'Individual' && (this.inputValue == null || this.inputValue == undefined || this.inputValue == '')) {
                            this.showToast('Error', 'Please enter the first name to proceed. ', 'error');
                            this.isLoading = false;
                            return;
                        }
                        if (this.customerType == 'Individual' && (this.inputValue2 == null || this.inputValue2 == undefined || this.inputValue2 == '')) {
                            this.isLoading = false;
                            this.showToast('Error', 'Please enter the last name to proceed. ', 'error');
                            return;
                        }
                        if (this.customerType == 'Individual' && (!this.inputValue2 || this.inputValue2.length < 2)) {
                            this.isLoading = false;
                            this.showToast('Error', 'Please enter a last name with at least 2 characters and a maximum of 50 characters.', 'error');
                            return;
                        }
                        if (this.customerType == 'Non Individual' && (!this.entityname || this.entityname.length < 2)) {
                            this.isLoading = false;
                            this.showToast('Error', 'Please enter an entity name with at least 2 characters.', 'error');
                            return;
                        }
                        if (this.customerType == 'Non Individual' && (!this.contactName || this.contactName.length < 2)) {
                            this.isLoading = false;
                            this.showToast('Error', 'Please enter a contact person name with at least 2 characters.', 'error');
                            return;
                        }
                        if (!this.custProfile) {
                            this.isLoading = false;
                            this.showToast('Error', 'Please enter a applicant profile to proceed.', 'error');
                            return;
                        }
                        if (this.maskedPhoneNumber != null && this.maskedPhoneNumber.length < 10) {
                            this.showToast('Error', 'Please enter correct mobile number', 'error');
                            this.isLoading = false;
                            return;
                        }
                        if (this.maskedPhoneNumber.length == 10) {
                            this.isLoading = true;
                            // ✅ Call MNRL check first
                            // checkMNRL({ 
                            //     inputMap: { mobNumber: this.maskedPhoneNumber, processName: 'MNRL Check' } 
                            // })
                            // .then(mnrlResult => {
                            //     console.log('MNRL Result:', mnrlResult);
                            //     this.isLoading = true;
                            //     if (mnrlResult && mnrlResult.isBlacklisted) {
                            //         console.log('Not Blacklisted, proceed further',mnrlResult.isBlacklisted);
                            //         // ✅ Stop further execution if blacklisted
                            //         this.showToast('Error', mnrlResult.message, 'error');
                            //         this.isLoading = false;
                            //         return;
                            //     }
                            //     else {
                            //console.log('Blacklisted, show error message',mnrlResult.isBlacklisted);
                            if (this.no && this.no.length === 10) {
                                mobile = 'XXXXXX' + this.no.slice(-4);
                            }
                            console.log('mobile', mobile);
                            this.updateRecordField(this.recordId, 'Customer_Type__c', this.customerType);
                            this.updateRecordField(this.recordId, 'Employment_Type__c', this.custProfile);
                            this.updateRecordField(this.recordId, 'MobilePhone', this.no)
                                .then(() => {
                                    this.updateRecordField(this.recordId, 'Mobile_Number_Masked__c', mobile);
                                    this.navigateToSecondPage(); // Navigate only after MobilePhone is committed
                                })
                                .catch(() => {
                                    this.showToast('Error', 'Failed to save mobile number. Please try again.', 'error');
                                    this.isLoading = false;
                                });
                            //this.isLoading = false;
                            // }
                            //     }).catch(error => {
                            //     console.error('Error in MNRL check: ', JSON.stringify(error));
                            //     this.showToast('Error', 'Failed to validate mobile number. Please try again.', 'error');
                            //     this.isLoading = false;
                            // });
                        }
                        // if((this.middlename!= null&& this.middlename!=undefined) && this.middlename.length<=2){
                        //     this.showToast('Error', 'Middle name should be more than 2 characters', 'error');
                        // }
                        // Show an error message if required fields are missing
                        // this.showToast('Error', 'Please fill all the required fields to proceed.', 'error');
                        //this.navigateToSecondPage();
                        //this.isLoading = false;
                    }
                    //     } 
                    //     else {
                    //         console.log('Customer exists.');
                    //         this.isLoading = false;
                    //         this.softdedupe = true; // Enable soft dedupe view
                    //     }
                    // })
                    // .catch(error => {
                    //     // Handle errors from the API call
                    //     console.error('Error:', error);
                    // });
                }
            })
            .catch(error => {
                // Handle errors from the getReferenceLead method
                console.error('Error in getReferenceLead:', error);
                this.isLoading = false;
            });
    }

    // Handle Second Information Section
    handleSecondInformation() {
        console.log('Handling Second Information');
        console.log('(this.dateOfBirth )--', (this.dateOfBirth));
        console.log('(this.dateofInc )--', (this.dateofInc));
        console.log('bvintage', this.bvintage, this.loanamt, this.customerType);
        console.log('pinno' + this.pinno);
        //if((this.dateOfBirth || this.dateofInc)  && ((this.panno== null || this.panno==undefined || this.panno == '' || (this.customerType== 'Individual' && panNumberValidation(this.panno))||(this.customerType!= 'Individual' && this.btpevalue != null && this.btpevalue != undefined && this.btpevalue != '' && validateNonIndividualPAN(this.panno, this.btpevalue)))) && this.loanamt && this.customerType  && this.bvintage != null) {
        console.log('this.purposeOfLoan>', this.purposeOfLoan);
        console.log('selectedchannelTypeValue>', this.selectedchannelTypeValue);
        console.log('nameValue', this.nameValue);
        console.log('codeValue', this.codeValue);
        console.log('check condition', ((this.dateOfBirth != undefined && this.dateOfBirth != null && this.dateOfBirth != '' && this.customerType === 'Individual') || (this.dateofInc != undefined && this.dateofInc != null && this.dateofInc != '' && this.customerType === 'Non Individual')));
        console.log('DOB valid:', this.dateOfBirth !== undefined && this.dateOfBirth !== null && this.dateOfBirth !== '' && this.customerType === 'Individual');
        // Validate Connector Code again before proceeding
        if (
            (
                (
                    (this.dateOfBirth !== undefined && this.dateOfBirth !== null && this.dateOfBirth !== '' && this.customerType === 'Individual') ||
                    (this.dateofInc !== undefined && this.dateofInc !== null && this.dateofInc !== '' && this.customerType === 'Non Individual')

                ) &&
                (this.customerType === 'Individual' || (this.btpevalue != null && this.btpevalue != undefined && this.btpevalue != '' && this.customerType === 'Non Individual')
                ) &&
                this.loanamt !== undefined && this.loanamt !== null && this.loanamt !== '' &&
                this.customerType !== undefined && this.customerType !== null && this.customerType !== '' &&
                this.pinno !== null &&
                this.emailno !== undefined && this.emailno != null && this.emailno != '' &&
                this.purposeOfLoan !== null &&
                this.purposeOfLoan !== undefined &&
                this.purposeOfLoan !== ''
            ) &&
            (
                (this.selectedchannelTypeValue?.trim().toLowerCase() === 'campaign' && this.campValue !== null && this.campValue !== '' && this.campValue !== undefined) ||
                (this.isDirectLike(this.selectedchannelTypeValue) || this.selectedchannelTypeValue?.trim().toLowerCase() === 'csc' || this.selectedchannelTypeValue?.trim().toLowerCase() === 'online') || ((this.selectedchannelTypeValue?.trim().toLowerCase() === 'dsa' || this.selectedchannelTypeValue?.trim().toLowerCase() === 'connector' || this.selectedchannelTypeValue?.trim().toLowerCase() === 'corporate dsa') && (this.dsaId != null && this.dsaId != '')) ||
                (this.nameValue != undefined && this.codeValue != undefined)
            )
        ) {
            console.log('In If');
            this.fillsecondinformation = false;
            this.fillfirstinformation = false;
            this.fillthirdinformation = true;
            this.currPage = 3;
            this.headerTitle = 'Send Consent';
            this.shownext = true;
            this.showprev = true;
            if (this.loanAmt < 500000) {
                this.showLoanAmtMessage = true;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Warning',
                    message: 'The loan amount is less then 5 lakh.',
                    variant: 'warning'
                }));
            }
            if (this.visibilerecord) {
                console.log('In If+' + this.selectedVertical);
                console.log('1390 ' + this.recordId);
                evaluateLeadConditions({ leadId: this.recordId })
                    .then(result => {
                        console.log('result ' + result);
                        if (result) {
                            console.log('780');
                            //this.fetchPincodeName();
                            this.qualdis = true;
                            this.qualified = result;
                            this.currPage = 3;
                            this.updateRecordField(this.recordId, 'Lead_Sub_Status__c', 'Qualified');
                            this.updateRecordField(this.recordId, 'Channel__c', this.selectedchannelTypeValue);
                            this.updateRecordField(this.recordId, 'Current_Page__c', 3);
                            // this.disablefields();
                            // if ((this.selectedchannelTypeValue?.trim().toLowerCase() === 'direct')) {
                            //     try {
                            //         await maybeStampDSAAM({
                            //             leadId: this.recordId,
                            //             channel: this.selectedchannelTypeValue
                            //         });
                            //     } catch (e) {
                            //         console.error('maybeStampDSAAM failed (recordId path):', e);
                            //     }
                            // }
                            this.fillthirdinformation = true;
                            // this.connectedCallback();
                            //this.fillthirdinformation = true;
                        }
                        else {
                            console.log('790');
                            //this.fetchPincodeName();
                            this.qualdis = true;
                            this.qualified = result;
                            this.currPage = 3;
                            this.updateRecordField(this.recordId, 'Status', 'Closed');
                            this.updateRecordField(this.recordId, 'Lead_Sub_Status__c', 'Disqualified');
                            this.updateRecordField(this.recordId, 'Closed_Reasons__c', 'Disqualified');
                            this.updateRecordField(this.recordId, 'Channel__c', this.selectedchannelTypeValue);
                            fireEvent(this.pageRef, "closeLeadfromedit", "Breed-Labrador");
                            this.updateRecordField(this.recordId, 'Current_Page__c', 3);
                            // this.disablefields();
                            this.fillthirdinformation = true;
                            this.connectedCallback();

                        }
                    })
            }
            else {
                evaluateLeadConditions({ leadId: this.newLeadId })
                    .then(async (result) => {
                        console.log('result ' + result);
                        if (result) {
                            console.log('806');
                            //this.fetchPincodeName();
                            this.qualdis = true;
                            this.qualified = result;
                            this.currPage = 3;
                            this.updateRecordField(this.newLeadId, 'Lead_Sub_Status__c', 'Qualified');
                            this.updateRecordField(this.recordId, 'Channel__c', this.selectedchannelTypeValue);
                            this.updateRecordField(this.newLeadId, 'Current_Page__c', 3);
                            //  this.disablefields();
                            if (this.isDirectLike(this.selectedchannelTypeValue)) {
                                try {
                                    await maybeStampDSAAM({
                                        leadId: this.newLeadId,
                                        channel: this.selectedchannelTypeValue
                                    });
                                } catch (e) {
                                    console.error('maybeStampDSAAM failed (newLeadId path):', e);
                                }
                            }
                            this.fillthirdinformation = true;
                            this.connectedCallback();

                        }
                        else {
                            console.log('816');
                            this.qualdis = true;
                            this.qualified = result;
                            this.currPage = 3;
                            //this.fetchPincodeName();
                            this.updateRecordField(this.newLeadId, 'Lead_Sub_Status__c', 'Disqualified');
                            this.updateRecordField(this.newLeadId, 'Closed_Reasons__c', 'Disqualified');
                            this.updateRecordField(this.recordId, 'Channel__c', this.selectedchannelTypeValue);
                            this.updateRecordField(this.newLeadId, 'Status', 'Closed');
                            this.updateRecordField(this.newLeadId, 'Current_Page__c', 3);
                            // this.disablefields();
                            this.fillthirdinformation = true;
                            this.connectedCallback();

                            if (!this.qualified) {
                                this.canClose = false;
                            }
                        }
                        this.headerTitle = (this.qualified && this.fillthirdinformation) ? 'Send Consent' : 'Enter Lead Information';

                    })
            }
            this.getDoccheckImageUploadedstatus();
            this.isLoading = false;
        }
        else {
            this.updateRecordField(this.recordId, 'Current_Page__c', 2);
            if (this.customerType == 'Individual' && this.dateOfBirth == null) {
                this.showToast('Error', 'Please select the correct date of birth.', 'error');
            }

            if (this.customerType == 'Non Individual' && this.dateofInc == null) {
                this.showToast('Error', 'Please select the correct Date of incorporation.', 'error');
            }

            if (this.loanamt == null) {
                this.showToast('Error', 'Please fill the loan amount.', 'error');

            }
            console.log('btype val>' + this.btpevalue)
            if (this.customerType == 'Non Individual' && (this.btpevalue == '' || this.btpevalue == null || this.btpevalue == undefined)) {
                this.showToast('Error', 'Please fill the constitution.', 'error');

            }
            console.log('this.emailno>', this.emailno);
            if (this.emailno == null) {
                this.showToast('Error', 'Please fill the email address.', 'error');

            }
            if (this.pinno == null || this.pinno == undefined || this.pinno == '') {
                this.showToast('Error', 'Please fill the Pin Code.', 'error');
            }
            if (this.purposeOfLoan == null || this.purposeOfLoan == undefined || this.purposeOfLoan == '') {
                this.showToast('Error', 'Please fill the Purpose of Loan.', 'error');
            }

            if (
                (this.nameValue == null || this.nameValue == undefined) && !this.isDirectLike(this.selectedchannelTypeValue) && !['Campaign', 'Connector', 'DSA'].includes(this.selectedchannelTypeValue)
            ) {
                this.showToast('Error', 'Please fill the ' + this.nameLabel + '.', 'error');
            }
            if (
                (this.codeValue == null || this.codeValue == undefined) && !this.isDirectLike(this.selectedchannelTypeValue) && !['Campaign', 'Connector', 'DSA'].includes(this.selectedchannelTypeValue)
            ) {
                this.showToast('Error', 'Please fill the code.', 'error');
            }
            if (this.selectedchannelTypeValue == 'Campaign' && (this.campValue == null || this.campValue == '')) {
                this.showToast('Error', 'Please select campaign code.', 'error');
            }
            if (((this.selectedchannelTypeValue?.trim().toLowerCase() === 'dsa' || this.selectedchannelTypeValue?.trim().toLowerCase() === 'connector' || this.selectedchannelTypeValue?.trim().toLowerCase() === 'corporate dsa') && (this.dsaId == null || this.dsaId == ''))) {
                this.showToast('Error', 'Please select DSA/Connector.', 'error');
            }
            if (this.panno != null && this.panno != undefined && this.panno != '') {
                console.log('this.panno : ' + this.panno);
                if (this.customerType == 'Individual') {
                    if (!panNumberValidation(this.panno)) {
                        this.showToast('Error', 'Please fill PAN Number in correct format', 'error');

                    }
                }
                if (this.customerType != 'Individual') {
                    if (this.btpevalue != null && this.btpevalue != undefined && this.btpevalue != '') {
                        if (!validateNonIndividualPAN(this.panno, this.btpevalue)) {
                            this.showToast('Error', 'Please fill PAN Number in correct format', 'error');

                        }
                    }

                }

            }

            if (this.bvintage == null && this.showBusinessVintage) {
                this.showToast('Error', 'Please fill the Business Vintage', 'error');
            }
            if (this.maskedPhoneNumber != null && this.maskedPhoneNumber.length < 10) {
                this.showToast('Error', 'Please enter correct mobile number', 'error');
                return;
            }
            //this.isLoading = false;
            //const exists = this.bindustryvalues.some(item => item.value === this.bindustval);
            //console.log('this.exists---'+this.exists);

            // if(!exists){
            //     this.bindustval = '';
            //    this.showToast('Error', 'Please fill the Valid Business Industry', 'error');
            // }

            // this.showToast('Error', 'Please fill all the required fields to proceed###.', 'error');
        }
        this.isLoading = false;
    }

    // Handle Third Information Section
    handleThirdInformation() {
        console.log('Handling Third Information');
        try {

            this.fillsecondinformation = false;
            this.fillthirdinformation = false;
            this.fillfirstinformation = false;
            this.fillfourthinformation = true;
            this.shownext = true;
            this.showprev = true;

            if (this.visibilerecord) {
                this.updateRecordField(this.recordId, 'Current_Page__c', 4);
            }
            else {
                this.updateRecordField(this.newLeadId, 'Current_Page__c', 4);
            }
            this.isLoading = false;
        } catch (error) {
            console.log('error', error.stringify());
        }

    }

    // Navigate to Second Page
    navigateToSecondPage() {
        this.colormethod();
        console.log('isloading' + this.isLoading);
        this.fillsecondinformation = true;
        console.log('930');
        this.fillthirdinformation = false;
        this.fillfirstinformation = false;
        this.showprev = true;
        this.shownext = true;


        if (this.visibilerecord) {
            console.log('inside 1152');
            this.updateRecordField(this.recordId, 'Current_Page__c', 2);
        }
        else {
            console.log('inside 1156');
            this.updateRecordField(this.newLeadId, 'Current_Page__c', 2);
        }

        this.isLoading = false;
    }
    callGetLoanAPI(finReference) {
        this.isloading = true;
        console.log('finReference--', finReference);
        getExistingLoanDetails({ loanId: finReference })
            .then(loanResponse => {
                console.log('Loan API Response--', loanResponse);

                // Parse response if it's a string
                let loanResponseObj = typeof loanResponse === 'string' ? JSON.parse(loanResponse) : loanResponse;
                const returnCode = loanResponseObj?.returnStatus?.returnCode;
                console.log('returnCode--', returnCode);

                if (returnCode === '0000' && loanResponseObj.customer && loanResponseObj.customer.cif) {
                    this.cifNumber = loanResponseObj.customer.cif;
                    console.log('cifNumber--', this.cifNumber);

                    // Merge first, middle, last name from customer.personalInfo
                    const personalInfo = loanResponseObj.customer.personalInfo || {};
                    const fullName = [personalInfo.firstName, personalInfo.middleName, personalInfo.lastName]
                        .filter(name => name && name.trim() !== '')
                        .join(' ');
                    this.customerName = fullName;
                    console.log('customerName--', this.customerName);

                    // Map only financeDetail fields needed for table
                    if (loanResponseObj.financeSchedule && loanResponseObj.financeSchedule.financeDetail) {
                        const fd = loanResponseObj.financeSchedule.financeDetail;
                        const lmsRecord = {
                            finReference: fd.finReference || '',
                            finType: fd.finType || '',
                            finStatus: fd.status || '',
                            finAmount: fd.finAmount || 0,
                            outstandingBal: (fd.finAmount || 0) - (fd.paidPri || 0),
                            source: 'LMS',
                            isDisabled: fd.status === 'Cancelled' || fd.status === 'Rejected'
                        };

                        this.customerFinanceDetailList = [
                            ...this.customerFinanceDetailList,
                            lmsRecord
                        ];
                    }
                    if (!this.isGhfLoan) {
                        this.showRecords = true;
                        this.showNext = true;
                        this.showFormFields = false;
                        this.showDuplicateRecords = false;
                        this.isloading = false;
                    }
                    else {
                        this.createRelatedRecords(this.customerFinanceDetailList)
                    }


                }
                else {
                    this.isloading = false;
                    this.showToast('Warning', 'No Loan Details found with this loan number', 'warning');
                }
            })
            .catch(error => {
                this.isloading = false;
                console.error('Loan API Error:', error);
            });
    }
    customerName;
    handleconversion() {
        console.log('top up lead--------' + this.isTopupLead);
        // this.parentLoanNumberFL= 'LA-000000884';
        // this.sourceSystemFL='SF';
        console.log('this.parentLoanNumberFL-----' + this.parentLoanNumberFL);

        if (this.parentLoanNumberFL != null && this.parentLoanNumberFL != null && this.parentLoanNumberFL != undefined) {
            var loanAppNo;
            var lmsNo;
            console.log('this.selectedRecord-----' + this.selectedRecord);
            // if(this.selectedRecord.sourceSystem == 'LMS'){
            //     loanAppNo = this.selectedRecord.finReference;
            //     lmsNo = true;
            // }
            // else{
            //     loanAppNo = this.selectedRecord.finReference;
            //     lmsNo = false;
            // }
            if (this.sourceSystemFL == 'SF') {

                loanAppNo = this.parentLoanNumberFL;
                lmsNo = false;
                this.cloneLoanApplicationFL();
            }
            else {
                loanAppNo = this.parentLoanNumberFL;
                lmsNo = true;
                this.createLoanFromLeadFL();
            }

            // checkLoanApplicationInSFDC({ loanAppNo: loanAppNo, lmsNo: lmsNo })
            // .then(result => {
            //     if (result && result.length > 0) {
            //         // Map result to add isDisabled flag
            //         this.customerFinanceDetailList = result.map(rec => {
            //             return {
            //                 ...rec,
            //                 isDisabled: rec.finStatus === 'Cancelled' || rec.finStatus === 'Rejected'
            //             };
            //         });
            //         this.customerName = result.customerName;

            //          this.callGetLoanAPI(loanAppNo);
            //     } else {
            //         // No records found
            //         if (!lmsNo) {
            //             this.isloading = false;
            //             this.showToast('Warning', 'No records found with this Loan Application Number', 'error');
            //         } else {
            //             // If lmsNo is true, call GetLoan API
            //             this.callGetLoanAPI(loanAppNo);
            //         }
            //     }
            // })
            // .catch(error => {
            //     this.isloading = false;
            //     console.error('Error in handleLoanAppNo:', error);
            //     this.showToast('Error', 'Unexpected error occurred', 'error');
            // });
        }
        else {
            console.log('this.panno=:' + this.panno);
            if (this.panno != undefined && this.panno != '' && this.panno != null) {
                this.showConfirmationPopup = true;
                this.isLoading = false;
                this.confirmationMessage = 'Are you sure you want to continue with ' + this.panno + ' as your PAN?';
            }
            else {
                this.showConfirmationPopup = false;
                if (this.dsa) {
                    if (this.visibilerecord) {
                        console.log('at 1067');

                        createLoanFromLead({ leadId: this.recordId })
                            .then(result => {
                                console.log('result ' + result);
                                if (result) {
                                    console.log('result ' + result);
                                    const childCompVar = this.template.querySelector('c-lead-stage-path');
                                    const sendParam = { recordId: this.recordId };
                                    childCompVar.refreshChild(sendParam);
                                    this.isLoading = false;

                                    fireEvent(this.pageRef, "closeLeadfromedit", "Breed-Labrador");
                                    this.showToast('Success', 'Lead converted to loan application successfully.', 'success');
                                    console.log('at 1081');
                                    setTimeout(() => {
                                        this[NavigationMixin.Navigate]({
                                            type: 'standard__recordPage',
                                            attributes: {
                                                recordId: result, // Replace with the dynamic record ID
                                                actionName: 'view',
                                                objectApiName: 'Opportunity' // Ensure this matches the object you're navigating to
                                            },
                                        });
                                    }, 1000);
                                }
                            }).catch(error => {
                                this.isLoading = false;
                                console.log('error>>' + JSON.stringify(error));
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: error.body.pageErrors[0].message,
                                        variant: 'error',
                                    }),
                                );
                            });
                    }
                    else {
                        closeLead({ leadId: this.newLeadId })
                            .then(result => {
                                console.log('result ' + result);
                                if (result) {
                                    const childCompVar = this.template.querySelector('c-lead-stage-path');
                                    const sendParam = { recordId: this.newLeadId };
                                    childCompVar.refreshChild(sendParam);
                                    this.isLoading = false;

                                    fireEvent(this.pageRef, "closeLead", "Breed-Labrador");
                                    this.showToast('Success', 'Lead converted to loan application successfully.', 'success');

                                    setTimeout(() => {
                                        console.log('at 1109');
                                        this[NavigationMixin.Navigate]({
                                            type: 'standard__recordPage',
                                            attributes: {
                                                recordId: result, // Replace with the dynamic record ID
                                                actionName: 'view',
                                                objectApiName: 'Opportunity' // Ensure this matches the object you're navigating to
                                            },
                                        });
                                    }, 1000);
                                }
                            }).catch(error => {
                                this.isLoading = false;
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: error.body.pageErrors[0].message,
                                        variant: 'error',
                                    }),
                                );
                            });
                    }
                }
                else {
                    if (this.visibilerecord) {
                        console.log('at 1125');
                        createLoanFromLead({ leadId: this.recordId })
                            .then(result => {
                                console.log('result ' + result);
                                if (result) {
                                    const childCompVar = this.template.querySelector('c-lead-stage-path');
                                    const sendParam = { recordId: this.recordId };
                                    childCompVar.refreshChild(sendParam);

                                    fireEvent(this.pageRef, "closeLead", "Breed-Labrador");
                                    this.isLoading = false;
                                    this.showToast('Success', 'Lead converted to loan application successfully.', 'success');

                                    setTimeout(() => {
                                        console.log('at 1139');
                                        this[NavigationMixin.Navigate]({
                                            type: 'standard__recordPage',
                                            attributes: {
                                                recordId: result, // Replace with the dynamic record ID
                                                actionName: 'view',
                                                objectApiName: 'Opportunity' // Ensure this matches the object you're navigating to
                                            },
                                        });
                                    }, 1000);
                                }
                            }).catch(error => {
                                console.log('error.body.pageErrors[0].message-----', JSON.stringify(error));
                                this.isLoading = false;
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: error.body.pageErrors[0].message,
                                        variant: 'error',
                                    }),
                                );
                            });
                    }
                    else {
                        console.log('at 1153');
                        createLoanFromLead({ leadId: this.newLeadId })
                            .then(result => {
                                console.log('result ' + result);
                                if (result) {
                                    this[NavigationMixin.Navigate]({
                                        type: 'standard__recordPage',
                                        attributes: {
                                            recordId: result, // Replace with the dynamic record ID
                                            actionName: 'view',
                                            objectApiName: 'Opportunity' // Ensure this matches the object you're navigating to
                                        },
                                    });

                                    const childCompVar = this.template.querySelector('c-lead-stage-path');
                                    const sendParam = { recordId: this.newLeadId };
                                    childCompVar.refreshChild(sendParam);
                                    //   fireEvent(this.pageRef, "closeLead", "Breed-Labrador");

                                    this.isLoading = false;
                                    this.showToast('Success', 'Lead converted to loan application successfully.', 'success');

                                    setTimeout(() => {
                                        console.log('at 1167');

                                    }, 1000);
                                }
                            }).catch(error => {
                                console.log('error---', error);
                                this.isLoading = false;
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: error.body.pageErrors[0].message,
                                        variant: 'error',
                                    }),
                                );
                            });
                    }
                }
            }
        }
    }
    createdLoanId;
    createLoanFromLeadFL() {
        const inputMap = {
            leadId: this.newLeadId,
            recordId: this.recordId
        }
        console.log('Mappppp----', inputMap);
        createLoanFromLeadFL({
            inputMap: inputMap
        })
            .then(result => {
                console.log('result ' + JSON.stringify(result));
                this.createdLoanId = result.loanId;
                createRelatedRecords({ loanNumber: result.parentLoanNum, recordId: result.loanId })
                    .then(response => {
                        //this.createDocuments();
                        const childCompVar = this.template.querySelector('c-lead-stage-path');
                        const sendParam = { recordId: this.recordId };
                        childCompVar.refreshChild(sendParam);
                        this.isLoading = false;

                        fireEvent(this.pageRef, "closeLeadfromedit", "Breed-Labrador");
                        this.showToast('Success', 'Lead converted to loan application successfully.', 'success');
                        console.log('at 1081');
                        setTimeout(() => {
                            this[NavigationMixin.Navigate]({
                                type: 'standard__recordPage',
                                attributes: {
                                    recordId: this.createdLoanId, // Replace with the dynamic record ID
                                    actionName: 'view',
                                    objectApiName: 'Opportunity' // Ensure this matches the object you're navigating to
                                },
                            });
                        }, 1000);

                    })
                    .catch(error => {
                        this.isLoading = false;
                        console.log('error>>' + JSON.stringify(error));
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: error.body.pageErrors[0].message,
                                variant: 'error',
                            }),
                        );
                    });

            })
            .catch(error => {
                this.isLoading = false;
                console.log('error>>' + JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.pageErrors[0].message,
                        variant: 'error',
                    }),
                );
            });

    }

    hideCancelrecord() {

        if (this.fillsecondinformation && (!this.fillfirstinformation) && (!this.fillthirdinformation)) {
            console.log('320');
            this.fillsecondinformation = false;
            this.fillthirdinformation = false;
            this.fillfirstinformation = true;
            this.showprev = false;
            this.shownext = true;
            this.hideNextButton = true;

            this.headerTitle = 'Enter Lead Information';
            console.log('this.currPage before', this.currPage);
            if (this.currPage != null && this.currPage != '' && this.currPage != '1') {
                this.updateRecordField(this.recordId, 'Current_Page__c', this.currPage - 1);
            }
            console.log('this.currPage after', this.currPage);
            console.log('pinno ' + this.pinno);
        }
        else if (!this.closed && !this.fillthirdinformation) {
            console.log('1625');
            this.fillthirdinformation = true;
            this.fillfourthinformation = false;
            this.headerTitle = 'Send Consent';
        }
        else {
            console.log('1631');
            console.log('channel', this.selectedchannelTypeValue);
            this.headerTitle = 'Enter Lead Information';
            this.fillsecondinformation = true;
            this.fillthirdinformation = false;
            this.fillfirstinformation = false;
            this.fillfourthinformation = false;
            this.showprev = true;
            this.shownext = true;
            if (this.currPage != null && this.currPage != '' && this.currPage != '1') {
                this.updateRecordField(this.recordId, 'Current_Page__c', this.currPage - 1);
            }
        }
        this.colormethod();
    }


    handleLoanAmountChange(event) {
        let requestedAmount = event.target.value;

        if (!/^\d*$/.test(requestedAmount)) {
            event.target.value = requestedAmount.replace(/\D/g, '');

        }

        if (requestedAmount && requestedAmount.trim() !== "") {
            this.checklAmt = true;

            getNumberToWord({ laAmt: requestedAmount })
                .then(result => {
                    this.loanamtinwords = result;
                })
                .catch(error => {
                    console.error('Error fetching converted amount', error);
                });
        } else {
            this.checklAmt = false;
        }

        if (!requestedAmount || requestedAmount.length === 0) {
            this.checklAmt = false;
        }

        if (requestedAmount >= 50000 && requestedAmount <= 50000000) {
            this.loanamt = requestedAmount;
            console.log('loanamt ' + this.loanamt);

            if (this.visibilerecord) {
                this.updateRecordField(this.recordId, 'Requested_Loan_Amount__c', this.loanamt);
                this.correctLoanAmt = true;
            } else {
                this.updateRecordField(this.newLeadId, 'Requested_Loan_Amount__c', this.loanamt);
                this.correctLoanAmt = true;
            }
        } else {
            console.log('requestedAmount-1086--' + requestedAmount);
            if (requestedAmount.length > 5) {
                console.log('requestedAmount.length ----' + requestedAmount.length);
                // this.loanAmt = requestedAmount.slice(0, -1);
                // event.target.value = this.loanAmt;
                getNumberToWord({ laAmt: requestedAmount })
                    .then(result => {
                        this.loanamtinwords = result;
                    })
                    .catch(error => {
                        console.error('Error fetching converted amount', error);
                    });
                // this.showToast('Warning', 'Loan Amount is less than 5 lakhs.', 'warning');
                //this.loanAmt = '';
                this.correctLoanAmt = true;
                console.log('requestedAmount.correctLoanAmt ----' + this.correctLoanAmt);
                return;
            } else if (requestedAmount.length <= 5) {
                console.log('requestedAmount.length ++++ ----' + requestedAmount.length);
                this.correctLoanAmt = false;
            }
        }
    }

    // handleLoanAmountChange(event) {
    //     const requestedAmount = event.target.value;

    //     if (!this.no.match(checkValidity) && this.no.length > 0) {
    //     this.showBox = false;
    //     // If input contains non-numeric characters, remove them and display an error
    //     this.no = this.no.replace(/[^0-9]/g, '');
    //     event.target.value = this.no;


    //     if(requestedAmount!=null){
    //         this.checklAmt = true;
    //         getNumberToWord({ laAmt: requestedAmount })
    //         .then(result => {
    //             this.loanamtinwords = result;
    //         })
    //         .catch(error => {
    //             console.error('Error fetching converted amount', error);
    //         });
    //     }
    //     else{
    //         this.checklAmt = false;
    //     }
    //     if(event.target.value == undefined || event.target.value == null || event.target.value.length==0){
    //         this.checklAmt = false;
    //     }

    //     if (requestedAmount >= 50000 && requestedAmount <= 50000000) {
    //         this.loanamt = requestedAmount;
    //         console.log('loanamt ' + this.loanamt);
    //         if (this.visibilerecord) {
    //             this.updateRecordField(this.recordId, 'Requested_Loan_Amount__c', this.loanamt);
    //             this.correctLoanAmt = true;
    //         }
    //         else{
    //             this.updateRecordField(this.newLeadId, 'Requested_Loan_Amount__c', this.loanamt);;
    //             this.correctLoanAmt = true;
    //         }
    //     }
    //     else {
    //         if(requestedAmount.length > 5){
    //             this.loanAmt = requestedAmount.slice(0, -1);
    //             event.target.value = this.loanAmt;
    //             this.showToast('Error','Requested loan amount should be between 50,000 and 5 Crore','error');
    //             this.loanAmt ='';
    //             this.correctLoanAmt = true;
    //             return;
    //         }
    //         else if(requestedAmount.length <= 5) {
    //             this.correctLoanAmt = false;
    //         }
    //     }
    // }

    handleLoanAmountBlur(event) {
        console.log('inisde method check------');
        let requestedAmount = event.target.value;

        if (requestedAmount < 500000 && requestedAmount.length > 0) {
            this.showToast('Warning', 'Loan amount is less than 5 lakh.', 'warning');
            //this.loanAmt = '';
            // requestedAmount = null;
            // event.target.value = requestedAmount;
            //this.loanAmt = null;
            //this.loanAmt='';
            this.loanamt = requestedAmount;
            this.checklAmt = false;
            console.log('loanamt--1780 ' + this.loanamt);
            if (this.visibilerecord) {
                this.updateRecordField(this.recordId, 'Requested_Loan_Amount__c', this.loanamt);
                this.correctLoanAmt = true;
            }
            else {
                this.updateRecordField(this.newLeadId, 'Requested_Loan_Amount__c', this.loanamt);
                this.correctLoanAmt = true;
            }
            return;
        }
        // else if( requestedAmount >50000000 && requestedAmount.length>5){
        //     requestedAmount = null;
        //     event.target.value = requestedAmount;
        //     this.loanAmt = null;
        //     this.loanAmt='';
        //     this.checklAmt = false;
        //     if (this.visibilerecord) {
        //         this.updateRecordField(this.recordId, 'Requested_Loan_Amount__c', this.loanamt);
        //         this.correctLoanAmt = true;
        //     }
        //     else{
        //         this.updateRecordField(this.newLeadId, 'Requested_Loan_Amount__c', this.loanamt);
        //         this.correctLoanAmt = true;
        //     }  
        //     return;
        // }
        else {

            this.loanAmt = requestedAmount;
            if (this.visibilerecord) {
                this.updateRecordField(this.recordId, 'Requested_Loan_Amount__c', this.loanamt);
                this.correctLoanAmt = true;
            }
        }
    }

    handlePanChange(event) {
        console.log('this.panno ' + event.target.value);
        // var panRegex = /^[A-Z]{5}[0-9]{4}[A-Z]$/;
        var panRegex = /^[A-Z]{3}P[A-Z]{1}[0-9]{4}[A-Z]{1}$/;
        //var nonIndiPanRegex = /^[A-Z]{4}[A-OQ-Z]{1}[A-Z]{1}[0-9]{4}[A-Z]{1}$/
        var specialCharactersRegex = /[!@#$%^&*(),.?":{}|<>+']/;
        var panvalue = event.target.value;
        if (panvalue != null) {
            this.panno = event.target.value.toUpperCase(); // Convert to uppercase for case-insensitive matching
            this.panLength = event.target.value.length;
        }
        else {
            this.panno = ''; // or set to a default value
            this.panLength = 0; // or set to a default length
        }
        if (this.panLength > 0) {
            console.log('1309 ');
            this.panIndex = this.panLength - 1;
            console.log('1311 ');
        }
        console.log('panIndex ' + this.panIndex);
        console.log('panno ' + this.panno);
        console.log('panLength ' + this.panLength);
        console.log('showdob ' + this.showdob);

        if (this.showdob) {
            if (this.panLength == 10) {
                if (this.panno.match(panRegex)) {
                    this.panval = false;
                    console.log('valid Pan');//pan
                    this.duplicateLeadforPan();
                }
                else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please fill the PAN in the correct format. ',
                            variant: 'error',
                        }),
                    );
                    this.panno = null;
                    return;
                    this.panval = true;
                }
            }
            else if (this.panno.length <= 5) {
                const numberPattern = /\d/; // Pattern to check for any digit
                if (numberPattern.test(this.panno)) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Numbers are not allowed in the first 5 characters.',
                            variant: 'error',
                        }),
                    );
                    this.panno = this.panno.replace(numberPattern, ''); // Remove the number
                    event.target.value = this.panno;
                    return;
                }
            }
            else if (this.panno.length > 5 && this.panno.length <= 9) {
                const characterPattern = /[A-Za-z]/;; // Pattern to check for any digit
                if (characterPattern.test(this.panno[this.panIndex])) {
                    var lastIndex = this.panno.length - 1;
                    //var thisIndex = lastIndex;
                    const secondLastChar = this.panno[lastIndex - 1];
                    console.log('1530 Captured Second Last Character: ' + secondLastChar);
                    if (lastIndex >= 0) {
                        // Remove the last character from the string
                        console.log('1534');
                        // this.panno = this.panno.replace(/\d+/g, '');
                        this.panno = this.panno.substring(0, lastIndex);
                        event.target.value = this.panno;
                    }
                    console.log('this.inputValue=:' + this.inputValue);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please fill the PAN in the correct format. ',
                            variant: 'error',
                        }),

                    );
                    return;
                }
            }
            if (this.panLength > 0 && this.panLength !== 10 && this.panno[this.panIndex].match(specialCharactersRegex)) {
                console.log('Entering 1327');
                var lastIndex = this.panno.length - 1;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please fill the PAN in the correct format.',
                        variant: 'error',
                    }),
                );
                if (lastIndex >= 0) {
                    // Remove the last character from the string
                    console.log('387');
                    // this.panno = this.panno.replace(/\d+/g, '');
                    this.panno = this.panno.substring(0, lastIndex);
                    event.target.value = this.panno;
                }
                return;
                this.panval = true;
            }
            if (this.panLength == 0) {
                console.log('1345');
                this.panval = false;
            }
            if (this.panno.length >= 4 && this.panno.charAt(3) != 'P') {
                console.log('entering');
                var lastIndex = this.panno.length - 1;
                //var thisIndex = lastIndex;
                const secondLastChar = this.panno[lastIndex - 1];
                console.log('Captured Second Last Character: ' + secondLastChar);
                if (lastIndex >= 0) {
                    // Remove the last character from the string
                    console.log('387');
                    // this.panno = this.panno.replace(/\d+/g, '');
                    this.panno = this.panno.substring(0, lastIndex);
                    event.target.value = this.panno;
                }
                console.log('this.inputValue=:' + this.inputValue);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please fill the PAN in the correct format. ',
                        variant: 'error',
                    }),

                );
                return;

            }
            if (this.panno.match(specialCharactersRegex)) {
                console.log('1559');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please fill the PAN in the correct format. ',
                        variant: 'error',
                    }),
                );
                this.panval = true;
                this.panno = null;
                event.target.value = this.panno;
                return;
            }
        }
        else {

            //var nonIndiPanRegex = /^[A-Z]{4}[A-Z]{1}[A-Z]{1}[0-9]{4}[A-Z]{1}$/
            console.log('this.btpevalue---', this.btpevalue);
            console.log('this.panno----', this.panno);
            /*if(this.btpevalue == null || this.btpevalue == undefined || this.btpevalue == ''){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter business type first to proceed further.',
                        variant: 'error',
                    }),
                );
                return;
            }*/
            var nonIndi = /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/;
            if (this.panLength == 10) {
                console.log('this.btpevalue---', this.btpevalue);
                console.log('this.panno----', this.panno);


                if (this.btpevalue != null && this.btpevalue != undefined && this.btpevalue != '') {
                    if (validateNonIndividualPAN(this.panno, this.btpevalue)) {
                        // if (this.panno.match(nonIndi)) {
                        this.panval = false;
                        console.log('valid Pan');//pan
                        this.duplicateLeadforPan();
                    }
                }
                else if (this.panno.match(nonIndi)) {
                    this.panval = false;
                    console.log('valid Pan');//pan
                    this.duplicateLeadforPan();
                }

                else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please fill the PAN in the correct format. ',
                            variant: 'error',
                        }),
                    );
                    this.panval = true;
                    this.panno = null;
                    event.target.value = this.panno;
                    return;
                }
            }
            else if (this.panno.length <= 5) {
                const numberPattern = /\d/; // Pattern to check for any digit
                if (numberPattern.test(this.panno)) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Numbers are not allowed in the first 5 characters.',
                            variant: 'error',
                        }),
                    );
                    this.panno = this.panno.replace(numberPattern, ''); // Remove the number
                    event.target.value = this.panno;
                    return;
                }
            }
            else if (this.panLength > 0 && this.panLength !== 10 && this.panno[this.panIndex].match(specialCharactersRegex)) {
                console.log('Entering 1327');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please fill the PAN in the correct format. ',
                        variant: 'error',
                    }),
                );
                return;
            }
            else if (this.panLength == 0) {
                console.log('1345');
                this.panval = false;
            }
        }
        if (event.target.value.includes('')) {
            console.log('1466');
            if (this.visibilerecord) {
                this.updateRecordField(this.recordId, 'PAN__c', event.target.value);
            }
            else {
                console.log('this.newLeadId', this.newLeadId);
                console.log('event.target.value', event.target.value);
                this.duplicateLeadforPan();
                if (this.newLeadId && this.newLeadId.length > 0) {
                    this.updateRecordField(this.newLeadId, 'PAN__c', event.target.value);
                }
            }
            return;
        }
        if (event.target.value.includes(' ')) {
            console.log('1469');
            event.target.value = this.panno;
            return;
        }

    }

    duplicateLeadforPan() {
        if (this.visibilerecord) {
            getreferenceLeadforPan({ pan: this.panno, recordId: this.recordId })
                .then(result => {
                    this.leadNameIfAnyPan = result;
                    console.log('leadNameIfAny ' + this.leadNameIfAnyPan);
                    if (this.leadNameIfAnyPan != null) {
                        this.leadname = this.leadNameIfAnyPan;
                        this.type = 'Pan';
                        this.isShownewModal = true;
                        this.checkpin = true;
                        this.isShowModal = false;
                        // this.showToast('error','similar Lead is already there' +this.leadNameIfAnyPan , 'error');
                        this.panno = '';
                        this.updateRecordField(this.recordId, 'PAN__c', '');
                        return true;
                    }
                    else {
                        if (this.visibilerecord) {
                            this.updateRecordField(this.recordId, 'PAN__c', this.panno);
                        }
                        else {
                            if (this.newLeadId) {
                                this.updateRecordField(this.newLeadId, 'PAN__c', this.panno);
                            }
                        }
                    }
                })
                .catch(error => {
                    console.error('Error fetching converted amount', error);
                });
        }
        else {
            getreferenceLeadforPan({ pan: this.panno, recordId: this.newLeadId })
                .then(result => {
                    this.leadNameIfAnyPan = result;
                    console.log('leadNameIfAny ' + this.leadNameIfAnyPan);

                    if (this.leadNameIfAnyPan != null) {
                        this.leadname = this.leadNameIfAnyPan;
                        this.type = 'Pan';
                        this.isShownewModal = true;
                        this.checkpin = true;
                        this.isShowModal = false;
                        // this.showToast('error','similar Lead is already there' +this.leadNameIfAnyPan , 'error');
                        this.panno = '';
                        this.updateRecordField(this.newLeadId, 'PAN__c', '');
                        return true;
                    }
                    else {
                        if (this.visibilerecord) {
                            this.updateRecordField(this.recordId, 'PAN__c', this.panno);
                        }
                        else {
                            if (this.newLeadId) {
                                this.updateRecordField(this.newLeadId, 'PAN__c', this.panno);
                            }
                        }
                    }
                })
                .catch(error => {
                    console.error('Error fetching converted amount', error);
                });
        }
    }

    handleOK(event) {
        this.isShownewModal = false;
        this.showfields = true;
        this.isLoading = false;
    }

    handleProductChange(event) {
        this.callTopUpCmp = false;
        // console.log('event.target.label --> '+JSON.stringify(event.target.label));
        this.selectedProductType = event.target.value;
        console.log('selectedProductType ' + this.selectedProductType);
        console.log('visibilerecord ' + this.visibilerecord);
        console.log('visibilerecord ' + this.hasHLPermission);
        console.log('visibilerecord ' + this.callTopUpCmp);
        //HL-Ishi-31/10
        if (this.hasHLPermission && this.selectedProductType == 'Flexi Loan') {
            this.callTopUpCmp = true;
            console.log('visibilerecord ' + this.callTopUpCmp);
        }
        //HL-Ishi-31/10
        else if (this.selectedProductType == 'Home Loan') {
            console.log('this.showPan', this.showPan);
            //this.showPan = true;
            this.inputLabel = 'Constitution';
        } else {
            console.log('this.showPan', this.showPan);
            this.showPan = false;
            this.inputLabel = 'Business Type';
        }
        console.log('Saving product to record:', this.selectedProductType);
        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'Product__c', this.selectedProductType);

        }
        else {
            if (this.newLeadId != null && this.newLeadId != '') {
                this.updateRecordField(this.newLeadId, 'Product__c', this.selectedProductType);
            }
            console.log('inside 1892');
        }
    }

    handlepincodelookupdeselected(event) {

        this.pinno = null;
        this.cityValue = null;
        this.stateValue = null;
        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'Pincode__c', null);
            this.updateRecordField(this.recordId, 'City__c', null);
            this.updateRecordField(this.recordId, 'State__c', null);
        }
        else {
            this.updateRecordField(this.newLeadId, 'Pincode__c', null);
            this.updateRecordField(this.newLeadId, 'City__c', null);
            this.updateRecordField(this.newLeadId, 'State__c', null);
        }

        this.pincodeFilled = false;
        this.servicable = true;
        console.log('inside handlepincodelookupdeselected');
        try {
            fireEvent(this.pageRef, "branchReset", "Breed-Labrador");
        }
        catch (error) {
            console.log('error=>', JSON.stringify(error));
        }
    }

    handleSelectDsaUser(event) {
        try {
            const record = event.detail.searchRecord;

            console.log('Selected Record (RAW):', record);
            console.log('Channel:', this.selectedchannelTypeValue);

            // ✅ Always set dsaId (IMPORTANT - even for Connector)
            this.dsaId = record?.Id || '';
            this.dsaname = record?.Name || '';

            // ✅ Set name/code safely
            this.nameValue = record?.Name || '';
            this.codeValue = record?.Vendor_Code__c || '';

            // ✅ Optional clarity (tracking)
            if (this.selectedchannelTypeValue === 'Connector') {
                this.connectorId = this.dsaId;
                this.connectorName = this.dsaname;
            }

            console.log('Final values ->', {
                dsaId: this.dsaId,
                nameValue: this.nameValue,
                codeValue: this.codeValue
            });

            // 🚨 HARD GUARD — prevents your exact issue
            if (!this.dsaId) {
                console.error('ERROR: dsaId is undefined/null → lookup not returning ID');
                return;
            }

            const leadId = this.visibilerecord ? this.recordId : this.newLeadId;

            // ✅ Update fields (same as PROD logic)
            this.updateRecordField(leadId, 'DSA_Account__c', this.dsaId);
            this.updateRecordField(leadId, 'Channel_Name__c', this.nameValue);
            this.updateRecordField(leadId, 'Channel_Code__c', this.codeValue);

        } catch (error) {
            console.log('error =>', JSON.stringify(error));

            if (error?.body?.message) {
                console.log('Apex error message:', error.body.message);
            } else if (error?.message) {
                console.log('JS error message:', error.message);
            } else {
                console.log('Unknown error:', error);
            }
        }
    }
    handleSelectedConnectorUser(event) {
        try {

            this.connectorId = event.detail.searchRecord.Id;
            this.connectorName = event.detail.searchRecord.Name;
            /*this.codeValue = event.detail.searchRecord.Vendor_Code__c;
            this.nameValue = event.detail.searchRecord.Name;*/
            //console.log('event.detail.searchRecord.Id', event.detail.searchRecord.Account.Name);
            // this.dsaname = event.detail.searchRecord.User__r.Name; // Fetch the 'id' field from the event's detail
            // console.log('Received ID: dsaname',  this.dsaname);

            // If you need a name or other fields, you will need to fetch them separately
            if (this.visibilerecord) {
                this.updateRecordField(this.recordId, 'DSA_Account__c', this.dsaId);
                this.updateRecordField(this.recordId, 'Channel_Code__c', this.codeValue);
                this.updateRecordField(this.recordId, 'Channel_Name__c', this.nameValue);
            }
            else {
                this.updateRecordField(this.newLeadId, 'DSA_Account__c', this.dsaId);
                this.updateRecordField(this.newLeadId, 'Channel_Code__c', this.codeValue);
                this.updateRecordField(this.newLeadId, 'Channel_Name__c', this.nameValue);

            }

        } catch (error) {
            console.log('error=>', JSON.stringify(error));
            console.log('error=>', JSON.stringify(error));
            if (error && error.body && error.body.message) {
                console.log('Apex error message:', error.body.message);
            } else if (error && error.message) {
                console.log('JS error message:', error.message);
            } else {
                console.log('Unknown error:', error);
            }
        }
    }
    handleDeleteDsaUser(event) {
        this.dsaId = '';
        this.dsaname = '';
        // if(event.detail.label == 'DSA'){
        this.codeValue = undefined;
        this.nameValue = undefined;
        //}
        //console.log('event.detail.searchRecord.Id', event.detail.searchRecord.Account.Name);
        // this.dsaname = event.detail.searchRecord.User__r.Name; // Fetch the 'id' field from the event's detail
        // console.log('Received ID: dsaname',  this.dsaname);

        // If you need a name or other fields, you will need to fetch them separately
        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'DSA_Account__c', this.dsaId);
            // if(event.detail.label == 'DSA'){
            this.updateRecordField(this.recordId, 'Channel_Code__c', this.codeValue);
            this.updateRecordField(this.recordId, 'Channel_Name__c', this.nameValue);
            // }
        }
        else {
            this.updateRecordField(this.newLeadId, 'DSA_Account__c', this.dsaId);
            // if(event.detail.label == 'DSA'){
            this.updateRecordField(this.newLeadId, 'Channel_Code__c', this.codeValue);
            this.updateRecordField(this.newLeadId, 'Channel_Name__c', this.nameValue);
            //  }

        }
    }

    //review
    handleSelectedRow(event) {
        //console.log('event.detail pincode: '+ JSON.stringify(event.detail));

        //const { id, is_serviceable, pincodeAllData } = event.detail;
        //const pinId =  event.detail.id;
        //console.log('Received ID:', id);
        //console.log('Is Serviceable:', is_serviceable);
        //console.log('Pincode Data:', pincodeAllData);

        this.pinno = event.detail.searchRecord.Id;
        this.pincodename = event.detail.searchRecord.Name;
        this.cityValue = (event.detail.searchRecord.City__r && event.detail.searchRecord.City__r.Name) || this.cityValue;
        this.stateValue = event.detail.searchRecord.State__c || this.stateValue;
        //if(this.BL){
        console.log('event.detail.searchRecord.Is_Pincode_Servicable__c', event.detail.searchRecord.Is_Pincode_Servicable__c);
        this.servicable = event.detail.searchRecord.Is_Pincode_Servicable__c;
        //}
        this.pincodecheck = false;
        this.showfields = true;
        this.tehsiltown = true;
        this.pincodeFilled = true

        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'Pincode__c', this.pinno);
            this.updateRecordField(this.recordId, 'City__c', this.cityValue);
            this.updateRecordField(this.recordId, 'State__c', this.stateValue);
        }
        else {
            this.updateRecordField(this.newLeadId, 'Pincode__c', this.pinno);
            this.updateRecordField(this.newLeadId, 'City__c', this.cityValue);
            this.updateRecordField(this.newLeadId, 'State__c', this.stateValue);
        }
    }

    isDisableCustomerProf = false

    handleCustomerTypeChange(event) {
        this.customerType = event.detail.value;
        this.custProfile = '';
        this.custProfileOptions = this.custProfileOptionsActual.filter(opt => opt.validFor.includes(this.custProfileOptionsController[this.customerType]));
        console.log('this.custProfileOptions##', JSON.stringify(this.custProfileOptions));
        /*if(this.custProfileOptions.length >= 1){
            this.custProfile = this.custProfileOptions[0].label
            // this.loantypeClosed = true
        }*/

        if (this.selectedProductType == 'Business Loan' && this.customerType == 'Individual') {
            //this.custProfile = 'SEP';
            this.isDisableCustomerProf = true;
        } else {
            this.isDisableCustomerProf = false;
        }
        if (this.customerType != null && this.customerType != undefined && this.customerType != '') {
            this.showCustProfile = true;
        }
        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'Customer_Type__c', this.customerType);
            this.updateRecordField(this.recordId, 'Employment_Type__c', this.custProfile);
        }
        else {
            if (this.newLeadId != null && this.newLeadId != '') {
                this.updateRecordField(this.newLeadId, 'Customer_Type__c', this.customerType);
                this.updateRecordField(this.recordId, 'Employment_Type__c', this.custProfile);
            }
        }

        if (this.customerType == 'Individual') {
            this.shownonindi = false;
            this.showindi = true;
            this.showdob = true;
        }
        else if (this.customerType == 'Non Individual') {
            // this.inputValue2 = '';
            this.shownonindi = true;
            this.showindi = false;
            this.showdob = false;
        }
        else {
            //this.inputValue2 = '';
            this.shownonindi = true;
            this.showindi = false;
            this.showdob = false;
        }
    }
    handleProfileChange(event) {
        console.log('handleProfileChange.value##', event.target.value);
        this.custProfile = event.target.value;
        try {
            sessionStorage.setItem('custProfile', this.custProfile);
            const key = this.controllerValues[this.custProfile];
            console.log('key##', key);
            const filteredOptions = this.btypeval.filter(opt => opt.validFor.includes(key))
                .map(opt => ({ label: opt.label, value: opt.value }));
            this.businessTypeOptions = [...filteredOptions];
            //this
            console.log('this.businessTypeOptions##', JSON.stringify(this.businessTypeOptions));
            this.btypevalue = undefined;
            console.log('this.custProfile>>', this.custProfile);
            if (this.custProfile == 'SEP' || this.custProfile == 'SENP') {
                console.log('inside');
                this.showBusinessDetails = true;
            } else {
                this.showBusinessDetails = false;
            }
            /* if(this.custProfile == 'SEP'){
                 this.updateRecordField(this.recordId, 'Company', null);
                 this.updateRecordField(this.recordId, 'COMM_Contact_Person_Name__c', null);
             }*/
            this.updateRecordField(this.recordId, 'Business_Type__c', null);
            if (this.visibilerecord) {
                // this.updateRecordField(this.recordId, 'Employment_Type__c', this.custProfile);

            }
            else {
                if (this.newLeadId != null && this.newLeadId != '') {
                    //this.updateRecordField(this.recordId, 'Employment_Type__c', this.custProfile);
                }
            }
        } catch (error) {
            console.log('error>>', error);
        }
    }

    handleDateChange(event) {
        const selectedDate = new Date(event.target.value);
        const currentDate = new Date();
        // const age = currentDate.getFullYear() - selectedDate.getFullYear();


        const minAllowedDate = new Date();
        minAllowedDate.setFullYear(currentDate.getFullYear() - 130); // 130 years ago  

        const maxAllowedDate = new Date();
        maxAllowedDate.setFullYear(currentDate.getFullYear() - 18);

        console.log('minAllowedDate--', minAllowedDate);
        console.log('maxAllowedDate--', maxAllowedDate);


        //  if(age >= 18 && age <= 130) {
        if (selectedDate >= minAllowedDate && selectedDate <= maxAllowedDate) {
            this.dateOfBirth = event.target.value;
            console.log('dateOfBirth ' + this.dateOfBirth);

            if (this.recordId) {
                this.updateRecordField(this.recordId, 'Date_of_Birth__c', this.dateOfBirth);
            }
            else {
                this.updateRecordField(this.newLeadId, 'Date_of_Birth__c', this.dateOfBirth);
            }
        }
        else {
            this.showToast('Error', 'Age should be more than 18 years.', 'error');
            this.dateOfBirth = null;
            event.target.value = '';
        }
    }
    handleDobBlurChange(event) {
        const datePattern = /^\d{4}-\d{2}-\d{2}$/; // Pattern for YYYY-MM-DD format
        const dateValue = event.target.value;
        if (this.siteUser) {
            const selectedDate = new Date(event.target.value);
            const currentDate = new Date();
            const age = currentDate.getFullYear() - selectedDate.getFullYear();
            if (age >= 18 && age <= 130) {

            }
            else {
                this.dateOfBirth = '';
                event.target.value = this.dateOfBirth;
            }
        }
        else {
            console.log('1512 ' + event.target.value);
        }
        if (dateValue != null && dateValue != '') {
            if (!dateValue.match(datePattern)) {
                this.dateOfBirth = '';
                event.target.value = this.dateOfBirth;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Enter a valid date',
                        variant: 'error',
                    }),
                );
                return;
            }
        }
    }

    handleDateofIncChange(event) {
        const selectedDate = new Date(event.detail.value);
        this.dateofInc = event.detail.value;
        const currentDate = new Date();

        if (selectedDate > currentDate) {
            this.showToast('Error', 'Date of Incorporation should not be a future date.', 'error');
            this.dateofInc = '';
            // this.dateofInc = null; 
            // event.detail.value = this.dateofInc;
        }
        else {
            this.dateofInc = event.detail.value;
            if (this.visibilerecord) {
                this.updateRecordField(this.recordId, 'Date_of_Incorporation__c', this.dateofInc);
            }
            else {
                this.updateRecordField(this.newLeadId, 'Date_of_Incorporation__c', this.dateofInc);
            }
            this.calculateYearsDifference(this.dateofInc);
        }
    }

    calculateYearsDifference(date) {
        const currentDate = new Date();
        const inputDate = new Date(date);
        let yearsDifference = currentDate.getFullYear() - inputDate.getFullYear();
        if (currentDate.getMonth() < inputDate.getMonth() || (currentDate.getMonth() === inputDate.getMonth() && currentDate.getDate() < inputDate.getDate())) {
            yearsDifference--;
        }
        this.bvintage = yearsDifference;
        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'Business_Vintage__c', this.bvintage);
        }
        else {
            this.updateRecordField(this.newLeadId, 'Business_Vintage__c', this.bvintage);
        }
    }

    handleIncBlur(event) {
        console.log('siteUser ' + this.siteUser);
        if (this.siteUser) {
            console.log('1479');
            const selectedDate = new Date(event.target.value);
            console.log('selectedDate ' + selectedDate);
            // this.dateofInc =  event.detail.value;
            const currentDate = new Date();
            console.log('currentDate ' + currentDate);
            console.log('1483');
            console.log('1483');
            if (selectedDate > currentDate) {
                // this.showToast('Error','Date of Incorporation should not be a future date','error');
                console.log('1485');
                this.dateofInc = '';
                event.target.value = this.dateofInc;
            }
            else {
                console.log('1489');
                this.dateofInc = event.detail.value;
                if (this.visibilerecord) {
                    this.updateRecordField(this.recordId, 'Date_of_Incorporation__c', this.dateofInc);
                }
                else {
                    this.updateRecordField(this.newLeadId, 'Date_of_Incorporation__c', this.dateofInc);
                }
            }
        }
        else {
            console.log('1560');
        }
    }

    value = "";

    handlebInudstry(event) {
        this.bindustval = event.detail.value;

        const exists = this.bindustryvalues.some(item => item.value === this.bindustval);
        if (exists) {
            if (this.visibilerecord) {
                this.updateRecordField(this.recordId, 'Industry', this.bindustval);
            }
            else {
                this.updateRecordField(this.newLeadId, 'Industry', this.bindustval);
            }
        }
        // else {
        //     this.showToast('Error','Please select from the options below','error');
        //     this.bindustval = null;
        //     event.target.value = '';
        // }
    }
    hanldeIndustryonBlur(event) {
        const exists = this.bindustryvalues.some(item => item.value === this.bindustval);
        if (exists) {
        }
        else {
            this.showToast('Error', 'Please select from the options below', 'error');
            this.bindustval = null;
            event.target.value = '';
        }
    }

    handleVintageChange(event) {
        this.bvintage = event.detail.value;
        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'Business_Vintage__c', this.bvintage);
        }
        else {
            this.updateRecordField(this.newLeadId, 'Business_Vintage__c', this.bvintage);
        }
    }

    closelead() {
        this.dispositionlost = true;
        if (this.isIOS || this.isWindows) {
            const scrollOptions = {
                left: 0,
                top: window.innerHeight / 2, // Calculate the middle of the page
                behavior: 'smooth'
            };
            window.scrollTo(scrollOptions);

        }

        if (this.isAndroid) {
            const scrollOptions = {
                left: 0,
                top: document.body.scrollHeight / 2, // Calculate the middle of the page
                behavior: 'smooth'
            };
            window.scrollTo(scrollOptions);
        }
        // this.showfields = false;
    }

    handleDispositionClosed() {
        this.dispositionlost = false;
        this.showfields = true;
    }

    get maskedPhoneNumber() {
        if (this.no && this.no.length === 10 && !isNaN(this.no) && this.optverif) {
            return 'XXXXXX' + this.no.slice(-4);
        }
        return this.no;
    }

    redirectorclose() {
        console.log('dsa ' + this.dsa + 'telesales ' + this.telesales + 'salesexecutive ' + this.salesexecutive);
        console.log('visible record ' + this.visibilerecord + 'mobile ' + this.isMobile);
        if (this.isMobile) {
            console.log('mobile')
            if (this.telesales || this.salesexecutive || this.systemAdmin) {
                console.log('inside telesales');
                this[NavigationMixin.Navigate]({
                    type: 'standard__navItemPage',
                    attributes: { apiName: 'Home_Page' }
                });
            }
            else {
                if (this.dsa) {
                    console.log('dsa')
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: '/losportal/s/'
                        }
                    });
                }
            }
        }
        else {
            if (this.visibilerecord) {
                console.log('visibilerecord' + this.systemAdmin)
                console.log(this.telesales + 'this.telesales')
                if (this.telesales || this.salesexecutive || this.systemAdmin) {
                    console.log('inside telesales');
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: 'lightning/n/Sales_Home'
                        }
                    });
                }
                else {
                    if (this.dsa) {
                        console.log('dsa')

                        this[NavigationMixin.Navigate]({
                            type: 'standard__webPage',
                            attributes: {
                                url: '/losportal/s/'
                            }
                        });
                    }
                }
            }
            else {
                console.log('else test')
                // const closevent = new CustomEvent('closelead');
                // this.dispatchEvent(closevent);
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: 'lightning/n/Home'
                    }
                });

            }
        }
    }

    handleClose() {
        this.dispositionlost = false;
        this.isHotWarm = false
    }

    handledispositionsave() {
        this.dispositionlost = false;
        this.showfields = true;

        if (this.mobile) {
            this.updateleaddetails();
        }
        else {
            if (this.isDesktop) {
                const closevent = new CustomEvent('closelead');
                this.dispatchEvent(closevent);
            }
            else {
                this.updateleaddetails();
            }
        }
    }

    handleYesofromMobileandPin() {
        this.isShownewModal = false;
        this.showfields = true;
        this.isLoading = false;
    }

    onabandonprev(event) {
        this.isShownewModal = false;
        this.showfields = true;
        this.isLoading = false;
        if (this.no.length === 10) {
            this.isLoading = true;
            if (!this.visibilerecord) {
                if (!this.newLeadId) {
                    console.log('inputValue ' + this.inputValue);
                    console.log('inputValue2 ' + this.inputValue2);
                    console.log('this.assignedRo reflead --> ' + this.assignedRo);
                    console.log('selected Product type>' + this.selectedProductType);
                    console.log('salesexecutive>' + this.salesexecutive);

                    if ((((this.inputValue2 && this.inputValue2.length >= 2) && (this.inputValue && this.inputValue.length >= 1)) ||
                        ((this.entityname && this.entityname.length >= 2) && (this.contactName && this.contactName.length >= 2))) &&
                        this.selectedProductType != null && this.customerType != null) {

                        createLead({
                            firstName: this.inputValue,
                            middleName: this.middlename,
                            lastName: this.inputValue2,
                            mobileNumber: this.no,
                            company: this.entityname,
                            contactPersonName: this.contactName,
                            custType: this.customerType,
                            channel: this.selectedchannelTypeValue,
                            employementType: this.custProfile,
                            productType: this.selectedProductType,
                            pan: this.panno,
                            salesExecutive: this.salesexecutive
                        })
                            .then(newLead => {
                                console.log(',this.selectedProductType.dobordoi----' + this.selectedProductType);
                                console.log(',this.selectedProductType.dobordoi----' + this.loanSource);
                                console.log(',this.selectedProductType.dobordoi----' + this.referenceNumber);
                                if (this.selectedProductType == 'Flexi Loan' && this.hasHLPermission) {
                                    // this.purposeOfLoanValue = this.purposeOfLoanValue.filter(option => option.value == 'Flexi Loan Personal Expenses' || option.value == 'Flexi Loan Others' || option.value == 'Flexi Loan Family Expenses' || option.value == 'Flexi Loan Consumer Durable' );
                                    //HL_Ishi
                                    if (this.selectedCustId != null && this.selectedCustId != '' && this.selectedCustId != null) {
                                        console.log('Inside 1110------' + this.selectedCustId);
                                        this.updateRecordField(newLead, 'HL_Customer_LMS_ID__c', this.selectedCustId);
                                    }
                                    console.log(',this.dobordoi----' + this.dobordoi);
                                    if (this.customerType == 'Individual') {
                                        this.updateRecordField(newLead, 'Date_of_Birth__c', this.dobordoi);
                                    }
                                    else {
                                        this.updateRecordField(newLead, 'Date_of_Incorporation__c', this.dobordoi);
                                    }
                                    console.log(',refff numberr---' + this.referenceNumber);
                                    this.updateRecordField(newLead, 'FL_Source__c', this.loanSource);
                                    this.updateRecordField(newLead, 'Parent_Loan_Number__c', this.referenceNumber);

                                }

                                console.log('newLead ' + newLead);
                                this.newLeadId = newLead;
                                this.leadId = this.newLeadId;
                                this.ntbScreen = true;
                                this.updateRecordField(this.newLeadId, 'Current_Page__c', 2);

                                console.log('newLeadId ' + this.newLeadId);
                                this.showToast('Success', 'Lead record has been created successfully.', 'success');
                                this.isLoading = false;
                                this.oldno = this.no;

                                var childCompVar = this.template.querySelector('c-lead-stage-path');
                                var sendParam = { 'recordId': newLead };
                                childCompVar.refreshChild(sendParam);

                                if (newLead != null) {
                                    this.showBox = true;

                                    getreferenceLeadname({ recordId: this.newLeadId })
                                        .then(name => {
                                            this.showLead = true;
                                            this.createdleadName = name;
                                            this.leadinwords = 'Lead ' + this.createdleadName + ' is created.';
                                            if (this.telesales || this.others || this.dsa || this.salesexecutive) {
                                                const allowedLabels = ['DSA', 'Corporate DSA'];
                                                this.channelvaluesRo = this.dsa ? this.channelvaluesRo.filter(item => allowedLabels.includes(item.label)) : this.channelvaluesRo.values;
                                                console.log('this.dsa', this.dsa);
                                                this[NavigationMixin.Navigate]({
                                                    type: 'standard__recordPage',
                                                    attributes: {
                                                        recordId: this.newLeadId,
                                                        objectApiName: 'Lead',
                                                        actionName: 'view'
                                                    }
                                                });
                                            } else if (this.salesexecutive && this.isMobile) {
                                                this[NavigationMixin.Navigate]({
                                                    type: 'standard__recordPage',
                                                    attributes: {
                                                        recordId: this.newLeadId,
                                                        objectApiName: 'Lead',
                                                        actionName: 'view'
                                                    }
                                                });
                                            }
                                        })
                                }
                            })
                            .catch(error => {
                                console.error('Error creating Lead: ', JSON.stringify(error));
                            });
                    } else {
                        if (this.customerType == 'Individual' && (!this.inputValue || !this.inputValue2)) {
                            this.showToast('Error', 'Kindly add first name and last name first before you enter the mobile number', 'error');
                        } else if (this.customerType == 'Individual' && (!this.inputValue || this.inputValue.length < 1)) {
                            this.showToast('Error', 'Please enter a first name with at least 1 character and a maximum of 50 characters.', 'error');
                        } else if (this.customerType == 'Individual' && (!this.inputValue2 || this.inputValue2.length < 2)) {
                            this.showToast('Error', 'Please enter a last name with at least 2 characters and a maximum of 50 characters.', 'error');
                        } else if (this.customerType == 'Non Individual' && (!this.entityname || this.entityname.length < 2)) {
                            this.showToast('Error', 'Please enter an Entity Name with at least 2 characters and a maximum of 50 characters.', 'error');
                        } else if (this.customerType == 'Non Individual' && (!this.contactName || this.contactName.length < 2)) {
                            this.showToast('Error', 'Please enter a Contact Person Name with at least 2 characters and a maximum of 50 characters.', 'error');
                        }
                    }
                } else {
                    this.updateRecordField(this.recordId, 'MobilePhone', this.no);
                }
            }
        }
    }

    onapproval(event) {
        this.isShownewModal = false;
        this.showfields = true;
        this.isLoading = false;
        if (this.no.length === 10) {
            this.isLoading = true;
            if (!this.visibilerecord) {
                if (!this.newLeadId) {
                    console.log('inputValue ' + this.inputValue);
                    console.log('inputValue2 ' + this.inputValue2);
                    console.log('this.assignedRo reflead --> ' + this.assignedRo);
                    console.log('selected Product type>' + this.selectedProductType);
                    console.log('salesexecutive>' + this.salesexecutive);

                    if ((((this.inputValue2 && this.inputValue2.length >= 2) && (this.inputValue && this.inputValue.length >= 1)) ||
                        ((this.entityname && this.entityname.length >= 2) && (this.contactName && this.contactName.length >= 2))) &&
                        this.selectedProductType != null && this.customerType != null) {

                        createLead({
                            firstName: this.inputValue,
                            middleName: this.middlename,
                            lastName: this.inputValue2,
                            mobileNumber: this.no,
                            company: this.entityname,
                            contactPersonName: this.contactName,
                            custType: this.customerType,
                            channel: this.selectedchannelTypeValue,
                            employementType: this.custProfile,
                            productType: this.selectedProductType,
                            pan: this.panno,
                            salesExecutive: this.salesexecutive
                        })
                            .then(newLead => {
                                console.log(',this.selectedProductType.dobordoi----' + this.selectedProductType);
                                console.log(',this.selectedProductType.dobordoi----' + this.loanSource);
                                console.log(',this.selectedProductType.dobordoi----' + this.referenceNumber);
                                if (this.selectedProductType == 'Flexi Loan' && this.hasHLPermission) {
                                    // this.purposeOfLoanValue = this.purposeOfLoanValue.filter(option => option.value == 'Flexi Loan Personal Expenses' || option.value == 'Flexi Loan Others' || option.value == 'Flexi Loan Family Expenses' || option.value == 'Flexi Loan Consumer Durable' );
                                    //HL_Ishi
                                    if (this.selectedCustId != null && this.selectedCustId != '' && this.selectedCustId != null) {
                                        console.log('Inside 1110------' + this.selectedCustId);
                                        this.updateRecordField(newLead, 'HL_Customer_LMS_ID__c', this.selectedCustId);
                                    }
                                    console.log(',this.dobordoi----' + this.dobordoi);
                                    if (this.customerType == 'Individual') {
                                        this.updateRecordField(newLead, 'Date_of_Birth__c', this.dobordoi);
                                    }
                                    else {
                                        this.updateRecordField(newLead, 'Date_of_Incorporation__c', this.dobordoi);
                                    }
                                    console.log(',refff numberr---' + this.referenceNumber);
                                    this.updateRecordField(newLead, 'FL_Source__c', this.loanSource);
                                    this.updateRecordField(newLead, 'Parent_Loan_Number__c', this.referenceNumber);

                                }

                                console.log('newLead ' + newLead);
                                this.newLeadId = newLead;
                                this.leadId = this.newLeadId;
                                this.ntbScreen = true;
                                this.updateRecordField(this.newLeadId, 'Current_Page__c', 2);

                                console.log('newLeadId ' + this.newLeadId);
                                this.showToast('Success', 'Lead record has been created successfully.', 'success');
                                this.isLoading = false;
                                this.oldno = this.no;

                                var childCompVar = this.template.querySelector('c-lead-stage-path');
                                var sendParam = { 'recordId': newLead };
                                childCompVar.refreshChild(sendParam);

                                if (newLead != null) {
                                    this.showBox = true;

                                    getreferenceLeadname({ recordId: this.newLeadId })
                                        .then(name => {
                                            this.showLead = true;
                                            this.createdleadName = name;
                                            this.leadinwords = 'Lead ' + this.createdleadName + ' is created.';
                                            if (this.telesales || this.others || this.dsa || this.salesexecutive) {
                                                const allowedLabels = ['DSA', 'Corporate DSA'];
                                                this.channelvaluesRo = this.dsa ? this.channelvaluesRo.filter(item => allowedLabels.includes(item.label)) : this.channelvaluesRo.values;
                                                console.log('this.dsa', this.dsa);
                                                this[NavigationMixin.Navigate]({
                                                    type: 'standard__recordPage',
                                                    attributes: {
                                                        recordId: this.newLeadId,
                                                        objectApiName: 'Lead',
                                                        actionName: 'view'
                                                    }
                                                });
                                            } else if (this.salesexecutive && this.isMobile) {
                                                this[NavigationMixin.Navigate]({
                                                    type: 'standard__recordPage',
                                                    attributes: {
                                                        recordId: this.newLeadId,
                                                        objectApiName: 'Lead',
                                                        actionName: 'view'
                                                    }
                                                });
                                            }

                                            const inputMap = {
                                                'leadId': this.newLeadId,
                                                'oldLeadId': this.leadNameIfAny
                                            }
                                            submitForApproval({ inputMap: inputMap })
                                                .then(result => {
                                                    console.log('resul in approval---', result);
                                                    if (result == 'success') {
                                                        this.showToast('Success', 'Approval has been sent to branch head.', 'success');
                                                        // this.connectedCallback();
                                                        location.reload();
                                                    } else {
                                                        this.showToast('Error', 'Error sending approval.', 'error');
                                                    }

                                                })
                                        })
                                }
                            })
                            .catch(error => {
                                console.error('Error creating Lead: ', JSON.stringify(error));
                            });
                    } else {
                        if (this.customerType == 'Individual' && (!this.inputValue || !this.inputValue2)) {
                            this.showToast('Error', 'Kindly add first name and last name first before you enter the mobile number', 'error');
                        } else if (this.customerType == 'Individual' && (!this.inputValue || this.inputValue.length < 1)) {
                            this.showToast('Error', 'Please enter a first name with at least 1 character and a maximum of 50 characters.', 'error');
                        } else if (this.customerType == 'Individual' && (!this.inputValue2 || this.inputValue2.length < 2)) {
                            this.showToast('Error', 'Please enter a last name with at least 2 characters and a maximum of 50 characters.', 'error');
                        } else if (this.customerType == 'Non Individual' && (!this.entityname || this.entityname.length < 2)) {
                            this.showToast('Error', 'Please enter an Entity Name with at least 2 characters and a maximum of 50 characters.', 'error');
                        } else if (this.customerType == 'Non Individual' && (!this.contactName || this.contactName.length < 2)) {
                            this.showToast('Error', 'Please enter a Contact Person Name with at least 2 characters and a maximum of 50 characters.', 'error');
                        }
                    }
                } else {
                    this.updateRecordField(this.recordId, 'MobilePhone', this.no);
                }
            }
        }
    }
    getDSADetails() {
        fetchDSAContact().then(result => {
            console.log('result account team members>>' + JSON.stringify(result));
            if (!this.fromChannelChange) {
                this.selectedchannelTypeValue = result[0].Account.Corporate_DSA__c ? 'Corporate DSA' : 'DSA';
            }
            this.nameValue = this.selectedchannelTypeValue == 'DSA' ? result[0].Name : result[0].Account.Name;
            this.codeValue = result[0].Account.Vendor_Code__c;
        })
            .catch(error => {
                console.log('error account team members>>', JSON.stringify(error));
            })
    }
    leaddetails() {
        console.log('leadId 1059' + this.recordId);
        this.isLoading = true;

        fetchleaddetails({ leadId: this.recordId, processName: 'LeadManagement' })
            .then(result => {
                console.log('LeadManagement: ', result);
                this.check = result;

                if (this.check) {
                    //HL-Ishi-31/10/2025
                    if (this.isHLUser) {
                        this.isApprovalPending = this.check[0].Dedupe_Approval_Status__c == 'Send for Approval' ? true : false;
                    }
                    if (this.check[0].Product__c == 'Flexi Loan' && this.hasHLPermission) {
                        this.purposeOfLoanValue = this.purposeOfLoanValue.filter(option => option.value == 'Flexi Loan Personal Expenses' || option.value == 'Flexi Loan Others' || option.value == 'Flexi Loan Family Expenses' || option.value == 'Flexi Loan Consumer Durable');
                        this.purposeOfLoan = this.check[0].COMM_Purpose_of_Loan__c === undefined ? '' : this.check[0].COMM_Purpose_of_Loan__c;
                        this.parentLoanNumberFL = this.check[0].Parent_Loan_Number__c;
                        this.sourceSystemFL = this.check[0].FL_Source__c;
                    }
                    else {
                        this.purposeOfLoan = this.check[0].COMM_Purpose_of_Loan__c === undefined ? '' : this.check[0].COMM_Purpose_of_Loan__c;
                    }
                    //HL-Ishi-31/10/2025                       
                    console.log('substatus--' + this.check[0].Lead_Sub_Status__c);
                    //this.loantypeClosed = this.check[0].Lead_Sub_Status__c == 'Converted' ? true : false;
                    //this.CustProfileDisabled = this.loantypeClosed == true? true : false;
                    this.pinno = this.check[0].Pincode__c != null ? this.check[0].Pincode__c : null;
                    console.log('pinno ' + this.pinno);

                    if (this.pinno != null) {
                        console.log('1324');
                        this.pincodename = this.check[0].Pincode__r.Name;
                        console.log('pincodename ' + this.pincodename);
                        this.showpincode = true;
                        this.pincodeFilled = true;
                    }
                    else {
                        this.showpincode = true;
                        this.pincodeFilled = false;
                    }

                    this.btpevalue = this.check[0].Business_Type__c;
                    this.offownerval = this.check[0].Office_Ownership__c;
                    this.turnover = this.check[0].Turnover_Yearly__c ? this.check[0].Turnover_Yearly__c : this.check[0].COMM_Business_Turnover__c;
                    this.purposeOfLoan = this.check[0].COMM_Purpose_of_Loan__c === undefined ? '' : this.check[0].COMM_Purpose_of_Loan__c;
                    this.leadGender = this.check[0].GenderIdentity;
                    this.subProduct = this.check[0].Sub_Product__c;
                    this.alternateMobile = this.check[0].Alternate_Mobile_Number__c;
                    this.cityValue = this.check[0].City__c;
                    this.stateValue = this.check[0].State__c;
                    this.campValue = this.check[0].COMM_Campaign_Code__c;
                    this.emailno = this.check[0].Email;
                    this.inputValue = this.check[0].FirstName;
                    this.inputValue2 = this.check[0].LastName;
                    this.entityname = this.check[0].Company;
                    this.contactName = this.check[0].COMM_Contact_Person_Name__c;
                    this.middlename = this.check[0].MiddleName;
                    this.selectedchannelTypeValue = this.check[0].Channel__c === undefined ? '' : this.check[0].Channel__c;
                    console.log('this.selectedchannelTypeValue', this.selectedchannelTypeValue);
                    if ((this.check[0].Channel__c || '').trim() === 'Online') {
                        this.isOnlineLead = true;
                        if (this.check[0].Product__c != null && this.check[0].Product__c !== '') this.productDisabled = true;
                        if (this.check[0].MobilePhone != null && this.check[0].MobilePhone !== '') this.disableMobile = true;
                    }
                    this.hideNameAndCode = this.isDirectLike(this.selectedchannelTypeValue) || this.selectedchannelTypeValue === 'Campaign' || this.selectedchannelTypeValue === '' ? true : false;
                    this.showCampaignCode = this.selectedchannelTypeValue == 'Campaign' ? true : false;
                    this.leadSource = this.check[0].LeadSource;
                    this.customerType = this.check[0].Customer_Type__c;
                    this.custProfile = this.check[0].Employment_Type__c;
                    console.log('this.custProfile##', this.custProfile);
                    this.nameValue = this.check[0].Channel_Name__c;
                    this.codeValue = this.check[0].Channel_Code__c;
                    this.isConsentReceived = this.check[0].COMM_Is_Consent_Received__c;
                    this.consentStatus = this.check[0].COMM_Consent_Status__c;
                    this.leadNotAssigned = this.check[0].Branch__c === undefined ? true : false;
                    if (this.pinno != null && this.pinno != '') {
                        this.servicable = this.check[0].Is_Pincode_Serviceable__c;
                    }
                    console.log('this.servicable>>' + this.servicable);
                    console.log('Branch__c>>' + this.check[0].Branch__c);
                    if (this.custProfile == 'SEP' || this.custProfile == 'SENP') {
                        console.log('inside');
                        this.showBusinessDetails = true;
                    } else {
                        this.showBusinessDetails = false;
                    }
                    if (this.check[0].CreatedBy?.Profile?.Name == this.constants?.API_Only_Integrations_Profile) {
                        this.showSource = true;
                    }
                    else {
                        this.showSource = false;
                    }

                    this.no = this.check[0].MobilePhone;
                    if (this.check[0].Lead_Type__c == 'Hot') {
                        this.responsive = true;
                    }
                    else {
                        this.responsive = false;
                    }

                    // this.panno = this.check[0].PAN_Number__c;
                    this.currPage = this.check[0].Current_Page__c;
                    //this.tempEmpId = this.check[0].Lead_Generator_User_Id__c;
                    this.actCust = this.check[0].Customer__c;
                    console.log('actCust ' + this.actCust);
                    console.log('Status 1066' + this.check[0].Status);
                    console.log('sub status ' + this.check[0].Lead_Sub_Status__c);

                    if (this.check[0].Status == this.constants?.Closed) {
                        this.canClose = false;
                        console.log('1152 canClose ' + this.canClose);
                        this.disablefields();
                        this.closed = true;
                        //this.channelDisabled = true;s
                        this.closedReason = this.check[0].Closed_Reasons__c;
                        this.fillseventhInformations = true;
                        this.fillfirstinformation = false;
                        this.fillsecondinformation = false;
                        this.fillfourthinformation = false;
                        this.fillthirdinformation = false;
                        this.fillfifthinformation = false;
                    }
                    if (this.check[0].Lead_Sub_Status__c == this.constants?.Disqualified || this.check[0].Lead_Sub_Status__c == this.constants?.Qualified) {
                        //  this.disablefields();
                        //this.channelDisabled = true;
                        //this.optverif = true;
                        this.qualdis = true;
                        //this.fetchPincodeName();
                        this.showareaManager = false;
                    }
                    // Disable all fields if channel is Online, a Sales User is assigned, but is not the current logged-in user
                    const assignedSalesUser = this.check[0].Assigned_Sales_User__c;
                    const isOnlineChannel = (this.check[0].Channel__c || '').trim() === 'Online';
                    if (isOnlineChannel && assignedSalesUser && assignedSalesUser !== USER_ID) {
                        console.log('Online lead: Sales user assigned to someone else, disabling fields for current user.');
                        this.disablefieldsOnline();
                        this.optverif = false; // prevent mobile masking
                        this.disableMobile = true; // disable mobile without masking
                    }
                    console.log('consent' + this.isConsentReceived);
                    if (this.isConsentReceived && this.consentStatus == 'Accepted') {
                        console.log('2709');
                        this.disablefields();
                    }
                    if ((this.isConsentReceived == false && this.consentStatus == 'Pending') || (this.isConsentReceived == true && this.consentStatus == 'Accepted')) {
                        this.optverif = true;
                    }
                    if (this.check[0].Lead_Sub_Status__c == this.constants?.Disqualified) {
                        this.qualified = false;
                    }
                    else if (this.check[0].Lead_Sub_Status__c == this.constants?.Qualified) {
                        this.qualified = true;
                    }
                    //this.customerType = this.check[0].Customer_Type__c;
                    this.headerTitle = this.qualified == true ? 'Send Consent' : 'Enter Lead Information';
                    this.custProfileOptions = this.custProfileOptionsActual.filter(opt => opt.validFor.includes(this.custProfileOptionsController[this.customerType]));
                    console.log('Employment_Type__c', this.check[0].Employment_Type__c);
                    //this.showCustProfile = true;
                    if (this.customerType != this.constants?.Individual) {
                        this.showdob = false;
                        this.shownonindi = true;
                    }
                    else {
                        this.showdob = true;
                        this.showindi = true;
                    }
                    console.log('this.check[0].Channel__c : ' + this.check[0].Channel__c);
                    if (this.check[0].Channel__c == undefined || this.check[0].Channel__c == '') {

                        if (this.dsa) {
                            this.selectedchannelTypeValue = 'DSA';
                            this.hideNameAndCode = false;
                            const allowedLabels = ['DSA', 'Corporate DSA'];
                            this.channelvaluesRo = this.dsa ? this.channelvaluesRo.filter(item => allowedLabels.includes(item.label)) : this.channelvaluesRo;
                            //this.disableNameAndCode = true;
                        } else {
                            console.log('selectedchannelTypeValue', this.selectedchannelTypeValue);
                            //this.selectedchannelTypeValue = 'Direct';
                            console.log('selectedchannelTypeValue', this.selectedchannelTypeValue);
                            this.hideNameAndCode = true;
                        }
                    }
                    // Set dsaId/dsaname FIRST so c-search-lookup receives values on mount
                    console.warn('DSA_Account__c:', this.check[0].DSA_Account__c,
                        '| DSA_Account__r.Name:', this.check[0].DSA_Account__r?.Name,
                        '| Channel__c:', this.check[0].Channel__c);
                    if (this.check[0].DSA_Account__c) {
                        this.dsaId = this.check[0].DSA_Account__c;
                        this.dsaname = this.check[0].DSA_Account__r?.Name;
                    }
                    // Set visibility flags AFTER dsaId/dsaname so child mounts with values already set
                    const _ch = (this.check[0].Channel__c || '').trim();
                    if (_ch === 'DSA' || _ch === 'Corporate DSA') {
                        if (this.check[0].Status !== 'Closed') this.showdsaName = true;
                    } else if (_ch === 'Connector') {
                        if (this.check[0].Status !== 'Closed') this.showConnectorName = true;
                    }
                    this.dateofInc = this.check[0].Date_of_Incorporation__c;
                    this.loanamt = this.check[0].Requested_Loan_Amount__c;
                    console.log('1190 ' + this.loanamt);

                    if (this.loanamt != null && this.loanamt != '') {
                        this.checklAmt = true;
                        getNumberToWord({ laAmt: this.loanamt })
                            .then(result => {
                                this.loanamtinwords = result;
                            })
                            .catch(error => {
                                console.error('Error fetching converted amount', error);
                            });
                    }

                    this.bindustval = this.check[0].Industry;
                    if (this.bindustval == undefined)
                        this.bindustval = '';
                    this.bvintage = this.check[0].Business_Vintage__c;
                    this.dateOfBirth = this.check[0].Date_of_Birth__c;
                    this.selectedProductType = this.check[0].Product__c;
                    const telesalesProfiles = ['GC Tele Sales Manager', 'GC Tele Sales User'];
                    if (this.rawProductPicklistOptions.length > 0 && telesalesProfiles.includes(this.uprofile)) {
                        this.filterProductOptions();
                    }
                    if (this.selectedProductType == 'Home Loan') {
                        this.showPan = true;
                        this.inputLabel = 'Constitution';
                    }

                    this.stage = this.check[0].Lead_Sub_Status__c;

                    if (this.stage == 'Converted') {
                        this.converted = true;
                    }
                    else {
                        this.converted = false;
                    }
                    if (this.check[0].Dsa_Area_Manager__c) {
                        this.arm = this.check[0].Dsa_Area_Manager__c;
                        this.armName = this.check[0].Dsa_Area_Manager__r.Name;
                    }
                    // this.optverif = this.check[0].Is_Consent_Received__c;
                    this.mobVerified = this.check[0].Is_Mobile_Verified__c;
                    this.panno = this.check[0].PAN__c;
                    console.log('optverif ' + this.optverif);
                    console.log('mobVerified ' + this.mobVerified);

                    if (this.optverif != false) {
                        // this.showelig = true;
                        this.showverif = false;
                    }
                    else if (this.mobVerified != true && this.optverif != true) {
                        // this.showelig = false;
                        this.showverif = true;
                    }
                    else if (this.mobVerified != false) {
                        // this.showelig = true;
                        this.showverif = true;
                    }
                    if (this.actCust != null && this.actCust != '') {
                        this.disablefirstName = true;
                        this.loantypeClosed = true;
                        this.CustProfileDisabled = true;
                        this.optverif = true;
                        this.disableMobile = true;
                    }
                    console.log('stage ' + this.stage);
                    console.log('currPage ' + this.currPage);
                    console.log('currPage canClose' + this.canClose);
                    if (this.canClose) {
                        switch (this.currPage) {
                            case 1:
                                this.fillthirdinformation = false;
                                this.fillsecondinformation = false;
                                this.fillfirstinformation = true;
                                console.log('1877');
                                this.fillfourthinformation = false;
                                this.shownext = true;
                                break;
                            case 2:
                                this.fillthirdinformation = false;
                                this.fillsecondinformation = true;
                                console.log('1883');
                                this.fillfirstinformation = false;
                                this.fillfourthinformation = false;
                                this.shownext = true;
                                break;
                            case 3:
                                this.fillthirdinformation = true;
                                this.fillsecondinformation = false;
                                this.fillfirstinformation = false;
                                this.fillfourthinformation = false;
                                this.shownext = true;
                                break;
                            case 4:
                                if (!this.telesales) {
                                    console.log('1842');
                                    // If true, skip page 4 and go to page 3
                                    this.currPage = 3;
                                    this.fillfourthinformation = false;
                                    this.fillthirdinformation = true;
                                    this.fillsecondinformation = false;
                                    this.fillfirstinformation = false;
                                    this.shownext = true;
                                }
                                else {
                                    console.log('1851');
                                    // If dsa and salesexecutive are not true, proceed with page 4
                                    this.fillfourthinformation = true;
                                    this.fillthirdinformation = false;
                                    this.fillsecondinformation = false;
                                    this.fillfirstinformation = false;
                                    this.shownext = true;
                                }
                                break;
                        }
                    }
                    else {
                        this.fillseventhInformations = true;
                        this.fillfirstinformation = false;
                        this.fillsecondinformation = false;
                        this.fillfourthinformation = false;
                        this.fillthirdinformation = false;
                        this.fillfifthinformation = false;
                    }
                }

                this.isLoading = false;
            })
            .catch(error => {
                // this.error = error;
                console.log('errorlead details', JSON.stringify(error));
                this.isLoading = false;
            });
    }

    handleEmailChange(event) {
        this.emailno = event.target.value;
        console.log('emailno ' + this.emailno);
        // Validate email format

        if (this.validateEmail(this.emailno)) {
            console.log('Valid email');
            this.validemail = true;
            if (this.visibilerecord) {
                this.updateRecordField(this.recordId, 'Email', this.emailno);
            }
            else {
                this.updateRecordField(this.newLeadId, 'Email', this.emailno);
            }
        }
        else {
            this.validemail = false;
            console.log('Invalid email');
        }
    }

    validateEmail(email) {
        // Regular expression for email validation
        // var emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
        var emailRegex = /^[A-Za-z0-9](\.?[A-Za-z0-9_%+-])*@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$/;

        return emailRegex.test(email);
    }

    handleemailBlur() {


        if (this.emailno != null) {
            if (!this.validemail) {
                this.emailno = '';
                this.showToast('Error', 'Please enter a valid email.', 'error')
            }
        }
    }

    handleGenderChange(event) {
        this.leadGender = event.detail.value;
        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'GenderIdentity', this.leadGender);
        }
        else {
            this.updateRecordField(this.newLeadId, 'GenderIdentity', this.leadGender);
        }
    }

    handlewnership(event) {
        this.offownerval = event.detail.value;
        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'Office_Ownership__c', this.offownerval);
        }
        else {
            this.updateRecordField(this.newLeadId, 'Office_Ownership__c', this.offownerval);
        }
    }

    handleTurnover(event) {
        this.turnover = event.detail?.value || event.target?.value;
        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'COMM_Business_Turnover__c', this.turnover);
            this.updateRecordField(this.recordId, 'Turnover_Yearly__c', this.turnover);
        }
        else {
            this.updateRecordField(this.newLeadId, 'COMM_Business_Turnover__c', this.turnover);
            this.updateRecordField(this.newLeadId, 'Turnover_Yearly__c', this.turnover);
        }
    }

    handleSubProductChange(event) {
        this.subProduct = event.target.value;
        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'Sub_Product__c', this.subProduct);
        }
        else {
            this.updateRecordField(this.newLeadId, 'Sub_Product__c', this.subProduct);
        }
    }

    handleAlternateMobileChange(event) {
        const value = (event.target.value || '').replace(/[^0-9]/g, '');
        this.alternateMobile = value;
        event.target.value = value;

        if (value && value.length !== 10) {
            this.showToast('Error', 'Please enter a valid 10 digit alternate mobile number.', 'error');
            return;
        }

        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'Alternate_Mobile_Number__c', this.alternateMobile);
        }
        else {
            this.updateRecordField(this.newLeadId, 'Alternate_Mobile_Number__c', this.alternateMobile);
        }
    }

    handleCityChange(event) {
        this.cityValue = event.target.value;
        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'City__c', this.cityValue);
        }
        else {
            this.updateRecordField(this.newLeadId, 'City__c', this.cityValue);
        }
    }

    handleStateChange(event) {
        this.stateValue = event.target.value;
        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'State__c', this.stateValue);
        }
        else {
            this.updateRecordField(this.newLeadId, 'State__c', this.stateValue);
        }
    }

    handlePurposeofloan(event) {
        this.purposeOfLoan = event.detail.value;
        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'COMM_Purpose_of_Loan__c', this.purposeOfLoan);
        }
        else {
            this.updateRecordField(this.newLeadId, 'COMM_Purpose_of_Loan__c', this.purposeOfLoan);
        }
    }
    handleCampaignCode(event) {
        this.campValue = event.detail.value;
        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'COMM_Campaign_Code__c', this.campValue);
        }
        else {
            this.updateRecordField(this.newLeadId, 'COMM_Campaign_Code__c', this.campValue);
        }
    }
    getDoccheckImageUploadedstatus() {
        if (this.visibilerecord) {
            this.leadId = this.recordId;
            console.log('leadId 1263', this.leadId);
        }
        else {
            this.leadId = this.newLeadId;
            console.log('leadId 1263', this.leadId);
        }

        // this.isLoading = true;
        checkImageUploaded({ leadId: this.leadId })
            .then(result => {
                console.log('result1', result);
                this.reqimagesUploaded = result;
                this.isLoading = false; // Ensure isLoading is set to false here to stop loading after completion
            })
            .catch(error => {
                console.log('errorlead details', JSON.stringify(error));
                this.isLoading = false;
            });
    }

    disablefields() {
        this.loantypeClosed = true;
        this.CustProfileDisabled = true;
        this.disablefirstName = true;
        this.disableMiddleName = true;
        this.disableLastName = true;
        this.showmob = true;
        this.datedisabled = true;
        this.disablepincode = true;
        this.productDisabled = true;
        console.log('Inside disable fields>>');
        this.disablePurposeOfLoan = true;
        console.log('disablePurposeOfLoan' + this.disablePurposeOfLoan);
        this.disableEmail = true;
        this.loanamtClosed = true;
        this.buttonval = 'Continue';
        this.checkEligibilityButton = 'Continue';
        this.pincodeDisabled = true;
        this.optverif = true;
        this.disableMobile = true;
        this.disableChannel = true;
        this.disableGeneratorNTB = true;
        this.disableExternalFields = true;
        this.disableLeadType = true;
    }

    // Online-specific disable: marks isOnlineDisable so computed getters
    // only lock fields that already have a value (empty fields stay editable).
    disablefieldsOnline() {
        this.isOnlineDisable = true;
        this.disablefields();
    }

    hanldemiddlenameChange(event) {

        let middleName = event.target.value;
        event.target.value = middleName.replace(/\s+/g, '');
        //  this.inputValue = event.target.value;

        this.middlename = event.target.value;
        var checkValidity = /^[a-zA-Z\s]*$/;
        if (checkValidity.test(this.middlename) && this.middlename.length <= 50) {

            if (this.visibilerecord) {
                this.updateRecordField(this.recordId, 'MiddleName', this.middlename);
            }
            else {
                if (this.newLeadId && this.newLeadId.length > 0) {
                    this.updateRecordField(this.newLeadId, 'MiddleName', this.middlename);
                }
            }
        } else {

            if (this.middlename.length > 50) {
                this.middlename = this.middlename.slice(0, 50) + this.middlename.slice(51); // Remove 41st character
                event.target.value = this.middlename;
            }
            var lastIndex = this.middlename.length - 1;
            //var thisIndex = lastIndex;
            const secondLastChar = this.middlename[lastIndex - 1];

            console.log('Captured Second Last Character: ' + secondLastChar);
            console.log('lastIndex-->' + lastIndex);
            if (lastIndex >= 0) {
                // Remove the last character from the string
                console.log('387');
                this.middlename = this.middlename.replace(/[^a-zA-Z\s]/g, '');
                event.target.value = this.middlename;
                //this.inputValue = this.inputValue+secondLastChar;
            }
            console.log('this.inputValue=:' + this.middlename);
            //this.fnameval = true;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill the middle name in the correct format. ',
                    variant: 'error',
                }),
            );
        }
    }


    handleIbusinessnameChange(event) {
        this.entityname = event.detail.value;

        // Allow only specific special characters (- and ')
        const specialCharactersPattern = /[^a-zA-Z0-9\s\-']/g;
        var checkValidity = /\d/;
        if (checkValidity.test(this.entityname)) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill the Business Entity Name in the correct format.',
                    variant: 'error',
                }),
            );
            this.entityname = this.entityname.replace(checkValidity, ''); // Remove invalid characters
            event.target.value = this.entityname;
            return;
        }
        if (specialCharactersPattern.test(this.entityname)) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Only the special characters "-" and "\'" are allowed.',
                    variant: 'error',
                }),
            );
            this.entityname = this.entityname.replace(specialCharactersPattern, ''); // Remove invalid characters
            event.target.value = this.entityname;
            return;
        }
        // Prevent double spacing within names
        const doubleSpacePattern = /\s\s+/g;
        if (doubleSpacePattern.test(this.entityname)) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Double spacing is not allowed within names.',
                    variant: 'error',
                }),
            );
            this.entityname = this.entityname.replace(doubleSpacePattern, ' '); // Replace double spaces with a single space
            event.target.value = this.entityname;
            return;
        }
        else {
            if (this.visibilerecord) {
                this.updateRecordField(this.recordId, 'Company', this.entityname);
            } else {
                if (this.newLeadId) {
                    this.updateRecordField(this.newLeadId, 'Company', this.entityname);
                }
            }
        }
        // Limit the length to 100 characters
        if (this.entityname.length > 100) {
            this.entityname = this.entityname.slice(0, 100);
            event.target.value = this.entityname;
        }
    }
    handleContactNameChange(event) {
        let contactName = event.detail.value;

        //event.target.value = contactName.replace(/\s+/g, '');
        //  this.inputValue = event.target.value;

        this.contactName = event.target.value;
        var checkValidity = /^[a-zA-Z\s]*$/;
        if (checkValidity.test(this.contactName) && this.contactName.length <= 50) {

            if (this.visibilerecord) {
                this.updateRecordField(this.recordId, 'COMM_Contact_Person_Name__c', this.contactName);
            }
            else {
                if (this.newLeadId && this.newLeadId.length > 0) {
                    this.updateRecordField(this.newLeadId, 'COMM_Contact_Person_Name__c', this.contactName);
                }
            }
        } else {

            if (this.contactName.length > 50) {
                this.contactName = this.contactName.slice(0, 50) + this.contactName.slice(51); // Remove 41st character
                event.target.value = this.contactName;
            }
            var lastIndex = this.contactName.length - 1;
            //var thisIndex = lastIndex;
            const secondLastChar = this.contactName[lastIndex - 1];

            console.log('Captured Second Last Character: ' + secondLastChar);
            console.log('lastIndex-->' + lastIndex);
            if (lastIndex >= 0) {
                // Remove the last character from the string
                console.log('387');
                this.contactName = this.contactName.replace(/[^a-zA-Z\s]/g, '');
                event.target.value = this.contactName;
                //this.inputValue = this.inputValue+secondLastChar;
            }
            console.log('this.inputValue=:' + this.contactName);
            //this.fnameval = true;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill the contact person name in the correct format. ',
                    variant: 'error',
                }),
            );
        }

    }

    handleCancelDedupe(event) {
        this.softdedupe = false;
    }

    handleSkipDedupe(event) {
        this.softdedupe = false;
        this.navigateToSecondPage();
    }

    handleTagCustomery(event) {
        this.actCust = event.detail.Id;
        console.log('actCust ' + this.actCust);
        this.showToast('success', 'Customer tagged to this Lead', 'success');
        this.softdedupe = false;
        this.disablebasicFields();
        this.dateOfBirth =
            this.navigateToSecondPage();
    }

    disablebasicFields() {
        this.loantypeClosed = true;
        this.CustProfileDisabled = true;
        this.disablefirstName = true;
        this.productDisabled = true;
        this.optverif = true;
        this.disableMobile = true;
        this.datedisabled = true;
        this.pincodeDisabled = true;
    }

    handlehotwarm(event) {
        this.isHotWarm = true;
        if (this.isIOS || this.isWindows) {
            const scrollOptions = {
                left: 0,
                top: window.innerHeight / 2, // Calculate the middle of the page
                behavior: 'smooth'
            };
            window.scrollTo(scrollOptions);

        }

        if (this.isAndroid) {
            const scrollOptions = {
                left: 0,
                top: document.body.scrollHeight / 2, // Calculate the middle of the page
                behavior: 'smooth'
            };
            window.scrollTo(scrollOptions);
        }
    }

    handleresponsive(event) {
        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'Lead_Type__c', 'Hot');
        }
        else {
            this.updateRecordField(this.newLeadId, 'Lead_Type__c', 'Hot');
        }
        this.responsive = true;
        this.showToast('Success', 'Lead Type changed to Hot.', 'success');
    }

    handletypeclose(event) {
        this.isHotWarm = false;
    }

    handletypesave(event) {
        const dispositionValue = event.detail.disposition;
        console.log('Selected Disposition:', +dispositionValue);

        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'Lead_Type__c', 'Cold');
        }
        else {
            this.updateRecordField(this.newLeadId, 'Lead_Type__c', 'Cold');
        }
        this.responsive = false;
        this.isHotWarm = false;
        this.showToast('Success', 'Lead Type changed to Cold.', 'success');
    }

    handleChannelPicklistChange(event) {
        this.selectedchannelTypeValue = event ? event.detail.value : this.selectedchannelTypeValue;
        this.updateRecordField(this.recordId, 'Orignal_Branch_id__c', this.originalBranchId);
        const acceptedChannelValues = ['DSA', 'Corporate DSA', 'Connector', 'Employee Referral', 'Customer Referral', 'CSC', 'Online'];
        console.log('selectedchannelTypeValuebefore', this.selectedchannelTypeValue);
        // Treat CSC and Online the same as Direct for UI/validation: hide name/code when channel is Direct, CSC, or Online
        const normalizedChannel = (this.selectedchannelTypeValue || '').trim();
        this.hideNameAndCode = !acceptedChannelValues.includes(normalizedChannel) || (['direct', 'csc', 'online'].includes(normalizedChannel.toLowerCase()) ? true : this.hideNameAndCode) ? !acceptedChannelValues.includes(normalizedChannel) : this.hideNameAndCode;
        // Simpler: hide name/code if channel is Direct, CSC, or Online
        this.hideNameAndCode = (this.isDirectLike(normalizedChannel) || normalizedChannel.toLowerCase() === 'csc' || normalizedChannel.toLowerCase() === 'online') ? true : !acceptedChannelValues.includes(normalizedChannel?.trim());
        // Disable channel picklist if CSC or Online
        if (normalizedChannel.toLowerCase() === 'csc' || normalizedChannel.toLowerCase() === 'online') {
            this.disableChannel = true;
        } else {
            this.disableChannel = false;
        }
        console.log('hideNameAndCode', this.hideNameAndCode);
        console.log('selectedchannelTypeValue', this.selectedchannelTypeValue);
        // Campaign visibility unchanged
        this.showCampaignCode = (normalizedChannel.toLowerCase() === 'campaign') ? true : false;
        this.fromChannelChange = true;
        if (this.selectedchannelTypeValue == 'DSA' || this.selectedchannelTypeValue == 'Corporate DSA') {
            //this.disableNameAndCode = true;
            this.getDSADetails();
            this.showdsaName = true;
        }
        else if (this.selectedchannelTypeValue == 'Connector') {
            // this.disableNameAndCode = true;
            this.showConnectorName = true;
            this.showdsaName = false;
        }
        else {
            this.showConnectorName = false;
            this.disableNameAndCode = false;
            this.showdsaName = false;
        }
        if (!this.originalBranchId && this.check && this.check[0]?.Branch__c) {
            this.originalBranchId = this.check[0].Branch__c;
            console.log('Captured original Branch__c:', this.originalBranchId);
        }
        else {
            this.originalBranchId = this.check[0].Orignal_Branch_id__c;
        }
        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'Channel__c', this.selectedchannelTypeValue);
            if (this.selectedchannelTypeValue == 'Direct' && this.nameValue && this.codeValue) {
                this.updateRecordField(this.recordId, 'Channel_Code__c', '');
                this.updateRecordField(this.recordId, 'Channel_Name__c', '');
            } else if (this.selectedchannelTypeValue == 'Direct' && this.campValue) {
                this.updateRecordField(this.recordId, 'COMM_Campaign_Code__c', '');
            }
            if (this.salesexecutive && !this.isDirectLike(this.selectedchannelTypeValue)) {
                console.log('Clearing Branch__c since channel is non-Direct');
                this.updateRecordField(this.recordId, 'Branch__c', '');
                this.updateRecordField(this.recordId, 'Orignal_Branch_id__c', this.originalBranchId);
                this.leadNotAssigned = true;
            }
            if (this.salesexecutive && this.isDirectLike(this.selectedchannelTypeValue) && this.originalBranchId) {
                console.log('Restoring Branch__c since channel switched back to Direct:', this.originalBranchId);
                this.updateRecordField(this.recordId, 'Branch__c', this.originalBranchId);
                this.updateRecordField(this.recordId, 'Orignal_Branch_id__c', '');
                this.leadNotAssigned = false;
            }
        }
        else {
            this.updateRecordField(this.newLeadId, 'Channel__c', this.selectedchannelTypeValue);
            if (this.salesexecutive && !this.isDirectLike(this.selectedchannelTypeValue)) {
                console.log('Clearing Branch__c since channel is non-Direct (newLeadId)');
                this.updateRecordField(this.newLeadId, 'Branch__c', '');
                this.updateRecordField(this.recordId, 'Orignal_Branch_id__c', this.originalBranchId);
                this.leadNotAssigned = true;
            }
            if (this.salesexecutive && this.isDirectLike(this.selectedchannelTypeValue) && this.originalBranchId) {
                console.log('Restoring Branch__c for newLeadId since channel switched back to Direct:', this.originalBranchId);
                this.updateRecordField(this.newLeadId, 'Branch__c', this.originalBranchId);
                this.updateRecordField(this.recordId, 'Orignal_Branch_id__c', '');
                this.leadNotAssigned = false;
            }
        }
    }
    get nameLabel() {
        return this.nameCodeLabelMap[this.selectedchannelTypeValue]?.nameLabel || this.nameCodeLabelMap['Default'].nameLabel;
    }
    get codeLabel() {
        return this.nameCodeLabelMap[this.selectedchannelTypeValue]?.codeLabel || this.nameCodeLabelMap['Default'].codeLabel;
    }
    handleSelectedAr(event) {
        console.log('searchRecord-->', event.detail.searchRecord);
        this.arm = event.detail.searchRecord.UserId;      // Fetching the ID
        this.armName = event.detail.searchRecord.User.Name; // Fetching the Name

        console.log('Selected ID: ' + this.arm);
        console.log('Selected Name: ' + this.armName);

        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'Dsa_Area_Manager__c', this.arm);
        }
        else {
            this.updateRecordField(this.newLeadId, 'Dsa_Area_Manager__c', this.arm);
        }
    }

    handleunselectAr(event) {
        this.arm = null;
        if (this.visibilerecord) {
            this.updateRecordField(this.recordId, 'Dsa_Area_Manager__c', this.arm);
        }
        else {
            this.updateRecordField(this.newLeadId, 'Dsa_Area_Manager__c', this.arm);
        }
    }

    handleCloseConfimationPopup(event) {
        this.showConfirmationPopup = false;
    }
    handleCallDedupe() {
        this.isLoading = true;
        console.log('handleCallDedupe called');
        var leadId;
        if (this.visibilerecord) {
            leadId = this.recordId;
        }
        else {
            leadId = this.newLeadId;
        }
        createLoanAndAppDet({
            panNumber: this.panno,
            leadId: leadId
        }).then(result => {
            console.log('result---2429-', JSON.stringify(result))
            // this[NavigationMixin.Navigate]({
            //     type: 'standard__recordPage',
            //     attributes: {
            //         recordId: response.loanId, // Replace with the dynamic record ID
            //         actionName: 'view',
            //         objectApiName: 'Opportunity' // Ensure this matches the object you're navigating to
            //     },
            // });
            this.newLoanId = result;
            checkSFDedupe({
                panNumber: this.panno,
                applicantId: '',
                loanId: result
            }).then(response => {



                console.log('result---2442-', JSON.stringify(response))
                const childCompVar = this.template.querySelector('c-lead-stage-path');
                const sendParam = { recordId: this.newLeadId };
                childCompVar.refreshChild(sendParam);
                fireEvent(this.pageRef, "closeLead", "Breed-Labrador");

                this.isLoading = false;
                this.showToast('Success', 'Lead converted to loan application successfully.', 'success');
                console.log('response in lead to loan----', JSON.stringify(response));


                setTimeout(() => {
                    if (response.freshCustomer) {
                        this.newLoanId = response.loanId;
                        const state = {
                            c__param1: 'navigateToBasic',

                        };
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: response.loanId, // Replace with the dynamic record ID
                                actionName: 'view',
                                objectApiName: 'Opportunity' // Ensure this matches the object you're navigating to
                            },
                            state: state
                        });
                    }
                    else {
                        const state = {
                            c__param1: 'navigateToDedupe',

                        };
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: response.loanId, // Replace with the dynamic record ID
                                actionName: 'view',
                                objectApiName: 'Opportunity' // Ensure this matches the object you're navigating to
                            },
                            state: state
                        });
                    }


                }, 1000);


            }).catch(error => {
                this.isLoading = false;
                const state = {
                    c__param1: 'navigateToBasic',

                };
                console.log('Error in convert- 2465---', error);
                console.log('Error in convert- 2465---', result);
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result, // Replace with the dynamic record ID
                        actionName: 'view',
                        objectApiName: 'Opportunity' // Ensure this matches the object you're navigating to
                    },
                    state: state
                });



            })
        }).catch(error => {
            this.isLoading = false;
            this.showToast('Error', 'Dedupe failed', 'error');
            console.log('newloanid---', this.newLoanId);
            this.showConfirmationPopup = false;
            const state = {
                c__param1: 'navigateToBasic',

            };
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.newLoanId, // Replace with the dynamic record ID
                    actionName: 'view',
                    objectApiName: 'Opportunity' // Ensure this matches the object you're navigating to
                },
                state: state
            });
            // console.log('Error in convert--2480--', result);

            // this.dispatchEvent(
            // new ShowToastEvent({
            //     title: 'Error',
            //     message: error.body.pageErrors[0].message,
            //     variant: 'error',
            // }),
            // );

        })
    }

    customStyle() {
        this.visibilerecord = true;
        // let combowrapper;
        setTimeout(() => {
            /*const  combowrapper = this.template.querySelector('.combowrapper');
           
             if (combowrapper) {
                 const style = document.createElement('style');
                 style.innerText = `
                    .combowrapper {
                        
                            lightning-combobox::part(listbox) {
             max-height: 150px;
             overflow-y: scroll;
         }
                 }
                     
                                  }
                 `;
                  combowrapper.appendChild(style);*/
            const combobox = this.template.querySelector('.cbc');
            if (combobox) {
                // Try a couple of likely containers depending on runtime
                const sr = combobox.shadowRoot;
                if (!sr) return;

                // Common candidates for the dropdown list container:
                const candidates = [
                    '.slds-listbox.slds-dropdown_fluid',
                    '.slds-combobox__dropdown.slds-dropdown',
                    '[role="listbox"]'
                ];

                for (const sel of candidates) {
                    const list = sr.querySelector(sel);
                    if (list) {
                        list.style.maxHeight = '220px';
                        list.style.overflowY = 'auto';
                        list.style.webkitOverflowScrolling = 'touch'; // smooth on iOS
                        this._patched = true;
                        break;
                    }
                }

            } else {
                console.error('No elements with class "combowrapper" found in renderedCallback.');
            }
        }, 1000);

    }




    handleStatusChange(event) {
        console.log('event.detail>>', event.detail.status);
        if (event.detail.status == 'Accepted') {
            this.statusNotAccepted = false;
            this.optverif = true;
            this.disablefields();
        }
        if (event.detail.status == 'Pending') {
            this.optverif = true;
            this.disableMobile = true;
        }

    }
    handleAssignmentStatus(payload) {
        this.leadNotAssigned = payload.isAssigned;
        console.log('leadNotAssigned', this.leadNotAssigned);
        // Immediately disable fields when sales user is assigned on Online leads
        if ((this.selectedchannelTypeValue || '').trim() === 'Online') {
            this.disablefieldsOnline();
            this.optverif = false; // prevent mobile masking
            this.disableMobile = true; // disable mobile without masking
        }
    }
    handlecheckMNRL() {

        checkMNRL({
            inputMap: { mobNumber: this.no, processName: 'MNRL Check', relatedId: this.recordId }
        })
            .then(mnrlResult => {
                console.log('MNRL Result:', mnrlResult);

                if (mnrlResult && mnrlResult.isBlacklisted) {
                    //Stop further execution if blacklisted
                    this.showToast('Error', mnrlResult.message, 'error');
                    //this.isLoading = false;
                    return;
                } else {
                    this.handleSecondInformation();
                }
            })
            .catch(error => {
                console.error('Error in MNRL check: ', JSON.stringify(error));
                this.showToast('Error', 'Failed to validate mobile number. Please try again.', 'error');
            });
    }
    //review
    // fetchPincodeName(){
    //     pincodeName({ pinId: this.pinno })
    //     .then((result) => {
    //         this.pincodename = result;
    //         console.log('Pincode Name:', this.pincodename);
    //     })
    //     .catch((error) => {
    //         console.error('Error fetching pincode name:', error.body.pageErrors[0].message);
    //     });
    // }

    // handlepreview(event){
    //     this.imageSrc = event.detail.imageUrl;
    //     console.log('Image URL received:', event.detail.imageUrl);
    //     this.showimage = true;
    //     this.showfields = false;
    // }

    // closePreview(){
    //     this.showimage = false;
    //     this.showfields = true;
    // }

    // openGenericpopup(event){
    //     // this.showfields = false;
    //     this.showConfirmation = true;
    //     this.deleteDocId = event.detail.docId;
    //     console.log('deleteDocId '+this.deleteDocId);
    // }

    // handleDeleted(event){
    //     console.log('1068');
    //     this.getDoccheckImageUploadedstatus();
    //     this.isLoading = false;
    // }

    // hanleUpload(event){
    //     this.getDoccheckImageUploadedstatus();
    //     this.isLoading = false;
    // }

    // addDoc(){
    //     this.addDocuments = true;
    //     // this.showfields = false;
    // }

    // handleYes(event) {
    //     this.isLoading = true;
    //     this.showConfirmation = false;
    //     this.showfields = true;
    //     console.log('1055 ' + this.deleteDocId);

    //     if(this.deleteDocId) {
    //         // Delay the querying of the child component
    //         setTimeout(() => {
    //             const childComponent = this.template.querySelector('c-upload-docs');
    //             console.log('childComponent ', childComponent);
    //             if(childComponent) {
    //                 // Call the delete method in the child component
    //                 childComponent.deleteDocument(this.deleteDocId);
    //             }
    //             else {
    //                 console.log('Child component not found');
    //             }
    //         }, 1000); // Delay of 1 second
    //     } 
    //     else {
    //         console.log('deleteDocId is undefined');
    //         this.isLoading = false; // Set loading to false if docId is undefined
    //     }
    // }

    // handleNo(event){
    //     this.showConfirmation = false;
    //     this.showfields = true;
    //     this.deleteDocId = null
    // }

    // handleSaveDoc(event){
    //     this.addDocuments = false;
    //     this.showfields = true;
    //     this.isloading = true;
    //     setTimeout(() => {
    //         const childComponent = this.template.querySelector('c-upload-docs');
    //         console.log('childComponent ', childComponent);
    //         if(childComponent) {
    //             // Call the delete method in the child component
    //             childComponent.connectedCallback();
    //         }
    //         else {
    //             console.log('Child component not found');
    //         }
    //         this.isloading = false;
    //     }, 1000); // Delay of 1 second
    // }

    // SendConsentLink(){
    //     console.log('this.recordId '+this.recordId);
    //     this.navigateToConsentPage();

    //     if(this.visibilerecord){
    //         this.updateRecordField(this.recordId, 'Is_Consent_Received__c', this.otptrue);
    //         this.dispatchEvent(
    //             new ShowToastEvent({
    //                 title: 'Success',
    //                 message: 'Consent Link Sent.',
    //                 variant: 'Success',
    //             })
    //         );

    //         this.showverif = false;
    //         this.showverify = true;
    //         this.startTimer(30);
    //     }
    //     else{
    //         this.updateRecordField(this.newLeadId, 'Is_Consent_Received__c', this.otptrue);
    //         this.dispatchEvent(
    //             new ShowToastEvent({
    //                 title: 'Success',
    //                 message: 'Consent Link Sent.',
    //                 variant: 'Success',
    //             })
    //         );
    //         this.showverif = false;
    //         this.showverify = true;
    //         this.startTimer(30);
    //     }
    // }

    //mytimeout;
    // sendVerCode(event) {
    //     this.verif = '';
    //     if(this.mytimeout){
    //         console.log('502');
    //         clearTimeout(this.mytimeout);
    //     }
    //     this.isShowcode = true;
    //     this.showBox = false;
    //     this.optverifs = true;
    //     this.showverify = true;
    //     this.otpnotverified=false;
    //     this.startTimer(30);
    //     // this.shownewbox = true; // Assume initially it's true
    //     this.showToast('Success', 'Verification Code sent successfully', 'success');
    //     setTimeout(() => {
    //         // Check if the button has not been clicked
    //         if(!this.isVerifyCodeClicked) {
    //             this.resend = true;
    //             console.log('resend ' + this.resend);
    //             if(!this.shownewbox) { // Only proceed if shownewbox is still true
    //                 this.resentTimeout();
    //             }
    //         }
    //     }, this.otpTimeout);
    // }

    // resentTimeout() {
    //     this.mytimeout = setTimeout(() => {
    //         console.log('521 ');
    //         this.isShowcode = false;
    //         this.showBox = true;
    //         this.optverifs = false;
    //         this.showverify = false;
    //         this.shownewbox = false; // Set shownewbox to false after the timeout
    //     }, this.otpTimeout);
    // }

    // verifiycode(event){
    //     this.verifyCode();
    // }

    // handleInterestChange(event) {
    //     this.customerInterest = event.detail.value;
    //     this.showLoginButton = this.customerInterest === 'Yes';
    // }

    // handleVerificationCodeChange(event) {
    //     this.verif = event.target.value;
    //     console.log('verif ' + this.verif);
    //     // You can save the input or perform other actions here
    // }

    // startTimer(seconds) {
    //     this.showTimer = true;
    //     console.log('453 ' + seconds);
    //     this.countdown = seconds;
    //     this.isButtonDisabled = true;

    //     clearInterval(this.timer);

    //     this.timer = setInterval(() => {
    //         this.countdown -= 1;
    //         //const minutes = Math.floor(this.countdown / 60);
    //         const seconds = this.countdown % 60;
    //         // Update timerValue to display only seconds
    //         this.timerValue = `${seconds < 10 ? '0' : ''}${seconds}`;
    //         this.reset = 'Resend in ' + this.timerValue + ' seconds';
    //         console.log('reset ' + this.reset);
    //         this.shownonresend = true;

    //         if(this.countdown === 0) {
    //             clearInterval(this.timer);
    //             this.resend = true;
    //             this.shownonresend = false;
    //         }
    //     }, 1000);
    // }

    // disconnectedCallback(){
    //     clearInterval(this.timer);
    // }

    // handlePin(event){
    //     var checkValidity = /^[0-9]*$/;
    //     var number = event.target.value;
    //     if (!number.match(checkValidity) && number.length > 0) {
    //         // If input contains non-numeric characters, remove them and display an error
    //         number= number.replace(/[^0-9]/g, '');
    //         event.target.value = number;
    //         return;
    //     }
    //     else{
    //         var pin = /^[0-9]{6}$/;
    //         var specialCharactersRegex = /^[!@#$%^&*(),.?":{}|<>]+$/;
    //         var numericRegex = /^[a-zA-Z\s]*$/;
    //         this.pinno = event.target.value;
    //         this.pinLength = this.pinno.length;
    //         console.log('pinLength '+this.pinLength);

    //         if(this.pinno.match(pin)) {
    //             this.pinval = false;
    //             this.pincode = this.recordId;
    //             const fields = {};
    //             this.pincodecheck= true;
    //             this.showfields = false;
    //             this.pinval = false;
    //         }
    //         else if(this.pinno.match(numericRegex)){
    //             this.pinval = true
    //             this.pincodecheck= false;
    //             this.dispatchEvent(
    //                 new ShowToastEvent({
    //                     title: 'Error',
    //                     message: 'Please fill pincode in the correct format',
    //                     variant: 'error',
    //                 }),
    //             );
    //         }
    //         else if(this.pinno.match(specialCharactersRegex)){
    //             this.pinval = true
    //             this.pincodecheck= false;
    //             this.dispatchEvent(
    //                 new ShowToastEvent({
    //                     title: 'Error',
    //                     message: 'Please fill pincode in the correct format',
    //                     variant: 'error',
    //                 }),
    //             );
    //         }
    //         else if(this.pinLength == 6 && !this.pinno.match(pin)){
    //             this.pinval = true
    //             this.pincodecheck= false;
    //             this.dispatchEvent(
    //                 new ShowToastEvent({
    //                     title: 'Error',
    //                     message: 'Please fill pincode in the correct format',
    //                     variant: 'error',
    //                 }),
    //             );
    //         }
    //         else if(this.pinLength > 6){
    //             this.pinval = true
    //             this.pincodecheck= false;
    //             this.dispatchEvent(
    //                 new ShowToastEvent({
    //                     title: 'Error',
    //                     message: 'Please fill pincode in the correct format',
    //                     variant: 'error',
    //                 }),
    //             );
    //         }
    //     }
    // }
    //Lead Details
    handleStampLeadDetails(event) {
        console.log('this.inputValue=:' + JSON.stringify(event.detail));
        console.log('this.showindi' + this.showindi);
        if (event.detail.customerType != null && event.detail.customerType != '' && event.detail.customerType != undefined && event.detail.cusType == 'Non Individual') {
            this.showindi = false;
            this.customerType = 'Non Individual';
            this.custProfileOptions = this.custProfileOptionsActual.filter(opt => opt.validFor.includes(this.custProfileOptionsController[this.customerType]));
            console.log('this.custProfileOptions##', JSON.stringify(this.custProfileOptions));
        }
        else {
            this.showindi = true;
            this.customerType = 'Individual';
            this.custProfileOptions = this.custProfileOptionsActual.filter(opt => opt.validFor.includes(this.custProfileOptionsController[this.customerType]));
            console.log('this.custProfileOptions##', JSON.stringify(this.custProfileOptions));
        }
        if (this.showindi) {
            if (event.detail.name != null && event.detail.name != undefined && event.detail.name != '') {
                const nameVal = event.detail.name;
                this.disablefirstName = true;
                const splittedName = nameVal.split(' ');
                if (splittedName.length === 1) {
                    // Only one word → last name
                    this.inputValue = splittedName[0]; // first name empty
                    this.middlename = '';
                    this.inputValue2 = '';
                }
                else if (splittedName.length === 2) {
                    // Two words → first and last
                    this.inputValue = splittedName[0];
                    this.middlename = '';
                    this.inputValue2 = splittedName[1];
                }
                else if (splittedName.length >= 3) {
                    // Three or more words → first, middle, last
                    this.inputValue = splittedName[0];
                    this.middlename = splittedName.slice(1, -1).join(' '); // all middle parts
                    this.inputValue2 = splittedName[splittedName.length - 1];
                }
            }
            this.dateOfBirth = event?.detail?.dob != null ? event.detail.dob : null;
            this.dobordoi = event.detail.dob;


        }
        else {
            this.entityname = event?.detail?.name != null ? event.detail.name : '';
            this.dateofInc = event?.detail?.dob != null ? event.detail.dob : null;
            this.dobordoi = event.detail.dob;
        }
        this.selectedCustId = event.detail.custLmsId;

    }

    handleResetProduct(event) {
        this.callTopUpCmp = false;
        console.log('event.detail-->', event.detail);
        if (event.detail.custLmsId = '' || event.detail.custLmsId == null || event.detail.custLmsId == undefined) {
            this.selectedProductType = '';
        }
        else {
            this.selectedCustId = event.detail.custLmsId;
        }
        // this.hasHLPermission=true;

    }
    selectedRecord;
    isTopupLead = false;
    handleReceiveResultFlexi(event) {
        console.log('inside lead');
        this.callTopUpCmp = false;
        this.selectedRecord = event.detail.selectedRecord;
        console.log('selectedRecord=:' + JSON.stringify(this.selectedRecord));
        this.loanSource = this.selectedRecord.source;
        this.referenceNumber = this.selectedRecord.finReference;
        this.isTopupLead = true;
    }

    cloneLoanApplicationFL() {
        const inputMap = {
            leadId: this.newLeadId,
            recordId: this.recordId,
            loanNum: this.parentLoanNumberFL
        }
        cloneLoanApplicationFL({
            inputMap: inputMap
        })
            .then(result => {
                this.createdLoanId = result.loanId;
                console.log('result ' + JSON.stringify(result));
                const childCompVar = this.template.querySelector('c-lead-stage-path');
                const sendParam = { recordId: this.recordId };
                childCompVar.refreshChild(sendParam);
                this.isLoading = false;

                fireEvent(this.pageRef, "closeLeadfromedit", "Breed-Labrador");
                this.showToast('Success', 'Lead converted to loan application successfully.', 'success');
                console.log('at 1081');
                setTimeout(() => {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: this.createdLoanId, // Replace with the dynamic record ID
                            actionName: 'view',
                            objectApiName: 'Opportunity' // Ensure this matches the object you're navigating to
                        },
                    });
                }, 1000);
            })
            .catch(error => {
                this.isLoading = false;
                console.log('error>>' + JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.pageErrors[0].message,
                        variant: 'error',
                    }),
                );
            });




        console.log('Mappppp----', inputMap);
    }
    hasRendered;

    renderedCallback() {
        if (this._overflowPatched) return;
        this._overflowPatched = true;

        // Walk up to find the first element that clips dropdowns
        let el = this.template.host.parentElement;
        for (let i = 0; i < 12 && el; i++, el = el.parentElement) {
            const cs = getComputedStyle(el);
            const clips = ['hidden', 'clip'].includes(cs.overflow) ||
                ['hidden', 'clip'].includes(cs.overflowY);
            if (clips) {
                // allow scroll (so the combobox menu can fully render and scroll internally)
                el.style.overflowY = 'auto';
                break;
            }


        }
        this.colormethod();
    }

    //    colormethod() {
    //    // if (this.hasRendered) return;
    //     console.log('enter in colormethod...after previous');
    //     const inputTarget = this.template.querySelector('.custom-input');
    //     console.log('inputTarget--', inputTarget);
    //     // Only execute if the element is actually present in the DOM
    //     if (inputTarget) {
    //         console.log('in if..5334');
    //         this.hasRendered = true; // Mark as rendered only when successful

    //         const style = document.createElement('style');
    //         style.innerText = `
    //             .custom-input label {
    //                 color: white !important;
    //             }
    //         `;
    //         inputTarget.appendChild(style);
    //     }
    // }
    pageHeaderStyleAdded = false;
    lineInputStyleAdded = false;
    colormethod() {

        /* ____GenAI: converts every boxed lightning-input / lightning-combobox
           field on Basic Information + Additional Details into an underline/
           "line format" field per explicit request (reference screenshot).
           Root cause: the box (background/border/radius) lives on
           ".slds-input" / ".slds-combobox__input" INSIDE lightning-input's /
           lightning-combobox's own shadow DOM, which a scoped component .css
           file cannot reach - same root cause already solved elsewhere in
           this file (datepicker calendar, page header) by injecting a real
           global <style> tag via document.head, which is the only way to
           override shadow-DOM-internal markup. Colors used below (#33455e
           border, #8b5cf6 focus, #ff4d4f error) are the SAME colors already
           used throughout this component's dark theme - no new palette, no
           label/value/handler/validation/required logic touched, and the
           selectors are scoped to ".lead-main-panel" so no other component on
           the page is affected____ */
        if (!this.lineInputStyleAdded) {
            this.lineInputStyleAdded = true;

            const lineInputStyle = document.createElement('style');
            lineInputStyle.setAttribute('data-source', 'lmv2-line-input-style');
            lineInputStyle.innerText = `
                .lead-main-panel .slds-input,
                .lead-main-panel .slds-combobox__input,
                .lead-main-panel textarea.slds-textarea {
                    background: transparent !important;
                    border: none !important;
                    border-bottom: 1px solid #33455e !important;
                    border-radius: 0 !important;
                    box-shadow: none !important;
                }
                .lead-main-panel .slds-input:focus,
                .lead-main-panel .slds-combobox__input:focus,
                .lead-main-panel .slds-has-focus .slds-input,
                .lead-main-panel .slds-has-focus .slds-combobox__input {
                    border-bottom: 1px solid #8b5cf6 !important;
                    box-shadow: none !important;
                }
                .lead-main-panel .slds-has-error .slds-input,
                .lead-main-panel .slds-has-error .slds-combobox__input {
                    border: none !important;
                    border-bottom: 1px solid #ff4d4f !important;
                    background: transparent !important;
                    box-shadow: none !important;
                }
            `;
            document.head.appendChild(lineInputStyle);
        }

        console.log('enter in colormethod...after previous');

        const inputTarget = this.template.querySelector('.custom-input');
        console.log('inputTarget--', inputTarget);

        // Custom input label styling
        if (inputTarget && !this.hasRendered) {
            console.log('in if..5334');

            this.hasRendered = true;

            const style = document.createElement('style');

            style.innerText = `
            .custom-input label {
                color: white !important;
            }
        `;

            inputTarget.appendChild(style);
        }

        // Salesforce standard page header styling
        if (!this.pageHeaderStyleAdded) {

            const pageHeaderStyle = document.createElement('style');

            pageHeaderStyle.innerText = `
            .slds-page-header {
                background: #21163f !important;
                border: none !important;
                box-shadow: none !important;
            }

            .slds-page-header .slds-page-header__title,
            .slds-page-header h1,
            .slds-page-header h2 {
                color: #ffffff !important;
            }
        `;

            document.head.appendChild(pageHeaderStyle);

            this.pageHeaderStyleAdded = true;
        }
    }

}